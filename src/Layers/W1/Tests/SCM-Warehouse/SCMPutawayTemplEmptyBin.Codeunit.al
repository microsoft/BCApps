codeunit 137933 "SCM Put-away Templ. Empty Bin"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure T01_FindEmptyBinDoesNotSuggestFirstBin()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
    begin
        // [SCENARIO #01] A put-away template with "Find Empty Bin" must suggest an empty bin

        // [GIVEN] An item.
        // [GIVEN] A warehouse location with Bin Mandatory, Require Receive, Require Put-away, Require Shipment and Require Pick enabled.
        // [GIVEN] Bin A1 and bin C1 contain inventory.
        // [GIVEN] Bin B1 is empty.
        // [GIVEN] RECEIPT is configured as the Receipt Bin and SHIP is configured as the Shipment Bin.
        // [GIVEN] A Put-away Template configured with Find Floating Bin and Find Empty Bin.
        // [GIVEN] Always Create Put-away Line is enabled.
        Initialize();
        CreateBaseData();
        ConfigureTemplate(false, true, false, false, false, true);
        SetAlwaysCreatePutAwayLine(true);

        // [WHEN] A warehouse receipt is posted.
        CreateAndPostWarehouseReceipt();

        // [THEN] A single place line is created.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Action Type", "Warehouse Action Type"::Place);
        LibraryAssert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        // [THEN] The empty bin B1 is selected.
        LibraryAssert.AreEqual(EmptyBin.Code, WarehouseActivityLine."Bin Code", 'Wrong Bin Code');

        // [THEN] The suggested bin is empty
        Bin.Get(LocationCode, WarehouseActivityLine."Bin Code");
        LibraryAssert.IsTrue(Bin.Empty, 'Suggested bin must be empty');
    end;

    [Test]
    procedure T02_FindBinContentDoesNotSuggestReceiptOrShipmentBin()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO #02] Receipt and shipment bins are excluded when searching through Bin Content.

        // [GIVEN] A warehouse setup with Receipt and Shipment bins configured. Shipment bin has the highest ranking. Shipment bin contains inventory.
        // [GIVEN] A Put-away Template configured with Find Same Item.
        // [GIVEN] Always Create Put-away Line is enabled.
        Initialize();
        CreateBaseData();
        ConfigureBinTopCandidates();
        AddInventoryToBin(ShipmentBin.Code, LibraryRandom.RandIntInRange(5, 10));
        ConfigureTemplate(false, true, true, false, false, false);
        SetAlwaysCreatePutAwayLine(true);

        // [WHEN] A warehouse receipt is posted.
        CreateAndPostWarehouseReceipt();

        // [THEN] A place line is created.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Action Type", "Warehouse Action Type"::Place);
        LibraryAssert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        // [THEN] The Receipt Bin is not selected.
        LibraryAssert.AreNotEqual(ReceiptBin.Code, WarehouseActivityLine."Bin Code", 'Receipt bin must not be selected.');
        // [THEN] The Shipment Bin is not selected.
        LibraryAssert.AreNotEqual(ShipmentBin.Code, WarehouseActivityLine."Bin Code", 'Shipment bin must not be selected.');
        // [THEN] Assert exact bin - StockedBinC is selected.
        LibraryAssert.AreEqual(StockedBinC.Code, WarehouseActivityLine."Bin Code", 'Expected StockedBinC as the destination bin.');
    end;

    [Test]
    procedure T03_NoEligibleBinAlwaysCreatePutAwayLineTrue()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO #03] A fallback put-away line is created when no eligible bin exists and Always Create Put-away Line is enabled.

        // [GIVEN] A Put-away Template configured with Find Empty Bin.
        // [GIVEN] No empty bins are available.
        // [GIVEN] Always Create Put-away Line is enabled.
        Initialize();
        CreateBaseData();
        ConfigureTemplate(false, true, false, false, false, true);
        ConfigureNoEligibleBinScenario();
        SetAlwaysCreatePutAwayLine(true);

        // [WHEN] A warehouse receipt is posted.
        CreateAndPostWarehouseReceipt();

        // [THEN] A single place line is created.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Action Type", "Warehouse Action Type"::Place);
        LibraryAssert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        // [THEN] The place line is created without a destination bin.
        LibraryAssert.AreEqual('', WarehouseActivityLine."Bin Code", 'Expected fallback put-away line.');
    end;

    [Test]
    procedure T04_NoEligibleBinAlwaysCreatePutAwayLineFalse()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO #04] No put-away line is created when no eligible bin exists and Always Create Put-away Line is disabled.

        // [GIVEN] A Put-away Template configured with Find Empty Bin.
        // [GIVEN] No empty bins are available.
        // [GIVEN] Always Create Put-away Line is disabled.
        Initialize();
        CreateBaseData();
        ConfigureTemplate(false, true, false, false, false, true);
        ConfigureNoEligibleBinScenario();
        SetAlwaysCreatePutAwayLine(false);

        // [WHEN] A warehouse receipt is posted.
        CreateAndPostWarehouseReceipt();

        // [THEN] No place line is created.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Action Type", "Warehouse Action Type"::Place);
        LibraryAssert.RecordCount(WarehouseActivityLine, 0);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Put-away Templ. Empty Bin");
        ClearLastError();

        LibraryRandom.Init();
        GlobalLanguage(1033);
    end;

    local procedure CreateBaseData()
    begin
        LibraryInventory.CreateItem(Item);
        CreateLocation();
        CreateBins();
        AddInventory();
    end;

    local procedure CreateLocation()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Put-away", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Pick", true);
        Location.Modify(true);
        LocationCode := Location.Code;
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);
    end;

    local procedure CreateBins()
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateBin(StockedBinA, LocationCode, 'A1', '', '');
        LibraryWarehouse.CreateBin(EmptyBin, LocationCode, 'B1', '', '');
        LibraryWarehouse.CreateBin(StockedBinC, LocationCode, 'C1', '', '');
        LibraryWarehouse.CreateBin(ReceiptBin, LocationCode, 'RECEIPT', '', '');
        LibraryWarehouse.CreateBin(ShipmentBin, LocationCode, 'SHIP', '', '');
        Location.Get(LocationCode);

        Location.Validate("Receipt Bin Code", ReceiptBin.Code);
        Location.Validate("Shipment Bin Code", ShipmentBin.Code);
        Location.Validate("Put-away Bin Policy", "Put-away Bin Policy"::"Put-away Template");

        Location.Modify(true);
    end;

    local procedure AddInventory()
    begin
        AddInventoryToBin(StockedBinA.Code, LibraryRandom.RandIntInRange(5, 10));
        AddInventoryToBin(StockedBinC.Code, LibraryRandom.RandIntInRange(5, 10));
    end;


    local procedure ConfigureTemplate(FindFixedBin: Boolean; FindFloatingBin: Boolean; FindSameItem: Boolean; FindUnitOfMeasureMatch: Boolean; FindBinLessThanMinQty: Boolean; FindEmptyBin: Boolean)
    var
        Location: Record Location;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
    begin
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, FindFixedBin, FindFloatingBin, FindSameItem, FindUnitOfMeasureMatch, FindBinLessThanMinQty, FindEmptyBin);
        Location.Get(LocationCode);
        Location.Validate("Put-away Template Code", PutAwayTemplateHeader.Code);
        Location.Modify(true);
    end;

    local procedure SetAlwaysCreatePutAwayLine(Value: Boolean)
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        Location.Validate("Always Create Put-away Line", Value);
        Location.Modify(true);
    end;

    local procedure AddInventoryToBin(BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationCode, BinCode, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostWarehouseReceipt()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Order, '', Item."No.", 1, LocationCode, 0D);
        WarehouseReceiptHeader.Get(CreateWarehouseReceiptNo(PurchaseHeader));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    procedure CreateWarehouseReceiptNo(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        if PurchaseHeader.Status = PurchaseHeader.Status::Open then
            LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptLine.SetRange("Source Document", "Warehouse Activity Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseReceiptLine.SetLoadFields("No.");
        WarehouseReceiptLine.FindFirst();
        exit(WarehouseReceiptLine."No.");
    end;

    local procedure ConfigureNoEligibleBinScenario()
    begin
        AddInventoryToBin(EmptyBin.Code, 1);
        AddInventoryToBin(ReceiptBin.Code, 1);
        AddInventoryToBin(ShipmentBin.Code, 1);
    end;

    local procedure ConfigureBinTopCandidates()
    begin
        ShipmentBin.Validate("Bin Ranking", 30);
        ShipmentBin.Modify();

        StockedBinC.Validate("Bin Ranking", 20);
        StockedBinC.Modify();

        StockedBinA.Validate("Bin Ranking", 10);
        StockedBinA.Modify();
    end;


    var
        Item: Record Item;
        EmptyBin: Record Bin;
        ReceiptBin: Record Bin;
        ShipmentBin: Record Bin;
        StockedBinA: Record Bin;
        StockedBinC: Record Bin;
        LibraryAssert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LocationCode: Code[10];
}
