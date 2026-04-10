codeunit 137931 "SCM - Movement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Movement]
    end;

    var
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        TotalPendingMovQtyExceedsBinAvailErr: Label 'Item tracking defined for line %1, lot number %2, serial number %3, package number %4 cannot be applied.', Comment = '%1=Line No.,%2=Lot No.,%3=Serial No.,%4=Package No.';
        DialogCodeErr: Label 'Dialog';
        LinesExistErr: Label 'You cannot change %1 because one or more lines exist.';
        NothingToReplenishErr: Label 'There is nothing to replenish.';

    [Test]
    [Scope('OnPrem')]
    procedure CalculateBinReplenishmentQtyHandledBase()
    var
        PutAwayBin: Record Bin;
        PickBin: Record Bin;
        BinContent: Record "Bin Content";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        LocationCode: Code[10];
        ItemNo: Code[20];
        MinQty: Decimal;
    begin
        // [FEATURE] [UT] [Movement Worksheet] [Qty. Handled]
        // [SCENARIO 312913] When Calculate Bin Replenishment in Movement Worksheet then Qty Handled (Base) is <zero>
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        MinQty := LibraryRandom.RandInt(10);

        // [GIVEN] Location with with Pick Bin and Put-away Bin, Bin Ranking is higher for Pick Bin
        // [GIVEN] Bin Content for Put-away Bin had 10 PCS
        // [GIVEN] Fixed Bin Content for Pick Bin with Item, Min Qty = 5, Max Qty = 15
        LocationCode := CreateFullWMSLocation(1, false);

        LibraryWarehouse.FindBin(PutAwayBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.CreateBinContent(
          BinContent, LocationCode, PutAwayBin."Zone Code", PutAwayBin.Code, ItemNo, '', GetItemBaseUoM(ItemNo));
        UpdateBinContentQty(BinContent, 2 * MinQty);

        LibraryWarehouse.FindBin(PickBin, LocationCode, FindZone(LocationCode, FindBinType(true, true, false, false)), 1);
        LibraryWarehouse.CreateBinContent(
          BinContent, LocationCode, PickBin."Zone Code", PickBin.Code, ItemNo, '', GetItemBaseUoM(ItemNo));
        UpdateBinContentForReplenishment(
          BinContent, MinQty, 3 * MinQty, PutAwayBin."Bin Ranking" + LibraryRandom.RandInt(10), PickBin."Bin Type Code");

        // [WHEN] Calculate Bin Replenishment
        CalculateBinReplenishment(BinContent, LocationCode);

        // [THEN] Whse. Worksheet Line is created for Pick Bin with Qty Handled = Qty Handled (Base) = 0
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.TestField("To Bin Code", PickBin.Code);
        WhseWorksheetLine.TestField("Qty. Outstanding", 2 * MinQty);
        WhseWorksheetLine.TestField("Qty. Handled", 0);
        WhseWorksheetLine.TestField("Qty. Handled (Base)", 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandlerMultipleEntries')]
    [Scope('OnPrem')]
    procedure CreateMovementFromWkshWhenMultipleSimilarWkshLinesFEFO()
    var
        PutAwayBin: Record Bin;
        PickBin: Record Bin;
        BinContent: Record "Bin Content";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        LocationCode: Code[10];
        ItemNo: Code[20];
        MinQty: Integer;
        LotNo: array[4] of Code[50];
        ExpirationDate: array[4] of Date;
        Qty: array[4] of Integer;
        Delta: Integer;
        Index: Integer;
    begin
        // [FEATURE] [Movement Worksheet] [FEFO] [Item Tracking]
        // [SCENARIO 312913] Create Movement from Movement Worksheet generates correct Movements when multiple Similar Lines Present
        // [SCENARIO 312913] and pending Whse Shipment when Pick According to FEFO is enabled
        Initialize();
        InitQtys(MinQty, Qty, 2, 2, 10, 6);
        Delta := 1;
        for Index := 1 to ArrayLen(LotNo) do begin
            LotNo[Index] := LibraryUtility.GenerateGUID();
            ExpirationDate[Index] := CalcDate(StrSubstNo('<%1M>', Index), WorkDate());
        end;

        // [GIVEN] Item had Item Tracking Code with Lot Tracking and Man. Expir. Date Entry Reqd.
        ItemNo := CreateItemWithItemTrackingCode(true, true, false, false, true);

        // [GIVEN] Location with Pick According to FEFO enabled
        // [GIVEN] Pick Bin and 3 Put-away Bins "B1", "B2" and "B3", Bin Ranking was higher for Pick Bin
        // [GIVEN] Fixed Bin Content for Pick Bin with the Item, Min Qty = 10, Max Qty = 30
        LocationCode := CreateFullWMSLocation(1, true);
        LibraryWarehouse.FindBin(PutAwayBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.CreateNumberOfBins(LocationCode, PutAwayBin."Zone Code", PutAwayBin."Bin Type Code", 2, false);
        LibraryWarehouse.FindBin(PickBin, LocationCode, FindZone(LocationCode, FindBinType(true, true, false, false)), 1);
        SetBinRanking(PickBin, PutAwayBin."Bin Ranking" + LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateBinContent(
          BinContent, LocationCode, PickBin."Zone Code", PickBin.Code, ItemNo, '', GetItemBaseUoM(ItemNo));
        UpdateBinContentForReplenishment(BinContent, MinQty, 3 * MinQty, PickBin."Bin Ranking", PickBin."Bin Type Code");

        // [GIVEN] Released Purchase Order with 20 PCS of the Item, Item Tracking was specified as follows:
        // [GIVEN] Lot "L1" with 2 PCS, Expiration Date = 1/1/2021
        // [GIVEN] Lot "L2" with 2 PCS, Expiration Date = 1/2/2021
        // [GIVEN] Lot "L3" with 10 PCS, Expiration Date = 1/3/2021
        // [GIVEN] Lot "L4" with 6 PCS, Expiration Date = 1/4/2021
        // [GIVEN] Posted Whse Receipt
        CreatePurchaseOrderWithLocationAndItem(PurchaseHeader, LocationCode, ItemNo, 2 * MinQty);
        PrepareItemTrackingLinesPurchase(PurchaseHeader, LotNo, ExpirationDate, Qty);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PostWhseReceipt(PurchaseHeader);

        // [GIVEN] Updated Put-away Place Lines as follows:
        // [GIVEN] Line with Lot "L2" had Bin Code = "B1"
        // [GIVEN] Line with Lot "L3" had Bin Code = "B2"
        // [GIVEN] Line with Lot "L4" had Bin Code = "B3"
        // [GIVEN] Registered Put-away
        FindPutAway(WarehouseActivityHeader, ItemNo);
        FilterWhseActivityLines(WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place);
        for Index := 1 to ArrayLen(LotNo) - 1 do begin
            LibraryWarehouse.FindBin(PutAwayBin, LocationCode, PutAwayBin."Zone Code", Index);
            WarehouseActivityLine.SetRange("Lot No.", LotNo[Index + 1]);
            WarehouseActivityLine.FindFirst();
            WarehouseActivityLine.Validate("Zone Code", PutAwayBin."Zone Code");
            WarehouseActivityLine.Validate("Bin Code", PutAwayBin.Code);
            WarehouseActivityLine.Modify(true);
        end;
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Released Sales Order with 2 PCS of Item with Lot "L1", created Warehouse Shipment and registered Pick
        CreateSalesOrderWithLocationAndItem(SalesHeader, LocationCode, ItemNo, Qty[1]);
        PrepareItemTrackingLineSales(SalesHeader, LotNo[1], Qty[1]);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        RegisterPick(SalesHeader);

        // [GIVEN] Calculated Bin Replenishment (Whse. Worksheet Lines were created with Total 18 PCS = 2 + 10 + 6 PCS)
        CalculateBinReplenishment(BinContent, LocationCode);

        // [GIVEN] Changed Qty. to Handle in the Lines, so that 16 PCS are handled
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindSet();
        WhseWorksheetLine.Next();
        repeat
            WhseWorksheetLine.Validate("Qty. to Handle", WhseWorksheetLine."Qty. to Handle" - Delta);
            WhseWorksheetLine.Modify();
        until WhseWorksheetLine.Next() = 0;

        // [GIVEN] Created Movement (3 Take Lines: Lot "L2", Bin "B1" with 2 PCS, Lot "L3", Bin "B2" with 10 PCS, Lot "L4", Bin "B3" with 4 PCS)
        // [GIVEN] Registered Movement
        CreateMovementFromMovementWorksheet();
        FindMovement(WarehouseActivityHeader, ItemNo);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Create Movement
        CreateMovementFromMovementWorksheet();

        // [THEN] Movement has Take Line with Lot "L4", Bin "B3" and 2 PCS
        LibraryWarehouse.FindBin(PutAwayBin, LocationCode, PutAwayBin."Zone Code", 3);
        FindMovement(WarehouseActivityHeader, ItemNo);
        FilterWhseActivityLines(WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Lot No.", LotNo[4]);
        WarehouseActivityLine.TestField("Bin Code", PutAwayBin.Code);
        WarehouseActivityLine.TestField("Qty. to Handle", 2 * Delta);
        Assert.RecordCount(WarehouseActivityLine, 1);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandlerLotMultipleEntries,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementWithTrackingWhenPendingMovementExistsAndMoreQtyInTrkg()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Item: Record Item;
        Bin: Record Bin;
        ToBin: Record Bin;
        LocationCode: Code[10];
        ItemNo: Code[20];
        LotNo: array[2] of Code[50];
        QtyLot: array[2] of Integer;
        Index: Integer;
    begin
        // [FEATURE] [Worksheet] [Item Tracking] [Bin]
        // [SCENARIO 325576] When pending Movements present then Movement is not created from Movement Worksheet if Lot Tracked Item has not enough PCS in the Bin
        Initialize();
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        QtyLot[1] := 1 + LibraryRandom.RandInt(10);
        QtyLot[2] := LibraryRandom.RandInt(10);

        // [GIVEN] Location with 2 Bins
        LocationCode := CreateFullWMSLocation(2, false);

        // [GIVEN] Item with Lot Warehouse Tracking enabled
        ItemNo := CreateItemWithItemTrackingCode(true, true, false, false, false);

        // [GIVEN] Bin "B" had 4 PCS with Lot "L1" and 6 PCS with Lot "L2"
        LibraryWarehouse.FindBin(Bin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.FindBin(ToBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 2);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(QtyLot[Index]);
        end;
        LibraryWarehouse.UpdateWarehouseStockOnBin(Bin, ItemNo, QtyLot[1] + QtyLot[2], true);
        Item.Get(ItemNo);
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');

        // [GIVEN] Warehouse Movement Worksheet Line with 1 PCS of the Item with From-Bin = "B" and Lot "L1"
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, ToBin, ItemNo, '', 1);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo[1]);
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Qty. (Base)");
        WhseWorksheetLine.OpenItemTrackingLines();

        // [GIVEN] Created Movement from Worksheet
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", "Whse. Activity Sorting Method"::None, false, false);

        // [GIVEN] Warehouse Movement Worksheet Line with 10 PCS of the Item with From-Bin = "B"
        // [GIVEN] Warehouse Item Tracking was specified as follows: 4 PCS with Lot "L1" and 6 PCS with Lot "L2"
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, ToBin, ItemNo, '', QtyLot[1] + QtyLot[2]);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(QtyLot[Index]);
        end;
        WhseWorksheetLine.OpenItemTrackingLines();

        // [WHEN] Create Movement from Worksheet
        asserterror LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", "Whse. Activity Sorting Method"::None, false, false);

        // [THEN] Error 'Item tracking defined for line 10000, lot number L1, serial number cannot be applied.'
        Assert.ExpectedError(StrSubstNo(TotalPendingMovQtyExceedsBinAvailErr, WhseWorksheetLine."Line No.", LotNo[1], '', ''));
        Assert.ExpectedErrorCode(DialogCodeErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandlerLotMultipleEntries,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementWithLotTrackingWhenPendingMovementExists()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Item: Record Item;
        Bin: Record Bin;
        ToBin: Record Bin;
        LocationCode: Code[10];
        ItemNo: Code[20];
        LotNo: array[2] of Code[50];
        QtyLot: array[2] of Integer;
        Index: Integer;
    begin
        // [FEATURE] [Worksheet] [Item Tracking] [Bin]
        // [SCENARIO 325576] When pending Movements present then Movement is created from Movement Worksheet if Lot Tracked Item has enough PCS in the Bin
        Initialize();
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        QtyLot[1] := 1 + LibraryRandom.RandInt(10);
        QtyLot[2] := LibraryRandom.RandInt(10);

        // [GIVEN] Location with 2 Bins
        LocationCode := CreateFullWMSLocation(2, false);

        // [GIVEN] Item with Lot Warehouse Tracking enabled
        ItemNo := CreateItemWithItemTrackingCode(true, true, false, false, false);

        // [GIVEN] Bin "B" had 4 PCS with Lot "L1" and 6 PCS with Lot "L2"
        LibraryWarehouse.FindBin(Bin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.FindBin(ToBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 2);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(QtyLot[Index]);
        end;
        LibraryWarehouse.UpdateWarehouseStockOnBin(Bin, ItemNo, QtyLot[1] + QtyLot[2], true);
        Item.Get(ItemNo);
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');

        // [GIVEN] Warehouse Movement Worksheet Line with 1 PCS of the Item with From-Bin = "B" and Lot "L1"
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, ToBin, ItemNo, '', 1);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo[1]);
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Qty. (Base)");
        WhseWorksheetLine.OpenItemTrackingLines();

        // [GIVEN] Created Movement from Worksheet
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", "Whse. Activity Sorting Method"::None, false, false);

        // [GIVEN] Warehouse Movement Worksheet Line with 9 PCS of the Item with From-Bin = "B"
        // [GIVEN] Warehouse Item Tracking was specified as follows: 3 PCS with Lot "L1" and 6 PCS with Lot "L2"
        QtyLot[1] -= WhseWorksheetLine."Qty. (Base)";
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, ToBin, ItemNo, '', QtyLot[1] + QtyLot[2]);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(QtyLot[Index]);
        end;
        WhseWorksheetLine.OpenItemTrackingLines();

        // [WHEN] Create Movement from Worksheet
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", "Whse. Activity Sorting Method"::None, false, false);

        // [THEN] Movement is created
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.");
        WarehouseActivityLine.SetRange("Bin Code", Bin.Code);
        WarehouseActivityLine.SetRange("Lot No.", LotNo[2]);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
        for Index := 1 to ArrayLen(LotNo) do begin
            WarehouseActivityLine.SetRange("Lot No.", LotNo[Index]);
            WarehouseActivityLine.FindFirst();
            WarehouseActivityLine.TestField("Qty. (Base)", QtyLot[Index]);
        end;
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandlerPackageMultipleEntries,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementWithPackageTrackingWhenPendingMovementExists()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Item: Record Item;
        Bin: Record Bin;
        ToBin: Record Bin;
        LocationCode: Code[10];
        ItemNo: Code[20];
        PackageNo: array[2] of Code[50];
        QtyPackage: array[2] of Integer;
        Index: Integer;
    begin
        // [FEATURE] [Worksheet] [Item Tracking] [Bin]
        // [SCENARIO 325576] When pending Movements present then Movement is created from Movement Worksheet if Package Tracked Item has enough PCS in the Bin
        Initialize();
        PackageNo[1] := LibraryUtility.GenerateGUID();
        PackageNo[2] := LibraryUtility.GenerateGUID();
        QtyPackage[1] := 1 + LibraryRandom.RandInt(10);
        QtyPackage[2] := LibraryRandom.RandInt(10);

        // [GIVEN] Location with 2 Bins
        LocationCode := CreateFullWMSLocation(2, false);

        // [GIVEN] Item with Lot Warehouse Tracking enabled
        ItemNo := CreateItemWithItemTrackingCode(false, false, true, true, false);

        // [GIVEN] Bin "B" had 4 PCS with Lot "L1" and 6 PCS with Lot "L2"
        LibraryWarehouse.FindBin(Bin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.FindBin(ToBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 2);
        LibraryVariableStorage.Enqueue(ArrayLen(PackageNo));
        for Index := 1 to ArrayLen(PackageNo) do begin
            LibraryVariableStorage.Enqueue(PackageNo[Index]);
            LibraryVariableStorage.Enqueue(QtyPackage[Index]);
        end;
        LibraryWarehouse.UpdateWarehouseStockOnBin(Bin, ItemNo, QtyPackage[1] + QtyPackage[2], true);
        Item.Get(ItemNo);
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');

        // [GIVEN] Warehouse Movement Worksheet Line with 1 PCS of the Item with From-Bin = "B" and Lot "L1"
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, ToBin, ItemNo, '', 1);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(PackageNo[1]);
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Qty. (Base)");
        WhseWorksheetLine.OpenItemTrackingLines();

        // [GIVEN] Created Movement from Worksheet
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", "Whse. Activity Sorting Method"::None, false, false);

        // [GIVEN] Warehouse Movement Worksheet Line with 9 PCS of the Item with From-Bin = "B"
        // [GIVEN] Warehouse Item Tracking was specified as follows: 3 PCS with Package "L1" and 6 PCS with Package "L2"
        QtyPackage[1] -= WhseWorksheetLine."Qty. (Base)";
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, ToBin, ItemNo, '', QtyPackage[1] + QtyPackage[2]);
        LibraryVariableStorage.Enqueue(ArrayLen(PackageNo));
        for Index := 1 to ArrayLen(PackageNo) do begin
            LibraryVariableStorage.Enqueue(PackageNo[Index]);
            LibraryVariableStorage.Enqueue(QtyPackage[Index]);
        end;
        WhseWorksheetLine.OpenItemTrackingLines();

        // [WHEN] Create Movement from Worksheet
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", "Whse. Activity Sorting Method"::None, false, false);

        // [THEN] Movement is created
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.");
        WarehouseActivityLine.SetRange("Bin Code", Bin.Code);
        WarehouseActivityLine.SetRange("Package No.", PackageNo[2]);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
        for Index := 1 to ArrayLen(PackageNo) do begin
            WarehouseActivityLine.SetRange("Package No.", PackageNo[Index]);
            WarehouseActivityLine.FindFirst();
            WarehouseActivityLine.TestField("Qty. (Base)", QtyPackage[Index]);
        end;
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrWhenValidateLocationCodeIntMovementWithLine()
    var
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        Location: Record Location;
    begin
        // [FEATURE] [UT] [Internal Movement]
        // [SCENARIO 311310] Location Code cannot be changed in Internal Movement if Lines present.
        Initialize();

        // [GIVEN] Internal Movement with Location 'BLUE' had Internal Movement Line
        CreateLocationWithBinMandatory(Location, true);
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, '');
        LibraryWarehouse.CreateInternalMovementLine(
          InternalMovementHeader, InternalMovementLine, LibraryInventory.CreateItemNo(), '', '', LibraryRandom.RandInt(10));
        CreateLocationWithBinMandatory(Location, true);

        // [WHEN] Validate Location Code = 'SILVER' in Internal Movement Header
        asserterror InternalMovementHeader.Validate("Location Code", Location.Code);

        // [THEN] Error 'You cannot change Location Code because one or more lines exist.'
        Assert.ExpectedError(StrSubstNo(LinesExistErr, InternalMovementHeader.FieldCaption("Location Code")));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateLocationCodeIntMovementWithoutLines()
    var
        InternalMovementHeader: Record "Internal Movement Header";
        Location: Record Location;
    begin
        // [FEATURE] [UT] [Internal Movement]
        // [SCENARIO 311310] Location Code can be changed in Internal Movement Header when Lines do not present.
        Initialize();

        // [GIVEN] Internal Movement Header with Location 'BLUE'
        CreateLocationWithBinMandatory(Location, true);
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, '');
        CreateLocationWithBinMandatory(Location, true);

        // [WHEN] Validate Location Code = 'SILVER' in Internal Movement Header
        InternalMovementHeader.Validate("Location Code", Location.Code);

        // [THEN] Internal Movement Header has Location Code 'SILVER'
        InternalMovementHeader.TestField("Location Code", Location.Code);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandlerLotMultipleEntries,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementWithLotTrackingFromSeveralBins()
    var
        Item: Record Item;
        FromBin: array[2] of Record Bin;
        ToBin: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LocationCode: Code[10];
        LotNo: array[2] of Code[50];
        QtyLot: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Worksheet] [Item Tracking] [Bin]
        // [SCENARIO 352396] Creating movement from movement worksheet lines with various source bins.
        Initialize();
        QtyLot := LibraryRandom.RandInt(10);

        // [GIVEN] Directed put-away and pick location.
        LocationCode := CreateFullWMSLocation(3, false);

        // [GIVEN] Item with "Lot Warehouse Tracking" enabled.
        Item.Get(CreateItemWithItemTrackingCode(true, true, false, false, false));

        LibraryWarehouse.FindBin(ToBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.FindBin(FromBin[1], LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 2);
        LibraryWarehouse.FindBin(FromBin[2], LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 3);

        // [GIVEN] Place "Lot-1" for 10 pcs of the item to bin "B1", and "Lot-2" for 10 pcs to bin "B2".
        for i := 1 to ArrayLen(LotNo) do begin
            LotNo[i] := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(1);
            LibraryVariableStorage.Enqueue(LotNo[i]);
            LibraryVariableStorage.Enqueue(QtyLot);
            LibraryWarehouse.UpdateWarehouseStockOnBin(FromBin[i], Item."No.", QtyLot, true);
        end;
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');

        // [GIVEN] Open movement worksheet and create two lines, one per bin, assign "Lot-1" and "Lot-2" respectively.
        for i := 1 to ArrayLen(LotNo) do begin
            LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, FromBin[i], ToBin, Item."No.", '', QtyLot);
            LibraryVariableStorage.Enqueue(1);
            LibraryVariableStorage.Enqueue(LotNo[i]);
            LibraryVariableStorage.Enqueue(WhseWorksheetLine."Qty. (Base)");
            WhseWorksheetLine.OpenItemTrackingLines();
        end;

        // [WHEN] Create movement from the movement worksheet.
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", "Whse. Activity Sorting Method"::None, false, false);

        // [THEN] A new warehouse movement from bins "B1" and "B2" has been created.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        for i := 1 to ArrayLen(LotNo) do begin
            WarehouseActivityLine.SetRange("Lot No.", LotNo[i]);
            WarehouseActivityLine.FindFirst();
            WarehouseActivityLine.TestField("Bin Code", FromBin[i].Code);
            WarehouseActivityLine.TestField("Qty. (Base)", QtyLot);
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandlerPackageMultipleEntries,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementWithPackageTrackingFromSeveralBins()
    var
        Item: Record Item;
        FromBin: array[2] of Record Bin;
        ToBin: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LocationCode: Code[10];
        PackageNo: array[2] of Code[50];
        QtyPackage: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Worksheet] [Item Tracking] [Bin]
        // [SCENARIO 352396] Creating movement from movement worksheet lines with various source bins.
        Initialize();
        QtyPackage := LibraryRandom.RandInt(10);

        // [GIVEN] Directed put-away and pick location.
        LocationCode := CreateFullWMSLocation(3, false);

        // [GIVEN] Item with "Lot Warehouse Tracking" enabled.
        Item.Get(CreateItemWithItemTrackingCode(false, false, true, true, false));

        LibraryWarehouse.FindBin(ToBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.FindBin(FromBin[1], LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 2);
        LibraryWarehouse.FindBin(FromBin[2], LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 3);

        // [GIVEN] Place "Package-1" for 10 pcs of the item to bin "B1", and "Package-2" for 10 pcs to bin "B2".
        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(1);
            LibraryVariableStorage.Enqueue(PackageNo[i]);
            LibraryVariableStorage.Enqueue(QtyPackage);
            LibraryWarehouse.UpdateWarehouseStockOnBin(FromBin[i], Item."No.", QtyPackage, true);
        end;
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');

        // [GIVEN] Open movement worksheet and create two lines, one per bin, assign "Package-1" and "Package-2" respectively.
        for i := 1 to ArrayLen(PackageNo) do begin
            LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, FromBin[i], ToBin, Item."No.", '', QtyPackage);
            LibraryVariableStorage.Enqueue(1);
            LibraryVariableStorage.Enqueue(PackageNo[i]);
            LibraryVariableStorage.Enqueue(WhseWorksheetLine."Qty. (Base)");
            WhseWorksheetLine.OpenItemTrackingLines();
        end;

        // [WHEN] Create movement from the movement worksheet.
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", "Whse. Activity Sorting Method"::None, false, false);

        // [THEN] A new warehouse movement from bins "B1" and "B2" has been created.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        for i := 1 to ArrayLen(PackageNo) do begin
            WarehouseActivityLine.SetRange("Package No.", PackageNo[i]);
            WarehouseActivityLine.FindFirst();
            WarehouseActivityLine.TestField("Bin Code", FromBin[i].Code);
            WarehouseActivityLine.TestField("Qty. (Base)", QtyPackage);
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandlerPackageMultipleEntries')]
    [Scope('OnPrem')]
    procedure MovementWorksheetWithLotPackageTrackingGetBinContent()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        BinType: Record "Bin Type";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseInternalPutawayHeader: Record "Whse. Internal Put-away Header";
        LocationCode: Code[10];
        PackageNo: array[2] of Code[50];
        TotalQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Worksheet] [Item Tracking] [Bin]
        // [SCENARIO 352396] Creating movement worksheet lines using Get Content Bin report for lot/package tracking 
        Initialize();
        TotalQty := 10;

        // [GIVEN] Directed put-away and pick location.
        LocationCode := CreateFullWMSLocation(3, false);

        // [GIVEN] Item with "Lot Warehouse Tracking" enabled.
        Item.Get(CreateItemWithItemTrackingCode(false, false, true, true, false));

        BinType.SetRange(Receive, false);
        BinType.SetRange(Ship, true);
        if not BinType.FindFirst() then
            LibraryWarehouse.CreateBinType(BinType, false, true, false, false);

        LibraryWarehouse.FindBin(Bin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 2);

        // [GIVEN] Place "Package1" of 10 pcs and "Package2" of 10 pcs to bin
        for i := 1 to ArrayLen(PackageNo) do begin
            PackageNo[i] := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(1);
            LibraryVariableStorage.Enqueue(PackageNo[i]);
            LibraryVariableStorage.Enqueue(TotalQty);
            LibraryWarehouse.UpdateWarehouseStockOnBin(Bin, Item."No.", TotalQty, true);
        end;

        CreateEmptyMovementWorksheetLine(WhseWorksheetLine, LocationCode);

        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", Bin.Code);

        LibraryWarehouse.WhseGetBinContent(
            BinContent, WhseWorksheetLine, WhseInternalPutawayHeader, "Warehouse Destination Type 2"::MovementWorksheet);

        // [WhEN] Verify item tracking in warehouse worksheet line
        WhseWorksheetLine.SetRange("Item No.", Item."No.");
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.TestField("Item No.", Item."No.");
        WhseWorksheetLine.TestField(Quantity, TotalQty * 2);

        // Check item tracking
        WhseItemTrackingLine.SetRange("Source Type", Database::"Whse. Worksheet Line");
        WhseItemTrackingLine.SetRange("Source Batch Name", WhseWorksheetLine."Worksheet Template Name");
        WhseItemTrackingLine.SetRange("Source ID", WhseWorksheetLine.Name);
        WhseItemTrackingLine.SetRange("Source Ref. No.", WhseWorksheetLine."Line No.");
        WhseItemTrackingLine.SetRange("Item No.", Item."No.");
        WhseItemTrackingLine.SetRange("Location Code", LocationCode);
        WhseItemTrackingLine.SetRange("Package No.", PackageNo[1]);
        WhseItemTrackingLine.FindFirst();
        Assert.AreEqual(WhseItemTrackingLine."Quantity (Base)", TotalQty, '');
        WhseItemTrackingLine.SetRange("Package No.", PackageNo[2]);
        WhseItemTrackingLine.FindFirst();
        Assert.AreEqual(WhseItemTrackingLine."Quantity (Base)", TotalQty, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UoMRoundingPrecisionTransferredWhenCreatingMovement()
    var
        Item: Record Item;
        ItemBaseUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        LocationCode: Code[10];
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WhseJournalLine: Record "Warehouse Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        // [SCENARIO] Rounding precision should be transferred to warehouse activity lines when doing a warehouse movement.
        Initialize();
        Qty := 10;

        // [GIVEN] An item with base UoM rounding precision 0.01 and a non-base UoM with rounding precision 0.1.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemBaseUOM, Item."No.", BaseUOM.Code, 1);
        ItemBaseUOM."Qty. Rounding Precision" := 0.01;
        ItemBaseUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemBaseUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemNonBaseUOM, Item."No.", NonBaseUOM.Code, 12);
        ItemNonBaseUOM."Qty. Rounding Precision" := 0.1;
        ItemNonBaseUOM.Modify();

        // [GIVEN] Directed put-away and pick location.
        LocationCode := CreateFullWMSLocation(2, false);
        LibraryWarehouse.FindBin(Bin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);

        // [GIVEN] Create warehouse journal line for item.
        LibraryWarehouse.WarehouseJournalSetup(LocationCode, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
            WhseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, LocationCode,
            '', Bin.Code, WhseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        WhseJournalLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);
        WhseJournalLine.Modify(true);
        LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, LocationCode, false);

        // [GIVEN] Item journal posted for warehouse journal line.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(
            ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // [GIVEN] Open movement worksheet and create line for bin using non-base UoM.
        CreateEmptyMovementWorksheetLine(WhseWorksheetLine, LocationCode);
        WhseWorksheetLine.Validate("Item No.", Item."No.");
        WhseWorksheetLine.Validate("From Bin Code", Bin.Code);
        WhseWorksheetLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);
        WhseWorksheetLine.Validate(Quantity, Qty);
        WhseWorksheetLine.Modify(true);

        // [WHEN] Create movement from the movement worksheet.
        LibraryWarehouse.CreateWhseMovement(
            WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", "Whse. Activity Sorting Method"::None, false, false);

        // [THEN] Rounding precision has been transferred to the warehouse activity lines.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.FindSet();

        repeat
            Assert.AreEqual(
                ItemBaseUOM."Qty. Rounding Precision",
                WarehouseActivityLine."Qty. Rounding Precision (Base)",
                'Expected base rounding precision to match item base UoM'
            );
            Assert.AreEqual(
                ItemNonBaseUOM."Qty. Rounding Precision",
                WarehouseActivityLine."Qty. Rounding Precision",
                'Expected rounding precision to match item non-base UoM'
            );
        until WarehouseActivityLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('BinContentsListModalPageHandler')]
    procedure ValidateAndLookupFromBinCodeOnInternalMovementLine()
    var
        Location: Record Location;
        FromBin: array[2] of Record Bin;
        ToBin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        InternalMovement: TestPage "Internal Movement";
    begin
        // [FEATURE] [Internal Movement] [Blocked]
        // [SCENARIO 402448] Cannot select a blocked bin in "From Bin Code" in internal movement line either via lookup or validate.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location with mandatory bin.
        // [GIVEN] Two source bin codes "S1", "S2" and a target bin code "T1".
        CreateLocationWithBinMandatory(Location, true);
        LibraryWarehouse.CreateBin(FromBin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(FromBin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(ToBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Create bin content for bin "S1" and block outbound movements.
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', FromBin[1].Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate("Block Movement", BinContent."Block Movement"::Outbound);
        BinContent.Modify(true);

        // [GIVEN] Block all movements for bin "S2".
        FromBin[2].Validate("Block Movement", FromBin[2]."Block Movement"::All);
        FromBin[2].Modify(true);

        // [GIVEN] Create internal movement.
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, ToBin.Code);
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, BinContent."Item No.", '', '', 0);

        Commit();

        // [WHEN] Select "From Bin Code" = "S1" via lookup.
        // [THEN] An error message is thrown - the bin is blocked for outbound movements.
        LibraryVariableStorage.Enqueue(FromBin[1].Code);
        InternalMovement.OpenEdit();
        InternalMovement.FILTER.SetFilter("No.", InternalMovementHeader."No.");
        InternalMovement.InternalMovementLines.First();
        asserterror InternalMovement.InternalMovementLines."From Bin Code".Lookup();
        InternalMovement.Close();
        Assert.ExpectedError('Outbound');

        // [WHEN] Select "From Bin Code" = "S2" via validate.
        // [THEN] An error message is thrown - the bin is blocked for all movements.
        asserterror InternalMovementLine.Validate("From Bin Code", FromBin[2].Code);
        Assert.ExpectedError('All');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BinListModalPageHandler')]
    procedure ValidateAndLookupToBinCodeOnInternalMovementLine()
    var
        Location: Record Location;
        FromBin: Record Bin;
        ToBin: array[2] of Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        InternalMovement: TestPage "Internal Movement";
    begin
        // [FEATURE] [Internal Movement] [Blocked]
        // [SCENARIO 402448] Cannot select a blocked bin in "To Bin Code" in internal movement line either via lookup or validate.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location with mandatory bin.
        // [GIVEN] A source bin codes "S1" and two target bin codes "T1", "T2".
        CreateLocationWithBinMandatory(Location, true);
        LibraryWarehouse.CreateBin(FromBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(ToBin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(ToBin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Create bin content for bin "T1" and block inbound movements.
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', ToBin[1].Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate("Block Movement", BinContent."Block Movement"::Inbound);
        BinContent.Modify(true);

        // [GIVEN] Block all movements for bin "T2".
        ToBin[2].Validate("Block Movement", ToBin[2]."Block Movement"::All);
        ToBin[2].Modify(true);

        // [GIVEN] Create internal movement.
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, '');
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, BinContent."Item No.", '', '', 0);

        Commit();

        // [WHEN] Select "To Bin Code" = "T1" via lookup.
        // [THEN] An error message is thrown - the bin is blocked for inbound movements.
        LibraryVariableStorage.Enqueue(ToBin[1].Code);
        InternalMovement.OpenEdit();
        InternalMovement.FILTER.SetFilter("No.", InternalMovementHeader."No.");
        InternalMovement.InternalMovementLines.First();
        asserterror InternalMovement.InternalMovementLines."To Bin Code".Lookup();
        InternalMovement.Close();
        Assert.ExpectedError('Inbound');

        // [WHEN] Select "To Bin Code" = "T2" via validate.
        // [THEN] An error message is thrown - the bin is blocked for all movements.
        asserterror InternalMovementLine.Validate("To Bin Code", ToBin[2].Code);
        Assert.ExpectedError('All');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('BinListModalPageHandler')]
    procedure ValidateAndLookupToBinCodeOnInternalMovementHeader()
    var
        Location: Record Location;
        ToBin: array[2] of Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovement: TestPage "Internal Movement";
    begin
        // [FEATURE] [Internal Movement] [Blocked]
        // [SCENARIO 402448] Cannot select a blocked bin in "To Bin Code" in internal movement header either via lookup or validate.
        Initialize();

        // [GIVEN] Location with mandatory bin.
        // [GIVEN] Two bin codes "T1", "T2".
        CreateLocationWithBinMandatory(Location, true);
        LibraryWarehouse.CreateBin(ToBin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(ToBin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Block bin "T1" for inbound movements, block "T2" for all movements.
        ToBin[1].Validate("Block Movement", ToBin[1]."Block Movement"::Inbound);
        ToBin[1].Modify(true);
        ToBin[2].Validate("Block Movement", ToBin[2]."Block Movement"::All);
        ToBin[2].Modify(true);

        // [GIVEN] Create internal movement header.
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, '');

        Commit();

        // [WHEN] Select "To Bin Code" = "T1" via lookup.
        // [THEN] An error message is thrown - the bin is blocked for inbound movements.
        LibraryVariableStorage.Enqueue(ToBin[1].Code);
        InternalMovement.OpenEdit();
        InternalMovement.FILTER.SetFilter("No.", InternalMovementHeader."No.");
        asserterror InternalMovement."To Bin Code".Lookup();
        InternalMovement.Close();
        Assert.ExpectedError('Inbound');

        // [WHEN] Select "To Bin Code" = "T2" via validate.
        // [THEN] An error message is thrown - the bin is blocked for all movements.
        asserterror InternalMovementHeader.Validate("To Bin Code", ToBin[2].Code);
        Assert.ExpectedError('All');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure CheckInboundOutboundBinCodesOnCreateMovementFromInternalMvmt()
    var
        Location: Record Location;
        FromBin: array[2] of Record Bin;
        ToBin: array[2] of Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Internal Movement] [Blocked]
        // [SCENARIO 402448] Cannot create inventory movement from internal movement when either "From Bin Code" or "To Bin Code" is blocked.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location with mandatory bin.
        // [GIVEN] Two source bin codes "S1", "S2" and two target bin codes "T1", "T2".
        CreateLocationWithBinMandatory(Location, true);
        LibraryWarehouse.CreateBin(FromBin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(FromBin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(ToBin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(ToBin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Post inventory to bins "S1" and "S2".
        UpdateInventoryInBin(Item."No.", FromBin[1]);
        UpdateInventoryInBin(Item."No.", FromBin[2]);

        // [GIVEN] Block outbound movements from bin "S1".
        BinContent.Get(Location.Code, FromBin[1].Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate("Block Movement", BinContent."Block Movement"::Outbound);
        BinContent.Modify(true);

        // [GIVEN] Block inbound movements to bin "T1".
        ToBin[1].Validate("Block Movement", ToBin[1]."Block Movement"::Inbound);
        ToBin[1].Modify(true);

        // [GIVEN] Create internal movement.
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, '');
        LibraryWarehouse.CreateInternalMovementLine(
          InternalMovementHeader, InternalMovementLine, BinContent."Item No.", '', '', LibraryRandom.RandInt(10));

        Commit();

        // [WHEN] Set "From Bin Code" = "S1", "To Bin Code" = "T2" and create inventory movement.
        // [THEN] An inventory movement cannot be created - "From Bin Code" is blocked for outbound movements.
        InternalMovementLine.Find();
        InternalMovementLine."From Bin Code" := FromBin[1].Code;
        InternalMovementLine."To Bin Code" := ToBin[2].Code;
        InternalMovementLine.Modify();
        asserterror LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
        Assert.ExpectedError('Outbound');

        // [WHEN] Set "From Bin Code" = "S2", "To Bin Code" = "T1" and create inventory movement.
        // [THEN] An inventory movement cannot be created - "To Bin Code" is blocked for inbound movements.
        InternalMovementLine.Find();
        InternalMovementLine."From Bin Code" := FromBin[2].Code;
        InternalMovementLine."To Bin Code" := ToBin[1].Code;
        InternalMovementLine.Modify();
        asserterror LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
        Assert.ExpectedError('Inbound');

        // [WHEN] Set "From Bin Code" = "S2", "To Bin Code" = "T2" and create inventory movement.
        InternalMovementLine.Find();
        InternalMovementLine."From Bin Code" := FromBin[2].Code;
        InternalMovementLine."To Bin Code" := ToBin[2].Code;
        InternalMovementLine.Modify();
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        // [THEN] An inventory movement has been successfully created.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsNotEmpty(WarehouseActivityLine);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandlerLotMultipleEntries,MessageHandler')]
    procedure ExpirationDateInMovementFromWkshtWhenLotIsNotInInventoryYet()
    var
        Bin: array[2] of Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        LotNo: Code[20];
        ExpirationDate: Date;
        Qty: Decimal;
    begin
        // [FEATURE] [Worksheet] [Item Tracking] [Expiration Date]
        // [SCENARIO 420579] Expiration Date is copied from movement worksheet to warehouse movement when the lot no. is not posted to inventory yet.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        ExpirationDate := LibraryRandom.RandDate(90);
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Lot-tracked item with enabled warehouse tracking and mandatory expiration date.
        ItemNo := CreateItemWithItemTrackingCode(true, true, false, false, true);

        // [GIVEN] Location set up for directed put-away and pick.
        // [GIVEN] Two bins "B1" and "B2" in picking zone.
        LocationCode := CreateFullWMSLocation(2, false);
        LibraryWarehouse.FindBin(Bin[1], LocationCode, FindZone(LocationCode, FindBinType(true, true, false, false)), 1);
        LibraryWarehouse.FindBin(Bin[2], LocationCode, FindZone(LocationCode, FindBinType(true, true, false, false)), 2);

        // [GIVEN] Create and post warehouse journal line: bin = "B1", lot no. = "L", expiration date = "31/12/YY".
        CreateAndPostWhseItemJournalLine(Bin[1], ItemNo, LotNo, ExpirationDate, Qty);

        // [GIVEN] Create movement worksheet line: from bin = "B1", to bin = "B2", lot no. = "L", expiration date = "31/12/YY".
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin[1], Bin[2], ItemNo, '', Qty);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        WhseWorksheetLine.OpenItemTrackingLines();
        UpdateExpirationDateOnWhseItemTrackingLine(ItemNo, LotNo, ExpirationDate);

        // [WHEN] Create warehouse movement from the movement worksheet.
        LibraryWarehouse.CreateWhseMovement(
            WhseWorksheetLine.Name, LocationCode, "Whse. Activity Sorting Method"::None, false, false);

        // [THEN] A new warehouse movement is created.
        // [THEN] Lot no. = "L" and expiration date = "31/12/YY" on the movement line.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Lot No.", LotNo);
        WarehouseActivityLine.TestField("Expiration Date", ExpirationDate);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandlerMultipleEntries')]
    [Scope('OnPrem')]
    procedure ValidateBinCodeForActionTypePlaceShouldNotUpdateWhenBinTypeRecieve()
    var
        PutAwayBin: Record Bin;
        PickBin: Record Bin;
        BinContent: Record "Bin Content";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LocationCode: Code[10];
        ItemNo: Code[20];
        MinQty: Integer;
        LotNo: array[4] of Code[50];
        ExpirationDate: array[4] of Date;
        Qty: array[4] of Integer;
        Index: Integer;
    begin
        // [SCENARIO 472665] DP&P Location and we allow you to change the Place line of a Put away into a "Receive" Bin Type. Now you cannot pick from it or move it via reclass or movement.

        // [GIVEN] Initialize Setup, create Location, and sete initial values for Quantity, Lot, and Expiration Date
        Initialize();
        LocationCode := CreateFullWMSLocation(1, true);
        InitQtys(MinQty, Qty, 2, 2, 10, 6);
        for Index := 1 to ArrayLen(LotNo) do begin
            LotNo[Index] := LibraryUtility.GenerateGUID();
            ExpirationDate[Index] := CalcDate(StrSubstNo('<%1M>', Index), WorkDate());
        end;

        // [GIVEN] Item had Item Tracking Code with Lot Tracking and Man. Expir. Date Entry Reqd.
        ItemNo := CreateItemWithItemTrackingCode(true, true, false, false, true);

        // [GIVEN] Pick Bin and 3 Put-away Bins "B1", "B2" and "B3", Bin Ranking was higher for Pick Bin
        // [GIVEN] Fixed Bin Content for Pick Bin with the Item, Min Qty = 10, Max Qty = 30
        LibraryWarehouse.FindBin(PutAwayBin, LocationCode, FindZone(LocationCode, FindBinType(false, false, false, true)), 1);
        LibraryWarehouse.CreateNumberOfBins(LocationCode, PutAwayBin."Zone Code", PutAwayBin."Bin Type Code", 2, false);
        LibraryWarehouse.FindBin(PickBin, LocationCode, FindZone(LocationCode, FindBinType(false, false, false, true)), 1);
        SetBinRanking(PickBin, PutAwayBin."Bin Ranking" + LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateBinContent(
          BinContent, LocationCode, PickBin."Zone Code", PickBin.Code, ItemNo, '', GetItemBaseUoM(ItemNo));
        UpdateBinContentForReplenishment(BinContent, MinQty, 3 * MinQty, PickBin."Bin Ranking", PickBin."Bin Type Code");

        // [THEN] Released Purchase Order with Item Tracking
        CreatePurchaseOrderWithLocationAndItem(PurchaseHeader, LocationCode, ItemNo, 2 * MinQty);
        PrepareItemTrackingLinesPurchase(PurchaseHeader, LotNo, ExpirationDate, Qty);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Posted Whse Receipt
        PostWhseReceipt(PurchaseHeader);

        // [THEN] Find PutAway, Bin, Warehouse Activity Line, and Update Zone Code
        FindPutAway(WarehouseActivityHeader, ItemNo);
        FilterWhseActivityLines(WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place);
        LibraryWarehouse.FindBin(PutAwayBin, LocationCode, PutAwayBin."Zone Code", 0);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Zone Code", PutAwayBin."Zone Code");

        // [Verify] Error should occur while validating Bin Code for Put-away Place Lines
        asserterror WarehouseActivityLine.Validate("Bin Code", PutAwayBin.Code);
    end;

    [Test]
    procedure CalculateBinReplenishmentInMovementWorksheetForMaxQtyOfFixedBinContent()
    var
        Item: Record Item;
        PutAwayBin: Record Bin;
        PutPickBin: Record Bin;
        BinContent: Record "Bin Content";
        BinContentFilter: Record "Bin Content";
        LocationCode: Code[10];
        ItemNo: Code[20];
        MinQty: Decimal;
    begin
        // [SCENARIO 561988] When Calculate Bin Replenishment in Movement Worksheet then Qty should be less than "Max. Qty" of Fixed Bin Content
        Initialize();

        // [GIVEN] Create Item 
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Generate Random Min Qty
        MinQty := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Location with with Put Pick Bin and Put-away Bin, Bin Ranking is higher for Pick Bin
        LocationCode := CreateFullWMSLocation(1, false);
        LibraryWarehouse.FindBin(PutPickBin, LocationCode, FindZone(LocationCode, FindBinType(true, true, false, false)), 1);
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, PutPickBin."Zone Code", PutPickBin.Code, ItemNo, '', GetItemBaseUoM(ItemNo));
        UpdateBinContentForReplenishmentWithFixedBin(BinContent, MinQty, 2 * MinQty, LibraryRandom.RandIntInRange(11, 20));

        // [GIVEN] Bin Content for Put-away Bin
        LibraryWarehouse.FindBin(PutAwayBin, LocationCode, FindZone(LocationCode, FindBinType(false, true, false, false)), 1);
        LibraryWarehouse.CreateBinContent(
          BinContent, LocationCode, PutAwayBin."Zone Code", PutAwayBin.Code, ItemNo, '', GetItemBaseUoM(ItemNo));
        UpdateBinContentForReplenishmentWithFixedBin(BinContent, 0, 0, LibraryRandom.RandIntInRange(1, 10));

        // [GIVEN] Create and Post Two Positive Adjustment for Item
        Item.Get(ItemNo);
        CreateAndPostTwoPositiveAdjustmt(Item, LocationCode, PutAwayBin.Code, PutPickBin.Code, 5 * MinQty, LibraryRandom.RandIntInRange(1, 2));

        // [GIVEN] Calculate Bin Replenishment
        BinContentFilter.SetRange("Item No.", ItemNo);
        CalculateBinReplenishmentWithDialog(BinContentFilter, LocationCode);

        // [WHEN] Calculate Bin Replenishment again
        asserterror CalculateBinReplenishmentWithDialog(BinContentFilter, LocationCode);

        // [THEN] Error should occur while calculating Bin Replenishment
        Assert.ExpectedError(NothingToReplenishErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM - Movement");

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
    end;

    local procedure InitQtys(var MinQty: Integer; var Qty: array[4] of Integer; Qty1: Integer; Qty2: Integer; Qty3: Integer; Qty4: Integer)
    var
        Index: Integer;
    begin
        Qty[1] := Qty1;
        Qty[2] := Qty2;
        Qty[3] := Qty3;
        Qty[4] := Qty4;
        MinQty := 0;
        for Index := 1 to ArrayLen(Qty) do
            MinQty += Qty[Index];
        MinQty := MinQty / 2;
    end;

    procedure CreateEmptyMovementWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        LibraryWarehouse.CreateWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, WhseWorksheetName."Location Code",
          "Warehouse Worksheet Template Type"::"Put-away");
    end;

    local procedure PrepareItemTrackingLinesPurchase(var PurchaseHeader: Record "Purchase Header"; LotNo: array[4] of Code[50]; ExpirationDate: array[4] of Date; Qty: array[4] of Integer)
    var
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Index: Integer;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();

        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(Qty[Index]);
        end;
        PurchaseLine.OpenItemTrackingLines();
        LibraryVariableStorage.AssertEmpty();

        for Index := 1 to ArrayLen(LotNo) do begin
            ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
            ReservationEntry.SetRange("Source ID", PurchaseLine."Document No.");
            ReservationEntry.SetRange("Item No.", PurchaseLine."No.");
            ReservationEntry.SetRange("Lot No.", LotNo[Index]);
            ReservationEntry.FindFirst();
            ReservationEntry."Expiration Date" := ExpirationDate[Index];
            ReservationEntry.Modify();
        end;
    end;

    local procedure PrepareItemTrackingLineSales(var SalesHeader: Record "Sales Header"; LotNo: Code[50]; Qty: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.OpenItemTrackingLines();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateItemWithItemTrackingCode(LotTracking: Boolean; LotWhseTracking: Boolean; PackageTracking: Boolean; PackageWhseTracking: Boolean; ExpirationDateRequired: Boolean): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", LotTracking);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LotWhseTracking);
        ItemTrackingCode.Validate("Package Specific Tracking", PackageTracking);
        ItemTrackingCode.Validate("Package Warehouse Tracking", PackageWhseTracking);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ExpirationDateRequired);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateFullWMSLocation(Bins: Integer; PickAccordingToFEFO: Boolean): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateFullWMSLocation(Location, Bins);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        Location.Validate("Pick According to FEFO", PickAccordingToFEFO);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateLocationWithBinMandatory(var Location: Record Location; BinMandatory: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, false, false, false, false);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreatePurchaseOrderWithLocationAndItem(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreateSalesOrderWithLocationAndItem(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreateMovementFromMovementWorksheet()
    var
        DummyWhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
    begin
        WhseSourceCreateDocument.SetWhseWkshLine(DummyWhseWorksheetLine);
        WhseSourceCreateDocument.UseRequestPage(false);
        WhseSourceCreateDocument.Run();
    end;

    local procedure PostWhseReceipt(PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
            DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure RegisterPick(SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", SalesLine."Line No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure CalculateBinReplenishment(BinContent: Record "Bin Content"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        LibraryWarehouse.CalculateBinReplenishment(BinContent, WhseWorksheetName, LocationCode, true, true, false);
    end;

    local procedure SetBinRanking(var Bin: Record Bin; BinRanking: Integer)
    begin
        Bin.Validate("Bin Ranking", BinRanking);
        Bin.Modify(true);
    end;

    local procedure UpdateBinContentQty(var BinContent: Record "Bin Content"; Qty: Decimal)
    begin
        BinContent.Validate(Quantity, Qty);
        BinContent.Validate("Quantity (Base)", Qty);
        BinContent.Modify(true);
    end;

    local procedure UpdateBinContentForReplenishment(var BinContent: Record "Bin Content"; MinQty: Decimal; MaxQty: Decimal; BinRanking: Integer; BinTypeCode: Code[10])
    begin
        BinContent.Validate(Fixed, true);
        BinContent.Validate(Default, true);
        BinContent.Validate("Min. Qty.", MinQty);
        BinContent.Validate("Max. Qty.", MaxQty);
        BinContent.Validate("Bin Ranking", BinRanking);
        BinContent.Validate("Bin Type Code", BinTypeCode);
        BinContent.Modify(true);
    end;

    local procedure UpdateInventoryInBin(ItemNo: Code[20]; Bin: Record Bin)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, ItemNo, Bin."Location Code", Bin.Code, LibraryRandom.RandIntInRange(50, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateExpirationDateOnWhseItemTrackingLine(ItemNo: Code[20]; LotNo: Code[20]; ExpirationDate: Date)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.SetRange("Item No.", ItemNo);
        WhseItemTrackingLine.SetRange("Lot No.", LotNo);
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine."Expiration Date" := ExpirationDate;
        WhseItemTrackingLine.Modify();
    end;

    local procedure CreateAndPostWhseItemJournalLine(Bin: Record Bin; ItemNo: Code[20]; LotNo: Code[20]; ExpirationDate: Date; Qty: Decimal)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          Bin."Location Code", Bin."Zone Code", Bin.Code,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);

        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        WarehouseJournalLine.OpenItemTrackingLines();
        UpdateExpirationDateOnWhseItemTrackingLine(ItemNo, LotNo, ExpirationDate);

        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
    end;

    local procedure FilterWhseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
    end;

    local procedure FindPutAway(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ItemNo: Code[20])
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptLine.SetRange("Item No.", ItemNo);
        PostedWhseReceiptLine.FindFirst();
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, PostedWhseReceiptLine."Source Type", PostedWhseReceiptLine."Source Subtype",
          PostedWhseReceiptLine."Source No.", PostedWhseReceiptLine."Source Line No.");
    end;

    local procedure FindMovement(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ItemNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure FindBinType(IsPick: Boolean; IsPutAway: Boolean; IsShip: Boolean; IsReceive: Boolean): Code[10]
    var
        BinType: Record "Bin Type";
    begin
        BinType.SetRange(Pick, IsPick);
        BinType.SetRange("Put Away", IsPutAway);
        BinType.SetRange(Ship, IsShip);
        BinType.SetRange(Receive, IsReceive);
        BinType.FindFirst();
        exit(BinType.Code);
    end;

    local procedure FindZone(LocationCode: Code[10]; BinTypeCode: Code[10]): Code[10]
    var
        Zone: Record Zone;
    begin
        LibraryWarehouse.FindZone(Zone, LocationCode, BinTypeCode, false);
        exit(Zone.Code);
    end;

    local procedure GetItemBaseUoM(ItemNo: Code[20]): Code[10]
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        exit(Item."Base Unit of Measure");
    end;

    local procedure UpdateBinContentForReplenishmentWithFixedBin(var BinContent: Record "Bin Content"; MinQty: Decimal; MaxQty: Decimal; BinRanking: Integer)
    begin
        BinContent.Validate(Fixed, true);
        BinContent.Validate("Min. Qty.", MinQty);
        BinContent.Validate("Max. Qty.", MaxQty);
        BinContent.Validate("Bin Ranking", BinRanking);
        BinContent.Modify(true);
    end;

    local procedure CalculateBinReplenishmentWithDialog(BinContent: Record "Bin Content"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        LibraryWarehouse.CalculateBinReplenishment(BinContent, WhseWorksheetName, LocationCode, true, false, false);
    end;

    local procedure CreateAndPostTwoPositiveAdjustmt(Item: Record Item; LocationCode: Code[10]; BinCode1: Code[20]; BinCode2: Code[20]; Qty1: Decimal; Qty2: Decimal)
    var
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WhseJournalTemplate: Record "Warehouse Journal Template";
        WhseJournalBatch: Record "Warehouse Journal Batch";
    begin
        FindItemJournal(ItemJournalTemplate, ItemJournalBatch);
        Location.Get(LocationCode);
        LibraryWarehouse.WarehouseJournalSetup(LocationCode, WhseJournalTemplate, WhseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
            WarehouseJournalLine, WhseJournalTemplate.Name,
            WhseJournalBatch.Name, LocationCode, '',
            BinCode1, WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
            Item."No.", Qty1);
        LibraryWarehouse.CreateWhseJournalLine(
            WarehouseJournalLine, WhseJournalTemplate.Name,
            WhseJournalBatch.Name, LocationCode, '',
            BinCode2, WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
            Item."No.", Qty2);
        LibraryWarehouse.PostWhseJournalLine(WhseJournalTemplate.Name, WhseJournalBatch.Name, LocationCode);
        Item.SetRange("Location Filter", LocationCode);
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure FindItemJournal(var ItemJournalTemplate: Record "Item Journal Template"; var ItemJournalBatch: Record "Item Journal Batch")
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandlerMultipleEntries(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Index: Integer;
    begin
        ItemTrackingLines.First();
        for Index := 1 to LibraryVariableStorage.DequeueInteger() do begin
            ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
            ItemTrackingLines.Next();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesModalPageHandlerLotMultipleEntries(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        Index: Integer;
    begin
        WhseItemTrackingLines.First();
        for Index := 1 to LibraryVariableStorage.DequeueInteger() do begin
            WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
            WhseItemTrackingLines.Next();
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesModalPageHandlerPackageMultipleEntries(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        Index: Integer;
    begin
        WhseItemTrackingLines.First();
        for Index := 1 to LibraryVariableStorage.DequeueInteger() do begin
            WhseItemTrackingLines."Package No.".SetValue(LibraryVariableStorage.DequeueText());
            WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
            WhseItemTrackingLines.Next();
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure BinListModalPageHandler(var BinList: TestPage "Bin List")
    begin
        BinList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        BinList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure BinContentsListModalPageHandler(var BinContentsList: TestPage "Bin Contents List")
    begin
        BinContentsList.FILTER.SetFilter("Bin Code", LibraryVariableStorage.DequeueText());
        BinContentsList.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

