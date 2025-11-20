codeunit 137504 "SCM Warehouse Unit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Warehouse] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        UoMMgt: Codeunit "Unit of Measure Management";
        QtyMustNotBeChangedErr: Label '%1 must not be changed';
        WhseShptCreatedMsg: Label 'Warehouse Shipment Header has been created.';
        WarehouseReceiptHeaderCreatedMsg: Label '1 Warehouse Receipt Header has been created.';
        TrackingAmtNotMachPickErr: Label 'Registered Warehouse Pick amount do not match Item Tracking Line amount. ';
        TransferLineNotExistErr: Label 'Transfer Line doesn''t exist.';
        TransferLineShouldnotExistErr: Label 'Transfer Line shouldn''t exist.';
        NotificationMsg: Label 'The available inventory for item %1 is lower than the entered quantity at this location.', Comment = '%1=Item No.';
        CannotCreateBinWithoutLocationErr: Label 'Location Code must have a value';
        ItemTrkgManagedByWhseMsg: Label 'You cannot assign a serial, lot or package number because item tracking for this document line is done through a warehouse activity.';

    [Test]
    [Scope('OnPrem')]
    procedure GetBinContentFetchesContentFromDedicatedBin()
    var
        Bin: Record Bin;
        Item: Record Item;
        BinContent: Record "Bin Content";
        WhseEntry: Record "Warehouse Entry";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseInternalPutAwayHeaderDummy: Record "Whse. Internal Put-away Header";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseGetBinContent: Report "Whse. Get Bin Content";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        LocationCode: Code[10];
    begin
        SequenceNoMgt.ClearState();
        // VSTF 333341
        Initialize();

        // SETUP: Create bin content on dedicated bin
        LocationCode := MockLocationCode();

        Bin.Init();
        Bin."Location Code" := LocationCode;
        Bin.Code := LibraryUtility.GenerateGUID();
        Bin.Insert();

        MockItemWithBaseUOM(Item);

        BinContent."Location Code" := Bin."Location Code";
        BinContent."Bin Code" := Bin.Code;
        BinContent."Item No." := Item."No.";
        BinContent."Unit of Measure Code" := Item."Base Unit of Measure";
        BinContent.Dedicated := true;
        BinContent.Insert();

        WhseEntry.Init();
        WhseEntry."Location Code" := BinContent."Location Code";
        WhseEntry."Bin Code" := BinContent."Bin Code";
        WhseEntry."Item No." := BinContent."Item No.";
        WhseEntry."Unit of Measure Code" := BinContent."Unit of Measure Code";
        WhseEntry."Qty. (Base)" := 10;
        WhseEntry.Insert();

        // make a warehouse worksheet line- for use in the calling of the report
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Movement);
        WhseWorksheetTemplate.FindFirst();
        WhseWorksheetLine."Worksheet Template Name" := WhseWorksheetTemplate.Name;

        // EXERCISE: Invoke get bin content on movement worksheet
        BinContent.SetRange("Item No.", BinContent."Item No."); // filter on the bin content created only
        WhseGetBinContent.SetTableView(BinContent);
        Commit();
        WhseGetBinContent.UseRequestPage(false);
        WhseInternalPutAwayHeaderDummy.Init();
        WhseGetBinContent.SetParameters(WhseWorksheetLine, WhseInternalPutAwayHeaderDummy, "Warehouse Destination Type 2"::MovementWorksheet);
        WhseGetBinContent.Run();

        // VERIFY: Make sure the warehouse worksheet line appears with the quantity on the bin content
        WhseWorksheetLine.SetRange("Item No.", BinContent."Item No.");
        WhseWorksheetLine.SetRange(Quantity, WhseEntry."Qty. (Base)");
        Assert.IsFalse(WhseWorksheetLine.IsEmpty, 'There should be a line created from dedicated bin quantity.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTrackingLineHasCorrectShipmentDateWhenRegisteringPickFromWhseShipment()
    begin
        ItemTrackingLineHasCorrectShipmentDateWhenRegisteringWhseActivity(true, false, 0); // 0 is for Sales
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTrackingLineHasCorrectShipmentDateWhenRegisteringPickFromAssembly()
    begin
        ItemTrackingLineHasCorrectShipmentDateWhenRegisteringWhseActivity(true, false, 1); // 1 is for Assembly
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTrackingLineHasCorrectShipmentDateWhenRegisteringPickFromProduction()
    begin
        ItemTrackingLineHasCorrectShipmentDateWhenRegisteringWhseActivity(true, false, 2); // 2 is for Production
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTrackingLineHasCorrectShipmentDateWhenRegisteringInvtMvmtFromAssembly()
    begin
        ItemTrackingLineHasCorrectShipmentDateWhenRegisteringWhseActivity(false, false, 1); // 1 is for Assembly
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTrackingLineHasCorrectShipmentDateWhenRegisteringInvtMvmtFromProduction()
    begin
        ItemTrackingLineHasCorrectShipmentDateWhenRegisteringWhseActivity(false, false, 2); // 2 is for Production
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTrackingLineHasCorrectShipmentDateWhenRegisteringInvtPickFromSales()
    begin
        ItemTrackingLineHasCorrectShipmentDateWhenRegisteringWhseActivity(false, true, 0); // 0 is for Sales
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTrackingLineHasCorrectShipmentDateWhenRegisteringInvtPickFromProduction()
    begin
        ItemTrackingLineHasCorrectShipmentDateWhenRegisteringWhseActivity(false, true, 2); // 2 is for Production
    end;

    local procedure ItemTrackingLineHasCorrectShipmentDateWhenRegisteringWhseActivity(DPPLocation: Boolean; InvtPick: Boolean; DemandType: Option Sales,Assembly,Production)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        TakeBinCode: Code[10];
        RefDate: Date;
    begin
        // VSTF 332220
        Initialize();

        // SETUP: Create entries for inventory, Create pick from warehouse shipment
        TakeBinCode := LibraryUtility.GenerateGUID();
        RefDate := WorkDate() - 4;

        CreateInventory(ItemLedgerEntry, TakeBinCode, DPPLocation);

        CreatePick(DemandType, DPPLocation, InvtPick, WarehouseActivityHeader, ItemLedgerEntry, RefDate, TakeBinCode);

        // EXERCISE: Register pick
        WarehouseActivityLine."Activity Type" := WarehouseActivityHeader.Type;
        WarehouseActivityLine."No." := WarehouseActivityHeader."No.";
        CODEUNIT.Run(CODEUNIT::"Whse.-Activity-Register", WarehouseActivityLine);

        // VERIFY: Reservation Entry has the same Shipment Date as WarehouseShipmentLine
        ReservationEntry.SetRange("Item No.", ItemLedgerEntry."Item No.");
        ReservationEntry.FindLast();
        Assert.AreEqual(RefDate, ReservationEntry."Shipment Date",
          'Reservation Entry has the same Shipment Date as WarehouseShipmentLine');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingLineWithSpecificUOMWhenRegisteringWhseActivityFromTransferOrder()
    var
        ItemUOM: Record "Item Unit of Measure";
        TransHeader: Record "Transfer Header";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseActivityHdr: Record "Warehouse Activity Header";
        LocationCode: Code[10];
        BinCode: array[2] of Code[20];
        LotNo: array[3] of Code[20];
    begin
        Initialize();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibraryVariableStorage.Enqueue(WarehouseReceiptHeaderCreatedMsg);
        VSTF334573CreateInventory(ItemUOM, LocationCode, LotNo, BinCode);

        LibraryVariableStorage.Enqueue(WhseShptCreatedMsg);
        VSTF334573CreateReleaseTransOrder(TransHeader, LocationCode, ItemUOM, LotNo);

        LibraryWarehouse.CreateWhseShipmentFromTO(TransHeader);

        GetWhseShptFromTransfer(WhseShptHeader, TransHeader."No.");

        // Post pick and shipment partially
        VSTF334573CreateRegisterPickWithQtyToHandle(
          WhseActivityHdr, WhseShptHeader, TransHeader."Transfer-from Code", LotNo, BinCode);

        Assert.AreEqual(
          GetWhseRegisteredPickAmount(ItemUOM."Item No."),
          -GetItemTrackingAmount(ItemUOM."Item No."),
          TrackingAmtNotMachPickErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineWithItemToPlanAndOutstandingQty()
    var
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        // [FEATURE] [Item Availability]
        // [SCENARIO 361067.1] Shipping/Receipt Transfer Lines are shown in Availability By Event in case of Outstanding Qty. <> 0
        Initialize();

        // [GIVEN] Item
        MockItem(Item);

        // [GIVEN] Transfer Order with Outstanding Qty <> 0
        MockTransferLine(Item."No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Run Item's Availability By Event
        // [THEN] Transfer Shipment line is shown as Item To Plan Demand
        TransferLine.Reset();
        Assert.IsTrue(TransferLine.FindLinesWithItemToPlan(Item, false, false), TransferLineNotExistErr); // ship

        // [THEN] Tansfer Receipt Line is shown as Item To Plan Supply
        Assert.IsTrue(TransferLine.FindLinesWithItemToPlan(Item, true, false), TransferLineNotExistErr); // receipt
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineWithItemToPlanAndShippedQty()
    var
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        // [FEATURE] [Item Availability]
        // [SCENARIO 361067.2] Receipt Transfer Line is shown in Availability By Event in case of Outstanding Qty. = 0
        Initialize();

        // [GIVEN] Item
        MockItem(Item);

        // [GIVEN] Transfer Order with Outstanding Qty = 0
        MockTransferLine(Item."No.", 0);

        // [WHEN] Run Item's Availability By Event
        // [THEN] Transfer Shipment line is not shown as Item To Plan Demand
        TransferLine.Reset();
        Assert.IsFalse(TransferLine.FindLinesWithItemToPlan(Item, false, false), TransferLineShouldnotExistErr); // ship

        // [THEN] Tansfer Receipt Line is shown as Item To Plan Supply
        Assert.IsTrue(TransferLine.FindLinesWithItemToPlan(Item, true, false), TransferLineNotExistErr); // receipt
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIfFromServiceLine2ShptLine_BlankQtyToConsume()
    var
        ServiceLine: Record "Service Line";
        ServiceWarehouseMgt: Codeunit "Service Warehouse Mgt.";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 380057] COD 5750 "Whse.-Create Source Document".CheckIfFromServiceLine2ShptLine() returns TRUE in case of "Qty. to Consume" = 0
        Initialize();

        MockServiceLine(ServiceLine);
        Assert.IsTrue(
            ServiceWarehouseMgt.CheckIfFromServiceLine2ShptLine(ServiceLine),
            'Service Line to Shipment Line should be possible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIfFromServiceLine2ShptLine_QtyToConsume()
    var
        ServiceLine: Record "Service Line";
        ServiceWarehouseMgt: Codeunit "Service Warehouse Mgt.";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 380057] COD 5750 "Whse.-Create Source Document".CheckIfFromServiceLine2ShptLine() returns FALSE in case of "Qty. to Consume" <> 0
        Initialize();

        MockServiceLine(ServiceLine);
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity / 2);
        Assert.IsFalse(
            ServiceWarehouseMgt.CheckIfFromServiceLine2ShptLine(ServiceLine),
            'Service Line to Shipment Line should not be possible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReNumberLineNosOnSplitLineInWarehousePick()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePick: TestPage "Warehouse Pick";
        i: Integer;
    begin
        // [FEATURE] [Pick] [UI]
        // [SCENARIO 228376] When the spacing between Line No. is 1 on two adjacent lines, "SplitLine" function does the re-numbering of all lines in warehouse pick. The cursor stays on the pick line that was split.
        Initialize();

        // [GIVEN] Three warehouse pick lines with "Line No." = 1, 2, 3.
        MockWhseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, CreateLocationWithWhseEmployee());
        for i := 1 to 3 do
            MockWhseActivityLine(WarehouseActivityLine, WarehouseActivityHeader, i, WarehouseActivityLine."Action Type"::Take);

        // [WHEN] Open Warehouse Pick page and invoke "Split Line" action on line 2.
        WarehouseActivityLine.Get(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", 2);
        WarehousePick.OpenEdit();
        WarehousePick.GotoRecord(WarehouseActivityHeader);
        WarehousePick.WhseActivityLines.GotoRecord(WarehouseActivityLine);
        WarehousePick.WhseActivityLines.SplitWhseActivityLine.Invoke();

        // [THEN] The cursor on the page remains on the second line. "Quantity" = "Qty. to Handle", so the line is split.
        WarehousePick.WhseActivityLines."Item No.".AssertEquals(WarehouseActivityLine."Item No.");
        WarehousePick.WhseActivityLines.Quantity.AssertEquals(WarehouseActivityLine."Qty. to Handle");

        // [THEN] There are now 4 pick lines.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, 4);

        // [THEN] New Line Nos. are assigned to all lines.
        VerifyWhseActivityLineNos(WarehouseActivityLine, 4, '10000,20000,25000,30000');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CursorPositionNotChangedOnSplitLineWithRenumberingInWarehousePutAway()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAway: TestPage "Warehouse Put-away";
        i: Integer;
    begin
        // [FEATURE] [Put-away] [UI]
        // [SCENARIO 228376] After "SplitLine" function does the re-numbering of all lines in warehouse put-away, the cursor stays on the line that was split.
        Initialize();

        // [GIVEN] Three warehouse put-away lines with "Line No." = 1, 2, 3.
        MockWhseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::"Put-away", CreateLocationWithWhseEmployee());
        for i := 1 to 3 do
            MockWhseActivityLine(WarehouseActivityLine, WarehouseActivityHeader, i, WarehouseActivityLine."Action Type"::Place);

        // [WHEN] Open Warehouse Put-away page and invoke "Split Line" action on line 2.
        WarehouseActivityLine.Get(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", 2);
        WarehousePutAway.OpenEdit();
        WarehousePutAway.GotoRecord(WarehouseActivityHeader);
        WarehousePutAway.WhseActivityLines.GotoRecord(WarehouseActivityLine);
        WarehousePutAway.WhseActivityLines.SplitWhseActivityLine.Invoke();

        // [THEN] The cursor on the page remains on the second line. "Quantity" = "Qty. to Handle", so the line is split.
        WarehousePutAway.WhseActivityLines."Item No.".AssertEquals(WarehouseActivityLine."Item No.");
        WarehousePutAway.WhseActivityLines.Quantity.AssertEquals(WarehouseActivityLine."Qty. to Handle");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CursorPositionNotChangedOnSplitLineWithRenumberingInWarehouseMovement()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseMovement: TestPage "Warehouse Movement";
        i: Integer;
    begin
        // [FEATURE] [Movement] [UI]
        // [SCENARIO 228376] After "SplitLine" function does the re-numbering of all lines in warehouse movement, the cursor stays on the line that was split.
        Initialize();

        // [GIVEN] Three warehouse movement lines with "Line No." = 1, 2, 3.
        MockWhseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::Movement, CreateLocationWithWhseEmployee());
        for i := 1 to 3 do
            MockWhseActivityLine(WarehouseActivityLine, WarehouseActivityHeader, i, WarehouseActivityLine."Action Type"::Place);

        // [WHEN] Open Warehouse Movement page and invoke "Split Line" action on line 2.
        WarehouseActivityLine.Get(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", 2);
        WarehouseMovement.OpenEdit();
        WarehouseMovement.GotoRecord(WarehouseActivityHeader);
        WarehouseMovement.WhseMovLines.GotoRecord(WarehouseActivityLine);
        WarehouseMovement.WhseMovLines.SplitWhseActivityLine.Invoke();

        // [THEN] The cursor on the page remains on the second line. "Quantity" = "Qty. to Handle", so the line is split.
        WarehouseMovement.WhseMovLines."Item No.".AssertEquals(WarehouseActivityLine."Item No.");
        WarehouseMovement.WhseMovLines.Quantity.AssertEquals(WarehouseActivityLine."Qty. to Handle");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CursorPositionNotChangedOnSplitLineWithRenumberingInInventoryPick()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        InventoryPick: TestPage "Inventory Pick";
        i: Integer;
    begin
        // [FEATURE] [Inventory Pick] [UI]
        // [SCENARIO 228376] After "SplitLine" function does the re-numbering of all lines in inventory pick, the cursor stays on the line that was split.
        Initialize();

        // [GIVEN] Three inventory pick lines with "Line No." = 1, 2, 3.
        MockWhseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::"Invt. Pick", CreateLocationWithWhseEmployee());
        for i := 1 to 3 do
            MockWhseActivityLine(WarehouseActivityLine, WarehouseActivityHeader, i, WarehouseActivityLine."Action Type"::Place);

        // [WHEN] Open Inventory Pick page and invoke "Split Line" action on line 2.
        WarehouseActivityLine.Get(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", 2);
        InventoryPick.OpenEdit();
        InventoryPick.GotoRecord(WarehouseActivityHeader);
        InventoryPick.WhseActivityLines.GotoRecord(WarehouseActivityLine);
        InventoryPick.WhseActivityLines.SplitWhseActivityLine.Invoke();

        // [THEN] The cursor on the page remains on the second line. "Quantity" = "Qty. to Handle", so the line is split.
        InventoryPick.WhseActivityLines."Item No.".AssertEquals(WarehouseActivityLine."Item No.");
        InventoryPick.WhseActivityLines.Quantity.AssertEquals(WarehouseActivityLine."Qty. to Handle");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CursorPositionNotChangedOnSplitLineWithRenumberingInInventoryPutAway()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        InventoryPutAway: TestPage "Inventory Put-away";
        i: Integer;
    begin
        // [FEATURE] [Inventory Put-away] [UI]
        // [SCENARIO 228376] After "SplitLine" function does the re-numbering of all lines in inventory put-away, the cursor stays on the line that was split.
        Initialize();

        // [GIVEN] Three inventory put-away lines with "Line No." = 1, 2, 3.
        MockWhseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::"Invt. Put-away", CreateLocationWithWhseEmployee());
        for i := 1 to 3 do
            MockWhseActivityLine(WarehouseActivityLine, WarehouseActivityHeader, i, WarehouseActivityLine."Action Type"::Place);

        // [WHEN] Open Inventory Put-away page and invoke "Split Line" action on line 2.
        WarehouseActivityLine.Get(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", 2);
        InventoryPutAway.OpenEdit();
        InventoryPutAway.GotoRecord(WarehouseActivityHeader);
        InventoryPutAway.WhseActivityLines.GotoRecord(WarehouseActivityLine);
        InventoryPutAway.WhseActivityLines.SplitWhseActivityLine.Invoke();

        // [THEN] The cursor on the page remains on the second line. "Quantity" = "Qty. to Handle", so the line is split.
        InventoryPutAway.WhseActivityLines."Item No.".AssertEquals(WarehouseActivityLine."Item No.");
        InventoryPutAway.WhseActivityLines.Quantity.AssertEquals(WarehouseActivityLine."Qty. to Handle");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CursorPositionNotChangedOnSplitLineWithRenumberingInInventoryMovement()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        InventoryMovement: TestPage "Inventory Movement";
        i: Integer;
    begin
        // [FEATURE] [Inventory Movement] [UI]
        // [SCENARIO 228376] After "SplitLine" function does the re-numbering of all lines in inventory movement, the cursor stays on the line that was split.
        Initialize();

        // [GIVEN] Three inventory movement lines with "Line No." = 1, 2, 3.
        MockWhseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::"Invt. Movement", CreateLocationWithWhseEmployee());
        for i := 1 to 3 do
            MockWhseActivityLine(WarehouseActivityLine, WarehouseActivityHeader, i, WarehouseActivityLine."Action Type"::Place);

        // [WHEN] Open Inventory Movement page and invoke "Split Line" action on line 2.
        WarehouseActivityLine.Get(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", 2);
        InventoryMovement.OpenEdit();
        InventoryMovement.GotoRecord(WarehouseActivityHeader);
        InventoryMovement.WhseActivityLines.GotoRecord(WarehouseActivityLine);
        InventoryMovement.WhseActivityLines.SplitWhseActivityLine.Invoke();

        // [THEN] The cursor on the page remains on the second line. "Quantity" = "Qty. to Handle", so the line is split.
        InventoryMovement.WhseActivityLines."Item No.".AssertEquals(WarehouseActivityLine."Item No.");
        InventoryMovement.WhseActivityLines.Quantity.AssertEquals(WarehouseActivityLine."Qty. to Handle");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhsePickLinesSortedByShelfWhenBinNotMandatory()
    var
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: array[3] of Code[20];
        ShelfNo: array[3] of Code[10];
        i: Integer;
    begin
        // [FEATURE] [Pick]
        // [SCENARIO 256408] Warehouse pick lines at location with disabled mandatory bin are sorted by Shelf No. when you choose "Shelf or Bin" sorting method on the header.
        Initialize();

        // [GIVEN] Location with "Bin Mandatory" = FALSE.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);

        for i := 1 to 3 do begin
            ItemNo[i] := LibraryUtility.GenerateGUID();
            ShelfNo[i] := LibraryUtility.GenerateGUID();
        end;

        // [GIVEN] Warehouse pick with 3 lines:
        // [GIVEN] Line 10000: item no. = "I1", shelf no. = "S3".
        // [GIVEN] Line 20000: item no. = "I2", shelf no. = "S2".
        // [GIVEN] Line 30000: item no. = "I2", shelf no. = "S1".
        MockWhseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, Location.Code);
        for i := 1 to 3 do
            MockWhseActivityLineWithBinAndShelf(
              WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::" ",
              ItemNo[i], '', ShelfNo[4 - i]);

        // [WHEN] Select "Shelf or Bin" sorting method on the warehouse pick header.
        WarehouseActivityHeader.Validate("Sorting Method", WarehouseActivityHeader."Sorting Method"::"Shelf or Bin");

        // [THEN] The pick lines are sorted by shelf no., the first line in order has shelf no. = "S1".
        VerifySortingOrderWhseActivityLines(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::" ", ShelfNo[1], '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhsePickLinesSortedByBinWhenBinMandatory()
    var
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: array[3] of Code[20];
        ShelfNo: array[3] of Code[10];
        BinCode: array[3] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Pick]
        // [SCENARIO 256408] Warehouse pick lines at location with enabled mandatory bin are sorted by Bin Code when you choose "Shelf or Bin" sorting method on the header.
        Initialize();

        // [GIVEN] Location with "Bin Mandatory" = TRUE.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);

        for i := 1 to 3 do begin
            ItemNo[i] := LibraryUtility.GenerateGUID();
            ShelfNo[i] := LibraryUtility.GenerateGUID();
            BinCode[i] := LibraryUtility.GenerateGUID();
        end;

        // [GIVEN] Warehouse pick with 3 lines:
        // [GIVEN] Line 10000: item no. = "I1", shelf no. = "S1", bin code = "B3".
        // [GIVEN] Line 20000: item no. = "I2", shelf no. = "S2", bin code = "B2".
        // [GIVEN] Line 30000: item no. = "I2", shelf no. = "S3", bin code = "B1".
        MockWhseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, Location.Code);
        for i := 1 to 3 do begin
            MockWhseActivityLineWithBinAndShelf(
              WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take,
              ItemNo[i], BinCode[4 - i], ShelfNo[i]);
            MockWhseActivityLineWithBinAndShelf(
              WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place,
              ItemNo[i], BinCode[4 - i], ShelfNo[i]);
        end;

        // [WHEN] Select "Shelf or Bin" sorting method on the warehouse pick header.
        WarehouseActivityHeader.Validate("Sorting Method", WarehouseActivityHeader."Sorting Method"::"Shelf or Bin");

        // [THEN] The pick lines are sorted by bin code, the first line in order has bin code = "B1" and shelf no. = "S3".
        VerifySortingOrderWhseActivityLines(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, ShelfNo[3], BinCode[1]);
        VerifySortingOrderWhseActivityLines(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, ShelfNo[3], BinCode[1]);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,MessageHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure NotificationWhenItemTrackingIsHandledByWhse()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 356989] A user is notified when they cannot assign lot or serial no. via Item Tracking Lines page because a warehouse activity exists.
        Initialize();

        // [GIVEN] Lot-tracked item with "Lot Warehouse Tracking" = TRUE.
        // [GIVEN] Location that requires put-away.
        ItemNo := CreateItemWithLotTracking();
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);

        // [GIVEN] Released purchase order.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create inventory put-away.
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        // [WHEN] Go back to the purchase order and open item tracking lines.
        PurchaseLine.OpenItemTrackingLines();

        // [THEN] A notification is raised pointing that the item tracking can only be set in put-away.
        Assert.ExpectedMessage(ItemTrkgManagedByWhseMsg, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SortingPickWorksheetLinesByBinAndShelf()
    var
        Location: Record Location;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        ItemNo: Code[20];
        ShelfNo: array[3] of Code[10];
        BinCode: array[3] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Pick Worksheet] [Sorting]
        // [SCENARIO 406575] Pick worksheet lines sorted by bin code are then also sorted by shelf no.
        Initialize();

        // [GIVEN] Location with "Bin Mandatory" = TRUE.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);

        ItemNo := LibraryUtility.GenerateGUID();
        for i := 1 to 3 do begin
            ShelfNo[i] := LibraryUtility.GenerateGUID();
            BinCode[i] := LibraryUtility.GenerateGUID();
        end;

        // [GIVEN] Three pick worksheet lines:
        // [GIVEN] Line 1: bin code = "B1", shelf no. = "S3".
        // [GIVEN] Line 2: bin code = "B2", shelf no. = "S2"
        // [GIVEN] Line 3: bin code = "B2", shelf no. = "S1"
        MockPickWorksheetLineWithBinAndShelf(WhseWorksheetLine, Location.Code, ItemNo, BinCode[1], ShelfNo[3]);
        MockPickWorksheetLineWithBinAndShelf(WhseWorksheetLine, Location.Code, ItemNo, BinCode[2], ShelfNo[2]);
        MockPickWorksheetLineWithBinAndShelf(WhseWorksheetLine, Location.Code, ItemNo, BinCode[2], ShelfNo[1]);

        // [WHEN] Sort pick worksheet lines by "Shelf/Bin No.".
        WhseWorksheetLine.SortWhseWkshLines(
          WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name, Location.Code, "Whse. Activity Sorting Method"::"Shelf or Bin");

        // [THEN] The pick worksheet lines are sorted by bin code first, then by shelf, as follows:
        // [THEN] Line 1: bin code = "B1", shelf no. = "S3".
        // [THEN] Line 2: bin code = "B2", shelf no. = "S1"
        // [THEN] Line 3: bin code = "B2", shelf no. = "S2"
        WhseWorksheetLine.Reset();
        WhseWorksheetLine.SetCurrentKey("Sorting Sequence No.");
        WhseWorksheetLine.SetRange("Item No.", ItemNo);

        WhseWorksheetLine.FindSet();
        WhseWorksheetLine.TestField("To Bin Code", BinCode[1]);
        WhseWorksheetLine.TestField("Shelf No.", ShelfNo[3]);

        WhseWorksheetLine.Next();
        WhseWorksheetLine.TestField("To Bin Code", BinCode[2]);
        WhseWorksheetLine.TestField("Shelf No.", ShelfNo[1]);

        WhseWorksheetLine.Next();
        WhseWorksheetLine.TestField("To Bin Code", BinCode[2]);
        WhseWorksheetLine.TestField("Shelf No.", ShelfNo[2]);
    end;

    [Test]
    procedure SortingWarehousePickLinesByBinAndShelf()
    var
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        ShelfNo: array[3] of Code[10];
        BinCode: array[3] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Warehouse Pick] [Sorting]
        // [SCENARIO 406575] Warehouse pick lines sorted by bin code are then also sorted by shelf no.
        Initialize();

        // [GIVEN] Location with "Bin Mandatory" = TRUE.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);

        ItemNo := LibraryUtility.GenerateGUID();
        for i := 1 to 3 do begin
            ShelfNo[i] := LibraryUtility.GenerateGUID();
            BinCode[i] := LibraryUtility.GenerateGUID();
        end;

        // [GIVEN] Warehouse pick with 3 lines:
        // [GIVEN] Line 1: bin code = "B1", shelf no. = "S3".
        // [GIVEN] Line 2: bin code = "B2", shelf no. = "S2"
        // [GIVEN] Line 3: bin code = "B2", shelf no. = "S1"
        MockWhseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, Location.Code);
        MockWhseActivityLineWithBinAndShelf(
          WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, ItemNo, BinCode[1], ShelfNo[3]);
        MockWhseActivityLineWithBinAndShelf(
          WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, ItemNo, BinCode[2], ShelfNo[2]);
        MockWhseActivityLineWithBinAndShelf(
          WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, ItemNo, BinCode[2], ShelfNo[1]);

        // [WHEN] Select "Shelf or Bin" sorting method on the warehouse pick header.
        WarehouseActivityHeader.Validate("Sorting Method", "Whse. Activity Sorting Method"::"Shelf or Bin");

        // [THEN] The pick lines are sorted by bin code first, then by shelf, as follows:
        // [THEN] Line 1: bin code = "B1", shelf no. = "S3".
        // [THEN] Line 2: bin code = "B2", shelf no. = "S1"
        // [THEN] Line 3: bin code = "B2", shelf no. = "S2"
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetCurrentKey("Sorting Sequence No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");

        WarehouseActivityLine.FindSet();
        WarehouseActivityLine.TestField("Bin Code", BinCode[1]);
        WarehouseActivityLine.TestField("Shelf No.", ShelfNo[3]);

        WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField("Bin Code", BinCode[2]);
        WarehouseActivityLine.TestField("Shelf No.", ShelfNo[1]);

        WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField("Bin Code", BinCode[2]);
        WarehouseActivityLine.TestField("Shelf No.", ShelfNo[2]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ShelfNoOnWhsePickLinesForATOComponents()
    var
        Location: Record Location;
        AsmItem: Record Item;
        CompItem: Record Item;
        BOMComponent: Record "BOM Component";
        SKU: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Assemble-to-Order] [Warehouse Pick] [Shelf]
        // [SCENARIO 442501] Shelf No. on warehouse pick lines for an assemble-to-order component is populated from the item or SKU card.
        Initialize();

        // [GIVEN] Location with required shipment and pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);

        // [GIVEN] Assemble-to-order item "A", Shelf No. = "S1".
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Validate("Shelf No.", LibraryUtility.GenerateGUID());
        AsmItem.Modify(true);

        // [GIVEN] Component item "C", create a stockkeeping unit, set Shelf No. = "S2" on the new SKU.
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location.Code, CompItem."No.", '');
        SKU.Validate("Shelf No.", LibraryUtility.GenerateGUID());
        SKU.Modify(true);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");

        // [GIVEN] Post item "C" to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, CompItem."No.", Location.Code, '', LibraryRandom.RandInt(100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for item "A" with a linked assembly-to-order, release the order, create warehouse shipment.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', AsmItem."No.", 1, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create pick from the warehouse shipment.
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
            DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] "Shelf No." = "S2" on the pick line for component "C".
        WarehouseActivityLine.SetRange("Item No.", CompItem."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Shelf No.", SKU."Shelf No.");
    end;

    [Test]
    procedure AutofillLotTrackingOnNextPlaceLine()
    var
        Location: Record Location;
        Bins: array[3] of Record Bin;
        Item: Record Item;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        TakeWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        PlaceWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        xWarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Pick]
        // [SCENARIO 459864] Automatically copy Lot No. from Take line to the next Place line in warehouse pick.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location set up for required shipment and pick.
        // [GIVEN] Lot-tracked item with warehouse tracking.
        CreateLocationForWhsePick(Location, Bins);
        Item.Get(CreateItemWithLotTracking());

        // [GIVEN] Post lot "L1" to bin "B1" and lot "L2" to bin "B2" using item journal.
        CreateAndPostItemJournalLineWithTracking(Bins[1], Item."No.", '', LotNos[1], 0D, Qty);
        CreateAndPostItemJournalLineWithTracking(Bins[2], Item."No.", '', LotNos[2], 0D, Qty);

        // [GIVEN] Sales order, release, create warehouse shipment and pick.
        CreateSalesOrderWithPick(WarehouseActivityHeader, Item."No.", Location.Code, 2 * Qty);

        // [GIVEN] The pick contains the following lines:
        // [GIVEN] 10000: TAKE from "B1"
        // [GIVEN] 20000: PLACE to ship bin
        // [GIVEN] 30000: TAKE from "B2"
        // [GIVEN] 40000: PLACE to ship bin
        FindTakeAndPlaceWarehouseActivityLines(TakeWarehouseActivityLine, PlaceWarehouseActivityLine, WarehouseActivityHeader);

        // [WHEN] Select lot "L2" on Take line 30000.
        // [THEN] The lot no. is filled in automatically on Place line 40000.
        xWarehouseActivityLine := TakeWarehouseActivityLine[2];
        TakeWarehouseActivityLine[2]."Lot No." := LotNos[2];
        TakeWarehouseActivityLine[2].CopyItemTrackingToRelatedLine(xWarehouseActivityLine, TakeWarehouseActivityLine[2].FieldNo("Lot No."));
        PlaceWarehouseActivityLine[2].Find();
        PlaceWarehouseActivityLine[2].TestField("Lot No.", LotNos[2]);

        // [WHEN] Select lot "L1" on Take line 10000.
        // [THEN] The lot no. is filled in automatically on Place line 20000.
        xWarehouseActivityLine := TakeWarehouseActivityLine[1];
        TakeWarehouseActivityLine[1]."Lot No." := LotNos[1];
        TakeWarehouseActivityLine[1].CopyItemTrackingToRelatedLine(xWarehouseActivityLine, TakeWarehouseActivityLine[1].FieldNo("Lot No."));
        PlaceWarehouseActivityLine[1].Find();
        PlaceWarehouseActivityLine[1].TestField("Lot No.", LotNos[1]);
    end;

    [Test]
    procedure AutofillSerialLotPackageTrackingOnNextPlaceLine()
    var
        Location: Record Location;
        Bins: array[3] of Record Bin;
        Item: Record Item;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        TakeWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        PlaceWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        xWarehouseActivityLine: Record "Warehouse Activity Line";
        SerialNos: array[2] of Code[50];
        LotNos: array[2] of Code[50];
        PackageNos: array[2] of Code[50];
        ExpirationDates: array[2] of Date;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Pick]
        // [SCENARIO 459864] Automatically copy Serial No., Lot No., Package No. and Expiration Date from Take line to the next Place line in warehouse pick.
        Initialize();
        for i := 1 to ArrayLen(SerialNos) do begin
            LotNos[i] := LibraryUtility.GenerateGUID();
            SerialNos[i] := LibraryUtility.GenerateGUID();
            PackageNos[i] := LibraryUtility.GenerateGUID();
            ExpirationDates[i] := LibraryRandom.RandDate(60);
        end;

        // [GIVEN] Location set up for required shipment and pick.
        // [GIVEN] Lot-tracked item with warehouse tracking.
        CreateLocationForWhsePick(Location, Bins);
        Item.Get(CreateItemWithSerialLotPackageTracking());

        // [GIVEN] Post serial no. "S1", lot "L1", package "P1", expiration date "D1" to bin "B1".
        // [GIVEN] Post serial no. "S2", lot "L2", package "P2", expiration date "D2" to bin "B2".
        CreateAndPostItemJournalLineWithTracking(Bins[1], Item."No.", SerialNos[1], LotNos[1], PackageNos[1], ExpirationDates[1], 1);
        CreateAndPostItemJournalLineWithTracking(Bins[2], Item."No.", SerialNos[2], LotNos[2], PackageNos[2], ExpirationDates[2], 1);

        // [GIVEN] Sales order, release, create warehouse shipment and pick.
        CreateSalesOrderWithPick(WarehouseActivityHeader, Item."No.", Location.Code, 2);

        // [GIVEN] The pick contains the following lines:
        // [GIVEN] 10000: TAKE from "B1"
        // [GIVEN] 20000: PLACE to ship bin
        // [GIVEN] 30000: TAKE from "B2"
        // [GIVEN] 40000: PLACE to ship bin
        FindTakeAndPlaceWarehouseActivityLines(TakeWarehouseActivityLine, PlaceWarehouseActivityLine, WarehouseActivityHeader);

        // [WHEN] Select serial no. "S1" on Take line 10000.
        // [THEN] The serial no., lot no., package no., and expiration date are filled in automatically on Place line 20000.
        xWarehouseActivityLine := TakeWarehouseActivityLine[1];
        TakeWarehouseActivityLine[1].Validate("Serial No.", SerialNos[1]);
        TakeWarehouseActivityLine[1].UpdateExpirationDate(TakeWarehouseActivityLine[1].FieldNo("Serial No."));
        TakeWarehouseActivityLine[1].CopyItemTrackingToRelatedLine(xWarehouseActivityLine, TakeWarehouseActivityLine[1].FieldNo("Serial No."));
        PlaceWarehouseActivityLine[1].Find();
        PlaceWarehouseActivityLine[1].TestField("Serial No.", SerialNos[1]);
        PlaceWarehouseActivityLine[1].TestField("Lot No.", LotNos[1]);
        PlaceWarehouseActivityLine[1].TestField("Package No.", PackageNos[1]);
        PlaceWarehouseActivityLine[1].TestField("Expiration Date", ExpirationDates[1]);
    end;

    [Test]
    procedure AutofillTrackingOnPreviousPlaceLine()
    var
        Location: Record Location;
        Bins: array[3] of Record Bin;
        Item: Record Item;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        TakeWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        PlaceWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        xWarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Pick]
        // [SCENARIO 459864] Automatically copy Lot No. from Take line to the previous Place line in warehouse pick.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location set up for required shipment and pick.
        // [GIVEN] Lot-tracked item with warehouse tracking.
        CreateLocationForWhsePick(Location, Bins);
        Item.Get(CreateItemWithLotTracking());

        // [GIVEN] Post lot "L1" to bin "B1" and lot "L2" to bin "B2" using item journal.
        CreateAndPostItemJournalLineWithTracking(Bins[1], Item."No.", '', LotNos[1], 0D, Qty);
        CreateAndPostItemJournalLineWithTracking(Bins[2], Item."No.", '', LotNos[2], 0D, Qty);

        // [GIVEN] Sales order, release, create warehouse shipment and pick.
        CreateSalesOrderWithPick(WarehouseActivityHeader, Item."No.", Location.Code, 2 * Qty);

        // [GIVEN] The pick contains the following lines:
        // [GIVEN] 10000: TAKE from "B1"
        // [GIVEN] 20000: PLACE to ship bin
        // [GIVEN] 30000: TAKE from "B2"
        // [GIVEN] 40000: PLACE to ship bin
        FindTakeAndPlaceWarehouseActivityLines(TakeWarehouseActivityLine, PlaceWarehouseActivityLine, WarehouseActivityHeader);

        // [GIVEN] Select lot "L1" on Take line 10000 and on Place line 40000.
        TakeWarehouseActivityLine[1]."Lot No." := LotNos[1];
        TakeWarehouseActivityLine[1].Modify();
        PlaceWarehouseActivityLine[2]."Lot No." := LotNos[1];
        PlaceWarehouseActivityLine[2].Modify();

        // [WHEN] Select lot "L2" on Take line 30000.
        // [THEN] The lot no. is filled in automatically on Place line 20000.
        xWarehouseActivityLine := TakeWarehouseActivityLine[2];
        TakeWarehouseActivityLine[2]."Lot No." := LotNos[2];
        TakeWarehouseActivityLine[2].CopyItemTrackingToRelatedLine(xWarehouseActivityLine, TakeWarehouseActivityLine[2].FieldNo("Lot No."));
        PlaceWarehouseActivityLine[1].Find();
        PlaceWarehouseActivityLine[1].TestField("Lot No.", LotNos[2]);
    end;

    [Test]
    procedure DeleteTrackingOnNextPlaceLine()
    var
        Location: Record Location;
        Bins: array[3] of Record Bin;
        Item: Record Item;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        TakeWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        PlaceWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        xWarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Pick]
        // [SCENARIO 459864] Automatically delete Lot No. on Place line after user deletes it on the related Take line.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location set up for required shipment and pick.
        // [GIVEN] Lot-tracked item with warehouse tracking.
        CreateLocationForWhsePick(Location, Bins);
        Item.Get(CreateItemWithLotTracking());

        // [GIVEN] Post lot "L1" to bin "B1" and lot "L2" to bin "B2" using item journal.
        CreateAndPostItemJournalLineWithTracking(Bins[1], Item."No.", '', LotNos[1], 0D, Qty);
        CreateAndPostItemJournalLineWithTracking(Bins[2], Item."No.", '', LotNos[2], 0D, Qty);

        // [GIVEN] Sales order, release, create warehouse shipment and pick.
        CreateSalesOrderWithPick(WarehouseActivityHeader, Item."No.", Location.Code, 2 * Qty);

        // [GIVEN] The pick contains the following lines:
        // [GIVEN] 10000: TAKE from "B1"
        // [GIVEN] 20000: PLACE to ship bin
        // [GIVEN] 30000: TAKE from "B2"
        // [GIVEN] 40000: PLACE to ship bin
        FindTakeAndPlaceWarehouseActivityLines(TakeWarehouseActivityLine, PlaceWarehouseActivityLine, WarehouseActivityHeader);

        // [GIVEN] Select lot "L1" on Take line 10000 and on Place line 40000.
        TakeWarehouseActivityLine[1]."Lot No." := LotNos[1];
        TakeWarehouseActivityLine[1].Modify();
        PlaceWarehouseActivityLine[2]."Lot No." := LotNos[1];
        PlaceWarehouseActivityLine[2].Modify();

        // [WHEN] Delete lot no. on Take line 10000.
        // [THEN] The lot no. is deleled in automatically on Place line 40000.
        xWarehouseActivityLine := TakeWarehouseActivityLine[1];
        TakeWarehouseActivityLine[1]."Lot No." := '';
        TakeWarehouseActivityLine[1].CopyItemTrackingToRelatedLine(xWarehouseActivityLine, TakeWarehouseActivityLine[1].FieldNo("Lot No."));
        PlaceWarehouseActivityLine[2].Find();
        PlaceWarehouseActivityLine[2].TestField("Lot No.", '');
    end;

    [Test]
    procedure DoNotAutofillTrackingOnPlaceLineForAnotherSource()
    var
        Location: Record Location;
        Bins: array[3] of Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        TakeWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        PlaceWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        xWarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Pick]
        // [SCENARIO 459864] Do not copy Lot No. from Take line to the Place line for another source.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location set up for required shipment and pick.
        // [GIVEN] Lot-tracked item with warehouse tracking.
        CreateLocationForWhsePick(Location, Bins);
        Item.Get(CreateItemWithLotTracking());

        // [GIVEN] Post lot "L1" to bin "B1" and lot "L2" to bin "B2" using item journal.
        CreateAndPostItemJournalLineWithTracking(Bins[1], Item."No.", '', LotNos[1], 0D, Qty);
        CreateAndPostItemJournalLineWithTracking(Bins[2], Item."No.", '', LotNos[2], 0D, Qty);

        // [GIVEN] Sales order, release, create warehouse shipment and pick.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] The pick contains the following lines:
        // [GIVEN] 10000: TAKE from "B1"
        // [GIVEN] 20000: PLACE to ship bin
        // [GIVEN] 30000: TAKE from "B2"
        // [GIVEN] 40000: PLACE to ship bin
        FindTakeAndPlaceWarehouseActivityLines(TakeWarehouseActivityLine, PlaceWarehouseActivityLine, WarehouseActivityHeader);

        // [GIVEN] Select lot "L1" on Take line 10000 and on Place line 40000.
        TakeWarehouseActivityLine[1]."Lot No." := LotNos[1];
        TakeWarehouseActivityLine[1].Modify();
        PlaceWarehouseActivityLine[2]."Lot No." := LotNos[1];
        PlaceWarehouseActivityLine[2].Modify();

        // [WHEN] Select lot "L2" on Take line 30000.
        // [THEN] The lot no. is not copied to Place line 20000 because it has different source document line.
        xWarehouseActivityLine := TakeWarehouseActivityLine[2];
        TakeWarehouseActivityLine[2]."Lot No." := LotNos[2];
        TakeWarehouseActivityLine[2].CopyItemTrackingToRelatedLine(xWarehouseActivityLine, TakeWarehouseActivityLine[2].FieldNo("Lot No."));
        PlaceWarehouseActivityLine[1].Find();
        PlaceWarehouseActivityLine[1].TestField("Lot No.", '');
    end;

    [Test]
    procedure DoNotAutofillTrackingOnPlaceLineWithDifferentQuantity()
    var
        Location: Record Location;
        Bins: array[3] of Record Bin;
        Item: Record Item;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        TakeWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        PlaceWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
        xWarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Pick]
        // [SCENARIO 459864] Do not copy Lot No. from Take line to the Place line with different quantity in warehouse pick.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location set up for required shipment and pick.
        // [GIVEN] Lot-tracked item with warehouse tracking.
        CreateLocationForWhsePick(Location, Bins);
        Item.Get(CreateItemWithLotTracking());

        // [GIVEN] Post lot "L1" to bin "B1" and lot "L2" to bin "B2" using item journal.
        CreateAndPostItemJournalLineWithTracking(Bins[1], Item."No.", '', LotNos[1], 0D, Qty);
        CreateAndPostItemJournalLineWithTracking(Bins[2], Item."No.", '', LotNos[2], 0D, 2 * Qty);

        // [GIVEN] Sales order, release, create warehouse shipment and pick.
        CreateSalesOrderWithPick(WarehouseActivityHeader, Item."No.", Location.Code, 3 * Qty);

        // [GIVEN] The pick contains the following lines:
        // [GIVEN] 10000: TAKE from "B1"
        // [GIVEN] 20000: PLACE to ship bin
        // [GIVEN] 30000: TAKE from "B2"
        // [GIVEN] 40000: PLACE to ship bin
        FindTakeAndPlaceWarehouseActivityLines(TakeWarehouseActivityLine, PlaceWarehouseActivityLine, WarehouseActivityHeader);

        // [GIVEN] Select lot "L1" on Take line 10000 and on Place line 40000.
        TakeWarehouseActivityLine[1]."Lot No." := LotNos[1];
        TakeWarehouseActivityLine[1].Modify();
        PlaceWarehouseActivityLine[2]."Lot No." := LotNos[1];
        PlaceWarehouseActivityLine[2].Modify();

        // [WHEN] Select lot "L2" on Take line 30000.
        // [THEN] The lot no. is not copied to Place line 20000 because it has different quantity.
        xWarehouseActivityLine := TakeWarehouseActivityLine[2];
        TakeWarehouseActivityLine[2]."Lot No." := LotNos[2];
        TakeWarehouseActivityLine[2].CopyItemTrackingToRelatedLine(xWarehouseActivityLine, TakeWarehouseActivityLine[2].FieldNo("Lot No."));
        PlaceWarehouseActivityLine[1].Find();
        PlaceWarehouseActivityLine[1].TestField("Lot No.", '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse Unit Tests");
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateItemWithLotTracking(): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItem(Item);
        ItemTrackingCode.Init();
        ItemTrackingCode.Code := LibraryUtility.GenerateGUID();
        ItemTrackingCode."Lot Specific Tracking" := true;
        ItemTrackingCode."Lot Warehouse Tracking" := true;
        ItemTrackingCode.Insert();
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify();
        exit(Item."No.");
    end;

    local procedure CreateItemWithSerialLotPackageTracking(): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItem(Item);
        ItemTrackingCode.Init();
        ItemTrackingCode.Code := LibraryUtility.GenerateGUID();
        ItemTrackingCode."SN Specific Tracking" := true;
        ItemTrackingCode."SN Warehouse Tracking" := true;
        ItemTrackingCode."Lot Specific Tracking" := true;
        ItemTrackingCode."Lot Warehouse Tracking" := true;
        ItemTrackingCode."Package Specific Tracking" := true;
        ItemTrackingCode."Package Warehouse Tracking" := true;
        ItemTrackingCode."Use Expiration Dates" := true;
        ItemTrackingCode.Insert();
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify();
        exit(Item."No.");
    end;

    local procedure CreateLocationForWhsePick(var Location: Record Location; var Bins: array[3] of Record Bin)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(Bins[1], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bins[2], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bins[3], Location.Code, '', '', '');
        Location.Validate("Shipment Bin Code", Bins[3].Code);
        Location.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLineWithTracking(Bin: Record Bin; ItemNo: Code[20]; SerialNo: Code[50]; LotNo: Code[50]; ExpirationDate: Date; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, Bin."Location Code", Bin.Code, Qty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, SerialNo, LotNo, ItemJournalLine.Quantity);
        ReservationEntry.Validate("Expiration Date", ExpirationDate);
        ReservationEntry.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalLineWithTracking(Bin: Record Bin; ItemNo: Code[20]; SerialNo: Code[50]; LotNo: Code[50]; PackageNo: Code[50]; ExpirationDate: Date; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, Bin."Location Code", Bin.Code, Qty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, SerialNo, LotNo, PackageNo, ItemJournalLine.Quantity);
        ReservationEntry.Validate("Expiration Date", ExpirationDate);
        ReservationEntry.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateSalesOrderWithPick(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Qty, LocationCode, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure FindTakeAndPlaceWarehouseActivityLines(var TakeWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
                                                           var PlaceWarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
                                                           WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        TakeWarehouseActivityLine[1] := WarehouseActivityLine;
        WarehouseActivityLine.Next();
        TakeWarehouseActivityLine[2] := WarehouseActivityLine;

        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        PlaceWarehouseActivityLine[1] := WarehouseActivityLine;
        WarehouseActivityLine.Next();
        PlaceWarehouseActivityLine[2] := WarehouseActivityLine;
    end;

    local procedure CreateInventory(var ItemLedgerEntry: Record "Item Ledger Entry"; BinCodeToStore: Code[10]; DPPLocation: Boolean)
    var
        WarehouseEntry2: Record "Warehouse Entry";
        WarehouseEntry: Record "Warehouse Entry";
        ItemNo: Code[20];
        LocationCode: Code[10];
    begin
        LocationCode := MockCustomLocationCode(not DPPLocation, false, false, DPPLocation);
        ItemNo := CreateItemWithLotTracking();

        MockILE(ItemLedgerEntry, ItemNo, LocationCode, 10);
        ItemLedgerEntry."Lot No." := LibraryUtility.GenerateGUID();
        ItemLedgerEntry.Modify();

        WarehouseEntry2.FindLast();
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := WarehouseEntry2."Entry No." + 1;
        WarehouseEntry."Item No." := ItemLedgerEntry."Item No.";
        WarehouseEntry."Location Code" := ItemLedgerEntry."Location Code";
        WarehouseEntry."Bin Code" := BinCodeToStore;
        WarehouseEntry."Qty. (Base)" := ItemLedgerEntry.Quantity;
        WarehouseEntry."Lot No." := ItemLedgerEntry."Lot No.";
        WarehouseEntry.Insert();
    end;

    local procedure CreatePick(DemandType: Option Sales,Assembly,Production; DPPLocation: Boolean; InvtPick: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var ItemLedgerEntry: Record "Item Ledger Entry"; RefDate: Date; TakeBinCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ProdOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PlaceBinCode: Code[10];
        WhseDocType: Enum "Warehouse Activity Document Type";
        WhseDocNo: Code[20];
        SourceType: Integer;
        SourceSubtype: Option;
        SourceNo: Code[20];
        SourceLineNo: Integer;
        SourceSubLineNo: Integer;
        PlaceActionType: Enum "Warehouse Action Type";
    begin
        PlaceBinCode := LibraryUtility.GenerateGUID();
        case DemandType of
            DemandType::Sales:
                begin
                    SalesLine."Document Type" := SalesLine."Document Type"::Order;
                    SalesLine."Document No." := LibraryUtility.GenerateGUID();
                    SalesLine.Type := SalesLine.Type::Item;
                    SalesLine."No." := ItemLedgerEntry."Item No.";
                    SalesLine."Location Code" := ItemLedgerEntry."Location Code";
                    SalesLine."Quantity (Base)" := ItemLedgerEntry.Quantity;
                    SalesLine."Outstanding Qty. (Base)" := SalesLine."Quantity (Base)";
                    SalesLine."Shipment Date" := RefDate;
                    SalesLine.Insert();

                    WarehouseShipmentHeader.Init();
                    WarehouseShipmentHeader."No." := LibraryUtility.GenerateGUID();
                    WarehouseShipmentHeader.Insert();
                    WarehouseShipmentLine.Init();
                    WarehouseShipmentLine."No." := WarehouseShipmentHeader."No.";
                    WarehouseShipmentLine."Item No." := SalesLine."No.";
                    WarehouseShipmentLine."Qty. (Base)" := SalesLine."Quantity (Base)";
                    WarehouseShipmentLine.Quantity := SalesLine."Quantity (Base)";
                    WarehouseShipmentLine."Qty. Outstanding (Base)" := SalesLine."Outstanding Qty. (Base)";
                    WarehouseShipmentLine."Qty. Outstanding" := SalesLine."Outstanding Qty. (Base)";
                    WarehouseShipmentLine."Location Code" := SalesLine."Location Code";
                    WarehouseShipmentLine."Bin Code" := PlaceBinCode;
                    WarehouseShipmentLine."Source Type" := DATABASE::"Sales Line";
                    WarehouseShipmentLine."Source Subtype" := SalesLine."Document Type".AsInteger();
                    WarehouseShipmentLine."Source No." := SalesLine."Document No.";
                    WarehouseShipmentLine."Source Line No." := SalesLine."Line No.";
                    WarehouseShipmentLine."Shipment Date" := SalesLine."Shipment Date";
                    WarehouseShipmentLine."Due Date" := SalesLine."Shipment Date" + 2; // different from the Shipment Date
                    WarehouseShipmentLine.Insert(true);

                    WhseDocType := WarehouseActivityLine."Whse. Document Type"::Shipment;
                    WhseDocNo := WarehouseShipmentLine."No.";
                    SourceType := DATABASE::"Sales Line";
                    SourceSubtype := WarehouseShipmentLine."Source Subtype";
                    SourceNo := WarehouseShipmentLine."Source No.";
                    SourceLineNo := WarehouseShipmentLine."Source Line No.";
                    SourceSubLineNo := 0;
                end;
            DemandType::Assembly:
                begin
                    AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
                    AssemblyHeader."No." := LibraryUtility.GenerateGUID();
                    AssemblyHeader.Insert();
                    AssemblyLine."Document Type" := AssemblyHeader."Document Type";
                    AssemblyLine."Document No." := AssemblyHeader."No.";
                    AssemblyLine.Type := AssemblyLine.Type::Item;
                    AssemblyLine."No." := ItemLedgerEntry."Item No.";
                    AssemblyLine."Location Code" := ItemLedgerEntry."Location Code";
                    AssemblyLine."Bin Code" := PlaceBinCode;
                    AssemblyLine."Quantity (Base)" := ItemLedgerEntry.Quantity;
                    AssemblyLine."Remaining Quantity (Base)" := AssemblyLine."Quantity (Base)";
                    AssemblyLine."Due Date" := RefDate;
                    AssemblyLine.Insert();

                    WhseDocType := WarehouseActivityLine."Whse. Document Type"::Assembly;
                    WhseDocNo := AssemblyLine."Document No.";
                    SourceType := DATABASE::"Assembly Line";
                    SourceSubtype := AssemblyLine."Document Type".AsInteger();
                    SourceNo := AssemblyLine."Document No.";
                    SourceLineNo := AssemblyLine."Line No.";
                    SourceSubLineNo := 0;
                end;
            DemandType::Production:
                begin
                    ProdOrder.Status := ProdOrder.Status::Released;
                    ProdOrder."No." := LibraryUtility.GenerateGUID();
                    ProdOrder.Insert();
                    ProdOrderComponent.Init();
                    ProdOrderComponent.Status := ProdOrder.Status;
                    ProdOrderComponent."Prod. Order No." := ProdOrder."No.";
                    ProdOrderComponent."Item No." := ItemLedgerEntry."Item No.";
                    ProdOrderComponent."Location Code" := ItemLedgerEntry."Location Code";
                    ProdOrderComponent."Bin Code" := PlaceBinCode;
                    ProdOrderComponent."Quantity (Base)" := ItemLedgerEntry.Quantity;
                    ProdOrderComponent."Expected Qty. (Base)" := ProdOrderComponent."Quantity (Base)";
                    ProdOrderComponent."Remaining Qty. (Base)" := ProdOrderComponent."Quantity (Base)";
                    ProdOrderComponent."Due Date" := RefDate;
                    ProdOrderComponent.Insert();

                    WhseDocType := WarehouseActivityLine."Whse. Document Type"::Production;
                    WhseDocNo := ProdOrderComponent."Prod. Order No.";
                    SourceType := DATABASE::"Prod. Order Component";
                    SourceSubtype := ProdOrderComponent.Status.AsInteger();
                    SourceNo := ProdOrderComponent."Prod. Order No.";
                    SourceLineNo := ProdOrderComponent."Line No.";
                    SourceSubLineNo := ProdOrderComponent."Prod. Order Line No.";
                end;
        end;

        if DPPLocation then
            WarehouseActivityHeader.Type := WarehouseActivityHeader.Type::Pick
        else
            if InvtPick then
                WarehouseActivityHeader.Type := WarehouseActivityHeader.Type::"Invt. Pick"
            else
                WarehouseActivityHeader.Type := WarehouseActivityHeader.Type::"Invt. Movement";
        WarehouseActivityHeader."No." := LibraryUtility.GenerateGUID();
        WarehouseActivityHeader."Registering No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseActivityHeader.Insert();
        if WarehouseActivityHeader.Type <> WarehouseActivityHeader.Type::"Invt. Pick" then
            CreateWarehouseActivityLine(WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take,
              ItemLedgerEntry."Location Code", TakeBinCode, ItemLedgerEntry."Item No.", ItemLedgerEntry.Quantity, ItemLedgerEntry."Lot No.",
              WhseDocType, WhseDocNo, SourceType, SourceSubtype, SourceNo, SourceLineNo, SourceSubLineNo);

        if WarehouseActivityHeader.Type = WarehouseActivityHeader.Type::"Invt. Pick" then
            PlaceActionType := WarehouseActivityLine."Action Type"::" "
        else
            PlaceActionType := WarehouseActivityLine."Action Type"::Place;
        CreateWarehouseActivityLine(WarehouseActivityHeader, PlaceActionType,
          ItemLedgerEntry."Location Code", PlaceBinCode, ItemLedgerEntry."Item No.", ItemLedgerEntry.Quantity, ItemLedgerEntry."Lot No.",
          WhseDocType, WhseDocNo, SourceType, SourceSubtype, SourceNo, SourceLineNo, SourceSubLineNo);
    end;

    local procedure CreateWarehouseActivityLine(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; BinCode: Code[10]; ItemNo: Code[20]; QuantityBase: Decimal; LotNo: Code[50]; WhseDocType: Enum "Warehouse Activity Document Type"; WhseDocNo: Code[20]; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
    begin
        case WarehouseActivityHeader.Type of
            WarehouseActivityHeader.Type::"Put-away":
                WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::"Put-away";
            WarehouseActivityHeader.Type::Pick:
                WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Pick;
            WarehouseActivityHeader.Type::Movement:
                WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Movement;
            WarehouseActivityHeader.Type::"Invt. Put-away":
                WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::"Invt. Put-away";
            WarehouseActivityHeader.Type::"Invt. Pick":
                WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::"Invt. Pick";
            WarehouseActivityHeader.Type::"Invt. Movement":
                WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::"Invt. Movement";
        end;
        WarehouseActivityLine."No." := WarehouseActivityHeader."No.";
        WarehouseActivityLine2.SetRange("Activity Type", WarehouseActivityLine."Activity Type");
        WarehouseActivityLine2.SetRange("No.", WarehouseActivityLine."No.");
        if WarehouseActivityLine2.FindLast() then
            WarehouseActivityLine."Line No." := WarehouseActivityLine2."Line No." + 10000
        else
            WarehouseActivityLine."Line No." := 10000;
        WarehouseActivityLine."Action Type" := ActionType;
        WarehouseActivityLine."Location Code" := LocationCode;
        WarehouseActivityLine."Bin Code" := BinCode;
        WarehouseActivityLine."Item No." := ItemNo;
        WarehouseActivityLine."Qty. (Base)" := QuantityBase;
        WarehouseActivityLine."Qty. to Handle (Base)" := WarehouseActivityLine."Qty. (Base)";
        WarehouseActivityLine."Lot No." := LotNo;
        WarehouseActivityLine."Whse. Document Type" := WhseDocType;
        WarehouseActivityLine."Whse. Document No." := WhseDocNo;
        WarehouseActivityLine."Source Type" := SourceType;
        WarehouseActivityLine."Source Subtype" := SourceSubtype;
        WarehouseActivityLine."Source No." := SourceNo;
        WarehouseActivityLine."Source Line No." := SourceLineNo;
        WarehouseActivityLine."Source Subline No." := SourceSubLineNo;
        WarehouseActivityLine.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF335595NoErrorOnRoundingShouldOccurWhenCreatingWarehouseShipment()
    var
        ItemUnitOfMeasureBOX: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesWarehouseMgt: Codeunit "Sales Warehouse Mgt.";
        ItemNo: Code[20];
        LocationCode: Code[10];
        Qty: Decimal;
    begin
        // Refer VSTF 335595
        Initialize();

        // SETUP : Create sales
        LocationCode := MockCustomLocationCode(false, true, false, false);
        ItemNo := MockItemNoWithBaseUOM();
        VSTF335595CreateUnitOfMeasure(ItemUnitOfMeasureBOX, ItemNo, LibraryUtility.GenerateGUID(), 144);

        Qty := 20 / 144;
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        SalesHeader.Insert();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine."Unit of Measure Code" := ItemUnitOfMeasureBOX.Code;
        SalesLine."Qty. per Unit of Measure" := ItemUnitOfMeasureBOX."Qty. per Unit of Measure";
        SalesLine.Validate(Quantity, Qty);
        SalesLine."Location Code" := LocationCode;
        SalesLine.Insert();

        WarehouseShipmentHeader.Init();
        WarehouseShipmentHeader."No." := LibraryUtility.GenerateGUID();
        WarehouseShipmentHeader."Location Code" := LocationCode;
        WarehouseShipmentHeader.Insert();

        // EXERCISE : Create shipment from sales line
        SalesWarehouseMgt.FromSalesLine2ShptLine(WarehouseShipmentHeader, SalesLine);

        // VERIFY : No rounding errors on Quantity
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        Assert.AreEqual(SalesLine.Quantity, WarehouseShipmentLine.Quantity,
          'Quantity must be same as that of sales line.');
        Assert.AreEqual(UoMMgt.RoundQty(SalesLine."Outstanding Quantity"), WarehouseShipmentLine."Qty. Outstanding",
          'Outstanding Quantity must be same as that of sales line.');
        Assert.AreEqual(SalesLine."Quantity (Base)", WarehouseShipmentLine."Qty. (Base)",
          'Quantity Base must be same as that of sales line.');
        Assert.AreEqual(SalesLine."Outstanding Qty. (Base)", WarehouseShipmentLine."Qty. Outstanding (Base)",
          'Outstanding Quantity Base must be same as that of sales line.');
    end;

    local procedure VSTF335595CreateUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; UOMCode: Code[10]; QtyPerUOM: Decimal)
    begin
        ItemUnitOfMeasure."Item No." := ItemNo;
        ItemUnitOfMeasure.Code := UOMCode;
        ItemUnitOfMeasure."Qty. per Unit of Measure" := QtyPerUOM;
        ItemUnitOfMeasure.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegiserablePickCreatedWithoutRoundingErrors()
    var
        ItemUnitOfMeasureForSales: Record "Item Unit of Measure";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
        ItemNo: Code[20];
        LocationCode: Code[10];
        LotNo: Code[10];
        Qty: Decimal;
    begin
        // VSTF 330787
        // SETUP : Create inventory with entries designed to induce the rounding errors
        Initialize();
        VSTF330787CreateInventory(ItemNo, LocationCode, true, ItemUnitOfMeasureForSales, LotNo);

        // SETUP : Create sales, and reservation entries against inventory.
        Qty := 10;
        VSTF330787CreateSalesAndReservationEntriesAgainstInventory(WarehouseShipmentHeader, WarehouseShipmentLine,
          ItemNo, LocationCode, 10, ItemUnitOfMeasureForSales, LotNo);

        // EXERCISE: Create pick or inventory pick
        Commit();
        WarehouseShipmentLine.SetRange("Item No.", WarehouseShipmentLine."Item No.");
        WhseShipmentCreatePick.SetWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        WhseShipmentCreatePick.SetHideValidationDialog(true);
        WhseShipmentCreatePick.UseRequestPage(false);
        WhseShipmentCreatePick.RunModal();

        // VERIFY: Qty on pick should be same as demand
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindSet();
        repeat
            Assert.AreEqual(Qty, WarehouseActivityLine.Quantity, 'Same quantity in sales and pick.');
            Assert.AreEqual(WarehouseShipmentLine."Unit of Measure Code",
              WarehouseActivityLine."Unit of Measure Code", 'Same UOM in sales and pick.');
            WarehouseActivityLine."Qty. to Handle" := WarehouseActivityLine.Quantity;
            WarehouseActivityLine."Qty. to Handle (Base)" := WarehouseActivityLine."Qty. (Base)";
        until WarehouseActivityLine.Next() = 0;

        // EXERCISE: Register pick
        CODEUNIT.Run(CODEUNIT::"Whse.-Activity-Register", WarehouseActivityLine);

        // VERIFY: Pick vanishes
        Assert.IsFalse(WarehouseActivityLine.Find('-'), 'Warehouse pick should have been registered.');
    end;

    local procedure VSTF330787CreateInventory(var ItemNo: Code[20]; var LocationCode: Code[10]; DPPLocation: Boolean; var ItemUnitOfMeasureCAS: Record "Item Unit of Measure"; var LotNo: Code[10])
    var
        ItemUnitOfMeasureBAG: Record "Item Unit of Measure";
        BinCode: Code[20];
    begin
        LocationCode := VSTF330787CreateLocation(DPPLocation);
        BinCode := VSTF330787CreateBin(LocationCode);

        ItemNo := CreateItemWithLotTracking();
        VSTF330787CreateItemUnitOfMeasure(ItemUnitOfMeasureBAG, ItemNo, 0.45);
        VSTF330787CreateItemUnitOfMeasure(ItemUnitOfMeasureCAS, ItemNo, 10.8);

        LotNo := LibraryUtility.GenerateGUID();
        VSTF330787CreateEntry(ItemNo, LocationCode, BinCode, 4, LotNo, ItemUnitOfMeasureBAG);
        VSTF330787CreateEntry(ItemNo, LocationCode, BinCode, 4, LotNo, ItemUnitOfMeasureBAG);
        VSTF330787CreateEntry(ItemNo, LocationCode, BinCode, 10, LotNo, ItemUnitOfMeasureCAS);
    end;

    local procedure VSTF334573CreateInventory(var ItemUOM: Record "Item Unit of Measure"; var LocationCode: Code[10]; var LotNo: array[3] of Code[20]; var BinCode: array[2] of Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        UnitOfMeasure: Record "Unit of Measure";
        WarehouseEmployee: Record "Warehouse Employee";
        ItemNo: Code[20];
    begin
        LocationCode := CreateWhiteLikeLocationWithPutPickFlags();

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);

        BinCode[1] := CreateBinWithPutPickType(LocationCode);
        BinCode[2] := CreateBinWithPutPickType(LocationCode);

        ItemNo := CreateItemWithTracking();

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ItemNo, UnitOfMeasure.Code, 8.4);

        VSTF334573CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, UnitOfMeasure, LotNo);

        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.");

        VSTF334573CreateAndRegisterPutAway(PurchaseHeader."No.", BinCode);
    end;

    local procedure VSTF334573CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; UnitOfMeasure: Record "Unit of Measure"; var LotNo: array[3] of Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify();

        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, 20, LocationCode, UnitOfMeasure);
        LotNo[1] := GetItemTrackingLotNo(PurchaseLine);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, 15, LocationCode, UnitOfMeasure);
        LotNo[2] := GetItemTrackingLotNo(PurchaseLine);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, 15, LocationCode, UnitOfMeasure);
        LotNo[3] := GetItemTrackingLotNo(PurchaseLine);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure VSTF334573CreateAndRegisterPutAway(PurchaseHeaderNo: Code[20]; BinCode: array[2] of Code[20])
    begin
        SplitPutAwayLineAndUpdateBin(PurchaseHeaderNo, 10, BinCode, 20);
        SplitPutAwayLineAndUpdateBin(PurchaseHeaderNo, 7, BinCode, 15);
        SplitPutAwayLineAndUpdateBin(PurchaseHeaderNo, 8, BinCode, 15);

        RegisterPutAway(PurchaseHeaderNo);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; UnitOfMeasure: Record "Unit of Measure")
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        PurchaseLine.Modify(true);

        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure GetItemTrackingLotNo(PurchaseLine: Record "Purchase Line"): Code[20]
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source ID", PurchaseLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", PurchaseLine."Line No.");
        ReservationEntry.SetRange("Item No.", PurchaseLine."No.");
        ReservationEntry.FindFirst();
        exit(ReservationEntry."Lot No.");
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure SplitPutAwayLineAndUpdateBin(SourceNo: Code[20]; QtyToHandle: Decimal; BinCode: array[2] of Code[20]; Qty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindFirstWhseActivityLine(WarehouseActivityLine, SourceNo, Qty);

        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Validate("Bin Code", BinCode[1]);
        WarehouseActivityLine.Modify(true);

        WarehouseActivityLine.SplitLine(WarehouseActivityLine);
        // only one empty exists after split
        WarehouseActivityLine.SetRange(Quantity);
        WarehouseActivityLine.SetRange("Bin Code", '');
        WarehouseActivityLine.FindFirst();

        WarehouseActivityLine.Validate("Bin Code", BinCode[2]);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure RegisterPutAway(SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindFirstWhseActivityLine(WarehouseActivityLine, SourceNo, 0);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindFirstWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; Qty: Decimal)
    begin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Purchase Order");
        if Qty <> 0 then
            WarehouseActivityLine.SetRange(Quantity, Qty);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure VSTF330787CreateLocation(DPPLocation: Boolean): Code[10]
    begin
        exit(MockCustomLocationCode(true, false, DPPLocation, DPPLocation));
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; BinTypeCode: Code[20])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.SetRange("Cross-Dock Bin Zone", false);

        Zone.FindFirst();
    end;

    local procedure CreateBinWithPutPickType(LocationCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
        Zone: Record Zone;
        BinTypeCode: Code[10];
    begin
        BinTypeCode := LibraryWarehouse.SelectBinType(false, false, true, true);
        FindZone(Zone, LocationCode, BinTypeCode);
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), Zone.Code, BinTypeCode);
        exit(Bin.Code);
    end;

    local procedure CreateSimpleLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        exit(Location.Code);
    end;

    local procedure CreateLocationWithWhseEmployee(): Code[10]
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, CreateSimpleLocation(), false);
        exit(WarehouseEmployee."Location Code");
    end;

    local procedure CreateInTransitLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.Get(CreateSimpleLocation());
        Location."Use As In-Transit" := true;
        Location.Modify();
        exit(Location.Code);
    end;

    local procedure VSTF330787CreateBin(LocationCode: Code[10]): Code[10]
    var
        Bin: Record Bin;
    begin
        Bin.Init();
        Bin.Code := LibraryUtility.GenerateGUID();
        Bin."Location Code" := LocationCode;
        Bin.Insert();
        exit(Bin.Code);
    end;

    local procedure VSTF330787CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; QtyPerUOM: Decimal)
    begin
        Clear(ItemUnitOfMeasure);
        ItemUnitOfMeasure."Item No." := ItemNo;
        ItemUnitOfMeasure.Code := LibraryUtility.GenerateGUID();
        ItemUnitOfMeasure."Qty. per Unit of Measure" := QtyPerUOM;
        ItemUnitOfMeasure.Insert();
    end;

    local procedure VSTF330787CreateEntry(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; LotNo: Code[50]; ItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseEntry2: Record "Warehouse Entry";
        BinContent: Record "Bin Content";
        BinType: Record "Bin Type";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.ClearState();
        MockILE(ItemLedgerEntry, ItemNo, LocationCode, Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure");
        ItemLedgerEntry."Lot No." := LotNo;
        ItemLedgerEntry."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        ItemLedgerEntry."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        ItemLedgerEntry.Modify();

        WarehouseEntry2.FindLast();
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := WarehouseEntry2."Entry No." + 1;
        WarehouseEntry."Item No." := ItemLedgerEntry."Item No.";
        WarehouseEntry."Location Code" := ItemLedgerEntry."Location Code";
        WarehouseEntry."Bin Code" := BinCode;
        WarehouseEntry.Quantity := Quantity;
        WarehouseEntry."Qty. (Base)" := ItemLedgerEntry.Quantity;
        WarehouseEntry."Lot No." := ItemLedgerEntry."Lot No.";
        WarehouseEntry."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        WarehouseEntry."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        WarehouseEntry.Insert();

        if not BinContent.Get(WarehouseEntry."Location Code", WarehouseEntry."Bin Code", WarehouseEntry."Item No.",
             WarehouseEntry."Variant Code", WarehouseEntry."Unit of Measure Code")
        then begin
            BinContent."Location Code" := WarehouseEntry."Location Code";
            BinContent."Bin Code" := WarehouseEntry."Bin Code";
            BinContent."Item No." := WarehouseEntry."Item No.";
            BinContent."Unit of Measure Code" := WarehouseEntry."Unit of Measure Code";
            BinContent."Qty. per Unit of Measure" := WarehouseEntry."Qty. per Unit of Measure";
            BinType.SetRange(Pick, true);
            BinType.FindFirst();
            BinContent."Bin Type Code" := BinType.Code;
            BinContent.Insert();
        end;
    end;

    local procedure CreateWhiteLikeLocationWithPutPickFlags(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Always Create Pick Line", true);
        Location.Validate("Bin Capacity Policy", Location."Bin Capacity Policy"::"Never Check Capacity");
        Location.Validate("Use ADCS", false);
        Location.Modify(true);

        exit(Location.Code);
    end;

    local procedure CreateItemWithTracking(): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode."Lot Warehouse Tracking" := true;
        ItemTrackingCode."Lot Transfer Tracking" := true;
        ItemTrackingCode."Lot Purchase Outbound Tracking" := true;
        ItemTrackingCode.Modify(true);

        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        exit(Item."No.");
    end;

    local procedure VSTF330787CreateSalesAndReservationEntriesAgainstInventory(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; ItemUnitOfMeasure: Record "Item Unit of Measure"; LotNo: Code[10])
    var
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        QtyFromCasILE: Decimal;
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := LibraryUtility.GenerateGUID();
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine."Location Code" := LocationCode;
        SalesLine.Quantity := Quantity;
        SalesLine."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        SalesLine."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        SalesLine."Quantity (Base)" := SalesLine.Quantity * SalesLine."Qty. per Unit of Measure";
        SalesLine."Outstanding Qty. (Base)" := SalesLine."Quantity (Base)";
        SalesLine.Insert();

        VSTF330787CreateWarehouseShipment(WarehouseShipmentHeader, WarehouseShipmentLine, SalesLine);

        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetFilter("Unit of Measure Code", '<>%1', ItemUnitOfMeasure.Code);

        ItemLedgerEntry.FindFirst();
        ReservationEntry.FindLast();
        VSTF330787CreateReservation(ReservationEntry."Entry No." + 1, false,
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
          -0.16667, -ItemLedgerEntry.Quantity, ItemUnitOfMeasure."Qty. per Unit of Measure", LotNo);
        VSTF330787CreateReservation(ReservationEntry."Entry No." + 1, true,
          DATABASE::"Item Ledger Entry", 0, '', ItemLedgerEntry."Entry No.",
          ItemLedgerEntry.Quantity * ItemLedgerEntry."Qty. per Unit of Measure", ItemLedgerEntry.Quantity,
          ItemLedgerEntry."Qty. per Unit of Measure", LotNo);
        if WhseItemTrackingLine.FindLast() then;
        VSTF330787CreateWhseItemTrkgLine(WhseItemTrackingLine."Entry No." + 1, WarehouseShipmentLine."Location Code",
          DATABASE::"Warehouse Shipment Line", 0, WarehouseShipmentLine."No.", WarehouseShipmentLine."Line No.",
          0.16667, ItemLedgerEntry.Quantity, ItemUnitOfMeasure."Qty. per Unit of Measure", LotNo);

        ItemLedgerEntry.FindLast();
        VSTF330787CreateReservation(ReservationEntry."Entry No." + 2, false,
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
          -0.16667, -ItemLedgerEntry.Quantity, ItemUnitOfMeasure."Qty. per Unit of Measure", LotNo);
        VSTF330787CreateReservation(ReservationEntry."Entry No." + 2, true,
          DATABASE::"Item Ledger Entry", 0, '', ItemLedgerEntry."Entry No.",
          ItemLedgerEntry.Quantity * ItemLedgerEntry."Qty. per Unit of Measure", ItemLedgerEntry.Quantity,
          ItemLedgerEntry."Qty. per Unit of Measure", LotNo);
        VSTF330787CreateWhseItemTrkgLine(WhseItemTrackingLine."Entry No." + 2, WarehouseShipmentLine."Location Code",
          DATABASE::"Warehouse Shipment Line", 0, WarehouseShipmentLine."No.", WarehouseShipmentLine."Line No.",
          0.16667, ItemLedgerEntry.Quantity, ItemUnitOfMeasure."Qty. per Unit of Measure", LotNo);

        ItemLedgerEntry.SetRange("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ItemLedgerEntry.FindLast();
        QtyFromCasILE := 104.4;
        VSTF330787CreateReservation(ReservationEntry."Entry No." + 3, false,
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
          -9.66666, -QtyFromCasILE, ItemUnitOfMeasure."Qty. per Unit of Measure", LotNo);
        VSTF330787CreateReservation(ReservationEntry."Entry No." + 3, true,
          DATABASE::"Item Ledger Entry", 0, '', ItemLedgerEntry."Entry No.",
          9.66666, QtyFromCasILE, ItemUnitOfMeasure."Qty. per Unit of Measure", LotNo);
        VSTF330787CreateWhseItemTrkgLine(WhseItemTrackingLine."Entry No." + 3, WarehouseShipmentLine."Location Code",
          DATABASE::"Warehouse Shipment Line", 0, WarehouseShipmentLine."No.", WarehouseShipmentLine."Line No.",
          9.66666, QtyFromCasILE, ItemUnitOfMeasure."Qty. per Unit of Measure", LotNo);
    end;

    local procedure VSTF330787CreateWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SalesLine: Record "Sales Line")
    begin
        // SETUP : Create whse shipment from demand
        WarehouseShipmentHeader.Init();
        WarehouseShipmentHeader."No." := LibraryUtility.GenerateGUID();
        WarehouseShipmentHeader.Insert();
        WarehouseShipmentLine.Init();
        WarehouseShipmentLine."No." := WarehouseShipmentHeader."No.";
        WarehouseShipmentLine."Item No." := SalesLine."No.";
        WarehouseShipmentLine.Quantity := SalesLine.Quantity;
        WarehouseShipmentLine."Qty. Outstanding" := WarehouseShipmentLine.Quantity;
        WarehouseShipmentLine."Qty. (Base)" := SalesLine."Quantity (Base)";
        WarehouseShipmentLine."Qty. Outstanding (Base)" := WarehouseShipmentLine."Qty. (Base)";
        WarehouseShipmentLine."Unit of Measure Code" := SalesLine."Unit of Measure Code";
        WarehouseShipmentLine."Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
        WarehouseShipmentLine."Location Code" := SalesLine."Location Code";
        WarehouseShipmentLine."Bin Code" := VSTF330787CreateBin(WarehouseShipmentLine."Location Code");
        WarehouseShipmentLine."Source Type" := DATABASE::"Sales Line";
        WarehouseShipmentLine."Source Subtype" := SalesLine."Document Type".AsInteger();
        WarehouseShipmentLine."Source No." := SalesLine."Document No.";
        WarehouseShipmentLine."Source Line No." := SalesLine."Line No.";
        WarehouseShipmentLine."Shipment Date" := SalesLine."Shipment Date";
        WarehouseShipmentLine.Insert();
    end;

    local procedure VSTF330787CreateReservation(EntryNo: Integer; Positive: Boolean; SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; Quantity: Decimal; QuantityBase: Decimal; QtyPerUOM: Decimal; LotNo: Code[10])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry."Entry No." := EntryNo;
        ReservationEntry.Positive := Positive;
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Reservation;
        ReservationEntry."Source Type" := SourceType;
        ReservationEntry."Source Subtype" := SourceSubType;
        ReservationEntry."Source ID" := SourceID;
        ReservationEntry."Source Ref. No." := SourceRefNo;
        ReservationEntry.Quantity := Quantity;
        ReservationEntry."Quantity (Base)" := QuantityBase;
        ReservationEntry."Qty. per Unit of Measure" := QtyPerUOM;
        ReservationEntry."Lot No." := LotNo;
        ReservationEntry.Insert();
    end;

    local procedure VSTF330787CreateWhseItemTrkgLine(EntryNo: Integer; LocationCode: Code[10]; SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; Quantity: Decimal; QuantityBase: Decimal; QtyPerUOM: Decimal; LotNo: Code[10])
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.Init();
        WhseItemTrackingLine."Entry No." := EntryNo;
        WhseItemTrackingLine."Location Code" := LocationCode;
        WhseItemTrackingLine."Source Type" := SourceType;
        WhseItemTrackingLine."Source Subtype" := SourceSubType;
        WhseItemTrackingLine."Source ID" := SourceID;
        WhseItemTrackingLine."Source Ref. No." := SourceRefNo;
        WhseItemTrackingLine."Quantity (Base)" := QuantityBase;
        WhseItemTrackingLine."Qty. to Handle" := Quantity;
        WhseItemTrackingLine."Qty. to Handle (Base)" := WhseItemTrackingLine."Quantity (Base)";
        WhseItemTrackingLine."Qty. per Unit of Measure" := QtyPerUOM;
        WhseItemTrackingLine."Lot No." := LotNo;
        WhseItemTrackingLine.Insert();
    end;

    local procedure VSTF334573CreateReleaseTransOrder(var TransHeader: Record "Transfer Header"; LocationCode: Code[10]; ItemUOM: Record "Item Unit of Measure"; LotNo: array[3] of Code[20])
    var
        TransLine: Record "Transfer Line";
    begin
        CreateTransHeader(TransHeader, LocationCode, CreateSimpleLocation(), CreateInTransitLocation());
        CreateTransLine(TransLine, TransHeader, ItemUOM, 50);
        CreateReservEntryForTransfer(TransLine, ItemUOM, LotNo[1], 42, 126);
        CreateReservEntryForTransfer(TransLine, ItemUOM, LotNo[2], 24, 102);
        CreateReservEntryForTransfer(TransLine, ItemUOM, LotNo[3], 20, 106);
        LibraryWarehouse.ReleaseTransferOrder(TransHeader);
    end;

    local procedure VSTF334573CreateRegisterPickWithQtyToHandle(var WhseActivityHdr: Record "Warehouse Activity Header"; WhseShptHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10]; LotNo: array[3] of Code[20]; BinCode: array[2] of Code[20])
    begin
        LibraryWarehouse.CreateWhsePick(WhseShptHeader);
        GetLastActvHdrCreatedNoSrc(WhseActivityHdr, LocationCode, WhseActivityHdr.Type::Pick);

        SetQtyToHandleOnActivityLines(WhseActivityHdr, LotNo[1], BinCode[1], 5);
        SetQtyToHandleOnActivityLines(WhseActivityHdr, LotNo[1], BinCode[2], 5);
        SetQtyToHandleOnActivityLines(WhseActivityHdr, LotNo[2], BinCode[1], 4);
        SetQtyToHandleOnActivityLines(WhseActivityHdr, LotNo[2], BinCode[2], 3);
        SetQtyToHandleOnActivityLines(WhseActivityHdr, LotNo[3], BinCode[1], 1);
        SetQtyToHandleOnActivityLines(WhseActivityHdr, LotNo[3], BinCode[2], 3);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHdr);
    end;

    local procedure CreateTransHeader(var TransHeader: Record "Transfer Header"; TransFromCode: Code[10]; TransToCode: Code[10]; InTransitCode: Code[10])
    begin
        TransHeader.Init();
        TransHeader."Transfer-from Code" := TransFromCode;
        TransHeader."Transfer-to Code" := TransToCode;
        TransHeader."In-Transit Code" := InTransitCode;
        TransHeader.Insert(true);
    end;

    local procedure CreateTransLine(var TransLine: Record "Transfer Line"; TransHeader: Record "Transfer Header"; ItemUnitOfMeasure: Record "Item Unit of Measure"; Qty: Decimal)
    var
        RecRef: RecordRef;
    begin
        TransLine."Document No." := TransHeader."No.";
        RecRef.GetTable(TransLine);
        TransLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, TransLine.FieldNo("Line No."));
        TransLine.Validate("Item No.", ItemUnitOfMeasure."Item No.");
        TransLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ItemUnitOfMeasure.Get(TransLine."Item No.", TransLine."Unit of Measure Code");
        TransLine."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
        TransLine.Quantity := Qty;
        TransLine."Quantity (Base)" := Qty * TransLine."Qty. per Unit of Measure";
        TransLine."Outstanding Quantity" := TransLine.Quantity;
        TransLine."Outstanding Qty. (Base)" := TransLine."Quantity (Base)";
        TransLine."Receipt Date" := WorkDate();
        TransLine."Transfer-from Code" := TransHeader."Transfer-from Code";
        TransLine."Transfer-to Code" := TransHeader."Transfer-to Code";
        TransLine."Shipment Date" := WorkDate();
        TransLine."Receipt Date" := WorkDate();
        TransLine.Insert();
    end;

    local procedure CreateReservEntryForTransfer(TransLine: Record "Transfer Line"; ItemUOM: Record "Item Unit of Measure"; LotNo: Code[50]; Qty: Decimal; Qty2: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.FindLast();
        ReservEntry.Init();
        ReservEntry."Item No." := ItemUOM."Item No.";
        ReservEntry."Qty. per Unit of Measure" := ItemUOM."Qty. per Unit of Measure";
        ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
        ReservEntry."Source Type" := DATABASE::"Transfer Line";
        ReservEntry."Source ID" := TransLine."Document No.";
        ReservEntry."Source Ref. No." := TransLine."Line No.";
        ReservEntry."Lot No." := LotNo;
        ReservEntry."Item Tracking" := ReservEntry."Item Tracking"::"Lot No.";

        ReservEntry."Location Code" := TransLine."Transfer-from Code";
        ReservEntry.Positive := false;
        ReservEntry."Source Subtype" := 0;
        InsertReservEntry(ReservEntry, -Qty, ItemUOM."Qty. per Unit of Measure");
        InsertReservEntry(ReservEntry, -Qty2, ItemUOM."Qty. per Unit of Measure");

        ReservEntry."Location Code" := TransLine."Transfer-to Code";
        ReservEntry.Positive := true;
        ReservEntry."Source Subtype" := 1;
        InsertReservEntry(ReservEntry, Qty, ItemUOM."Qty. per Unit of Measure");
        InsertReservEntry(ReservEntry, Qty2, ItemUOM."Qty. per Unit of Measure");
    end;

    local procedure MockItem(var Item: Record Item)
    begin
        Item.Init();
        Item."No." := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), DATABASE::Item);
        Item.Insert();
    end;

    local procedure MockItemNo(): Code[20]
    var
        Item: Record Item;
    begin
        MockItem(Item);
        exit(Item."No.");
    end;

    local procedure MockItemWithBaseUOM(var Item: Record Item)
    begin
        MockItem(Item);
        Item."Base Unit of Measure" := MockItemUOMCode(Item."No.", 1);
        Item.Modify();
    end;

    local procedure MockItemNoWithBaseUOM(): Code[20]
    var
        Item: Record Item;
    begin
        MockItemWithBaseUOM(Item);
        exit(Item."No.");
    end;

    local procedure MockItemUOM(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; QtyPerUOM: Decimal)
    begin
        ItemUnitOfMeasure."Item No." := ItemNo;
        ItemUnitOfMeasure.Code := LibraryUtility.GenerateRandomCode(ItemUnitOfMeasure.FieldNo(Code), DATABASE::"Item Unit of Measure");
        ItemUnitOfMeasure."Qty. per Unit of Measure" := QtyPerUOM;
        ItemUnitOfMeasure.Insert();
    end;

    local procedure MockItemUOMCode(ItemNo: Code[20]; QtyPerUOM: Decimal): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        MockItemUOM(ItemUnitOfMeasure, ItemNo, QtyPerUOM);
        exit(ItemUnitOfMeasure.Code);
    end;

    local procedure MockTransferLine(ItemNo: Code[20]; OutstandingQty: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Init();
        TransferLine."Document No." := LibraryUtility.GenerateRandomCode(TransferLine.FieldNo("Document No."), DATABASE::"Transfer Line");
        TransferLine."Line No." := 10000;
        TransferLine."Item No." := ItemNo;
        TransferLine."Outstanding Qty. (Base)" := OutstandingQty;
        TransferLine.Insert();
    end;

    local procedure MockServiceHeader(): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Init();
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;
        ServiceHeader."No." := LibraryUtility.GenerateRandomCode(ServiceHeader.FieldNo("No."), DATABASE::"Service Header");
        ServiceHeader.Insert(true);
        exit(ServiceHeader."No.");
    end;

    local procedure MockServiceLine(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.Init();
        ServiceLine."Document Type" := ServiceLine."Document Type"::Order;
        ServiceLine."Document No." := MockServiceHeader();
        ServiceLine."Line No." := 10000;
        ServiceLine.Type := ServiceLine.Type::Item;
        ServiceLine."No." := MockItemNoWithBaseUOM();
        ServiceLine.Validate(Quantity, LibraryRandom.RandIntInRange(100, 200));
        ServiceLine.Insert(true);
    end;

    local procedure MockWhseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10])
    begin
        WarehouseActivityHeader.Init();
        WarehouseActivityHeader.Type := ActivityType;
        WarehouseActivityHeader."No." := LibraryUtility.GenerateGUID();
        WarehouseActivityHeader."Location Code" := LocationCode;
        WarehouseActivityHeader.Insert();
    end;

    local procedure MockWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; LineNo: Integer; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.Init();
        WarehouseActivityLine."Activity Type" := WarehouseActivityHeader.Type;
        WarehouseActivityLine."No." := WarehouseActivityHeader."No.";
        WarehouseActivityLine."Line No." := LineNo;
        WarehouseActivityLine."Action Type" := ActionType;
        WarehouseActivityLine."Item No." := LibraryUtility.GenerateGUID();
        WarehouseActivityLine.Quantity := LibraryRandom.RandIntInRange(10, 20);
        WarehouseActivityLine."Qty. Outstanding" := WarehouseActivityLine.Quantity;
        WarehouseActivityLine."Qty. to Handle" := LibraryRandom.RandInt(5);
        WarehouseActivityLine.Insert();
    end;

    local procedure MockWhseActivityLineWithBinAndShelf(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; BinCode: Code[20]; ShelfNo: Code[10])
    begin
        WarehouseActivityLine.Init();
        WarehouseActivityLine."Activity Type" := WarehouseActivityHeader.Type;
        WarehouseActivityLine."No." := WarehouseActivityHeader."No.";
        WarehouseActivityLine."Line No." := LibraryUtility.GetNewRecNo(WarehouseActivityLine, WarehouseActivityLine.FieldNo("Line No."));
        WarehouseActivityLine."Action Type" := ActionType;
        WarehouseActivityLine."Location Code" := WarehouseActivityHeader."Location Code";
        WarehouseActivityLine."Item No." := ItemNo;
        WarehouseActivityLine."Bin Code" := BinCode;
        WarehouseActivityLine."Shelf No." := ShelfNo;
        WarehouseActivityLine.Insert();
    end;

    local procedure MockPickWorksheetLineWithBinAndShelf(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20]; ShelfNo: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);

        WhseWorksheetLine.Init();
        WhseWorksheetLine."Worksheet Template Name" := WhseWorksheetTemplate.Name;
        WhseWorksheetLine.Name := WhseWorksheetName.Name;
        WhseWorksheetLine."Location Code" := LocationCode;
        WhseWorksheetLine."Line No." := LibraryUtility.GetNewRecNo(WhseWorksheetLine, WhseWorksheetLine.FieldNo("Line No."));
        WhseWorksheetLine."Item No." := ItemNo;
        WhseWorksheetLine."To Bin Code" := BinCode;
        WhseWorksheetLine."Shelf No." := ShelfNo;
        WhseWorksheetLine.Insert();
    end;

    local procedure InsertReservEntry(var ReservEntry: Record "Reservation Entry"; QtyBase: Decimal; QtyPerUOM: Decimal)
    begin
        ReservEntry."Entry No." += 1;
        ReservEntry."Quantity (Base)" := QtyBase;
        ReservEntry.Quantity := Round(ReservEntry."Quantity (Base)" / QtyPerUOM, 0.00001);
        ReservEntry."Qty. to Handle (Base)" := ReservEntry."Quantity (Base)";
        ReservEntry."Qty. to Invoice (Base)" := ReservEntry."Quantity (Base)";
        ReservEntry.Insert();
    end;

    local procedure GetWhseShptFromTransfer(var WhseShptHeader: Record "Warehouse Shipment Header"; TransNo: Code[20])
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.SetRange("Source Document", WhseShptLine."Source Document"::"Outbound Transfer");
        WhseShptLine.SetRange("Source No.", TransNo);
        WhseShptLine.FindFirst();
        WhseShptHeader.Get(WhseShptLine."No.");
    end;

    local procedure GetLastActvHdrCreatedNoSrc(var WhseActivityHdr: Record "Warehouse Activity Header"; LocationCode: Code[10]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WhseActivityHdr.SetRange("Location Code", LocationCode);
        WhseActivityHdr.SetRange(Type, ActivityType);
        WhseActivityHdr.FindLast();
    end;

    local procedure GetWhseRegisteredPickAmount(ItemNo: Code[20]): Decimal
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetCurrentKey(
          "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.",
          "Whse. Document No.", "Serial No.", "Lot No.", "Action Type");
        RegisteredWhseActivityLine.SetRange("Activity Type", RegisteredWhseActivityLine."Activity Type"::Pick);
        RegisteredWhseActivityLine.SetRange("Action Type", RegisteredWhseActivityLine."Action Type"::Place);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.CalcSums("Qty. (Base)");

        exit(RegisteredWhseActivityLine."Qty. (Base)");
    end;

    local procedure GetItemTrackingAmount(ItemNo: Code[20]) "Sum": Decimal
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Subtype", ReservationEntry."Source Subtype"::"0");
        ReservationEntry.SetRange("Item No.", ItemNo);
        if ReservationEntry.FindSet() then
            repeat
                Sum += ReservationEntry."Qty. to Handle (Base)";
            until ReservationEntry.Next() = 0;
    end;

    local procedure SetQtyToHandleOnActivityLines(WhseActivityHdr: Record "Warehouse Activity Header"; LotNo: Code[50]; BinCode: Code[20]; QtyToHandle: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        QtyTaken: Decimal;
    begin
        WhseActivityLine.SetRange("Activity Type", WhseActivityHdr.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHdr."No.");
        WhseActivityLine.SetRange("Lot No.", LotNo);
        WhseActivityLine.SetRange("Bin Code", BinCode);
        WhseActivityLine.FindSet(true);
        QtyTaken := WhseActivityLine."Qty. to Handle";
        WhseActivityLine.Validate("Qty. to Handle", QtyToHandle);

        WhseActivityLine.Modify(true);

        WhseActivityLine.SetRange("Bin Code");
        // action type "Place" has another bin code
        WhseActivityLine.Next();
        WhseActivityLine.TestField("Action Type", WhseActivityLine."Action Type"::Place);
        WhseActivityLine.TestField("Qty. to Handle", QtyTaken);
        WhseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WhseActivityLine.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPickWithBlankBinCodeHasTwoLinesFromEachBin()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        DefaultBinCode: Code[10];
        NonDefaultBinCode: Code[10];
        QtyOnDefaultBin: Decimal;
        QtyOnNonDefaultBin: Decimal;
    begin
        VSTF335757Preconditions(0, ProdOrderComponent, WarehouseRequest, DefaultBinCode, NonDefaultBinCode,
          QtyOnDefaultBin, QtyOnNonDefaultBin); // 0 : Blank source doc bin

        // EXERCISE : Create inventory pick
        VSTF335757CallCreateInvtDoc(WarehouseActivityHeader.Type::"Invt. Pick", ProdOrderComponent, WarehouseRequest);

        // VERIFY : 2 lines one for each bin code
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        VSTF335757SetFilterOnWhseActivityLines(ProdOrderComponent, WarehouseActivityLine);
        WarehouseActivityLine.SetRange("Bin Code", DefaultBinCode);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(QtyOnDefaultBin, WarehouseActivityLine.Quantity, 'Qty from Default bin is 1st priority.');
        WarehouseActivityLine.SetRange("Bin Code", NonDefaultBinCode);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(ProdOrderComponent."Expected Quantity" - QtyOnDefaultBin,
          WarehouseActivityLine.Quantity, 'Qty from NonDefault bin is 2nd priority.')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPickWithDefaultBinCodeHasTwoLinesFromEachBin()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        DefaultBinCode: Code[10];
        NonDefaultBinCode: Code[10];
        QtyOnDefaultBin: Decimal;
        QtyOnNonDefaultBin: Decimal;
    begin
        VSTF335757Preconditions(1, ProdOrderComponent, WarehouseRequest, DefaultBinCode, NonDefaultBinCode,
          QtyOnDefaultBin, QtyOnNonDefaultBin); // 1 : Default source doc bin

        // EXERCISE : Create inventory pick
        VSTF335757CallCreateInvtDoc(WarehouseActivityHeader.Type::"Invt. Pick", ProdOrderComponent, WarehouseRequest);

        // VERIFY : 2 lines one for each bin code
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        VSTF335757SetFilterOnWhseActivityLines(ProdOrderComponent, WarehouseActivityLine);
        Assert.AreEqual(2, WarehouseActivityLine.Count, '2 lines- one from default and one from non default.');
        WarehouseActivityLine.SetRange("Bin Code", DefaultBinCode);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(QtyOnDefaultBin, WarehouseActivityLine.Quantity, 'Qty from Default bin is 1st priority.');
        WarehouseActivityLine.SetRange("Bin Code", NonDefaultBinCode);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(ProdOrderComponent."Expected Quantity" - QtyOnDefaultBin,
          WarehouseActivityLine.Quantity, 'Qty from NonDefault bin is 2nd priority.')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPickWithNonDefaultBinCodeHasTwoLinesFromEachBin()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        DefaultBinCode: Code[10];
        NonDefaultBinCode: Code[10];
        QtyOnDefaultBin: Decimal;
        QtyOnNonDefaultBin: Decimal;
    begin
        VSTF335757Preconditions(2, ProdOrderComponent, WarehouseRequest, DefaultBinCode, NonDefaultBinCode,
          QtyOnDefaultBin, QtyOnNonDefaultBin); // 2 : Non default source doc bin

        // EXERCISE : Create inventory pick
        VSTF335757CallCreateInvtDoc(WarehouseActivityHeader.Type::"Invt. Pick", ProdOrderComponent, WarehouseRequest);

        // VERIFY : 2 lines one for each bin code
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        VSTF335757SetFilterOnWhseActivityLines(ProdOrderComponent, WarehouseActivityLine);
        Assert.AreEqual(2, WarehouseActivityLine.Count, '2 lines- one from default and one from non default.');
        WarehouseActivityLine.SetRange("Bin Code", NonDefaultBinCode);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(QtyOnNonDefaultBin, WarehouseActivityLine.Quantity,
          'Qty from Non Default bin is 1st priority as it is the source line.');
        WarehouseActivityLine.SetRange("Bin Code", DefaultBinCode);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(ProdOrderComponent."Expected Quantity" - QtyOnNonDefaultBin,
          WarehouseActivityLine.Quantity, 'Qty from Default bin is 2nd priority.')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryMovementWithBlankBinCodeCreatesNoDoc()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        DefaultBinCode: Code[10];
        NonDefaultBinCode: Code[10];
        QtyOnDefaultBin: Decimal;
        QtyOnNonDefaultBin: Decimal;
    begin
        VSTF335757Preconditions(0, ProdOrderComponent, WarehouseRequest, DefaultBinCode, NonDefaultBinCode,
          QtyOnDefaultBin, QtyOnNonDefaultBin); // 0 : Blank source doc bin

        // EXERCISE : Create inventory pick
        VSTF335757CallCreateInvtDoc(WarehouseActivityHeader.Type::"Invt. Movement", ProdOrderComponent, WarehouseRequest);

        // VERIFY : 0 lines one for each bin code
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        VSTF335757SetFilterOnWhseActivityLines(ProdOrderComponent, WarehouseActivityLine);
        Assert.IsTrue(WarehouseActivityLine.IsEmpty, 'Place line bin code is blank- no doc is created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryMovementWithDefaultBinCodeHasOneLineFromNonDefaultBin()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        DefaultBinCode: Code[10];
        NonDefaultBinCode: Code[10];
        QtyOnDefaultBin: Decimal;
        QtyOnNonDefaultBin: Decimal;
    begin
        VSTF335757Preconditions(1, ProdOrderComponent, WarehouseRequest, DefaultBinCode, NonDefaultBinCode,
          QtyOnDefaultBin, QtyOnNonDefaultBin); // 1 : Default source doc bin

        // EXERCISE : Create inventory pick
        VSTF335757CallCreateInvtDoc(WarehouseActivityHeader.Type::"Invt. Movement", ProdOrderComponent, WarehouseRequest);

        // VERIFY : 1 pair of lines- take from non default and place to default
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        VSTF335757SetFilterOnWhseActivityLines(ProdOrderComponent, WarehouseActivityLine);
        Assert.AreEqual(2, WarehouseActivityLine.Count, '1 pair of lines- take from non default and place to default');
        WarehouseActivityLine.SetRange("Bin Code", NonDefaultBinCode);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(QtyOnNonDefaultBin, WarehouseActivityLine.Quantity, 'Full qty from non default bin');
        WarehouseActivityLine.SetRange("Bin Code", DefaultBinCode);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(QtyOnNonDefaultBin, WarehouseActivityLine.Quantity, 'Same qty as Take on Place line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryMovementWithNonDefaultBinCodeHasOneLineFromDefaultBin()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        DefaultBinCode: Code[10];
        NonDefaultBinCode: Code[10];
        QtyOnDefaultBin: Decimal;
        QtyOnNonDefaultBin: Decimal;
    begin
        VSTF335757Preconditions(2, ProdOrderComponent, WarehouseRequest, DefaultBinCode, NonDefaultBinCode,
          QtyOnDefaultBin, QtyOnNonDefaultBin); // 2 : Non default source doc bin

        // EXERCISE : Create inventory pick
        VSTF335757CallCreateInvtDoc(WarehouseActivityHeader.Type::"Invt. Movement", ProdOrderComponent, WarehouseRequest);

        // VERIFY : 1 pair of lines- take from default and place to non default.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        VSTF335757SetFilterOnWhseActivityLines(ProdOrderComponent, WarehouseActivityLine);
        Assert.AreEqual(2, WarehouseActivityLine.Count, '1 pair of lines- take from default and place to non default.');
        WarehouseActivityLine.SetRange("Bin Code", DefaultBinCode);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(QtyOnDefaultBin, WarehouseActivityLine.Quantity, 'Full qty from default bin');
        WarehouseActivityLine.SetRange("Bin Code", NonDefaultBinCode);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(QtyOnDefaultBin, WarehouseActivityLine.Quantity, 'Same qty as Take on Place line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToCreateBinWithoutLocation()
    var
        Bin: Record Bin;
    begin
        // [SCENARIO 207605] Stan cannot create Bin without Location Code

        Bin.Init();
        Bin.Validate(Code, LibraryUtility.GenerateGUID());
        asserterror Bin.Insert(true);

        Assert.ExpectedError(CannotCreateBinWithoutLocationErr);
    end;

    local procedure VSTF335757Preconditions(SourceDocBinCode: Option Blank,Default,NonDefault; var ProdOrderComponent: Record "Prod. Order Component"; var WarehouseRequest: Record "Warehouse Request"; var DefaultBinCode: Code[10]; var NonDefaultBinCode: Code[10]; var QtyOnDefaultBin: Decimal; var QtyOnNonDefaultBin: Decimal)
    var
        ProductionOrder: Record "Production Order";
        ItemNo: Code[20];
        LocationCode: Code[10];
    begin
        // Refer to VSTF 335757
        Initialize();

        // SETUP : Create inventory for new item in 2 bins for Require Pick location.
        ItemNo := MockItemNo();
        LocationCode := MockCustomLocationCode(true, false, true, false);

        QtyOnDefaultBin := 5;
        DefaultBinCode := VSTF335757CreateBinContent(true, ItemNo, LocationCode, QtyOnDefaultBin);
        QtyOnNonDefaultBin := 5;
        NonDefaultBinCode := VSTF335757CreateBinContent(false, ItemNo, LocationCode, QtyOnNonDefaultBin);

        // SETUP : Create prod. order with 7 PCS of component.
        ProductionOrder.Status := ProductionOrder.Status::Released;
        ProductionOrder."No." := LibraryUtility.GenerateGUID();
        ProductionOrder.Insert();
        ProdOrderComponent.Status := ProductionOrder.Status;
        ProdOrderComponent."Prod. Order No." := ProductionOrder."No.";
        ProdOrderComponent."Item No." := ItemNo;
        ProdOrderComponent."Flushing Method" := ProdOrderComponent."Flushing Method"::"Pick + Manual";
        ProdOrderComponent."Location Code" := LocationCode;
        ProdOrderComponent."Quantity per" := 1;
        ProdOrderComponent."Expected Quantity" := 7;
        ProdOrderComponent."Expected Qty. (Base)" := 7;
        ProdOrderComponent."Remaining Quantity" := 7;
        ProdOrderComponent."Remaining Qty. (Base)" := 7;
        ProdOrderComponent."Qty. per Unit of Measure" := 1;
        case SourceDocBinCode of
            SourceDocBinCode::Blank:
                ProdOrderComponent."Bin Code" := '';
            SourceDocBinCode::Default:
                ProdOrderComponent."Bin Code" := DefaultBinCode;
            SourceDocBinCode::NonDefault:
                ProdOrderComponent."Bin Code" := NonDefaultBinCode;
        end;
        ProdOrderComponent.Insert();

        WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Prod. Consumption";
        WarehouseRequest."Source Subtype" := ProdOrderComponent.Status.AsInteger();
        WarehouseRequest."Source No." := ProdOrderComponent."Prod. Order No.";
        WarehouseRequest."Location Code" := ProdOrderComponent."Location Code";
    end;

    local procedure VSTF335757CreateBinContent(Default: Boolean; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal) BinCode: Code[10]
    var
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseEntry2: Record "Warehouse Entry";
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.ClearState();
        MockILENo(ItemNo, LocationCode, Qty);

        BinCode := LibraryUtility.GenerateGUID();

        Bin.Init();
        Bin."Location Code" := LocationCode;
        Bin.Code := BinCode;
        Bin.Default := Default;
        Bin.Insert();

        BinContent.Init();
        BinContent.Default := Default;
        BinContent."Location Code" := LocationCode;
        BinContent."Bin Code" := BinCode;
        BinContent."Item No." := ItemNo;
        BinContent.Insert();

        WarehouseEntry2.FindLast();
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := WarehouseEntry2."Entry No." + 1;
        WarehouseEntry."Location Code" := LocationCode;
        WarehouseEntry."Bin Code" := BinCode;
        WarehouseEntry."Item No." := ItemNo;
        WarehouseEntry.Quantity := Qty;
        WarehouseEntry."Qty. (Base)" := Qty;
        WarehouseEntry.Insert();
    end;

    local procedure VSTF335757CallCreateInvtDoc(ActivityType: Enum "Warehouse Activity Type"; ProdOrderComponent: Record "Prod. Order Component"; WarehouseRequest: Record "Warehouse Request")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        CreateInvtPickMovement: Codeunit "Create Inventory Pick/Movement";
    begin
        CreateInvtPickMovement.SetWhseRequest(WarehouseRequest, true);
        CreateInvtPickMovement.CheckSourceDoc(WarehouseRequest);
        WarehouseActivityHeader.Type := ActivityType;
        WarehouseActivityHeader."No." := LibraryUtility.GenerateGUID();
        WarehouseActivityHeader."Source Type" := DATABASE::"Prod. Order Component";
        WarehouseActivityHeader."Source Subtype" := ProdOrderComponent.Status.AsInteger();
        WarehouseActivityHeader."Source No." := ProdOrderComponent."Prod. Order No.";
        WarehouseActivityHeader."Location Code" := ProdOrderComponent."Location Code";
        if ActivityType = WarehouseActivityHeader.Type::"Invt. Movement" then
            CreateInvtPickMovement.SetInvtMovement(true);
        CreateInvtPickMovement.AutoCreatePickOrMove(WarehouseActivityHeader);
    end;

    local procedure VSTF335757SetFilterOnWhseActivityLines(var ProdOrderComponent: Record "Prod. Order Component"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Prod. Order Component");
        WarehouseActivityLine.SetRange("Source Subtype", ProdOrderComponent.Status);
        WarehouseActivityLine.SetRange("Source No.", ProdOrderComponent."Prod. Order No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RaiseErrorOnIncreasingQtyToShipOnSalesLineIfPickExists()
    begin
        RaiseErrorOnChangingQtyToShipOnSalesLineIfPickExists(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RaiseErrorOnDecreasingQtyToShipOnSalesLineIfPickExists()
    begin
        RaiseErrorOnChangingQtyToShipOnSalesLineIfPickExists(false);
    end;

    local procedure RaiseErrorOnChangingQtyToShipOnSalesLineIfPickExists(Increase: Boolean)
    var
        LocationCode: Code[10];
        ItemNo: Code[20];
        Qty: Decimal;
        QtyToShip: Decimal;
        NewQtyToShip: Decimal;
        SourceSubtype: Integer;
        SourceNo: Code[20];
        SourceLineNo: Integer;
        FieldName: Text;
    begin
        // Refer to SICLIY 6636
        Initialize();

        // SETUP : Create new item, make Invt location, make sales and a warehouse activity line.
        RaiseErrorOnChangingQtyIfPickExistsGetQuantities(Qty, QtyToShip, NewQtyToShip, Increase);
        RaiseErrorOnChangingQtyIfPickExistsMakeItemLocation(ItemNo, LocationCode);
        RaiseErrorOnChangingQtyToShipOnSalesLineIfPickExistsMakeSalesLine(ItemNo, LocationCode,
          Qty, QtyToShip, SourceSubtype, SourceNo, SourceLineNo);
        RaiseErrorOnChangingQtyIfPickExistsMakeWhseActivity(ItemNo, LocationCode, Qty, DATABASE::"Sales Line",
          SourceSubtype, SourceNo, SourceLineNo);

        // EXERCISE : Change Qty
        asserterror RaiseErrorOnChangingQtyToShipOnSalesLineIfPickExistsChangeSalesLine(FieldName, NewQtyToShip,
            SourceSubtype, SourceNo, SourceLineNo);
        // VERIFY : Error message
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(QtyMustNotBeChangedErr, FieldName)) > 0,
          'No change allowed as whse activity line exists.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RaiseErrorOnIncreasingQtyToShipOnTransferLineIfPickExists()
    begin
        RaiseErrorOnChangingQtyToShipOnTransferLineIfPickExists(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RaiseErrorOnDecreasingQtyToShipOnTransferLineIfPickExists()
    begin
        RaiseErrorOnChangingQtyToShipOnTransferLineIfPickExists(false);
    end;

    local procedure RaiseErrorOnChangingQtyToShipOnTransferLineIfPickExists(Increase: Boolean)
    var
        LocationCode: Code[10];
        ItemNo: Code[20];
        Qty: Decimal;
        QtyToShip: Decimal;
        NewQtyToShip: Decimal;
        SourceNo: Code[20];
        SourceLineNo: Integer;
        FieldName: Text;
    begin
        // Refer to SICLIY 6636
        Initialize();

        // SETUP : Create new item, make Invt location, make sales and a warehouse activity line.
        RaiseErrorOnChangingQtyIfPickExistsGetQuantities(Qty, QtyToShip, NewQtyToShip, Increase);
        RaiseErrorOnChangingQtyIfPickExistsMakeItemLocation(ItemNo, LocationCode);
        RaiseErrorOnChangingQtyToShipOnTransferLineIfPickExistsMakeTransferLine(ItemNo, LocationCode,
          Qty, QtyToShip, SourceNo, SourceLineNo);
        RaiseErrorOnChangingQtyIfPickExistsMakeWhseActivity(ItemNo, LocationCode, Qty, DATABASE::"Transfer Line",
          0, SourceNo, SourceLineNo);

        // EXERCISE : Change Qty
        asserterror RaiseErrorOnChangingQtyToShipOnTransferLineIfPickExistsChangeTransferLine(FieldName, NewQtyToShip,
            SourceNo, SourceLineNo);
        // VERIFY : Error message
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(QtyMustNotBeChangedErr, FieldName)) > 0,
          'No change allowed as whse activity line exists.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RaiseErrorOnIncreasingQtyToReceiveOnTransferLineIfPutAwayExists()
    begin
        RaiseErrorOnChangingQtyToReceiveOnTransferLineIfPutAwayExists(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RaiseErrorOnDecreasingQtyToReceiveOnTransferLineIfPutAwayExists()
    begin
        RaiseErrorOnChangingQtyToReceiveOnTransferLineIfPutAwayExists(false);
    end;

    local procedure RaiseErrorOnChangingQtyToReceiveOnTransferLineIfPutAwayExists(Increase: Boolean)
    var
        LocationCode: Code[10];
        ItemNo: Code[20];
        Qty: Decimal;
        QtyToReceive: Decimal;
        NewQtyToReceive: Decimal;
        SourceNo: Code[20];
        SourceLineNo: Integer;
        FieldName: Text;
    begin
        // Refer to SICLIY 6636
        Initialize();

        // SETUP : Create new item, make Invt location, make sales and a warehouse activity line.
        RaiseErrorOnChangingQtyIfPickExistsGetQuantities(Qty, QtyToReceive, NewQtyToReceive, Increase);
        RaiseErrorOnChangingQtyIfPickExistsMakeItemLocation(ItemNo, LocationCode);
        RaiseErrorOnChangingQtyToReceiveOnTransferLineIfPickExistsMakeTransferLine(ItemNo, LocationCode,
          Qty, QtyToReceive, SourceNo, SourceLineNo);
        RaiseErrorOnChangingQtyIfPickExistsMakeWhseActivity(
          ItemNo, LocationCode, Qty, DATABASE::"Transfer Line", 1, SourceNo, SourceLineNo);

        // EXERCISE : Change Qty
        asserterror RaiseErrorOnChangingQtyToReceiveOnTransferLineIfPutAwayExistsChangeTransferLine(
            FieldName, NewQtyToReceive, SourceNo, SourceLineNo);
        // VERIFY : Error message
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(QtyMustNotBeChangedErr, FieldName)) > 0,
          'No change allowed as whse activity line exists.');
    end;

    local procedure RaiseErrorOnChangingQtyIfPickExistsGetQuantities(var Qty: Decimal; var QtyToShip: Decimal; var NewQtyToShip: Decimal; Increase: Boolean)
    begin
        Qty := 5;
        QtyToShip := Qty - 1;
        if Increase then
            NewQtyToShip := Qty
        else
            NewQtyToShip := QtyToShip - 1;
    end;

    local procedure RaiseErrorOnChangingQtyIfPickExistsMakeItemLocation(var ItemNo: Code[20]; var LocationCode: Code[10])
    begin
        ItemNo := MockItemNo();
        LocationCode := MockCustomLocationCode(true, false, true, false);
    end;

    local procedure RaiseErrorOnChangingQtyToShipOnSalesLineIfPickExistsMakeSalesLine(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; QtyToShip: Decimal; var SourceSubtype: Integer; var SourceNo: Code[20]; var SourceLineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        SalesHeader.Insert();

        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine."Location Code" := LocationCode;
        SalesLine.Quantity := Qty;
        SalesLine."Qty. to Ship" := QtyToShip;
        SalesLine.Insert();

        SourceSubtype := SalesLine."Document Type".AsInteger();
        SourceNo := SalesLine."Document No.";
        SourceLineNo := SalesLine."Line No.";
    end;

    local procedure RaiseErrorOnChangingQtyToShipOnTransferLineIfPickExistsMakeTransferLine(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; QtyToShip: Decimal; var SourceNo: Code[20]; var SourceLineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Init();
        TransferLine."Document No." := LibraryUtility.GenerateGUID();
        TransferLine."Item No." := ItemNo;
        TransferLine."Transfer-from Code" := LocationCode;
        TransferLine.Quantity := Qty;
        TransferLine."Qty. to Ship" := QtyToShip;
        TransferLine.Insert();

        SourceNo := TransferLine."Document No.";
        SourceLineNo := TransferLine."Line No.";
    end;

    local procedure RaiseErrorOnChangingQtyToReceiveOnTransferLineIfPickExistsMakeTransferLine(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; QtyToReceive: Decimal; var SourceNo: Code[20]; var SourceLineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Init();
        TransferLine."Document No." := LibraryUtility.GenerateGUID();
        TransferLine."Item No." := ItemNo;
        TransferLine."Transfer-to Code" := LocationCode;
        TransferLine.Quantity := Qty;
        TransferLine."Qty. in Transit" := Qty;
        TransferLine."Qty. to Receive" := QtyToReceive;
        TransferLine.Insert();

        SourceNo := TransferLine."Document No.";
        SourceLineNo := TransferLine."Line No.";
    end;

    local procedure RaiseErrorOnChangingQtyIfPickExistsMakeWhseActivity(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.Init();
        WhseActivityLine."No." := LibraryUtility.GenerateGUID();
        WhseActivityLine."Source Type" := SourceType;
        WhseActivityLine."Source Subtype" := SourceSubtype;
        WhseActivityLine."Source No." := SourceNo;
        WhseActivityLine."Source Line No." := SourceLineNo;
        WhseActivityLine."Item No." := ItemNo;
        WhseActivityLine.Quantity := Qty;
        WhseActivityLine."Location Code" := LocationCode;
        WhseActivityLine.Insert();
    end;

    local procedure RaiseErrorOnChangingQtyToShipOnSalesLineIfPickExistsChangeSalesLine(var FieldName: Text; NewQtyToShip: Decimal; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        SalesOrderSubform: TestPage "Sales Order Subform";
    begin
        SalesOrderSubform.Trap();
        SalesLine.Get(SourceSubtype, SourceNo, SourceLineNo);
        PAGE.Run(PAGE::"Sales Order Subform", SalesLine);
        SalesOrderSubform."Qty. to Ship".SetValue(NewQtyToShip);
        FieldName := SalesLine.FieldCaption("Qty. to Ship");
    end;

    local procedure RaiseErrorOnChangingQtyToShipOnTransferLineIfPickExistsChangeTransferLine(var FieldName: Text; NewQtyToShip: Decimal; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
        TransferOrderSubform: TestPage "Transfer Order Subform";
    begin
        TransferOrderSubform.Trap();
        TransferLine.Get(SourceNo, SourceLineNo);
        PAGE.Run(PAGE::"Transfer Order Subform", TransferLine);
        TransferOrderSubform."Qty. to Ship".SetValue(NewQtyToShip);
        FieldName := TransferLine.FieldCaption("Qty. to Ship");
    end;

    local procedure RaiseErrorOnChangingQtyToReceiveOnTransferLineIfPutAwayExistsChangeTransferLine(var FieldName: Text; NewQtyToReceive: Decimal; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
        TransferOrderSubform: TestPage "Transfer Order Subform";
    begin
        TransferOrderSubform.Trap();
        TransferLine.Get(SourceNo, SourceLineNo);
        PAGE.Run(PAGE::"Transfer Order Subform", TransferLine);
        TransferOrderSubform."Qty. to Receive".SetValue(NewQtyToReceive);
        FieldName := TransferLine.FieldCaption("Qty. to Receive");
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ChangingUOMOnSalesRaisesAvailabilityWarning()
    var
        Item: Record Item;
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        BigItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrderSubform: TestPage "Sales Order Subform";
    begin
        // Refer to VSTF SE 207913 - second scenario
        Initialize();
        LibrarySales.SetDiscountPostingSilent(0);
        // SETUP : Create item, with two UOMs, add inventory less than the higher UOM, and make sales for 1 base unit of measure
        MockItem(Item);
        MockItemUOM(BaseItemUnitOfMeasure, Item."No.", 1);
        MockItemUOM(BigItemUnitOfMeasure, Item."No.", 144);
        Item."Stockout Warning" := Item."Stockout Warning"::Yes;
        Item.Modify();

        MockILE(ItemLedgerEntry, Item."No.", '', 144 - 20); // less than 1 BigUnitOfMeasure
        ItemLedgerEntry."Qty. per Unit of Measure" := BaseItemUnitOfMeasure."Qty. per Unit of Measure";
        ItemLedgerEntry."Unit of Measure Code" := BaseItemUnitOfMeasure.Code;
        ItemLedgerEntry.Modify();
        LibrarySales.CreateCustomer(Customer);

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesLine."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Quantity := 1;
        SalesLine."Quantity (Base)" := 1;
        SalesLine."Outstanding Quantity" := 1;
        SalesLine."Qty. per Unit of Measure" := BaseItemUnitOfMeasure."Qty. per Unit of Measure";
        SalesLine."Unit of Measure Code" := BaseItemUnitOfMeasure.Code;
        SalesLine.Insert();

        // EXERCISE : change UOM Code in sales to big uom so that sale qty > inventory.
        SalesOrderSubform.Trap();
        PAGE.Run(PAGE::"Sales Order Subform", SalesLine);
        SalesOrderSubform."Unit of Measure Code".SetValue(BigItemUnitOfMeasure.Code);
        // VERIFY : An availabity notification is sent
        Assert.ExpectedMessage(StrSubstNo(NotificationMsg, Item."No."), LibraryVariableStorage.DequeueText());
        NotificationLifecycleMgt.RecallAllNotifications();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FilterLinesWithItemToPlan_TestLocationFilter()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        LocationFilter: Text;
    begin
        // [FEATURE] [Item Ledger Entry] [Filters] [Location]
        FilterLinesWithItemToPlan(Item);
        LocationFilter := Item.GetFilter("Location Filter");

        Item.Reset();
        Item.SetFilter("Location Filter", LocationFilter);
        ItemLedgerEntry.FilterLinesWithItemToPlan(Item, false);
        Assert.AreEqual(1, ItemLedgerEntry.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FilterLinesWithItemToPlan_TestVariantFilter()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        VariantFilter: Text;
    begin
        // [FEATURE] [Item Ledger Entry] [Filters] [Variant]
        FilterLinesWithItemToPlan(Item);
        VariantFilter := Item.GetFilter("Variant Filter");

        Item.Reset();
        Item.SetFilter("Variant Filter", VariantFilter);
        ItemLedgerEntry.FilterLinesWithItemToPlan(Item, false);
        Assert.AreEqual(1, ItemLedgerEntry.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FilterLinesWithItemToPlan_TestGlobalDim1Filter()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        GlobalDim1Filter: Text;
    begin
        // [FEATURE] [Item Ledger Entry] [Filters] [Global Dimension 1]
        FilterLinesWithItemToPlan(Item);
        GlobalDim1Filter := Item.GetFilter("Global Dimension 1 Filter");

        Item.Reset();
        Item.SetFilter("Global Dimension 1 Filter", GlobalDim1Filter);
        ItemLedgerEntry.FilterLinesWithItemToPlan(Item, false);
        Assert.AreEqual(1, ItemLedgerEntry.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FilterLinesWithItemToPlan_TestGlobalDim2Filter()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        GlobalDim2Filter: Text;
    begin
        // [FEATURE] [Item Ledger Entry] [Filters] [Global Dimension 2]
        FilterLinesWithItemToPlan(Item);
        GlobalDim2Filter := Item.GetFilter("Global Dimension 2 Filter");

        Item.Reset();
        Item.SetFilter("Global Dimension 2 Filter", GlobalDim2Filter);
        ItemLedgerEntry.FilterLinesWithItemToPlan(Item, false);
        Assert.AreEqual(1, ItemLedgerEntry.Count, '');
    end;

    local procedure FilterLinesWithItemToPlan(var Item: Record Item)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LocationCode: Code[10];
        VariantCode: Code[10];
        GlobalDim1Value: Code[10];
        GlobalDim2Value: Code[10];
    begin
        MockItem(Item);
        LocationCode := LibraryUtility.GenerateGUID();
        VariantCode := LibraryUtility.GenerateGUID();
        GlobalDim1Value := LibraryUtility.GenerateGUID();
        GlobalDim2Value := LibraryUtility.GenerateGUID();

        MockCustomILE(ItemLedgerEntry, Item."No.", LocationCode, 1, true, '', '', '');
        MockCustomILE(ItemLedgerEntry, Item."No.", '', 1, true, VariantCode, '', '');
        MockCustomILE(ItemLedgerEntry, Item."No.", '', 1, true, '', GlobalDim1Value, '');
        MockCustomILE(ItemLedgerEntry, Item."No.", '', 1, true, '', '', GlobalDim2Value);

        Item.SetFilter("Location Filter", LocationCode);
        Item.SetFilter("Variant Filter", VariantCode);
        Item.SetFilter("Global Dimension 1 Filter", GlobalDim1Value);
        Item.SetFilter("Global Dimension 2 Filter", GlobalDim2Value);
    end;

    local procedure MockLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        Location.Init();
        Location.Code := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location);
        Location.Insert();
        exit(Location.Code);
    end;

    local procedure MockCustomLocationCode(NewRequirePick: Boolean; NewRequireShipment: Boolean; NewBinMandatory: Boolean; NewDirectedPutAwayAndPick: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        Location.Init();
        Location.Code := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location);
        Location."Require Pick" := NewRequirePick;
        Location."Require Shipment" := NewRequireShipment;
        Location."Bin Mandatory" := NewBinMandatory;
        Location."Directed Put-away and Pick" := NewDirectedPutAwayAndPick;
        if Location."Require Pick" then
            if Location."Require Shipment" then
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)"
            else
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";

        if Location."Require Put-away" then
            Location."Prod. Output Whse. Handling" := Location."Prod. Output Whse. Handling"::"Inventory Put-away";

        Location.Insert();
        exit(Location.Code);
    end;

    local procedure MockILE(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.ClearState();
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry."Entry No." += 1;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::"Positive Adjmt.";
        ItemLedgerEntry."Location Code" := LocationCode;
        ItemLedgerEntry.Quantity := Qty;
        ItemLedgerEntry.Insert();
    end;

    local procedure MockCustomILE(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; NewOpen: Boolean; VariantCode: Code[10]; GlobalDim1Value: Code[10]; GlobalDim2Value: Code[10])
    begin
        MockILE(ItemLedgerEntry, ItemNo, LocationCode, Qty);
        ItemLedgerEntry.Open := NewOpen;
        ItemLedgerEntry."Variant Code" := VariantCode;
        ItemLedgerEntry."Global Dimension 1 Code" := GlobalDim1Value;
        ItemLedgerEntry."Global Dimension 2 Code" := GlobalDim2Value;
        ItemLedgerEntry.Modify();
    end;

    local procedure MockILENo(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        MockILE(ItemLedgerEntry, ItemNo, LocationCode, Qty);
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure VerifyWhseActivityLineNos(var WarehouseActivityLine: Record "Warehouse Activity Line"; NoOfLines: Integer; ExpectedLineNos: Text)
    var
        i: Integer;
        LineNo: Integer;
    begin
        WarehouseActivityLine.FindSet();
        for i := 1 to NoOfLines do begin
            Evaluate(LineNo, SelectStr(i, ExpectedLineNos));
            WarehouseActivityLine.TestField("Line No.", LineNo);
            WarehouseActivityLine.Next();
        end;
    end;

    local procedure VerifySortingOrderWhseActivityLines(WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Enum "Warehouse Action Type"; ShelfNo: Code[10]; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetCurrentKey("Sorting Sequence No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Shelf No.", ShelfNo);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;
}

