codeunit 137051 "SCM Warehouse - III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        IsInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalBatch: Record "Item Journal Batch";
        LocationWhite: Record Location;
        LocationSilver: Record Location;
        LocationSilver2: Record Location;
        LocationSilver3: Record Location;
        LocationGreen: Record Location;
        LocationOrange: Record Location;
        LocationYellow: Record Location;
        LocationYellow2: Record Location;
        LocationRed: Record Location;
        LocationGreen2: Record Location;
        LocationOrange2: Record Location;
        LocationIntransit: Record Location;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        Counter: Integer;
        IsInitialized: Boolean;
        TrackingAction: Option SerialNo,LotNo,All,SelectEntries,AssignLotNo,UpdateAndAssignNew,CheckQtyToHandleBase,AssignPackageNo;
        PostJournalLines: Label 'Do you want to post the journal lines';
        LinesPosted: Label 'The journal lines were successfully posted';
        PickActivitiesCreated: Label 'Number of Invt. Pick activities created';
        HandlingError: Label 'Nothing to handle.';
        Quantity2: Decimal;
        WarehouseShipmentNo: Code[20];
        QuantityError: Label 'Quantity must be %1 in %2.';
        SourceNo: Code[20];
        SourceNoError: Label 'You cannot change Source No. because one or more lines exist.';
        SourceDocumentError: Label 'You cannot change Source Document because one or more lines exist.';
        GetSourceDocumentError: Label 'You cannot use this function if the lines already exist.';
        BinError: Label 'Bin Code must be %1 in %2.';
        ReleasedProdOrderCreated: Label 'Released Prod. Order';
        LocationCode: Code[10];
        PutAwayCreated: Label 'Number of Invt. Put-away activities created';
        NothingToCreate: Label 'There is nothing to create';
        ValidationError: Label 'Validation error for Field:';
        WorkCenterError: Label 'Location %1 must be set up with Bin Mandatory if the Work Center %2 uses it.';
        EditableError: Label 'Can Be Edited.';
        EnabledError: Label 'Field is Enabled.';
        WantToContinueMessage: Label 'Are you sure that you want to continue?';
        UseAsInTransitEditableErr: Label 'Field ''Use As In-Transit'' in Location Card Page should be editable when creating new Location';
        FieldMustNotBeEmptyErr: Label 'Field %1 in table %2 must not be empty.';
        WrongNoOfWhseActivityLinesErr: Label '%1 warehouse activity lines must be created for lot %2';
        QtyInPickErr: Label 'Incorrect quantity in Pick.';
        ItemTrackingErr: Label 'Item tracking numbers defined for item %1 in the %2 are higher than the item quantity.', Comment = 'Item tracking numbers should not be higher than the item quantity.';
        TwoFieldsOfTableMustBeEqualErr: Label 'Field %1 must be equal to field %2 in table %3.', Comment = '%1 - Field 1, %2 - field 2, %3 - table.';
        NoWarehouseActivityLineErr: Label 'There is no Warehouse Activity Line within the filter.';
        UnexpectedSourceNoErr: Label 'Unexpected value of Source No. field.';
        ExpiredItemsNotPickedMsg: Label 'Some items were not included in the pick due to their expiration date.';
        ZoneCodeMustMatchErr: Label 'Zone Code must match.';
        WhseActivityHeaderMustNotBeEmpty: Label 'Warehouse Activity Header must not be empty.';
        ExpirationDateCalcFormula: Label '<CY-1Y>';
        ExpirationDateMustNotBeEmptyErr: Label 'Expiration Date must not be empty.';
        QtyToHandleErr: Label '%1 must be %2 in %3', Comment = '%1 = Qty. to Handle, %2 = QtyToHandle, %3 = Warehouse Activity Line';
        DoNotFillQtyToHandleMustBeFalseErr: Label 'Do Not Fill Qty. to Handle must be false in Warehouse Activity Header';

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandler,PickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtPickFromPurchReturnOrderWithStrictExpiration()
    begin
        Initialize();
        InventoryPickFromPurchaseReturnOrder(true);  // Strict Expiration Posting True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandler,PickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure InvtPickFromPurchReturnOrderWithoutStrictExpiration()
    begin
        Initialize();
        InventoryPickFromPurchaseReturnOrder(false);  // Strict Expiration Posting False.
    end;

    local procedure InventoryPickFromPurchaseReturnOrder(StrictExpirationPosting: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item, assign Serial No. on Item Journal Line and post Item Journal. Create a Purchase Return Order;
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        CreateTrackedItem(Item, false, true, StrictExpirationPosting, false, StrictExpirationPosting);
        Quantity := LibraryRandom.RandInt(5) + 2;  // Integer Value required.
        CreateItemJournaLine(Item."No.", LocationSilver.Code, Bin.Code, Quantity);
        AssignSerialNoAndPostItemJournal(Item."No.", LocationSilver.Code);
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, Item."No.", Quantity, LocationSilver.Code);

        // Exercise: Create Inventory Pick. If Strict Expiration - True then post Inventory Pick as well.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Return Order", PurchaseHeader."No.", false, true, false);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationSilver.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        if StrictExpirationPosting then
            PostInventoryPick(PurchaseHeader."No.");

        // Verify: Verify the values on Inventory Pick with or without posting.
        if StrictExpirationPosting then
            VerifyPostedInventorytPickLine(PurchaseHeader."No.", LocationSilver.Code, Item."No.", WorkDate(), Bin.Code)
        else
            VerifyInventoryPutAwayPick(WarehouseActivityLine, PurchaseHeader."No.", LocationSilver.Code, Item."No.", Bin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandler,PickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromSalesOrderWithStrictExpiration()
    begin
        Initialize();
        InventoryPickFromSalesOrder(true);  // Strict Expiration Posting True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandler,PickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromSalesOrderWithoutStrictExpiration()
    begin
        Initialize();
        InventoryPickFromSalesOrder(false);  // Strict Expiration Posting False.
    end;

    local procedure InventoryPickFromSalesOrder(StrictExpirationPosting: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item, assign Serial No. on Item Journal Line and post Item Journal. Create a Sales Order, create Inventory Pick.
        LibraryWarehouse.FindBin(Bin, LocationSilver2.Code, '', 1);  // Find Bin of Index 1.
        CreateTrackedItem(Item, false, true, StrictExpirationPosting, false, StrictExpirationPosting);

        Quantity := LibraryRandom.RandInt(5) + 2;  // Integer Value required.
        CreateItemJournaLine(Item."No.", LocationSilver2.Code, Bin.Code, Quantity);
        AssignSerialNoAndPostItemJournal(Item."No.", LocationSilver2.Code);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity, LocationSilver2.Code);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationSilver2.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);

        // Exercise: Create Inventory Pick.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationSilver2.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        if StrictExpirationPosting then
            PostInventoryPick(SalesHeader."No.");

        // Verify: Verify the values on Inventory Pick with or without posting.
        if StrictExpirationPosting then
            VerifyPostedInventorytPickLine(SalesHeader."No.", LocationSilver2.Code, Item."No.", WorkDate(), Bin.Code)
        else
            VerifyInventoryPutAwayPick(WarehouseActivityLine, SalesHeader."No.", LocationSilver2.Code, Item."No.", Bin.Code, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandler,ShipmentMessageHandler')]
    [Scope('OnPrem')]
    procedure PickErrorWhseShipmentWithoutStrictExpiration()
    begin
        Initialize();
        PickErrorOnWarehouseShipment(false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandler,ShipmentMessageHandler')]
    [Scope('OnPrem')]
    procedure PickErrorWhseShipmentWithStrictExpiration()
    begin
        Initialize();
        PickErrorOnWarehouseShipment(true);
    end;

    local procedure PickErrorOnWarehouseShipment(StrictExpirationPosting: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
        WarehouseShipmentNo: Code[20];
    begin
        // Setup: Create Item with Item Tracking Code, assign Serial No. on Item Journal Line and post Item Journal. Create a Sales Order, create Warehouse shipment.
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.FindBin(Bin, LocationGreen.Code, '', 1);  // Find Bin of Index 1.
        CreateTrackedItem(Item, false, true, StrictExpirationPosting, false, StrictExpirationPosting);

        Quantity := LibraryRandom.RandInt(5) + 2;  // Integer Value required.
        CreateItemJournaLine(Item."No.", LocationGreen.Code, Bin.Code, Quantity);
        AssignSerialNoAndPostItemJournal(Item."No.", LocationGreen.Code);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity, LocationGreen.Code);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Exercise : Create Pick from Warehouse Shipment Header.
        asserterror CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Verify: Verify that Pick is not created.
        Assert.ExpectedError(HandlingError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickWithoutDelete()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create Item and update Inventory, create and release Purchase Order, create Put Away, create and release Sales Order, create and release Whse Shipment.
        Initialize();
        CreateItemWithItemTrackingCode(Item, '');  // Creating Item without Item Tracking Code for the test.
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader, LocationWhite.Code, Item."No.");
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndPostWarehouseShipmentFromSO(SalesHeader, WarehouseShipmentHeader, Item."No.", Quantity2, LocationWhite.Code);

        // Exercise: Create Pick.
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Verify: Verify the values on Whse Activity Line.
        VerifyWhseActivityLine(WarehouseActivityLine, Quantity2, SalesHeader."No.", LocationWhite.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickWithChangedDocumentAfterDelete()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create Item, update Item inventory, create and release Purchase Order, create Put Away, create and release Sales Order, create and release Whse Shipment.
        // Update Quantity on Pick, register and delete it. Create and release Sales Order, create Whse Shipment.
        Initialize();
        CreateItemWithItemTrackingCode(Item, '');  // Creating Item without Item Tracking Code for the test.
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader, LocationWhite.Code, Item."No.");
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndPostWarehouseShipmentFromSO(SalesHeader, WarehouseShipmentHeader, Item."No.", Quantity2, LocationWhite.Code);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);
        UpdateActivityLineAndDeletePartially(WarehouseActivityLine, SalesHeader."No.");
        CreateAndPostWarehouseShipmentFromSO(SalesHeader2, WarehouseShipmentHeader, Item."No.", Quantity2 / 2, LocationWhite.Code);  // Using partial Quantity as on Whse Activity Line.

        // Exercise: Create Pick.
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Verify: Verify the values on Whse Activity Line.
        VerifyWhseActivityLine(WarehouseActivityLine2, Quantity2 / 2, SalesHeader2."No.", LocationWhite.Code);  // Verify the Quantity half of the Whse Activity Line.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickWithHandlingError()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Update Item inventory, create and release Purchase Order, create Put Away, create and release Sales Order, create and release Whse Shipment.
        Initialize();
        CreateItemWithItemTrackingCode(Item, '');  // Creating Item without Item Tracking Code for the test.
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader, LocationWhite.Code, Item."No.");
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndPostWarehouseShipmentFromSO(SalesHeader, WarehouseShipmentHeader, Item."No.", Quantity2, LocationWhite.Code);

        // Exercise: Create Pick.
        asserterror CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Verify: Verify that Pick is not created.
        Assert.ExpectedError(HandlingError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickWithHandlingErrorAfterDeleteShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Update Item inventory, create and release Purchase Order, create Put Away, create and release Sales Order, create and release Whse Shipment.
        // Delete Warehouse Shipment Lines and again create the Sales Order and create and release Wraehouse Shipment.
        Initialize();
        CreateItemWithItemTrackingCode(Item, '');  // Creating Item without Item Tracking Code for the test.
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader, LocationWhite.Code, Item."No.");
        CreateAndPostWarehouseShipmentFromSO(SalesHeader, WarehouseShipmentHeader, Item."No.", Quantity2, LocationWhite.Code);
        DeleteWarehouseShipmentLines(WarehouseShipmentHeader);
        CreateAndPostWarehouseShipmentFromSO(SalesHeader2, WarehouseShipmentHeader, Item."No.", Quantity2 / 2, LocationWhite.Code);  // Using partial Quantity as on Whse Activity Line.

        // Exercise: Create Pick.
        asserterror CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Verify: Verify that Pick is not created.
        Assert.ExpectedError(HandlingError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickRecreatedAfterDeletion()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Update Item inventory, create and release Purchase Order, create Put Away, create and release Sales Order, create and release Whse Shipment.
        Initialize();
        CreateItemWithItemTrackingCode(Item, '');  // Creating Item without Item Tracking Code for the test.
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader, LocationWhite.Code, Item."No.");
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndPostWarehouseShipmentFromSO(SalesHeader, WarehouseShipmentHeader, Item."No.", Quantity2, LocationWhite.Code);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Exercise: Update Whse Activity Line and create Pick.
        Clear(WarehouseActivityLine);
        UpdateAndCreatePick(WarehouseActivityLine, SalesHeader."No.");

        // Verify: Verify the values on Warehouse Activity.
        VerifyWhseActivityLine(WarehouseActivityLine, (Quantity2 / 2) + (Quantity2 / 4), SalesHeader."No.", LocationWhite.Code);  // Pick created for Half Quantity updated Added to the Updated Quantity on Whse Activity Line.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickWithReducedQuantityFromSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Update Item inventory, create and release Purchase Order, create Put Away, create and release Sales Order, create and release Whse Shipment.
        Initialize();
        CreateItemWithItemTrackingCode(Item, '');  // Creating Item without Item Tracking Code for the test.
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader, LocationWhite.Code, Item."No.");
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndPostWarehouseShipmentFromSO(SalesHeader, WarehouseShipmentHeader, Item."No.", 2 * Quantity2, LocationWhite.Code);  // Value required for the test.

        // Exercise: Create Pick.
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Verify: Verify the values on Whse Activity Line.
        VerifyWhseActivityLine(WarehouseActivityLine, Quantity2, SalesHeader."No.", LocationWhite.Code);  // Pick created for half the Quantity as on Sales Order.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickWithDeletionAndRecreateShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Update Item inventory, create and release Purchase Order, create Put Away, create and release Sales Order, create and release Whse Shipment.
        Initialize();
        CreateItemWithItemTrackingCode(Item, '');  // Creating Item without Item Tracking Code for the test.
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader, LocationWhite.Code, Item."No.");
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndPostWarehouseShipmentFromSO(SalesHeader, WarehouseShipmentHeader, Item."No.", 2 * Quantity2, LocationWhite.Code);  // Value required for the test.
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Update Quantity on Pick, register and delete it. Post Whse Shipment and delete it. Create and release Sales Order, create Whse Shipment.
        UpdateActivityLineAndDeletePartially(WarehouseActivityLine, SalesHeader."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        DeleteWarehouseShipmentLines(WarehouseShipmentHeader);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);

        // Exercise: Create Pick.
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // Whse Shipment created for total Quantity on Sales Order reduced by Quantity To Handle on Whse Activity Line.
        VerifyWarehouseShipmentLine(WarehouseShipmentNo, Item."No.", 2 * Quantity2 - (Quantity2 / 2));
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeSourceNoOnInventoryMovement()
    var
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Setup: Create Item Movement Setup.
        Initialize();
        CreateItemMovementSetup(ProductionOrder, WarehouseActivityHeader);

        // Exercise: Change Source No On Inventory Movement.
        FindWarehouseActivityHeader(WarehouseActivityHeader, ProductionOrder."No.");
        asserterror WarehouseActivityHeader.Validate("Source No.", LibraryUtility.GenerateGUID());

        // Verify: Verify the error message on changing Source No.
        Assert.ExpectedError(SourceNoError);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeSourceDocOnInventoryMovement()
    var
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Setup: Create Item Movement Setup.
        Initialize();
        CreateItemMovementSetup(ProductionOrder, WarehouseActivityHeader);

        // Exercise: Change Source Document for Inventory movement.
        FindWarehouseActivityHeader(WarehouseActivityHeader, ProductionOrder."No.");
        asserterror WarehouseActivityHeader.Validate("Source Document", WarehouseActivityHeader."Source Document"::"Assembly Order");

        // Verify: Verify the error Message on changing Source Doc.
        Assert.ExpectedError(SourceDocumentError);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure GetSourceDocTwiceOnInventoryMovement()
    var
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        InventoryMovement: TestPage "Inventory Movement";
    begin
        // Setup: Create Item Movement Setup.
        Initialize();
        CreateItemMovementSetup(ProductionOrder, WarehouseActivityHeader);

        // Exercise: Get Source Document for already created Inventory movement.
        OpenInventoryMovement(InventoryMovement, WarehouseActivityHeader."No.", ProductionOrder."No.");
        asserterror InventoryMovement.GetSourceDocument.Invoke();

        // Verify: Verify Error Message for Get Source Document.
        Assert.ExpectedError(GetSourceDocumentError);
    end;

    [Test]
    [HandlerFunctions('ShipmentWithProductionOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWhseShipmentUsingProdOrderWithoutBin()
    var
        Quantity: Decimal;
    begin
        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2) + 10;  // Small value required.
        PickFromWhseShipmentUsingProdOrder(false, Quantity);  // No updation of Bin on Whse Activity Line.
    end;

    [Test]
    [HandlerFunctions('ShipmentWithProductionOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWhseShipmentUsingProdOrderWithBin()
    var
        Quantity: Decimal;
    begin
        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2) + 10;  // Small value required.
        PickFromWhseShipmentUsingProdOrder(true, Quantity);  // Updating Bin on Whse Activity Line.
    end;

    [Test]
    [HandlerFunctions('ShipmentWithProductionOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure PickTwiceQuantityFromWhseShipmentUsingProdOrderWithoutBin()
    var
        Quantity: Decimal;
    begin
        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2) + 100;  // Large value required.
        PickFromWhseShipmentUsingProdOrder(false, Quantity);  // No updation of Bin on Whse Activity Line.
    end;

    [Test]
    [HandlerFunctions('ShipmentWithProductionOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure PickTwiceQuantityFromWhseShipmentUsingProdOrderWithBin()
    var
        Quantity: Decimal;
    begin
        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2) + 100;  // Large value required.
        PickFromWhseShipmentUsingProdOrder(true, Quantity);  // Updating Bin on Whse Activity Line.
    end;

    local procedure PickFromWhseShipmentUsingProdOrder(UpdateBin: Boolean; Quantity: Decimal)
    var
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Update Location Setup, create Manufacturing Setup. Create Sales Order and post Whse Shipment.
        // Create production Order from sales Order, update Bin on Production Order Line, explode routing and Post Output Journal.
        UpdateLocationSetup(true);  // Always Create Pick Line as TRUE.
        CreateManufacturingSetup(RoutingHeader, Item);
        CreateAndPostWarehouseShipmentFromSO(SalesHeader, WarehouseShipmentHeader, Item."No.", Quantity, LocationWhite.Code);  // Value required for the test.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProdOrderLine.Status::Released, "Create Production Order Type"::ItemOrder);
        UpdateProductionOrderLine(ProdOrderLine, Item."No.");
        ExplodeRoutingAndPostOutputJournal(ProdOrderLine, Quantity);

        // Exercise: Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the values on Whse Activity Line. Verify the Bin Code value as blank on Whse Activity Line.
        VerifyWhseActivityLine(WarehouseActivityLine, Quantity, SalesHeader."No.", LocationWhite.Code);  // Pick created for the Quantity as on Sales Order.
        VerifyBinCode(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LocationWhite.Code, SalesHeader."No.", '');

        if UpdateBin then begin
            UpdateBinOnActivityLine(WarehouseActivityLine, '', ProdOrderLine."Bin Code");

            // Exercise: Register Whse Activity.
            RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

            // Verify: Verify the values on Registered Whse Activity Line.
            VerifyRegisteredWhseActivityLine(WarehouseActivityLine, Quantity);
        end;

        // Tear Down: Restore the original value for Location.
        UpdateLocationSetup(false);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ShipmentWithProductionOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure PickWithReservationUsingProdOrder()
    var
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Update Location Setup, create Manufacturing Setup. Create Sales Order and post Whse Shipment.
        // Create production Order from sales Order, update Bin on Production Order Line, explode routing and Post Output Journal.
        Initialize();
        UpdateLocationSetup(true);  // Always Create Pick Line as TRUE.
        CreateManufacturingSetup(RoutingHeader, Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateInventoryUsingWhseJournal(LocationWhite, Item, 2 * Quantity);  // Value required for the test.
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", Quantity, LocationWhite.Code);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProdOrderLine.Status::Released, "Create Production Order Type"::ItemOrder);
        UpdateProductionOrderLine(ProdOrderLine, Item."No.");
        ExplodeRoutingAndPostOutputJournal(ProdOrderLine, Quantity);

        // Exercise: Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the values on Whse Activity Line.
        VerifyWhseActivityLine(WarehouseActivityLine, 2 * Quantity, SalesHeader."No.", LocationWhite.Code);  // Pick created for twice Quantity as on sales Order.

        // Tear Down: Restore the original value for Location.
        UpdateLocationSetup(false);
    end;

    [Test]
    [HandlerFunctions('ShipmentWithProductionOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure PickHandlingErrorWithProdOrder()
    begin
        // Setup.
        Initialize();
        PickHandlingWithProductionOrder(false, true);  // AlwaysCreatePickLine-FALSE, OutputJournal-TRUE.
    end;

    [Test]
    [HandlerFunctions('ShipmentWithProductionOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure PickUsingProdOrderWithReducedOutputQuantity()
    begin
        // Setup.
        Initialize();
        PickHandlingWithProductionOrder(true, true);  // AlwaysCreatePickLine-TRUE, OutputJournal-TRUE.
    end;

    [Test]
    [HandlerFunctions('ShipmentWithProductionOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure PickUsingProdOrderWithoutOutputJournal()
    begin
        // Setup.
        Initialize();
        PickHandlingWithProductionOrder(true, false);  // AlwaysCreatePickLine-TRUE, OutputJournal-FALSE.
    end;

    local procedure PickHandlingWithProductionOrder(AlwaysCreatePickLine: Boolean; OutputJournal: Boolean)
    var
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Update Location Setup, create Manufacturing Setup. Create Sales Order and post Whse Shipment.
        // Create production Order from sales Order, update Bin on Production Order Line.
        UpdateLocationSetup(AlwaysCreatePickLine);
        CreateManufacturingSetup(RoutingHeader, Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostWarehouseShipmentFromSO(SalesHeader, WarehouseShipmentHeader, Item."No.", Quantity, LocationWhite.Code);  // Value required for the test.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProdOrderLine.Status::Released, "Create Production Order Type"::ItemOrder);
        UpdateProductionOrderLine(ProdOrderLine, Item."No.");
        if OutputJournal then
            ExplodeRoutingAndPostOutputJournal(ProdOrderLine, Quantity / 2);  // Reduce the Output Quantity on Output Journal.

        // Exercise: Create Pick.
        if AlwaysCreatePickLine then
            LibraryWarehouse.CreatePick(WarehouseShipmentHeader)
        else
            asserterror LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the values on Whse Activity Line. Verify the Bin code On Whse Activity Line as blank.
        if AlwaysCreatePickLine then begin
            VerifyWhseActivityLine(WarehouseActivityLine, Quantity, SalesHeader."No.", LocationWhite.Code);
            VerifyBinCode(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LocationWhite.Code, SalesHeader."No.",
              '');
        end else
            Assert.ExpectedError(HandlingError);  // Verify the Nothing To Handle Error.

        // Tear Down: Restore the original value for Location.
        UpdateLocationSetup(false);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWhseShipmentWithReservation()
    begin
        // Setup.
        Initialize();
        PickFromMultipleSources(false);  // Pick From Pick WorkSheet FALSE.
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromPickWorksheetWithReservation()
    begin
        // Setup.
        Initialize();
        PickFromMultipleSources(true);  // Pick From Pick WorkSheet TRUE.
    end;

    local procedure PickFromMultipleSources(PickFromWorkSheet: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item, Update Inventory, create Sales Order with reservation, create Warehouse Shipment.
        CreateItem(Item, '');
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateInventoryUsingWhseJournal(LocationWhite, Item, Quantity);
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", Quantity, LocationWhite.Code);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);

        // Exercise: Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the values on Whse Activity Line.
        VerifyWhseActivityLine(WarehouseActivityLine, Quantity, SalesHeader."No.", LocationWhite.Code);  // Verify the Quantity on the Whse Activity Line.

        // Exercise: Delete Whse Activity Line, create Pick from Pick Worksheet for partial Quantity.
        if PickFromWorkSheet then begin
            DeleteWarehouseActivity(WarehouseActivityLine);
            LocationCode := LocationWhite.Code;  // Assign value to global variable.
            CreatePickFromPickWorksheet(LocationWhite.Code, Quantity / 2);  // Partial Quantity.

            // Verify: Verify the Pick created from Pick Worksheet.
            VerifyWhseActivityLine(WarehouseActivityLine2, Quantity / 2, SalesHeader."No.", LocationWhite.Code);  // Verify the partial Quantity on the Whse Activity Line.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayRegisterWithUpdatedBinOnSource()
    begin
        // Setup.
        Initialize();
        PickUsingMultipleBins(true, false, false);  // Updating Bin On Put away.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickRegisterWithUpdatedBinOnSource()
    begin
        // Setup.
        Initialize();
        PickUsingMultipleBins(false, true, false);  // UpdateBinAndPostWhseShipment set to TRUE.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure MultiplePickCreationWithUpdatedBinOnSource()
    begin
        // Setup.
        Initialize();
        PickUsingMultipleBins(false, true, true);  // MultiplePick set to TRUE.
    end;

    local procedure PickUsingMultipleBins(UpdateBinOnActivityLine: Boolean; UpdateBinAndPostWhseShipment: Boolean; MultiplePicks: Boolean)
    var
        Item: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Decimal;
    begin
        // Setup: Find Bin, create Item, update Item Inventory, create purchase order, create Warehouse Receipt, update Bin Code on Warehouse receipt.
        // Post Warehouse Receipt, update Quantity To Handle on Activity Line, create Sales Order and release it Update Bin on Whse Shipment Line.
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 1);  // Find bin of Index 1.
        CreateItem(Item, '');
        Quantity := LibraryRandom.RandDec(100, 2) + 100;
        UpdateItemInventory(Item."No.", LocationOrange.Code, Bin.Code, Quantity);  // Value required.
        LibraryWarehouse.FindBin(Bin2, LocationOrange.Code, '', 2);  // Find bin of Index 2.
        CreateAndPostWhseReceiptFromPOWithBin(PurchaseHeader, Item."No.", Bin2.Code);
        LibraryWarehouse.FindBin(Bin3, LocationOrange.Code, '', 3);  // Find bin of Index 3.

        if UpdateBinOnActivityLine then begin
            // Exercise: Update Quantity To Handle and Bin on Whse. Activity Line.
            UpdateQuantityToHandleAndBinOnActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, PurchaseHeader."No.", Quantity / 2,
              WarehouseActivityLine."Activity Type"::"Put-away", Bin3.Code);
            UpdateQuantityToHandleAndBinOnActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Quantity / 2,
              WarehouseActivityLine."Activity Type"::"Put-away", Bin3.Code);

            // Verify: Verify the Updated Bin Code on Whse. Activity Line. Verify the registered Quantity On Whse. Activity Line.
            WarehouseActivityLine.TestField("Bin Code", Bin3.Code);
            RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
            VerifyRegisteredWhseActivityLine(WarehouseActivityLine, Quantity / 2);  // Verify the Updated Quantity on Registered Whse Activity Line.
        end;

        if UpdateBinAndPostWhseShipment then begin
            CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", Quantity, LocationOrange.Code);
            CreateAndPostWarehouseShipmentFromSO(SalesHeader2, WarehouseShipmentHeader, Item."No.", Quantity, LocationOrange.Code);  // Value required for the test.
            CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
            LibraryWarehouse.ReopenWhseShipment(WarehouseShipmentHeader);
            UpdateBinOnWhseShipmentLine(SalesHeader."No.", Bin3.Code);

            // Exercise: Create Pick.
            LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
            FindWhseActivityLine(
              WarehouseActivityLine2, WarehouseActivityLine2."Activity Type"::Pick, LocationOrange.Code, SalesHeader."No.",
              WarehouseActivityLine2."Action Type"::Take);
            RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine2."Activity Type"::Pick);
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

            // Verify: Verify the Quantity on registered Pick.
            VerifyRegisteredWhseActivityLine(WarehouseActivityLine2, Quantity);
        end;

        if MultiplePicks then begin
            // Exercise: Create Pick.
            asserterror LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

            // Verify: Verify that Pick is not created.
            Assert.ExpectedError(HandlingError);
        end;
    end;

    [Test]
    [HandlerFunctions('ShipmentWithProductionOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure MultiplePickErrorFromWhseShipmentUsingProdOrder()
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ProdOrderLine: Record "Prod. Order Line";
        Quantity: Decimal;
    begin
        // Setup: Update Location Setup, create Manufacturing Setup. Create Sales Order and post Whse Shipment.
        // Create production Order from sales Order, update Bin on Production Order Line, explode routing and Post Output Journal.
        Initialize();
        UpdateLocationSetup(true);  // Always Create Pick Line as TRUE.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateManufacturingSetup(RoutingHeader, Item);
        CreateAndPostWarehouseShipmentFromSO(SalesHeader, WarehouseShipmentHeader, Item."No.", Quantity, LocationWhite.Code);  // Value required for the test.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProdOrderLine.Status::Released, "Create Production Order Type"::ItemOrder);
        UpdateProductionOrderLine(ProdOrderLine, Item."No.");
        ExplodeRoutingAndPostOutputJournal(ProdOrderLine, Quantity);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Exercise: Create Pick.
        asserterror LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify that Pick is not created.
        Assert.ExpectedError(HandlingError);

        // Tear Down: Restore the original value for Location.
        UpdateLocationSetup(false);
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure DeletePickPartiallyAndRecreateFromWhseWorksheet()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create Item, update Item inventory, create and release Purchase Order, create and post Whse Receipt, create Put Away, create and release Sales Order, create and release Whse Shipment.
        // create Pick and update Quantity on Pick, register and delete it. Create and release Sales Order, create Whse Shipment.
        Initialize();
        CreateItemWithItemTrackingCode(Item, '');  // Creating Item without Item Tracking Code for the test.
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader, LocationWhite.Code, Item."No.");
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndPostWarehouseShipmentFromSO(SalesHeader, WarehouseShipmentHeader, Item."No.", Quantity2, LocationWhite.Code);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);
        UpdateActivityLineAndDeletePartially(WarehouseActivityLine, SalesHeader."No.");
        CreateAndPostWarehouseShipmentFromSO(SalesHeader2, WarehouseShipmentHeader, Item."No.", Quantity2 / 2, LocationWhite.Code);  // Using partial Quantity as on Whse Activity Line.
        LocationCode := LocationWhite.Code;  // Assign value to global variable.

        // Exercise: Create Pick from Pick Worksheet.
        CreatePickFromPickWorksheet(LocationWhite.Code, Quantity2 / 2);  // Partial Quantity.

        // Verify: Verify the values on Whse Activity Line.
        VerifyWhseActivityLine(WarehouseActivityLine2, Quantity2 / 2, SalesHeader2."No.", LocationWhite.Code);  // Verify the updated partial Quantity on the Whse Activity Line.
    end;

    [Test]
    [HandlerFunctions('ShipmentMessageHandler,ItemTrackingPageHandler,ConfirmHandler,SelectEntriesHandler')]
    [Scope('OnPrem')]
    procedure PickFromWhseShipmentWithLotNo()
    begin
        // Setup.
        Initialize();
        PickUsingPickWorksheetWithLotNo(false, false);
    end;

    [Test]
    [HandlerFunctions('ShipmentMessageHandler,ItemTrackingPageHandler,ConfirmHandler,PickSelectionPageHandler,SelectEntriesHandler')]
    [Scope('OnPrem')]
    procedure DeletePickAndRecreateFromPickWorksheetWithLotNo()
    begin
        // Setup.
        Initialize();
        PickUsingPickWorksheetWithLotNo(true, false);  // Delete and recreate Pick using Pick Worksheet.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler,PickSelectionPageHandler,ShipmentMessageHandler,SelectEntriesHandler')]
    [Scope('OnPrem')]
    procedure MultiplePicksErrorWithLotNo()
    begin
        // Setup.
        Initialize();
        PickUsingPickWorksheetWithLotNo(true, true);  // Delete and recreate using Pick Worksheet and recreate from Whse Shipment.
    end;

    local procedure PickUsingPickWorksheetWithLotNo(DeleteAndRecreate: Boolean; MultiplePicks: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // Create Item with Item Tracking Code, create Item Journal Line and assign Lot No and post it. Create and release sales Order.
        // Assign Lot No to Sales Order. Create and release Whse Shipment.
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        CreateTrackedItem(Item, true, false, false, false, false);
        CreateItemJournaLine(Item."No.", LocationYellow.Code, '', Quantity);
        AssignLotNoAndPostItemJournal();

        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity, LocationYellow.Code);
        AssignTrackingForSalesOrder(SalesOrder, SalesHeader."No.");
        LocationCode := LocationYellow.Code;  // Assign value to global variable.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        WarehouseShipmentNo := WarehouseShipmentHeader."No.";  // Assign Global variable for Page Handler.

        // Exercise: Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the values on Whse Activity Lines.
        VerifyMultipleWhseActivityLines(WarehouseActivityLine, Quantity, SalesHeader."No.", LocationYellow.Code);

        if DeleteAndRecreate then begin
            // Exercise: Delete the Whse Activity Line. Create Pick using Pick Worrksheet.
            DeleteWarehouseActivity(WarehouseActivityLine);
            CreatePickFromPickWorksheet(LocationYellow.Code, Quantity / 2);  // Partial Quantity.

            // Verify: Verify the values on Whse Activity Lines.
            VerifyMultipleWhseActivityLines(WarehouseActivityLine2, Quantity / 2, SalesHeader."No.", LocationYellow.Code);
        end;
        if MultiplePicks then begin
            // Exercise: Create Pick from Whse Shipment.
            asserterror LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

            // Verify: Verify that Pick is not created.
            Assert.ExpectedError(HandlingError);
        end;
    end;

    [Test]
    [HandlerFunctions('ShipmentMessageHandler,ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandler,SelectEntriesHandler')]
    [Scope('OnPrem')]
    procedure PickFromWhseShipmentWithSerialNo()
    begin
        // Setup.
        Initialize();
        PickUsingPickWorksheetWithSerialNo(false, false);
    end;

    [Test]
    [HandlerFunctions('ShipmentMessageHandler,ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandler,PickSelectionPageHandler,SelectEntriesHandler')]
    [Scope('OnPrem')]
    procedure DeletePickAndRecreateFromPickWorksheetWithSerialNo()
    begin
        // Setup.
        Initialize();
        PickUsingPickWorksheetWithSerialNo(true, false);  // Delete and recreate Pick using Pick Worksheet.
    end;

    [Test]
    [HandlerFunctions('ShipmentMessageHandler,ItemTrackingPageHandler,QuantityToCreatePageHandler,ConfirmHandler,PickSelectionPageHandler,SelectEntriesHandler')]
    [Scope('OnPrem')]
    procedure MultiplePicksErrorWithSerialNo()
    begin
        // Setup.
        Initialize();
        PickUsingPickWorksheetWithSerialNo(true, true);  // Delete and recreate Pick using Pick Worksheet and recreate from Whse Shipment.
    end;

    local procedure PickUsingPickWorksheetWithSerialNo(DeleteAndRecreate: Boolean; MultiplePicks: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // Create Item with Item Tracking Code, create Item Journal Line and assign Serial No and post it. Create and release Sales Order.
        // Assign Serial No to Sales Order. Create and release Whse Shipment.
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        CreateTrackedItem(Item, false, true, false, false, false);
        CreateItemJournaLine(Item."No.", LocationYellow.Code, '', Quantity);
        AssignSerialNoAndPostItemJournal(Item."No.", LocationYellow.Code);

        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity, LocationYellow.Code);
        AssignTrackingForSalesOrder(SalesOrder, SalesHeader."No.");
        LocationCode := LocationYellow.Code;  // Assign value to global variable.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        WarehouseShipmentNo := WarehouseShipmentHeader."No.";  // Assign Global variable for Page Handler.

        // Exercise: Create Pick from Whse Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the values on Whse Activity Lines. Verify the Serial Tracked Quantities.
        VerifyMultipleWhseActivityLines(WarehouseActivityLine, 1, SalesHeader."No.", LocationYellow.Code);

        if DeleteAndRecreate then begin
            // Exercise: Delete Whse Activity Lines and recreate the Pick using Pick Worksheet.
            DeleteWarehouseActivity(WarehouseActivityLine);
            CreatePickFromPickWorksheet(LocationYellow.Code, Quantity / 2);  // Partial Quantity.

            // Verify: Verify the values on Whse Activity Lines. Verify the Serial Tracked Quantities.
            VerifyMultipleWhseActivityLines(WarehouseActivityLine2, 1, SalesHeader."No.", LocationYellow.Code);
        end;
        if MultiplePicks then begin
            // Exercise: Create Pick from Whse Shipment.
            asserterror LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

            // Verify: Verify that Pick is not created.
            Assert.ExpectedError(HandlingError);
        end;
    end;

    [Test]
    [HandlerFunctions('PutAwayMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayUsingWhseBatchJob()
    begin
        // Setup.
        Initialize();
        CreateInventoryPutAwayPickUsingWhseBatchJob(true, false, false, false);  // Inventory Put-Away TRUE.
    end;

    [Test]
    [HandlerFunctions('PutAwayMessageHandler')]
    [Scope('OnPrem')]
    procedure MultipleInventoryPutAwayUsingWhseBatchJob()
    begin
        // Setup.
        Initialize();
        CreateInventoryPutAwayPickUsingWhseBatchJob(true, true, false, false);  // Multiple Inventory Put-Away TRUE.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,PutAwayWithPickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickUsingWhseBatchJob()
    begin
        // Setup.
        Initialize();
        CreateInventoryPutAwayPickUsingWhseBatchJob(true, false, true, false);  // Inventory Put-Away and Pick with reservation TRUE.
    end;

    [Test]
    [HandlerFunctions('PutAwayWithPickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickUsingWhseBatchJobWithTransferOrder()
    begin
        // Setup.
        Initialize();
        CreateInventoryPutAwayPickUsingWhseBatchJob(true, false, false, true);  // Inventory Put-Away and Pick with Transfer Order TRUE.
    end;

    local procedure CreateInventoryPutAwayPickUsingWhseBatchJob(InventoryPutAway: Boolean; MultipleInventoryPutAway: Boolean; InventoryPickWithReservation: Boolean; InventoryPickWithTransferOrder: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WarehouseActivityLine3: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Create Item, update Item Inventory at the Location, create and release Purchase Order.
        CreateItem(Item, '');
        Quantity := LibraryRandom.RandDec(100, 2) + 100;  // Large value required.
        UpdateItemInventory(Item."No.", LocationYellow2.Code, '', Quantity);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", Quantity, LocationYellow2.Code);

        if InventoryPutAway then begin
            // Exercise: Create Inventory Put-Away.
            LibraryWarehouse.CreateInvtPutPickMovement(
              WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

            // Verify: Verify the values on Whse Activity Line.
            FindWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Put-away", LocationYellow2.Code, PurchaseHeader."No.",
              WarehouseActivityLine."Action Type");
            VerifyInventoryPutAwayPick(WarehouseActivityLine, PurchaseHeader."No.", LocationYellow2.Code, Item."No.", '', Quantity);
        end;

        if MultipleInventoryPutAway then
            // Exercise: Create Inventory Put-Away.
            LibraryWarehouse.CreateInvtPutPickMovement(
            WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // Verify: Verify that Inventory Put-Away is not created in MessageHandler.

        if InventoryPickWithReservation then begin
            CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", Quantity, LocationYellow2.Code);
            // Exercise: Create Inventory Pick.
            LibraryWarehouse.CreateInvtPutPickMovement(
              WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

            // Verify: Verify the values on Whse Activity Line.
            FindWhseActivityLine(
              WarehouseActivityLine2, WarehouseActivityLine2."Activity Type"::"Invt. Pick", LocationYellow2.Code, SalesHeader."No.",
              WarehouseActivityLine2."Action Type");
            VerifyInventoryPutAwayPick(WarehouseActivityLine2, SalesHeader."No.", LocationYellow2.Code, Item."No.", '', Quantity);
        end;

        if InventoryPickWithTransferOrder then begin
            // Create Transfer Order, Sales Order.
            UpdateItemInventory(Item."No.", LocationRed.Code, '', Quantity);
            CreateAndReleaseTransferOrder(LocationYellow2.Code, LocationRed.Code, Item."No.", Quantity);
            CreateAndReleaseSalesOrder(SalesHeader2, Item."No.", Quantity, LocationRed.Code);

            // Exercise: Create Inventory Pick.
            LibraryWarehouse.CreateInvtPutPickMovement(
              WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader2."No.", false, true, false);

            // Verify: Verify the values on Whse Activity Line.
            FindWhseActivityLine(
              WarehouseActivityLine3, WarehouseActivityLine3."Activity Type"::"Invt. Pick", LocationRed.Code, SalesHeader2."No.",
              WarehouseActivityLine3."Action Type");
            VerifyInventoryPutAwayPick(WarehouseActivityLine3, SalesHeader2."No.", LocationRed.Code, Item."No.", '', Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,PutAwayWithPickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickUsingProdOrderWithReservation()
    begin
        // Setup.
        Initialize();
        CreateInventoryPickUsingWhseBatchJobWithProdOrder(false);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,PutAwayWithPickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickUsingProdOrderWithTransferOrder()
    begin
        // Setup.
        Initialize();
        CreateInventoryPickUsingWhseBatchJobWithProdOrder(true);  // Using Transfer Order TRUE.
    end;

    local procedure CreateInventoryPickUsingWhseBatchJobWithProdOrder(UseTransferOrder: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Create Parent and Child Item, Update the Inventory, create and release Purchase Order.
        Initialize();
        CreateItem(Item, '');
        CreateItem(Item2, '');
        LibraryPurchase.CreateVendor(Vendor);
        Quantity := LibraryRandom.RandDec(100, 2) + 100;  // Large value required.
        UpdateItemInventory(Item."No.", LocationYellow2.Code, '', Quantity);  // Value required.
        UpdateItemInventory(Item2."No.", LocationYellow2.Code, '', Quantity);  // Value required.
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", Quantity, LocationYellow2.Code);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", Quantity, LocationYellow2.Code);

        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."No.", Quantity, Item."Base Unit of Measure");
        Item.Find();
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", LocationYellow2.Code, Quantity);

        // Exercise: Create Inventory Pick.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // Verify: Verify the values on Whse Activity Line.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationYellow2.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type");
        VerifyInventoryPutAwayPick(WarehouseActivityLine, ProductionOrder."No.", LocationYellow2.Code, Item2."No.", '', Quantity);

        if UseTransferOrder then begin
            CreateAndReleaseTransferOrder(LocationYellow2.Code, LocationRed.Code, Item."No.", Quantity);
            CreateAndReleaseSalesOrder(SalesHeader2, Item."No.", Quantity, LocationRed.Code);

            // Exercise: Create Inventory Pick.
            LibraryWarehouse.CreateInvtPutPickMovement(
              WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader2."No.", false, true, false);

            // Verify: Verify that Inventory Pick is not created in MessageHandler.
        end;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ReceiptWithPickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure AvailableInventoryPickFromSalesOrder()
    begin
        // Setup.
        Initialize();
        InventoryPickWithSalesOrder(false, false);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ReceiptWithPickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure MultipleInventoryPickFromSalesOrder()
    begin
        // Setup.
        Initialize();
        InventoryPickWithSalesOrder(true, false);  // Error creating multiple Inventory Picks.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ReceiptWithPickActivitiesMessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPickWithUpdatedActivityLine()
    begin
        // Setup.
        Initialize();
        InventoryPickWithSalesOrder(true, true);  // Update and Post Inventory Pick.
    end;

    local procedure InventoryPickWithSalesOrder(MultipleInventoryPick: Boolean; UpdateAndPost: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Create Item, create and release Purchase Order, create and post Whse Receipt. Create and release a Sales Order with reservations.
        // Create another Sales Order without reservations for the same Location.
        CreateItem(Item, '');
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader, LocationGreen2.Code, Item."No.");
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", Quantity2 / 4, LocationGreen2.Code);  // Value required.
        CreateAndReleaseSalesOrder(SalesHeader2, Item."No.", Quantity2, LocationGreen2.Code);

        // Exercise: Create Inventory Pick.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Verify: Verify the Inventory Pick created.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationGreen2.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type");
        VerifyInventoryPutAwayPick(WarehouseActivityLine, SalesHeader."No.", LocationGreen2.Code, Item."No.", '', Quantity2 - Quantity2 / 2);

        if MultipleInventoryPick then
            // Exercise: Create Inventory Pick.
            LibraryWarehouse.CreateInvtPutPickMovement(
            WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader2."No.", false, true, false);

        // Verify: Verify that Pick is not created in MessageHandler.

        if UpdateAndPost then begin
            // Exercise: Update Quantity on Inventory Pick and Post it.
            UpdateQuantityOnActivityLine(WarehouseActivityLine, Quantity2 / 2);  // Partial Quantity.
            PostInventoryPick(SalesHeader."No.");

            // Verify: Verify the Posted Inventory Pick Line. Expiration Date is blank.
            VerifyPostedInventorytPickLine(SalesHeader."No.", LocationGreen2.Code, Item."No.", 0D, '')
        end;
    end;

    [Test]
    [HandlerFunctions('PutAwayWithPickActivitiesMessageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure AvailableInventoryPickWithReservation()
    begin
        // Setup.
        Initialize();
        CreateInventoryPickWithReservation(false);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,PutAwayWithPickActivitiesTwiceMessageHandler')]
    [Scope('OnPrem')]
    procedure AvailableInventoryPickWithReservationAfterCreateInventoryPick()
    begin
        // Setup.
        Initialize();
        CreateInventoryPickWithReservation(true);  // Available Inventory Pick after reservation.
    end;

    local procedure CreateInventoryPickWithReservation(ReserveAfterPick: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Create Item, update Item Inventory at the Location, create and release Purchase Order. Create Inventory Put-Away.
        // Create two Sales Orders with reservations.
        CreateItem(Item, '');
        Quantity := LibraryRandom.RandDec(100, 2) + 100;  // Large value required.
        UpdateItemInventory(Item."No.", LocationYellow2.Code, '', Quantity);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", Quantity, LocationYellow2.Code);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", Quantity / 2, LocationYellow2.Code);
        CreateAndReleaseSalesOrderWithReservation(SalesHeader2, Item."No.", Quantity / 4, LocationYellow2.Code);  // Value required.

        // Exercise: Create Inventory Pick.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Verify: Verify the Inventory Pick. Available Qty to Pick is verified with reservation.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationYellow2.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type");
        VerifyInventoryPutAwayPick(
          WarehouseActivityLine, SalesHeader."No.", LocationYellow2.Code, Item."No.", '', Quantity / 2 + Quantity / 4);

        if ReserveAfterPick then begin
            // Exercise: Create Inventory Pick.
            LibraryWarehouse.CreateInvtPutPickMovement(
              WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader2."No.", false, true, false);

            // Verify: Verify the Inventory Pick Line. Available Qty to Pick is verified with reservation.
            FindWhseActivityLine(
              WarehouseActivityLine2, WarehouseActivityLine2."Activity Type"::"Invt. Pick", LocationYellow2.Code, SalesHeader2."No.",
              WarehouseActivityLine2."Action Type");
            VerifyInventoryPutAwayPick(
              WarehouseActivityLine2, SalesHeader2."No.", LocationYellow2.Code, Item."No.", '', Quantity / 2 - Quantity / 4);
        end;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWhseShipmentWithReservationAndPartialDelete()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create Item, create and release Purchase Order, create Put Away, create and release Sales Order, create and release Whse Shipment.
        // Update Quantity on Pick, register and delete it. Create and release Sales Order, create Whse Shipment.
        Initialize();
        CreateItem(Item, '');
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader, LocationWhite.Code, Item."No.");
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", Quantity2 / 2, LocationWhite.Code);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        UpdateActivityLineAndDeletePartially(WarehouseActivityLine, SalesHeader."No.");
        CreateAndPostWarehouseShipmentFromSO(SalesHeader2, WarehouseShipmentHeader, Item."No.", Quantity2, LocationWhite.Code);  // Using partial Quantity as on Whse Activity Line.

        // Exercise: Create Pick from Whse Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the values on Whse Activity Line. Available Quantity to Pick and Ship is verified.
        VerifyWhseActivityLine(WarehouseActivityLine2, Quantity2 - Quantity2 / 2, SalesHeader2."No.", LocationWhite.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationWithMultipleBins()
    var
        Bin: Record Bin;
        LocationCard: TestPage "Location Card";
    begin
        // Setup: Create Multiple Bins for a Location and create Bin for another Location.
        Initialize();
        LibraryWarehouse.CreateBin(
          Bin, LocationSilver.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');

        // Exercise: Enter Bins present on Location Silver at Open Shop Floor Bin Code, To-Production Bin Code and From-Production Bin Code.
        SetBinOnLocationCard(LocationCard, LocationSilver.Code, Bin.Code);

        // Verify: Verify Bin on Location.
        VerifyBinOnLocationCard(LocationSilver.Code, Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationBinErrorWithChangedBin()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        LocationCard: TestPage "Location Card";
    begin
        // Setup: Create Multiple Bins for a Location and create Bin for another Location.
        Initialize();
        LibraryWarehouse.CreateBin(
          Bin, LocationSilver.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        LibraryWarehouse.CreateBin(
          Bin2, LocationOrange2.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin2.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');

        // Exercise: Set Bin on Open Shop Floor Bin Code, To-Production Bin Code and From-Production Bin Code of Location which is not at the Location .
        asserterror SetBinOnLocationCard(LocationCard, LocationSilver.Code, Bin2.Code);

        // Verify: Verify that Bin not present in Location cannot be populated on Open Shop Floor Bin Code,To-Production Bin Code and From-Production Bin Code of Location.
        Assert.ExpectedError(ValidationError);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LocationWithoutBinMandatoryWithDisabledBinCodes()
    var
        Bin: Record Bin;
        LocationCard: TestPage "Location Card";
        BinMandatory: Boolean;
    begin
        // Setup: Create multiple Bins for a Location and update Location.
        Initialize();
        LibraryWarehouse.CreateBin(
          Bin, LocationOrange2.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        OpenLocationCard(LocationCard, LocationOrange2.Code);

        // Exercise: Update Bin Mandatory false on Location.
        BinMandatory := LocationCard."Bin Mandatory".AsBoolean();
        LocationCard."Bin Mandatory".SetValue(false);

        // Verify: Verify Open Shop Floor Bin Code, To Production Bin Code and From Production Bin Code are disabled.
        Assert.IsFalse(LocationCard."Open Shop Floor Bin Code".Enabled(), EditableError);
        Assert.IsFalse(LocationCard."To-Production Bin Code".Enabled(), EditableError);
        Assert.IsFalse(LocationCard."From-Production Bin Code".Enabled(), EditableError);
        LocationCard."Bin Mandatory".SetValue(BinMandatory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithMultipleBins()
    var
        Bin: Record Bin;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // Setup: Create multiple Bins for a Location, create Bin for another Location and create Work center with Location.
        Initialize();
        LibraryWarehouse.CreateBin(
          Bin, LocationSilver.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        CreateWorkCenterSetup(WorkCenter);
        UpdateLocationOnWorkCenter(WorkCenter, LocationSilver.Code);

        // Exercise: Enter Bins present on Location at Open Shop Floor Bin Code, To Production Bin Code and From-Production Bin Code of Work Center.
        SetBinOnWorkCenterCard(WorkCenterCard, LocationSilver.Code, Bin.Code);

        // Verify: Verify Bin on Work Center.
        VerifyBinOnWorkCenterCard(LocationSilver.Code, Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterBinErrorWithChangedBin()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // Setup: Create multiple Bins for a Location, create Bin for another Location and create Work center with Location.
        Initialize();
        LibraryWarehouse.CreateBin(
          Bin, LocationSilver.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        LibraryWarehouse.CreateBin(
          Bin2, LocationOrange2.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin2.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        CreateWorkCenterSetup(WorkCenter);
        UpdateLocationOnWorkCenter(WorkCenter, LocationSilver.Code);

        // Exercise: Set Bin on Work Center which is not at the Location of Work Center.
        asserterror SetBinOnWorkCenterCard(WorkCenterCard, LocationSilver.Code, Bin2.Code);

        // Verify: Verify that Bin not present in Location cannot be populated on Open Shop Floor Bin Code, To-Production Bin Code and From-Production Bin Code of Work Center.
        Assert.ExpectedError(ValidationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithBinMandatoryErrorOnChangeLocation()
    var
        Bin: Record Bin;
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create multiple Bins for Location and create Work Center with that Location.
        Initialize();
        LibraryWarehouse.CreateBin(
          Bin, LocationOrange2.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        CreateWorkCenterSetup(WorkCenter);
        UpdateLocationOnWorkCenter(WorkCenter, LocationOrange2.Code);

        // Exercise: Update Location for Bin Mandatory False.
        asserterror UpdateLocationForBinMandatory(LocationOrange2, false);  // Bin Mandatory FALSE.

        // Verify: Verify Error for Bin Mandatory False, if the location is used by Work Center.
        Assert.ExpectedError(StrSubstNo(WorkCenterError, LocationOrange2.Code, WorkCenter."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterAndLocationUneditableOnMachineCenter()
    var
        Bin: Record Bin;
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        MachineCenterCard: TestPage "Machine Center Card";
        MachineCenterCard2: TestPage "Machine Center Card";
    begin
        // Setup: Create multiple Bins for a Location, create Bin for another Location, create Work Center With Location  and create Machine Center for that Work center.
        Initialize();

        CreateWorkAndMachineCenter(WorkCenter, Bin, MachineCenter);

        // Exercise: Enter Bins present on Location at Open Shop Floor Bin Code, To Production Bin Code and From-Production Bin Code of Work Center.
        OpenMachineCenterCard(MachineCenterCard, WorkCenter."No.");
        SetBinOnMachineCenterCard(MachineCenterCard2, WorkCenter."No.", Bin.Code);

        // Verify: Verify Location Code is disabled on Machine Center and Bin on Machine Center.
        Assert.IsFalse(MachineCenterCard."Location Code".Editable(), EditableError);
        VerifyBinOnMachineCenterCard(WorkCenter."No.", Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MachineCenterBinErrorWithChangedBin()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        MachineCenterCard: TestPage "Machine Center Card";
    begin
        // Setup: Create multiple Bins for a Location, create Bin for another Location, create Work Center With Location  and create Machine Center for that Work center.
        Initialize();
        LibraryWarehouse.CreateBin(
          Bin, LocationSilver.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        LibraryWarehouse.CreateBin(
          Bin2, LocationOrange2.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin2.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        CreateWorkCenterSetup(WorkCenter);
        UpdateLocationOnWorkCenter(WorkCenter, LocationSilver.Code);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandInt(10));

        // Exercise: Set Bin on Machine Center which is not at the location of Work Center.
        asserterror SetBinOnMachineCenterCard(MachineCenterCard, WorkCenter."No.", Bin2.Code);

        // Verify: Verify that Bin not present in Location cannot be populated on Open Shop Floor Bin Code,To-Production Bin Code and From-Production Bin Code of Machine Center.
        Assert.ExpectedError(ValidationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithouLocationAndLocationOnMachineCenterWithBins()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        MachineCenterCard: TestPage "Machine Center Card";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // Setup: Create Work Center without Location and create Machine Center for that Machine Center.
        Initialize();
        CreateWorkCenterSetup(WorkCenter);
        UpdateLocationOnWorkCenter(WorkCenter, '');
        OpenWorkCenterCard(WorkCenterCard, LocationSilver.Code);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandInt(10));

        // Exercise: Open Machine Center Card.
        OpenMachineCenterCard(MachineCenterCard, WorkCenter."No.");

        // Verify: Location Code is empty and uneditable. Open Shop Floor Bin Code, To Production Bin Code and From Production Bin Code is disabled.
        MachineCenterCard."Location Code".AssertEquals('');
        Assert.IsFalse(MachineCenterCard."Location Code".Editable(), EditableError);
        Assert.IsFalse(MachineCenterCard."Open Shop Floor Bin Code".Enabled(), EnabledError);
        Assert.IsFalse(MachineCenterCard."To-Production Bin Code".Enabled(), EnabledError);
        Assert.IsFalse(MachineCenterCard."From-Production Bin Code".Enabled(), EnabledError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterChangeLocationWithoutBin()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        // Setup: Create Work Center With Location and create Machine Center of that Work Center not having Bin Code on it.
        Initialize();
        CreateWorkCenterSetup(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandInt(10));

        // Exercise: Update Work Center on new Location.
        UpdateLocationOnWorkCenter(WorkCenter, LocationOrange2.Code);

        // Verify: Verify Location is updated on Work Center.
        VerifyLocationOnWorkCenter(WorkCenter."No.", LocationOrange2.Code);
    end;

    [Test]
    [HandlerFunctions('ChangeLocationConfirmHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterChangeLocationWithBinError()
    var
        Bin: Record Bin;
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        // Setup: Create Bin for a Location, create Work Center With Location  and create Machine Center of that Work Center having Bin Code on it.
        Initialize();

        CreateWorkAndMachineCenter(WorkCenter, Bin, MachineCenter);
        MachineCenter.Validate("To-Production Bin Code", Bin.Code);
        MachineCenter.Modify(true);

        // Exercise: Update Work Center on new Location.
        asserterror UpdateLocationOnWorkCenter(WorkCenter, LocationOrange.Code);

        // Verify: Bin error on rejectng the Change Location Confirm Handler.
        Assert.ExpectedTestFieldError(MachineCenter.FieldCaption("To-Production Bin Code"), '''');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure QuantityOnItemLedgerEntriesWhenPickAccordingToFEFOTrue()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
    begin
        // Verify Quantity on Item Ledger Entry when Inventory Activity Posted with Expiration Date on Item Tracking Lines.

        // Setup: Create LocationCode,Item with tracking Code and Purchase Document with Inventory Put away / Pick away.
        Initialize();
        CreateTrackedItem(Item, true, false, false, true, true);
        CreateBinContent(Bin, Item."No.", Item."Base Unit of Measure");
        Quantity := CreatePurchaseDocumentWithItemTrackingLines(PurchaseHeader, Item."No.", Bin."Location Code");
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // Exercise: Auto fill the the Quantity on Inventory Activity and Post.
        AutoFillQuantityAndPostInventoryActivity(Bin."Location Code");

        // Verify: Verify The Quantity on Item Ledger Entry.
        VerifyItemLedgerEntry(Item."No.", Bin."Location Code", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,SelectEntriesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure QuantityOnInventoryActivityLinesWhenPickAccordingToFEFOTrue()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Verify Quantity WareHouse Inventory Activity Lines when Sales Order created with Inventory Put away / Pick away.

        // Setup: Create LocationCode,Item with tracking Code and Purchase Document with Inventory Put away / Pick away.
        Initialize();
        CreateTrackedItem(Item, true, false, false, true, true);
        CreateBinContent(Bin, Item."No.", Item."Base Unit of Measure");
        CreatePurchaseDocumentWithItemTrackingLines(PurchaseHeader, Item."No.", Bin."Location Code");
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        AutoFillQuantityAndPostInventoryActivity(Bin."Location Code");
        CreateSalesOrderWithItemTrackingLines(SalesHeader, SalesLine, Item."No.", Bin."Location Code");

        // Exercise: Create Sales Order with Inventory Put away / Pick away.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // Verify: Verify The Quantity on WareHouse Inventory Activity Lines.
        SalesLine.TestField(Quantity, GetQuantityFromWareHouseInventoryActivityLines(Bin."Location Code", Item."No.", SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldUseAsInTransitInLocationCardPageIsEditableWhenCreatingNewLocation()
    var
        LocationCard: TestPage "Location Card";
    begin
        // [FEATURE] [Locations]
        // [SCENARIO] Field "Use As In-Transit" in Location Card Page should be editable when creating new Location

        // [WHEN] Create new Location
        LocationCard.OpenNew();

        // [THEN] Field "Use As In-Transit" on Location Card Page is editable
        Assert.IsTrue(LocationCard."Use As In-Transit".Editable(), UseAsInTransitEditableErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure LotNoAndExpirationDateFilledInWhseActivityLineAfterPartialPost()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse] [Tracking] [FEFO] [Pick] [Pick Worksheet]
        // [SCENARIO 362753]

        Initialize();

        // [GIVEN] Warehouse location with FEFO enabled
        CreateFullWhseLocationWithFEFO(Location);

        // [GIVEN] Item "I" with tracking by Lot No.
        CreateTrackedItem(Item, true, false, false, true, true);

        // [GIVEN] Receive "X" pieces of item "I" with lot no. and expiration date
        LibraryVariableStorage.Enqueue(TrackingAction::LotNo);
        Quantity := CreatePurchaseDocumentWithItemTrackingLines(PurchaseHeader, Item."No.", Location.Code);
        CreateAndPostWhseReceiptAndRegisterPutAwayFromPO(PurchaseHeader);

        // [GIVEN] Create sales order for item "I"
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity, Location.Code);
        // [GIVEN] Create warehouse shipment from sales order
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        WarehouseShipmentNo := WarehouseShipmentHeader."No.";
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [GIVEN] Open pick worksheet and create a new pick from whse. shipment. Item "I", quantity = X / 2
        LocationCode := Location.Code;
        CreatePickFromPickWorksheet(Location.Code, Quantity / 2);
        // [GIVEN] Register pick
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [WHEN] Create a new pick from pick worksheet for the remaining quantity of item "I"
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst();
        UpdateQuantityOnWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetLine."Qty. Outstanding");
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name,
          Location.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        // [THEN] Lot No. and expiration date on pick lines are not empty
        VerifyLotAndExpirationDateOnWhseActivityLines(SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingPageHandler,ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickLotNoWithReservationsUsingFEFO()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // [FEATURE] [Reservation] [FEFO] [Warehouse Pick]
        // [SCENARIO 364373] When shipping Sales Order "SO", using FEFO, Lot No should be assigned after Pick, Quantity reserved fully, including reservation for "SO".

        // [GIVEN] Warehouse location with FEFO enabled, Lot tracked Item available on stock of quantity "Q"
        Initialize();

        LibraryWarehouse.FindBin(Bin, LocationSilver3.Code, '', 2); // Find Bin of Index 2.
        LocationSilver3.Validate("Shipment Bin Code", Bin.Code);
        LocationSilver3.Modify();

        CreateTrackedItem(Item, true, false, false, false, false);
        Quantity := LibraryRandom.RandIntInRange(10, 100);
        LibraryWarehouse.FindBin(Bin, LocationSilver3.Code, '', 1); // Find Bin of Index 1.
        CreateItemJournaLine(Item."No.", LocationSilver3.Code, Bin.Code, 2 * Quantity);
        AssignLotNoAndPostItemJournal();
        LotNo := GetLotNoFromItemEntry(Item."No.");

        // [GIVEN] Create and release Sales Order "SO1" of Quantity = "Q" / 2, fully reserve.
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity, LocationSilver3.Code);
        ReservationFromSalesOrder(SalesHeader."No.");

        // [GIVEN] Create and release Sales Order "SO2" of Quantity = "Q" / 2, fully reserve.
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity, LocationSilver3.Code);
        ReservationFromSalesOrder(SalesHeader."No.");

        // [GIVEN] Create and release warehouse shipment from sales order "SO2"
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        WarehouseShipmentNo := WarehouseShipmentHeader."No.";
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [WHEN] Create Pick from warehouse shipment
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        // [THEN] Quantity "Q" / 2 picked, Lot No filled in Pick lines.
        VerifyWhseActivityLotNo(LocationSilver3.Code, Item."No.", Quantity, LotNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PickItemWithPickedLotUsingFEFO()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeaderNo: array[2] of Code[20];
        LotNo: Code[50];
        PartQty: Decimal;
        SmallQty: Decimal;
    begin
        // [FEATURE] [FEFO] [Warehouse Pick] [Lot Tracked Item]
        // [SCENARIO 372295] Pick should contain Lot No for Sales Order Line if stock available and there are Lots partially picked.

        // [GIVEN] Warehouse location with FEFO enabled, Lot tracked Item available on stock: Lot "XL", quantity 200, Lot "L" of quantity 100
        Initialize();

        LibraryWarehouse.FindBin(Bin, LocationSilver3.Code, '', 3); // Find Bin of Index 3.
        LocationSilver3.Validate("Shipment Bin Code", Bin.Code);
        LocationSilver3.Modify();

        CreateTrackedItem(Item, true, false, false, false, false);
        PartQty := LibraryRandom.RandIntInRange(10, 50);
        LibraryWarehouse.FindBin(Bin, LocationSilver3.Code, '', 1); // Find Bin of Index 1.
        CreateItemJournaLine(Item."No.", LocationSilver3.Code, Bin.Code, 4 * PartQty);
        AssignLotNoExpirationAndPostItemJournal(Item."No.", CalcDate('<+5Y>', WorkDate()));

        LibraryWarehouse.FindBin(Bin, LocationSilver3.Code, '', 2); // Find Bin of Index 2.
        CreateItemJournaLine(Item."No.", LocationSilver3.Code, Bin.Code, 2 * PartQty);
        AssignLotNoExpirationAndPostItemJournal(Item."No.", CalcDate('<+5Y+1D>', WorkDate()));
        LotNo := GetLotNoFromItemEntry(Item."No.");

        // [GIVEN] Create Sales Order "SO1" for Item of quantity 150, create Warehouse Shipment and Pick.
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", 3 * PartQty, LocationSilver3.Code);
        SalesHeaderNo[1] := SalesHeader."No.";
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeaderNo[1]);
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentHeader."No.");

        // [GIVEN] Create Sales Order "SO2" for Item with two lines: first line Quantity = 50, second line Quantity = 100.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LocationSilver3.Code, PartQty);
        SalesHeaderNo[2] := SalesHeader."No.";
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2 * PartQty);
        SalesLine.Validate("Location Code", LocationSilver3.Code);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Warehouse Shipment and Pick.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeaderNo[2]);
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentHeader."No.");
        // [GIVEN] Open  Pick for "SO1", set "Qty. to Handle" to 100, register Pick.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationSilver3.Code, SalesHeaderNo[1], WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Validate("Qty. to Handle", 2 * PartQty);
        WarehouseActivityLine.Modify(true);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationSilver3.Code, SalesHeaderNo[1], WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.Validate("Qty. to Handle", 2 * PartQty);
        WarehouseActivityLine.Modify(true);
        RegisterWarehouseActivity(SalesHeaderNo[1], WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Open Pick for "SO2", set first line "Qty. to Handle" to 10, set second line "Qty. to Handle" to 0, register Pick.
        Clear(WarehouseActivityLine);
        SmallQty := LibraryRandom.RandIntInRange(5, 10);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationSilver3.Code, SalesHeaderNo[2], WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Validate("Qty. to Handle", SmallQty);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Qty. to Handle", 0);
        WarehouseActivityLine.Modify(true);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationSilver3.Code, SalesHeaderNo[2], WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.Validate("Qty. to Handle", SmallQty);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Qty. to Handle", 0);
        WarehouseActivityLine.Modify(true);
        RegisterWarehouseActivity(SalesHeaderNo[2], WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Delete Pick for "SO2".
        DeleteWarehouseActivity(WarehouseActivityLine);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeaderNo[2]);

        // [WHEN] Create Pick for "SO2".
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentHeader."No.");

        // [THEN] Created Pick contains Lot "L" of Quantity 100 for second Sales Order Line.
        Clear(WarehouseActivityLine);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationSilver3.Code, SalesHeaderNo[2], WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField(Quantity, 2 * PartQty);
        WarehouseActivityLine.TestField("Lot No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PickItemWithShippedLotUsingFEFO()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeaderNo: Code[20];
        LotNo: Code[50];
        PartQty: Decimal;
    begin
        // [FEATURE] [FEFO] [Warehouse Pick] [Lot Tracked Item]
        // [SCENARIO 372295] Pick should contain Lot No for Sales Order Line if stock available and there are Lots partially picked and shipped.

        // [GIVEN] Warehouse location with FEFO enabled, Lot tracked Item available on stock: Lot "L", quantity 200
        Initialize();

        LibraryWarehouse.FindBin(Bin, LocationSilver3.Code, '', 3); // Find Bin of Index 3.
        LocationSilver3.Validate("Shipment Bin Code", Bin.Code);
        LocationSilver3.Modify();

        CreateTrackedItem(Item, true, false, false, false, false);
        PartQty := LibraryRandom.RandIntInRange(10, 50);
        LibraryWarehouse.FindBin(Bin, LocationSilver3.Code, '', 1); // Find Bin of Index 1.
        CreateItemJournaLine(Item."No.", LocationSilver3.Code, Bin.Code, 2 * PartQty);
        AssignLotNoExpirationAndPostItemJournal(Item."No.", CalcDate('<+5Y>', WorkDate()));
        LotNo := GetLotNoFromItemEntry(Item."No.");

        // [GIVEN] Create Sales Order "SO" for Item of quantity 200, create Warehouse Shipment and Pick.
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", 2 * PartQty, LocationSilver3.Code);
        SalesHeaderNo := SalesHeader."No.";
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeaderNo);
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentHeader."No.");
        // [GIVEN] Open  Pick for "SO", set "Qty. to Handle" to 100, register Pick, ship from Warehouse Shipment, then delete Pick.
        UpdateQuantityToHandleOnActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, LocationSilver3.Code, SalesHeaderNo, PartQty);
        UpdateQuantityToHandleOnActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, LocationSilver3.Code, SalesHeaderNo, PartQty);
        RegisterWarehouseActivity(SalesHeaderNo, WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        DeleteWarehouseActivity(WarehouseActivityLine);

        // [WHEN] Create Pick for "SO".
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentHeader."No.");

        // [THEN] Created Pick contains Lot "L" of Quantity 100.
        Clear(WarehouseActivityLine);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationSilver3.Code, SalesHeaderNo, WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField(Quantity, PartQty);
        WarehouseActivityLine.TestField("Lot No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler,ConfirmHandler2')]
    [Scope('OnPrem')]
    procedure InventoryMovementTwoItemsWithSameLotNo()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Lot] [Internal Movement] [Inventory Movement]
        // [SCENARIO] Can register Inventory Movement from Internal Movement when two Items have the same "Lot No" code.

        // [GIVEN] Two Items with Lot specific tracking, including warehouse tracking, both on inventory, "Lot No." codes are equal.
        Initialize();
        CreateTrackedItem(Item, true, false, false, false, false);
        Qty := LibraryRandom.RandIntInRange(5, 10);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        CreateLotTrackedItemJournalLine(
          ItemJournalLine, Item."No.", '', LocationSilver.Code, Bin.Code, WorkDate(), LibraryUtility.GenerateGUID(), Qty);

        CreateItemWithItemTrackingCode(Item2, Item."Item Tracking Code");
        LibraryWarehouse.FindBin(Bin2, LocationSilver.Code, '', 2);  // Find Bin of Index 2.
        CreateLotTrackedItemJournalLine(
          ItemJournalLine, Item2."No.", '', LocationSilver.Code, Bin.Code, WorkDate(), LibraryUtility.GenerateGUID(), Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Internal Movement with two items, create Inventoty Movement from Internal Movement.
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, LocationSilver.Code, Bin2.Code);
        LibraryWarehouse.GetBinContentInternalMovement(
          InternalMovementHeader, LocationSilver.Code, StrSubstNo('%1|%2', Item."No.", Item2."No."), Bin.Code);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.SetRange("Location Code", LocationSilver.Code);
        WarehouseActivityLine.SetFilter("Item No.", '%1|%2', Item."No.", Item2."No.");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        // [WHEN] Register Inventory Movement
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Invt. Movement");
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        // [THEN] Registered successfully
        RegisteredInvtMovementLine.SetRange("Location Code", LocationSilver.Code);
        RegisteredInvtMovementLine.SetRange("Item No.", Item."No.");
        RegisteredInvtMovementLine.FindFirst();
        RegisteredInvtMovementLine.TestField(Quantity, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2')]
    [Scope('OnPrem')]
    procedure CreatePutAwayFromPostedWhseReceiptDoesNotCombineLotNo()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        I: Integer;
        LotNo: array[3] of Code[20];
    begin
        // [FEATURE] [Warehouse] [Item Tracking] [Put-Away]
        // [SCENARIO] Put-away created from a posted warehouse receipt is not combined with other receipts for the same lot no.

        Initialize();

        // [GIVEN] Item "I" with Lot No. tracking
        CreateTrackedItem(Item, true, false, false, false, false);
        // [GIVEN] Location with put-away worksheet setup
        CreateLocationForPutAwayWorksheet(Location);

        for I := 1 to ArrayLen(LotNo) do
            LotNo[I] := LibraryUtility.GenerateGUID();

        // [GIVEN] Post 1st warehouse receipt with 2 pcs of item "I": 1 - "LotA" and 1 - "LotB"
        PostPurchaseReceiptWithItemTracking(Item, LotNo, Location.Code);
        // [GIVEN] Post 2nd warehouse receipt with 2 pcs of item "I" and the same tracking lines "LotA" and "LotB"
        PostPurchaseReceiptWithItemTracking(Item, LotNo, Location.Code);

        // [WHEN] Create warehouse put-away from the first posted receipt
        CreatePutAway(Item."No.");

        // [THEN] Put-away document created containing 2 activity lines for LotA, and 2 lines for LotB
        for I := 1 to ArrayLen(LotNo) do begin
            WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
            WarehouseActivityLine.SetRange("Item No.", Item."No.");
            WarehouseActivityLine.SetRange("Lot No.", LotNo[I]);
            Assert.AreEqual(2, WarehouseActivityLine.Count, StrSubstNo(WrongNoOfWhseActivityLinesErr, 2, LotNo[I]));
        end;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,PickNotCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromSalesOrderWithShippingAdviceComplete()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Inventory Pick] [Shipping Advice]
        // [SCENARIO 377991] Inventory Pick should not be created if Quantity is not fully sufficient with Shipping Advice Complete
        Initialize();

        // [GIVEN] Sales Order for Item with Shipping Advice = "Complete", Quantity = "X"
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndReleaseSalesOrderWithShippingAdvice(
          SalesHeader, Item."No.", Quantity + 1, LocationYellow2.Code, SalesHeader."Shipping Advice"::Complete);

        // [GIVEN] Purchase Order with Reserved Quantity against Saless Order, Quantity = "X" - 1
        CreateAndReleasePurchaseOrderWithReservation(PurchaseHeader, Item."No.", Quantity, LocationYellow2.Code, WorkDate());

        // [GIVEN] Positive Adjustment for Item
        UpdateItemInventory(Item."No.", LocationYellow2.Code, '', Quantity);

        // [WHEN] Create Inventory Pick from Sales Order
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // [THEN] Message "Nothing to handle" is thrown
        // Verify in PickNotCreatedMessageHandler
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,PickCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromSalesOrderWithShippingAdvicePartial()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PickQty: Decimal;
        Quantity: Decimal;
    begin
        // [FEATURE] [Inventory Pick] [Shipping Advice]
        // [SCENARIO 377991] Inventory Pick should be created if Quantity is not fully sufficient with Shipping Advice Partial
        Initialize();

        // [GIVEN] Sales Order for Item with Shipping Advice = "Partial", Quantity = "X"
        PickQty := LibraryRandom.RandInt(10);
        Quantity := LibraryRandom.RandInt(10);
        LibraryInventory.CreateItem(Item);
        CreateAndReleaseSalesOrderWithShippingAdvice(
          SalesHeader, Item."No.", Quantity + PickQty, LocationYellow2.Code, SalesHeader."Shipping Advice"::Partial);

        // [GIVEN] Purchase Order with Reserved Quantity against Saless Order, Quantity = "X" - "Y"
        CreateAndReleasePurchaseOrderWithReservation(PurchaseHeader, Item."No.", Quantity, LocationYellow2.Code, WorkDate());

        // [GIVEN] Positive Adjustment for Item "Y"
        UpdateItemInventory(Item."No.", LocationYellow2.Code, '', PickQty);

        // [WHEN] Create Inventory Pick from Sales Order
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // [THEN] Pick is created with Quantity = "Y"
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationYellow2.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type");
        Assert.AreEqual(PickQty, WarehouseActivityLine.Quantity, StrSubstNo(QuantityError, PickQty, WarehouseActivityLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2,ConfirmHandler2')]
    [Scope('OnPrem')]
    procedure PickItemWithReservedAndBlockedLot()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        LotNos: array[3] of Code[20];
        NoOfBins: Integer;
        QuantityPerLotPerBin: Decimal;
    begin
        // [FEATURE] [Sales Order] [Pick] [Item Tracking]
        // [SCENARIO 379663] Pick created from Sales Shipment should contain all available required quantity excluding reserved and blocked Lot.
        Initialize();

        // [GIVEN] Lot-tracked Item.
        // [GIVEN] Full WMS Location.
        // [GIVEN] Posted Purchase Receipt with three lots "L1", "L2", "L3".
        // [GIVEN] Registered Put-away with lines evenly split by lots and bins "B1", "B2", "B3".
        // [GIVEN] Sales Order with Item Tracking for Lots "L1", "L2" and "L3".
        // [GIVEN] Warehouse Shipment for Sales Order.
        QuantityPerLotPerBin := LibraryRandom.RandInt(10);
        PrepareInventoryAndTrackedSalesDocumentForPick(
          WarehouseShipmentHeader, LocationCode, ItemNo, LotNos, NoOfBins, QuantityPerLotPerBin);

        // [GIVEN] Lot "L1" is reserved.
        SetLotReserved(ItemNo, LocationCode, LotNos, 1, ArrayLen(LotNos) * QuantityPerLotPerBin);

        // [GIVEN] Lot "L1" is blocked.
        SetLotBlocked(ItemNo, LotNos, 1);

        // [WHEN] Create Pick for the Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        // [THEN] Pick does not contain Lot "L1".
        // [THEN] Pick contains purchased quantity of Lots "L2" and "L3" in Bins "B1", "B2", "B3".
        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LotNos[1], '');
        Assert.RecordIsEmpty(WarehouseActivityLine);

        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, StrSubstNo('<>%1', LotNos[1]), '');
        WarehouseActivityLine.CalcSums(Quantity);
        Assert.AreEqual((ArrayLen(LotNos) - 1) * NoOfBins * QuantityPerLotPerBin, WarehouseActivityLine.Quantity, QtyInPickErr); // two lots in three bins
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2,ConfirmHandler2')]
    [Scope('OnPrem')]
    procedure PickItemWithReservedLotAndBlockedBin()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        BinCode: Code[20];
        LotNos: array[3] of Code[20];
        NoOfBins: Integer;
        QuantityPerLotPerBin: Decimal;
    begin
        // [FEATURE] [Sales Order] [Pick] [Bin Content] [Item Tracking]
        // [SCENARIO 379664] Pick created from Sales Shipment should contain all available required quantity excluding reserved Lot and blocked Bin.
        Initialize();

        // [GIVEN] Lot-tracked Item.
        // [GIVEN] Full WMS Location.
        // [GIVEN] Posted Purchase Receipt with three lots "L1", "L2", "L3".
        // [GIVEN] Registered Put-away with lines evenly split by lots and bins "B1", "B2", "B3".
        // [GIVEN] Sales Order with Item Tracking for Lots "L1", "L2" and "L3".
        // [GIVEN] Warehouse Shipment for Sales Order.
        QuantityPerLotPerBin := LibraryRandom.RandInt(10);
        PrepareInventoryAndTrackedSalesDocumentForPick(
          WarehouseShipmentHeader, LocationCode, ItemNo, LotNos, NoOfBins, QuantityPerLotPerBin);

        // [GIVEN] Lot "L1" is reserved.
        SetLotReserved(ItemNo, LocationCode, LotNos, 1, ArrayLen(LotNos) * QuantityPerLotPerBin);

        // [GIVEN] Bin Content for "B1" is blocked for all movement.
        SetBinContentBlocked(BinCode, 1, LocationCode, ItemNo);

        // [WHEN] Create Pick for the Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        // [THEN] Pick contains neither Lot "L1" nor Bin "B1".
        // [THEN] Pick contains purchased quantity of Lots "L2" and "L3" in Bins "B2" and "B3".
        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', BinCode);
        Assert.RecordIsEmpty(WarehouseActivityLine);

        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', StrSubstNo('<>%1', BinCode));
        WarehouseActivityLine.CalcSums(Quantity);
        Assert.AreEqual((ArrayLen(LotNos) - 1) * (NoOfBins - 1) * QuantityPerLotPerBin, WarehouseActivityLine.Quantity, QtyInPickErr); // two lots in two bins
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2')]
    [Scope('OnPrem')]
    procedure PickItemWithBlockedLotAndBlockedBin()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        BinCode: Code[20];
        LotNos: array[3] of Code[20];
        NoOfBins: Integer;
        QuantityPerLotPerBin: Decimal;
    begin
        // [FEATURE] [Sales Order] [Pick] [Bin Content] [Item Tracking]
        // [SCENARIO 379664] Pick created from Sales Shipment should contain all available required quantity excluding blocked Lot and blocked Bin.
        Initialize();

        // [GIVEN] Lot-tracked Item.
        // [GIVEN] Full WMS Location.
        // [GIVEN] Posted Purchase Receipt with three lots "L1", "L2", "L3".
        // [GIVEN] Registered Put-away with lines evenly split by lots and bins "B1", "B2", "B3".
        // [GIVEN] Sales Order with Item Tracking for Lots "L1", "L2" and "L3".
        // [GIVEN] Warehouse Shipment for Sales Order.
        QuantityPerLotPerBin := LibraryRandom.RandInt(10);
        PrepareInventoryAndTrackedSalesDocumentForPick(
          WarehouseShipmentHeader, LocationCode, ItemNo, LotNos, NoOfBins, QuantityPerLotPerBin);

        // [GIVEN] Lot "L1" is blocked.
        SetLotBlocked(ItemNo, LotNos, 1);

        // [GIVEN] Bin Content for "B1" is blocked for all movement.
        SetBinContentBlocked(BinCode, 1, LocationCode, ItemNo);

        // [WHEN] Create Pick for the Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        // [THEN] Pick contains neither Bin "B1" nor Lot "L1".
        // [THEN] Pick contains purchased quantity of Lots "L2" and "L3" in Bins "B2" and "B3".
        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', BinCode);
        Assert.RecordIsEmpty(WarehouseActivityLine);

        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LotNos[1], '');
        Assert.RecordIsEmpty(WarehouseActivityLine);

        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
          StrSubstNo('<>%1', LotNos[1]), StrSubstNo('<>%1', BinCode));
        WarehouseActivityLine.CalcSums(Quantity);
        Assert.AreEqual((ArrayLen(LotNos) - 1) * (NoOfBins - 1) * QuantityPerLotPerBin, WarehouseActivityLine.Quantity, QtyInPickErr); // two lots in two bins
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2,ConfirmHandler2')]
    [Scope('OnPrem')]
    procedure PickItemWithReservedAndBlockedLotAndBlockedBin()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        BinCode: Code[20];
        LotNos: array[3] of Code[20];
        NoOfBins: Integer;
        QuantityPerLotPerBin: Decimal;
    begin
        // [FEATURE] [Sales Order] [Pick] [Bin Content] [Item Tracking]
        // [SCENARIO 379664] Pick created from Sales Shipment should contain all available required quantity excluding reserved Lot, blocked Lot and blocked Bin.
        Initialize();

        // [GIVEN] Lot-tracked Item.
        // [GIVEN] Full WMS Location.
        // [GIVEN] Posted Purchase Receipt with three lots "L1", "L2", "L3".
        // [GIVEN] Registered Put-away with lines evenly split by lots and bins "B1", "B2", "B3".
        // [GIVEN] Sales Order with Item Tracking for Lots "L1", "L2" and "L3".
        // [GIVEN] Warehouse Shipment for Sales Order.
        QuantityPerLotPerBin := LibraryRandom.RandInt(10);
        PrepareInventoryAndTrackedSalesDocumentForPick(
          WarehouseShipmentHeader, LocationCode, ItemNo, LotNos, NoOfBins, QuantityPerLotPerBin);

        // [GIVEN] Lot "L1" is reserved.
        SetLotReserved(ItemNo, LocationCode, LotNos, 1, ArrayLen(LotNos) * QuantityPerLotPerBin);

        // [GIVEN] Lot "L2" is blocked.
        SetLotBlocked(ItemNo, LotNos, 2);

        // [GIVEN] Bin Content for "B1" is blocked for all movement.
        SetBinContentBlocked(BinCode, 1, LocationCode, ItemNo);

        // [WHEN] Create Pick for the Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        // [THEN] Pick contain neither Lot "L1" nor Lot "L2" nor Bin "B1".
        // [THEN] Pick contains purchased quantity of Lot "L3" in Bins "B2" and "B3".
        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LotNos[1], '');
        Assert.RecordIsEmpty(WarehouseActivityLine);

        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LotNos[2], '');
        Assert.RecordIsEmpty(WarehouseActivityLine);

        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', BinCode);
        Assert.RecordIsEmpty(WarehouseActivityLine);

        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
          StrSubstNo('<>%1&<>%2', LotNos[1], LotNos[2]), StrSubstNo('<>%1', BinCode));
        WarehouseActivityLine.CalcSums(Quantity);
        Assert.AreEqual((ArrayLen(LotNos) - 2) * (NoOfBins - 1) * QuantityPerLotPerBin, WarehouseActivityLine.Quantity, QtyInPickErr); // one lot in two bins
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2')]
    [Scope('OnPrem')]
    procedure AvailableQtyToPickWithOneBlockedBinAndQtyReservedByOtherOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        BinCode: Code[20];
        LotNos: array[3] of Code[20];
        NoOfBins: Integer;
        QuantityPerLotPerBin: Decimal;
    begin
        // [FEATURE] [Sales Order] [Pick] [Bin Content] [Item Tracking]
        // [SCENARIO 380216] Available quantity to pick created from Sales Shipment includes neither quantity in blocked Bin nor quantity reserved by other Sales Order.
        Initialize();

        // [GIVEN] Lot-tracked Item.
        // [GIVEN] Full WMS Location.
        // [GIVEN] Posted Purchase Receipt with three lots.
        // [GIVEN] Registered Put-away with lines evenly split by lots and bins "B1", "B2", "B3".
        // [GIVEN] Sales Order "SO1" with released Warehouse Shipment.
        // [GIVEN] Quantity per each Lot per each Bin = "Q". Full quantity = 9Q. Quantity stored in each Bin = 3Q.
        QuantityPerLotPerBin := LibraryRandom.RandInt(10);
        PrepareInventoryAndNotTrackedSalesDocumentForPick(
          WarehouseShipmentHeader, LocationCode, ItemNo, LotNos, NoOfBins, QuantityPerLotPerBin);

        // [GIVEN] Sales Order "SO2" with Quantity = 10Q and reserved Quantity = 2Q.
        SetQtyReserved(SalesHeader, ItemNo, LocationCode, 10 * QuantityPerLotPerBin, 2 * QuantityPerLotPerBin);

        // [GIVEN] Bin Content for "B1" is blocked for all movement.
        SetBinContentBlocked(BinCode, 1, LocationCode, ItemNo);

        // [WHEN] Create Pick for the Shipment of Sales Order "SO1".
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        // [THEN] Available quantity to pick = 4Q (9Q total - 3Q in blocked bin - 2Q reserved).
        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', '');
        WarehouseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(4 * QuantityPerLotPerBin, WarehouseActivityLine.Quantity, QtyInPickErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2')]
    [Scope('OnPrem')]
    procedure AvailableQtyToPickWithTwoBlockedBinsAndQtyReservedByOtherOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        BinCode: Code[20];
        LotNos: array[3] of Code[20];
        NoOfBins: Integer;
        QuantityPerLotPerBin: Decimal;
    begin
        // [FEATURE] [Sales Order] [Pick] [Bin Content] [Item Tracking]
        // [SCENARIO 380216] Available quantity to pick created from Sales Shipment includes neither quantity in blocked Bins nor quantity reserved from not blocked bin.
        Initialize();

        // [GIVEN] Lot-tracked Item.
        // [GIVEN] Full WMS Location.
        // [GIVEN] Posted Purchase Receipt with three lots.
        // [GIVEN] Registered Put-away with lines evenly split by lots and bins "B1", "B2", "B3".
        // [GIVEN] Sales Order "SO1" with released Warehouse Shipment.
        // [GIVEN] Quantity per each Lot per each Bin = "Q". Full quantity = 9Q. Quantity stored in each Bin = 3Q.
        QuantityPerLotPerBin := LibraryRandom.RandInt(10);
        PrepareInventoryAndNotTrackedSalesDocumentForPick(
          WarehouseShipmentHeader, LocationCode, ItemNo, LotNos, NoOfBins, QuantityPerLotPerBin);

        // [GIVEN] Sales Order "SO2" with Quantity = 10Q and reserved Quantity = 2Q.
        SetQtyReserved(SalesHeader, ItemNo, LocationCode, 10 * QuantityPerLotPerBin, 2 * QuantityPerLotPerBin);

        // [GIVEN] Bin Contents for "B1" and "B2" are blocked for all movement.
        SetBinContentBlocked(BinCode, 1, LocationCode, ItemNo);
        SetBinContentBlocked(BinCode, 2, LocationCode, ItemNo);

        // [WHEN] Create Pick for the Shipment of Sales Order "SO1".
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        // [THEN] Available quantity to pick = 2Q (9Q total - 6Q in blocked bins - 1Q reserved from not blocked bin).
        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', '');
        WarehouseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(2 * QuantityPerLotPerBin, WarehouseActivityLine.Quantity, QtyInPickErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2')]
    [Scope('OnPrem')]
    procedure AvailableQtyToPickWithBlockedLotAndQtyReservedByOtherOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        LotNos: array[3] of Code[20];
        NoOfBins: Integer;
        QuantityPerLotPerBin: Decimal;
    begin
        // [FEATURE] [Sales Order] [Pick] [Item Tracking]
        // [SCENARIO 380216] Available quantity to pick created from Sales Shipment includes neither quantity in blocked Lot nor quantity reserved by other Sales Order.
        Initialize();

        // [GIVEN] Lot-tracked Item.
        // [GIVEN] Full WMS Location.
        // [GIVEN] Posted Purchase Receipt with three lots "L1", "L2", "L3".
        // [GIVEN] Registered Put-away with lines evenly split by lots and bins.
        // [GIVEN] Sales Order "SO1" with released Warehouse Shipment.
        // [GIVEN] Quantity per each Lot per each Bin = "Q". Full quantity = 9Q. Quantity of each Lot = 3Q.
        QuantityPerLotPerBin := LibraryRandom.RandInt(10);
        PrepareInventoryAndNotTrackedSalesDocumentForPick(
          WarehouseShipmentHeader, LocationCode, ItemNo, LotNos, NoOfBins, QuantityPerLotPerBin);

        // [GIVEN] Sales Order "SO2" with Quantity = 10Q and reserved Quantity = 3Q.
        SetQtyReserved(SalesHeader, ItemNo, LocationCode, 10 * QuantityPerLotPerBin, 3 * QuantityPerLotPerBin);

        // [GIVEN] Lot "L2" is blocked.
        SetLotBlocked(ItemNo, LotNos, 2);

        // [WHEN] Create Pick for the Shipment of Sales Order "SO1".
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        // [THEN] Available quantity to pick = 3Q (9Q total - 3Q in blocked lot - 3Q reserved).
        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', '');
        WarehouseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(3 * QuantityPerLotPerBin, WarehouseActivityLine.Quantity, QtyInPickErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2')]
    [Scope('OnPrem')]
    procedure AvailableQtyToPickWithBlockedBinAndQtyReservedByThisOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        BinCode: Code[20];
        LotNos: array[3] of Code[20];
        NoOfBins: Integer;
        QuantityPerLotPerBin: Decimal;
        FullQuantity: Decimal;
        LotQuantity: Decimal;
    begin
        // [FEATURE] [Sales Order] [Pick] [Bin Content] [Item Tracking]
        // [SCENARIO 380216] Available quantity to pick created from Sales Shipment does not include quantity in blocked Bin.
        Initialize();

        // [GIVEN] Lot-tracked Item.
        // [GIVEN] Full WMS Location.
        // [GIVEN] Posted Purchase Receipt with three lots.
        // [GIVEN] Registered Put-away with lines evenly split by lots and bins "B1", "B2", "B3".
        // [GIVEN] Quantity per each Lot per each Bin = "Q". Full quantity = 9Q. Quantity stored in each Bin = 3Q.
        QuantityPerLotPerBin := LibraryRandom.RandInt(10);
        MakeInventoryDistributedByLotsAndBins(LocationCode, ItemNo, LotNos, NoOfBins, LotQuantity, FullQuantity, QuantityPerLotPerBin);

        // [GIVEN] Released Sales Order with Quantity = 10Q and reserved Quantity = 2Q.
        // [GIVEN] Released Warehouse Shipment.
        SetQtyReserved(SalesHeader, ItemNo, LocationCode, 10 * QuantityPerLotPerBin, 2 * QuantityPerLotPerBin);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);

        // [GIVEN] Bin Content for "B1" is blocked for all movement.
        SetBinContentBlocked(BinCode, 1, LocationCode, ItemNo);

        // [WHEN] Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        // [THEN] Available quantity to pick = 6Q (9Q total - 3Q in blocked bin).
        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', '');
        WarehouseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(6 * QuantityPerLotPerBin, WarehouseActivityLine.Quantity, QtyInPickErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2')]
    [Scope('OnPrem')]
    procedure AvailableQtyToPickWithBlockedLotAndQtyReservedByThisOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        LotNos: array[3] of Code[20];
        NoOfBins: Integer;
        QuantityPerLotPerBin: Decimal;
        FullQuantity: Decimal;
        LotQuantity: Decimal;
    begin
        // [FEATURE] [Sales Order] [Pick] [Item Tracking]
        // [SCENARIO 380216] Available quantity to pick created from Sales Shipment does not include quantity in blocked Lot.
        Initialize();

        // [GIVEN] Lot-tracked Item.
        // [GIVEN] Full WMS Location.
        // [GIVEN] Posted Purchase Receipt with three lots "L1", "L2", "L3".
        // [GIVEN] Registered Put-away with lines evenly split by lots and bins.
        // [GIVEN] Quantity per each Lot per each Bin = "Q". Full quantity = 9Q. Quantity of each Lot = 3Q.
        QuantityPerLotPerBin := LibraryRandom.RandInt(10);
        MakeInventoryDistributedByLotsAndBins(LocationCode, ItemNo, LotNos, NoOfBins, LotQuantity, FullQuantity, QuantityPerLotPerBin);

        // [GIVEN] Released Sales Order with Quantity = 10Q and reserved Quantity = 2Q.
        // [GIVEN] Released Warehouse Shipment.
        SetQtyReserved(SalesHeader, ItemNo, LocationCode, 10 * QuantityPerLotPerBin, 2 * QuantityPerLotPerBin);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);

        // [GIVEN] Lot "L2" is blocked.
        SetLotBlocked(ItemNo, LotNos, 2);

        // [WHEN] Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        // [THEN] Available quantity to pick = 6Q (9Q total - 3Q in blocked lot).
        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', '');
        WarehouseActivityLine.CalcSums(Quantity);
        Assert.AreEqual(6 * QuantityPerLotPerBin, WarehouseActivityLine.Quantity, QtyInPickErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure InternalMovementQtyLessItemTracking()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Lot] [Internal Movement]
        // [SCENARIO 379358] Internal Movement Quantity should not be less than Item Tracking if Lot Warehouse Tracking is checked.

        // [GIVEN] Item with Lot Warehouse Tracking Code.
        Initialize();
        CreateTrackedItem(Item, true, false, false, false, false);

        // [GIVEN] "Lot No." with Item Inventory of "Qty".
        Qty := LibraryRandom.RandIntInRange(15, 25);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        CreateLotTrackedItemJournalLine(
          ItemJournalLine, Item."No.", '', LocationSilver.Code, Bin.Code, WorkDate(), LibraryUtility.GenerateGUID(), Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Internal Movement with Item and Get Bin Content.
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, LocationSilver.Code, Bin.Code);
        LibraryWarehouse.GetBinContentInternalMovement(
          InternalMovementHeader, LocationSilver.Code, StrSubstNo('%1', Item."No."), Bin.Code);
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        InternalMovementLine.FindFirst();

        // [WHEN] Change Quantity to a value less than "Qty".
        asserterror InternalMovementLine.Validate(Quantity, Qty - LibraryRandom.RandInt(10));

        // [THEN] Get an error message "Item tracking defined for item more than the quantity you have entered".
        Assert.ExpectedError(StrSubstNo(ItemTrackingErr, InternalMovementLine."Item No.", InternalMovementLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseWorksheetLineQtytoHandleRounding()
    var
        Item: Record Item;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
        QuantityBase: Decimal;
        QuantityPerUoM: Decimal;
        NonBaseItemUnitofMeasureCode: Code[10];
    begin
        // [FEATURE] [Warehouse Worksheet] [Unit of Measure]
        // [SCENARIO 380191] "Qty. to Handle" must be equal to "Qty. Outstanding" if "Qty. to Handle (Base)" is equal to "Qty. Outstanding (Base)"
        Initialize();

        // [GIVEN] Item with non Base Unit Of Measure, "Qty. per Unit of Measure" = 0.33333
        QuantityPerUoM := 0.33333;
        NonBaseItemUnitofMeasureCode := CreateItemWithNonBaseUnitOfMeasure(Item, QuantityPerUoM);

        // [GIVEN] Item Quantity in non Base Unit Of Measure = 403.92
        Quantity := 403.92;

        // [GIVEN] Item Quantity in Base Unit Of Measure = 135
        QuantityBase := Round(Quantity * QuantityPerUoM, 1, '>');

        // [GIVEN] Item Inventory  = 135, Whse. Worksheet Line
        CreateItemInventoryAndWhseWorksheetInternalPickLineWithUOM(
          WhseWorksheetLine, Item."No.", NonBaseItemUnitofMeasureCode, QuantityBase);

        // [GIVEN] "Qty. Outstanding" in non Base Unit Of Measure = 403.92
        WhseWorksheetLine.Validate("Qty. Outstanding", Quantity);

        // [WHEN] VALIDATE "Qty. to Handle" in non Base Unit Of Measure = 403.92
        WhseWorksheetLine.Validate("Qty. to Handle", Quantity);

        // [THEN] "Qty. to Handle" must be equal to "Qty. Outstanding" for Whse. Worksheet Line
        Assert.AreEqual(
          WhseWorksheetLine."Qty. Outstanding", WhseWorksheetLine."Qty. to Handle",
          StrSubstNo(
            TwoFieldsOfTableMustBeEqualErr, WhseWorksheetLine.FieldName("Qty. to Handle"),
            WhseWorksheetLine.FieldName("Qty. Outstanding"), WhseWorksheetLine.TableName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseActivityPutAwayLocationRequireReceiveIsNotChecked()
    var
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [FEATURE] [Inventory Put-away]
        // [SCENARIO 380898] On validate of Location Code for Warehouse Activity of Type Inventory Put-away Location."Require Receive" isn't checked.
        Initialize();

        // [GIVEN] Location "L" with "Require Receive" enabled.
        CreateLocationRequireReceive(Location);

        // [GIVEN] Warehouse Activity of Type Inventory Put-away - WAIP.
        WarehouseActivityHeader.Validate(Type, WarehouseActivityHeader.Type::"Invt. Put-away");

        // [WHEN] validate WAIP."Location Code" with L.Code
        WarehouseActivityHeader.Validate("Location Code", Location.Code);

        // [THEN] Value is validated without errors.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseActivityPutAwayLocationRequireReceiveProductionOrder()
    var
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Inventory Put-away][Production]
        // [SCENARIO 380898] Inventory Put-away can be created for a production order on a location with "Require Receipt" enabled.
        Initialize();

        // [GIVEN] Location "L" with "Require Receive" enabled.
        CreateLocationRequireReceive(Location);

        // [GIVEN] Refreshed Production Order with Inbound Warehouse Request.
        CreateRefreshedProductionOrderAndInbndWhseRequest(ProductionOrder, Location.Code);

        // [WHEN] Create Inventory Put-away
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);

        // [THEN] Corresponding Whse. Activity Line is created.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Put-away", Location.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseActivityPutAwayLocationRequireReceivePurchaseOrder()
    var
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Inventory Put-away][Purchase]
        // [SCENARIO 380898] Inventory Put-away can't be created for a purchase order on a location with "Require Receipt" enabled.
        Initialize();

        // [GIVEN] Location with "Require Receive" enabled.
        CreateLocationRequireReceive(Location);

        // [GIVEN] Released Purchase Order on this Location.
        CreateReleasedPurchaseOrder(PurchaseHeader, Location.Code);

        // [WHEN] Create Inventory Put-away
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // [THEN] Corresponding Whse. Activity Line isn't created.
        asserterror
          FindWhseActivityLine(
            WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Put-away", Location.Code, PurchaseHeader."No.",
            WarehouseActivityLine."Action Type");
        Assert.ExpectedError(NoWarehouseActivityLineErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SourceDocumentsGetSourceNoPageHandler')]
    [Scope('OnPrem')]
    procedure WhseActivityPutAwayLocationRequireReceiveGetSourceProductionOrder()
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [FEATURE] [Inventory Put-away][Production]
        // [SCENARIO 380898] Inventory Put-away can be created for a Production Order on a location with "Require Receipt" enabled and this Production Order is shown in Source Documents list.
        Initialize();

        // [GIVEN] Location "L" with "Require Receive" enabled.
        CreateLocationRequireReceive(Location);

        // [GIVEN] Refreshed Production Order PO with Inbound Warehouse Request.
        CreateRefreshedProductionOrderAndInbndWhseRequest(ProductionOrder, Location.Code);

        // [GIVEN] Inventory Put-away Header "Location Code" is validated with L.Code
        CreateInventoryPutAwayHeaderWithLocationCode(WarehouseActivityHeader, Location.Code);

        // [WHEN] Invoke Inventory Put-away Get Source Document action
        CODEUNIT.Run(CODEUNIT::"Create Inventory Put-away", WarehouseActivityHeader);

        // [THEN] "No." of Production Order PO is present in the list of source documents.
        Assert.AreEqual(ProductionOrder."No.", LibraryVariableStorage.DequeueText(), UnexpectedSourceNoErr);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsGetSourceNoPageHandler')]
    [Scope('OnPrem')]
    procedure WhseActivityPutAwayLocationRequireReceiveGetSourcePurchaseOrder()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [FEATURE] [Inventory Put-away][Purchase]
        // [SCENARIO 380898] Inventory Put-away can't be created for a purchase order on a location with "Require Receipt" enabled and this purchase order isn't shown in Source Documents list.
        Initialize();

        // [GIVEN] Location L with "Require Receive" enabled.
        CreateLocationRequireReceive(Location);

        // [GIVEN] Released Purchase Order PO.
        CreateReleasedPurchaseOrder(PurchaseHeader, Location.Code);

        // [GIVEN] Void Inventory Put-away "Location Code" is validated with L.Code
        CreateInventoryPutAwayHeaderWithLocationCode(WarehouseActivityHeader, Location.Code);

        // [WHEN] Invoke Inventory Put-away Get Source Document action
        CODEUNIT.Run(CODEUNIT::"Create Inventory Put-away", WarehouseActivityHeader);

        // [THEN] "No." of Purchase Order PO isn't present in the list of source documents.
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), UnexpectedSourceNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedQtyNotDistributedOnAdjustmentBinOnCreatePick()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Sales Order] [Pick] [Reservation] [Adjustment Bin]
        // [SCENARIO 208295] Reserved quantity should not be distributed to the adjustment bin on creating warehouse pick.
        Initialize();

        // [GIVEN] Full WMS location "L" with adjustment bin "A-01".
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Item is placed to bin "Z-01" on location "L".
        CreateItem(Item, '');
        UpdateInventoryUsingWhseJournal(Location, Item, LibraryRandom.RandIntInRange(50, 100));

        // [GIVEN] Part of the inventory of "I" is written-off from "Z-01" and thereby automatically placed to the adjustment bin "A-01".
        // [GIVEN] Calculate Whse. Adjustment job has not been run.
        // It is important that the adjustment bin has "A-01" code which goes before "Z-01" on the list of bins on "L".
        CreateAndRegisterWhseJournalLine(Location.Code, Location."Cross-Dock Bin Code", Item."No.", -LibraryRandom.RandInt(10));

        // [GIVEN] Sales order on "L" is released and reserved.
        // [GIVEN] Warehouse shipment for the sales order is created.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, LibraryRandom.RandIntInRange(10, 20));
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);

        // [WHEN] Create pick from the warehouse shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Warehouse pick for the reserved quantity from bin "A-01" is created.
        SalesLine.CalcFields("Reserved Quantity");
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, Location.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField("Bin Code", Location."Cross-Dock Bin Code");
        WarehouseActivityLine.TestField(Quantity, SalesLine."Reserved Quantity");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2')]
    [Scope('OnPrem')]
    procedure CreatePickFunctionPicksAllAvailableInventoryWhenFEFOEnabledAtLocation()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNos: array[3] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Warehouse Pick] [FEFO] [Item Tracking]
        // [SCENARIO 218658] Create Pick function should pick all required quantity from available inventory when "Pick According to FEFO" is enabled at location.
        Initialize();

        // [GIVEN] WMS location with FEFO enabled.
        CreateFullWhseLocationWithFEFO(Location);

        // [GIVEN] Lot-tracked item.
        CreateTrackedItem(Item, true, false, false, false, false);

        // [GIVEN] Lots "L1", "L2", "L3" are purchased and put-away. Quantity of each lot = 20 pcs.
        // [GIVEN] The lots are arranged by their expiration dates - "L1" has the earliest date, "L3" has the latest.
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
        CreatePurchaseWithMultipleLotTracking(PurchaseHeader, Item."No.", LotNos, Location.Code, 60);
        for i := 1 to ArrayLen(LotNos) do begin
            ReservationEntry.SetRange("Item No.", Item."No.");
            ReservationEntry.SetRange("Lot No.", LotNos[i]);
            ReservationEntry.FindFirst();
            ReservationEntry.Validate("Expiration Date", WorkDate() + i);
            ReservationEntry.Modify(true);
        end;
        CreateAndPostWhseReceiptAndRegisterPutAwayFromPO(PurchaseHeader);

        // [GIVEN] Sales order "SO1" for 30 pcs.
        // [GIVEN] Warehouse shipment and pick are created for "SO1".
        // [GIVEN] The warehouse pick is registered, so that 20 pcs of "L1" and 10 pcs of "L2" are now in ship zone.
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", 30, Location.Code);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Sales order "SO2" for 20 pcs.
        // [GIVEN] Warehouse shipment is created for "SO2"
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", 20, Location.Code);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");

        // [WHEN] Create pick for the shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] 10 pcs of "L2" and 10 pcs of "L3" are picked.
        VerifyQtyOnWhseActivityLinesByLotNo(Location.Code, Item."No.", LotNos[2], 10);
        VerifyQtyOnWhseActivityLinesByLotNo(Location.Code, Item."No.", LotNos[3], 10);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOutputPostedWithVariantCodeFromInvtPutAway()
    var
        Location: Record Location;
        Item: Record Item;
        ItemVariant: array[2] of Record "Item Variant";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Inventory Put-away] [Production Order] [Item Variant]
        // [SCENARIO 252196] Item Variant is populated on output item entries, when the output is posted through inventory put-away.
        Initialize();

        // [GIVEN] Location set up for required put-away.
        CreateLocationRequireReceive(Location);

        // [GIVEN] Item with two variants "A" and "B".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item."No.");

        // [GIVEN] Production order with two lines, one per each item variant.
        CreateProdOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, Item."No.", Location.Code, LibraryRandom.RandInt(10));
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", ItemVariant[1].Code, ProductionOrder."Location Code",
          LibraryRandom.RandInt(10));
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", ItemVariant[2].Code, ProductionOrder."Location Code",
          LibraryRandom.RandInt(10));

        // [GIVEN] Create warehouse request and inventory put-away for the production order.
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);

        // [WHEN] Post the inventory put-away and therefore the output.
        AutoFillQuantityAndPostInventoryActivity(Location.Code);

        // [THEN] Output item entries have variant codes "A" and "B".
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Variant Code", ItemVariant[1].Code);
        Assert.RecordCount(ItemLedgerEntry, 1);
        ItemLedgerEntry.SetRange("Variant Code", ItemVariant[2].Code);
        Assert.RecordCount(ItemLedgerEntry, 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FEFORespectedWhenCreateInvtPickFromSalesOrderWithNonSpecificReservation()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Inventory Pick] [FEFO] [Reservation] [Late Binding]
        // [SCENARIO 256426] FEFO is respected when you create inventory pick from sales order with non-specific reservation.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with expiration calculation formula defined on item card.
        Qty := LibraryRandom.RandIntInRange(20, 40);
        CreateLotTrackedItemWithExpirationCalculation(Item);

        // [GIVEN] Two lots "L1" and "L2" are in inventory on the location, that is set up for FEFO picking. Quantity of each lot = "Q".
        // [GIVEN] Lot "L2" has an earlier expiration date than lot "L1".
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);
        CreateAndPostSetOfLotTrackedItemJournalLines(LotNos, Item."No.", LocationSilver.Code, Bin.Code, Qty);

        // [GIVEN] Sales order with item "I" and quantity = "Q". Item tracking is not set on the sales line.
        // [GIVEN] Auto-reserve the sales order against the inventory.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", Qty, LocationSilver.Code, LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20));
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create inventory pick from the sales order.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [THEN] The program suggests to pick lot "L2", which is expired earlier than "L1".
        FindWarehouseActivityNo(WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Lot No.", LotNos[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ReservationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FEFORespectedWhenCreateInvtPickFromPurchOrderWithNonSpecificReservation()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [Inventory Pick] [FEFO] [Reservation] [Late Binding]
        // [SCENARIO 256426] FEFO is respected when you create inventory pick from purchase return order with non-specific reservation.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with expiration calculation formula defined on item card.
        CreateLotTrackedItemWithExpirationCalculation(Item);
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Two lots "L1" and "L2" are in inventory on the location, that is set up for FEFO picking. Quantity of each lot = "Q".
        // [GIVEN] Lot "L2" has an earlier expiration date than lot "L1".
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);
        CreateAndPostSetOfLotTrackedItemJournalLines(LotNos, Item."No.", LocationSilver.Code, Bin.Code, Qty);

        // [GIVEN] Purchase return order with item "I" and quantity = "Q". Item tracking is not set on the purchase line.
        // [GIVEN] Auto-reserve the purchase return against the inventory.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo(),
          Item."No.", Qty, LocationSilver.Code, LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20));
        PurchaseLine.ShowReservation();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Create inventory pick from the purchase return.
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        // [THEN] The program suggests to pick lot "L2", which is expired earlier than "L1".
        FindWarehouseActivityNo(WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Lot No.", LotNos[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler2,MessageHandler')]
    [Scope('OnPrem')]
    procedure FEFONotRespectedWhenCreateInvtPickFromSalesOrderWithLotSpecificReservation()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Inventory Pick] [FEFO] [Reservation] [Item Tracking]
        // [SCENARIO 256426] Lot-specific reservation has a priority against FEFO when you create inventory pick from sales order.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with expiration calculation formula defined on item card.
        CreateLotTrackedItemWithExpirationCalculation(Item);
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Two lots "L1" and "L2" are in inventory on the location, that is set up for FEFO picking. Quantity of each lot = "Q".
        // [GIVEN] Lot "L2" has an earlier expiration date than lot "L1".
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);
        CreateAndPostSetOfLotTrackedItemJournalLines(LotNos, Item."No.", LocationSilver.Code, Bin.Code, Qty);

        // [GIVEN] Sales order with item "I" and quantity = "Q".
        // [GIVEN] Open item tracking on the sales line and select lot "L1".
        // [GIVEN] Lot "L1" is reserved from the inventory.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", Qty, LocationSilver.Code, LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20));
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNos[1]);
        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.OpenItemTrackingLines();
        SalesLine.ShowReservation();
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create inventory pick from the sales order.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [THEN] The program suggests to pick the reserved lot "L1", despite its later expiration date than of "L2".
        FindWarehouseActivityNo(WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Lot No.", LotNos[1]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FEFORespectedWhenCreateInvtMovementFromSalesWithNonSpecificReservation()
    var
        Bin: array[2] of Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Inventory Movement] [FEFO] [Reservation] [Late Binding]
        // [SCENARIO 256426] FEFO is respected when you create inventory movement from sales order with non-specific reservation.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with expiration calculation formula defined on item card.
        Qty := LibraryRandom.RandIntInRange(20, 40);
        CreateLotTrackedItemWithExpirationCalculation(Item);

        // [GIVEN] Bins "B1" and "B2" on the location, that is set up for picking by FEFO.
        LibraryWarehouse.FindBin(Bin[1], LocationSilver.Code, '', 1);
        LibraryWarehouse.FindBin(Bin[2], LocationSilver.Code, '', 2);
        LibraryWarehouse.CreateBinContent(
          BinContent, LocationSilver.Code, '', Bin[2].Code, Item."No.", '', Item."Base Unit of Measure");

        // [GIVEN] Two lots "L1" and "L2" are stored in bin "B1" on the location. Quantity of each lot = "Q".
        // [GIVEN] Lot "L2" has an earlier expiration date than lot "L1".
        CreateAndPostSetOfLotTrackedItemJournalLines(LotNos, Item."No.", LocationSilver.Code, Bin[1].Code, Qty);

        // [GIVEN] Sales order with item "I", quantity = "Q" and bin code = "B2". Item tracking is not set on the sales line.
        // [GIVEN] Auto-reserve the sales order against the inventory.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", Qty, LocationSilver.Code, LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20));
        SalesLine.Validate("Bin Code", Bin[2].Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create inventory movement from the sales line in order to transfer the item from "B1" to "B2".
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", false, false, true);
        // [THEN] The program suggests to move lot "L2", which is expired earlier than "L1".
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Movement", LocationSilver.Code, SalesHeader."No.", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField("Lot No.", LotNos[2]);
        Assert.RecordCount(WarehouseActivityLine, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler2,MessageHandler')]
    [Scope('OnPrem')]
    procedure FEFORespectedWhenCreateInvtMovementFromInternalMovementWithoutItemTracking()
    var
        Bin: array[2] of Record Bin;
        Item: Record Item;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Internal Movement] [Inventory Movement] [FEFO]
        // [SCENARIO 256426] FEFO is respected when you create inventory movement from internal movement and no item tracking is defined.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with expiration calculation formula defined on item card.
        Qty := LibraryRandom.RandIntInRange(20, 40);
        CreateLotTrackedItemWithExpirationCalculation(Item);

        // [GIVEN] Bins "B1" and "B2" on the location, that is set up for picking by FEFO.
        LibraryWarehouse.FindBin(Bin[1], LocationSilver.Code, '', 1);
        LibraryWarehouse.FindBin(Bin[2], LocationSilver.Code, '', 2);

        // [GIVEN] Two lots "L1" and "L2" are stored in bin "B1" on the location. Quantity of each lot = "Q" pcs.
        // [GIVEN] Lot "L2" has an earlier expiration date than lot "L1".
        CreateAndPostSetOfLotTrackedItemJournalLines(LotNos, Item."No.", LocationSilver.Code, Bin[1].Code, Qty);

        // [GIVEN] Internal movement in order to transfer "Q" pcs of item "I" from "B1" to "B2".
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, LocationSilver.Code, Bin[2].Code);
        LibraryWarehouse.GetBinContentInternalMovement(InternalMovementHeader, LocationSilver.Code, Item."No.", '');
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        InternalMovementLine.FindFirst();
        InternalMovementLine.Validate("Qty. (Base)", Qty);
        InternalMovementLine.Modify(true);

        // [GIVEN] Item tracking is assigned automatically to internal movement line, so remove it.
        DeleteWhseItemTracking(
          DATABASE::"Internal Movement Line", 0, InternalMovementLine."No.", InternalMovementLine."Line No.");

        // [WHEN] Create inventory movement from the internal movement.
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
        // [THEN] The program suggests to move lot "L2", which has an earlier expiration date than lot "L1".
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Movement", LocationSilver.Code, '', WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField("Lot No.", LotNos[2]);
        Assert.RecordCount(WarehouseActivityLine, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VariantCodeIsAssignedToWhseItemTrackingLineOnInternalMovementLine()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        LotNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Variant] [Internal Movement] [Item Tracking]
        // [SCENARIO 257683] When you open item tracking lines on an internal movement line with populated variant code, a new record in whse. item tracking should be initialized with that variant code.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with item variant "V".
        CreateTrackedItem(Item, true, false, false, false, false);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Post the positive adjustment of item "I", variant "V". Set lot no. = "L" on the item tracking lines.
        LibraryWarehouse.FindBin(Bin, LocationSilver2.Code, '', 1);
        CreateLotTrackedItemJournalLine(
          ItemJournalLine, Item."No.", ItemVariant.Code, LocationSilver2.Code, Bin.Code, WorkDate(), LotNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create internal movement and select item "I" and variant "V" on the line.
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, LocationSilver2.Code, '');
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, Item."No.", '', Bin.Code, Qty);
        InternalMovementLine.Validate("Variant Code", ItemVariant.Code);
        InternalMovementLine.Modify(true);

        // [WHEN] Open item tracking lines on the movement line, set lot no. = "L", close the item tracking.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        InternalMovementLine.OpenItemTrackingLines();

        // [THEN] Variant code is equal to "V" on created whse. item tracking line.
        FilterWhseItemTracking(
          WhseItemTrackingLine, DATABASE::"Internal Movement Line", 0, InternalMovementLine."No.", InternalMovementLine."Line No.");
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.TestField("Variant Code", ItemVariant.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure VariantCodeIsAssignedToWhseItemTrackingLineOnInternalPutawayLine()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        LotNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Variant] [Internal Put-away] [Item Tracking]
        // [SCENARIO 257683] When you open item tracking lines on an internal put-away line with populated variant code, a new record in whse. item tracking should be initialized with that variant code.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with item variant "V".
        CreateTrackedItem(Item, true, false, false, false, false);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Register whse. journal line for positive adjustment of item "I", variant "V" on location with directed put-away and pick. Set lot no. = "L" on the warehouse journal line.
        // [GIVEN] Calculate warehouse adjustment and post the item journal.
        FindBin(Bin);
        UpdateInventoryWithTrackingUsingWhseJournal(
          LocationWhite.Code, Bin.Code, Item."No.", ItemVariant.Code, LotNo, Qty);

        // [GIVEN] Create whse. internal put-away and select item "I" and variant "V" on the line.
        LibraryWarehouse.CreateWhseInternalPutawayHdr(WhseInternalPutAwayHeader, LocationWhite.Code);
        LibraryWarehouse.CreateWhseInternalPutawayLine(WhseInternalPutAwayHeader, WhseInternalPutAwayLine, Item."No.", Qty);
        WhseInternalPutAwayLine.Validate("Variant Code", ItemVariant.Code);
        WhseInternalPutAwayLine.Modify(true);

        // [WHEN] Open item tracking lines on the whse. put-away line, set lot no. = "L", close the item tracking.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        WhseInternalPutAwayLine.OpenItemTrackingLines();

        // [THEN] Variant code is equal to "V" on created whse. item tracking line.
        FilterWhseItemTracking(
          WhseItemTrackingLine, DATABASE::"Whse. Internal Put-away Line", 0,
          WhseInternalPutAwayHeader."No.", WhseInternalPutAwayLine."Line No.");
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.TestField("Variant Code", ItemVariant.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2,WhseShipmentCreatePickPageRequestHandler,MessageHandlerGetText')]
    [Scope('OnPrem')]
    procedure WarningOfExcludedExpiredItemsNotShownWhenExpiredLotBlocked()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Location: Record Location;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[3] of Code[20];
        LotQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [FEFO] [Warehouse Pick] [Item Tracking] [Expiration Date]
        // [SCENARIO 263227] Warning message reading that expired items are not included in pick, does not raise, if the expired lot is blocked and cannot be picked anyway.
        Initialize();

        // [GIVEN] WMS location with enabled picking by FEFO.
        CreateFullWhseLocationWithFEFO(Location);

        // [GIVEN] Lot-tracked item. The item tracking is set up for "Strict Expiration Posting".
        CreateItemTrackingCode(ItemTrackingCode, true, false, true, true, true);
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
        LotQty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Purchase three lots "L1", "L2", "L3" of the item.
        // [GIVEN] The expiration date in lot "L1" is earlier than WorkDate(), so the lot is expired.
        // [GIVEN] Sales order for all purchased quantity.
        // [GIVEN] Create warehouse shipment from the sales order.
        PrepareInventoryWithExpDatesAndSalesShipment(WarehouseShipmentHeader, Location.Code, Item."No.", LotNos, LotQty);

        // [GIVEN] Lot "L1" is blocked.
        SetLotBlocked(Item."No.", LotNos, 1);

        // [WHEN] Create pick from the warehouse shipment.
        Commit();
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.CreatePickDoc(WarehouseShipmentLine, WarehouseShipmentHeader);

        // [THEN] Warehouse pick is created.
        FilterWarehouseActivityLine(
              WarehouseActivityLine, Item."No.", Location.Code, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', '');
        Assert.RecordIsNotEmpty(WarehouseActivityLine);

        // [THEN] The resulting message does not have a warning about excluded expired lots.
        Assert.IsFalse(
          StrPos(LibraryVariableStorage.DequeueText(), ExpiredItemsNotPickedMsg) > 0,
          'Redundant warning of expired items in the pick raised.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2,WhseItemTrackingLinesPageHandler,WhseShipmentCreatePickPageRequestHandler,MessageHandlerGetText')]
    [Scope('OnPrem')]
    procedure WarningOfExcludedExpiredItemsNotShownWhenExpiredLotNotInInventory()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Location: Record Location;
        BinContent: Record "Bin Content";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[3] of Code[20];
        LotQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [FEFO] [Warehouse Pick] [Item Tracking] [Expiration Date]
        // [SCENARIO 263227] Warning message reading that expired items are not included in pick, does not raise, if the expired lot is not in the inventory and cannot be picked anyway.
        Initialize();

        // [GIVEN] WMS location with enabled picking by FEFO.
        CreateFullWhseLocationWithFEFO(Location);

        // [GIVEN] Lot-tracked item. The item tracking is set up for "Strict Expiration Posting".
        CreateItemTrackingCode(ItemTrackingCode, true, false, true, true, true);
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
        LotQty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Purchase three lots "L1", "L2", "L3" of the item.
        // [GIVEN] The expiration date in lot "L1" is earlier than WorkDate(), so the lot is expired.
        // [GIVEN] Sales order for all purchased quantity.
        // [GIVEN] Create warehouse shipment from the sales order.
        PrepareInventoryWithExpDatesAndSalesShipment(WarehouseShipmentHeader, Location.Code, Item."No.", LotNos, LotQty);

        // [GIVEN] Write off all stock of the expired lot "L1".
        FindBinContent(BinContent, Item."No.", Location.Code);
        UpdateInventoryWithTrackingUsingWhseJournal(Location.Code, BinContent."Bin Code", Item."No.", '', LotNos[1], -LotQty);

        // [WHEN] Create pick from the warehouse shipment.
        Commit();
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.CreatePickDoc(WarehouseShipmentLine, WarehouseShipmentHeader);

        // [THEN] Warehouse pick is created.
        FilterWarehouseActivityLine(
            WarehouseActivityLine, Item."No.", Location.Code, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', '');
        Assert.RecordIsNotEmpty(WarehouseActivityLine);

        // [THEN] The resulting message does not have a warning about excluded expired lots.
        Assert.IsFalse(
          StrPos(LibraryVariableStorage.DequeueText(), ExpiredItemsNotPickedMsg) > 0,
          'Redundant warning of expired items in the pick raised.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2,WhseShipmentCreatePickPageRequestHandler,MessageHandlerGetText')]
    [Scope('OnPrem')]
    procedure WarningOfExcludedExpiredItemsShownWhenExpiredLotInStockAndNotBlocked()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Location: Record Location;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[3] of Code[20];
        LotQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [FEFO] [Warehouse Pick] [Item Tracking] [Expiration Date]
        // [SCENARIO 263227] Warning message reading that expired items are not included in pick raises, when the lot cannot be picked only because it is expired.
        Initialize();

        // [GIVEN] WMS location with enabled picking by FEFO.
        CreateFullWhseLocationWithFEFO(Location);

        // [GIVEN] Lot-tracked item. The item tracking is set up for "Strict Expiration Posting".
        CreateItemTrackingCode(ItemTrackingCode, true, false, true, true, true);
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
        LotQty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Purchase three lots "L1", "L2", "L3" of the item.
        // [GIVEN] The expiration date in lot "L1" is earlier than WorkDate(), so the lot is expired.
        // [GIVEN] Sales order for all purchased quantity.
        // [GIVEN] Create warehouse shipment from the sales order.
        PrepareInventoryWithExpDatesAndSalesShipment(WarehouseShipmentHeader, Location.Code, Item."No.", LotNos, LotQty);

        // [WHEN] Create pick from the warehouse shipment.
        Commit();
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.CreatePickDoc(WarehouseShipmentLine, WarehouseShipmentHeader);

        // [THEN] Warehouse pick is created.
        FilterWarehouseActivityLine(
              WarehouseActivityLine, Item."No.", Location.Code, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, '', '');
        Assert.RecordIsNotEmpty(WarehouseActivityLine);

        // [THEN] The resulting message has a warning that some of the lots are expired and not included in the pick.
        Assert.IsTrue(
          StrPos(LibraryVariableStorage.DequeueText(), ExpiredItemsNotPickedMsg) > 0,
          'Expected warning of expired items in the pick did not raise.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AvailQtyReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QtyInOpenShopFloorBinAndToProductionBinMustBeExcludedFromTotalAvailQty()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        EntrySummary: Record "Entry Summary";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Reservation] [Available to Reserve] [Sales] [Order]
        // [SCENARIO 279622] Units in the Open Shop Floor bin must be excluded from Total Available Quantity in the Reservation page
        Initialize();

        // [GIVEN] Create Location with an employee
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create an Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create some stock for the Item and put all units of Item into Open Shop Floor bin
        Quantity := LibraryRandom.RandIntInRange(50, 100);
        Bin.Get(Location.Code, Location."Open Shop Floor Bin Code");
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item."No.", Quantity, false);

        // [GIVEN] Create a Sales Order with single line of Item
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", LibraryRandom.RandInt(50), Location.Code, WorkDate());

        // [GIVEN] Open created Sales Order on test page
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Invoke Reservation page
        Commit();
        SalesOrder.SalesLines.Reserve.Invoke();

        // [THEN] Units that are in Open Shop Floor bin are not included in Total Available Quantity
        EntrySummary."Qty. Alloc. in Warehouse" := LibraryVariableStorage.DequeueDecimal();
        EntrySummary."Total Available Quantity" := LibraryVariableStorage.DequeueDecimal();
        EntrySummary.TestField("Qty. Alloc. in Warehouse", Quantity);
        EntrySummary.TestField("Total Available Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('AvailQtyReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QtyInToProductionBinAndToProductionBinMustBeExcludedFromTotalAvailQty()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        EntrySummary: Record "Entry Summary";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Reservation] [Available to Reserve] [Sales] [Order]
        // [SCENARIO 279622] Units in the To-Production bin must be excluded from Total Available Quantity in the Reservation page
        Initialize();

        // [GIVEN] Create Location with an employee
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create an Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create some stock for the Item and put all units of Item into the To-Production bin
        Quantity := LibraryRandom.RandIntInRange(50, 100);
        Bin.Get(Location.Code, Location."To-Production Bin Code");
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item."No.", Quantity, false);

        // [GIVEN] Create a Sales Order with single line of Item
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", LibraryRandom.RandInt(50), Location.Code, WorkDate());

        // [GIVEN] Open created Sales Order on test page
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Invoke Reservation page
        Commit();
        SalesOrder.SalesLines.Reserve.Invoke();

        // [THEN] Units that are in the To-Production bin are not included in Total Available Quantity
        EntrySummary."Qty. Alloc. in Warehouse" := LibraryVariableStorage.DequeueDecimal();
        EntrySummary."Total Available Quantity" := LibraryVariableStorage.DequeueDecimal();
        EntrySummary.TestField("Qty. Alloc. in Warehouse", Quantity);
        EntrySummary.TestField("Total Available Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    procedure PickWithFEFOWhenUnregisteredPicksPresent()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        LotNo: Code[50];
        PartQty: Decimal;
    begin
        // [FEATURE] [FEFO] [Warehouse Pick] [Lot Tracked Item]
        // [SCENARIO 309231] When create Pick from Sales Order and Pick According to FEFO is used and there are other unregistered Picks pending
        // [SCENARIO 309231] then Pick is created with appropriate Quantity in Take and Place Lines
        Initialize();
        PartQty := LibraryRandom.RandIntInRange(10, 50);

        // [GIVEN] Location with Pick According To FEFO, Require Shipment, Require Pick and Bin Mandatory
        CreateAndUpdateLocation(Location, true, false, true, false, true, true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', LibraryRandom.RandIntInRange(3, 5), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 3); // Find Bin with Index 3.
        Location.Validate("Shipment Bin Code", Bin.Code);
        Location.Modify();

        // [GIVEN] Item with Item Tracking Code having Lot Tracking enabled
        CreateTrackedItem(Item, true, false, false, false, false);

        // [GIVEN] Bin "B1" had Lot "L1" with Expiration Date = 1/1/2020 and 200 PCS
        LotNo := LibraryUtility.GenerateGUID();
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin.Code, LotNo, PartQty, CalcDate('<5Y>', WorkDate()));
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin.Code, LotNo, PartQty, CalcDate('<5Y>', WorkDate()));
        PostItemJournalLineWithLotNoExpiration(
          Item."No.", Location.Code, Bin.Code, LotNo, 2 * PartQty, CalcDate('<5Y>', WorkDate()));

        // [GIVEN] Bin "B2" had Lot "L2" with Expiration Date = 1/1/2021 and 100 PCS
        LotNo := LibraryUtility.GenerateGUID();
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 2);
        PostItemJournalLineWithLotNoExpiration(
          Item."No.", Location.Code, Bin.Code, LotNo, 2 * PartQty, CalcDate('<5Y+1D>', WorkDate()));

        // [GIVEN] Release Sales Order "SO1" with 150 PCS, create Warehouse Shipment and register Pick
        RegisterWarehouseActivity(
          PrepareSalesOrderWithPick(Item."No.", Location.Code, 3 * PartQty), WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Release Sales Order "SO2" with 50 PCS, create Warehouse Shipment and create Pick
        PrepareSalesOrderWithPick(Item."No.", Location.Code, PartQty);

        // [GIVEN] Release Sales Order "SO3" with 12 PCS, create Warehouse Shipment and register Pick
        RegisterWarehouseActivity(
          PrepareSalesOrderWithPick(Item."No.", Location.Code, PartQty), WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Release Sales Order "SO4" with 3 PCS, create Warehouse Shipment
        PrepareSalesOrderWithWhseShipment(SalesHeader, WarehouseShipmentHeader, Item."No.", Location.Code, PartQty);

        // [WHEN] Create Pick from Warehouse Shipment
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentHeader."No.");

        // [THEN] Pick is created with 3 PCS and Lot "L2"
        VerifyWarehouseActivityTakePlaceLinesQtyAndLot(SalesHeader."No.", Location.Code, PartQty, LotNo);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ConfirmHandler2,MessageHandler')]
    [Scope('OnPrem')]
    procedure PickingByFEFOOnlyPickTypeBinsAreConsidered()
    var
        Location: Record Location;
        Zone: Record Zone;
        BinNoPick: Record Bin;
        BinPick: Record Bin;
        Item: Record Item;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [FEFO] [Directed Put-Away and Pick] [Item Tracking] [Expiration Date] [Pick]
        // [SCENARIO 319438] Only items stored in bins of "Pick" type are included to picking by FEFO.
        Initialize();
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Directed put-away and pick location with FEFO enabled.
        // [GIVEN] Bin "NoPick" in no-pick zone, bin "Pick" in pick zone.
        CreateFullWhseLocationWithFEFO(Location);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, false), false);
        LibraryWarehouse.FindBin(BinNoPick, Location.Code, Zone.Code, 1);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(BinPick, Location.Code, Zone.Code, 1);

        // [GIVEN] Lot-tracked item.
        CreateTrackedItem(Item, true, false, false, false, false);

        // [GIVEN] Register two positive adjustments for 10 pcs via Warehouse Item Journal:
        // [GIVEN] put lot "L1" with expiration date = "WORKDATE" into "NoPick" bin, and lot "L2" with expiration date "WorkDate() + 1 month" to "Pick" bin.
        // [GIVEN] Note that lot "L1" has earlier expiration date than "L2".
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        CreateWhseJournalLineWithLotTracking(WarehouseJournalBatch, BinNoPick, Item."No.", Qty, LotNo[1], WorkDate());
        CreateWhseJournalLineWithLotTracking(WarehouseJournalBatch, BinPick, Item."No.", Qty, LotNo[2], WorkDate() + 30);
        LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code, false);
        CalcWhseAdjustmentAndPostItemJournal(Item);

        // [GIVEN] Sales order for 10 pcs.
        // [GIVEN] Release and create warehouse shipment from the order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));

        // [WHEN] Create pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] A warehouse pick for lot "L2" from bin "Pick" is created, because the earlier expired lot "L1" is stored in a bin where we cannot pick from.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, Location.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField("Bin Code", BinPick.Code);
        WarehouseActivityLine.TestField("Lot No.", LotNo[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromPickWkshWhenSalesUoMNotMatchBaseUoM()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QtyItemStock: Integer;
        QtyToSell: Integer;
    begin
        // [FEATURE] [Unit of Measure] [Bin] [Pick] [Worksheet]
        // [SCENARIO 327633] Create Pick from Pick Worksheet for an Item which has Sales Unit of Measure <> Base Unit of Measure
        // [SCENARIO 327633] And item Location has Bins
        QtyItemStock := 1;
        QtyToSell := 2;

        // [GIVEN] Location with Bin Mandatory enabled
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', ArrayLen(Bin), false);
        LibraryWarehouse.FindBin(Bin[1], Location.Code, '', 1);
        LibraryWarehouse.FindBin(Bin[2], Location.Code, '', 2);
        Location.Validate("Receipt Bin Code", Bin[1].Code);
        Location.Validate("Shipment Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Item had Base Unit of Measure = PALLET and Sales Unit of Measure BOX (BOX = 1/10 PALLET)
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 0.1);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Item had stock of 1 PALLET in WMS Location with Breakbulk allowed
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, Location."Receipt Bin Code", QtyItemStock);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Released Sales Order with 2 BOX of the Item and released Warehouse Shipment
        PrepareSalesOrderWithWhseShipment(SalesHeader, WarehouseShipmentHeader, Item."No.", Location.Code, QtyToSell);
        WarehouseShipmentNo := WarehouseShipmentHeader."No.";
        LocationCode := Location.Code;

        // [WHEN] Create Pick from Pick Worksheet
        CreatePickFromPickWorksheet(Location.Code, QtyToSell);

        // [THEN] Pick is created with 2 BOX of the Item
        VerifyWhseActivityLine(WarehouseActivityLine, QtyToSell, SalesHeader."No.", Location.Code);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesMultipleModalPageHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure WhsePickWhenItemTrackingIsReplacedForComponent()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LotNo: array[2] of Code[50];
        LotQty: Integer;
        ComponentQty: Decimal;
        PartialQtyMultiplier: Decimal;
        SecondPickQty: Decimal;
    begin
        // [FEATURE] [Pick] [Production] [Item Tracking]
        // [SCENARIO 331480] When partially registered Pick is deleted for Lot Tracked Component Item and old Item Tracking is replaced
        // [SCENARIO 331480] then newly created Pick has same Lot as specified in Item Tracking
        Initialize();
        LotQty := 4 * LibraryRandom.RandInt(10);
        ComponentQty := LotQty / 2;
        PartialQtyMultiplier := 0.5;
        SecondPickQty := ComponentQty * (1 - PartialQtyMultiplier);

        // [GIVEN] Lot Tracked Item "I" had stock of 100 PCS: 50 PCS with Lot L1 and 50 PCS with Lot L2
        CreateItemWithStockSeveralLots(Item, Location, LotNo, LotQty);

        // [GIVEN] Production Order with 1 PCS of Item "A" with 20 PCS of Item "I" as component
        // [GIVEN] Lot Tracking for Production Order Component had 20 PCS of Lot L1
        CreateProdOrderWithLotTrackedComponentItem(
          ProductionOrder, ProdOrderComponent, LibraryInventory.CreateItemNo(), 1, Item."No.", ComponentQty, LotNo[1], Location.Code);

        // [GIVEN] Pick was created for Production Order with Lot L1 and 20 PCS
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        VerifyWarehouseActivityTakePlaceLinesQtyAndLot(ProductionOrder."No.", Location.Code, ComponentQty, LotNo[1]);

        // [GIVEN] Registered 12 PCS and deleted Pick
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
          ProdOrderComponent."Prod. Order Line No.");
        RegisterAndDeletePartialPick(WarehouseActivityHeader, PartialQtyMultiplier);

        // [GIVEN] Item Tracking Line with 20 PCS of Lot L1 was replaced by a new Line with 8 PCS of Lot L2
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo[2]);
        LibraryVariableStorage.Enqueue(SecondPickQty);
        ProdOrderComponent.OpenItemTrackingLines();

        // [WHEN] Create Whse. Pick
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [THEN] Pick is created with 8 PCS of Lot L2
        VerifyWarehouseActivityTakePlaceLinesQtyAndLot(ProductionOrder."No.", Location.Code, SecondPickQty, LotNo[2]);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesMultipleModalPageHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure WhsePickWhenItemTrackingIsUpdatedForComponent()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LotNo: array[2] of Code[50];
        LotQty: Integer;
        ComponentQty: Decimal;
        PartialQtyMultiplier: Decimal;
        PickQty: array[2] of Decimal;
        Index: Integer;
    begin
        // [FEATURE] [Pick] [Production] [Item Tracking]
        // [SCENARIO 331480] When partially registered Pick is deleted for Lot Tracked Component Item and Item Tracking is updated
        // [SCENARIO 331480] then newly created Pick has same Lot as specified in Item Tracking
        Initialize();
        LotQty := 4 * LibraryRandom.RandInt(10);
        ComponentQty := LotQty / 2;
        PartialQtyMultiplier := 0.5;
        PickQty[1] := ComponentQty * PartialQtyMultiplier;
        PickQty[2] := ComponentQty * (1 - PartialQtyMultiplier);

        // [GIVEN] Lot Tracked Item "I" had stock of 100 PCS: 50 PCS with Lot L1 and 50 PCS with Lot L2
        CreateItemWithStockSeveralLots(Item, Location, LotNo, LotQty);

        // [GIVEN] Production Order with 1 PCS of Item "A" with 20 PCS of Item "I" as component
        // [GIVEN] Lot Tracking for Production Order Component had 20 PCS of Lot L1
        CreateProdOrderWithLotTrackedComponentItem(
          ProductionOrder, ProdOrderComponent, LibraryInventory.CreateItemNo(), 1, Item."No.", ComponentQty, LotNo[1], Location.Code);

        // [GIVEN] Pick was created for Production Order with Lot L1 and 20 PCS
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        VerifyWarehouseActivityTakePlaceLinesQtyAndLot(ProductionOrder."No.", Location.Code, ComponentQty, LotNo[1]);

        // [GIVEN] Registered 12 PCS and deleted Pick
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
          ProdOrderComponent."Prod. Order Line No.");
        RegisterAndDeletePartialPick(WarehouseActivityHeader, PartialQtyMultiplier);

        // [GIVEN] Quantity in old Item Tracking Line with Lot L1 was updated to 12 PCS and new Line was added with Lot L2 8 PCS
        LibraryVariableStorage.Enqueue(TrackingAction::UpdateAndAssignNew);
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(PickQty[Index]);
        end;
        ProdOrderComponent.OpenItemTrackingLines();

        // [WHEN] Create Whse. Pick
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [THEN] Pick is created with 8 PCS of Lot L2
        VerifyWarehouseActivityTakePlaceLinesQtyAndLot(ProductionOrder."No.", Location.Code, PickQty[2], LotNo[2]);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesMultipleModalPageHandler,ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WhsePickWhenItemTrackingIsReplacedForAsmComponent()
    var
        Location: Record Location;
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LotNo: array[2] of Code[50];
        LotQty: Integer;
        ComponentQty: Decimal;
        PartialQtyMultiplier: Decimal;
        SecondPickQty: Decimal;
    begin
        // [FEATURE] [Pick] [Assembly] [Item Tracking]
        // [SCENARIO 331480] When partially registered Pick is deleted for Lot Tracked Assembly Component Item and old Item Tracking is replaced
        // [SCENARIO 331480] then newly created Pick has same Lot as specified in Item Tracking
        Initialize();
        LotQty := 4 * LibraryRandom.RandInt(10);
        ComponentQty := LotQty / 2;
        PartialQtyMultiplier := 0.5;
        SecondPickQty := ComponentQty * (1 - PartialQtyMultiplier);

        // [GIVEN] Lot Tracked Item had stock of 100 PCS: 50 PCS with Lot L1 and 50 PCS with Lot L2
        CreateItemWithStockSeveralLots(Item, Location, LotNo, LotQty);

        // [GIVEN] Assembly Order with Assembly Line having 20 PCS of the Item; Lot L1 was assigned in Item Tracking for the Line
        CreateAsmOrderWithLotTrackedItemLine(
          AssemblyHeader, AssemblyLine, LibraryInventory.CreateItemNo(), 1, Item."No.", ComponentQty, LotNo[1], Location.Code);

        // [GIVEN] Pick was created for Assembly Order with Lot L1 and 20 PCS
        LibraryAssembly.ReleaseAO(AssemblyHeader);
        CreateWhsePickFromAssembly(AssemblyHeader);
        VerifyWarehouseActivityTakePlaceLinesQtyAndLot(
          AssemblyLine."Document No.", Location.Code, AssemblyLine.Quantity, LotNo[1]);

        // [GIVEN] Stan decided to register 12 PCS and delete Pick
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.",
          AssemblyLine."Line No.");
        RegisterAndDeletePartialPick(WarehouseActivityHeader, PartialQtyMultiplier);

        // [GIVEN] Item Tracking Line with 20 PCS of Lot "L1" was replaced by a new Line with 8 PCS of Lot "L2" was added
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo[2]);
        LibraryVariableStorage.Enqueue(SecondPickQty);
        AssemblyLine.OpenItemTrackingLines();

        // [WHEN] Create Whse. Pick
        CreateWhsePickFromAssembly(AssemblyHeader);

        // [THEN] Pick is created with 8 PCS of Lot "L2"
        VerifyWarehouseActivityTakePlaceLinesQtyAndLot(AssemblyLine."Document No.", Location.Code, SecondPickQty, LotNo[2]);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesMultipleModalPageHandler,ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WhsePickWhenItemTrackingIsUpdatedForAsmComponent()
    var
        Location: Record Location;
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LotNo: array[2] of Code[50];
        LotQty: Integer;
        ComponentQty: Decimal;
        PartialQtyMultiplier: Decimal;
        PickQty: array[2] of Decimal;
        Index: Integer;
    begin
        // [FEATURE] [Pick] [Assembly] [Item Tracking]
        // [SCENARIO 331480] When partially registered Pick is deleted for Lot Tracked Assembly Component Item and old Item Tracking is updated
        // [SCENARIO 331480] then newly created Pick has same Lot as specified in Item Tracking
        Initialize();
        LotQty := 4 * LibraryRandom.RandInt(10);
        ComponentQty := LotQty / 2;
        PartialQtyMultiplier := 0.5;
        PickQty[1] := ComponentQty * PartialQtyMultiplier;
        PickQty[2] := ComponentQty * (1 - PartialQtyMultiplier);

        // [GIVEN] Lot Tracked Item "I" had stock of 100 PCS: 50 PCS with Lot L1 and 50 PCS with Lot L2
        CreateItemWithStockSeveralLots(Item, Location, LotNo, LotQty);

        // [GIVEN] Assembly Order with Assembly Line having 20 PCS of the Item; Lot L1 was assigned in Item Tracking for the Line
        CreateAsmOrderWithLotTrackedItemLine(
          AssemblyHeader, AssemblyLine, LibraryInventory.CreateItemNo(), 1, Item."No.", ComponentQty, LotNo[1], Location.Code);

        // [GIVEN] Pick was created for Assembly Order with Lot L1 and 20 PCS
        LibraryAssembly.ReleaseAO(AssemblyHeader);
        CreateWhsePickFromAssembly(AssemblyHeader);
        VerifyWarehouseActivityTakePlaceLinesQtyAndLot(
          AssemblyLine."Document No.", Location.Code, AssemblyLine.Quantity, LotNo[1]);

        // [GIVEN] Stan decided to register 12 PCS and delete Pick
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.",
          AssemblyLine."Line No.");
        RegisterAndDeletePartialPick(WarehouseActivityHeader, PartialQtyMultiplier);

        // [GIVEN] Quantity in old Item Tracking Line with Lot "L1" was updated to 12 PCS and new Line was added with 8 PCS of Lot "L2"
        LibraryVariableStorage.Enqueue(TrackingAction::UpdateAndAssignNew);
        for Index := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(PickQty[Index]);
        end;
        AssemblyLine.OpenItemTrackingLines();

        // [WHEN] Create Whse. Pick
        CreateWhsePickFromAssembly(AssemblyHeader);

        // [THEN] Pick is created with 8 PCS of Lot "L2"
        VerifyWarehouseActivityTakePlaceLinesQtyAndLot(AssemblyLine."Document No.", Location.Code, PickQty[2], LotNo[2]);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,PickCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure PickWithFEFOWithMultipleILEForBlockedLot()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        LotNo: array[3] of Code[20];
        PartQty: Decimal;
    begin
        // [FEATURE] [FEFO] [Inventory Pick] [Lot Tracked Item] [Lot No. Info]
        // [SCENARIO 376045] When create Pick from Sales Order and Pick According to FEFO is used with multiple ILE for a blocked lot,
        // [SCENARIO 376045] Inventory Pick is created with quantity from non-blocked lot
        Initialize();
        PartQty := LibraryRandom.RandIntInRange(10, 50);

        // [GIVEN] Location with Pick According To FEFO, Require Pick and Bin Mandatory
        CreateAndUpdateLocation(Location, true, false, true, false, false, true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');

        // [GIVEN] Item with Item Tracking Code having Lot Tracking and Expiration Dates enabled
        CreateTrackedItem(Item, true, false, false, false, true);

        // [GIVEN] Lot "L1" with Expiration Date = 1/1/2020 and 150 PCS
        LotNo[1] := LibraryUtility.GenerateGUID();
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin.Code, LotNo[1], PartQty, CalcDate('<5Y>', WorkDate()));
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin.Code, LotNo[1], 0.5 * PartQty, CalcDate('<5Y>', WorkDate()));

        // [GIVEN] Blocked Lot "L2" with Expiration Date = 1/1/2021 and 500 PCS split between multiple Item Ledger Entries
        LotNo[2] := LibraryUtility.GenerateGUID();
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin.Code, LotNo[2], 2 * PartQty, CalcDate('<5Y+1D>', WorkDate()));
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin.Code, LotNo[2], PartQty, CalcDate('<5Y+1D>', WorkDate()));
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin.Code, LotNo[2], 2 * PartQty, CalcDate('<5Y+1D>', WorkDate()));
        SetLotBlocked(Item."No.", LotNo, 2);

        // [GIVEN] Release Sales Order "SO1" with 200 PCS
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", 2 * PartQty, Location.Code);

        // [WHEN] Create Inventory Pick from Sales Order
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // [THEN] Pick is created with 150 PCS and Lot "L1"
        VerifyWhseActivityLotNo(Location.Code, Item."No.", 1.5 * PartQty, LotNo[1]);

        // [THEN] No Lot "L2" lines created on the pick
        FilterWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", Location.Code, WarehouseActivityLine."Activity Type"::"Invt. Pick",
          WarehouseActivityLine."Action Type"::Take, '', '');
        WarehouseActivityLine.SetRange("Lot No.", LotNo[2]);
        Assert.RecordIsEmpty(WarehouseActivityLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesWhenInvtMovementFromAsmConsumptionWithFEFO()
    var
        Bin: array[2] of Record Bin;
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        ReservationEntry: Record "Reservation Entry";
        Location: Record Location;
        LotNo: Code[50];
        PartQty: Decimal;
    begin
        // [FEATURE] [FEFO] [Lot Tracked Item] [Inventory Movement] [Assembly Order] [Consumption]
        // [SCENARIO 372941] Inventory Movement created for Assembly Consumption of Lot-Tracked Item with FEFO in use does not create Whse. Item Tracking Lines. They are created at the moment you register the inventory movement.
        Initialize();
        PartQty := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Location with Pick According To FEFO, Require Pick, Put-away and Bin Mandatory
        CreateAndUpdateLocation(Location, true, true, true, false, false, true);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, '', '', '');
        Location.Validate("To-Assembly Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Item "CHILD" with Item Tracking Code having Lot Tracking and expiration dates enabled
        CreateTrackedItem(Item, true, false, false, false, true);

        // [GIVEN] Lot "L1" with Expiration Date = 1/1/2020 and 15 PCS of "CHILD" Item
        LotNo := LibraryUtility.GenerateGUID();
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin[1].Code, LotNo, PartQty, CalcDate('<5Y>', WorkDate()));

        // [GIVEN] Assembly Order to make an Item from 15 PCS of "CHILD" Item created and released
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), Location.Code, 1, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", PartQty, PartQty, '');
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        // [WHEN] Create Inventory Movement from Assembly Order
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Assembly Consumption", AssemblyHeader."No.", false, false, true);

        // [THEN] No Whse. Item Tracking Lines are created by this moment.
        WhseItemTrackingLine.SetRange("Location Code", Location.Code);
        Assert.RecordIsEmpty(WhseItemTrackingLine);

        // [THEN] Register the inventory movement.
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(),
          AssemblyLine."Document No.", AssemblyLine."Line No.");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Whse. item tracking lines for the assembly line with lot "L1" are now created.
        WhseItemTrackingLine.SetSourceFilter(
          DATABASE::"Assembly Line", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", AssemblyLine."Line No.", false);
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.TestField("Lot No.", LotNo);

        // [THEN] An item tracking line with lot "L1" is assigned to the assembly line.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Lot No.", LotNo);

        // [THEN] The assembly line is reserved from inventory.
        ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.Get(ReservationEntry."Entry No.", true);
        ReservationEntry.TestField("Source Type", Database::"Item Ledger Entry");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesWhenInvtMovementFromProdComponentWithFEFO()
    var
        Bin: array[2] of Record Bin;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        ReservationEntry: Record "Reservation Entry";
        Location: Record Location;
        LotNo: Code[50];
        PartQty: Decimal;
    begin
        // [FEATURE] [FEFO] [Lot Tracked Item] [Inventory Movement] [Prod. Order Component]
        // [SCENARIO 372941] Inventory Movement created for Prod. Order Component of Lot-Tracked Item with FEFO in use does not create Whse. Item Tracking Lines. They are created at the moment you register the inventory movement.
        Initialize();
        PartQty := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Location with Pick According To FEFO, Require Pick, Put-away and Bin Mandatory
        CreateAndUpdateLocation(Location, true, true, true, false, false, true);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, '', '', '');
        Location.Validate("To-Production Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Item "CHILD" with Item Tracking Code having Lot Tracking and expiration dates enabled
        CreateTrackedItem(Item, true, false, false, false, true);

        // [GIVEN] Lot "L1" with Expiration Date = 1/1/2020 and 15 PCS of "CHILD" Item
        LotNo := LibraryUtility.GenerateGUID();
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin[1].Code, LotNo, PartQty, CalcDate('<5Y>', WorkDate()));

        // [GIVEN] Released Prod. Order to make an Item from 15 PCS of "CHILD" Item with manual flushing
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", LibraryInventory.CreateItemNo(), '', Location.Code, 1);
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", Item."No.");
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Validate("Flushing Method", ProdOrderComponent."Flushing Method"::"Pick + Manual");
        ProdOrderComponent.Validate("Quantity per", PartQty);
        ProdOrderComponent.Modify(true);

        // [WHEN] Create Inventory Movement from Production Order
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // [THEN] No Whse. Item Tracking Lines are created by this moment.
        WhseItemTrackingLine.SetRange("Location Code", Location.Code);
        Assert.RecordIsEmpty(WhseItemTrackingLine);

        // [THEN] Register the inventory movement.
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(),
          ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Line No.");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Whse. item tracking lines for the prod. order component with lot "L1" are now created.
        WhseItemTrackingLine.SetSourceFilter(
          DATABASE::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
          ProdOrderComponent."Line No.", false);
        WhseItemTrackingLine.SetSourceFilter('', ProdOrderComponent."Line No.");
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.TestField("Lot No.", LotNo);

        // [THEN] An item tracking line with lot "L1" is assigned to the prod. order component.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
          ProdOrderComponent."Line No.", false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Lot No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    procedure WhseItemTrackingLinesWhenInvtMovementPostedPartiallyFromAsmWithFEFO()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [FEFO] [Item Tracking] [Inventory Movement] [Assembly]
        // [SCENARIO 392021] Second inventory movement created for assembly consumption for lot-tracked component has proper quantity.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Location with Pick According To FEFO, Require Pick, Put-away and Bin Mandatory.
        CreateAndUpdateLocation(Location, true, true, true, false, false, true);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, '', '', '');
        Location.Validate("To-Assembly Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Lot-tracked item "COMP".
        CreateTrackedItem(Item, true, false, false, false, true);

        // [GIVEN] Lot "L1" with expiration date = WorkDate() + 1 month.
        // [GIVEN] Post 20 pcs of "COMP" item to inventory.
        LotNo := LibraryUtility.GenerateGUID();
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin[1].Code, LotNo, Qty, LibraryRandom.RandDate(30));

        // [GIVEN] Assembly order to make a new item from 20 pcs of "COMP".
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), Location.Code, 1, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", Qty, Qty, '');
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        // [GIVEN] Create inventory movement for the assembly.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Assembly Consumption", AssemblyHeader."No.", false, false, true);

        // [GIVEN] Partially register the inventory movement (15 of 20 pcs).
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(),
          AssemblyLine."Document No.", AssemblyLine."Line No.");
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", Qty * 3 / 4);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Delete the inventory movement.
        WarehouseActivityHeader.Find();
        WarehouseActivityHeader.Delete(true);

        // [WHEN] Create another inventory movement for the assembly.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Assembly Consumption", AssemblyHeader."No.", false, false, true);

        // [THEN] The inventory movement for 5 pcs has been created.
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(),
          AssemblyLine."Document No.", AssemblyLine."Line No.");
        WarehouseActivityLine.TestField(Quantity, Qty / 4);

        // [THEN] The inventory movement can be registered.
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] An item tracking line with lot "L1" and quantity = 20 pcs is assigned to the assembly line.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", false);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, -Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    procedure PartialPostingOfInvtMovementForAssemblyComponentWithEnabledFEFO()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [FEFO] [Item Tracking] [Inventory Movement] [Assembly]
        // [SCENARIO 408800] Second inventory movement created for assembly consumption for lot-tracked component respects FEFO.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Location with Pick According To FEFO, Require Pick, Put-away and Bin Mandatory.
        CreateAndUpdateLocation(Location, true, true, true, false, false, true);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, '', '', '');
        Location.Validate("To-Assembly Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Lot-tracked item "COMP".
        CreateTrackedItem(Item, true, false, false, false, true);

        // [GIVEN] Post 1 pc of item "COMP", lot "L1", expiration date = WorkDate() + 10 to inventory.
        LotNos[1] := LibraryUtility.GenerateGUID();
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin[1].Code, LotNos[1], 1, LibraryRandom.RandDate(10));

        // [GIVEN] Post 10 pcs of item "COMP", lot "L2", expiration date = WorkDate() + 20 to inventory.
        LotNos[2] := LibraryUtility.GenerateGUID();
        PostItemJournalLineWithLotNoExpiration(
          Item."No.", Location.Code, Bin[1].Code, LotNos[2], Qty, LibraryRandom.RandDateFromInRange(WorkDate(), 11, 20));

        // [GIVEN] Assembly order to make a new item from 10 pcs of "COMP".
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), Location.Code, 1, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", Qty, Qty, '');
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        // [GIVEN] Create inventory movement for the assembly.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Assembly Consumption", AssemblyHeader."No.", false, false, true);

        // [GIVEN] Partially register the inventory movement - 0 pcs of lot "L1", 5 pcs of lot "L2".
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Lot No.", LotNos[1]);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", 0);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
        WarehouseActivityLine.SetRange("Lot No.", LotNos[2]);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", Qty / 2);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Delete the inventory movement.
        WarehouseActivityHeader.Find();
        WarehouseActivityHeader.Delete(true);

        // [WHEN] Create another inventory movement for the assembly.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Assembly Consumption", AssemblyHeader."No.", false, false, true);

        // [THEN] The inventory movement for 1 pc of lot "L1" and 4 pcs of lot "L2" has been created.
        WarehouseActivityLine.SetRange("Lot No.", LotNos[1]);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, 1);

        WarehouseActivityLine.SetRange("Lot No.", LotNos[2]);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, Qty / 2 - 1);

        // [THEN] The inventory movement can be registered.
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    procedure NotExpiredItemsAreNotExcludedFromInventoryPick()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        ExpiredItem: Record Item;
        GoodItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        // [FEATURE] [FEFO] [Item Tracking] [Inventory Movement] [Assembly]
        // [SCENARIO 445492] Creating inventory pick must include items that are not expired and skip expired ones.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Location set up for bin mandatory, bin according to FEFO, and required put-away and pick.
        CreateAndUpdateLocation(Location, true, true, true, false, false, true);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, '', '', '');
        Location.Validate("To-Assembly Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Lot-tracked item "E" with required expiration date.
        CreateTrackedItem(ExpiredItem, true, false, true, false, true);

        // [GIVEN] Item "G".
        LibraryInventory.CreateItem(GoodItem);

        // [GIVEN] Post item "E" to inventory, assign lot number and set "Expiration Date" < WorkDate(), so it is expired.
        PostItemJournalLineWithLotNoExpiration(
          ExpiredItem."No.", Location.Code, Bin[1].Code, LibraryUtility.GenerateGUID(), Qty, CalcDate('<-1W>', WorkDate()));

        // [GIVEN] Post item "G" to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, GoodItem."No.", Location.Code, Bin[1].Code, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Assembly order with two components - "E" and "G", release.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), Location.Code, 1, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ExpiredItem."No.", ExpiredItem."Base Unit of Measure", Qty, Qty, '');
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, GoodItem."No.", GoodItem."Base Unit of Measure", Qty, Qty, '');
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        // [WHEN] Create inventory movement for the assembly order.
        LibraryWarehouse.CreateInvtPutPickMovement(
          "Warehouse Request Source Document"::"Assembly Consumption", AssemblyHeader."No.", false, false, true);

        // [THEN] Item "G" is included to the new inventory movement.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.SetRange("Item No.", GoodItem."No.");
        Assert.RecordIsNotEmpty(WarehouseActivityLine);

        // [THEN] Expired item "E" is not included.
        WarehouseActivityLine.SetRange("Item No.", ExpiredItem."No.");
        Assert.RecordIsEmpty(WarehouseActivityLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateWhsePickForAsmOrderWithPickOptional()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehousePickHeader: Record "Warehouse Activity Header";
        WarehousePickLine: Record "Warehouse Activity Line";
    begin
        // [Bug 459237] WhsePick/Assembly- system creates warehouse pick for completely posted lines. 
        Initialize();

        // [GIVEN] An Assembly Order for 2 pieces of the parent item
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)";
        Location.Modify();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), Location.Code, 2, '');

        // [GIVEN] One Assembly Line with "Qty. per" = 1 and location (which has "Require pick" = false) 
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, Location.Code);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", 2, 1, '');
        AssemblyLine.Validate("Location Code", Location.Code);
        AssemblyLine.Modify();

        // [WHEN] The order is posted for just one item (No pick was created)
        AssemblyHeader.Validate("Quantity to Assemble", 1);
        AssemblyHeader.Modify();
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");

        // [THEN] Qty. Picked is updated to 1 as Qty. Picked (0) < Qty. Posted (1)
        AssemblyLine.Get(AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.");
        AssemblyLine.TestField(AssemblyLine."Consumed Quantity", 1);
        AssemblyLine.TestField(AssemblyLine."Qty. Picked", 1);

        // [WHEN] We create a pick for the remaining 1 item to be assemble
        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId(), 0, false, false, false);
        FindPickLine(WarehousePickLine, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyHeader."No.");
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehousePickHeader, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.",
          AssemblyLine."Line No.");

        // [THEN] The quantity of the pick is 1
        Assert.AreEqual(1, WarehousePickLine.Quantity, 'Expected Qty To Pick to be 1, since only 1 item is left to be assembled.');

        // [WHEN] The Pick is registered
        LibraryWarehouse.RegisterWhseActivity(WarehousePickHeader);

        // [THEN] Qty. Picked is increased by 1.
        AssemblyLine.Get(AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.");
        AssemblyLine.TestField(AssemblyLine."Qty. Picked", 2);

        // [GIVEN] The quantity is increased to 3
        LibraryAssembly.ReopenAO(AssemblyHeader);
        AssemblyHeader.Validate("Quantity", 3);
        AssemblyHeader.Modify();

        // [WHEN] The order is posted for one item (Which has just been picked)
        AssemblyHeader.Validate("Quantity to Assemble", 1);
        AssemblyHeader.Modify();
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");

        // [THEN] Qty. Picked is still 2, as Qty. Picked (2) = Qty. Posted (2)
        AssemblyLine.Get(AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.");
        AssemblyLine.TestField(AssemblyLine."Consumed Quantity", 2);
        AssemblyLine.TestField(AssemblyLine."Qty. Picked", 2);

        // [WHEN] We create a Warehouse Pick for the remaining 1 item to be assemble
        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId(), 0, false, false, false);
        FindPickLine(WarehousePickLine, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyHeader."No.");
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehousePickHeader, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.",
          AssemblyLine."Line No.");

        // [THEN] The quantity of the pick is 1 (One was consumed w.o. pick. One was consumed with pick. One is left to pick)
        Assert.AreEqual(1, WarehousePickLine.Quantity, 'Expected Qty to pick to be 1, since only 1 item is left to be assembled.');

        // [WHEN] Register the pick
        LibraryWarehouse.RegisterWhseActivity(WarehousePickHeader);

        // [THEN] Qty. Picked is updated to 3
        AssemblyLine.Get(AssemblyLine."Document Type", AssemblyLine."Document No.", AssemblyLine."Line No.");
        AssemblyLine.TestField(AssemblyLine."Qty. Picked", 3);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhsePickNotAllowedFoConsumedItemOnAsmOrderWithPickOptional()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehousePickHeader: Record "Warehouse Activity Header";
        WarehousePickLine: Record "Warehouse Activity Line";
    begin
        // [Bug 459237] WhsePick/Assembly- system creates warehouse pick for completely posted lines.
        // [SCENARIO] Whse. pick is allowed only for quantity not yet picked or consumed.
        Initialize();

        // [GIVEN] An Assembly Order for 5 pieces of the parent item
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)";
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), Location.Code, 5, '');

        // [GIVEN] One Assembly Line with "Qty. per" = 1 and location (which has "Require pick" = false) 
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, Location.Code);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", 2, 1, '');
        AssemblyLine.Validate("Location Code", Location.Code);
        AssemblyLine.Modify();

        // [GIVE] Create warehouse pick for the items
        AssemblyHeader.Validate(Status, AssemblyHeader.Status::Released);
        AssemblyHeader.Modify();
        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId(), 0, false, false, false);
        FindPickLine(WarehousePickLine, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyHeader."No.");
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehousePickHeader, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.",
          AssemblyLine."Line No.");

        // [THEN] The quantity of the pick is 5
        WarehousePickLine.TestField(WarehousePickLine.Quantity, AssemblyLine.Quantity);

        // [WHEN] Update Quantity to Consume on Assembly header
        asserterror AssemblyHeader.Validate("Quantity to Assemble", 3);

        // [THEN] Error: active warehouse line exists
        Assert.ExpectedError('must not be changed');

        // [WHEN] Update Quantity to Consume on Assembly Line
        asserterror AssemblyLine.Validate("Quantity to Consume", 3);

        // [THEN] Error: active warehouse line exists
        Assert.ExpectedError('must not be changed');

        // [GIVEN] The order is posted without registering the created picks.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [WHEN] We register the Warehouse Pick.
        FindPickLine(WarehousePickLine, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyHeader."No.");
        LibraryWarehouse.FindWhseActivityBySourceDoc(WarehousePickHeader, DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.");
        asserterror LibraryWarehouse.RegisterWhseActivity(WarehousePickHeader);

        // [THEN] Cannot register pick because the items are already consumed as the assembly line is deleted.
        Assert.ExpectedError('does not exist');
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPostOneHandler,ConfirmHandler2,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateWhsePickForProductionOrderWithPickOptional()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
        WarehousePickHeader: Record "Warehouse Activity Header";
        WarehousePickLine: Record "Warehouse Activity Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // [Bug 459238] WhsePick/Prod Ord- system creates warehouse pick for completely posted lines. 
        Initialize();

        // [GIVEN] Inventory of Item on Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, Location.Code);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] A Production Order with one line with qty 1 of an item
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, LibraryInventory.CreateItemNo(), 1);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", LibraryInventory.CreateItemNo(), '', Location.Code, 1);

        // [GIVEN] One Component to the line with Qty. per = 2
        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", Item."No.");
        ProdOrderComponent.Validate("Quantity per", 2);
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Modify();

        // [WHEN] One component item is consumed via. the Production Journal
        LibraryVariableStorage.Enqueue(Item."No.");
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderComponent."Prod. Order Line No.");

        // [THEN] Qty. Picked is updated to 1 as Qty. Picked (0) < Qty. Posted (1)
        ProdOrderComponent.Find('=');
        ProdOrderComponent.CalcFields("Act. Consumption (Qty)");
        ProdOrderComponent.TestField("Act. Consumption (Qty)", 1);
        ProdOrderComponent.TestField("Qty. Picked", 1);

        // [WHEN] We create a Warehouse Pick for the Production Order
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        FindPickLine(WarehousePickLine, Database::"Prod. Order Component", "Production Order Status"::Released.AsInteger(), ProductionOrder."No.");
        LibraryWarehouse.FindWhseActivityBySourceDoc(WarehousePickHeader, Database::"Prod. Order Component", "Production Order Status"::Released.AsInteger(), ProductionOrder."No.", ProdOrderLine."Line No.");

        // [THEN] The quantity of the pick is 1
        Assert.AreEqual(1, WarehousePickLine."Qty. (Base)", 'Expected Qty to pick to be 1, since only 1 component item is left to be consumed.');

        // [WHEN] The Pick is registered
        LibraryWarehouse.RegisterWhseActivity(WarehousePickHeader);

        // [THEN] Qty. Picked is increased by 1, Qty. Picked = 2
        ProdOrderComponent.Find('=');
        ProdOrderComponent.CalcFields("Act. Consumption (Qty)");
        ProdOrderComponent.TestField("Act. Consumption (Qty)", 1);
        ProdOrderComponent.TestField("Qty. Picked", 2);

        // [GIVEN] The Qty. per (equal to the expected quantity in this case) is increase to 3
        ProdOrderComponent.Find('=');
        ProdOrderComponent.Validate("Quantity per", 3);
        ProdOrderComponent.Modify();

        // [WHEN] One component item is consumed via. the Production Journal
        LibraryVariableStorage.Enqueue(Item."No.");
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderComponent."Prod. Order Line No.");

        // [THEN] Qty. Picked stays as 2 as Qty. Picked(2) = Qty Posted (2)
        ProdOrderComponent.Find('=');
        ProdOrderComponent.CalcFields("Act. Consumption (Qty)");
        ProdOrderComponent.TestField("Act. Consumption (Qty)", 2);
        ProdOrderComponent.TestField("Qty. Picked", 2);

        // [WHEN] We create a Warehouse Pick for the Production Order for the remaining 1 qty
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        FindPickLine(WarehousePickLine, Database::"Prod. Order Component", "Production Order Status"::Released.AsInteger(), ProductionOrder."No.");
        LibraryWarehouse.FindWhseActivityBySourceDoc(WarehousePickHeader, Database::"Prod. Order Component", "Production Order Status"::Released.AsInteger(), ProductionOrder."No.", ProdOrderLine."Line No.");

        // [THEN] The quantity of the pick is 1 (One was consumed w.o. pick. One was consumed with pick. One is left to pick)
        Assert.AreEqual(1, WarehousePickLine.Quantity, 'Expected Qty to pick to be 1, since only 1 component item is left to be consumed.');
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPostHandler,ConfirmHandler2,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhsePickNotAllowedFoConsumedItemOnProdCompWithPickOptional()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
        WarehousePickHeader: Record "Warehouse Activity Header";
        WarehousePickLine: Record "Warehouse Activity Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // [Bug 459238] WhsePick/Prod Ord- system creates warehouse pick for completely posted lines.
        // [SCENARIO] Create pick is allowed only for quantity not yet picked or consumed.

        Initialize();

        // [GIVEN] Inventory of Item on Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJnlLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), Item."No.", 10, Location.Code);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] A Production Order with one line with qty 1 of an item
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, LibraryInventory.CreateItemNo(), 1);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", LibraryInventory.CreateItemNo(), '', Location.Code, 1);

        // [GIVEN] One Component to the line with Qty. per = 5
        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", Item."No.");
        ProdOrderComponent.Validate("Quantity per", 5);
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Modify();

        // [WHEN] We create a Warehouse Pick for the Production Order
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        FindPickLine(WarehousePickLine, Database::"Prod. Order Component", "Production Order Status"::Released.AsInteger(), ProductionOrder."No.");
        LibraryWarehouse.FindWhseActivityBySourceDoc(WarehousePickHeader, Database::"Prod. Order Component", "Production Order Status"::Released.AsInteger(), ProductionOrder."No.", ProdOrderLine."Line No.");

        // [THEN] The quantity of the pick is 5
        Assert.AreEqual(5, WarehousePickLine."Qty. (Base)", 'Expected Qty to pick to be 5.');

        // [GIVEN] All the component items are consumed via. the Production Journal
        LibraryVariableStorage.Enqueue(Item."No.");
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderComponent."Prod. Order Line No.");

        // [THEN] Qty. Picked is updated to 5 as Qty. Picked (0) < Qty. Posted (5)
        ProdOrderComponent.Find('=');
        ProdOrderComponent.CalcFields("Act. Consumption (Qty)");
        ProdOrderComponent.TestField("Act. Consumption (Qty)", 5);
        ProdOrderComponent.TestField("Qty. Picked", 5);

        // [WHEN] We register pick for 5 quantity 
        asserterror LibraryWarehouse.RegisterWhseActivity(WarehousePickHeader);

        // [THEN] Cannot register pick because the items are already consumed.
        Assert.ExpectedError('is partially or completely consumed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckWhseClassOnLocation()
    var
        Location: Record Location;
        LocationCard: TestPage "Location Card";
    begin
        // [Scenario] 'Check Whse. Class' field on the Location card behaves as expected
        Initialize();

        // [GIVEN] Create Location
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] Location card is opened for the created Location record
        LocationCard.OpenEdit();
        LocationCard.GoToRecord(Location);

        // [THEN] 'Bin Mandatory' and 'Check Whse. Class' are false
        LocationCard."Bin Mandatory".AssertEquals(false);
        LocationCard."Check Whse. Class".AssertEquals(false);

        // [THEN] 'Check Whse. Class' field is disabled
        Assert.IsFalse(LocationCard."Check Whse. Class".Enabled(), 'Check Whse. Class field should be disabled.');

        // [WHEN] 'Bin Mandatory' is set to true
        LocationCard."Bin Mandatory".SetValue(true);

        // [THEN] 'Check Whse. Class' field is still set to false but the field becomes editable
        LocationCard."Check Whse. Class".AssertEquals(false);
        Assert.IsTrue(LocationCard."Check Whse. Class".Enabled(), 'Check Whse. Class field should not be disabled.');

        // [WHEN] 'Check Whse. Class' is enabled and 'Bin Mandatory' is disabled
        LocationCard."Check Whse. Class".SetValue(true);
        LocationCard."Bin Mandatory".SetValue(false);

        // [THEN] 'Check Whse. Class' is disabled as well and is not editable
        LocationCard."Check Whse. Class".AssertEquals(false);
        Assert.IsFalse(LocationCard."Check Whse. Class".Enabled(), 'Check Whse. Class field should be disabled.');

        // [WHEN] 'Directed Put-away and Pick' is enabled
        LocationCard."Bin Mandatory".SetValue(true);
        LocationCard."Directed Put-away and Pick".AssertEquals(false);
        LocationCard."Directed Put-away and Pick".SetValue(true);

        // [THEN] 'Check Whse. Class' is enabled but the field is not editable
        LocationCard."Check Whse. Class".AssertEquals(true);
        Assert.IsFalse(LocationCard."Check Whse. Class".Enabled(), 'Check Whse. Class field should be disabled.');

        // [WHEN] 'Directed Put-away and Pick' is disabled
        LocationCard."Directed Put-away and Pick".SetValue(false);

        // [THEN] 'Check Whse. Class' continues to be enabled but the field turns to be editable
        LocationCard."Check Whse. Class".AssertEquals(true);
        Assert.IsTrue(LocationCard."Check Whse. Class".Enabled(), 'Check Whse. Class field should not be disabled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSpecialEquipmentOnLocation()
    var
        Location: Record Location;
        LocationCard: TestPage "Location Card";
    begin
        // [Scenario] 'Special Equipment' field on the Location card behaves as expected
        Initialize();

        // [GIVEN] Create Location
        LibraryWarehouse.CreateLocation(Location);

        // [WHEN] Location card is opened for the created Location record
        LocationCard.OpenEdit();
        LocationCard.GoToRecord(Location);

        // [THEN] 'Bin Mandatory' is false and 'Special Equipment' is ''
        LocationCard."Bin Mandatory".AssertEquals(false);
        LocationCard."Special Equipment".AssertEquals(false);

        // [THEN] 'Special Equipment' field is disabled
        Assert.IsFalse(LocationCard."Special Equipment".Enabled(), 'Special Equipment field should be disabled.');

        // [WHEN] 'Bin Mandatory' is set to true
        LocationCard."Bin Mandatory".SetValue(true);

        // [THEN] 'Special Equipment' field becomes editable
        Assert.IsTrue(LocationCard."Special Equipment".Enabled(), 'Special Equipment field should not be disabled.');
    end;

    [Test]
    procedure RegisterWhsePickWithBreakbulkForConsumption()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Warehouse Pick] [Breakbulk] [Consumption]
        // [SCENARIO 466792] Register warehouse pick with breakbulk for consumption.
        Initialize();

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, false);

        // [GIVEN] Item "I" with base unit of measure "BOX" and alternate unit of measure "PCS" = 0.1 "BOX".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 0.1);

        // [GIVEN] Post 1 "BOX" to inventory at directed put-away and pick location.
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(Item."No.", LocationWhite.Code, 1, false);

        // [GIVEN] Create production order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, LibraryInventory.CreateItemNo(), 1);
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", ProductionOrder."Source No.", '', LocationWhite.Code, 1);

        // [GIVEN] Add item "I" as component.
        // [GIVEN] "Quantity Per" = 1 "PCS".
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", Item."No.");
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProdOrderComponent.Validate("Location Code", LocationWhite.Code);
        ProdOrderComponent.TestField("Expected Qty. (Base)", 0.1);
        ProdOrderComponent.Modify();

        // [GIVEN] Create warehouse pick for prod. order component.
        // [GIVEN] Ensure the pick includes breakbulk lines.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        WarehouseActivityLine.SetFilter("Breakbulk No.", '<>0');
        FindPickLine(
          WarehouseActivityLine, Database::"Prod. Order Component", "Production Order Status"::Released.AsInteger(),
          ProductionOrder."No.");

        // [WHEN] Register the warehouse pick.
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, Database::"Prod. Order Component", "Production Order Status"::Released.AsInteger(),
          ProductionOrder."No.", ProdOrderLine."Line No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] The pick has been successfully registered.
        ProdOrderComponent.Find();
        ProdOrderComponent.TestField("Qty. Picked", 1);
        ProdOrderComponent.TestField("Qty. Picked (Base)", 0.1);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPostOneHandler,ConfirmHandler2,MessageHandler')]
    procedure PostingConsumptionWithAlternateUoMAtLocationWithNoPick()
    var
        Location: Record Location;
        CompItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // [FEATURE] [Production] [Consumption] [Unit of Measure]
        // [SCENARIO 473386] "Qty. Picked" is properly updated on posting prod. order component with alternate unit of measure.
        Initialize();

        // [GIVEN] Location that is not set up for warehouse.
        // [GIVEN] Item "C" with base unit of measure = "PC" and alternate UoM "GR" = 0.001 "PC".
        // [GIVEN] Post 1 PC of item "C" to inventory.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, CompItem."No.", 0.001);
        LibraryInventory.CreateItemJnlLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate(), CompItem."No.", LibraryRandom.RandInt(10), Location.Code);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Production order at the location.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, LibraryInventory.CreateItemNo(), 1);
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", ProductionOrder."Source No.", '', Location.Code, 1);

        // [GIVEN] Add 1 "GR" of item "C" to prod. order components.
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", CompItem."No.");
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Modify();

        // [WHEN] Post consumption.
        LibraryVariableStorage.Enqueue(CompItem."No.");
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderComponent."Prod. Order Line No.");

        // [THEN] The consumption has been successfully posted.
        // [THEN] "Qty. Picked" is updated to 1.
        // [THEN] "Qty. Picked (Base)" is updated to 0.001.
        ProdOrderComponent.Find();
        ProdOrderComponent.CalcFields("Act. Consumption (Qty)");
        ProdOrderComponent.TestField("Act. Consumption (Qty)", 0.001);
        ProdOrderComponent.TestField("Qty. Picked", 1);
        ProdOrderComponent.TestField("Qty. Picked (Base)", 0.001);
        ProdOrderComponent.TestField("Completely Picked");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure ZoneCodeShouldFlowToWarehouseEntriesWhenPostProductionJournal()
    var
        Item: Record Item;
        Item2: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        Zone: Record Zone;
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseEntry: Record "Warehouse Entry";
        ItemJournalBatchConsumptionJnl: Record "Item Journal Batch";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // [SCENARIO 481027] Zone is missing in warehouse entries created via for production posting
        // [SCENARIO 566206] Zone is missing in warehouse entries created via for negative consumption posting
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Item 2.
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create Location.
        CreateLocation(Location);

        // [GIVEN] Create Zone.
        LibraryWarehouse.CreateZone(Zone, Zone.Code, Location.Code, '', '', '', 0, false);

        // [GIVEN] Create Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, Zone.Code, '');

        // [GIVEN] Create Item Journal line & Validate Location Code & Bin code.
        CreateItemJournalLine(ItemJnlTemplate, ItemJnlBatch, ItemJnlLine, Item);
        ItemJnlLine.Validate("Location Code", Location.Code);
        ItemJnlLine.Validate("Bin Code", Bin.Code);
        ItemJnlLine.Modify(true);

        // [GIVEN] Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlTemplate.Name, ItemJnlBatch.Name);

        // [GIVEN] Create Released Production Order & Refresh it.
        CreateReleasedProdOrderAndRefresh(ProductionOrder, Item2, Location.Code, Bin.Code, LibraryRandom.RandInt(0));

        // [GIVEN] Add Component Line to Released Production Order.
        AddComponentToProdOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(0), Location.Code, Bin.Code, Item."Flushing Method");

        // [GIVEN] Find Production Order Line.
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Post Production Journal.
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Find Warehouse Entry for Source Document Output Jnl.
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"Output Jnl.");
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.FindFirst();

        // [VERIFY] Verify Warehouse Entry Zone Code & Zone Code are same.
        Assert.AreEqual(Zone.Code, WarehouseEntry."Zone Code", ZoneCodeMustMatchErr);

        // [WHEN] Find Warehouse Entry for Source Document Consumption Jnl.
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"Consumption Jnl.");
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.FindFirst();

        // [VERIFY] Verify Warehouse Entry Zone Code & Zone Code are same.
        Assert.AreEqual(Zone.Code, WarehouseEntry."Zone Code", ZoneCodeMustMatchErr);

        // [GIVEN] Create Consumption Journal for negative consumption.
        LibraryManufacturing.CreateConsumptionJournalLine(
            ItemJournalBatchConsumptionJnl, ProdOrderLine, Item, WorkDate(), Location.Code, '', -WarehouseEntry.Quantity, Item."Unit Cost");
        ItemJnlLine.SetRange("Journal Template Name", ItemJournalBatchConsumptionJnl."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJournalBatchConsumptionJnl.Name);
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Bin Code", Bin.Code);
        ItemJnlLine.Modify(true);

        // [WHEN] Post Consumption Journal for negative consumption.
        LibraryInventory.PostItemJournalBatch(ItemJournalBatchConsumptionJnl);

        // [THEN] Find Warehouse Entry for Source Document Consumption Jnl. Verify Warehouse Entry Zone Code & Zone Code are same.
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"Consumption Jnl.");
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.FindLast();
        Assert.AreEqual(Zone.Code, WarehouseEntry."Zone Code", ZoneCodeMustMatchErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerGetText')]
    [Scope('OnPrem')]
    procedure ZoneCodeShouldFlowToWarehouseEntriesWhenPostInventoryPick()
    var
        Item: Record Item;
        Item2: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        Zone: Record Zone;
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [SCENARIO 481027] Zone is missing in warehouse entries created via for production posting
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Item 2.
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create Location & Validate Prod Consump Whse Handling.
        CreateLocation(Location);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");
        Location.Modify(true);

        // [GIVEN] Create Zone.
        LibraryWarehouse.CreateZone(Zone, Zone.Code, Location.Code, '', '', '', 0, false);

        // [GIVEN] Create Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, Zone.Code, '');

        // [GIVEN] Create Item Journal Line & Validate Location Code & Bin Code.
        CreateItemJournalLine(ItemJnlTemplate, ItemJnlBatch, ItemJnlLine, Item);
        ItemJnlLine.Validate("Location Code", Location.Code);
        ItemJnlLine.Validate("Bin Code", Bin.Code);
        ItemJnlLine.Modify(true);

        // [GIVEN] Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlTemplate.Name, ItemJnlBatch.Name);

        // [GIVEN] Create Released Production Order & Refresh it.
        CreateReleasedProdOrderAndRefresh(ProductionOrder, Item2, Location.Code, Bin.Code, LibraryRandom.RandInt(0));

        // [GIVEN] Add Component to Released Production Order.
        AddComponentToProdOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(0), Location.Code, Bin.Code, Item."Flushing Method");

        // [GIVEN] Run Create Inventory PutAway/Pick/Movement & Create Inventory Pick.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Fill Qty to Handle in Inventory Pick.
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // [GIVEN] Post Inventory Pick.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [WHEN] Find Warehouse Entry of Bin Code.
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.FindFirst();

        // [VERIFY] Verify Warehouse Entry Zone Code & Zone Code are same.
        Assert.AreEqual(Zone.Code, WarehouseEntry."Zone Code", ZoneCodeMustMatchErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerGetText')]
    [Scope('OnPrem')]
    procedure ZoneCodeShouldFlowToWarehouseEntriesWhenRegisterPick()
    var
        Item: Record Item;
        Item2: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        Bin2: Record Bin;
        Zone: Record Zone;
        Zone2: Record Zone;
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [SCENARIO 481027] Zone is missing in warehouse entries created via for production posting
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Item 2.
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create Location.
        CreateLocation(Location);

        // [GIVEN] Create Zone.
        LibraryWarehouse.CreateZone(Zone, Zone.Code, Location.Code, '', '', '', 0, false);

        // [GIVEN] Create Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, Zone.Code, '');

        // [GIVEN] Create Zone 2.
        LibraryWarehouse.CreateZone(Zone2, Zone2.Code, Location.Code, '', '', '', 0, false);

        // [GIVEN] Create Bin 2.
        LibraryWarehouse.CreateBin(Bin2, Location.Code, Bin2.Code, Zone2.Code, '');

        // [GIVEN] Validate Require Shipment, Require Pick & Shipment Bin Code in Location.
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Shipment Bin Code", Bin2.Code);
        Location.Modify(true);

        // [GIVEN] Create Item Journal Line & Validate Location Code & Bin Code.
        CreateItemJournalLine(ItemJnlTemplate, ItemJnlBatch, ItemJnlLine, Item);
        ItemJnlLine.Validate("Location Code", Location.Code);
        ItemJnlLine.Validate("Bin Code", Bin.Code);
        ItemJnlLine.Modify(true);

        // [GIVEN] Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlTemplate.Name, ItemJnlBatch.Name);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Create a Sales Line & Validate Location Code, Bin Code & Qty to Ship.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(0));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Bin Code", Bin.Code);
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandInt(0));
        SalesLine.Modify(true);

        // [GIVEN] Release Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Warehouse Shipment from Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Find Warehouse Shipment Line.
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesHeader."Document Type");
        WarehouseShipmentLine.FindLast();

        // [GIVEN] Find Warehouse Shipment Header.
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        // [GIVEN] Release Warehosue Shipment.
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [GIVEN] Create Warehosue Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Register Warehouse Pick.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Find Warehouse Entry of Entry Type S Order & Bin Code.
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"S. Order");
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.FindFirst();

        // [VERIFY] Verify Warehouse Entry Zone Code & Zone Code are same.
        Assert.AreEqual(Zone.Code, WarehouseEntry."Zone Code", ZoneCodeMustMatchErr);

        // [WHEN] Find Warehouse Entry of Entry Type S Order & Bin 2 Code.
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"S. Order");
        WarehouseEntry.SetRange("Bin Code", Bin2.Code);
        WarehouseEntry.FindFirst();

        // [VERIFY] Verify Warehouse Entry Zone Code & Zone 2 Code are same.
        Assert.AreEqual(Zone2.Code, WarehouseEntry."Zone Code", ZoneCodeMustMatchErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerGetText')]
    [Scope('OnPrem')]
    procedure ChangeStatusOfFirmPlannedProdOrderToReleasedProdOrderAndCreateInvPick()
    var
        Item: Record Item;
        Item2: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        Bin2: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ReleasedProdOrderNo: Code[20];
    begin
        // [SCENARIO 496097] Inventory Pick is created when stan runs Create Inventory PutAway/Pick/Movement action from Released Production Order which is created from Change Status action of Firm Planned Production Order.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Item 2.
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create Location & Validate Prod Consump Whse Handling.
        CreateLocation(Location);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");
        Location.Modify(true);

        // [GIVEN] Create Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create Bin 2.
        LibraryWarehouse.CreateBin(Bin2, Location.Code, Bin2.Code, '', '');

        // [GIVEN] Validate To-Production Bin Code in Location.
        Location.Validate("To-Production Bin Code", Bin2.Code);
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Validate Components at Location in Manufacturing Setup.
        LibraryManufacturing.SetComponentsAtLocation(Location.Code);

        // [GIVEN] Create Item Journal Line & Validate Location Code & Bin Code.
        CreateItemJournalLine(ItemJnlTemplate, ItemJnlBatch, ItemJnlLine, Item);
        ItemJnlLine.Validate("Location Code", Location.Code);
        ItemJnlLine.Validate("Bin Code", Bin.Code);
        ItemJnlLine.Modify(true);

        // [GIVEN] Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJnlTemplate.Name, ItemJnlBatch.Name);

        // [GIVEN] Create and Certify Production BOM.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ProductionBOMLine, Item);

        // [GIVEN] Validate Production BOM in Item 2.
        Item2.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item2.Modify(true);

        // [GIVEN] Create and Refresh Firm Planned Production Order.
        CreateAndRefreshFirmPlannedProdOrder(ProductionOrder, Item2);

        // [GIVEN] Change Status of Firm Planned Production Order to Released Production Order.
        ReleasedProdOrderNo := LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProductionOrder."No.");

        // [GIVEN] Run Create Inventory PutAway/Pick/Movement to Create Inventory Pick.
        LibraryWarehouse.CreateInvtPutPickMovement(
            "Warehouse Request Source Document"::"Prod. Consumption",
            ReleasedProdOrderNo,
            false,
            true,
            false);

        // [WHEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);

        // [VERIFY] Warehouse Activity Header is created.
        Assert.IsFalse(WarehouseActivityHeader.IsEmpty(), WhseActivityHeaderMustNotBeEmpty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignLotNoPageHandler,MessageHandler,ConfirmHandler2')]
    [Scope('OnPrem')]
    procedure ExpirationDateIsPopulatedInInvPickLinesFromSalesOrderItemTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        ExpirationDate: Date;
        LotNo: Code[50];
        AssemblyOrder: TestPage "Assembly Order";
    begin
        // [SCENARIO 507008] Expiration Date is populated in Inventory Pick Lines when Stan manually enters Expiration Date in Assembly Header's Item Tracking Lines and then creates Inventory Pick From Sales Order.
        Initialize();

        // [GIVEN] Create Location & Validate Require Put-away, Require Pick and Asm. Consump. Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Put-away", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Asm. Consump. Whse. Handling", Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Item Tracking Code and Validate Use Expiration Dates and Man. Expir. Date Entry Reqd.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create Item and Validate Replenishment System, Assembly Policy and Item Tracking Code.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        // [GIVEN] Create Item 2 and Validate Replenishment System.
        LibraryInventory.CreateItem(Item2);
        Item2.Validate("Replenishment System", Item2."Replenishment System"::Purchase);
        Item2.Modify(true);

        // [GIVEN] Create and post Purchase Order.
        CreateAndPostPurchaseOrder(PurchaseHeader, Item2."No.", Location.Code);

        // [GIVEN] Create Sales Order.
        CreateSalesOrder(SalesHeader, Item."No.", Location.Code);

        // [GIVEN] Find Assembly Header.
        AssemblyHeader.SetRange("Item No.", Item."No.");
        AssemblyHeader.FindFirst();

        // [GIVEN] Create Assembly Line and Validate Location Code.
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item2."No.", Item2."Base Unit of Measure", LibraryRandom.RandInt(0), LibraryRandom.RandInt(0), '');
        AssemblyLine.Validate("Location Code", Location.Code);
        AssemblyLine.Modify(true);

        // [GIVEN] Generate and save Expiration Date and Lot No. in two different Variables.
        ExpirationDate := CalcDate(ExpirationDateCalcFormula, WorkDate());
        LotNo := Format(LibraryRandom.RandText(3));

        // [GIVEN] Open Assembly Order page and run Item Tracking Lines action.
        AssemblyOrder.OpenEdit();
        AssemblyOrder.GoToRecord(AssemblyHeader);
        LibraryVariableStorage.Enqueue(TrackingAction::LotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ExpirationDate);
        AssemblyOrder."Item Tracking Lines".Invoke();

        // [GIVEN] Release Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Find Reservation Entry.
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.FindFirst();

        // [GIVEN] Validate Lot No. and Expiration Date in Reservation Entry.
        ReservationEntry.Validate("Lot No.", LotNo);
        ReservationEntry.Validate("Expiration Date", ExpirationDate);
        ReservationEntry.Modify(true);

        // [GIVEN] Create Inventory PutAway/Pick/Movement.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // [WHEN] Find Warehouse Activity Header.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.FindFirst();

        // [VERIFY] Expiration Date is not empty in Warehouse Activity Line.
        Assert.AreNotEqual(0D, WarehouseActivityLine."Expiration Date", ExpirationDateMustNotBeEmptyErr);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromPickWorkSheetPopulatesQtyToHandleInWarehousePick()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        Bin2: Record Bin;
        Zone: Record Zone;
        Zone2: Record Zone;
        BinType, BinType2 : Record "Bin Type";
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseJournalTemplate: Record "Warehouse Journal Template";
        WhseJournalBatch: Record "Warehouse Journal Batch";
        WhseJournalLine: Record "Warehouse Journal Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        QtyToHandle: Decimal;
    begin
        // [SCENARIO 521215] When Stan runs Get Warehouse Documents action from Pick Worksheet then Whse. Worksheet Line is created with Qty. to Handle filled 
        // And when Stan creates Pick from Pick Worksheet then Qty. to Handle is populated in Warehouse Pick.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Location and Validate Always Create Put-away Line, Always Create Pick Line and Allow Breakbulk.
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Always Create Pick Line", true);
        Location.Validate("Allow Breakbulk", true);
        Location.Modify(true);

        // [GIVEN] Create Item Tracking Code and Validate Man. Expir. Date Entry Reqd. and Use Expiration Dates.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", false);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Validate Item Tracking Code.
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Find Bin Type.
        FindBinType(BinType, false, false, true, false);

        // [GIVEN] Find Bin Type 2.
        FindBinType(BinType2, false, false, false, false);

        // [GIVEN] Create Zone.
        LibraryWarehouse.CreateZone(
            Zone,
            Zone.Code,
            Location.Code,
            BinType.Code,
            '',
            '',
            LibraryRandom.RandInt(0),
            false);

        // [GIVEN] Create Zone 2.
        LibraryWarehouse.CreateZone(
            Zone2,
            Zone2.Code,
            Location.Code,
            BinType2.Code,
            '',
            '',
            0,
            false);

        // [GIVEN] Create Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, Zone.Code, BinType.Code);

        // [GIVEN] Create Bin 2.
        LibraryWarehouse.CreateBin(Bin2, Location.Code, Bin2.Code, Zone.Code, BinType.Code);

        // [GIVEN] Create Warehouse Journal Setup.
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WhseJournalTemplate, WhseJournalBatch);

        // [GIVEN] Create Warehouse Item Journal Line for Item.
        LibraryWarehouse.CreateWhseJournalLine(
            WhseJournalLine,
            WhseJournalBatch."Journal Template Name",
            WhseJournalBatch.Name,
            Bin."Location Code",
            Bin."Zone Code",
            Bin.Code,
            WhseJournalLine."Entry Type"::"Positive Adjmt.",
            Item."No.",
            LibraryRandom.RandIntInRange(1500, 1500));

        // [GIVEN] Open Item Tracking Lines.
        WhseJournalLine.OpenItemTrackingLines();

        // [GIVEN] Register Warehouse Journal Line.
        LibraryWarehouse.RegisterWhseJournalLine(WhseJournalBatch."Journal Template Name", WhseJournalBatch.Name, Location.Code, true);

        // [GIVEN] Calculate Warehouse Adjustment and Post Item Journal.
        CalcWhseAdjustmentAndPostItemJournal(Item);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Create and Reserve Sales Line.
        CreateAndReserveSalesLine(SalesHeader, SalesLine, Item, Location, LibraryRandom.RandIntInRange(400, 400));

        // [GIVEN] Release Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Warehouse Shipment from Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Find Warehouse Shipment Line.
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", SalesHeader."Document Type");
        WarehouseShipmentLine.FindLast();

        // [GIVEN] Find Warehouse Shipment Header.
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        // [GIVEN] Release Warehouse Shipment.
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [GIVEN] Get Warehouse Document on Whse. Worksheet Line.
        GetWarehouseDocumentOnWarehouseWorksheetLine(WhseWorksheetName, Location, WarehouseShipmentHeader."No.", '');

        // [GIVEN] Find Whse. Worksheet Line.
        FindLastWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, Location.Code);

        // [GIVEN] Save and generate Qty. to Handle in a Variable.
        QtyToHandle := WhseWorksheetLine."Qty. to Handle";

        // [GIVEN] Create Pick from Pick Worksheet.
        LibraryWarehouse.CreatePickFromPickWorksheet(
            WhseWorksheetLine,
            WhseWorksheetLine."Line No.",
            WhseWorksheetName."Worksheet Template Name",
            WhseWorksheetName.Name,
            Location.Code,
            '',
            0,
            0,
            "Whse. Activity Sorting Method"::None,
            false,
            false,
            false,
            false,
            false,
            false,
            false);

        // [WHEN] Find Warehouse Activity Line.
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.FindLast();

        // [THEN] Qty. to Handle in Warehouse Activity Line must be equal to QtyToHandle.
        Assert.AreEqual(
            QtyToHandle,
            WarehouseActivityLine."Qty. to Handle",
            StrSubstNo(
                QtyToHandleErr,
                WarehouseActivityLine.FieldCaption("Qty. to Handle"),
                QtyToHandle,
                WarehouseActivityLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure QtyToHandleBaseInItemTrackingOfComponentsInReleasedProdOrderShowsTotalRegisteredWhsePickQty()
    var
        Item: array[3] of Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Location: Record Location;
        Bin: array[5] of Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemJnlLine: array[2] of Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: array[2] of Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // [SCENARIO 537502] When Stan partially Registers Warehouse Pick of a Released Production Order having two Components, one with Item Tracking
        // And another one without Item Tracking then the Item Tracking of Component should show total Registered quantity in Qty. to Handle (Base).
        Initialize();

        // [GIVEN] Create Item Tracking Code and Validate Man. Expir. Date Entry Reqd. and Use Expiration Dates.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", false);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create Location & Validate Require Shipment, Require Receive, Require Put-away, Require Pick,
        // Prod. Consump. Whse. Handling and Asm. Consump. Whse. Handling
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Put-away", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Validate("Asm. Consump. Whse. Handling", Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Modify(true);

        // [GIVEN] Create Bin.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, Bin[1].Code, '', '');

        // [GIVEN] Create Bin 2.
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, Bin[2].Code, '', '');

        // [GIVEN] Create Bin 3.
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, Bin[3].Code, '', '');

        // [GIVEN] Create Bin 4.
        LibraryWarehouse.CreateBin(Bin[4], Location.Code, Bin[4].Code, '', '');

        // [GIVEN] Create Bin 5.
        LibraryWarehouse.CreateBin(Bin[5], Location.Code, Bin[5].Code, '', '');

        // [GIVEN] Validate Open Shop Floor Bin Code, To-Production Bin Code 
        // And From-Production Bin Code in Location.
        Location.Validate("Open Shop Floor Bin Code", Bin[1].Code);
        Location.Validate("To-Production Bin Code", Bin[2].Code);
        Location.Validate("From-Production Bin Code", Bin[3].Code);
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item[1]);

        // [GIVEN] Create Item 2.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item[2].Modify(true);

        // [GIVEN] Create Item 3.
        LibraryInventory.CreateItem(Item[3]);

        // [GIVEN] Generate and save Lot No. and Quantity in two different Variables.
        LotNo := LibraryUtility.GenerateGUID();
        Quantity := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Lot Tracked Item Journal Line.
        CreateLotTrackedItemJournalLine(ItemJnlLine[1], Item[2]."No.", '', Location.Code, Bin[4].Code, WorkDate(), LotNo, Quantity);

        // [GIVEN] Create Item Journal Line 2.
        LibraryInventory.CreateItemJournalLine(
            ItemJnlLine[2],
            ItemJnlLine[1]."Journal Template Name",
            ItemJnlLine[1]."Journal Batch Name",
            ItemJnlLine[2]."Entry Type"::Purchase,
            Item[1]."No.",
            Quantity);

        // [GIVEN] Validate Location Code and Bin Code in Item Journal Line 2.
        ItemJnlLine[2].Validate("Location Code", Location.Code);
        ItemJnlLine[2].Validate("Bin Code", Bin[5].Code);
        ItemJnlLine[2].Modify(true);

        // [GIVEN] Post Item Journal Lines.
        LibraryInventory.PostItemJournalLine(ItemJnlLine[1]."Journal Template Name", ItemJnlLine[1]."Journal Batch Name");

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, Item[3]."No.", Location.Code, Quantity);

        // [GIVEN] Find Prod. Order Line.
        FindProdOrderLine(ProdOrderLine, ProductionOrder);

        // [GIVEN] Create Production Order Component and Validate Item No., Quantity per, Location Code and Bin Code.
        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent[1], ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent[1].Validate("Item No.", Item[1]."No.");
        ProdOrderComponent[1].Validate("Quantity per", LibraryRandom.RandInt(0));
        ProdOrderComponent[1].Validate("Location Code", Location.Code);
        ProdOrderComponent[1].Validate("Bin Code", Bin[2].Code);
        ProdOrderComponent[1].Modify();

        // [GIVEN] Create Production Order Component 2 and Validate Item No., Quantity per, Location Code and Bin Code.
        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent[2], ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent[2].Validate("Item No.", Item[2]."No.");
        ProdOrderComponent[2].Validate("Quantity per", LibraryRandom.RandInt(0));
        ProdOrderComponent[2].Validate("Location Code", Location.Code);
        ProdOrderComponent[2].Validate("Bin Code", Bin[2].Code);
        ProdOrderComponent[2].Modify();

        // [GIVEN] Open Item Tracking Lines for Production Order Component 2.
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        ProdOrderComponent[2].OpenItemTrackingLines();

        // [GIVEN] Create Warehouse Pick from Production Order.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [GIVEN] Find and Register Warehouse Activity.
        FindAndRegisterWhseActivity(
            WarehouseActivityLine,
            WarehouseActivityLine."Activity Type"::Pick,
            Location.Code,
            ProductionOrder."No.",
            LibraryRandom.RandIntInRange(4, 4));

        // [GIVEN] Find and Register Warehouse Activity.
        FindAndRegisterWhseActivity(
            WarehouseActivityLine,
            WarehouseActivityLine."Activity Type"::Pick,
            Location.Code,
            ProductionOrder."No.",
            LibraryRandom.RandIntInRange(6, 6));

        // [WHEN] Open Item Tracking Lines from Production Order Component 2.
        LibraryVariableStorage.Enqueue(TrackingAction::CheckQtyToHandleBase);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        ProdOrderComponent[2].OpenItemTrackingLines();

        // [THEN] Qty. to Handle (Base) is equal to Quantity in ItemTrackingPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('WarehouseShipmentCreatePickRequestPageHandler')]
    procedure QtyToHandleInWhseActLineIsNotAutoFilledIfDoNotFillQtyToHandleIsTrueInWhseActHdr()
    var
        Bin: Record Bin;
        BinType: Record "Bin Type";
        Zone: Record Zone;
        Item: array[3] of Record Item;
        Location: Record Location;
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivitLine: Record "Warehouse Activity Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
    begin
        // [SCENARIO 540363] When Stan partially Register Warehouse Pick then Qty. to Handle in Warehouse Activity Lines 
        // Is not auto filled if "Do Not Fill Qty. to Handle" is true in Warehouse Activity Header.
        Initialize();

        // [GIVEN] Create three Items.
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateItem(Item[3]);

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] Create a Bin Type.
        CreateBinType(BinType);

        // [GIVEN] Create a Zone.
        LibraryWarehouse.CreateZone(Zone, Zone.Code, Location.Code, BinType.Code, '', '', 0, false);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, Zone.Code, BinType.Code);

        // [GIVEN] Create and Post Warehouse Journal Lines.
        CreateAndPostWhseJournalLines(Item[1], Item[2], Item[3], Location, Zone, Bin);

        // [GIVEN] Run Calc. Warehouse Adjustment and Post Item Journal for three items.
        CalcWhseAdjustmentAndPostItemJournal(Item[1]);
        CalcWhseAdjustmentAndPostItemJournal(Item[2]);
        CalcWhseAdjustmentAndPostItemJournal(Item[3]);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Sales Header and Validate Location Code.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        // [GIVEN] Create three Sales Lines.
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(5, 5));
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, Item[2]."No.", LibraryRandom.RandIntInRange(5, 5));
        LibrarySales.CreateSalesLine(SalesLine[3], SalesHeader, SalesLine[3].Type::Item, Item[3]."No.", LibraryRandom.RandIntInRange(5, 5));

        // [GIVEN] Release Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Warehouse Shipment from Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Find Warehouse Shipment Header.
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindFirst();

        // [GIVEN] Release Warehouse Shipment.
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [GIVEN] Find Warehouse Shipment Line.
        WarehouseShipmentLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivitLine.FindFirst();

        // [GIVEN] Create Pick from Warehouse Shipment Line.
        CreatePickFromWhseShipimentLine(WarehouseShipmentHeader);

        // [GIVEN] Find Warehouse Activity Lines of Item[1] and Validate Qty. to Handle.
        FindAndValidateQtyToHandleInWhseActivityLine(Item[1]);

        // [GIVEN] Find Acitivity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Register Warehouse Activity.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Find Warehouse Activity Line of Item[2].
        WarehouseActivitLine.SetRange("Item No.", Item[2]."No.");
        WarehouseActivitLine.FindFirst();

        // [THEN] Qty. to Handle in Warehouse Activity Line is 0.
        Assert.AreEqual(
            0,
            WarehouseActivitLine."Qty. to Handle",
            StrSubstNo(
                QtyToHandleErr,
                WarehouseActivitLine.FieldCaption("Qty. to Handle"),
                0,
                WarehouseActivitLine.TableCaption()));

        // [WHEN] Find Warehouse Activity Line of Item[3].
        WarehouseActivitLine.SetRange("Item No.", Item[3]."No.");
        WarehouseActivitLine.FindFirst();

        // [THEN] Qty. to Handle in Warehouse Activity Line is 0.
        Assert.AreEqual(
            0,
            WarehouseActivitLine."Qty. to Handle",
            StrSubstNo(
                QtyToHandleErr,
                WarehouseActivitLine.FieldCaption("Qty. to Handle"),
                0,
                WarehouseActivitLine.TableCaption()));

        // [WHEN] Run Autofill Qty. to Handle.
        WarehouseActivitLine.AutofillQtyToHandle(WarehouseActivitLine);

        // [THEN] Qty. to Handle in Warehouse Activity Line is equal to Quantity of Warehouse Activity Line.
        Assert.AreEqual(
            WarehouseActivitLine.Quantity,
            WarehouseActivitLine."Qty. to Handle",
            StrSubstNo(
                QtyToHandleErr,
                WarehouseActivitLine.FieldCaption("Qty. to Handle"),
                WarehouseActivitLine.Quantity,
                WarehouseActivitLine.TableCaption()));

        // [WHEN] Find Acitivity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [THEN] Do Not Fill Qty. to Handle in Warehouse Activity Header is false.
        Assert.IsFalse(WarehouseActivityHeader."Do Not Fill Qty. to Handle", DoNotFillQtyToHandleMustBeFalseErr);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesMultipleModalPageHandler,ItemTrackingPageHandler')]
    procedure WhsePickHasLotNoWhenRegisteredPickDeletedAndCreateNewPick()
    var
        Item: Record Item;
        Location: Record Location;
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LotNo: array[2] of Code[50];
        LotQty: Integer;
        PartialQtyMultiplier: Decimal;
    begin
        // [SCENARIO 549983] When partially registered Pick is deleted for Lot Tracked Component Item and create new pick
        // then newly created Pick has same Lot No as specified in Item Tracking.
        Initialize();
        LotQty := LibraryRandom.RandIntInRange(2000, 2000);
        PartialQtyMultiplier := 0.1;

        // [GIVEN] Lot Tracked Item "I" had stock of 4000 PCS: 2000 PCS with Lot L1 and 2000 PCS with Lot L2.
        CreateItemWithStockSeveralLots(Item, Location, LotNo, LotQty);

        // [GIVEN] Production Order with 1 PCS of Item "A" with 2000 PCS of Item "I" as component.
        CreateProdOrderWithLotTrackedComponentItem(
            ProductionOrder, ProdOrderComponent, LibraryInventory.CreateItemNo(), 1, Item."No.", LotQty, LotNo[2], Location.Code);

        // [GIVEN] Pick was created for Production Order with Lot L2 and 2000 PCS.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        VerifyWarehouseActivityTakePlaceLinesQtyAndLot(ProductionOrder."No.", Location.Code, LotQty, LotNo[2]);

        // [GIVEN] Registered 200 PCS and deleted Pick
        LibraryWarehouse.FindWhseActivityBySourceDoc(
            WarehouseActivityHeader, DATABASE::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
            ProdOrderComponent."Prod. Order Line No.");
        RegisterAndDeletePartialPick(WarehouseActivityHeader, PartialQtyMultiplier);

        // [WHEN] Create Whse. Pick.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [THEN] Pick is created with 8 PCS of Lot L2
        VerifyWarehouseActivityTakePlaceLinesQtyAndLot(ProductionOrder."No.", Location.Code, LotQty - (LotQty * PartialQtyMultiplier), LotNo[2]);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesMultiplePackageModalPageHandler,ItemTrackingPageHandler')]
    procedure WhsePickHasPackageNoWhenRegisteredPickDeletedAndCreateNewPick()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PackageNo: array[2] of Code[50];
        PackageQty: Integer;
        PartialQtyMultiplier: Decimal;
    begin
        // [SCENARIO 549983] When partially registered Pick is deleted for Package Tracked Component Item and create new pick
        // then newly created Pick has same Package No as specified in Item Tracking.
        Initialize();
        PackageQty := LibraryRandom.RandIntInRange(2000, 2000);
        PartialQtyMultiplier := 0.1;

        // [GIVEN] Package Tracked Item "I" had stock of 4000 PCS: 2000 PCS with Package P1 and 2000 PCS with Package P2.
        CreateItemWithStockSeveralPackages(Item, Location, PackageNo, PackageQty);

        // [GIVEN] Production Order with 1 PCS of Item "A" with 2000 PCS of Item "I" as component.
        CreateProdOrderWithPackageTrackedComponentItem(
            ProductionOrder, ProdOrderComponent, LibraryInventory.CreateItemNo(), 1, Item."No.", PackageQty, PackageNo[2], Location.Code);

        // [GIVEN] Pick was created for Production Order with Package P2 and 2000 PCS.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        VerifyWarehouseActivityTakePlaceLinesQtyAndPackage(ProductionOrder."No.", Location.Code, PackageQty, PackageNo[2]);

        // [GIVEN] Registered 200 PCS and deleted Pick
        LibraryWarehouse.FindWhseActivityBySourceDoc(
            WarehouseActivityHeader, DATABASE::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
            ProdOrderComponent."Prod. Order Line No.");
        RegisterAndDeletePartialPick(WarehouseActivityHeader, PartialQtyMultiplier);

        // [WHEN] Create Whse. Pick.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [THEN] Pick is created with 8 PCS of Package P2
        VerifyWarehouseActivityTakePlaceLinesQtyAndPackage(ProductionOrder."No.", Location.Code, PackageQty - (PackageQty * PartialQtyMultiplier), PackageNo[2]);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    procedure CreatePickAccToFEFOandLotNoForDirectedPutAwayAndPickLocation()
    var
        Item: Record Item;
        ItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        SaleQuantity: Decimal;
    begin
        // [SCENARIO 563367] Directed Put away and pick - Nothing to Handle error with FEFO Picking where item with no expiration or an earlier expiration with a different UOM than what is on the Sales Order, and does not want to breakbulk.
        Initialize();

        // [GIVEN] Create Location with Pick According To FEFO and Allow BreakBulk as False.
        CreateFullWMSLocation(Location, 2);
        Location.Validate("Pick According to FEFO", true);
        Location.Validate("Allow Breakbulk", false);
        Location.Modify(true);

        //[GIVEN] Create Item With Item Tracking Code and with 2 Item Unit of Measure Code
        CreateTrackedItem(Item, true, false, false, false, false);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[1], Item."No.", 24);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[2], Item."No.", 288);

        // [GIVEN] Create and Post Warehouse Receipt of Purchase Order 1.
        PostPurchaseReceiptWithItemTracking(Item, ItemUnitOfMeasure[2], Location.Code, (LibraryRandom.RandDecInDecimalRange(1000, 1000, 2)));

        // [GIVEN] Create and Post Warehouse Receipt of Purchase Order 2.
        PostPurchaseReceiptWithItemTracking(Item, ItemUnitOfMeasure[1], Location.Code, (LibraryRandom.RandDecInDecimalRange(10000, 10000, 2)));

        // [GIVEN] Create Sales Order with Warehouse Shipment
        SaleQuantity := LibraryRandom.RandDecInDecimalRange(12, 12, 02);
        PrepareSalesOrderWithWhseShipment(SalesHeader, WarehouseShipmentHeader, Item."No.", Location.Code, SaleQuantity, ItemUnitOfMeasure[1].Code);

        // [WHEN] Create Pick from Warehouse Shipment Header
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentHeader."No.");

        // [THEN] Verify Pick Created and values on Whse Activity Line.
        VerifyWhseActivityLine(WarehouseActivityLine, SaleQuantity, SalesHeader."No.", Location.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    procedure CreatePickAccToFEFOandLotNoForNonDirectedPutAwayAndPickLocation()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        QtyItemStock: Decimal;
        QtyToSell: Decimal;
        LotNo: Code[50];
        ExpirationDate: Date;
    begin
        // [SCENARIO 574361] Non-Directed Put away and pick - FEFO picking selects Lot when there is an alternative UOM on the Sales Order.
        Initialize();

        // [GIVEN] Create Location with Bin Mandatory, Requre Pick and Pick According To FEFO
        CreateAndUpdateLocation(Location, true, false, true, false, true, true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', ArrayLen(Bin), false);
        LibraryWarehouse.FindBin(Bin[1], Location.Code, '', 1);
        LibraryWarehouse.FindBin(Bin[2], Location.Code, '', 2);
        Location.Validate("Shipment Bin Code", Bin[2].Code);
        Location.Modify(true);

        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        //[GIVEN] Create Item With Item Tracking Code and with different Sales Item Unit of Measure Code
        CreateTrackedItem(Item, true, false, false, false, false);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 24);

        // [GIVEN] Create and Post Positive Adjustment Item Journal Line with Lot No. and Expiration Date
        QtyItemStock := LibraryRandom.RandDecInDecimalRange(1000, 1000, 2);
        LotNo := Format(LibraryRandom.RandText(10));
        ExpirationDate := CalcDate(ExpirationDateCalcFormula, WorkDate());
        PostItemJournalLineWithLotNoExpiration(Item."No.", Location.Code, Bin[1].Code, LotNo, QtyItemStock, ExpirationDate);

        // [GIVEN] Create Sales Order with Warehouse Shipment
        QtyToSell := LibraryRandom.RandDecInDecimalRange(12, 12, 02);
        PrepareSalesOrderWithWhseShipment(SalesHeader, WarehouseShipmentHeader, Item."No.", Location.Code, QtyToSell, ItemUnitOfMeasure.Code);

        // [WHEN] Create Pick from Warehouse Shipment Header
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentHeader."No.");

        // [THEN] Verify Pick Created and values on Whse Activity Line
        VerifyWhseActivityLine(WarehouseActivityLine, QtyToSell, SalesHeader."No.", Location.Code);

        // [THEN] Verify Lot No. and Expiration Date on Whse Activity Line
        WarehouseActivityLine.TestField("Lot No.", LotNo);
        WarehouseActivityLine.TestField("Expiration Date", ExpirationDate);
    end;

    [Test]
    [HandlerFunctions('WhseCalculateInventoryIncludeItemWithoutTransactionHandler')]
    procedure WhseCalculateInventoryShouldRunWithoutAnyErrorForDeletedItem()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BinCode: Code[20];
        PostingDate: Date;
        Quantity: Decimal;
        WhsePhysInvJournal: TestPage "Whse. Phys. Invt. Journal";
    begin
        // [SCENARIO 562944] Verify "Calculate Inventory" in Warehouse Physical Inventory Journal should run without any error.
        // when Stan filter with "Location Code" and "Bin Code" after closing the fiscal year for deleted item.
        Initialize();

        // [GIVEN] Create Warehouse location.
        CreateFullWMSLocation(Location, 2);

        // [GIVEN] Create Fiscal Year and Inventory Period.
        PostingDate := CreateFiscalYearAndInventoryPeriod();

        // [GIVEN] Create an Item "I".
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create PO for Item "I" with Posting Date.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, Item."No.");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        // [GIVEN] Save Quantity.
        Quantity := PurchaseLine.Quantity;

        // [GIVEN] Create and Post Whse. Receipt from PO with Bin.
        BinCode := CreateAndPostWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Register Put Away.
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Post Purchase Order.
        PurchaseHeader.Find();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Create and Release SO for Item "I" with Posting Date.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, Quantity);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create and Post Whse. Shipment from SO.
        CreateAndPostWhseShipmentFromSO(SalesHeader, Location.Code);

        // [GIVEN] Post Sales Order.
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Run Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Close Accounting Year and Create Fiscal Year.
        LibraryFiscalYear.CloseAccountingPeriod();
        LibraryFiscalYear.CreateFiscalYear();

        // [GIVEN] Delete Item.
        Item.Delete(true);
        Commit();

        // [WHEN] Open "Whse. Phys. Invt. Journal".
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(Location.Code);
        LibraryVariableStorage.Enqueue(BinCode);
        WhsePhysInvJournal.OpenEdit();

        // [THEN] "Calculate Inventory" in Warehouse Physical Inventory Journal should run without any error.
        WhsePhysInvJournal."Calculate &Inventory".Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse - III");
        Clear(TrackingAction);
        Clear(Quantity2);
        Clear(WarehouseShipmentNo);
        Clear(SourceNo);
        Clear(LocationCode);
        Clear(Counter);
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse - III");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        CreateLocationSetup();
        NoSeriesSetup();
        ItemJournalSetup();
        OutputJournalSetup();
        LibrarySetupStorage.SaveInventorySetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse - III");
    end;

    local procedure AutoFillQuantityAndPostInventoryActivity(LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);  // Location: White.
        CreateAndUpdateLocation(LocationSilver, true, true, true, false, false, true);  // Location Silver: Pick According To FEFO TRUE.
        CreateAndUpdateLocation(LocationSilver2, true, true, true, false, false, false);  // Location Silver2: Pick According To FEFO FALSE.
        CreateAndUpdateLocation(LocationSilver3, true, true, true, true, true, true);  // Location Silver: Pick According To FEFO TRUE.
        CreateAndUpdateLocation(LocationGreen, true, true, true, true, true, false);  // Location Green: Bin Mandatory TRUE.
        CreateAndUpdateLocation(LocationOrange, true, true, true, true, true, false);  // Location Orange: Bin Mandatory TRUE.
        CreateAndUpdateLocation(LocationYellow, false, true, true, true, true, false);  // Location Yellow: Bin Mandatory FALSE.
        CreateAndUpdateLocation(LocationYellow2, false, true, true, false, false, true);  // Location Yellow2: Require Shipment and Receive FALSE.
        CreateAndUpdateLocation(LocationRed, false, true, true, false, false, true);  // Location Red: Require Shipment and Receive FALSE.
        CreateAndUpdateLocation(LocationGreen2, false, true, true, true, false, false);  // Location Green2: Bin Mandatory FALSE, Require Shipment FALSE.
        CreateAndUpdateLocation(LocationOrange2, true, true, false, true, true, true);  // Location Orange2: Bin Mandatory TRUE, Require PIck FALSE.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver2.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value Required.
        LibraryWarehouse.CreateNumberOfBins(LocationSilver2.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value required.
        LibraryWarehouse.CreateNumberOfBins(LocationSilver3.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value required.
        LibraryWarehouse.CreateNumberOfBins(LocationGreen.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value required.
        LibraryWarehouse.CreateNumberOfBins(LocationOrange.Code, '', '', LibraryRandom.RandInt(5) + 2, false);  // 2 is required as minimun number of Bin must be 2.

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationIntransit);
        LocationIntransit.Validate("Use As In-Transit", true);
        LocationIntransit.Modify(true);
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
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, '');  // Value required.
    end;

    local procedure OutputJournalSetup()
    begin
        Clear(OutputItemJournalTemplate);
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        OutputItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        OutputItemJournalTemplate.Modify(true);

        Clear(OutputItemJournalBatch);
        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
        OutputItemJournalBatch.Modify(true);
    end;

    local procedure PrepareSalesOrderWithPick(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        PrepareSalesOrderWithWhseShipment(SalesHeader, WarehouseShipmentHeader, ItemNo, LocationCode, Qty);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentHeader."No.");
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SalesHeader."No.", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Validate("Qty. to Handle", Qty);
        WarehouseActivityLine.Modify(true);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SalesHeader."No.", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.Validate("Qty. to Handle", Qty);
        WarehouseActivityLine.Modify(true);
        exit(SalesHeader."No.");
    end;

    local procedure PrepareSalesOrderWithWhseShipment(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    begin
        CreateAndReleaseSalesOrder(SalesHeader, ItemNo, Qty, LocationCode);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure PostItemJournalLineWithLotNoExpiration(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; LotNo: Code[50]; Qty: Decimal; ExpirationDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryVariableStorage.AssertEmpty();

        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.SetRange("Expiration Date", 0D);
        ReservationEntry.ModifyAll("Expiration Date", ExpirationDate, true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(100, 2), Item."Reordering Policy"::Order,
          Item."Flushing Method", '', ProductionBOMNo);
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(100, 2));  // Value Required.
        Item.Modify(true);
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

    local procedure FindPickLine(var WarehousePickLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20])
    begin
        WarehousePickLine.SetRange("Source Type", SourceType);
        WarehousePickLine.SetRange("Source Subtype", SourceSubType);
        WarehousePickLine.SetRange("Activity Type", WarehousePickLine."Action Type"::Place);
        WarehousePickLine.SetRange("Source No.", SourceNo);
        WarehousePickLine.FindFirst();
    end;

    local procedure UpdateActivityLineAndDeletePartially(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20])
    begin
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, SourceNo,
          WarehouseActivityLine."Action Type"::Take);
        // Updated the Quantity half of the Quantity on Whse Activity Line.
        UpdateQuantityToHandleOnActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, LocationWhite.Code, SourceNo, Quantity2 / 2);
        UpdateQuantityToHandleOnActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, LocationWhite.Code, SourceNo, Quantity2 / 2);
        RegisterWarehouseActivity(SourceNo, WarehouseActivityLine."Activity Type"::Pick);
        DeleteWarehouseActivity(WarehouseActivityLine);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo2: Code[20]; QuantityPer: Decimal; UnitOfMeasureCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Choose any unit of measure.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);

        // Create component lines in the BOM.
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo2, QuantityPer);

        // Certify BOM.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateItemMovementSetup(var ProductionOrder: Record "Production Order"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        Item2: Record Item;
    begin
        // Create Item, update Inventory, create and refresh released Production Order and create Inventory Movement, get Source Document.
        CreateItemSetup(Item, Item2);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder."Source Type"::Item, Item."No.", LocationSilver.Code, LibraryRandom.RandDec(10, 2));
        SourceNo := ProductionOrder."No.";
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryWarehouse.CreateInventoryMovementHeader(WarehouseActivityHeader, LocationSilver.Code);
        LibraryWarehouse.GetSourceDocInventoryMovement(WarehouseActivityHeader);
    end;

    local procedure CreateItemSetup(var Item: Record Item; var Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        Bin: Record Bin;
    begin
        UpdateBinOnLocation();
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 2);  // Find Bin Of Index 2.
        CreateItem(Item, '');
        CreateItem(Item2, '');
        CreateAndCertifyProductionBOM(
          ProductionBOMHeader, Item2."No.", LibraryRandom.RandDec(100, 2), Item."Base Unit of Measure");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
        UpdateItemInventory(Item2."No.", LocationSilver.Code, Bin.Code, LibraryRandom.RandDec(100, 2) + 100);
    end;

    local procedure CreateAsmOrderWithLotTrackedItemLine(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; ParentItemNo: Code[20]; ParentItemQty: Decimal; ChildItemNo: Code[20]; ChildItemQty: Decimal; ChildItemLotNo: Code[50]; LocationCode: Code[10])
    var
        Item: Record Item;
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), ParentItemNo, LocationCode, ParentItemQty, '');
        Item.Get(ChildItemNo);
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", ChildItemQty, ChildItemQty, '');
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);
        LibraryVariableStorage.Enqueue(ChildItemLotNo);
        LibraryVariableStorage.Enqueue(ChildItemQty);
        AssemblyLine.OpenItemTrackingLines();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateProdOrderWithLotTrackedComponentItem(var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component"; ParentItemNo: Code[20]; ParentItemQty: Decimal; ChildItemNo: Code[20]; ChildItemQty: Decimal; ChildItemLotNo: Code[50]; LocationCode: Code[10])
    begin
        CreateProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItemNo, LocationCode, ParentItemQty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);
        CreateProductionOrderComponentWithItemQtyAndFlushingMethod(
          ProdOrderComponent, ProdOrderComponent.Status::Released, ProductionOrder."No.", GetFirstProdOrderLineNo(ProductionOrder),
          ChildItemNo, ChildItemQty, LocationCode, "Flushing Method"::"Pick + Manual");
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);
        LibraryVariableStorage.Enqueue(ChildItemLotNo);
        LibraryVariableStorage.Enqueue(ProdOrderComponent.Quantity);
        ProdOrderComponent.OpenItemTrackingLines();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, SourceType, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
    end;

    local procedure CreateProductionOrderComponentWithItemQtyAndFlushingMethod(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; ItemNo: Code[20]; QtyPer: Decimal; LocationCode: Code[10]; FlushingMethod: Enum "Flushing Method")
    begin
        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent, Status, ProdOrderNo, ProdOrderLineNo);
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", QtyPer);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Validate("Flushing Method", FlushingMethod);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateProdOrder(ProductionOrder, ProductionOrder.Status::Released, SourceType, SourceNo, LocationCode, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateWhsePickFromAssembly(var AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyHeader.SetHideValidationDialog(true);
        AssemblyHeader.CreatePick(false, UserId, 0, false, false, false);
    end;

    local procedure CreateLocationForPutAwayWorksheet(var Location: Record Location)
    begin
        CreateAndUpdateLocation(Location, true, true, true, true, true, false);
        Location.Validate("Use Put-away Worksheet", true);
        Location.Modify(true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 1, false);
    end;

    local procedure CreateLocationRequireReceive(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Prod. Output Whse. Handling", "Prod. Output Whse. Handling"::"Inventory Put-away");
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateItemWithStockSeveralLots(var Item: Record Item; var Location: Record Location; var LotNo: array[2] of Code[50]; LotQty: Decimal)
    var
        Index: Integer;
        TotalQty: Decimal;
    begin
        CreateTrackedItem(Item, true, false, false, false, false);
        CreateFullWMSLocation(Location, 2);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        for Index := 1 to ArrayLen(LotNo) do begin
            LotNo[Index] := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(LotNo[Index]);
            LibraryVariableStorage.Enqueue(LotQty);
            TotalQty += LotQty;
        end;
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(Item."No.", Location.Code, TotalQty, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateTrackedItem(var Item: Record Item; Lot: Boolean; Serial: Boolean; StrictExpirationPosting: Boolean; ManExpirDateEntryReqd: Boolean; UseExpirationDates: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, Lot, Serial, StrictExpirationPosting, ManExpirDateEntryReqd, UseExpirationDates);
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
    end;

    local procedure CreateLotTrackedItemWithExpirationCalculation(var Item: Record Item)
    var
        ExpirationCalculation: DateFormula;
    begin
        Evaluate(ExpirationCalculation, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));
        CreateTrackedItem(Item, true, false, false, false, true);
        Item.Validate("Expiration Calculation", ExpirationCalculation);
        Item.Modify(true);
    end;

    local procedure OpenInventoryMovement(var InventoryMovement: TestPage "Inventory Movement"; No: Code[20]; SourceNo: Code[20])
    begin
        InventoryMovement.OpenEdit();
        InventoryMovement.FILTER.SetFilter("No.", No);
        InventoryMovement.FILTER.SetFilter("Source No.", SourceNo);
    end;

    local procedure AssignSerialNoAndPostItemJournal(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournal: TestPage "Item Journal";
    begin
        ItemJournal.OpenEdit();
        LibraryVariableStorage.Enqueue(TrackingAction::SerialNo);
        ItemJournal.ItemTrackingLines.Invoke();

        // Update Reservation Entry to differentiate among Expiration Dates.
        UpdateReservationEntry(ItemNo, CalcDate('<' + '-' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()), LocationCode);  // Value required.
        ItemJournal.Post.Invoke();
    end;

    local procedure AssignNoSeriesForItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Find();
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure AssignTrackingForSalesOrder(var SalesOrder: TestPage "Sales Order"; No: Code[20])
    begin
        OpenSalesOrder(SalesOrder, No);
        LibraryVariableStorage.Enqueue(TrackingAction::SelectEntries);
        SalesOrder.SalesLines.ItemTrackingLines.Invoke();  // Open Item Tracking Line.
    end;

    local procedure AssignLotNoAndPostItemJournal()
    var
        ItemJournal: TestPage "Item Journal";
    begin
        ItemJournal.OpenEdit();
        LibraryVariableStorage.Enqueue(TrackingAction::LotNo);
        ItemJournal.ItemTrackingLines.Invoke();
        ItemJournal.Post.Invoke();
    end;

    local procedure AssignLotNoExpirationAndPostItemJournal(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
        ItemJournal: TestPage "Item Journal";
    begin
        ItemJournal.OpenEdit();
        LibraryVariableStorage.Enqueue(TrackingAction::LotNo);
        ItemJournal.ItemTrackingLines.Invoke();

        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Expiration Date", 0D);
        ReservationEntry.ModifyAll("Expiration Date", ExpirationDate, true);

        ItemJournal.Post.Invoke();
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; BinMandatory: Boolean; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; PickAccordingToFEFO: Boolean)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        Location.Validate("Pick According to FEFO", PickAccordingToFEFO);
        Location.Modify(true);
    end;

    local procedure CreateItemJournaLine(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateLotTrackedItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; PostingDate: Date; LotNo: Code[50]; Qty: Decimal)
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Qty);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure CreateAndPostSetOfLotTrackedItemJournalLines(var AssignedLotNos: array[2] of Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        i: Integer;
    begin
        for i := 1 to ArrayLen(AssignedLotNos) do begin
            AssignedLotNos[i] := LibraryUtility.GenerateGUID();
            CreateLotTrackedItemJournalLine(
              ItemJournalLine, ItemNo, '', LocationCode, BinCode, WorkDate() - i, AssignedLotNos[i], Qty);
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);

        if ItemTrackingCode <> '' then begin
            Item.Validate("Item Tracking Code", ItemTrackingCode);
            Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
            Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
            Item.Modify(true);
        end else begin
            // Update Inventory.
            CreateItemJournaLine(Item."No.", LocationWhite.Code, '', LibraryRandom.RandDec(100, 2));
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        end;
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Lot: Boolean; Serial: Boolean; StrictExpirationPosting: Boolean; ManExpirDateEntryReqd: Boolean; UseExpirationDates: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("Use Expiration Dates", UseExpirationDates);
        ItemTrackingCode.Validate("Strict Expiration Posting", StrictExpirationPosting);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManExpirDateEntryReqd);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateFullWhseLocationWithFEFO(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateFullWMSLocation(var Location: Record Location; BinsPerZone: Integer)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, BinsPerZone);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreatePurchaseLineAndAssignLotNo(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        UpdateLocationOnPurchaseLine(PurchaseLine, LocationCode);
        LibraryVariableStorage.Enqueue(true);
        PurchaseLine.OpenItemTrackingLines();
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Expiration Date", CalcDate('<CY+1D>', WorkDate()), true);
        exit(PurchaseLine.Quantity);
    end;

    local procedure CreateAndReleasePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        UpdateLocationOnPurchaseLine(PurchaseLine, LocationCode);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateWorkAndMachineCenter(var WorkCenter: Record "Work Center"; var Bin: Record Bin; var MachineCenter: Record "Machine Center")
    begin
        LibraryWarehouse.CreateBin(
          Bin, LocationOrange2.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        CreateWorkCenterSetup(WorkCenter);
        UpdateLocationOnWorkCenter(WorkCenter, LocationOrange2.Code);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreatePick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WarehouseShipmentNo: Code[20])
    begin
        WarehouseShipmentHeader.Get(WarehouseShipmentNo);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, 0D);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo,
          LibraryRandom.RandDec(100, 2), LocationCode, 0D);
    end;

    local procedure CreateAndPostWarehouseReceiptFromPO(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationCode, ItemNo);
        Quantity2 := PurchaseLine.Quantity;  // Assign value to global variable.
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure CreateAndPostWarehouseShipmentFromSO(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateAndReleaseSalesOrder(SalesHeader, ItemNo, Quantity, LocationCode);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
    end;

    local procedure CreateAndReleaseWhseShipment(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        WarehouseShipmentNo := WarehouseShipmentHeader."No.";  // Assign value to global variable.
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndCertifyRoutingSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenterSetup(WorkCenter);
        CreateRouting(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingHeader.Type::Serial);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateManufacturingSetup(var RoutingHeader: Record "Routing Header"; var Item: Record Item)
    begin
        CreateAndCertifyRoutingSetup(RoutingHeader);
        CreateItem(Item, '');
    end;

    local procedure CreateRouting(var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; WorkCenterNo: Code[20]; Type: Option)
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, Type);
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, WorkCenterNo, RoutingLine."Operation No.", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10));
    end;

    local procedure CreateWorkCenterSetup(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-2M>', WorkDate()), CalcDate('<2M>', WorkDate()));
    end;

    local procedure CreateWhseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithReservation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, ItemNo, Quantity, LocationCode);
        ReservationFromSalesOrder(SalesHeader."No.");  // Reserve Full Quantity on Sales Order.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        UpdateSalesLines(SalesLine, SalesHeader."No.", 2 * Quantity);  // Update Quantity to twice for partial reservation.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithShippingAdvice(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ShippingAdvice: Enum "Sales Header Shipping Advice")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, Quantity);
        SalesHeader.Validate("Shipping Advice", ShippingAdvice);
        SalesHeader.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndPostWhseReceiptFromPOWithBin(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; BinCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationOrange.Code, ItemNo);
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader);
        UpdateBinAndPostWhseReceiptLine(PurchaseHeader."No.", BinCode);
    end;

    local procedure CreateAndPostWhseReceiptAndRegisterPutAwayFromPO(var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndPostPurchaseWithReceiptAndPutaway(ItemNo: Code[20]; LotNos: array[3] of Code[20]; NoOfBins: Integer; LocationCode: Code[10]; QuantityPerLotPerBin: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        CreatePurchaseWithMultipleLotTracking(
          PurchaseHeader, ItemNo, LotNos, LocationCode, NoOfBins * ArrayLen(LotNos) * QuantityPerLotPerBin);
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        SplitAndRegisterPutAwayLines(PurchaseHeader."No.", LocationCode, LotNos, NoOfBins, QuantityPerLotPerBin);
    end;

    local procedure CreateWhseWorksheetName(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Pick);
        WhseWorksheetTemplate.FindFirst();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateAndReleasePurchaseOrderWithReceiptDate(PurchaseHeader, ItemNo, Quantity, LocationCode, WorkDate());
    end;

    local procedure CreateAndReleasePurchaseOrderWithReceiptDate(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ReceiptDate: Date)
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        UpdateLocationOnPurchaseLine(PurchaseLine, LocationCode);
        PurchaseLine.Validate("Expected Receipt Date", ReceiptDate);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithReservation(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ReceiptDate: Date)
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        CreateAndReleasePurchaseOrderWithReceiptDate(PurchaseHeader, ItemNo, Quantity, LocationCode, ReceiptDate);
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.Reserve.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure CreateAndReleaseTransferOrder(FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationIntransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndModifyLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateBinContent(var Bin: Record Bin; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10])
    var
        BinContent: Record "Bin Content";
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, CreateAndModifyLocationCode(), false);
        LibraryWarehouse.CreateBin(
          Bin, WarehouseEmployee."Location Code",
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, WarehouseEmployee."Location Code", '', Bin.Code, ItemNo, '', BaseUnitOfMeasure);
        BinContent.Validate(Fixed, false);
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithItemTrackingLines(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]) Quantity: Decimal
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        Quantity :=
          CreatePurchaseLineAndAssignLotNo(PurchaseHeader, ItemNo, LocationCode, LibraryRandom.RandDecInDecimalRange(100, 200, 2));
        CreatePurchaseLineAndAssignLotNo(PurchaseHeader, ItemNo, LocationCode, LibraryRandom.RandDecInDecimalRange(10, 20, 2));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        exit(Quantity);
    end;

    local procedure CreatePurchaseWithMultipleLotTracking(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LotNos: array[3] of Code[20]; LocationCode: Code[10]; Quantity: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, WorkDate());

        LibraryVariableStorage.Enqueue(ArrayLen(LotNos));
        for i := 1 to ArrayLen(LotNos) do begin
            LibraryVariableStorage.Enqueue(LotNos[i]);
            LibraryVariableStorage.Enqueue(Quantity / ArrayLen(LotNos));
        end;

        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesOrderWithItemTrackingLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, LibraryRandom.RandDecInRange(10, 15, 2));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(5, 2));
        SalesLine.OpenItemTrackingLines();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateSalesWithMultipleLotTracking(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; SalesQty: Decimal; NoOfLots: Integer; LotNos: array[3] of Code[20]; LotQty: Decimal)
    var
        i: Integer;
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, SalesQty);
        LibraryVariableStorage.Enqueue(NoOfLots);
        for i := 1 to NoOfLots do begin
            LibraryVariableStorage.Enqueue(LotNos[i]);
            LibraryVariableStorage.Enqueue(LotQty);
        end;
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure ChangeBinCodeOnActivityLine(BinCode: Code[20]; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationCode, SourceNo,
          WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure CreatePickFromPickWorksheet(LocationCode: Code[10]; QtyToHandle: Decimal)
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        CreateWhseWorksheetName(WhseWorksheetName, LocationCode);
        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode);
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode);
        UpdateQuantityOnWhseWorksheetLine(WhseWorksheetLine, QtyToHandle);
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          LocationCode, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
    end;

    local procedure CreatePutAway(ItemNo: Code[20])
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptLine.SetRange("Item No.", ItemNo);
        PostedWhseReceiptLine.FindFirst();
        PostedWhseReceiptLine.SetRange("No.", PostedWhseReceiptLine."No.");
        PostedWhseReceiptLine.SetHideValidationDialog(true);
        PostedWhseReceiptLine.CreatePutAwayDoc(PostedWhseReceiptLine, '');
    end;

    local procedure CreateRefreshedProductionOrderAndInbndWhseRequest(var ProductionOrder: Record "Production Order"; LocationCode: Code[10])
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        Quantity: Decimal;
    begin
        CreateItem(ParentItem, '');
        CreateItem(ComponentItem, '');
        Quantity := LibraryRandom.RandInt(10);
        UpdateItemInventory(ComponentItem."No.", LocationCode, '', Quantity);

        CreateAndCertifyProductionBOM(ProductionBOMHeader, ComponentItem."No.", Quantity, ParentItem."Base Unit of Measure");
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ParentItem."No.", LocationCode, Quantity);
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);
    end;

    local procedure CreateReleasedPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        CreateItem(Item, '');
        Quantity := LibraryRandom.RandInt(10);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorNo(), Item."No.", Quantity, LocationCode, WorkDate());
    end;

    local procedure CreateAndRegisterWhseJournalLine(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, '',
          BinCode, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, true);
    end;

    local procedure CreateWhseJournalLineWithLotTracking(WarehouseJournalBatch: Record "Warehouse Journal Batch"; Bin: Record Bin; ItemNo: Code[20]; Qty: Decimal; LotNo: Code[50]; ExpirationDate: Date)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          Bin."Location Code", Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        WarehouseJournalLine.OpenItemTrackingLines();

        WhseItemTrackingLine.SetRange("Lot No.", LotNo);
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.Validate("Expiration Date", ExpirationDate);
        WhseItemTrackingLine.Modify(true);
    end;

    local procedure CalcWhseAdjustmentAndPostItemJournal(var Item: Record Item)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, '');  // Value required.
    end;

    local procedure SplitAndRegisterPutAwayLines(SourceNo: Code[20]; LocationCode: Code[10]; LotNos: array[3] of Code[20]; NoOfBins: Integer; QuantityPerLotPerBin: Integer)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
        i: Integer;
        j: Integer;
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::"Put-away", WarehouseActivityLine."No.");

        for i := 1 to ArrayLen(LotNos) do
            for j := 1 to NoOfBins do begin
                FindPlaceActivityLine(WarehouseActivityLine, WarehouseActivityHeader."No.", LotNos[i]);
                if j <> NoOfBins then // for N put-away lines we should perform N-1 splitting operations
                    SplitActivityLine(WarehouseActivityLine, QuantityPerLotPerBin);
                LibraryWarehouse.FindBin(Bin, LocationCode, 'PICK', j);
                UpdateBinOnActivityLine(WarehouseActivityLine, 'PICK', Bin.Code);
            end;

        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindPlaceActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityNo: Code[20]; LotNo: Code[50])
    begin
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityNo);
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        WarehouseActivityLine.FindLast();
    end;

    local procedure SplitActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyToHandle: Decimal)
    begin
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);
    end;

    local procedure GetLotNoFromItemEntry(ItemNo: Code[20]): Code[20]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindLast();
        exit(ItemLedgerEntry."Lot No.");
    end;

    local procedure GetFirstProdOrderLineNo(ProductionOrder: Record "Production Order"): Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        exit(ProdOrderLine."Line No.");
    end;

    local procedure RegisterAndDeletePartialPick(var WarehouseActivityHeader: Record "Warehouse Activity Header"; PartialQtyMultiplier: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity * PartialQtyMultiplier);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.");
        WarehouseActivityHeader.Delete(true);
    end;

    local procedure DeleteWarehouseActivity(WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        WarehouseActivityHeader.Delete(true);
    end;

    local procedure DeleteWarehouseShipmentLines(WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        WarehouseShipmentHeader.SetRange("No.", WarehouseShipmentNo);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.ReopenWhseShipment(WarehouseShipmentHeader);
        WarehouseShipmentHeader.DeleteAll(true);
    end;

    local procedure DeleteWhseItemTracking(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        FilterWhseItemTracking(WhseItemTrackingLine, SourceType, SourceSubtype, SourceID, SourceRefNo);
        WhseItemTrackingLine.DeleteAll(true);
    end;

    local procedure ExplodeRoutingAndPostOutputJournal(ProdOrderLine: Record "Prod. Order Line"; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        OutputJournalExplodeRouting(ItemJournalLine, ProdOrderLine."Prod. Order No.", Quantity, false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, ActivityType);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentNo(): Code[20]
    var
        WarehouseSetup: Record "Warehouse Setup";
        NoSeries: Codeunit "No. Series";
    begin
        WarehouseSetup.Get();
        exit(NoSeries.PeekNextNo(WarehouseSetup."Whse. Ship Nos."));
    end;

    local procedure FindWarehouseReceiptNo(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20])
    begin
        WarehouseActivityHeader.SetRange("Source No.", SourceNo);
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure FindRegisterWarehouseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; SourceNo: Code[20])
    begin
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Location Code", LocationCode);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.FindFirst();
    end;

    local procedure FindBin(var Bin: Record Bin)
    begin
        Bin.SetRange("Location Code", LocationWhite.Code);
        Bin.SetRange("Adjustment Bin", false);
        Bin.FindFirst();
    end;

    local procedure FindBinContent(var BinContent: Record "Bin Content"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.FindFirst();
    end;

    local procedure FindWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FilterWarehouseShipmentLine(WarehouseShipmentLine, SourceNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FilterWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
    end;

    local procedure FilterWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; LocationCode: Code[10]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; LotNoFilter: Text; BinCodeFilter: Text)
    begin
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetCurrentKey(
          "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code", "Unit of Measure Code", "Breakbulk No.",
          "Activity Type", "Lot No.");
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetFilter("Lot No.", LotNoFilter);
        WarehouseActivityLine.SetFilter("Bin Code", BinCodeFilter);
    end;

    local procedure FilterWhseItemTracking(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer)
    begin
        WhseItemTrackingLine.SetRange("Source Type", SourceType);
        WhseItemTrackingLine.SetRange("Source Subtype", SourceSubtype);
        WhseItemTrackingLine.SetRange("Source ID", SourceID);
        WhseItemTrackingLine.SetRange("Source Ref. No.", SourceRefNo);
    end;

    local procedure GetQuantityFromWareHouseInventoryActivityLines(LocationCode: Code[10]; ItemNo: Code[20]; SalesHeaderNo: Code[20]) WarehouseActivityLineQuantity: Decimal
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Sales Order");
        WarehouseActivityHeader.SetRange("Source No.", SalesHeaderNo);
        WarehouseActivityHeader.FindFirst();
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLineQuantity += WarehouseActivityLine.Quantity;
        until WarehouseActivityLine.Next() = 0;
        exit(WarehouseActivityLineQuantity);
    end;

    local procedure PostInventoryPick(SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Invt. Pick");
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptNo(WarehouseReceiptLine, SourceDocument, SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure MakeInventoryDistributedByLotsAndBins(var LocationCode: Code[10]; var ItemNo: Code[20]; var LotNos: array[3] of Code[20]; var NoOfBins: Integer; var LotQuantity: Decimal; var FullQuantity: Decimal; QuantityPerLotPerBin: Decimal)
    var
        Item: Record Item;
        Location: Record Location;
        i: Integer;
    begin
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
        NoOfBins := ArrayLen(LotNos);
        LotQuantity := NoOfBins * QuantityPerLotPerBin;
        FullQuantity := ArrayLen(LotNos) * LotQuantity;

        CreateTrackedItem(Item, true, false, false, false, false);
        LibraryWarehouse.CreateFullWMSLocation(Location, NoOfBins);
        ItemNo := Item."No.";
        LocationCode := Location.Code;

        CreateAndPostPurchaseWithReceiptAndPutaway(ItemNo, LotNos, NoOfBins, LocationCode, QuantityPerLotPerBin);
    end;

    local procedure PrepareInventoryAndTrackedSalesDocumentForPick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var LocationCode: Code[10]; var ItemNo: Code[20]; var LotNos: array[3] of Code[20]; var NoOfBins: Integer; QuantityPerLotPerBin: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FullQuantity: Decimal;
        LotQuantity: Decimal;
    begin
        MakeInventoryDistributedByLotsAndBins(LocationCode, ItemNo, LotNos, NoOfBins, LotQuantity, FullQuantity, QuantityPerLotPerBin);

        CreateSalesWithMultipleLotTracking(
          SalesHeader, SalesLine, ItemNo, LocationCode, FullQuantity, ArrayLen(LotNos), LotNos, LotQuantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
    end;

    local procedure PrepareInventoryAndNotTrackedSalesDocumentForPick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var LocationCode: Code[10]; var ItemNo: Code[20]; var LotNos: array[3] of Code[20]; var NoOfBins: Integer; QuantityPerLotPerBin: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FullQuantity: Decimal;
        LotQuantity: Decimal;
    begin
        MakeInventoryDistributedByLotsAndBins(LocationCode, ItemNo, LotNos, NoOfBins, LotQuantity, FullQuantity, QuantityPerLotPerBin);

        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, FullQuantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
    end;

    local procedure PrepareInventoryWithExpDatesAndSalesShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10]; ItemNo: Code[20]; LotNos: array[3] of Code[20]; LotQty: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        CreatePurchaseWithMultipleLotTracking(PurchaseHeader, ItemNo, LotNos, LocationCode, ArrayLen(LotNos) * LotQty);
        UpdateReservationEntry(ItemNo, WorkDate() - 1, LocationCode);
        CreateAndPostWhseReceiptAndRegisterPutAwayFromPO(PurchaseHeader);

        CreateAndReleaseSalesOrder(SalesHeader, ItemNo, ArrayLen(LotNos) * LotQty, LocationCode);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, Type);
        WarehouseActivityHeader.SetRange(Type, Type);
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure UpdateReservationEntry(ItemNo: Code[20]; ExpirationDate: Date; LocationCode: Code[10])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.FindFirst();
        ReservationEntry.Validate("Expiration Date", ExpirationDate);
        ReservationEntry.Modify(true);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetFilter("Expiration Date", '<>%1', ExpirationDate);
        ReservationEntry.FindSet();
        repeat
            ReservationEntry.Validate("Expiration Date", WorkDate());
            ReservationEntry.Modify(true);
        until ReservationEntry.Next() = 0;
    end;

    local procedure UpdateQuantityToHandleOnActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; SourceNo: Code[20]; QtyToHandle: Decimal)
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SourceNo, ActionType);
        UpdateQuantityOnActivityLine(WarehouseActivityLine, QtyToHandle);
    end;

    local procedure UpdateAndCreatePick(WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Update Quantity to Handle on Whse Activity Line to half on Whse Activity Line.
        UpdatePick(WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, SourceNo, Quantity2 / 4);
        UpdatePick(WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, SourceNo, Quantity2 / 4);
        RegisterWarehouseActivity(SourceNo, WarehouseActivityHeader.Type::Pick);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);
    end;

    local procedure UpdatePick(WarehouseActivityLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; QtyToHandle: Decimal)
    begin
        UpdateQuantityToHandleOnActivityLine(
          WarehouseActivityLine, ActionType, LocationWhite.Code, SourceNo, QtyToHandle);
        WarehouseActivityLine.Validate("Qty. Outstanding", 0);  // Making rest of availability i,e Qty. Outstanding to be nullified for the test.
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateBinOnLocation()
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);
        LocationSilver.Validate("To-Production Bin Code", Bin.Code);
        LocationSilver.Modify(true);
    end;

    local procedure UpdateLocationSetup(AlwaysCreatePickLine: Boolean)
    begin
        LocationWhite.Validate("Always Create Pick Line", AlwaysCreatePickLine);
        LocationWhite.Modify(true);
    end;

    local procedure OutputJournalExplodeRouting(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20]; Quantity: Decimal; UpdateItemJournalLine: Boolean)
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Output, '', 0);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProductionOrderNo);
        ItemJournalLine.Modify(true);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        if UpdateItemJournalLine then begin
            ItemJournalLine.Validate("Output Quantity", Quantity);
            ItemJournalLine.Modify(true);
        end;
    end;

    local procedure OpenSalesOrder(var SalesOrder: TestPage "Sales Order"; No: Code[20])
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenLocationCard(var LocationCard: TestPage "Location Card"; LocationCode: Code[10])
    begin
        LocationCard.OpenEdit();
        LocationCard.FILTER.SetFilter(Code, LocationCode);
    end;

    local procedure OpenWorkCenterCard(var WorkcenterCard: TestPage "Work Center Card"; LocationCode: Code[20])
    begin
        WorkcenterCard.OpenEdit();
        WorkcenterCard.FILTER.SetFilter("Location Code", LocationCode);
    end;

    local procedure OpenMachineCenterCard(var MachineCenterCard: TestPage "Machine Center Card"; WorkCenterNo: Code[20])
    begin
        MachineCenterCard.OpenEdit();
        MachineCenterCard.FILTER.SetFilter("Work Center No.", WorkCenterNo);
    end;

    local procedure CreateInventoryPutAwayHeaderWithLocationCode(var WarehouseActivityHeader: Record "Warehouse Activity Header"; LocationCode: Code[10])
    begin
        WarehouseActivityHeader.Validate(Type, WarehouseActivityHeader.Type::"Invt. Put-away");
        WarehouseActivityHeader.Validate("Location Code", LocationCode);
        WarehouseActivityHeader.Insert(true);
    end;

    local procedure PostPurchaseReceiptWithItemTracking(Item: Record Item; LotNo: array[3] of Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Bin: Record Bin;
    begin
        CreatePurchaseWithMultipleLotTracking(PurchaseHeader, Item."No.", LotNo, LocationCode, 3);

        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader);
        FindWarehouseReceiptNo(
          WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        LibraryWarehouse.FindBin(Bin, LocationCode, '', 1);
        WarehouseReceiptLine.Validate("Bin Code", Bin.Code);
        WarehouseReceiptLine.Modify(true);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure ReservationFromSalesOrder(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines.Reserve.Invoke();
        SalesOrder.Close();
    end;

    local procedure UpdateProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    var
        Bin: Record Bin;
    begin
        FindBin(Bin);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Bin Code", Bin.Code);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateSalesLines(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; Quantity: Decimal)
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    local procedure UpdateInventoryUsingWhseJournal(Location: Record Location; Item: Record Item; Quantity: Decimal)
    begin
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        CreateAndRegisterWhseJournalLine(Location.Code, Location."Cross-Dock Bin Code", Item."No.", Quantity);
        CalcWhseAdjustmentAndPostItemJournal(Item);
    end;

    local procedure UpdateInventoryWithTrackingUsingWhseJournal(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; Qty: Decimal)
    var
        Item: Record Item;
        WhseJournalTemplate: Record "Warehouse Journal Template";
        WhseJournalBatch: Record "Warehouse Journal Batch";
        WhseJournalLine: Record "Warehouse Journal Line";
    begin
        Item.Get(ItemNo);
        LibraryWarehouse.SelectWhseJournalTemplateName(WhseJournalTemplate, WhseJournalTemplate.Type::Item);
        LibraryWarehouse.SelectWhseJournalBatchName(
          WhseJournalBatch, WhseJournalBatch."Template Type"::Item, WhseJournalTemplate.Name, LocationCode);

        LibraryWarehouse.CreateWhseJournalLine(
          WhseJournalLine, WhseJournalBatch."Journal Template Name", WhseJournalBatch.Name, LocationCode, '', BinCode,
          WhseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        WhseJournalLine.Validate("Variant Code", VariantCode);
        WhseJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Abs(Qty));
        WhseJournalLine.OpenItemTrackingLines();
        LibraryWarehouse.RegisterWhseJournalLine(
          WhseJournalBatch."Journal Template Name", WhseJournalBatch.Name, LocationCode, true);

        CalcWhseAdjustmentAndPostItemJournal(Item);
    end;

    local procedure UpdateBinOnActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ZoneCode: Code[10]; BinCode: Code[20])
    begin
        WarehouseActivityLine.Validate("Zone Code", ZoneCode);
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateBinAndPostWhseReceiptLine(SourceNo: Code[20]; BinCode: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptLine.Validate("Bin Code", BinCode);
        WarehouseReceiptLine.Modify(true);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
    end;

    local procedure UpdateBinOnWhseShipmentLine(SourceNo: Code[20]; BinCode: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Bin Code", BinCode);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure UpdateQuantityToHandleAndBinOnActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; QtyToHandle: Decimal; ActivityType: Enum "Warehouse Activity Type"; BinCode: Code[20])
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationOrange.Code, SourceNo, ActionType);
        ChangeBinCodeOnActivityLine(BinCode, SourceNo, LocationOrange.Code);
        UpdateQuantityOnActivityLine(WarehouseActivityLine, QtyToHandle);
    end;

    local procedure UpdateQuantityOnWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; QtyToHandle: Decimal)
    begin
        WhseWorksheetLine.Validate("Qty. to Handle", QtyToHandle);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure UpdateQuantityOnActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyToHandle: Decimal)
    begin
        WarehouseActivityLine.Validate("Qty. to Handle (Base)", QtyToHandle);
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateLocationForBinMandatory(var Location: Record Location; BinMandatory: Boolean)
    begin
        Location.Validate("Bin Mandatory", BinMandatory);
        Location.Modify(true);
    end;

    local procedure UpdateLocationOnWorkCenter(WorkCenter: Record "Work Center"; LocationCode: Code[10])
    begin
        WorkCenter.Validate("Location Code", LocationCode);
        WorkCenter.Modify(true);
    end;

    local procedure UpdateLocationOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    begin
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure SetBinOnLocationCard(var LocationCard: TestPage "Location Card"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        OpenLocationCard(LocationCard, LocationCode);
        LocationCard."Open Shop Floor Bin Code".SetValue(BinCode);
        LocationCard."To-Production Bin Code".SetValue(BinCode);
        LocationCard."From-Production Bin Code".SetValue(BinCode);
        LocationCard.OK().Invoke();
    end;

    local procedure SetBinOnWorkCenterCard(var WorkCenterCard: TestPage "Work Center Card"; No: Code[20]; BinCode: Code[20])
    begin
        OpenWorkCenterCard(WorkCenterCard, No);
        WorkCenterCard."Open Shop Floor Bin Code".SetValue(BinCode);
        WorkCenterCard."To-Production Bin Code".SetValue(BinCode);
        WorkCenterCard."From-Production Bin Code".SetValue(BinCode);
        WorkCenterCard.OK().Invoke();
    end;

    local procedure SetBinOnMachineCenterCard(var MachineCenterCard: TestPage "Machine Center Card"; WorkCenterNo: Code[20]; BinCode: Code[20])
    begin
        OpenMachineCenterCard(MachineCenterCard, WorkCenterNo);
        MachineCenterCard."Open Shop Floor Bin Code".SetValue(BinCode);
        MachineCenterCard."To-Production Bin Code".SetValue(BinCode);
        MachineCenterCard."From-Production Bin Code".SetValue(BinCode);
        MachineCenterCard.OK().Invoke();
    end;

    local procedure CreateItemWithNonBaseUnitOfMeasure(var Item: Record Item; QtyPerUoM: Decimal): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPerUoM);
        exit(ItemUnitOfMeasure.Code);
    end;

    local procedure PostItemPurchaseAndRegisterPutAway(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorNo(), ItemNo, Quantity, LocationCode, WorkDate());
        CreateAndPostWhseReceiptAndRegisterPutAwayFromPO(PurchaseHeader);
    end;

    local procedure CreateItemSalesOrderAndReleaseShipment(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, ItemNo, Quantity, LocationCode);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        WarehouseShipmentNo := WarehouseShipmentHeader."No.";
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateItemWhseWorksheetInternalPickLineWithUOM(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20]; ItemUnitofMeasureCode: Code[10])
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        CreateWhseWorksheetName(WhseWorksheetName, LocationCode);
        LibraryWarehouse.CreateWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          LocationCode, WhseWorksheetLine."Whse. Document Type"::"Internal Pick");

        WhseWorksheetLine.Validate("Item No.", ItemNo);
        WhseWorksheetLine.Validate("Unit of Measure Code", ItemUnitofMeasureCode);
    end;

    local procedure CreateItemInventoryAndWhseWorksheetInternalPickLineWithUOM(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ItemNo: Code[20]; ItemUnitofMeasureCode: Code[10]; Quantity: Decimal)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        PostItemPurchaseAndRegisterPutAway(ItemNo, Quantity, Location.Code);
        CreateItemSalesOrderAndReleaseShipment(ItemNo, Quantity, Location.Code);
        CreateItemWhseWorksheetInternalPickLineWithUOM(WhseWorksheetLine, Location.Code, ItemNo, ItemUnitofMeasureCode);
    end;

    local procedure SetQtyReserved(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; SalesQty: Decimal; ReservedQty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, ReservedQty);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        SalesLine.Validate(Quantity, SalesQty);
        SalesLine.Modify(true);
    end;

    local procedure SetLotReserved(ItemNo: Code[20]; LocationCode: Code[10]; LotNos: array[3] of Code[20]; LotNoIndex: Integer; LotQuantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesWithMultipleLotTracking(
          SalesHeader, SalesLine, ItemNo, LocationCode, LotQuantity, LotNoIndex, LotNos, LotQuantity);
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure SetLotBlocked(ItemNo: Code[20]; LotNos: array[3] of Code[20]; LotNoIndex: Integer)
    var
        LotNoInformation: Record "Lot No. Information";
    begin
        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, ItemNo, '', LotNos[LotNoIndex]);
        LotNoInformation.Validate(Blocked, true);
        LotNoInformation.Modify(true);
    end;

    local procedure SetBinContentBlocked(var BinCode: Code[20]; BinIndex: Integer; LocationCode: Code[10]; ItemNo: Code[20])
    var
        Bin: Record Bin;
        Item: Record Item;
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.FindBin(Bin, LocationCode, 'PICK', BinIndex);
        BinCode := Bin.Code;
        Item.Get(ItemNo);
        BinContent.Get(LocationCode, BinCode, ItemNo, '', Item."Base Unit of Measure");
        BinContent.Validate("Block Movement", BinContent."Block Movement"::All);
        BinContent.Modify(true);
    end;

    local procedure VerifyInventoryPutAwayPick(WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal)
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedInventorytPickLine(SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; ExpirationDate: Date; BinCode: Code[20])
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.SetRange("Location Code", LocationCode);
        PostedInvtPickLine.FindFirst();
        PostedInvtPickLine.TestField("Item No.", ItemNo);
        PostedInvtPickLine.TestField("Expiration Date", ExpirationDate);
        PostedInvtPickLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ExpectedQuantity: Decimal; SourceNo: Code[20]; LocationCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SourceNo,
          WarehouseActivityLine."Action Type"::Take);
        Assert.AreNearlyEqual(
          ExpectedQuantity, WarehouseActivityLine.Quantity, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(QuantityError, ExpectedQuantity, WarehouseActivityLine.TableCaption()));
        Assert.AreNearlyEqual(
          ExpectedQuantity, WarehouseActivityLine."Qty. Outstanding", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(QuantityError, ExpectedQuantity, WarehouseActivityLine.TableCaption()));
    end;

    local procedure VerifyQtyOnWhseActivityLinesByLotNo(LocationCode: Code[10]; ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FilterWarehouseActivityLine(
          WarehouseActivityLine, ItemNo, LocationCode, WarehouseActivityLine."Activity Type"::Pick,
          WarehouseActivityLine."Action Type"::Take, '', '');
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");
        WarehouseActivityLine.TestField("Qty. Outstanding (Base)", Qty);
    end;

    local procedure VerifyWarehouseShipmentLine(No: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", No);
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseActivityTakePlaceLinesQtyAndLot(SourceNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SourceNo, WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField(Quantity, Qty);
        WarehouseActivityLine.TestField("Lot No.", LotNo);
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SourceNo, WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.TestField(Quantity, Qty);
        WarehouseActivityLine.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyRegisteredWhseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line"; ExpectedQuantity: Decimal)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindRegisterWarehouseActivityLine(
          RegisteredWhseActivityLine, WarehouseActivityLine."Activity Type", WarehouseActivityLine."Action Type",
          WarehouseActivityLine."Location Code", WarehouseActivityLine."Source No.");
        Assert.AreNearlyEqual(
          ExpectedQuantity, RegisteredWhseActivityLine.Quantity, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(QuantityError, ExpectedQuantity, WarehouseActivityLine.TableCaption()));
    end;

    local procedure VerifyBinCode(ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; SourceNo: Code[20]; ExpectedBinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, SourceNo, ActionType);
        Assert.AreEqual(
          ExpectedBinCode, WarehouseActivityLine."Bin Code", StrSubstNo(BinError, ExpectedBinCode, WarehouseActivityLine.TableCaption()));
    end;

    local procedure VerifyMultipleWhseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; ExpectedQuantity: Decimal; SourceNo: Code[20]; LocationCode: Code[10])
    begin
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SourceNo, WarehouseActivityLine."Action Type");
        repeat
            WarehouseActivityLine.TestField(Quantity, ExpectedQuantity);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyBinOnLocationCard(LocationCode: Code[10]; BinCode: Code[20])
    var
        LocationCard: TestPage "Location Card";
    begin
        OpenLocationCard(LocationCard, LocationCode);
        LocationCard."Open Shop Floor Bin Code".AssertEquals(BinCode);
        LocationCard."To-Production Bin Code".AssertEquals(BinCode);
        LocationCard."From-Production Bin Code".AssertEquals(BinCode);
    end;

    local procedure VerifyBinOnWorkCenterCard(LocationCode: Code[10]; BinCode: Code[20])
    var
        WorkCenterCard: TestPage "Work Center Card";
    begin
        OpenWorkCenterCard(WorkCenterCard, LocationCode);
        WorkCenterCard."Open Shop Floor Bin Code".AssertEquals(BinCode);
        WorkCenterCard."To-Production Bin Code".AssertEquals(BinCode);
        WorkCenterCard."From-Production Bin Code".AssertEquals(BinCode);
    end;

    local procedure VerifyBinOnMachineCenterCard(WorkCenterNo: Code[20]; BinCode: Code[20])
    var
        MachineCenterCard: TestPage "Machine Center Card";
    begin
        OpenMachineCenterCard(MachineCenterCard, WorkCenterNo);
        MachineCenterCard."Open Shop Floor Bin Code".AssertEquals(BinCode);
        MachineCenterCard."To-Production Bin Code".AssertEquals(BinCode);
        MachineCenterCard."From-Production Bin Code".AssertEquals(BinCode);
    end;

    local procedure VerifyLocationOnWorkCenter(No: Code[20]; LocationCode: Code[10])
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetRange("No.", No);
        WorkCenter.FindFirst();
        WorkCenter.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Location Code", LocationCode);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyLotAndExpirationDateOnWhseActivityLines(DocumentType: Option; DocumentNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseActivityLine.SetRange("Source Subtype", DocumentType);
        WarehouseActivityLine.SetRange("Source No.", DocumentNo);
        WarehouseActivityLine.FindSet();
        repeat
            Assert.AreNotEqual('', WarehouseActivityLine."Lot No.", StrSubstNo(FieldMustNotBeEmptyErr, WarehouseActivityLine.FieldCaption("Lot No."), WarehouseActivityLine.TableCaption));
            Assert.AreNotEqual(0D, WarehouseActivityLine."Expiration Date", StrSubstNo(FieldMustNotBeEmptyErr, WarehouseActivityLine.FieldCaption("Expiration Date"), WarehouseActivityLine.TableCaption))
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyWhseActivityLotNo(LocationCode: Code[10]; ItemNo: Code[20]; ExpectedQuantity: Decimal; ExpectedLotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, ExpectedQuantity);
        WarehouseActivityLine.TestField("Lot No.", ExpectedLotNo);
    end;

    local procedure CreateLocation(var Location: Record Location): Code[10]
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        exit(Location.Code);
    end;

    local procedure CreateItemJournalLine(var ItemJnlTemplate: Record "Item Journal Template"; var ItemJnlBatch: Record "Item Journal Batch"; var ItemJnlLine: Record "Item Journal Line"; Item: Record Item)
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(100));
    end;

    local procedure CreateReleasedProdOrderAndRefresh(var ProductionOrder: Record "Production Order"; Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; Qty: Integer)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure AddComponentToProdOrder(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; QuantityPer: Decimal; LocationCode: Code[10]; BinCode: Code[20]; FlushingMethod: Enum "Flushing Method")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProdOrderComponent.Init();
        ProdOrderComponent.Status := ProductionOrder.Status;
        ProdOrderComponent."Prod. Order No." := ProductionOrder."No.";
        ProdOrderComponent."Prod. Order Line No." := ProdOrderLine."Line No.";
        ProdOrderComponent."Line No." += 10000;
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Validate("Flushing Method", FlushingMethod);
        ProdOrderComponent.Validate("Bin Code", BinCode);
        ProdOrderComponent.Validate("Quantity per", QuantityPer);
        ProdOrderComponent.Insert(true);

        LibraryVariableStorage.Enqueue(ProductionOrder."No.");
    end;

    local procedure CreateAndCertifyProductionBOM(
        var ProductionBOMHeader: Record "Production BOM Header";
        var ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item)
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader,
            ProductionBOMLine,
            '',
            ProductionBOMLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(0));

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndRefreshFirmPlannedProdOrder(var ProductionOrder: Record "Production Order"; Item: Record Item)
    begin
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::"Firm Planned",
            ProductionOrder."Source Type"::Item,
            Item."No.",
            LibraryRandom.RandInt(0));

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocCode: Code[10])
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(10, 10));
        PurchaseLine.Validate("Location Code", LocCode);
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocCode: Code[10])
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(0));
        SalesLine.Validate("Location Code", LocCode);
        SalesLine.Modify(true);
    end;

    local procedure FindBinType(
        var BinType: Record "Bin Type";
        Receive: Boolean;
        Ship: Boolean;
        Pick: Boolean;
        PutAway: Boolean)
    begin
        BinType.SetRange("Put Away", PutAway);
        BinType.SetRange(Pick, Pick);
        BinType.SetRange(Receive, Receive);
        BinType.SetRange(Ship, Ship);
        BinType.FindFirst();
    end;

    local procedure CreateAndReserveSalesLine(
        var Salesheader: Record "Sales Header";
        var SalesLine: Record "Sales Line";
        Item: Record Item;
        Location: Record Location;
        Qty: Decimal)
    var
        Index: Integer;
    begin
        for Index := 1 to 5 do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
            SalesLine.Validate("Location Code", Location.Code);
            SalesLine.Modify(true);

            LibrarySales.AutoReserveSalesLine(SalesLine);

            LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);
            LibraryVariableStorage.Enqueue(Format(Qty));
            LibraryVariableStorage.Enqueue(Qty);
            SalesLine.OpenItemTrackingLines();

            Qty -= LibraryRandom.RandIntInRange(50, 50);
        end;
    end;

    local procedure GetWarehouseDocumentOnWarehouseWorksheetLine(
        var WhseWorksheetName: Record "Whse. Worksheet Name";
        Location: Record Location;
        DocumentNo: Code[20];
        DocumentNo2: Code[20])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);
        WhsePickRequest.SetRange(Status, WhsePickRequest.Status::Released);
        WhsePickRequest.SetRange("Completely Picked", false);
        WhsePickRequest.SetRange("Location Code", Location.Code);
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Shipment);
        if DocumentNo <> '' then
            WhsePickRequest.SetFilter("Document No.", '%1|%2', DocumentNo, DocumentNo2);
        LibraryWarehouse.GetOutboundSourceDocuments(WhsePickRequest, WhseWorksheetName, Location.Code);
    end;

    local procedure FindLastWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindLast();
    end;

    local procedure FindAndRegisterWhseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; Qty: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ActionType: Enum "Warehouse Action Type";
    begin
        FindWhseActivityLineWithQtyToHandle(
            WarehouseActivityLine,
            ActivityType,
            LocationCode,
            SourceNo,
            ActionType::Take,
            Qty);

        FindWhseActivityLineWithQtyToHandle(
            WarehouseActivityLine,
            ActivityType,
            LocationCode,
            SourceNo,
            ActionType::Place,
            Qty);

        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();

        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindWhseActivityLineWithQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; Qty: Decimal)
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, ActivityType);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Qty. to Handle", Qty);
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure FindAndValidateQtyToHandleInWhseActivityLine(Item: Record Item)
    var
        WarehouseActivitLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivitLine.SetRange("Item No.", Item."No.");
        WarehouseActivitLine.FindFirst();
        WarehouseActivitLine.Validate("Qty. to Handle", WarehouseActivitLine.Quantity);
        WarehouseActivitLine.Modify(true);

        WarehouseActivitLine.SetRange("Item No.", Item."No.");
        WarehouseActivitLine.FindLast();
        WarehouseActivitLine.Validate("Qty. to Handle", WarehouseActivitLine.Quantity);
        WarehouseActivitLine.Modify(true);
    end;

    local procedure CreateAndPostWhseJournalLines(
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin)
    var
        WhseJournalTemplate: Record "Warehouse Journal Template";
        WhseJournalBatch: Record "Warehouse Journal Batch";
        WhseJournalLine: array[3] of Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WhseJournalTemplate, WhseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WhseJournalBatch, WhseJournalTemplate.Name, Location.Code);

        LibraryWarehouse.CreateWhseJournalLine(
            WhseJournalLine[1],
            WhseJournalTemplate.Name,
            WhseJournalBatch.Name,
            Location.Code,
            Zone.Code,
            Bin.Code,
            WhseJournalLine[1]."Entry Type"::"Positive Adjmt.",
            Item."No.",
            LibraryRandom.RandIntInRange(5, 5));

        LibraryWarehouse.CreateWhseJournalLine(
            WhseJournalLine[2],
            WhseJournalTemplate.Name,
            WhseJournalBatch.Name,
            Location.Code,
            Zone.Code,
            Bin.Code,
            WhseJournalLine[2]."Entry Type"::"Positive Adjmt.",
            Item2."No.",
            LibraryRandom.RandIntInRange(5, 5));

        LibraryWarehouse.CreateWhseJournalLine(
            WhseJournalLine[3],
            WhseJournalTemplate.Name,
            WhseJournalBatch.Name,
            Location.Code,
            Zone.Code,
            Bin.Code,
            WhseJournalLine[3]."Entry Type"::"Positive Adjmt.",
            Item3."No.",
            LibraryRandom.RandIntInRange(5, 5));

        LibraryWarehouse.PostWhseJournalLine(WhseJournalTemplate.Name, WhseJournalBatch.Name, Location.Code);
    end;

    local procedure CreateBinType(var BinType: Record "Bin Type")
    begin
        BinType.SetRange("Put Away", true);
        BinType.SetRange(Pick, true);
        if not BinType.FindFirst() then
            LibraryWarehouse.CreateBinType(BinType, false, false, true, true);
    end;

    local procedure CreatePickFromWhseShipimentLine(WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseShptCreatePick: Report "Whse.-Shipment - Create Pick";
    begin
        WhseShptLine.SetRange("No.", WhseShptHeader."No.");
        WhseShptLine.FindFirst();

        WhseShptCreatePick.SetWhseShipmentLine(WhseShptLine, WhseShptHeader);
        WhseShptCreatePick.SetHideValidationDialog(true);
        WhseShptCreatePick.UseRequestPage(true);
        WhseShptCreatePick.RunModal();
    end;

    local procedure CreateItemWithStockSeveralPackages(var Item: Record Item; var Location: Record Location; var PackageNo: array[2] of Code[50]; PackageQty: Decimal)
    var
        Index: Integer;
        TotalQty: Decimal;
    begin
        CreateTrackedItemWithPackage(Item, false, false, true, false, false, false);
        CreateFullWMSLocation(Location, 2);
        LibraryVariableStorage.Enqueue(ArrayLen(PackageNo));
        for Index := 1 to ArrayLen(PackageNo) do begin
            PackageNo[Index] := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(PackageNo[Index]);
            LibraryVariableStorage.Enqueue(PackageQty);
            TotalQty += PackageQty;
        end;
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(Item."No.", Location.Code, TotalQty, true);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateTrackedItemWithPackage(var Item: Record Item; Lot: Boolean; Serial: Boolean; Package: Boolean; StrictExpirationPosting: Boolean; ManExpirDateEntryReqd: Boolean; UseExpirationDates: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCodeIncludingPackage(ItemTrackingCode, Lot, Serial, Package, StrictExpirationPosting, ManExpirDateEntryReqd, UseExpirationDates);
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
    end;

    local procedure CreateItemTrackingCodeIncludingPackage(var ItemTrackingCode: Record "Item Tracking Code"; Lot: Boolean; Serial: Boolean; Package: Boolean; StrictExpirationPosting: Boolean; ManExpirDateEntryReqd: Boolean; UseExpirationDates: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot, Package);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("Package Specific Tracking", Package);
        ItemTrackingCode.Validate("Use Expiration Dates", UseExpirationDates);
        ItemTrackingCode.Validate("Strict Expiration Posting", StrictExpirationPosting);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManExpirDateEntryReqd);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateProdOrderWithPackageTrackedComponentItem(var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component"; ParentItemNo: Code[20]; ParentItemQty: Decimal; ChildItemNo: Code[20]; ChildItemQty: Decimal; ChildItemPackageNo: Code[50]; LocationCode: Code[10])
    begin
        CreateProdOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItemNo, LocationCode, ParentItemQty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);
        CreateProductionOrderComponentWithItemQtyAndFlushingMethod(
            ProdOrderComponent, ProdOrderComponent.Status::Released, ProductionOrder."No.", GetFirstProdOrderLineNo(ProductionOrder),
            ChildItemNo, ChildItemQty, LocationCode, "Flushing Method"::Manual);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignPackageNo);
        LibraryVariableStorage.Enqueue(ChildItemPackageNo);
        LibraryVariableStorage.Enqueue(ProdOrderComponent.Quantity);
        ProdOrderComponent.OpenItemTrackingLines();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifyWarehouseActivityTakePlaceLinesQtyAndPackage(SourceNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; PackageNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SourceNo, WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField(Quantity, Qty);
        WarehouseActivityLine.TestField("Package No.", PackageNo);
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SourceNo, WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.TestField(Quantity, Qty);
        WarehouseActivityLine.TestField("Package No.", PackageNo);
    end;

    local procedure PrepareSalesOrderWithWhseShipment(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; UnitofMeasureCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
         '', ItemNo, Qty, LocationCode, 0D);
        SalesLine.Validate("Unit of Measure Code", UnitofMeasureCode);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure PostPurchaseReceiptWithItemTracking(Item: Record Item; ItemUnitOfeasure: Record "Item Unit of Measure"; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        LotNo: Code[50];
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Quantity, LocationCode, WorkDate());
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfeasure.Code);
        PurchaseLine.Modify(true);

        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader);
        FindWarehouseReceiptNo(
          WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(WarehouseReceiptLine."Qty. (Base)");
        WarehouseReceiptLine.OpenItemTrackingLines(); // Use handler to assign lot no.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndPostWhseShipmentFromSO(var SalesHeader: Record "Sales Header"; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(FindWhseShipmentNo(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No."));
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentHeader."No.");
        FindWhseActivityLine(
            WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SalesHeader."No.",
            WarehouseActivityLine."Action Type"::Take);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
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

    local procedure CreateFiscalYearAndInventoryPeriod() PostingDate: Date
    var
        InventoryPeriod: Record "Inventory Period";
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.DeleteAll();

        LibraryFiscalYear.CreateFiscalYear();
        PostingDate := LibraryFiscalYear.GetLastPostingDate(false);
        LibraryInventory.CreateInventoryPeriod(InventoryPeriod, PostingDate);
    end;

    local procedure CreateAndPostWhseReceiptFromPO(PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        BinCode: Code[20];
    begin
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        BinCode := WarehouseReceiptLine."Bin Code";
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        exit(BinCode);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPostOneHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal."Item No.".SetValue(LibraryVariableStorage.DequeueText());
        ProductionJournal.Quantity.SetValue(1);
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPostHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal."Item No.".SetValue(LibraryVariableStorage.DequeueText());
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectEntriesHandler(var ItemTrackingSummaryPage: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummaryPage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, PostJournalLines) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler2(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ChangeLocationConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, WantToContinueMessage) > 0, ConfirmMessage);
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        QtyToHandleBase: Decimal;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            TrackingAction::SerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            TrackingAction::LotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            TrackingAction::AssignLotNo:
                begin
                    ItemTrackingLines.First();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            TrackingAction::UpdateAndAssignNew:
                begin
                    ItemTrackingLines.First();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines.Next();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            TrackingAction::CheckQtyToHandleBase:
                begin
                    ItemTrackingLines.Filter.SetFilter("Lot No.", LibraryVariableStorage.DequeueText());
                    QtyToHandleBase := LibraryVariableStorage.DequeueDecimal();
                    Assert.AreEqual(
                        QtyToHandleBase,
                        ItemTrackingLines."Qty. to Handle (Base)".AsDecimal(),
                        StrSubstNo(
                            QtyToHandleErr,
                            ItemTrackingLines."Qty. to Handle (Base)".Caption(),
                            QtyToHandleBase,
                            ItemTrackingLines.Caption()));
                end;
            TrackingAction::AssignPackageNo:
                begin
                    ItemTrackingLines.First();
                    ItemTrackingLines."Package No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PickActivitiesMessageHandler(Message: Text[1024])
    begin
        Counter += 1;
        case Counter of
            1:
                Assert.IsTrue(StrPos(Message, LinesPosted) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, PickActivitiesCreated) > 0, Message);
            3:
                Assert.IsTrue(StrPos(Message, NothingToCreate) > 0, Message);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ShipmentMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, LinesPosted) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ShipmentWithProductionOrderMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, ReleasedProdOrderCreated) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PutAwayMessageHandler(Message: Text[1024])
    begin
        Counter += 1;
        case Counter of
            1:
                Assert.IsTrue(StrPos(Message, PutAwayCreated) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, NothingToCreate) > 0, Message);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PutAwayWithPickActivitiesMessageHandler(Message: Text[1024])
    begin
        Counter += 1;
        case Counter of
            1:
                Assert.IsTrue(StrPos(Message, PutAwayCreated) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, PickActivitiesCreated) > 0, Message);
            3:
                Assert.IsTrue(StrPos(Message, NothingToCreate) > 0, Message);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ReceiptWithPickActivitiesMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, PickActivitiesCreated) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PutAwayWithPickActivitiesTwiceMessageHandler(Message: Text[1024])
    begin
        Counter += 1;
        case Counter of
            1:
                Assert.IsTrue(StrPos(Message, PutAwayCreated) > 0, Message);
            2, 3:
                Assert.IsTrue(StrPos(Message, PickActivitiesCreated) > 0, Message);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SourceDocumentsPageHandler(var SourceDocuments: Page "Source Documents"; var Response: Action)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Location Code", LocationSilver.Code);
        WarehouseRequest.SetRange("Source No.", SourceNo);
        WarehouseRequest.FindFirst();
        SourceDocuments.SetRecord(WarehouseRequest);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionPageHandler(var PickSelection: Page "Pick Selection"; var Response: Action)
    var
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        WhsePickRequest.SetRange("Location Code", LocationCode);
        WhsePickRequest.SetRange("Document No.", WarehouseShipmentNo);
        WhsePickRequest.FindFirst();
        PickSelection.SetRecord(WhsePickRequest);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemtrackingLines: TestPage "Item Tracking Lines")
    var
        Handler: Variant;
        QtyToHandleBase: Variant;
        Handler2: Boolean;
    begin
        LibraryVariableStorage.Dequeue(Handler);
        Handler2 := Handler;  // Assign Variant to Boolean variable.
        if Handler2 then
            ItemtrackingLines."Assign Lot No.".Invoke()
        else begin
            ItemtrackingLines."Select Entries".Invoke();
            LibraryVariableStorage.Dequeue(QtyToHandleBase);
            ItemtrackingLines."Qty. to Handle (Base)".SetValue(QtyToHandleBase);
            ItemtrackingLines.OK().Invoke();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesMultipleModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        Index: Integer;
    begin
        for Index := 1 to LibraryVariableStorage.DequeueInteger() do begin
            WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
            WhseItemTrackingLines.New();
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesMultiplePackageModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        Index: Integer;
    begin
        for Index := 1 to LibraryVariableStorage.DequeueInteger() do begin
            WhseItemTrackingLines."Package No.".SetValue(LibraryVariableStorage.DequeueText());
            WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
            WhseItemTrackingLines.New();
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseShipmentCreatePickPageRequestHandler(var WhseShipmentCreatePick: TestRequestPage "Whse.-Shipment - Create Pick")
    begin
        WhseShipmentCreatePick.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WarehouseShipmentCreatePickRequestPageHandler(var WhseShipmentCreatePick: TestRequestPage "Whse.-Shipment - Create Pick")
    begin
        WhseShipmentCreatePick.DoNotFillQtytoHandle.SetValue(true);
        WhseShipmentCreatePick.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler2(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        I: Integer;
    begin
        for I := 1 to LibraryVariableStorage.DequeueInteger() do begin
            ItemTrackingLines.New();
            ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueInteger());
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PickNotCreatedMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, NothingToCreate) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PickCreatedMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, PickActivitiesCreated) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerGetText(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SourceDocumentsGetSourceNoPageHandler(var SourceDocuments: TestPage "Source Documents")
    begin
        LibraryVariableStorage.Enqueue(SourceDocuments."Source No.".Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailQtyReservationPageHandler(var Reservation: TestPage Reservation)
    var
        "Integer": Integer;
    begin
        Reservation.First();

        if not Evaluate(Integer, Reservation.QtyAllocatedInWarehouse.Value) then
            Integer := 0;
        LibraryVariableStorage.Enqueue(Integer);

        if not Evaluate(Integer, Reservation.TotalAvailableQuantity.Value) then
            Integer := 0;
        LibraryVariableStorage.Enqueue(Integer);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", LibraryVariableStorage.DequeueText());
        ItemJournalLine.FindSet();
        repeat
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
        until ItemJournalLine.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingAssignLotNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        TrackingAction := DequeueVariable;
        case TrackingAction of
            TrackingAction::LotNo:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Expiration Date".SetValue(LibraryVariableStorage.DequeueDate());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        Index: Integer;
        Qty: Integer;
    begin
        Qty := LibraryRandom.RandIntInRange(400, 400);
        for Index := 1 to 5 do begin
            WhseItemTrackingLines."Lot No.".SetValue(Format(Qty));
            WhseItemTrackingLines.Quantity.SetValue(Format(Qty));
            Qty -= LibraryRandom.RandIntInRange(50, 50);
            WhseItemTrackingLines.Next();
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure WhseCalculateInventoryIncludeItemWithoutTransactionHandler(var WhseCalculateInventory: TestRequestPage "Whse. Calculate Inventory")
    begin
        WhseCalculateInventory."Bin Content".SetFilter("Location Code", LibraryVariableStorage.DequeueText());
        WhseCalculateInventory."Bin Content".SetFilter("Bin Code", LibraryVariableStorage.DequeueText());
        WhseCalculateInventory.OK().Invoke();
    end;
}

