codeunit 137006 "SCM Put-away Templ. Empty Bin"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] Put-away template - find empty bin
        isInitialized := false;
    end;

    [Test]
    procedure T01_FindEmptyBinDoesNotSuggestFirstBin()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
    begin
        // [SCENARIO #01] A put-away template with "Find Empty Bin" must suggest an empty bin
        // [GIVEN] A basic warehouse location (Bin Mandatory, Require Receive, no Directed Put-away and Pick)
        // [GIVEN] Bins A1 (stocked), B1 (empty), C1 (stocked), RECEIPT (receipt bin) and SHIP (shipment bin)
        // [GIVEN] Put-away Bin Policy = Put-away Template with Find Floating Bin and Find Empty Bin
        Initialize();

        // [WHEN] Post a warehouse receipt so the put-away is created automatically
        CreateAndPostWarehouseReceipt();

        // [THEN] The empty bin B1 is suggested, not the first bin of the list
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Action Type", "Warehouse Action Type"::Place);
        LibraryAssert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        LibraryAssert.AreEqual(EmptyBin.Code, WarehouseActivityLine."Bin Code", 'Wrong Bin Code');

        // [THEN] The suggested bin is empty
        Bin.Get(LocationCode, WarehouseActivityLine."Bin Code");
        LibraryAssert.IsTrue(Bin.Empty, 'Suggested bin must be empty');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Put-away Templ. Empty Bin");
        ClearLastError();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Put-away Templ. Empty Bin");
        LibraryRandom.Init();
        CreateData();
        GlobalLanguage(1033);
        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Put-away Templ. Empty Bin");
    end;

    local procedure CreateData()
    var
        Location: Record Location;
        StockedBinA: Record Bin;
        StockedBinC: Record Bin;
        ReceiptBin: Record Bin;
        ShipmentBin: Record Bin;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, false, true, false, false, false, true);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Put-away", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Pick", true);
        Location.Modify(true);
        LocationCode := Location.Code;
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);

        LibraryWarehouse.CreateBin(StockedBinA, LocationCode, 'A1', '', '');
        LibraryWarehouse.CreateBin(EmptyBin, LocationCode, 'B1', '', '');
        LibraryWarehouse.CreateBin(StockedBinC, LocationCode, 'C1', '', '');
        LibraryWarehouse.CreateBin(ReceiptBin, LocationCode, 'RECEIPT', '', '');
        LibraryWarehouse.CreateBin(ShipmentBin, LocationCode, 'SHIP', '', '');

        Location.Validate("Receipt Bin Code", ReceiptBin.Code);
        Location.Validate("Shipment Bin Code", ShipmentBin.Code);
        Location.Validate("Put-away Bin Policy", "Put-away Bin Policy"::"Put-away Template");
        Location.Validate("Put-away Template Code", PutAwayTemplateHeader.Code);
        Location.Validate("Always Create Put-away Line", true);
        Location.Modify(true);

        AddInventoryToBin(StockedBinA.Code, LibraryRandom.RandIntInRange(5, 10));
        AddInventoryToBin(StockedBinC.Code, LibraryRandom.RandIntInRange(5, 10));
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

    var
        Item: Record Item;
        EmptyBin: Record Bin;
        LibraryAssert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        LocationCode: Code[10];
}
