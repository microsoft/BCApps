codeunit 137048 "SCM Warehouse II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
    end;

    var
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseEmployee: Record "Warehouse Employee";
        LocationGreen: Record Location;
        LocationBlue: Record Location;
        LocationOrange: Record Location;
        LocationOrange2: Record Location;
        LocationOrange3: Record Location;
        LocationWhite: Record Location;
        LocationRed: Record Location;
        LocationPink: Record Location;
        LocationIntransit: Record Location;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        WarehouseShipmentNo: Code[20];
        NewUnitOfMeasure: Code[10];
        BinError: Label 'Bin Code must be%1 in %2.';
        BinError2: Label 'Bin Code must be %1 in %2.';
        QuantityError: Label 'Quantity must be %1 in %2.';
        ErrorText: Label 'You can create a Pick only for the available quantity in Whse. Worksheet Line ';
        ErrorQtyToHandleText: Label 'Qty. to Ship must not be greater than 0 units in Warehouse Shipment Line No.=''%1''';
        ErrorMessage: Label 'Wrong Error Message';
        UnexpectedMessageDialog: Label 'Unexpected Message dialog %1.';
        DisregardMessage: Label 'The entered information may be disregarded by warehouse activities.';
        DeletedMessage: Label 'was successfully posted and is now deleted.';
        HandlingError: Label 'Nothing to handle.';
        LocationCode2: Code[10];
        PickActivityMessage: Label 'Pick activity no. ';
        PutAwayActivityMessage: Label 'Put-away activity no. ';
        NonWarehouseErr: Label 'Directed Put-away and Pick must have a value';
        BinContentGetCaptionErr: Label 'BinContent.GetCaption does not work with %1';
        LocationCodeMustMatchErr: Label 'Location Code must match.';
        QuantityErr: Label 'Quantity must not be changed when a Warehouse Receipt Line for this Purchase Line exists:  in Purchase Line Document Type=''%1'',Document No.=''%2'',Line No.=''%3''.',
                     Comment = '%1= Document Type Value, %2= Document No. Value, %3= Line No. Value.';

    [Test]
    [Scope('OnPrem')]
    procedure TransferWhseShipment()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        BinCode: Code[20];
        WarehouseShipmentNo: Code[20];
    begin
        // Setup : Create Item, Transfer Order.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, Item."No.", LocationOrange.Code, LocationOrange2.Code, LocationIntransit.Code);
        WarehouseShipmentNo := FindWarehouseShipmentNo();

        // Exercise: Create Warehouse Shipment from Transfer Order.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // Verify : Check that Bin Code is same as on Transfer Order.
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentNo);
        Assert.AreEqual(BinCode, WarehouseShipmentLine."Bin Code", StrSubstNo(BinError, BinCode, WarehouseShipmentLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferWhseCreatePick()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BinCode: Code[20];
        BinCode2: Code[20];
        WarehouseShipmentNo: Code[20];
    begin
        // Setup : Create Item, Transfer Order, Create Warehouse Shipment from Transfer Order and change bin code on Shipment Line.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, Item."No.", LocationOrange.Code, LocationOrange2.Code, LocationIntransit.Code);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        WhseShipFromTOWithNewBinCode(BinCode2, TransferHeader, WarehouseShipmentNo, LocationOrange.Code);

        // Exercise: Create Pick.
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Verify: Check that Place Bin Code is same as changed on shipment line and Take Bin Code as transfer order line.
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LocationOrange.Code,
          TransferHeader."No.", BinCode);
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place, LocationOrange.Code,
          TransferHeader."No.", BinCode2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferWhseReceipt()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        BinCode2: Code[20];
        WarehouseReceiptNo: Code[20];
        WarehouseShipmentNo: Code[20];
    begin
        // Setup : Create Item, Transfer Order, Create Warehouse Shipment from Transfer Order and change bin code on Shipment Line and Post
        // Warehouse Shipment.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, Item."No.", LocationOrange.Code, LocationOrange2.Code, LocationIntransit.Code);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        WhseShipFromTOWithNewBinCode(BinCode2, TransferHeader, WarehouseShipmentNo, LocationOrange.Code);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);
        RegisterWarehouseActivity(TransferHeader."No.", WarehouseActivityHeader.Type::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // Exercise: Create Warehouse Receipt from Transfer Order.
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);

        // Verify: Check that Warehouse Receipt Line Bin Code is same as Transfer To Bin Code.
        WarehouseReceiptNo := FindWarehouseReceiptNo(WarehouseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.");
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptNo);
        WarehouseReceiptLine.FindFirst();
        Assert.AreEqual(
          TransferLine."Transfer-To Bin Code", WarehouseReceiptLine."Bin Code",
          StrSubstNo(BinError, TransferLine."Transfer-To Bin Code", WarehouseReceiptLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ShipmentReceiptDeleteMessageHandler')]
    [Scope('OnPrem')]
    procedure TransferPostWhseReceipt()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        BinCode2: Code[20];
        WarehouseShipmentNo: Code[20];
    begin
        // Setup : Create Item, Transfer Order, Create Warehouse Shipment from Transfer Order and change bin code on Shipment Line and Post
        // Warehouse Shipment.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, Item."No.", LocationOrange.Code, LocationOrange2.Code, LocationIntransit.Code);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        WhseShipFromTOWithNewBinCode(BinCode2, TransferHeader, WarehouseShipmentNo, LocationOrange.Code);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);
        RegisterWarehouseActivity(TransferHeader."No.", WarehouseActivityHeader.Type::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);

        // Exercise:
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.");

        // Verify: Check that Take and Place Bin Code is same as changed on Transfer To Bin Code on Warehouse Activity Line.
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take, LocationOrange2.Code,
          TransferHeader."No.", TransferLine."Transfer-To Bin Code");
        // The program selectes first bin that is not shipment bin, receipt bin or posted whse receipt line (take line) bin (look into help). As result we need to check negative condition
        VerifyBinCodeNotEqual(
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, LocationOrange2.Code,
          TransferHeader."No.", TransferLine."Transfer-To Bin Code");
        VerifyBinCodeNotEqual(
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, LocationOrange2.Code,
          TransferHeader."No.", '');
    end;

    [Test]
    [HandlerFunctions('ShipmentReceiptDeleteMessageHandler')]
    [Scope('OnPrem')]
    procedure TransferRegisterPutAway()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        BinContent: Record "Bin Content";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        BinCode2: Code[20];
        WarehouseShipmentNo: Code[20];
    begin
        // Setup : Create Item, Transfer Order, Create Warehouse Shipment from Transfer Order and change bin code on Shipment Line and Post
        // Warehouse Shipment and Post Warehouse Receipt.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, Item."No.", LocationOrange.Code, LocationOrange2.Code, LocationIntransit.Code);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        WhseShipFromTOWithNewBinCode(BinCode2, TransferHeader, WarehouseShipmentNo, LocationOrange.Code);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);
        RegisterWarehouseActivity(TransferHeader."No.", WarehouseActivityHeader.Type::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.");

        // Exercise: Register Put Away.
        RegisterWarehouseActivity(TransferHeader."No.", WarehouseActivityHeader.Type::"Put-away");

        // Verify: Check That Bin Content Quantity is same as Quantity on Transfer Order.
        FindBinContent(BinContent, LocationOrange2.Code, Item."No.");
        BinContent.CalcFields(Quantity);
        Assert.AreEqual(
          TransferLine.Quantity, BinContent.Quantity, StrSubstNo(QuantityError, TransferLine.Quantity, TransferLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseCreateSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        BinCode: Code[20];
    begin
        // Setup : Create Item, Bin Content for the item.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.

        // Exercise.
        CreateSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());

        // Verify: Check that Bin Code is same as Default Bin Code.
        SalesLine.TestField("Bin Code", BinCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesWhseShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Item: Record Item;
        BinCode: Code[20];
        WarehouseShipmentNo: Code[20];
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        WarehouseShipmentNo := FindWarehouseShipmentNo();

        // Exercise.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Check That Bin Code on Warehouse Shipment Line is same as Bin Code as on Sales Line.
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentNo);
        Assert.AreEqual(BinCode, WarehouseShipmentLine."Bin Code", StrSubstNo(BinError, BinCode, WarehouseShipmentLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreatePick()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BinCode: Code[20];
        WarehouseShipmentNo: Code[20];
        BinCode2: Code[20];
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order, Create Warehouse Shipment.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        WhseShipFromSOWithNewBinCode(BinCode2, SalesHeader, WarehouseShipmentNo, LocationOrange.Code);

        // Exercise.
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Verify: Check that Place Bin Code is same as changed on shipment line and Take Bin Code as Bin Code on Sales order line.
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LocationOrange.Code, SalesHeader."No.",
          BinCode);
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place, LocationOrange.Code, SalesHeader."No.",
          BinCode2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRegisterPickPostShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
        BinCode: Code[20];
        WarehouseShipmentNo: Code[20];
        BinCode2: Code[20];
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order, Create Warehouse Shipment, Create And
        // Register Pick.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        WhseShipFromSOWithNewBinCode(BinCode2, SalesHeader, WarehouseShipmentNo, LocationOrange.Code);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityHeader.Type::Pick);

        // Exercise.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // Verify: Check that Warehouse Entry Quantity and Bin Code are same as Sales Line after change Bin Code on Warehouse Shipment Line.
        FindWarehouseEntry(WarehouseEntry, Item."No.", LocationOrange.Code);
        VerifyWarehouseEntry(WarehouseEntry, BinCode, -SalesLine.Quantity);
        WarehouseEntry.Next();
        VerifyWarehouseEntry(WarehouseEntry, BinCode2, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('DisregardedMessageHandler')]
    [Scope('OnPrem')]
    procedure SalesDefaultBinWarningMessage()
    var
        Item: Record Item;
        BinContent: Record "Bin Content";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Bin: Record Bin;
    begin
        // Setup : Create Item, Bin Content for the Item and Create Sales Order.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 2);
        LibraryWarehouse.CreateBinContent(BinContent, LocationOrange.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        UpdateItemInventory(Item."No.", LocationOrange.Code, Bin.Code, LibraryRandom.RandDec(100, 2) + 100);

        // Exercise, Verify : Change Bin Code and check that warning message is Pop Out or Not. Verification is done under Message Handler.
        SalesLine.Validate("Bin Code", Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseCreatePurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        BinCode: Code[20];
    begin
        // Setup : Create Item, Bin Content for the item.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.

        // Exercise.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");

        // Verify: Check that Bin Code is same as Default Bin Code.
        PurchaseLine.TestField("Bin Code", BinCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseWarehouseReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Item: Record Item;
        BinCode: Code[20];
        WarehouseReceiptNo: Code[20];
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Exercise:
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Verify: Check That Bin Code on Warehouse Receipt Line is same as Bin Code as on Purchase Line.
        WarehouseReceiptNo := FindWarehouseReceiptNo(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptNo);
        Assert.AreEqual(BinCode, WarehouseReceiptLine."Bin Code", StrSubstNo(BinError, BinCode, WarehouseReceiptLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePutAway()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Item: Record Item;
        BinCode: Code[20];
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Exercise:
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Verify: Check that Take and Place Bin Code is same as Receipt line Bin Code.
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take, LocationOrange.Code,
          PurchaseHeader."No.", BinCode);
        // The program selectes first bin that is not shipment bin, receipt bin or posted whse receipt line (take line) bin (look into help). As result we need to check negative condition
        VerifyBinCodeNotEqual(
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, LocationOrange.Code,
          PurchaseHeader."No.", BinCode);
        VerifyBinCodeNotEqual(
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, LocationOrange.Code,
          PurchaseHeader."No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseChangeBinAndRegister()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Item: Record Item;
        WarehouseEntry: Record "Warehouse Entry";
        BinCode: Code[20];
        BinCode2: Code[20];
    begin
        // Setup : Create Item, Bin Content for the Item and Create and Release Sales Order.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Exercise: Change Bin Code on Put Away Line and Register Put Away.
        ChangeBinCodeOnActivityLine(BinCode2, PurchaseHeader."No.", LocationOrange.Code);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify: Check that Warehouse Entry Quantity and Bin Code are same as Purchase Line after change Bin Code on
        // Put Away and Register.
        FindWarehouseEntry(WarehouseEntry, Item."No.", LocationOrange.Code);
        VerifyWarehouseEntry(WarehouseEntry, BinCode, -PurchaseLine.Quantity);
        WarehouseEntry.Next();
        VerifyWarehouseEntry(WarehouseEntry, BinCode2, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('DisregardedMessageHandler')]
    [Scope('OnPrem')]
    procedure PurchDefaultBinWarningMessage()
    var
        Item: Record Item;
        BinContent: Record "Bin Content";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
    begin
        // Setup : Create Item, Bin Content for the Item and Create Purchase Order.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 2);  // Value required for Bin Index.
        LibraryWarehouse.CreateBinContent(BinContent, LocationOrange.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        UpdateItemInventory(Item."No.", LocationOrange.Code, Bin.Code, LibraryRandom.RandDec(100, 2) + 100);

        // Exercise, Verify : Change Bin Code and check that warning message is Pop Out or Not. Verification is done under Message Handler.
        PurchaseLine.Validate("Bin Code", Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderBinCode()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        BinCode: Code[20];
    begin
        // Setup : Create Item, Bin Content for the Item and Create Production BOM with Two Item of different Default Bin and
        // attached with Item.
        Initialize();
        BinCode := CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateItemAddInventory(Item2, LocationOrange.Code, 2);
        CreateItemAddInventory(Item3, LocationOrange.Code, 3);
        CreateBOM(ProductionBOMHeader, Item2."No.", Item3."No.", LibraryRandom.RandDec(100, 2));
        Item.Find();
        ItemWithProductionBOM(Item, ProductionBOMHeader."No.");

        // Exercise: Create Firm Planned Production Order.
        CreateProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.", LocationOrange.Code,
          LibraryRandom.RandDec(100, 2), WorkDate());

        // Verify: Check that Production Order Bin Code is same as Default Bin Code of Item.
        ProductionOrder.TestField("Bin Code", BinCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrdComponentBinCode()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        BinCode: Code[20];
        BinCode2: Code[20];
    begin
        // Setup : Create Item, Bin Content for the Item and Create Production BOM with Two Item of different Default Bin and
        // attached with Item and Create Firm Planned Production Order.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        BinCode := CreateItemAddInventory(Item2, LocationOrange.Code, 2);
        BinCode2 := CreateItemAddInventory(Item3, LocationOrange.Code, 3);
        CreateBOM(ProductionBOMHeader, Item2."No.", Item3."No.", LibraryRandom.RandDec(100, 2));
        Item.Find();
        ItemWithProductionBOM(Item, ProductionBOMHeader."No.");
        CreateProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.", LocationOrange.Code,
          LibraryRandom.RandDec(100, 2), WorkDate());

        // Exercise:
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify that Bin Code of Production Order Component Item is same as default Bin Code of Item.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        VerifyBinOnProdOrdComponent(ProdOrderComponent, Item2."No.", BinCode);
        ProdOrderComponent.Next();
        VerifyBinOnProdOrdComponent(ProdOrderComponent, Item3."No.", BinCode2);
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure BinCodeForPickUsingWorkSheet()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        salesLine: Record "Sales Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        BinCode: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Item, Update Inventory, Warehouse Shipment and Select Document from Pick Selection Page.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 1);
        UpdateItemInventory(Item."No.", LocationOrange.Code, Bin.Code, Quantity);

        CreateAndReleaseSalesOrder(SalesHeader, salesLine, LocationOrange.Code, Item."No.", Quantity, WorkDate());
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        WhseShipFromSOWithNewBinCode(BinCode, SalesHeader, WarehouseShipmentNo, LocationOrange.Code);
        ReleaseWarehouseShipment(WarehouseShipmentHeader, WarehouseShipmentNo);
        LocationCode2 := LocationOrange.Code;  // Assign value to global variable for use in handler.

        // Create Pick Worksheet Template, Getsource Document and Select the Pick Line from Pick Selection Page.
        CreateWhseWorksheetName(WhseWorksheetName, LocationOrange.Code);
        GetSourceDocOutbound.GetSingleWhsePickDoc(
          WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationOrange.Code);
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationOrange.Code);

        // Exercise : Create Pick From Pick Worksheet.
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, 10000, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          LocationOrange.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        // Verify: Check that Take and Place Bin Code is same as expected.
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LocationOrange.Code, SalesHeader."No.",
          Bin.Code);
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place, LocationOrange.Code, SalesHeader."No.",
          BinCode);
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure PickErrorForQtyWhseWorksheet()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        BinCode: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Item, Update Inventory, Warehouse Shipment with more that inventory and Select Document from Pick Selection Page.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 1);
        UpdateItemInventory(Item."No.", LocationOrange.Code, Bin.Code, Quantity);

        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, LocationOrange.Code, Item."No.", Quantity + LibraryRandom.RandDec(100, 2), WorkDate());
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        WhseShipFromSOWithNewBinCode(BinCode, SalesHeader, WarehouseShipmentNo, LocationOrange.Code);
        ReleaseWarehouseShipment(WarehouseShipmentHeader, WarehouseShipmentNo);
        LocationCode2 := LocationOrange.Code;  // Assign value to global variable for use in handler.

        // Create Pick Worksheet Template, Getsource Document and Select the Pick Line from Pick Selection Page.
        CreateWhseWorksheetName(WhseWorksheetName, LocationOrange.Code);
        GetSourceDocOutbound.GetSingleWhsePickDoc(
          WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationOrange.Code);
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationOrange.Code);
        AssignQtyToHndlOnWhseWrkSheet(WhseWorksheetLine, WhseWorksheetName, LocationOrange.Code);

        // Exercise : Create Pick From Pick Worksheet.
        asserterror LibraryWarehouse.CreatePickFromPickWorksheet(
            WhseWorksheetLine, 10000, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationOrange.Code, '',
            0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        // Verify : Check that Last error is same as expected.
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorText) > 0, ' ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeForPickFromWhseShipment()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        BinCode: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Item, Update Inventory, Warehouse Shipment.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 1);
        UpdateItemInventory(Item."No.", LocationOrange.Code, Bin.Code, Quantity);

        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", Quantity, WorkDate());
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        WhseShipFromSOWithNewBinCode(BinCode, SalesHeader, WarehouseShipmentNo, LocationOrange.Code);
        ReleaseWarehouseShipment(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Exercise.
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Verify: Check that Take and Place Bin Code is same as expected.
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LocationOrange.Code, SalesHeader."No.",
          Bin.Code);
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place, LocationOrange.Code, SalesHeader."No.",
          BinCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDefaultBin()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        BinCode: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Item, Update Inventory, Warehouse Shipment.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 1);
        UpdateItemInventory(Item."No.", LocationOrange.Code, Bin.Code, Quantity);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", Quantity, WorkDate());
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        WhseShipFromSOWithNewBinCode(BinCode, SalesHeader, WarehouseShipmentNo, LocationOrange.Code);
        ReleaseWarehouseShipment(WarehouseShipmentHeader, WarehouseShipmentNo);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Exercise : Register Pick Activity and Post Shipment.
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityHeader.Type::Pick);
        PostWarehouseShipment(WarehouseShipmentNo);

        // Verify : Posted shipment is same as sales.
        VerifyPostedShipment(SalesHeader);

        // Verify That Default Bin Code on Bin Content is First Warehouse Receipt Bin Code.
        VerifyDefaultBinContent(LocationOrange.Code, Item."No.", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentReportHandler,PickActivityMessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromProductionOrder()
    begin
        // Check That Pick Document is same as Expected without changing Unit Of Measure and Create Pick from Production Order.
        PickForProductionOrder(false);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentReportHandler,PickActivityMessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickForProductionOrder()
    begin
        // Check That Register Pick Document is same as Pick document without changing Unit Of Measure.
        PickForProductionOrder(true);
    end;

    local procedure PickForProductionOrder(RegisterPick: Boolean)
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ProductionOrder: Record "Production Order";
        Item2: Record Item;
        Item3: Record Item;
    begin
        // Setup : Create Location, Item, Purchase Order, Create and Post Warehouse Receipt, Register Putaway,
        // Create Released Production Order, Create Pick from Production Order.
        Initialize();
        CreateBOMWithComponent(ProductionBOMHeader, Item2, Item3);
        CreateItem(Item);
        ItemWithProductionBOM(Item, ProductionBOMHeader."No.");
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item2."No.");
        NewUnitOfMeasure := ItemUnitOfMeasure.Code;  // Use Global Value for Handler Function.
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationWhite.Code, Item2."No.");
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LocationWhite.Code,
          LibraryRandom.RandDec(10, 2), WorkDate());

        // Exercise for CreatePickFromProductionOrder;
        ProductionOrder.CreatePick(UserId, 0, false, false, false);  // SetBreakBulkFilter False,DoNotFillQtyToHandle False,PrintDocument False
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Take);

        if RegisterPick then begin
            // Exercise : Register Pick.
            RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityHeader.Type::Pick);

            // Verify : Verify That Register Pick Document is same as Pick document without changing Unit Of Measure.
            VerifyRegisteredWhseActivityLine(WarehouseActivityLine, Item."Base Unit of Measure", 1, WarehouseActivityLine.Quantity);  // value is Quantity Per Unit Of Measure For Base Unit Of Measure.
        end else
            VerifyWhseActivityLine(WarehouseActivityLine, Item."Base Unit of Measure", 1, WarehouseActivityLine.Quantity);  // value is Quantity Per Unit Of Measure For Base Unit Of Measure.
    end;

    [Test]
    [HandlerFunctions('ChangeUOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeUOMAndCreatePutAway()
    begin
        // Check That Put Away Document is same as Expected after run change Unit Of Measure.
        Initialize();
        PutAwayWithNewUOM(false);
    end;

    [Test]
    [HandlerFunctions('ChangeUOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeUOMAndRegisterPutAway()
    begin
        // Check That Register Put Document is same as Put Away Document after run change Unit Of Measure.
        Initialize();
        PutAwayWithNewUOM(true);
    end;

    local procedure PutAwayWithNewUOM(RegisterPutAway: Boolean)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ExpectedQuantity: Decimal;
    begin
        // Setup : Create Location, Item, Purchase Order, Create and Post Warehouse Receipt.
        CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        NewUnitOfMeasure := ItemUnitOfMeasure.Code;   // Use Global Value for Handler Function.
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationWhite.Code, Item."No.");
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place);
        ExpectedQuantity := WarehouseActivityLine.Quantity / ItemUnitOfMeasure."Qty. per Unit of Measure";

        // Exercise for ChangeUOMAndCreatePutAway;
        LibraryWarehouse.ChangeUnitOfMeasure(WarehouseActivityLine);

        if RegisterPutAway then begin
            // Exercise: Register Put Away.
            RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");

            // Verify : Verify That Register Put Document is same as Put Away Document after change Unit Of Measure.
            VerifyRegisteredWhseActivityLine(
              WarehouseActivityLine, ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Qty. per Unit of Measure", ExpectedQuantity);
        end else
            VerifyWhseActivityLine(WarehouseActivityLine, NewUnitOfMeasure, ItemUnitOfMeasure."Qty. per Unit of Measure", ExpectedQuantity);
    end;

    [Test]
    [HandlerFunctions('ChangeUOMRequestPageHandler,WhseSourceCreateDocumentReportHandler,PickActivityMessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeUOMAndCreatePickFromProductionOrder()
    begin
        // Check That Pick Document is same as Expected with changing Unit Of Measure and Create Pick from Production Order.
        Initialize();
        ChangeUOMAndPickForProdOrder(false);
    end;

    [Test]
    [HandlerFunctions('ChangeUOMRequestPageHandler,WhseSourceCreateDocumentReportHandler,PickActivityMessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeUOMAndRegisterPickForProductionOrder()
    begin
        // Check That Register Pick Document is same as Pick document with changing Unit Of Measure and Create Pick from Production Order.
        Initialize();
        ChangeUOMAndPickForProdOrder(true);
    end;

    local procedure ChangeUOMAndPickForProdOrder(RegisterPick: Boolean)
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ProductionOrder: Record "Production Order";
        Item2: Record Item;
        Item3: Record Item;
        ExpectedQuantity: Decimal;
    begin
        // Setup : Create Location, Item, Purchase Order, Create and Post Warehouse Receipt, Change Unit Of Measure and Register Putaway.
        // Create Released Production Order, Create Pick from Production Order.
        CreateBOMWithComponent(ProductionBOMHeader, Item2, Item3);
        CreateItem(Item);
        ItemWithProductionBOM(Item, ProductionBOMHeader."No.");
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item2."No.");
        NewUnitOfMeasure := ItemUnitOfMeasure.Code;   // Use Global Value for Handler Function.
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationWhite.Code, Item2."No.");
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        ChangeUOMAndRegisterWhseAct(WarehouseActivityLine, LocationWhite.Code, PurchaseHeader."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LocationWhite.Code,
          LibraryRandom.RandDec(10, 2), WorkDate());

        // Exercise For ChangeUOMAndCreatePickFromProductionOrder.
        ProductionOrder.CreatePick(UserId, 0, false, false, false);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Take);

        if RegisterPick then begin
            // Exercise : Register Pick.
            RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityHeader.Type::Pick);

            // Verify : Verify That Register Pick Document is same as Pick document with changing Unit Of Measure.
            VerifyRegisteredWhseActivityLine(
              WarehouseActivityLine, NewUnitOfMeasure, ItemUnitOfMeasure."Qty. per Unit of Measure", WarehouseActivityLine.Quantity);
        end else begin
            ExpectedQuantity := CalculateExpectedQuantity(ProductionOrder."No.", Item2."No.", ItemUnitOfMeasure."Qty. per Unit of Measure");
            VerifyWhseActivityLine(WarehouseActivityLine, NewUnitOfMeasure, ItemUnitOfMeasure."Qty. per Unit of Measure", ExpectedQuantity);
        end;
    end;

    [Test]
    [HandlerFunctions('ReceiptTransferDeletedMessageHandler')]
    [Scope('OnPrem')]
    procedure TransferAndReceiveUsingWarehouseReceipt()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Setup : Create Item, Transfer Order and Post Warehouse Receipt.
        Initialize();

        CreateItem(Item);
        UpdateItemInventory(Item."No.", LocationBlue.Code, '', LibraryRandom.RandDec(100, 2) + 100);
        CreateAndRealeaseTransferOrder(
          TransferHeader, TransferLine, Item."No.", LocationBlue.Code, LocationOrange.Code, LocationIntransit.Code);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.");

        // Exercise: Register Put Away.
        RegisterWarehouseActivity(TransferHeader."No.", WarehouseActivityHeader.Type::"Put-away");

        // Verify : Check that Transfer Receipt Line expected when Made Transfer Receipt using Full WMS Setup.
        VerifyTransferReceipt(TransferLine);

        // Check Warehouse Entry has same data as expected.
        FindWarehouseEntry(WarehouseEntry, Item."No.", LocationOrange.Code);
        VerifyWarehouseEntry(WarehouseEntry, TransferLine."Transfer-To Bin Code", -TransferLine.Quantity);
        WarehouseEntry.Next();
        // The program selectes first bin that is not shipment bin, receipt bin or posted whse receipt line (take line) bin (look into help). As result we need to check negative condition
        Assert.AreNotEqual(TransferLine."Transfer-To Bin Code", WarehouseEntry."Bin Code", StrSubstNo(BinError2,
            TransferLine."Transfer-To Bin Code", WarehouseEntry.TableCaption()));
        Assert.AreNotEqual('', WarehouseEntry."Bin Code", StrSubstNo(BinError2, '', WarehouseEntry.TableCaption()));
        WarehouseEntry.TestField(Quantity, TransferLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipTransferOrder()
    begin
        Initialize();
        TransferOrderWithShipmentAndReceipt(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiveTransferOrder()
    begin
        Initialize();
        TransferOrderWithShipmentAndReceipt(false);
    end;

    local procedure TransferOrderWithShipmentAndReceipt(Ship: Boolean)
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        BinCode2: Code[20];
        WarehouseShipmentNo: Code[20];
    begin
        // Setup : Create Item, Transfer Order, Create Warehouse Shipment from Transfer Order and Post Warehouse Shipment.
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationOrange.Code, LocationBlue.Code, LocationIntransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandDec(100, 2));
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        WhseShipFromTOWithNewBinCode(BinCode2, TransferHeader, WarehouseShipmentNo, LocationOrange.Code);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationOrange.Code, TransferHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        RegisterWarehouseActivity(TransferHeader."No.", WarehouseActivityHeader.Type::Pick);

        if Ship then begin
            PostWarehouseShipment(WarehouseShipmentNo);

            // Verify : Check that Transfer Shipment Line same data as expected when Ship Transfer Order.
            VerifyTransferShipment(TransferHeader."No.", Item."No.", TransferLine.Quantity, LocationBlue.Code, LocationOrange.Code);

            // Check Registered Pick Line with expected data.
            VerifyRegisteredWhseActivityLine(WarehouseActivityLine, Item."Base Unit of Measure", 1, TransferLine.Quantity);
        end else begin
            PostWarehouseShipment(WarehouseShipmentNo);

            // Exercise:
            TransferHeader.Get(TransferHeader."No.");
            LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

            // Verify : Check that Transfer Receipt Line same data as expected when Ship Transfer Order using Full WMS Setup.
            VerifyTransferReceipt(TransferLine);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoFillQtyToShipInWhseShipment()
    var
        LocationGreen2: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Item, Create and Release Sales Order, Create Warehouse Shipment.
        Initialize();
        LibraryWarehouse.CreateLocationWMS(LocationGreen2, false, false, false, true, true);  // BinMandatory FALSE,RequirePutAway FALSE,RequirePick FALSE,RequireReceive TRUE,RequireShipment TRUE
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2) + 100;
        UpdateItemInventory(Item."No.", LocationGreen2.Code, '', Quantity);
        CreateSalesOrder(SalesHeader, SalesLine, LocationGreen2.Code, Item."No.", Quantity, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentNo);

        // Exercise.
        WarehouseShipmentLine.AutofillQtyToHandle(WarehouseShipmentLine);

        // Verify : Check that Qty to Ship and Quantity is same as expected after run Auto Fill Qty.
        VerifyWarehouseShipmentLine(WarehouseShipmentNo, Item."No.", SalesLine.Quantity, SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToShipErrorForWhseShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Item, Create and Release Sales Order, Create Warehouse Shipment.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2) + 100;
        UpdateItemInventory(Item."No.", LocationGreen.Code, '', Quantity);
        CreateSalesOrder(SalesHeader, SalesLine, LocationGreen.Code, Item."No.", Quantity, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentNo);

        // Exercise.
        asserterror WarehouseShipmentLine.Validate("Qty. to Ship", Quantity);

        // Verify : Check that Error Message is same as expected when we directly put Quantity in Qty to Ship Field when there is Require Pick on location.
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrorQtyToHandleText, WarehouseShipmentNo)) > 0, ErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPartialPick()
    begin
        // Check That Quantity To Ship on Warehouse Shipment Line is same as Partial Pick Quantity after Register Warehouse Activity.
        Initialize();
        PratialWarehouseShipment(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPartialPickAndPostShipment()
    begin
        // Check that Quantity on Posted Warehouse Shipment is same as Qty To Handle On Pick.
        Initialize();
        PratialWarehouseShipment(false);
    end;

    local procedure PratialWarehouseShipment(RegisterOnly: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentNo: Code[20];
        Quantity: Decimal;
        QtyToHandle: Decimal;
    begin
        // Setup : Create Item, and Create and Release Sales Order, Create Warehouse Shipment, Create Pick and select partial Quantity and Register Pick.
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2) + 100;
        UpdateItemInventory(Item."No.", LocationGreen.Code, '', Quantity);
        CreateSalesOrder(SalesHeader, SalesLine, LocationGreen.Code, Item."No.", Quantity, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationGreen.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::" ");
        QtyToHandle := Quantity / 2;
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);
        if RegisterOnly then begin
            RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityHeader.Type::Pick);

            // Verify : Check That Quantity To Ship on Warehouse Shipment Line is same as Partial Pick Quantity after Register Warehouse Activity.
            VerifyWarehouseShipmentLine(WarehouseShipmentHeader."No.", Item."No.", QtyToHandle, SalesLine.Quantity);
        end else begin
            RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityHeader.Type::Pick);

            // Exercise.
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

            // Verify: Check that Quantity on Posted Warehouse Shipment is same as Qty To Handle On Pick.
            VerifyPostedWarehouseShipmentLine(LocationGreen.Code, Item."No.", WarehouseShipmentHeader."No.", SalesHeader."No.", QtyToHandle);
        end;
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayForTwoPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Item: Record Item;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Create Item, Create Two Purchase Order ,Create Warehouse Receipt and Select Created Purchase Order.
        Initialize();
        LocationCode2 := LocationOrange.Code;  // Assign value to global variable for use in handler.
        CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");
        CreateAndReleasePurchaseOrder(PurchaseHeader2, PurchaseLine2, LocationOrange.Code, Item."No.");
        CreateWarehouseReceiptHeader(WarehouseReceiptHeader, LocationOrange.Code);
        GetSourceDocumentInbound(WarehouseReceiptHeader, PurchaseHeader);
        GetSourceDocumentInbound(WarehouseReceiptHeader, PurchaseHeader2);

        // Exercise :  Post Warehouse Receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify : Check That Put Away created from Warehouse Receipt have same data as on Diffrent Purchase Order.
        VerifyActivityLine(
          LocationOrange.Code, PurchaseHeader."No.", PurchaseLine."No.", Item."Base Unit of Measure", PurchaseLine.Quantity,
          WarehouseActivityLine."Activity Type"::"Put-away");
        VerifyActivityLine(
          LocationOrange.Code, PurchaseHeader2."No.", PurchaseLine2."No.", Item."Base Unit of Measure", PurchaseLine2.Quantity,
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Exercise : Register Put Away.
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify : Check That  Registered Put Away is same as Put Away created from Warehouse Receipt have same data as on Diffrent Purchase Order.
        VerifyRegisteredActivityLine(
          WarehouseActivityLine."Activity Type"::"Put-away", LocationOrange.Code, PurchaseHeader."No.", PurchaseLine."No.",
          Item."Base Unit of Measure", PurchaseLine.Quantity);
        VerifyRegisteredActivityLine(
          WarehouseActivityLine."Activity Type"::"Put-away", LocationOrange.Code, PurchaseHeader2."No.", PurchaseLine2."No.",
          Item."Base Unit of Measure", PurchaseLine2.Quantity);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickForTwoSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup. Create Item, Update Inventory, Create Two Sales Order, Create Warehouse Shipment and Select Created Sales Order.
        Initialize();
        LocationCode2 := LocationOrange.Code;  // Assign value to global variable for use in handler.
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        CreateAndReleaseSalesOrder(SalesHeader2, SalesLine2, LocationOrange.Code, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        CreateWarehouseShipmentHeader(WarehouseShipmentHeader, LocationOrange.Code);
        GetSourceDocumentOutbound(WarehouseShipmentHeader, SalesHeader);
        GetSourceDocumentOutbound(WarehouseShipmentHeader, SalesHeader2);

        // Exercise : Create Pick from Warehouse Shipment Header.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify : Check That Pick created from Warehouse Shipment have same data as on Diffrent Sales Order.
        VerifyActivityLine(
          LocationOrange.Code, SalesHeader."No.", SalesLine."No.", Item."Base Unit of Measure", SalesLine.Quantity,
          WarehouseActivityLine."Activity Type"::Pick);
        VerifyActivityLine(
          LocationOrange.Code, SalesHeader2."No.", SalesLine2."No.", Item."Base Unit of Measure", SalesLine2.Quantity,
          WarehouseActivityLine."Activity Type"::Pick);

        // Exercise : Register Pick.
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify : Check That Registered Pick is same as Pick created from Warehouse Shipment have same data as on Diffrent Sales Order.
        VerifyRegisteredActivityLine(
          WarehouseActivityLine."Activity Type"::Pick, LocationOrange.Code, SalesHeader."No.", SalesLine."No.",
          Item."Base Unit of Measure", SalesLine.Quantity);
        VerifyRegisteredActivityLine(
          WarehouseActivityLine."Activity Type"::Pick, LocationOrange.Code, SalesHeader2."No.", SalesLine2."No.",
          Item."Base Unit of Measure", SalesLine2.Quantity);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure PostShippingAdviceComplete()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QtyToShip: Decimal;
    begin
        // Setup: Create Item, Update Inventory, Create Sales Order With Shipping Advice Complete, Create Warehouse Shipment and Select Created Sales Order Create Pick And Change Quantity On Qty To Ship Of Warehouse Shipment.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", LibraryRandom.RandDec(10, 2) + 10, WorkDate());
        SalesHeader.Validate("Shipping Advice", SalesHeader."Shipping Advice"::Complete);
        SalesHeader.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWarehouseShipmentHeader(WarehouseShipmentHeader, LocationOrange.Code);
        LocationCode2 := LocationOrange.Code;  // Assign value to global variable for use in handler.
        GetSourceDocumentOutbound(WarehouseShipmentHeader, SalesHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        QtyToShip := LibraryRandom.RandDec(10, 2);
        UpdateQuantityOnWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader."No.", QtyToShip);  // Change Quantity To Ship On Warehouse Shipment Line.

        // Exercise : Post Ware House Shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        WarehouseShipmentLine.Find();
        WarehouseShipmentLine.TestField("Qty. Shipped", 0);

        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", 0);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure PostCompleteSalesShipment()
    var
        Quantity: Decimal;
    begin
        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        PostShipment(Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure PostPartialShipment()
    var
        Quantity: Decimal;
    begin
        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        PostShipment(Quantity, Quantity / 2);
    end;

    local procedure PostShipment(Quantity: Decimal; QtyToShip: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        PostedWhseShipmentNo: Code[20];
    begin
        // Create Item, Update Inventory, Create Sales Order , Create Warehouse Shipment and Select Created Sales Order Create Pick And Change Quantity On Qty To Ship Of Warehouse Shipment.
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", Quantity, WorkDate());
        CreateWarehouseShipmentHeader(WarehouseShipmentHeader, LocationOrange.Code);
        LocationCode2 := LocationOrange.Code;  // Assign value to global variable for use in handler.
        GetSourceDocumentOutbound(WarehouseShipmentHeader, SalesHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        UpdateQuantityOnWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader."No.", QtyToShip);
        PostedWhseShipmentNo := FindPostedWhseShipmentNo();

        // Exercise : Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify : Check That Posted Warrehouse Shipment has same data as expected when Posting quantity is Partial or Complete.
        PostedWhseShipmentLine.SetRange("No.", PostedWhseShipmentNo);
        PostedWhseShipmentLine.FindFirst();
        PostedWhseShipmentLine.TestField("Item No.", SalesLine."No.");
        PostedWhseShipmentLine.TestField(Quantity, QtyToShip);

        // Verify That Quantity Shipped is update On Sales Line.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Quantity Shipped", QtyToShip);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentWithDifferentUOM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create Item, Item Unit Of Measure, Location, Update Inventory, Create Sales Order , Create Warehouse Shipment From Sales Order, Create And Register Pick , And Post Warehouse Shipment.
        Initialize();
        CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
        Quantity := LibraryRandom.RandDec(10, 2);
        UpdateInventoryUsingWhseJournal(LocationWhite, Item, Quantity);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationWhite.Code, Item."No.", Quantity, WorkDate());
        WarehouseShipmentNo := FindWarehouseShipmentNo();

        LocationCode2 := LocationWhite.Code;  // Assignvalue to global variable for use in handler.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Execise : Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify : Check That Quantity Shipped and Out standing Quantity is same as expected when use Diffrent UOM.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Unit of Measure", ItemUnitOfMeasure.Code);
        SalesLine.TestField("Quantity Shipped", Quantity);
        SalesLine.TestField("Outstanding Quantity", SalesLine.Quantity - Quantity);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PickErrorMultipleLinesWithBlankLocation()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Update Warehouse Setup, create Item, create a Sales Order on blank location, create Warehouse Shipment.
        Initialize();
        UpdateWarehouseSetup(true, true);  // Update the Warehouse Setup with Require Receive and Require Shipment True.
        CreateItem(Item);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, '', Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        CreateAndReleaseSalesOrder(SalesHeader2, SalesLine2, '', Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);

        // Assign values to global variable.
        LocationCode2 := '';
        GetSourceDocumentOutbound(WarehouseShipmentHeader, SalesHeader);
        GetSourceDocumentOutbound(WarehouseShipmentHeader, SalesHeader2);

        // Exercise : Create Pick from Warehouse Shipment Header.
        asserterror LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify that Pick is not created.
        Assert.ExpectedError(HandlingError);

        // Tear Down: Restore the original value of Warehouse Setup.
        UpdateWarehouseSetup(false, false);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PickErrorSingleLineWithBlankLocation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Update Warehouse Setup, create Item, create a Sales Order on blank location, create Warehouse Shipment.
        Initialize();
        UpdateWarehouseSetup(true, true);  // Update the Warehouse Setup with Require Receive and Require Shipment True.
        CreateItem(Item);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, '', Item."No.", LibraryRandom.RandDec(10, 2), WorkDate());
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);

        // Assign values to global variable.
        LocationCode2 := '';
        GetSourceDocumentOutbound(WarehouseShipmentHeader, SalesHeader);

        // Exercise : Create Pick from Warehouse Shipment Header.
        asserterror LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify that Pick is not created.
        Assert.ExpectedError(HandlingError);

        // Tear Down: Restore the original value of Warehouse Setup.
        UpdateWarehouseSetup(false, false);
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromPickWorksheet()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        Quantity: Decimal;
    begin
        // Setup: Create Location, create Item, Update Inventory, Warehouse Shipment and select Document from Pick Selection page.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateItemInventory(Item."No.", LocationGreen.Code, '', Quantity);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationGreen.Code, Item."No.", Quantity, WorkDate());
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        ReleaseWarehouseShipment(WarehouseShipmentHeader, WarehouseShipmentNo);

        LocationCode2 := LocationGreen.Code;  // Assign value to global variable for use in handler.
        // Create Pick Worksheet Template, get source Document and select the Pick Line from Pick Selection page, create Pick from Pick Worksheet.
        CreateWhseWorksheetName(WhseWorksheetName, LocationGreen.Code);
        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationGreen.Code);
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationGreen.Code);
        AssignQtyToHndlOnWhseWrkSheet(WhseWorksheetLine, WhseWorksheetName, LocationGreen.Code);
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, 10000, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationGreen.Code, '',
          0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityHeader.Type::Pick);

        // Exercise: Post Whse Shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // Verify: Verify the values on Posted Warehouse Shipment Line.
        VerifyPostedWarehouseShipmentLine(LocationGreen.Code, Item."No.", WarehouseShipmentHeader."No.", SalesHeader."No.", Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure AvailablePickOnWarehouseWorksheet()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        Quantity: Decimal;
    begin
        // Setup: Create Location, create Item, update Inventory, create a sales Order, create Warehouse Shipment.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateItemInventory(Item."No.", LocationGreen.Code, '', Quantity);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationGreen.Code, Item."No.", Quantity, WorkDate());

        // Assign value to global variable. Create Pick Worksheet Template, get source Document and select the Pick Line from Pick Selection page.
        LocationCode2 := LocationGreen.Code;
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        ReleaseWarehouseShipment(WarehouseShipmentHeader, WarehouseShipmentNo);
        CreateWhseWorksheetName(WhseWorksheetName, LocationGreen.Code);
        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationGreen.Code);
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationGreen.Code);

        // Exercise: Assign Quantity to handle on Whse. WorkSheet.
        AssignQtyToHndlOnWhseWrkSheet(WhseWorksheetLine, WhseWorksheetName, LocationGreen.Code);

        // Verify: Verify the Correct Quantity Outstanding.
        WhseWorksheetLine.TestField("Qty. Outstanding", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickAcrossMultipleBins()
    var
        Item: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Decimal;
    begin
        // Setup: Find Bin, create Item, update Item Inventory, create purchase order, create Warehouse Receipt, update Bin Code on Warehouse receipt.
        // Post Warehouse Receipt, update Quantity To Handle on Activity Line, create Sales Order and release it, create Pick.
        Initialize();
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 1);  // Find bin of Index 1.
        CreateItem(Item);
        UpdateItemInventory(Item."No.", LocationOrange.Code, Bin.Code, LibraryRandom.RandDec(100, 2));
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        FindWarehouseReceiptLine(
          WarehouseReceiptLine, FindWarehouseReceiptNo(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No."));
        LibraryWarehouse.FindBin(Bin2, LocationOrange.Code, '', 2);  // Find bin of Index 2.
        WarehouseReceiptLine.Validate("Bin Code", Bin.Code);
        WarehouseReceiptLine.Modify(true);
        Quantity := PurchaseLine.Quantity;
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        UpdateQuantityToHandleAndBinOnActivityLine(WarehouseActivityLine."Action Type"::Take, PurchaseHeader."No.", Quantity / 2);
        UpdateQuantityToHandleAndBinOnActivityLine(WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Quantity / 2);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationOrange.Code, Item."No.", Quantity, WorkDate());

        LocationCode2 := LocationOrange.Code;  // Assign value to global variable for use in handler.
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        ReleaseWarehouseShipment(WarehouseShipmentHeader, WarehouseShipmentNo);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationOrange.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take);

        // Exercise: Register Pick.
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify: Verify the Quantity on registered Pick.
        VerifyRegisteredWhseActivityLine(WarehouseActivityLine, Item."Base Unit of Measure", 1, Quantity / 2);  // Verify the registered Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseReceiptFromPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // Setup: Create a Purchase Order and create Warehouse Receipt from Purchase Order for Red Location.
        Initialize();
        CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationRed.Code, Item."No.");
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Exercise: Post Warehouse Receipt.
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Verify: Verify the values on Item Ledger Entry.
        FindPurchaseReceipt(PurchRcptHeader, PurchaseHeader."No.");
        VerifyItemLedgerEntry(PurchRcptHeader."No.", Item."No.", LocationRed.Code, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinePageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithInvoiceNoAsReceiptNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create a Purchase Order, create and post Warehouse Receipt, Create Purchase Invoice having same Invoice No. as Receipt No.
        Initialize();
        UpdatePurchaseInvoiceNoSeries(true);  // Make No. Series Manual for Purchase Invoice to allow Receipt No. as Invoice No.
        CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationRed.Code, Item."No.");
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        FindPurchaseReceiptLine(PurchRcptLine, PurchaseHeader."No.");
        CreatePurchaseInvoiceWithReceiptNo(PurchaseHeader2, PurchaseHeader, PurchRcptLine."Document No.");

        // Create Purchase Line For Item Charge, Create Item Charge Assignment, post Puchase Invoice.
        CreatePurchaseLineAndAssignItemCharge(PurchaseHeader2, PurchaseLine2, PurchRcptLine);
        LibraryPurchase.GetPurchaseReceiptLine(PurchaseLine2);  // Get Receipt Line for Item Charge Assignment(Purch).

        // Exercise: Post Puchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify posted Purchase Invoice.
        VerifyPostedPurchaseInvoice(DocumentNo, PurchaseLine2.Type::Item, PurchRcptLine.Quantity);
        VerifyPostedPurchaseInvoice(DocumentNo, PurchaseLine2.Type::"Charge (Item)", PurchaseLine2.Quantity);

        // Teardown: Reset Manual No. False for Purchase Invoice.
        UpdatePurchaseInvoiceNoSeries(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShipmentFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesShipmentHeader: Record "Sales Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create and release Sales Order and create Warehouse Shipment from SO for Location Red.
        Initialize();
        CreateItem(Item);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationRed.Code, Item."No.", LibraryRandom.RandDec(100, 2), WorkDate());
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(FindWhseShipmentNo(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No."));

        // Exercise: Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify values in Item Ledger Entry.
        FindSalesShipment(SalesShipmentHeader, SalesHeader."No.");
        VerifyItemLedgerEntry(SalesShipmentHeader."No.", Item."No.", LocationRed.Code, -SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinePageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithInvoiceNoAsShipmentNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create and release Sales Order, create and post Warehouse Shipment, create Sales Invoice having same Invoice No. as ShipmentNo.
        Initialize();
        UpdateSalesInvoiceNoSeries(true);  // Make No. Series Manual for Sales Invoice to allow Shipment No. as Invoice No.
        CreateItem(Item);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationRed.Code, Item."No.", LibraryRandom.RandDec(100, 2), WorkDate());
        CreateAndPostWhseShipmentFromSO(SalesHeader);
        FindSalesShipmentLine(SalesShipmentLine, SalesHeader."No.");
        CreateSalesInvoiceWithShipmentNo(SalesHeader2, SalesHeader, SalesShipmentLine."Document No.");

        // Create SalesLine for Item Charge, create Item Charge Assignment.
        CreateSalesLineAndAssignItemCharge(SalesHeader2, SalesLine2, SalesShipmentLine);
        LibrarySales.GetShipmentLines(SalesLine2);  // Get Shipment Line for Item Charge Assignment.

        // Exercise: Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Verify: Verify posted Sales Invoice.
        VerifyPostedSalesInvoice(DocumentNo, SalesLine2.Type::Item, SalesShipmentLine.Quantity);
        VerifyPostedSalesInvoice(DocumentNo, SalesLine2.Type::"Charge (Item)", SalesLine2.Quantity);

        // Teardown: Reset Manual No. False for Sales Invoice.
        UpdateSalesInvoiceNoSeries(false);
    end;

    [Test]
    [HandlerFunctions('WhseShipmentCreatePick,PickActivityMessageHandler')]
    [Scope('OnPrem')]
    procedure WhseBatchPickFromWhseShipment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentRelease: Codeunit "Whse.-Shipment Release";
        Quantity: Decimal;
    begin
        // Setup: Create and release Purchase Order, create Warehouse Receipt, register Put away and create Warehouse Shipment from Sales Order for White Location.
        Initialize();
        CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationWhite.Code, Item."No.");
        Quantity := PurchaseLine.Quantity;
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationWhite.Code, Item."No.", Quantity, WorkDate());
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(WarehouseShipmentNo);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader."No.");
        WhseShipmentRelease.Release(WarehouseShipmentHeader);

        // Exercise: Create Pick from Warehouse Shipment.
        WarehouseShipmentLine.CreatePickDoc(WarehouseShipmentLine, WarehouseShipmentHeader);

        // Verify: Verify Pick has been created on Warehouse Activity Line.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        VerifyWhseActivityLine(WarehouseActivityLine, Item."Base Unit of Measure", 1, WarehouseActivityLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentReportHandler,PickActivityMessageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWhseInternalPick()
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseInternalPickRelease: Codeunit "Whse. Internal Pick Release";
    begin
        // Setup: Create Item, find Zone, find Bin, update Inventory, create Warehouse Internal Pick and Release.
        Initialize();
        CreateItem(Item);
        FindZone(Zone, LocationWhite.Code);
        UpdateInventoryOnLocationWithWhseAdjustment(LocationWhite, Item, 100 + LibraryRandom.RandDec(100, 2));  // For large Quantity.
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 2);  // Find Bin for Zone with Bin Index 2.
        CreateWhseInternalPickHeader(WhseInternalPickHeader, Zone.Code, Bin.Code);
        LibraryWarehouse.CreateWhseInternalPickLine(
          WhseInternalPickHeader, WhseInternalPickLine, Item."No.", LibraryRandom.RandDec(100, 2));
        WhseInternalPickRelease.Release(WhseInternalPickHeader);

        // Exercise: Create Pick from Warehouse Internal Pick.
        WhseInternalPickLine.CreatePickDoc(WhseInternalPickLine, WhseInternalPickHeader);

        // Verify: Verify Pick has been created on Whse Activity Line.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, WhseInternalPickHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        VerifyWhseActivityLine(WarehouseActivityLine, Item."Base Unit of Measure", 1, WarehouseActivityLine.Quantity);  // value is Quantity Per Unit Of Measure For Base Unit Of Measure.
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentReportHandler,PutAwayActivityMessageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayFromWhseInternalPutAway()
    var
        Item: Record Item;
        Bin: Record Bin;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseIntPutAwayRelease: Codeunit "Whse. Int. Put-away Release";
        Quantity: Decimal;
    begin
        // Setup: Create Item, find Zone, find Bin, update Inventory, create Warehouse Internal Put Away and release.
        Initialize();
        CreateItem(Item);
        UpdateInventoryOnLocationWithWhseAdjustment(LocationWhite, Item, 100 + LibraryRandom.RandDec(100, 2));  // For large Quantity.
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        CreateWhseInternalPutawayHeader(WhseInternalPutAwayHeader, Bin."Zone Code", Bin.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryWarehouse.CreateWhseInternalPutawayLine(WhseInternalPutAwayHeader, WhseInternalPutAwayLine, Item."No.", Quantity);
        WhseIntPutAwayRelease.Release(WhseInternalPutAwayHeader);

        // Exercise: Create Put Away from Warehouse Internal Put Away.
        WhseInternalPutAwayLine.CreatePutAwayDoc(WhseInternalPutAwayLine);

        // Verify: Verify the values on Warehouse Activity Line.
        WarehouseActivityLine.SetRange("Location Code", LocationWhite.Code);
        WarehouseActivityLine.FindFirst();
        VerifyWhseActivityLine(WarehouseActivityLine, Item."Base Unit of Measure", 1, WarehouseActivityLine.Quantity);  // Value 1 is Quantity Per Unit Of Measure.
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler')]
    [Scope('OnPrem')]
    procedure WhseBatchPickFromProductionOrder()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProductionOrder: Record "Production Order";
        Item2: Record Item;
        Item3: Record Item;
    begin
        // Setup: Cretae BOM, create Item, Item with Production BOM, create and release Purchase Order, post Whse Receipt, register Put away.
        // Create and refresh Production Order.
        Initialize();
        CreateBOMWithComponent(ProductionBOMHeader, Item2, Item3);
        CreateItem(Item);
        ItemWithProductionBOM(Item, ProductionBOMHeader."No.");
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationWhite.Code, Item2."No.");
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LocationWhite.Code,
          LibraryRandom.RandDec(10, 2), WorkDate());

        // Exercise: Create Pick from Production Order.
        ProductionOrder.CreatePick(UserId, 0, false, false, false);  // SetBreakBulkFilter False, DoNotFillQtyToHandle False, PrintDocument False.

        // Verify: Verify the values on Whse Activity Line.
        VerifyWhseActivityLine(WarehouseActivityLine, Item."Base Unit of Measure", 1, WarehouseActivityLine.Quantity);  // value is Quantity Per Unit Of Measure For Base Unit Of Measure.
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler')]
    [Scope('OnPrem')]
    procedure WhseBatchPutAwayFromPostedWhseReceiptLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Item: Record Item;
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        Quantity: Decimal;
    begin
        // Setup : Create Item, create and release Purchase Order and Create and post Warehouse Receipt.
        Initialize();
        CreateItemAddInventory(Item, LocationOrange.Code, 1);  // Value required for Bin Index.
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");
        Quantity := PurchaseLine.Quantity;
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        FindPostedWhseReceiptLines(PostedWhseReceiptLine, PurchaseHeader."No.");

        // Exercise: Create Put away.
        Commit();
        PostedWhseReceiptLine.CreatePutAwayDoc(PostedWhseReceiptLine, UserId);

        // Verify: Verify the values on Posted Whse Receipt Line.
        VerifyPostedWhseReceiptLine(PurchaseHeader."No.", Item."No.", Quantity, LocationOrange.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyRndingPrecisionIsCopiedToPostedWhseReceiptLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Item: Record Item;
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        Quantity: Decimal;
        QtyRndingPrecision: Decimal;
    begin
        Initialize();

        // Setup : Create Item, create and release Purchase Order and Create Warehouse Receipt.
        QtyRndingPrecision := 0.01; // Hardcoding the value is fine as the test veriifes that the value travels all the way to posted lines
        CreateItemWithRndingPrecAddInventory(Item, QtyRndingPrecision, LocationOrange.Code, 1);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, Item."No.");
        Quantity := PurchaseLine.Quantity;
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Exercise: Warehouse receipt is posted
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        FindPostedWhseReceiptLines(PostedWhseReceiptLine, PurchaseHeader."No.");

        // Verify: The 'Qty. Rounding Precision' travels all the way through to Posted Warehouse Receipt Line.
        PostedWhseReceiptLine.TestField("Qty. Rounding Precision", QtyRndingPrecision);
        PostedWhseReceiptLine.TestField("Qty. Rounding Precision (Base)", QtyRndingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetMaxQtyRemainingWhenRndingExceedsTotalQtyOnPostedWhseReceiptLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        Bin: Record Bin;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
    begin
        Initialize();

        // Bug 401892 Oustanding quaity and remaining quatity rounds to exceed total quanity
        // [GIVEN] An item with 2 unit of measures and qty. rounding precision as default and non base item unit of measure set to maximum decimals.
        NonBaseQtyPerUOM := 5.55555;
        BaseQtyPerUOM := 1;
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 1);
        UpdateItemInventory(Item."No.", LocationOrange.Code, Bin.Code, LibraryRandom.RandInt(100));

        // [GIVEN] Create and release Purchase Order and Create Warehouse Receipt.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Location Code", LocationOrange.Code);
        PurchaseLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WarehouseReceiptHeader.Get(FindWarehouseReceiptNo(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No."));

        // [GIVEN] Partial Qty. to Received
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        if WarehouseReceiptLine.FindFirst() then begin
            WarehouseReceiptLine.Validate("Qty. to Receive", 0.3);
            WarehouseReceiptLine.Modify(true);
        end;

        // [WHEN]: Warehouse receipt is posted
        WhsePostReceipt.Run(WarehouseReceiptLine);

        // [THEN]: The "Qty. yo Receive (Base)" and "Qty. Outstanding (Base)" values are set to the maximum quantites remaining rather then the rounded values which exceeds total quanity
        WarehouseReceiptLine.TestField("Qty. to Receive (Base)", NonBaseQtyPerUOM - WarehouseReceiptLine."Qty. Received (Base)");
        WarehouseReceiptLine.TestField("Qty. Outstanding (Base)", NonBaseQtyPerUOM - WarehouseReceiptLine."Qty. Received (Base)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetMaxQtyRemainingWhenRndingExceedsTotalQtyOnPostedWhseReceiptLineToShip()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        Bin: Record Bin;
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
    begin
        Initialize();

        // Bug 404726 Oustanding quaity and remaining quatity rounds to exceed total quanity
        // [GIVEN] An item with 2 unit of measures and qty. rounding precision as default and non base item unit of measure set to maximum decimals.
        NonBaseQtyPerUOM := 5.55555;
        BaseQtyPerUOM := 1;
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        LibraryWarehouse.FindBin(Bin, LocationOrange3.Code, '', 1);
        UpdateItemInventory(Item."No.", LocationOrange3.Code, Bin.Code, LibraryRandom.RandInt(100));

        // [GIVEN] Create and release Sales Order and Create Warehouse Receipt.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Location Code", LocationOrange3.Code);
        SalesLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WarehouseShipmentLine.SetRange("Source Document", "Warehouse Activity Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.FindFirst();

        // [GIVEN] Partial Qty. to Ship
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentLine."No.");
        if WarehouseShipmentLine.FindFirst() then begin
            WarehouseShipmentLine.Validate("Qty. to Ship", 0.3);
            WarehouseShipmentLine.Modify(true);
        end;

        // [WHEN]: Warehouse receipt is posted
        WhsePostShipment.Run(WarehouseShipmentLine);

        // [THEN]: The "Qty. to Ship (Base)" and "Qty. Outstanding (Base)" values are set to the maximum quantites remaining rather then the rounded values which exceeds total quanity
        WarehouseShipmentLine.TestField("Qty. to Ship (Base)", NonBaseQtyPerUOM - WarehouseShipmentLine."Qty. Shipped (Base)");
        WarehouseShipmentLine.TestField("Qty. Outstanding (Base)", NonBaseQtyPerUOM - WarehouseShipmentLine."Qty. Shipped (Base)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPartialWarehouseReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Bin: Record Bin;
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
        PartialQty: Integer;
    begin
        Initialize();

        PartialQty := 4;

        // Bug 419578 Attempt to undo partial Warehouse Receipt of Purchase Order results in error, "This will cause the quantity and base quantity fields to be out of balance."
        // [GIVEN] An item with 1 unit of measures and qty. rounding precision as default
        CreateItemWithRepl(Item, Item."Replenishment System"::Purchase);
        LibraryWarehouse.FindBin(Bin, LocationPink.Code, '', 1);
        UpdateItemInventory(Item."No.", LocationPink.Code, Bin.Code, LibraryRandom.RandIntInRange(20, 100));

        // [GIVEN] Create and release Purchase Order and Create Warehouse Receipt.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseLine."Document Type"::Order, CreateVendor(), Item."No.",
          10);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [WHEN]: Warehouse receipt is posted
        WarehouseReceiptLine.SetRange("Source Document", "Warehouse Activity Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        if WarehouseReceiptLine.FindFirst() then begin
            WarehouseReceiptLine.Validate("Qty. to Receive", PartialQty);
            WarehouseReceiptLine.Modify(true);
        end;

        WhsePostReceipt.Run(WarehouseReceiptLine);

        //[Then] Undo Purchase Receipt Line
        UndoPurchaseReceiptLines(PurchaseLine);

        //[Then] Verify Quantity after Undo Receipt on Posted Purchase Receipt And Quantity Received is blank on Purchase Line.
        VerifyUndoReceiptLineOnPostedReceipt(PurchaseLine."Document No.", PartialQty);
        VerifyQuantityReceivedOnPurchaseLine(PurchaseHeader."Document Type", PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure WhseBatchPickFromPickWorksheet()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        Quantity: Decimal;
    begin
        // Setup: Create Item, Update Inventory, create and release Sales Order, Create warehouse Shipment and select Document from Pick Selection page.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateItemInventory(Item."No.", LocationGreen.Code, '', Quantity);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, LocationGreen.Code, Item."No.", Quantity, WorkDate());
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        ReleaseWarehouseShipment(WarehouseShipmentHeader, WarehouseShipmentNo);

        LocationCode2 := LocationGreen.Code;  // Assign value to global variable for use in handler.
        // Create Pick Worksheet Template, get source Document and select the Pick Line from Pick Selection page.
        CreateWhseWorksheetName(WhseWorksheetName, LocationGreen.Code);
        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationGreen.Code);
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationGreen.Code);

        // Exercise: Create Pick from Pick Worksheet.
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, 10000, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationGreen.Code, '',
          0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityHeader.Type::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // Verify: Verify the values on Posted Warehouse Shipment Line.
        VerifyPostedWarehouseShipmentLine(LocationGreen.Code, Item."No.", WarehouseShipmentHeader."No.", SalesHeader."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWhseInternalPickWithNonWarehouse()
    var
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
    begin
        // Test and verify an error message pops up when create Internal Pick with Non-warehouse.

        // Setup & Exercise: Create Whse. Internal Pick with Non-Warehouse.
        // Verify: Verify the error message.
        Initialize();
        asserterror LibraryWarehouse.CreateWhseInternalPickHeader(WhseInternalPickHeader, LocationOrange.Code);
        Assert.ExpectedError(NonWarehouseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWhseInternalPutawayWithNonWarehouse()
    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
    begin
        // Test and verify an error message pops up when create Internal Put-away with Non-warehouse.

        // Setup & Exercise: Create Whse. Internal Putaway with Non-Warehouse.
        // Verify: Verify the error message.
        Initialize();
        asserterror LibraryWarehouse.CreateWhseInternalPutawayHdr(WhseInternalPutAwayHeader, LocationOrange.Code);
        Assert.ExpectedError(NonWarehouseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinContentGetCaptionWithFilterOnBinCode()
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        LocationCode: Code[10];
        FirstCode: Code[20];
        SecondCode: Code[20];
    begin
        // Test and Verify caption build on set filter

        // Setup
        Initialize();
        FillBinContent(LocationCode, false);

        // Exercise
        FindBinCodesInBinContent(FirstCode, SecondCode, LocationCode);

        // Verify
        VerifyBinContentGetCaptionWithFilter(
          '', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Bin Code"), Bin.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '@%1*', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Bin Code"), Bin.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '%1..%2', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Bin Code"), Bin.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '..%2', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Bin Code"), Bin.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '%1|%2', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Bin Code"), Bin.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinContentGetCaptionWithFilterOnItemNo()
    var
        BinContent: Record "Bin Content";
        Item: Record Item;
        LocationCode: Code[10];
        FirstCode: Code[20];
        SecondCode: Code[20];
    begin
        // Test and Verify caption build on set filter

        // Setup
        Initialize();
        FillBinContent(LocationCode, false);

        // Exercise
        FindItemCodesInBinContent(FirstCode, SecondCode, LocationCode);

        // Verify
        VerifyBinContentGetCaptionWithFilter(
          '', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Item No."), Item.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '@%1*', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Item No."), Item.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '%1..%2', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Item No."), Item.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '..%1', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Item No."), Item.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '%1|%2', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Item No."), Item.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinContentGetCaptionWithFilterOnVariantCode()
    var
        BinContent: Record "Bin Content";
        ItemVariant: Record "Item Variant";
        LocationCode: Code[10];
        FirstCode: Code[20];
        SecondCode: Code[20];
    begin
        // Test and Verify caption build on set filter

        // Setup
        Initialize();
        FillBinContent(LocationCode, true);

        // Exercise
        FindItemVariantCodesInBinContent(FirstCode, SecondCode, LocationCode);

        // Verify
        VerifyBinContentGetCaptionWithFilter(
          '', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Variant Code"), ItemVariant.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '@%1*', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Variant Code"), ItemVariant.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '%1..%2', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Variant Code"), ItemVariant.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '..%1', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Variant Code"), ItemVariant.TableCaption());
        VerifyBinContentGetCaptionWithFilter(
          '%1|%2', LocationCode, FirstCode, SecondCode, BinContent.FieldNo("Variant Code"), ItemVariant.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePutawayToFloatingBinWithFixedBinExist()
    begin
        // Check Item can be put away into floating Bin with Fixed Bin existing.
        Initialize();
        CreatePutawayToFloatingBin(true, false, false); // TRUE for Fixed Bin
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePutawayToFloatingBinWithDefaultBinExist()
    begin
        // Check Item can be put away into floating Bin with Default Bin existing.
        Initialize();
        CreatePutawayToFloatingBin(false, true, false); // TRUE for Default Bin
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePutawayToFloatingBinWithDedicatedBinExist()
    begin
        // Check Item can be put away into floating Bin with Dedicated Bin existing.
        Initialize();
        CreatePutawayToFloatingBin(false, false, true); // TRUE for Dedicated Bin
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockBinPrioritizedOverDefaultBinInWhsePick()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [FEATURE] [Pick] [Bin] [Cross-Dock]
        // [SCENARIO 220838] When creating a warehouse pick on a cross-dock location, cross-dock bins should be suggested before default bins

        Initialize();

        // [GIVEN] Location with cross-dock
        CreateLocationWithCrossDockingSetup(Location);

        // [GIVEN] Item "I" with inventory on the cross-dock location. Stock is stored in the default location "DB"
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        UpdateItemInventory(Item."No.", Location.Code, Bin.Code, LibraryRandom.RandInt(100));

        // [GIVEN] Create purchase order for item "I", create warehouse receipt from the purchase
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, Item."No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateWhseReceiptFromPurchOrder(WarehouseReceiptHeader, PurchaseHeader);

        // [GIVEN] Create sales order for item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", PurchaseLine.Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Calculate cross-dock
        CalculateCrossDockLines(WarehouseReceiptHeader."No.", Location.Code);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [GIVEN] Register put-away from the purchase. Put-away is registered on the cross-dock bin "CB".
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Create warehouse shipment from the sales order
        CreateWhseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Create warehouse pick from the shipment
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [THEN] Item is picked from the cross-dock bin "CB"
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, Location.Code,
          SalesHeader."No.", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField("Bin Code", Location."Cross-Dock Bin Code");
    end;

    [Test]
    procedure RegisterPutawayIfWarehouseClassCheckIsDisabledInLocation()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Bin1: Record Bin;
        Bin2: Record Bin;
        WarehouseEmployeeSetup: Record "Warehouse Employee";
        WarehouseClass: Record "Warehouse Class";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityHdr: record "Registered Whse. Activity Hdr.";
    begin
        // [SCENARIO 476957] Issue generated with Warehouse Class Code being validated even when the Location Code is setup with Boolean for Check Warehouse Class disabled when processing a Warehouse Put-away
        Initialize();

        // [GIVEN] Create a Warehouse Location.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);

        // [GIVEN] Create Bin 1 & Validate Receipt Bin Code.
        LibraryWarehouse.CreateBin(Bin1, Location.Code, Format(LibraryRandom.RandText(3)), '', '');
        Location.Validate("Receipt Bin Code", Bin1.Code);

        // [GIVEN] Create Bin 2.
        LibraryWarehouse.CreateBin(Bin2, Location.Code, Format(LibraryRandom.RandText(3)), '', '');

        // [GIVEN] Disable Check Whse. Class in Warehouse Location.
        Location.Validate("Check Whse. Class", false);
        Location.Modify(true);

        // [GIVEN] Create a Warehouse Employee for Warehouse Location.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployeeSetup, Location.Code, true);

        // [GIVEN] Create a Warehouse Class.
        LibraryWarehouse.CreateWarehouseClass(WarehouseClass);

        // [GIVEN] Create an Item & Validate Warehouse Class Code.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Warehouse Class Code", WarehouseClass.Code);
        Item.Modify(true);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, Vendor."No.");

        // [GIVEN] Create a Purchase Line & Validate Location Code.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::Item, Item."No.", LibraryRandom.RandInt(20));
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create & Post Warehouse Receipt.
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Find Warehouse Put-away Lines.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseActivityLine.FindFirst();

        // [GIVEN] Find Warehouse Put-away Header.
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Put-away");
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Register Warehouse Put-away.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Find Registered Warehouse Put-away.
        RegisteredWhseActivityHdr.SetRange("Whse. Activity No.", WarehouseActivityHeader."No.");
        RegisteredWhseActivityHdr.FindFirst();

        // [VERIFY] Verify Location Code in Registered Warehouse Put-away.
        Assert.AreEqual(WarehouseActivityHeader."Location Code", RegisteredWhseActivityHdr."Location Code", LocationCodeMustMatchErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyConfirmationDialogOpenPostedPurchaseInvoiceWhenPurchaseInvoiceCreatedWithReceiptNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseHeader2: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [SCENARIO 487977] Confirmation dialogue in Purchase Invoices after Posting is missing
        Initialize();

        // [GIVEN] Setup: Create a Purchase Order, create and post Warehouse Receipt
        CreateItem(Item);
        UpdatePurchaseInvoiceNoSeries(true);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationRed.Code, Item."No.");

        // [GIVEN] Create adn post Warehouse Receipt
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        FindPurchaseReceiptLine(PurchRcptLine, PurchaseHeader."No.");

        // [THEN] Create Purchase Invoice with Receipt No.
        CreatePurchaseInvoiceWithReceiptNo(PurchaseHeader2, PurchaseHeader, PurchRcptLine."Document No.");

        // [THEN] Open Purchase Invoice Page and Post the Invoice
        PostedPurchaseInvoice.Trap();
        PurchaseInvoice.OpenView();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader2."No.");
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        LibrarySales.EnableConfirmOnPostingDoc();
        PurchaseInvoice.Post.Invoke();

        // [VERIFY] Verify: The posted document opened in the Posted Purchase Invoice page
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyConfirmationDialogOpenPostedPurchInvWhenPurchInvCreatedWithReceiptNoAndPostedFromPurchaseInvoicesList()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseHeader2: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseInvoices: TestPage "Purchase Invoices";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [SCENARIO 487977] Confirmation dialogue in Purchase Invoices after Posting is missing
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Setup: Create a Purchase Order, create and post Warehouse Receipt
        CreateItem(Item);
        UpdatePurchaseInvoiceNoSeries(true);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationRed.Code, Item."No.");

        // [GIVEN] Create adn post Warehouse Receipt
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        FindPurchaseReceiptLine(PurchRcptLine, PurchaseHeader."No.");

        // [THEN] Create Purchase Invoice with Receipt No.
        CreatePurchaseInvoiceWithReceiptNo(PurchaseHeader2, PurchaseHeader, PurchRcptLine."Document No.");

        // [THEN] Open Purchase Invoices List Page and Post the Invoice
        PostedPurchaseInvoice.Trap();
        PurchaseInvoices.OpenView();
        PurchaseInvoices.Filter.SetFilter("No.", PurchaseHeader2."No.");
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        LibrarySales.EnableConfirmOnPostingDoc();
        PurchaseInvoices.PostSelected.Invoke(); //.Post.Invoke();

        // [VERIFY] Verify: The posted document opened in the Posted Purchase Invoice page
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyConfirmationDialogToOpenPostedPurchaseInvoiceWhenPurchaseInvoiceCreatedWithReceiptNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseHeader2: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [SCENARIO 501930] Confirmation dialogue open Posted Purchase Invoice when Purchase Invoices with Get Receipt Lines
        Initialize();

        // [GIVEN] Create Item
        CreateItem(Item);

        // [GIVEN] Update Purchase "Purchases & Payables Setup" with same "Invoice Nos." and "Posted Invoice Nos." series
        UpdatePurchaseSetupWithSamePreAndPostedNoSeries();

        // [GIVEN] Create Purchase Order
        //CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationRed.Code, Item."No.");
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] Create adn post Warehouse Receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Find Purchase Receipt Line
        FindPurchaseReceiptLine(PurchRcptLine, PurchaseHeader."No.");

        // [THEN] Create Purchase Invoice with Receipt No.
        CreatePurchaseInvoiceWithReceipt(PurchaseHeader2, PurchaseHeader);

        // [THEN] Open Purchase Invoice Page and Post the Invoice
        PostedPurchaseInvoice.Trap();
        PurchaseInvoice.OpenView();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader2."No.");

        // [THEN]  Disable warnings
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        LibrarySales.EnableConfirmOnPostingDoc();

        // [THEN] Post the Purchase Invoice
        PurchaseInvoice.Post.Invoke();

        // [VERIFY] The posted document opened in the Posted Purchase Invoice page
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    procedure PurchaseOrderLineDeleteNotAllowedWhenWarehouseReceiptExists()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 571552] Delete of Purchase Order line is not allowed while a Warehouse Receipt exists.
        Initialize();

        // [GIVEN] Create Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create a Warehouse Location.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Purchase Order.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, Item."No.");

        // [GIVEN] Release Purchase Document.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create a Warehouse Receipt of Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Reopen Purchase Order.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [WHEN] Validate Purchase Line to 0.
        asserterror PurchaseLine.Validate(Quantity, 0);

        // [THEN] Quantity should not be allowed to be 0 when Warehouse Recipt exits.
        Assert.ExpectedError(
            StrSubstNo(
                QuantityErr,
                PurchaseLine."Document Type",
                PurchaseLine."Document No.",
                PurchaseLine."Line No."));
    end;

    local procedure Initialize()
    var
        WarehouseSetup: Record "Warehouse Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse II");
        LibraryVariableStorage.Clear();
        Clear(WarehouseShipmentNo);
        Clear(LocationCode2);
        Clear(NewUnitOfMeasure);
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse II");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        NoSeriesSetup();
        CreateLocationSetup();
        ItemJournalSetup();
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
        WarehouseSetup.Validate("Shipment Posting Policy", WarehouseSetup."Shipment Posting Policy"::"Posting errors are not processed");
        WarehouseSetup.Modify();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse II");
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
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateLocationSetup()
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateLocationWMS(LocationGreen, false, true, true, true, true);  // Location: Green.
        LibraryWarehouse.CreateLocationWMS(LocationBlue, false, false, false, false, false);  // Location: Blue.
        LibraryWarehouse.CreateLocationWMS(LocationOrange, true, true, true, true, true);  // Location: Orange.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationOrange.Code, false);
        LibraryWarehouse.CreateLocationWMS(LocationOrange2, true, true, true, true, true);  // Location: Orange2.
        LibraryWarehouse.CreateLocationWMS(LocationOrange3, true, true, false, true, true);  // Location: Orange.
        LibraryWarehouse.CreateLocationWMS(LocationRed, false, false, false, true, true);  // Location: Red.
        LibraryWarehouse.CreateLocationWMS(LocationPink, true, false, true, true, true);  // Location: Orange.
        LibraryWarehouse.CreateInTransitLocation(LocationIntransit);

        LibraryWarehouse.CreateNumberOfBins(LocationOrange.Code, '', '', LibraryRandom.RandInt(5) + 2, false);  // 2 is required as minimun number of Bin must be 2.
        LibraryWarehouse.CreateNumberOfBins(LocationOrange2.Code, '', '', LibraryRandom.RandInt(5) + 1, false);
        LibraryWarehouse.CreateNumberOfBins(LocationOrange3.Code, '', '', LibraryRandom.RandInt(5), false);
        LibraryWarehouse.CreateNumberOfBins(LocationPink.Code, '', '', LibraryRandom.RandInt(5), false);

        LocationCode2 := LocationOrange.Code;  // Assign value to global variable for use in handler.
    end;

    [Normal]
    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure AssignQtyToHndlOnWhseWrkSheet(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    begin
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode);
        WhseWorksheetLine."Qty. to Handle" := WhseWorksheetLine.Quantity / 2;  // Assigning directly to recreate original behavior.
        WhseWorksheetLine."Qty. to Handle (Base)" := WhseWorksheetLine.Quantity / 2;
        WhseWorksheetLine.Modify(true);
    end;

    local procedure CalculateCrossDockLines(WarehouseReceiptNo: Code[20]; LocationCode: Code[10])
    var
        WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity";
        WhseCrossDockMgt: Codeunit "Whse. Cross-Dock Management";
    begin
        WhseCrossDockMgt.CalculateCrossDockLines(WhseCrossDockOpp, '', WarehouseReceiptNo, LocationCode);
    end;

    local procedure CreateBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; ItemNo2: Code[20]; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // Choose any unit of measure.
        UnitOfMeasure.FindFirst();
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure.Code);

        // Create component lines in the BOM.
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QuantityPer);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo2, QuantityPer);

        // Certify BOM.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(100, 2), Item."Reordering Policy"::Order,
          Item."Flushing Method", '', '');
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(100, 2));  // Value Required.
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateItemAddInventory(var Item: Record Item; LocationCode: Code[10]; BinIndex: Integer): Code[20]
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.FindBin(Bin, LocationCode, '', BinIndex);
        CreateItem(Item);
        UpdateItemInventory(Item."No.", LocationCode, Bin.Code, LibraryRandom.RandDec(100, 2) + 100);
        exit(Bin.Code);
    end;

    local procedure CreateItemWithRndingPrecAddInventory(var Item: Record Item; QtyRndingPrecision: Decimal; LocationCode: Code[10]; BinIndex: Integer): Code[20]
    var
        Bin: Record Bin;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryWarehouse.FindBin(Bin, LocationCode, '', BinIndex);
        CreateItem(Item);
        ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
        ItemUnitOfMeasure.Validate("Qty. Rounding Precision", QtyRndingPrecision);
        ItemUnitOfMeasure.Modify();

        UpdateItemInventory(Item."No.", LocationCode, Bin.Code, LibraryRandom.RandDec(100, 2) + 100);
        exit(Bin.Code);
    end;

    local procedure ChangeBinCodeOnWhseShipLine(var BinCode: Code[20]; LocationCode: Code[10]; WarehouseShipmentNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Bin: Record Bin;
    begin
        LibraryWarehouse.FindBin(Bin, LocationCode, '', 4);
        BinCode := Bin.Code;
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentNo);
        WarehouseShipmentLine.Validate("Bin Code", BinCode);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure ChangeBinCodeOnActivityLine(var BinCode: Code[20]; SourceNo: Code[20]; LocationCode: Code[10])
    var
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryWarehouse.FindBin(Bin, LocationCode, '', 2);
        BinCode := Bin.Code;
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationCode, SourceNo,
          WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure ChangeUOMAndRegisterWhseAct(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; SourceNo: Code[20])
    var
        Bin: Record Bin;
    begin
        ChangeUnitOfMeasure(WarehouseActivityLine, LocationCode, SourceNo);
        FindBin(Bin, LocationCode);
        UpdateWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine.FieldNo("Bin Code"), Bin.Code);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        UpdateWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine.FieldNo("Qty. to Handle"), WarehouseActivityLine."Qty. to Handle (Base)");
        RegisterWarehouseActivity(SourceNo, WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure ChangeUnitOfMeasure(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; SourceNo: Code[20])
    begin
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationCode, SourceNo,
          WarehouseActivityLine."Action Type"::Place);
        LibraryWarehouse.ChangeUnitOfMeasure(WarehouseActivityLine);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date)
    begin
        // Random values used are not important for test.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, ShipmentDate);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date)
    begin
        CreateSalesOrder(SalesHeader, SalesLine, LocationCode, ItemNo, Quantity, ShipmentDate);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreatePick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WarehouseShipmentNo: Code[20])
    begin
        WarehouseShipmentHeader.Get(WarehouseShipmentNo);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        // Create Purchase Order with One Item Line. Random values used are not important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; DueDate: Date)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, SourceType, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);
    end;

    local procedure CreateAndRealeaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; IntransitLocationCode: Code[10])
    var
        ToBin: Record Bin;
    begin
        LibraryWarehouse.FindBin(ToBin, ToLocationCode, '', 1);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, IntransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, LibraryRandom.RandDec(100, 2));
        TransferLine.Validate("Transfer-To Bin Code", ToBin.Code);
        TransferLine.Modify(true);

        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateWhseWorksheetName(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Pick);
        WhseWorksheetTemplate.FindFirst();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    local procedure CreateWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        WarehouseReceiptHeader.Validate("Location Code", LocationOrange.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, '', 1);
        WarehouseReceiptHeader.Validate("Bin Code", Bin.Code);
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreateBOMWithComponent(var ProductionBOMHeader: Record "Production BOM Header"; var Item: Record Item; var Item2: Record Item)
    begin
        CreateItem(Item);
        CreateItem(Item2);
        CreateBOM(ProductionBOMHeader, Item."No.", Item2."No.", LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateAndPostWhseReceiptFromPO(var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationCode, ItemNo);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; DueDate: Date)
    begin
        CreateProdOrder(ProductionOrder, Status, SourceType, SourceNo, LocationCode, Quantity, DueDate);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateLocationWithCrossDockingSetup(var Location: Record Location)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        Location.Validate("Use Cross-Docking", true);

        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Location.Validate("Receipt Bin Code", Bin.Code);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Location.Validate("Shipment Bin Code", Bin.Code);

        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Bin.Validate("Cross-Dock Bin", true);
        Bin.Modify(true);

        Location.Validate("Cross-Dock Bin Code", Bin.Code);
        Location.Modify(true);
    end;

    local procedure CalculateExpectedQuantity(ProductionOrderNo: Code[20]; ItemNo: Code[20]; QtyPerUnitOfMeasure: Decimal) ExpectedQuantity: Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        ExpectedQuantity := ProdOrderComponent."Remaining Quantity" / QtyPerUnitOfMeasure;
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, 1);
    end;

    local procedure CreateWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", LocationOrange.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, '', 2);
        WarehouseShipmentHeader.Validate("Bin Code", Bin.Code);
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure GetSourceDocumentInbound(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseHeader: Record "Purchase Header")
    var
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
    begin
        LibraryVariableStorage.Enqueue(DATABASE::"Purchase Line");
        LibraryVariableStorage.Enqueue(PurchaseHeader."Document Type");
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        GetSourceDocInbound.GetSingleInboundDoc(WarehouseReceiptHeader);
    end;

    local procedure GetSourceDocumentOutbound(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesHeader: Record "Sales Header")
    var
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        LibraryVariableStorage.Enqueue(DATABASE::"Sales Line");
        LibraryVariableStorage.Enqueue(SalesHeader."Document Type");
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        GetSourceDocOutbound.GetSingleOutboundDoc(WarehouseShipmentHeader);
    end;

    local procedure CreatePurchaseLineAndAssignItemCharge(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
    end;

    local procedure CreateSalesLineAndAssignItemCharge(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line")
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
          SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");
    end;

    local procedure CreateAndPostWhseShipmentFromSO(var SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(FindWhseShipmentNo(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No."));
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure CreatePurchaseInvoiceWithReceiptNo(var PurchaseHeader: Record "Purchase Header"; var PurchaseHeader2: Record "Purchase Header"; DocumentNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        // Creates a purchase invoice for the given posted purchase order, finally the order and the invoice will be linked.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchaseHeader2."Buy-from Vendor No.");
        PurchaseHeader.Validate("No.", DocumentNo);
        PurchaseHeader.Insert(true);  // Used for primary key as the record cannot use RENAME function.
        PurchaseHeader.Validate("Buy-from Vendor No.", PurchaseHeader2."Buy-from Vendor No.");
        PurchaseHeader.Modify(true);

        // Link Purchase Order with Purchase Invoice. Create Purchase Invoice Lines.
        FindPurchaseReceipt(PurchRcptHeader, PurchaseHeader2."No.");
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure CreateSalesInvoiceWithShipmentNo(var SalesHeader: Record "Sales Header"; SalesHeader2: Record "Sales Header"; DocumentNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        // Creates a Sales invoice for the given posted Sales order, finally the order and the invoice will be linked.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SalesHeader2."Sell-to Customer No.");
        SalesHeader.Validate("No.", DocumentNo);
        SalesHeader.Insert(true);  // Used for primary key as the record cannot use RENAME function.
        SalesHeader.Validate("Sell-to Customer No.", SalesHeader2."Sell-to Customer No.");
        SalesHeader.Modify(true);

        // Link Sales Order with Sales Invoice. Create Sales Invoice Lines.
        FindSalesShipment(SalesShipmentHeader, SalesHeader2."No.");
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
    end;

    local procedure CreateWhseInternalPickHeader(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; ToZoneCode: Code[10]; ToBinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseInternalPickHeader(WhseInternalPickHeader, LocationWhite.Code);
        WhseInternalPickHeader.Validate("To Zone Code", ToZoneCode);
        WhseInternalPickHeader.Validate("To Bin Code", ToBinCode);
        WhseInternalPickHeader.Modify(true);
    end;

    local procedure CreateBinContentWithItemVariantCode(var BinContent: Record "Bin Content"; LocationCode: Code[10]; BinCode: Code[20]; ZoneCode: Code[10]; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10]; "Fixed": Boolean; Default: Boolean; ItemVariantCode: Code[10])
    begin
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, ZoneCode, BinCode, ItemNo, ItemVariantCode, BaseUnitOfMeasure);
        BinContent.Validate(Fixed, Fixed);
        BinContent.Validate(Default, Default);
        BinContent.Modify(true);
    end;

    local procedure CreateWhseInternalPutawayHeader(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; FromZonecode: Code[10]; FromBinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseInternalPutawayHdr(WhseInternalPutAwayHeader, LocationWhite.Code);
        WhseInternalPutAwayHeader.Validate("From Zone Code", FromZonecode);
        WhseInternalPutAwayHeader.Validate("From Bin Code", FromBinCode);
        WhseInternalPutAwayHeader.Modify(true);
    end;

    local procedure CreatePutawayToFloatingBin("Fixed": Boolean; Default: Boolean; Dedicated: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LocationCode: Code[10];
    begin
        // Setup: Create 2 Items: Item1,Item2, create 2 PUTPICK Bins: Bin1, Bin2 in WMS location, set Bin2 as Item1's Fixed,Default or Dedicated Bin.
        // Create Purchase Order for Item2 at the WMS location.
        LocationCode := CreateWMSLocationWithBinAndBinContent(Fixed, Default, Dedicated);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, LocationCode, LibraryInventory.CreateItem(Item));

        // Exercise: Create and post warehouse receipt for Purchase Order created above, Put-away will be created.
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);

        // Verify: Item2 is put-away into Bin1 following the rule - Find Floating Bin = TRUE & Find Empty Bin = TRUE
        FindBin(Bin, LocationCode); // The first PUTPICK Bin is the floating Bin
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::"Put-away",
          WarehouseActivityLine."Action Type"::Place, LocationCode, PurchaseHeader."No.", Bin.Code);
    end;

    local procedure CreateWhseReceiptFromPurchOrder(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          FindWarehouseReceiptNo(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No."));
    end;

    local procedure CreateWhseShipmentFromSalesOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
    end;

    local procedure CreateWMSLocationWithBinAndBinContent("Fixed": Boolean; Default: Boolean; Dedicated: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        CreateFullWarehouseSetup(Location);
        UpdateBinAndBinContent(Location.Code, Fixed, Default, Dedicated); // Set the PUTPICK Bin with the highest Bin Code as Fixed,Default or Dedicated Bin.
        exit(Location.Code);
    end;

    local procedure FindPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseHeaderNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        FindPurchaseReceipt(PurchRcptHeader, PurchaseHeaderNo);
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.FindFirst();
    end;

    local procedure FindPurchaseReceipt(var PurchRcptHeader: Record "Purch. Rcpt. Header"; OrderNo: Code[20])
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
    end;

    local procedure FindSalesShipment(var SalesShipmentHeader: Record "Sales Shipment Header"; OrderNo: Code[20])
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
    end;

    local procedure FindWhseShipmentNo(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]): Code[20]
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
        exit(WarehouseShipmentLine."No.");
    end;

    local procedure UpdatePurchaseInvoiceNoSeries(ManualNos: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeries: Record "No. Series";
    begin
        PurchasesPayablesSetup.Get();
        NoSeries.SetRange(Code, PurchasesPayablesSetup."Invoice Nos.");
        NoSeries.FindFirst();
        NoSeries.Validate("Manual Nos.", ManualNos);
        NoSeries.Modify(true);
    end;

    local procedure UpdateSalesInvoiceNoSeries(ManualNos: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
    begin
        SalesReceivablesSetup.Get();
        NoSeries.SetRange(Code, SalesReceivablesSetup."Invoice Nos.");
        NoSeries.FindFirst();
        NoSeries.Validate("Manual Nos.", ManualNos);
        NoSeries.Modify(true);
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        BinType: Record "Bin Type";
        Zone: Record Zone;
    begin
        FindBinType(BinType, true, true, false, false);
        Bin.SetRange("Bin Type Code", BinType.Code);
        Bin.SetRange("Location Code", LocationCode);
        FindZone(Zone, LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindFirst();
    end;

    local procedure FindBinContent(var BinContent: Record "Bin Content"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetFilter(Quantity, '>%1', 0);
        BinContent.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; No: Code[20])
    begin
        WarehouseReceiptLine.SetRange("No.", No);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; No: Code[20])
    begin
        WarehouseShipmentLine.SetRange("No.", No);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseActivityNo(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"): Code[20]
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
        exit(WarehouseActivityLine."No.");
    end;

    local procedure FindWarehouseReceiptNo(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
        exit(WarehouseReceiptLine."No.");
    end;

    local procedure FindWarehouseShipmentNo(): Code[20]
    var
        WarehouseSetup: Record "Warehouse Setup";
        NoSeries: Codeunit "No. Series";
    begin
        WarehouseSetup.Get();
        exit(NoSeries.PeekNextNo(WarehouseSetup."Whse. Ship Nos."));
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("No.", FindWarehouseActivityNo(SourceNo, ActivityType));
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrderNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.FindSet();
    end;

    local procedure FindWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure FindRegisterWarehouseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; SourceNo: Code[20])
    begin
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Location Code", LocationCode);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.FindFirst();
    end;

    local procedure FindPostedWhseShipmentNo(): Code[20]
    var
        WarehouseSetup: Record "Warehouse Setup";
        NoSeries: Codeunit "No. Series";
    begin
        WarehouseSetup.Get();
        exit(NoSeries.PeekNextNo(WarehouseSetup."Posted Whse. Shipment Nos."));
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; SalesHeaderNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        FindSalesShipment(SalesShipmentHeader, SalesHeaderNo);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[20])
    var
        BinType: Record "Bin Type";
    begin
        Zone.SetRange("Location Code", LocationCode);
        FindBinType(BinType, true, true, false, false);
        Zone.SetRange("Bin Type Code", BinType.Code);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure FindBinType(var BinType: Record "Bin Type"; PutAway: Boolean; Pick: Boolean; Receive: Boolean; Ship: Boolean)
    begin
        BinType.SetRange("Put Away", PutAway);
        BinType.SetRange(Pick, Pick);
        BinType.SetRange(Receive, Receive);
        BinType.SetRange(Ship, Ship);
        BinType.FindFirst();
    end;

    local procedure FindPostedWhseReceiptLines(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; SourceNo: Code[20])
    begin
        PostedWhseReceiptLine.SetRange("Source Document", PostedWhseReceiptLine."Source Document"::"Purchase Order");
        PostedWhseReceiptLine.SetRange("Source No.", SourceNo);
        PostedWhseReceiptLine.FindFirst();
    end;

    local procedure FindLastBin(var Bin: Record Bin; LocationCode: Code[10]; ZoneCode: Code[10])
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", ZoneCode);
        Bin.FindLast();
    end;

    local procedure ItemWithProductionBOM(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(FindWarehouseReceiptNo(SourceDocument, SourceNo));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseShipment(No: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WarehouseShipmentHeader.Get(No);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    [Normal]
    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange(Type, Type);
        WarehouseActivityHeader.SetRange("No.", FindWarehouseActivityNo(SourceNo, Type));
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure ReleaseWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WarehouseShipmentNo: Code[20])
    begin
        WarehouseShipmentHeader.Get(WarehouseShipmentNo);
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure UpdateInventoryUsingWhseJournal(Location: Record Location; Item: Record Item; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, '',
          Location."Cross-Dock Bin Code", WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [Normal]
    local procedure UpdateWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(WarehouseActivityLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(WarehouseActivityLine);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateQuantityOnWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; No: Code[20]; QtyToShip: Decimal)
    begin
        WarehouseShipmentLine.SetRange("No.", No);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure WhseShipFromTOWithNewBinCode(var BinCode: Code[20]; TransferHeader: Record "Transfer Header"; WarehouseShipmentNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        ChangeBinCodeOnWhseShipLine(BinCode, LocationCode, WarehouseShipmentNo);
    end;

    local procedure WhseShipFromSOWithNewBinCode(var BinCode: Code[20]; SalesHeader: Record "Sales Header"; WarehouseShipmentNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        ChangeBinCodeOnWhseShipLine(BinCode, LocationCode, WarehouseShipmentNo);
    end;

    local procedure UpdateWarehouseSetup(RequireReceive: Boolean; RequireShipment: Boolean)
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Require Receive", RequireReceive);
        WarehouseSetup.Validate("Require Shipment", RequireShipment);
        WarehouseSetup.Modify(true);
    end;

    local procedure UpdateQuantityToHandleAndBinOnActivityLine(ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin3: Record Bin;
    begin
        LibraryWarehouse.FindBin(Bin3, LocationOrange.Code, '', 3);  // Find bin of Index 3.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationOrange.Code, SourceNo, ActionType);
        ChangeBinCodeOnActivityLine(Bin3.Code, SourceNo, LocationOrange.Code);
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Validate("Qty. to Handle (Base)", QtyToHandle);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateInventoryOnLocationWithWhseAdjustment(Location: Record Location; Item: Record Item; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, '',
          Location."Cross-Dock Bin Code", WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateBinAndBinContent(LocationCode: Code[10]; "Fixed": Boolean; Default: Boolean; Dedicated: Boolean)
    var
        Zone: Record Zone;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
    begin
        FindZone(Zone, LocationCode);
        FindLastBin(Bin, Zone."Location Code", Zone.Code);
        Bin.Validate(Dedicated, Dedicated);
        Bin.Modify(true);
        CreateBinContentWithItemVariantCode(
          BinContent, LocationCode, Bin.Code, Zone.Code, LibraryInventory.CreateItem(Item), Item."Base Unit of Measure", Fixed, Default, '');
    end;

    local procedure FindBinCodeInBinContent(var BinContent: Record "Bin Content"; var ItemCode: Code[20]; MaxStep: Integer)
    begin
        BinContent.Next(LibraryRandom.RandInt(MaxStep));
        ItemCode := BinContent."Bin Code";
    end;

    local procedure FindBinCodesInBinContent(var FirstCode: Code[20]; var SecondCode: Code[20]; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        FindBinCodeInBinContent(BinContent, FirstCode, BinContent.Count div 2);
        FindBinCodeInBinContent(BinContent, SecondCode, BinContent.Count div 2);
    end;

    local procedure FindItemCodeInBinContent(var BinContent: Record "Bin Content"; var ItemCode: Code[20]; MaxStep: Integer)
    begin
        BinContent.Next(LibraryRandom.RandInt(MaxStep));
        ItemCode := BinContent."Item No.";
    end;

    local procedure FindItemCodesInBinContent(var FirstCode: Code[20]; var SecondCode: Code[20]; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        FindItemCodeInBinContent(BinContent, FirstCode, BinContent.Count div 2);
        FindItemCodeInBinContent(BinContent, SecondCode, BinContent.Count div 2);
    end;

    local procedure FindItemVariantCodeInBinContent(var BinContent: Record "Bin Content"; var ItemCode: Code[20]; MaxStep: Integer)
    begin
        BinContent.Next(LibraryRandom.RandInt(MaxStep));
        ItemCode := BinContent."Variant Code";
    end;

    local procedure FindItemVariantCodesInBinContent(var FirstCode: Code[20]; var SecondCode: Code[20]; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
        ItemCode: Code[20];
    begin
        BinContent.SetRange("Location Code", LocationCode);
        FindItemCodeInBinContent(BinContent, ItemCode, BinContent.Count div 2);
        BinContent.SetRange("Item No.", ItemCode);
        BinContent.FindFirst();

        FindItemVariantCodeInBinContent(BinContent, FirstCode, BinContent.Count div 2);
        FindItemVariantCodeInBinContent(BinContent, SecondCode, BinContent.Count div 2);
    end;

    local procedure FillBinContent(var LocationCode: Code[10]; CreateItemVariant: Boolean)
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        BinType: Record "Bin Type";
        ItemVariant: Record "Item Variant";
        ItemIndex: Integer;
        BinIndex: Integer;
        ItemVariantIndex: Integer;
    begin
        LocationCode := LocationWhite.Code;

        FindZone(Zone, LocationCode);
        FindBinType(BinType, true, false, false, false);

        for BinIndex := 1 to LibraryRandom.RandIntInRange(3, 10) do begin
            LibraryWarehouse.CreateBin(
              Bin,
              LocationCode,
              CopyStr(
                LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
                LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))),
              Zone.Code,
              BinType.Code);
            for ItemIndex := 1 to LibraryRandom.RandIntInRange(3, 10) do begin
                CreateItem(Item);
                if CreateItemVariant then
                    for ItemVariantIndex := 1 to LibraryRandom.RandIntInRange(3, 10) do begin
                        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
                        CreateBinContentWithItemVariantCode(
                          BinContent, LocationCode, Bin.Code, Zone.Code, Item."No.", Item."Base Unit of Measure", true, true, ItemVariant.Code);
                    end
                else
                    CreateBinContentWithItemVariantCode(
                      BinContent, LocationCode, Bin.Code, Zone.Code, Item."No.", Item."Base Unit of Measure", true, true, '');
            end;
        end;
    end;

    local procedure VerifyBinContentGetCaptionWithFilter(FilterMask: Text; LocationCode: Code[20]; FirstCode: Code[20]; SecondCode: Code[20]; FieldNo: Integer; TableCaption2: Text)
    var
        BinContent: Record "Bin Content";
        Location: Record Location;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        ExpectedCaption: Text;
    begin
        RecRef.GetTable(BinContent);
        FieldRef := RecRef.Field(BinContent.FieldNo("Location Code"));
        FieldRef.SetFilter(LocationCode);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.SetFilter(StrSubstNo(FilterMask, FirstCode, SecondCode));
        RecRef.FindFirst();
        RecRef.SetTable(BinContent);

        ExpectedCaption := StrSubstNo('%1 %2', Location.TableCaption(), LocationCode);
        if FilterMask <> '' then
            ExpectedCaption := StrSubstNo('%1 %2 %3', ExpectedCaption, TableCaption2, FieldRef.Value);

        Assert.AreEqual(
          ExpectedCaption,
          BinContent.GetCaption(),
          StrSubstNo(BinContentGetCaptionErr, BinContent.GetFilters));
    end;

    local procedure VerifyActivityLine(LocationCode: Code[10]; SourceNo: Code[20]; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10]; Quantity: Decimal; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, SourceNo, WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField(Quantity, Quantity);
        VerifyWhseActivityLine(WarehouseActivityLine, BaseUnitOfMeasure, 1, Quantity);  // value is Quantity Per Unit Of Measure For Base Unit Of Measure.
    end;

    local procedure VerifyBinCode(ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; SourceNo: Code[20]; ExpectedBinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, SourceNo, ActionType);
        Assert.AreEqual(
          ExpectedBinCode, WarehouseActivityLine."Bin Code", StrSubstNo(BinError, ExpectedBinCode, WarehouseActivityLine.TableCaption()));
    end;

    local procedure VerifyBinCodeNotEqual(ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; SourceNo: Code[20]; NotExpectedBinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, SourceNo, ActionType);
        Assert.AreNotEqual(
          NotExpectedBinCode, WarehouseActivityLine."Bin Code", StrSubstNo(BinError2, NotExpectedBinCode, WarehouseActivityLine.TableCaption()));
    end;

    local procedure FindWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.FindSet();
    end;

    local procedure VerifyBinOnProdOrdComponent(var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20]; BinCode: Code[20])
    begin
        ProdOrderComponent.TestField("Item No.", ItemNo);
        ProdOrderComponent.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyWarehouseEntry(WarehouseEntry: Record "Warehouse Entry"; BinCode: Code[20]; Quantity: Decimal)
    begin
        WarehouseEntry.TestField("Bin Code", BinCode);
        WarehouseEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedShipment(SalesHeader: Record "Sales Header")
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            PostedWhseShipmentLine.SetRange("Source No.", SalesLine."Document No.");
            PostedWhseShipmentLine.SetRange("Source Line No.", SalesLine."Line No.");
            PostedWhseShipmentLine.FindFirst();
            Assert.AreEqual(PostedWhseShipmentLine.Quantity, SalesLine.Quantity,
              StrSubstNo(QuantityError, SalesLine.Quantity, PostedWhseShipmentLine.TableCaption()));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyDefaultBinContent(LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange(Default, true);
        BinContent.FindFirst();
        Assert.AreEqual(BinCode, BinContent."Bin Code", StrSubstNo(BinError, BinCode, BinContent.TableCaption()));
    end;

    local procedure VerifyWhseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line"; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Decimal; ExpectedQuantity: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        WarehouseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseActivityLine.TestField("Qty. per Unit of Measure", QtyPerUnitOfMeasure);
        Assert.AreNearlyEqual(
          ExpectedQuantity, WarehouseActivityLine.Quantity, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(QuantityError, ExpectedQuantity, WarehouseActivityLine.TableCaption()));
        Assert.AreNearlyEqual(
          ExpectedQuantity, WarehouseActivityLine."Qty. Outstanding", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(QuantityError, ExpectedQuantity, WarehouseActivityLine.TableCaption()));
    end;

    local procedure VerifyRegisteredWhseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line"; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Decimal; ExpectedQuantity: Decimal)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindRegisterWarehouseActivityLine(
          RegisteredWhseActivityLine, WarehouseActivityLine."Activity Type", WarehouseActivityLine."Action Type",
          WarehouseActivityLine."Location Code", WarehouseActivityLine."Source No.");

        RegisteredWhseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        RegisteredWhseActivityLine.TestField("Qty. per Unit of Measure", QtyPerUnitOfMeasure);
        Assert.AreNearlyEqual(
          ExpectedQuantity, RegisteredWhseActivityLine.Quantity, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(QuantityError, ExpectedQuantity, WarehouseActivityLine.TableCaption()));
    end;

    local procedure VerifyTransferReceipt(TransferLine: Record "Transfer Line")
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        TransferReceiptLine.SetRange("Transfer Order No.", TransferLine."Document No.");
        TransferReceiptLine.SetRange("Item No.", TransferLine."Item No.");
        TransferReceiptLine.FindFirst();
        TransferReceiptLine.TestField(Quantity, TransferLine.Quantity);
        TransferReceiptLine.TestField("Transfer-to Code", TransferLine."Transfer-to Code");
        TransferReceiptLine.TestField("Transfer-from Code", TransferLine."Transfer-from Code");
        TransferReceiptLine.TestField("Transfer-To Bin Code", TransferLine."Transfer-To Bin Code");
    end;

    local procedure VerifyTransferShipment(TransferOderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; TransferToCode: Code[10]; TransferFromCode: Code[10])
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        TransferShipmentLine.SetRange("Transfer Order No.", TransferOderNo);
        TransferShipmentLine.SetRange("Item No.", ItemNo);
        TransferShipmentLine.FindFirst();
        TransferShipmentLine.TestField(Quantity, Quantity);
        TransferShipmentLine.TestField("Transfer-to Code", TransferToCode);
        TransferShipmentLine.TestField("Transfer-from Code", TransferFromCode);
    end;

    local procedure VerifyWarehouseShipmentLine(No: Code[20]; ItemNo: Code[20]; QtyToShip: Decimal; Quantity: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", No);
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedWarehouseShipmentLine(LocationCode: Code[10]; ItemNo: Code[20]; WhseShipmentNo: Code[20]; SourceNo: Code[20]; Quantity: Decimal)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        PostedWhseShipmentLine.SetRange("Location Code", LocationCode);
        PostedWhseShipmentLine.SetRange("Item No.", ItemNo);
        PostedWhseShipmentLine.SetRange("Whse. Shipment No.", WhseShipmentNo);
        PostedWhseShipmentLine.FindFirst();
        PostedWhseShipmentLine.TestField(Quantity, Quantity);
        PostedWhseShipmentLine.TestField("Source No.", SourceNo);
    end;

    local procedure VerifyRegisteredActivityLine(ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; ExpectedQuantity: Decimal)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisterWarehouseActivityLine(
          RegisteredWhseActivityLine, ActivityType, RegisteredWhseActivityLine."Action Type"::Place, LocationCode, SourceNo);
        RegisteredWhseActivityLine.TestField("Item No.", ItemNo);
        RegisteredWhseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        RegisteredWhseActivityLine.TestField("Qty. per Unit of Measure", 1);
        Assert.AreEqual(
          ExpectedQuantity, RegisteredWhseActivityLine.Quantity,
          StrSubstNo(QuantityError, ExpectedQuantity, RegisteredWhseActivityLine.TableCaption()));
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item No.", ItemNo);
        ItemLedgerEntry.TestField("Location Code", LocationCode);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedPurchaseInvoice(DocumentNo: Code[20]; Type: Enum "Purchase Line Type"; Quantity: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange(Type, Type);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedSalesInvoice(DocumentNo: Code[20]; Type: Enum "Sales Line Type"; Quantity: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange(Type, Type);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedWhseReceiptLine(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[20])
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        FindPostedWhseReceiptLines(PostedWhseReceiptLine, SourceNo);
        PostedWhseReceiptLine.TestField("Item No.", ItemNo);
        PostedWhseReceiptLine.TestField("Location Code", LocationCode);
        PostedWhseReceiptLine.TestField(Quantity, Quantity);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Integer)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Location Code", LocationPink.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationPink.Code);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateItemWithRepl(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(10, 2));  // Using Random value for Last Direct Cost.
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        Item.Modify(true);
    end;

    local procedure UndoPurchaseReceiptLines(PurchaseLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FindReceiptLine(PurchRcptLine, PurchaseLine."No.");
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    local procedure FindReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; No: Code[20])
    begin
        PurchRcptLine.SetRange("No.", No);
        PurchRcptLine.FindFirst();
    end;

    local procedure VerifyUndoReceiptLineOnPostedReceipt(DocumentNo: Code[20]; QtyToReceive: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", DocumentNo);
        PurchRcptLine.FindLast();
        PurchRcptLine.TestField(Quantity, -1 * QtyToReceive);
    end;

    local procedure VerifyQuantityReceivedOnPurchaseLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Quantity Received", 0);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Cost" := LibraryRandom.RandDec(1000, 2);
        Item.Modify();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
         PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandDec(100, 2), '', WorkDate());
    end;

    local procedure CreatePurchaseInvoiceWithReceipt(var PurchaseHeader: Record "Purchase Header"; var PurchaseHeader2: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchaseHeader2."Buy-from Vendor No.");
        PurchaseHeader.Validate("Buy-from Vendor No.", PurchaseHeader2."Buy-from Vendor No.");
        PurchaseHeader.Modify(true);

        FindPurchaseReceipt(PurchRcptHeader, PurchaseHeader2."No.");
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure UpdatePurchaseSetupWithSamePreAndPostedNoSeries()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Invoice Nos.", PurchasesPayablesSetup."Posted Invoice Nos.");
        PurchasesPayablesSetup.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentReportHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ChangeUOMRequestPageHandler(var WhseChangeUnitOfMeasure: TestRequestPage "Whse. Change Unit of Measure")
    begin
        WhseChangeUnitOfMeasure.UnitOfMeasureCode.SetValue(NewUnitOfMeasure);
        WhseChangeUnitOfMeasure.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SourceDocumentsPageHandler(var SourceDocuments: Page "Source Documents"; var Response: Action)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Location Code", LocationCode2);
        WarehouseRequest.SetRange("Source Type", LibraryVariableStorage.DequeueInteger());
        WarehouseRequest.SetRange("Source Subtype", LibraryVariableStorage.DequeueInteger());
        WarehouseRequest.SetRange("Source No.", LibraryVariableStorage.DequeueText());
        WarehouseRequest.FindFirst();
        SourceDocuments.SetRecord(WarehouseRequest);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionPageHandler(var PickSelection: Page "Pick Selection"; var Response: Action)
    var
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        WhsePickRequest.SetRange("Location Code", LocationCode2);
        WhsePickRequest.SetRange("Document No.", WarehouseShipmentNo);
        WhsePickRequest.FindFirst();
        PickSelection.SetRecord(WhsePickRequest);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinePageHandler(var GetReceiptLines: Page "Get Receipt Lines"; var Response: Action)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinePageHandler(var GetShipmentLines: Page "Get Shipment Lines"; var Response: Action)
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseShipmentCreatePick(var WhseShipmentCreatePick: TestRequestPage "Whse.-Shipment - Create Pick")
    begin
        WhseShipmentCreatePick.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ShipmentReceiptDeleteMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, DeletedMessage) > 0, StrSubstNo(UnexpectedMessageDialog, Message));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DisregardedMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, DisregardMessage) > 0, StrSubstNo(UnexpectedMessageDialog, Message));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ReceiptTransferDeletedMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, DeletedMessage) > 0, StrSubstNo(UnexpectedMessageDialog, Message));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PickActivityMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, PickActivityMessage) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PutAwayActivityMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, PutAwayActivityMessage) > 0, Message);
    end;
}
