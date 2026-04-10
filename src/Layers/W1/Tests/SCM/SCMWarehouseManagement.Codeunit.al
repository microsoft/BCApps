codeunit 137064 "SCM Warehouse Management"
{
    EventSubscriberInstance = Manual;

    Permissions = TableData "Item Ledger Entry" = rimd,
                  TableData "Warehouse Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        Initialized := false;
    end;

    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationSilver: Record Location;
        LocationOrange: Record Location;
        LocationGreen: Record Location;
        LocationWhite: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        WhseShipmentRelease: Codeunit "Whse.-Shipment Release";
        Initialized: Boolean;
        WarehouseOperations: Label 'The entered information may be disregarded by warehouse activities.';
        PutAwayActivitiesCreated: Label 'Number of Invt. Put-away activities created: 1 out of a total of 1.';
        CountWarehouseLineError: Label 'Number of Warehouse Shipment Line must be same.  ';
        CountWarehouseReceiptLineError: Label 'Number of Warehouse Receipt Line must be same.  ';
        ShippingAdvice: Label 'Shipping Advice field is set to Complete';
        WarehouseClassMsg: Label 'Warehouse Class Code must be ';
        ReceiptSpecialWarehouse: Label 'One or more of the lines on this Warehouse Receipt Header require special warehouse handling. The Bin Code for such lines has been set to blank.';
        ProductionSpecialWarehouse: Label 'One or more of the lines on this Production Order require special warehouse handling. The Bin Code for these lines has been set to blank.';
        BinCodeBlankedError: Label 'Bin Code should be blanked for prod. line as it does not match class code.';
        CountComponentsError: Label 'There should be 2 components.';
        NothingToHandleMsg: Label 'There is nothing to handle.';
        QtyAvailMustBeZeroErr: Label 'Quantity available to pick must be 0.';
        BinErr: Label 'Incorrect Bin';
        QtyErr: Label 'Incorrect Quantity';
        FilterError: Label 'Location code based filter value is incorrect.';

    [Test]
    [Scope('OnPrem')]
    procedure RenameBinOnSales()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BinCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Existing order line should get new Bin Code after Bin Code is renamed.
        // Setup.
        Initialize();
        BinCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code)));
        LibraryInventory.CreateItem(Item);
        CreateBinAndBinContent(Bin, LocationSilver.Code, Item."No.", Item."Base Unit of Measure", true);

        CreateSalesHeader(SalesHeader, '', '', SalesHeader."Shipping Advice"::Partial);
        CreateSalesLine(SalesHeader, SalesLine, Item."No.", LocationSilver.Code, LibraryRandom.RandInt(5));

        // Exercise: Rename Bin Code.
        Bin2.Get(LocationSilver.Code, Bin.Code);
        Bin2.Rename(LocationSilver.Code, BinCode);

        // Verify: Verify Sales line with the new Bin Code.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Bin Code", BinCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameBinOnPurchase()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BinCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Existing order line should get new Bin Code after Bin Code is renamed.
        // Setup.
        Initialize();
        BinCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code)));
        LibraryInventory.CreateItem(Item);
        CreateBinAndBinContent(Bin, LocationSilver.Code, Item."No.", Item."Base Unit of Measure", true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item."No.", LocationSilver.Code, LibraryRandom.RandInt(10));

        // Exercise: Rename Bin Code.
        Bin2.Get(LocationSilver.Code, Bin.Code);
        Bin2.Rename(LocationSilver.Code, BinCode);

        // Verify: Verify Purchase line with the new Bin Code.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.TestField("Bin Code", BinCode);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseReceiptFixedBin()
    var
        Location: Record Location;
    begin
        // Verify Bin Code after creating Warehouse Receipt from Purchase Order: Default Bin Selection - Fixed Bin.
        // Setup.
        Initialize();
        WhseReceiptFromPurchaseOrder(Location."Default Bin Selection"::"Fixed Bin");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseReceiptLastUsedBin()
    var
        Location: Record Location;
    begin
        // Verify Bin Code after creating Warehouse Receipt from Purchase Order: Default Bin Selection - Last-Used Bin.
        // Setup.
        Initialize();
        WhseReceiptFromPurchaseOrder(Location."Default Bin Selection"::"Last-Used Bin");
    end;

    local procedure WhseReceiptFromPurchaseOrder(DefaultBinSelection: Enum "Location Default Bin Selection")
    var
        Item: Record Item;
        Item2: Record Item;
        BinRecv: Record Bin;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        UpdateLocation(LocationOrange, DefaultBinSelection, true);
        LibraryWarehouse.CreateBin(
          BinRecv, LocationOrange.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(BinRecv.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, BinRecv.FieldNo(Code))), '', '');
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", Item2."No.", LocationOrange.Code, BinRecv.Code, LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), Item."Base Unit of Measure");

        // Exercise: Create Warehouse Receipt.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Verify: Verify Bin on Warehouse Receipt Header and Warehouse Receipt Lines.
        VerifyWarehouseReceipt(LocationOrange);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseReceiptFixedBin()
    var
        Location: Record Location;
    begin
        // Verify Bin Code after creating Warehouse Receipt from Purchase Order and changed Bin Code on Warehouse Receipt Line: Default Bin Selection - Fixed Bin.
        // Setup.
        Initialize();
        PostWhseReceipt(Location."Default Bin Selection"::"Fixed Bin");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseReceiptLastUsedBin()
    var
        Location: Record Location;
    begin
        // Verify Bin Code after creating Warehouse Receipt from Purchase Order and changed Bin Code on Warehouse Receipt Line: Default Bin Selection - Last-Used Bin.
        // Setup.
        Initialize();
        PostWhseReceipt(Location."Default Bin Selection"::"Last-Used Bin");
    end;

    local procedure PostWhseReceipt(DefaultBinSelection: Enum "Location Default Bin Selection")
    var
        Item: Record Item;
        Item2: Record Item;
        BinRecv: Record Bin;
        BinRecv2: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        UpdateLocation(LocationOrange, DefaultBinSelection, true);
        LibraryWarehouse.FindBin(BinRecv, LocationOrange.Code, '', 3);  // Find Bin based on Bin Index.
        LibraryWarehouse.FindBin(BinRecv2, LocationOrange.Code, '', 4);

        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", Item2."No.", LocationOrange.Code, BinRecv2.Code, LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), Item."Base Unit of Measure");
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        ChangeBinCodeOnWarehouseReceiptLine(WarehouseReceiptHeader, BinRecv.Code, LocationOrange.Code);

        // Exercise: Post Warehouse Receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify that the new Bin Codes are updated on the Purchase Lines and Warehouse Activity Line.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.", Item."No.");
        PurchaseLine.TestField("Bin Code", BinRecv.Code);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.", Item2."No.");
        PurchaseLine.TestField("Bin Code", LocationOrange."Receipt Bin Code");

        FindWarehouseActivityHeader(WarehouseActivityHeader, LocationOrange.Code, WarehouseActivityHeader.Type::"Put-away");
        VerifyWarehouseActivityLine(WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, Item."No.", BinRecv.Code);
        VerifyWarehouseActivityLine(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, Item2."No.", LocationOrange."Receipt Bin Code");
        VerifyWarehouseActivityLine(WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, Item."No.", BinRecv2.Code);
        VerifyWarehouseActivityLine(WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, Item2."No.", BinRecv.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderFixedBin()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Sales Order] [Location] [Require Shipment]
        // [SCENARIO 387693] Bin Code is blank on Sales Lines when Location has "Require Shipment" and "Shipment Bin Code" set. Default Bin Selection = Fixed Bin.
        Initialize();
        SalesOrderWithBin(Location."Default Bin Selection"::"Fixed Bin");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderLastUsedBin()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Sales Order] [Location] [Require Shipment]
        // [SCENARIO 387693] Bin Code is blank on Sales Lines when Location has "Require Shipment" and "Shipment Bin Code" set. Default Bin Selection = Last-Used Bin.
        Initialize();
        SalesOrderWithBin(Location."Default Bin Selection"::"Last-Used Bin");
    end;

    local procedure SalesOrderWithBin(DefaultBinSelection: Enum "Location Default Bin Selection")
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        BinRecv: Record Bin;
        BinRecv2: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        UpdateLocation(LocationOrange, DefaultBinSelection, true);
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 3);  // Find Bin based on Bin Index.
        LibraryWarehouse.FindBin(Bin2, LocationOrange.Code, '', 4);
        LibraryWarehouse.FindBin(BinRecv, LocationOrange.Code, '', 5);
        LibraryWarehouse.FindBin(BinRecv2, LocationOrange.Code, '', 6);

        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", Item2."No.", LocationOrange.Code, BinRecv2.Code, LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), Item."Base Unit of Measure");
        CreateAndPostWhseReceipt(PurchaseHeader, BinRecv.Code, LocationOrange.Code);

        // [GIVEN] Change Bin Code in Warehouse Activity Lines and Register Warehouse Activity.
        UpdateAndRegisterWarehouseActivityLine(LocationOrange.Code, Item."No.", Item2."No.", Bin.Code, Bin2.Code);

        // [WHEN] Create Sales Order.
        CreateSalesOrder(
          SalesHeader, Item."No.", Item2."No.", LocationOrange.Code, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));

        // [THEN] Sales Line has blank Bin Code.
        FindSalesLine(SalesLine, SalesHeader."No.", Item."No.");
        VerifyBinCodeOnSalesLine(SalesLine, '', '', DefaultBinSelection);
        FindSalesLine(SalesLine, SalesHeader."No.", Item2."No.");
        VerifyBinCodeOnSalesLine(SalesLine, '', '', DefaultBinSelection);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseShipmentFixedBin()
    var
        Location: Record Location;
    begin
        // Verify Bin Code after creating Warehouse Shipment from Sales Order: Default Bin Selection - Fixed Bin.
        // Setup.
        Initialize();
        WhseShipmentFromSalesOrder(Location."Default Bin Selection"::"Fixed Bin");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseShipmentLastUsedBin()
    var
        Location: Record Location;
    begin
        // Verify Bin Code after creating Warehouse Shipment from Sales Order: Default Bin Selection - Last-Used Bin.
        // Setup.
        Initialize();
        WhseShipmentFromSalesOrder(Location."Default Bin Selection"::"Last-Used Bin");
    end;

    local procedure WhseShipmentFromSalesOrder(DefaultBinSelection: Enum "Location Default Bin Selection")
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        BinRecv: Record Bin;
        BinRecv2: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        UpdateLocation(LocationOrange, DefaultBinSelection, true);
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 3);  // Find Bin based on Bin Index.
        LibraryWarehouse.FindBin(Bin2, LocationOrange.Code, '', 4);
        LibraryWarehouse.FindBin(BinRecv, LocationOrange.Code, '', 5);
        LibraryWarehouse.FindBin(BinRecv2, LocationOrange.Code, '', 6);

        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", Item2."No.", LocationOrange.Code, BinRecv2.Code, LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), Item."Base Unit of Measure");
        CreateAndPostWhseReceipt(PurchaseHeader, BinRecv.Code, LocationOrange.Code);
        UpdateAndRegisterWarehouseActivityLine(LocationOrange.Code, Item."No.", Item2."No.", Bin.Code, Bin2.Code);

        CreateSalesOrder(
          SalesHeader, Item."No.", Item2."No.", LocationOrange.Code, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise: Create Warehouse Shipment.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Verify Bin on Warehouse Shipment Header and Warehouse Shipment Lines.
        VerifyWarehouseShipment(LocationOrange);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PickFixedBin()
    var
        Location: Record Location;
    begin
        // Verify Bin Code after creating Warehouse Shipment from Sales Order and changed Bin Code on Warehouse Shipment Line: Default Bin Selection - Fixed Bin.
        // Setup.
        Initialize();
        PickFromShipment(Location."Default Bin Selection"::"Fixed Bin");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFilterGenerationBasedOnLocationCode()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        WMSManagement: Codeunit "WMS Management";
        SCMWarehouseManagement: Codeunit "SCM Warehouse Management";
        FilterValue: Text;
    begin
        CreateLocation(Location, 'ALLOW');
        CreateLocation(Location, 'NOTALLOW');

        BindSubscription(SCMWarehouseManagement);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, '', false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, 'ALLOW', false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, 'NOTALLOW', false);

        FilterValue := WMSManagement.GetWarehouseEmployeeLocationFilter(WarehouseEmployee."User ID");
        Assert.AreEqual('''''|''ALLOW''', FilterValue, FilterError); // Expected value: "''|'ALLOW'"

        UnbindSubscription(SCMWarehouseManagement);
    end;

    local procedure CreateLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        Location.Init();
        Location.Validate(Code, LocationCode);
        Location.Validate(Name, Location.Code);
        Location.Validate("Require Shipment", true);
        Location.Insert(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnBeforeLocationIsAllowed', '', false, false)]
    local procedure OnLocationCheck(LocationCode: Code[10]; var LocationAllowed: Boolean)
    begin
        LocationAllowed := false;

        if (LocationCode = 'ALLOW') or (LocationCode = '''''') then
            LocationAllowed := true;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PickLastUsedBin()
    var
        Location: Record Location;
    begin
        // Verify Bin Code after creating Warehouse Shipment from Sales Order and changed Bin Code on Warehouse Shipment Line: Default Bin Selection - Last-Used Bin.
        // Setup.
        Initialize();
        PickFromShipment(Location."Default Bin Selection"::"Last-Used Bin");
    end;

    local procedure PickFromShipment(DefaultBinSelection: Enum "Location Default Bin Selection")
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        BinRecv: Record Bin;
        BinRecv2: Record Bin;
        BinShip: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        UpdateLocation(LocationOrange, DefaultBinSelection, true);
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 3);  // Find Bin based on Bin Index.
        LibraryWarehouse.FindBin(Bin2, LocationOrange.Code, '', 4);
        LibraryWarehouse.FindBin(BinRecv, LocationOrange.Code, '', 5);
        LibraryWarehouse.FindBin(BinRecv2, LocationOrange.Code, '', 6);
        LibraryWarehouse.FindBin(BinShip, LocationOrange.Code, '', 7);

        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", Item2."No.", LocationOrange.Code, BinRecv2.Code, LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), Item."Base Unit of Measure");
        CreateAndPostWhseReceipt(PurchaseHeader, BinRecv.Code, LocationOrange.Code);
        UpdateAndRegisterWarehouseActivityLine(LocationOrange.Code, Item."No.", Item2."No.", Bin.Code, Bin2.Code);

        CreateSalesOrder(
          SalesHeader, Item."No.", Item2."No.", LocationOrange.Code, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        ChangeBinCodeOnWarehouseShipmentLine(WarehouseShipmentHeader, BinShip.Code, LocationOrange.Code, Item."No.");

        // Exercise: Create Pick from shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify that the new Bin Codes are updated on Warehouse Activity Line.
        FindWarehouseActivityHeader(WarehouseActivityHeader, LocationOrange.Code, WarehouseActivityHeader.Type::Pick);
        VerifyWarehouseActivityLine(WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, Item."No.", BinShip.Code);
        VerifyWarehouseActivityLine(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, Item2."No.", LocationOrange."Shipment Bin Code");
        VerifyWarehouseActivityLine(WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, Item."No.", Bin.Code);
        VerifyWarehouseActivityLine(WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, Item2."No.", Bin2.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseShipmentFixedBin()
    var
        Location: Record Location;
    begin
        // [SCENARIO] Bin Code after creating Warehouse Shipment from Sales Order, changed Bin Code on Warehouse Shipment Line and Post:
        // [SCENARIO] Default Bin Selection - "Fixed Bin".
        // Setup.
        Initialize();
        PostWhseShipment(Location."Default Bin Selection"::"Fixed Bin");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseShipmentLastUsedBin()
    var
        Location: Record Location;
    begin
        // [SCENARIO] Bin Code after creating Warehouse Shipment from Sales Order, changed Bin Code on Warehouse Shipment Line and Post:
        // [SCENARIO] Default Bin Selection - "Last-Used Bin".
        // Setup.
        Initialize();
        PostWhseShipment(Location."Default Bin Selection"::"Last-Used Bin");
    end;

    local procedure PostWhseShipment(DefaultBinSelection: Enum "Location Default Bin Selection")
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        BinRecv: Record Bin;
        BinRecv2: Record Bin;
        BinShip: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        UpdateLocation(LocationOrange, DefaultBinSelection, true);
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 3);  // Find Bin based on Bin Index.
        LibraryWarehouse.FindBin(Bin2, LocationOrange.Code, '', 4);
        LibraryWarehouse.FindBin(BinRecv, LocationOrange.Code, '', 5);
        LibraryWarehouse.FindBin(BinRecv2, LocationOrange.Code, '', 6);
        LibraryWarehouse.FindBin(BinShip, LocationOrange.Code, '', 7);

        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", Item2."No.", LocationOrange.Code, BinRecv2.Code, LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10), Item."Base Unit of Measure");
        CreateAndPostWhseReceipt(PurchaseHeader, BinRecv.Code, LocationOrange.Code);
        UpdateAndRegisterWarehouseActivityLine(LocationOrange.Code, Item."No.", Item2."No.", Bin.Code, Bin2.Code);

        CreateSalesOrder(
          SalesHeader, Item."No.", Item2."No.", LocationOrange.Code, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        ChangeBinCodeOnWarehouseShipmentLine(WarehouseShipmentHeader, BinShip.Code, LocationOrange.Code, Item."No.");

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWarehouseActivityHeader(WarehouseActivityHeader, LocationOrange.Code, WarehouseActivityHeader.Type::Pick);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // Exercise: Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify that the new Bin Codes are updated on the Sales Lines.
        PostedWhseShipmentLine.SetRange("Item No.", Item."No.");
        PostedWhseShipmentLine.FindFirst();
        PostedWhseShipmentLine.TestField("Bin Code", BinShip.Code);
        PostedWhseShipmentLine.SetRange("Item No.", Item2."No.");
        PostedWhseShipmentLine.FindFirst();
        PostedWhseShipmentLine.TestField("Bin Code", LocationOrange."Shipment Bin Code");
    end;

    [Test]
    [HandlerFunctions('PutAwayMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayWithSingleBinContent()
    begin
        // Verify Bin Code in Warehouse Activity Line after creating Inventory put-away.
        // Setup.
        Initialize();
        InventoryPutAwayMultipleUOM(false);  // Boolean for Single Bin Content.
    end;

    [Test]
    [HandlerFunctions('PutAwayMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayWithMultipleBinContent()
    begin
        // Verify Bin Code in Warehouse Activity Line after creating Inventory put-away.
        // Setup.
        Initialize();
        InventoryPutAwayMultipleUOM(true);  // Boolean for Multiple Bin Content.
    end;

    local procedure InventoryPutAwayMultipleUOM(MultipleBinContent: Boolean)
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        UnitOfMeasure: Record "Unit of Measure";
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        UpdateItemWithUnitOfMeasure(UnitOfMeasure, Item."No.");

        UpdateLocation(LocationOrange, LocationOrange."Default Bin Selection"::"Fixed Bin", false);
        CreateBinAndBinContent(Bin, LocationOrange.Code, Item."No.", Item."Base Unit of Measure", false);

        if MultipleBinContent then
            CreateBinContent(BinContent, LocationOrange.Code, Bin.Code, Item."No.", UnitOfMeasure.Code, false);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", Item."No.", LocationOrange.Code, '', Quantity, Quantity, UnitOfMeasure.Code);

        // Exercise: Create Inventory Put and Pick.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, true, false);

        // Verify: Verify Warehouse Activity Line.
        VerifyWarehouseActivityLineDetails(
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away", Item."No.", UnitOfMeasure.Code, Quantity, '',
          WarehouseActivityLine."Action Type"::Place);
        VerifyWarehouseActivityLineDetails(
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away", Item."No.", Item."Base Unit of Measure", Quantity,
          '', WarehouseActivityLine."Action Type"::Place);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWhseReceiptWithSingleBinContent()
    begin
        // Verify Bin Code in Warehouse Activity Line after Posting Werehouse Receipt.
        // Setup.
        Initialize();
        PostWhseReceiptMultipleUOM(false);  // Boolean for Single Bin Content.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWhseReceiptMultipleBinContent()
    begin
        // Verify Bin Code in Warehouse Activity Line after Posting Werehouse Receipt.
        // Setup.
        Initialize();
        PostWhseReceiptMultipleUOM(true);  // Boolean for Multiple Bin Content.
    end;

    local procedure PostWhseReceiptMultipleUOM(MultipleBinContent: Boolean)
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        UnitOfMeasure: Record "Unit of Measure";
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        UpdateItemWithUnitOfMeasure(UnitOfMeasure, Item."No.");

        UpdateLocation(LocationOrange, LocationOrange."Default Bin Selection"::"Fixed Bin", true);
        CreateBinAndBinContent(Bin, LocationOrange.Code, Item."No.", Item."Base Unit of Measure", false);

        if MultipleBinContent then
            CreateBinContent(BinContent, LocationOrange.Code, Bin.Code, Item."No.", UnitOfMeasure.Code, false);

        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", Item."No.", LocationOrange.Code, '', Quantity, Quantity, UnitOfMeasure.Code);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        UpdateWarehouseReceiptLine(PurchaseHeader."No.", Bin.Code);

        // Exercise: Post Warehouse Receipt.
        FindWarehouseReceiptHeader(WarehouseReceiptHeader, LocationOrange.Code);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify Warehouse Activity Lines.
        VerifyWarehouseActivityLineDetails(
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away", Item."No.", UnitOfMeasure.Code, Quantity, Bin.Code,
          WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLineDetails(
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away", Item."No.", UnitOfMeasure.Code, Quantity, '',
          WarehouseActivityLine."Action Type"::Place);
        VerifyWarehouseActivityLineDetails(
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away", Item."No.", Item."Base Unit of Measure", Quantity,
          Bin.Code, WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLineDetails(
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away", Item."No.", Item."Base Unit of Measure", Quantity, '',
          WarehouseActivityLine."Action Type"::Place);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleSalesOrderWithShippingAdvice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Customer: Record Customer;
        Quantity: Decimal;
    begin
        // Verify Warehouse Shipment after creating multilple Sales Order With Shipping Advice as Complete.
        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        UpdateInventoryOnLocationWithWhseAdjustment(LocationWhite, Item, Quantity);

        // Create Two Sales Orders for Quantity on Location.
        CreateAndReleaseSalesOrderWithShippingAdvice(
          SalesHeader, Customer."No.", LocationWhite.Code, Item."No.", Quantity, SalesHeader."Shipping Advice"::Complete);
        CreateAndReleaseSalesOrderWithShippingAdvice(
          SalesHeader2, Customer."No.", LocationWhite.Code, Item."No.", Quantity, SalesHeader."Shipping Advice"::Complete);

        // Exercise: Create Warehouse Shipment for first Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Verify Warehouse Shipment was created.
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesHeader."Document Type");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        Assert.AreEqual(1, WarehouseShipmentLine.Count, CountWarehouseLineError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithoutInventoryOnLocation()
    begin
        // Verify Error message on Creating Warehouse Shipment If Sales Order have Shipping Advice as Complete and blank Inventory on Location.
        // Setup.
        Initialize();
        SalesOrderWhseShipment(false);  // Update Inventory as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInventoryOnBlankLocation()
    begin
        // Verify Error message on Creating Warehouse Shipment If Sales Order have Shipping Advice as Complete and blank Inventory on Location.
        // Setup.
        Initialize();
        SalesOrderWhseShipment(true);  // Update Inventory as True.
    end;

    local procedure SalesOrderWhseShipment(UpdateInventory: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndReleaseSalesOrderWithShippingAdvice(
          SalesHeader, '', LocationWhite.Code, Item."No.", LibraryRandom.RandDec(10, 2),
          SalesHeader."Shipping Advice"::Complete);

        if UpdateInventory then begin
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10 + LibraryRandom.RandDec(10, 2));
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        end;

        // Exercise: Create Warehouse Shipment From Sales Order.
        asserterror LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Verify Error message.
        Assert.IsTrue((StrPos(GetLastErrorText, ShippingAdvice) > 0) and (StrPos(GetLastErrorText, Item."No.") > 0), GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInventoryOnLocation()
    begin
        // Verify Error message on Creating Warehouse Shipment If Sales Order have Shipping Advice as Complete, multiple lines, Partial and blank Inventory on location.
        // Setup.
        Initialize();
        SalesOrderWhseShipmentWithDiffSalesLines(false);  // Update Inventory as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPartialInventoryOnLocation()
    begin
        // Verify Error message on Creating Warehouse Shipment If Sales Order have Shipping Advice as Complete, multiple lines, Partial and blank Inventory on location.
        // Setup.
        Initialize();
        SalesOrderWhseShipmentWithDiffSalesLines(true);  // Update Inventory as True.
    end;

    local procedure SalesOrderWhseShipmentWithDiffSalesLines(UpdateInventory: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Item4: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);

        // Create Sales Order with Multiple lines on location.
        CreateSalesHeader(SalesHeader, '', LocationWhite.Code, SalesHeader."Shipping Advice"::Complete);
        CreateMultipleSalesLine(SalesHeader, Item."No.", Item2."No.", Item3."No.", Quantity);
        CreateMultipleSalesLine(SalesHeader, Item."No.", Item2."No.", Item3."No.", Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Add inventory for Item and Item2 in Location.
        LibraryWarehouse.WarehouseJournalSetup(LocationWhite.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, '',
          LocationWhite."Cross-Dock Bin Code", WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 50 + Quantity);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, '',
          LocationWhite."Cross-Dock Bin Code", WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item2."No.", 50 + Quantity);
        Item4.SetRange("No.", Item."No.", Item2."No.");

        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, true);
        LibraryWarehouse.CalculateWhseAdjustment(Item4, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        if UpdateInventory then
            UpdateInventoryOnLocationWithWhseAdjustment(LocationWhite, Item3, Quantity);

        // Exercise: Create Warehouse Shipment From Sales Order.
        asserterror LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Verify Error message.
        Assert.IsTrue((StrPos(GetLastErrorText, ShippingAdvice) > 0) and (StrPos(GetLastErrorText, Item3."No.") > 0), GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityToHandleOnLocation()
    var
        Item: Record Item;
    begin
        // Verify Warehouse Shipment Line after changing Quantity to Handle On Warehouse Activity Line on Location - Green.
        // Setup: Create Item and update inventory on location.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateInventoryOnLocation(LocationGreen.Code, Item."No.", 100 + LibraryRandom.RandDec(100, 2));  // For large Quantity.
        QuantityToHandleOnWhseActivityLine(LocationGreen, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityToHandleOnFullWMSLocation()
    var
        Item: Record Item;
    begin
        // Verify Warehouse Shipment Line after changing Quantity to Handle On Warehouse Activity Line on Full WMS Location - White.
        // Setup: Create Item and update inventory on location.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateInventoryOnLocationWithWhseAdjustment(LocationWhite, Item, 100 + LibraryRandom.RandDec(100, 2));  // For large Quantity.
        QuantityToHandleOnWhseActivityLine(LocationWhite, Item);
    end;

    local procedure QuantityToHandleOnWhseActivityLine(Location: Record Location; Item: Record Item)
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
        Quantity2: Decimal;
        QtyToHandle: Decimal;
        QtyToHandle2: Decimal;
    begin
        // Create Random Quantity, Create Sales Order, Create Warehouse Shipment form Sales Order, Create Pick and update Quantity to Handle on Warehouse Activity Line.
        Quantity := 10 + LibraryRandom.RandDec(10, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);
        QtyToHandle := LibraryRandom.RandDec(5, 2);
        QtyToHandle2 := QtyToHandle + LibraryRandom.RandDec(5, 2);

        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Item."No.", Location.Code, Quantity, Quantity2);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, Location.Code);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        FindWarehouseActivityHeader(WarehouseActivityHeader, Location.Code, WarehouseActivityHeader.Type::Pick);
        UpdateQuantityToHandleOnWhseActivityLine(WarehouseActivityHeader, Quantity, QtyToHandle);
        UpdateQuantityToHandleOnWhseActivityLine(WarehouseActivityHeader, Quantity2, QtyToHandle2);

        // Exercise.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // Verify: Verify Warehouse Shipment Line for Quantities.
        VerifyWarehouseShipmentLine(WarehouseShipmentHeader."No.", Item."No.", Quantity, Quantity, QtyToHandle, QtyToHandle, 0);  // Value important for Test.
        VerifyWarehouseShipmentLine(WarehouseShipmentHeader."No.", Item."No.", Quantity2, Quantity2, QtyToHandle2, QtyToHandle2, 0);  // Value important for Test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentAutofillQtyToShipOnLocation()
    var
        Item: Record Item;
    begin
        // Verify Warehouse Shipment Line after changing Quantity to Handle On Warehouse Activity Line and Auto fill Qty to Ship on Location - Green.
        // Setup: Create Item and update inventory on location.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateInventoryOnLocation(LocationGreen.Code, Item."No.", 100 + LibraryRandom.RandDec(100, 2));  // For large Quantity.
        WhseShipmentAutofillQtyToShip(LocationGreen, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentAutofillQtyToShipOnFullWMSLocation()
    var
        Item: Record Item;
    begin
        // Verify Warehouse Shipment Line after changing Quantity to Handle On Warehouse Activity Line and Auto fill Qty to Ship on Full WMS Location - White.
        // Setup: Create Item and update inventory on location.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateInventoryOnLocationWithWhseAdjustment(LocationWhite, Item, 100 + LibraryRandom.RandDec(100, 2));  // For large Quantity.
        WhseShipmentAutofillQtyToShip(LocationWhite, Item);
    end;

    local procedure WhseShipmentAutofillQtyToShip(Location: Record Location; Item: Record Item)
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
        Quantity2: Decimal;
        QtyToHandle: Decimal;
        QtyToHandle2: Decimal;
    begin
        // Create Random Quantity, Create Sales Order, Create Warehouse Shipment form Sales Order, Create Pick and update Quantity to Handle on Warehouse Activity Line and Auto fill Quantity To Ship Warehouse Shipment.
        Quantity := 10 + LibraryRandom.RandDec(10, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);
        QtyToHandle := LibraryRandom.RandDec(5, 2);
        QtyToHandle2 := QtyToHandle + LibraryRandom.RandDec(5, 2);

        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Item."No.", Location.Code, Quantity, Quantity2);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, Location.Code);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        FindWarehouseActivityHeader(WarehouseActivityHeader, Location.Code, WarehouseActivityHeader.Type::Pick);
        UpdateQuantityToHandleOnWhseActivityLine(WarehouseActivityHeader, Quantity, QtyToHandle);
        UpdateQuantityToHandleOnWhseActivityLine(WarehouseActivityHeader, Quantity2, QtyToHandle2);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // Exercise: Auto fill Qty To Ship on Warehouse Shipment.
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);

        // Verify: Verify Warehouse Shipment Line for Quantities.
        VerifyWarehouseShipmentLine(WarehouseShipmentHeader."No.", Item."No.", Quantity, Quantity, QtyToHandle, QtyToHandle, 0);  // Value important for Test.
        VerifyWarehouseShipmentLine(WarehouseShipmentHeader."No.", Item."No.", Quantity2, Quantity2, QtyToHandle2, QtyToHandle2, 0);  // Value important for Test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToShipOnWhseShipmentLineOnLocation()
    var
        Item: Record Item;
    begin
        // Verify Warehouse Shipment Line after changing Qty to Ship On Warehouse Shipment Line, Auto fill Qty to Ship and post Shipment on Location - Green.
        // Setup: Create Item and update inventory on location.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateInventoryOnLocation(LocationGreen.Code, Item."No.", 100 + LibraryRandom.RandDec(100, 2));  // For large Quantity.;
        QtyToShipOnWhseShipmentLine(LocationGreen, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToShipOnWhseShipmentLineOnFullWMSLocation()
    var
        Item: Record Item;
    begin
        // Verify Warehouse Shipment Line after changing Qty to Ship On Warehouse Shipment Line, Auto fill Qty to Ship and post Shipment on Full WMS Location - White.
        // Setup: Create Item and update inventory on location.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateInventoryOnLocationWithWhseAdjustment(LocationWhite, Item, 100 + LibraryRandom.RandDec(100, 2));  // For large Quantity.;
        QtyToShipOnWhseShipmentLine(LocationWhite, Item);
    end;

    local procedure QtyToShipOnWhseShipmentLine(Location: Record Location; Item: Record Item)
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
        Quantity2: Decimal;
        QtyToHandle: Decimal;
        QtyToHandle2: Decimal;
        QtytoShip: Decimal;
    begin
        // Create Random Quantity, Create Sales Order, Create Warehouse Shipment form Sales Order, Create Pick and Change Quantity To Ship On Warehouse Shipment Line, Auto fill Quantity To Ship Warehouse Shipment and Post.
        Quantity := 20 + LibraryRandom.RandDec(10, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);
        QtyToHandle := 5 + LibraryRandom.RandDec(5, 2);
        QtyToHandle2 := QtyToHandle + LibraryRandom.RandDec(5, 2);
        QtytoShip := LibraryRandom.RandDec(5, 2);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Item."No.", Location.Code, Quantity, Quantity2);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, Location.Code);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        FindWarehouseActivityHeader(WarehouseActivityHeader, Location.Code, WarehouseActivityHeader.Type::Pick);
        UpdateQuantityToHandleOnWhseActivityLine(WarehouseActivityHeader, Quantity, QtyToHandle);
        UpdateQuantityToHandleOnWhseActivityLine(WarehouseActivityHeader, Quantity2, QtyToHandle2);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);

        ChangeQtyToShipOnWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader."No.", QtytoShip);  // Change Qty to Ship on Whse Shipment line.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Exercise: Auto fill Qty To Ship on Warehouse Shipment.
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);

        // Verify: Verify Warehouse Shipment Line for Quantities.
        VerifyWarehouseShipmentLine(
          WarehouseShipmentHeader."No.", Item."No.", Quantity, Quantity - QtytoShip, QtyToHandle - QtytoShip, QtyToHandle, QtytoShip);
        VerifyWarehouseShipmentLine(WarehouseShipmentHeader."No.", Item."No.", Quantity2, Quantity2, QtyToHandle2, QtyToHandle2, 0);  // Value important for Test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseReceiptAutofillQtyToRecvOnLocation()
    begin
        // Verify Warehouse Receipt Line after changing Qty to Receive On Warehouse Receipt Line on Location - Green.
        // Setup.
        Initialize();
        WhseReceiptAutofillQtyToRecv(LocationGreen);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseReceiptAutofillQtyToRecvOnFullWMSLocation()
    begin
        // Verify Warehouse Receipt Line after changing Qty to Receive On Warehouse Receipt Line on Full WMS Location - White.
        // Setup.
        Initialize();
        WhseReceiptAutofillQtyToRecv(LocationWhite);
    end;

    local procedure WhseReceiptAutofillQtyToRecv(Location: Record Location)
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Item: Record Item;
        Quantity: Decimal;
        Quantity2: Decimal;
        QtyToReceive: Decimal;
    begin
        // Create Random Quantity, Create Purchase Order, Create Warehouse Receipt form Purchase Order, Change Qty to Receive On Whse Receipt Line.
        Quantity := 10 + LibraryRandom.RandDec(10, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);
        QtyToReceive := LibraryRandom.RandDec(5, 2);

        LibraryInventory.CreateItem(Item);
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", Item."No.", Location.Code, '', Quantity, Quantity2, Item."Base Unit of Measure");
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        FindWarehouseReceiptHeader(WarehouseReceiptHeader, Location.Code);
        ChangeQtyToReceiveOnWhseReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader."No.", QtyToReceive);  // Change Qty to Receive on Whse Receipt line.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Exercise.
        LibraryWarehouse.AutofillQtyToRecvWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify Warehouse Receipt Line for Quantities.
        VerifyWarehouseReceiptLine(WarehouseReceiptHeader."No.", Item."No.", Quantity, Quantity, Quantity, 0);
        VerifyWarehouseReceiptLine(
          WarehouseReceiptHeader."No.", Item."No.", Quantity2, Quantity2 - QtyToReceive, Quantity2 - QtyToReceive, QtyToReceive)
    end;

    [Test]
    [HandlerFunctions('ReceiptSpecialMessageHandler')]
    [Scope('OnPrem')]
    procedure WhseReceiptWithWhseClass()
    var
        Item: Record Item;
        Item2: Record Item;
        WarehouseClass: Record "Warehouse Class";
        WarehouseClass2: Record "Warehouse Class";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Bin: Record Bin;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        // Verify Blank Bin Code on Warehouse Receipt line after Get Source Documents Receipt.
        // Setup: Create two Item, Create Location, Create two different Warehouse Class Code, Create Purchase Order, Create Warehouse Receipt Header.
        Initialize();
        CreateMultipleItemWithWarehouseClass(Item, Item2, WarehouseClass, WarehouseClass2);

        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", Item2."No.", LocationWhite.Code, '', LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2), Item."Base Unit of Measure");
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        CreateBinWithWarehouseClass(Bin, LocationWhite.Code, false, false, true, false, '');
        CreateWarehouseReceiptHeader(WarehouseReceiptHeader, LocationWhite.Code, Bin.Code);
        CreateWarehouseSourceFilter(WarehouseSourceFilter, Vendor."No.");

        // Exercise.
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, LocationWhite.Code);

        // Verify: Verify Warehouse Receipt lines should be created but with blank Bin Code.
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.SetRange("Bin Code", '');
        Assert.AreEqual(2, WarehouseReceiptLine.Count, CountWarehouseReceiptLineError);
    end;

    [Test]
    [HandlerFunctions('ReceiptSpecialMessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseReceiptWithWhseClass()
    var
        Item: Record Item;
        Item2: Record Item;
        WarehouseClass: Record "Warehouse Class";
        WarehouseClass2: Record "Warehouse Class";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        // Verify Bin Code on Warehouse Receipt line after posting of Warehouse Receipt.
        // Setup: Create two Item, Create Location,Create two different Warehouse Class Codes, Create Purchase Order, Create Warehouse Receipt Header and change Bin on line.
        Initialize();
        CreateMultipleItemWithWarehouseClass(Item, Item2, WarehouseClass, WarehouseClass2);
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", Item2."No.", LocationWhite.Code, '', LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2), Item."Base Unit of Measure");
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");

        CreateBinWithWarehouseClass(Bin, LocationWhite.Code, false, false, true, false, '');
        CreateWarehouseReceiptHeader(WarehouseReceiptHeader, LocationWhite.Code, Bin.Code);
        CreateWarehouseSourceFilter(WarehouseSourceFilter, Vendor."No.");
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, LocationWhite.Code);

        // Create two Receipt bins, one for each of the Warehouse Class codes.
        CreateAndUpdateBinCodeWarehouseReceiptLine(Bin2, LocationWhite.Code, Item."No.", WarehouseClass.Code);
        CreateAndUpdateBinCodeWarehouseReceiptLine(Bin3, LocationWhite.Code, Item2."No.", WarehouseClass2.Code);
        LibraryWarehouse.AutofillQtyToRecvWhseReceipt(WarehouseReceiptHeader);
        UpdateLocationWhite(LocationWhite, true);  // Always Create Put-away Line.

        // Exercise.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify Bin Code on Warehouse Receipt line.
        VerifyPostedWhseReceiptLine(WarehouseReceiptHeader."No.", Item."No.", Bin2.Code);
        VerifyPostedWhseReceiptLine(WarehouseReceiptHeader."No.", Item2."No.", Bin3.Code);

        // TearDown.
        UpdateLocationWhite(LocationWhite, false);  // Always Create Put-away Line.
    end;

    [Test]
    [HandlerFunctions('ReceiptSpecialMessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhseActivityWithWhseClass()
    var
        Item: Record Item;
        Item2: Record Item;
        WarehouseClass: Record "Warehouse Class";
        WarehouseClass2: Record "Warehouse Class";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        // Verify Bin Code on Registered Whse Activity Line after Register Warehouse Activity.
        // Setup: Create two Item, Create Location, Create two different Warehouse Class Code, Create Purchase Order, Create Warehouse Receipt Header and change Bin on line and Post.
        Initialize();
        CreateMultipleItemWithWarehouseClass(Item, Item2, WarehouseClass, WarehouseClass2);

        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Item."No.", Item2."No.", LocationWhite.Code, '', LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2), Item."Base Unit of Measure");
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        CreateBinWithWarehouseClass(Bin, LocationWhite.Code, false, false, true, false, '');
        CreateWarehouseReceiptHeader(WarehouseReceiptHeader, LocationWhite.Code, Bin.Code);
        CreateWarehouseSourceFilter(WarehouseSourceFilter, Vendor."No.");
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, LocationWhite.Code);

        CreateAndUpdateBinCodeWarehouseReceiptLine(Bin, LocationWhite.Code, Item."No.", WarehouseClass.Code);
        CreateAndUpdateBinCodeWarehouseReceiptLine(Bin, LocationWhite.Code, Item2."No.", WarehouseClass2.Code);
        LibraryWarehouse.AutofillQtyToRecvWhseReceipt(WarehouseReceiptHeader);
        UpdateLocationWhite(LocationWhite, true);  // Always Create Put-away Line.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Exercise: Create two put-pick bins to place the put-away created Change Bin Code in Warehouse Activity Lines and Register Warehouse Activity.
        CreateBinWithWarehouseClass(Bin2, LocationWhite.Code, true, true, false, false, WarehouseClass.Code);
        CreateBinWithWarehouseClass(Bin3, LocationWhite.Code, true, true, false, false, WarehouseClass2.Code);
        UpdateAndRegisterWarehouseActivityLine(LocationWhite.Code, Item."No.", Item2."No.", Bin2.Code, Bin3.Code);

        // Verify: Verify Bin Code on Registered Whse Activity Line.
        VerifyRegisteredWhseActivityLine(LocationWhite.Code, PurchaseHeader."No.", Item."No.", Bin2.Code);
        VerifyRegisteredWhseActivityLine(LocationWhite.Code, PurchaseHeader."No.", Item2."No.", Bin3.Code);

        // TearDown.
        UpdateLocationWhite(LocationWhite, false);  // Always Create Put-away Line.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentWithWhseClass()
    var
        Item: Record Item;
        Item2: Record Item;
        WarehouseClass: Record "Warehouse Class";
        WarehouseClass2: Record "Warehouse Class";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Verify Blank Bin Code on Warehouse Shipment Line after creating Warehouse Shipment from Sales Order.
        // Setup: Create two Item, Create Location, Create the two different Warehouse Class Code and sales Order.
        Initialize();
        CreateMultipleItemWithWarehouseClass(Item, Item2, WarehouseClass, WarehouseClass2);
        CreateAndReleaseSalesOrder(
          SalesHeader, Item."No.", Item2."No.", LocationWhite.Code, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // Exercise.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Verify Bin Codes are blank on Warehouse Shipment Line.
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesLine."Document Type"::Order);
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.SetRange("Bin Code", '');
        Assert.AreEqual(2, WarehouseShipmentLine.Count, CountWarehouseLineError);
    end;

    [Test]
    [HandlerFunctions('ProductionSpecialMessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderWithWhseClass()
    var
        Item: Record Item;
        Item2: Record Item;
        WarehouseClass: Record "Warehouse Class";
        WarehouseClass2: Record "Warehouse Class";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ParentItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        Bin: Record Bin;
    begin
        // Verify Blank Bin Code on Production Order line after refresh Production Order.
        // Setup: Create two Item, Create Location, Create the two different Warehouse Class Code and Production Order.
        Initialize();
        CreateMultipleItemWithWarehouseClass(Item, Item2, WarehouseClass, WarehouseClass2);

        CreateBinWithWarehouseClass(Bin, LocationWhite.Code, false, false, false, false, '');
        LibraryInventory.CreateItem(ParentItem);
        CreateCertifiedProductionBOM(ParentItem, Item."No.", Item2."No.", WarehouseClass.Code);
        CreateProductionOrder(ProductionOrder, ParentItem."No.", LocationWhite.Code, Bin.Code);

        // Exercise.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify Blank Bin code in Prod Order Line.
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        Assert.AreEqual('', ProdOrderLine."Bin Code", BinCodeBlankedError);
        FindProdOrderComponent(ProdOrderComponent, ProdOrderLine, '');
        Assert.AreEqual(2, ProdOrderComponent.Count, CountComponentsError);
    end;

    [Test]
    [HandlerFunctions('ProductionSpecialMessageHandler')]
    [Scope('OnPrem')]
    procedure BinCodeOnProdOrderComponentError()
    var
        Item: Record Item;
        Item2: Record Item;
        WarehouseClass: Record "Warehouse Class";
        WarehouseClass2: Record "Warehouse Class";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ParentItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        Bin: Record Bin;
    begin
        // Verify error msg after changing Bin code in Prod Order Component.
        // Setup: Create two Item, Create Location, Create the two different Warehouse Class Code, Production Order change Bin Code on Prod Order Component.
        Initialize();
        CreateMultipleItemWithWarehouseClass(Item, Item2, WarehouseClass, WarehouseClass2);

        CreateBinWithWarehouseClass(Bin, LocationWhite.Code, false, false, false, false, '');
        LibraryInventory.CreateItem(ParentItem);
        CreateCertifiedProductionBOM(ParentItem, Item."No.", Item2."No.", WarehouseClass.Code);
        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", LocationWhite.Code, Bin.Code);
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        FindProdOrderComponent(ProdOrderComponent, ProdOrderLine, '');

        // Exercise: Change Bin Code on Prod Order Component.
        asserterror ProdOrderComponent.Validate("Bin Code", LocationWhite."To-Production Bin Code");

        // Verify: Verify Error Msg.
        Assert.IsTrue(StrPos(GetLastErrorText, WarehouseClassMsg) > 0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('ProductionSpecialMessageHandler')]
    [Scope('OnPrem')]
    procedure BinCodeOnProdOrderComponentWithWhseClass()
    var
        Item: Record Item;
        Item2: Record Item;
        WarehouseClass: Record "Warehouse Class";
        WarehouseClass2: Record "Warehouse Class";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ParentItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        Bin: Record Bin;
        Bin2: Record Bin;
    begin
        // Verify Bin Code on Prod Order Component after changing Bin code  with Warehouse Class Code in Prod Order Component.
        // Setup: Create two Item, Create Location, Create two different Warehouse Class Code, Production Order change Bin Code on Prod Order Component with Warehouse Class Code.
        Initialize();
        CreateMultipleItemWithWarehouseClass(Item, Item2, WarehouseClass, WarehouseClass2);

        CreateBinWithWarehouseClass(Bin, LocationWhite.Code, false, false, false, false, '');
        LibraryInventory.CreateItem(ParentItem);
        CreateCertifiedProductionBOM(ParentItem, Item."No.", Item2."No.", WarehouseClass.Code);
        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", LocationWhite.Code, Bin.Code);
        FindProdOrderLine(ProdOrderLine, ProductionOrder);

        // Exercise: Change Bin Code on Prod Order Component with Warehouse Class Code.
        UpdateBin(Bin, WarehouseClass.Code);
        FindProdOrderComponent(ProdOrderComponent, ProdOrderLine, '');
        ChangeBinCodeOnProdOrderComponent(ProdOrderComponent, Bin.Code);

        CreateBinWithWarehouseClass(Bin2, LocationWhite.Code, false, false, false, false, WarehouseClass2.Code);
        ProdOrderComponent.FindLast();
        ChangeBinCodeOnProdOrderComponent(ProdOrderComponent, Bin2.Code);

        // Verify: Verify Bin Code on Prod Order Component.
        FindProdOrderComponent(ProdOrderComponent, ProdOrderLine, Bin.Code);
        ProdOrderComponent.TestField("Bin Code", Bin.Code);
        FindProdOrderComponent(ProdOrderComponent, ProdOrderLine, Bin2.Code);
        ProdOrderComponent.TestField("Bin Code", Bin2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedBinContentAffectsAvailability_WMS_NoLots()
    begin
        WMS_Scenario(0); // No lots
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedBinContentAffectsAvailability_WMS_SameLot()
    begin
        WMS_Scenario(1); // Same lot
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedBinContentAffectsAvailability_WMS_DiffLots()
    begin
        WMS_Scenario(2); // Different lots
    end;

    local procedure WMS_Scenario(LotType: Option)
    var
        Location: Record Location;
        Item: Record Item;
        BinContentBlocked: Record "Bin Content";
        BinContentUnblocked: Record "Bin Content";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        CreatePick: Codeunit "Create Pick";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create two bin contents - one of which is blocked - to hold lot tracked item.
        Initialize();

        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        Item."Item Tracking Code" := VSTF323171_CreateItemTrackingCode(LotType, false);
        Item.Modify();

        CreateItemTrackingNos(LotBlocked, LotUnblocked, LotType);
        BlockedQty := LibraryRandom.RandDecInDecimalRange(1, 10, 1);
        VSTF323171_CreateBinContent(true, BinContentBlocked, Location.Code, Item."No.", LotBlocked, '', BlockedQty, true);
        UnblockedQty := LibraryRandom.RandDecInDecimalRange(BlockedQty + 1, 100, 1);
        VSTF323171_CreateBinContent(true, BinContentUnblocked, Location.Code, Item."No.", LotUnblocked, '', UnblockedQty, false);

        // EXERCISE & VERIFY: Get availability and verify that only the unblocked qty is available.
        case LotType of
            0: // No lots
                begin
                    WhseItemTrackingLine."Serial No." := '';
                    WhseItemTrackingLine."Lot No." := '';
                    Assert.AreEqual(
                      UnblockedQty,
                      CreatePick.CalcTotalAvailQtyToPick(BinContentBlocked."Location Code", BinContentBlocked."Item No.",
                        BinContentBlocked."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
                      '');
                end;
            1: // Same lot
                begin
                    WhseItemTrackingLine."Serial No." := '';
                    WhseItemTrackingLine."Lot No." := LotBlocked;
                    Assert.AreEqual(
                      UnblockedQty,
                      CreatePick.CalcTotalAvailQtyToPick(BinContentBlocked."Location Code", BinContentBlocked."Item No.",
                        BinContentBlocked."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
                      '');
                end;
            2: // Different lots
                begin
                    WhseItemTrackingLine."Serial No." := '';
                    WhseItemTrackingLine."Lot No." := LotBlocked;
                    Assert.AreEqual(
                      0,
                      CreatePick.CalcTotalAvailQtyToPick(BinContentBlocked."Location Code", BinContentBlocked."Item No.",
                        BinContentBlocked."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
                      '');
                end;
        end;
    end;

    local procedure CreateItemTrackingNos(var LotBlocked: Code[10]; var LotUnblocked: Code[10]; LotType: Option)
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        case LotType of
            0: // No lots
                begin
                    LotBlocked := '';
                    LotUnblocked := '';
                end;
            1: // Same lot
                begin
                    LotBlocked := LibraryUtility.GenerateRandomCode(WhseEntry.FieldNo("Lot No."), DATABASE::"Warehouse Entry");
                    LotUnblocked := LotBlocked;
                end;
            2: // Different lots
                begin
                    LotBlocked := LibraryUtility.GenerateRandomCode(WhseEntry.FieldNo("Lot No."), DATABASE::"Warehouse Entry");
                    LotUnblocked := LibraryUtility.GenerateRandomCode(WhseEntry.FieldNo("Lot No."), DATABASE::"Warehouse Entry");
                end;
        end;
    end;

    local procedure CreateLotNosWithBlocking(var LotBlocked: Code[10]; var LotUnblocked: Code[10]; LotType: Option; ItemNo: Code[20]; VariantCode: Code[10])
    var
        LotNoInformation: Record "Lot No. Information";
    begin
        CreateItemTrackingNos(LotBlocked, LotUnblocked, LotType);
        LotNoInformation.Init();
        LotNoInformation."Item No." := ItemNo;
        LotNoInformation."Variant Code" := VariantCode;
        LotNoInformation."Lot No." := LotBlocked;
        LotNoInformation.Blocked := true;
        LotNoInformation.Insert();
    end;

    local procedure CreateSerialNosWithBlocking(var LotBlocked: Code[10]; var LotUnblocked: Code[10]; LotType: Option; ItemNo: Code[20]; VariantCode: Code[10])
    var
        SerialNoInformation: Record "Serial No. Information";
    begin
        CreateItemTrackingNos(LotBlocked, LotUnblocked, LotType);
        SerialNoInformation.Init();
        SerialNoInformation."Item No." := ItemNo;
        SerialNoInformation."Variant Code" := VariantCode;
        SerialNoInformation."Serial No." := LotBlocked;
        SerialNoInformation.Blocked := true;
        SerialNoInformation.Insert();
    end;

    local procedure VSTF323171_CreateItemTrackingCode(LotType: Option; LotAndSerial: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if LotType = 0 then // No lots
            exit;
        ItemTrackingCode.Code := LibraryUtility.GenerateRandomCode(ItemTrackingCode.FieldNo(Code), DATABASE::"Item Tracking Code");
        ItemTrackingCode."Lot Specific Tracking" := true;
        ItemTrackingCode."Lot Warehouse Tracking" := true;
        if LotAndSerial then begin
            ItemTrackingCode."SN Specific Tracking" := true;
            ItemTrackingCode."SN Warehouse Tracking" := true;
        end;
        ItemTrackingCode.Insert();
        exit(ItemTrackingCode.Code);
    end;

    local procedure VSTF323171_CreateBinContent(ForceCreateBinContent: Boolean; var BinContent: Record "Bin Content"; LocationCode: Code[10]; ItemNo: Code[20]; LotNo: Code[10]; SerialNo: Code[10]; Qty: Decimal; Blocked: Boolean)
    var
        Bin: Record Bin;
        WhseEntry: Record "Warehouse Entry";
        WhseEntryCurrent: Record "Warehouse Entry";
    begin
        if ForceCreateBinContent then begin
            LibraryWarehouse.CreateBin(Bin, LocationCode, '', '', '');
            Clear(BinContent);
            BinContent."Location Code" := LocationCode;
            BinContent."Bin Code" := Bin.Code;
            BinContent."Item No." := ItemNo;
            if Blocked then
                BinContent."Block Movement" := BinContent."Block Movement"::Outbound;
            BinContent.Insert();
        end;

        WhseEntry.Init();
        if WhseEntryCurrent.FindLast() then
            WhseEntry."Entry No." := WhseEntryCurrent."Entry No." + 1
        else
            WhseEntry."Entry No." := 1;
        WhseEntry."Bin Code" := BinContent."Bin Code";
        WhseEntry."Item No." := BinContent."Item No.";
        WhseEntry."Location Code" := BinContent."Location Code";
        WhseEntry."Lot No." := LotNo;
        WhseEntry."Serial No." := SerialNo;
        WhseEntry."Qty. (Base)" := Qty;
        WhseEntry.Insert();
    end;

    [Test]
    [HandlerFunctions('SourceDocPageHandler')]
    [Scope('OnPrem')]
    procedure BlockedBinContentAffectsAvailability_BW_NoLots()
    begin
        BW_Scenario(0); // No lots
    end;

    [Test]
    [HandlerFunctions('SourceDocPageHandler')]
    [Scope('OnPrem')]
    procedure BlockedBinContentAffectsAvailability_BW_SameLot()
    begin
        BW_Scenario(1); // Same lot
    end;

    [Test]
    [HandlerFunctions('SourceDocPageHandler')]
    [Scope('OnPrem')]
    procedure BlockedBinContentAffectsAvailability_BW_DiffLots()
    begin
        BW_Scenario(2); // Different lots
    end;

    local procedure BW_Scenario(LotType: Option)
    var
        Location: Record Location;
        Item: Record Item;
        BinContentBlocked: Record "Bin Content";
        BinContentUnblocked: Record "Bin Content";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseRequest: Record "Warehouse Request";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create two bin contents - one of which is blocked - to hold lot tracked item.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryInventory.CreateItem(Item);
        Item."Item Tracking Code" := VSTF323171_CreateItemTrackingCode(LotType, false);
        Item.Modify();

        CreateItemTrackingNos(LotBlocked, LotUnblocked, LotType);
        BlockedQty := LibraryRandom.RandDecInDecimalRange(1, 10, 1);
        VSTF323171_CreateBinContent(true, BinContentBlocked, Location.Code, Item."No.", LotBlocked, '', BlockedQty, true);
        UnblockedQty := LibraryRandom.RandDecInDecimalRange(BlockedQty + 1, 100, 1);
        VSTF323171_CreateBinContent(true, BinContentUnblocked, Location.Code, Item."No.", LotUnblocked, '', UnblockedQty, false);

        CreateItemLedgEntry(Item."No.", Location.Code, BlockedQty, LotBlocked);
        CreateItemLedgEntry(Item."No.", Location.Code, UnblockedQty, LotUnblocked);

        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateRandomCode(WhseActivityHeader.FieldNo("No."),
            DATABASE::"Warehouse Activity Header");
        SalesHeader.Insert();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Location Code" := Location.Code;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine."Qty. to Ship" := BlockedQty + UnblockedQty;
        SalesLine."Qty. to Ship (Base)" := BlockedQty + UnblockedQty;
        SalesLine.Insert();

        if LotType in [1, 2] then begin // Same lot or Different lots
            CreateReservEntry(SalesLine, BlockedQty, LotBlocked, '');
            CreateReservEntry(SalesLine, UnblockedQty, LotUnblocked, '');
        end;

        WhseRequest.Type := WhseRequest.Type::Outbound;
        WhseRequest."Location Code" := Location.Code;
        WhseRequest."Document Status" := WhseRequest."Document Status"::Released;
        WhseRequest."Completely Handled" := false;
        WhseRequest."Source Document" := WhseRequest."Source Document"::"Sales Order";
        WhseRequest."Source No." := SalesHeader."No.";
        WhseRequest.Insert();

        WhseActivityHeader."No." := LibraryUtility.GenerateRandomCode(WhseActivityHeader.FieldNo("No."),
            DATABASE::"Warehouse Activity Header");
        WhseActivityHeader."Location Code" := Location.Code;
        WhseActivityHeader.Insert();

        // EXERCISE: Call the codeunit to create the inventory picks
        CODEUNIT.Run(CODEUNIT::"Create Inventory Pick/Movement", WhseActivityHeader);

        // VERIFY: Verify that only the pick for the unblocked qty is created.
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.AreEqual(1, WhseActivityLine.Count, '');
        case LotType of
            0: // No lots
                begin
                    Assert.IsTrue(WhseActivityLine.FindFirst(), '');
                    Assert.AreEqual(UnblockedQty, WhseActivityLine.Quantity, '');
                    Assert.AreEqual(BinContentUnblocked."Bin Code", WhseActivityLine."Bin Code", '');
                end;
            1, // same lot
            2: // Different lots
                begin
                    Assert.IsTrue(WhseActivityLine.FindFirst(), '');
                    Assert.AreEqual(UnblockedQty, WhseActivityLine.Quantity, '');
                    Assert.AreEqual(BinContentUnblocked."Bin Code", WhseActivityLine."Bin Code", '');
                    Assert.AreEqual(LotUnblocked, WhseActivityLine."Lot No.", '');
                end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SourceDocPageHandler(var SourceDocuments: Page "Source Documents"; var Response: Action)
    var
        WhseRequest: Record "Warehouse Request";
    begin
        WhseRequest.SetRange(Type, WhseRequest.Type::Outbound);
        WhseRequest.SetRange("Source Type", 0);
        WhseRequest.SetRange("Source Subtype", 0);
        WhseRequest.FindLast();
        SourceDocuments.SetRecord(WhseRequest);
        Response := ACTION::LookupOK;
    end;

    local procedure CreateItemLedgEntry(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; LotNo: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntryCurrent: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        if ItemLedgerEntryCurrent.FindLast() then
            ItemLedgerEntry."Entry No." := ItemLedgerEntryCurrent."Entry No." + 1
        else
            ItemLedgerEntry."Entry No." := 1;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Location Code" := LocationCode;
        ItemLedgerEntry.Quantity := Qty;
        ItemLedgerEntry."Lot No." := LotNo;
        ItemLedgerEntry.Insert();
    end;

    local procedure CreateReservEntry(SalesLine: Record "Sales Line"; Qty: Decimal; LotNo: Code[10]; SerialNo: Code[10])
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationEntryCurrent: Record "Reservation Entry";
    begin
        ReservationEntry.Init();
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
        if ReservationEntryCurrent.FindLast() then
            ReservationEntry."Entry No." := ReservationEntryCurrent."Entry No." + 1
        else
            ReservationEntry."Entry No." := 1;
        ReservationEntry."Source ID" := SalesLine."Document No.";
        ReservationEntry."Source Ref. No." := SalesLine."Line No.";
        ReservationEntry."Source Type" := DATABASE::"Sales Line";
        ReservationEntry."Source Subtype" := SalesLine."Document Type".AsInteger();
        ReservationEntry.Positive := false;
        ReservationEntry."Quantity (Base)" := -Qty;
        ReservationEntry."Qty. to Handle (Base)" := ReservationEntry."Quantity (Base)";
        ReservationEntry."Lot No." := LotNo;
        ReservationEntry."Serial No." := SerialNo;
        ReservationEntry.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedLotAffectsAvailabilityForPick_WMS()
    var
        BinContent: Record "Bin Content";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        CreatePick: Codeunit "Create Pick";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        SNBlocked: Code[10];
        SNUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create a bin content with two lots - one of which is blocked and the other is not.
        Initialize();

        BlockedITAffectsAvailabilityForPick_WMS(BinContent, LotBlocked, LotUnblocked, SNBlocked,
          SNUnblocked, BlockedQty, UnblockedQty, false);

        // EXERCISE & VERIFY"
        WhseItemTrackingLine."Serial No." := '';
        WhseItemTrackingLine."Lot No." := LotBlocked;
        Assert.AreEqual(
          0,
          CreatePick.CalcTotalAvailQtyToPick(BinContent."Location Code", BinContent."Item No.",
            BinContent."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
          'Get lot-specific availability and verify that the blocked lot is not available.');
        WhseItemTrackingLine."Lot No." := LotUnBlocked;
        Assert.AreEqual(
          UnblockedQty,
          CreatePick.CalcTotalAvailQtyToPick(BinContent."Location Code", BinContent."Item No.",
            BinContent."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
          'Get lot-specific availability and verify that only the unblocked lot is available.');
        WhseItemTrackingLine."Lot No." := '';
        Assert.AreEqual(
          UnblockedQty,
          CreatePick.CalcTotalAvailQtyToPick(BinContent."Location Code", BinContent."Item No.",
            BinContent."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
          'Get availability and verify that only the unblocked lot is available.');
        Assert.AreEqual(
          UnblockedQty,
          BinContent.CalcQtyAvailToPick(0),
          'Get bin content pick availability and verify that only the unblocked lot is available.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedSerialLotAffectsAvailabilityForBinContent_WMS()
    var
        BinContent: Record "Bin Content";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        CreatePick: Codeunit "Create Pick";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        SNBlocked: Code[10];
        SNUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create a bin content with two lots - one of which is blocked and the other is not.
        Initialize();

        BlockedITAffectsAvailabilityForPick_WMS(
          BinContent, LotBlocked, LotUnblocked, SNBlocked, SNUnblocked, BlockedQty, UnblockedQty, true);

        // EXERCISE & VERIFY
        WhseItemTrackingLine."Serial No." := '';
        WhseItemTrackingLine."Lot No." := LotBlocked;
        Assert.AreEqual(
          0,
          CreatePick.CalcTotalAvailQtyToPick(BinContent."Location Code", BinContent."Item No.",
            BinContent."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
          'Get lot-specific availability and verify that the blocked lot is not available.');
        WhseItemTrackingLine."Serial No." := SNBlocked;
        WhseItemTrackingLine."Lot No." := '';
        Assert.AreEqual(
          0,
          CreatePick.CalcTotalAvailQtyToPick(BinContent."Location Code", BinContent."Item No.",
            BinContent."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
          'Get lot-specific availability and verify that the blocked serial is not available.');
        WhseItemTrackingLine."Serial No." := SNBlocked;
        WhseItemTrackingLine."Lot No." := LotBlocked;
        Assert.AreEqual(
          0,
          CreatePick.CalcTotalAvailQtyToPick(BinContent."Location Code", BinContent."Item No.",
            BinContent."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
          'Get lot-specific availability and verify that the blocked lot & serial is not available.');
        WhseItemTrackingLine."Serial No." := '';
        WhseItemTrackingLine."Lot No." := LotUnBlocked;
        Assert.AreEqual(
          UnblockedQty,
          CreatePick.CalcTotalAvailQtyToPick(BinContent."Location Code", BinContent."Item No.",
            BinContent."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
          'Get lot-specific availability and verify that only the unblocked lot is available.');
        WhseItemTrackingLine."Serial No." := SNUnblocked;
        WhseItemTrackingLine."Lot No." := '';
        Assert.AreEqual(
          UnblockedQty,
          CreatePick.CalcTotalAvailQtyToPick(BinContent."Location Code", BinContent."Item No.",
            BinContent."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
          'Get lot-specific availability and verify that only the unblocked serial is available.');
        WhseItemTrackingLine."Serial No." := SNUnblocked;
        WhseItemTrackingLine."Lot No." := LotUnBlocked;
        Assert.AreEqual(
          UnblockedQty,
          CreatePick.CalcTotalAvailQtyToPick(BinContent."Location Code", BinContent."Item No.",
            BinContent."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
          'Get lot-specific availability and verify that only the unblocked lot & serial is available.');
        WhseItemTrackingLine."Serial No." := '';
        WhseItemTrackingLine."Lot No." := '';
        Assert.AreEqual(
          UnblockedQty,
          CreatePick.CalcTotalAvailQtyToPick(BinContent."Location Code", BinContent."Item No.",
            BinContent."Variant Code", WhseItemTrackingLine, 0, 0, '', 0, 0, BlockedQty + UnblockedQty, false),
          'Get availability and verify that only the unblocked lot is available.');
        Assert.AreEqual(
          UnblockedQty,
          BinContent.CalcQtyAvailToPick(0),
          'Get bin content pick availability and verify that only the unblocked lot is available.');
    end;

    [Test]
    [HandlerFunctions('SourceDocPageHandler')]
    [Scope('OnPrem')]
    procedure BlockedLotAffectsAvailabilityForPick_BW_SalesWithNoLot()
    var
        BinContent: Record "Bin Content";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        SNBlocked: Code[10];
        SNUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create a bin content with two lots - one of which is blocked and the other is not.
        Initialize();

        BlockedITAffectsAvailabilityForPick_BW(
          BinContent, WhseActivityHeader, LotBlocked, LotUnblocked, SNBlocked, SNUnblocked, BlockedQty, UnblockedQty, false, false, false);

        // EXERCISE: Call the codeunit to create the inventory picks
        CODEUNIT.Run(CODEUNIT::"Create Inventory Pick/Movement", WhseActivityHeader);

        // VERIFY
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.AreEqual(1, WhseActivityLine.Count, '');
        Assert.IsTrue(WhseActivityLine.FindFirst(), '');
        Assert.AreEqual(UnblockedQty, WhseActivityLine.Quantity, '');
        Assert.AreEqual('', WhseActivityLine."Lot No.", '');
    end;

    [Test]
    [HandlerFunctions('SourceDocPageHandler,NothingToHandleMessageHandler')]
    [Scope('OnPrem')]
    procedure BlockedLotAffectsAvailabilityForPick_BW_SalesWithBlockedLot()
    var
        BinContent: Record "Bin Content";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        SNBlocked: Code[10];
        SNUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create a bin content with two lots - one of which is blocked and the other is not.
        Initialize();

        BlockedITAffectsAvailabilityForPick_BW(
          BinContent, WhseActivityHeader, LotBlocked, LotUnblocked, SNBlocked, SNUnblocked, BlockedQty, UnblockedQty, false, true, false);

        // EXERCISE: Call the codeunit to create the inventory picks
        CODEUNIT.Run(CODEUNIT::"Create Inventory Pick/Movement", WhseActivityHeader);

        // VERIFY
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.IsTrue(WhseActivityLine.IsEmpty, '');
    end;

    [Test]
    [HandlerFunctions('SourceDocPageHandler')]
    [Scope('OnPrem')]
    procedure BlockedLotAffectsAvailabilityForPick_BW_SalesWithUnblockedLot()
    var
        BinContent: Record "Bin Content";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        SNBlocked: Code[10];
        SNUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create a bin content with two lots - one of which is blocked and the other is not.
        Initialize();

        BlockedITAffectsAvailabilityForPick_BW(
          BinContent, WhseActivityHeader, LotBlocked, LotUnblocked, SNBlocked, SNUnblocked, BlockedQty, UnblockedQty, false, false, true);

        // EXERCISE: Call the codeunit to create the inventory picks
        CODEUNIT.Run(CODEUNIT::"Create Inventory Pick/Movement", WhseActivityHeader);

        // VERIFY
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.AreEqual(1, WhseActivityLine.Count, '');
        Assert.IsTrue(WhseActivityLine.FindFirst(), '');
        Assert.AreEqual(UnblockedQty, WhseActivityLine.Quantity, '');
        Assert.AreEqual(LotUnblocked, WhseActivityLine."Lot No.", '');
    end;

    [Test]
    [HandlerFunctions('SourceDocPageHandler')]
    [Scope('OnPrem')]
    procedure BlockedLotAffectsAvailabilityForPick_BW_SalesWithBlockedAndUnblockedLot()
    var
        BinContent: Record "Bin Content";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        SNBlocked: Code[10];
        SNUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create a bin content with two lots - one of which is blocked and the other is not.
        Initialize();

        BlockedITAffectsAvailabilityForPick_BW(
          BinContent, WhseActivityHeader, LotBlocked, LotUnblocked, SNBlocked, SNUnblocked, BlockedQty, UnblockedQty, false, true, true);

        // EXERCISE: Call the codeunit to create the inventory picks
        CODEUNIT.Run(CODEUNIT::"Create Inventory Pick/Movement", WhseActivityHeader);

        // VERIFY
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.AreEqual(1, WhseActivityLine.Count, '');
        Assert.IsTrue(WhseActivityLine.FindFirst(), '');
        Assert.AreEqual(UnblockedQty, WhseActivityLine.Quantity, '');
        Assert.AreEqual(LotUnblocked, WhseActivityLine."Lot No.", '');
    end;

    [Test]
    [HandlerFunctions('SourceDocPageHandler')]
    [Scope('OnPrem')]
    procedure BlockedSerialLotAffectsAvailabilityForPick_BW_SalesWithNoLot()
    var
        BinContent: Record "Bin Content";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        SNBlocked: Code[10];
        SNUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create a bin content with two lots - one of which is blocked and the other is not.
        Initialize();

        BlockedITAffectsAvailabilityForPick_BW(
          BinContent, WhseActivityHeader, LotBlocked, LotUnblocked, SNBlocked, SNUnblocked, BlockedQty, UnblockedQty, true, false, false);

        // EXERCISE: Call the codeunit to create the inventory picks
        CODEUNIT.Run(CODEUNIT::"Create Inventory Pick/Movement", WhseActivityHeader);

        // VERIFY
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.AreEqual(1, WhseActivityLine.Count, '');
        Assert.IsTrue(WhseActivityLine.FindFirst(), '');
        Assert.AreEqual(UnblockedQty, WhseActivityLine.Quantity, '');
        Assert.AreEqual('', WhseActivityLine."Lot No.", '');
        Assert.AreEqual('', WhseActivityLine."Serial No.", '');
    end;

    [Test]
    [HandlerFunctions('SourceDocPageHandler,NothingToHandleMessageHandler')]
    [Scope('OnPrem')]
    procedure BlockedSerialLotAffectsAvailabilityForPick_BW_SalesWithBlockedLot()
    var
        BinContent: Record "Bin Content";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        SNBlocked: Code[10];
        SNUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create a bin content with two lots - one of which is blocked and the other is not.
        Initialize();

        BlockedITAffectsAvailabilityForPick_BW(
          BinContent, WhseActivityHeader, LotBlocked, LotUnblocked, SNBlocked, SNUnblocked, BlockedQty, UnblockedQty, true, true, false);

        // EXERCISE: Call the codeunit to create the inventory picks
        CODEUNIT.Run(CODEUNIT::"Create Inventory Pick/Movement", WhseActivityHeader);

        // VERIFY
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.IsTrue(WhseActivityLine.IsEmpty, '');
    end;

    [Test]
    [HandlerFunctions('SourceDocPageHandler')]
    [Scope('OnPrem')]
    procedure BlockedSerialLotAffectsAvailabilityForPick_BW_SalesWithUnblockedLot()
    var
        BinContent: Record "Bin Content";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        SNBlocked: Code[10];
        SNUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create a bin content with two lots - one of which is blocked and the other is not.
        Initialize();

        BlockedITAffectsAvailabilityForPick_BW(
          BinContent, WhseActivityHeader, LotBlocked, LotUnblocked, SNBlocked, SNUnblocked, BlockedQty, UnblockedQty, true, false, true);

        // EXERCISE: Call the codeunit to create the inventory picks
        CODEUNIT.Run(CODEUNIT::"Create Inventory Pick/Movement", WhseActivityHeader);

        // VERIFY
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.AreEqual(1, WhseActivityLine.Count, '');
        Assert.IsTrue(WhseActivityLine.FindFirst(), '');
        Assert.AreEqual(UnblockedQty, WhseActivityLine.Quantity, '');
        Assert.AreEqual(LotUnblocked, WhseActivityLine."Lot No.", '');
        Assert.AreEqual(SNUnblocked, WhseActivityLine."Serial No.", '');
    end;

    [Test]
    [HandlerFunctions('SourceDocPageHandler')]
    [Scope('OnPrem')]
    procedure BlockedSerialLotAffectsAvailabilityForPick_BW_SalesWithBlockedAndUnblockedLot()
    var
        BinContent: Record "Bin Content";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        LotBlocked: Code[10];
        LotUnblocked: Code[10];
        SNBlocked: Code[10];
        SNUnblocked: Code[10];
        BlockedQty: Decimal;
        UnblockedQty: Decimal;
    begin
        // SETUP: Create a bin content with two lots - one of which is blocked and the other is not.
        Initialize();

        BlockedITAffectsAvailabilityForPick_BW(
          BinContent, WhseActivityHeader, LotBlocked, LotUnblocked, SNBlocked, SNUnblocked, BlockedQty, UnblockedQty, true, true, true);

        // EXERCISE: Call the codeunit to create the inventory picks
        CODEUNIT.Run(CODEUNIT::"Create Inventory Pick/Movement", WhseActivityHeader);

        // VERIFY
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        Assert.AreEqual(1, WhseActivityLine.Count, '');
        Assert.IsTrue(WhseActivityLine.FindFirst(), '');
        Assert.AreEqual(UnblockedQty, WhseActivityLine.Quantity, '');
        Assert.AreEqual(LotUnblocked, WhseActivityLine."Lot No.", '');
        Assert.AreEqual(SNUnblocked, WhseActivityLine."Serial No.", '');
    end;

    local procedure BlockedITAffectsAvailabilityForPick_WMS(var BinContent: Record "Bin Content"; var LotBlocked: Code[10]; var LotUnblocked: Code[10]; var SNBlocked: Code[10]; var SNUnblocked: Code[10]; var BlockedQty: Decimal; var UnblockedQty: Decimal; LotAndSerial: Boolean)
    var
        Location: Record Location;
        Item: Record Item;
    begin
        BlockedITAffectsAvailabilityForPick(
          BinContent, Location, Item, LotBlocked, LotUnblocked, SNBlocked, SNUnblocked, BlockedQty, UnblockedQty, LotAndSerial);
    end;

    local procedure BlockedITAffectsAvailabilityForPick_BW(var BinContent: Record "Bin Content"; var WhseActivityHeader: Record "Warehouse Activity Header"; var LotBlocked: Code[10]; var LotUnblocked: Code[10]; var SNBlocked: Code[10]; var SNUnblocked: Code[10]; var BlockedQty: Decimal; var UnblockedQty: Decimal; LotAndSerial: Boolean; SalesLineHasBlockedLot: Boolean; SalesLineHasUnblockedLot: Boolean)
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseRequest: Record "Warehouse Request";
        QtyToShip: Decimal;
    begin
        BlockedITAffectsAvailabilityForPick(
          BinContent, Location, Item, LotBlocked, LotUnblocked, SNBlocked, SNUnblocked, BlockedQty, UnblockedQty, LotAndSerial);
        Location."Bin Mandatory" := true;
        Location.Modify();

        CreateItemLedgEntry(Item."No.", Location.Code, BlockedQty, LotBlocked);
        CreateItemLedgEntry(Item."No.", Location.Code, UnblockedQty, LotUnblocked);

        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateRandomCode(WhseActivityHeader.FieldNo("No."),
            DATABASE::"Warehouse Activity Header");
        SalesHeader.Insert();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Location Code" := Location.Code;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        if SalesLineHasBlockedLot then
            QtyToShip += BlockedQty;
        if SalesLineHasUnblockedLot then
            QtyToShip += UnblockedQty;
        if not SalesLineHasBlockedLot and not SalesLineHasUnblockedLot then
            QtyToShip := BlockedQty + UnblockedQty;
        SalesLine."Qty. to Ship" := QtyToShip;
        SalesLine."Qty. to Ship (Base)" := QtyToShip;
        SalesLine."Bin Code" := BinContent."Bin Code";
        SalesLine.Insert();

        if SalesLineHasBlockedLot then
            CreateReservEntry(SalesLine, BlockedQty, LotBlocked, SNBlocked);
        if SalesLineHasUnblockedLot then
            CreateReservEntry(SalesLine, UnblockedQty, LotUnblocked, SNUnblocked);

        WhseRequest.Type := WhseRequest.Type::Outbound;
        WhseRequest."Location Code" := Location.Code;
        WhseRequest."Document Status" := WhseRequest."Document Status"::Released;
        WhseRequest."Completely Handled" := false;
        WhseRequest."Source Document" := WhseRequest."Source Document"::"Sales Order";
        WhseRequest."Source No." := SalesHeader."No.";
        WhseRequest.Insert();

        WhseActivityHeader."No." := LibraryUtility.GenerateRandomCode(WhseActivityHeader.FieldNo("No."),
            DATABASE::"Warehouse Activity Header");
        WhseActivityHeader."Location Code" := Location.Code;
        WhseActivityHeader.Insert();

        // EXERCISE & VERIFY: Check availability for pick
        Assert.AreEqual(
          UnblockedQty,
          BinContent.CalcQtyAvailToPick(0),
          'Get bin content pick availability and verify that only the unblocked lot is available.');
    end;

    local procedure BlockedITAffectsAvailabilityForPick(var BinContent: Record "Bin Content"; var Location: Record Location; var Item: Record Item; var LotBlocked: Code[10]; var LotUnblocked: Code[10]; var SNBlocked: Code[10]; var SNUnblocked: Code[10]; var BlockedQty: Decimal; var UnblockedQty: Decimal; LotAndSerial: Boolean)
    var
        LotTypeForDifferentLots: Integer;
    begin
        LotTypeForDifferentLots := 2;
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        Item."Item Tracking Code" := VSTF323171_CreateItemTrackingCode(LotTypeForDifferentLots, LotAndSerial);
        Item.Modify();

        CreateLotNosWithBlocking(LotBlocked, LotUnblocked, LotTypeForDifferentLots, Item."No.", '');
        if LotAndSerial then
            CreateSerialNosWithBlocking(SNBlocked, SNUnblocked, LotTypeForDifferentLots, Item."No.", '');
        if LotAndSerial then
            BlockedQty := 1
        else
            BlockedQty := LibraryRandom.RandDecInDecimalRange(1, 10, 1);
        VSTF323171_CreateBinContent(true, BinContent, Location.Code, Item."No.", LotBlocked, SNBlocked, BlockedQty, false);
        if LotAndSerial then
            UnblockedQty := 1
        else
            UnblockedQty := LibraryRandom.RandDecInDecimalRange(BlockedQty + 1, 100, 1);
        VSTF323171_CreateBinContent(false, BinContent, Location.Code, Item."No.", LotUnblocked, SNUnblocked, UnblockedQty, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBinContentWithItemTracking()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        QtyNoLotNoSerial: Decimal;
        QtyLotNoSerial: Decimal;
        QtyNoLotSerial: Decimal;
        QtyLotSerial: Decimal;
        LotNo: Code[10];
        SerialNo: Code[10];
    begin
        // See changes in VSTF 323171 for details- This is a test to check if the Bin Content gives
        // correct quantities with the filtering on item tracking
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', '');

        QtyNoLotNoSerial := LibraryRandom.RandDec(10, 2);
        QtyLotNoSerial := LibraryRandom.RandDec(100, 2);
        QtyNoLotSerial := LibraryRandom.RandDec(1000, 2);
        QtyLotSerial := LibraryRandom.RandDec(10000, 2);
        LotNo := LibraryUtility.GenerateGUID();
        SerialNo := LibraryUtility.GenerateGUID();

        CheckBinContentWithItemTrackingCreateWhseEntry(BinContent, '', '', QtyNoLotNoSerial);
        CheckBinContentWithItemTrackingCreateWhseEntry(BinContent, LotNo, '', QtyLotNoSerial);
        CheckBinContentWithItemTrackingCreateWhseEntry(BinContent, '', SerialNo, QtyNoLotSerial);
        CheckBinContentWithItemTrackingCreateWhseEntry(BinContent, LotNo, SerialNo, QtyLotSerial);

        // EXERCISE & VERIFY : get bin content with various filtering on IT and compare to qty.
        CheckBinContentWithItemTrackingFilterBinContent(BinContent, Item."No.", Location.Code, Bin.Code, '', '');
        Assert.AreEqual(QtyNoLotNoSerial + QtyLotNoSerial + QtyNoLotSerial + QtyLotSerial, BinContent."Quantity (Base)", '');
        CheckBinContentWithItemTrackingFilterBinContent(BinContent, Item."No.", Location.Code, Bin.Code, LotNo, '');
        Assert.AreEqual(QtyLotNoSerial + QtyLotSerial, BinContent."Quantity (Base)", '');
        CheckBinContentWithItemTrackingFilterBinContent(BinContent, Item."No.", Location.Code, Bin.Code, '', SerialNo);
        Assert.AreEqual(QtyNoLotSerial + QtyLotSerial, BinContent."Quantity (Base)", '');
        CheckBinContentWithItemTrackingFilterBinContent(BinContent, Item."No.", Location.Code, Bin.Code, LotNo, SerialNo);
        Assert.AreEqual(QtyLotSerial, BinContent."Quantity (Base)", '');
    end;

    local procedure CheckBinContentWithItemTrackingCreateWhseEntry(BinContent: Record "Bin Content"; LotNo: Code[10]; SerialNo: Code[10]; Qty: Decimal)
    var
        WhseEntry: Record "Warehouse Entry";
        WhseEntry2: Record "Warehouse Entry";
    begin
        WhseEntry.Init();
        if WhseEntry2.FindLast() then
            WhseEntry."Entry No." := WhseEntry2."Entry No." + 1
        else
            WhseEntry."Entry No." := 1;
        WhseEntry."Location Code" := BinContent."Location Code";
        WhseEntry."Bin Code" := BinContent."Bin Code";
        WhseEntry."Item No." := BinContent."Item No.";
        WhseEntry."Lot No." := LotNo;
        WhseEntry."Serial No." := SerialNo;
        WhseEntry."Qty. (Base)" := Qty;
        WhseEntry.Insert();
    end;

    local procedure CheckBinContentWithItemTrackingFilterBinContent(var BinContent: Record "Bin Content"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; LotNo: Code[10]; SerialNo: Code[10])
    begin
        Clear(BinContent);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        if LotNo <> '' then
            BinContent.SetRange("Lot No. Filter", LotNo);
        if SerialNo <> '' then
            BinContent.SetRange("Serial No. Filter", SerialNo);
        BinContent.FindLast();
        BinContent.CalcFields("Quantity (Base)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedQtyIsNotAvailableToPickFromPickWorksheet()
    var
        Item: Record Item;
        Bin: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        CreatePick: Codeunit "Create Pick";
        AvailQty: Decimal;
    begin
        // [FEATURE] [Warehouse] [Pick Worksheet]
        // [SCENARIO 362753] Blocked bin content is excluded from quantity available to pick when calculting available qty. from pick worksheet

        Initialize();

        // [GIVEN] "X" pieces of item "I" on a pick bin "B"
        LibraryInventory.CreateItem(Item);
        FindPickBin(Bin, LocationWhite.Code);
        UpdateInventoryOnLocationWithWhseAdjustment(LocationWhite, Item, LibraryRandom.RandDec(100, 2));
        // [GIVEN] Bin "B" is blocked
        BlockBinContent(LocationWhite.Code, Bin.Code, Item."No.");
        CreateMockWarehouseWorksheetLine(WhseWorksheetLine, LocationWhite.Code, Item."No.", Bin."Zone Code");

        // [WHEN] Calculate quantity available to pick from pick worksheet
        CreatePick.SetWhseWkshLine(WhseWorksheetLine, 0);
        CreatePick.SetCalledFromPickWksh(true);
        AvailQty := CreatePick.CalcTotalAvailQtyToPick(LocationWhite.Code, Item."No.", '', 0, 0, '', 0, 0, 0, false);
        // [THEN] Available quantity is 0
        Assert.AreEqual(0, AvailQty, QtyAvailMustBeZeroErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedQtyIsNotAvailableToPickFromMoveWorksheet()
    var
        Item: Record Item;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Bin: Record Bin;
        CreatePick: Codeunit "Create Pick";
        AvailQty: Decimal;
    begin
        // [FEATURE] [Warehouse] [Move Worksheet]
        // [SCENARIO 362753] Blocked bin content is excluded from quantity available to pick when calculting available qty. from move worksheet

        Initialize();

        // [GIVEN] "X" pieces of item "I" on a pick bin "B"
        LibraryInventory.CreateItem(Item);
        FindPickBin(Bin, LocationWhite.Code);
        UpdateInventoryOnLocationWithWhseAdjustment(LocationWhite, Item, LibraryRandom.RandDec(100, 2));
        // [GIVEN] Bin "B" is blocked
        BlockBinContent(LocationWhite.Code, Bin.Code, Item."No.");
        CreateMockWarehouseWorksheetLine(WhseWorksheetLine, LocationWhite.Code, Item."No.", Bin."Zone Code");

        // [WHEN] Calculate quantity available to pick from move worksheet
        CreatePick.SetWhseWkshLine(WhseWorksheetLine, 0);
        CreatePick.SetCalledFromMoveWksh(true);
        AvailQty := CreatePick.CalcTotalAvailQtyToPick(LocationWhite.Code, Item."No.", '', 0, 0, '', 0, 0, 0, false);
        // [THEN] Available quantity is 0
        Assert.AreEqual(0, AvailQty, QtyAvailMustBeZeroErr);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,ChangeUOMRequestPageHandler,WhseSourceCreateDocumentPageHandler')]
    [Scope('OnPrem')]
    procedure MovementPutPickIsNotExist()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Delta: Integer;
        QtyPerUOM: Integer;
        MinusDelta: Integer;
    begin
        // [FEATURE] [Bin Content] [Move Worksheet]
        // [SCENARIO 211627] Unpacking of bin content should be reflected in Warehouse Movements after creating movement with multiple lines for bin with filled "Min. Qty." and "Max. Qty.".
        Initialize();

        Delta := LibraryRandom.RandInt(5);
        QtyPerUOM := LibraryRandom.RandIntInRange(Delta, 50);
        MinusDelta := LibraryRandom.RandInt(QtyPerUOM - Delta);

        // [GIVEN] Item Unit Of Measure with "Qty. Per Unit of Measure" = "X" and Item with this Item Unit Of Measure in "Put-away Unit of Measure Code" field.
        CreateItemWithPutAwayUnitOfMeasure(Item, ItemUnitOfMeasure, QtyPerUOM);

        // [GIVEN] Bin and Bin Content with "Min. Qty." = 2 * "X" and "Max. Qty." = 3 * "X".
        CreateBinWithBinContent(Bin, BinContent, Item, LocationWhite.Code, 2 * QtyPerUOM, 3 * QtyPerUOM);

        // [GIVEN] Purchase order with Quantity between 2 * "X" and 3 * "X".
        // [GIVEN] Put-away from Warehouse Receipt Header.
        CreatePutAwayLinesFromPurchase(WarehouseActivityHeader, LocationWhite.Code, Item."No.", 3 * QtyPerUOM - MinusDelta);

        // [GIVEN] Split and change Unit of Measure of Put-Away lines.
        SplitAndChangeUnitofMeasureofPutAwayLines(
          ItemUnitOfMeasure,
          Item, Bin, WarehouseActivityHeader."No.", QtyPerUOM, Delta, 3 * QtyPerUOM - MinusDelta, 2 * QtyPerUOM - Delta - MinusDelta);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Calculate Bin Replenishment from Movement Worksheet.
        CalculateBinReplenishment(LocationWhite.Code);

        // [WHEN] Movement Create from Worksheet.
        Commit();
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // [THEN] Two warehouse activity lines are created as a result of unpacking: "Take" action with Quantity = 1 and "Place" action with Quantity = "X"
        VerifyWhseActivityLine(Item."No.", ItemUnitOfMeasure.Code, Bin.Code, WarehouseActivityLine."Action Type"::Take, 1);
        VerifyWhseActivityLine(Item."No.", Item."Base Unit of Measure", Bin.Code, WarehouseActivityLine."Action Type"::Place, QtyPerUOM)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure VerifyShipmentDateOnSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Qty: Decimal;
        DeltaDate: Integer;
    begin
        // [FEATURE] [Sales Order] [Warehouse Shipment]
        // [SCENARIO 374793] Shipment Date on Sales Line should be updated after Posting Warehouse Shipment with a different Shipment Date
        Initialize();

        // [GIVEN] Released Sales Order Line "L" with "Shipment Date" = "D1"
        LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandDec(10, 2);
        UpdateInventoryOnLocationWithWhseAdjustment(LocationWhite, Item, Qty);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Item."No.", LocationWhite.Code, Qty, Qty);

        // [GIVEN] Warehouse Shipment "WS" with "Shipment Date" = "D2"
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, LocationWhite.Code);
        DeltaDate := LibraryRandom.RandInt(10);
        WarehouseShipmentHeader.Validate("Shipment Date", WorkDate() + DeltaDate);
        WarehouseShipmentHeader.Modify();

        // [GIVEN] Registered Pick for "WS"
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWarehouseActivityHeader(WarehouseActivityHeader, LocationWhite.Code, WarehouseActivityHeader.Type::Pick);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post "WS"
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        // [THEN] "L" has Shipment Date = "D2"
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Shipment Date", WorkDate() + DeltaDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickWithDefaultBinContent()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Bin: array[2] of Record Bin;
        IsDefault: array[2] of Boolean;
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Pick] [Bin Content]
        // [SCENARIO 377947] Create Pick Job should fill "Take" Line with Bin Code taken from Default Bin Content of Item
        Initialize();

        // [GIVEN] Bin Mandatory Location with Require Pick and Shipment
        // [GIVEN] Item of Quantity = "Q" on Bin Content "X" and "Q" on Default Bin Content "Y"
        // [GIVEN] Sales Order for Item of Quantity "SQ" <= "Q"
        // [GIVEN] Whse Shipment for Item
        IsDefault[1] := false;
        IsDefault[2] := true;
        Quantity := LibraryRandom.RandInt(Quantity);
        CreateWhseShipmentForItemWithTwoBinContents(Item, Bin, IsDefault, Quantity);

        // [WHEN] Create Pick
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, LocationOrange.Code);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Whse Pick is created where "Take" line has "Bin Code" = "Y" and Quantity = "SQ"
        VerifyPickBinAndQuantity(Item."No.", Bin[2].Code, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickWithNoDefaultBinContent()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        Bin: array[2] of Record Bin;
        IsDefault: array[2] of Boolean;
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Pick] [Bin Content]
        // [SCENARIO 377947] Create Pick Job should fill "Take" Line with Bin Code taken from first Bin Content of Item if there is no Default
        Initialize();

        // [GIVEN] Bin Mandatory Location with Require Pick and Shipment
        // [GIVEN] Item of Quantity = "Q" on Bin Content "X" and "Q" on Bin Content "Y"
        // [GIVEN] Sales Order for Item of Quantity "SQ" <= "Q"
        // [GIVEN] Whse Shipment for Item
        IsDefault[1] := false;
        IsDefault[2] := false;
        Quantity := LibraryRandom.RandInt(Quantity);
        CreateWhseShipmentForItemWithTwoBinContents(Item, Bin, IsDefault, Quantity);

        // [WHEN] Create Pick
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, LocationOrange.Code);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Whse Pick is created where "Take" line has "Bin Code" = "X" and Quantity = "SQ"
        VerifyPickBinAndQuantity(Item."No.", Bin[1].Code, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyOnOutboundBinsAssumedZeroWhenWhseShipmentDeletedAtBasiclWMSLocation()
    var
        Item: Record Item;
        Location: Record Location;
        ShipBin: Record Bin;
        BulkBin: Record Bin;
        WarehouseEntry: Record "Warehouse Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        LotNo: Code[50];
        SalesDocNo: Code[20];
        ShipmentDocNo: Code[20];
        ReclassDocNo: Code[20];
        Qty: Decimal;
        QtyOnOutboundBins: Decimal;
    begin
        // [FEATURE] [Warehouse Shipment] [Item Reclassification] [Basic Warehousing] [UT]
        // [SCENARIO 302510] At location with disabled directed put-away and pick quantity on outbound bins is zero when the shipment was reverted using item reclassification journal.
        Initialize();

        // [GIVEN] Location with required shipment and pick.
        // [GIVEN] Two bins - "BULK" and "SHIP".
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateBin(ShipBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(BulkBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        LotNo := LibraryUtility.GenerateGUID();
        SalesDocNo := LibraryUtility.GenerateGUID();
        ShipmentDocNo := LibraryUtility.GenerateGUID();
        ReclassDocNo := LibraryUtility.GenerateGUID();

        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] 100 pcs are stored in bin "BULK".
        MockWhseEntry(
          Location.Code, BulkBin.Code, Item."No.", LotNo, LibraryRandom.RandIntInRange(100, 200),
          DATABASE::"Item Journal Line", LibraryUtility.GenerateGUID(), WarehouseEntry."Whse. Document Type"::" ", '',
          WarehouseEntry."Entry Type"::"Positive Adjmt.", WarehouseEntry."Reference Document"::"Item Journal");

        // [GIVEN] Create warehouse shipment, pick and register the pick.
        // [GIVEN] 10 pcs are taken from bin "BULK" and placed into bin "SHIP".
        // [GIVEN] Do not post the shipment and delete it.
        MockWhseEntry(
          Location.Code, BulkBin.Code, Item."No.", LotNo, -Qty,
          DATABASE::"Sales Line", SalesDocNo, WarehouseEntry."Whse. Document Type"::Shipment, ShipmentDocNo,
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::Pick);
        MockWhseEntry(
          Location.Code, ShipBin.Code, Item."No.", LotNo, Qty,
          DATABASE::"Sales Line", SalesDocNo, WarehouseEntry."Whse. Document Type"::Shipment, ShipmentDocNo,
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::Pick);

        // [GIVEN] Move the shipped quantity back to bin "BULK" using item reclassification journal.
        MockWhseEntry(
          Location.Code, ShipBin.Code, Item."No.", LotNo, -Qty,
          DATABASE::"Item Journal Line", ReclassDocNo, WarehouseEntry."Whse. Document Type"::" ", '',
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::"Item Journal");
        MockWhseEntry(
          Location.Code, BulkBin.Code, Item."No.", LotNo, Qty,
          DATABASE::"Item Journal Line", ReclassDocNo, WarehouseEntry."Whse. Document Type"::" ", '',
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::"Item Journal");

        // [WHEN] Invoke "CalcQtyOnOutboundBins" function in Codeunit 7312 in order to calculate quantity stored in outbound bins.
        WhseItemTrackingSetup."Lot No." := LotNo;
        QtyOnOutboundBins := WhseAvailMgt.CalcQtyOnOutboundBins(Location.Code, Item."No.", '', WhseItemTrackingSetup, false);

        // [THEN] Quantity on outbound bins = 0.
        Assert.AreEqual(0, QtyOnOutboundBins, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyOnOutboundBinsIsCalculatedWhenWhseShipmentExistsAtBasiclWMSLocation()
    var
        Item: Record Item;
        Location: Record Location;
        ShipBin: Record Bin;
        BulkBin: Record Bin;
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        LotNo: Code[50];
        SalesDocNo: Code[20];
        ShipmentDocNo: Code[20];
        PostedShipmentDocNo: Code[20];
        Qty: Decimal;
        QtyOnOutboundBins: Decimal;
    begin
        // [FEATURE] [Warehouse Shipment] [Basic Warehousing] [UT]
        // [SCENARIO 302510] At location with disabled directed put-away and pick quantity on outbound bins is calculated when there is an active warehouse shipment.
        Initialize();

        // [GIVEN] Location with required shipment and pick.
        // [GIVEN] Two bins - "BULK" and "SHIP".
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateBin(ShipBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(BulkBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        LotNo := LibraryUtility.GenerateGUID();
        SalesDocNo := LibraryUtility.GenerateGUID();
        ShipmentDocNo := LibraryUtility.GenerateGUID();
        PostedShipmentDocNo := LibraryUtility.GenerateGUID();

        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] 100 pcs are stored in bin "BULK".
        MockWhseEntry(
          Location.Code, BulkBin.Code, Item."No.", LotNo, LibraryRandom.RandIntInRange(100, 200),
          DATABASE::"Item Journal Line", LibraryUtility.GenerateGUID(), WarehouseEntry."Whse. Document Type"::" ", '',
          WarehouseEntry."Entry Type"::"Positive Adjmt.", WarehouseEntry."Reference Document"::"Item Journal");

        // [GIVEN] Create warehouse shipment, pick and register the pick.
        // [GIVEN] 20 pcs are taken from bin "BULK" and placed into bin "SHIP".
        WarehouseShipmentHeader."No." := ShipmentDocNo;
        WarehouseShipmentHeader.Insert();

        MockWhseEntry(
          Location.Code, BulkBin.Code, Item."No.", LotNo, -Qty,
          DATABASE::"Sales Line", SalesDocNo, WarehouseEntry."Whse. Document Type"::Shipment, ShipmentDocNo,
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::Pick);
        MockWhseEntry(
          Location.Code, ShipBin.Code, Item."No.", LotNo, Qty,
          DATABASE::"Sales Line", SalesDocNo, WarehouseEntry."Whse. Document Type"::Shipment, ShipmentDocNo,
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::Pick);

        // [GIVEN] Undo the shipment. -5 pcs.
        MockWhseEntry(
          Location.Code, ShipBin.Code, Item."No.", LotNo, -Qty / 4,
          DATABASE::"Sales Line", SalesDocNo, WarehouseEntry."Whse. Document Type"::Shipment, PostedShipmentDocNo,
          WarehouseEntry."Entry Type"::"Negative Adjmt.", WarehouseEntry."Reference Document"::"Posted Shipment");
        MockWhseEntry(
          Location.Code, BulkBin.Code, Item."No.", LotNo, Qty / 4,
          DATABASE::"Sales Line", SalesDocNo, WarehouseEntry."Whse. Document Type"::Shipment, PostedShipmentDocNo,
          WarehouseEntry."Entry Type"::"Positive Adjmt.", WarehouseEntry."Reference Document"::"Posted Shipment");

        // [WHEN] Invoke "CalcQtyOnOutboundBins" function in Codeunit 7312 in order to calculate quantity stored in outbound bins.
        WhseItemTrackingSetup."Lot No." := LotNo;
        QtyOnOutboundBins := WhseAvailMgt.CalcQtyOnOutboundBins(Location.Code, Item."No.", '', WhseItemTrackingSetup, false);

        // [THEN] Quantity on outbound bins = 15 (20 in the shipment - 5 undone).
        Assert.AreEqual(Qty * 3 / 4, QtyOnOutboundBins, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyOnOutboundBinsCalculatedWhenFirstShipmentWasRevertedAndSecondPickedAtBasiclWMS()
    var
        Item: Record Item;
        Location: Record Location;
        ShipBin: Record Bin;
        BulkBin: Record Bin;
        WarehouseShipmentHeader: array[2] of Record "Warehouse Shipment Header";
        WarehouseEntry: Record "Warehouse Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        LotNo: Code[50];
        SalesDocNo: Code[20];
        ReclassDocNo: Code[20];
        Qty: Decimal;
        QtyOnOutboundBins: Decimal;
    begin
        // [FEATURE] [Warehouse Shipment] [Item Reclassification] [Basic Warehousing] [UT]
        // [SCENARIO 302510] At location with disabled directed put-away and pick quantity on outbound bins is properly calculated when the first shipment was picked but deleted.
        Initialize();

        // [GIVEN] Location with required shipment and pick.
        // [GIVEN] Two bins - "BULK" and "SHIP".
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateBin(ShipBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(BulkBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        LotNo := LibraryUtility.GenerateGUID();
        SalesDocNo := LibraryUtility.GenerateGUID();
        ReclassDocNo := LibraryUtility.GenerateGUID();

        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] 100 pcs are stored in bin "BULK".
        MockWhseEntry(
          Location.Code, BulkBin.Code, Item."No.", LotNo, LibraryRandom.RandIntInRange(100, 200),
          DATABASE::"Item Journal Line", LibraryUtility.GenerateGUID(), WarehouseEntry."Whse. Document Type"::" ", '',
          WarehouseEntry."Entry Type"::"Positive Adjmt.", WarehouseEntry."Reference Document"::"Item Journal");

        // [GIVEN] Create warehouse shipment, pick and register the pick.
        // [GIVEN] 10 pcs are taken from bin "BULK" and placed into bin "SHIP".
        WarehouseShipmentHeader[1]."No." := LibraryUtility.GenerateGUID();
        WarehouseShipmentHeader[1].Insert();
        MockWhseEntry(
          Location.Code, BulkBin.Code, Item."No.", LotNo, -Qty,
          DATABASE::"Sales Line", SalesDocNo, WarehouseEntry."Whse. Document Type"::Shipment, WarehouseShipmentHeader[1]."No.",
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::Pick);
        MockWhseEntry(
          Location.Code, ShipBin.Code, Item."No.", LotNo, Qty,
          DATABASE::"Sales Line", SalesDocNo, WarehouseEntry."Whse. Document Type"::Shipment, WarehouseShipmentHeader[1]."No.",
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::Pick);

        // [GIVEN] Do not post the shipment and delete it.
        WarehouseShipmentHeader[1].Delete();

        // [GIVEN] Move the shipped quantity back to bin "BULK" using item reclassification journal.
        MockWhseEntry(
          Location.Code, ShipBin.Code, Item."No.", LotNo, -Qty,
          DATABASE::"Item Journal Line", ReclassDocNo, WarehouseEntry."Whse. Document Type"::" ", '',
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::"Item Journal");
        MockWhseEntry(
          Location.Code, BulkBin.Code, Item."No.", LotNo, Qty,
          DATABASE::"Item Journal Line", ReclassDocNo, WarehouseEntry."Whse. Document Type"::" ", '',
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::"Item Journal");

        // [GIVEN] Create another shipment, pick and register the pick.
        // [GIVEN] 10 pcs are taken from bin "BULK" and placed into bin "SHIP".
        WarehouseShipmentHeader[2]."No." := LibraryUtility.GenerateGUID();
        WarehouseShipmentHeader[2].Insert();
        MockWhseEntry(
          Location.Code, BulkBin.Code, Item."No.", LotNo, -Qty,
          DATABASE::"Sales Line", SalesDocNo, WarehouseEntry."Whse. Document Type"::Shipment, WarehouseShipmentHeader[2]."No.",
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::Pick);
        MockWhseEntry(
          Location.Code, ShipBin.Code, Item."No.", LotNo, Qty,
          DATABASE::"Sales Line", SalesDocNo, WarehouseEntry."Whse. Document Type"::Shipment, WarehouseShipmentHeader[2]."No.",
          WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Reference Document"::Pick);

        // [WHEN] Invoke "CalcQtyOnOutboundBins" function in Codeunit 7312 in order to calculate quantity stored in outbound bins.
        WhseItemTrackingSetup."Lot No." := LotNo;
        QtyOnOutboundBins := WhseAvailMgt.CalcQtyOnOutboundBins(Location.Code, Item."No.", '', WhseItemTrackingSetup, false);

        // [THEN] Quantity on outbound bins = 10.
        Assert.AreEqual(Qty, QtyOnOutboundBins, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure VerifyWarehouseShipmentLineUpdatedCorrectly()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Qty: Decimal;
        QtytoShip: Decimal;
    begin
        // [FEATURE] [Sales Order] [Warehouse Shipment]
        // [SCENARIO 478583] Warehouse shipment line is updated wrongly when undoing a shipment
        Initialize();

        // [GIVEN] Setup: Create Item, setup quantities, update inventory for Item
        LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandDecInRange(10, 20, 2);
        QtytoShip := LibraryRandom.RandDecInRange(8, 9, 2);
        UpdateInventoryOnLocationWithWhseAdjustment(LocationWhite, Item, Qty);

        // [GIVEN] Create and Release Sales Order
        CreateAndReleaseSalesOrderWithOneSalesLine(SalesHeader, Item."No.", LocationWhite.Code, Qty);

        // [GIVEN] Create Warehouse Shipment from Sales Order
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, LocationWhite.Code);

        // [GIVEN] Registered Pick for Warehouse Shipment
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWarehouseActivityHeader(WarehouseActivityHeader, LocationWhite.Code, WarehouseActivityHeader.Type::Pick);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Update Qty to Ship on Whse Shipment line.
        UpdateQtyToShipOnWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader."No.", QtytoShip);

        // [WHEN] Post Warehouse Shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Re-open and delete the Warehouse Shipment
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, LocationWhite.Code);
        WhseShipmentRelease.Reopen(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Delete(true);

        // [THEN] Create Warehouse Shipment again from Sales Order
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Undo Shipment
        UndoSalesShipmentLine(SalesLine, SalesHeader."No.");

        // [VERIFY] Verify: Warehouse Shipmet Line Qunatity and Sales Line Quantity are equal
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, LocationWhite.Code);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader, Item."No.");
        Assert.AreEqual(SalesLine.Quantity, WarehouseShipmentLine.Quantity, QtyErr);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.ClearState();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse Management");
        ClearWarehouseEntry();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse Management");

        NoSeriesSetup();
        ItemJournalSetup();
        CreateLocationSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();

        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse Management");
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
    end;

    local procedure BlockBinContent(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();

        BinContent.Validate("Block Movement", BinContent."Block Movement"::All);
        BinContent.Modify(true);
    end;

    local procedure CreateLocationSetup()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // Location: Silver.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationSilver);
        LocationSilver."Bin Mandatory" := true;
        LocationSilver.Validate("Default Bin Selection", LocationSilver."Default Bin Selection"::"Fixed Bin");
        LocationSilver.Modify(true);

        // Location: Orange.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationOrange);
        LibraryWarehouse.CreateNumberOfBins(LocationOrange.Code, '', '', 7, false);  // Total Bins created here = 7.
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 1);  // Find Bin based on Bin Index.
        LibraryWarehouse.FindBin(Bin2, LocationOrange.Code, '', 2);
        UpdateLocation(LocationOrange, LocationOrange."Default Bin Selection"::"Fixed Bin", true);
        LocationOrange."Bin Mandatory" := true;
        LocationOrange.Validate("Shipment Bin Code", Bin.Code);
        LocationOrange.Validate("Receipt Bin Code", Bin2.Code);
        LocationOrange.Modify(true);

        // Location: Green.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationGreen);
        UpdateLocation(LocationGreen, LocationGreen."Default Bin Selection"::"Fixed Bin", true);

        // Location: White.
        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);  // Value for Number Of Bins.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
    end;

    local procedure UpdateLocation(var Location: Record Location; DefaultBinSelection: Enum "Location Default Bin Selection"; RequireReceive: Boolean)
    begin
        Location.Validate("Default Bin Selection", DefaultBinSelection);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Shipment", true);
        Location.Modify(true);
    end;

    local procedure ClearWarehouseEntry()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseActivityHeader.DeleteAll();
        WarehouseShipmentHeader.DeleteAll();
        WarehouseReceiptHeader.DeleteAll();
    end;

    local procedure ItemJournalSetup()
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CalculateBinReplenishment(LocationCode: Code[10])
    var
        DummyBinContent: Record "Bin Content";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        LibraryWarehouse.CalculateBinReplenishment(DummyBinContent, WhseWorksheetName, LocationCode, true, true, false);
    end;

    local procedure CreateBinWithWarehouseClass(var Bin: Record Bin; LocationCode: Code[10]; PutAway: Boolean; Pick: Boolean; Receive: Boolean; Ship: Boolean; WarehouseClassCode: Code[10])
    var
        BinType: Record "Bin Type";
        Zone: Record Zone;
    begin
        FindBinType(BinType, PutAway, Pick, Receive, Ship);
        FindZone(Zone, LocationCode, BinType.Code);
        LibraryWarehouse.CreateBin(
          Bin, LocationCode,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), Zone.Code, BinType.Code);
        UpdateBin(Bin, WarehouseClassCode);
    end;

    local procedure CreateBinAndBinContent(var Bin: Record Bin; LocationCode: Code[10]; ItemNo: Code[20]; UnitOfMeasure: Code[10]; Default: Boolean)
    var
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBin(
          Bin, LocationCode,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        CreateBinContent(BinContent, LocationCode, Bin.Code, ItemNo, UnitOfMeasure, Default);
    end;

    local procedure CreateBinWithBinContent(var Bin: Record Bin; var BinContent: Record "Bin Content"; Item: Record Item; LocationCode: Code[10]; MinQty: Decimal; MaxQty: Decimal)
    var
        Zone: Record Zone;
        BinTypeCode: Code[10];
    begin
        BinTypeCode := LibraryWarehouse.SelectBinType(false, false, false, true);
        LibraryWarehouse.CreateZone(Zone, LibraryUtility.GenerateGUID(), LocationCode, BinTypeCode, '', '', 0, false);
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), Zone.Code, BinTypeCode);
        CreateBinContentWithMinAndMaxQty(BinContent, Item, LocationCode, Bin.Code, Zone.Code, BinTypeCode, MinQty, MaxQty, 1000);
    end;

    local procedure CreateBinContent(var BinContent: Record "Bin Content"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10]; Default: Boolean)
    begin
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', BinCode, ItemNo, '', BaseUnitOfMeasure);
        BinContent.Validate(Fixed, true);
        BinContent.Validate(Default, Default);
        BinContent.Modify(true);
    end;

    local procedure CreateItemWithPutAwayUnitOfMeasure(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; QtyPerUOM: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPerUOM);
        Item.Validate("Put-away Unit of Measure Code", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateMultipleItemWithWarehouseClass(var Item: Record Item; var Item2: Record Item; var WarehouseClass: Record "Warehouse Class"; var WarehouseClass2: Record "Warehouse Class")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        UpdateItemWithWarehouseClass(Item, WarehouseClass);
        UpdateItemWithWarehouseClass(Item2, WarehouseClass2);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; Quantity2: Decimal; UnitOfMeasureCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, LocationCode, Quantity);
        UpdatePurchaseLineWithUOM(PurchaseLine, UnitOfMeasureCode);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo2, LocationCode, Quantity2);
        UpdatePurchaseLineWithBinCode(PurchaseLine, BinCode);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Quantity2: Decimal)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesHeader(SalesHeader, Customer."No.", '', SalesHeader."Shipping Advice"::Partial);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, LocationCode, Quantity);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo2, LocationCode, Quantity2);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateMockWarehouseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20]; ZoneCode: Code[10])
    begin
        WhseWorksheetLine.Init();
        WhseWorksheetLine."Location Code" := LocationCode;
        WhseWorksheetLine."Item No." := ItemNo;
        WhseWorksheetLine."From Zone Code" := ZoneCode;
        WhseWorksheetLine."To Zone Code" := ZoneCode;
    end;

    local procedure CreateWhseShipmentForItemWithTwoBinContents(var Item: Record Item; var Bin: array[2] of Record Bin; IsDefault: array[2] of Boolean; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StockQuantity: Decimal;
    begin
        UpdateLocation(LocationOrange, LocationOrange."Default Bin Selection"::"Fixed Bin", true);
        LibraryInventory.CreateItem(Item);
        CreateBinAndBinContent(Bin[1], LocationOrange.Code, Item."No.", Item."Base Unit of Measure", IsDefault[1]);
        CreateBinAndBinContent(Bin[2], LocationOrange.Code, Item."No.", Item."Base Unit of Measure", IsDefault[2]);

        StockQuantity := Quantity + LibraryRandom.RandInt(Quantity);
        LibraryInventory.PostPositiveAdjustment(Item, LocationOrange.Code, '', Bin[1].Code, StockQuantity, WorkDate(), 0);
        LibraryInventory.PostPositiveAdjustment(Item, LocationOrange.Code, '', Bin[2].Code, StockQuantity, WorkDate(), 0);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, SalesLine, Item."No.", LocationOrange.Code, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateMultipleSalesLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo2, Quantity);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo3, Quantity);
    end;

    local procedure CreateAndReleaseSalesOrderWithShippingAdvice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ShippingAdvice: Enum "Sales Header Shipping Advice")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, CustomerNo, LocationCode, ShippingAdvice);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LocationCode: Code[10]; ShippingAdvice: Enum "Sales Header Shipping Advice")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Shipping Advice", ShippingAdvice);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Quantity2: Decimal)
    begin
        CreateSalesOrder(SalesHeader, ItemNo, ItemNo2, LocationCode, Quantity, Quantity2);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndPostWhseReceipt(PurchaseHeader: Record "Purchase Header"; BinCode: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        ChangeBinCodeOnWarehouseReceiptLine(WarehouseReceiptHeader, BinCode, LocationCode);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreatePutAwayLinesFromPurchase(var WarehouseActivityHeader: Record "Warehouse Activity Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptHeader(WarehouseReceiptHeader, LocationCode);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        FindWarehouseActivityHeader(WarehouseActivityHeader, LocationCode, WarehouseActivityHeader.Type::"Put-away");
    end;

    local procedure CreateWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        WarehouseReceiptHeader.Validate("Location Code", LocationCode);
        WarehouseReceiptHeader.Validate("Bin Code", BinCode);
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreateWarehouseSourceFilter(var WarehouseSourceFilter: Record "Warehouse Source Filter"; BuyFromVendorNoFilter: Code[100])
    begin
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Inbound);
        WarehouseSourceFilter.Validate("Buy-from Vendor No. Filter", BuyFromVendorNoFilter);
        WarehouseSourceFilter.Modify(true);
    end;

    local procedure CreateBinContentWithMinAndMaxQty(BinContent: Record "Bin Content"; Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; ZoneCode: Code[10]; BinTypeCode: Code[10]; MinQty: Decimal; MaxQty: Decimal; BinRanking: Integer)
    begin
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, ZoneCode, BinCode, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Fixed, true);
        BinContent.Validate("Bin Type Code", BinTypeCode);
        BinContent.Validate("Min. Qty.", MinQty);
        BinContent.Validate("Max. Qty.", MaxQty);
        BinContent.Validate("Bin Ranking", BinRanking);
        BinContent.Modify(true);
    end;

    local procedure ChangeBinCodeOnWarehouseReceiptLine(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; BinCode: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptHeader(WarehouseReceiptHeader, LocationCode);
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.Validate("Bin Code", BinCode);  // Change Bin Code.
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure ChangeBinCodeOnWarehouseShipmentLine(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; BinCode: Code[20]; LocationCode: Code[10]; ItemNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Bin Code", BinCode);  // Change Bin Code.
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure ChangeBinCodeOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; BinCode: Code[20])
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityHeader, ActionType, ItemNo);
        WarehouseActivityLine.Validate("Bin Code", BinCode);  // Change Bin Code.
        WarehouseActivityLine.Modify(true);
    end;

    local procedure ChangeQtyToShipOnWhseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; No: Code[20]; QtyToShip: Decimal)
    begin
        WarehouseShipmentLine.SetRange("No.", No);
        WarehouseShipmentLine.FindSet();
        WarehouseShipmentLine.Validate("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.Modify(true);
        WarehouseShipmentLine.Next();
        WarehouseShipmentLine.Validate("Qty. to Ship", 0);  // Value important for Test.
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure ChangeQtyToReceiveOnWhseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; No: Code[20]; QtyToReceive: Decimal)
    begin
        WarehouseReceiptLine.SetRange("No.", No);
        WarehouseReceiptLine.FindSet();
        WarehouseReceiptLine.Validate("Qty. to Receive", 0);  // Value important for Test.
        WarehouseReceiptLine.Modify(true);
        WarehouseReceiptLine.Next();
        WarehouseReceiptLine.Validate("Qty. to Receive", QtyToReceive);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure ChangeBinCodeOnProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; BinCode: Code[20])
    begin
        ProdOrderComponent.Validate("Bin Code", BinCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateCertifiedProductionBOM(var Item: Record Item; ItemNo: Code[20]; ItemNo2: Code[20]; WarehouseClassCode: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo2, 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Warehouse Class Code", WarehouseClassCode);
        Item.Modify(true);
    end;

    local procedure CreateProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, 1);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreateProductionOrder(ProductionOrder, ItemNo, LocationCode, BinCode);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure MockWhseEntry(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; QtyBase: Decimal; SourceType: Integer; SourceNo: Code[20]; WhseDocType: Enum "Warehouse Journal Document Type"; WhseDocNo: Code[20]; EntryType: Option; RefDoc: Enum "Whse. Reference Document Type")
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := LibraryUtility.GetNewRecNo(WarehouseEntry, WarehouseEntry.FieldNo("Entry No."));
        WarehouseEntry."Location Code" := LocationCode;
        WarehouseEntry."Bin Code" := BinCode;
        WarehouseEntry."Item No." := ItemNo;
        WarehouseEntry."Lot No." := LotNo;
        WarehouseEntry."Qty. (Base)" := QtyBase;
        WarehouseEntry."Source Type" := SourceType;
        WarehouseEntry."Source No." := SourceNo;
        WarehouseEntry."Whse. Document Type" := WhseDocType;
        WarehouseEntry."Whse. Document No." := WhseDocNo;
        WarehouseEntry."Entry Type" := EntryType;
        WarehouseEntry."Reference Document" := RefDoc;
        WarehouseEntry.Insert();
    end;

    local procedure ClearWarehouseJournal()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.DeleteAll();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; No: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    begin
        WarehouseReceiptHeader.SetRange("Location Code", LocationCode);
        WarehouseReceiptHeader.FindLast();
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindLast();
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; LocationCode: Code[10]; Type: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityHeader.SetRange(Type, Type);
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindLast();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindPlaceWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeaderNo: Code[20]; QuantityFilter: Decimal)
    begin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeaderNo);
        WarehouseActivityLine.SetRange("Qty. (Base)", QuantityFilter);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindBinType(var BinType: Record "Bin Type"; PutAway: Boolean; Pick: Boolean; Receive: Boolean; Ship: Boolean)
    begin
        BinType.SetRange("Put Away", PutAway);
        BinType.SetRange(Pick, Pick);
        BinType.SetRange(Receive, Receive);
        BinType.SetRange(Ship, Ship);
        BinType.FindFirst();
    end;

    local procedure FindPickBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        BinType: Record "Bin Type";
    begin
        Clear(Bin);

        Bin.SetRange("Location Code", LocationCode);
        BinType.SetRange(Pick, true);
        if BinType.FindSet() then
            repeat
                Bin.SetRange("Bin Type Code", BinType.Code);
                if Bin.FindFirst() then
                    exit;
            until BinType.Next() = 0;
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; BinTypeCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.FindFirst();
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; BinCode: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.SetRange("Bin Code", BinCode);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure SplitAndChangeUnitofMeasureofPutAwayLines(ItemUnitOfMeasure: Record "Item Unit of Measure"; Item: Record Item; Bin: Record Bin; WarehouseActivityHeaderNo: Code[20]; QtyPerUOMForNotBOM: Integer; Delta: Integer; PutAwayQuantity: Integer; QuantityAfterTwoSplitting: Integer)
    var
        WarehouseActivityLine: array[2] of Record "Warehouse Activity Line";
    begin
        FindPlaceWhseActivityLine(WarehouseActivityLine[1], WarehouseActivityHeaderNo, PutAwayQuantity);
        SplitWarehouseActivityLine(WarehouseActivityLine[1], QtyPerUOMForNotBOM / ItemUnitOfMeasure."Qty. per Unit of Measure");
        FindPlaceWhseActivityLine(WarehouseActivityLine[2], WarehouseActivityHeaderNo, PutAwayQuantity - QtyPerUOMForNotBOM);
        UpdateZoneCodeAndBinCode(WarehouseActivityLine[2], WarehouseActivityLine[1]."Zone Code", WarehouseActivityLine[1]."Bin Code");
        LibraryVariableStorage.Enqueue(Item."Base Unit of Measure"); // Enqueue for ChangeUOMRequestPageHandler
        LibraryWarehouse.ChangeUnitOfMeasure(WarehouseActivityLine[2]);
        SplitWarehouseActivityLine(WarehouseActivityLine[2], Delta);
        FindPlaceWhseActivityLine(WarehouseActivityLine[2], WarehouseActivityHeaderNo, QuantityAfterTwoSplitting);
        UpdateZoneCodeAndBinCode(WarehouseActivityLine[2], Bin."Zone Code", Bin.Code);
    end;

    local procedure SplitWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; QuantityToSplit: Decimal)
    begin
        WarehouseActivityLine.Validate("Qty. to Handle", QuantityToSplit);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);
    end;

    local procedure UpdateAndRegisterWarehouseActivityLine(LocationCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; BinCode: Code[20]; BinCode2: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, LocationCode, WarehouseActivityHeader.Type::"Put-away");
        ChangeBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, ItemNo, BinCode);
        ChangeBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, ItemNo2, BinCode2);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure UpdatePurchaseLineWithUOM(var PurchaseLine: Record "Purchase Line"; UnitOfMeasureCode: Code[10])
    begin
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode); // Unit of Measure Code.
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchaseLineWithBinCode(var PurchaseLine: Record "Purchase Line"; BinCode: Code[20])
    begin
        PurchaseLine.Validate("Bin Code", BinCode);  // Update Bin Code.
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateItemWithUnitOfMeasure(var UnitOfMeasure: Record "Unit of Measure"; ItemNo: Code[20])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasure.Code, LibraryRandom.RandDec(10, 2));
    end;

    local procedure UpdateWarehouseReceiptLine(SourceNo: Code[20]; BinCode: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindSet();
        repeat
            WarehouseReceiptLine.Validate("Bin Code", BinCode);
            WarehouseReceiptLine.Modify(true);
        until WarehouseReceiptLine.Next() = 0;
    end;

    local procedure UpdateInventoryOnLocationWithWhseAdjustment(Location: Record Location; Item: Record Item; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        ClearWarehouseJournal();
        LibraryWarehouse.WarehouseJournalSetup(LocationWhite.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, '',
          Location."Cross-Dock Bin Code", WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateInventoryOnLocation(LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateQuantityToHandleOnWhseActivityLine(WarehouseActivityHeader: Record "Warehouse Activity Header"; Quantity: Decimal; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange(Quantity, Quantity);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateLocationWhite(var Location: Record Location; AlwaysCreatePutAwayLine: Boolean)
    begin
        Location.Validate("Always Create Put-away Line", AlwaysCreatePutAwayLine);
        Location.Modify(true);
    end;

    local procedure UpdateBin(var Bin: Record Bin; WarehouseClassCode: Code[10])
    begin
        Bin.Validate("Warehouse Class Code", WarehouseClassCode);
        Bin.Modify(true);
    end;

    local procedure UpdateZoneCodeAndBinCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; ZoneCode: Code[10]; BinCode: Code[20])
    begin
        WarehouseActivityLine.Validate("Zone Code", ZoneCode);
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateItemWithWarehouseClass(var Item: Record Item; var WarehouseClass: Record "Warehouse Class")
    begin
        LibraryWarehouse.CreateWarehouseClass(WarehouseClass);
        Item.Validate("Warehouse Class Code", WarehouseClass.Code);
        Item.Modify(true);
    end;

    local procedure UpdateBinWarehouseReceiptLine(ItemNo: Code[20]; BinCode: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.Validate("Bin Code", BinCode);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure CreateAndUpdateBinCodeWarehouseReceiptLine(var Bin: Record Bin; LocationCode: Code[10]; ItemNo: Code[20]; WarehouseClassCode: Code[10])
    begin
        CreateBinWithWarehouseClass(Bin, LocationCode, false, false, true, false, WarehouseClassCode);
        UpdateBinWarehouseReceiptLine(ItemNo, Bin.Code);
    end;

    local procedure VerifyBinCodeOnSalesLine(SalesLine: Record "Sales Line"; BinCode: Code[20]; BinCode2: Code[20]; DefaultBinSelection: Enum "Location Default Bin Selection")
    var
        Location: Record Location;
    begin
        case DefaultBinSelection of
            Location."Default Bin Selection"::"Fixed Bin":
                SalesLine.TestField("Bin Code", BinCode);
            Location."Default Bin Selection"::"Last-Used Bin":
                SalesLine.TestField("Bin Code", BinCode2);
        end;
    end;

    local procedure VerifyWarehouseReceipt(Location: Record Location)
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptHeader(WarehouseReceiptHeader, Location.Code);
        WarehouseReceiptHeader.TestField("Bin Code", Location."Receipt Bin Code");
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindSet();
        repeat
            WarehouseReceiptLine.TestField("Bin Code", WarehouseReceiptHeader."Bin Code");
        until WarehouseReceiptLine.Next() = 0;
    end;

    local procedure VerifyWarehouseShipment(Location: Record Location)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, Location.Code);
        WarehouseShipmentHeader.TestField("Bin Code", Location."Shipment Bin Code");
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindSet();
        repeat
            WarehouseShipmentLine.TestField("Bin Code", WarehouseShipmentHeader."Bin Code");
        until WarehouseShipmentLine.Next() = 0;
    end;

    local procedure VerifyWarehouseShipmentLine(No: Code[20]; ItemNo: Code[20]; Quantity: Decimal; QtyOutstanding: Decimal; QtyToShip: Decimal; QtyPicked: Decimal; QtyShipped: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", No);
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.SetRange(Quantity, Quantity);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField("Qty. Outstanding", QtyOutstanding);
        WarehouseShipmentLine.TestField("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.TestField("Qty. Picked", QtyPicked);
        WarehouseShipmentLine.TestField("Qty. Shipped", QtyShipped)
    end;

    local procedure VerifyWarehouseReceiptLine(No: Code[20]; ItemNo: Code[20]; Quantity: Decimal; QtyOutstanding: Decimal; QtyToReceive: Decimal; QtyReceived: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("No.", No);
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.SetRange(Quantity, Quantity);
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.TestField("Qty. Outstanding", QtyOutstanding);
        WarehouseReceiptLine.TestField("Qty. to Receive", QtyToReceive);
        WarehouseReceiptLine.TestField("Qty. Received", QtyReceived)
    end;

    local procedure VerifyWarehouseActivityLine(WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityHeader, ActionType, ItemNo);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyWhseActivityLine(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; BinCode: Code[20]; ActionType: Enum "Warehouse Action Type"; ExpectedQuantity: Integer)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseActivityLine.SetFilter("Bin Code", '<>%1', BinCode);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, ExpectedQuantity);
    end;

    local procedure VerifyWarehouseActivityLineDetails(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal; BinCode: Code[20]; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseActivityLine.FindFirst();

        WarehouseActivityLine.TestField("Activity Type", ActivityType);
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyPickBinAndQuantity(ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, LocationOrange.Code, WarehouseActivityHeader.Type::Pick);
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, ItemNo);
        Assert.AreEqual(BinCode, WarehouseActivityLine."Bin Code", BinErr);
        Assert.AreEqual(Quantity, WarehouseActivityLine.Quantity, QtyErr);
    end;

    local procedure VerifyPostedWhseReceiptLine(WhseReceiptNo: Code[20]; ItemNo: Code[20]; BinCode: Code[20])
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptLine.SetRange("Whse. Receipt No.", WhseReceiptNo);
        PostedWhseReceiptLine.SetRange("Source Document", PostedWhseReceiptLine."Source Document"::"Purchase Order");
        PostedWhseReceiptLine.SetRange("Item No.", ItemNo);
        PostedWhseReceiptLine.FindFirst();
        PostedWhseReceiptLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyRegisteredWhseActivityLine(LocationCode: Code[10]; SourceNo: Code[20]; ItemNo: Code[20]; BinCode: Code[20])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Action Type", RegisteredWhseActivityLine."Action Type"::Place);
        RegisteredWhseActivityLine.SetRange("Location Code", LocationCode);
        RegisteredWhseActivityLine.SetRange("Source Type", DATABASE::"Purchase Line");
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.FindFirst();
        RegisteredWhseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure CreateAndReleaseSalesOrderWithOneSalesLine(
        var SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
        LocationCode: Code[10];
        Quantity: Decimal)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesHeader(SalesHeader, Customer."No.", '', SalesHeader."Shipping Advice"::Partial);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, LocationCode, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure UpdateQtyToShipOnWhseShipmentLine(
        var WarehouseShipmentLine: Record "Warehouse Shipment Line";
        No: Code[20];
        QtyToShip: Decimal)
    begin
        WarehouseShipmentLine.SetRange("No.", No);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure UndoSalesShipmentLine(var SalesLine: Record "Sales Line"; OrderNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesLine.SetRange("Document No.", OrderNo);
        SalesLine.FindFirst();
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesShipmentLine.SetRange("Order Line No.", SalesLine."Line No.");
        SalesShipmentLine.FindFirst();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure FindWarehouseShipmentLine(
        var WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ItemNo: Code[20])
    begin
        WarehouseShipmentLine.Reset();
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ChangeUOMRequestPageHandler(var WhseChangeUnitOfMeasure: TestRequestPage "Whse. Change Unit of Measure")
    begin
        WhseChangeUnitOfMeasure.UnitOfMeasureCode.SetValue(LibraryVariableStorage.DequeueText());
        WhseChangeUnitOfMeasure.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentPageHandler(var WhseSourceCreateDocumentPageHandler: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocumentPageHandler.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DummyMessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, WarehouseOperations) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PutAwayMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, PutAwayActivitiesCreated) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ReceiptSpecialMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, ReceiptSpecialWarehouse) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ProductionSpecialMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, ProductionSpecialWarehouse) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingToHandleMessageHandler(Message: Text)
    begin
        Assert.IsTrue(StrPos(Message, NothingToHandleMsg) > 0, 'Wrong message.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

