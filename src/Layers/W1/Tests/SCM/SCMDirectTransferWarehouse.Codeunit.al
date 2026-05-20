codeunit 137108 "SCM Direct Transfer Warehouse"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Direct Transfer] [Warehouse] [SCM]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        WrongPostPreviewErr: Label 'Expected empty error from Preview. Actual error: ';
        UnexpectedTransferQtyErr: Label 'Unexpected transfer quantity at location %1 (Positive=%2).', Comment = '%1 = Location Code, %2 = Positive flag';
        InTransitCodeNotClearedErr: Label 'In-Transit Code must not be cleared when Direct Transfer Posting = "Shipment and Receipt".';

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferNoWarehouseRequirements()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [No Warehouse]
        // [SCENARIO 617394] Direct Transfer with "Shipment and Receipt" mode and no warehouse requirements posts directly
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");

        // [WHEN] Post Transfer Order directly
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] Transfer Shipment Header is created
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferShipmentHeader);

        // [THEN] Transfer Receipt Header is created (unified posting)
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferReceiptHeader);

        // [THEN] Item Ledger Entries show inventory moved from "FROM" to "TO"
        VerifyItemLedgerEntriesForTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferWithOutboundShipmentRequirement()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Shipment]
        // [SCENARIO 617394] Direct Transfer with "Shipment and Receipt" mode allows warehouse shipment on Transfer-from location
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, false, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order from "FROM" to "TO"
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");

        // [WHEN] Release Transfer Order
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Create Warehouse Shipment from Transfer Order
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [WHEN] Post Warehouse Shipment
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        PostWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] Transfer Shipment Header is created
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferShipmentHeader);

        // [THEN] Transfer Receipt Header is created (unified posting)
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferReceiptHeader);

        // [THEN] Item Ledger Entries show inventory moved from "FROM" to "TO"
        VerifyItemLedgerEntriesForTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferWithShipmentCannotCreatePick()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Shipment]
        // [SCENARIO 617394] Direct Transfer with "Require Shipment" only cannot create picks
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE only (no pick)
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, false, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order and Release
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Creation of Inventory  Pick is attempted
        Commit();
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Outbound Transfer", TransferLine."Document No.", false, true, false);

        // [THEN] Pick lines are not created
        WarehouseActivityLine.SetRange("Source No.", TransferHeader."No.");
        WarehouseActivityLine.SetRange("Location Code", LocationFrom.Code);
        Assert.RecordIsEmpty(WarehouseActivityLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferWithOutboundPickAndShipment()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Pick] [Warehouse Shipment]
        // [SCENARIO 617394] Direct Transfer with both "Require Pick" and "Require Shipment" on Transfer-from location
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with "Require Pick" = TRUE and "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, true, false, true);
        //CreateWarehouseBinsForLocation(LocationFrom.Code);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order and Release
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Create Warehouse Shipment
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [WHEN] Create Warehouse Pick from Shipment
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [WHEN] Register Warehouse Pick
        FindWarehouseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, LocationFrom.Code, TransferHeader."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post Warehouse Shipment
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        PostWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] Both Transfer Shipment and Receipt are posted
        VerifyTransferShipmentAndReceiptPosted(TransferHeader."No.");

        // [THEN] Inventory moved correctly
        VerifyItemLedgerEntriesForTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferWithPickShipmentCannotPostWithoutPick()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Pick] [Warehouse Shipment]
        // [SCENARIO 617394] Direct Transfer with Pick + Shipment cannot post warehouse shipment without registering pick
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with "Require Pick" = TRUE and "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, true, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order and Release
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Create Warehouse Shipment
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [WHEN] Create Warehouse Pick from Shipment (but don't register it)
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [WHEN] Attempt to post warehouse shipment without registering pick
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);

        // [THEN] Posting fails because pick is not registered
        asserterror PostWarehouseShipment(WarehouseShipmentHeader);
        Assert.ExpectedError('There is nothing to post');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferErrorWhenInboundLocationRequiresReceive()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Receipt]
        // [SCENARIO 617394] Direct Transfer fails validation when Transfer-to location requires warehouse receipt
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);

        // [GIVEN] Location "TO" with "Require Receive" = TRUE
        CreateLocationWithWarehouseSetup(LocationTo, false, false, false, true, false);

        // [GIVEN] Item with inventory
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order with "TO" location requiring receive
        // [THEN] Creating Direct Transfer fails with validation error
        asserterror CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        Assert.ExpectedError('Require Receive must be equal to ''No''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferErrorWhenInboundLocationRequiresPutaway()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Put-away]
        // [SCENARIO 617394] Direct Transfer fails validation when Transfer-to location requires put-away
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);

        // [GIVEN] Location "TO" with "Require Put-away" = TRUE
        CreateLocationWithWarehouseSetup(LocationTo, false, true, false, false, false);

        // [GIVEN] Item with inventory
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order with "TO" location requiring put-away
        // [THEN] Creating Direct Transfer fails with validation error
        asserterror CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        Assert.ExpectedError('Require Put-away must be equal to ''No''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferPostingModeDirectTransferAllowsWarehouse()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Inventory Setup]
        // [SCENARIO 617394] When "Direct Transfer Posting" = "Direct Transfer", warehouse handling is allowed on Transfer-from (legacy mode)
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Direct Transfer" (original mode)
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Direct Transfer");

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, false, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with inventory
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Direct Transfer");

        // [THEN] Transfer Order created successfully - in "Direct Transfer" mode, warehouse handling is allowed
        TransferHeader.TestField("Direct Transfer", true);
        TransferHeader.TestField("Transfer-from Code", LocationFrom.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferModeNoWarehouseRequirements()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DirectTransferHeader: Record "Direct Trans. Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Direct Transfer Mode]
        // [SCENARIO 617394] Direct Transfer in "Direct Transfer" mode posts from FROM to TO directly
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Direct Transfer"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Direct Transfer");

        // [GIVEN] Location "FROM" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Direct Transfer");

        // [WHEN] Post Transfer Order directly
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] Transfer Shipment Header is created
        //TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        //Assert.RecordIsNotEmpty(TransferShipmentHeader);// DIRECT TRANSFER DOCS ARE CREATED NOT THIS
        DirectTransferHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordCount(DirectTransferHeader, 1);

        // [THEN] Direct Transfer Header is created
        DirectTransferHeader.FindFirst();
        DirectTransferHeader.TestField("Transfer-from Code", LocationFrom.Code);
        DirectTransferHeader.TestField("Transfer-to Code", LocationTo.Code);

        // [THEN] Item Ledger Entries show direct transfer from "FROM" to "TO"
        VerifyItemLedgerEntriesForDirectTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferModeWithShipmentCompleteFlow()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        DirectTransferHeader: Record "Direct Trans. Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Direct Transfer Mode] [Warehouse Shipment]
        // [SCENARIO 617394] Direct Transfer in "Direct Transfer" mode with warehouse shipment posts from FROM to TO
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Direct Transfer"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Direct Transfer");

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, false, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Direct Transfer");

        // [WHEN] Release Transfer Order
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Create Warehouse Shipment from Transfer Order
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [WHEN] Post Warehouse Shipment
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        PostWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] Direct Transfer Header is created
        DirectTransferHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordCount(DirectTransferHeader, 1);
        DirectTransferHeader.FindFirst();
        DirectTransferHeader.TestField("Transfer-from Code", LocationFrom.Code);
        DirectTransferHeader.TestField("Transfer-to Code", LocationTo.Code);

        // [THEN] Item Ledger Entries show direct transfer from "FROM" to "TO"
        VerifyItemLedgerEntriesForDirectTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferModeWithPickAndShipment()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        DirectTransferHeader: Record "Direct Trans. Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Direct Transfer Mode] [Warehouse Pick] [Warehouse Shipment]
        // [SCENARIO 617394] Direct Transfer in "Direct Transfer" mode with Pick + Shipment posts via pick registration
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Direct Transfer"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Direct Transfer");

        // [GIVEN] Location "FROM" with "Require Pick" = TRUE and "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, true, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order and Release
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Direct Transfer");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Create Warehouse Shipment
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [WHEN] Create Warehouse Pick from Shipment
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [WHEN] Register Warehouse Pick
        FindWarehouseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, LocationFrom.Code, TransferHeader."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post Warehouse Shipment
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        PostWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] Direct Transfer Header is created
        DirectTransferHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordCount(DirectTransferHeader, 1);

        DirectTransferHeader.FindFirst();
        DirectTransferHeader.TestField("Transfer-from Code", LocationFrom.Code);
        DirectTransferHeader.TestField("Transfer-to Code", LocationTo.Code);

        // [THEN] Inventory moved directly from FROM to TO
        VerifyItemLedgerEntriesForDirectTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferModeWithPickOnly()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        DirectTransferHeader: Record "Direct Trans. Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Direct Transfer Mode] [Inventory Pick]
        // [SCENARIO 617394] Direct Transfer in "Direct Transfer" mode with Pick only posts via inventory pick
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Direct Transfer"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Direct Transfer");

        // [GIVEN] Location "FROM" with "Require Pick" = TRUE only
        CreateLocationWithWarehouseSetup(LocationFrom, true, false, true, false, false);
        CreateWarehouseBinsForLocation(LocationFrom.Code);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with inventory in bin
        CreateItemWithInventoryInBin(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Direct Transfer");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Create Inventory Pick
        LibraryWarehouse.CreateInvtPutPickMovement(
            "Warehouse Request Source Document"::"Outbound Transfer",
            TransferHeader."No.", false, true, false);

        // [WHEN] Register Inventory Pick
        FindWarehouseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::"Invt. Pick", LocationFrom.Code, TransferHeader."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Direct Transfer Header is created from FROM to TO
        DirectTransferHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordCount(DirectTransferHeader, 1);

        DirectTransferHeader.FindFirst();
        DirectTransferHeader.TestField("Transfer-from Code", LocationFrom.Code);
        DirectTransferHeader.TestField("Transfer-to Code", LocationTo.Code);

        // [THEN] Inventory moved directly from FROM to TO
        VerifyItemLedgerEntriesForDirectTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferUnifiedPostingWithLotTracking()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Item Tracking] [Lot Number]
        // [SCENARIO 617394] Direct Transfer with warehouse shipment correctly handles lot tracking across unified posting
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, false, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with lot tracking and inventory with specific lot number
        CreateItemWithLotTracking(Item);
        CreateItemInventoryWithLotNo(Item."No.", LocationFrom.Code, LotNo, Quantity);

        // [WHEN] Create Direct Transfer Order
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        AssignLotNoToTransferLine(TransferLine, LotNo, Quantity);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Create and post warehouse shipment
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        PostWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] Item Ledger Entries have correct lot number on both shipment and receipt sides
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", LocationTo.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(LotNo, ItemLedgerEntry."Lot No.", 'Lot number should match on receipt');
        Assert.AreEqual(Quantity, ItemLedgerEntry.Quantity, 'Quantity should match');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferMultipleLinesWithWarehouseShipment()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: array[3] of Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        Quantity: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Direct Transfer] [Multiple Lines]
        // [SCENARIO 617394] Direct Transfer with warehouse shipment correctly posts multiple transfer lines in unified transaction
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, false, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Three items with inventory
        for i := 1 to 3 do
            CreateItemWithPositiveInventory(Item[i], LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order with three lines
        CreateDirectTransferOrderHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");
        for i := 1 to 3 do
            CreateDirectTransferLine(TransferHeader, TransferLine, Item[i]."No.", '', Quantity);

        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Create and post warehouse shipment
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        PostWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] Transfer Shipment has three lines
        TransferShipmentLine.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.AreEqual(3, TransferShipmentLine.Count, 'Transfer Shipment should have 3 lines');

        // [THEN] All items have correct inventory at destination
        for i := 1 to 3 do
            VerifyItemLedgerEntriesForTransfer(Item[i]."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferPostErrorsWhenDestnLocIsBinMandatory()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Entry]
        // [SCENARIO 617394] Direct Transfer with warehouse shipment creates correct warehouse entries
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE and "Bin Mandatory" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, true, false, false, false, true);
        CreateWarehouseBinsForLocation(LocationFrom.Code);

        // [GIVEN] Location "TO" without warehouse requirements but with bins
        CreateLocationWithWarehouseSetup(LocationTo, true, false, false, false, false);
        CreateWarehouseBinsForLocation(LocationTo.Code);

        // [GIVEN] Item with inventory in bin at "FROM" location
        CreateItemWithInventoryInBin(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order and post via warehouse shipment
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        asserterror PostWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] Warehouse Entry created for shipment (negative)
        Assert.ExpectedError('New Bin Code must have a value in Item Journal Line');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferWarehouseEntriesCreatedCorrectly()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Entry]
        // [SCENARIO 617394] Direct Transfer with warehouse shipment creates correct warehouse entries
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE and "Bin Mandatory" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, true, false, false, false, true);
        CreateWarehouseBinsForLocation(LocationFrom.Code);

        // [GIVEN] Location "TO" without warehouse requirements but with bins
        CreateLocationWithWarehouseSetup(LocationTo, false, false, false, false, false);
        CreateWarehouseBinsForLocation(LocationTo.Code);

        // [GIVEN] Item with inventory in bin at "FROM" location
        CreateItemWithInventoryInBin(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order and post via warehouse shipment
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        PostWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] Warehouse Entry created for shipment (negative)
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", LocationFrom.Code);
        WarehouseEntry.SetFilter(Quantity, '<%1', 0);
        Assert.RecordIsNotEmpty(WarehouseEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferInventoryPickFlow()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Inventory Pick]
        // [SCENARIO 617394] Direct Transfer with "Require Pick" only (no shipment) posts correctly via inventory pick
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with "Require Pick" = TRUE only
        CreateLocationWithWarehouseSetup(LocationFrom, true, false, true, false, false);
        CreateWarehouseBinsForLocation(LocationFrom.Code);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with inventory in bin
        CreateItemWithInventoryInBin(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Create Inventory Pick
        LibraryWarehouse.CreateInvtPutPickMovement(
            "Warehouse Request Source Document"::"Outbound Transfer",
            TransferHeader."No.", false, true, false);

        // [WHEN] Register Inventory Pick
        FindWarehouseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::"Invt. Pick", LocationFrom.Code, TransferHeader."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Transfer is posted (both shipment and receipt)
        VerifyTransferShipmentAndReceiptPosted(TransferHeader."No.");

        // [THEN] Inventory moved correctly
        VerifyItemLedgerEntriesForTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferShouldPostReceiptWithShipmentTrue()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Unit Test]
        // [SCENARIO 617394] ShouldPostReceiptWithShipment() returns TRUE when conditions are met
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with warehouse requirements
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, false, false, true);

        // [GIVEN] Location "TO" without inbound warehouse handling
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with inventory
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");

        // [THEN] ShouldPostReceiptWithShipment() returns TRUE
        Assert.IsTrue(TransferHeader.ShouldPostReceiptWithShipment(), 'Should post shipment and receipt together');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferShouldPostReceiptWithShipmentFalseInDirectTransferMode()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Unit Test]
        // [SCENARIO 617394] ShouldPostReceiptWithShipment() returns FALSE when "Direct Transfer Posting" = "Direct Transfer"
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Direct Transfer"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Direct Transfer");

        // [GIVEN] Locations without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with inventory
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [WHEN] Create Direct Transfer Order
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Direct Transfer");

        // [THEN] ShouldPostShipmentAndReceiptTogether() returns FALSE
        Assert.IsFalse(TransferHeader.ShouldPostReceiptWithShipment(), 'Should not post shipment and receipt together in Direct Transfer mode');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferShouldPostReceiptWithShipmentFalseWithInboundWhse()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Unit Test]
        // [SCENARIO 617394] ShouldPostReceiptWithShipment() returns FALSE when Transfer-to has inbound warehouse handling
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);

        // [GIVEN] Location "TO" with "Require Put-away" = TRUE
        CreateLocationWithWarehouseSetup(LocationTo, false, true, false, false, false);

        // [GIVEN] Item with inventory
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [GIVEN] Create Transfer Order (not Direct Transfer, because Direct Transfer validation would block this)
        CreateTransferOrderHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, false);
        CreateDirectTransferLine(TransferHeader, TransferLine, Item."No.", '', Quantity);

        // [THEN] ShouldPostReceiptWithShipment() returns FALSE because inbound location has warehouse handling
        Assert.IsFalse(TransferHeader.ShouldPostReceiptWithShipment(), 'Should not post shipment and receipt together when inbound has warehouse handling');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PreviewPostingInvtPickDirectTransferShowsShipmentAndReceiptEntries()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        WhseActivityPost: Codeunit "Whse.-Act.-Post (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Inventory Pick] [Preview Posting]
        // [SCENARIO 617394] Preview posting from an inventory pick for a direct transfer order shows both transfer shipment and transfer receipt entries
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt"); // "Shipment and Receipt"

        // [GIVEN] Location "FROM" with "Require Pick" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, true, false, false);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [GIVEN] Direct Transfer Order from "FROM" to "TO"
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Inventory Pick created from the transfer order
        LibraryWarehouse.CreateInvtPutPickMovement(
            "Warehouse Request Source Document"::"Outbound Transfer",
            TransferHeader."No.", false, true, false);

        // [GIVEN] Qty to Handle is set on the inventory pick lines
        FindWarehouseActivityHeader(WarehouseActivityHeader, WarehouseActivityHeader.Type::"Invt. Pick", LocationFrom.Code, TransferHeader."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();

        Commit();

        // [WHEN] Preview posting is executed from the inventory pick
        GLPostingPreview.Trap();
        asserterror WhseActivityPost.Preview(WarehouseActivityLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] Preview shows Item Ledger Entries for both transfer shipment and transfer receipt (4 entries: 2 per document)
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 4);

        // [THEN] Preview shows Value Entries for both transfer shipment and transfer receipt (4 entries: 2 per document)
        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 4);

        GLPostingPreview.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InvtPickDirectTransferPartialPostAfterDeletingLotLine()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        ItemNonLot: Record Item;
        ItemLot: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Inventory Pick] [Item Tracking] [Partial Posting]
        // [SCENARIO 617394] Posting an inventory pick for a non-lot-tracked line succeeds after deleting the lot-tracked pick line
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt"); // "Shipment and Receipt"

        // [GIVEN] Location "FROM" with "Require Pick" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, true, false, false);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Non-lot-tracked item with positive inventory at "FROM"
        CreateItemWithPositiveInventory(ItemNonLot, LocationFrom.Code, Quantity);

        // [GIVEN] Lot-tracked item with inventory (LotNo) at "FROM"
        CreateItemWithLotTracking(ItemLot);
        CreateItemInventoryWithLotNo(ItemLot."No.", LocationFrom.Code, LotNo, Quantity);

        // [GIVEN] Direct Transfer Order from "FROM" to "TO" with two lines: non-lot item (Line 1) and lot item (Line 2)
        CreateDirectTransferOrderHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");
        CreateDirectTransferLine(TransferHeader, TransferLine, ItemNonLot."No.", '', Quantity);
        CreateDirectTransferLine(TransferHeader, TransferLine, ItemLot."No.", '', Quantity);
        AssignLotNoToTransferLine(TransferLine, LotNo, Quantity);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Inventory Pick created from the transfer order
        LibraryWarehouse.CreateInvtPutPickMovement(
            "Warehouse Request Source Document"::"Outbound Transfer",
            TransferHeader."No.", false, true, false);

        // [GIVEN] The inventory pick line for the lot-tracked item is deleted
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("Location Code", LocationFrom.Code);
        WarehouseActivityLine.SetRange("Source No.", TransferHeader."No.");
        WarehouseActivityLine.SetRange("Item No.", ItemLot."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityLine.Delete(true);

        // [GIVEN] Qty to Handle set for the remaining non-lot-tracked item line
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        Commit();

        // [WHEN] The inventory pick is posted for the non-lot-tracked item
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Non-lot-tracked item inventory is moved from "FROM" to "TO"
        VerifyItemLedgerEntriesForTransfer(ItemNonLot."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreviewPostingWhseShipmentDirectTransferNoFalseDeletionMessage()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        WhsePostShipmentYesNo: Codeunit "Whse.-Post Shipment (Yes/No)";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Shipment] [Preview Posting]
        // [SCENARIO 617394] Preview posting from a warehouse shipment for a direct transfer order does not show a false "Transfer Order has been deleted" message
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt"); // "Shipment and Receipt"

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, false, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [GIVEN] Direct Transfer Order from "FROM" to "TO"
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Warehouse Shipment created from the transfer order (emits a "created" message consumed by handler)
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();

        // Clear messages accumulated during setup so we only observe preview messages
        LibraryVariableStorage.Clear();
        Commit();

        // [WHEN] Preview posting is executed from the warehouse shipment
        GLPostingPreview.Trap();
        asserterror WhsePostShipmentYesNo.Preview(WarehouseShipmentLine);
        Assert.AreEqual('', GetLastErrorText, WrongPostPreviewErr + GetLastErrorText);

        // [THEN] No false "Transfer Order has been deleted" message was shown during preview
        Assert.AreEqual(0, LibraryVariableStorage.Length(),
            'Preview posting should not show a "Transfer Order has been deleted" message');

        // [THEN] Preview shows Item Ledger Entries for both transfer shipment and transfer receipt (4 entries: 2 per document)
        GLPostingPreview.First();
        VerifyGLPostingPreviewLine(GLPostingPreview, ItemLedgerEntry.TableCaption(), 4);

        // [THEN] Preview shows Value Entries for both transfer shipment and transfer receipt (4 entries: 2 per document)
        GLPostingPreview.Next();
        VerifyGLPostingPreviewLine(GLPostingPreview, ValueEntry.TableCaption(), 4);

        GLPostingPreview.OK().Invoke();

        // [THEN] Transfer order was not actually deleted during preview
        Assert.IsTrue(TransferHeader.Find(), 'Transfer order should still exist after preview posting');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferWhseShipmentPartialPosting()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
        PartialQty: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Shipment] [Partial Posting]
        // [SCENARIO 617394] A warehouse shipment for a direct transfer order can be partially posted, leaving the remaining quantity for a subsequent post
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        PartialQty := Round(Quantity / 2, 1);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, false, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [GIVEN] Direct Transfer Order from "FROM" to "TO"
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Warehouse Shipment created from the transfer order
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");

        // [GIVEN] Qty. to Ship is set to a partial quantity (less than the full quantity)
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Qty. to Ship", PartialQty);
        WarehouseShipmentLine.Modify(true);

        // [WHEN] Post the warehouse shipment with the partial quantity
        PostWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] Item Ledger Entries show only the partial quantity was moved
        VerifyItemLedgerEntriesForTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -PartialQty, PartialQty);

        // [THEN] Warehouse Shipment still exists with the remaining outstanding quantity
        Assert.IsTrue(WarehouseShipmentHeader.Find(), 'Warehouse Shipment should still exist after partial posting');

        // [THEN] The remaining quantity can be shipped in a subsequent posting
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);
        PostWarehouseShipment(WarehouseShipmentHeader);
        VerifyItemLedgerEntriesForTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DirectTransferWhseShipmentPostingWithPostingErrorsNotProcessed()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSetup: Record "Warehouse Setup";
        Quantity: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse Shipment] [Posting Policy]
        // [SCENARIO 617394] Posting a warehouse shipment for a direct transfer order succeeds when "Shipment Posting Policy" = "Posting errors are not processed"
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Warehouse Setup has "Shipment Posting Policy" = "Posting errors are not processed"
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Shipment Posting Policy", WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed");
        WarehouseSetup.Modify(true);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, false, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [GIVEN] Direct Transfer Order from "FROM" to "TO"
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Warehouse Shipment created from the transfer order
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);

        // [WHEN] Post the warehouse shipment
        PostWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] Transfer Shipment and Receipt are posted and inventory is moved
        VerifyTransferShipmentAndReceiptPosted(TransferHeader."No.");
        VerifyItemLedgerEntriesForTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferHeaderInheritsFromRoute()
    var
        TransferRoute: Record "Transfer Route";
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
    begin
        // [FEATURE] [Transfer Route]
        // [SCENARIO 617394] Transfer Header inherits Direct Transfer settings from Transfer Route
        Initialize();

        // [GIVEN] Two locations "From" and "To"
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);

        // [GIVEN] Transfer Route with "Direct Transfer" mode
        LibraryWarehouse.CreateAndUpdateTransferRoute(
            TransferRoute, LocationFrom.Code, LocationTo.Code, '', '', '');
        TransferRoute.Validate("Direct Transfer", true);
        TransferRoute.Validate("Direct Transfer Posting", TransferRoute."Direct Transfer Posting"::"Direct Transfer");
        TransferRoute.Modify(true);

        // [WHEN] Create Transfer Order with these locations
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');
        TransferHeader.Validate("Direct Transfer", true);

        // [THEN] Transfer Header should inherit the settings
        TransferHeader.TestField("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Direct Transfer");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferHeaderCanOverrideRoute()
    var
        TransferRoute: Record "Transfer Route";
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
    begin
        // [FEATURE] [Transfer Route]
        // [SCENARIO 617394] Transfer Header can override Direct Transfer settings from Transfer Route
        Initialize();

        // [GIVEN] Two locations "From" and "To"
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);

        // [GIVEN] Transfer Route with "Direct Transfer" mode
        LibraryWarehouse.CreateAndUpdateTransferRoute(
            TransferRoute, LocationFrom.Code, LocationTo.Code, '', '', '');
        TransferRoute.Validate("Direct Transfer", true);
        TransferRoute.Validate("Direct Transfer Posting", TransferRoute."Direct Transfer Posting"::"Direct Transfer");
        TransferRoute.Modify(true);

        // [GIVEN] Create Transfer Order (inherits from route)
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');

        // [WHEN] "Direct Transfer" is set to TRUE
        TransferHeader.Validate("Direct Transfer", true);

        // [THEN] "Direct Transfer Poting" is set to TRUE
        TransferHeader.TestField("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Direct Transfer");

        // [WHEN] Override to "Shipment and Receipt" mode
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");

        // [THEN] "Direct Transfer Posting" is overridden without any errors being thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferFromValidateCopiesRouteDefaultsToHeader()
    var
        TransferRoute: Record "Transfer Route";
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentService: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        // [FEATURE] [Transfer Route]
        // [SCENARIO 631788] Transfer-from Code validation copies route defaults to the header.
        Initialize();

        // [GIVEN] Locations and a transfer route with in-transit and shipping defaults.
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, '<1D>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentService, ShippingAgent.Code, ShippingTime);
        LibraryWarehouse.CreateAndUpdateTransferRoute(
            TransferRoute, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code,
            ShippingAgent.Code, ShippingAgentService.Code);

        // [GIVEN] A transfer order with only the destination location selected.
        LibraryInventory.CreateTransferHeader(TransferHeader, '', LocationTo.Code, '');

        // [WHEN] Transfer-from Code is validated.
        TransferHeader.Validate("Transfer-from Code", LocationFrom.Code);

        // [THEN] Route defaults are copied to the header.
        TransferHeader.TestField("In-Transit Code", LocationInTransit.Code);
        TransferHeader.TestField("Shipping Agent Code", ShippingAgent.Code);
        TransferHeader.TestField("Shipping Agent Service Code", ShippingAgentService.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferToValidateCopiesRouteDefaultsToHeader()
    var
        TransferRoute: Record "Transfer Route";
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentService: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        // [FEATURE] [Transfer Route]
        // [SCENARIO 631788] Transfer-to Code validation copies route defaults to the header.
        Initialize();

        // [GIVEN] Locations and a transfer route with in-transit and shipping defaults.
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, '<1D>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentService, ShippingAgent.Code, ShippingTime);
        LibraryWarehouse.CreateAndUpdateTransferRoute(
            TransferRoute, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code,
            ShippingAgent.Code, ShippingAgentService.Code);

        // [GIVEN] A transfer order with only the source location selected.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, '', '');

        // [WHEN] Transfer-to Code is validated.
        TransferHeader.Validate("Transfer-to Code", LocationTo.Code);

        // [THEN] Route defaults are copied to the header.
        TransferHeader.TestField("In-Transit Code", LocationInTransit.Code);
        TransferHeader.TestField("Shipping Agent Code", ShippingAgent.Code);
        TransferHeader.TestField("Shipping Agent Service Code", ShippingAgentService.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiptAndShipmentModeRequiresMatchingQuantities()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
    begin
        // [FEATURE] [Direct Transfer] [Validation]
        // [SCENARIO 617394] "Shipment and Receipt" mode requires Qty to Ship = Qty to Receive
        Initialize();

        // [GIVEN] Two locations
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with inventory
        LibraryInventory.CreateItem(Item);
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Transfer Order with "Shipment and Receipt" mode
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        TransferHeader.Modify(true);

        // [GIVEN] Transfer Line with Quantity = 10
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);

        // [WHEN] Set Qty. to Ship = 10 but Qty. to Receive = 5
        TransferLine.Validate("Qty. to Receive", 5);
        TransferLine.Modify(true);

        // [THEN] Posting should fail with error
        asserterror TransferOrderPostYesNo.Run(TransferHeader);
        Assert.ExpectedError('The quantity to ship and quantity to receive must be equal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InTransitCodeGetsClearedWhenDirectTransferIsTrue()
    var
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
    begin
        // [FEATURE] [Direct Transfer] [In-Transit]
        // [SCENARIO 617394] "Shipment and Receipt" mode allows using In-Transit Code
        Initialize();

        // [GIVEN] Three locations
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationInTransit);

        // [GIVEN] Transfer Order with "Shipment and Receipt" mode
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');

        // [WHEN] Direct Transfer is set to true
        TransferHeader.Validate("Direct Transfer", true);

        // [WHEN] In-Transit Code is set to ''
        TransferHeader.TestField("In-Transit Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferModeBlocksInTransitCode()
    var
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
    begin
        // [FEATURE] [Direct Transfer] [In-Transit]
        // [SCENARIO 617394] "Direct Transfer" mode should have Direct Transfer = TRUE which blocks In-Transit Code on page
        Initialize();

        // [GIVEN] Two locations
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);

        // [GIVEN] Transfer Order with "Direct Transfer" mode
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Direct Transfer");
        TransferHeader.Modify(true);

        // [THEN] Direct Transfer checkbox is TRUE (which makes In-Transit Code disabled on page)
        TransferHeader.TestField("Direct Transfer", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferPostingClearsInTransitCodeWhenSetToDirectTransferMode()
    var
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
    begin
        // [FEATURE] [Direct Transfer] [In-Transit]
        // [SCENARIO 631788] Validating Direct Transfer Posting = "Direct Transfer" clears In-Transit Code on the header.
        Initialize();

        // [GIVEN] Locations and an in-transit location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);

        // [GIVEN] Direct Transfer order in "Shipment and Receipt" mode with In-Transit Code entered.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        TransferHeader.Validate("In-Transit Code", LocationInTransit.Code);
        TransferHeader.Modify(true);

        // [WHEN] Direct Transfer Posting is changed to "Direct Transfer".
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Direct Transfer");

        // [THEN] In-Transit Code is automatically cleared.
        TransferHeader.TestField("In-Transit Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferPostingChecksInboundWhseHandlingOnTransferToLocation()
    var
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
    begin
        // [FEATURE] [Direct Transfer] [Warehouse]
        // [SCENARIO 631788] Validating Direct Transfer Posting checks inbound warehouse handling requirements on Transfer-to location.
        Initialize();

        // [GIVEN] From location without WMS and To location requiring receive.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWMS(LocationTo, false, false, false, true, false);

        // [GIVEN] Direct Transfer order in "Direct Transfer" posting mode.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');

        // [WHEN] Direct Transfer is set to true which sets Direct Transfer Posting to "Shipment and Receipt".
        asserterror TransferHeader.Validate("Direct Transfer", true);

        // [THEN] Validation fails because Transfer-to location has inbound warehouse handling enabled.
        Assert.ExpectedError(LocationTo.FieldCaption("Require Receive"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferHeaderDirectTransferPostingErrorsIfDirectTransferIsFalse()
    var
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: Record Item;
    begin
        // [FEATURE] [Direct Transfer] [Receipt and Shipment]
        // [SCENARIO 617394] Transfer Order errors if Direct Transfer Posting is set without switching "Direct Transfer" ON
        Initialize();

        // [GIVEN] Three locations: From, To, and In-Transit
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);

        // [GIVEN] Item with inventory at From location
        LibraryInventory.CreateItem(Item);
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Create Transfer Order with "Shipment and Receipt" mode
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferHeader.Validate("Direct Transfer", false);

        // [WHEN] Try to set "Direct Transfer Posting" to "Shipment and Receipt" without switching "Direct Transfer" ON
        asserterror TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        // [THEN] Error is raised
        Assert.ExpectedError(TransferHeader.FieldCaption("Direct Transfer"));

        // [WHEN] Try to set "Direct Transfer Posting" to "Direct Transfer" without switching "Direct Transfer" ON
        asserterror TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Direct Transfer");
        // [THEN] Error is raised
        Assert.ExpectedError(TransferHeader.FieldCaption("Direct Transfer"));

        // [WHEN] Set "Direct Transfer" to TRUE, then set "Direct Transfer Posting" to "Shipment and Receipt"
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::" ");
        // [THEN] No error should occur
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferHeaderDirectTransferModeVerifyDocs()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        DirectTransHeader: Record "Direct Trans. Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        // [FEATURE] [Direct Transfer] [Direct Transfer Mode]
        // [SCENARIO 617394] Transfer Order with "Direct Transfer" mode creates single Posted Direct Transfer
        Initialize();

        // [GIVEN] Two locations: From and To
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item with inventory at From location
        LibraryInventory.CreateItem(Item);
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Create Transfer Order with "Direct Transfer" mode
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Direct Transfer");
        TransferHeader.Modify(true);

        // [GIVEN] Create Transfer Line
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Post Transfer Order
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] Posted Direct Transfer is created
        DirectTransHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordIsNotEmpty(DirectTransHeader);

        // [THEN] No Transfer Shipment or Receipt created
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordIsEmpty(TransferShipmentHeader);

        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordIsEmpty(TransferReceiptHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostAndPrintWhseShipmentDirectTransferMode()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        DirectTransferHeader: Record "Direct Trans. Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Post & Print warehouse shipment for direct transfer with Direct Transfer posting mode does not error
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Direct Transfer"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Direct Transfer");

        // [GIVEN] Location "FROM" with "Require Shipment" = TRUE
        CreateLocationWithWarehouseSetup(LocationFrom, false, false, false, false, true);

        // [GIVEN] Location "TO" without warehouse requirements
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);

        // [GIVEN] Item "I" with positive inventory at location "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [GIVEN] Direct Transfer Order from "FROM" to "TO"
        CreateDirectTransferOrder(TransferHeader, TransferLine, LocationFrom.Code, LocationTo.Code, Item."No.", '', Quantity, TransferHeader."Direct Transfer Posting"::"Direct Transfer");

        // [GIVEN] Transfer Order is released
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Warehouse Shipment "WS" is created from Transfer Order
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, TransferHeader."No.");
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);

        // [WHEN] Post Warehouse Shipment.
        PostWarehouseShipment(WarehouseShipmentHeader);

        // [THEN] Direct Transfer Header is created (no error occurred)
        DirectTransferHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordCount(DirectTransferHeader, 1);

        // [THEN] Inventory moved correctly from "FROM" to "TO"
        VerifyItemLedgerEntriesForDirectTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure DirectTransferShipmentAndReceiptWithInTransitPostsViaInTransit()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 631788] Direct Transfer with "Shipment and Receipt" posting type and an In-Transit Code entered on the order:
        // items are first moved FROM → In-Transit (shipment leg) then In-Transit → TO (receipt leg) in one transaction.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 100);

        // [GIVEN] Inventory Setup has "Direct Transfer Posting" = "Shipment and Receipt"
        SetDirectTransferPostingMode(Enum::"Direct Transfer Posting Type"::"Shipment and Receipt");

        // [GIVEN] Locations "FROM", "TO" and an In-Transit location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);

        // [GIVEN] Item with positive inventory at "FROM"
        CreateItemWithPositiveInventory(Item, LocationFrom.Code, Quantity);

        // [GIVEN] A Transfer Header created without an In-Transit Code
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');

        // [WHEN] "Direct Transfer" is set to TRUE, posting is set to "Shipment and Receipt", and In-Transit Code is entered manually
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Shipment and Receipt");
        TransferHeader.Validate("In-Transit Code", LocationInTransit.Code);
        TransferHeader.Modify(true);

        // [THEN] "In-Transit Code" is stored on the order and used during posting
        Assert.AreEqual(
            LocationInTransit.Code,
            TransferHeader."In-Transit Code",
            InTransitCodeNotClearedErr);

        // [WHEN] Transfer line is added and the order is posted
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Quantity);
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] An item ledger entry moves items FROM → In-Transit (shipment leg)
        VerifyItemLedgerEntryByLocationAndSign(Item."No.", LocationInTransit.Code, true, Quantity);

        // [THEN] An item ledger entry moves items In-Transit → TO (receipt leg)
        VerifyItemLedgerEntryByLocationAndSign(Item."No.", LocationInTransit.Code, false, -Quantity);

        // [THEN] Net movement: FROM loses Qty, TO gains Qty
        VerifyItemLedgerEntriesForTransfer(Item."No.", LocationFrom.Code, LocationTo.Code, -Quantity, Quantity);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if isInitialized then
            exit;

        InventorySetup.Get();
        InventorySetup.Validate("Direct Transfer Posting Type", InventorySetup."Direct Transfer Posting Type"::"Shipment and Receipt"); // "Shipment and Receipt"
        InventorySetup.Modify();

        isInitialized := true;
        Commit();
    end;

    local procedure SetDirectTransferPostingMode(PostingMode: Enum "Direct Transfer Posting Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Direct Transfer Posting Type", PostingMode);
        InventorySetup.Modify();
        Commit();
    end;

    local procedure CreateLocationWithWarehouseSetup(var Location: Record Location; BinMandatory: Boolean; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
    end;

    local procedure CreateWarehouseBinsForLocation(LocationCode: Code[10])
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, CopyStr(LibraryUtility.GenerateGUID(), 1, 20), '', '');
        LibraryWarehouse.CreateBin(Bin, LocationCode, CopyStr(LibraryUtility.GenerateGUID(), 1, 20), '', '');
    end;

    local procedure CreateItemWithPositiveInventory(var Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationCode, '', Quantity, 0);
    end;

    local procedure CreateItemWithInventoryInBin(var Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        Bin: Record Bin;
    begin
        LibraryInventory.CreateItem(Item);
        FindFirstBinForLocation(Bin, LocationCode);
        CreateAndPostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationCode, Bin.Code, Quantity, 0);
    end;

    local procedure CreateItemWithLotTracking(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemInventoryWithLotNo(ItemNo: Code[20]; LocationCode: Code[10]; LotNo: Code[50]; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, '', LotNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLine(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode);
        if UnitCost <> 0 then
            ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateTransferOrderHeader(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; DirectTransfer: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if DirectTransfer then begin
            InventorySetup.Get();
            CreateTransferOrderHeader(TransferHeader, FromLocationCode, ToLocationCode, DirectTransfer, InventorySetup."Direct Transfer Posting Type");
        end else
            CreateTransferOrderHeader(TransferHeader, FromLocationCode, ToLocationCode, DirectTransfer, Enum::"Direct Transfer Posting Type"::" ");
    end;

    local procedure CreateTransferOrderHeader(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; DirectTransfer: Boolean; DirectTransferPosting: Enum "Direct Transfer Posting Type")
    var
        InTransitLocation: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocation.Code);
        if DirectTransfer then begin
            TransferHeader.Validate("Direct Transfer", true);
            TransferHeader.Validate("Direct Transfer Posting", DirectTransferPosting);
            TransferHeader.Modify(true);
        end;
    end;

    local procedure CreateDirectTransferOrderHeader(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; DirectTransferPosting: Enum "Direct Transfer Posting Type")
    begin
        CreateTransferOrderHeader(TransferHeader, FromLocationCode, ToLocationCode, true, DirectTransferPosting);
    end;

    local procedure CreateDirectTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal; DirectTransferPosting: Enum "Direct Transfer Posting Type")
    begin
        CreateDirectTransferOrderHeader(TransferHeader, FromLocationCode, ToLocationCode, DirectTransferPosting);
        CreateDirectTransferLine(TransferHeader, TransferLine, ItemNo, VariantCode, Quantity);
    end;

    local procedure CreateDirectTransferLine(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        if VariantCode <> '' then begin
            TransferLine.Validate("Variant Code", VariantCode);
            TransferLine.Modify(true);
        end;
    end;

    local procedure AssignLotNoToTransferLine(var TransferLine: Record "Transfer Line"; LotNo: Code[50]; Quantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryItemTracking.CreateTransferOrderItemTracking(ReservationEntry, TransferLine, '', LotNo, Quantity);
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferOrderNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Outbound Transfer");
        WarehouseShipmentLine.SetRange("Source No.", TransferOrderNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; Type: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", Type);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(Type, WarehouseActivityLine."No.");
    end;

    local procedure FindFirstBinForLocation(var Bin: Record Bin; LocationCode: Code[10])
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.FindFirst();
    end;

    local procedure VerifyTransferShipmentAndReceiptPosted(TransferOrderNo: Code[20])
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferOrderNo);
        Assert.RecordIsNotEmpty(TransferShipmentHeader);

        TransferReceiptHeader.SetRange("Transfer Order No.", TransferOrderNo);
        Assert.RecordIsNotEmpty(TransferReceiptHeader);
    end;

    local procedure VerifyItemLedgerEntriesForTransfer(ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ExpectedQtyFrom: Decimal; ExpectedQtyTo: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", FromLocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(ExpectedQtyFrom, ItemLedgerEntry.Quantity, 'Item ledger quantity incorrect for FROM location');

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", ToLocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(ExpectedQtyTo, ItemLedgerEntry.Quantity, 'Item ledger quantity incorrect for TO location');
    end;

    local procedure VerifyItemLedgerEntriesForDirectTransfer(ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ExpectedQtyFrom: Decimal; ExpectedQtyTo: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", FromLocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Direct Transfer");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(ExpectedQtyFrom, ItemLedgerEntry.Quantity, 'Item ledger quantity incorrect for FROM location');

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", ToLocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Direct Transfer");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(ExpectedQtyTo, ItemLedgerEntry.Quantity, 'Item ledger quantity incorrect for TO location');
    end;

    local procedure PostWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure VerifyGLPostingPreviewLine(GLPostingPreview: TestPage "G/L Posting Preview"; TableName: Text; ExpectedEntryCount: Integer)
    begin
        Assert.AreEqual(TableName, GLPostingPreview."Table Name".Value, StrSubstNo('A record for Table Name %1 was not found.', TableName));
        Assert.AreEqual(ExpectedEntryCount, GLPostingPreview."No. of Records".AsInteger(),
            StrSubstNo('Table Name %1 Unexpected number of records.', TableName));
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Acknowledge messages
    end;

    [MessageHandler]
    procedure TrackingMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    local procedure VerifyItemLedgerEntryByLocationAndSign(ItemNo: Code[20]; LocationCode: Code[10]; IsPositive: Boolean; ExpectedQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange(Positive, IsPositive);
        Assert.RecordCount(ItemLedgerEntry, 1);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(
            ExpectedQuantity,
            ItemLedgerEntry.Quantity,
            StrSubstNo(UnexpectedTransferQtyErr, LocationCode, IsPositive));
    end;

    [StrMenuHandler]
    procedure StrMenuHandlerShip(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;
}
