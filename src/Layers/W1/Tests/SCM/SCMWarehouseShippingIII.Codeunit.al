codeunit 137162 "SCM Warehouse - Shipping III"
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
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        LocationOrange: Record Location;
        LocationYellow: Record Location;
        LocationGreen: Record Location;
        LocationRed: Record Location;
        LocationInTransit: Record Location;
        LocationSilver: Record Location;
        LocationBlack: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        isInitialized: Boolean;
        ValueMustBeEqualTxt: Label 'Value must be equal.';
        InvtPickCreatedTxt: Label 'Number of Invt. Pick activities created';
        NothingToHandleErr: Label 'Nothing to handle. %1.', Comment = '%1: Details';
        QtyReservedNotFromInventoryTxt: Label 'The quantity to be picked is not in inventory yet. You must first post the supply from which the source document is reserved';
        NothingToHandleNonPickableBinTxt: Label 'The quantity to be picked is in bin %1, which is not set up for picking', Comment = '%1: Field("Bin Code")';
        NothingToHandleReplenishmentBinTxt: Label 'The quantity to be picked is in bin %1, which is set up for receiving or shipping', Comment = '%1: Field("Bin Code")';
        NoDetailsForNothingToHandleErr: Label 'Nothing to handle message has no further details.';
        NothingToHandleDetailsQueueNotEmptyErr: Label 'Nothing to handle details text queue must be empty now.';
        AssemblyOrderMsg: Label 'Due Date %1 is before work date %2 in one or more of the assembly lines.', Comment = '%1 = Due Date';
        PickActivityMsg: Label 'Pick activity';
        ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,AssignSerialNo,ApplyFromItemEntry,AssignAutoSerialNo,AssignAutoLotAndSerialNo,AssignManualLotNo,AssignManualTwoLotNo,AssignTwoLotNo,SelectEntriesForMultipleLines,UpdateQty,PartialAssignManualTwoLotNo,AssignSerialAndLotNos;
        UndoShipmentConfirmMessageQst: Label 'Do you really want to undo the selected Shipment lines';
        ReservationMode: Option " ",ReserveFromCurrentLine,AutoReserve;
        ReportName: Option SalesShipment,ItemTrackingAppendix;
        UndoShipmentConfirmQst: Label 'Do you want to undo the selected shipment line(s)?';
        UndoConsumptionConfirmQst: Label 'Do you want to undo consumption of the selected shipment line(s)?';
        UndoType: Option UndoShipment,UndoConsumption;
        CannotChangeValueErr: Label 'You cannot change %1 because one or more lines exist.';
        WhsShpmtHeaderExternalDocumentNoIsWrongErr: Label 'Warehouse Shipment Header."External Document No." is wrong.';
        WhsRcptHeaderVendorShpmntNoIsWrongErr: Label 'Warehouse Receipt Header."Vendor Shipment No." is wrong.';
        InvPickMsg: Label 'Number of Invt. Pick activities created';

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLineFullWithAsmItemSerialAndItemtrackingLot()
    var
        AssemblyItem: Record Item;
        Quantity: Decimal;
    begin
        // Test PostiveAdjmt Quantity on Whse Entry after undo Sales Shipment Line with Full Qty when Items are created with Serial and Lot specific.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        CreateSerialItemWithRepSysAssembly(AssemblyItem);
        ItemTrackingWithLotSpecific(AssemblyItem, Quantity, Quantity, ItemTrackingMode::AssignAutoSerialNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLinePartialWithAsmItemLotAndItemtrackingLot()
    var
        AssemblyItem: Record Item;
        Quantity: Decimal;
    begin
        // Test PostiveAdjmt Quantity on Whse Entry after undo Sales Shipment Line with Partial Qty when Items are created with Lot specific.
        Initialize();
        Quantity := 100;
        CreateItemWithRepSysAssembly(AssemblyItem);
        ItemTrackingWithLotSpecific(AssemblyItem, Quantity, Quantity / LibraryRandom.RandInt(3),
          ItemTrackingMode::AssignLotNo)
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLineFullWithAsmItemLotAndItemtrackingLot()
    var
        AssemblyItem: Record Item;
        Quantity: Decimal;
    begin
        // Test PostiveAdjmt Quantity on Whse Entry after undo Sales Shipment Line with Full Qty when Items are created with Lot specific.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        CreateItemWithRepSysAssembly(AssemblyItem);
        ItemTrackingWithLotSpecific(AssemblyItem, Quantity, Quantity, ItemTrackingMode::AssignLotNo)
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLinePartialWithAsmItemLotAndItemtrackingSerial()
    var
        AssemblyItem: Record Item;
        Quantity: Decimal;
    begin
        // Test PostiveAdjmt Quantity on Whse Entry after undo Sales Shipment Line with Partial Qty when Items are created with Lot and Serial specific.
        Initialize();
        Quantity := 100;
        CreateItemWithRepSysAssembly(AssemblyItem);
        ItemTrackingWithSerialSpecific(AssemblyItem, Quantity, Quantity / LibraryRandom.RandInt(3),
          ItemTrackingMode::AssignLotNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLineFullWithAsmItemLotAndItemtrackingSerial()
    var
        AssemblyItem: Record Item;
        Quantity: Decimal;
    begin
        // Test PostiveAdjmt Quantity on Whse Entry after undo Sales Shipment Line with Full Qty when Items are created with Lot and Serial specific.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        CreateItemWithRepSysAssembly(AssemblyItem);
        ItemTrackingWithSerialSpecific(AssemblyItem, Quantity, Quantity, ItemTrackingMode::AssignLotNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLinePartialWithAsmItemSerialAndItemtrackingSerial()
    var
        AssemblyItem: Record Item;
        Quantity: Decimal;
    begin
        // Test PostiveAdjmt Quantity on Whse Entry after undo Sales Shipment Line with Partial Qty when Items are created with Serial specific.
        Initialize();
        Quantity := 100;
        CreateSerialItemWithRepSysAssembly(AssemblyItem);
        ItemTrackingWithSerialSpecific(AssemblyItem, Quantity, Quantity / LibraryRandom.RandInt(3),
          ItemTrackingMode::AssignAutoSerialNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLineFullWithAsmItemSerialAndItemtrackingSerial()
    var
        AssemblyItem: Record Item;
        Quantity: Decimal;
    begin
        // Test PostiveAdjmt Quantity on Whse Entry after undo Sales Shipment Line with Full Qty when Items are created with Serial specific.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        CreateSerialItemWithRepSysAssembly(AssemblyItem);
        ItemTrackingWithSerialSpecific(AssemblyItem, Quantity, Quantity, ItemTrackingMode::AssignAutoSerialNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLinePartialWithAsmItemSerialAndItemtrackingLot()
    var
        AssemblyItem: Record Item;
        Quantity: Decimal;
    begin
        // Test PostiveAdjmt Quantity on Whse Entry after undo Sales Shipment Line with Partial Qty when Items are created with Serial and Lot specific.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        CreateSerialItemWithRepSysAssembly(AssemblyItem);
        ItemTrackingWithLotSpecific(AssemblyItem, Quantity, Quantity / LibraryRandom.RandInt(3),
          ItemTrackingMode::AssignAutoSerialNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickAccordingToFEFOWithSerialItemTrackingUsingDifferentExpirationDate()
    begin
        // Setup.
        Initialize();
        WarehousePickAccordingToFEFOWithSerialItemTracking(true);  // Use DifferentExpirationDate as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickAccordingToFEFOWithSerialItemTrackingUsingSameExpirationDate()
    begin
        // Setup.
        Initialize();
        WarehousePickAccordingToFEFOWithSerialItemTracking(false);  // Use DifferentExpirationDate as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickAccordingToFEFOWithLotAndSerialItemTrackingUsingDifferentExpirationDate()
    begin
        // Setup.
        Initialize();
        WarehousePickAccordingToFEFOWithLotAndSerialItemTracking(true);  // Use DifferentExpirationDate as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickAccordingToFEFOWithLotAndSerialItemTrackingUsingSameExpirationDate()
    begin
        // Setup.
        Initialize();
        WarehousePickAccordingToFEFOWithLotAndSerialItemTracking(false);  // Use DifferentExpirationDate as False.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickAccordingToFEFODoesNotConsiderStockWithLaterExpirationDate()
    var
        Location: Record Location;
        Item: Record Item;
        BinPick: Record Bin;
        BinBulk: Record Bin;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Pick] [FEFO]
        // [SCENARIO 380556] Picking by FEFO always takes the first expiring lot in a pick zone.
        Initialize();

        // [GIVEN] Full WMS Location with "Pick According to FEFO" enabled.
        CreateWMSLocationWithFEFOEnabled(Location);

        // [GIVEN] Lot-tracked Item.
        CreateItemWithLotItemTrackingCode(Item, true, '');

        // [GIVEN] Two same sized (quantity = "Q") lots "L1" and "L2" of Item is put-away on the Location.
        // [GIVEN] "L1" is expiring earlier than "L2" and is placed into BULK zone.
        // [GIVEN] "L2" is expiring later than "L1" and is placed into PICK zone.
        Quantity := LibraryRandom.RandInt(10);
        FindBinForPickZone(BinPick, Location.Code, true); // PICK zone
        UpdateAndTrackInventoryUsingWhseJournal(BinPick, Item, Quantity, '', WorkDate() + LibraryRandom.RandIntInRange(11, 20));
        FindBinForPickZone(BinBulk, Location.Code, false); // BULK zone
        UpdateAndTrackInventoryUsingWhseJournal(BinBulk, Item, Quantity, '', WorkDate() + LibraryRandom.RandInt(10));

        // [GIVEN] Warehouse Shipment created out of Sales Order with Item and quantity = "Q".
        CreateAndReleaseSalesOrder(
          SalesHeader, LibrarySales.CreateCustomerNo(), Item."No.", Quantity, Location.Code, '', false, ReservationMode::" ");
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);

        // [WHEN] Create Pick from Sales Shipment.
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [THEN] Warehouse pick from the bin in pick zone is created.
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.TestField("Bin Code", BinPick.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickAccordingToFEFOWithSerialItemTrackingUsingDifferentExpirationDate()
    begin
        // Setup.
        Initialize();
        InventoryPickAccordingToFEFOWithSerialItemTracking(true);  // Use DifferentExpirationDate as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickAccordingToFEFOWithSerialItemTrackingUsingSameExpirationDate()
    begin
        // Setup.
        Initialize();
        InventoryPickAccordingToFEFOWithSerialItemTracking(false);  // Use DifferentExpirationDate as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickAccordingToFEFOWithLotAndSerialItemTrackingUsingDifferentExpirationDate()
    begin
        // Setup.
        Initialize();
        InventoryPickAccordingToFEFOWithLotAndSerialItemTracking(true);  // Use DifferentExpirationDate as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickAccordingToFEFOWithLotAndSerialItemTrackingUsingSameExpirationDate()
    begin
        // Setup.
        Initialize();
        InventoryPickAccordingToFEFOWithLotAndSerialItemTracking(false);  // Use DifferentExpirationDate as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickAccordingToFEFOWithLotItemTrackingUsingDifferentExpirationDate()
    begin
        // Setup.
        Initialize();
        InventoryPickAccordingToFEFOWithLotItemTracking(true);  // Use DifferentExpirationDate as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickAccordingToFEFOWithLotItemTrackingUsingSameExpirationDate()
    begin
        // Setup.
        Initialize();
        InventoryPickAccordingToFEFOWithLotItemTracking(false);  // Use DifferentExpirationDate as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure MovementAccordingToFEFOWithSerialItemTrackingUsingDifferentExpirationDate()
    begin
        // Setup.
        Initialize();
        MovementAccordingToFEFOWithItemTracking(true, true, false);  // Use DifferentExpirationDate as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure MovementAccordingToFEFOWithSerialItemTrackingUsingSameExpirationDate()
    begin
        // Setup.
        Initialize();
        MovementAccordingToFEFOWithItemTracking(false, true, false);  // Use DifferentExpirationDate as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure MovementAccordingToFEFOWithLotAndSerialItemTrackingUsingDifferentExpirationDate()
    begin
        // Setup.
        Initialize();
        MovementAccordingToFEFOWithItemTracking(true, true, true);  // Use DifferentExpirationDate as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure MovementAccordingToFEFOWithLotAndSerialItemTrackingUsingSameExpirationDate()
    begin
        // Setup.
        Initialize();
        MovementAccordingToFEFOWithItemTracking(false, true, true);  // Use DifferentExpirationDate as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure MovementAccordingToFEFOWithLotItemTrackingUsingDifferentExpirationDate()
    begin
        // Setup.
        Initialize();
        MovementAccordingToFEFOWithItemTracking(true, false, true);  // Use DifferentExpirationDate as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure MovementAccordingToFEFOWithLotItemTrackingUsingSameExpirationDate()
    begin
        // Setup.
        Initialize();
        MovementAccordingToFEFOWithItemTracking(false, false, true);  // Use DifferentExpirationDate as False.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure MovementAccordingToFEFOIsNotPermittedFromReplenishmentBin()
    var
        Location: Record Location;
        Item: Record Item;
        BinFrom: Record Bin;
        BinTo: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Movement] [FEFO]
        // [SCENARIO 380556] Movement should not be created from a replenishment Bin (with SHIP or RECEIVE type). "Nothing to handle" error message with description of the issue and Bin no. should be thrown.
        Initialize();

        // [GIVEN] Full WMS Location with "Pick According to FEFO" enabled.
        CreateWMSLocationWithFEFOEnabled(Location);

        // [GIVEN] Lot-tracked Item.
        CreateItemWithLotItemTrackingCode(Item, true, '');

        // [GIVEN] Quantity "Q" of Item is put-away in a bin in RECEIVE zone.
        Quantity := LibraryRandom.RandInt(10);
        FindReplenishmentBin(BinFrom, Location.Code);
        UpdateAndTrackInventoryUsingWhseJournal(BinFrom, Item, Quantity, '', WorkDate() + LibraryRandom.RandInt(10));

        // [GIVEN] Movement Worksheet Line from the bin in RECEIVE zone to a bin in PICK zone for Item is created.
        FindBinForPickZone(BinTo, Location.Code, true);
        BinTo.Validate("Bin Ranking", LibraryRandom.RandInt(100));
        BinTo.Modify(true);
        CreateMovementWorksheetLine(WhseWorksheetLine, BinTo, Item."No.", Quantity);
        WhseWorksheetLine."Qty. to Handle" := Quantity;
        WhseWorksheetLine."Qty. to Handle (Base)" := Quantity;
        WhseWorksheetLine.Modify(true);

        // [WHEN] Create Movement from Movement Worksheet Line.
        asserterror LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::None, false, false, false);

        // [THEN] Movement is not created.
        // [THEN] "Nothing to handle" error with the indication of a not suitable bin from which a required lot is stored.
        Assert.ExpectedError(StrSubstNo(NothingToHandleErr, StrSubstNo(NothingToHandleReplenishmentBinTxt, BinFrom.Code)));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler,SalesShipmentReportHandler')]
    [Scope('OnPrem')]
    procedure CorrectionQuantityForLotInReportSalesShipment()
    begin
        // Test to verify Correction Quantity is correct for Lot tracking line in Report 208 (Sales - Shipment)
        VerifyReportForUndoShipmentWithLotTracking(ReportName::SalesShipment, 'TrackingSpecBufferLotNo', 'TrackingSpecBufferQty');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler,ItemTrackingAppendixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CorrectionQuantityForLotInReportItemTrackingAppendix()
    begin
        // Test to verify Correction Quantity is correct for Lot tracking line in Report 6521 (Item Tracking Appendix)
        VerifyReportForUndoShipmentWithLotTracking(ReportName::ItemTrackingAppendix, 'LotNo', 'TotalQuantity');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler,ServiceShipmentReportHandler')]
    [Scope('OnPrem')]
    procedure CorrectionQuantityForLotInReportServiceShipmentWithUndoShipment()
    begin
        // Test to verify Correction Quantity is correct for Lot tracking line with Undo Shipment in Report 5913 (Service - Shipment)
        CorrectionQuantityForLotInReportServiceShipment(UndoType::UndoShipment);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler,ServiceShipmentReportHandler')]
    [Scope('OnPrem')]
    procedure CorrectionQuantityForLotInReportServiceShipmentWithUndoConsumption()
    begin
        // Test to verify Correction Quantity is correct for Lot tracking line with Undo Consumption in Report 5913 (Service - Shipment)
        CorrectionQuantityForLotInReportServiceShipment(UndoType::UndoConsumption);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure FEFOPickWithMultipleUOMs()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesHeader: Record "Sales Header";
        Quantity: array[2] of Decimal;
        QtyPerUOM: Decimal;
        OldPickAccordingToFEFO: Boolean;
    begin
        // [FEATURE] [Warehouse Pick] [FEFO]
        // [SCENARIO] Check that can pick Quantity if available when "Pick According to FEFO" set, Item with multiple UOMs.

        // [GIVEN] Set "Pick According to FEFO" for Location, Lot Tracked Item with two lots of quantities "Q1" and "Q2" availavble in some bin (UOM with coeff "C" > 1).
        Initialize();
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, true);

        QtyPerUOM := 76; // QtyPerUOM = 76 needed for test
        Quantity[1] := 4; // Value needed for test.
        Quantity[2] := 10; // Value needed for test.

        CreateItemWithLotItemTrackingCode(Item, true, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPerUOM);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateAndRegisterPutAwayFromPurchaseOrderNoExpiration(
          Bin, Item."No.", LocationWhite.Code, Quantity[1], ItemUnitOfMeasure.Code, true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateAndRegisterPutAwayFromPurchaseOrderNoExpiration(
          Bin, Item."No.", LocationWhite.Code, Quantity[2], ItemUnitOfMeasure.Code, true);

        // [GIVEN] Released Sales Order with two lines of Quantities "S1" and "S2", where "S1" + "S2" < ("Q1" + "Q2") * "C".
        Quantity[1] := 700; // Value needed for test.
        Quantity[2] := 100; // Value needed for test.

        CreateAndReleaseSalesOrderWithMultipleSalesLines(
          SalesHeader, '', Item."No.", Item."No.", Quantity[1], Quantity[2], LocationWhite.Code);
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);

        // [WHEN] Create Pick.
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [THEN] Picked Quantity equals to "S1" + "S2".
        VerifyQtyToPickEqualsTo(Item."No.", Quantity[1] + Quantity[2]);

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FEFOPickLotsWhenNoStockAvailable()
    var
        SalesHeader: Record "Sales Header";
        Bin: Record Bin;
        Item: Record Item;
        Quantity: Decimal;
        OldPickAccordingToFEFO: Boolean;
    begin
        // [FEATURE] [Warehouse Pick] [FEFO] [Lot Item Tracking]
        // [SCENARIO] Check that cannot pick Quantity greater than available when "Pick According to FEFO" set.

        // [GIVEN] Set "Pick according to FEFO" for Location where Lot Tracked Item of Quantity "X" is available.
        Initialize();
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, true);

        CreateItemWithLotItemTrackingCode(Item, true, LibraryUtility.GetGlobalNoSeriesCode());
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        Quantity := 2 * LibraryRandom.RandIntInRange(500, 1000);
        CreateAndRegisterPutAwayFromPurchaseOrderNoExpiration(Bin, Item."No.", LocationWhite.Code, Quantity, '', true);

        // [GIVEN] Reserve "R" quantity if Item for Sales Order.
        // [GIVEN] Create Sales Orer of Quantity "S", where "S" > ("X" - "R").
        // [WHEN] Create Pick.
        // [THEN] Quantity Picked equals to ("X" - "R")
        FEFOPickWhenNoStockAvailableVerify(SalesHeader, Item."No.", Quantity, 100);

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure FEFOPickSerialsWhenNoStockAvailable()
    var
        SalesHeader: Record "Sales Header";
        Bin: Record Bin;
        Item: Record Item;
        Quantity: Decimal;
        OldPickAccordingToFEFO: Boolean;
    begin
        // [FEATURE] [Warehouse Pick] [FEFO] [Serial Item Tracking]
        // [SCENARIO] Check that cannot pick Quantity greater than available when "Pick According to FEFO" set.

        // [GIVEN] Set "Pick according to FEFO" for Location where Serial Tracked Item of Quantity "X" is available.
        Initialize();
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, true);

        CreateItemWithSerialItemTrackingCodeUsingStrictExpiration(Item, false);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignAutoSerialNo);  // Enqueue for ItemTrackingLinesPageHandler.
        Quantity := 2 * LibraryRandom.RandIntInRange(5, 10);
        CreateAndRegisterPutAwayFromPurchaseOrderNoExpiration(Bin, Item."No.", LocationWhite.Code, Quantity, '', false);

        // [GIVEN] Reserve "R" quantity if Item for Sales Order.
        // [GIVEN] Create Sales Orer of Quantity "S", where "S" > ("X" - "R").
        // [WHEN] Create Pick.
        // [THEN] Quantity Picked equals to ("X" - "R")
        FEFOPickWhenNoStockAvailableVerify(SalesHeader, Item."No.", Quantity, 1);

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOneOfTwoFullyPickedShipmentsOfTheSameItem()
    var
        WarehouseShipmentHeader: array[2] of Record "Warehouse Shipment Header";
        WarehouseShipmentLine: array[2] of Record "Warehouse Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LocationCode: Code[10];
        AssemblyItem: Code[20];
        ComponentItem: Code[20];
    begin
        // [FEATURE] [Pick] [Assemble-to-Order]
        // [SCENARIO 223800] The shipment can be posted when another fully picked shipment of the same item exists
        Initialize();

        // [GIVEN] Location with directed put-away and pick with specified To/From Assembly bins
        LocationCode := CreateAssemblyFullWMSLocation();

        // [GIVEN] Assembly Item "A" with one component "C"
        CreateAssemblyItemWithComponent(AssemblyItem, ComponentItem);

        // [GIVEN] "C" has enough inventory
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(ComponentItem, LocationCode, 2, false);

        // [GIVEN] Two Sales Orders of "A" with shipments for which the picks are created, one of these shipments - "S"
        CreateTwoSalesOrdersWithShipmentsAndPicks(WarehouseShipmentHeader, WarehouseShipmentLine, AssemblyItem, LocationCode, 1);

        // [WHEN] Post "S"
        WarehouseShipmentLine[1].Validate("Qty. to Ship", 1);
        WarehouseShipmentLine[1].Modify(true);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader[1], false);

        // [THEN] Sale Item Ledger Entry for "A" exists
        ItemLedgerEntry.SetRange("Item No.", AssemblyItem);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        Assert.RecordCount(ItemLedgerEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickWithLinesChangeLocationError()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        Qty: Integer;
    begin
        // [FEATURE] [Inventory Pick]
        // [SCENARIO 256471] It should not be allowed to change location code in an inventory pick that has lines
        Initialize();

        // [GIVEN] Locations "L1" and "L2", both require inventory pick
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location[1], false, false, true, false, false);
        LibraryWarehouse.CreateLocationWMS(Location[2], false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[2].Code, false);

        Qty := LibraryRandom.RandInt(100);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location[1].Code, '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create inventory pick with one line on location "L1"
        CreateInventoryPickFromSalesOrder(SalesHeader, Item."No.", Location[1].Code, Qty, false);
        FindWarehouseActivityLine(
          WhseActivityLine, WhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");

        // [WHEN] Change location code to "L2"
        asserterror WhseActivityHeader.Validate("Location Code", Location[2].Code);

        // [THEN] Error: You cannot change location code because one or more lines exist.
        Assert.ExpectedError(StrSubstNo(CannotChangeValueErr, WhseActivityHeader.FieldCaption("Location Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPickNoLinesChangeLocation()
    var
        Location: array[2] of Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [FEATURE] [Inventory Pick]
        // [SCENARIO 256471] It should be allowed to change location code in an inventory pick that has no lines
        Initialize();

        // [GIVEN] Locations "L1" and "L2", both require inventory pick
        LibraryWarehouse.CreateLocationWMS(Location[1], false, false, true, false, false);
        LibraryWarehouse.CreateLocationWMS(Location[2], false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[1].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location[2].Code, false);

        // [GIVEN] Create inventory pick without lines on location "L1"
        WhseActivityHeader.Validate(Type, WhseActivityHeader.Type::"Invt. Pick");
        WhseActivityHeader.Validate("Location Code", Location[1].Code);
        WhseActivityHeader.Insert(true);

        // [WHEN] Change location code to "L2"
        WhseActivityHeader.Validate("Location Code", Location[2].Code);

        // [THEN] Location code is successfully updated
        WhseActivityHeader.TestField("Location Code", Location[2].Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TestPermissions(TestPermissions::NonRestrictive)]
    [Scope('OnPrem')]
    procedure CreateInvtPickDoesNotRequireWhsePermission()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [FEATURE] [Inventory Pick]
        // [SCENARIO 263236] A user does not require permissions for warehouse documents to create inventory pick.
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        // [GIVEN] Location "L" set up for required pick.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Item "I" is in inventory on "L".
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, '', LibraryRandom.RandIntInRange(20, 40));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order on location "L".
        CreateAndReleaseSalesOrder(
          SalesHeader, '', Item."No.", LibraryRandom.RandInt(10), Location.Code, '', false, ReservationMode::" ");

        // [GIVEN] Lower permissions of a user, so they have access only to inventory documents (invt. pick, put-away, etc.), not warehouse documents (whse. shipment, receipt).
        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.AddO365WhseEdit();

        // [WHEN] Create inventory pick from the sales order.
        LibraryVariableStorage.Enqueue(InvtPickCreatedTxt);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // [THEN] Inventory pick is created.
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [TestPermissions(TestPermissions::NonRestrictive)]
    [Scope('OnPrem')]
    procedure CalcAvailQtyToInvtPickDoesNotRequireWhsePermission()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        QtyInStock: Decimal;
        QtyAvailToPick: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263236] A user does not require permissions for warehouse documents to run CalcInvtAvailQty function, that calculates available quantity to pick/put-away/move with inventory documents.
        LibraryLowerPermissions.SetOutsideO365Scope();
        Initialize();

        // [GIVEN] Location "L" set up for required pick.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] "Q" pcs of item "I" are in stock on location "L".
        QtyInStock := LibraryRandom.RandIntInRange(20, 40);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, '', QtyInStock);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Lower permissions of a user, so they have access only to inventory documents (invt. pick, put-away, etc.), not warehouse documents (whse. shipment, receipt).
        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.AddO365WhseEdit();

        // [WHEN] Invoke "CalcInvtAvailQty" function in codeunit Warehouse Availability Mgt., in order to calculate available quantity to pick.
        QtyAvailToPick := WhseAvailMgt.CalcInvtAvailQty(Item, Location, '', WarehouseActivityLine);

        // [THEN] No permission issues. Available quantity to pick = "Q".
        Assert.AreEqual(QtyInStock, QtyAvailToPick, 'Available quantity to pick is wrong.');
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure NothingToPickDueToReservMessageShownOnTryingToPickNotFromInventory()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Warehouse Pick] [Reservation]
        // [SCENARIO 279461] A detailed "Nothing to handle" error message is shown that points to the existing reservation not from the inventory, when a user cannot create pick from shipment due to this reason.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase order for 20 pcs of item "I" on a location with directed put-away and pick.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          Item."No.", LocationWhite.Code, LibraryRandom.RandIntInRange(11, 20), '', false);

        // [GIVEN] Sales order for 10 pcs of item "I", reserved from the purchase.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", LibraryRandom.RandInt(10), LocationWhite.Code, LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20));
        LibraryVariableStorage.Enqueue(ReservationMode::ReserveFromCurrentLine);
        SalesLine.ShowReservation();

        // [GIVEN] Post item stock, good enough to fulfill the sales (>100 pcs).
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(
          Item."No.", LocationWhite.Code, LibraryRandom.RandIntInRange(100, 200), false);

        // [GIVEN] Create warehouse shipment from the sales order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);

        // [WHEN] Create warehouse pick.
        asserterror CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [THEN] A pick was not created because the sales is reserved not from the inventory.
        // [THEN] An elaborate "Nothing to handle..." error message is raised that explains the incapability of picking.
        Assert.ExpectedError(StrSubstNo(NothingToHandleErr, QtyReservedNotFromInventoryTxt));
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure NothingToPickMessageForSeveralReasonsThatBlockPicking()
    var
        Bin: Record Bin;
        Item: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        CreatePick: Codeunit "Create Pick";
        FirstActivityNo: Code[20];
        LastActivityNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Warehouse Pick] [Reservation] [Bin]
        // [SCENARIO 279461] A queue of details texts for "Nothing to handle" error message is accumulated when there are several reasons why warehouse pick cannot be created from shipment.
        Initialize();

        // [GIVEN] Items "I1", "I2".
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Purchase order for "I1".
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          Item[1]."No.", LocationWhite.Code, LibraryRandom.RandIntInRange(11, 20), '', false);

        // [GIVEN] Sales order with two lines:
        // [GIVEN] 1st line - item "I1", and it is reserved from the purchase.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item[1]."No.", LibraryRandom.RandInt(10), LocationWhite.Code, LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20));
        LibraryVariableStorage.Enqueue(ReservationMode::ReserveFromCurrentLine);
        SalesLine.ShowReservation();

        // [GIVEN] 2nd line - item "I2".
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[2]."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", LocationWhite.Code);
        SalesLine.Modify(true);

        // [GIVEN] Post stock for both items "I1" and "I2" on location with directed put-away and pick.
        // [GIVEN] Item "I1" is placed into "PICK" zone from which it can be picked.
        FindBinForPickZone(Bin, LocationWhite.Code, true);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item[1]."No.", LibraryRandom.RandIntInRange(100, 200), false);

        // [GIVEN] Item "I2" is placed into "BULK" zone from which it cannot be picked.
        FindBinForPickZone(Bin, LocationWhite.Code, false);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item[2]."No.", LibraryRandom.RandIntInRange(100, 200), false);

        // [GIVEN] Create warehouse shipment from the sales order.
        // [GIVEN] None of two lines of the shipment cannot be picked - item "I1" is reserved from purchase, item "I2" is stored in the unreachable zone.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);

        // [WHEN] Create pick, but do not interrupt the process on the first error.
        for i := 1 to 2 do begin
            WarehouseShipmentLine.SetRange("Item No.", Item[i]."No.");
            FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
            CreatePick.SetWhseShipment(WarehouseShipmentLine, 1, '', '', '');
            CreatePick.CreateTempLine(
              WarehouseShipmentLine."Location Code", WarehouseShipmentLine."Item No.", WarehouseShipmentLine."Variant Code", WarehouseShipmentLine."Unit of Measure Code",
              '', WarehouseShipmentLine."Bin Code", WarehouseShipmentLine."Qty. per Unit of Measure", WarehouseShipmentLine."Qty. Outstanding", WarehouseShipmentLine."Qty. Outstanding (Base)");
        end;
        CreatePick.CreateWhseDocument(FirstActivityNo, LastActivityNo, false);

        // [THEN] A queue of pick errors causes is accumulated.
        // [THEN] The first run of "GetCannotBeHandledReason" function in Create Pick codeunit gets the reason why item "I1" was not picked.
        Assert.AreEqual(
          QtyReservedNotFromInventoryTxt, CreatePick.GetCannotBeHandledReason(), NoDetailsForNothingToHandleErr);

        // [THEN] The second run of "GetCannotBeHandledReason" function in Create Pick codeunit gets the reason why item "I2" was not picked.
        Assert.AreEqual(
          StrSubstNo(NothingToHandleNonPickableBinTxt, Bin.Code), CreatePick.GetCannotBeHandledReason(), NoDetailsForNothingToHandleErr);

        // [THEN] The third run of "GetCannotBeHandledReason" function in Create Pick codeunit does not get any more information.
        Assert.AreEqual('', CreatePick.GetCannotBeHandledReason(), NothingToHandleDetailsQueueNotEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickForReservedShipmentOnLocationWithNoPickRequired()
    var
        Item: Record Item;
        Location: Record Location;
        ShipmentBin: Record Bin;
        PickBin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Warehouse Shipment] [Warehouse Pick] [Reservation]
        // [SCENARIO 292483] You can pick a reserved item at location with disabled Require Pick.
        Initialize();

        // [GIVEN] Location with mandatory bin and required shipment.
        // [GIVEN] Require Pick = FALSE at the location.
        // [GIVEN] Two bins: "Pick" and "Ship".
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(ShipmentBin, Location.Code, '', 1);
        LibraryWarehouse.FindBin(PickBin, Location.Code, '', 2);
        Location.Validate("Shipment Bin Code", ShipmentBin.Code);
        Location.Modify(true);

        // [GIVEN] Place some stock into bin "Pick".
        Qty := LibraryRandom.RandInt(10);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, PickBin.Code, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order and reserve it from the inventory.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, Location.Code, WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Create warehouse shipment from the sales order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick in order to move items from bin "Pick" to bin "Ship".
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [THEN] The warehouse pick is created.
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.TestField(Quantity, Qty);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure UndoPostedSalesShipmentForOneOfMultipleLocations()
    var
        Location: array[2] of Record Location;
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        Index: Integer;
    begin
        // [FEATURES] [Undo Shipment] [Sales Order]
        // [SCENARIO 292815] Undo Sales Shipment should consider Location Code for each Sales Line.
        Initialize();

        // [GIVEN] Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.SetRecFilter();

        // [GIVEN] Two Items in two Sales Lines with Two Location Codes "A" and "B"
        // [GIVEN] Each Location Code Require Shipment
        for Index := 1 to ArrayLen(Location) do begin
            CreateAndUpdateLocation(Location[Index], false, false, false, true, false);
            LibraryInventory.CreateItem(Item[Index]);
            LibrarySales.CreateSalesLine(SalesLine[Index], SalesHeader, SalesLine[Index].Type::Item, Item[Index]."No.", 1);
            SalesLine[Index].Validate("Location Code", Location[Index].Code);
            SalesLine[Index].Modify(true);
        end;

        // [GIVEN] Sales Order released and Whse. Shipments created and posted for both lines
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesLine[1]."Document Type");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.FindSet();
        repeat
            WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        until WarehouseShipmentLine.Next() = 0;

        // [GIVEN] Shipment for the Line 2 with Location Code "B" is being Undo
        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentLine.SetRange("Order Line No.", SalesLine[2]."Line No.");
        SalesShipmentLine.SetRange(Quantity, SalesLine[2].Quantity);
        SalesShipmentLine.FindFirst();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [WHEN] Create new Whse. Shipment for the Line 2
        GetSourceDocOutbound.CreateFromSalesOrderHideDialog(SalesHeader);

        // [THEN] Whse. Shipment created for the Sales Line 2 for "B"
        WarehouseShipmentLine.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine[2]."Document Type".AsInteger(), SalesLine[2]."Document No.", SalesLine[2]."Line No.", true);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField("Location Code", SalesLine[2]."Location Code");
        WarehouseShipmentLine.TestField(Quantity, SalesLine[2].Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentAfterReleasedSalesOrderExternalDocNoChanged()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [FEATURE] [Warehouse Shipment]
        // [SCENARIO 325564] "External Document No." in Warehouse Shipment must be same as the latest value in Source Sales Order when "External Document No." was modified after the release
        Initialize();

        // [GIVEN] Released Sales Order "S1"
        CreateAndReleaseSalesOrder(
          SalesHeader, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo(), 1, LocationWhite.Code, '', false, ReservationMode::" ");

        // [GIVEN] "External Document No." on "S1" changed to "TESTAFTER"
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);

        // [WHEN] Create Warehouse Shipment for this Sales Order
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] "External Document No." = "TESTAFTER" in Warehouse Shipment
        FindWarehouseShipmentHeaderBySource(
          WarehouseShipmentHeader, DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", -1);
        Assert.AreEqual(
          SalesHeader."External Document No.",
          WarehouseShipmentHeader."External Document No.", WhsShpmtHeaderExternalDocumentNoIsWrongErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentAfterReleasedPurchReturnOrderExternalDocNoChanged()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [FEATURE] [Warehouse Shipment]
        // [SCENARIO 325564] "External Document No." in Warehouse Shipment must be same as the latest "Vendor Shipment No." of Source Purchase Return Order when "Vendor Shipment No." was modified after the release
        Initialize();

        // [GIVEN] Released Purchase Return Order "P1"
        CreateAndReleaseSimplePurchaseReturnOrder(PurchaseHeader, 1);

        // [GIVEN] "Vendor Shipment No." on "P1" changed to "TESTAFTER"
        PurchaseHeader.Validate("Vendor Shipment No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // [WHEN] Create Warehouse Shipment for this Purchase Return Order
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);

        // [THEN] "External Document No." = "TESTAFTER" in Warehouse Shipment
        FindWarehouseShipmentHeaderBySource(
          WarehouseShipmentHeader, DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", -1);
        Assert.AreEqual(
          PurchaseHeader."Vendor Shipment No.",
          WarehouseShipmentHeader."External Document No.", WhsShpmtHeaderExternalDocumentNoIsWrongErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentAfterReleasedTransferOrderExternalDocNoChanged()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [FEATURE] [Warehouse Shipment]
        // [SCENARIO 325564] "External Document No." in Warehouse Shipment must be same as the latest value in Source Transfer Order when "External Document No." was modified after the release
        Initialize();

        // [GIVEN] Released Transfer Order "T1"
        CreateAndReleaseSimpleTransferOrder(TransferHeader, LocationYellow.Code, LocationWhite.Code, LibraryInventory.CreateItemNo(), 1);

        // [GIVEN] "External Document No." on "T1" changed to "TESTAFTER"
        TransferHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        TransferHeader.Modify(true);

        // [WHEN] Create Warehouse Shipment for this Transfer Order
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [THEN] "External Document No." = "TESTAFTER" in Warehouse Shipment
        FindWarehouseShipmentHeaderBySource(WarehouseShipmentHeader, DATABASE::"Transfer Line", 0, TransferHeader."No.", -1);
        Assert.AreEqual(
          TransferHeader."External Document No.",
          WarehouseShipmentHeader."External Document No.", WhsShpmtHeaderExternalDocumentNoIsWrongErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandlerSimple')]
    procedure DirectTransferOrderWithWarehouseShipmentAndPickDirectTransferPosting()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        InventorySetup: Record "Inventory Setup";
        WarehouseSetup: Record "Warehouse Setup";
        FromLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        DirectTransferHeader: Record "Direct Trans. Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Shipment]
        // [SCENARIO 325564] Direct Transfer from Required Shipment location (GREEN) to non warehouse location (BLUE) can be completely posted by posting of warehouse shipment
        Initialize();

        InventorySetup.Get();
        InventorySetup."Direct Transfer Posting" := InventorySetup."Direct Transfer Posting"::"Direct Transfer";
        InventorySetup.Modify();

        WarehouseSetup.Get();
        WarehouseSetup."Shipment Posting Policy" :=
            WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error";
        WarehouseSetup.Modify();

        // [GIVEN] Released Direct Transfer Order "T1"
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, true, false, true);

        // [GIVEN] Post 10 pcs to inventory.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", FromLocation.Code, '', 10);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateAndReleaseDirectTransferOrder(TransferHeader, FromLocation.Code, LocationBlue.Code, Item."No.", 1);

        // [WHEN] Create Warehouse Shipment for this Transfer Order
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [WHEN] Find Warehouse Shipment, create and register Pick and post Warehouse Shipment
        FindWarehouseShipmentHeaderBySource(WarehouseShipmentHeader, DATABASE::"Transfer Line", 0, TransferHeader."No.", -1);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        WhseActivityRegister.Run(WarehouseActivityLine);

        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Direct transfer order is fully posted to posted direct transfer
        DirectTransferHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        DirectTransferHeader.FindFirst();
        asserterror TransferHeader.Get(TransferHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferOrderWithWarehouseShipmentDirectTransferPostingFromTransferOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        InventorySetup: Record "Inventory Setup";
        WarehouseSetup: Record "Warehouse Setup";
        FromLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrderPostTransfer: Codeunit "TransferOrder-Post Transfer";
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Shipment]
        // [SCENARIO 325564] Direct Transfer from Required Shipment location (GREEN) to non warehouse location (BLUE) can be completely posted by posting of warehouse shipment
        Initialize();

        InventorySetup.Get();
        InventorySetup."Direct Transfer Posting" := InventorySetup."Direct Transfer Posting"::"Direct Transfer";
        InventorySetup.Modify();

        WarehouseSetup.Get();
        WarehouseSetup."Shipment Posting Policy" :=
            WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error";
        WarehouseSetup.Modify();

        // [GIVEN] Released Direct Transfer Order "T1"
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, false, false, true);

        // [GIVEN] Post 10 pcs to inventory.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", FromLocation.Code, '', 10);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateAndReleaseDirectTransferOrder(TransferHeader, FromLocation.Code, LocationBlue.Code, Item."No.", 1);

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        TransferLine.testfield("Qty. to Ship", 0);

        asserterror TransferOrderPostTransfer.Run(TransferHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandlerSimple,ConfirmHandlerAsTrue')]
    procedure DirectTransferOrderWithInventoryPickDirectTransferPosting()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        InventorySetup: Record "Inventory Setup";
        WarehouseSetup: Record "Warehouse Setup";
        FromLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        DirectTransferHeader: Record "Direct Trans. Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Shipment]
        // [SCENARIO 325564] Direct Transfer from Required Shipment location (GREEN) to non warehouse location (BLUE) can be completely posted by posting of warehouse shipment
        Initialize();

        InventorySetup.Get();
        InventorySetup."Direct Transfer Posting" := InventorySetup."Direct Transfer Posting"::"Direct Transfer";
        InventorySetup.Modify();

        WarehouseSetup.Get();
        WarehouseSetup."Shipment Posting Policy" :=
            WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error";
        WarehouseSetup.Modify();

        // [GIVEN] Released Direct Transfer Order "T1"
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, true, false, false);

        // [GIVEN] Post 10 pcs to inventory.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", FromLocation.Code, '', 10);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateAndReleaseDirectTransferOrder(TransferHeader, FromLocation.Code, LocationBlue.Code, Item."No.", 1);

        // [WHEN] Create Inventory Pick for  this Transfer Order
        LibraryWarehouse.CreateInvtPutPickMovement(
            "Warehouse Request Source Document"::"Outbound Transfer", TransferHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick");

        // [WHEN] Autofill and register Inventory Pick and fully post transfer order
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        CODEUNIT.Run(CODEUNIT::"Whse.-Act.-Post (Yes/No)", WarehouseActivityLine);

        // [THEN] Direct transfer order is fully posted to posted direct transfer
        DirectTransferHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        DirectTransferHeader.FindFirst();
        asserterror TransferHeader.Get(TransferHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferOrderWithTransferToBinCode()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        InventorySetup: Record "Inventory Setup";
        TransferHeader: Record "Transfer Header";
        TransferOrderPostTransfer: Codeunit "TransferOrder-Post Transfer";
    begin
        // [FEATURE] [Direct Transfer] 
        // [SCENARIO 467919] Posted Direct Transfer line has blank “Transfer-to Bin Code” when transfer to location has Bin Mandatory setup
        Initialize();

        // [GIVEN] when in Inventory Setup field "Direct Transfer Posting" is set as "Direct Transfer"
        InventorySetup.Get();
        InventorySetup."Direct Transfer Posting" := InventorySetup."Direct Transfer Posting"::"Direct Transfer";
        InventorySetup.Modify();

        // [GIVEN] Created new item and put on the inventory
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationBlue.Code, '', 10);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Set default bin on the destination location 
        CreatedDefaulBinContent(LocationSilver, Item, '');

        // [GIVEN] Created new transfer order 
        CreateAndReleaseDirectTransferOrder(TransferHeader, LocationBlue.Code, LocationSilver.Code, Item."No.", 1);

        // [WHEN] transfer order posted as direct transfer
        TransferOrderPostTransfer.SetHideValidationDialog(true);
        TransferOrderPostTransfer.Run(TransferHeader);

        // [THEN] posted direct transfer line contains info about transfer-to bin code
        CheckPostedDirectTransfer(TransferHeader, Item);
    end;

    local procedure CheckPostedDirectTransfer(TransferHeader: Record "Transfer Header"; Item: Record Item)
    var
        DirectTransferHeader: Record "Direct Trans. Header";
        DirectTransferLine: Record "Direct Trans. Line";
    begin
        DirectTransferHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        DirectTransferHeader.FindFirst();

        DirectTransferLine.SetRange("Document No.", DirectTransferHeader."No.");
        DirectTransferLine.SetRange("Item No.", Item."No.");
        DirectTransferLine.FindFirst();
        DirectTransferLine.TestField("Transfer-To Bin Code");
    end;

    local procedure CreatedDefaulBinContent(Location: Record Location; Item: Record Item; BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
    begin
        Location.TestField("Bin Mandatory");
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetRange("Unit of Measure Code", Item."Base Unit of Measure");
        if BinContent.FindFirst() then begin
            if BinCode <> '' then
                BinContent.TestField("Bin Code", BinCode);
            exit;
        end;

        if BinCode = '' then begin
            LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
            BinCode := Bin.Code;
        end;

        BinContent.Init();
        BinContent.Validate("Location Code", Location.Code);
        BinContent.Validate("Bin Code", BinCode);
        BinContent.Validate("Item No.", Item."No.");
        BinContent.Default := true;
        BinContent.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseReceiptAfterReleasedSalesReturnOrderExternalDocNoChanged()
    var
        SalesHeader: Record "Sales Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // [FEATURE] [Warehouse Receipt]
        // [SCENARIO 325564] "Vendor Shipment No." in Warehouse Receipt must be same as the latest "External Document No." in Source Sales Return Order when "External Document No." was modified after the release
        Initialize();

        // [GIVEN] Released Sales Return Order "S1"
        CreateAndReleaseSimpleSalesReturnOrder(SalesHeader, 1);

        // [GIVEN] "External Document No." on "S1" changed to "TESTAFTER"
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);

        // [WHEN] Create Warehouse Receipt for this Sales Return Order
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);

        // [THEN] "Vendor Shipment No." = "TESTAFTER" in Warehouse Receipt
        FindWarehouseReceiptHeaderBySource(
          WarehouseReceiptHeader, DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", -1);
        Assert.AreEqual(
          SalesHeader."External Document No.", WarehouseReceiptHeader."Vendor Shipment No.", WhsRcptHeaderVendorShpmntNoIsWrongErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseReceiptAfterReleasedPurchOrderExternalDocNoChanged()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // [FEATURE] [Warehouse Receipt]
        // [SCENARIO 325564] "Vendor Shipment No." in Warehouse Shipment must be same as the latest value in Source Purchase Order when "Vendor Shipment No." was modified after the release
        Initialize();

        // [GIVEN] Released Purchase Order "P1"
        CreateAndReleasePurchaseOrderWithItemTracking(PurchaseHeader, LibraryInventory.CreateItemNo(), LocationWhite.Code, 1, false);

        // [GIVEN] "Vendor Shipment No." on "P1" changed to "TESTAFTER"
        PurchaseHeader.Validate("Vendor Shipment No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // [WHEN] Create Warehouse Receipt for this Purchase Order
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] "Vendor Shipment No." = "TESTAFTER" in Warehouse Receipt
        FindWarehouseReceiptHeaderBySource(
          WarehouseReceiptHeader, DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", -1);
        Assert.AreEqual(
          PurchaseHeader."Vendor Shipment No.", WarehouseReceiptHeader."Vendor Shipment No.", WhsRcptHeaderVendorShpmntNoIsWrongErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseRequestReopenSalesOrderNegativeQuantity()
    var
        SalesHeader: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // [FEATURE] [Reopen] [Sales] [Order] [Warehouse Request]
        // [SCENARIO 329042] Inbound Warehouse Request for Sales Order Line with negative quantity has status "Open" when Sales Order is reopened
        Initialize();

        // [GIVEN] Released Sales Order "S1" with Sales Line for Quantity = -1
        CreateAndReleaseSalesOrder(
          SalesHeader, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo(), -1, LocationWhite.Code, '', false, ReservationMode::" ");

        // [WHEN] Reopen the Sales Order
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [THEN] Inbound warehouse request for the sales header has status "Open"
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetSourceFilter(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        WarehouseRequest.FindFirst();
        WarehouseRequest.TestField("Document Status", WarehouseRequest."Document Status"::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseRequestReopenSalesReturnOrderNegativeQuantity()
    var
        SalesHeader: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // [FEATURE] [Reopen] [Sales] [Return Order] [Warehouse Request]
        // [SCENARIO 329042] Outbound Warehouse Request for Sales Return Order Line with negative quantity has status "Open" when Sales Return Order is reopened
        Initialize();

        // [GIVEN] Released Return Sales Order "S1" with Sales Line for Quantity = -1
        CreateAndReleaseSimpleSalesReturnOrder(SalesHeader, -1);

        // [WHEN] Reopen the Sales Order
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [THEN] Outbound warehouse request for the sales header has status "Open"
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetSourceFilter(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        WarehouseRequest.FindFirst();
        WarehouseRequest.TestField("Document Status", WarehouseRequest."Document Status"::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseRequestReopenPurchOrderNegativeQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // [FEATURE] [Reopen] [Purchase] [Order] [Warehouse Request]
        // [SCENARIO 329042] Outbound Warehouse Request for Purchase Order Line with negative quantity has status "Open" when Purchase Order is reopened
        Initialize();

        // [GIVEN] Released Purchase Order "P1" with Purchase Line for Quantity = -1
        CreateAndReleasePurchaseOrderWithItemTracking(PurchaseHeader, LibraryInventory.CreateItemNo(), LocationWhite.Code, -1, false);

        // [WHEN] Reopen the Purchase Order
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [THEN] Outbound warehouse request for the Purchase header has status "Open"
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetSourceFilter(DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.");
        WarehouseRequest.FindFirst();
        WarehouseRequest.TestField("Document Status", WarehouseRequest."Document Status"::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseRequestReopenPurchReturnOrderNegativeQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // [FEATURE] [Reopen] [Purchase] [Return Order] [Warehouse Request]
        // [SCENARIO 329042] Inbound Warehouse Request for Purchase Return Order Line with negative quantity has status "Open" when Purchase Return Order is reopened
        Initialize();

        // [GIVEN] Released Return Purchase Order "P1" with Purchase Line for Quantity = -1
        CreateAndReleaseSimplePurchaseReturnOrder(PurchaseHeader, -1);

        // [WHEN] Reopen the Purchase Order
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [THEN] Inbound warehouse request for the Purchase header has status "Open"
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetSourceFilter(DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.");
        WarehouseRequest.FindFirst();
        WarehouseRequest.TestField("Document Status", WarehouseRequest."Document Status"::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyReceivedNotPutAwayTakesAvailQtyIntoConsideration()
    var
        Item: Record Item;
        Location: Record Location;
        ReceiptBin: Record Bin;
        ShipmentBin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Warehouse Pick] [Put-Away] [Purchase] [Receipt] [Credit-Memo]
        // [SCENARIO 351606] Creating pick when one of receipts was not put-away and reversed by posting credit-memo.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Location with required receipt, shipment, put-away and pick.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 5, false);
        LibraryWarehouse.FindBin(ReceiptBin, Location.Code, '', 2);
        LibraryWarehouse.FindBin(ShipmentBin, Location.Code, '', 3);

        Location.Validate("Receipt Bin Code", ReceiptBin.Code);
        Location.Validate("Shipment Bin Code", ShipmentBin.Code);
        Location.Modify(true);

        // [GIVEN] Create purchase order, release it, create warehouse receipt and post it.
        // [GIVEN] Delete the warehouse put-away without registering it.
        CreateAndReleasePurchaseOrderWithItemTracking(PurchaseHeader, Item."No.", Location.Code, Qty, false);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false, 0);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeader.Delete(true);

        // [GIVEN] Create purchase credit-memo and post it.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Item."No.", Location.Code, Qty, '', false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create another purchase order, release it, create and post warehouse receipt and put-away.
        CreateAndReleasePurchaseOrderWithItemTracking(PurchaseHeader, Item."No.", Location.Code, Qty, false);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false, 0);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Create sales order, release it, create warehouse shipment.
        CreateAndReleaseSalesOrder(SalesHeader, '', Item."No.", Qty, Location.Code, '', false, 0);
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);

        // [WHEN] Create pick from the warehouse shipment.
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [THEN] The pick is successfully created.
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.TestField(Quantity, Qty);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure RegisteringPickQtyWithItemTrackingSelectedOnPickAndQtyInShipBin()
    var
        Item: Record Item;
        BinPick: Record Bin;
        BinShip: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PickLotNo: Code[50];
        PickBinQty: Decimal;
        ShipBinQty: Decimal;
    begin
        // [FEATURE] [Warehouse Shipment] [Pick] [Item Tracking]
        // [SCENARIO 365391] Registering pick with item tracking selected on the pick line when there is quantity stored in shipment bin.
        Initialize();
        PickLotNo := LibraryUtility.GenerateGUID();
        PickBinQty := LibraryRandom.RandIntInRange(50, 100);
        ShipBinQty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Lot-tracked item.
        CreateItemWithLotItemTrackingCode(Item, true, '');

        // [GIVEN] Post 100 pcs into a bin in PICK zone, assign lot no. "L1".
        FindBinForPickZone(BinPick, LocationWhite.Code, true); // PICK zone
        CreateWarehouseJournalLine(WarehouseJournalLine, BinPick, Item, PickBinQty, '');
        LibraryVariableStorage.Enqueue(PickLotNo);
        LibraryVariableStorage.Enqueue(PickBinQty);
        WarehouseJournalLine.OpenItemTrackingLines();
        RegisterWhseJournalLineAndPostItemJournal(Item, BinPick);

        // [GIVEN] Post 10 pcs into a bin in SHIP zone, assign lot no. "L2".
        FindBinForShipZone(BinShip, LocationWhite.Code); // SHIP zone
        UpdateAndTrackInventoryUsingWhseJournal(BinShip, Item, ShipBinQty, '', WorkDate());

        // [GIVEN] Create sales order for 110 pcs.
        // [GIVEN] Release the sales order and create warehouse shipment.
        // [GIVEN] Create pick from the warehouse shipment.
        CreatePickFromSalesOrder(SalesHeader, '', Item."No.", PickBinQty + ShipBinQty, LocationWhite.Code, false, 0);

        // [GIVEN] Assign lot no. "L1" to the pick lines. Only quantity stored in PICK zone can be picked.
        FilterWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.ModifyAll("Lot No.", PickLotNo);

        // [WHEN] Register the pick.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // [THEN] 100 pcs have been picked.
        Item.CalcFields("Qty. Picked");
        Item.TestField("Qty. Picked", PickBinQty);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAsTrue')]
    procedure UndoShipmentWithWarehouseEntries()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        WarehouseEntry: Record "Warehouse Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Undo Shipment] [Invoice] [Sales]
        // [SCENARIO 410025] Undo Shipment posts warehouse entries if the shipment has not been invoiced.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Location with mandatory bin.
        CreateAndUpdateLocation(Location, false, false, false, false, true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Post 10 pcs to inventory.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin.Code, 2 * Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order for 10 pcs, set "Qty. to Ship" = 5.
        // [GIVEN] Ship 5 pcs, do not invoice.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 2 * Qty, Location.Code, WorkDate());
        SalesLine.Validate("Qty. to Ship", Qty);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Ensure the item's inventory = warehouse = 5 pcs.
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, Qty);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", Qty);

        // [WHEN] Locate the sales shipment line and invoke "Undo Shipment".
        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [THEN] The sales line is not shipped or invoiced.
        SalesLine.Find();
        SalesLine.TestField("Qty. to Ship", Salesline.Quantity);
        SalesLine.TestField("Quantity Shipped", 0);

        // [THEN] The item's both inventory and warehouse are back 10 pcs.
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 2 * Qty);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", 2 * Qty);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAsTrue')]
    procedure UndoShipmentWithWarehouseEntriesAfterCancelInvoice()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        WarehouseEntry: Record "Warehouse Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        Qty: Decimal;
    begin
        // [FEATURE] [Undo Shipment] [Invoice] [Sales]
        // [SCENARIO 410025] Undo Shipment does not post excessive warehouse entries if they were previously created by cancelling invoice.
        Initialize();
        LibrarySales.SetDefaultCancelReasonCodeForSalesAndReceivablesSetup();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Location with mandatory bin.
        CreateAndUpdateLocation(Location, false, false, false, false, true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Post 10 pcs to inventory.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin.Code, 2 * Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order for 10 pcs, set "Qty. to Ship" = 5.
        // [GIVEN] Ship and invoice 5 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 2 * Qty, Location.Code, WorkDate());
        SalesLine.Validate("Qty. to Ship", Qty);
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Cancel the posted invoice. That action reverses the shipment too.
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [GIVEN] Ensure the item's inventory = warehouse = 10 pcs.
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 2 * Qty);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", 2 * Qty);

        // [WHEN] Locate the sales shipment line and invoke "Undo Shipment".
        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [THEN] The sales line is not shipped or invoiced.
        SalesLine.Find();
        SalesLine.TestField("Qty. to Ship", Salesline.Quantity);
        SalesLine.TestField("Qty. to Invoice", SalesLine.Quantity);
        SalesLine.TestField("Quantity Shipped", 0);
        SalesLine.TestField("Quantity Invoiced", 0);

        // [THEN] The item's both inventory and warehouse remain 10 pcs.
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 2 * Qty);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", 2 * Qty);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple,CreatePickFromWhseShptReqHandler')]
    procedure ServiceOrderWarehouseShipmentWithNonInventoryServiceLines()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        NonInventoryItem: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine1: Record "Service Line";
        ServiceLine2: Record "Service Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReleaseWhseShipment: Codeunit "Whse.-Shipment Release";
        ServGetSourceDocOutbound: Codeunit "Serv. Get Source Doc. Outbound";
        WMSMgt: Codeunit "WMS Management";
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        // [SCENARIO] A service order containing inventory and non-inventory item both with a location can be processed
        // when warehouse pick and shipment is required.
        Initialize();

        // [GIVEN] A location requiring pick and shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);

        // [GIVEN] An inventory item in stock at location.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine,
          ItemJournalTemplate.Name,
          ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          Item."No.",
          1
        );
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify(true);
        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);

        // [GIVEN] A non-inventory item.
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A service order with a service item line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] A service line with inventory item and location.
        LibraryService.CreateServiceLineWithQuantity(ServiceLine1, ServiceHeader, ServiceLine1.Type::Item, Item."No.", 1);
        ServiceLine1.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine1.Validate("Location Code", Location.Code);
        ServiceLine1.Modify(true);

        // [GIVEN] A service line with non-inventory item and location.
        LibraryService.CreateServiceLineWithQuantity(ServiceLine2, ServiceHeader, ServiceLine2.Type::Item, NonInventoryItem."No.", 1);
        ServiceLine2.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine2.Validate("Location Code", Location.Code);
        ServiceLine2.Modify(true);

        // [WHEN] Creating a warehouse shipment for the service order.
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        ServGetSourceDocOutbound.CreateFromServiceOrderHideDialog(ServiceHeader);

        // [THEN] Only the inventory item is added to the shipment lines.
        WhseShptLine.SetRange("Location Code", Location.Code);
        Assert.AreEqual(1, WhseShptLine.Count(), 'Expected only one shipping line.');
        WhseShptLine.FindFirst();
        Assert.AreEqual(Item."No.", WhseShptLine."Item No.", 'Expected shipping line for inventory item.');

        // [WHEN] Creating pick for the warehouse shipment.
        WhseShptHeader.Get(WhseShptLine."No.");
        ReleaseWhseShipment.Release(WhseShptHeader);

        WhseShptLine.CreatePickDoc(WhseShptLine, WhseShptHeader);

        // [THEN] Only the inventory item is added to the pick lines.
        WhseActivityLine.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type"::Shipment);
        WhseActivityLine.SetRange("Whse. Document No.", WhseShptHeader."No.");
        Assert.AreEqual(1, WhseActivityLine.Count(), 'Expected only one pick line.');
        WhseActivityLine.FindFirst();
        Assert.AreEqual(Item."No.", WhseActivityLine."Item No.", 'Expected pick line for inventory item.');

        // [WHEN] Registering pick, posting shipment and service order.
        WhseActivityLine.AutofillQtyToHandle(WhseActivityLine);
        WMSMgt.CheckBalanceQtyToHandle(WhseActivityLine);
        WhseActivityRegister.ShowHideDialog(true);
        WhseActivityRegister.Run(WhseActivityLine);

        WhseShptLine.Reset();
        WhseShptLine.SetRange("Location Code", Location.Code);
        WhseShptLine.AutofillQtyToHandle(WhseShptLine);
        WhsePostShipment.SetPostingSettings(false);
        WhsePostShipment.SetPrint(false);
        WhsePostShipment.Run(WhseShptLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Only an shipment service ILE exists for the non-inventory item. 
        ItemLedgerEntry.SetRange("Item No.", NonInventoryItem."No.");
        Assert.AreEqual(1, ItemLedgerEntry.Count(), 'Expected only one ILE');
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(
            ItemLedgerEntry."Document Type"::"Service Shipment",
            ItemLedgerEntry."Document Type",
            'Expected ILE for service shipment'
        );
    end;

    [Test]
    procedure VerifyOpenWhseRequestLinesIsRemovedOnReleasedSalesOrderLines()
    var
        Item: Record Item;
        Location, Location2 : Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 459402] Verify Open Warehouse Request lines are removed on Release Sales Line, after Sales Lines are removed and recreated
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Locations with Require Put Away and Pick
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, false, false);
        LibraryWarehouse.CreateLocationWMS(Location2, false, true, true, false, false);

        // [GIVEN] Create and Release Sales Order
        CreateAndReleaseSalesOrderWithMultipleSalesLines(SalesHeader, '', Item."No.", Item."No.", 1, -1, Location.Code);

        // [GIVEN] Reopen the Sales Order
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [THEN] Verify Warehouse Request rec exist
        VerifyWarehouseRequestRec(Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", 2);

        // [GIVEN] Remove Sales Lines
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.DeleteAll(true);

        // [WHEN] Update Location on Sales Order, create new Sales Line and Release Sales Order
        SalesHeader.Validate("Location Code", Location2.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] Verify Warehouse Request lines are removed
        VerifyWarehouseRequestRec(Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyOpenWhseRequestLineIsRemovedOnReleasedPurchaseOrderLines()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 459402] Verify Open Warehouse Request lines are removed on delete Purchase Line, after Purchase Lines are removed and recreated
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Locations with Require Put Away and Pick
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, false, false);

        // [GIVEN] Create and Release Purchase Order
        CreateAndReleasePurchaseOrderWithMultiplePurchaseLines(PurchaseHeader, '', Item."No.", Item."No.", 1, 1, LocationGreen.Code);

        // [GIVEN] Reopen the Purchase Order
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [THEN] Verify Warehouse Request rec exist
        VerifyWarehouseRequestRec(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", 1);

        // [GIVEN] Remove Purchase Lines
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.DeleteAll(true);

        // [WHEN] Update Location on Purchase Order, create new Purchase Line and Release Purchase Order
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] Verify Warehouse Request lines are removed
        VerifyWarehouseRequestRec(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", 0);
    end;

    [Test]
    procedure PostWarehouseShipmentForOrderOnlyAttachedNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        i: Integer;
    begin
        // [FEATURE] [Attached to Line No] [Non-Inventory Item] [Sales] [Order] [Shipment]
        // [SCENARIO 456417] Automatic posting of attached non-inventory sales order lines using warehouse shipment.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in sales setup to "Attached/Assigned".
        UpdateNonInvtPostingPolicyInSalesSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);

        // [GIVEN] Create sales order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2". Attach "NI1" to "I1" and "NI2" to "I2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreateSalesDocumentWithVariousLines(
          SalesHeader, SalesHeader."Document Type"::Order, Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create warehouse shipment.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Set "Qty. to Ship" on warehouse shipment line for "I2" to zero.
        FindWarehouseShipmentHeaderFromSalesOrder(WarehouseShipmentHeader, SalesHeader."No.", Location.Code);
        UpdateQuantityOnWarehouseShipmentLineFromSalesOrder(SalesHeader."No.", Item[2]."No.", Location.Code, '', 0);

        // [WHEN] Post the warehouse shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Item line "I1" is fully shipped.
        // [THEN] Item line "I2" is not shipped.
        FindSalesLine(SalesLine, SalesHeader, Item[1]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, Item[2]."No.");
        SalesLine.TestField("Quantity Shipped", 0);

        // [THEN] Non-inventory line "NI1" is fully shipped.
        // [THEN] Non-inventory line "NI2" is not shipped.
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[1]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[2]."No.");
        SalesLine.TestField("Quantity Shipped", 0);

        // [THEN] Item charge line "IC1" is shipped for half quantity.
        // [THEN] Item charge line "IC2" is shipped for half quantity.
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[1]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity / 2);
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[2]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple')]
    procedure PostInventoryPickForOrderOnlyAttachedNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        // [FEATURE] [Attached to Line No] [Non-Inventory Item] [Sales] [Order] [Inventory Pick]
        // [SCENARIO 456417] Automatic posting of attached non-inventory sales order lines using inventory pick.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in sales setup to "Attached/Assigned".        
        UpdateNonInvtPostingPolicyInSalesSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required pick.        
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Post items to inventory.
        for i := 1 to 2 do
            CreateAndPostItemJournalLine(
              Item[i]."No.", "Item Ledger Entry Type"::"Positive Adjmt.", LibraryRandom.RandIntInRange(50, 100), Location.Code);

        // [GIVEN] Create sales order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2". Attach "NI1" to "I1" and "NI2" to "I2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreateSalesDocumentWithVariousLines(
          SalesHeader, SalesHeader."Document Type"::Order, Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create inventory pick.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [GIVEN] Set "Qty. to Handle" on inventory pick line for "I2" to zero.
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick");
        UpdateQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", Item[2]."No.", 0);

        // [WHEN] Post the inventory pick.
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", false);

        // [THEN] Item line "I1" is fully shipped.
        // [THEN] Item line "I2" is not shipped.
        FindSalesLine(SalesLine, SalesHeader, Item[1]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, Item[2]."No.");
        SalesLine.TestField("Quantity Shipped", 0);

        // [THEN] Non-inventory line "NI1" is fully shipped.
        // [THEN] Non-inventory line "NI2" is not shipped.
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[1]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[2]."No.");
        SalesLine.TestField("Quantity Shipped", 0);

        // [THEN] Item charge line "IC1" is shipped for half quantity.
        // [THEN] Item charge line "IC2" is shipped for half quantity.
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[1]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity / 2);
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[2]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity / 2);
    end;

    [Test]
    procedure PostWarehouseReceiptForReturnOrderOnlyAttachedNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        i: Integer;
    begin
        // [FEATURE] [Attached to Line No] [Non-Inventory Item] [Sales] [Return Order] [Receipt]
        // [SCENARIO 456417] Automatic posting of attached non-inventory sales return order lines using warehouse shipment.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in sales setup to "Attached/Assigned".
        UpdateNonInvtPostingPolicyInSalesSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required receipt.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);

        // [GIVEN] Create sales return order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2". Attach "NI1" to "I1" and "NI2" to "I2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreateSalesDocumentWithVariousLines(
          SalesHeader, SalesHeader."Document Type"::"Return Order", Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create warehouse receipt.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);

        // [GIVEN] Set "Qty. to Receive" on warehouse receipt line for "I2" to zero.
        FindWarehouseReceiptHeaderFromSalesReturnOrder(WarehouseReceiptHeader, SalesHeader."No.", Location.Code);
        UpdateQuantityOnWarehouseReceiptLineFromSalesReturnOrder(SalesHeader."No.", Item[2]."No.", Location.Code, '', 0);

        // [WHEN] Post the warehouse receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Item line "I1" is fully received.
        // [THEN] Item line "I2" is not received.
        FindSalesLine(SalesLine, SalesHeader, Item[1]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, Item[2]."No.");
        SalesLine.TestField("Return Qty. Received", 0);

        // [THEN] Non-inventory line "NI1" is fully received.
        // [THEN] Non-inventory line "NI2" is not received.
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[1]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[2]."No.");
        SalesLine.TestField("Return Qty. Received", 0);

        // [THEN] Item charge line "IC1" is received for half quantity.
        // [THEN] Item charge line "IC2" is received for half quantity.
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[1]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity / 2);
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[2]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple')]
    procedure PostInventoryPutawayForReturnOrderOnlyAttachedNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        // [FEATURE] [Attached to Line No] [Non-Inventory Item] [Sales] [Return Order] [Inventory Put-away]
        // [SCENARIO 456417] Automatic posting of attached non-inventory sales return order lines using inventory put-away.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in sales setup to "Attached/Assigned".
        UpdateNonInvtPostingPolicyInSalesSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required put-away.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Create sales return order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2". Attach "NI1" to "I1" and "NI2" to "I2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreateSalesDocumentWithVariousLines(
          SalesHeader, SalesHeader."Document Type"::"Return Order", Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create inventory put-away.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [GIVEN] Set "Qty. to Handle" on inventory put-away line for "I2" to zero.
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        UpdateQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away", Item[2]."No.", 0);

        // [WHEN] Post the inventory put-away.
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away", false);

        // [THEN] Item line "I1" is fully received.
        // [THEN] Item line "I2" is not received.
        FindSalesLine(SalesLine, SalesHeader, Item[1]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, Item[2]."No.");
        SalesLine.TestField("Return Qty. Received", 0);

        // [THEN] Non-inventory line "NI1" is fully received.
        // [THEN] Non-inventory line "NI2" is not received.
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[1]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[2]."No.");
        SalesLine.TestField("Return Qty. Received", 0);

        // [THEN] Item charge line "IC1" is received for half quantity.
        // [THEN] Item charge line "IC2" is received for half quantity.
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[1]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity / 2);
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[2]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity / 2);
    end;

    [Test]
    procedure PostWarehouseShipmentForOrderAllNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        i: Integer;
    begin
        // [FEATURE] [Attached to Line No] [Non-Inventory Item] [Sales] [Order] [Shipment]
        // [SCENARIO 456417] Automatic posting of all non-inventory sales order lines using warehouse shipment.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in sales setup to "All".
        UpdateNonInvtPostingPolicyInSalesSetup("Non-Invt. Item Whse. Policy"::All);

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);

        // [GIVEN] Create sales order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreateSalesDocumentWithVariousLines(
          SalesHeader, SalesHeader."Document Type"::Order, Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create warehouse shipment.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Set "Qty. to Ship" on warehouse shipment line for "I2" to zero.
        FindWarehouseShipmentHeaderFromSalesOrder(WarehouseShipmentHeader, SalesHeader."No.", Location.Code);
        UpdateQuantityOnWarehouseShipmentLineFromSalesOrder(SalesHeader."No.", Item[2]."No.", Location.Code, '', 0);

        // [WHEN] Post the warehouse shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Item line "I1" is fully shipped.
        // [THEN] Item line "I2" is not shipped.
        FindSalesLine(SalesLine, SalesHeader, Item[1]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, Item[2]."No.");
        SalesLine.TestField("Quantity Shipped", 0);

        // [THEN] Non-inventory line "NI1" is fully shipped.
        // [THEN] Non-inventory line "NI2" is fully shipped.
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[1]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[2]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);

        // [THEN] Item charge line "IC1" is fully shipped.
        // [THEN] Item charge line "IC2" is fully shipped.
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[1]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[2]."No.");
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple')]
    procedure PostInventoryPutawayForReturnOrderAllNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        // [FEATURE] [Attached to Line No] [Non-Inventory Item] [Sales] [Return Order] [Inventory Put-away]
        // [SCENARIO 456417] Automatic posting of all non-inventory sales return order lines using inventory put-away.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in sales setup to "All".
        UpdateNonInvtPostingPolicyInSalesSetup("Non-Invt. Item Whse. Policy"::All);

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required put-away.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Create sales return order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreateSalesDocumentWithVariousLines(
          SalesHeader, SalesHeader."Document Type"::"Return Order", Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create inventory put-away.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [GIVEN] Set "Qty. to Handle" on inventory put-away line for "I2" to zero.
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        UpdateQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away", Item[2]."No.", 0);

        // [WHEN] Post the inventory put-away.
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away", false);

        // [THEN] Item line "I1" is fully received.
        // [THEN] Item line "I2" is not received.
        FindSalesLine(SalesLine, SalesHeader, Item[1]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, Item[2]."No.");
        SalesLine.TestField("Return Qty. Received", 0);

        // [THEN] Non-inventory line "NI1" is fully received.
        // [THEN] Non-inventory line "NI2" is fully received.
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[1]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, NonInvtItem[2]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity);

        // [THEN] Item charge line "IC1" is fully received.
        // [THEN] Item charge line "IC2" is fully received.
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[1]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity);
        FindSalesLine(SalesLine, SalesHeader, ItemCharge[2]."No.");
        SalesLine.TestField("Return Qty. Received", SalesLine.Quantity);
    end;

    [Test]
    procedure VerifyWhseRequestLineIsNotCreatedForNonInventoryItemOnReleasePurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 465042] Verify Whse Request Line is not created for Non Inventory Item on Release Purchase Order
        Initialize();

        // [GIVEN] Create Non Inventory Item
        LibraryInventory.CreateNonInventoryTypeItem(Item);

        // [WHEN] Create and Release Purchase Order
        CreateAndReleasePurchaseOrderWithMultiplePurchaseLines(PurchaseHeader, '', Item."No.", '', 1, 0, LocationGreen.Code);

        // [THEN] Verify Warehouse Request rec not exist
        VerifyWarehouseRequestRec(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", 0);
    end;

    [Test]
    procedure VerifyWhseRequestLineIsNotCreatedForNonInventoryItemOnReleaseSalesOrder()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 465042] Verify Whse Request Line is not created for Non Inventory Item on Release Sales Order
        Initialize();

        // [GIVEN] Create Non Inventory Item
        LibraryInventory.CreateNonInventoryTypeItem(Item);

        // [GIVEN] Create Locations with Require Put Away and Pick
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, false, false);

        // [WHEN] Create and Release Sales Order
        CreateAndReleaseSalesOrderWithMultipleSalesLines(SalesHeader, '', Item."No.", '', 1, 0, Location.Code);

        // [THEN] Verify Warehouse Request rec not exist
        VerifyWarehouseRequestRec(Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,UndoShipmentConfirmHandler')]
    procedure S466089_UndoSalesShipmentLineIsAllowedForPartOfQtyShippedWithoutInventoryPick()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        PostedShipmentNo: Code[20];
    begin
        // [FEATURE] [Item] [Sales Order] [Inventory Pick] [Undo Sales Shipment Line]
        // [SCENARIO 466089] Undo Sales Shipment Line is allowed for part of Quantity shipped without Inventory Pick.
        Initialize();

        // [GIVEN] Location set up for Inventory Pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Post 1 Qty. of Item to inventory.
        CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 1, Location.Code);

        // [GIVEN] Create and release Sales Order with Quantity = 3.
        CreateAndReleaseSalesOrder(SalesHeader, '', Item."No.", 3, Location.Code, '', false, ReservationMode::" ");

        // [GIVEN] Create Inventory Pick from the Sales Order.
        LibraryVariableStorage.Enqueue(InvPickMsg); // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader); // Uses MessageHandler.
        FindWarehouseActivityLine(
            WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
            WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);

        // [GIVEN] Post the Inventory Pick with Quantity = 1
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [WHEN] The Sales Shipment from Sales Order for remaining Quantity = 2.
        SalesHeader.GetBySystemId(SalesHeader.SystemId);
        PostedShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Verify that all Sales Shipment Qty. is posted.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);

        // [WHEN] Undo the 2nd Sales Shipment.
        SalesShipmentLine.SetRange("Document No.", PostedShipmentNo);
        SalesShipmentLine.FindFirst();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine); // Uses UndoShipmentConfirmHandler.

        // [THEN] No Error is raised.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure GetShipmentLinesInSalesInvoiceWithAttachedNonInvtLine()
    var
        Item: Record Item;
        NonInvtItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineNonInvtItem: Record "Sales Line";
    begin
        // [FEATURE] [Non-Inventory Item] [Sales] [Order] [Invoice] [Get Shipment Lines]
        // [SCENARIO 477047] Get Shipment Lines in Sales Invoice with attached non-inventory line does not produce duplicate lines.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in sales setup to "Attached/Assigned".
        UpdateNonInvtPostingPolicyInSalesSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create item and non-inventory item.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem);

        // [GIVEN] Create sales order with two lines: item and non-inventory item.
        // [GIVEN] Attach the non-inventory item to the item line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(
          SalesLineItem, SalesHeader, SalesLineItem.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        LibrarySales.CreateSalesLine(
          SalesLineNonInvtItem, SalesHeader, SalesLineNonInvtItem.Type::Item, NonInvtItem."No.", LibraryRandom.RandInt(10));
        SalesLineNonInvtItem."Attached to Line No." := SalesLineItem."Line No.";
        SalesLineNonInvtItem.Modify();

        // [GIVEN] Post the sales order as Ship.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Create sales invoice using "Get Shipment Lines".
        CreateSalesInvoiceFromShipment(SalesHeaderInvoice, SalesHeader);

        // [THEN] Sales invoice has two lines: item and non-inventory item.
        // [THEN] No duplicate lines.
        FindSalesLine(SalesLineNonInvtItem, SalesHeaderInvoice, NonInvtItem."No.");
        Assert.RecordCount(SalesLineNonInvtItem, 1);
        FindSalesLine(SalesLineNonInvtItem, SalesHeaderInvoice, Item."No.");
        Assert.RecordCount(SalesLineNonInvtItem, 1);
    end;

    [Test]
    procedure GetReturnReceiptLinesInSalesCrMemoWithAttachedNonInvtLine()
    var
        Item: Record Item;
        NonInvtItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeaderCrMemo: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineNonInvtItem: Record "Sales Line";
    begin
        // [FEATURE] [Non-Inventory Item] [Sales] [Return Order] [Credit Memo] [Get Return Receipt Lines]
        // [SCENARIO 477047] Get Return Receipt Lines in Sales Credit Memo with attached non-inventory line does not produce duplicate lines.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in sales setup to "Attached/Assigned".
        UpdateNonInvtPostingPolicyInSalesSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create item and non-inventory item.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem);

        // [GIVEN] Create sales return order with two lines: item and non-inventory item.
        // [GIVEN] Attach the non-inventory item to the item line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        LibrarySales.CreateSalesLine(
          SalesLineItem, SalesHeader, SalesLineItem.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        LibrarySales.CreateSalesLine(
          SalesLineNonInvtItem, SalesHeader, SalesLineNonInvtItem.Type::Item, NonInvtItem."No.", LibraryRandom.RandInt(10));
        SalesLineNonInvtItem."Attached to Line No." := SalesLineItem."Line No.";
        SalesLineNonInvtItem.Modify();

        // [GIVEN] Post the sales return as Receive.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Create sales credit memo using "Get Return Receipt Lines".
        CreateSalesCrMemoFromReturnReceipt(SalesHeaderCrMemo, SalesHeader);

        // [THEN] Sales credit memo has two lines: item and non-inventory item.
        // [THEN] No duplicate lines.
        FindSalesLine(SalesLineNonInvtItem, SalesHeaderCrMemo, NonInvtItem."No.");
        Assert.RecordCount(SalesLineNonInvtItem, 1);
        FindSalesLine(SalesLineNonInvtItem, SalesHeaderCrMemo, Item."No.");
        Assert.RecordCount(SalesLineNonInvtItem, 1);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse - Shipping III");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        Clear(ItemTrackingMode);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse - Shipping III");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        CreateLocationSetup();
        CreateTransferRoute();
        NoSeriesSetup();
        ItemJournalSetup();

        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        LibrarySetupStorage.Save(Database::"Inventory Setup");
        LibrarySetupStorage.Save(Database::"Warehouse Setup");
        LibrarySetupStorage.SaveSalesSetup();

        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse - Shipping III");
    end;

    local procedure WarehousePickAccordingToFEFOWithSerialItemTracking(DifferentExpirationDate: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        OldPickAccordingToFEFO: Boolean;
    begin
        // Update Pick According to FEFO on Location. Create and register Put Away from Purchase Order using Serial with Strict Expiration Item Tracking.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, true);
        CreateItemWithSerialItemTrackingCodeUsingStrictExpiration(Item, true);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        Quantity := LibraryRandom.RandInt(5);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignAutoSerialNo);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateAndRegisterPutAwayFromPurchaseOrder(
          Bin, ItemTrackingMode::AssignAutoSerialNo, Item."No.", LocationWhite.Code, Quantity + Quantity, WorkDate(), true,
          DifferentExpirationDate);  // Value required for test and Tracking as True.

        // Exercise.
        CreatePickFromSalesOrder(SalesHeader, '', Item."No.", Quantity, LocationWhite.Code, true, ReservationMode::" ");  // Use Tracking as True.

        // Verify.
        if DifferentExpirationDate then begin
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity);
        end else begin
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);  // Use 0 for same expiration date verification.
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity);  // Use 0 for same expiration date verification.
        end;

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    local procedure WarehousePickAccordingToFEFOWithLotAndSerialItemTracking(DifferentExpirationDate: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        OldPickAccordingToFEFO: Boolean;
        ExpirationDate: Date;
    begin
        // Update Pick According to FEFO on Location. Create and register Put Away from Purchase Order using Lot and Serial with Strict Expiration Item Tracking.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, true);
        CreateItemWithLotAndSerialItemTrackingCodeUsingStrictExpiration(Item);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        Quantity := LibraryRandom.RandInt(5);
        ExpirationDate := WorkDate();
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialAndLotNos);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateAndRegisterPutAwayFromPurchaseOrder(
          Bin, ItemTrackingMode::AssignSerialAndLotNos, Item."No.", LocationWhite.Code, Quantity, ExpirationDate, true, true);  // Use DifferentExpirationDate and Tracking as True.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialAndLotNos);  // Enqueue for ItemTrackingLinesPageHandler.
        if DifferentExpirationDate then
            ExpirationDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        CreateAndRegisterPutAwayFromPurchaseOrder(
          Bin, ItemTrackingMode::AssignSerialAndLotNos, Item."No.", LocationWhite.Code, Quantity, ExpirationDate, true, true);  // Use DifferentExpirationDate and Tracking as True.

        // Exercise.
        CreatePickFromSalesOrder(SalesHeader, '', Item."No.", Quantity, LocationWhite.Code, true, ReservationMode::" ");  // Tracking as True.

        // Verify.
        if DifferentExpirationDate then begin
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity);
        end else begin
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);  // Use 0 for same expiration date verification.
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity);  // Use 0 for same expiration date verification.
        end;

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    local procedure InventoryPickAccordingToFEFOWithSerialItemTracking(DifferentExpirationDate: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        OldPickAccordingToFEFO: Boolean;
        Quantity: Decimal;
    begin
        // Update Pick According to FEFO on Location. Create and post Item Journal Line using Serial with Strict Expiration Item Tracking.
        UpdatePickAccordingToFEFOOnLocation(LocationSilver, OldPickAccordingToFEFO, true);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateItemWithSerialItemTrackingCodeUsingStrictExpiration(Item, true);
        Quantity := LibraryRandom.RandInt(5);
        CreateAndPostItemJournalLineWithItemTracking(
          Bin."Location Code", Bin.Code, Item."Base Unit of Measure", ItemTrackingMode::AssignAutoSerialNo, Item."No.", Quantity + Quantity,
          WorkDate(), DifferentExpirationDate, false);  // Value required for test.

        // Exercise.
        CreateInventoryPickFromSalesOrderUsingItemTracking(SalesHeader, Item."No.", LocationSilver.Code, Quantity);

        // Verify.
        if DifferentExpirationDate then
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Source Document"::"Sales Order",
              SalesHeader."No.", WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity)
        else
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Source Document"::"Sales Order",
              SalesHeader."No.", WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);  // Use 0 for same expiration date verification.

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationSilver, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    local procedure InventoryPickAccordingToFEFOWithLotAndSerialItemTracking(DifferentExpirationDate: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        OldPickAccordingToFEFO: Boolean;
        Quantity: Decimal;
        ExpirationDate: Date;
    begin
        // Update Pick According to FEFO on Location. Create and post Item Journal Line using Lot and Serial with Strict Expiration Item Tracking.
        UpdatePickAccordingToFEFOOnLocation(LocationSilver, OldPickAccordingToFEFO, true);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateItemWithLotAndSerialItemTrackingCodeUsingStrictExpiration(Item);
        Quantity := LibraryRandom.RandInt(5);
        ExpirationDate := WorkDate();
        CreateAndPostItemJournalLineWithItemTracking(
          Bin."Location Code", Bin.Code, Item."Base Unit of Measure", ItemTrackingMode::AssignSerialAndLotNos, Item."No.", Quantity,
          ExpirationDate, true, false);  // Use DifferentExpirationDate as True.
        if DifferentExpirationDate then
            ExpirationDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        CreateAndPostItemJournalLineWithItemTracking(
          Bin."Location Code", Bin.Code, Item."Base Unit of Measure", ItemTrackingMode::AssignSerialAndLotNos, Item."No.", Quantity,
          ExpirationDate, true, false);  // Use DifferentExpirationDate as True.

        // Exercise.
        CreateInventoryPickFromSalesOrderUsingItemTracking(SalesHeader, Item."No.", LocationSilver.Code, Quantity);

        // Verify.
        if DifferentExpirationDate then
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Source Document"::"Sales Order",
              SalesHeader."No.", WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity)
        else
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Source Document"::"Sales Order",
              SalesHeader."No.", WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);  // Use 0 for same expiration date verification.

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationSilver, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    local procedure InventoryPickAccordingToFEFOWithLotItemTracking(DifferentExpirationDate: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        OldPickAccordingToFEFO: Boolean;
        Quantity: Decimal;
        ExpirationDate: Date;
    begin
        // Update Pick According to FEFO on Location. Create and post Item Journal Line using Lot with Strict Expiration Item Tracking.
        UpdatePickAccordingToFEFOOnLocation(LocationSilver, OldPickAccordingToFEFO, true);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateItemWithLotItemTrackingCodeUsingStrictExpiration(Item);
        Quantity := LibraryRandom.RandInt(5);
        ExpirationDate := WorkDate();
        CreateAndPostItemJournalLineWithItemTracking(
          Bin."Location Code", Bin.Code, Item."Base Unit of Measure", ItemTrackingMode::AssignLotNo, Item."No.", Quantity, ExpirationDate,
          true, false);  // Use DifferentExpirationDate as True.
        if DifferentExpirationDate then
            ExpirationDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        CreateAndPostItemJournalLineWithItemTracking(
          Bin."Location Code", Bin.Code, Item."Base Unit of Measure", ItemTrackingMode::AssignLotNo, Item."No.", Quantity, ExpirationDate,
          true, false);  // Use DifferentExpirationDate as True.

        // Exercise.
        CreateInventoryPickFromSalesOrderUsingItemTracking(SalesHeader, Item."No.", LocationSilver.Code, Quantity);

        // Verify: Use 1 and 0 for NextCount required for test.
        if DifferentExpirationDate then
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Source Document"::"Sales Order",
              SalesHeader."No.", WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity)
        else
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Source Document"::"Sales Order",
              SalesHeader."No.", WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);  // Use 0 for same expiration date verification.

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationSilver, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    local procedure MovementAccordingToFEFOWithItemTracking(DifferentExpirationDate: Boolean; UseSerialNo: Boolean; UseLotNo: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        OldPickAccordingToFEFO: Boolean;
        ExpirationDate: Date;
    begin
        // Update Pick According to FEFO on Location. Create and register Put Away from Purchase Order using Lot and Serial with Strict Expiration Item Tracking.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, true);
        case true of
            UseLotNo and UseSerialNo:
                CreateItemWithLotAndSerialItemTrackingCodeUsingStrictExpiration(Item);
            UseLotNo and not UseSerialNo:
                CreateItemWithLotItemTrackingCodeUsingStrictExpiration(Item);
            not UseLotNo and UseSerialNo:
                CreateItemWithSerialItemTrackingCodeUsingStrictExpiration(Item, true);
        end;

        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        Quantity := LibraryRandom.RandInt(5);
        ExpirationDate := WorkDate();
        if DifferentExpirationDate then
            ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());

        case true of
            UseLotNo and UseSerialNo:
                begin
                    LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignAutoLotAndSerialNo);  // Enqueue for ItemTrackingLinesPageHandler.
                    CreateAndRegisterPutAwayFromPurchaseOrder(
                      Bin, ItemTrackingMode::AssignAutoLotAndSerialNo, Item."No.", LocationWhite.Code, Quantity, ExpirationDate, true, false);  // Use Tracking as True.
                    LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignAutoLotAndSerialNo);  // Enqueue for ItemTrackingLinesPageHandler.
                    CreateAndRegisterPutAwayFromPurchaseOrder(
                      Bin, ItemTrackingMode::AssignAutoLotAndSerialNo, Item."No.", LocationWhite.Code, Quantity, WorkDate(), true, false);  // Use Tracking as True.
                end;
            UseLotNo and not UseSerialNo:
                begin
                    LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
                    CreateAndRegisterPutAwayFromPurchaseOrder(
                      Bin, ItemTrackingMode::AssignLotNo, Item."No.", LocationWhite.Code, Quantity, ExpirationDate, true, false);  // Use Tracking as True.
                    LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
                    CreateAndRegisterPutAwayFromPurchaseOrder(
                      Bin, ItemTrackingMode::AssignLotNo, Item."No.", LocationWhite.Code, Quantity, WorkDate(), true, false);  // Use Tracking as True.
                end;
            not UseLotNo and UseSerialNo:
                begin
                    LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignAutoSerialNo);  // Enqueue for ItemTrackingLinesPageHandler.
                    CreateAndRegisterPutAwayFromPurchaseOrder(
                      Bin, ItemTrackingMode::AssignAutoSerialNo, Item."No.", LocationWhite.Code, Quantity, ExpirationDate, true, false);  // Use Tracking as True.
                    LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignAutoSerialNo);  // Enqueue for ItemTrackingLinesPageHandler.
                    CreateAndRegisterPutAwayFromPurchaseOrder(
                      Bin, ItemTrackingMode::AssignAutoSerialNo, Item."No.", LocationWhite.Code, Quantity, WorkDate(), true, false);  // Use Tracking as True.
                end;
        end;

        // Exercise.
        CreateMovementWithMovementWorksheetLine(Bin, Item."No.", Quantity);

        // Verify.
        if DifferentExpirationDate then begin
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."Source Document"::" ", '',
              WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."Source Document"::" ", '',
              WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity);
        end else begin
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."Source Document"::" ", '',
              WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);  // Use 0 for same expiration date verification.
            VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(
              WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."Source Document"::" ", '',
              WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity);  // Use 0 for same expiration date verification.
        end;

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    local procedure FEFOPickWhenNoStockAvailableVerify(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; AddQty: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateAndReleaseSalesOrder(
          SalesHeader, '', ItemNo, (Quantity / 2) + AddQty, LocationWhite.Code, '', false, ReservationMode::AutoReserve);
        Clear(SalesHeader);
        CreateAndReleaseSalesOrder(
          SalesHeader, '', ItemNo, (Quantity / 2) + AddQty, LocationWhite.Code, '', false, ReservationMode::" ");
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        VerifyQtyToPickEqualsTo(ItemNo, (Quantity / 2) - AddQty);
    end;

    local procedure ItemTrackingWithSerialSpecific(AssemblyItem: Record Item; Quantity: Decimal; ShipmentQuantity: Decimal; ItemTrackingForAssHeader: Option)
    var
        ChildItem: Record Item;
    begin
        CreateItemWithSerialItemTrackingCodeUsingStrictExpiration(ChildItem, false);
        QuantityAfterUndoSalesShipmentLine(AssemblyItem, ChildItem, Quantity, ShipmentQuantity,
          ItemTrackingMode::AssignAutoSerialNo, ItemTrackingForAssHeader);
    end;

    local procedure ItemTrackingWithLotSpecific(AssemblyItem: Record Item; Quantity: Decimal; ShipmentQuantity: Decimal; ItemTrackingForAssHeader: Option)
    var
        ChildItem: Record Item;
    begin
        CreateItemWithLotItemTrackingCode(ChildItem, true, '');
        UpdateLotNoOnItem(ChildItem);
        QuantityAfterUndoSalesShipmentLine(AssemblyItem, ChildItem, Quantity, ShipmentQuantity,
          ItemTrackingMode::AssignLotNo, ItemTrackingForAssHeader);
    end;

    local procedure AssignNoOnWhseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; AssemblyHeaderNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, ItemNo);
        FilterWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Assembly Consumption", AssemblyHeaderNo, WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Serial No.", ItemLedgerEntry."Serial No.");
            WarehouseActivityLine.Validate("Lot No.", ItemLedgerEntry."Lot No.");
            WarehouseActivityLine.Modify(true);
            WarehouseActivityLine.Next();
            WarehouseActivityLine.Validate("Serial No.", ItemLedgerEntry."Serial No.");
            WarehouseActivityLine.Validate("Lot No.", ItemLedgerEntry."Lot No.");
            WarehouseActivityLine.Modify(true);
            ItemLedgerEntry.Next();
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure AssignNoOnAsmHeader(ItemNo: Code[20]; ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,AssignSerialNo,ApplyFromItemEntry,AssignAutoSerialNo,AssignAutoLotAndSerialNo)
    var
        AssemblyHeader: Record "Assembly Header";
        LotNo: Variant;
    begin
        AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.SetRange("Item No.", ItemNo);
        AssemblyHeader.FindFirst();
        if ItemTrackingMode = ItemTrackingMode::AssignLotNo then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
            AssemblyHeader.OpenItemTrackingLines();
            LibraryVariableStorage.Dequeue(LotNo);
        end else begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);
            AssemblyHeader.OpenItemTrackingLines();
        end;
    end;

    local procedure QuantityAfterUndoSalesShipmentLine(AssemblyItem: Record Item; ChildItem: Record Item; Quantity: Decimal; ShipmentQuantity: Decimal; ItemTrackingForWhseReceipt: Option; ItemTrackingForAsmHeader: Option)
    var
        BOMComponent: Record "BOM Component";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LibraryAssembly: Codeunit "Library - Assembly";
        ReservationMode: Option " ",ReserveFromCurrentLine,AutoReserve;
        AssemblyHeaderNo: Code[20];
    begin
        // Setup: Create an Assembly Item with Component Item having Serial Item Tracking.
        LibraryAssembly.CreateAssemblyListComponent(BOMComponent.Type::Item,
          ChildItem."No.", AssemblyItem."No.", '', BOMComponent."Resource Usage Type", 1, true);

        // Create and Release Purchase Order.Create and Post Warehouse Receipt from Purchase Order.
        CreateAndReleasePurchaseOrderWithItemTracking(PurchaseHeader, ChildItem."No.", LocationWhite.Code, Quantity, false);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, true, ItemTrackingForWhseReceipt);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Create Sales Document.Realease ant Pick created Assembly Order.
        LibraryVariableStorage.Enqueue(StrSubstNo(AssemblyOrderMsg, WorkDate() - 1, WorkDate()));
        LibraryVariableStorage.Enqueue(StrSubstNo(AssemblyOrderMsg, WorkDate() - 1, WorkDate()));
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, '',
          AssemblyItem."No.", ShipmentQuantity, LocationWhite.Code, '', false, ReservationMode);
        AssemblyHeaderNo := ReleaseAndCreateWhsePickFromAsmHeader(AssemblyItem."No.");

        // Assign Serial No on Activity Lines and Lotno. on Assembly Header.
        AssignNoOnWhseActivityLines(WarehouseActivityLine, ChildItem."No.", AssemblyHeaderNo);
        RegisterWhseActivityAfterAutofillingQtyToHandle(WarehouseActivityLine);
        AssignNoOnAsmHeader(AssemblyItem."No.", ItemTrackingForAsmHeader);

        // Release created Sales order ,create Warehouse Shipment from Sales Header and Post Whse Shipment after updating Qty. to ship.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);
        UpdateQtyToShipAndPostWhseShipment(SalesHeader."No.", ShipmentQuantity);

        // Exercise: Undo Posted Warehouse shipmentLines.
        UndoSaleShipmentLine(SalesHeader."No.");

        // Verify: Verifying Quantity on Bin Content and Postive Adjmt Qty on Warehouse Entry of Child Item.
        ChildItem.CalcFields(Inventory);
        Assert.AreEqual(ChildItem.Inventory, CalcQuantityOnBinContent(LocationWhite.Code, ChildItem."No."), ValueMustBeEqualTxt);
        Assert.AreEqual(ShipmentQuantity,
          GetPostiveAdjmtQtyFromWarehouseEntry(ChildItem."No.", LocationWhite.Code, AssemblyHeaderNo), ValueMustBeEqualTxt);
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateLocationWMS(LocationOrange, true, true, true, true, true);  // With Require Put Away, Require Pick, Require Receive, Require Shipment and Bin Mandatory.
        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, false, true, false, false);  // With Require Pick and Bin Mandatory.
        LibraryWarehouse.CreateLocationWMS(LocationBlack, true, false, true, false, true);  // With Require Pick, Require Shipment and Bin Mandatory.
        LibraryWarehouse.CreateLocationWMS(LocationYellow, false, true, true, true, true);  // With Require Receive, Require Put Away, Require Shipment and Require Pick.
        LibraryWarehouse.CreateLocationWMS(LocationGreen, false, true, false, true, false);  // With Required Receive and Require Put Away.
        LibraryWarehouse.CreateLocationWMS(LocationRed, false, true, false, false, false);  // With Require Put Away.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationOrange.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationBlack.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationYellow.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationOrange.Code, '', '', 2, false);  // Value required for No. of Bins.
    end;

    local procedure CalcQuantityOnBinContent(LocationCode: Code[20]; ItemNo: Code[20]) BinContentQuantity: Decimal
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindSet();
        repeat
            BinContent.CalcFields(Quantity);
            BinContentQuantity += BinContent.Quantity;
        until BinContent.Next() = 0;
        exit(BinContentQuantity);
    end;

    local procedure CorrectionQuantityForLotInReportServiceShipment(UndoOption: Option)
    var
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: array[3] of Code[20];
        DocumentNo: Code[20];
        Quantity: array[3] of Decimal;
        i: Integer;
    begin
        // Test to verify Correction Quantity is correct for Lot tracking line in Report 5913 (Service - Shipment)

        // Setup: Create and post a Purchase Order with 2 lines with different Lot Tracking
        // 1st Line: Quantity[2], Lot[2]
        // 2nd Line: Quantity[2], Lot[3]
        Initialize();
        SalesReceivablesSetup.Get();
        UpdateSalesReceivableSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning", false);
        PostPurchaseOrderWithTwoLot(Item, Quantity, LotNo, true, false);

        // Create and post a Service Order, Service lines with 2 Lot Tracking selected from previous Lot Nos.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::PartialAssignManualTwoLotNo); // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo[2]);
        LibraryVariableStorage.Enqueue(LotNo[3]);

        case UndoOption of
            UndoType::UndoShipment:
                begin
                    DocumentNo := CreateAndPostServiceDocumentWithLotTracking(Item."No.", Quantity[2] * 2, true, false, false); // Ship=TRUE,Consume=FALSE,Invoice=FALSE
                    UndoShipmentForService(DocumentNo);
                    VerifyItemLedgerEntryForCorrection(ItemLedgerEntry."Entry Type"::Sale, Item."No.", Quantity[2] / 2, true);
                end;
            UndoType::UndoConsumption:
                begin
                    DocumentNo := CreateAndPostServiceDocumentWithLotTracking(Item."No.", Quantity[2] * 2, true, true, false); // Ship=TRUE,Consume=TRUE,Invoice=FALSE
                    UndoConsumptionForService(DocumentNo);
                    VerifyItemLedgerEntryForCorrection(ItemLedgerEntry."Entry Type"::"Negative Adjmt.", Item."No.", Quantity[2] / 2, true);
                end;
        end;

        // Exercise: Run Service Shipment Report.
        RunServiceShipmentReport(false, true, true, DocumentNo); // ShowInternalInfo=FALSE,ShowCorrectionLine=TRUE,ShowLotSerialNoAppendix=TRUE

        // Verify: Verify Quantity and "Correction" Quantity are correct for the Lot Nos. in Report.
        LibraryReportDataset.LoadDataSetFile();
        for i := 2 to 3 do
            VerifyUndoTrackingQuantity('TrackingSpecBufLotNo', LotNo[i], 'TrackingSpecBufQty', Quantity[i] / 2);

        // TearDown: Roll Back Sales & Receivables Setup
        UpdateSalesReceivableSetup(SalesReceivablesSetup."Credit Warnings", SalesReceivablesSetup."Stockout Warning");
    end;

    local procedure CreateItemWithRepSysAssembly(var Item: Record Item)
    begin
        CreateItemWithLotItemTrackingCode(Item, true, '');
        UpdateItemWithReplenishmentSystem(Item);
    end;

    local procedure CreateSerialItemWithRepSysAssembly(var Item: Record Item)
    begin
        CreateItemWithSerialItemTrackingCodeUsingStrictExpiration(Item, false);
        UpdateItemWithReplenishmentSystem(Item);
    end;

    local procedure CreateAndPostItemJournalLineWithItemTracking(LocationCode: Code[10]; BinCode: Code[20]; ItemUnitOfMeasure: Code[10]; ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,AssignSerialNo,ApplyFromItemEntry,AssignAutoSerialNo,AssignAutoLotAndSerialNo; ItemNo: Code[20]; Quantity: Decimal; ExpirationDate: Date; DifferentExpirationDate: Boolean; UpdateLotNo: Boolean) LotNo: Code[50]
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        DequeueVariable: Variant;
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, LocationCode, Quantity, WorkDate(), BinCode, ItemUnitOfMeasure);
        LibraryVariableStorage.Enqueue(ItemTrackingMode);  // Enqueue for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        UpdateExpirationDateOnReservationEntry(ItemNo, ExpirationDate, DifferentExpirationDate);
        if UpdateLotNo then begin
            LotNo := LibraryUtility.GenerateGUID();
            ReservationEntry.SetRange("Item No.", ItemNo);
            ReservationEntry.ModifyAll("Lot No.", LotNo, true);
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        if ItemTrackingMode = ItemTrackingMode::AssignLotNo then begin
            LibraryVariableStorage.Dequeue(DequeueVariable);
            LotNo := DequeueVariable;
        end;
    end;

    local procedure CreateAndPostServiceDocumentWithLotTracking(ItemNo: Code[20]; Quantity: Decimal; Ship: Boolean; Consume: Boolean; Invoice: Boolean): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        CreateServiceDocumentAndUpdateServiceLine(ServiceLine, ItemNo, LibrarySales.CreateCustomerNo(), Quantity, Consume);
        ServiceLine.OpenItemTrackingLines();
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, Ship, Consume, Invoice);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader: Record "Purchase Header"; ItemTracking: Boolean; ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,AssignSerialNo,ApplyFromItemEntry,AssignAutoSerialNo,AssignAutoLotAndSerialNo)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        if ItemTracking then
            OpenWhseReceiptItemTrackingLines(WarehouseReceiptLine, ItemTrackingMode);
        PostWarehouseReceipt(WarehouseReceiptLine."No.");
    end;

    local procedure CreateAndReleasePurchaseOrderWithItemTracking(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UseTracking: Boolean)
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, ItemNo, LocationCode, Quantity, '', UseTracking);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithMultipleUOMAndLotTracking(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; Quantity: array[3] of Decimal; var UOMCode: array[3] of Code[10]; var LotNo: array[4] of Code[20]; var QtyPerUOM: Decimal; LocationCode: Code[10])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        i: Integer;
    begin
        CreateItemWithLotItemTrackingCode(Item, true, LibraryUtility.GetGlobalNoSeriesCode()); // Taking TRUE for Lot.
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        QtyPerUOM := ItemUnitOfMeasure."Qty. per Unit of Measure";
        UOMCode[1] := ItemUnitOfMeasure.Code;
        UOMCode[2] := '';
        UOMCode[3] := '';

        for i := 1 to 3 do
            if Quantity[i] <> 0 then begin
                LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignManualLotNo); // Enqueue for ItemTrackingLinesPageHandler.
                LibraryVariableStorage.Enqueue(LotNo[i]);
                CreatePurchaseLine(PurchaseHeader, Item."No.", LocationCode, Quantity[i], '', UOMCode[i], true);
            end;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSimplePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; Quantity: Decimal)
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order",
          LibraryInventory.CreateItemNo(), LocationWhite.Code, Quantity, '', false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSimpleSalesReturnOrder(var SalesHeader: Record "Sales Header"; Quantity: Decimal)
    begin
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo(),
          LibraryInventory.CreateItemNo(), Quantity, LocationWhite.Code, '', false, ReservationMode::" ");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; VariantCode: Code[10]; ItemTracking: Boolean; ReservationMode: Option)
    begin
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, CustomerNo, ItemNo, Quantity, LocationCode, VariantCode, ItemTracking,
          ReservationMode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithMultipleSalesLines(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; Quantity2: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        if ItemNo2 <> '' then
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo2, Quantity2);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithMultiplePurchaseLines(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; Quantity2: Decimal; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, VendorNo, LocationCode);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        if ItemNo2 <> '' then
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo2, Quantity2);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSimpleTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleaseDirectTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify();
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndRegisterPutAwayFromPurchaseOrder(var Bin: Record Bin; ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,AssignSerialNo,ApplyFromItemEntry,AssignAutoSerialNo,AssignAutoLotAndSerialNo; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; ExpirationDate: Date; UseTracking: Boolean; DifferentExpirationDate: Boolean) LotNo: Code[50]
    var
        PurchaseHeader: Record "Purchase Header";
        DequeueVariable: Variant;
    begin
        CreateAndReleasePurchaseOrderWithItemTracking(PurchaseHeader, ItemNo, LocationCode, Quantity, UseTracking);
        if ItemTrackingMode = ItemTrackingMode::AssignLotNo then begin
            LibraryVariableStorage.Dequeue(DequeueVariable);
            LotNo := DequeueVariable;
        end;
        if UseTracking then
            UpdateExpirationDateOnReservationEntry(ItemNo, ExpirationDate, DifferentExpirationDate);
        RegisterPutAwayFromPurchaseOrder(PurchaseHeader, Bin);
    end;

    local procedure CreateAndRegisterPutAwayFromPurchaseOrderNoExpiration(var Bin: Record Bin; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UOM: Code[10]; CleanQueue: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        DequeueVariable: Variant;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseHeader, ItemNo, LocationCode, Quantity, '', UOM, true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        if CleanQueue then
            LibraryVariableStorage.Dequeue(DequeueVariable); // Enqueued in ItemTrackingLinesPageHandler
        RegisterPutAwayFromPurchaseOrder(PurchaseHeader, Bin);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Put-away", RequirePutAway);
        Location.Validate("Require Pick", RequirePick);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Shipment", RequireShipment);
        Location."Bin Mandatory" := BinMandatory;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    local procedure RegisterPutAwayFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var Bin: Record Bin)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false, ItemTrackingMode::" ");
        UpdateZoneAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Bin);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure RegisterAssemblyPick(AssemblyNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Assembly Consumption",
          AssemblyNo, WarehouseActivityLine."Activity Type"::Pick);
        RegisterWhseActivityAfterAutofillingQtyToHandle(WarehouseActivityLine);
    end;

    local procedure CreateAssemblyFullWMSLocation(): Code[10]
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        LibraryWarehouse.CreateZone(
          Zone, LibraryUtility.GenerateRandomCode(Zone.FieldNo(Code), DATABASE::Zone),
          Location.Code, LibraryWarehouse.SelectBinType(false, false, false, false), '', '', 0, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, Zone.Code, LibraryWarehouse.SelectBinType(false, false, false, false), 2, false);

        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);
        Location.Validate("To-Assembly Bin Code", Bin.Code);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 2);
        Location.Validate("From-Assembly Bin Code", Bin.Code);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        exit(Location.Code);
    end;

    local procedure CreateAssemblyItemWithComponent(var AssemblyItem: Code[20]; var ComponentItem: Code[20])
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Modify(true);
        LibraryInventory.CreateItem(ChildItem);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItem."No.", BOMComponent.Type::Item, ChildItem."No.", 1, ChildItem."Base Unit of Measure");
        AssemblyItem := ParentItem."No.";
        ComponentItem := ChildItem."No.";
    end;

    local procedure CreateTwoSalesOrdersWithShipmentsAndPicks(var WarehouseShipmentHeader: array[2] of Record "Warehouse Shipment Header"; var WarehouseShipmentLine: array[2] of Record "Warehouse Shipment Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        InventorySetup: Record "Inventory Setup";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        i: Integer;
    begin
        InventorySetup.Get();
        for i := 1 to 2 do begin
            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader[i], SalesLine[i], SalesHeader[i]."Document Type"::Order, LibrarySales.CreateCustomerNo(),
              ItemNo, Quantity, LocationCode, CalcDate(InventorySetup."Default Safety Lead Time", WorkDate()));
            SalesLine[i].Validate("Qty. to Assemble to Order", Quantity);
            SalesLine[i].Modify(true);
            LibrarySales.ReleaseSalesDocument(SalesHeader[i]);
            LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader[i]);
            WarehouseShipmentLine[i].SetRange("Source No.", SalesHeader[i]."No.");
            WarehouseShipmentLine[i].FindFirst();
            WarehouseShipmentLine[i].Validate("Qty. to Ship", Quantity);
            WarehouseShipmentLine[i].Modify(true);
            WarehouseShipmentHeader[i].Get(WarehouseShipmentLine[i]."No.");
            LibraryWarehouse.CreatePick(WarehouseShipmentHeader[i]);
        end;
        LibraryAssembly.FindLinkedAssemblyOrder(
          AssemblyHeader, SalesLine[1]."Document Type", SalesLine[1]."Document No.", SalesLine[1]."Line No.");
        RegisterAssemblyPick(AssemblyHeader."No.");
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreateInventoryPickFromSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UseItemTracking: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, '', ItemNo, Quantity, LocationCode, '', UseItemTracking, ReservationMode::" ");
        LibraryVariableStorage.Enqueue(InvtPickCreatedTxt);  // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
    end;

    local procedure CreateInventoryPickFromSalesOrderUsingItemTracking(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateInventoryPickFromSalesOrder(SalesHeader, ItemNo, LocationCode, Quantity, true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; PostingDate: Date; BinCode: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');  // Use Blank No. Series.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        if BinCode <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Serial: Boolean; Lot: Boolean; StrictExpirationPosting: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("Use Expiration Dates", StrictExpirationPosting);
        ItemTrackingCode.Validate("Strict Expiration Posting", StrictExpirationPosting);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemTrackingLine(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Serial No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(1);  // Value required for Quantity.
    end;

    local procedure CreateItemWithLotAndSerialItemTrackingCodeUsingStrictExpiration(var Item: Record Item)
    var
        LotAndSerialWithStrictExpirationItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(LotAndSerialWithStrictExpirationItemTrackingCode, true, true, true);
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(),
          LotAndSerialWithStrictExpirationItemTrackingCode.Code);
    end;

    local procedure CreateItemWithLotItemTrackingCode(var Item: Record Item; Lot: Boolean; LotNos: Code[20])
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, false, Lot, false);
        LibraryInventory.CreateTrackedItem(Item, LotNos, '', ItemTrackingCode.Code);  // Taking blank for Serial Nos.
    end;

    local procedure CreateItemWithLotItemTrackingCodeUsingStrictExpiration(var Item: Record Item)
    var
        LotWithStrictExpirationItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(LotWithStrictExpirationItemTrackingCode, false, true, true);  // Use Lot with Strict Expiration.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', LotWithStrictExpirationItemTrackingCode.Code);
    end;

    local procedure CreateItemWithSerialItemTrackingCodeUsingStrictExpiration(var Item: Record Item; StrictExpiration: Boolean)
    var
        SerialWithStrictExpirationItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(SerialWithStrictExpirationItemTrackingCode, true, false, StrictExpiration);
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), SerialWithStrictExpirationItemTrackingCode.Code);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandInt(10) + 1); // Value required for test.
    end;

    local procedure CreateWMSLocationWithFEFOEnabled(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);
    end;

    local procedure CreateMovementFromMovementWorksheetLine(WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindWarehouseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode, ItemNo, ItemNo2);
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::None, false, false, false);  // Taking 0 for SortActivity.
    end;

    local procedure CreateMovementWithMovementWorksheetLine(var Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        Bin2: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        LibraryWarehouse.CreateBin(Bin2, Bin."Location Code", LibraryUtility.GenerateGUID(), Bin."Zone Code", Bin."Bin Type Code");
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, Bin2, ItemNo, '', Quantity);
        WhseWorksheetName.Get(WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name, WhseWorksheetLine."Location Code");
        CreateMovementFromMovementWorksheetLine(WhseWorksheetName, Bin."Location Code", ItemNo, ItemNo);
    end;

    [Scope('OnPrem')]
    procedure CreateMovementWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Bin."Location Code");
        LibraryWarehouse.CreateWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, WhseWorksheetName."Location Code",
          "Warehouse Worksheet Document Type"::" ");
        WhseWorksheetLine.Validate("Item No.", ItemNo);
        WhseWorksheetLine.Validate("To Zone Code", Bin."Zone Code");
        WhseWorksheetLine.Validate("To Bin Code", Bin.Code);
        WhseWorksheetLine.Validate(Quantity, Quantity);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure CreatePickFromSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemTracking: Boolean; ReservationMode: Option)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if ItemTracking then
            LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateAndReleaseSalesOrder(SalesHeader, CustomerNo, ItemNo, Quantity, LocationCode, '', ItemTracking, ReservationMode);
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreatePickFromWarehouseShipment(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; VariantCode: Code[10]; UseTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        CreatePurchaseLine(PurchaseHeader, ItemNo, LocationCode, Quantity, VariantCode, '', UseTracking);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; VariantCode: Code[10]; UOM: Code[10]; ItemTracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Variant Code", VariantCode);
        if UOM <> '' then
            PurchaseLine.Validate("Unit of Measure Code", UOM);
        PurchaseLine.Modify(true);
        if ItemTracking then
            PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateReservation(SalesLine: Record "Sales Line"; ReservationMode: Option " ",ReserveFromCurrentLine,AutoReserve)
    begin
        if ReservationMode = ReservationMode::ReserveFromCurrentLine then
            LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(ReservationMode);  // Enqueue for ReservationPageHandler.
        SalesLine.ShowReservation();
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; VariantCode: Code[10]; UseTracking: Boolean; ReservationMode: Option)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
        if UseTracking then
            SalesLine.OpenItemTrackingLines();
        if ReservationMode <> 0 then
            CreateReservation(SalesLine, ReservationMode);
    end;

    local procedure CreateSalesDocumentWithVariousLines(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Purchase Document Type";
                                                        Item: array[2] of Record Item; NonInvtItem: array[2] of Record Item;
                                                        ItemCharge: array[2] of Record "Item Charge"; LocationCode: Code[10])
    var
        SalesLineItem: array[2] of Record "Sales Line";
        SalesLineNonInvtItem: array[2] of Record "Sales Line";
        SalesLineItemCharge: array[2] of Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        i: Integer;
        j: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);

        for i := 1 to 2 do
            LibrarySales.CreateSalesLine(
              SalesLineItem[i], SalesHeader, SalesLineItem[i].Type::Item, Item[i]."No.", LibraryRandom.RandInt(10));

        for i := 1 to 2 do begin
            LibrarySales.CreateSalesLine(
              SalesLineNonInvtItem[i], SalesHeader, SalesLineNonInvtItem[i].Type::Item, NonInvtItem[i]."No.", LibraryRandom.RandInt(10));
            SalesLineNonInvtItem[i]."Attached to Line No." := SalesLineItem[i]."Line No.";
            SalesLineNonInvtItem[i].Modify();
        end;

        for i := 1 to 2 do begin
            LibrarySales.CreateSalesLine(
              SalesLineItemCharge[i], SalesHeader, SalesLineItemCharge[i].Type::"Charge (Item)", ItemCharge[i]."No.", 2);
            SalesLineItemCharge[i].Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLineItemCharge[i].Modify(true);
            for j := 1 to 2 do begin
                LibrarySales.CreateItemChargeAssignment(
                  ItemChargeAssignmentSales, SalesLineItemCharge[i], ItemCharge[i],
                  SalesLineItem[j]."Document Type", SalesLineItem[j]."Document No.", SalesLineItem[j]."Line No.",
                  SalesLineItem[j]."No.", 1, SalesLineItemCharge[i]."Unit Cost");
                ItemChargeAssignmentSales.Insert(true);
            end;
        end;
    end;

    local procedure CreateSalesInvoiceFromShipment(var SalesHeaderInvoice: Record "Sales Header"; SalesHeader: Record "Sales Header")
    var
        SalesShptLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        FindSalesShipmentLine(SalesShptLine, SalesHeader."No.");
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesGetShipment.CreateInvLines(SalesShptLine);
    end;

    local procedure CreateSalesCrMemoFromReturnReceipt(var SalesHeaderCrMemo: Record "Sales Header"; SalesHeader: Record "Sales Header")
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        FindReturnReceiptLine(ReturnReceiptLine, SalesHeader."No.");
        LibrarySales.CreateSalesHeader(SalesHeaderCrMemo, SalesHeaderCrMemo."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        SalesGetReturnReceipts.SetSalesHeader(SalesHeaderCrMemo);
        SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, No);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2)); // Using Random value for Unit Cost.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceDocumentAndUpdateServiceLine(var ServiceLine: Record "Service Line"; ItemNo: Code[20]; CustomerNo: Code[20]; Quantity: Decimal; PostConsume: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        CreateServiceDocument(ServiceLine, ServiceHeader."Document Type"::Order, CustomerNo, ItemNo, Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        if PostConsume then
            ServiceLine.Validate("Qty. to Consume", Quantity / 2)
        else
            ServiceLine.Validate("Qty. to Ship", Quantity / 2);
        ServiceLine.Modify(true);
    end;

    local procedure CreateTransferRoute()
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationGreen.Code, LocationYellow.Code);
        TransferRoute.Validate("In-Transit Code", LocationInTransit.Code);
        TransferRoute.Modify(true);
    end;

    local procedure CreateWarehouseShipmentFromSalesHeader(SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; Item: Record Item; Quantity: Decimal; VariantCode: Code[10])
    begin
        LibraryWarehouse.WarehouseJournalSetup(Bin."Location Code", WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        WarehouseJournalLine.Validate("Variant Code", VariantCode);
        WarehouseJournalLine.Modify(true);
    end;

    local procedure FilterWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        if SourceNo <> '' then
            WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
    end;

    local procedure FindBinForPickZone(var Bin: Record Bin; LocationCode: Code[10]; Pick: Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, Pick));  // Taking True for PutAway.
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, Bin.Count);
    end;

    local procedure FindBinForShipZone(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, true, false, false));
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, 1);
    end;

    local procedure FindReplenishmentBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(true, false, false, false));
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, 1);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; No: Code[20])
    begin
        SalesLine.Reset();
        SalesLine.SetRange("No.", No);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
    end;

    local procedure FindSalesShipmentLine(var SalesShptLine: Record "Sales Shipment Line"; OrderNo: Code[20])
    var
        SalesShptHeader: Record "Sales Shipment Header";
    begin
        SalesShptHeader.SetRange("Order No.", OrderNo);
        SalesShptHeader.FindFirst();
        SalesShptLine.SetRange("Document No.", SalesShptHeader."No.");
        SalesShptLine.FindFirst();
    end;

    local procedure FindReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; ReturnOrderNo: Code[20])
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        ReturnReceiptHeader.SetRange("Return Order No.", ReturnOrderNo);
        ReturnReceiptHeader.FindFirst();
        ReturnReceiptLine.SetRange("Document No.", ReturnReceiptHeader."No.");
        ReturnReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        FilterWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure AutoFillQtyToHandleOnWarehouseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptHeaderBySource(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetSourceFilter(SourceType, SourceSubtype, SourceNo, SourceLineNo, false);
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
    end;

    local procedure FindWarehouseReceiptHeaderFromSalesReturnOrder(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptHeader(
          WarehouseReceiptHeader, WarehouseReceiptLine."Source Document"::"Sales Return Order", SourceNo, LocationCode);
    end;

    local procedure FindWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Location Code", LocationCode);
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentHeaderBySource(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetSourceFilter(SourceType, SourceSubtype, SourceNo, SourceLineNo, false);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FindWarehouseShipmentHeaderFromSalesOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentHeader(
          WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SourceNo, LocationCode);
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Location Code", LocationCode);
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FindWarehouseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.SetFilter("Item No.", ItemNo + '|' + ItemNo2);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; BinTypeCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure GetPostiveAdjmtQtyFromWarehouseEntry(ItemNo: Code[20]; LocationCode: Code[20]; AssemblyHeaderNo: Code[20]) PositiveAdjmtQty: Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetRange("Source No.", AssemblyHeaderNo);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::"Positive Adjmt.");
        WarehouseEntry.FindSet();
        repeat
            PositiveAdjmtQty += WarehouseEntry.Quantity;
        until WarehouseEntry.Next() = 0;
        exit(PositiveAdjmtQty);
    end;

    local procedure OpenWhseReceiptItemTrackingLines(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,AssignSerialNo,ApplyFromItemEntry,AssignAutoSerialNo,AssignAutoLotAndSerialNo)
    var
        LotNo: Variant;
    begin
        if ItemTrackingMode = ItemTrackingMode::AssignLotNo then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
            WarehouseReceiptLine.OpenItemTrackingLines();
            LibraryVariableStorage.Dequeue(LotNo)
        end else begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignAutoSerialNo);
            WarehouseReceiptLine.OpenItemTrackingLines();
        end;
    end;

    local procedure PostInventoryActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; Invoice: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, Invoice);
    end;

    local procedure PostPurchaseOrderWithTwoLot(var Item: Record Item; var Quantity: array[3] of Decimal; var LotNo: array[3] of Code[20]; PostShipReceive: Boolean; PostInvoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        UOM: array[3] of Code[10];
        QtyPerUOM: Decimal;
    begin
        Quantity[1] := 0;
        Quantity[2] := LibraryRandom.RandIntInRange(10, 100);
        Quantity[3] := Quantity[2];
        LotNo[1] := '';
        LotNo[2] := LibraryUtility.GenerateGUID();
        LotNo[3] := LibraryUtility.GenerateGUID();
        CreateAndReleasePurchaseOrderWithMultipleUOMAndLotTracking(PurchaseHeader, Item, Quantity, UOM, LotNo, QtyPerUOM, '');
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, PostShipReceive, PostInvoice);
    end;

    local procedure PostWarehouseReceipt(WarehouseReceiptNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(WarehouseReceiptNo);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure RegisterWarehouseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterWhseJournalLineAndPostItemJournal(Item: Record Item; Bin: Record Bin)
    begin
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure RegisterWhseActivityAfterAutofillingQtyToHandle(WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RunItemTrackingAppendixReport(DocType: Option; DocNo: Code[20])
    var
        ItemTrackingAppendix: Report "Item Tracking Appendix";
    begin
        LibraryVariableStorage.Enqueue(DocType);
        LibraryVariableStorage.Enqueue(DocNo);
        Commit(); // Use the COMMIT function to save the changes
        Clear(ItemTrackingAppendix);
        ItemTrackingAppendix.UseRequestPage(true);
        ItemTrackingAppendix.Run();
    end;

    local procedure ReleaseAndCreateWhsePickFromAsmHeader(ItemNo: Code[20]): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        LibraryAssembly: Codeunit "Library - Assembly";
    begin
        AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.SetRange("Item No.", ItemNo);
        AssemblyHeader.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);
        LibraryVariableStorage.Enqueue(PickActivityMsg);
        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
        exit(AssemblyHeader."No.");
    end;

    local procedure RunSalesShipmentReport(No: Code[20]; ShowInternalInformation: Boolean; LogInteraction: Boolean; ShowCorrectionLines: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipment: Report "Sales - Shipment";
    begin
        Clear(SalesShipment);
        SalesShipmentHeader.SetRange("No.", No);
        SalesShipment.SetTableView(SalesShipmentHeader);

        // Passing 0 for No. of Copies, TRUE for Show Serial/ Lot No and FALSE for Show Assembly Components. Appendix option as these options can not be checked.
        SalesShipment.InitializeRequest(0, ShowInternalInformation, LogInteraction, ShowCorrectionLines, true, false);
        Commit(); // Due to limitation in Report Commit is required for this Test case.
        SalesShipment.Run();
    end;

    local procedure RunServiceShipmentReport(ShowInternalInfo: Boolean; ShowCorrectionLine: Boolean; ShowLotSerialNoAppendix: Boolean; OrderNo: Code[20])
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipment: Report "Service - Shipment";
    begin
        Clear(ServiceShipment);
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipment.SetTableView(ServiceShipmentHeader);
        ServiceShipment.InitializeRequest(ShowInternalInfo, ShowCorrectionLine, ShowLotSerialNoAppendix);
        Commit(); // Due to limitation in Report Commit is required for this Test case.
        ServiceShipment.Run();
    end;

    local procedure UpdateItemWithReplenishmentSystem(var Item: Record Item)
    begin
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure UndoSaleShipmentLine(OrderNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentHeader.FindFirst();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UpdateExpirationDateOnReservationEntry(ItemNo: Code[20]; ExpirationDate: Date; DifferentExpirationDate: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        DateDifference: Integer;
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindSet();
        repeat
            ReservationEntry.Validate("Expiration Date", ExpirationDate);
            if DifferentExpirationDate then begin
                DateDifference += 1;
                ReservationEntry.Validate("Expiration Date", CalcDate('<-' + Format(DateDifference) + 'D>', ExpirationDate));
            end;
            ReservationEntry.Modify(true);
        until ReservationEntry.Next() = 0;
    end;

    local procedure UpdateExpirationDateOnWhseItemTrackingLine(ItemNo: Code[20]; ExpirationDate: Date)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.SetRange("Item No.", ItemNo);
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.Validate("Expiration Date", ExpirationDate);
        WhseItemTrackingLine.Modify(true);
    end;

    local procedure UpdateLotNoOnItemTrackingLine(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        LotNo: Code[50];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LotNo := DequeueVariable;
        ItemTrackingLines."Lot No.".SetValue(LotNo);
    end;

    local procedure UpdateZoneAndBinCodeOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; Bin: Record Bin)
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.ModifyAll("Zone Code", Bin."Zone Code", true);
        WarehouseActivityLine.ModifyAll("Bin Code", Bin.Code, true);
    end;

    local procedure UpdateAndTrackInventoryUsingWhseJournal(Bin: Record Bin; Item: Record Item; Quantity: Decimal; VariantCode: Code[10]; ExpirationDate: Date)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, Item, Quantity, VariantCode);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(Quantity);
        WarehouseJournalLine.OpenItemTrackingLines();
        UpdateExpirationDateOnWhseItemTrackingLine(Item."No.", ExpirationDate);
        RegisterWhseJournalLineAndPostItemJournal(Item, Bin);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdatePickAccordingToFEFOOnLocation(var Location: Record Location; var OldPickAccordingToFEFO: Boolean; NewPickAccordingToFEFO: Boolean)
    begin
        OldPickAccordingToFEFO := Location."Pick According to FEFO";
        Location.Validate("Pick According to FEFO", NewPickAccordingToFEFO);
        Location.Modify(true);
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

    local procedure UpdateNonInvtPostingPolicyInSalesSetup(NonInvtItemWhsePolicy: Enum "Non-Invt. Item Whse. Policy")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Auto Post Non-Invt. via Whse.", NonInvtItemWhsePolicy);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateQtyToShipAndPostWhseShipment(SourceNo: Code[20]; QtyToShip: Decimal)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.Modify(true);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure UpdateLotNoOnItem(var ChildItem: Record Item)
    begin
        ChildItem.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        ChildItem.Modify(true);
    end;

    local procedure UpdateQuantityOnWarehouseReceiptLineFromSalesReturnOrder(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; QtyToReceive: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        UpdateQuantityOnWarehouseReceiptLine(
          WarehouseReceiptLine."Source Document"::"Sales Return Order", SourceNo, ItemNo, LocationCode, VariantCode, QtyToReceive);
    end;

    local procedure UpdateQuantityOnWarehouseReceiptLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; QtyToReceive: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.SetRange("Variant Code", VariantCode);
        WarehouseReceiptLine.SetRange("Location Code", LocationCode);
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo);
        WarehouseReceiptLine.Validate("Qty. to Receive", QtyToReceive);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure UpdateQuantityOnWarehouseShipmentLineFromSalesOrder(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; QtyToShip: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        UpdateQuantityOnWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SourceNo, ItemNo, LocationCode, VariantCode, QtyToShip);
    end;

    local procedure UpdateQuantityOnWarehouseShipmentLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; QtyToShip: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.SetRange("Variant Code", VariantCode);
        WarehouseShipmentLine.SetRange("Location Code", LocationCode);
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentLine.Validate("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure UpdateQtyToHandleOnWarehouseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ItemNo: Code[20]; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UndoSalesShipmentLine(DocumentNo: Code[20]; ExpectedMessage: Text)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(ExpectedMessage); // Enqueue for ConfirmHandler.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UndoShipmentForService(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        LibraryVariableStorage.Enqueue(UndoShipmentConfirmQst); // Enqueue for ConfirmHandler.
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServiceShipmentLine);
    end;

    local procedure UndoConsumptionForService(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        LibraryVariableStorage.Enqueue(UndoConsumptionConfirmQst); // Enqueue for ConfirmHandler.
        CODEUNIT.Run(CODEUNIT::"Undo Service Consumption Line", ServiceShipmentLine);
    end;

    local procedure VerifyItemLedgerEntryForCorrection(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal; Correction: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.SetRange(Quantity, Quantity);
        ItemLedgerEntry.FindFirst();
        repeat
            Assert.AreEqual(Correction, ItemLedgerEntry.Correction, ValueMustBeEqualTxt);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyWarehouseActivityLinesWithLotAndSerialNoAccordingToFEFO(ActivityType: Enum "Warehouse Activity Type"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ActualQuantity: Decimal;
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.FindSet();
        repeat
            ItemLedgerEntry.SetRange("Serial No.", WarehouseActivityLine."Serial No.");
            ItemLedgerEntry.SetRange("Lot No.", WarehouseActivityLine."Lot No.");
            FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, ItemNo);
            WarehouseActivityLine.TestField("Expiration Date", ItemLedgerEntry."Expiration Date");
            WarehouseActivityLine.TestField(Quantity, ItemLedgerEntry.Quantity);
            ActualQuantity += WarehouseActivityLine.Quantity;
        until WarehouseActivityLine.Next() = 0;
        Assert.AreEqual(ExpectedQuantity, ActualQuantity, ValueMustBeEqualTxt);
    end;

    local procedure VerifyReportForUndoShipmentWithLotTracking(ReportNameOption: Option; LotNoElementName: Text; QuantityElementName: Text)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        LotNo: array[3] of Code[20];
        DocumentNo: Code[20];
        Quantity: array[3] of Decimal;
        i: Integer;
        DocType: Option "Sales Quote","Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Sales Post. Shipment","Sales Post. Invoice","Purch. Quote","Purch. Order","Purch. Invoice","Purch. Credit Memo","Purch. Return Order";
    begin
        Initialize();
        // Setup: Create and post a Purchase Order with 2 different Lot Tracking
        // 1st Line: Quantity[2], Lot[2]
        // 2nd Line: Quantity[2], Lot[3]
        PostPurchaseOrderWithTwoLot(Item, Quantity, LotNo, true, false);

        // Create and post a Sales Order with 2 lines with previous Lot Nos.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignManualTwoLotNo); // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo[2]);
        LibraryVariableStorage.Enqueue(LotNo[3]);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, '', Item."No.", Quantity[2] * 2, '', '', true, ReservationMode::" ");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false); // Post as Ship

        // Undo the Posted Sales Shipment.
        UndoSalesShipmentLine(DocumentNo, UndoShipmentConfirmMessageQst);

        // Exercise: Run Sales Shipment Report / Item Tracking Appendix Report.
        case ReportNameOption of
            ReportName::SalesShipment:
                RunSalesShipmentReport(DocumentNo, true, false, true); // ShowInternalInformation=TRUE, LogInteraction=FALSE, ShowCorrectionLines=TRUE
            ReportName::ItemTrackingAppendix:
                RunItemTrackingAppendixReport(DocType::"Sales Post. Shipment", DocumentNo);
        end;

        // Verify: Verify Quantity and "Correction" Quantity are correct for the Lot Nos. in Report.
        LibraryReportDataset.LoadDataSetFile();
        for i := 2 to 3 do
            VerifyUndoTrackingQuantity(LotNoElementName, LotNo[i], QuantityElementName, Quantity[i]);
    end;

    local procedure VerifyUndoTrackingQuantity(LotNoElementName: Text; LotNo: Code[50]; QuantityElementName: Text; Quantity: Decimal)
    begin
        LibraryReportDataset.SetRange(LotNoElementName, LotNo);
        LibraryReportDataset.SetRange(QuantityElementName, -Quantity);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(QuantityElementName, -Quantity);
    end;

    local procedure VerifyQtyToPickEqualsTo(ItemNo: Code[20]; ExpectedQty: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        PickQtySum: Decimal;
    begin
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindSet();
        repeat
            WarehouseShipmentLine.CalcFields("Pick Qty.");
            PickQtySum += WarehouseShipmentLine."Pick Qty.";
        until WarehouseShipmentLine.Next() = 0;
        Assert.AreEqual(ExpectedQty, PickQtySum, ValueMustBeEqualTxt);
    end;

    local procedure VerifyWarehouseRequestRec(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; Expected: Integer)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Source Type", SourceType);
        WarehouseRequest.SetRange("Source Subtype", SourceSubtype);
        WarehouseRequest.SetRange("Source No.", SourceNo);
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Open);
        Assert.AreEqual(Expected, WarehouseRequest.Count(), 'Expected warehouse request to exist.');
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
        QtyBase: Variant;
        Quantity: Decimal;
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
                    Quantity := ItemTrackingLines.Quantity3.AsDecimal();
                    repeat
                        CreateItemTrackingLine(ItemTrackingLines);
                        ItemTrackingLines.Next();
                        Quantity -= 1;
                    until Quantity = 0;
                end;
            ItemTrackingMode::AssignSerialAndLotNos:
                begin
                    Quantity := ItemTrackingLines.Quantity3.AsDecimal();
                    repeat
                        ItemTrackingLines."Serial No.".SetValue(LibraryUtility.GenerateGUID());
                        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
                        ItemTrackingLines."Quantity (Base)".SetValue(1);
                        ItemTrackingLines.Next();
                        Quantity -= 1;
                    until Quantity = 0;
                end;
            ItemTrackingMode::ApplyFromItemEntry:
                begin
                    UpdateLotNoOnItemTrackingLine(ItemTrackingLines);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsDecimal());
                    ItemTrackingLines."Appl.-from Item Entry".Lookup();
                end;
            ItemTrackingMode::AssignAutoSerialNo:
                begin
                    LibraryVariableStorage.Enqueue(false);  // Enqueue for EnterQuantityToCreatePageHandler.
                    ItemTrackingLines."Assign Serial No.".Invoke();
                end;
            ItemTrackingMode::AssignAutoLotAndSerialNo:
                begin
                    LibraryVariableStorage.Enqueue(true);  // Enqueue for EnterQuantityToCreatePageHandler.
                    ItemTrackingLines."Assign Serial No.".Invoke();
                end;
            ItemTrackingMode::AssignManualLotNo:
                begin
                    UpdateLotNoOnItemTrackingLine(ItemTrackingLines);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsDecimal());
                end;
            ItemTrackingMode::AssignManualTwoLotNo:
                begin
                    UpdateLotNoOnItemTrackingLine(ItemTrackingLines);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsDecimal() / 2);
                    ItemTrackingLines.Next();
                    UpdateLotNoOnItemTrackingLine(ItemTrackingLines);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsDecimal());
                end;
            ItemTrackingMode::AssignTwoLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines."Quantity (Base)".AsDecimal() / 2);
                    ItemTrackingLines."Assign Lot No.".Invoke();
                end;
            ItemTrackingMode::SelectEntriesForMultipleLines:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.Next();
                    ItemTrackingLines."Select Entries".Invoke();
                end;
            ItemTrackingMode::UpdateQty:
                begin
                    LibraryVariableStorage.Dequeue(QtyBase);
                    ItemTrackingLines.First();
                    ItemTrackingLines."Quantity (Base)".SetValue(QtyBase);
                end;
            ItemTrackingMode::PartialAssignManualTwoLotNo:
                begin
                    UpdateLotNoOnItemTrackingLine(ItemTrackingLines);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsDecimal() / 4);
                    ItemTrackingLines.Next();
                    UpdateLotNoOnItemTrackingLine(ItemTrackingLines);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsDecimal() / 3);
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentReportHandler(var SalesShipment: TestRequestPage "Sales - Shipment")
    begin
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceShipmentReportHandler(var ServiceShipment: TestRequestPage "Service - Shipment")
    begin
        ServiceShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ReservationMode := DequeueVariable;
        case ReservationMode of
            ReservationMode::ReserveFromCurrentLine:
                Reservation."Reserve from Current Line".Invoke();
            ReservationMode::AutoReserve:
                Reservation."Auto Reserve".Invoke();
        end;
        Reservation.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingAppendixRequestPageHandler(var ItemTrackingAppendix: TestRequestPage "Item Tracking Appendix")
    var
        Document: Variant;
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(Document);
        LibraryVariableStorage.Dequeue(DocumentNo);
        ItemTrackingAppendix.Document.SetValue(Document);
        ItemTrackingAppendix.DocumentNo.SetValue(DocumentNo);
        ItemTrackingAppendix.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerAsTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UndoShipmentConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm handler for Undo Shipment Confirmation Message. Send Reply YES.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerSimple(Message: Text)
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickFromWhseShptReqHandler(var CreatePickFromWhseShptReqPage: TestRequestPage "Whse.-Shipment - Create Pick")
    begin
        CreatePickFromWhseShptReqPage.OK().Invoke();
    end;
}

