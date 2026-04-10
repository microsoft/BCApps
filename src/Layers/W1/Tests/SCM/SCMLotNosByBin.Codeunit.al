codeunit 137165 "SCM Lot Nos By Bin"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Item Tracking] [SCM]
        isInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        AssignLotNo: Boolean;

    local procedure LotByBinOnPutAway(QtyToHandleDelta: Integer; Register: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Setup.
        Initialize();

        // Create WMS location and tracked item.
        AssignLotNo := true;  // Used in ItemTrackingLinesHandler.
        CreateFullWarehouseSetup(Location);
        CreateItemWithItemTrackingCode(Item);

        // Create Purchase Orders with lot numbers. Create and post whse. receipt.
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseHeader, Item."No.", Location.Code, 3);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.");

        // Update Qty to Handle.
        FindWarehouseActivityLines(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away");
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");

        repeat
            WhseActivityLine.Validate("Qty. to Handle", WhseActivityLine.Quantity - QtyToHandleDelta);
            WhseActivityLine.Modify(true);
        until WhseActivityLine.Next() = 0;

        // Register put-away.
        if Register then
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        if (QtyToHandleDelta > 0) or (not Register) then
            VerifyLotNosOnBinQuery(PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure PartialPutAwayRegister()
    begin
        LotByBinOnPutAway(1, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure NotRegisteredPutAway()
    begin
        LotByBinOnPutAway(0, false);
    end;

    local procedure LotByBinOnInvtPutAway(QtyToHandleDelta: Integer; Post: Boolean)
    var
        WhseRequest: Record "Warehouse Request";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Setup.
        Initialize();

        // Create WMS location and tracked item.
        AssignLotNo := true;  // Used in ItemTrackingLinesHandler.
        CreateFullWarehouseSetup(Location);
        Location."Directed Put-away and Pick" := false;
        Location."Require Receive" := false;
        Location."Require Shipment" := false;
        Location.Modify(true);
        CreateItemWithItemTrackingCode(Item);

        // Create Purchase Orders with lot numbers. Create and post whse. receipt.
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseHeader, Item."No.", Location.Code, 3);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WhseRequest."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // Update Qty to Handle.
        FindWarehouseActivityLines(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Invt. Put-away");
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");

        repeat
            WhseActivityLine.Validate("Bin Code", GetBin(Location.Code));
            WhseActivityLine.Validate("Qty. to Handle", WhseActivityLine.Quantity - QtyToHandleDelta);
            WhseActivityLine.Modify(true);
        until WhseActivityLine.Next() = 0;

        // Post inventory put-away.
        if Post then
            LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);

        if (QtyToHandleDelta > 0) or (not Post) then
            VerifyLotNosOnBinQuery(PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Invt. Put-away");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartialInvtPutAwayPost()
    begin
        LotByBinOnInvtPutAway(1, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NotPostedInvtPutAway()
    begin
        LotByBinOnInvtPutAway(0, false);
    end;

    local procedure LotByBinOnPick(QtyToHandleDelta: Integer; Register: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        WhseActivityHeader: Record "Warehouse Activity Header";
        SalesHeader: Record "Sales Header";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup.
        Initialize();

        // Create WMS location and tracked item.
        AssignLotNo := true;  // Used in ItemTrackingLinesHandler.
        CreateFullWarehouseSetup(Location);
        CreateItemWithItemTrackingCode(Item);

        // Create Purchase Orders with lot numbers. Create and post whse. receipt.
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseHeader, Item."No.", Location.Code, 1);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.");

        // Update Qty to Handle.
        FindWarehouseActivityLines(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Put-away");
        repeat
            WhseActivityLine.Validate("Qty. to Handle", WhseActivityLine.Quantity);
        until WhseActivityLine.Next() = 0;
        WhseActivityLine.Modify(true);

        // Register put-away.
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // Create Sales Order. Create Whse Shipment and Pick.
        Item.CalcFields(Inventory);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Location.Code, LibraryRandom.RandIntInRange(2, Item.Inventory));
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WhseShipmentHeader.SetRange("Location Code", Location.Code);
        WhseShipmentHeader.FindFirst();
        LibraryWarehouse.CreatePick(WhseShipmentHeader);

        // Update Qty to Handle on Pick. Assign item tracking on Pick.
        FindWarehouseActivityLines(WhseActivityLine, SalesHeader."No.", WhseActivityLine."Activity Type"::Pick);
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        repeat
            WhseActivityLine.Validate("Qty. to Handle", WhseActivityLine.Quantity - QtyToHandleDelta);
            SelectLotNoOnWhsePick(WhseActivityLine);
            WhseActivityLine.Modify(true);
        until WhseActivityLine.Next() = 0;

        // Register pick.
        if Register then
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        if (QtyToHandleDelta > 0) or (not Register) then
            VerifyLotNosOnBinQuery(SalesHeader."No.", WhseActivityLine."Activity Type"::Pick);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PartialPickRegister()
    begin
        LotByBinOnPick(1, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure NotRegisteredPick()
    begin
        LotByBinOnPick(0, false);
    end;

    local procedure LotByBinOnInvtPick(QtyToHandleDelta: Integer; Post: Boolean)
    var
        WhseRequest: Record "Warehouse Request";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        WhseActivityHeader: Record "Warehouse Activity Header";
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        Initialize();

        // Create WMS location and tracked item.
        AssignLotNo := true;  // Used in ItemTrackingLinesHandler.
        CreateFullWarehouseSetup(Location);
        Location."Directed Put-away and Pick" := false;
        Location."Require Receive" := false;
        Location."Require Shipment" := false;
        Location.Modify(true);
        CreateItemWithItemTrackingCode(Item);

        // Create Purchase Orders with lot numbers. Create and post whse. receipt.
        CreateAndReleasePurchaseOrderWithItemTrackingLines(PurchaseHeader, Item."No.", Location.Code, 1);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WhseRequest."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // Update Qty to Handle.
        FindWarehouseActivityLines(WhseActivityLine, PurchaseHeader."No.", WhseActivityLine."Activity Type"::"Invt. Put-away");
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");

        repeat
            WhseActivityLine.Validate("Bin Code", GetBin(Location.Code));
            WhseActivityLine.Validate("Qty. to Handle", WhseActivityLine.Quantity);
            WhseActivityLine.Modify(true);
        until WhseActivityLine.Next() = 0;

        // Post inventory put-away.
        LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);

        // Create Sales Order. Create Invt. Pick.
        Item.CalcFields(Inventory);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Location.Code, LibraryRandom.RandIntInRange(2, Item.Inventory));
        LibraryWarehouse.CreateInvtPutPickMovement(WhseRequest."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Update Qty to Handle on Pick. Assign item tracking on Pick.
        FindWarehouseActivityLines(WhseActivityLine, SalesHeader."No.", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        repeat
            WhseActivityLine.Validate("Qty. to Handle", WhseActivityLine.Quantity - QtyToHandleDelta);
            SelectLotNoOnWhsePick(WhseActivityLine);
            WhseActivityLine.Modify(true);
        until WhseActivityLine.Next() = 0;

        // Post inventory put-away.
        if Post then
            LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);

        if (QtyToHandleDelta > 0) or (not Post) then
            VerifyLotNosOnBinQuery(SalesHeader."No.", WhseActivityLine."Activity Type"::"Invt. Pick");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,MessageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PartialInvtPickPost()
    begin
        LotByBinOnInvtPick(1, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,MessageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure NotPostedInvtPick()
    begin
        LotByBinOnInvtPick(0, false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Lot Nos By Bin");
        // Clear global variables.
        Clear(AssignLotNo);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Lot Nos By Bin");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Lot Nos By Bin");
    end;

    local procedure CreateAndReleasePurchaseOrderWithItemTrackingLines(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; NoOfLines: Integer)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        "count": Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        for count := 1 to NoOfLines do begin
            LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandIntInRange(2, 10));
            CreateAndUpdatePurchaseLine(
              PurchaseLine, PurchaseHeader, ItemNo, LocationCode, '', LibraryRandom.RandIntInRange(2, 20), ItemUnitOfMeasure.Code);
            PurchaseLine.OpenItemTrackingLines();
        end;

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndUpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Validate("Unit of Measure", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bins per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Lot: Boolean; Serial: Boolean; ManExpirDateEntryReqd: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManExpirDateEntryReqd);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, true, false, false);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    local procedure GetLotQtyFromWhseEntries(var WarehouseEntry: Record "Warehouse Entry"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; LotNo: Code[50])
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetRange("Bin Code", BinCode);
        WarehouseEntry.SetRange("Lot No.", LotNo);
        WarehouseEntry.CalcSums("Qty. (Base)");
    end;

    local procedure GetBin(LocationCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
        BinType: Record "Bin Type";
    begin
        BinType.SetRange(Pick, true);
        BinType.SetRange("Put Away", true);
        BinType.FindFirst();
        Bin.SetFilter("Location Code", LocationCode);
        Bin.SetFilter("Bin Type Code", BinType.Code);
        Bin.FindFirst();
        exit(Bin.Code);
    end;

    local procedure FindWarehouseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure SelectLotNoOnWhsePick(var WhseActivityLine: Record "Warehouse Activity Line")
    var
        LookUpBinContent: Boolean;
    begin
        LookUpBinContent :=
          (WhseActivityLine."Activity Type".AsInteger() <= WhseActivityLine."Activity Type"::Movement.AsInteger()) or
          (WhseActivityLine."Action Type" <> WhseActivityLine."Action Type"::Place);
        WhseActivityLine.LookUpTrackingSummary(WhseActivityLine, LookUpBinContent, -1, "Item Tracking Type"::"Lot No.");
    end;

    local procedure VerifyLotNosOnBinQuery(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WhseEntry: Record "Warehouse Entry";
        WhseActivityLine: Record "Warehouse Activity Line";
        LotNosByBin: Query "Lot Numbers by Bin";
        "Count": Integer;
        ExpCount: Integer;
    begin
        // Check Whse Activity Line - Query consistency.

        FindWarehouseActivityLines(WhseActivityLine, SourceNo, ActivityType);
        if WhseActivityLine.FindSet() then
            repeat
                Count := 0;
                ExpCount := 0;
                GetLotQtyFromWhseEntries(
                  WhseEntry, WhseActivityLine."Item No.", WhseActivityLine."Location Code", WhseActivityLine."Bin Code",
                  WhseActivityLine."Lot No.");
                if WhseEntry."Qty. (Base)" <> 0 then
                    ExpCount := 1;

                LotNosByBin.SetRange(Item_No, WhseActivityLine."Item No.");
                LotNosByBin.SetRange(Variant_Code, WhseActivityLine."Variant Code");
                LotNosByBin.SetRange(Location_Code, WhseActivityLine."Location Code");
                LotNosByBin.SetRange(Bin_Code, WhseActivityLine."Bin Code");
                LotNosByBin.SetRange(Lot_No, WhseActivityLine."Lot No.");
                LotNosByBin.Open();

                while LotNosByBin.Read() do begin
                    Assert.AreEqual(
                      WhseEntry."Qty. (Base)", LotNosByBin.Sum_Qty_Base, WhseActivityLine."Bin Code" + '-' + WhseActivityLine."Lot No.");
                    Count += 1;
                end;

                Assert.AreEqual(
                  ExpCount, Count, 'Query returned wrong no. of rows for ' + WhseActivityLine."Bin Code" + '-' + WhseActivityLine."Lot No.");
            until WhseActivityLine.Next() = 0;

        // Check Query - Whse Activity Line consistency.
        WhseActivityLine.FindFirst();
        LotNosByBin.SetRange(Item_No, WhseActivityLine."Item No.");
        LotNosByBin.SetRange(Variant_Code, WhseActivityLine."Variant Code");
        LotNosByBin.SetRange(Location_Code, WhseActivityLine."Location Code");
        LotNosByBin.Open();

        while LotNosByBin.Read() do begin
            GetLotQtyFromWhseEntries(WhseEntry, LotNosByBin.Item_No, LotNosByBin.Location_Code, LotNosByBin.Bin_Code, LotNosByBin.Lot_No);
            Assert.AreEqual(WhseEntry."Qty. (Base)", LotNosByBin.Sum_Qty_Base, LotNosByBin.Bin_Code + '-' + LotNosByBin.Lot_No);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        if AssignLotNo then
            ItemTrackingLines."Assign Lot No.".Invoke();

        ItemTrackingLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.FILTER.SetFilter("Total Available Quantity", '>0');
        ItemTrackingSummary.OK().Invoke();
    end;
}

