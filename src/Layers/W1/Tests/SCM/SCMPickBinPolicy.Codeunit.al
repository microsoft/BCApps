codeunit 137290 "SCM Pick Bin Policy"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM] [Inventory Pick] [Pick Bin Policy]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryPickBinPolicyDefault_FallsBackToRankingIfDefaultNotSet()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy falls back to 'Bin Ranking' if it is set to 'Default' but no bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, false, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Ensure none of the bins are marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 3 inventory pick lines are created with 20, 20 and 10 quantity each
        VerifyPickLines(WarehouseActivityLine, Location.Code, 3, 50, 20);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryPickBinPolicyDefault_SelectsDefaultAndThenRanking()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy uses Bin marked as Default, if set to 'Default' and then uses Ranking for remaining quantity.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, false, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);
        BinContent.SetCurrentKey("Bin Ranking");
        BinContent.SetAscending("Bin Ranking", true);
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.FindFirst();
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] Verify max quantity is used from Bin that is marked as 'Default'
        WarehouseActivityLine.SetRange("Bin Code", BinContent."Bin Code");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, 20);

        // [THEN] 3 inventory pick lines are created and 2 lines are picked based on 'Bin Ranking'
        WarehouseActivityLine.SetRange("Bin Code");
        VerifyPickLines(WarehouseActivityLine, Location.Code, 3, 30, 20);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryPickBinPolicyRanking_DefaultBinIsNoConsidered()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy when set to 'Bin Ranking', ignores the 'Default' property on the Bin to select Bins.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Bin Ranking'.
        CreateLocationSetupWithBins(Location, false, true, false, false, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Bin Ranking";
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);
        BinContent.SetCurrentKey("Bin Ranking");
        BinContent.SetAscending("Bin Ranking", true);
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.FindFirst();
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.ModifyAll("Bin Code", '');

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 3 inventory pick lines are created
        VerifyPickLines(WarehouseActivityLine, Location.Code, 3, 50, 20);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryPickBinPolicyRanking_DefaultBinIsNoConsidered_MultipleSaleLines()
    var
        ItemWithoutDefault: Record Item;
        ItemWithDefault: Record Item;
        LowBin: Record Bin;
        HighBin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy when set to 'Bin Ranking', ignores the 'Default' property on the Bin to select Bins.
        Initialize();

        // [GIVEN] Create Location with 2 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Bin Ranking'.
        CreateLocationSetupWithBins(Location, false, true, false, false, true, 2, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Bin Ranking";
        Location.Modify(true);

        // [GIVEN] Assign Bin Ranking
        LowBin.SetRange("Location Code", Location.Code);
        LowBin.FindFirst();
        HighBin.SetRange("Location Code", Location.Code);
        HighBin.FindLast();

        LowBin."Bin Ranking" := 100;
        LowBin.Modify(true);

        HighBin."Bin Ranking" := 200;
        HighBin.Modify(true);

        // [GIVEN] Create an items.
        LibraryInventory.CreateItem(ItemWithDefault);
        LibraryInventory.CreateItem(ItemWithoutDefault);

        // [GIVEN] Both Bins have 10 quantity of each item
        CreateAndPostItemJournalLine(ItemWithoutDefault."No.", ItemWithDefault."No.",
                                     10, 10, LowBin.Code, LowBin.Code,
                                     Location.Code, "Item Ledger Entry Type"::"Positive Adjmt.");
        CreateAndPostItemJournalLine(ItemWithoutDefault."No.", ItemWithDefault."No.",
                                     10, 10, HighBin.Code, HighBin.Code,
                                     Location.Code, "Item Ledger Entry Type"::"Positive Adjmt.");

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", ItemWithoutDefault."No.");
        BinContent.ModifyAll(Default, false, true);

        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", ItemWithDefault."No.");
        BinContent.SetRange(Default, true);
        BinContent.FindFirst();

        Assert.AreEqual(BinContent."Bin Code", LowBin.Code, 'Low Bin is not the default Bin');

        // [GIVEN] Create Sales Order requesting 15 quantity of each item and make sure 'Bin Code' is empty.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, SalesLine, Location.Code, ItemWithoutDefault."No.", '', 15);
        CreateSalesLine(SalesHeader, SalesLine, Location.Code, ItemWithDefault."No.", '', 15);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.ModifyAll("Bin Code", '');

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] Make sure for both the items, 10 quantity is picked from higher ranking Bin and 5 from lower one
        WarehouseActivityLine.SetRange("Item No.", ItemWithoutDefault."No.");
        WarehouseActivityLine.SetRange("Bin Code", HighBin.Code);
        WarehouseActivityLine.SetRange(Quantity, 10);
        Assert.RecordCount(WarehouseActivityLine, 1);

        WarehouseActivityLine.SetRange("Bin Code", LowBin.Code);
        WarehouseActivityLine.SetRange(Quantity, 5);
        Assert.RecordCount(WarehouseActivityLine, 1);

        WarehouseActivityLine.SetRange("Item No.", ItemWithDefault."No.");
        WarehouseActivityLine.SetRange("Bin Code", HighBin.Code);
        WarehouseActivityLine.SetRange(Quantity, 10);
        Assert.RecordCount(WarehouseActivityLine, 1);

        WarehouseActivityLine.SetRange("Bin Code", LowBin.Code);
        WarehouseActivityLine.SetRange(Quantity, 5);
        Assert.RecordCount(WarehouseActivityLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryPickBinPolicyDefault_EmptyDefaultBinIsNoConsidered()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        EmptyBinCode: Code[20];
    begin
        // [SCENARIO] Pick Bin Policy when set to Ranking, ignores Bins that are empty.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, false, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item except the first one.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        EmptyBinCode := Bin.Code;
        Bin.Next();
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', EmptyBinCode, Item."No.", '', '');
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.ModifyAll("Bin Code", '');

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 3 inventory pick lines are created and Bins are selected based on 'Bin Ranking'
        VerifyPickLines(WarehouseActivityLine, Location.Code, 3, 50, 20);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryPickBinPolicyDefault_AlwaysCreatePickLineONCreatesPickLineWithEmptyBinCode()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        EmptyBinCode: Code[20];
    begin
        // [SCENARIO] Pick Bin Policy falls back to 'Bin Ranking' if it is set to 'Default' but no bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, false, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location."Always Create Pick Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        EmptyBinCode := Bin.Code;
        Bin.Next();
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 2, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', EmptyBinCode, Item."No.", '', '');
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.ModifyAll("Bin Code", '');

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 5 inventory pick lines are created
        VerifyPickLines(WarehouseActivityLine, Location.Code, 5, 8, 2);
        WarehouseActivityLine.SetRange("Bin Code", '');
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, 42);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryPickBinPolicyDefault_AlwaysCreatePickLineOFFDoesNotCreatesPickLineWithEmptyBinCode()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        EmptyBinCode: Code[20];
    begin
        // [SCENARIO] Pick Bin Policy falls back to 'Bin Ranking' if it is set to 'Default' but no bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, false, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location."Always Create Pick Line" := false;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        EmptyBinCode := Bin.Code;
        Bin.Next();
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 2, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', EmptyBinCode, Item."No.", '', '');
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.ModifyAll("Bin Code", '');

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 4 inventory pick lines are created
        VerifyPickLines(WarehouseActivityLine, Location.Code, 4, 8, 2);
        WarehouseActivityLine.SetRange("Bin Code", '');
        Assert.RecordCount(WarehouseActivityLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryPickBinPolicyDefault_FallsBackToRankingIfDefaultNotSet_SalesReturnOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy falls back to 'Bin Ranking' if it is set to 'Default' but no bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, false, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Ensure none of the bins are marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);

        // [GIVEN] Create Sales Return Order for -50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", Location.Code, Item."No.", -50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Return Order", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 3 inventory pick lines are created with 20, 20 and 10 quantity each
        VerifyPickLines(WarehouseActivityLine, Location.Code, 3, 50, 20);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryPickBinPolicyDefault_FallsBackToRankingIfDefaultNotSet_PurchaseOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy falls back to 'Bin Ranking' if it is set to 'Default' but no bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, false, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Ensure none of the bins are marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);

        // [GIVEN] Create Purchase Order for -50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Location.Code, Item."No.", -50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Order", PurchaseHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 3 inventory pick lines are created with 20, 20 and 10 quantity each
        VerifyPickLines(WarehouseActivityLine, Location.Code, 3, 50, 20);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryPickBinPolicyDefault_FallsBackToRankingIfDefaultNotSet_PurchaseReturnOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy falls back to 'Bin Ranking' if it is set to 'Default' but no bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, false, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Ensure none of the bins are marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);

        // [GIVEN] Create Purchase Return Order for 50 quantity of the created item.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Location.Code, Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Return Order", PurchaseHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 3 inventory pick lines are created with 20, 20 and 10 quantity each
        VerifyPickLines(WarehouseActivityLine, Location.Code, 3, 50, 20);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryPickBinPolicyDefault_AlwaysCreatePickLinesWithNoDefaultBinCreatesPickLines()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy is set to 'Default' but no bin is marked as default and 'Alway Create Pick Lines' creates lines as expected.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, false, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location."Always Create Pick Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);

        // [WHEN] Inventory Pick document lines are created.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 1 inventory pick line is for the whole quantity with 'Bin Code' as ''.
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Bin Code", '');
        WarehouseActivityLine.TestField(Quantity, 50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickBinPolicyDefault_FallsBackToRankingIfDefaultNotSet()
    var
        Item: Record Item;
        Bin: Record Bin;
        ReceiveBin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy falls back to 'Bin Ranking' if it is set to 'Default' but no bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, true, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, '', '', '');

        // [GIVEN] Ensure none of the bins are marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);

        // [GIVEN] Shipment created for the document
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Warehouse Pick is created for the shipment
        WarehouseShipmentLine.SetRange("Source Document", "Warehouse Activity Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.ModifyAll("Bin Code", ReceiveBin.Code);
        WarehouseShipmentLine.FindFirst();

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        Commit();

        // [THEN] Warehouse Pick document lines are created.
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 3 warehouse pick lines of type 'Take' are created with 20, 20 and 10 quantity each
        VerifyWarehousePickLines(WarehouseActivityLine, Location.Code, 3, 50, 20, ReceiveBin.Code);

        // [THEN] 3 warehouse pick lines of type 'Place' are created for the destination bin
        WarehouseActivityLine.SetRange("Bin Code");
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        WarehouseActivityLine.SetRange("Bin Code", ReceiveBin.Code);
        Assert.RecordCount(WarehouseActivityLine, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickBinPolicyDefault_SelectsDefaultAndThenRanking()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy uses Bin marked as Default, if set to 'Default' and then uses Ranking for remaining quantity.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, true, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);
        BinContent.SetCurrentKey("Bin Ranking");
        BinContent.SetAscending("Bin Ranking", true);
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.FindFirst();
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);

        // [GIVEN] Shipment created for the document
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Warehouse Pick is created for the shipment
        WarehouseShipmentLine.SetRange("Source Document", "Warehouse Activity Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.ModifyAll("Bin Code", Bin.Code);
        WarehouseShipmentLine.FindFirst();

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        Commit();

        // [THEN] Warehouse Pick document lines are created.
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] Verify max quantity is used from Bin that is marked as 'Default'
        WarehouseActivityLine.SetRange("Bin Code", BinContent."Bin Code");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, 20);

        WarehouseActivityLine.SetRange("Bin Code");

        // [THEN] 3 warehouse pick lines of type 'Take' are created with 20, 20 and 10 quantity each
        VerifyWarehousePickLines(WarehouseActivityLine, Location.Code, 3, 30, 20, Bin.Code);

        // [THEN] 3 warehouse pick lines of type 'Place' are created for the destination bin
        WarehouseActivityLine.Reset();
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        WarehouseActivityLine.SetRange("Bin Code", Bin.Code);
        Assert.RecordCount(WarehouseActivityLine, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickBinPolicyRanking_DefaultBinIsNotConsidered()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy when set to 'Bin Ranking', ignores the 'Default' property on the Bin to select Bins.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Bin Ranking'.
        CreateLocationSetupWithBins(Location, false, true, false, true, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Bin Ranking";
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);
        BinContent.SetCurrentKey("Bin Ranking");
        BinContent.SetAscending("Bin Ranking", true);
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.FindFirst();
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.ModifyAll("Bin Code", '');

        // [GIVEN] Shipment created for the document
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Warehouse Pick is created for the shipment
        WarehouseShipmentLine.SetRange("Source Document", "Warehouse Activity Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.ModifyAll("Bin Code", Bin.Code);
        WarehouseShipmentLine.FindFirst();

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        Commit();

        // [THEN] Warehouse Pick document lines are created.
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 3 warehouse pick lines of type 'Take' are created with 20, 20 and 10 quantity each
        VerifyPickLines(WarehouseActivityLine, Location.Code, 3, 50, 20, Bin.Code);

        // [THEN] 3 warehouse pick lines of type 'Place' are created for the destination bin
        WarehouseActivityLine.Reset();
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        WarehouseActivityLine.SetRange("Bin Code", Bin.Code);
        Assert.RecordCount(WarehouseActivityLine, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickBinPolicyRanking_DefaultBinIsNotConsidered_MultipleSaleLines()
    var
        ItemWithoutDefault: Record Item;
        ItemWithDefault: Record Item;
        LowBin: Record Bin;
        HighBin: Record Bin;
        ReceiveBin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Pick Bin Policy when set to 'Bin Ranking', ignores the 'Default' property on the Bin to select Bins.
        Initialize();

        // [GIVEN] Create Location with 2 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Bin Ranking'.
        CreateLocationSetupWithBins(Location, false, true, false, true, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Bin Ranking";
        Location.Modify(true);

        // [GIVEN] Assign Bin Ranking
        LowBin.SetRange("Location Code", Location.Code);
        LowBin.FindFirst();
        HighBin.SetRange("Location Code", Location.Code);
        HighBin.FindLast();

        LowBin."Bin Ranking" := 100;
        LowBin.Modify(true);

        HighBin."Bin Ranking" := 200;
        HighBin.Modify(true);

        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, '', '', '');

        // [GIVEN] Create an items.
        LibraryInventory.CreateItem(ItemWithDefault);
        LibraryInventory.CreateItem(ItemWithoutDefault);

        // [GIVEN] Both Bins have 10 quantity of each item
        CreateAndPostItemJournalLine(ItemWithoutDefault."No.", ItemWithDefault."No.",
                                     10, 10, LowBin.Code, LowBin.Code,
                                     Location.Code, "Item Ledger Entry Type"::"Positive Adjmt.");
        CreateAndPostItemJournalLine(ItemWithoutDefault."No.", ItemWithDefault."No.",
                                     10, 10, HighBin.Code, HighBin.Code,
                                     Location.Code, "Item Ledger Entry Type"::"Positive Adjmt.");

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", ItemWithoutDefault."No.");
        BinContent.ModifyAll(Default, false, true);

        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", ItemWithDefault."No.");
        BinContent.SetRange(Default, true);
        BinContent.FindFirst();

        Assert.AreEqual(BinContent."Bin Code", LowBin.Code, 'Low Bin is not the default Bin');

        // [GIVEN] Create Sales Order requesting 15 quantity of each item and make sure 'Bin Code' is empty.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, SalesLine, Location.Code, ItemWithoutDefault."No.", '', 15);
        CreateSalesLine(SalesHeader, SalesLine, Location.Code, ItemWithDefault."No.", '', 15);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.ModifyAll("Bin Code", '');

        // [GIVEN] Shipment created for the document
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Warehouse Pick is created for the shipment
        WarehouseShipmentLine.SetRange("Source Document", "Warehouse Activity Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.ModifyAll("Bin Code", ReceiveBin.Code);
        WarehouseShipmentLine.FindFirst();

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        Commit();

        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] Make sure for both the items, 10 quantity is picked from higher ranking Bin and 5 from lower one
        WarehouseActivityLine.SetRange("Item No.", ItemWithoutDefault."No.");
        WarehouseActivityLine.SetRange("Bin Code", HighBin.Code);
        WarehouseActivityLine.SetRange(Quantity, 10);
        Assert.RecordCount(WarehouseActivityLine, 1);

        WarehouseActivityLine.SetRange("Bin Code", LowBin.Code);
        WarehouseActivityLine.SetRange(Quantity, 5);
        Assert.RecordCount(WarehouseActivityLine, 1);

        WarehouseActivityLine.SetRange("Item No.", ItemWithDefault."No.");
        WarehouseActivityLine.SetRange("Bin Code", HighBin.Code);
        WarehouseActivityLine.SetRange(Quantity, 10);
        Assert.RecordCount(WarehouseActivityLine, 1);

        WarehouseActivityLine.SetRange("Bin Code", LowBin.Code);
        WarehouseActivityLine.SetRange(Quantity, 5);
        Assert.RecordCount(WarehouseActivityLine, 1);

        // [THEN] 3 warehouse pick lines of type 'Place' are created for the destination bin
        WarehouseActivityLine.Reset();
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        WarehouseActivityLine.SetRange("Bin Code", ReceiveBin.Code);
        Assert.RecordCount(WarehouseActivityLine, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickBinPolicyDefault_EmptyDefaultBinIsNotConsidered()
    var
        Item: Record Item;
        Bin: Record Bin;
        ReceiveBin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        EmptyBinCode: Code[20];
    begin
        // [SCENARIO] Pick Bin Policy when set to Ranking, ignores Bins that are empty.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, true, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item except the first one.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        EmptyBinCode := Bin.Code;
        Bin.Next();
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, '', '', '');

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', EmptyBinCode, Item."No.", '', '');
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.ModifyAll("Bin Code", '');

        // [GIVEN] Shipment created for the document
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Warehouse Pick is created for the shipment
        WarehouseShipmentLine.SetRange("Source Document", "Warehouse Activity Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.ModifyAll("Bin Code", ReceiveBin.Code);
        WarehouseShipmentLine.FindFirst();

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        Commit();

        // [THEN] Warehouse Pick document lines are created.
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 3 warehouse pick lines of type 'Take' are created with 20, 20 and 10 quantity each
        VerifyWarehousePickLines(WarehouseActivityLine, Location.Code, 3, 50, 20, ReceiveBin.Code);

        // [THEN] 3 warehouse pick lines of type 'Place' are created for the destination bin
        WarehouseActivityLine.SetRange("Bin Code");
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        WarehouseActivityLine.SetRange("Bin Code", ReceiveBin.Code);
        Assert.RecordCount(WarehouseActivityLine, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickBinPolicyDefault_AlwaysCreatePickLineONCreatesPickLineWithEmptyBinCode()
    var
        Item: Record Item;
        Bin: Record Bin;
        ReceiveBin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        EmptyBinCode: Code[20];
    begin
        // [SCENARIO] Pick Bin Policy falls back to 'Bin Ranking' if it is set to 'Default' but no bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, true, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location."Always Create Pick Line" := true;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        EmptyBinCode := Bin.Code;
        Bin.Next();
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 2, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, '', '', '');

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', EmptyBinCode, Item."No.", '', '');
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.ModifyAll("Bin Code", '');

        // [GIVEN] Shipment created for the document
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Warehouse Pick is created for the shipment
        WarehouseShipmentLine.SetRange("Source Document", "Warehouse Activity Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.ModifyAll("Bin Code", ReceiveBin.Code);
        WarehouseShipmentLine.FindFirst();

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        Commit();

        // [THEN] Warehouse Pick document lines are created.
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 5 warehouse pick lines of type 'Take' are created
        VerifyPickLines(WarehouseActivityLine, Location.Code, 5, 8, 2, ReceiveBin.Code);

        WarehouseActivityLine.SetRange("Bin Code", '');
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, 42);

        // [THEN] 5 warehouse pick lines of type 'Place' are created for the destination bin
        WarehouseActivityLine.Reset();
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        WarehouseActivityLine.SetRange("Bin Code", ReceiveBin.Code);
        Assert.RecordCount(WarehouseActivityLine, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickBinPolicyDefault_AlwaysCreatePickLineOFFDoesNotCreatesPickLineWithEmptyBinCode()
    var
        Item: Record Item;
        Bin: Record Bin;
        ReceiveBin: Record Bin;
        BinContent: Record "Bin Content";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        EmptyBinCode: Code[20];
    begin
        // [SCENARIO] Pick Bin Policy falls back to 'Bin Ranking' if it is set to 'Default' but no bin is marked as default.
        Initialize();

        // [GIVEN] Create Location with 5 bins with different Bin Rankings but no bin is marked as default and the 'Pick Bin Policy' is set to 'Default'.
        CreateLocationSetupWithBins(Location, false, true, false, true, true, 5, true); // Create Location with Require Pick and Bin Mandatory.
        Location."Pick Bin Policy" := Location."Pick Bin Policy"::"Default Bin";
        Location."Always Create Pick Line" := false;
        Location.Modify(true);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        EmptyBinCode := Bin.Code;
        Bin.Next();
        repeat
            CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 2, Location.Code, Bin.Code, false);
        until Bin.Next() = 0;
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, '', '', '');

        // [GIVEN] Ensure bin with lowest Ban Ranking is marked as 'Default'
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.ModifyAll(Default, false, true);

        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', EmptyBinCode, Item."No.", '', '');
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create Sales Order for 50 quantity of the created item.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", 50, false);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.ModifyAll("Bin Code", '');

        // [GIVEN] Shipment created for the document
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Warehouse Pick is created for the shipment
        WarehouseShipmentLine.SetRange("Source Document", "Warehouse Activity Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.ModifyAll("Bin Code", ReceiveBin.Code);
        WarehouseShipmentLine.FindFirst();

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        Commit();

        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 4 inventory pick lines are created
        VerifyPickLines(WarehouseActivityLine, Location.Code, 4, 8, 2);
        WarehouseActivityLine.SetRange("Bin Code", '');
        Assert.RecordCount(WarehouseActivityLine, 0);

        // [THEN] 4 warehouse pick lines of type 'Place' are created for the destination bin
        WarehouseActivityLine.Reset();
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        WarehouseActivityLine.SetRange("Bin Code", ReceiveBin.Code);
        Assert.RecordCount(WarehouseActivityLine, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickQtyWithAlwaysCreatePickAndAlternateUoM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Bin: Record Bin;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty, QtyPer : Decimal;
    begin
        // [FEATURE] [Always Create Pick] [Unit of Measure]
        // [SCENARIO 492010] Correct unit of measure conversion on warehouse pick line when Always Create Pick Line is used.
        Initialize();
        Qty := 2;
        QtyPer := 5;

        CreateLocationSetupWithBins(Location, false, true, false, true, true, 5, false);
        Location."Always Create Pick Line" := true;
        Location.Modify(true);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPer);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", Qty, false);

        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WarehouseShipmentLine.SetRange("Source Document", "Warehouse Activity Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.ModifyAll("Bin Code", Bin.Code);
        WarehouseShipmentLine.FindFirst();

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField(Quantity, Qty);
        WarehouseActivityLine.TestField("Qty. (Base)", Qty * QtyPer);
        WarehouseActivityLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);

        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.TestField(Quantity, Qty);
        WarehouseActivityLine.TestField("Qty. (Base)", Qty * QtyPer);
        WarehouseActivityLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Pick Bin Policy");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Pick Bin Policy");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.SavePurchasesSetup();

        NoSeriesSetup();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Pick Bin Policy");
    end;

    local procedure VerifyPickLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; ExpectedPickLines: Integer; TotalQuantity: Decimal; LineQuantity: Decimal)
    begin
        VerifyPickLines(WarehouseActivityLine, LocationCode, ExpectedPickLines, TotalQuantity, LineQuantity, '');
    end;

    local procedure VerifyPickLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; ExpectedPickLines: Integer; TotalQuantity: Decimal; LineQuantity: Decimal; ShipBinCode: Code[20])
    var
        BinContent: Record "Bin Content";
        VerifiedQuantity: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [THEN] Expected number of inventory pick lines are created
        Assert.RecordCount(WarehouseActivityLine, ExpectedPickLines);

        // [THEN] Bins are selected based on the Bin Ranking
        BinContent.SetCurrentKey("Bin Ranking");
        BinContent.SetAscending("Bin Ranking", false);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.FindFirst();
        repeat
            if BinContent."Bin Code" <> ShipBinCode then begin
                if (TotalQuantity - VerifiedQuantity) >= LineQuantity then
                    ExpectedQuantity := LineQuantity
                else
                    ExpectedQuantity := TotalQuantity - VerifiedQuantity;

                WarehouseActivityLine.SetRange("Bin Code", BinContent."Bin Code");
                WarehouseActivityLine.FindFirst();

                WarehouseActivityLine.TestField(Quantity, ExpectedQuantity);
                VerifiedQuantity += LineQuantity;
            end;
        until (BinContent.Next() = 0) or (VerifiedQuantity >= TotalQuantity);
    end;

    local procedure VerifyWarehousePickLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; ExpectedPickLines: Integer; TotalQuantity: Decimal; LineQuantity: Decimal; ShipBinCode: Code[20])
    var
        BinContent: Record "Bin Content";
        VerifiedQuantity: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // [THEN] Expected number of inventory pick lines are created
        Assert.RecordCount(WarehouseActivityLine, ExpectedPickLines);

        // [THEN] Bins are selected based on the Bin Ranking
        BinContent.SetCurrentKey(Default, "Location Code", "Item No.", "Variant Code", "Bin Code");
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.FindFirst();
        repeat
            if BinContent."Bin Code" <> ShipBinCode then begin
                if (TotalQuantity - VerifiedQuantity) >= LineQuantity then
                    ExpectedQuantity := LineQuantity
                else
                    ExpectedQuantity := TotalQuantity - VerifiedQuantity;

                WarehouseActivityLine.SetRange("Bin Code", BinContent."Bin Code");
                WarehouseActivityLine.FindFirst();

                WarehouseActivityLine.TestField(Quantity, ExpectedQuantity);
                VerifiedQuantity += LineQuantity;
            end;
        until (BinContent.Next() = 0) or (VerifiedQuantity >= TotalQuantity);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure CreateLocationSetupWithBins(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean; NoOfBins: Integer; UseBinRanking: Boolean)
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NoOfBins, false); // Value required.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        if UseBinRanking then begin
            Bin.SetRange("Location Code", Location.Code);
            if Bin.FindSet() then
                repeat
                    Bin.Validate("Bin Ranking", LibraryRandom.RandIntInRange(100, 1000));
                    Bin.Modify(true);
                until Bin.Next() = 0;
        end;
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibrarySales.SetOrderNoSeriesInSetup();
        InventorySetup.Get();
        InventorySetup."Inventory Put-away Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        InventorySetup."Inventory Pick Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        InventorySetup.Modify(true);
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate: Record "Item Journal Template"; var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal;
                                                                                  LocationCode: Code[10];
                                                                                  BinCode: Code[20];
                                                                                  UseTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        if UseTracking then
            ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo1: Code[20]; ItemNo2: Code[20];
                                                 Quantity1: Decimal; Quantity2: Decimal;
                                                 BinCode1: Code[20]; BinCode2: Code[20];
                                                 LocationCode: Code[10]; EntryType: Enum "Item Ledger Entry Type")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo1,
          Quantity1);
        ItemJournalLine.Validate("Location Code", LocationCode);
        if BinCode1 <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode1);
        ItemJournalLine.Modify(true);

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo2,
          Quantity2);
        ItemJournalLine.Validate("Location Code", LocationCode);
        if BinCode2 <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode2);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndReleaseSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10];
                                                                                                            ItemNo: Code[20];
                                                                                                            Quantity: Decimal;
                                                                                                            UseTraking: Boolean)
    var
        SalesLine: Record "Sales Line";
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        CreateSalesLine(SalesHeader, SalesLine, LocationCode, ItemNo, '', Quantity);
        if UseTraking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
            SalesLine.OpenItemTrackingLines();
        end;
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; LocationCode: Code[10];
                                                                                                            ItemNo: Code[20];
                                                                                                            Quantity: Decimal;
                                                                                                            UseTraking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LocationCode, ItemNo, '', Quantity);
        if UseTraking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
            PurchaseLine.OpenItemTrackingLines();
        end;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
    end;
}

