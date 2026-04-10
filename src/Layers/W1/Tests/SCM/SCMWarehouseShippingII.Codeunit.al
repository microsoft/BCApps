codeunit 137155 "SCM Warehouse - Shipping II"
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
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryRandom: Codeunit "Library - Random";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        isInitialized: Boolean;
        ValueMustBeEqualTxt: Label 'Value must be equal.';
        WhseItemTrackingNotEnabledErr: Label 'Warehouse item tracking is not enabled for No. %1', Comment = '%1 = Item No.';
        WarehouseActivityLineMustBeEmptyTxt: Label 'Warehouse Activity Line must be empty.';
        PostJournalLinesConfirmationTxt: Label 'Do you want to post the journal lines';
        JournalLinesPostedTxt: Label 'The journal lines were successfully posted';
        InvtPutAwayCreatedTxt: Label 'Number of Invt. Put-away activities created';
        NothingToHandleErr: Label 'Nothing to handle.';
        TransferOrderDeletedTxt: Label 'Transfer order %1 was successfully posted and is now deleted.', Comment = '%1 = Transfer Order No.';
        PutAwayActivityTxt: Label 'Put-away activity';
        PickActivityTxt: Label 'Pick activity';
        ReservationEntryMustBeEmptyTxt: Label 'Reservation Entry must be empty.';
        InvtPickActivitiesCreatedTxt: Label 'Number of Invt. Pick activities created';
        OrderExpectedTxt: Label 'Order should be created.';
        BeforeWorkDateMsg: Label 'is before work date %1 in one or more of the assembly lines', Comment = '%1 = Work Date';
        CannotChangePurchasingCodeErr: Label 'You cannot change the purchasing code for a sales line that has been completely shipped.';
        ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,AssignSerialNo,ApplyFromItemEntry,AssignAutoSerialNo,AssignAutoLotAndSerialNo,AssignManualLotNo,AssignManualTwoLotNo,AssignTwoLotNo,SelectEntriesForMultipleLines,UpdateQty,PartialAssignManualTwoLotNo;
        AvailabilityWarningsQst: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        ReservationMode: Option " ",ReserveFromCurrentLine,AutoReserve;
        BinValidationErr: Label 'Location code validation in the Production Order must prioritize Default Bin codes';
        NoOfPostedOrdersMsg: Label 'All the documents were posted.', Comment = '%1: Count(Sales Header)';
        VendorHistBuyFromFactBoxMustBeNonEditableTxt: Label 'Vendor Hist. Buy-from FactBox Must Be NonEditable.';

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,SelectLotOnItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickWithMutipleLotItemTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: array[4] of Code[10];
        Quantity: Decimal;
        SplitQty: Decimal;
    begin
        // Test to verify Register Pick successfully with mutiple Lot Item Tracking.

        // Setup: Create a Purchase Order with 4 lines with Lot Tracking.
        // The 1st line and 2nd line with same Lot and the others different.
        // Post Warehouse Receipt, then split Put-Away Line and update Zone Code and Bin Code for Place line, Register Put-away.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);
        SplitQty := Quantity - LibraryRandom.RandInt(5);
        CreateAndReleasePurchaseOrderWithMultipleTrackingLines(PurchaseHeader, Item, Quantity, LotNo);
        CreateAndRegisterSplitedPutAwayFromReleasedPurchaseOrder(PurchaseHeader, LotNo[1], SplitQty);

        // Create a Sales Order with 3 lines and assign Lot No. Update the Quantity(Base) on the 1st tracking line of the 2nd sales line.
        // Post Warehourse Shipment, then Create Pick
        CreateAndReleaseSalesOrderWithSelectLotAndUpdateQtyOnTrackingLine(
          SalesHeader, Item."No.", LotNo, Quantity, LibraryRandom.RandDecInDecimalRange(0, SplitQty, 2)); // The value updated need to less than SplitQty to repro the issue.
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Exercise: Register Pick and Post Warehouse Shipment
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", true);

        // Verify: Verify Quantity and Lot No.is correct in Registed Pick.
        VerifyItemLedgerEntriesWithMultipleLotNo(ItemLedgerEntry."Entry Type"::Sale, Item."No.", LotNo, -Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure AvailableQtyToTakeInPickWorksheetForBreakBulk()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePickRequest: Record "Whse. Pick Request";
        UOM: array[3] of Code[10];
        LotNo: array[3] of Code[20];
        Quantity: array[3] of Decimal;
        QtyPerUOM: Decimal;
        TransferQty: Decimal;
        TransferQty2: Decimal;
        Qty: Decimal;
    begin
        // Test to verify Available Qty. to Take in Pick Worksheet is consist with Pick lines created by shipment for BreakBulk item

        // Setup: Create a Purchase Order with 2 lines, create Whse. Receipt and register Put-away
        // Line1: Quantity, UOM1
        // Line2: Quantity, UOM2 (UOM2 is "Base Unit of Measure")
        Initialize();
        WhsePickRequest.DeleteAll(); // Clear dirty data.
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LotNo[1];
        LotNo[3] := LotNo[1]; // Lot3 can be any value due to there is no 3rd line
        Quantity[1] := LibraryRandom.RandIntInRange(10, 100);
        Quantity[2] := Quantity[1];
        Quantity[3] := 0;
        ReleasePurchaseOrderAndRegisterPutAwayWithMultipleUOMAndLotTracking(Item, Quantity, UOM, LotNo, QtyPerUOM);

        // Create a Transfer Oder with 1 line and Create Pick from Shipment
        // Line1: "More than" Quantity, UOM2. - There is no enough UOM2 of Item in Inventory, so we need breakbulk several UOM1 of Item.
        TransferQty := LibraryRandom.RandIntInRange(Quantity[1], Quantity[1] * QtyPerUOM);
        ReleaseTransferOrderAndCreatePickWithUOMAndLotTracking(
          TransferHeader, LocationWhite.Code, LocationBlue.Code, Item."No.", TransferQty, LotNo[1]);

        // Create a Transfer Oder with 1 line and Create Pick from Shipment
        // Line1: "All the remains" of Quantity, UOM2. - We cannot pick "All the remains" UOM2 items, because the breakbulk item cannot be use
        TransferQty2 := Quantity[1] + Quantity[1] * QtyPerUOM - TransferQty;
        ReleaseTransferOrderAndCreatePickWithUOMAndLotTracking(
          TransferHeader, LocationWhite.Code, LocationBlue.Code, Item."No.", TransferQty2, LotNo[1]);

        // Find the Warehouse Pick and get the value of Quantity of Take, then delete the Pick
        FindWarehouseActivityLineWithActionType(
          WarehouseActivityLine, Item."Base Unit of Measure", LotNo[1], WarehouseActivityLine."Source Document"::"Outbound Transfer",
          TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take);
        Qty := WarehouseActivityLine.Quantity;
        DeleteWarehouseActivityHeader(WarehouseActivityLine."No.");

        // Exercise: Get the Warehouse Shipment On Pick Worksheet
        GetWarehouseDocumentOnWhseWorksheetLine(WhseWorksheetName, LocationWhite.Code, WhsePickRequest."Document Type"::Shipment);

        // Verify: Verify "Qty. to Handle" and "Available Qty. To Pick" in pick worksheet is consist with Pick lines created by shipment
        VerifyQuantityInPickWorksheetPage(Item."No.", Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickFromPickWorksheetForSalesAndTransferOrderWithVariant()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePickRequest: Record "Whse. Pick Request";
        Quantity: Decimal;
    begin
        // Setup: Create Sales Order with Item Variant. Create Transfer Order. Get Source document for both Transfer and Sales Order on Warehouse Shipment. Get Warehouse Document on Pick Worksheet.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithVariant(Item, ItemVariant);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, ItemVariant.Code);
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '');
        CreateAndReleaseSalesOrder(SalesHeader, '', Item."No.", Quantity, LocationWhite.Code, ItemVariant.Code, false, ReservationMode::" ");
        CreateAndReleaseTransferOrder(TransferHeader, LocationWhite.Code, LocationBlue.Code, Item."No.", '', Quantity, '', WorkDate(), WorkDate());
        CreateWarehouseShipmentWithGetSourceDocument(LocationWhite.Code, true, true, false, Item."No.", Item."No.");  // Taking TRUE for Sales Orders.
        GetWarehouseDocumentOnWhseWorksheetLine(WhseWorksheetName, LocationWhite.Code, WhsePickRequest."Document Type"::Shipment);

        // Exercise.
        CreatePickFromPickWorksheet(WhseWorksheetName, Item."No.", Item."No.", 0);  // Taking 0 for MaxNoOfLines.

        // Verify.
        VerifyWarehousePickLines(
          WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", Quantity, '', Bin.Code,
          LocationWhite."Shipment Bin Code");
        VerifyWarehousePickLines(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Quantity, ItemVariant.Code, Bin.Code,
          LocationWhite."Shipment Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickFromPickWorksheetWithMaxNoOfLinesForTransferOrderWithMultipleLines()
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        ItemVariant: Record "Item Variant";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePickRequest: Record "Whse. Pick Request";
        Quantity: Decimal;
        NoOfPicks: Integer;
    begin
        // Setup: Create Transfer Order with multiple lines. Get Source document on Warehouse Shipment. Get Warehouse Document on Pick Worksheet.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateItemWithVariant(Item2, ItemVariant);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '');
        UpdateInventoryUsingWhseJournal(Bin, Item2, Quantity, ItemVariant.Code);
        CreateAndReleaseTransferOrder(
          TransferHeader, LocationWhite.Code, LocationBlue.Code, Item."No.", Item2."No.", Quantity, ItemVariant.Code, WorkDate(), WorkDate());
        CreateWarehouseShipmentWithGetSourceDocument(LocationWhite.Code, true, false, false, Item."No.", Item2."No.");
        GetWarehouseDocumentOnWhseWorksheetLine(WhseWorksheetName, LocationWhite.Code, WhsePickRequest."Document Type"::Shipment);
        GetNoOfPicksOnLocation(NoOfPicks, LocationWhite.Code);

        // Exercise.
        CreatePickFromPickWorksheet(WhseWorksheetName, Item."No.", Item2."No.", 1);  // Taking 1 for MaxNoOfLines. Value required for the test.

        // Verify: No. Of Picks on the Location got increased by 2 as MaxNoOfLines was taken as 1.
        VerifyNoOfPicks(LocationWhite.Code, NoOfPicks + 2);  // Value required for the test.
        VerifyWarehousePickLines(
          WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", Quantity, '', Bin.Code,
          LocationWhite."Shipment Bin Code");
        VerifyWarehousePickLines(
          WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item2."No.", Quantity, ItemVariant.Code,
          Bin.Code, LocationWhite."Shipment Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickFromPickWorksheetForReleasedProductionOrderWithVariant()
    begin
        // Setup.
        Initialize();
        PickFromPickWorksheetForReleasedProductionOrderWithVariant(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickFromPickWorksheetForReleasedProductionOrderWithVariant()
    begin
        // Setup.
        Initialize();
        PickFromPickWorksheetForReleasedProductionOrderWithVariant(true);  // TRUE for Register Warehouse Pick.
    end;

    local procedure PickFromPickWorksheetForReleasedProductionOrderWithVariant(RegisterWarehousePick: Boolean)
    var
        Bin: Record Bin;
        ItemVariant: Record "Item Variant";
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ComponentItem2: Record Item;
        ProductionOrder: Record "Production Order";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePickRequest: Record "Whse. Pick Request";
        Quantity: Decimal;
    begin
        // Create and refresh Production Order. Get Warehouse Document on Pick Worksheet.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithProductionBOMWithMultipleLines(ParentItem, ComponentItem, ComponentItem2, ItemVariant);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        UpdateInventoryUsingWhseJournal(Bin, ComponentItem, Quantity, '');
        UpdateInventoryUsingWhseJournal(Bin, ComponentItem2, Quantity, ItemVariant.Code);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", Quantity, LocationWhite.Code, WorkDate());
        GetWarehouseDocumentOnWhseWorksheetLine(WhseWorksheetName, LocationWhite.Code, WhsePickRequest."Document Type"::Production);

        // Exercise.
        CreatePickFromPickWorksheet(WhseWorksheetName, ComponentItem."No.", ComponentItem2."No.", 0);  // Taking 0 for MaxNoOfLines.

        // Verify.
        VerifyWarehousePickLines(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", ComponentItem."No.", Quantity, '', Bin.Code,
          LocationWhite."To-Production Bin Code");
        VerifyWarehousePickLines(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", ComponentItem2."No.", Quantity,
          ItemVariant.Code, Bin.Code, LocationWhite."To-Production Bin Code");

        if RegisterWarehousePick then begin
            // Exercise.
            AutoFillQuantityToHandleOnWhsePickLine(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.");
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
              WarehouseActivityLine."Activity Type"::Pick);

            // Verify.
            VerifyRegisteredPickLines(
              RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", ComponentItem."No.", Quantity, '',
              Bin.Code, LocationWhite."To-Production Bin Code");
            VerifyRegisteredPickLines(
              RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", ComponentItem2."No.", Quantity,
              ItemVariant.Code, Bin.Code, LocationWhite."To-Production Bin Code");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickFromPickWorksheetForWhseInternalPickAfterRegisterMovementWithVariant()
    begin
        // Setup.
        Initialize();
        PickFromPickWorksheetForWhseInternalPickAfterRegisterMovementWithVariant(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickFromPickWorksheetForWhseInternalPickAfterRegisterMovementWithVariant()
    begin
        // Setup.
        Initialize();
        PickFromPickWorksheetForWhseInternalPickAfterRegisterMovementWithVariant(true);  // TRUE for Register Warehouse Pick.
    end;

    local procedure PickFromPickWorksheetForWhseInternalPickAfterRegisterMovementWithVariant(RegisterWarehousePick: Boolean)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhsePickRequest: Record "Whse. Pick Request";
        Quantity: Decimal;
    begin
        // Setup: Create two Items with Variant. Update Inventory using Warehouse Journal. Create and Release Warehouse Internal Pick. Create Movement from Movement Worksheet for two Items.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithVariant(Item, ItemVariant);
        CreateItemWithVariant(Item2, ItemVariant2);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, ItemVariant.Code);
        UpdateInventoryUsingWhseJournal(Bin, Item2, Quantity, ItemVariant2.Code);
        CreateAndReleaseWarehouseInternalPickWithMultipleLines(
          LocationWhite.Code, LocationWhite."To-Production Bin Code", Item."No.", Item2."No.", Quantity, ItemVariant.Code, ItemVariant2.Code);
        LibraryWarehouse.CreateBin(Bin2, LocationWhite.Code, LibraryUtility.GenerateGUID(), Bin."Zone Code", Bin."Bin Type Code");
        FindAdjustmentBin(Bin3, LocationWhite);
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, Bin3, Item."No.", ItemVariant.Code, Quantity);
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, Bin2, Item2."No.", ItemVariant2.Code, Quantity);
        WhseWorksheetName.Get(WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name, WhseWorksheetLine."Location Code");
        CreateMovementFromMovementWorksheetLine(WhseWorksheetName, LocationWhite.Code, Item."No.", Item2."No.");

        // Register the Movement and Get Warehouse Document on Pick Worksheet.
        WarehouseActivityLine.SetFilter("Item No.", Item."No." + '|' + Item2."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '', WarehouseActivityLine."Activity Type"::Movement);
        GetWarehouseDocumentOnWhseWorksheetLine(WhseWorksheetName, LocationWhite.Code, WhsePickRequest."Document Type"::"Internal Pick");

        // Exercise.
        CreatePickFromPickWorksheet(WhseWorksheetName, Item."No.", Item2."No.", 0);  // Taking 0 for MaxNoOfLines.

        // Verify: Pick is created for Item for which Movement was done on Pick Zone.
        VerifyWarehousePickLines(
          WarehouseActivityLine."Source Document"::" ", '', Item2."No.", Quantity, ItemVariant2.Code, Bin2.Code,
          LocationWhite."To-Production Bin Code");

        // Verify: Pick is not created for Item for which Movement was done on Adjustment Zone.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        FilterWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '', WarehouseActivityLine."Activity Type"::Pick);
        Assert.IsTrue(WarehouseActivityLine.IsEmpty, WarehouseActivityLineMustBeEmptyTxt);

        if RegisterWarehousePick then begin
            // Exercise.
            WarehouseActivityLine.SetRange("Item No.", Item2."No.");
            AutoFillQuantityToHandleOnWhsePickLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '');
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '', WarehouseActivityLine."Activity Type"::Pick);

            // Verify.
            VerifyRegisteredPickLines(
              "Warehouse Activity Source Document"::" ", '', Item2."No.", Quantity, ItemVariant2.Code, Bin2.Code,
              LocationWhite."To-Production Bin Code");  // 0 required for blank Source Document.
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentAsInvoiceWithDifferentPurchaseUnitOfMeasureAndLotNo()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // Setup: Create Item with different Purchase Unit Of Measure and Lot Tracking. Create and register Put-Away from Purchase Order. Create and register Pick from Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithLotItemTrackingCode(Item, true, LibraryUtility.GetGlobalNoSeriesCode());  // Taking TRUE for Lot.
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        UpdatePurchaseUnitOfMeasureOnItem(Item, ItemUnitOfMeasure.Code);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        LotNo :=
          CreateAndRegisterPutAwayFromPurchaseOrder(
            Bin, ItemTrackingMode::AssignLotNo, Item."No.", LocationWhite.Code, Quantity, WorkDate(), true, false);
        CreateAndRegisterPickFromSalesOrder(
          SalesHeader, Item."No.", Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", LocationWhite.Code, true, ReservationMode::" ");  // Value required for the test.

        // Exercise.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", true);

        // Verify: Posted Sales Invoice Line and Item ledger entry.
        VerifySalesInvoiceLine(Item."No.", Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", Item."Base Unit of Measure");  // Value required for the test.
        VerifyItemLedgerEntryForLotNo(
          Item."No.", ItemLedgerEntry."Entry Type"::Sale, -Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", LotNo);  // Value required for the test.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentWithSerialNoAndItemTrackingNotEnabledOnItem()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create and release Purchase Order with Serial No. Create and register Put-Away from Purchase Order. Create Pick from Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(5);
        CreateItemWithLotItemTrackingCode(Item, false, '');  // Freeentry Code with Lot as False.
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateAndRegisterPutAwayFromPurchaseOrder(
          Bin, ItemTrackingMode::AssignSerialNo, Item."No.", LocationWhite.Code, Quantity, WorkDate(), true, false);
        CreatePickFromSalesOrder(SalesHeader, '', Item."No.", Quantity, LocationWhite.Code, true, ReservationMode::" ");
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // Exercise.
        asserterror WarehouseActivityLine.Validate("Serial No.", LibraryUtility.GenerateGUID());

        // Verify.
        Assert.ExpectedError(StrSubstNo(WhseItemTrackingNotEnabledErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerNo,ItemTrackingSummaryPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PostShipmentFromSalesOrderWithSerialNoReservation()
    var
        Bin: Record Bin;
        Item: Record Item;
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create and release Purchase Order with Serial No. Create and register Put-Away from Purchase Order. Create and register Pick from Sales Order with Reservation.
        Initialize();
        Quantity := LibraryRandom.RandInt(5);
        CreateItemWithLotItemTrackingCode(Item, false, '');  // Freeentry Code with Lot as False.
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateAndRegisterPutAwayFromPurchaseOrder(
          Bin, ItemTrackingMode::AssignSerialNo, Item."No.", LocationWhite.Code, Quantity, WorkDate(), true, false);
        CreateAndRegisterPickFromSalesOrder(
          SalesHeader, Item."No.", Quantity, LocationWhite.Code, true, ReservationMode::ReserveFromCurrentLine);  // Taking TRUE for Reservation.

        // Exercise.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", true);

        // Verify.
        VerifyItemLedgerEntryForSerialNo(ItemLedgerEntry."Entry Type"::Sale, Item."No.", '', -1, -Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickByGetSourcePurchaseReturnOrderWithVariant()
    begin
        // Setup.
        Initialize();
        ShipmentAfterRegisterPickByGetSourcePurchaseReturnOrderWithVariant(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostShipmentAfterRegisterPickByGetSourcePurchaseReturnOrderWithVariant()
    begin
        // Setup.
        Initialize();
        ShipmentAfterRegisterPickByGetSourcePurchaseReturnOrderWithVariant(true);  // Taking TRUE for PostWhseShipment.
    end;

    local procedure ShipmentAfterRegisterPickByGetSourcePurchaseReturnOrderWithVariant(PostWhseShipment: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create Item with Variant. Create and release Purchase Return Order. Create Warehouse Shipment by Get Source Document. Create Pick from Warehouse Shipment.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithVariant(Item, ItemVariant);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, ItemVariant.Code);

        // Exercise.
        CreateAndRegisterPickFromPurchaseReturnOrder(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity, ItemVariant.Code);

        // Verify.
        VerifyRegisteredPickLines(
          RegisteredWhseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.", Item."No.", Quantity,
          ItemVariant.Code, Bin.Code, LocationWhite."Shipment Bin Code");

        if PostWhseShipment then begin
            // Exercise.
            PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.", false);

            // Verify.
            VerifyPostedWhseShipmentLine(
              PostedWhseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.", Item."No.", Quantity, ItemVariant.Code);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickByGetSourceTransferOrderWithVariant()
    begin
        // Setup.
        Initialize();
        ShipmentAfterRegisterPickByGetSourceTransferOrderWithVariant(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostShipmentAfterRegisterPickByGetSourceTransferOrderWithVariant()
    begin
        // Setup.
        Initialize();
        ShipmentAfterRegisterPickByGetSourceTransferOrderWithVariant(true);  // Taking TRUE for PostWhseShipment.
    end;

    local procedure ShipmentAfterRegisterPickByGetSourceTransferOrderWithVariant(PostWhseShipment: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        ItemVariant: Record "Item Variant";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create two Items with and without Variant. Create and release Transfer Order. Create Warehouse Shipment by Get Source Document. Create Pick from Warehouse Shipment.
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateItemWithVariant(Item2, ItemVariant);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '');
        UpdateInventoryUsingWhseJournal(Bin, Item2, Quantity, ItemVariant.Code);

        // Exercise.
        CreateAndRegisterPickFromTransferOrder(
          TransferHeader, LocationWhite.Code, LocationBlue.Code, Item."No.", Item2."No.", Quantity, ItemVariant.Code);

        // Verify.
        VerifyRegisteredPickLines(
          RegisteredWhseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", Quantity, '', Bin.Code,
          LocationWhite."Shipment Bin Code");
        VerifyRegisteredPickLines(
          RegisteredWhseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item2."No.", Quantity, ItemVariant.Code,
          Bin.Code, LocationWhite."Shipment Bin Code");

        if PostWhseShipment then begin
            // Exercise.
            PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", false);

            // Verify.
            VerifyPostedWhseShipmentLine(
              PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", Quantity, '');
            VerifyPostedWhseShipmentLine(
              PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item2."No.", Quantity, ItemVariant.Code);
        end;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickFromSalesOrderAfterAutoReserveWithBinCodeModifiedOnPutAwayLine()
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Bin2: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create Warehouse Receipt from Purchase Order. Update Bin Code on Warehouse Receipt line and post it. Update Bin Code on Place line of Put Away and register it.
        // Create and release Sales Order with Auto Reserve. Create Pick from Sales Order with Auto Reserve.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        FindBin(Bin, LocationOrange.Code);
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationOrange.Code, Item."No.", Quantity);
        UpdateZoneAndBinCodeOnWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", Bin);
        PostWarehouseReceipt(WarehouseReceiptLine."No.");
        LibraryWarehouse.CreateBin(Bin2, LocationOrange.Code, LibraryUtility.GenerateGUID(), '', '');
        UpdateZoneAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Bin2);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        CreatePickFromSalesOrder(SalesHeader, '', Item."No.", Quantity, LocationOrange.Code, false, ReservationMode::AutoReserve);

        // Exercise.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // Verify.
        VerifyRegisteredPickLines(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Quantity, '', Bin2.Code, Bin.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemLedgerEntriesHandler')]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoAgainstSalesInvoiceUsingLotItemTracking()
    var
        Bin: Record Bin;
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Customer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[50];
        Quantity: Decimal;
        DocumentNo: Code[20];
    begin
        // Setup: Create Item Tracking Code, Create Tracked Item, Create and Post Warehouse Receipt from Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithLotItemTrackingCode(Item, true, LibraryUtility.GetGlobalNoSeriesCode());  // Taking TRUE for Lot.
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        LotNo :=
          CreateAndRegisterPutAwayFromPurchaseOrder(
            Bin, ItemTrackingMode::AssignLotNo, Item."No.", LocationWhite.Code, Quantity, WorkDate(), true, false);

        // Register Put Away. Create and Release Sales Order. Create Pick from Warehouse Shipment. Register Pick. Post Warehouse Shipment. Create and Release Credit Memo.
        LibrarySales.CreateCustomer(Customer);
        CreatePickFromSalesOrder(SalesHeader, Customer."No.", Item."No.", Quantity, LocationWhite.Code, true, ReservationMode::" ");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);  // Post as Invoice.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::ApplyFromItemEntry);  // ItemTrackingMode used in ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);  // Enqueue LotNo for ItemTrackingPageHandler.
        CreateAndReleaseSalesCreditMemo(SalesHeader, Customer."No.", Item."No.", Quantity, LocationWhite.Code);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // Verify: Verify Item Ledger Entries and Posted Sales Credit Memo Line.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type"::"Purchase Receipt", Item."No.", LocationWhite.Code,
          LotNo, '', Quantity, 0, WorkDate());  // Value required for Test.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Sale, ItemLedgerEntry."Document Type"::"Sales Shipment", Item."No.", LocationWhite.Code, LotNo, '',
          -Quantity, 0, WorkDate());  // Value required for Test.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Sale, ItemLedgerEntry."Document Type"::"Sales Return Receipt", Item."No.", LocationWhite.Code,
          LotNo, '', Quantity, Quantity, WorkDate());
        VerifyPostedSalesCreditMemoLine(DocumentNo, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentAfterPostProductionJournalFromReleasedProductionOrder()
    var
        Bin: Record Bin;
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Customer: Record Customer;
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Item with Production BOM, Create and Post Warehouse Receipt from Purchase Order and register Warehouse Activity.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        Quantity2 := LibraryRandom.RandInt(10);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        CreateItemWithProductionBOM(ParentItem, ComponentItem, ProductionBOMLine);
        CreateAndRegisterPutAwayFromPurchaseOrder(
          Bin, ItemTrackingMode, ComponentItem."No.", LocationWhite.Code, (ProductionBOMLine."Quantity per" * Quantity) + Quantity2,
          WorkDate(), false, false);

        // Create and Refresh Production Order. Create and Register Pick from Production Order.
        LibrarySales.CreateCustomer(Customer);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", Quantity, LocationWhite.Code, WorkDate());
        CreateAndRegisterPickFromProductionOrder(ProductionOrder, true);  // Register as TRUE.
        OpenProductionJournal(ProductionOrder);  // Open and post Production Journal. Posting is done in ProductionJournalHandler function.

        // Create and Release Sales Order, Create Pick from Warehouse Shipment. Register Warehouse Activity.
        CreatePickFromSalesOrder(SalesHeader, Customer."No.", ComponentItem."No.", Quantity2, LocationWhite.Code, false, ReservationMode::" ");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // Exercise: Post Warehouse Shipment.
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Registered Warehouse Activity Lines and Item Ledger Entries.
        VerifyRegisteredPickLine(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
          RegisteredWhseActivityLine."Action Type"::Place, ComponentItem."No.",
          Quantity * ProductionBOMLine."Quantity per", '', LocationWhite."From-Production Bin Code");
        VerifyRegisteredPickLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          RegisteredWhseActivityLine."Action Type"::Place, ComponentItem."No.", Quantity2, '', LocationWhite."Shipment Bin Code");
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type"::"Purchase Receipt", ComponentItem."No.",
          LocationWhite.Code, '', '', (Quantity * ProductionBOMLine."Quantity per") + Quantity2, 0, WorkDate());
        // Value required for test.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Sale, ItemLedgerEntry."Document Type"::"Sales Shipment", ComponentItem."No.", LocationWhite.Code,
          '', '', -Quantity2, 0, WorkDate());  // Value required for test.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Consumption, ItemLedgerEntry."Document Type"::" ", ComponentItem."No.", LocationWhite.Code, '', '',
          -(Quantity * ProductionBOMLine."Quantity per"), 0, WorkDate());  // Value required for test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPutAwayAfterSplitPutAwayLine()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayAndPickAfterSplitPutAwayLine(false);  // Use Pick as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickAfterSplitPutAwayLine()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayAndPickAfterSplitPutAwayLine(true);  // Use Pick as True.
    end;

    local procedure RegisterPutAwayAndPickAfterSplitPutAwayLine(Pick: Boolean)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Create Item with Purchase UOM. Create and post Warehouse Receipt from Purchase Order. Split Put Away Line.
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        UpdatePurchaseUnitOfMeasureOnItem(Item, ItemUnitOfMeasure.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        Quantity2 := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithItemTracking(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity + Quantity2, false);  // Value required for test.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false, ItemTrackingMode::" ");
        FindBinForPickZone(Bin, LocationWhite.Code, false);  // BULK Zone.
        UpdateZoneAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Bin);
        UpdateBinCodeAfterSplitPutAwayLine(Bin2, PurchaseHeader."No.", Quantity2);

        // Exercise: Register Put Away.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify.
        VerifyRegisteredPutAwayLine(
          WarehouseActivityLine."Action Type"::Take, PurchaseHeader."No.", Item."No.", LocationWhite."Receipt Bin Code",
          Quantity + Quantity2);  // Value required for test.
        VerifyRegisteredPutAwayLine(WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Item."No.", Bin.Code, Quantity2);
        VerifyRegisteredPutAwayLine(WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Item."No.", Bin2.Code, Quantity);

        if Pick then begin
            // Exercise.
            CreateAndRegisterPickFromSalesOrder(
              SalesHeader, Item."No.", (Quantity + Quantity2) * ItemUnitOfMeasure."Qty. per Unit of Measure", LocationWhite.Code, false,
              ReservationMode::" ");  // Value required for test.

            // Verify.
            VerifyRegisteredPickLine(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Action Type"::Take,
              Item."No.", Quantity, '', Bin2.Code);
            VerifyRegisteredPickLine(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Action Type"::Place,
              Item."No.", Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", '', Bin2.Code);  // Value required for test.
        end;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickReservedSalesOrderWithoutAlwaysCreatePickLine()
    begin
        // Setup.
        Initialize();
        PickReservedSalesOrderAlwaysCreatePickLine(false);  // Use AlwaysCreatePickLine as False.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickReservedSalesOrderWithAlwaysCreatePickLine()
    begin
        // Setup.
        Initialize();
        PickReservedSalesOrderAlwaysCreatePickLine(true);  // Use AlwaysCreatePickLine as True.
    end;

    local procedure PickReservedSalesOrderAlwaysCreatePickLine(AlwaysCreatePickLine: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        OldAlwaysCreatePickLine: Boolean;
        Quantity: Decimal;
    begin
        // Update Always Create Pick Line on Location. Create Item with Sales and Purchase Unit Of Measure. Create and register Put Away from Purchase Order. Create and release Sales Order.
        UpdateAlwaysCreatePickLineOnLocation(LocationWhite, OldAlwaysCreatePickLine, AlwaysCreatePickLine);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemWithSalesAndPurchaseUnitOfMeasure(Item);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        CreateAndRegisterPutAwayFromPurchaseOrder(Bin, ItemTrackingMode, Item."No.", LocationWhite.Code, Quantity, WorkDate(), false, false);
        CreateAndReleaseSalesOrder(SalesHeader, '', Item."No.", Quantity, LocationWhite.Code, '', false, ReservationMode::AutoReserve);

        if LocationWhite."Always Create Pick Line" then begin
            // Exercise.
            CreateAndRegisterPickFromSalesOrderAfterUpdateZoneAndBinOnPickLine(SalesHeader2, Bin, Item."No.", LocationWhite.Code, Quantity);

            // Verify.
            VerifyRegisteredPickLines(
              RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader2."No.", Item."No.", Quantity, '', Bin.Code,
              LocationWhite."Shipment Bin Code");
        end else begin
            // Exercise.
            asserterror CreatePickFromSalesOrder(
                SalesHeader2, '', Item."No.", Quantity, LocationWhite.Code, false, ReservationMode::" ");

            // Verify.
            Assert.ExpectedError(NothingToHandleErr);
        end;

        // Tear down.
        UpdateAlwaysCreatePickLineOnLocation(LocationWhite, OldAlwaysCreatePickLine, OldAlwaysCreatePickLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseReceiptFromTransferOrderWithMultipleLots()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayFromTransferOrderWithMultipleLots(false, false);  // Use PartialPutAway and RemainingPutAway as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPartialPutAwayFromTransferOrderWithMultipleLots()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayFromTransferOrderWithMultipleLots(true, false);  // Use PartialPutAway as True and RemainingPutAway as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,WhseSourceCreateDocumentPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterRemainingPutAwayFromTransferOrderWithMultipleLots()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayFromTransferOrderWithMultipleLots(true, true);  // Use PartialPutAway and RemainingPutAway as True.
    end;

    local procedure RegisterPutAwayFromTransferOrderWithMultipleLots(PartialPutAway: Boolean; RemainingPutAway: Boolean)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        WarehouseEntry: Record "Warehouse Entry";
        LotNo: Code[50];
        LotNo2: Code[20];
        Quantity: Decimal;
    begin
        // Create Item with Lot Item Tracking Code. Create and post Transfer Order as Ship with Item Tracking.
        CreateItemWithLotItemTrackingCode(Item, true, LibraryUtility.GetGlobalNoSeriesCode());  // Taking TRUE for Lot.
        Quantity := LibraryRandom.RandDec(100, 2);
        LotNo :=
          CreateAndPostItemJournalLineWithItemTracking(
            LocationBlue.Code, '', Item."Base Unit of Measure", ItemTrackingMode::AssignLotNo, Item."No.", Quantity, WorkDate(), false, false);  // Different Expiration Date as FALSE.
        LotNo2 :=
          CreateAndPostItemJournalLineWithItemTracking(
            LocationBlue.Code, '', Item."Base Unit of Measure", ItemTrackingMode::AssignLotNo, Item."No.", Quantity, WorkDate(), false, false);  // Different Expiration Date as FALSE.
        CreateAndPostTransferOrderAsShip(
          TransferHeader, LocationBlue.Code, LocationWhite.Code, Item."No.", Quantity + Quantity, true, WorkDate(), WorkDate(), true);  // Value required for test. Use Tracking and Posting as True.

        // Exercise.
        CreateAndPostWarehouseReceiptFromTransferOrder(TransferHeader);

        // Verify.
        Bin.Get(LocationWhite.Code, LocationWhite."Receipt Bin Code");
        VerifyWarehouseEntry(Bin, WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", LotNo, Quantity);
        VerifyWarehouseEntry(Bin, WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", LotNo2, Quantity);

        if PartialPutAway then begin
            // Exercise.
            FindBinForPickZone(Bin2, LocationWhite.Code, true);  // PICK Zone.
            RegisterPutAwayAfterDeletePutAwayLines(Bin2, TransferHeader."No.", LotNo2);

            // Verify.
            VerifyWarehouseEntry(Bin, WarehouseEntry."Entry Type"::Movement, Item."No.", LotNo, -Quantity);
            VerifyWarehouseEntry(Bin2, WarehouseEntry."Entry Type"::Movement, Item."No.", LotNo, Quantity);
        end;

        if RemainingPutAway then begin
            // Exercise.
            CreatePutAwayFromPostedWarehouseReceipt(Item."No.");
            RegisterPutAwayAfterDeletePutAwayLines(Bin2, TransferHeader."No.", LotNo);

            // Verify.
            VerifyWarehouseEntry(Bin, WarehouseEntry."Entry Type"::Movement, Item."No.", LotNo2, -Quantity);
            VerifyWarehouseEntry(Bin2, WarehouseEntry."Entry Type"::Movement, Item."No.", LotNo2, Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayFromSalesReturnOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item and Customer. Create and post Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostSalesOrder(Customer, Item, LocationRed.Code, Quantity);

        // Exercise.
        CreateInventoryPutAwayFromSalesReturnOrderAfterGetPostedDocumentLinesToReverse(SalesHeader, Customer."No.");

        // Verify.
        VerifyInventoryPutAwayLine(Item, SalesHeader."No.", LocationRed.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure PostTransferOrderWithDifferentDimensionCode()
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Default Dimension. Create and post Purchase Order as Receive. Create and post Transfer Order as Ship.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemWithDefaultDimension(DefaultDimension, DimensionValue);
        CreateAndPostPurchaseOrderAsReceive(DefaultDimension."No.", LocationBlue.Code, Quantity);
        CreateAndPostTransferOrderAsShip(
          TransferHeader, LocationBlue.Code, LocationRed.Code, DefaultDimension."No.", Quantity, false, WorkDate(), WorkDate(), true);  // Use Tracking as FALSE and Posting as TRUE.

        // Exercise.
        PostTransferOrderAsReceiveAfterUpdateDimensionOnTransferLine(TransferHeader, DimensionValue.Code);

        // Verify: Use 0 for Remaining Quantity.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Transfer, ItemLedgerEntry."Document Type"::"Transfer Shipment", DefaultDimension."No.",
          LocationBlue.Code, '', DefaultDimension."Dimension Value Code", -Quantity, 0, WorkDate());
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Transfer, ItemLedgerEntry."Document Type"::"Transfer Shipment", DefaultDimension."No.",
          LocationInTransit.Code, '', DefaultDimension."Dimension Value Code", Quantity, 0, WorkDate());
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Transfer, ItemLedgerEntry."Document Type"::"Transfer Receipt", DefaultDimension."No.",
          LocationInTransit.Code, '', DimensionValue.Code, -Quantity, 0, WorkDate());
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Transfer, ItemLedgerEntry."Document Type"::"Transfer Receipt", DefaultDimension."No.",
          LocationRed.Code, '', DimensionValue.Code, Quantity, Quantity, WorkDate());
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostItemJournalOnMultipleLocationWithLot()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
        LotNo: Code[50];
    begin
        // Setup: Create Item with Lot and Replenishment System.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        LotNo := LibraryUtility.GenerateGUID();
        CreateLotItemWithReplenishmentSystem(Item, Item."Replenishment System"::Purchase);

        // Exercise.
        CreateAndPostItemJournalLineWithManualLotNo(
          ItemJournalLine, Item."No.", LocationYellow.Code, Quantity, WorkDate(), LotNo, true, Item."Base Unit of Measure");  // TRUE for posting.
        CreateAndPostItemJournalLineWithManualLotNo(
          ItemJournalLine, Item."No.", LocationGreen.Code, Quantity + LibraryRandom.RandInt(50),
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), LotNo, true, Item."Base Unit of Measure"); // TRUE for posting.

        // Verify.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type", Item."No.", LocationYellow.Code, LotNo, '', Quantity,
          Quantity, WorkDate());
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type", Item."No.", LocationGreen.Code, LotNo, '',
          ItemJournalLine.Quantity, ItemJournalLine.Quantity, ItemJournalLine."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryPageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderWithFirmPlannedProductionOrderWithSKU()
    begin
        // Setup.
        Initialize();
        TransferOrderWithFirmPlannedProductionOrder(false);  // Posting as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryPageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostTransferOrderWithFirmPlannedProductionOrderWithSKU()
    begin
        // Setup.
        Initialize();
        TransferOrderWithFirmPlannedProductionOrder(true);  // Posting as TRUE.
    end;

    local procedure TransferOrderWithFirmPlannedProductionOrder(BeforePosting: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
        LotNo: Code[50];
    begin
        // Create and post Item Journal Line with Production BOM. Create and refresh Released and Firm Planned Production Orders.
        Quantity := LibraryRandom.RandInt(50);
        LotNo := LibraryUtility.GenerateGUID();
        CreateAndRefreshMultipleProdOrdersAfterPostItemJnl(ItemJournalLine, Quantity, LotNo, LocationYellow.Code, LocationGreen.Code);

        // Exercise.
        if BeforePosting then
            CreateAndPostTransferOrderAsShip(
              TransferHeader, LocationGreen.Code, LocationYellow.Code, ItemJournalLine."Item No.", Quantity, true,
              ItemJournalLine."Posting Date",
              CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', ItemJournalLine."Posting Date"), false) // Use Tracking as True and Posting as False.
        else
            CreateAndPostTransferOrderAsShip(
              TransferHeader, LocationGreen.Code, LocationYellow.Code, ItemJournalLine."Item No.", Quantity, true,
              ItemJournalLine."Posting Date",
              CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', ItemJournalLine."Posting Date"), true);  // Use Tracking and Posting as True.

        // Verify.
        VerifyReservationEntry(
          ItemJournalLine."Item No.", LocationYellow.Code, ReservationEntry."Reservation Status"::Surplus, Quantity, TransferHeader."No.");
        if BeforePosting then
            VerifyReservationEntry(
              ItemJournalLine."Item No.", LocationGreen.Code, ReservationEntry."Reservation Status"::Surplus, -Quantity, TransferHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryPageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryBeforePostItemJournal()
    begin
        // Setup.
        Initialize();
        PostItemJournalWithProductionBOMAndTransferOrder(false);  // PostItemJournal as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryPageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryAfterPostItemJournal()
    begin
        // Setup.
        Initialize();
        PostItemJournalWithProductionBOMAndTransferOrder(true);  // PostItemJournal as TRUE.
    end;

    local procedure PostItemJournalWithProductionBOMAndTransferOrder(PostItemJournal: Boolean)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
        LotNo: Code[50];
    begin
        // Create Item with Lot and Replenishment System. Create and refresh Released and Firm Planned Production Orders. Create and post Transfer Order.
        Quantity := LibraryRandom.RandInt(50);
        LotNo := LibraryUtility.GenerateGUID();
        CreateAndRefreshMultipleProdOrdersAfterPostItemJnl(ItemJournalLine, Quantity, LotNo, LocationYellow.Code, LocationGreen.Code);
        CreateAndPostTransferOrderAsShip(
          TransferHeader, LocationGreen.Code, LocationYellow.Code, ItemJournalLine."Item No.", Quantity, true, ItemJournalLine."Posting Date",
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', ItemJournalLine."Posting Date"), true);  // Use Tracking and Posting as True.

        // Exercise.
        CreateAndPostItemJournalLineWithManualLotNo(
          ItemJournalLine, ItemJournalLine."Item No.", LocationYellow.Code, Quantity, WorkDate(), LotNo, PostItemJournal,
          ItemJournalLine."Unit of Measure Code");

        // Verify.
        if PostItemJournal then
            VerifyEmptyReservationEntry(ItemJournalLine."Item No.", Item.TableCaption())
        else
            VerifyReservationEntry(
              ItemJournalLine."Item No.", LocationYellow.Code, ReservationEntry."Reservation Status"::Prospect, Quantity, '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryPageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateRegenerativePlanAfterShipTransferOrder()
    begin
        // Setup.
        Initialize();
        PostTransferOrderAfterCalculateRegenerativePlan(false);  // Post Transfer Order as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryPageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReceiveTransferOrderAfterCalculateRegenerativePlan()
    begin
        // Setup.
        Initialize();
        PostTransferOrderAfterCalculateRegenerativePlan(true);  // Post Transfer Order as TRUE.
    end;

    local procedure PostTransferOrderAfterCalculateRegenerativePlan(PostTransferOrder: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
        LotNo: Code[50];
    begin
        // Create Item with Lot and Replenishment System. Create and post Item Journal Line and Transfer Order with Production BOM. Run Calculate Regenerative Plan report.
        Quantity := LibraryRandom.RandInt(50);
        LotNo := LibraryUtility.GenerateGUID();
        CreateAndRefreshMultipleProdOrdersAfterPostItemJnl(ItemJournalLine, Quantity, LotNo, LocationYellow.Code, LocationGreen.Code);
        CreateAndPostTransferOrderAsShip(
          TransferHeader, LocationGreen.Code, LocationYellow.Code, ItemJournalLine."Item No.", Quantity, true, ItemJournalLine."Posting Date",
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', ItemJournalLine."Posting Date"), true);  // Use Tracking and Posting as True.
        CreateAndPostItemJournalLineWithManualLotNo(
          ItemJournalLine, ItemJournalLine."Item No.", LocationYellow.Code, Quantity, WorkDate(), LotNo, true,
          ItemJournalLine."Unit of Measure Code");  // Use Posting as True.
        RunCalculateRegenerativePlan(
          ItemJournalLine."Item No.", LocationYellow.Code,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', TransferHeader."Receipt Date"));

        if PostTransferOrder then begin
            // Exercise.
            PostTransferOrderAsReceive(TransferHeader, Quantity);

            // Verify.
            VerifyEmptyReservationEntry(ItemJournalLine."Item No.", TransferHeader."No.");
        end else
            // Verify.
            VerifyReservationEntry(
            ItemJournalLine."Item No.", LocationYellow.Code, ReservationEntry."Reservation Status"::Surplus, Quantity, TransferHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure UOMConversionAfterPostItemJournal()
    begin
        // Setup.
        Initialize();
        PostInvtPickFromRPOUsingFirmPlannedProdOrder(false);  // IsProductionOrder as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,CreateInventoryPutAwayPickHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UOMConversionAfterPostInventoryPickUsingRPO()
    begin
        // Setup.
        Initialize();
        PostInvtPickFromRPOUsingFirmPlannedProdOrder(true);  // IsProductionOrder as True.
    end;

    local procedure PostInvtPickFromRPOUsingFirmPlannedProdOrder(IsProductionOrder: Boolean)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        Bin: Record Bin;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
        LotNo: Code[50];
    begin
        // Create Item with Lot Item Tracking Code and create Item Unit of Measure.
        Quantity := LibraryRandom.RandInt(50);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');  // Bin Type and Zone code are blank.
        CreateItemWithLotItemTrackingCode(Item, true, LibraryUtility.GetGlobalNoSeriesCode());  // Taking TRUE for Lot.
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");

        // Exercise.
        LotNo :=
          CreateAndPostItemJournalLineWithItemTracking(
            LocationSilver.Code, Bin.Code, ItemUnitOfMeasure.Code, ItemTrackingMode::AssignLotNo, Item."No.", Quantity, WorkDate(), false, false);  // Different Expiration Date as False.

        // Verify.
        VerifyItemLedgerEntryForLotNo(
          Item."No.", ItemLedgerEntry."Entry Type"::Purchase, ItemUnitOfMeasure."Qty. per Unit of Measure" * Quantity, LotNo);  // Value required for the test.

        if IsProductionOrder then begin
            // Exercise.
            CreateAndRefreshFirmPlannedProductionOrderUsingLot(
              ProductionOrder, Item."No.", Quantity, LocationBlue.Code, LocationSilver.Code, ItemUnitOfMeasure.Code);
            CreateInvtPickFromRPOUsingFirmPlannedProdOrder(ProductionOrder);
            PostWarehouseActivity(ProductionOrder."No.", Quantity);

            // Verify.
            VerifyItemLedgerEntryForLotNo(
              Item."No.", ItemLedgerEntry."Entry Type"::Consumption, -Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", LotNo);  // Value required for the test.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedProductionOrderWithProductionBin()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ParentItem: Record Item;
        MachineCenter: Record "Machine Center";
        OperationNo: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Create and certify BOM. Create Item with Routing and Production BOM. Update Bin on Work Center and Machine Center.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);
        OperationNo := CreateRoutingSetup(RoutingLine, WorkCenter, MachineCenter);
        LibraryInventory.CreateItem(Item);
        CreateAndCertifyBOM(ProductionBOMHeader, ProductionBOMLine, Item."Base Unit of Measure", Item."No.", Quantity);
        CreateItemWithRoutingAndProductionBOM(ParentItem, ProductionBOMHeader."No.", RoutingLine."Routing No.");
        UpdateBinOnLocation(LocationSilver);
        UpdateWorkCenter(WorkCenter, LocationSilver);
        UpdateMachineCenter(MachineCenter, LocationSilver);

        // Exercise.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", Quantity, LocationSilver.Code, WorkDate());  // Value required for the test.

        // Verify.
        VerifyProdOrderRoutingLine(LocationSilver, OperationNo, "Capacity Type"::"Machine Center", MachineCenter."No.");
        VerifyProdOrderRoutingLine(LocationSilver, RoutingLine."Operation No.", "Capacity Type"::"Work Center", WorkCenter."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedProductionOrderAfterUpdateBinOnComponent()
    begin
        // Setup.
        Initialize();
        UpdateBinOnComponentLineAfterRefreshProdOrder(false) // Pick as false.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhsePickOnProdOrderAfterUpdateBinOnComponentLine()
    begin
        // Setup.
        Initialize();
        UpdateBinOnComponentLineAfterRefreshProdOrder(true) // Pick as True.
    end;

    local procedure UpdateBinOnComponentLineAfterRefreshProdOrder(Pick: Boolean)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ParentItem: Record Item;
        MachineCenter: Record "Machine Center";
        Bin: Record Bin;
        Quantity: Decimal;
    begin
        // Create Routing and Create And Certify BOM. Create Item with Routing and Production BOM. Update Inventory using Warehouse Journal.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);
        CreateRoutingSetup(RoutingLine, WorkCenter, MachineCenter);
        LibraryInventory.CreateItem(Item);
        CreateAndCertifyBOM(ProductionBOMHeader, ProductionBOMLine, Item."Base Unit of Measure", Item."No.", Quantity);
        CreateItemWithRoutingAndProductionBOM(ParentItem, ProductionBOMHeader."No.", RoutingLine."Routing No.");
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // Pick as TRUE.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity * Quantity, '');  // Variant Code as blank and calculated value of Quantity required.

        // Exercise.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", Quantity, LocationWhite.Code, WorkDate());

        // Verify.
        VerifyProductionOrderComponent(ProductionOrder."No.", Item."No.", Quantity * Quantity);  // Value required for Expected Quantity.

        if Pick then begin
            // Exercise.
            CreateAndUpdateBinOnProductionOrderComponent(ProdOrderComponent, LocationWhite, ProductionOrder."No.");
            CreateAndRegisterPickFromProductionOrder(ProductionOrder, false);  // Register as false.

            // Verify.
            VerifyWarehousePickLine(
              WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
              WarehouseActivityLine."Action Type"::Take, Item."No.", ProdOrderComponent."Expected Quantity", '', Bin.Code);
            VerifyWarehousePickLine(
              WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
              WarehouseActivityLine."Action Type"::Place, Item."No.", ProdOrderComponent."Expected Quantity", '',
              ProdOrderComponent."Bin Code");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineWithDefaultQuantityToShipAsBlank()
    begin
        // Setup.
        Initialize();
        PurchaseOrderWithDefaultQuantityToShipAsBlank(false);  // Carry Out Action Message as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithDefaultQuantityToShipAsBlank()
    begin
        // Setup.
        Initialize();
        PurchaseOrderWithDefaultQuantityToShipAsBlank(true);  // Carry Out Action Message as TRUE.
    end;

    local procedure PurchaseOrderWithDefaultQuantityToShipAsBlank(CarryOutActionMsg: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DefaultQuantityToShip: Option;
    begin
        // Update Default Quantity to Ship on Sales and Receivables Setup. Create Sales Order with Drop Shipment.
        DefaultQuantityToShip :=
          UpdateDefaultQuantityToShipOnSalesReceivablesSetup(SalesReceivablesSetup."Default Quantity to Ship"::Blank);
        LibraryInventory.CreateItem(Item);
        CreateSalesOrderWithPurchaseCode(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2), true, false);

        // Exercise.
        GetSalesOrderForDropShipmentOnRequisitionWorksheet(SalesLine);

        // Verify.
        VerifyRequisitionLine(Item."No.", SalesLine.Quantity);

        if CarryOutActionMsg then begin
            // Exercise.
            PostPurchOrderAfterCarryOutActionMsgOnReqWorksheet(Item."No.", SalesLine.Quantity / 2);  // Calculated Value Required.

            // Verify.
            VerifySalesLine(SalesLine."Document No.", Item."No.", SalesLine.Quantity, 0);  // Value Required for test.
        end;

        // Tear down.
        UpdateDefaultQuantityToShipOnSalesReceivablesSetup(DefaultQuantityToShip);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteToInvoiceWithBlockedItem()
    var
        Customer: Record Customer;
        FromSalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // [SCENARIO 297560] Quote with blocked item cannot be converted into Invoice.
        // [FEATURE] [Sales] [Quote] [Invoice] [Item]
        Initialize();

        // [GIVEN] Item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales Quote is created
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateSalesQuoteHeaderWithLines(FromSalesHeader, Customer, Item, 1, 1);

        // [GIVEN] Item's Attribute "Blocked" is changed to TRUE
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Run Sales-Quote to Invoice
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Quote to Invoice", FromSalesHeader);

        // [THEN] Error "Blocked must be equal to 'No'..Current value is 'Yes'." has been thrown
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteToInvoiceWithBlockedResource()
    var
        Customer: Record Customer;
        FromSalesHeader: Record "Sales Header";
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 297560] Quote with blocked resource cannot be converted into Invoice.
        // [FEATURE] [Sales] [Quote] [Invoice] [Resource]
        Initialize();

        // [GIVEN] Resource is created
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Sales Quote is created
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateSalesQuoteHeader(FromSalesHeader, Customer);
        LibrarySales.CreateSalesLine(SalesLine, FromSalesHeader, SalesLine.Type::Resource, Resource."No.", 1);

        // [GIVEN] Resource's Attribute "Blocked" is changed to TRUE
        Resource.Validate(Blocked, true);
        Resource.Modify(true);

        // [WHEN] Run Sales-Quote to Invoice
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Quote to Invoice", FromSalesHeader);

        // [THEN] Error "Blocked must be equal to 'No'..Current value is 'Yes'." has been thrown
        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteMakeOrderWithBlockedItem()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        OldCreditWarning: Option;
        OldStockOutWarning: Boolean;
    begin
        // Setup: Create Sales Quote. Update Blocked as TRUE on Item.
        Initialize();
        OldCreditWarning := UpdateCreditWarningOnSalesAndReceivablesSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        OldStockOutWarning := UpdateStockOutWarningOnSalesReceivablesSetup(false);
        LibraryInventory.CreateItem(Item);
        CreateSalesQuote(SalesHeader, Item."No.");
        UpdateBlockedAsTrueOnItem(Item);

        // Exercise.
        asserterror LibrarySales.QuoteMakeOrder(SalesHeader);

        // [THEN] Error "Blocked must be equal to 'No'..Current value is 'Yes'." has been thrown
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));

        // Tear down.
        UpdateCreditWarningOnSalesAndReceivablesSetup(OldCreditWarning);
        UpdateStockOutWarningOnSalesReceivablesSetup(OldStockOutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteToOrderWithBlockedResource()
    var
        Customer: Record Customer;
        FromSalesHeader: Record "Sales Header";
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 297560] Quote with blocked resource cannot be converted into Order.
        // [FEATURE] [Sales] [Quote] [Order] [Resource]
        Initialize();

        // [GIVEN] Resource is created
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Sales Quote is created
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateSalesQuoteHeader(FromSalesHeader, Customer);
        LibrarySales.CreateSalesLine(SalesLine, FromSalesHeader, SalesLine.Type::Resource, Resource."No.", 1);

        // [GIVEN] Resource's Attribute "Blocked" is changed to TRUE
        Resource.Validate(Blocked, true);
        Resource.Modify(true);

        // [WHEN] Run Sales-Quote to Order
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", FromSalesHeader);

        // [THEN] Error "Blocked must be equal to 'No'..Current value is 'Yes'." has been thrown
        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderMakeOrderWithBlockedItem()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        OldCreditWarning: Option;
        OldStockOutWarning: Boolean;
    begin
        // Setup: Create Blanket Sales Order. Update Blocked as TRUE on Item.
        Initialize();
        OldCreditWarning := UpdateCreditWarningOnSalesAndReceivablesSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        OldStockOutWarning := UpdateStockOutWarningOnSalesReceivablesSetup(false);
        LibraryInventory.CreateItem(Item);
        CreateBlanketSalesOrder(SalesHeader, Item."No.");
        UpdateBlockedAsTrueOnItem(Item);

        // Exercise.
        asserterror LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // [THEN] Error "Blocked must be equal to 'No'..Current value is 'Yes'." has been thrown
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));

        // Tear down.
        UpdateCreditWarningOnSalesAndReceivablesSetup(OldCreditWarning);
        UpdateStockOutWarningOnSalesReceivablesSetup(OldStockOutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderToOrderWithBlockedResource()
    var
        Customer: Record Customer;
        FromSalesHeader: Record "Sales Header";
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 297560] Blanket Order with blocked resource cannot be converted into Order.
        // [FEATURE] [Sales] [Blanket Order] [Order] [Resource]
        Initialize();

        // [GIVEN] Resource is created
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Blanket Sales Order is created
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(FromSalesHeader, FromSalesHeader."Document Type"::"Blanket Order", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, FromSalesHeader, SalesLine.Type::Resource, Resource."No.", 1);

        // [GIVEN] Resource's Attribute "Blocked" is changed to TRUE
        Resource.Validate(Blocked, true);
        Resource.Modify(true);

        // [WHEN] Run Blanket Sales Order to Order
        asserterror CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", FromSalesHeader);

        // [THEN] Error "Blocked must be equal to 'No'..Current value is 'Yes'." has been thrown
        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteMakeOrderWithBlockedItem()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Create Purchase Quote. Update Blocked as TRUE on Item.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseQuote(PurchaseHeader, Item."No.");
        UpdateBlockedAsTrueOnItem(Item);

        // Exercise.
        asserterror LibraryPurchase.QuoteMakeOrder(PurchaseHeader);

        // [THEN] Error "Blocked must be equal to 'No'..Current value is 'Yes'." has been thrown
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderMakeOrderWithBlockedItem()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Create Blanket Purchase Order. Update Blocked as TRUE on Item.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateBlanketPurchaseOrder(PurchaseHeader, Item."No.");
        UpdateBlockedAsTrueOnItem(Item);

        // Exercise.
        asserterror LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // [THEN] Error "Blocked must be equal to 'No'..Current value is 'Yes'." has been thrown
        Assert.ExpectedTestFieldError(Item.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostItemJournalWithItemOnDifferentBins()
    begin
        // Setup.
        Initialize();
        ItemJournalWithItemOnDifferentBins(false);  // Create Pick as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickWithItemOnDifferentBins()
    begin
        // Setup.
        Initialize();
        ItemJournalWithItemOnDifferentBins(true);  // Create Pick as TRUE.
    end;

    local procedure ItemJournalWithItemOnDifferentBins(CreatePick: Boolean)
    var
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
        Bin2: Record Bin;
        LotNo: Code[50];
        LotNo2: Code[20];
        Quantity: Decimal;
    begin
        // Create Item with Lot and Serial Item Tracking Code. Create Multiple Bins.
        CreateItemTrackingCode(ItemTrackingCode, true, true, false);  // Serial and Lot as TRUE.
        LotNo := LibraryUtility.GenerateGUID();
        LotNo2 := LibraryUtility.GenerateGUID();
        Quantity := 1;
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);
        LibraryWarehouse.CreateBin(Bin, LocationBlack.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin2, LocationBlack.Code, LibraryUtility.GenerateGUID(), '', '');

        // Exercise.
        LotNo :=
          CreateAndPostItemJournalLineWithItemTracking(
            LocationBlack.Code, Bin.Code, Item."Base Unit of Measure", ItemTrackingMode::AssignAutoSerialNo, Item."No.", Quantity, WorkDate(),
            false, true);  // Update Lot No. as TRUE.
        LotNo2 :=
          CreateAndPostItemJournalLineWithItemTracking(
            LocationBlack.Code, Bin2.Code, Item."Base Unit of Measure", ItemTrackingMode::AssignAutoSerialNo, Item."No.", Quantity, WorkDate(),
            false, true);  // Update Lot No. as TRUE.

        // Verify.
        VerifyItemLedgerEntryForSerialNo(ItemLedgerEntry."Entry Type"::Purchase, Item."No.", LotNo, 1, Quantity);
        VerifyItemLedgerEntryForSerialNo(ItemLedgerEntry."Entry Type"::Purchase, Item."No.", LotNo2, 1, Quantity);

        if CreatePick then begin
            // Exercise: Create pick and assign serial/lot on the Pick lines.
            CreatePickFromSalesOrder(SalesHeader, '', Item."No.", 2 * Quantity, LocationBlack.Code, false, ReservationMode::" ");

            FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.");
            ItemLedgerEntry.SetRange("Lot No.", LotNo2);
            ItemLedgerEntry.FindFirst();

            FilterWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);
            WarehouseActivityLine.FindSet();
            repeat
                WarehouseActivityLine.Validate("Serial No.", ItemLedgerEntry."Serial No.");
                WarehouseActivityLine.Validate("Lot No.", ItemLedgerEntry."Lot No.");
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;

            // Verify.
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorHistBuyFromFactBoxAsNonEditable()
    var
        VendorHistBuyFromFactBox: TestPage "Vendor Hist. Buy-from FactBox";
    begin
        // Setup.
        Initialize();

        // Exercise.
        VendorHistBuyFromFactBox.OpenView();
        VendorHistBuyFromFactBox.FILTER.SetFilter("No.", LibraryPurchase.CreateVendorNo());

        // Verify.
        Assert.IsFalse(VendorHistBuyFromFactBox.CueQuotes.Editable(), VendorHistBuyFromFactBoxMustBeNonEditableTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayAfterRegisterWhseShipmentFromPurchaseOrder()
    begin
        // Setup.
        Initialize();
        WarehouseAcitivityLineAfterRegisterPutAway(false);  // Is Pick as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickAfterRegisterPutAwayFromPurchaseOrder()
    begin
        // Setup.
        Initialize();
        WarehouseAcitivityLineAfterRegisterPutAway(true);  // Is Pick as TRUE.
    end;

    local procedure WarehouseAcitivityLineAfterRegisterPutAway(IsPick: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Bin: Record Bin;
        Quantity: Decimal;
    begin
        // Create Item Unit Of Measure. Update Purchase Unit of Measure on Item. Find Bin for Pick Zone.
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        UpdatePurchaseUnitOfMeasureOnItem(Item, ItemUnitOfMeasure.Code);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.

        // Exercise: Create and Release Purchase Order with Item Tracking. Create and Post Warehouse Receipt from Purchase Order. Update Zone and Bin Code On Warehouse Activity Line.
        CreateAndReleasePurchaseOrderWithItemTracking(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity, false);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false, ItemTrackingMode::" ");
        UpdateZoneAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Bin);

        // Verify.
        VerifyPutAwayLine(
          PurchaseHeader."No.", WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity, LocationWhite."Receipt Bin Code");
        VerifyPutAwayLine(PurchaseHeader."No.", WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity, Bin.Code);

        if IsPick then begin
            // Exercise.
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Put-away");
            CreatePickFromSalesOrder(SalesHeader, '', Item."No.", Quantity / 2, LocationWhite.Code, false, ReservationMode::" ");

            // Verify.
            FilterWarehouseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);
            WarehouseActivityLine.SetRange(Quantity, Quantity / 2);
            Assert.AreEqual(1, WarehouseActivityLine.Count, OrderExpectedTxt);
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostShipmentWithNotPickedAssembleToOrderItem()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Test to verify posting Warehouse Shipment for other picked items should be allowed when there is a not picked Assemble-to-Order item
        Initialize();

        // Setup.
        CreateAssemblyItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemAndUpdateInventory(Item2, Quantity); // Create a normal item and update inventory to bin in PICK zone
        CreateSalesOrderAndWareshouseShipment(SalesHeader, Item."No.", Item2."No.", Quantity); // Create sales order with 2 lines, 1st line for assembly item, 2nd line for normal item
        CreateAndRegisterPickFromWareshouseShipment(SalesHeader."No."); // Create and register pick for the normal item

        // Exercise and Verify: Post shipment successfully.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickWithMutipleLotItemTrackingAndDifferentBins()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        // Test to verify Register Pick successfully with mutiple Lot Item Tracking and different Bins

        // Setup: Create a Purchase Order with 2 lines, each lines assigned 2 Lot No.
        // Post Warehouse Receipt, then split Put-Away Line and update Zone Code and Bin Code for Place line, Register Put-away
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        WarehousePutAwayWithTwoLotItemTracking(Item, Item2, Quantity);

        // Create a Sales Order with 4 lines and assign Lot No.
        // Post Warehourse Shipment, then Create Pick
        CreateAndReleaseSalesOrderWithSelectLotItemTracking(SalesHeader, Item, Item2, Quantity);
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Exercise: Register Pick
        // Verify: No error pops up, Register Pick successfully
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // Exercise: Post Warehouse Shipment
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", true);

        // Verify: Lot No. and Quantity is correct in Item Ledger Entries
        // Lot No. in sales posted ILE should be same with the Lot No. in Purchase posted ILE.
        VerifyItemLedgerEntriesForLotNo(
          ItemLedgerEntry."Entry Type"::Sale, Item."No.",
          FindLotNoOnItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No."), -Quantity / 5);
        VerifyItemLedgerEntriesForLotNo(
          ItemLedgerEntry."Entry Type"::Sale, Item2."No.",
          FindLotNoOnItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item2."No."), -Quantity / 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePurchaseCodeWithDropShipmentAfterPostWarehouseShipment()
    begin
        // Verify Error message should be pop up when updating Purchase Code to Drop Shipment after posting Warehouse Shipment for sales order
        UpdatePurchaseCodeAfterPostWarehouseShipment(true, false); // Set DropShipment as TRUE,SpecialOrder as FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePurchaseCodeWithSpecialOrderAfterPostWarehouseShipment()
    begin
        // Verify Error message should be pop up when updating Purchase Code to Special Order after posting Warehouse Shipment for sales order
        UpdatePurchaseCodeAfterPostWarehouseShipment(false, true); // Set DropShipment as FALSE,SpecialOrder as TRUE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateQuantityAndPurchaseCodeAfterPostWarehouseShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);

        // Setup: Post Warehourse Shipment and reopen Sales Order
        PostWarehouseShipmentAndReopenSalesOrder(SalesHeader, Item, Quantity);

        // Exercise: Update Quantity and Purchasing Code to Drop Shipment
        // Verify: Update successfully
        Quantity2 := LibraryRandom.RandDec(100, 2);
        FindSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.Validate(Quantity, Quantity + Quantity2);
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(true, false));
        SalesLine.Modify(true);

        // Exercise: Get Sales Order for Drop Shipment on Requisition Worksheet and Carry Out
        GetSalesOrderForDropShipmentOnRequisitionWorksheet(SalesLine);
        CarryOutActionMsgOnRequisitionWorksheet(Item."No.");

        // Verify: Verify Purchase Line.
        VerifyPurchaseLine(PurchaseLine, Item."No.", Quantity2);

        // Exercise: Post Purchase Order and Sales Order.
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false); // Receive as TRUE.
        SalesHeader.Find(); // Require for Posting.
        LibrarySales.PostSalesDocument(SalesHeader, true, true); // Post as Ship and Invoice.

        // Verify: Verify Posted Sales Invoice Line.
        VerifyPostedSalesInvoiceLine(Item."No.", Quantity + Quantity2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithDropShipmentAndNegativeQuantity()
    begin
        // Test to verify no error pops up when you post Sales Invoice for Drop Shipment with negative quantity
        PostSalesInvoiceWithPurchasingCodeAndNegativeQuantity(true, false); // Set DropShipment as TRUE,SpecialOrder as FALSE
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithSpecialOrderAndNegativeQuantity()
    begin
        // Test to verify no error pops up when you post Sales Invoice for Special Order with negative quantity
        PostSalesInvoiceWithPurchasingCodeAndNegativeQuantity(false, true); // Set DropShipment as FALSE,SpecialOrder as TRUE
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SplitLineOnWarehousePickWithMultipleUOMAndLotTracking()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        UOM: array[3] of Code[10];
        LotNo: array[3] of Code[20];
        Quantity: array[3] of Decimal;
        QtyPerUOM: Decimal;
        QtyToHandle: Decimal;
        QtyToHandle2: Decimal;
        BinCode: Code[20];
        BinCode2: Code[20];
    begin
        // Test to verify there is no error when Splitting Line on Warehouse Pick with multiple UOM and Lot tracking

        // Setup: Create a Purchase Order with 3 lines with Lot Tracking, create Whse. Receipt and register Put-away
        // 1st Line: Quantity, Lot1, UOM1
        // 2nd Line: Quantity, Lot1, UOM2 (UOM2 is "Base Unit of Measure")
        // 3rd Line: Quantity, Lot2, UOM2
        Initialize();
        CreateLocationSetup();
        Quantity[1] := LibraryRandom.RandIntInRange(10, 100);
        Quantity[2] := Quantity[1];
        Quantity[3] := Quantity[1];
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LotNo[1];
        LotNo[3] := LibraryUtility.GenerateGUID();
        ReleasePurchaseOrderAndRegisterPutAwayWithMultipleUOMAndLotTracking(Item, Quantity, UOM, LotNo, QtyPerUOM);

        // Create a Transfer Oder with 2 lines with Lot Tracking
        // 1st Line: Qty, Lot1, UOM1
        // 2nd Line: (Quantity - Qty) * QtyPerUOM + 2 * Quantity, Lot1 & Lot2, UOM2
        ReleaseTransferOrderAndCreatePick(
          TransferHeader, LocationWhite.Code, LocationBlue.Code, Item."No.", Quantity, QtyPerUOM, UOM[1], LotNo, ReservationMode::" ");

        // Exercise: Find Take and Place line with Lot No in Warehouse Pick, set the Bin Code
        // Verify: There is no error pops up when setting same Bin Code between Take & Place for breakbulk line and 2 split Take lines.
        FindAndSplitTakePlaceLines(Item, LotNo[1], TransferHeader."No.", WarehouseActivityLine."Action Type"::Place, QtyToHandle, BinCode);
        FindAndSplitTakePlaceLines(Item, LotNo[2], TransferHeader."No.", WarehouseActivityLine."Action Type"::Take, QtyToHandle2, BinCode2);

        // Exercise: Register Pick
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // Verify: Verify the Split lines are correct.
        VerifyRegisteredPickLineForQtyAndBinCode(
          Item, TransferHeader."No.", RegisteredWhseActivityLine."Action Type"::Place, LotNo[1], QtyToHandle, BinCode);
        VerifyRegisteredPickLineForQtyAndBinCode(
          Item, TransferHeader."No.", RegisteredWhseActivityLine."Action Type"::Take, LotNo[2], QtyToHandle2, BinCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithWorkCenterAndLocationHaveBinCode()
    var
        WorkCenter: Record "Work Center";
        ParentItemNo: Code[20];
        ItemNo: Code[20];
    begin
        // Verify when we both set up Bin Code on Work Center and Location, after Calculate Regenerative Plan,
        // Bin Code on Requistion Line for BOM Item should be From-Production Bin Code on Work Center.
        // Bin Code on Planning Component for Component Item should be To-Production Bin Code on Work Center.

        // Setup: Create and certify BOM. Create Item with Routing and Production BOM. Update Bin on Work Center. Update Bin on location
        Initialize();
        InitSetupForProdBOMWithRouting(WorkCenter, ItemNo, ParentItemNo, LocationSilver.Code);
        UpdateBinOnWorkCenter(WorkCenter, LocationSilver.Code);
        UpdateBinOnLocation(LocationSilver);

        // Exercise: Create Sales Order for BOM Item and Calculate Regenerative Plan from Sales Order for BOM Item.
        // Verify: Verify the Bin Code on Requisition Line and Planning Component.
        CalcRegenPlanForSalesOrderAndVerifyBinCode(
          LocationSilver.Code, ParentItemNo, WorkCenter."From-Production Bin Code", WorkCenter."To-Production Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithLocationHasBinCodeAndDefaultBin()
    var
        BinContent: Record "Bin Content";
        WorkCenter: Record "Work Center";
        ParentItemNo: Code[20];
        ItemNo: Code[20];
    begin
        // Verify when we both set up Bin Code on Location, and set the Default Bin for Component Item.
        // After Calculate Regenerative Plan, Bin Code on Requistion Line for BOM Item should be From-Production Bin Code on Location.
        // Bin Code on Planning Component for Component Item should be To-Production Bin Code on Location.

        // Setup: Create and certify BOM. Create Item with Routing and Production BOM. Update Bin on Location. Create Default Bin for Component Item.
        Initialize();
        InitSetupForProdBOMWithRouting(WorkCenter, ItemNo, ParentItemNo, LocationSilver.Code);
        UpdateBinOnLocation(LocationSilver);
        CreateDefaultBinContent(
          BinContent, ItemNo, LocationSilver.Code, LibraryRandom.RandInt(10), LibraryRandom.RandIntInRange(50, 100));

        // Exercise: Create Sales Order for BOM Item and Calculate Regenerative Plan from Sales Order for BOM Item.
        // Verify: Verify the Bin Code on Requisition Line and Planning Component.
        CalcRegenPlanForSalesOrderAndVerifyBinCode(
          LocationSilver.Code, ParentItemNo, LocationSilver."From-Production Bin Code", LocationSilver."To-Production Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanAssemblyItemLocationHasFromBinCode()
    var
        Location: Record Location;
        ParentItem: Record Item;
        ComponentItem: Record Item;
    begin
        // [FEATURE] [Assembly] [Bin] [Planning]
        // [SCENARIO 212823] Calc. regen. plan for assembly item at location From/To-Assembly Bin Codes specified sets "From-Assembly Bin Code" in "Requisition Line" and "To-Assembly Bin Code" in "Planning Component"
        Initialize();

        // [GIVEN] Location "L" with specified From/To-Assembly Bin Codes
        CreateLocationWithAssemblyBins(Location);

        // [GIVEN] Assembly Item "AI" and its component "CI"
        CreateAssemblyItemWithBOM(ParentItem, ComponentItem);

        // [GIVEN] SKU for "I" at "L" with specified safety stock as demand
        CreateLotForLotSKUWithSafetyStock(Location.Code, ParentItem."No.", 1);

        // [WHEN] Calculate regenerative plan for "AI"
        RunCalculateRegenerativePlan(ParentItem."No.", Location.Code, WorkDate());

        // [THEN] "Requisition Line"."Bin Code" is equal "L"."From-Assembly Bin Code", "Planning Component"."Bin Code" is equal "L"."To-Assembly Bin Code"
        VerifyBinCodeOnReqLineAndPlanningComponent(ParentItem."No.", Location."From-Assembly Bin Code", Location."To-Assembly Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanAssemblyItemLocationHasFromBinCodeAndDefaultBinContent()
    var
        Location: Record Location;
        ParentItem: Record Item;
        ComponentItem: Record Item;
        BinContent: Record "Bin Content";
    begin
        // [FEATURE] [Assembly] [Bin] [Planning]
        // [SCENARIO 212823] Calc. regen. plan for assembly item at location From/To-Assembly Bin Codes specified sets "From-Assembly Bin Code" in "Requisition Line" and "To-Assembly Bin Code" in "Planning Component" when Default Bin Content exists
        Initialize();

        // [GIVEN] Location "L" with specified From/To-Assembly Bin Codes
        CreateLocationWithAssemblyBins(Location);

        // [GIVEN] Assembly Item "AI" and its component "CI"
        CreateAssemblyItemWithBOM(ParentItem, ComponentItem);

        // [GIVEN] SKU for "AI" at "L" with specified safety stock as demand
        CreateLotForLotSKUWithSafetyStock(Location.Code, ParentItem."No.", 1);

        // [GIVEN] Default Bin Content for "CI" at "L"
        CreateDefaultBinContent(BinContent, ComponentItem."No.", Location.Code, 0, 0);

        // [WHEN] Calculate regenerative plan for "AI"
        RunCalculateRegenerativePlan(ParentItem."No.", Location.Code, WorkDate());

        // [THEN] "Requisition Line"."Bin Code" is equal "L"."From-Assembly Bin Code", "Planning Component"."Bin Code" is equal "L"."To-Assembly Bin Code"
        VerifyBinCodeOnReqLineAndPlanningComponent(ParentItem."No.", Location."From-Assembly Bin Code", Location."To-Assembly Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderLocationHasFromBinCodeAndDefaultBinContent()
    var
        Location: Record Location;
        ComponentItem: Record Item;
        BinContent: Record "Bin Content";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Production Order] [Bin] [Planning]
        // [SCENARIO 212823] After Update "Prod. Order Line"."Item No." "Prod. Order Line" has "Bin Code" equal to Location."From-Production Bin Code" if "From-Production Bin Code" is specified
        Initialize();

        // [GIVEN] Location "L" with specified "From-Production Bin Code"
        CreateLocationWithFromProdBinCode(Location);

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(ComponentItem);

        // [GIVEN] Default Bin Content for "I" at "L"
        CreateDefaultBinContent(BinContent, ComponentItem."No.", Location.Code, 0, 0);

        // [GIVEN] Realeased Production Order with line "L"
        CreateProdOrderLineAtLocation(ProdOrderLine, Location.Code);

        // [WHEN] Update "L"."Item No." by "I"
        ProdOrderLine.Validate("Item No.", ComponentItem."No.");

        // [THEN] "L"."Bin Code" is equal to "L"."From-Production Bin Code"
        ProdOrderLine.TestField("Bin Code", Location."From-Production Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderLocationHasDefaultBinContent()
    var
        Location: Record Location;
        ComponentItem: Record Item;
        BinContent: Record "Bin Content";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Production Order] [Bin] [Planning]
        // [SCENARIO 212823] After Update "Prod. Order Line"."Item No." "Prod. Order Line" has "Bin Code" equal to (default) "Bin Content"."Bin Code" if "From-Production Bin Code" isn't specified
        Initialize();

        // [GIVEN] Bin Mandatory Location "L"
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(ComponentItem);

        // [GIVEN] Default Bin Content "BC" for "I" at "L"
        CreateDefaultBinContent(BinContent, ComponentItem."No.", Location.Code, 0, 0);

        // [GIVEN] Realeased Production Order with line "L"
        CreateProdOrderLineAtLocation(ProdOrderLine, Location.Code);

        // [WHEN] Update "L"."Item No." by "I"
        ProdOrderLine.Validate("Item No.", ComponentItem."No.");

        // [THEN] "Prod. Order Line"."Bin Code" is equal to "BC"."Bin Code"
        ProdOrderLine.TestField("Bin Code", BinContent."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckProdOrderBinWhereBinIsSetForBothLocationAndItem()
    var
        ProductionOrder: Record "Production Order";
        Location: Record Location;
        BinContent: Record "Bin Content";
    begin
        Initialize();

        CreateLocationWithFromProdBinCode(Location);
        CreateProductionOrderWithItem(ProductionOrder);
        CreateDefaultBinContent(
          BinContent, ProductionOrder."Source No.", Location.Code,
          LibraryRandom.RandInt(10), LibraryRandom.RandIntInRange(50, 100));

        ProductionOrder.Validate("Location Code", Location.Code);

        Assert.AreEqual(ProductionOrder."Bin Code", Location."From-Production Bin Code", BinValidationErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckProdOrderBinWhereBinIsSetForLocationOnly()
    var
        ProductionOrder: Record "Production Order";
        Location: Record Location;
    begin
        Initialize();

        CreateLocationWithFromProdBinCode(Location);
        CreateProductionOrderWithItem(ProductionOrder);

        ProductionOrder.Validate("Location Code", Location.Code);

        Assert.AreEqual(ProductionOrder."Bin Code", Location."From-Production Bin Code", BinValidationErr);
    end;

    [Test]
    [HandlerFunctions('InboundOutboundHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickFromMultipleBinsWithUOMConversionsAndReservations()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: array[3] of Code[20];
        Quantity: array[3] of Decimal;
    begin
        // Test to verify total Quantity(Base) in Shipment Bin on Registered Whse. Activity Lines is correct after register pick from multiple bins with UOM conversions and reservations.

        // Setup: Create and released Purchase Order, create and Register splited Put-away.
        Initialize();
        CreateItemWithSalesAndPurchaseUnitOfMeasure(Item);
        ItemUnitOfMeasure.Get(Item."No.", Item."Purch. Unit of Measure");
        Quantity[1] := LibraryRandom.RandIntInRange(10, 100);
        Quantity[2] := Round(Quantity[1] / LibraryRandom.RandIntInRange(3, 5), 1);
        Quantity[3] := (Quantity[1] - Quantity[2]) * ItemUnitOfMeasure."Qty. per Unit of Measure";
        LotNo[1] := '';
        LotNo[2] := '';
        LotNo[3] := '';

        CreateAndReleasePurchaseOrderWithItemTracking(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity[1], false); // Value required for test, UsingTracking=FALSE
        CreateAndRegisterSplitedPutAwayFromReleasedPurchaseOrder(
          PurchaseHeader, '', LibraryRandom.RandInt(8)); // Value isn't important but need to less than Quantity[1].

        // Create and Reserve Transfer Oder with 2 lines, create Pick for the Transfer Order.
        // 1st Line: Quantity[2], ItemUnitOfMeasure.Code
        // 2nd Line: Quantity[3], Item."Base Unit of Measure"
        ReleaseTransferOrderAndCreatePick(
          TransferHeader, LocationWhite.Code, LocationBlue.Code, Item."No.", Quantity,
          ItemUnitOfMeasure."Qty. per Unit of Measure", ItemUnitOfMeasure.Code, LotNo, ReservationMode::AutoReserve);

        // Exercise: Register the Pick created. No error pops up.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer",
          TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify: Verify the total Quanity(Base) in Shipment Bin is correct.
        VerifyTotalQuantityBaseOnRegisteredPickLines(
          LocationWhite."Shipment Bin Code", Item."No.", Quantity[1] * ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ExplodeBOMHandler,ConfirmHandlerAsTrue')]
    [Scope('OnPrem')]
    procedure UndoShipmentWithMultipleAssembleToOrderItems()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
        PrevAutomaticCostAdjValue: Enum "Automatic Cost Adjustment Type";
        SalesShipmentNo: Code[20];
    begin
        // Verify that Shipment can be undone for Posted Warehouse Shipment with multiple lines with Items with 'Assemble-To-Order' Assembly Policy.

        Initialize();

        // Setup.
        PrevAutomaticCostAdjValue := UpdateAutomaticCostAdj(PrevAutomaticCostAdjValue::Always);

        CreateAssemblyItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        CreateAssemblyItem(Item2, Item2."Assembly Policy"::"Assemble-to-Order");
        LibraryInventory.UpdateInventoryPostingSetup(LocationBlue);
        PostStockForComponents(Item, LibraryRandom.RandIntInRange(10, 100));
        PostStockForComponents(Item2, LibraryRandom.RandIntInRange(10, 100));

        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateMsg, WorkDate())); // Enqueue for message triggered by sales line for assembly item
        CreateSalesOrder(SalesHeader, Item."No.", Item2."No.", Quantity, LocationBlue.Code); // Create sales order with 2 lines.
        SalesShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Exercise and Verify.
        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateMsg, WorkDate())); // Enqueue for ConfirmHandler.
        UndoSalesShipmentLine(SalesShipmentNo, StrSubstNo(BeforeWorkDateMsg, WorkDate()));
        VerifyItemLedgerEntryForLotNo(Item2."No.", ItemLedgerEntry."Entry Type"::Sale, -Quantity, '');

        // Teardown.
        UpdateAutomaticCostAdj(PrevAutomaticCostAdjValue);
    end;

    [Test]
    [HandlerFunctions('ExplodeBOMHandler,ConfirmHandlerAsTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchSalesPostingWithATOChangesPostingDateForLinkedAssembly()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        NewPostingDate: Date;
    begin
        // [FEATURE] [Sales Order] [Assemble-to-Order] [Batch Post]
        // [SCENARIO 382212] Batch sales posting with a new posting date updates the posting date of an assembly order linked to a sales document being posted.
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Assembly Item "I" with ATO assembly policy. All components of "I" are in stock.
        CreateAssemblyItem(Item, Item."Assembly Policy"::"Assemble-to-Order");
        LibraryInventory.UpdateInventoryPostingSetup(LocationBlue);
        PostStockForComponents(Item, LibraryRandom.RandIntInRange(10, 100));

        // [GIVEN] Sales Order "SO" of item "I" with automatically generated linked Assembly Header "AH". Posting date for both documents = "D1".
        CreateAndReleaseSalesOrderWithAssemblyItem(SalesHeader, Item."No.");

        // [WHEN] Run batch posting of "SO" with a direction to replace the posting date to "D2".
        NewPostingDate := LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20);
        BatchPostSalesOrderWithNewPostingDate(SalesHeader, NewPostingDate);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Posting date of "AH" is updated to "D2".
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Assembly Output", Item."No.");
        ItemLedgerEntry.TestField("Posting Date", NewPostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AsmHeaderPostingDateIsUpdatedWithSalesHeaderPostingDate()
    var
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Sales Order] [Assembly] [UT]
        // [SCENARIO 382212] SynchronizeAsmHeader function invoked for the sales document, makes the posting date of the linked assembly equal to the posting date of the sales.
        Initialize();

        // [GIVEN] Sales Order with linked Assembly Order.
        // [GIVEN] Posting date of the sales = "D1". Posting date of the assembly = "D2".
        MockSalesOrder(SalesHeader);
        MockAssemblyHeader(AssemblyHeader);
        MockATOLink(SalesHeader, AssemblyHeader);

        // [WHEN] Invoke SynchronizeAsmHeader function for the Sales Order.
        SalesHeader.SynchronizeAsmHeader();

        // [THEN] Posting date of the assembly is updated to "D1".
        AssemblyHeader.Find();
        AssemblyHeader.TestField("Posting Date", SalesHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransitCanBeEnabledAfterItemTrackingLinesAreSet()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Transfer] [Direct Transfer]
        // [SCENARIO 292368] User can enable Direct Transfer on Transfer Header after setting Item Tracking lines
        Initialize();

        // [GIVEN] Item with Lot Item Tracking code
        CreateItemWithLotItemTrackingCode(Item, true, LibraryUtility.GetGlobalNoSeriesCode());

        // [GIVEN] Item had previous inventory with LotNo
        Quantity := LibraryRandom.RandDec(10, 2);
        LotNo := CreateAndPostItemJournalLineWithItemTracking(
            LocationBlue.Code, '', Item."Base Unit of Measure", ItemTrackingMode::AssignLotNo, Item."No.", Quantity, WorkDate(), false, false);

        // [GIVEN] Transfer Order with Transfer Line for this Item is created
        CreateTransferOrder(TransferHeader, LocationBlue.Code, LocationSilver.Code, Item."No.", Quantity, WorkDate(), WorkDate());

        // [GIVEN] Item Tracking was set for this item with LotNo and Quantity accounting for all of the Transfer Line Quantity
        UpdateItemTrackingOnTransferLineWithLotNo(TransferHeader."No.", LotNo);
        // UI Handled by ItemTrackingLinesPageHandler

        // [WHEN] Direct transfer is set to True on Transfer Header
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);

        // [THEN] Direct Transfer was set without an error
        TransferHeader.TestField("Direct Transfer", true);

        // [THEN] Document can be posted
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SplitLineInWhsePickWithMultipleLines()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ActivityNo: Code[20];
    begin
        // [FEATURE] [Split Line]
        // [SCENARIO 330820] Split Line functionality renumbers Lines in Whse Activity
        // [SCENARIO 330820] when it is not possible to insert new Line No between the existing ones
        Initialize();
        ActivityNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Warehouse Pick had the following Lines:
        // [GIVEN] Line No 20000 with 5 PCS
        // [GIVEN] Line No 29998 with 6 PCS
        // [GIVEN] Line No 29999 with 7 PCS and Qty. to Handle 4 PCS
        // [GIVEN] Line No 30000 with 8 PCS
        MockWhseActivityLineWithQty(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, ActivityNo, 20000, 5, 5, 0);
        MockWhseActivityLineWithQty(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, ActivityNo, 29998, 6, 6, 0);
        MockWhseActivityLineWithQty(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, ActivityNo, 30000, 8, 8, 0);
        MockWhseActivityLineWithQty(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, ActivityNo, 29999, 7, 7, 4);

        // [WHEN] Split Line with No = 29999
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);

        // [THEN] Line with 5 PCS has Line No = 10000
        // [THEN] Line with 6 PCS has Line No = 20000
        // [THEN] Line with 4 PCS has Line No = 30000
        // [THEN] Line with 3 PCS has Line No = 35000
        // [THEN] Line with 8 PCS and Line No = 40000
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type");
        WarehouseActivityLine.SetRange("No.", ActivityNo);
        VerifyLineNoInFilteredWhseActivityLine(WarehouseActivityLine, 5, 10000);
        VerifyLineNoInFilteredWhseActivityLine(WarehouseActivityLine, 6, 20000);
        VerifyLineNoInFilteredWhseActivityLine(WarehouseActivityLine, 4, 30000);
        VerifyLineNoInFilteredWhseActivityLine(WarehouseActivityLine, 3, 35000);
        VerifyLineNoInFilteredWhseActivityLine(WarehouseActivityLine, 8, 40000);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandler,ItemTrackingLinesPageHandler,WhseShipmentCreatePickRequestPageHandler,MessageHandler')]
    procedure WhseShptLinesWithItemTrackingArePickedFirst()
    var
        Item: Record Item;
        BulkBin: Record Bin;
        PickBin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BulkLotNo: Code[20];
        PickLotNo: Code[20];
        SortingSequenceNo: array[2] of Integer;
        Qty: Decimal;
    begin
        // [FEATURE] [Warehouse Shipment] [Item Tracking] [Pick]
        // [SCENARIO 409256] Warehouse shipment lines with item tracking are picked first by demand.
        Initialize();
        BulkLotNo := LibraryUtility.GenerateGUID();
        PickLotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Location with directed put-away and pick.
        // [GIVEN] Locate bin "PICK" in pick zone, bin "BULK" in bulk zone.
        FindBinForPickZone(BulkBin, LocationWhite.Code, false);
        FindBinForPickZone(PickBin, LocationWhite.Code, true);

        // [GIVEN] Lot-tracked item.
        CreateItemWithLotItemTrackingCode(Item, true, '');

        // [GIVEN] Post 100 pcs to "BULK" bin, assign lot "BULKLOT".
        LibraryVariableStorage.Enqueue(BulkLotNo);
        LibraryVariableStorage.Enqueue(2 * Qty);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(BulkBin, Item."No.", 2 * Qty, true);

        // [GIVEN] Post 50 pcs to "PICK" bin, assign lot "PICKLOT".
        LibraryVariableStorage.Enqueue(PickLotNo);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(PickBin, Item."No.", Qty, true);

        // [GIVEN] Sales order with two lines -
        // [GIVEN] Line "1": quantity = 2, do not assign item tracking.
        // [GIVEN] Line "2": quantity = 50, select lot no. "PICKLOT".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationWhite.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, Item."No.", Qty);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignManualLotNo);
        LibraryVariableStorage.Enqueue(PickLotNo);
        SalesLine[2].OpenItemTrackingLines();

        // [GIVEN] Release the sales order, create warehouse shipment, release it.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [WHEN] Create pick with "Prioritize lines with item tracking" = TRUE.
        LibraryVariableStorage.Enqueue(PickActivityTxt);
        WarehouseShipmentLine.CreatePickDoc(WarehouseShipmentLine, WarehouseShipmentHeader);

        // [THEN] No pick lines are created for the sales line "1".
        WarehouseActivityLine.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine[1]."Document Type".AsInteger(), SalesLine[1]."Document No.", SalesLine[1]."Line No.", 0, true);
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [THEN] Pick is created for sales line "2", lot no. = "PICKLOT", quantity = 50.
        WarehouseActivityLine.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine[2]."Document Type".AsInteger(), SalesLine[2]."Document No.", SalesLine[2]."Line No.", 0, true);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, Qty);
        WarehouseActivityLine.TestField("Lot No.", PickLotNo);

        // [THEN] Warehouse shipment lines are sorted as in the sales order - line "1", line "2".
        WarehouseShipmentLine.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine[1]."Document Type".AsInteger(), SalesLine[1]."Document No.", SalesLine[1]."Line No.", true);
        WarehouseShipmentLine.FindFirst();
        SortingSequenceNo[1] := WarehouseShipmentLine."Sorting Sequence No.";
        WarehouseShipmentLine.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine[2]."Document Type".AsInteger(), SalesLine[2]."Document No.", SalesLine[2]."Line No.", true);
        WarehouseShipmentLine.FindFirst();
        SortingSequenceNo[2] := WarehouseShipmentLine."Sorting Sequence No.";
        Assert.IsTrue(SortingSequenceNo[1] < SortingSequenceNo[2], 'Wrong sorting of warehouse shipment lines.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ShipmentDateOnWhseShipmentMatchesSalesOrders()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Warehouse Shipment] [Sales] [Order]
        // [SCENARIO 418330] Shipment Date in Warehouse Shipment must match Shipment Date in Sales Order.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationYellow.Code);
        SalesHeader.Validate("Shipment Date", LibraryRandom.RandDate(60));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField("Shipment Date", SalesHeader."Shipment Date");

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        WarehouseShipmentHeader.TestField("Shipment Date", SalesHeader."Shipment Date");
    end;

    [Test]
    procedure VerifyRegisterWarehousePickForAdditionalUoMWhenShippedQtyIsRounded()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        AdditionalItemUOM: Record "Item Unit of Measure";
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [SCENARIO 493233] Verify Register Warehouse Pick for additional UoM when shipped qty is rounded 
        Initialize();
        ItemJournalSetup();

        // [GIVEN] Create Item with additional UoM
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create additional UoM for Item
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(AdditionalItemUOM, Item."No.", UnitOfMeasure.Code, 7.39368);

        // [GIVEN] Set additional UoM to Sales UoM
        Item.Validate("Sales Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Create and Register Warehouse Item Journal Line
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        UpdateInventoryUsingWhseJournal(Bin, Item, 1000, '');

        // [GIVEN] Calc. Warehouse Adj. for Item and Post Item Journal
        CalcWhseAdjustmentAndPostItemJournalLine(Item);

        // [GIVEN] Create Sales Order with Item and Release
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, Item."No.", 192, LocationWhite.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Warehouse Shipment from Sales Order
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);

        // [GIVEN] Create Warehouse Pick from Warehouse Shipment
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [GIVEN] Register Pick
        RegisterWarehouseActivity(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Post Ship for Warehouse Shipment
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [GIVEN] Create and Register Warehouse Item Journal Line
        UpdateInventoryUsingWhseJournal(Bin, Item, 1000, '');

        // [GIVEN] Calc. Warehouse Adj. for Item and Post Item Journal
        CalcWhseAdjustmentAndPostItemJournalLine(Item);

        // [GIVEN] Create Warehouse Pick
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [WHEN] Register Pick
        RegisterWarehouseActivity(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [THEN] Verify Warehouse Pick is registed, and warehouse shipment is posted
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse - Shipping II");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        Clear(ItemTrackingMode);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse - Shipping II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        CreateLocationSetup();
        CreateTransferRoute();
        NoSeriesSetup();
        ItemJournalSetup();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse - Shipping II");
    end;

    local procedure UpdateAutomaticCostAdj(NewAutomaticCostAdjValue: Enum "Automatic Cost Adjustment Type") OldAutomaticCostAdjValue: Enum "Automatic Cost Adjustment Type"
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        OldAutomaticCostAdjValue := InventorySetup."Automatic Cost Adjustment";
        InventorySetup."Automatic Cost Adjustment" := NewAutomaticCostAdjValue;
        InventorySetup.Modify();
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

    local procedure CreateLocationWithAssemblyBins(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        UpdateAssemblyBinOnLocation(Location);
    end;

    local procedure AutoFillQuantityToHandleOnWhsePickLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
    end;

    local procedure AssignItemTrackingOnPurchLines(DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();

        repeat
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignTwoLotNo); // Enqueue for ItemTrackingLinesPageHandler
            PurchaseLine.OpenItemTrackingLines();
        until PurchaseLine.Next() = 0;
    end;

    local procedure CertifyProductionBOMHeader(var ProductionBOMHeader: Record "Production BOM Header")
    begin
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CarryOutActionMsgOnRequisitionWorksheet(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CalcRegenPlanForSalesOrderAndVerifyBinCode(LocationCode: Code[10]; ParentItemNo: Code[20]; RequsitionLineBinCode: Code[20]; PalnningComponentBinCode: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateAndReleaseSalesOrder(
          SalesHeader, '', ParentItemNo, LibraryRandom.RandInt(10), LocationCode, '', false, ReservationMode::" ");

        RunCalculateRegenerativePlan(ParentItemNo, LocationCode, WorkDate());
        VerifyBinCodeOnReqLineAndPlanningComponent(ParentItemNo, RequsitionLineBinCode, PalnningComponentBinCode);
    end;

    local procedure CreateRoutingSetupWithWorkCenter(var RoutingLine: Record "Routing Line"; var WorkCenter: Record "Work Center"; LocationCode: Code[10])
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateWorkCenter(WorkCenter);
        UpdateLocationOnWorkCenter(WorkCenter, LocationCode);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '',
          CopyStr(
            LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Routing Line", RoutingLine.FieldNo("Operation No."))),
          RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateLocationWithFromProdBinCode(var Location: Record Location)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify();
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("From-Production Bin Code", Bin.Code);
        Location.Modify();
    end;

    local procedure CreateDefaultBinContent(var BinContent: Record "Bin Content"; ItemNo: Code[20]; LocationCode: Code[10]; MinQty: Decimal; MaxQty: Decimal)
    var
        Bin: Record Bin;
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(
          BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate("Bin Ranking", Bin."Bin Ranking");
        BinContent.Validate(Fixed, true);
        BinContent.Validate(Default, true);
        BinContent.Validate("Min. Qty.", MinQty);
        BinContent.Validate("Max. Qty.", MaxQty);
        BinContent.Modify(true);
    end;

    local procedure CreateInvtPickFromRPOUsingFirmPlannedProdOrder(var ProductionOrder: Record "Production Order")
    begin
        LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProductionOrder."No.");
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("Source No.", ProductionOrder."Source No.");
        ProductionOrder.FindFirst();
        LibraryVariableStorage.Enqueue(InvtPickActivitiesCreatedTxt);  // Enqueue for CreateInventoryPutAwayPickHandler.
        ProductionOrder.CreateInvtPutAwayPick();
    end;

    local procedure CreateItemWithStandardCost(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateLotForLotSKUWithSafetyStock(LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        StockkeepingUnit.Validate("Safety Stock Quantity", Quantity);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateAndCertifyBOMWithMultipleLines(var ProductionBOMHeader: Record "Production BOM Header"; UnitOfMeasureCode: Code[10]; ComponentItemNo: Code[20]; ComponentItemNo2: Code[20]; VariantCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        CreateProductionBOM(ProductionBOMHeader, ProductionBOMLine, UnitOfMeasureCode, ComponentItemNo, LibraryRandom.RandInt(10));
        CreateProductionBOMLine(ProductionBOMHeader, ComponentItemNo2, VariantCode);
        CertifyProductionBOMHeader(ProductionBOMHeader);
    end;

    local procedure CreateAndCertifyBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; UnitOfMeasureCode: Code[10]; ComponentItemNo: Code[20]; QuantityPer: Decimal)
    begin
        CreateProductionBOM(ProductionBOMHeader, ProductionBOMLine, UnitOfMeasureCode, ComponentItemNo, QuantityPer);
        CertifyProductionBOMHeader(ProductionBOMHeader);
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

    local procedure CreateAndPostItemJournalLineWithManualLotNo(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; PostingDate: Date; LotNo: Code[50]; Post: Boolean; ItemUnitOfMeasure: Code[10])
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, LocationCode, Quantity, PostingDate, '', ItemUnitOfMeasure);  // Use Blank value for Bin Code.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignManualLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        if Post then
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchaseOrderAsReceive(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateAndReleasePurchaseOrderWithItemTracking(PurchaseHeader, ItemNo, LocationCode, Quantity, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.
    end;

    local procedure CreateAndPostSalesOrder(var Customer: Record Customer; var Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        CreateAndReleaseSalesOrder(SalesHeader, Customer."No.", Item."No.", Quantity, LocationCode, '', false, ReservationMode::" ");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
    end;

    local procedure CreateAndPostTransferOrderAsShip(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; Tracking: Boolean; PostingDate: Date; ShipmentDate: Date; Post: Boolean)
    begin
        CreateAndReleaseTransferOrder(TransferHeader, FromLocationCode, ToLocationCode, ItemNo, '', Quantity, '', PostingDate, ShipmentDate);
        if Tracking then
            UpdateItemTrackingOnTransferLine(TransferHeader."No.");
        if Post then
            LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);  // Post as Ship.
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

    local procedure CreateAndPostWarehouseReceiptFromTransferOrder(var TransferHeader: Record "Transfer Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
        LibraryVariableStorage.Enqueue(StrSubstNo(TransferOrderDeletedTxt, TransferHeader."No."));  // Enqueue for MessageHandler.
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."No.");
    end;

    local procedure CreateAndRefreshFirmPlannedProductionOrderUsingLot(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; LocationCode2: Code[10]; UnitOfMeasureCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", Quantity, LocationCode, WorkDate());
        CreateProductionOrderComponent(ProdOrderComponent, ProductionOrder, ItemNo, UnitOfMeasureCode, LocationCode2);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingPageHandler.
        ProdOrderComponent.OpenItemTrackingLines();
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; DueDate: Date)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRefreshMultipleProdOrdersAfterPostItemJnl(var ItemJournalLine: Record "Item Journal Line"; Quantity: Decimal; LotNo: Code[50]; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ComponentItem: Record Item;
        QuantityPer: Decimal;
    begin
        QuantityPer := CreateLotItemWithProductionBOMAndSKU(ParentItem, ComponentItem, LocationCode, LocationCode2);

        // Calculated value of Quantity required for test.
        CreateAndPostItemJournalLineWithManualLotNo(
          ItemJournalLine, ComponentItem."No.", LocationCode, Quantity * QuantityPer * 2, WorkDate(), LotNo, true,
          ComponentItem."Base Unit of Measure");  // TRUE for posting.
        CreateAndPostItemJournalLineWithManualLotNo(
          ItemJournalLine, ComponentItem."No.", LocationCode2, ItemJournalLine.Quantity + LibraryRandom.RandInt(50),
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), LotNo, true,
          ComponentItem."Base Unit of Measure");  // TRUE for posting.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", Quantity, LocationCode,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', ItemJournalLine."Posting Date"));
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", Quantity, LocationCode,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', ProductionOrder."Due Date"));
    end;

    local procedure CreateAndReleasePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; VariantCode: Code[10])
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", ItemNo, LocationCode, Quantity, VariantCode, false);  // Use Tracking as FALSE.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithItemTracking(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UseTracking: Boolean)
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, ItemNo, LocationCode, Quantity, '', UseTracking);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithMultipleTrackingLines(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; Quantity: Decimal; var LotNo: array[4] of Code[10])
    var
        i: Integer;
    begin
        CreateItemWithLotItemTrackingCode(Item, true, LibraryUtility.GetGlobalNoSeriesCode()); // Taking TRUE for Lot.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithAssignLotNo(PurchaseHeader, LotNo[1], Item."No.", LocationWhite.Code, Quantity, '', true); // Create 1st line.
        LotNo[2] := LotNo[1];
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignManualLotNo); // Enqueue for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo[2]);
        CreatePurchaseLine(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity, '', '', true); // Create 2nd Line.
        for i := 3 to 4 do
            CreatePurchaseLineWithAssignLotNo(PurchaseHeader, LotNo[i], Item."No.", LocationWhite.Code, Quantity, '', true); // Create 3rd and 4th lines.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithTwoLotItemTracking(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; var Item2: Record Item; Quantity: Decimal)
    begin
        CreateItemWithLotItemTrackingCode(Item, true, LibraryUtility.GetGlobalNoSeriesCode());  // Taking TRUE for Lot.
        CreateItemWithLotItemTrackingCode(Item2, true, LibraryUtility.GetGlobalNoSeriesCode());  // Taking TRUE for Lot.

        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, Item."No.", LocationWhite.Code, Quantity, '', false);  // Create 1st Line
        CreatePurchaseLine(PurchaseHeader, Item2."No.", LocationWhite.Code, Quantity, '', '', false); // Create 2nd Line
        AssignItemTrackingOnPurchLines(PurchaseHeader."No.");
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

    local procedure CreateAndReleaseSalesOrderWithSelectLotItemTracking(var SalesHeader: Record "Sales Header"; var Item: Record Item; var Item2: Record Item; Quantity: Decimal)
    var
        ItemNo: array[4] of Code[20];
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // The quantity and order for lines is very important for this case
        ItemNo[1] := Item."No.";
        ItemNo[2] := Item2."No.";
        ItemNo[3] := Item2."No.";
        ItemNo[4] := Item."No.";
        for i := 1 to 4 do
            CreateSalesLineAndSelectItemTrackingCode(SalesHeader, ItemNo[i], Quantity / 5, LocationWhite.Code); // Here Quantity could be "Quantity / (4,8)" -  Denominator is greater 4 and less than 8

        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithSelectLotAndUpdateQtyOnTrackingLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; var LotNo: array[4] of Code[10]; Quantity: Decimal; UpdateQtyBase: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // Create three sales lines with select Lot No. and update Quantity(Base) for the 2nd sales line on Tracking Line.
        CreateSalesLineWithSelectLotOnTrackingLine(
          LotNo[1], '', SalesHeader, SalesLine, ItemNo, Quantity, LocationWhite.Code, ItemTrackingMode::SelectEntries);
        CreateSalesLineWithSelectLotOnTrackingLine(
          LotNo[2], LotNo[3], SalesHeader, SalesLine, ItemNo, 2 * Quantity,
          LocationWhite.Code, ItemTrackingMode::SelectEntriesForMultipleLines); // 2 * Quantity is the sum quantity of the 2nd and 3rd purchase line.
        UpdateQtyBaseOnTrackingLines(SalesLine, UpdateQtyBase);
        UpdateQtyBaseOnTrackingLines(SalesLine, Quantity);
        CreateSalesLineWithSelectLotOnTrackingLine(LotNo[4], '', SalesHeader,
          SalesLine, ItemNo, Quantity, LocationWhite.Code, ItemTrackingMode::SelectEntries);

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
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo2, Quantity2);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithAssemblyItem(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateMsg, WorkDate()));
        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateMsg, WorkDate()));
        CreateAndReleaseSalesOrder(
          SalesHeader, LibrarySales.CreateCustomerNo(), ItemNo, LibraryRandom.RandInt(10), LocationBlue.Code, '', false, ReservationMode::" ");
    end;

    local procedure CreateAndReleaseSalesCreditMemo(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, ItemNo, Quantity, LocationCode, '', true, ReservationMode::" ");  // Use Tracking as TRUE.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date; ShipmentDate: Date)
    begin
        CreateTransferHeaderWithShipmentAndPostingDate(TransferHeader, FromLocation, ToLocation, PostingDate, ShipmentDate);
        CreateTransferLine(TransferHeader, ItemNo, Quantity, '');
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; VariantCode: Code[10]; PostingDate: Date; ShipmentDate: Date)
    begin
        CreateTransferHeaderWithShipmentAndPostingDate(TransferHeader, FromLocation, ToLocation, PostingDate, ShipmentDate);
        CreateTransferLine(TransferHeader, ItemNo, Quantity, '');
        if VariantCode <> '' then
            CreateTransferLine(TransferHeader, ItemNo2, Quantity, VariantCode);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleaseWarehouseInternalPickWithMultipleLines(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; VariantCode: Code[10]; VariantCode2: Code[10])
    var
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickRelease: Codeunit "Whse. Internal Pick Release";
    begin
        CreateWhseInternalPickHeader(WhseInternalPickHeader, LocationCode, BinCode);
        CreateWhseInternalPickLine(WhseInternalPickHeader, ItemNo, Quantity, VariantCode);
        CreateWhseInternalPickLine(WhseInternalPickHeader, ItemNo2, Quantity, VariantCode2);
        WhseInternalPickRelease.Release(WhseInternalPickHeader);
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

    local procedure CreateAndRegisterSplitedPutAwayFromReleasedPurchaseOrder(PurchaseHeader: Record "Purchase Header"; LotNo: Code[10]; SplitQty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false, ItemTrackingMode::" ");

        // Find Put-away Place line
        FindWarehouseActivityLineWithActionType(WarehouseActivityLine, '', LotNo, WarehouseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place);

        // Split Place lines and place item into different bins
        SplitPutAwayLineAndUpdateZoneCodeAndBinCodeForPlace(WarehouseActivityLine, SplitQty);

        // Register Put Away.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndRegisterPickFromSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemTracking: Boolean; ReservationMode: Option)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreatePickFromSalesOrder(SalesHeader, '', ItemNo, Quantity, LocationCode, ItemTracking, ReservationMode);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndRegisterPickFromSalesOrderAfterUpdateZoneAndBinOnPickLine(var SalesHeader: Record "Sales Header"; Bin: Record Bin; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreatePickFromSalesOrder(SalesHeader, '', ItemNo, Quantity, LocationCode, false, ReservationMode::" ");
        UpdateZoneAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", WarehouseActivityLine."Activity Type"::Pick,
          WarehouseActivityLine."Action Type"::Take, SalesHeader."No.", Bin);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndRegisterPickFromPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; VariantCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, ItemNo, LocationCode, Quantity, VariantCode);
        CreateWarehouseShipmentWithGetSourceDocument(LocationCode, false, false, true, ItemNo, ItemNo);  // Taking TRUE for Purchase Return Orders.
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndRegisterPickFromProductionOrder(var ProductionOrder: Record "Production Order"; Register: Boolean)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        ProductionOrder.SetHideValidationDialog(true);
        ProductionOrder.CreatePick(UserId, 0, false, false, false);  // SetBreakBulkFilter, DoNotFillQtyToHandle, PrintDocument as FALSE.
        if Register then
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
              WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndRegisterPickFromTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; VariantCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateAndReleaseTransferOrder(TransferHeader, FromLocation, ToLocation, ItemNo, ItemNo2, Quantity, VariantCode, WorkDate(), WorkDate());
        CreateWarehouseShipmentWithGetSourceDocument(LocationWhite.Code, true, false, false, ItemNo, ItemNo2);  // Taking TRUE for Transfer Orders.
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndUpdateStockKeepingUnit(ItemNo: Code[20]; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        Item.SetRange("Location Filter", LocationCode, LocationCode2);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);
        UpdateStockKeepingUnit(
          LocationCode, ItemNo, StockkeepingUnit."Replenishment System"::Transfer, LocationCode2,
          StockkeepingUnit."Reordering Policy"::"Fixed Reorder Qty.", true);  // Include Inventory as True.
        UpdateStockKeepingUnit(
          LocationCode2, ItemNo, StockkeepingUnit."Replenishment System"::Purchase, '',
          StockkeepingUnit."Reordering Policy"::"Lot-for-Lot", false);  // Include Inventory as False.
    end;

    local procedure CreateAndUpdateBinOnProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; Location: Record Location; ProductionOrderNo: Code[20])
    var
        Bin: Record Bin;
        Bin2: Record Bin;
    begin
        Bin.Get(Location.Code, Location."From-Production Bin Code");
        LibraryWarehouse.CreateBin(Bin2, Bin."Location Code", LibraryUtility.GenerateGUID(), Bin."Zone Code", Bin."Bin Type Code");
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrderNo);
        ProdOrderComponent.Validate("Bin Code", Bin2.Code);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateBlanketSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Blanket Order", '', ItemNo,
          LibraryRandom.RandDec(10, 2), '', '', false, ReservationMode::" ");
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreateInventoryPutAwayFromSalesReturnOrderAfterGetPostedDocumentLinesToReverse(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        SalesHeader.GetPstdDocLinesToReverse();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryVariableStorage.Enqueue(InvtPutAwayCreatedTxt);  // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Return Order", SalesHeader."No.", true, false, false);  // Use True for Put Away.
    end;

    local procedure CreateProductionOrderWithItem(var ProductionOrder: Record "Production Order")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
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

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Serial: Boolean; Lot: Boolean; StrictExpirationPosting: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("Strict Expiration Posting", StrictExpirationPosting);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemTrackingLine(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Serial No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(1);  // Value required for Quantity.
    end;

    local procedure CreateItemWithRoutingAndProductionBOM(var Item: Record Item; ProductionBOMNo: Code[20]; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateAssemblyItemWithBOM(var ParentItem: Record Item; var ComponentItem: Record Item)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Validate("Reordering Policy", ParentItem."Reordering Policy"::Order);
        ParentItem.Modify(true);
        LibraryInventory.CreateItem(ComponentItem);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItem."No.", BOMComponent.Type::Item, ComponentItem."No.", 1, ComponentItem."Base Unit of Measure");
    end;

    local procedure CreateItemWithDefaultDimension(var DefaultDimension: Record "Default Dimension"; var DimensionValue: Record "Dimension Value")
    var
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryInventory.CreateItem(Item);
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
    end;

    local procedure CreateItemWithLotItemTrackingCode(var Item: Record Item; Lot: Boolean; LotNos: Code[20])
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, false, Lot, false);
        LibraryInventory.CreateTrackedItem(Item, LotNos, '', ItemTrackingCode.Code);  // Taking blank for Serial Nos.
    end;

    local procedure CreateItemWithProductionBOMWithMultipleLines(var ParentItem: Record Item; var ComponentItem: Record Item; var ComponentItem2: Record Item; var ItemVariant: Record "Item Variant")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithReplenishmentSystemAsProdOrder(ParentItem);
        CreateItemWithReplenishmentSystemAsProdOrder(ComponentItem);
        CreateItemWithReplenishmentSystemAsProdOrder(ComponentItem2);
        LibraryInventory.CreateItemVariant(ItemVariant, ComponentItem2."No.");
        CreateAndCertifyBOMWithMultipleLines(
          ProductionBOMHeader, ParentItem."Base Unit of Measure", ComponentItem."No.", ComponentItem2."No.", ItemVariant.Code);
        UpdateProductionBOMOnItem(ParentItem, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemWithProductionBOM(var ParentItem: Record Item; var ComponentItem: Record Item; var ProductionBOMLine: Record "Production BOM Line")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithReplenishmentSystem(ParentItem, ParentItem."Replenishment System"::"Prod. Order");
        CreateItemWithReplenishmentSystem(ComponentItem, ComponentItem."Replenishment System"::Purchase);
        UpdateReserveOnItem(ComponentItem);
        CreateAndCertifyBOM(
          ProductionBOMHeader, ProductionBOMLine, ParentItem."Base Unit of Measure", ComponentItem."No.", LibraryRandom.RandInt(10));
        UpdateProductionBOMOnItem(ParentItem, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemWithReplenishmentSystemAsProdOrder(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Flushing Method", Item."Flushing Method"::"Pick + Manual");
        Item.Modify(true);
    end;

    local procedure CreateItemWithSalesAndPurchaseUnitOfMeasure(var Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        UpdatePurchaseUnitOfMeasureOnItem(Item, ItemUnitOfMeasure.Code);
        UpdateSalesUnitOfMeasureOnItem(Item, ItemUnitOfMeasure.Code);
    end;

    local procedure CreateItemWithVariant(var Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandInt(10) + 1); // Value required for test.
    end;

    local procedure CreateItemWithReplenishmentSystem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateLotItemWithReplenishmentSystem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        CreateItemWithLotItemTrackingCode(Item, true, LibraryUtility.GetGlobalNoSeriesCode());  // Taking TRUE for Lot.
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateLotItemWithProductionBOMAndSKU(var ParentItem: Record Item; var ComponentItem: Record Item; LocationCode: Code[10]; LocationCode2: Code[10]): Decimal
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        CreateLotItemWithReplenishmentSystem(ParentItem, ParentItem."Replenishment System"::"Prod. Order");
        CreateLotItemWithReplenishmentSystem(ComponentItem, ComponentItem."Replenishment System"::Purchase);
        CreateBaseUnitOfMeasure(UnitOfMeasure, ParentItem);
        CreateBaseUnitOfMeasure(UnitOfMeasure, ComponentItem);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, ParentItem."No.");
        CreateAndUpdateStockKeepingUnit(ComponentItem."No.", LocationCode, LocationCode2);
        CreateAndCertifyBOM(
          ProductionBOMHeader, ProductionBOMLine, ParentItem."Base Unit of Measure", ComponentItem."No.",
          ItemUnitOfMeasure."Qty. per Unit of Measure");
        UpdateProductionBOMOnItem(ParentItem, ProductionBOMHeader."No.");
        exit(ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    local procedure CreateMovementFromMovementWorksheetLine(WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindWarehouseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode, ItemNo, ItemNo2);
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::None, false, false, false);  // Taking 0 for SortActivity.
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

    local procedure CreatePickFromPickWorksheet(WhseWorksheetName: Record "Whse. Worksheet Name"; ItemNo: Code[20]; ItemNo2: Code[20]; MaxNoOfLines: Integer)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindWarehouseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, WhseWorksheetName."Location Code", ItemNo, ItemNo2);
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, 0, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, WhseWorksheetName."Location Code", '',
          MaxNoOfLines, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);  // Taking 0 for Line No, MaxNoOfSourceDoc and SortPick.
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

    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; UnitOfMeasureCode: Code[10]; ItemNo: Code[20]; QuantityPer: Decimal)
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QuantityPer);
    end;

    local procedure CreateProductionBOMLine(var ProductionBOMHeader: Record "Production BOM Header"; ComponentItemNo: Code[20]; VariantCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItemNo, LibraryRandom.RandDec(10, 2));
        ProductionBOMLine.Validate("Variant Code", VariantCode);
        ProductionBOMLine.Modify(true);
    end;

    local procedure CreateProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; ItemNo: Code[20]; ItemUnitOfMeasureCode: Code[10]; LocationCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandInt(10));  // Using Random for Quantity per.
        ProdOrderComponent.Validate("Unit of Measure Code", ItemUnitOfMeasureCode);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; VariantCode: Code[10]; UseTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        CreatePurchaseLine(PurchaseHeader, ItemNo, LocationCode, Quantity, VariantCode, '', UseTracking);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, ItemNo, LocationCode, Quantity, '', false);  // Use Tracking as FALSE.
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

    local procedure CreatePurchaseLineWithAssignLotNo(var PurchaseHeader: Record "Purchase Header"; var LotNo: Code[50]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; VariantCode: Code[10]; ItemTracking: Boolean)
    var
        DequeueVar: Variant;
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo); // Enqueue for ItemTrackingLinesPageHandler.
        CreatePurchaseLine(PurchaseHeader, ItemNo, LocationCode, Quantity, VariantCode, '', ItemTracking);
        LibraryVariableStorage.Dequeue(DequeueVar);
        LotNo := DequeueVar;
    end;

    local procedure CreateBlanketPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", ItemNo, '', LibraryRandom.RandDec(10, 2), '', false);  // Use Tracking as FALSE.
    end;

    local procedure CreatePutAwayFromPostedWarehouseReceipt(ItemNo: Code[20])
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        LibraryVariableStorage.Enqueue(PutAwayActivityTxt);  // Enqueue for MessageHandler.
        PostedWhseReceiptLine.SetRange("Item No.", ItemNo);
        PostedWhseReceiptLine.FindFirst();
        PostedWhseReceiptLine.CreatePutAwayDoc(PostedWhseReceiptLine, '');  // Use blank for Assigned ID.
    end;

    local procedure CreatePurchasingCode(DropShipment: Boolean; SpecialOrder: Boolean) PurchasingCode: Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        if DropShipment then
            Purchasing.Validate("Drop Shipment", true);
        if SpecialOrder then
            Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
        PurchasingCode := Purchasing.Code
    end;

    local procedure CreatePurchaseQuote(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Quote, ItemNo, '', LibraryRandom.RandDec(10, 2), '', false);  // Use Tracking as FALSE.
    end;

    local procedure CreateRoutingSetup(var RoutingLine: Record "Routing Line"; var WorkCenter: Record "Work Center"; var MachineCenter: Record "Machine Center") OperationNo: Code[10]
    var
        RoutingHeader: Record "Routing Header";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDec(100, 2));
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '',
          CopyStr(
            LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Routing Line", RoutingLine.FieldNo("Operation No."))),
          RoutingLine.Type::"Machine Center", MachineCenter."No.");
        OperationNo := RoutingLine."Operation No.";
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '',
          CopyStr(
            LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Routing Line", RoutingLine.FieldNo("Operation No."))),
          RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; VariantCode: Code[10]; UseTracking: Boolean; ReservationMode: Option)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode, VariantCode, UseTracking, ReservationMode);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; VariantCode: Code[10]; ItemTracking: Boolean; ReservationMode: Option " ",ReserveFromCurrentLine,AutoReserve)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
        if ItemTracking then
            SalesLine.OpenItemTrackingLines();
        if ReservationMode <> ReservationMode::" " then begin
            if ReservationMode = ReservationMode::ReserveFromCurrentLine then
                LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());  // Enqueue for ConfirmHandler.
            LibraryVariableStorage.Enqueue(ReservationMode);  // Enqueue for ReservationPageHandler.
            SalesLine.ShowReservation();
        end;
    end;

    local procedure CreateSalesLineAndSelectItemTrackingCode(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries); // Enqueue for ItemTrackingLinesPageHandler
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesOrderWithPurchaseCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; DropShipment: Boolean; SpecialOrder: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(DropShipment, SpecialOrder));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Quote, '', ItemNo, LibraryRandom.RandDec(10, 2), '',
          '', false, ReservationMode::" ");
    end;

    local procedure CreateTransferHeaderWithShipmentAndPostingDate(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ToLocation: Code[10]; PostingDate: Date; ShipmentDate: Date)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, LocationInTransit.Code);
        TransferHeader.Validate("Posting Date", PostingDate);
        TransferHeader.Validate("Shipment Date", ShipmentDate);
        TransferHeader.Modify(true);
    end;

    local procedure CreateTransferOrderWithMultipleUOMAndLotTracking(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: array[3] of Decimal; QtyPerUOM: Decimal; UOMCode: Code[10]; LotNo: array[3] of Code[20])
    var
        TransferLine: Record "Transfer Line";
        Qty: Decimal;
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationInTransit.Code);

        Qty := Round(Quantity[1] / LibraryRandom.RandIntInRange(3, 5), 1);
        CreateTransferLineWithUOM(TransferHeader, ItemNo, Qty, UOMCode);
        CreateTransferLineWithUOM(TransferHeader, ItemNo, (Quantity[1] - Qty) * QtyPerUOM + 2 * Quantity[1], '');

        FindTransferLine(TransferLine, TransferHeader."No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignManualLotNo); // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo[1]);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        TransferLine.Next();
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignManualTwoLotNo);  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo[1]);
        LibraryVariableStorage.Enqueue(LotNo[3]);
        LibraryVariableStorage.Enqueue(AvailabilityWarningsQst);  // Enqueue for ConfirmHandler.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure CreateTransferOrderWithMultipleUOMAndReservation(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: array[3] of Decimal; UOMCode: Code[10]; ReservationMode: Option)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationInTransit.Code);
        CreateTransferLineWithUOM(TransferHeader, ItemNo, Quantity[2], UOMCode);
        CreateTransferLineWithUOM(TransferHeader, ItemNo, Quantity[3], '');

        FindTransferLine(TransferLine, TransferHeader."No.");
        LibraryVariableStorage.Enqueue(ReservationMode); // Enqueue for ReservationPageHandler.
        TransferLine.ShowReservation();
    end;

    local procedure CreateTransferLineWithUOM(TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; Quantity: Decimal; UOMCode: Code[10])
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        if UOMCode <> '' then begin
            TransferLine.Validate("Unit of Measure Code", UOMCode);
            TransferLine.Modify(true);
        end;
    end;

    local procedure CreateTransferLine(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10])
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Variant Code", VariantCode);
        TransferLine.Modify(true);
    end;

    local procedure CreateTransferRoute()
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationGreen.Code, LocationYellow.Code);
        TransferRoute.Validate("In-Transit Code", LocationInTransit.Code);
        TransferRoute.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
    end;

    local procedure CreateWhseInternalPickHeader(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseInternalPickHeader(WhseInternalPickHeader, LocationCode);
        WhseInternalPickHeader.Validate("To Bin Code", BinCode);
        WhseInternalPickHeader.Modify(true);
    end;

    local procedure CreateWhseInternalPickLine(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10])
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        LibraryWarehouse.CreateWhseInternalPickLine(WhseInternalPickHeader, WhseInternalPickLine, ItemNo, Quantity);
        WhseInternalPickLine.Validate("Variant Code", VariantCode);
        WhseInternalPickLine.Modify(true);
    end;

    local procedure CreateWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateWarehouseShipmentWithGetSourceDocument(LocationCode: Code[10]; OutboundTransfers: Boolean; SalesOrders: Boolean; PurchaseReturnOrders: Boolean; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateWarehouseShipmentHeaderWithLocation(WarehouseShipmentHeader, LocationCode);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Validate("Outbound Transfers", OutboundTransfers);
        WarehouseSourceFilter.Validate("Sales Orders", SalesOrders);
        WarehouseSourceFilter.Validate("Purchase Return Orders", PurchaseReturnOrders);
        WarehouseSourceFilter.Validate("Item No. Filter", ItemNo + '|' + ItemNo2);
        WarehouseSourceFilter.Modify(true);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, LocationCode);
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateWarehouseShipmentFromSalesHeader(SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateWarehouseShipmentHeaderWithLocation(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", LocationCode);
        WarehouseShipmentHeader.Modify(true);
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

    local procedure CreateAssemblyItem(var Item: Record Item; AssemblyPolicy: Enum "Assembly Policy")
    begin
        // Use False for Update Unit Cost and blank for Variant Code.
        LibraryAssembly.SetupAssemblyItem(
          Item, Item."Costing Method"::Standard, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', false,
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        Item.Validate("Assembly Policy", AssemblyPolicy);
        Item.Modify(true);
    end;

    local procedure CreateItemAndUpdateInventory(var Item: Record Item; Quantity: Decimal)
    var
        Bin: Record Bin;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.UpdateInventoryPostingSetup(LocationWhite);
        FindBinForPickZone(Bin, LocationWhite.Code, true); // PICK Zone.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '');
    end;

    local procedure CreateSalesOrderAndWareshouseShipment(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, ItemNo, ItemNo2, Quantity, LocationWhite.Code);
        CreateWarehouseShipmentFromSalesHeader(SalesHeader);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(StrSubstNo(BeforeWorkDateMsg, WorkDate())); // Enqueue for message triggered by sales line for assembly item
        CreateAndReleaseSalesOrderWithMultipleSalesLines(
          SalesHeader, Customer."No.", ItemNo, ItemNo2, LibraryRandom.RandDec(10, 2), Quantity, LocationCode);
    end;

    local procedure CreateAndRegisterPickFromWareshouseShipment(SalesHeaderNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeaderNo);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeaderNo,
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateSalesLineWithSelectLotOnTrackingLine(LotNo: Code[50]; LotNo2: Code[20]; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; TrackingMode: Option)
    var
        ReservationMode: Option " ",ReserveFromCurrentLine,AutoReserve;
    begin
        LibraryVariableStorage.Enqueue(TrackingMode); // Enqueue for ItemTrackingLinesPageHandler
        LibraryVariableStorage.Enqueue(LotNo); // Enqueue for ItemTrackingLinesPageHandler
        if TrackingMode = ItemTrackingMode::SelectEntriesForMultipleLines then
            LibraryVariableStorage.Enqueue(LotNo2); // Enqueue for ItemTrackingLinesPageHandler
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode, '', true, ReservationMode::" ");
    end;

    local procedure CreateProdOrderLineAtLocation(var ProdOrderLine: Record "Prod. Order Line"; LocationCode: Code[10])
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLineRecordRef: RecordRef;
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), 1);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        ProdOrderLine.Validate(Status, ProductionOrder.Status);
        ProdOrderLine.Validate("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLineRecordRef.GetTable(ProdOrderLine);
        ProdOrderLine.Validate("Line No.", LibraryUtility.GetNewLineNo(ProdOrderLineRecordRef, ProdOrderLine.FieldNo("Line No.")));
    end;

    local procedure MockSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("No."), DATABASE::"Sales Header");
        SalesHeader."Posting Date" := LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20);
        SalesHeader.Insert();
    end;

    local procedure MockATOLink(SalesHeader: Record "Sales Header"; AssemblyHeader: Record "Assembly Header")
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        AssembleToOrderLink.Init();
        AssembleToOrderLink."Assembly Document Type" := AssemblyHeader."Document Type";
        AssembleToOrderLink."Assembly Document No." := AssemblyHeader."No.";
        AssembleToOrderLink.Type := AssembleToOrderLink.Type::Sale;
        AssembleToOrderLink."Document Type" := SalesHeader."Document Type";
        AssembleToOrderLink."Document No." := SalesHeader."No.";
        AssembleToOrderLink.Insert();
    end;

    local procedure MockAssemblyHeader(var AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        AssemblyHeader."No." := LibraryUtility.GenerateRandomCode(AssemblyHeader.FieldNo("No."), DATABASE::"Assembly Header");
        AssemblyHeader."Posting Date" := WorkDate();
        AssemblyHeader.Insert();
    end;

    local procedure MockWhseActivityLineWithQty(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; ActivityNo: Code[20]; LineNo: Integer; Qty: Decimal; QtyOutstanding: Decimal; QtyToHandle: Decimal)
    begin
        WarehouseActivityLine.Init();
        WarehouseActivityLine."Activity Type" := ActivityType;
        WarehouseActivityLine."No." := ActivityNo;
        WarehouseActivityLine."Line No." := LineNo;
        WarehouseActivityLine.Quantity := Qty;
        WarehouseActivityLine."Qty. Outstanding" := QtyOutstanding;
        WarehouseActivityLine."Qty. to Handle" := QtyToHandle;
        WarehouseActivityLine.Insert();
    end;

    local procedure DeletePutAwayLines(SourceNo: Code[20]; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        FilterWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Inbound Transfer", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.DeleteAll(true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure DeleteWarehouseActivityHeader(WarehouseActivityLineNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLineNo);
        WarehouseActivityHeader.FindFirst();
        WarehouseActivityHeader.Delete(true);
    end;

    local procedure FilterSalesLine(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("No.", ItemNo);
    end;

    local procedure FilterWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
    end;

    local procedure FindAdjustmentBin(var Bin: Record Bin; Location: Record Location)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, false, false));
        Bin.SetFilter(Code, '<>%1', Location."Adjustment Bin Code");
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindFirst();
    end;

    local procedure FindAndSplitTakePlaceLines(Item: Record Item; LotNo: Code[50]; TransferHeaderNo: Code[20]; ActionType: Enum "Warehouse Action Type"; var QtyToHandle: Decimal; var BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLineWithActionType(
          WarehouseActivityLine, Item."Base Unit of Measure", LotNo, WarehouseActivityLine."Source Document"::"Outbound Transfer",
          TransferHeaderNo, WarehouseActivityLine."Activity Type"::Pick, ActionType);
        SplitLineAndUpdateBinCode(WarehouseActivityLine, QtyToHandle, BinCode);
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10])
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.FindLast();
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

    local procedure FindBinsForPickZone(var Bin: Record Bin; LocationCode: Code[10]; Pick: Boolean; BinIndex: Integer): Code[20]
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, Pick));  // Taking True for Putaway and Pick
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, BinIndex);  // Find Bin by BinIndex.
        exit(Bin.Code);
    end;

    local procedure FindLotNoOnItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]): Code[20]
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        exit(ItemLedgerEntry."Lot No.");
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrderNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindRegisteredWhseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; BinCode: Code[20])
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.SetRange("Bin Code", BinCode);
        RegisteredWhseActivityLine.FindFirst();
    end;

    local procedure FindRegisteredWhseActivityLineForLotAndUOM(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; UOMCode: Code[10]; LotNo: Code[50])
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.SetRange("Unit of Measure Code", UOMCode);
        RegisteredWhseActivityLine.SetRange("Lot No.", LotNo);
        RegisteredWhseActivityLine.FindFirst();
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
    end;

    local procedure FindPlanningComponent(var PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line")
    begin
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningComponent.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure FindTransferLine(var TransferLine: Record "Transfer Line"; DocumentNo: Code[20])
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        FilterWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLineWithActionType(var WarehouseActivityLine: Record "Warehouse Activity Line"; UOMCode: Code[10]; LotNo: Code[50]; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        if UOMCode <> '' then
            WarehouseActivityLine.SetRange("Unit of Measure Code", UOMCode);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
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

    local procedure GetNoOfPicksOnLocation(var NoOfPicks: Integer; LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::Pick);
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        NoOfPicks := WarehouseActivityHeader.Count();
    end;

    local procedure GetWarehouseDocumentOnWhseWorksheetLine(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; DocumentType: Enum "Warehouse Pick Request Document Type")
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhsePickRequest.SetRange(Status, WhsePickRequest.Status::Released);
        WhsePickRequest.SetRange("Completely Picked", false);
        WhsePickRequest.SetRange("Location Code", LocationCode);
        WhsePickRequest.SetRange("Document Type", DocumentType);
        LibraryWarehouse.GetOutboundSourceDocuments(WhsePickRequest, WhseWorksheetName, LocationCode);
    end;

    local procedure GetSalesOrderForDropShipmentOnRequisitionWorksheet(var SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, SelectRequisitionTemplate());
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
    end;

    local procedure GetSalesOrderForSpecialOrderOnRequisitionWorksheet(var SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, SelectRequisitionTemplate());
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, SalesLine."No.");
    end;

    local procedure InitSetupForProdBOMWithRouting(var WorkCenter: Record "Work Center"; var ItemNo: Code[20]; var ParentItemNo: Code[20]; LocationCode: Code[10])
    var
        ParentItem: Record Item;
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingLine: Record "Routing Line";
    begin
        CreateRoutingSetupWithWorkCenter(RoutingLine, WorkCenter, LocationCode);
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";

        CreateAndCertifyBOM(
          ProductionBOMHeader, ProductionBOMLine, Item."Base Unit of Measure", Item."No.", LibraryRandom.RandInt(10));
        CreateItemWithRoutingAndProductionBOM(ParentItem, ProductionBOMHeader."No.", RoutingLine."Routing No.");
        ParentItemNo := ParentItem."No.";
    end;

    local procedure OpenProductionJournal(ProductionOrder: Record "Production Order")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderComponent."Prod. Order Line No.");
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

    local procedure BatchPostSalesOrderWithNewPostingDate(var SalesHeader: Record "Sales Header"; NewPostingDate: Date)
    begin
        SalesHeader.SetRange("No.", SalesHeader."No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(NoOfPostedOrdersMsg, 1));
        Commit();
        LibrarySales.BatchPostSalesHeaders(SalesHeader, true, false, NewPostingDate, true, false, false);
    end;

    local procedure PostPurchOrderAfterCarryOutActionMsgOnReqWorksheet(ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        CarryOutActionMsgOnRequisitionWorksheet(ItemNo);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        UpdateQuantityToReceiveOnPurchaseLine(PurchaseLine, Quantity);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.
    end;

    local procedure PostPurchaseOrder(ItemNo: Code[20]; ToShipReceive: Boolean; ToInvoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ToShipReceive, ToInvoice);
    end;

    local procedure PostSalesInvoiceWithPurchasingCodeAndNegativeQuantity(DropShipment: Boolean; SpecialOrder: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);

        // Setup: Create sales order with Purchase Code
        CreateItemWithStandardCost(Item);
        CreateSalesOrderWithPurchaseCode(SalesHeader, SalesLine, Item."No.", -Quantity, DropShipment, SpecialOrder);

        // Get Sales Order for Drop Shipment on Requisition Worksheet and Carry Out
        if DropShipment then
            GetSalesOrderForDropShipmentOnRequisitionWorksheet(SalesLine);
        if SpecialOrder then
            GetSalesOrderForSpecialOrderOnRequisitionWorksheet(SalesLine);

        CarryOutActionMsgOnRequisitionWorksheet(Item."No.");

        // Exercise: Post Purchase Order and Sales Order
        PostPurchaseOrder(Item."No.", true, false);
        SalesHeader.Find(); // Require for Posting.
        LibrarySales.PostSalesDocument(SalesHeader, true, true); // Post as Ship and Invoice.

        // Verify: Verify Sales Order post successfully, Posted Sales Invoice is correct.
        VerifyPostedSalesInvoiceLine(Item."No.", -Quantity);
    end;

    local procedure PostTransferOrderAsReceive(TransferHeader: Record "Transfer Header"; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        FindTransferLine(TransferLine, TransferHeader."No.");
        TransferLine.Validate("Qty. to Receive", Quantity);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);  // Post as receive.
    end;

    local procedure PostTransferOrderAsReceiveAfterUpdateDimensionOnTransferLine(var TransferHeader: Record "Transfer Header"; ShortcutDimension1Code: Code[20])
    var
        TransferLine: Record "Transfer Line";
    begin
        FindTransferLine(TransferLine, TransferHeader."No.");
        TransferLine.Validate("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);  // Post as Receive.
    end;

    local procedure PostWarehouseActivity(ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrderNo,
          WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.Validate("Qty. to Handle", Quantity);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;

    local procedure PostWarehouseReceipt(WarehouseReceiptNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(WarehouseReceiptNo);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseShipment(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; Invoice: Boolean)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, Invoice);  // Use TRUE for Invoice.
    end;

    local procedure PostWarehouseShipmentAndReopenSalesOrder(var SalesHeader: Record "Sales Header"; var Item: Record Item; Quantity: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Create a new item, update the inventory.
        UpdateInventoryUsingItemJournal(Item, Quantity);

        // Create a Sales Order, Create Pick and post Warehourse Shipment
        CreateAndRegisterPickFromSalesOrder(
          SalesHeader, Item."No.", Quantity, LocationYellow.Code, false, ReservationMode::" "); // Value required for the test.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", false);

        // Reopen Sales Order
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
    end;

    local procedure RegisterPutAwayAfterDeletePutAwayLines(Bin: Record Bin; SourceNo: Code[20]; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        DeletePutAwayLines(SourceNo, LotNo);
        UpdateZoneAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Inbound Transfer",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, SourceNo, Bin);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Inbound Transfer", SourceNo,
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

    local procedure RegisterWhseJournalLineAndPostItemJournal(Item: Record Item; Bin: Record Bin)
    begin
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure ReleasePurchaseOrderAndRegisterPutAwayWithMultipleUOMAndLotTracking(var Item: Record Item; Quantity: array[3] of Decimal; var UOM: array[3] of Code[10]; var LotNo: array[3] of Code[20]; var QtyPerUOM: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleasePurchaseOrderWithMultipleUOMAndLotTracking(PurchaseHeader, Item, Quantity, UOM, LotNo, QtyPerUOM, LocationWhite.Code);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false, ItemTrackingMode::" ");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away"); // Register Put-away for Purchase Order
    end;

    local procedure ReleaseTransferOrderAndCreatePick(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: array[3] of Decimal; QtyPerUOM: Decimal; UOMCode: Code[10]; LotNo: array[3] of Code[20]; ReservationMode: Option " ",ReserveFromCurrentLine,AutoReserve)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if ReservationMode <> ReservationMode::" " then
            CreateTransferOrderWithMultipleUOMAndReservation(
              TransferHeader, FromLocationCode, ToLocationCode, ItemNo, Quantity, UOMCode, ReservationMode)
        else
            CreateTransferOrderWithMultipleUOMAndLotTracking(
              TransferHeader, FromLocationCode, ToLocationCode, ItemNo, Quantity, QtyPerUOM, UOMCode, LotNo);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        CreateWarehouseShipmentWithGetSourceDocument(LocationWhite.Code, true, false, false, ItemNo, ItemNo);  // Taking TRUE for Transfer Orders.
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");
    end;

    local procedure ReleaseTransferOrderAndCreatePickWithUOMAndLotTracking(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; TransferQty: Decimal; LotNo: Code[50])
    var
        TransferLine: Record "Transfer Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationInTransit.Code);

        CreateTransferLineWithUOM(TransferHeader, ItemNo, TransferQty, '');
        FindTransferLine(TransferLine, TransferHeader."No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignManualLotNo); // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        CreateWarehouseShipmentWithGetSourceDocument(LocationWhite.Code, true, false, false, ItemNo, ItemNo);  // Taking TRUE for Transfer Orders.
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");
    end;

    local procedure RunCalculateRegenerativePlan(ItemNo: Code[20]; LocationCode: Code[10]; StartingDate: Date)
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        Item.SetRange("Location Filter", LocationCode);
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, StartingDate, CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', StartingDate));
    end;

    local procedure SelectRequisitionTemplate() ReqWkshTemplateName: Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        ReqWkshTemplateName := ReqWkshTemplate.Name
    end;

    local procedure SplitPutAwayLineAndUpdateZoneCodeAndBinCodeForPlace(var WarehouseActivityLine: Record "Warehouse Activity Line"; Quantity: Decimal)
    begin
        UpdateZoneAndBinCodeInWarehouseActivityLine(WarehouseActivityLine, 1); // Find and set 1st bin

        // Update Qty. to Handle and split Place line
        WarehouseActivityLine.Validate("Qty. to Handle", Quantity);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);

        WarehouseActivityLine.Next();
        UpdateZoneAndBinCodeInWarehouseActivityLine(WarehouseActivityLine, 2); // Find and set 2nd bin
    end;

    local procedure SplitLineAndUpdateBinCode(WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyToHandle: Decimal; var BinCode: Code[20])
    begin
        // Update Qty. to Handle and split Place line
        BinCode := WarehouseActivityLine."Bin Code";
        QtyToHandle := Round(WarehouseActivityLine."Qty. to Handle" / LibraryRandom.RandIntInRange(3, 5), 1);
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);

        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Bin Code", ''); // Clear the default Bin Code and reset.
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateAlwaysCreatePickLineOnLocation(var Location: Record Location; var OldAlwaysCreatePickLine: Boolean; NewAlwaysCreatePickLine: Boolean)
    begin
        OldAlwaysCreatePickLine := Location."Always Create Pick Line";
        LocationWhite.Validate("Always Create Pick Line", NewAlwaysCreatePickLine);
        LocationWhite.Modify(true);
    end;

    local procedure UpdateBinCodeAfterSplitPutAwayLine(var Bin: Record Bin; SourceNo: Code[20]; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);
        FindBinForPickZone(Bin, LocationWhite.Code, true);  // PICK Zone.
        WarehouseActivityLine.SetRange("Bin Code", '');
        UpdateZoneAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, SourceNo, Bin);
    end;

    local procedure UpdateCreditWarningOnSalesAndReceivablesSetup(NewCreditWarnings: Option) OldCreditWarning: Integer
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldCreditWarning := SalesReceivablesSetup."Credit Warnings";
        SalesReceivablesSetup.Validate("Credit Warnings", NewCreditWarnings);
        SalesReceivablesSetup.Modify(true);
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

    local procedure UpdateBlockedAsTrueOnItem(var Item: Record Item)
    begin
        Item.Validate(Blocked, true);
        Item.Modify(true);
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

    local procedure UpdateReserveOnItem(var Item: Record Item)
    begin
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
    end;

    local procedure UpdateStockOutWarningOnSalesReceivablesSetup(NewStockOutWarning: Boolean) OldStockOutWarning: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldStockOutWarning := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockOutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateZoneAndBinCodeOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; Bin: Record Bin)
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.ModifyAll("Zone Code", Bin."Zone Code", true);
        WarehouseActivityLine.ModifyAll("Bin Code", Bin.Code, true);
    end;

    local procedure UpdateZoneAndBinCodeInWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; BinIndex: Integer)
    var
        Bin: Record Bin;
    begin
        FindBinsForPickZone(Bin, LocationWhite.Code, true, BinIndex);
        WarehouseActivityLine.Validate("Zone Code", Bin."Zone Code");
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateInventoryUsingWhseJournal(Bin: Record Bin; Item: Record Item; Quantity: Decimal; VariantCode: Code[10])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, Item, Quantity, VariantCode);
        RegisterWhseJournalLineAndPostItemJournal(Item, Bin);
    end;

    local procedure UpdateInventoryUsingItemJournal(var Item: Record Item; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.UpdateInventoryPostingSetup(LocationYellow);
        CreateItemJournalLine(ItemJournalLine, Item."No.", LocationYellow.Code, Quantity, WorkDate(), '', Item."Base Unit of Measure");
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateItemTrackingOnTransferLine(DocumentNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
    begin
        FindTransferLine(TransferLine, DocumentNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure UpdateItemTrackingOnTransferLineWithLotNo(DocumentNo: Code[20]; LotNo: Code[50])
    var
        TransferLine: Record "Transfer Line";
    begin
        FindTransferLine(TransferLine, DocumentNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignManualLotNo);  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure UpdateMachineCenter(MachineCenter: Record "Machine Center"; Location: Record Location)
    begin
        MachineCenter.Validate("Location Code", Location.Code);
        MachineCenter.Validate("Open Shop Floor Bin Code", Location."Open Shop Floor Bin Code");
        MachineCenter.Validate("From-Production Bin Code", Location."From-Production Bin Code");
        MachineCenter.Validate("To-Production Bin Code", Location."To-Production Bin Code");
        MachineCenter.Modify(true);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdatePurchaseUnitOfMeasureOnItem(var Item: Record Item; PurchaseUnitOfMeasure: Code[10])
    begin
        Item.Validate("Purch. Unit of Measure", PurchaseUnitOfMeasure);
        Item.Modify(true);
    end;

    local procedure UpdatePurchaseCodeAfterPostWarehouseShipment(DropShipment: Boolean; SpecialOrder: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Setup: Post Warehourse Shipment and reopen Sales Order
        PostWarehouseShipmentAndReopenSalesOrder(SalesHeader, Item, LibraryRandom.RandDec(100, 2));

        // Exercise: Update Purchasing Code
        FindSalesLine(SalesLine, SalesHeader."No.");
        asserterror SalesLine.Validate("Purchasing Code", CreatePurchasingCode(DropShipment, SpecialOrder));

        // Verify: Error message pops up
        Assert.ExpectedError(CannotChangePurchasingCodeErr);
    end;

    local procedure UpdateSalesUnitOfMeasureOnItem(var Item: Record Item; SalesUnitOfMeasure: Code[10])
    begin
        Item.Validate("Sales Unit of Measure", SalesUnitOfMeasure);
        Item.Modify(true);
    end;

    local procedure UpdateZoneAndBinCodeOnWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; Bin: Record Bin)
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptLine.Validate("Zone Code", Bin."Zone Code");
        WarehouseReceiptLine.Validate("Bin Code", Bin.Code);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure UpdateProductionBOMOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateBinOnLocation(var Location: Record Location)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin2, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin3, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Open Shop Floor Bin Code", Bin.Code);
        Location.Validate("From-Production Bin Code", Bin2.Code);
        Location.Validate("To-Production Bin Code", Bin3.Code);
        Location.Modify(true);
    end;

    local procedure UpdateAssemblyBinOnLocation(var Location: Record Location)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin2, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("From-Assembly Bin Code", Bin.Code);
        Location.Validate("To-Assembly Bin Code", Bin2.Code);
        Location.Modify(true);
    end;

    local procedure UpdateBinOnWorkCenter(var WorkCenter: Record "Work Center"; LocationCode: Code[10])
    var
        Bin: array[3] of Record Bin;
        i: Integer;
    begin
        for i := 1 to 3 do
            LibraryWarehouse.CreateBin(Bin[i], LocationCode, LibraryUtility.GenerateGUID(), '', '');

        WorkCenter.Validate("Open Shop Floor Bin Code", Bin[1].Code);
        WorkCenter.Validate("From-Production Bin Code", Bin[2].Code);
        WorkCenter.Validate("To-Production Bin Code", Bin[3].Code);
        WorkCenter.Modify(true);
    end;

    local procedure UpdateLocationOnWorkCenter(var WorkCenter: Record "Work Center"; LocationCode: Code[10])
    begin
        WorkCenter.Validate("Location Code", LocationCode);
        WorkCenter.Modify(true);
    end;

    local procedure UpdateStockKeepingUnit(LocationCode: Code[10]; ItemNo: Code[20]; ReplenishmentSystem: Enum "Replenishment System"; TransferfromCode: Code[10]; ReorderingPolicy: Enum "Reordering Policy"; IncludingInventory: Boolean)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.Get(LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Validate("Transfer-from Code", TransferfromCode);
        StockkeepingUnit.Validate("Reordering Policy", ReorderingPolicy);
        StockkeepingUnit.Validate("Include Inventory", IncludingInventory);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateDefaultQuantityToShipOnSalesReceivablesSetup(NewDefaultQuantityToShip: Option) OldDefaultQuantityToShip: Integer
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldDefaultQuantityToShip := SalesReceivablesSetup."Default Quantity to Ship";
        SalesReceivablesSetup.Validate("Default Quantity to Ship", NewDefaultQuantityToShip);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateQuantityToReceiveOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QuantityToReceive: Decimal)
    begin
        PurchaseLine.Validate("Qty. to Receive", QuantityToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateWorkCenter(WorkCenter: Record "Work Center"; Location: Record Location)
    begin
        WorkCenter.Validate("Location Code", Location.Code);
        WorkCenter.Validate("Open Shop Floor Bin Code", Location."Open Shop Floor Bin Code");
        WorkCenter.Validate("From-Production Bin Code", Location."From-Production Bin Code");
        WorkCenter.Validate("To-Production Bin Code", Location."To-Production Bin Code");
        WorkCenter.Modify(true);
    end;

    local procedure UpdateQtyBaseOnTrackingLines(var SalesLine: Record "Sales Line"; UpdateQtyBase: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::UpdateQty); // Enqueue for ItemTrackingLinesPageHandler
        LibraryVariableStorage.Enqueue(UpdateQtyBase);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure UndoSalesShipmentLine(DocumentNo: Code[20]; ExpectedMessage: Text)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(ExpectedMessage); // Enqueue for ConfirmHandler.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure PostStockForComponents(Item: Record Item; Quantity: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, Item."No.", LocationBlue.Code, Quantity, WorkDate(), '', Item."Base Unit of Measure");
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Explode BOM", ItemJournalLine);
        ItemJournalLine.FindSet();
        repeat
            if (ItemJournalLine."Location Code" = '') and (ItemJournalLine."Item No." <> '') then begin
                ItemJournalLine.Validate("Location Code", LocationBlue.Code);
                ItemJournalLine.Modify();
            end
        until ItemJournalLine.Next() = 0;
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure VerifyBinCodeOnReqLineAndPlanningComponent(ItemNo: Code[20]; RequisitionLineBinCode: Code[20]; PlanningComponentBinCode: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        FindPlanningComponent(PlanningComponent, RequisitionLine);
        RequisitionLine.TestField("Bin Code", RequisitionLineBinCode);
        PlanningComponent.TestField("Bin Code", PlanningComponentBinCode);
    end;

    local procedure VerifyEmptyReservationEntry(ItemNo: Code[20]; SourceID: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source ID", SourceID);
        Assert.IsTrue(ReservationEntry.IsEmpty, ReservationEntryMustBeEmptyTxt);
    end;

    local procedure VerifyInventoryPutAwayLine(var Item: Record Item; SourceNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Unit of Measure Code", Item."Base Unit of Measure");
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Return Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemLedgerEntryForSerialNo(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal; TotalQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity2: Decimal;
    begin
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField(Quantity, Quantity);  // Value required for Quantity.
            ItemLedgerEntry.TestField("Serial No.");
            Quantity2 += ItemLedgerEntry.Quantity;
        until ItemLedgerEntry.Next() = 0;
        Assert.AreEqual(Quantity2, TotalQuantity, ValueMustBeEqualTxt);
    end;

    local procedure VerifyItemLedgerEntryForLotNo(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal; LotNo: Code[50])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemLedgerEntriesForLotNo(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        repeat
            ItemLedgerEntry.TestField("Lot No.", LotNo);
            ItemLedgerEntry.TestField(Quantity, Quantity);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Entry Type"; DocumentType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; LotNo: Code[50]; GlobalDimension1Code: Code[20]; Quantity: Decimal; RemainingQuantity: Decimal; PostingDate: Date)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Remaining Quantity", RemainingQuantity);
        ItemLedgerEntry.TestField("Global Dimension 1 Code", GlobalDimension1Code);
        ItemLedgerEntry.TestField("Posting Date", PostingDate);
    end;

    local procedure VerifyPutAwayLine(SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyPostedWhseShipmentLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10])
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        PostedWhseShipmentLine.SetRange("Source Document", SourceDocument);
        PostedWhseShipmentLine.SetRange("Source No.", SourceNo);
        PostedWhseShipmentLine.SetRange("Item No.", ItemNo);
        PostedWhseShipmentLine.FindFirst();
        PostedWhseShipmentLine.TestField(Quantity, Quantity);
        PostedWhseShipmentLine.TestField("Variant Code", VariantCode);
    end;

    local procedure VerifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedSalesInvoiceLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("No.", ItemNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedSalesCreditMemoLine(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetRange("No.", ItemNo);
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyProductionOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrderNo);
        ProdOrderComponent.TestField("Item No.", ItemNo);
        ProdOrderComponent.TestField("Expected Quantity", ExpectedQuantity);
    end;

    local procedure VerifyProdOrderRoutingLine(Location: Record Location; OperationNo: Code[10]; CapacityType: Enum "Capacity Type"; RoutingNo: Code[20])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.SetRange(Type, CapacityType);
        ProdOrderRoutingLine.SetRange("No.", RoutingNo);
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.TestField("Open Shop Floor Bin Code", Location."Open Shop Floor Bin Code");
        ProdOrderRoutingLine.TestField("From-Production Bin Code", Location."From-Production Bin Code");
        ProdOrderRoutingLine.TestField("To-Production Bin Code", Location."To-Production Bin Code");
    end;

    local procedure VerifyQuantityInPickWorksheetPage(ItemNo: Code[20]; AvailableQtyToPick: Decimal)
    var
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        PickWorksheet.OpenEdit();
        PickWorksheet.FILTER.SetFilter("Item No.", ItemNo);
        PickWorksheet."Qty. to Handle".AssertEquals(AvailableQtyToPick);
        PickWorksheet.AvailableQtyToPickExcludingQCBins.AssertEquals(AvailableQtyToPick); // Control52 is Available Qty. To Pick
    end;

    local procedure VerifyRegisteredPickLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10]; BinCode: Code[20])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, SourceDocument, SourceNo, RegisteredWhseActivityLine."Activity Type"::Pick, ActionType, ItemNo, BinCode);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
        RegisteredWhseActivityLine.TestField("Variant Code", VariantCode);
    end;

    local procedure VerifyTotalQuantityBaseOnRegisteredPickLines(BinCode: Code[20]; ItemNo: Code[20]; TotalQtyBase: Decimal)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Activity Type", RegisteredWhseActivityLine."Activity Type"::Pick);
        RegisteredWhseActivityLine.SetRange("Bin Code", BinCode);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.CalcSums("Qty. (Base)");
        Assert.AreEqual(TotalQtyBase, RegisteredWhseActivityLine."Qty. (Base)", ValueMustBeEqualTxt);
    end;

    local procedure VerifyRegisteredPickLines(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10]; BinCode: Code[20]; BinCode2: Code[20])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        VerifyRegisteredPickLine(
          SourceDocument, SourceNo, RegisteredWhseActivityLine."Action Type"::Take, ItemNo, Quantity, VariantCode, BinCode);
        VerifyRegisteredPickLine(
          SourceDocument, SourceNo, RegisteredWhseActivityLine."Action Type"::Place, ItemNo, Quantity, VariantCode, BinCode2);
    end;

    local procedure VerifyRegisteredPickLineForQtyAndBinCode(Item: Record Item; DocumentNo: Code[20]; ActionType: Enum "Warehouse Action Type"; LotNo: Code[50]; Quantity: Decimal; BinCode: Code[20])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWhseActivityLineForLotAndUOM(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Source Document"::"Outbound Transfer", DocumentNo,
          RegisteredWhseActivityLine."Activity Type"::Pick, ActionType, Item."No.", Item."Base Unit of Measure", LotNo);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
        RegisteredWhseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyRegisteredPutAwayLine(ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Source Document"::"Purchase Order", SourceNo,
          RegisteredWhseActivityLine."Activity Type"::"Put-away", ActionType, ItemNo, BinCode);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyRequisitionLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField("Accept Action Message", true);
        RequisitionLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; LocationCode: Code[10]; ReservationStatus: Enum "Reservation Status"; Quantity: Decimal; SourceID: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        if SourceID <> '' then
            ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Quantity (Base)", Quantity);
    end;

    local procedure VerifySalesLine(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; QtyToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        FilterSalesLine(SalesLine, ItemNo);
        SalesLine.FindFirst();
        SalesLine.TestField(Quantity, Quantity);
        SalesLine.TestField("Qty. to Invoice", QtyToShip);
        SalesLine.TestField("Qty. to Ship", QtyToShip);
    end;

    local procedure VerifySalesInvoiceLine(ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.SetRange("No.", ItemNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Quantity, Quantity);
        SalesInvoiceLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    local procedure VerifyNoOfPicks(LocationCode: Code[10]; ExpectedNoOfPicks: Integer)
    var
        ActualNoOfPicks: Integer;
    begin
        GetNoOfPicksOnLocation(ActualNoOfPicks, LocationCode);
        Assert.AreEqual(ExpectedNoOfPicks, ActualNoOfPicks, ValueMustBeEqualTxt);
    end;

    local procedure VerifyWarehouseEntry(Bin: Record Bin; EntryType: Option; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Zone Code", Bin."Zone Code");
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.SetRange("Lot No.", LotNo);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehousePickLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10]; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Variant Code", VariantCode);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyWarehousePickLines(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10]; BinCode: Code[20]; BinCode2: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        VerifyWarehousePickLine(SourceDocument, SourceNo, WarehouseActivityLine."Action Type"::Take, ItemNo, Quantity, VariantCode, BinCode);
        VerifyWarehousePickLine(SourceDocument, SourceNo, WarehouseActivityLine."Action Type"::Place, ItemNo, Quantity, VariantCode, BinCode2);
    end;

    local procedure VerifyLineNoInFilteredWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; Qty: Decimal; ExpectedLineNo: Integer)
    begin
        WarehouseActivityLine.SetRange(Quantity, Qty);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Line No.", ExpectedLineNo);
    end;

    local procedure VerifyItemLedgerEntriesWithMultipleLotNo(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LotNo: array[4] of Code[10]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        i: Integer;
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        for i := 1 to 4 do begin
            ItemLedgerEntry.TestField("Lot No.", LotNo[i]);
            ItemLedgerEntry.TestField(Quantity, Quantity);
            ItemLedgerEntry.Next();
        end;
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FilterWarehouseShipmentLine(WarehouseShipmentLine, SourceNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FilterWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
    end;

    local procedure CalcWhseAdjustmentAndPostItemJournalLine(Item: Record Item)
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch."Template Type"::Item);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure SelectAndClearItemJournalBatch(Type: Enum "Item Journal Template Type")
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
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
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectLotOnItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    var
        LotNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(LotNo);
        ItemTrackingSummary.FILTER.SetFilter("Lot No.", LotNo);
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.OK().Invoke();
    end;

    local procedure WarehousePutAwayWithTwoLotItemTracking(var Item: Record Item; var Item2: Record Item; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleasePurchaseOrderWithTwoLotItemTracking(PurchaseHeader, Item, Item2, Quantity);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false, ItemTrackingMode::AssignTwoLotNo);

        // Find Put-away Place lines
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        // Split Place lines and place item into different bins
        repeat
            SplitPutAwayLineAndUpdateZoneCodeAndBinCodeForPlace(WarehouseActivityLine, WarehouseActivityLine.Quantity / 2);
        until WarehouseActivityLine.Next() = 0;

        // Register Put Away.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    [ModalPageHandler]
    procedure WhseItemTrackingLinesModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure WhseShipmentCreatePickRequestPageHandler(var WhseShipmentCreatePick: TestRequestPage "Whse.-Shipment - Create Pick")
    begin
        WhseShipmentCreatePick.CustomSorting.SetValue(true);
        WhseShipmentCreatePick.OK().Invoke();
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(ConfirmMessage, LocalMessage) > 0, ConfirmMessage);
        Reply := false;
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationTxt);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLinesPostedTxt);  // Enqueue for MessageHandler.
        ProductionJournal.Post.Invoke();
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesHandler(var ItemLedgerEntries: TestPage "Item Ledger Entries")
    begin
        ItemLedgerEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentPageHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInventoryPutAwayPickHandler(var CreateInvtPutAwayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutAwayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutAwayPickMvmt.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerAsTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure InboundOutboundHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1; // 1 for Outbound Reservation.
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ExplodeBOMHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1; // 1 for 'Retrieve dimensions from Components'
    end;

    local procedure CreateBaseUnitOfMeasure(var UnitOfMeasure: Record "Unit of Measure"; var Item: Record Item)
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Modify();
    end;
}

