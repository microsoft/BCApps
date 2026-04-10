codeunit 137501 "SCM Available to Pick UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        TooManyPickLinesErr: Label 'There were too many pick lines generated.';
        DifferentQtyErr: Label 'Quantity on pick line different from quantity on shipment line.';
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NothingToHandleErr: Label 'Nothing to handle.';
        NothingToCreateErr: Label 'There is nothing to create.';
        InvtPutAwayMsg: Label 'Number of Invt. Put-away activities created: 1 out of a total of 1.';
        InvtPickMsg: Label 'Number of Invt. Pick activities created: 1 out of a total of 1.';
        MissingExpectedErr: Label 'Unexpected message: %1';
        LibraryRandom: Codeunit "Library - Random";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        OverStockErr: Label 'item no. %1 is not available';
        NoActiveProductionBOMVersionFoundErr: Label 'There is no active Production BOM for the item %1.', Comment = '%1 - Item No.';
        BlockMovementGlobal: Option " ",Inbound,Outbound,All;
        BinCodeDictionary: Dictionary of [Text, List of [Code[20]]];
        PickableQtyErr: Label '%1 must be %2 in %3.', Comment = '%1= Field Name,%2= Field Value,%3= Page Caption.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Available to Pick UT");
        // Initialize setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Available to Pick UT");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        // Setup Demonstration data.
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Available to Pick UT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectedPutawayAndPickPositive()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        DirectedPutawayAndPick(TestType::Positive);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectedPutawayAndPickNegative()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        DirectedPutawayAndPick(TestType::Negative);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectedPutawayAndPickPartial()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        DirectedPutawayAndPick(TestType::Partial);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickSimpleScenarioFullPickSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Qty: Decimal;
    begin
        // [SCENARIO 359031] Directed Put-away and Pick simple scenario, complete warehouse pick
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Qty := 5;
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", Qty, '', '');

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", Qty, Qty);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Qty, Qty, Qty, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Qty);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Qty);
    end;

    local procedure DirectedPutAwayPickSimpleScenarioPartialPickSummaryPageScenario(IsCrossDock: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Qty: Decimal;
        RegisteredQty: Decimal;
    begin
        // [SCENARIO 359031] Directed put-away and Pick, partial quantity in pick bin, partial warehouse pick
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 1);
        if IsCrossDock then begin
            Location.Validate("Use Cross-Docking", true);
            Location.Modify();
        end;

        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Qty := 5;
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        RegisteredQty := Qty - 2;
        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", RegisteredQty, '', '');

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", Qty, RegisteredQty);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, RegisteredQty, RegisteredQty, Qty, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", RegisteredQty);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", RegisteredQty);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickSimpleScenarioPartialPickSummaryPage()
    begin
        DirectedPutAwayPickSimpleScenarioPartialPickSummaryPageScenario(false); //Not cross-dock
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickSimpleScenarioPartialPickSummaryPageCrossDock()
    begin
        DirectedPutAwayPickSimpleScenarioPartialPickSummaryPageScenario(true); //Cross-dock
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickAllMoveOrOutboundBlockedForBinNoPicksCreatedSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantities: List of [Decimal];
        PickBinCode: List of [Code[20]];
        EmptyTakeBinCode: List of [Code[20]];
    begin
        // [SCENARIO 359031] Directed Put-away and Pick, Bin blocked for all movement and block outbound movement. This leads to no warehouse pick creation.
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Quantities.Add(5);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantities.Get(1));
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        BinCodeDictionary.Get('PICK', PickBinCode);
        SetEmptyBinCodeList(EmptyTakeBinCode, PickBinCode.Count);

        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantities, EmptyTakeBinCode, PickBinCode);

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantities.Get(1));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Block bin for all movement or outbound movement randomly
        SetBinContentBlocked(PickBinCode.Get(1), Location.Code, Item."No.", LibraryRandom.RandIntInRange(2, 3));

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryNothingToHandleMsg(WarehousePickSummaryTestPage);

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", Quantities.Get(1), 0);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, 0, 0, Quantities.Get(1), 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickPartialOutboundBlockedForBinPartialPicksCreatedSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantities: List of [Decimal];
        PickBinCode: List of [Code[20]];
        EmptyTakeBinCode: List of [Code[20]];
    begin
        // [SCENARIO 359031] Directed Put-away and Pick with partial qty. blocked in the pick bins. This leads to partial warehouse pick creation.
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 2);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Quantities.Add(3);
        Quantities.Add(2);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantities.Get(1));
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantities.Get(2));
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        BinCodeDictionary.Get('PICK', PickBinCode);
        SetEmptyBinCodeList(EmptyTakeBinCode, PickBinCode.Count);

        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantities, EmptyTakeBinCode, PickBinCode);

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantities.Get(1) + Quantities.Get(2));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Block Bin 1 for outbound
        SetBinContentBlocked(PickBinCode.Get(1), Location.Code, Item."No.", BlockMovementGlobal::Outbound);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", Quantities.Get(1) + Quantities.Get(2), Quantities.Get(2)); //Bin 1 is blocked for outbound, i.e. Quantities[1] is blocked
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantities.Get(2), Quantities.Get(2), Quantities.Get(1) + Quantities.Get(2), 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Quantities.Get(2));
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Quantities.Get(2));
    end;

    [Test]
    [HandlerFunctions('VerifyMessageHandler')]
    procedure DirectedPutAwayPickErrorOnCreatingPicksForCompletelyPickedSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] [BUG 482628] Directed Put-away and Pick completely picked shipment lines. This leads to an error when creating warehouse pick.
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 2);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Quantity := 5;

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantity, '', '');

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);

        // [GIVEN] Register Warehouse Pick
        RegisterWhseActivity(WhseActivityLine."Activity Type"::Pick, Database::"Sales Line", WhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Quantity, '', '');

        // [WHEN] Create warehouse pick for the same document again
        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        LibraryVariableStorage.Enqueue('Nothing to handle. The quantity on the shipment lines are completely picked.');
        CreateWhsePickFromShipment(WhseShipmentHeader);

        // [THEN] Message is shown explaining that all the lines are completely picked
        // VerifyMessageHandler will verify the message
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler,VerifyDrillDownPickWorksheetModalPageHandler')]
    procedure DirectedPutAwayPickWorksheetBatchIsShownInSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item1: Record Item;
        Item2: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity1: Decimal;
        Quantity2: Decimal;
    begin
        // [SCENARIO 359031] [BUG 482628] Directed Put-away and Pick, calculation summary shows the lines present in the pick worksheet
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateItem(Item2);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Quantity1 := 3;
        Quantity2 := 8;

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item1."No.", Quantity1);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item2."No.", Quantity2);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity to make the quantity available in the pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // [GIVEN] Warehouse shipment for the Sales order with two sales in with qty. available in the pick bins
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader, SalesLine1.Type::Item, Item1."No.", Quantity1);
        SalesLine1.Validate("Location Code", Location.Code);
        SalesLine1.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, Item2."No.", Quantity2);
        SalesLine2.Validate("Location Code", Location.Code);
        SalesLine2.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Release the warehouse shipment
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");

        LibraryWarehouse.ReleaseWarehouseShipment(WhseShipmentHeader);

        // [GIVEN] Add the shipment lines to the pick worksheet.
        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Shipment, 0, WhseShipmentHeader."No.", WhseShipmentHeader."Location Code");
        LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWorksheetLine, WhsePickRequest, WhseShipmentHeader."Location Code");
        Assert.RecordCount(WhseWorksheetLine, 2);
        WhseWorksheetLine.FindSet();
        WhseWorksheetLine.Delete();
        WhseWorksheetLine.Next();
        Commit();

        // [WHEN] Create warehouse pick and show calculation summary.
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();
        WhseShipmentHeader.Get(WhseShipmentLine."No.");

        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine1."Line No.", Item1."No.", Quantity1, Quantity1);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity1, Quantity1, Quantity1, 0, 0, 0, 0, 0, 0, 0, 0);

        WarehousePickSummaryTestPage.Next();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine2."Line No.", Item2."No.", Quantity2, 0);
        CheckWhseSummaryFactBoxValuesForPickWorksheet(WarehousePickSummaryTestPage, WhseWorksheetLine.Name);

        // [WHEN] Drill Down to the pick worksheet
        LibraryVariableStorage.Enqueue(WhseWorksheetLine.Name);
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Location Code");
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Whse. Document No.");
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Whse. Document Type");
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Item No.");

        WarehousePickSummaryTestPage.SummaryPart."Worksheet Batch Name".Drilldown();

        // [THEN] Verify the information in VerifyDrillDownPickWorksheetModalPageHandler
        Assert.AreEqual(Item2."No.", WhseWorksheetLine."Item No.", 'Item No. in the pick worksheet line is not as expected.');
        WarehousePickSummaryTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseDoNotShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickCreatePickErrorsHintsUserToUseCalcSummary()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] [BUG 482628] Directed Put-away and Pick, show error message and hint the user to use Show Summary Page option
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item NOT available in pick bin
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(Item);

        Quantity := 5;

        // [GIVEN] Warehouse shipment for the Sales order with two sales in with qty. available in the pick bins
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick without the Show Summary Page option
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();
        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        asserterror CreateWhsePickFromShipment(WhseShipmentHeader); //CreatePickFromWhseDoNotShowCalcSummaryShptReqHandler is used to not show the summary page.

        // [THEN] Error message is shown and hinting the user to use Show Summary Page option
        Assert.ExpectedError('Nothing to handle.\Try the "Show Summary (Directed Put-away and Pick)" option when creating pick to inspect the error.');
    end;

    [Test]
    [HandlerFunctions('CreatePickFromProdOrderShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickProdOrderErrorOnCreatingPicksForCompletelyPickedSummaryPage()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        ProdParent: Record Item;
        ProdChild: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Location: Record Location;
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] [BUG 482628] Directed Put-away and Pick completely picked production order components. This leads to an error when creating warehouse pick.
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Production BOM item available in pick bin
        SetupLocationWithBins(Location, 1);
        Quantity := 1;
        SetupProductionOrderScenario(ProdChild, ProdParent, Enum::"Flushing Method"::"Pick + Manual", Quantity, Location);

        // [GIVEN] Released production order with qty. available in pick bin for ProdParent
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, Enum::"Production Order Status"::Released, Enum::"Prod. Order Source Type"::Item, ProdParent."No.", Quantity);
        ProdOrderLine.SetRange(Status, Enum::"Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Location Code", Location.Code);
        ProdOrderLine.Modify();

        ProdOrderComponent.SetRange(Status, Enum::"Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Modify();

        // [GIVEN] Create warehouse pick
        CreateWhsePickAndTrapSummary(ProductionOrder, WarehousePickSummaryTestPage); //CreatePickFromProdOrderShowCalcSummaryShptReqHandler will show calculation summary page.
        WarehousePickSummaryTestPage.Close();

        // [GIVEN] Register Warehouse Pick
        RegisterWhseActivity(WhseActivityLine."Activity Type"::Pick, Database::"Prod. Order Component", WhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.");

        // [WHEN] Create warehouse pick for the same document again
        asserterror ProductionOrder.CreatePick('', 0, false, false, false);

        // [THEN] Error is shown explaining that all the lines are completely picked
        Assert.ExpectedError('Nothing to handle. The production components are completely picked or not eligible for picking.');
    end;

    [Test]
    [HandlerFunctions('CreatePickFromProdOrderShowCalcSummaryShptReqHandler,VerifyDrillDownPickWorksheetModalPageHandler')]
    procedure DirectedPutAwayPickProdOrderWorksheetBatchIsShownInSummaryPage()
    var
        ProdParent: Record Item;
        ProdChild: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Location: Record Location;
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] [BUG 482628] Directed Put-away and Pick, calculation summary shows the lines present in the pick worksheet for production order
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        Quantity := 1;
        SetupLocationWithBins(Location, 1);
        SetupProductionOrderScenario(ProdChild, ProdParent, Enum::"Flushing Method"::"Pick + Manual", Quantity, Location);

        // [GIVEN] Released production order with qty. available in pick bin for ProdParent
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, Enum::"Production Order Status"::Released, Enum::"Prod. Order Source Type"::Item, ProdParent."No.", 1);
        ProdOrderLine.SetRange(Status, Enum::"Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Location Code", Location.Code);
        ProdOrderLine.Modify();

        ProdOrderComponent.SetRange(Status, Enum::"Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Modify();

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, false, false, false); //Create the warehouse pick request

        // [GIVEN] Add the production order to the pick worksheet.
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Production, ProductionOrder.Status, ProductionOrder."No.", Location.Code);
        LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWorksheetLine, WhsePickRequest, Location.Code);
        Assert.RecordCount(WhseWorksheetLine, 1);
        WhseWorksheetLine.FindFirst();

        // [WHEN] Create warehouse pick and show calculation summary.
        CreateWhsePickAndTrapSummary(ProductionOrder, WarehousePickSummaryTestPage); //CreatePickFromProdOrderShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Prod. Consumption", ProductionOrder."No.", ProdOrderLine."Line No.", ProdOrderComponent."Item No.", Quantity, 0);
        CheckWhseSummaryFactBoxValuesForPickWorksheet(WarehousePickSummaryTestPage, WhseWorksheetLine.Name);

        // [WHEN] Drill Down to the pick worksheet
        LibraryVariableStorage.Enqueue(WhseWorksheetLine.Name);
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Location Code");
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Whse. Document No.");
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Whse. Document Type");
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Item No.");

        WarehousePickSummaryTestPage.SummaryPart."Worksheet Batch Name".Drilldown();

        // [THEN] Verify the information in VerifyDrillDownPickWorksheetModalPageHandler
        Assert.AreEqual(ProdOrderComponent."Item No.", WhseWorksheetLine."Item No.", 'Item No. in the pick worksheet line is not as expected.');
        WarehousePickSummaryTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('CreatePickFromPrdOrderDoNotShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickProdOrderCreatePickErrorsHintsUserToUseCalcSummary()
    var
        ProdParent: Record Item;
        ProdChild: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Location: Record Location;
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] [BUG 482628] Directed Put-away and Pick, show error message and hint the user to use Show Summary Page option for production order
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item NOT available in pick bin
        Quantity := 1;
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(ProdChild);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProdBOMHeader, ProdChild."No.", Quantity);
        LibraryManufacturing.CreateItemManufacturing(ProdParent, Enum::"Costing Method"::Standard, 1000, Enum::"Reordering Policy"::" ", Enum::"Flushing Method"::"Pick + Manual", '', ProdBOMHeader."No.");

        // [GIVEN] Released production order
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, Enum::"Production Order Status"::Released, Enum::"Prod. Order Source Type"::Item, ProdParent."No.", 1);
        ProdOrderLine.SetRange(Status, Enum::"Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Location Code", Location.Code);
        ProdOrderLine.Modify();

        ProdOrderComponent.SetRange(Status, Enum::"Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Modify();

        // [WHEN] Create warehouse pick without the Show Summary Page option
        asserterror ProductionOrder.CreatePick('', 0, false, false, false); //Requires a request page handler CreatePickFromPrdOrderDoNotShowCalcSummaryShptReqHandler to not show the summary page

        // [THEN] Error message is shown and hinting the user to use Show Summary Page option
        Assert.ExpectedError('Nothing to handle.\Try the "Show Summary (Directed Put-away and Pick)" option when creating pick to inspect the error.');
    end;

    [Test]
    [HandlerFunctions('CreatePickFromAsmOrderShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickAsmOrderErrorOnCreatingPicksForCompletelyPickedSummaryPage()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        AsmParent: Record Item;
        AsmChild: Record Item;
        AsmHeader: Record "Assembly Header";
        Location: Record Location;
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] [BUG 482628] Directed Put-away and Pick completely picked assembly line items. This leads to an error when creating warehouse pick.
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Assemble to order item available in pick bin
        SetupLocationWithBins(Location, 1);
        Quantity := 1;
        SetupAssemblyOrderScenario(AsmChild, AsmParent, Enum::"Costing Method"::FIFO, Enum::"Replenishment System"::Assembly, Enum::"Assembly Policy"::"Assemble-to-Stock", Quantity, Location);

        // [GIVEN] Released assembly order with qty. available in pick bin
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate() + 100, AsmParent."No.", Location.Code, Quantity, '');
        LibraryAssembly.ReleaseAO(AsmHeader);

        // [GIVEN] Create warehouse pick
        CreateWhsePickAndTrapSummary(AsmHeader, WarehousePickSummaryTestPage); //CreatePickFromAsmOrderShowCalcSummaryShptReqHandler will show calculation summary page.
        WarehousePickSummaryTestPage.Close();

        // [GIVEN] Register Warehouse Pick
        RegisterWhseActivity(WhseActivityLine."Activity Type"::Pick, Database::"Assembly Line", WhseActivityLine."Source Document"::"Assembly Consumption", AsmHeader."No.");

        // [WHEN] Create warehouse pick for the same document again
        asserterror AsmHeader.CreatePick(false, '', 0, false, false, false);

        // [THEN] Error is shown explaining that all the lines are completely picked
        Assert.ExpectedError('Nothing to handle. The assembly line items are completely picked.');
    end;

    [Test]
    [HandlerFunctions('CreatePickFromAsmOrderShowCalcSummaryShptReqHandler,VerifyDrillDownPickWorksheetModalPageHandler')]
    procedure DirectedPutAwayPickAsmOrderWorksheetBatchIsShownInSummaryPage()
    var
        AsmParent: Record Item;
        AsmChild: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        Location: Record Location;
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] [BUG 482628] Directed Put-away and Pick, calculation summary shows the lines present in the pick worksheet for assembly order
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        Quantity := 1;
        SetupLocationWithBins(Location, 1);
        SetupAssemblyOrderScenario(AsmChild, AsmParent, Enum::"Costing Method"::FIFO, Enum::"Replenishment System"::Assembly, Enum::"Assembly Policy"::"Assemble-to-Stock", Quantity, Location);

        // [GIVEN] Released assembly order with qty. available in pick bin
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate() + 100, AsmParent."No.", Location.Code, Quantity, '');
        LibraryAssembly.ReleaseAO(AsmHeader);

        // [GIVEN] Add the assembly lines to the pick worksheet.
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Assembly, AsmHeader.Status, AsmHeader."No.", Location.Code);
        LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWorksheetLine, WhsePickRequest, Location.Code);
        Assert.RecordCount(WhseWorksheetLine, 1);
        WhseWorksheetLine.FindFirst();

        // [WHEN] Create warehouse pick and show calculation summary.
        CreateWhsePickAndTrapSummary(AsmHeader, WarehousePickSummaryTestPage); //CreatePickFromAsmOrderShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();
        AsmLine.SetRange("Document Type", AsmLine."Document Type"::Order);
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindFirst();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Assembly Consumption", AsmHeader."No.", AsmLine."Line No.", AsmChild."No.", Quantity, 0);
        CheckWhseSummaryFactBoxValuesForPickWorksheet(WarehousePickSummaryTestPage, WhseWorksheetLine.Name);

        // [WHEN] Drill Down to the pick worksheet
        LibraryVariableStorage.Enqueue(WhseWorksheetLine.Name);
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Location Code");
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Whse. Document No.");
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Whse. Document Type");
        LibraryVariableStorage.Enqueue(WhseWorksheetLine."Item No.");

        WarehousePickSummaryTestPage.SummaryPart."Worksheet Batch Name".Drilldown();

        // [THEN] Verify the information in VerifyDrillDownPickWorksheetModalPageHandler
        Assert.AreEqual(AsmLine."No.", WhseWorksheetLine."Item No.", 'Item No. in the pick worksheet line is not as expected.');
        WarehousePickSummaryTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('CreatePickFromAsmOrderDoNotShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickAsmOrderCreatePickErrorsHintsUserToUseCalcSummary()
    var
        AsmParent: Record Item;
        AsmChild: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        Location: Record Location;
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] [BUG 482628] Directed Put-away and Pick, show error message and hint the user to use Show Summary Page option for assembly order
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item NOT available in pick bin
        Quantity := 1;
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(AsmChild);
        LibraryInventory.CreateItem(AsmParent);

        // [GIVEN] Released assembly order
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate() + 100, AsmParent."No.", Location.Code, Quantity, '');
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, Enum::"BOM Component Type"::Item, AsmChild."No.", AsmChild."Base Unit of Measure", Quantity, Quantity, '');
        LibraryAssembly.ReleaseAO(AsmHeader);

        // [WHEN] Create warehouse pick without the Show Summary Page option
        asserterror AsmHeader.CreatePick(true, '', 0, false, false, false); //Requires a request page handler CreatePickFromAsmOrderDoNotShowCalcSummaryShptReqHandler to not show the summary page

        // [THEN] Error message is shown and hinting the user to use Show Summary Page option
        Assert.ExpectedError('Nothing to handle.\Try the "Show Summary (Directed Put-away and Pick)" option when creating pick to inspect the error.');
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickReceiveBinBlockedPickBinAvailFullPicksCreatedSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
        ReceiveBin: Code[20];
    begin
        // [SCENARIO 359031] Directed Put-away and Pick, qty. blocked in the receive bin, some qty. available in the pick bin, partial warehouse pick
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Quantity := 1;

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity to make the quantity available in the pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantity, '', '');

        // [GIVEN] Post a warehouse receipt for second purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();
        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Block the RECEIPT bin
        ReceiveBin := FindReceiptBin(Location.Code, Item."No.");
        SetBinContentBlocked(ReceiveBin, Location.Code, Item."No.", BlockMovementGlobal::Outbound);

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity, Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickReservedAgainstPOPickBinAvailFullPicksCreatedSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] Directed Put-away and Pick, sales order qty. reserved against purchase order, qty. available in the pick bin, full warehouse pick
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Quantity := 1;

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity to make the quantity available in the pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantity, '', '');

        // [GIVEN] Create a second purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Create Sales Order and reserve it against the purchase order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Post a warehouse receipt for second purchase order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();
        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, true, Quantity, Quantity, Quantity + Quantity, 0, 0, 2, 1, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickPickBinAvailAndQtyInDedicatedBinFullPicksCreatedSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
        ReceiveBin: Code[20];
    begin
        // [SCENARIO 359031] Directed Put-away and Pick, qty. available in the pick bin, qty. is added to dedicated bin, full warehouse pick
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Quantity := 1;

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // Get the Receive bin code
        ReceiveBin := FindReceiptBin(Location.Code, Item."No.");

        // [GIVEN] Register a put-away activity to make the quantity available in the pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantity, '', '');

        // [GIVEN] Change the receipt bin code to dedicated
        SetBinAsDedicated(Location.Code, ReceiveBin);

        // [GIVEN] Create a second purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Post a warehouse receipt for second purchase order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();
        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity, Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickReservedAgainstDedicatedAndPickBinHalfPicksCreatedSummaryPage()
    begin
        DirectedPutAwayPickHalfPicksCreatedForReservationAgainstDedicatedOrBlockedBins(0);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickReservedAgainstBlockedAndPickBinHalfPicksCreatedSummaryPage()
    begin
        DirectedPutAwayPickHalfPicksCreatedForReservationAgainstDedicatedOrBlockedBins(1);
    end;

    local procedure DirectedPutAwayPickHalfPicksCreatedForReservationAgainstDedicatedOrBlockedBins(FirstBinOption: Option Dedicated,Blocked)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        PickBinCode: List of [Code[20]];
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] Directed Put-away and Pick, 2 sales order qty. reserved against quantity in Pickable bin and blocked pickable bin, warehouse pick created for sales order against pickable bin
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 2);
        LibraryInventory.CreateItem(Item);

        // Get the pick bin codes
        BinCodeDictionary.Get('PICK', PickBinCode);

        // [GIVEN] Make the bin dedicated or block it
        case FirstBinOption of
            FirstBinOption::Dedicated:
                SetBinAsDedicated(Location.Code, PickBinCode.Get(1));
            FirstBinOption::Blocked:
                SetBinAsBlocked(PickBinCode.Get(1), Location.Code, BlockMovementGlobal::Outbound);
        end;

        // [GIVEN] Create a purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Quantity := 2;

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity to make the quantity available in the blocked pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantity, '', PickBinCode.Get(1));

        // [GIVEN] Create a second purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Post a warehouse receipt for second purchase order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();
        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity to make the quantity available in the pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantity, '', PickBinCode.Get(2));

        // [GIVEN] Create Sales Order 1 and reserve it
        LibrarySales.CreateSalesHeader(SalesHeader1, SalesHeader1."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader1, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Create Sales Order 2 and reserve it
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader2, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Warehouse shipment for the Sales order 1 with qty. available in pick bin
        LibrarySales.ReleaseSalesDocument(SalesHeader1);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader1);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader1."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader1."No.", SalesLine."Line No.", Item."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, true, Quantity, Quantity, Quantity + Quantity, 0, 0, Quantity, Quantity, 0, Quantity, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created for the first sales order
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader1."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader1."No.", Quantity);

        // [GIVEN] Warehouse shipment for the Sales order 2 with qty. available in pick bin
        LibrarySales.ReleaseSalesDocument(SalesHeader2);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader2);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader2."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader2."No.", SalesLine."Line No.", Item."No.", Quantity, 0);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, 0, Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);

        // [THEN] Message contains the error related to insufficient quantity.
        Assert.AreEqual('Nothing to handle. The quantity to be picked is not in inventory yet. You must first post the supply from which the source document is reserved.', WarehousePickSummaryTestPage.Message.Value, 'Message on the summary page is not as expected');

        WarehousePickSummaryTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler,MessageHandler')]
    procedure DirectedPutAwayPickPickBinAvailAndQtyInShipBinFullPicksCreatedSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        PickBin: Record Bin;
        ShipBin: Record Bin;
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] Directed Put-away and Pick, qty. available in the pick bin, qty. on ship bins, full warehouse pick
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Quantity := 1;

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity to make the quantity available in the pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantity, '', '');

        // [GIVEN] Create a second purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Post a warehouse receipt for second purchase order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();
        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantity, '', '');

        // [GIVEN] Use movement worksheet to move the quantity to ship bin
        LibraryWarehouse.FindBin(PickBin, Location.Code, 'PICK', 0);
        LibraryWarehouse.FindBin(ShipBin, Location.Code, 'SHIP', 0);
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, PickBin, ShipBin, Item."No.", '', Quantity);
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", "Whse. Activity Sorting Method"::None, false, false); //MessageHandler is needed

        Clear(WhseActivityLine);
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Movement);
        WhseActivityLine.SetRange("Item No.", Item."No.");
        WhseActivityLine.SetRange("Location Code", Location.Code);
        WhseActivityLine.FindFirst();
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");

        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity, Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickAfterCompletePickShowsSummaryPageWithQtyToHandleAs0()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Qty: Decimal;
    begin
        // [SCENARIO 359031] [BUG 482122] [BUG 482628] Directed put-away and Pick, full warehouse pick done, create pick after should show the summary page
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Qty := 5;
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Qty, '', '');

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", Qty, Qty);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Qty, Qty, Qty, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Qty);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Qty);

        // [WHEN] Create warehouse pick for the same shipment again
        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage);

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", 0, 0);
        WarehousePickSummaryTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler,BinContentVerifyQuantityModalPageHandler')]
    procedure DirectedPutAwayPickPartialPickWithUoMBreakBulkSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        BaseQty: Decimal;
        UoMQty: Decimal;
        QtyPerUoM: Decimal;
        Quantities: List of [Decimal];
        EmptyBinCode: List of [Code[20]];
    begin
        // [SCENARIO 359031] [Bug 482615] Directed Put-away and Pick partial warehouse pick wit different unit of measure 
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled, Break bulk enabled
        // [GIVEN] 10 Box and 10 PCS of Item available in pick bin. 1 Box = 12 PCS.
        SetupLocationWithBins(Location, 1);
        Location.Validate("Allow Breakbulk", true);
        LibraryInventory.CreateItem(Item);
        QtyPerUoM := 12;
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", QtyPerUoM);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        BaseQty := 10;
        UoMQty := 10;
        Quantities.Add(BaseQty);
        Quantities.Add(UoMQty);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", BaseQty);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", UoMQty);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", ItemUOM.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        SetEmptyBinCodeList(EmptyBinCode, Quantities.Count);
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantities, EmptyBinCode, EmptyBinCode);

        // [GIVEN] Warehouse shipment for the Sales order with more than available qty. in pick bin (11 Boxes)
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", UoMQty + 1);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit of Measure Code", ItemUOM.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        // Base Unit of Measure is shown by default. 10 boxes and 10 PCS can be handled i.e. 130 PCS.
        WarehousePickSummaryTestPage.First();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", (UoMQty + 1) * QtyPerUoM, UoMQty * QtyPerUoM + BaseQty);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, UoMQty * QtyPerUoM + BaseQty, UoMQty * QtyPerUoM + BaseQty, UoMQty * QtyPerUoM + BaseQty, 0, UoMQty * QtyPerUoM, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, Database::"Sales Line", Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", 2, UoMQty * QtyPerUoM + BaseQty);
        CheckPick(Enum::"Warehouse Action Type"::Place, Database::"Sales Line", Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", 2, UoMQty * QtyPerUoM + BaseQty);

        // [WHEN] Create warehouse pick again
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        // Base Unit of Measure is shown by default. 2 PCS cannot be picked.
        WarehousePickSummaryTestPage.First();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", ((UoMQty + 1) * QtyPerUoM) - (UoMQty * QtyPerUoM + BaseQty), 0);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, 0, UoMQty * QtyPerUoM + BaseQty, UoMQty * QtyPerUoM + BaseQty, 0, 0, 0, 0, 0, 0, 0, 0);

        // [THEN] Drill Down on the Qty. in Pickable bin opens bin content with two lines one for PCS and other for BOX
        // BinContentVerifyQuantityModalPageHandler will verify that both quantities with different UoM is shown in the bin content page
        LibraryVariableStorage.Enqueue(BaseQty);
        LibraryVariableStorage.Enqueue(UoMQty * QtyPerUoM);
        WarehousePickSummaryTestPage.SummaryPart."Qty. in Pickable Bins".DrillDown();
        WarehousePickSummaryTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler,MessageHandler,ConfirmHandlerTrue')]
    procedure DirectedPutAwayPickAsmToOrderCompAvailInPickBinFullPicksCreatedSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        AsmParent: Record Item;
        AsmChild: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        PutAwayBin: Record Bin;
        PickBin: Record Bin;
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] Directed Put-away and Pick, Assemble-to-order, qty. available in the pick bin, full warehouse pick
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Assemble to order item available in pick bin
        SetupLocationWithBins(Location, 1);
        Quantity := 1;
        LibraryInventory.CreateItem(AsmChild);
        LibraryAssembly.CreateItem(AsmParent, Enum::"Costing Method"::FIFO, Enum::"Replenishment System"::Assembly, '', '');
        AsmParent.Validate("Assembly Policy", Enum::"Assembly Policy"::"Assemble-to-Order");
        AsmParent.Modify();

        LibraryAssembly.CreateAssemblyListComponent(Enum::"BOM Component Type"::Item, AsmChild."No.", AsmParent."No.", '', 0, Quantity, true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, AsmChild."No.", 2 * Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity to make the quantity available in the pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", 2 * Quantity, '', '');

        // [GIVEN] Update location To-Assembly bin to Put-away bin and From-Assembly bin to Pick bin
        LibraryWarehouse.FindBin(PutAwayBin, Location.Code, 'BULK', 1);
        Location.Validate("To-Assembly Bin Code", PutAwayBin.Code);

        LibraryWarehouse.FindBin(PickBin, Location.Code, 'PICK', 0);
        Location.Validate("From-Assembly Bin Code", PickBin.Code);

        Location.Modify();

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin for AsmParent
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmParent."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();
        SalesLine.AsmToOrderExists(AsmHeader);
        AsmLine.SetRange("Document Type", AsmLine."Document Type"::Order);
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindFirst();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Assembly Consumption", AsmHeader."No.", AsmLine."Line No.", AsmChild."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity + Quantity, Quantity + Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, Database::"Assembly Line", Enum::"Warehouse Activity Source Document"::"Assembly Consumption", AsmHeader."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, Database::"Assembly Line", Enum::"Warehouse Activity Source Document"::"Assembly Consumption", AsmHeader."No.", Quantity);

        // [GIVEN] Register the warehouse pick
        RegisterWhseActivity(WhseActivityLine."Activity Type"::Pick, Database::"Assembly Line", WhseActivityLine."Source Document"::"Assembly Consumption", AsmHeader."No.", 1, '', '');

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin for AsmChild
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmChild."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", AsmChild."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity, Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromAsmOrderShowCalcSummaryShptReqHandler,CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickAsmToStockCompAvailInPickBinFullPicksCreatedSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        AsmParent: Record Item;
        AsmChild: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        PutAwayBin: Record Bin;
        PickBin: Record Bin;
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] Directed Put-away and Pick, Assemble-to-stock, qty. available in the pick bin, full warehouse pick
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Assemble to stock item available in pick bin
        SetupLocationWithBins(Location, 1);
        Quantity := 1;
        LibraryInventory.CreateItem(AsmChild);
        LibraryAssembly.CreateItem(AsmParent, Enum::"Costing Method"::FIFO, Enum::"Replenishment System"::Assembly, '', '');
        AsmParent.Validate("Assembly Policy", Enum::"Assembly Policy"::"Assemble-to-Stock");
        AsmParent.Modify();

        LibraryAssembly.CreateAssemblyListComponent(Enum::"BOM Component Type"::Item, AsmChild."No.", AsmParent."No.", '', 0, Quantity, true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, AsmChild."No.", 2 * Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity to make the quantity available in the pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", 2 * Quantity, '', '');

        // [GIVEN] Update location To-Assembly bin to Put-away bin and From-Assembly bin to Pick bin
        LibraryWarehouse.FindBin(PutAwayBin, Location.Code, 'BULK', 1);
        Location.Validate("To-Assembly Bin Code", PutAwayBin.Code);

        LibraryWarehouse.FindBin(PickBin, Location.Code, 'PICK', 0);
        Location.Validate("From-Assembly Bin Code", PickBin.Code);

        Location.Modify();

        // [GIVEN] Warehouse shipment for the assembly order with qty. available in pick bin for AsmParent
        LibraryAssembly.CreateAssemblyHeader(AsmHeader, WorkDate() + 100, AsmParent."No.", Location.Code, Quantity, '');

        // [WHEN] Create warehouse pick
        LibraryAssembly.ReleaseAO(AsmHeader);
        CreateWhsePickAndTrapSummary(AsmHeader, WarehousePickSummaryTestPage); //CreatePickFromAsmOrderShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();
        AsmLine.SetRange("Document Type", AsmLine."Document Type"::Order);
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindFirst();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Assembly Consumption", AsmHeader."No.", AsmLine."Line No.", AsmChild."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity + Quantity, Quantity + Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, Database::"Assembly Line", Enum::"Warehouse Activity Source Document"::"Assembly Consumption", AsmHeader."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, Database::"Assembly Line", Enum::"Warehouse Activity Source Document"::"Assembly Consumption", AsmHeader."No.", Quantity);

        // [GIVEN] Register the warehouse pick
        RegisterWhseActivity(WhseActivityLine."Activity Type"::Pick, Database::"Assembly Line", WhseActivityLine."Source Document"::"Assembly Consumption", AsmHeader."No.", 1, '', '');

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin for AsmChild
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AsmChild."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", AsmChild."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity, Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromProdOrderShowCalcSummaryShptReqHandler,CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectPutAwayPickProdOrderManualFlushAvailInPickBinFullPicksCreatedSummaryPage()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        ProdParent: Record Item;
        ProdChild: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Location: Record Location;
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] Directed Put-away and Pick, Production Order with manual flushing, qty. available in the pick bin, full warehouse pick
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Production BOM item available in pick bin
        SetupLocationWithBins(Location, 1);
        Quantity := 1;
        SetupProductionOrderScenario(ProdChild, ProdParent, Enum::"Flushing Method"::"Pick + Manual", Quantity, Location);

        // [GIVEN] Warehouse shipment for the released production order with qty. available in pick bin for ProdParent
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, Enum::"Production Order Status"::Released, Enum::"Prod. Order Source Type"::Item, ProdParent."No.", 1);
        ProdOrderLine.SetRange(Status, Enum::"Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Location Code", Location.Code);
        ProdOrderLine.Modify();

        ProdOrderComponent.SetRange(Status, Enum::"Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Modify();

        // [WHEN] Create warehouse pick
        CreateWhsePickAndTrapSummary(ProductionOrder, WarehousePickSummaryTestPage); //CreatePickFromProdOrderShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Prod. Consumption", ProductionOrder."No.", ProdOrderLine."Line No.", ProdOrderComponent."Item No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity + Quantity, Quantity + Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, Database::"Prod. Order Component", Enum::"Warehouse Activity Source Document"::"Prod. Consumption", ProductionOrder."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, Database::"Prod. Order Component", Enum::"Warehouse Activity Source Document"::"Prod. Consumption", ProductionOrder."No.", Quantity);

        // [GIVEN] Register the warehouse pick
        RegisterWhseActivity(WhseActivityLine."Activity Type"::Pick, Database::"Prod. Order Component", WhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, '', '');

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin for ProdChild
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ProdChild."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", ProdChild."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity, Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromProdOrderShowCalcSummaryShptReqHandler,CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectPutAwayPickProdOrderPickBackwardFlushAvailInPickBinFullPicksCreatedSummaryPage()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        ProdParent: Record Item;
        ProdChild: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Location: Record Location;
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] Directed Put-away and Pick, Production Order with pick + backward flushing, qty. available in the pick bin, full warehouse pick
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Production BOM item available in pick bin
        SetupLocationWithBins(Location, 1);
        Quantity := 1;
        SetupProductionOrderScenario(ProdChild, ProdParent, Enum::"Flushing Method"::"Pick + Backward", Quantity, Location);

        // [GIVEN] Warehouse shipment for the released production order with qty. available in pick bin for ProdParent
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, Enum::"Production Order Status"::Released, Enum::"Prod. Order Source Type"::Item, ProdParent."No.", 1);
        ProdOrderLine.SetRange(Status, Enum::"Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Location Code", Location.Code);
        ProdOrderLine.Modify();

        ProdOrderComponent.SetRange(Status, Enum::"Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Modify();

        // [WHEN] Create warehouse pick
        CreateWhsePickAndTrapSummary(ProductionOrder, WarehousePickSummaryTestPage); //CreatePickFromProdOrderShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Prod. Consumption", ProductionOrder."No.", ProdOrderLine."Line No.", ProdOrderComponent."Item No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity + Quantity, Quantity + Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, Database::"Prod. Order Component", Enum::"Warehouse Activity Source Document"::"Prod. Consumption", ProductionOrder."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, Database::"Prod. Order Component", Enum::"Warehouse Activity Source Document"::"Prod. Consumption", ProductionOrder."No.", Quantity);

        // [GIVEN] Register the warehouse pick
        RegisterWhseActivity(WhseActivityLine."Activity Type"::Pick, Database::"Prod. Order Component", WhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", 1, '', '');

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin for ProdChild
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ProdChild."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", ProdChild."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity, Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler,MessageHandler')]
    procedure DirectPutAwayPickProdOrderPickFwdFlushAvailInPickBinFullPicksCreatedSummaryPage()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        ProdParent: Record Item;
        ProdChild: Record Item;
        Location: Record Location;
        WhseShipmentLine: Record "Warehouse Shipment Line";
        PickBin: Record Bin;
        PutAwayBin: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 359031] Directed Put-away and Pick, Production Order with pick + forward flushing, qty. available in the pick bin, full warehouse pick
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Production BOM item available in pick bin
        SetupLocationWithBins(Location, 1);
        Quantity := 1;
        SetupProductionOrderScenario(ProdChild, ProdParent, Enum::"Flushing Method"::"Pick + Forward", Quantity, Location);

        // [GIVEN] Use movement worksheet to move 1 quantity of ProdChild to put-away bin ("To-Production Bin Code")
        LibraryWarehouse.FindBin(PickBin, Location.Code, 'PICK', 0);
        PutAwayBin.Get(Location.Code, Location."To-Production Bin Code");
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, PickBin, PutAwayBin, ProdChild."No.", '', Quantity);
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", "Whse. Activity Sorting Method"::None, false, false); //MessageHandler needed

        Clear(WhseActivityLine);
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Movement);
        WhseActivityLine.SetRange("Item No.", ProdChild."No.");
        WhseActivityLine.SetRange("Location Code", Location.Code);
        WhseActivityLine.FindFirst();
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");

        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin for ProdChild
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ProdChild."No.", Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();

        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", ProdChild."No.", Quantity, Quantity);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, Quantity, Quantity, Quantity + Quantity, 0, 0, 0, 0, 0, 0, 0, 0);
        WarehousePickSummaryTestPage.Close();

        // [THEN] Warehouse pick is created
        CheckPick(Enum::"Warehouse Action Type"::Take, SalesHeader."No.", Quantity);
        CheckPick(Enum::"Warehouse Action Type"::Place, SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler,ItemTrackingLinesAssignSNModalPageHandler,AssignSNWithInfoToCreateModalPageHandler')]
    procedure DirectedPutAwayPickNoPicksForMultiItemDifferentReasonsCreatedSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        ItemToBeReserved: Record Item;
        ItemToBeSNBlocked: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        SerialNoInformation: Record "Serial No. Information";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Quantity: Decimal;
    begin
        // [SCENARIO 485183] Directed Put-away and Pick, Qty handled is zero for multiple lines for different reasons and pick summary factbox has correct values.
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled
        // [GIVEN] Item available in pick bin
        SetupLocationWithBins(Location, 1);
        LibraryInventory.CreateItem(ItemToBeReserved);
        LibraryInventory.CreateItem(ItemToBeSNBlocked);
        LibraryItemTracking.AddSerialNoTrackingInfo(ItemToBeSNBlocked);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Quantity := 5;

        // [GIVEN] Create a purchase order for both the items
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemToBeReserved."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemToBeSNBlocked."No.", Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        PurchaseLine.OpenItemTrackingLines(); //ItemTrackingLinesAssignSNModalPageHandler, AssignSNWithInfoToCreateModalPageHandler will be used to assign item tracking lines.

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity to make the quantity available in the pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // [GIVEN] Create Sales Order and reserve it against the purchase order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader, SalesLine1.Type::Item, ItemToBeReserved."No.", Quantity);
        SalesLine1.Validate("Location Code", Location.Code);
        SalesLine1.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine1);

        // [GIVEN] Block the Serial numbers for the item
        SerialNoInformation.SetRange("Item No.", ItemToBeSNBlocked."No.");
        SerialNoInformation.FindSet();
        repeat
            SerialNoInformation.Validate(Blocked, true);
            SerialNoInformation.Modify();
        until SerialNoInformation.Next() = 0;

        // [GIVEN] Warehouse shipment for the Sales order with qty. available in pick bin for both the items
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader, SalesLine1.Type::Item, ItemToBeReserved."No.", Quantity);
        SalesLine1.Validate("Location Code", Location.Code);
        SalesLine1.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, ItemToBeSNBlocked."No.", Quantity);
        SalesLine2.Validate("Location Code", Location.Code);
        SalesLine2.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create warehouse pick
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown
        WarehousePickSummaryTestPage.First();
        CheckWarehouseSummaryNothingToHandleMsg(WarehousePickSummaryTestPage);

        // [THEN] Values are correctly updated for Reserved Item.
        WarehousePickSummaryTestPage.First();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine1."Line No.", ItemToBeReserved."No.", Quantity, 0);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, true, Quantity, Quantity, Quantity, 0, 0, Quantity, Quantity, 0, 0, 0, -Quantity);

        // [THEN] Values are correctly updated for blocked Item tracking.
        WarehousePickSummaryTestPage.Next();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine2."Line No.", ItemToBeSNBlocked."No.", Quantity, 0);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, true, false, 0, 0, Quantity, Quantity, 0, 0, Quantity, 0, 0, 0, 0);

        WarehousePickSummaryTestPage.Close();
    end;

    [Test]
    [HandlerFunctions('CreatePickFromWhseShowCalcSummaryShptReqHandler')]
    procedure DirectedPutAwayPickSimpleScenarioNotAllowBreakbulkSummaryPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        NothingToHandleMsg: Label 'Nothing to handle. Check "Allow Breakbulk" on Location Card.';
        BaseQty: Decimal;
        UoMQty: Decimal;
        QtyPerUoM: Decimal;
        Quantities: List of [Decimal];
        EmptyBinCode: List of [Code[20]];
    begin
        // [SCENARIO 545255] Directed Put-away and Pick warehouse pick with different unit of measure 
        Initialize();

        // [GIVEN] Location with Directed Put-away and Pick, Shipment required enabled, Breakbulk disabled
        SetupLocationWithBins(Location, 1);
        if Location."Allow Breakbulk" then begin
            Location.Validate("Allow Breakbulk", false);
            Location.Modify();
        end;

        // [GIVEN] Item with additional UoM - Box. 1 Box = 12 PCS.
        LibraryInventory.CreateItem(Item);
        QtyPerUoM := 12;
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", QtyPerUoM);

        // [GIVEN] Item available on the location in base unit of measure
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        BaseQty := LibraryRandom.RandIntInRange(100, 200);
        Quantities.Add(BaseQty);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", BaseQty);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        SetEmptyBinCodeList(EmptyBinCode, 1);
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Quantities, EmptyBinCode, EmptyBinCode);

        // [GIVEN] Released Sales order for item with different UoM (3 Boxes)
        UoMQty := LibraryRandom.RandInt(5);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", UoMQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit of Measure Code", ItemUOM.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Warehouse shipment for the Sales order
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        // [WHEN] Create warehouse pick
        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage); //CreatePickFromWhseShowCalcSummaryShptReqHandler will show calculation summary page.

        // [THEN] Warehouse pick summary page is shown, there is nothing to handle due to the location settings - Allow Breakbulk = false
        WarehousePickSummaryTestPage.First();
        CheckWarehouseSummaryLineDetails(WarehousePickSummaryTestPage, Enum::"Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", SalesLine."Line No.", Item."No.", UoMQty * QtyPerUoM, 0);
        CheckWhseSummaryFactBoxValues(WarehousePickSummaryTestPage, false, false, false, BaseQty, BaseQty, BaseQty, 0, 0, 0, 0, 0, 0, 0, 0);
        Assert.AreEqual(NothingToHandleMsg, WarehousePickSummaryTestPage.Message.Value, 'Message is not correct');
        WarehousePickSummaryTestPage.Close();
    end;

    local procedure SetupAssemblyOrderScenario(var AsmChild: Record Item; var AsmParent: Record Item; CostingMethod: Enum "Costing Method"; ReplenishmentSystem: Enum "Replenishment System"; AsmPolicy: Enum "Assembly Policy"; Quantity: Decimal; Location: Record Location)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        PutAwayBin: Record Bin;
        PickBin: Record Bin;
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryInventory.CreateItem(AsmChild);
        LibraryAssembly.CreateItem(AsmParent, CostingMethod, ReplenishmentSystem, '', '');
        AsmParent.Validate("Assembly Policy", AsmPolicy);
        AsmParent.Modify();

        LibraryAssembly.CreateAssemblyListComponent(Enum::"BOM Component Type"::Item, AsmChild."No.", AsmParent."No.", '', 0, Quantity, true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, AsmChild."No.", 2 * Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity to make the quantity available in the pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", 2 * Quantity, '', '');

        // [GIVEN] Update location To-Assembly bin to Put-away bin and From-Assembly bin to Pick bin
        LibraryWarehouse.FindBin(PutAwayBin, Location.Code, 'BULK', 1);
        Location.Validate("To-Assembly Bin Code", PutAwayBin.Code);

        LibraryWarehouse.FindBin(PickBin, Location.Code, 'PICK', 0);
        Location.Validate("From-Assembly Bin Code", PickBin.Code);

        Location.Modify();
    end;

    local procedure SetupProductionOrderScenario(var ProdChild: Record Item; var ProdParent: Record Item; FlushingMethod: Enum "Flushing Method"; Quantity: Decimal; Location: Record Location)
    var
        ProdBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        PutAwayBin: Record Bin;
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryInventory.CreateItem(ProdChild);
        ProdChild.Validate("Flushing Method", FlushingMethod);
        ProdChild.Modify();
        LibraryManufacturing.CreateCertifiedProductionBOM(ProdBOMHeader, ProdChild."No.", Quantity);
        LibraryManufacturing.CreateItemManufacturing(ProdParent, Enum::"Costing Method"::Standard, 1000, Enum::"Reordering Policy"::" ", FlushingMethod, '', ProdBOMHeader."No.");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ProdChild."No.", 2 * Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // [GIVEN] Register a put-away activity to make the quantity available in the pick bin
        RegisterWhseActivity(WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", 2 * Quantity, '', '');

        // [GIVEN] Update location To-Production bin to Put-away bin and From-Production bin and Open Shop Floor Bin to empty
        LibraryWarehouse.FindBin(PutAwayBin, Location.Code, 'BULK', 1);
        Location.Validate("To-Production Bin Code", PutAwayBin.Code);

        Location.Validate("Open Shop Floor Bin Code", '');
        Location.Validate("From-Production Bin Code", '');

        Location.Modify();
    end;

    local procedure FindReceiptBin(LocationCode: Code[10]; ItemNo: Code[20]): Code[20]
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Bin Type Code", 'RECEIVE');
        BinContent.FindFirst();
        exit(BinContent."Bin Code");
    end;

    local procedure SetBinContentBlocked(BinCode: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; BlockMovement: Option " ",Inbound,Outbound,All)
    var
        Item: Record Item;
        BinContent: Record "Bin Content";
    begin
        Item.Get(ItemNo);
        BinContent.Get(LocationCode, BinCode, ItemNo, '', Item."Base Unit of Measure");
        BinContent.Validate("Block Movement", BlockMovement);
        BinContent.Modify(true);
    end;

    local procedure SetBinAsDedicated(LocationCode: Code[10]; BinCode: Code[20])
    var
        Bin: Record Bin;
    begin
        Bin.Get(LocationCode, BinCode);
        Bin.Validate(Dedicated, true);
        Bin.Modify();
    end;

    local procedure SetBinAsBlocked(BinCode: Code[20]; LocationCode: Code[10]; BlockMovement: Option " ",Inbound,Outbound,All)
    var
        Bin: Record Bin;
    begin
        Bin.Get(LocationCode, BinCode);
        Bin.Validate("Block Movement", BlockMovement);
        Bin.Modify();
    end;

    [Normal]
    local procedure DirectedPutawayAndPick(TestType: Option Partial,Positive,Negative)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        FirstSOQty: Decimal;
        SecondSOQty: Decimal;
    begin
        Initialize();
        SetupLocation(Location, true, true, true);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", 9, '', '');

        // Set up behaviour based on test type
        case TestType of
            TestType::Partial:
                begin
                    FirstSOQty := 7;
                    SecondSOQty := 4;
                end;
            TestType::Positive:
                begin
                    FirstSOQty := 5;
                    SecondSOQty := 4;
                end;
            TestType::Negative:
                begin
                    FirstSOQty := 9;
                    SecondSOQty := 4;
                end;
        end;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", FirstSOQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);

        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::Pick, 37, WhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", 1, '', '');

        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", SecondSOQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");

        case TestType of
            TestType::Positive:
                begin
                    LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", WhseShipmentLine.Quantity);
                    CheckPick(WhseActivityLine."Action Type"::Place, SalesHeader."No.", WhseShipmentLine.Quantity);
                end;
            TestType::Partial:
                begin
                    LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", 2);
                    CheckPick(WhseActivityLine."Action Type"::Place, SalesHeader."No.", 2);
                end;
            TestType::Negative:
                begin
                    asserterror LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    Assert.IsTrue(StrPos(GetLastErrorText, NothingToHandleErr) > 0, 'Unexpected error message');
                    ClearLastError();
                end;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickAndShipmentPositive()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        PickAndShipment(TestType::Positive);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickAndShipmentNegative()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        PickAndShipment(TestType::Negative);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickAndShipmentPartial()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        PickAndShipment(TestType::Partial);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PickPositive()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        Pick(TestType::Positive);
    end;

    [Test]
    [HandlerFunctions('ErrorHandler')]
    [Scope('OnPrem')]
    procedure PickNegative()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        Pick(TestType::Negative);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PickPartial()
    var
        TestType: Option Partial,Positive,Negative;
    begin
        Pick(TestType::Partial);
    end;

    [Normal]
    local procedure PickAndShipment(TestType: Option Partial,Positive,Negative)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Location: Record Location;
        FirstSOQty: Decimal;
        SecondSOQty: Decimal;
    begin
        Initialize();
        Clear(Location);
        SetupLocation(Location, false, true, true);
        SetupWarehouse(Location.Code);
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, Item."No.", 10);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();
        WhseReceiptLine.Validate("Bin Code", 'RECEIPT');
        WhseReceiptLine.Modify();

        WhseReceiptHeader.Get(WhseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::"Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", 10, 'RECEIPT', 'PICK');

        // Set up behaviour based on test type
        case TestType of
            TestType::Partial:
                begin
                    FirstSOQty := 7;
                    SecondSOQty := 5;
                end;
            TestType::Positive:
                begin
                    FirstSOQty := 6;
                    SecondSOQty := 4;
                end;
            TestType::Negative:
                begin
                    FirstSOQty := 10;
                    SecondSOQty := 5;
                end;
        end;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", FirstSOQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();
        WhseShipmentLine.Validate("Bin Code", 'SHIPMENT');
        WhseShipmentLine.Modify();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);

        Clear(SalesHeader);
        Clear(WhseShipmentHeader);
        Clear(WhseShipmentLine);
        CreateAndPostSalesOrder(SalesHeader, SalesLine, Location.Code, Item."No.", SecondSOQty);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();
        WhseShipmentLine.Validate("Bin Code", 'SHIPMENT');
        WhseShipmentLine.Modify();

        WhseShipmentHeader.Get(WhseShipmentLine."No.");

        case TestType of
            TestType::Positive:
                begin
                    LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", WhseShipmentLine.Quantity);
                    CheckPick(WhseActivityLine."Action Type"::Place, SalesHeader."No.", WhseShipmentLine.Quantity);
                end;
            TestType::Partial:
                begin
                    LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", 3);
                    CheckPick(WhseActivityLine."Action Type"::Place, SalesHeader."No.", 3);
                end;
            TestType::Negative:
                begin
                    asserterror LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
                    Assert.IsTrue(StrPos(GetLastErrorText, NothingToHandleErr) > 0, 'Unexpected error message');
                    ClearLastError();
                end;
        end;
    end;

    [Normal]
    local procedure Pick(TestType: Option Partial,Positive,Negative)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Location: Record Location;
        FirstSOQty: Decimal;
        SecondSOQty: Decimal;
    begin
        Initialize();
        Clear(Location);
        SetupLocation(Location, false, false, true);
        SetupWarehouse(Location.Code);
        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, Item."No.", 10);
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        RegisterWhseActivity(
          WhseActivityLine."Activity Type"::"Invt. Put-away", 39, WhseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", 10, '', 'PICK');

        // Set up behaviour based on test type
        case TestType of
            TestType::Partial:
                begin
                    FirstSOQty := 7;
                    SecondSOQty := 5;
                end;
            TestType::Positive:
                begin
                    FirstSOQty := 6;
                    SecondSOQty := 4;
                end;
            TestType::Negative:
                begin
                    FirstSOQty := 10;
                    SecondSOQty := 5;
                end;
        end;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", FirstSOQty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        Clear(SalesHeader);
        CreateAndPostSalesOrder(SalesHeader, SalesLine, Location.Code, Item."No.", SecondSOQty);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        case TestType of
            TestType::Positive:
                begin
                    LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", SalesLine.Quantity);
                end;
            TestType::Partial:
                begin
                    LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
                    CheckPick(WhseActivityLine."Action Type"::Take, SalesHeader."No.", 3);
                end;
            TestType::Negative:
                LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByPeriodHandler')]
    [Scope('OnPrem')]
    procedure ShowItemAvailabilityByPeriodFromPick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Bug 335697: http://vstfnav:8080/tfs/web/wi.aspx?pcguid=d3e6cf82-0023-4026-88e3-9235f1398970&id=335697
        // The test verification is that the correct page opens (corresponds to page handler)
        SetupWhseActivityLineForShowItemAvailability(WarehouseActivityLine);
        WarehouseActivityLine.ShowItemAvailabilityByPeriod();
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByLocationHandler')]
    [Scope('OnPrem')]
    procedure ShowItemAvailabilityByLocationFromPick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Bug 335697: http://vstfnav:8080/tfs/web/wi.aspx?pcguid=d3e6cf82-0023-4026-88e3-9235f1398970&id=335697
        // The test verification is that the correct page opens (corresponds to page handler)
        SetupWhseActivityLineForShowItemAvailability(WarehouseActivityLine);
        WarehouseActivityLine.ShowItemAvailabilityByLocation();
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByVariantHandler')]
    [Scope('OnPrem')]
    procedure ShowItemAvailabilityByVariantFromPick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Bug 335697: http://vstfnav:8080/tfs/web/wi.aspx?pcguid=d3e6cf82-0023-4026-88e3-9235f1398970&id=335697
        // The test verification is that the correct page opens (corresponds to page handler)
        SetupWhseActivityLineForShowItemAvailability(WarehouseActivityLine);
        WarehouseActivityLine.ShowItemAvailabilityByVariant();
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByEventHandler')]
    [Scope('OnPrem')]
    procedure ShowItemAvailabilityByEventFromPick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Bug 335697: http://vstfnav:8080/tfs/web/wi.aspx?pcguid=d3e6cf82-0023-4026-88e3-9235f1398970&id=335697
        // The test verification is that the correct page opens (corresponds to page handler)
        SetupWhseActivityLineForShowItemAvailability(WarehouseActivityLine);
        WarehouseActivityLine.ShowItemAvailabilityByEvent();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderAvailabilityByVariant()
    var
        SalesHeader: Record "Sales Header";
        TempItemVariant: Record "Item Variant" temporary;
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        i: Integer;
        ItemVariantQuantity: Decimal;
    begin
        // [SCENARIO 361061.1] Verify overstock by Variant in case of different Variant codes used in one Sales Order
        Initialize();

        // [GIVEN] 2 items "Item[i]", 2 Variant Codes "Var[i][j]" per each "Item[i]"
        CreateItemsWithVariants(TempItemVariant, 2, 2);

        // [GIVEN] Sales Order with "Shipping Advice" = COMPLETE, several Sales Lines per each "Var[i][j]"
        // [GIVEN] All item variants have exact inventory to comply the sales order
        MockSalesHeader(SalesHeader);
        TempItemVariant.FindSet();
        repeat
            ItemVariantQuantity := 0;
            for i := 1 to 2 do
                ItemVariantQuantity += MockSalesLine(SalesHeader, TempItemVariant);
            MockPositiveILE(TempItemVariant, ItemVariantQuantity);
        until TempItemVariant.Next() = 0;

        // [GIVEN] Additional Sales Line with "Var[1][2]" for overstock condition
        TempItemVariant.FindFirst();
        TempItemVariant.SetRange("Item No.", TempItemVariant."Item No.");
        TempItemVariant.FindLast();
        MockSalesLine(SalesHeader, TempItemVariant);

        // [WHEN] Check Sales Order Availability
        asserterror GetSourceDocOutbound.CheckSalesHeader(SalesHeader, true);

        // [THEN] Error: 'item no. "Item[1]" is not available'
        Assert.ExpectedError(StrSubstNo(OverStockErr, TempItemVariant."Item No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderAvailabilityByVariant()
    var
        TransferHeader: Record "Transfer Header";
        TempItemVariant: Record "Item Variant" temporary;
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        i: Integer;
        ItemVariantQuantity: Decimal;
    begin
        // [SCENARIO 361061.2] Verify overstock by Variant in case of different Variant codes used in one Transfer Order
        Initialize();

        // [GIVEN] 2 items "Item[i]", 2 Variant Codes "Var[i][j]" per each "Item[i]"
        CreateItemsWithVariants(TempItemVariant, 2, 2);

        // [GIVEN] Transfer Order with "Shipping Advice" = COMPLETE, several Transfer Lines per each "Var[i][j]"
        // [GIVEN] All item variants have exact inventory to comply the Transfer Order
        MockTransferHeader(TransferHeader);
        TempItemVariant.FindSet();
        repeat
            ItemVariantQuantity := 0;
            for i := 1 to 2 do
                ItemVariantQuantity += MockTransferLine(TempItemVariant, TransferHeader."No.");
            MockPositiveILE(TempItemVariant, ItemVariantQuantity);
        until TempItemVariant.Next() = 0;

        // [GIVEN] Additional Transfer Line with "Var[1][2]" for overstock condition
        TempItemVariant.FindFirst();
        TempItemVariant.SetRange("Item No.", TempItemVariant."Item No.");
        TempItemVariant.FindLast();
        MockTransferLine(TempItemVariant, TransferHeader."No.");

        // [WHEN] Check Transfer Order Availability
        asserterror GetSourceDocOutbound.CheckTransferHeader(TransferHeader, true);

        // [THEN] Error: 'item no. "Item[1]" is not available'
        Assert.ExpectedError(StrSubstNo(OverStockErr, TempItemVariant."Item No."));
    end;

    [Test]
    [HandlerFunctions('ProductionBOMPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyProductionBOMFromItemCard()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 346526] Verify Production BOM page should open when there is no active version of production BOM and should be certified from Item Card page.
        Initialize();

        // [GIVEN] Create a Component Item.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create Production BOM with Component Item.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);

        // [GIVEN] Create a Production Item.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem."Replenishment System" := ProdItem."Replenishment System"::"Prod. Order";
        ProdItem."Manufacturing Policy" := ProdItem."Manufacturing Policy"::"Make-to-Order";
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [WHEN] Open Production BOM page from Item Card.
        LibraryVariableStorage.Enqueue(ProductionBOMHeader."No.");
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(ProdItem);
        ItemCard."Prod. Active BOM Version".Invoke();

        // [Verify] Verify Production BOM through "ProductionBOMPageHandler".
    end;

    [Test]
    [HandlerFunctions('ProductionBOMPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyProductionBOMFromItemList()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO 346526] Verify Production BOM page should open when there is no active version of production BOM and should be certified from Item List page.
        Initialize();

        // [GIVEN] Create a Component Item.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create Production BOM with Component Item.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);

        // [GIVEN] Create a Production Item.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem."Replenishment System" := ProdItem."Replenishment System"::"Prod. Order";
        ProdItem."Manufacturing Policy" := ProdItem."Manufacturing Policy"::"Make-to-Order";
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [WHEN] Open Production BOM page from Item List.
        LibraryVariableStorage.Enqueue(ProductionBOMHeader."No.");
        ItemList.OpenEdit();
        ItemList.GotoRecord(ProdItem);
        ItemList."Prod. Active BOM Version".Invoke();

        // [Verify] Verify Production BOM through "ProductionBOMPageHandler".
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyProductionBOMShouldNotOpenFromItemCard()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 346526] Verify Production BOM page should not open when there is no active version of production BOM and should not be certified from Item Card page.
        Initialize();

        // [GIVEN] Create a Component Item.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create Production BOM with Component Item.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);

        // [GIVEN] Update Production BOM Status.
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::New);

        // [GIVEN] Create a Production Item.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem."Replenishment System" := ProdItem."Replenishment System"::"Prod. Order";
        ProdItem."Manufacturing Policy" := ProdItem."Manufacturing Policy"::"Make-to-Order";
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [WHEN] Open Production BOM page from Item Card.
        LibraryVariableStorage.Enqueue(ProductionBOMHeader."No.");
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(ProdItem);
        asserterror ItemCard."Prod. Active BOM Version".Invoke();

        // [Verify] Verify expected error while opening Production BOM page.
        Assert.ExpectedError(StrSubstNo(NoActiveProductionBOMVersionFoundErr, ProdItem."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyProductionBOMShouldNotOpenFromItemList()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO 346526] Verify Production BOM page should not open when there is no active version of production BOM and should not be certified from Item List page.
        Initialize();

        // [GIVEN] Create a Component Item.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create Production BOM with Component Item.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);

        // [GIVEN] Update Production BOM Status.
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::New);

        // [GIVEN] Create a Production Item.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem."Replenishment System" := ProdItem."Replenishment System"::"Prod. Order";
        ProdItem."Manufacturing Policy" := ProdItem."Manufacturing Policy"::"Make-to-Order";
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [WHEN] Open Production BOM page from Item List.
        LibraryVariableStorage.Enqueue(ProductionBOMHeader."No.");
        ItemList.OpenEdit();
        ItemList.GotoRecord(ProdItem);
        asserterror ItemList."Prod. Active BOM Version".Invoke();

        // [Verify] Verify expected error while opening Production BOM page.
        Assert.ExpectedError(StrSubstNo(NoActiveProductionBOMVersionFoundErr, ProdItem."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerWithAssignTo,CreatePickFromWhseShowCalcSummaryShiptReqHandler')]
    procedure PickFromWarehouseShipmentWithFEFOPickSummaryHasCorrectAvailableToPick()
    var
        Bin: Record Bin;
        BinType: Record "Bin Type";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Item: Record Item;
        Location: Record Location;
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary";
        Type: Enum "Item Journal Template Type";
        Quantity: array[2] of Decimal;
    begin
        // [SCENARIO 540550] When creating Pick from a Warehouse Shipment with FEFO, the Pick Summary page shows right Available to pick.
        Initialize();

        // [GIVEN] Setup Location with Bins and Validate pick according to FEFO to true.
        SetupLocationWithBins(Location, LibraryRandom.RandIntInRange(1, 1));
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);

        // [GIVEN] Create Item with Lot tracking.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Find Bin Type for Put Away and Pick.
        BinType.SetRange("Put Away", true);
        BinType.SetRange("Pick", true);
        BinType.FindFirst();

        // [GIVEN] Find Bin for Put Away and Pick in the Location.
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Bin Type Code", BinType.Code);
        Bin.FindFirst();

        // [GIVEN] Clear LibraryVariableStorage and Set up Quantities.
        LibraryVariableStorage.Clear();
        Quantity[1] := LibraryRandom.RandIntInRange(10, 10);
        Quantity[2] := LibraryRandom.RandIntInRange(5, 5);

        // [GIVEN] Select Warehouse Journal Template and Batch.
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);

        // [GIVEN] Create Warehouse Journal Batch.
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);

        // [GIVEN] Create Warehouse Journal Line for first quantity.
        LibraryWarehouse.CreateWhseJournalLine(
            WarehouseJournalLine,
            WarehouseJournalBatch."Journal Template Name",
            WarehouseJournalBatch.Name,
            Location.Code,
            Bin."Zone Code",
            Bin.Code,
            WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
            Item."No.",
            Quantity[1]);
        LibraryVariableStorage.Enqueue(WarehouseJournalLine.Quantity);

        // [GIVEN] Open Item Tracking Lines for Warehouse Journal Line.
        WarehouseJournalLine.OpenItemTrackingLines();

        // [GIVEN] Create Warehouse Journal Line for second quantity.
        LibraryWarehouse.CreateWhseJournalLine(
            WarehouseJournalLine,
            WarehouseJournalBatch."Journal Template Name",
            WarehouseJournalBatch.Name,
            Location.Code,
            Bin."Zone Code",
            Bin.Code,
            WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
            Item."No.",
            Quantity[2]);
        LibraryVariableStorage.Enqueue(WarehouseJournalLine.Quantity);

        // [GIVEN] Open Item Tracking Lines for Warehouse Journal Line.
        WarehouseJournalLine.OpenItemTrackingLines();

        // [GIVEN] Register Whse. Journal Line.
        LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);

        // [GIVEN] Select Item Journal Template and Batch and Validate No. Series.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        ItemJournalBatch.Modify(true);

        // [GIVEN] Clear and Create Item Journal Line.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        // [GIVEN] Calculate Whse Adjustment for Item.
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);

        // [GIVEN] Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);

        // [GIVEN] Create Sales Order with a Customer.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Create Sales Line with Item and Location.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [GIVEN] Release Sales Document and Create Warehouse Shipment from Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Find Warehouse Shipment Line.
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        WhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WhseShipmentLine.FindFirst();

        // [GIVEN] Find Warehouse Shipment Header.
        WhseShipmentHeader.Get(WhseShipmentLine."No.");

        // [GIVEN] Create Warehouse Pick from Warehouse Shipment.
        CreateWhsePickAndTrapSummary(WhseShipmentHeader, WarehousePickSummaryTestPage);
        WarehousePickSummaryTestPage.First();

        // [THEN] Available to Pick should be equal to quantities in the Bin.
        Assert.AreEqual(
            Quantity[1] + Quantity[2],
            WarehousePickSummaryTestPage.SummaryPart."Qty. in Pickable Bins".AsDecimal(),
            StrSubstNo(
                PickableQtyErr,
                WarehousePickSummaryTestPage.SummaryPart."Qty. in Pickable Bins".Caption(),
                Quantity[1] + Quantity[2],
                WarehousePickSummaryTestPage.Caption()));
        WarehousePickSummaryTestPage.Close();
    end;

    local procedure SetupWhseActivityLineForShowItemAvailability(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        Initialize();
        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Pick;
        WarehouseActivityLine."Item No." := LibraryInventory.CreateItemNo();
    end;

    [Normal]
    local procedure SetupWarehouse(LocationCode: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);
    end;

    [Normal]
    local procedure SetupLocation(var Location: Record Location; IsDirected: Boolean; ShipmentRequired: Boolean; BinMandatory: Boolean)
    var
        Bin: Record Bin;
    begin
        Location.Init();
        Location.SetRange("Bin Mandatory", BinMandatory);
        Location.SetRange("Require Shipment", ShipmentRequired);
        Location.SetRange("Require Receive", true);
        Location.SetRange("Require Pick", true);
        Location.SetRange("Require Put-away", true);
        Location.SetRange("Directed Put-away and Pick", IsDirected);

        if not Location.FindFirst() then
            if not IsDirected then begin
                LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
                Location.Validate("Require Put-away", true);
                Location.Validate("Always Create Put-away Line", true);
                Location.Validate("Require Pick", true);
                Location.Validate("Require Receive", ShipmentRequired);
                Location.Validate("Require Shipment", ShipmentRequired);
                Location.Validate("Bin Mandatory", BinMandatory);
                Location.Modify(true);
                CreateBin(Bin, Location.Code, 'RECEIPT', '', '');
                CreateBin(Bin, Location.Code, 'PICK', '', '');
                CreateBin(Bin, Location.Code, 'SHIPMENT', '', '');
            end;

        Location.Validate("Always Create Pick Line", false);
        Location.Modify(true);
    end;

    local procedure SetupLocationWithBins(var Location: Record Location; PickBinQty: Integer)
    var
        Bin: Record Bin;
        Zone: Record Zone;
        BinCodeList: List of [Code[20]];
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, PickBinQty);
        Location.Validate("Use Cross-Docking", false);
        Location.Modify();
        SetupWarehouse(Location.Code);

        // Get Pick Zone and Pick bins
        Zone.Get(Location.Code, 'PICK');
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 0);

        if Bin.FindSet() then
            repeat
                BinCodeList.Add(Bin.Code);
            until Bin.Next() = 0;
        SetOrAddToBinCodeDictionary(BinCodeDictionary, 'PICK', BinCodeList);
    end;

    local procedure SetOrAddToBinCodeDictionary(var DictionaryVar: Dictionary of [Text, List of [Code[20]]]; DictKey: Text; Value: List of [Code[20]])
    begin
        if DictionaryVar.ContainsKey(DictKey) then
            DictionaryVar.Set(DictKey, Value)
        else
            DictionaryVar.Add(DictKey, Value);
    end;

    local procedure CreateBin(var Bin: Record Bin; LocationCode: Text[10]; BinCode: Text[20]; ZoneCode: Text[10]; BinTypeCode: Text[10])
    begin
        Clear(Bin);
        Bin.Init();
        Bin.Validate("Location Code", LocationCode);
        Bin.Validate(Code, BinCode);
        Bin.Validate("Zone Code", ZoneCode);
        Bin.Validate("Bin Type Code", BinTypeCode);
        Bin.Insert(true);
    end;

    local procedure CreateItemsWithVariants(var ItemVariant: Record "Item Variant"; ItemCnt: Integer; VariantCntPerItem: Integer)
    var
        ItemNo: Code[20];
        i: Integer;
        j: Integer;
    begin
        for i := 1 to ItemCnt do begin
            ItemNo := MockItem();
            for j := 1 to VariantCntPerItem do begin
                ItemVariant.Init();
                ItemVariant."Item No." := ItemNo;
                ItemVariant.Code := MockItemVariantCode(ItemNo);
                ItemVariant.Insert();
            end;
        end;
    end;

    local procedure CreateWhsePickAndTrapSummary(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary")
    var
        WarehouseShipmentLineRec: Record "Warehouse Shipment Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseShipmentRelease: Codeunit "Whse.-Shipment Release";
    begin
        WarehouseShipmentLineRec.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLineRec.FindFirst();
        WhseShptLine.Copy(WarehouseShipmentLineRec);
        WhseShptHeader.Get(WhseShptLine."No.");
        if WhseShptHeader.Status = WhseShptHeader.Status::Open then
            WhseShipmentRelease.Release(WhseShptHeader);
        WarehouseShipmentLineRec.SetHideValidationDialog(false);
        WarehousePickSummaryTestPage.Trap();
        WarehouseShipmentLineRec.CreatePickDoc(WhseShptLine, WhseShptHeader); //Requires a request page handler to set Show Summary to true
    end;

    local procedure CreateWhsePickFromShipment(WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseShipmentLineRec: Record "Warehouse Shipment Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseShipmentRelease: Codeunit "Whse.-Shipment Release";
    begin
        WarehouseShipmentLineRec.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLineRec.FindFirst();
        WhseShptLine.Copy(WarehouseShipmentLineRec);
        WhseShptHeader.Get(WhseShptLine."No.");
        if WhseShptHeader.Status = WhseShptHeader.Status::Open then
            WhseShipmentRelease.Release(WhseShptHeader);
        WarehouseShipmentLineRec.SetHideValidationDialog(false);
        WarehouseShipmentLineRec.CreatePickDoc(WhseShptLine, WhseShptHeader); //Requires a request page handler to set Show Summary
    end;

    local procedure CreateWhsePickAndTrapSummary(AssemblyHeader: Record "Assembly Header"; var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary")
    begin
        WarehousePickSummaryTestPage.Trap();
        AssemblyHeader.CreatePick(true, '', 0, false, false, false); //Requires a request page handler to set Show Summary to true
    end;

    local procedure CreateWhsePickAndTrapSummary(ProductionOrder: Record "Production Order"; var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary")
    begin
        WarehousePickSummaryTestPage.Trap();
        ProductionOrder.CreatePick('', 0, false, false, false); //Requires a request page handler to set Show Summary to true
    end;

    local procedure CheckWarehouseSummaryNothingToHandleMsg(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary")
    begin
        Assert.AreEqual('Nothing to handle.', WarehousePickSummaryTestPage.Message.Value, 'Message shown on the summary page is not correct');
    end;

    local procedure CheckWarehouseSummaryLineDetails(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; SourceLineNo: Integer; ItemNo: Code[20]; ExpectedQtyToHandle: Decimal; ExpectedQtyHandled: Decimal)
    begin
        Assert.AreEqual(SourceDocument.AsInteger(), WarehousePickSummaryTestPage."Source Document".AsInteger(), 'Source Document is not correct');
        Assert.AreEqual(SourceNo, WarehousePickSummaryTestPage."Source No.".Value, 'Source No. is not correct');
        Assert.AreEqual(SourceLineNo, WarehousePickSummaryTestPage."Source Line No.".AsInteger(), 'Source Line No. is not correct');
        Assert.AreEqual(ItemNo, WarehousePickSummaryTestPage."Item No.".Value, 'Item No. is not correct');
        Assert.AreEqual(ExpectedQtyToHandle, WarehousePickSummaryTestPage."Qty. to Handle (Base)".AsDecimal(), 'Qty. to Handle (Base) is not correct');
        Assert.AreEqual(ExpectedQtyHandled, WarehousePickSummaryTestPage."Qty. Handled (Base)".AsDecimal(), 'Qty. Handled (Base) is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxValues(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; IsCalledFromMovementWorksheet: Boolean; CheckTracking: Boolean; CheckReservationImpact: Boolean; ExpectedPickableTakeableQty: Decimal; ExpectedQtyInPickableTakeableBins: Decimal; ExpectedQtyInWhse: Decimal; ExpectedQtyInBlockedItemTracking: Decimal; ExpectedQtyAssigned: Decimal; ExpectedAvailableQtyNotInShipBin: Decimal; ExpectedQtyReservedInWarehouse: Decimal; ExpectedQtyResInPickShipBins: Decimal; ExpectedQtyReservedForThisLine: Decimal; ExpectedQtyBlockedItemTrackingRes: Decimal; ExpectedReservationImpact: Decimal)
    begin
        if IsCalledFromMovementWorksheet then begin
            CheckWhseSummaryFactBoxTakeableQty(WarehousePickSummaryTestPage, ExpectedPickableTakeableQty);
            CheckWhseSummaryFactBoxQtyInTakeableBins(WarehousePickSummaryTestPage, ExpectedQtyInPickableTakeableBins);
        end
        else begin
            CheckWhseSummaryFactBoxPickableQty(WarehousePickSummaryTestPage, ExpectedPickableTakeableQty);
            CheckWhseSummaryFactBoxQtyInPickableBins(WarehousePickSummaryTestPage, ExpectedQtyInPickableTakeableBins);
        end;

        if CheckTracking then begin
            CheckWhseSummaryFactBoxQtyInBlockedItemTracking(WarehousePickSummaryTestPage, ExpectedQtyInBlockedItemTracking);
            CheckWhseSummaryFactBoxQtyBlockedItemTrackingRes(WarehousePickSummaryTestPage, ExpectedQtyBlockedItemTrackingRes);
        end;

        if CheckReservationImpact then begin
            CheckWhseSummaryFactBoxAvailableQtyNotInShipBin(WarehousePickSummaryTestPage, ExpectedAvailableQtyNotInShipBin);
            CheckWhseSummaryFactBoxQtyReservedInWarehouse(WarehousePickSummaryTestPage, ExpectedQtyReservedInWarehouse);
            CheckWhseSummaryFactBoxQtyResInPickShipBins(WarehousePickSummaryTestPage, ExpectedQtyResInPickShipBins);
            CheckWhseSummaryFactBoxQtyReservedForThisLine(WarehousePickSummaryTestPage, ExpectedQtyReservedForThisLine);
            CheckWhseSummaryFactBoxReservationImpact(WarehousePickSummaryTestPage, ExpectedReservationImpact);
        end;

        if ExpectedQtyAssigned > 0 then
            CheckWhseSummaryFactBoxQtyAssigned(WarehousePickSummaryTestPage, ExpectedQtyAssigned)
        else
            Assert.AreEqual(false, WarehousePickSummaryTestPage.SummaryPart."Qty. assigned".Visible(), 'Qty. assigned. should not be visible');

        CheckWhseSummaryFactBoxQtyInWhse(WarehousePickSummaryTestPage, ExpectedQtyInWhse);
    end;

    local procedure CheckWhseSummaryFactBoxValuesForPickWorksheet(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; BatchName: Text)
    begin
        Assert.AreEqual(BatchName, WarehousePickSummaryTestPage.SummaryPart."Worksheet Batch Name".Value, 'Worksheet Batch Name is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxPickableQty(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Pickable Qty.".AsDecimal(), 'Pickable Qty. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxTakeableQty(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Takeable Qty.".AsDecimal(), 'Takeable Qty. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxQtyInPickableBins(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Qty. in Pickable Bins".AsDecimal(), 'Qty. in Pickable Bins. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxQtyInTakeableBins(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Qty. in takeable bins".AsDecimal(), 'Qty. in Takeable Bins. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxQtyInWhse(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Qty. in Warehouse".AsDecimal(), 'Qty. in warehouse. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxQtyInBlockedItemTracking(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Qty. in Blocked Item Tracking".AsDecimal(), 'Qty. in Blocked Item Tracking. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxQtyAssigned(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Qty. assigned".AsDecimal(), 'Qty. assigned. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxAvailableQtyNotInShipBin(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Available qty. not in ship bin".AsDecimal(), 'Available qty. not in ship bin. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxQtyReservedInWarehouse(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Qty. reserved in warehouse".AsDecimal(), 'Qty. reserved in warehouse. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxQtyResInPickShipBins(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Qty. res. in pick/ship bins".AsDecimal(), 'Qty. res. in pick/ship bins. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxQtyReservedForThisLine(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Qty. reserved for this line".AsDecimal(), 'Qty. reserved for this line. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxQtyBlockedItemTrackingRes(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart."Qty. block. Item Tracking Res.".AsDecimal(), 'Qty. block. Item Tracking Res.. is not correct');
    end;

    local procedure CheckWhseSummaryFactBoxReservationImpact(var WarehousePickSummaryTestPage: TestPage "Warehouse Pick Summary"; ExpectedQty: Decimal)
    begin
        Assert.AreEqual(ExpectedQty, WarehousePickSummaryTestPage.SummaryPart.Impact.AsDecimal(), 'Reservation Impact. is not correct');
    end;

    [Normal]
    local procedure CheckPick(LineType: Enum "Warehouse Action Type"; SalesOrderNo: Code[20]; ExpectedQty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.SetRange("Source Type", 37);
        WhseActivityLine.SetRange("Source Document", WhseActivityLine."Source Document"::"Sales Order");
        WhseActivityLine.SetRange("Source No.", SalesOrderNo);
        WhseActivityLine.SetRange("Action Type", LineType);
        Assert.AreEqual(1, WhseActivityLine.Count, TooManyPickLinesErr);
        WhseActivityLine.FindFirst();
        Assert.AreEqual(ExpectedQty, WhseActivityLine.Quantity, DifferentQtyErr);
    end;

    local procedure CheckPick(LineType: Enum "Warehouse Action Type"; SourceType: Integer; SourceDocument: Enum "Warehouse Activity Source Document"; OrderNo: Code[20]; ExpectedQty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.SetRange("Source Type", SourceType);
        WhseActivityLine.SetRange("Source Document", SourceDocument);
        WhseActivityLine.SetRange("Source No.", OrderNo);
        WhseActivityLine.SetRange("Action Type", LineType);
        Assert.AreEqual(1, WhseActivityLine.Count, TooManyPickLinesErr);
        WhseActivityLine.FindFirst();
        Assert.AreEqual(ExpectedQty, WhseActivityLine.Quantity, DifferentQtyErr);
    end;

    local procedure CheckPick(LineType: Enum "Warehouse Action Type"; SourceType: Integer; SourceDocument: Enum "Warehouse Activity Source Document"; OrderNo: Code[20]; ExpectedLines: Decimal; ExpectedTotalBaseQty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        TotalQty: Decimal;
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.SetRange("Source Type", SourceType);
        WhseActivityLine.SetRange("Source Document", SourceDocument);
        WhseActivityLine.SetRange("Source No.", OrderNo);
        WhseActivityLine.SetRange("Action Type", LineType);
        Assert.AreEqual(ExpectedLines, WhseActivityLine.Count, TooManyPickLinesErr);
        WhseActivityLine.FindSet();
        repeat
            TotalQty += WhseActivityLine."Qty. (Base)";
        until WhseActivityLine.Next() = 0;
        Assert.AreEqual(ExpectedTotalBaseQty, TotalQty, DifferentQtyErr);
    end;

    [Normal]
    local procedure RegisterWhseActivity(ActivityType: Enum "Warehouse Activity Type"; SourceType: Integer; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; QtyToHandle: Decimal; TakeBinCode: Code[20]; PlaceBinCode: Code[20])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Source Type", SourceType);
        WhseActivityLine.SetRange("Source Document", SourceDocument);
        WhseActivityLine.SetRange("Source No.", SourceNo);
        WhseActivityLine.FindSet();
        repeat
            WhseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Take) and (TakeBinCode <> '') then
                WhseActivityLine."Bin Code" := TakeBinCode
            else
                if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Place) and (PlaceBinCode <> '') then
                    WhseActivityLine."Bin Code" := PlaceBinCode;

            WhseActivityLine.Modify();
        until WhseActivityLine.Next() = 0;

        Clear(WhseActivityHeader);
        WhseActivityHeader.SetRange(Type, ActivityType);
        WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
        WhseActivityHeader.FindFirst();
        if (ActivityType = WhseActivityLine."Activity Type"::"Put-away") or
           (ActivityType = WhseActivityLine."Activity Type"::Pick)
        then
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader)
        else
            LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);
    end;

    local procedure RegisterWhseActivity(ActivityType: Enum "Warehouse Activity Type"; SourceType: Integer; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; var QtyToHandle: List of [Decimal]; var TakeBinCode: List of [Code[20]]; var PlaceBinCode: List of [Code[20]])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        i: Integer;
        counter: Integer;
    begin
        Clear(WhseActivityLine);
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Source Type", SourceType);
        WhseActivityLine.SetRange("Source Document", SourceDocument);
        WhseActivityLine.SetRange("Source No.", SourceNo);
        WhseActivityLine.FindSet();
        i := 1;
        counter := 1;
        repeat
            WhseActivityLine.Validate("Qty. to Handle", QtyToHandle.Get(i));
            if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Take) and (TakeBinCode.Get(i) <> '') then
                WhseActivityLine."Bin Code" := TakeBinCode.Get(i)
            else
                if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Place) and (PlaceBinCode.Get(i) <> '') then
                    WhseActivityLine."Bin Code" := PlaceBinCode.Get(i);

            WhseActivityLine.Modify();
            counter := counter + 1;
            i := i + (counter mod 2); //Update the index after Take and Place action.

        until WhseActivityLine.Next() = 0;

        Clear(WhseActivityHeader);
        WhseActivityHeader.SetRange(Type, ActivityType);
        WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
        WhseActivityHeader.FindFirst();
        if (ActivityType = WhseActivityLine."Activity Type"::"Put-away") or
           (ActivityType = WhseActivityLine."Activity Type"::Pick)
        then
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader)
        else
            LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);
    end;

    local procedure RegisterWhseActivity(ActivityType: Enum "Warehouse Activity Type"; SourceType: Integer; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        WhseActivityLine.SetRange("Source Type", SourceType);
        WhseActivityLine.SetRange("Source Document", SourceDocument);
        WhseActivityLine.SetRange("Source No.", SourceNo);
        WhseActivityLine.FindSet();
        repeat
            WhseActivityLine.Validate("Qty. to Handle", WhseActivityLine.Quantity);
            WhseActivityLine.Modify();
        until WhseActivityLine.Next() = 0;

        WhseActivityHeader.SetRange(Type, ActivityType);
        WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
        WhseActivityHeader.FindFirst();
        if (ActivityType = WhseActivityLine."Activity Type"::"Put-away") or
           (ActivityType = WhseActivityLine."Activity Type"::Pick)
        then
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader)
        else
            LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20]; ItemQuantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ItemQuantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; ItemQuantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, ItemQuantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure MockItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item.Init();
        Item."No." := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), DATABASE::Item);
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure MockItemVariantCode(ItemNo: Code[20]): Code[10]
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.Init();
        ItemVariant."Item No." := ItemNo;
        ItemVariant.Code := LibraryUtility.GenerateRandomCode(ItemVariant.FieldNo(Code), DATABASE::"Item Variant");
        ItemVariant.Insert();
        exit(ItemVariant.Code);
    end;

    local procedure MockPositiveILE(ItemVariant: Record "Item Variant"; ILEQty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LastEntryNo: Integer;
    begin
        ItemLedgerEntry.FindLast();
        LastEntryNo := ItemLedgerEntry."Entry No.";
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := LastEntryNo + 1;
        ItemLedgerEntry."Item No." := ItemVariant."Item No.";
        ItemLedgerEntry."Variant Code" := ItemVariant.Code;
        ItemLedgerEntry.Quantity := ILEQty;
        ItemLedgerEntry.Insert();
    end;

    local procedure MockSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("No."), DATABASE::"Sales Header");
        SalesHeader."Shipping Advice" := SalesHeader."Shipping Advice"::Complete;
        SalesHeader.Insert();
    end;

    local procedure MockSalesLine(SalesHeader: Record "Sales Header"; ItemVariant: Record "Item Variant"): Decimal
    var
        SalesLine: Record "Sales Line";
        LastLineNo: Integer;
    begin
        LastLineNo := 0;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            LastLineNo := SalesLine."Line No.";
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LastLineNo + 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemVariant."Item No.";
        SalesLine."Variant Code" := ItemVariant.Code;
        SalesLine."Outstanding Qty. (Base)" := LibraryRandom.RandDec(100, 2);
        SalesLine.Insert();
        exit(SalesLine."Outstanding Qty. (Base)");
    end;

    local procedure MockTransferHeader(var TransferHeader: Record "Transfer Header")
    begin
        TransferHeader.Init();
        TransferHeader."No." := LibraryUtility.GenerateRandomCode(TransferHeader.FieldNo("No."), DATABASE::"Transfer Header");
        TransferHeader."Shipping Advice" := TransferHeader."Shipping Advice"::Complete;
        TransferHeader.Insert();
    end;

    local procedure MockTransferLine(ItemVariant: Record "Item Variant"; TransferHeaderNo: Code[20]): Decimal
    var
        TransferLine: Record "Transfer Line";
        LastLineNo: Integer;
    begin
        LastLineNo := 0;
        TransferLine.SetRange("Document No.", TransferHeaderNo);
        if TransferLine.FindLast() then
            LastLineNo := TransferLine."Line No.";
        TransferLine.Init();
        TransferLine."Document No." := TransferHeaderNo;
        TransferLine."Line No." := LastLineNo + 10000;
        TransferLine."Item No." := ItemVariant."Item No.";
        TransferLine."Variant Code" := ItemVariant.Code;
        TransferLine."Outstanding Qty. (Base)" := LibraryRandom.RandDec(100, 2);
        TransferLine.Insert();
        exit(TransferLine."Outstanding Qty. (Base)");
    end;

    local procedure SetEmptyBinCodeList(var BinCodeList: List of [Code[20]]; Count: Integer)
    var
        i: Integer;
    begin
        for i := 1 to Count do
            BinCodeList.Add('');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ErrorHandler(Message: Text[1024])
    begin
        Message := DelChr(Message, '<>');
        if not (Message in [NothingToCreateErr, InvtPutAwayMsg, InvtPickMsg]) then
            Error(MissingExpectedErr, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByPeriodHandler(var ItemAvailabilityByPeriods: Page "Item Availability by Periods"; var Response: Action)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByLocationHandler(var ItemAvailabilityByLocation: Page "Item Availability by Location"; var Response: Action)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByVariantHandler(var ItemAvailabilityByVariant: Page "Item Availability by Variant"; var Response: Action)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByEventHandler(var ItemAvailabilityByEvent: Page "Item Availability by Event"; var Response: Action)
    begin
    end;

    [RequestPageHandler]
    procedure CreatePickFromWhseShowCalcSummaryShptReqHandler(var CreatePickFromWhseShptReqPage: TestRequestPage "Whse.-Shipment - Create Pick")
    begin
        CreatePickFromWhseShptReqPage.ShowSummaryField.SetValue(true);
        CreatePickFromWhseShptReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreatePickFromWhseDoNotShowCalcSummaryShptReqHandler(var CreatePickFromWhseShptReqPage: TestRequestPage "Whse.-Shipment - Create Pick")
    begin
        CreatePickFromWhseShptReqPage.ShowSummaryField.SetValue(false);
        CreatePickFromWhseShptReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreatePickFromAsmOrderShowCalcSummaryShptReqHandler(var CreatePickFromAsmOrderReqPage: TestRequestPage "Whse.-Source - Create Document")
    begin
        CreatePickFromAsmOrderReqPage.ShowSummaryField.SetValue(true);
        CreatePickFromAsmOrderReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreatePickFromAsmOrderDoNotShowCalcSummaryShptReqHandler(var CreatePickFromAsmOrderReqPage: TestRequestPage "Whse.-Source - Create Document")
    begin
        CreatePickFromAsmOrderReqPage.ShowSummaryField.SetValue(false);
        CreatePickFromAsmOrderReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreatePickFromProdOrderShowCalcSummaryShptReqHandler(var CreatePickFromProdOrderReqPage: TestRequestPage "Whse.-Source - Create Document")
    begin
        CreatePickFromProdOrderReqPage.ShowSummaryField.SetValue(true);
        CreatePickFromProdOrderReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreatePickFromPrdOrderDoNotShowCalcSummaryShptReqHandler(var CreatePickFromProdOrderReqPage: TestRequestPage "Whse.-Source - Create Document")
    begin
        CreatePickFromProdOrderReqPage.ShowSummaryField.SetValue(false);
        CreatePickFromProdOrderReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreatePickFromWhseShowCalcSummaryShiptReqHandler(var CreatePickFromWhseShptReqPage: TestRequestPage "Whse.-Shipment - Create Pick")
    begin
        CreatePickFromWhseShptReqPage.DoNotFillQtytoHandle.SetValue(true);
        CreatePickFromWhseShptReqPage.ShowSummaryField.SetValue(true);
        CreatePickFromWhseShptReqPage.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrue(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure BinContentVerifyQuantityModalPageHandler(var BinContents: TestPage "Bin Contents");
    var
        TotalBaseQty: Decimal;
    begin
        BinContents.First();
        TotalBaseQty := BinContents."Quantity (Base)".AsDecimal();
        BinContents.Next();
        TotalBaseQty += BinContents."Quantity (Base)".AsDecimal();
        // Use total base quantity as we cannot guarantee the sequence of the bin content lines.
        Assert.AreEqual(LibraryVariableStorage.DequeueDecimal() + LibraryVariableStorage.DequeueDecimal(), TotalBaseQty, 'Total Quantity (Base) is not correct');
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesAssignSNModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
    end;

    [ModalPageHandler]
    procedure AssignSNWithInfoToCreateModalPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateSNInfo.SetValue(true);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VerifyDrillDownPickWorksheetModalPageHandler(var PickWorksheet: TestPage "Pick Worksheet")
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), PickWorksheet.CurrentWkshName.Value, 'Worksheet Batch Name is not correct');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), PickWorksheet.CurrentLocationCode.Value, 'Location Code is not correct');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), PickWorksheet."Whse. Document No.".Value, 'Whse. Document No. is not correct');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), PickWorksheet.WhseDocumentType.Value, 'Whse. Document Type is not correct');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), PickWorksheet."Item No.".Value, 'Item No. is not correct');
        Assert.IsFalse(PickWorksheet.Next(), 'There should be only one line in the worksheet');
    end;

    [MessageHandler]
    procedure VerifyMessageHandler(Message: Text)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Message, 'Message is not correct');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionBOMPageHandler(var ProductionBOM: TestPage "Production BOM")
    begin
        ProductionBOM."No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandlerWithAssignTo(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateRandomText(10));
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        WhseItemTrackingLines.OK().Invoke();
    end;
}