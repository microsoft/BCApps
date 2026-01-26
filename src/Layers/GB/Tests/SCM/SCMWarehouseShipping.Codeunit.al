codeunit 137151 "SCM Warehouse - Shipping"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalTemplate2: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalBatch2: Record "Item Journal Batch";
        ItemJournalBatch3: Record "Item Journal Batch";
        LocationWhite: Record Location;
        LocationWhite2: Record Location;
        LocationWhite3: Record Location;
        LocationGreen: Record Location;
        LocationGreen2: Record Location;
        LocationOrange: Record Location;
        LocationOrange2: Record Location;
        LocationOrange3: Record Location;
        LocationSilver: Record Location;
        LocationSilver2: Record Location;
        LocationSilver3: Record Location;
        LocationRed: Record Location;
        LocationBlue: Record Location;
        LocationInTransit: Record Location;
        LocationWithRequirePick: Record Location;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        UoMMgt: Codeunit "Unit of Measure Management";
        ErrorQtyToHandleTxt: Label 'Qty. to Ship must not be greater than 0 units in Warehouse Shipment Line No.=''%1''', Comment = 'Line No';
        TrackingActionMsg: Label 'The change will not affect existing entries.';
        NothingToRegisterErr: Label 'There is nothing to register.';
        ShippingAdviceErr: Label 'If Shipping Advice is Complete in Sales Order no. %1, then all associated lines where type is Item must use the same location.', Comment = 'Sales Order No.';
        LibraryDimension: Codeunit "Library - Dimension";
        isInitialized: Boolean;
        ItemTrackingMode: Option "Assign Lot No.","Assign Serial No.","Select Entries",VerifyTracking,"Split Lot No.",AssitEditLotNo,"Assign Multiple Lines","Set Lot No.";
        SerialNoErr: Label 'Serial No does not exist.';
        NumberOfLineEqualErr: Label 'Number of Lines must be same.';
        ChangeShipingAdviceMsg: Label 'Do you want to change %1 in all related records in warehouse accordingly', Comment = 'Shipping Advice';
        InvPutAwayMsg: Label 'Number of Invt. Put-away activities created';
        InvPickMsg: Label 'Number of Invt. Pick activities created';
        QuantityMustNotBeEqualErr: Label 'Quantity must not be Equal';
        QuantityMustBeEqualErr: Label 'Quantities must be Equal';
        TransferOrderDeletedMsg: Label 'Transfer order %1 was successfully posted and is now deleted.', Comment = 'Order No.';
        RegisterPickConfirmMsg: Label 'Do you want to register the';
        PickActivityCreatedMsg: Label 'Pick activity no. ';
        PutAwayActivityCreatedMsg: Label 'Put-away activity no.';
        NothingToHandleErr: Label 'Nothing to handle.';
        UnexpectedErr: Label 'UnexpectedErr.';
        UndoShipmentConfirmMsg: Label 'Do you really want to undo the selected Shipment lines?';
        UndoPickedShipmentConfirmMsg: Label 'The items have been picked';
        ItemInventoryInErr: Label 'Item %1 is not in inventory', Comment = 'Item No. is not in inventory';
        CompleteShipmentErr: Label 'This document cannot be shipped completely. Change the value in the Shipping Advice field to Partial.';
        QuantityErr: Label 'The value of Quantity field  is not correct.';
        RequsitionLineShouldCreatedErr: Label 'Requisition Line cannot be found.';
        LotNoTxt: Label 'LOT_NO_%1', Comment = 'LOT NO';
        ReservEntryNotExistErr: Label 'There is no Reservation Entry within the filters';
        UndoSalesShipmentErr: Label 'Shipment Line with zero Quantity should not be considered for Undo Shipemnt';
        WhsShpmtHeaderExternalDocumentNoIsWrongErr: Label 'Warehouse Shipment Header."External Document No." is wrong.';
        WhsRcptHeaderVendorShpmntNoIsWrongErr: Label 'Warehouse Receipt Header."Vendor Shipment No." is wrong.';
        AvailWarningMsg: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        WrongQtyToHandleInTrackingSpecErr: Label 'Qty. to Handle (Base) in the item tracking assigned to the document line for item %1 is currently %2. It must be %3.\\Check the assignment for serial number %4, lot number %5, package number %6.', Comment = '%1: Field(Item No.), %2: Field(Qty. to Handle (Base)), %3: expected quantity, %4: Field(Serial No.), %5: Field(Lot No.), %6: Field(Package No.)';
        PostedInvoicesQtyErr: Label 'There must be 2 Sales Invoices.';
        PostedShpmtsQtyErr: Label 'There must be 2 Sales Shipments.';
        ChangedBinCodeOnWhseShptTxt: Label 'You have changed Bin Code on the Warehouse Shipment Header';
        SingleWarehouseShipmentCreatedMsg: Label '%1 %2 has been created.';
        MultipleWarehouseShipmentsCreatedMsg: Label '%1 warehouse shipments have been created.';
        SingleWarehouseReceiptCreatedMsg: Label '%1 %2 has been created.';
        MultipleWarehouseReceiptsCreatedMsg: Label '%1 warehouse receipts have been created.';
        WhseShipmentIsRequiredErr: Label 'Warehouse Shipment is required for Line No.';
        OutstandingQtyErr: Label 'Qty. Outstanding (Base) should be greater than zero';

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanForComponentAfterStockPickedFromProdOrderWithTracking()
    var
        ComponentItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item with Item Tracking. Update Inventory using Warehouse Journal.
        // Create and Register Pick from released Production Order. Assign Lot No. for the component line.
        // Create Sales Order for Component Item.
        Initialize();
        RegisterPickFromProdOrderWithLotNo(ComponentItem);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LocationWhite.Code, ComponentItem."No.", LibraryRandom.RandInt(10));

        // Exercise: Run calculate Net Change plan for ComponentItem.
        LibraryPlanning.CalcNetChangePlanForPlanWksh(ComponentItem, WorkDate(), WorkDate(), false);

        // Verify: Verify a Requsition line of Quantity = SalesLine.Quantity is suggested for the sales order.
        VerifyRequsitionLine(ComponentItem."No.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreateHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipmentPostErrorWithBlankQuantityToHandleAndSerialNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and register Put Away with Item tracking and post the Receipt. Create Pick from Sales Order. Delete Quantity to Handle on Activity Line.
        Initialize();
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '', false);  // Taking Serial No. as True. Taking Blank value for Lot Nos. on Item card.
        LibraryVariableStorage.Enqueue(TrackingActionMsg);  // Enqueue for MessageHandler.
        ModifyOrderTrackingPolicyInItem(Item);
        Quantity := LibraryRandom.RandInt(10);  // Taking Random Quantity.
        CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(
          PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, true, ItemTrackingMode::"Assign Serial No.", false);  // Taking ItemTracking as True.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        CreatePickFromSalesOrder(SalesHeader, LocationWhite.Code, Item."No.", Quantity, true);  // Taking ItemTracking as True.
        DeleteQuantityToHandleOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityHeader.Type::Pick);

        // Exercise: Register Warehouse Pick and catch the error.
        asserterror RegisterWarehouseActivity(
            WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick);

        // Verify: Error message.
        Assert.ExpectedError(StrSubstNo(NothingToRegisterErr));

        // Exercise and Verify: Open Item Tracking lines from Warehouse Shipment Line. Verify Serial No. is assigned on Item Tracking Lines.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::VerifyTracking);  // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue Quantity for Handler.
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentLine.OpenItemTrackingLines();  // Verify Item Tracking lines on ItemTrackingPageHandler.

        // Exercise: Enter Quantity to Ship in Shipment Line and catch the error.
        asserterror WarehouseShipmentLine.Validate("Qty. to Ship", 1);  // Value required for the test.

        // Verify: Error message.
        Assert.ExpectedError(StrSubstNo(ErrorQtyToHandleTxt, WarehouseShipmentLine."No."));

        // Exercise: Post Warehouse Shipment and catch the error.
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // Verify: Error message on posting Warehouse Shipment without registering Pick.
        Assert.ExpectedError(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSourceDocumentsOnWarehouseReceipt()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 302715] Quantity to Receive is filled for Warehouse Receipt lines in case "Do Not Fill Qty. to Handle" is not set on "Filters to Get Source Docs" report.
        Initialize();

        // [GIVEN] Sales Return Order, Purchase Order, Posted Transfer Order with the same Location code "White".
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDecInRange(10, 20, 2);
        CreateAndReleaseSalesReturnOrder(SalesHeader, Item."No.", Quantity);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", Quantity);

        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationOrange.Code, '', false);
        CreateAndReleaseTransferOrder(TransferHeader, LocationOrange.Code, LocationWhite.Code, Item."No.", Quantity, false);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [WHEN] Create Warehouse Receipt Header and get source documents.
        GetSourceDocumentOnWarehouseReceipt(WarehouseReceiptHeader, LocationWhite.Code, false);

        // [THEN] Warehouse Receipt Line created for the Sales Return Order, Purchase Order, Transfer Order.
        // [THEN] "Qty. to Receive" is filled for Warehouse Receipt Lines.
        VerifyWarehouseReceiptLine(
          WarehouseReceiptLine."Source Document"::"Sales Return Order", SalesHeader."No.", Item."No.", Quantity, Quantity);
        VerifyWarehouseReceiptLine(
          WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Item."No.", Quantity, Quantity);
        VerifyWarehouseReceiptLine(
          WarehouseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.", Item."No.", Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentErrorWithShippingAdviceCompleteWithTwoLocations()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and release Sales Order with two Sales Lines for different locations with Shipping Advice Complete.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        LibraryVariableStorage.Enqueue(ChangeShipingAdviceMsg);  // Enqueue for ConfirmHandler.
        CreateAndReleaseSalesOrderWithMultipleLinesUsingShippingAdvice(
          SalesHeader, SalesHeader."Shipping Advice"::Complete, Item."No.", Item."No.", Quantity, Quantity, LocationGreen.Code,
          LocationGreen2.Code, true);  // Taking True for Multiple Lines.

        // Exercise: Invoke Create Warehouse Shipment from Sales Order and catch error.
        asserterror LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Error message.
        Assert.ExpectedError(StrSubstNo(ShippingAdviceErr, SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWarehouseShipmentWithShippingAdvicePartialOnTwoLocations()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and release Sales Order with two Sales Lines for different locations with Shipping Advice Partial.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random quantity.
        CreateAndReleaseSalesOrderWithMultipleLinesUsingShippingAdvice(
          SalesHeader, SalesHeader."Shipping Advice"::Partial, Item."No.", Item."No.", Quantity, Quantity, LocationGreen.Code,
          LocationGreen2.Code, true);  // Taking True for Multiple Lines.

        // Exercise.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Warehouse Shipment lines for both locations.
        VerifyWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationGreen.Code, Item."No.", Quantity);
        VerifyWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationGreen2.Code, Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickWithDifferentSalesUnitOfMeasure()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with different Sales Unit of Measure. Create and register Put Away and post the Receipt.
        Initialize();
        CreateItemWithDifferentSalesUnitOfMeasure(Item, ItemUnitOfMeasure);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random quantity.
        CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(
          PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, false, ItemTrackingMode::"Assign Lot No.", false);

        // Exercise.
        CreatePickFromSalesOrder(SalesHeader, LocationWhite.Code, Item."No.", Quantity, false);

        // Verify: Warehouse Activity lines.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);
        VerifyWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."Action Type"::Place, Item."No.",
          Round(Quantity / ItemUnitOfMeasure."Qty. per Unit of Measure", 0.00001));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostShipmentWithDifferentSalesUnitOfMeasure()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
        SalesQuantity: Decimal;
    begin
        // Setup: Create Item with different Sales Unit of Measure. Create and register Put Away and post the Receipt. Create and register the Pick.
        Initialize();
        CreateItemWithDifferentSalesUnitOfMeasure(Item, ItemUnitOfMeasure);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random quantity.
        CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(
          PurchaseHeader, LocationWhite2.Code, Item."No.", Quantity, false, ItemTrackingMode::"Assign Lot No.", false);
        SalesQuantity := Quantity + LibraryRandom.RandDec(10, 2);  // Adding Random quantity.
        CreatePickFromSalesOrder(SalesHeader, LocationWhite2.Code, Item."No.", SalesQuantity, false);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick);

        // Exercise.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Verify: Values on Item Card.
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 0);  // Value required for the test.
        Item.CalcFields("Qty. on Sales Order");
        Item.TestField("Qty. on Sales Order", (SalesQuantity * ItemUnitOfMeasure."Qty. per Unit of Measure") - Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderAfterWarehousePutAwayRegisterWithLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create Item with Item Tracking Code. Create and register Put Away from Purchase Order and post Receipt.
        Initialize();
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(
          PurchaseHeader, LocationGreen.Code, Item."No.", Quantity, true, ItemTrackingMode::"Assign Lot No.", false);  // Taking ItemTracking as True.

        // Exercise: Post the Purchase Order as Receive and Invoice.
        PostPurchaseDocument(PurchaseHeader, DocumentNo);

        // Verify: Posted Purchase Invoice.
        VerifyPostedPurchaseInvoice(DocumentNo, Item."No.", LocationGreen.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderAfterWarehousePickRegisterWithLotNo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Variant: Variant;
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create Item with Item Tracking Code. Create and register Put Away from Purchase Order and post Receipt. Create and register Pick from Sales Order and post Shipment.
        Initialize();
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(
          PurchaseHeader, LocationGreen.Code, Item."No.", Quantity, true, ItemTrackingMode::"Assign Lot No.", false);  // Taking ItemTracking as True.
        LibraryVariableStorage.Dequeue(Variant);  // Dequeue LotNo for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        CreatePickFromSalesOrder(SalesHeader, LocationGreen.Code, Item."No.", Quantity, true);  // Taking ItemTracking as True.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick);
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Exercise: Post the Sales Order as Ship and Invoice.
        PostSalesDocument(SalesHeader, DocumentNo);

        // Verify: Posted Sales Invoice.
        VerifyPostedSalesInvoice(DocumentNo, Item."No.", LocationGreen.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('EnterQuantityToCreateHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderAfterWarehousePutAwayRegisterWithSerialNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create Item with Item Tracking Code. Create and register Put Away from Purchase Order and post Receipt.
        Initialize();
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '', false);  // Taking Serial No. as True. Taking Blank value for Lot Nos. on Item card.
        Quantity := LibraryRandom.RandInt(10);  // Taking Random Quantity.
        CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(
          PurchaseHeader, LocationGreen.Code, Item."No.", Quantity, true, ItemTrackingMode::"Assign Serial No.", false);  // Taking Item Tracking as True.

        // Exercise: Post the Purchase Order as Receive and Invoice.
        PostPurchaseDocument(PurchaseHeader, DocumentNo);

        // Verify: Posted Purchase Invoice.
        VerifyPostedPurchaseInvoice(DocumentNo, Item."No.", LocationGreen.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreateHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderAfterWarehousePickRegisterWithSerialNo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create Item with Item Tracking Code. Create and register Put Away from Purchase Order and post Receipt. Create and register Pick from Sales Order and post Shipment.
        Initialize();
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '', false);  // Taking Serial No. as True. Taking Blank value for Lot Nos. on Item card.
        Quantity := LibraryRandom.RandInt(10);  // Taking Random Quantity.
        CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(
          PurchaseHeader, LocationGreen.Code, Item."No.", Quantity, true, ItemTrackingMode::"Assign Serial No.", false);  // Taking Item Tracking as True.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        CreatePickFromSalesOrder(SalesHeader, LocationGreen.Code, Item."No.", Quantity, true);  // Taking ItemTracking as True.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick);
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Exercise: Post the Sales Order as Ship and Invoice.
        PostSalesDocument(SalesHeader, DocumentNo);

        // Verify: Posted Sales Invoice.
        VerifyPostedSalesInvoice(DocumentNo, Item."No.", LocationGreen.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayAndPickFromSalesOrderWithMultipleItems()
    var
        Item: Record Item;
        Item2: Record Item;
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Items and update Item Inventory from Item Journal. Create and release Sales Order with multiple lines. Create Inventory Put-Away and Pick.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        Quantity := -LibraryRandom.RandDec(10, 2);  // Taking Random value for Quantity.
        Quantity2 := LibraryRandom.RandDec(10, 2);  // Taking Random value for Quantity.
        CreateAndPostItemJournalLine(Item2."No.", Quantity2, LocationOrange.Code, '', false);  // Taking Blank for Bin Code and false for Item Tracking.
        CreateAndReleaseSalesOrderWithMultipleLinesUsingShippingAdvice(
          SalesHeader, SalesHeader."Shipping Advice"::Complete, Item."No.", Item2."No.", Quantity, Quantity2, LocationOrange.Code,
          LocationOrange.Code, true);  // Taking True for Multiple Lines.
        LibraryVariableStorage.Enqueue(InvPutAwayMsg);  // Enqueue for MessageHandler.
        LibraryVariableStorage.Enqueue(InvPickMsg);  // Enqueue for MessageHandler.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", true, true);  // Taking True for Put Away and Pick.
        AutoFillQtyToHandleOnWhseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order",
          SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        AutoFillQtyToHandleOnWhseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order",
          SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");

        // Exercise: Post Inventory Put-Away and Inventory Pick.
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");

        // Verify: Posted Inventory Put-Away and Inventory Pick line.
        VerifyPostedInventoryPutLine(
          PostedInvtPutAwayLine."Source Document"::"Sales Order", SalesHeader."No.", LocationOrange.Code, Item."No.", -Quantity);
        VerifyPostedInventoryPickLine(
          PostedInvtPickLine."Source Document"::"Sales Order", SalesHeader."No.", LocationOrange.Code, Item2."No.", Quantity2, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromSalesOrderWithItemReserveBeforePurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Reserve. Create and post Purchase Order. Create and release Sales Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateReserveOnItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random value for Quantity.
        CreatePurchaseOrder(PurchaseHeader, LocationOrange.Code, Item."No.", Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Receive as TRUE.
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationOrange.Code, '', Item."No.", Item."No.", Quantity, 0, false, false);  // Taking O for blank Quantity of second line.
        LibraryVariableStorage.Enqueue(InvPickMsg);  // Enqueue for MessageHandler.

        // Exercise: Create Inventory Pick from Sales Order.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", false, true);  // Taking True for Pick.

        // Verify: Inventory Pick Line.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Action Type"::" ", Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromSalesWithItemReserveAfterItemJournal()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and Post Item Journal line. Update Reserve as Always on Item. Create and release Sales Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random value for Quantity.
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationOrange.Code, '', false);  // Taking Blank for Bin Code and false for Item Tracking.
        UpdateReserveOnItem(Item);
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationOrange.Code, '', Item."No.", Item."No.", Quantity, 0, false, false);  // Taking O for blank Quantity of second line.

        // Exercise and Verify: Calculate value for Reserved Quantity and verify that it is not equal to Sales Line Quantity.
        SalesLine.CalcFields("Reserved Quantity");
        Assert.AreNotEqual(SalesLine.Quantity, SalesLine."Reserved Quantity", QuantityMustNotBeEqualErr);
        LibraryVariableStorage.Enqueue(InvPickMsg);  // Enqueue for MessageHandler.

        // Exercise: Create Inventory Pick from Sales Order.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", false, true);  // Taking True for Pick.

        // Verify: Inventory Pick Line.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Action Type"::" ", Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromSalesOrderWithBin()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and post Item Journal line with Bin Code. Create and release Sales Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        FindBin(Bin, LocationSilver.Code);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationSilver.Code, Bin.Code, false);
        CreateAndReleaseSalesOrderWithMultipleLinesUsingShippingAdvice(
          SalesHeader, SalesHeader."Shipping Advice"::Complete, Item."No.", '', Quantity, 0, LocationSilver.Code, LocationSilver.Code, false);  // Taking False for Multiple Lines. Taking 0 for Quantity of blank line. Taking Blank for 2nd Item.
        LibraryVariableStorage.Enqueue(InvPickMsg);  // Enqueue for MessageHandler.

        // Exercise: Create Inventory Pick from Sales Order.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", false, true);  // Taking True for Pick.

        // Verify: Verify Warehouse Activity line.
        VerifyWarehouseActivityLineWithBin(SalesHeader."No.", Item."No.", Quantity, LocationSilver.Code, Bin.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromTransferOrder()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and post Item Journal line. Create and release Transfer Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationOrange.Code, '', false);  // Taking Blank for Bin Code.
        CreateAndReleaseTransferOrder(TransferHeader, LocationOrange.Code, LocationOrange2.Code, Item."No.", Quantity, false);

        // Exercise: Create and Post Inventory Pick from Transfer Order.
        CreateAndPostInvPickFromTransferOrder(TransferHeader."No.");

        // Verify: Posted Inventory Pick Line.
        VerifyPostedInventoryPickLineForTransferOrder(TransferHeader."No.", Item."No.", Quantity, LocationOrange.Code, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayFromTransferOrder()
    var
        Item: Record Item;
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        TransferHeader: Record "Transfer Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and post Item Journal line. Create and release Transfer Order. Create and Post Inventory Pick from Transfer Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationOrange.Code, '', false);  // Taking Blank for Bin Code.
        CreateAndReleaseTransferOrder(TransferHeader, LocationOrange.Code, LocationOrange2.Code, Item."No.", Quantity, false);
        CreateAndPostInvPickFromTransferOrder(TransferHeader."No.");

        // Exercise: Create and Post Inventory Put Away from Transfer Order.
        CreateAndPostInvPutAwayFromTransferOrder(TransferHeader."No.");

        // Verify: Posted Inventory Put Away Line.
        VerifyPostedInventoryPutLine(
          PostedInvtPutAwayLine."Source Document"::"Inbound Transfer", TransferHeader."No.", LocationOrange2.Code, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromTransferOrderWithLotNo()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        LotNo: Variant;
        Quantity: Decimal;
    begin
        // Setup: Create Item with Item Tracking code. Create and post Item Journal line. Create and release Transfer Order with Lot No.
        Initialize();
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationOrange.Code, '', true);  // Taking Item Tracking as True and Blank for Bin Code.
        LibraryVariableStorage.Dequeue(LotNo);  // Dequeue LotNo for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        CreateAndReleaseTransferOrder(TransferHeader, LocationOrange.Code, LocationOrange2.Code, Item."No.", Quantity, true);  // Taking Item Tracking as True.

        // Exercise: Create and Post Inventory Pick from Transfer Order.
        CreateAndPostInvPickFromTransferOrder(TransferHeader."No.");

        // Verify: Posted Inventory Pick Line.
        VerifyPostedInventoryPickLineForTransferOrder(TransferHeader."No.", Item."No.", Quantity, LocationOrange.Code, LotNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPutAwayAndPickFromSalesOrderWithMultipleItemsPartialShipment()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Items and update Item Inventory from Item Journal. Create and release Sales Order with multiple lines and partial shipment and Shipping Advice is Complete.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        Quantity := -LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        Quantity2 := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipping Advice", SalesHeader."Shipping Advice"::Complete);
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item2."No.", Quantity2);
        SalesLine.Validate("Qty. to Ship", Round(Quantity2 * 0.5));
        SalesLine.Modify();

        // post anf verify there is a error
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Nothing to handle Error.
        Assert.AreEqual(StrSubstNo(CompleteShipmentErr), GetLastErrorText, UnexpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromSalesOrderWithMultipleLocations()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Create and release Sales Order with two lines for different Locations.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random value for Quantity.
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationRed.Code, LocationBlue.Code, Item."No.", Item2."No.", Quantity, Quantity, true, false);

        // Exercise: Create Warehouse Shipment from Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Warehouse Shipment Line.
        VerifyWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationRed.Code, Item."No.", Quantity);
        VerifyWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationBlue.Code, Item2."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WarehouseShipmentCardPageHandler')]
    procedure OpeningWarehouseShipmentCardFromSalesOrderWithSingleLocation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseShptHeader: Record "Warehouse Shipment Header";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Create and release Sales Order with single line.
        Initialize();
        LibraryVariableStorage.Enqueue(StrSubstNo(SingleWarehouseShipmentCreatedMsg, 1, WhseShptHeader.TableCaption()));  // Enqueue for MessageHandler.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random value for Quantity.
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationRed.Code, '', Item."No.", '', Quantity, 0, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, false);

        // Exercise: Create Warehouse Shipment from Sales Order with dialog
        GetSourceDocOutbound.CreateFromSalesOrder(SalesHeader);

        // Verify: Warehouse Shipment Card has been displayed
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WarehouseShipmentListPageHandler')]
    procedure OpeningWarehouseShipmentListFromSalesOrderWithMultipleLocations()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseEmployee: Record "Warehouse Employee";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Create and release Sales Order with two lines for different Locations.
        Initialize();
        LibraryVariableStorage.Enqueue(StrSubstNo(MultipleWarehouseShipmentsCreatedMsg, 2));  // Enqueue for MessageHandler.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random value for Quantity.
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationRed.Code, LocationBlue.Code, Item."No.", Item2."No.", Quantity, Quantity, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationBlue.Code, false);

        // Exercise: Create Warehouse Shipment from Sales Order with dialog
        GetSourceDocOutbound.CreateFromSalesOrder(SalesHeader);

        // Verify: Warehouse Shipment List has been displayed
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromSalesOrderWithNewSalesLine()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Create and release Sales Order with multiple lines. Create Warehouse Shipment from Sales Order. Reopen Sales Order and create a new Sales Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random value for Quantity.
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationRed.Code, LocationBlue.Code, Item."No.", Item2."No.", Quantity, Quantity, true, false);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        AddNewLineInSalesOrder(SalesHeader, LocationBlue.Code, Item3."No.", Quantity);

        // Exercise: Create Warehouse Shipment for new Sales line.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Warehouse Shipment Line.
        VerifyWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationBlue.Code, Item3."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSourceDocumentsOnWarehouseShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and release Sales Return Order. Create Warehouse Shipment Header with Location.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := -LibraryRandom.RandDec(10, 2);  // Taking Random Quantity. Negative value required for test.
        CreateAndReleaseSalesReturnOrder(SalesHeader, Item."No.", Quantity);
        CreateWarehouseShipmentHeaderWithLocation(WarehouseShipmentHeader, LocationWhite.Code);

        // Exercise: Get source document on Warehouse Shipment.
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, LocationWhite.Code);

        // Verify: Quantity does not match on Warehouse Shipment Line with Sales Line Quantity.
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Return Order", SalesHeader."No.");
        Assert.AreNotEqual(Quantity, WarehouseShipmentLine.Quantity, QuantityMustNotBeEqualErr);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure GetSourceDocumentsOnWarehouseShipmentWithItemTracking()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Item Tracking. Update Inventory using Warehouse Journal. Create and release Sales Order. Create Warehouse Shipment for the Sales Order.
        Initialize();
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '', false);  // Taking Serial No. as True. Taking Blank value for Lot Nos. on Item card.
        Quantity := LibraryRandom.RandInt(10);  // Taking Random Quantity.
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true);  // Find PICK Bin.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Serial No.");  // Enqueue ItemTrackingMode for WhseItemTrackingLinesHandler.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '', Item."Base Unit of Measure", true);  // Taking True for Item Tracking.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationWhite.Code, '', Item."No.", '', Quantity, 0, false, true);  // Taking True for Item Tracking. Taking O for Quantity of blank line.
        GetSourceDocumentOnWarehouseShipment(WarehouseShipmentHeader, LocationWhite.Code, false);

        // Exercise: Create Pick from the Warehouse Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Serial No. and Quantity on the Warehouse Pick Lines.
        VerifySerialNoOnWarehouseActivityLine(SalesHeader."No.", WarehouseActivityLine."Action Type"::Take);
        VerifySerialNoOnWarehouseActivityLine(SalesHeader."No.", WarehouseActivityLine."Action Type"::Place);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateConsumptionAfterPickFromReleasedProductionOrder()
    var
        Bin: Record Bin;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Setup: Create Item with BOM. Create Released Production Order. Create Requisition Line and Carry Out Action Message Plan.
        // Create Put Away from created Purchase Order. Create and Register Pick from Production Order.
        Initialize();
        CreateItemWithProductionBOM(ParentItem, ComponentItem, ParentItem."Replenishment System"::Purchase);
        Quantity := LibraryRandom.RandInt(10);  // Taking Random quantity.
        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", Quantity, LocationWhite.Code, '');
        CreateRequisitionLineAndCarryOutActionMessagePlan(ParentItem."No.", LocationWhite.Code, Quantity);
        RegisterPutAwayFromPurchaseOrder(ParentItem."No.");
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true);  // Find PICK Bin.
        UpdateInventoryUsingWhseJournal(Bin, ComponentItem, Quantity, '', ParentItem."Base Unit of Measure", false);
        CreateAndRegisterPickFromProductionOrder(ProductionOrder, Bin);

        // Exercise: Calculate Consumption and Post the Item Journal line.
        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ItemJournalBatch2."Journal Template Name", ItemJournalBatch2.Name);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch2."Journal Template Name", ItemJournalBatch2.Name);

        // Verify: Item Ledger entry for the Consumption entry.
        VerifyItemLedgerEntry(ComponentItem."No.", ItemLedgerEntry."Entry Type"::Consumption, -Quantity, '');
    end;

    [Test]
    [HandlerFunctions('OrderPromisingHandler')]
    [Scope('OnPrem')]
    procedure ReservationWithoutItemTrackingUsingPlanningWorksheet()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Setup: Create Item. Create Sales Order and invoke Capable-to-Promise to reserve. Carry out Action Message Plan on Planning Worksheet. Create Put Away from newly created Purchase Order.
        // Create Shipment and Get Source Document for the Sales Order. Create and Register the Pick from the Shipment.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', LocationWhite2.Code, Item."No.",
          LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        OpenOrderPromisingPage(SalesHeader."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        ModifyRequisitionLineAndCarryOutActionMessagePlan(Item."No.");
        RegisterPutAwayFromPurchaseOrder(Item."No.");
        GetSourceDocumentOnWarehouseShipment(WarehouseShipmentHeader, LocationWhite2.Code, false);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Exercise: Post the Warehouse Shipment.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Verify: Posted Warehouse Shipment line.
        VerifyPostedWhseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationWhite2.Code,
          LocationWhite2."Shipment Bin Code", Item."No.", SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickWithTwoPutAwaysWithOneRegistered()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Item. Create two Put-Aways for the Item. Register only one Put-Away.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random quantity.
        Quantity2 := LibraryRandom.RandDec(10, 2);  // Taking Random quantity.
        CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(
          PurchaseHeader, LocationWhite2.Code, Item."No.", Quantity, false, ItemTrackingMode::"Assign Lot No.", false);
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader2, LocationWhite2.Code, Item."No.", Quantity2);
        PostWarehouseReceipt(PurchaseHeader2."No.");

        // Exercise: Create Pick for the Item against both Put-Aways.
        CreatePickFromSalesOrder(SalesHeader, LocationWhite2.Code, Item."No.", Quantity + Quantity2, false);

        // Verify: Quantity in the Pick Lines is equal to the Quantity of the Registered Put-Away.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);
        VerifyWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('WarehouseActivityLinesHandler,WarehousePickHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickFromSalesOrderByPage()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipment: TestPage "Warehouse Shipment";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Update Inventory using Warehouse Journal. Create Pick from Sales Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true);  // Find PICK Bin.
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '', Item."Base Unit of Measure", false);
        CreatePickFromSalesOrder(SalesHeader, LocationWhite.Code, Item."No.", Quantity, false);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        FindBinWithBinTypeCode(Bin2, LocationWhite.Code, true, false, false);  // Find SHIP Bin.

        // Exercise: Open Warehouse Activity Lines page from Warehouse Shipment. Open Warehouse Pick page from the Activity Lines page and Register the Pick.
        WarehouseShipment.OpenEdit();
        WarehouseShipment.FILTER.SetFilter("No.", WarehouseShipmentHeader."No.");
        WarehouseShipment."Pick Lines".Invoke();  // WarehouseActivityLinesHandler is called here which itself will call WarehousePickHandler.

        // Verify: Registered Warehouse Activity line.
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::Pick, RegisteredWhseActivityLine."Action Type"::Take, Item."No.", Quantity, Bin.Code);
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::Pick, RegisteredWhseActivityLine."Action Type"::Place, Item."No.", Quantity,
          Bin2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickFromSalesOrderWithBinCodeModifiedOnPutAwayLine()
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
        BinCode: Code[20];
    begin
        // Setup: Create Item. Create and Post Warehouse Receipt. Update Bin Code on Warehouse Receipt and Post it.
        // Change Bin Code on Place entry of Put Away and Register it. Create and Release Sales Order with Auto Reserve. Create Pick from Warehouse Shipment.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Value for Quantity.
        FindBin(Bin, LocationOrange3.Code);
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationOrange3.Code, Item."No.", Quantity);
        UpdateZoneAndBinCodeOnWarehouseReceiptLine(Bin, PurchaseHeader."No.");
        BinCode := Bin.Code;  // Value is required for verification.
        PostWarehouseReceipt(PurchaseHeader."No.");
        Bin.Next();
        ModifyBinOnWarehouseActivityLineAndRegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Bin.Code);
        CreatePickFromSalesOrder(SalesHeader, LocationOrange3.Code, Item."No.", Quantity, false);

        // Exercise: Register the Pick lines.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify: Registered Warehouse Activity Line.
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::Pick, RegisteredWhseActivityLine."Action Type"::Take, Item."No.", Quantity, Bin.Code);
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::Pick, RegisteredWhseActivityLine."Action Type"::Place, Item."No.", Quantity, BinCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePartialPickFromPickWorksheetWithMultipleLines()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Item. Post Item Journal line with Pick Bin. Create Sales Order with multiple lines. Create and Release Warehouse Shipment.
        // Get Source Document on Pick Worksheet. Delete Auto fill Quantity to Handle and set partial Quantity to Handle on first line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        ModifyDirectedPutAwayAndPickInLocationWhite(LocationWhite3);
        FindBinWithBinTypeCode(Bin, LocationWhite3.Code, false, true, true);  // Find PICK Bin.
        CreateAndPostItemJournalLine(Item."No.", Quantity + Quantity2, LocationWhite3.Code, Bin.Code, false);  // Adding both the Quantities for posting the Item Journal.
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationWhite3.Code, LocationWhite3.Code, Item."No.", Item."No.", Quantity, Quantity2, true, false);
        CreateAndReleaseWarehouseShipmentFromSalesOrder(SalesHeader);
        GetWarehouseDocumentOnWhseWorksheetLine(WhseWorksheetName, LocationWhite3.Code);
        UpdateQuantityToHandleOnWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationWhite3.Code, Item."No.", Quantity / 2);  // Update Partial Quantity.

        // Exercise.
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetName."Worksheet Template Name",
          WhseWorksheetName.Name, LocationWhite3.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);  // Taking 0 for MaxNoOfLines, MaxNoOfSourceDoc and SortPick.

        // Verify: Warehouse Activity Line.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromReleasedProductionOrderFromFirmPlannedProductionOrder()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        OldAlwaysCreatePickLine: Boolean;
    begin
        // Setup: Create Item with BOM. Create and release Sales Order. Create Requisition Line and Carry Out Action Message Plan to create Firm Planned Order.
        // Change Status from Firm Planned to Released. Update Always Create Pick Line in Location to TRUE.
        Initialize();
        ModifyAlwaysCreatePickLineOnLocation(LocationWhite, OldAlwaysCreatePickLine, true);
        CreateItemWithProductionBOM(ParentItem, ComponentItem, ComponentItem."Replenishment System"::"Prod. Order");
        Quantity := LibraryRandom.RandInt(10);  // Taking Random quantity.
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationWhite.Code, '', ParentItem."No.", '', Quantity, 0, false, false);  // Taking O for Quantity of blank line.
        CreateRequisitionLineAndCarryOutPlanForFirmPlanned(ParentItem."No.", LocationWhite.Code, Quantity);
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.");
        LibraryManufacturing.ChangeProuctionOrderStatus(
          ProductionOrder."No.", ProductionOrder.Status, ProductionOrder.Status::Released);
        UpdateProductionOrderAndRefresh(ProductionOrder, ParentItem."No.");
        LibraryVariableStorage.Enqueue(PickActivityCreatedMsg);  // Enqueue for MessageHandler.

        // Exercise: Create Pick from Production Order.
        ProductionOrder.CreatePick('', 0, false, false, false);  // Taking 0 for Sorting Method option.

        // Verify: Warehouse Activity line.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
          WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."Action Type"::Take, ComponentItem."No.", Quantity);

        // Tear Down:
        ModifyAlwaysCreatePickLineOnLocation(LocationWhite, OldAlwaysCreatePickLine, OldAlwaysCreatePickLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateConsumptionAndPickFromPickWorksheetFromReleasedProductionOrder()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with BOM. Create Released Production Order. Get Source Document on Pick Worksheet and Create Pick. Register the Pick created.
        Initialize();
        CreateItemWithProductionBOM(ParentItem, ComponentItem, ComponentItem."Replenishment System"::Purchase);
        Quantity := LibraryRandom.RandInt(10);  // Taking Random quantity.
        CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(
          PurchaseHeader, LocationWhite2.Code, ComponentItem."No.", Quantity, false, ItemTrackingMode::"Assign Serial No.", false);
        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", Quantity, LocationWhite2.Code, '');
        GetWarehouseDocumentOnWhseWorksheetLine(WhseWorksheetName, LocationWhite2.Code);
        FindWarehouseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationWhite2.Code, ComponentItem."No.");
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          LocationWhite2.Code,
          '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);  // Taking 0 for MaxNoOfLines, MaxNoOfSourceDoc and SortPick.
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", WarehouseActivityHeader.Type::Pick);

        // Exercise: Calculate Consumption and Post the Item Journal line.
        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ItemJournalBatch2."Journal Template Name", ItemJournalBatch2.Name);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch2."Journal Template Name", ItemJournalBatch2.Name);

        // Verify: Item Ledger entry for the Consumption entry.
        VerifyItemLedgerEntry(ComponentItem."No.", ItemLedgerEntry."Entry Type"::Consumption, -Quantity, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickErrorWithAllowBreakBulkFalseOnLocation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Put-Away Unit of Measure. Create Purchase Order with, Warehouse Receipt from Purchase Order. Post Warehouse Receipt. Register Warehouse Activity, Create Pick from Warehouse Shipment. Update Allow Break Bulk on Location.
        Initialize();
        CreateItemWithPutAwayUOM(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Value for Quantity.
        CreateAndReleasePurchaseOrderWithDifferentPutAwayUOM(Item, LocationWhite2.Code, Quantity);
        RegisterPutAwayFromPurchaseOrder(Item."No.");
        CreateAndReleaseSalesOrderWithDifferentPutAwayUOM(SalesHeader, Item, LocationWhite2.Code, Quantity);
        CreatePickFromWhseShipment(SalesHeader);
        ModifyAllowBreakBulkOnLocation(LocationWhite2, false);  // Allow Break Bulk as FALSE.
        CreateAndReleaseSalesOrderWithDifferentPutAwayUOM(SalesHeader2, Item, LocationWhite2.Code, Quantity);

        // Exercise: Create Pick from Warehouse Shipment and catches the Error message.
        asserterror CreatePickFromWhseShipment(SalesHeader2);

        // Verify: Nothing to handle Error.
        Assert.ExpectedError(NothingToHandleErr);

        // Tear Down: Allow break bulk TRUE on Location.
        ModifyAllowBreakBulkOnLocation(LocationWhite2, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler,ConfirmHandler,ItemTrackingListPageHandler,CreateInventoryPutAwayPickHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPartialInventoryPickWithItemTrackingAndReservationForProdOrderComponent()
    begin
        // Setup.
        Initialize();
        InventoryPickWithItemTrackingAndReservationForProdOrderComponent(false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler,ConfirmHandler,ItemTrackingListPageHandler,CreateInventoryPutAwayPickHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPickWithItemTrackingAndReservationForProdOrderComponent()
    begin
        // Setup:
        Initialize();
        InventoryPickWithItemTrackingAndReservationForProdOrderComponent(true);
    end;

    local procedure InventoryPickWithItemTrackingAndReservationForProdOrderComponent(PostRemainingPick: Boolean)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        Variant: Variant;
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Create Item with Lot specific Tracking. Post Item Journal with Lot No. Create and Refresh Production Order.
        // Create Production Order Component with Item Tracking. Reserve the Component line. Create Inventory Pick.
        Quantity := LibraryRandom.RandInt(10);  // Taking Random Quantity.
        Quantity2 := Quantity + LibraryRandom.RandInt(10);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
        CreateAndPostItemJournalLine(Item."No.", Quantity2, LocationWithRequirePick.Code, '', true);
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", Quantity2, LocationWithRequirePick.Code, '');
        LibraryVariableStorage.Dequeue(Variant);  // Dequeue for ItemTrackingPageHandler.
        CreateAndReserveProdOrderComponentWithItemTracking(ProductionOrder);
        Commit();  // Commit is required here.
        ProductionOrder.CreateInvtPutAwayPick();

        // Exercise: Post Inventory Pick with Partial Quantity.
        UpdateQuantityToHandleOnWarehouseActivityLine(
          WarehouseActivityLine,
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
          WarehouseActivityHeader.Type::"Invt. Pick", Quantity, false);
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", WarehouseActivityHeader.Type::"Invt. Pick");

        // Verify: Reservation entry.
        VerifyReservationEntry(LocationWithRequirePick.Code, Item."No.", -(Quantity2 - Quantity));  // Remaining Quantity which is not posted.

        if PostRemainingPick then begin
            // Exercise: Post the Inventory Pick with remaining Quantity.
            PostInventoryActivity(
              WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
              WarehouseActivityHeader.Type::"Invt. Pick");

            // Verify: Posted Inventory Pick Line.
            VerifyPostedInventoryPickLine(
              PostedInvtPickLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", LocationWithRequirePick.Code, Item."No.",
              Quantity2 - Quantity, true);  // Remaining Quantity.
        end;
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayOfFinishedItemUsingInternalPutAway()
    var
        Bin: Record Bin;
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseIntPutAwayRelease: Codeunit "Whse. Int. Put-away Release";
        Quantity: Decimal;
    begin
        // Setup: Create Item with BOM. Update Inventory for Parent Item. Create and refresh Production Order. Post Consumption Journal and Output Journal.
        // Create Warehouse Internal Put-Away and Run Get Bin Content report on the Put-Away.
        Initialize();
        CreateItemWithProductionBOM(ParentItem, ComponentItem, ComponentItem."Replenishment System"::"Prod. Order");
        Quantity := LibraryRandom.RandInt(10);  // Taking Random quantity.
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, false);  // Find BULK Bin.
        UpdateInventoryUsingWhseJournal(Bin, ParentItem, Quantity, '', ParentItem."Base Unit of Measure", false);
        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", Quantity, LocationWhite.Code, Bin.Code);
        PostConsumptionJournal(ParentItem."No.", Quantity, ProductionOrder."No.", LocationWhite.Code, Bin.Code);
        PostOutputJournal(ParentItem."No.", ProductionOrder."No.", Quantity);
        CreateWarehouseInternalPutAway(WhseInternalPutAwayHeader, WhseInternalPutAwayLine, Bin, ParentItem."No.", Quantity);
        RunGetBinContentOnWhseInternalPutAway(WhseInternalPutAwayHeader, ParentItem."No.");

        // Exercise: Create Put Away from Warehouse Internal Put Away.
        WhseIntPutAwayRelease.Release(WhseInternalPutAwayHeader);
        LibraryVariableStorage.Enqueue(PutAwayActivityCreatedMsg);  // Enqueue for MessageHandler.
        WhseInternalPutAwayLine.CreatePutAwayDoc(WhseInternalPutAwayLine);

        // Verify: Warehouse Activity line.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine, "Warehouse Activity Source Document"::" ", '', WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take,
          ParentItem."No.", Quantity);  // Taking 0 for Blank Source Document option.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreateHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentWithManualExpirationDateEntryRequired()
    begin
        Initialize();
        PostWarehouseShipmentWithSerialLotAndManualExpirationDateEntryRequired(true);  // Manual Expiration Date Entry Required as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreateHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentWithoutManualExpirationDateEntryRequired()
    begin
        Initialize();
        PostWarehouseShipmentWithSerialLotAndManualExpirationDateEntryRequired(false);  // Manual Expiration Date Entry Required as FALSE.
    end;

    local procedure PostWarehouseShipmentWithSerialLotAndManualExpirationDateEntryRequired(ManExprDateEntryReqd: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Setup: Create Multiple Item Tracking Codes and Items. Create and Release Purchase Order with Multiple Lines, create and Post Warehouse Receipt, update Bin and Zone on Warehouse Activity Line. Register Warehouse Activity.
        if ManExprDateEntryReqd then
            CreateMultipleItemsWithTrackingCodes(Item, Item2, true)
        else
            CreateMultipleItemsWithTrackingCodes(Item, Item2, false);  // Manual Expiration Date Entry Required as FALSE.
        Quantity := LibraryRandom.RandInt(5);
        CreateAndReleasePurchaseOrderWithTrackingOnMultipleLines(PurchaseHeader, Item."No.", Quantity, Item2."No.", LocationWhite2.Code);
        if ManExprDateEntryReqd then
            UpdateExpirationDateOnReservationEntry(Item2."No.");
        CreateAndPostWarehouseReceipt(PurchaseHeader);
        ModifyZoneAndBinCodeOnPutAwayLine(PurchaseHeader."No.", LocationWhite2.Code);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");
        CreateAndReleaseSalesOrderWithItemTrackingOnMultipleLines(SalesHeader, LocationWhite2.Code, Item."No.", Item2."No.", Quantity);
        CreatePickFromWhseShipment(SalesHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick);

        // Exercise: Post Warehouse Shipment.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Verify: Posted Warehouse Shipment Line.
        VerifyPostedWhseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationWhite2.Code,
          LocationWhite2."Shipment Bin Code", Item."No.", Quantity);
        VerifyPostedWhseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationWhite2.Code,
          LocationWhite2."Shipment Bin Code", Item2."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentForSalesOrderForItemsWithLotNoAndWithoutTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        LotNo: Variant;
        Quantity: Decimal;
        Quantity2: Decimal;
        DocumentNo: Code[20];
    begin
        // Setup: Create one Item without Tracking and another with Lot specific Tracking. Create and Post Sales Order as Ship for both Items with Lot No. for second Item.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);  // Value required for test.
        LibraryInventory.CreateItem(Item);
        CreateItemWithItemTrackingCode(Item2, false, false, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. and Serial No. as False. Taking blank value for Serial Nos. on Item card.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for ItemTrackingPageHandler.
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, '', '', Item."No.", Item2."No.", Quantity, Quantity2, true, true);  // Taking Location Code as Blank.
        LibraryVariableStorage.Dequeue(LotNo);  // Dequeue for ItemTrackingPageHandler.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.

        // Exercise.
        LibraryVariableStorage.Enqueue(UndoShipmentConfirmMsg);  // Enqueue for ConfirmHandler.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // Verify: Posted Sales Shipment lines and Item ledger entry for Tracked Item.
        VerifyPostedSalesShipmentLine(DocumentNo, Item."No.", Quantity);
        VerifyPostedSalesShipmentLine(DocumentNo, Item2."No.", Quantity2);
        VerifyItemLedgerEntryForUndoShipment(Item2."No.", true, Quantity2);
        VerifyItemLedgerEntryForUndoShipment(Item2."No.", false, -Quantity2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPartialPickAndPostPartialShipmentWithMultipleLotNo()
    begin
        // Setup.
        Initialize();
        RegisterPickAndPostShipmentForSalesOrderWithMultipleLotNoForItem(false);  // Taking False for not posting Remaining Pick.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterRemainingPickAndPostRemainingShipmentWithMultipleLotNo()
    begin
        // Setup.
        Initialize();
        RegisterPickAndPostShipmentForSalesOrderWithMultipleLotNoForItem(true);  // taking True for posting Remaining Pick.
    end;

    local procedure RegisterPickAndPostShipmentForSalesOrderWithMultipleLotNoForItem(PostRemainingPick: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        LotNo: Variant;
        LotNo2: Variant;
        Quantity: Decimal;
    begin
        // Create Item with Lot Specific Tracking. Post Item Journal Line with Bin Code with multiple Lot No.
        Quantity := LibraryRandom.RandDec(10, 2);
        FindBin(Bin, LocationSilver2.Code);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Split Lot No.");  // Enqueue for ItemTrackingPageHandler.
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationSilver2.Code, Bin.Code, true);  // Taking Blank for Bin Code and True for Item Tracking.
        LibraryVariableStorage.Dequeue(LotNo);  // Dequeue for ItemTrackingPageHandler.
        LibraryVariableStorage.Dequeue(LotNo2);  // Dequeue for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for ItemTrackingPageHandler.

        // Create Warehouse Shipment from Sales Order with multiple Lot No. Modify Bin Code on Warehouse Shipment and Create Pick.
        CreateWarehouseShipmentFromSalesOrder(SalesHeader, LocationSilver2.Code, Item."No.", Quantity, true);
        Bin.Next();
        UpdateBinOnWarehouseShipmentLine(Bin, SalesHeader."No.");
        CreatePick(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Delete Quantity to Handle on Warehouse Activity Line for second Lot No.
        WarehouseActivityLine.SetRange("Lot No.", LotNo2);
        DeleteQuantityToHandleOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // Exercise: Register the Pick with Partial Quantity and Post the Warehouse Shipment.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        DeleteReservationEntry(Item."No.", LotNo2);
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Verify.
        VerifyPostedWhseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationSilver2.Code, Bin.Code, Item."No.",
          Quantity / 2);  // Value required for test.

        if PostRemainingPick then begin
            // Exercise: Register the rest of the Pick and Post the rest of the Shipment.
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
            PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

            // Verify.
            VerifyPostedWhseShipmentLine(
              WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationSilver2.Code, Bin.Code, Item."No.",
              Quantity / 2);  // Value required for test.
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostShipmentAfterDeletingRemainingPickFromSalesOrderWithLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        LotNo: Variant;
        Quantity: Decimal;
    begin
        // Setup: Create Item with Lot specific Tracking. Create and Register Put-Away from Purchase Order and Post receipt. Create Pick from Sales Order.
        // Register the Pick with Partial quantity. Delete the remaining Pick.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
        CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(
          PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, true, ItemTrackingMode::"Assign Lot No.", true);
        LibraryVariableStorage.Dequeue(LotNo);  // Dequeue for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for ItemTrackingPageHandler.
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationWhite.Code, '', Item."No.", '', Quantity, 0, false, true);
        CreatePickFromWhseShipment(SalesHeader);
        UpdateQuantityToHandleOnWarehouseActivityLine(
          WarehouseActivityLine,
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          Quantity / 2, true);  // Value required for test.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        DeletePick(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Exercise.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Verify: Posted Warehouse Shipment line.
        VerifyPostedWhseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationWhite.Code,
          LocationWhite."Shipment Bin Code", Item."No.", Quantity / 2);  // Value required for test.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostShipmentAfterDeletingRemainingPickFromTransferOrderWithLotNo()
    var
        Bin: Record Bin;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Lot specific Tracking. Update Inventory using Warehouse Journal. Create Pick from Transfer Order. Register the Pick with Partial quantity.
        // Delete the remaining Pick.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for ItemTrackingPageHandler.
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true);  // Find PICK Bin.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '', Item."Base Unit of Measure", true);  // Taking True for Item Tracking.
        CreateWarehouseShipmentFromTransferOrderWithLotNo(TransferHeader, LocationWhite.Code, LocationSilver3.Code, Item."No.", Quantity);
        CreatePick(WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");
        UpdateQuantityToHandleOnWarehouseActivityLine(
          WarehouseActivityLine,
          WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick, Quantity / 2, true);  // Value required for test.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        DeletePick(WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.");

        // Exercise.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");

        // Verify: Posted Warehouse Shipment line.
        VerifyPostedWhseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", LocationWhite.Code,
          LocationWhite."Shipment Bin Code", Item."No.", Quantity / 2);  // Value required for test.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostShipmentAfterDeletingRemainingPickFromPurchaseReturnOrderWithLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        LotNo: Variant;
        Quantity: Decimal;
    begin
        // Setup: Create Item with Lot specific Tracking. Create and Register Put-Away from Purchase Order and Post receipt. Create Pick from Purchase Return Order.
        // Register the Pick with Partial quantity. Delete the remaining Pick.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
        CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(
          PurchaseHeader, LocationWhite2.Code, Item."No.", Quantity, true, ItemTrackingMode::"Assign Lot No.", true);
        LibraryVariableStorage.Dequeue(LotNo);  // Dequeue for ItemTrackingPageHandler.
        CreateWarehouseShipmentFromPurchaseReturnOrderWithLotNo(PurchaseHeader, Item."No.", LocationWhite2.Code, Quantity);
        CreatePick(WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");
        UpdateQuantityToHandleOnWarehouseActivityLine(
          WarehouseActivityLine,
          WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick, Quantity / 2, true);  // Value required for test.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        DeletePick(WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");

        // Exercise.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");

        // Verify: Posted Warehouse Shipment line.
        VerifyPostedWhseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.", LocationWhite2.Code,
          LocationWhite2."Shipment Bin Code", Item."No.", Quantity / 2);  // Value required for test.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingSummaryPageHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentAfterRegisteringPickFromSalesOrderWithLotNo()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create Item with Lot specific Tracking. Update Inventory using Warehouse Item Journal. Create and Register the Pick from Warehouse Shipment.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for ItemTrackingPageHandler.
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true);  // Find PICK Bin.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '', Item."Base Unit of Measure", true);  // Taking True for Item Tracking.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for ItemTrackingPageHandler.
        CreatePickFromSalesOrder(SalesHeader, LocationWhite.Code, Item."No.", Quantity, true);  // Taking True for Item Tracking.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Exercise.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Verify: Posted Warehouse Shipment line.
        VerifyPostedWhseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationWhite.Code,
          LocationWhite."Shipment Bin Code", Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingSummaryPageHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromTransferOrderWithLotNo()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisteringPickFromTransferOrderWithLotNo(false, false);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingSummaryPageHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromTransferOrderWithLotNo()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisteringPickFromTransferOrderWithLotNo(true, false);  // Taking True for create Warehouse Pick.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingSummaryPageHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentFromTransferOrderWithLotNo()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisteringPickFromTransferOrderWithLotNo(true, true);  // Taking True for create Pick and Verify Posted Warehouse Shipment.
    end;

    local procedure PostWarehouseShipmentAfterRegisteringPickFromTransferOrderWithLotNo(CreateWarehousePick: Boolean; VerifyPostedWarehouseShipment: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create Item with Lot specific Tracking. Update Inventory using Warehouse Item Journal.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for ItemTrackingPageHandler.
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true);  // Find PICK Bin.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '', Item."Base Unit of Measure", true);  // Taking True for Item Tracking.

        // Exercise.
        CreateWarehouseShipmentFromTransferOrderWithLotNo(TransferHeader, LocationWhite.Code, LocationSilver3.Code, Item."No.", Quantity);

        // Verify.
        VerifyWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", LocationWhite.Code, Item."No.", Quantity);

        if CreateWarehousePick then begin
            // Exercise.
            CreatePick(WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");

            // Verify.
            VerifyWarehouseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);
            VerifyWarehouseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity);
        end;

        if VerifyPostedWarehouseShipment then begin
            // Exercise: Register the Pick and Post the Warehouse Shipment.
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);
            PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");

            // Verify: Posted Warehouse Shipment line and Transfer Order line.
            VerifyPostedWhseShipmentLine(
              WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", LocationWhite.Code,
              LocationWhite."Shipment Bin Code", Item."No.", Quantity);
            VerifyTransferOrderLine(TransferHeader."No.", Item."No.", 0, Quantity);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickIncorrectAllocationWithSalesUnitOfMeasureDiffersFromBOM()
    var
        Item: Record Item;
        Bin: array[3] of Record Bin;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: array[3] of Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        BackupLocation: Record Location;
        Quantity: array[3] of Decimal;
    begin
        // [FEATURE] [Warehouse Activity Line] [Warehouse Shipment] [Item Tracking]
        // [SCENARIO 379071] Pick lines with appropriate bin codes and quantities are created for item with Sales Unit of Measure differs from Base UoM.
        Initialize();

        // [GIVEN] Item with Sales Unit of Measure = U1.
        CreateItemWithDifferentSalesUnitOfMeasure(Item, ItemUnitOfMeasure);

        Quantity[1] := LibraryRandom.RandInt(100) * ItemUnitOfMeasure."Qty. per Unit of Measure";
        Quantity[2] := LibraryRandom.RandInt(100) * ItemUnitOfMeasure."Qty. per Unit of Measure";
        Quantity[3] := LibraryRandom.RandInt(100) * ItemUnitOfMeasure."Qty. per Unit of Measure";

        // [GIVEN] Bins "B1", "B2", "B3" from "Require Shipment" Location with preconfigured Bins.
        BackupLocation := LocationSilver;
        FindBinsAndSetLocationParemeters(Bin, LocationSilver);

        // [GIVEN] Positive adjustment with quantity = "X" in bin "B1",quantity = "Y" in bin "B2",quantity = "Z" in bin "B3".
        // [GIVEN] Sales Order for Bin "B1" of Quantity = "X" and "Unit of Measure Code" = Base UoM.
        // [GIVEN] Sales Order for Bin "B2" of Quantity = "Y" and "Unit of Measure Code" = Base UoM.
        // [GIVEN] Sales Order for Bin "B3" of Quantity = "Z" and "Unit of Measure Code" = U1.
        CreateThreeSalesOrderForDifferentBins(
          SalesHeader, Item, Bin, LocationSilver.Code, Quantity, ItemUnitOfMeasure."Qty. per Unit of Measure");

        // [GIVEN] Calling Get Source Document On Warehouse Shipment.
        GetSourceDocumentOnWarehouseShipment(WarehouseShipmentHeader, LocationSilver.Code, false);

        // [WHEN] Create Pick on Warehouse Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Warehouse Activity Lines with quantity = "X" and bin "B1", quantity = "Y" and bin "B2", quantity = "Z" and bin "B3" are created.
        VerifyBinCodeAndQuantityOnWarehouseActivityLine(
          SalesHeader[1]."No.", Bin[1].Code, UoMMgt.RoundQty(Quantity[1] / ItemUnitOfMeasure."Qty. per Unit of Measure"));
        VerifyBinCodeAndQuantityOnWarehouseActivityLine(
          SalesHeader[2]."No.", Bin[2].Code, UoMMgt.RoundQty(Quantity[2] / ItemUnitOfMeasure."Qty. per Unit of Measure"));
        VerifyBinCodeAndQuantityOnWarehouseActivityLine(SalesHeader[3]."No.", Bin[3].Code, Quantity[3]);

        // Tear down.
        LocationSilver := BackupLocation;
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingSummaryPageHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromPurchaseReturnOrderWithLotNo()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisteringPickFromPurchaseReturnOrderWithLotNo(false, false);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingSummaryPageHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromPurchaseReturnOrderWithLotNo()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisteringPickFromPurchaseReturnOrderWithLotNo(true, false);  // Taking True for create Warehouse Pick.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingSummaryPageHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentFromPurchaseReturnOrderWithLotNo()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisteringPickFromPurchaseReturnOrderWithLotNo(true, true);  // Taking True for create Pick and Verify Posted Warehouse Shipment.
    end;

    local procedure PostWarehouseShipmentAfterRegisteringPickFromPurchaseReturnOrderWithLotNo(CreateWarehousePick: Boolean; VerifyPostedWarehouseShipment: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create Item with Lot specific Tracking. Update Inventory using Warehouse Item Journal.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for ItemTrackingPageHandler.
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true);  // Find PICK Bin.
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '', Item."Base Unit of Measure", true);  // Taking True for Item Tracking.

        // Exercise.
        CreateWarehouseShipmentFromPurchaseReturnOrderWithLotNo(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity);

        // Verify.
        VerifyWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.", LocationWhite.Code, Item."No.", Quantity);

        if CreateWarehousePick then begin
            // Exercise.
            CreatePick(WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");

            // Verify.
            VerifyWarehouseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);
            VerifyWarehouseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity);
        end;

        if VerifyPostedWarehouseShipment then begin
            // Exercise: Register the Pick and Post the Warehouse Shipment.
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);
            PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");

            // Verify: Posted Warehouse Shipment line and Purchase Return Order line.
            VerifyPostedWhseShipmentLine(
              WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.", LocationWhite.Code,
              LocationWhite."Shipment Bin Code", Item."No.", Quantity);
            VerifyPurchaseReturnOrderLine(PurchaseHeader."No.", Item."No.", Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseInternalPickWithItemVariantAndMultipleUOM()
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        ItemVariant: Record "Item Variant";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WarehouseEntry: Record "Warehouse Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create an Item with Flushing Method as Forward and another with Flushing Method, Variant and two Item Unit of Measure. Update Inventory using Warehouse Journal. Create Pick from Warehouse Internal Pick.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithFlushingMethodForward(Item);
        CreateItemWithVariantAndFlushingMethod(ItemVariant);
        Item2.Get(ItemVariant."Item No.");
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item2."No.");
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '', Item."Base Unit of Measure", false);  // Taking Blank for Variant Code.
        UpdateInventoryUsingWhseJournal(Bin, Item2, Quantity, ItemVariant.Code, ItemUnitOfMeasure.Code, false);
        Bin.Get(LocationWhite.Code, LocationWhite."Open Shop Floor Bin Code");
        CreatePickFromWarehouseInternalPickWithMultipleLines(
          WhseInternalPickHeader, Bin, Item."No.", Item."Base Unit of Measure", Quantity, Item2."No.", ItemVariant.Code,
          ItemUnitOfMeasure.Code);

        // Exercise.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify: Warehouse Entries, Item Ledger Entries and Bin Contents.
        VerifyWarehouseEntry(Item."No.", WarehouseEntry."Entry Type"::"Negative Adjmt.", '', -Quantity);  // Taking Blank for Variant Code.
        VerifyWarehouseEntry(Item."No.", WarehouseEntry."Entry Type"::"Positive Adjmt.", '', Quantity);  // Taking Blank for Variant Code.
        VerifyWarehouseEntry(Item2."No.", WarehouseEntry."Entry Type"::"Negative Adjmt.", ItemVariant.Code, -Quantity);
        VerifyWarehouseEntry(Item2."No.", WarehouseEntry."Entry Type"::"Positive Adjmt.", ItemVariant.Code, Quantity);
        VerifyItemLedgerEntry(Item."No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Quantity, '');  // Taking Blank for Variant Code.
        VerifyItemLedgerEntry(
          Item2."No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure",
          ItemVariant.Code);  // Value required for the test.
        VerifyBinContent(LocationWhite.Code, Bin.Code, Item."No.", '', Quantity, '');  // Taking Blank for Variant Code and Warehouse Class Code.
        VerifyBinContent(LocationWhite.Code, Bin.Code, Item2."No.", ItemVariant.Code, Quantity, '');  // Taking Blank for Warehouse Class Code.
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderAfterPickFromWhseInternalPickWithItemVariantAndMultipleUOM()
    var
        Bin: Record Bin;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ComponentItem: Record Item;
        ComponentItem2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemVariant: Record "Item Variant";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        Quantity: Decimal;
    begin
        // Setup: Create an Item with Production BOM with two Component Items, one without Variant and another with Variant and different Unit of Measure. Update Inventory using Warehouse Journal.
        // Create Pick from Warehouse Internal Pick and register the Pick.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItemWithFlushingMethodForward(ParentItem);
        CreateItemWithFlushingMethodForward(ComponentItem);
        CreateItemWithVariantAndFlushingMethod(ItemVariant);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemVariant."Item No.");
        CreateAndCertifyBOMWithMultipleLines(
          ProductionBOMHeader, ParentItem."Base Unit of Measure", ComponentItem."No.", ItemVariant."Item No.", ItemVariant.Code,
          ItemUnitOfMeasure.Code);
        UpdateProductionBOMOnItem(ParentItem, ProductionBOMHeader."No.");
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        ComponentItem2.Get(ItemVariant."Item No.");
        UpdateInventoryUsingWhseJournal(Bin, ComponentItem, Quantity, '', ComponentItem."Base Unit of Measure", false);  // Taking Blank for Zone and Variant Code.
        UpdateInventoryUsingWhseJournal(Bin, ComponentItem2, Quantity, ItemVariant.Code, ItemUnitOfMeasure.Code, false);  // Taking Blank for Zone Code.
        Bin.Get(LocationWhite.Code, LocationWhite."Open Shop Floor Bin Code");
        CreatePickFromWarehouseInternalPickWithMultipleLines(
          WhseInternalPickHeader, Bin, ComponentItem."No.", ComponentItem."Base Unit of Measure", Quantity, ComponentItem2."No.",
          ItemVariant.Code, ItemUnitOfMeasure.Code);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Exercise.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ParentItem."No.", Quantity, LocationWhite.Code, LocationWhite."Open Shop Floor Bin Code");

        // Verify: Item Ledger Entries and Bin contents.
        VerifyItemLedgerEntry(ComponentItem."No.", ItemLedgerEntry."Entry Type"::Consumption, -Quantity, '');  // Taking Blank for Variant Code.
        VerifyItemLedgerEntry(
          ComponentItem2."No.", ItemLedgerEntry."Entry Type"::Consumption, -Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure",
          ItemVariant.Code);  // Value required for the test.
        VerifyBinContent(LocationWhite.Code, Bin.Code, ComponentItem."No.", '', 0, '');  // Value 0 is required for the test. Taking Blank for Variant Code and Warehouse Class Code.
        VerifyBinContent(LocationWhite.Code, Bin.Code, ComponentItem2."No.", ItemVariant.Code, 0, '');  // Value 0 is required for the test. Taking Blank for Warehouse Class Code.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerSimple')]
    [Scope('OnPrem')]
    procedure ShippingAgentCodeShouldBeChangedInSalesOrderAfterChangingInWhseShipment()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [FEATURE] [Warehouse Shipment] [Shipping Agent]
        // [SCENARIO 379948] Shipping Agent Service Code should be modified after changing Shipping Agent Code in Warehouse Shipment if Shipping Agent Service Code is empty in Warehouse Shipment.
        Initialize();

        // [GIVEN] Create Location with shipment requirement.
        CreateAndUpdateLocation(Location, false, false, false, true, false);

        // [GIVEN] Sales Order with Shipping Agent Code ="SA1" and filled Shipping Agent Service Code field.
        CreateSalesOrderWithPostingDate(SalesHeader, SalesHeader."Document Type"::Order, Location.Code);
        UpdateShippingAgentCodeAndShippingAgentServiceCode(SalesHeader);

        // [GIVEN] Warehouse Shipment with Shipping Agent Code ="SA2" and empty Shipping Agent Service Code field.
        CreateWarehouseShipmentFromSOWithPostingDate(WarehouseShipmentHeader, SalesHeader);
        UpdateShippingAgentCodeInWhseShipment(WarehouseShipmentHeader, ShippingAgent);

        // [WHEN] Post Warehouse Shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Sales Order and Posted Sales Shipment should have empty Shipping Agent Service Code field.
        VerifySalesHeaderAndSalesShipmentHeader(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerSimple')]
    [Scope('OnPrem')]
    procedure ShippingServiceAgentCodeShouldBeChangedAfterTwoPartialShipment()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PeriodLength: DateFormula;
        Quantity: Decimal;
        QuantityForFirstShip: Decimal;
    begin
        // [FEATURE] [Warehouse Shipment] [Shipping Agent]
        // [SCENARIO 379948] Shipping Agent Service Code should be modified in Sales Header after two partial Warehouse Shipment if Shipping Agent Service Code was changed before posting second partial Warehouse Shipment.
        Initialize();

        // [GIVEN] Create Location with shipment requirement.
        CreateAndUpdateLocation(Location, false, false, false, true, false);

        // [GIVEN] Sales Order with Shipping Agent Code ="SA1" and Shipping Agent Service Code = "SS1" field.
        Quantity := CreateSalesOrderWithDeterminedQuantity(SalesHeader, SalesHeader."Document Type"::Order, Location.Code);
        UpdateShippingAgentCodeAndShippingAgentServiceCode(SalesHeader);

        // [GIVEN] Warehouse Shipment with Shipping Agent Code ="SA2" and Shipping Agent Service Code = "SS2" field.
        CreateWarehouseShipmentFromSOWithPostingDate(WarehouseShipmentHeader, SalesHeader);
        UpdateShippingAgentCodeInWhseShipment(WarehouseShipmentHeader, ShippingAgent);
        QuantityForFirstShip := LibraryRandom.RandInt(Quantity - 1);
        Evaluate(PeriodLength, '<1D>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, PeriodLength);
        UpdateWhseShipment(WarehouseShipmentHeader, ShippingAgentServices, QuantityForFirstShip);

        // [GIVEN] Post partial Warehouse Shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [GIVEN] Update existing Warehouse Shipment with Shipping Agent Service Code = "SS3" field.
        WarehouseShipmentHeader.Find();
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, PeriodLength);
        UpdateWhseShipment(WarehouseShipmentHeader, ShippingAgentServices, Quantity - QuantityForFirstShip);

        // [WHEN] Post partial Warehouse Shipment second time.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Sales Order and Posted Sales Shipment should have Shipping Agent Service Code = "SS3".
        VerifyShippingAgentServiceInSalesHeaderAndSalesShipmentHeader(ShippingAgentServices, SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseClassCodeErrorOnWarehouseReceipt()
    var
        WarehouseClass: Record "Warehouse Class";
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        Zone: Record Zone;
    begin
        // Setup: Create Item with Warehouse Class Code. Create Zone with Warehouse Class Code. Create Bin for new Zone. Create Warehouse Receipt from Purchase Order.
        Initialize();
        CreateItemWithWarehouseClass(WarehouseClass, Item);
        LibraryWarehouse.CreateZone(
          Zone,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Zone.FieldNo(Code), DATABASE::Zone), 1,
            LibraryUtility.GetFieldLength(DATABASE::Zone, Zone.FieldNo(Code))),
          LocationWhite.Code, LibraryWarehouse.SelectBinType(true, false, false, false), WarehouseClass.Code, '', 0, false);  // Value required for Zone Rank. Taking True for Receive Zone.
        CreateBinWithWarehouseClassCode(Bin, Zone, '');  // Taking blank for Warehouse Class Code.
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationWhite.Code, Item."No.", LibraryRandom.RandDec(10, 2));

        // Exercise: Update Zone and Bin Code on Warehouse Receipt Line.
        asserterror UpdateZoneAndBinCodeOnWarehouseReceiptLine(Bin, PurchaseHeader."No.");

        // Verify: Error message.
        Assert.ExpectedTestFieldError(Item.FieldCaption("Warehouse Class Code"), WarehouseClass.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPutAwayWithWarehouseClassCode()
    var
        WarehouseClass: Record "Warehouse Class";
        Item: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Zone: Record Zone;
        Quantity: Decimal;
        OldAlwaysCreatePutAwayLine: Boolean;
    begin
        // Setup: Create Item with Warehouse Class Code. Create and Post Warehouse Receipt from Purchase Order with Warehouse Class Code. Create Pick Zone with Warehouse Class Code. Create Bin with Warehouse Class Code.
        Initialize();
        ModifyAlwaysCreatePutAwayLineOnLocation(LocationWhite, OldAlwaysCreatePutAwayLine, true);  // Taking True for Always Create Put-Away Line.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithWarehouseClass(WarehouseClass, Item);
        PostWarehouseReceiptFromPurchaseOrderWithWarehouseClassCode(
          PurchaseHeader, Bin, LocationWhite.Code, WarehouseClass.Code, Item."No.", Quantity);
        LibraryWarehouse.CreateZone(
          Zone,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Zone.FieldNo(Code), DATABASE::Zone), 1,
            LibraryUtility.GetFieldLength(DATABASE::Zone, Zone.FieldNo(Code))),
          LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true), WarehouseClass.Code, '', 0, false);  // Value required for Zone Rank. Taking True for Pick Zone.
        CreateBinWithWarehouseClassCode(Bin2, Zone, WarehouseClass.Code);

        // Exercise: Update Bin Code on Place Line and Register Put Away.
        ModifyBinOnWarehouseActivityLineAndRegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Bin2.Code);

        // Verify.
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::"Put-away", RegisteredWhseActivityLine."Action Type"::Take, Item."No.", Quantity,
          Bin.Code);
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::"Put-away", RegisteredWhseActivityLine."Action Type"::Place, Item."No.", Quantity,
          Bin2.Code);
        VerifyBinContent(LocationWhite.Code, Bin2.Code, Item."No.", '', Quantity, WarehouseClass.Code);  // Taking Blank for Variant Code.

        // Tear Down.
        Zone.Delete();
        ModifyAlwaysCreatePutAwayLineOnLocation(LocationWhite, OldAlwaysCreatePutAwayLine, OldAlwaysCreatePutAwayLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseClassCodeErrorOnWarehouseShipment()
    var
        WarehouseClass: Record "Warehouse Class";
        Item: Record Item;
        Bin: Record Bin;
        Zone: Record Zone;
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create Item with Warehouse Class Code. Create Zone with Warehouse Class Code. Create Bin for new Zone. Create Warehouse Shipment from Sales Order.
        Initialize();
        CreateItemWithWarehouseClass(WarehouseClass, Item);
        LibraryWarehouse.CreateZone(
          Zone,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Zone.FieldNo(Code), DATABASE::Zone), 1,
            LibraryUtility.GetFieldLength(DATABASE::Zone, Zone.FieldNo(Code))),
          LocationWhite.Code, LibraryWarehouse.SelectBinType(false, true, false, false), WarehouseClass.Code, '', 0, false);  // Value required for Zone Rank. Taking True for Ship Zone.
        CreateBinWithWarehouseClassCode(Bin, Zone, '');  // Taking Blank for Warehouse Class Code.
        CreateWarehouseShipmentFromSalesOrder(SalesHeader, LocationWhite.Code, Item."No.", LibraryRandom.RandDec(10, 2), false);

        // Exercise: Update Bin Code on Warehouse Shipment Line.
        asserterror UpdateBinOnWarehouseShipmentLine(Bin, SalesHeader."No.");

        // Verify: Error message.
        Assert.ExpectedTestFieldError(Item.FieldCaption("Warehouse Class Code"), WarehouseClass.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentFromSalesOrderWithWarehouseClassCode()
    var
        Item: Record Item;
        WarehouseClass: Record "Warehouse Class";
        Bin: Record Bin;
        Bin2: Record Bin;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Zone: Record Zone;
        Quantity: Decimal;
        OldAlwaysCreatePickLine: Boolean;
        OldAlwaysCreatePutAwayLine: Boolean;
    begin
        // Setup: Create Item with Warehouse Class Code. Create and Post Warehouse Receipt from Purchase Order with Warehouse Class Code. Create Pick from Sales Order with
        // Warehouse Class Code and register the Pick.
        Initialize();
        ModifyAlwaysCreatePickLineOnLocation(LocationWhite, OldAlwaysCreatePickLine, true);  // Taking True for Always Create Pick Line.
        ModifyAlwaysCreatePutAwayLineOnLocation(LocationWhite, OldAlwaysCreatePutAwayLine, true);  // Taking True for Always Create Put-Away Line.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithWarehouseClass(WarehouseClass, Item);
        PostWarehouseReceiptFromPurchaseOrderWithWarehouseClassCode(
          PurchaseHeader, Bin, LocationWhite.Code, WarehouseClass.Code, Item."No.", Quantity);
        LibraryWarehouse.CreateZone(
          Zone,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Zone.FieldNo(Code), DATABASE::Zone), 1,
            LibraryUtility.GetFieldLength(DATABASE::Zone, Zone.FieldNo(Code))),
          LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true), WarehouseClass.Code, '', 0, false);  // Value required for Zone Rank. Taking True for Pick Zone.
        CreateBinWithWarehouseClassCode(Bin2, Zone, WarehouseClass.Code);
        ModifyBinOnWarehouseActivityLineAndRegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Bin2.Code);
        CreatePickFromSalesOrderWithWarehouseClassCode(SalesHeader, Bin, LocationWhite.Code, WarehouseClass.Code, Item."No.", Quantity);
        ModifyBinOnWarehouseActivityLineAndRegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
          WarehouseActivityLine."Action Type"::Take, Bin2.Code);

        // Exercise.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Verify.
        VerifyPostedWhseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", LocationWhite.Code, Bin.Code, Item."No.", Quantity);

        // Tear Down.
        Zone.Delete();
        ModifyAlwaysCreatePickLineOnLocation(LocationWhite, OldAlwaysCreatePickLine, OldAlwaysCreatePickLine);
        ModifyAlwaysCreatePutAwayLineOnLocation(LocationWhite, OldAlwaysCreatePutAwayLine, OldAlwaysCreatePutAwayLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWarehouseReceiptFromPurchaseOrderWithMultipleLocation()
    var
        Item: Record Item;
        Location1: Record Location;
        Location2: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Create and release Sales Order with two lines for different Locations.
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location1, false, true, false, true, false); // Create location require put-away and receive.
        LibraryWarehouse.CreateLocationWMS(Location2, false, true, false, false, false); // Create location require put-away.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2); // Taking Random value for Quantity.
        CreateAndReleasePurchaseOrderWithMultipleLocations(
          PurchaseHeader, PurchaseLine, Location1.Code, Location2.Code, Item."No.", Item."No.", Quantity, Quantity, true);

        // Exercise: Create Warehouse Receipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Verify: The first purchase line created Warehouse Receipt Line and the second not.
        VerifyWarehouseReceiptCreated(
          WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Location1.Code, Item."No.", true);
        VerifyWarehouseReceiptCreated(
          WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Location2.Code, Item."No.", false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WarehouseReceiptCardPageHandler')]
    procedure OpeningWarehouseReceiptCardFromPurchaseOrderWithSingleLocation()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Create and release Purchase Order with single line.
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, true, false); // Create location require put-away and receive.
        LibraryVariableStorage.Enqueue(StrSubstNo(SingleWarehouseReceiptCreatedMsg, 1, WarehouseReceiptHeader.TableCaption()));  // Enqueue for MessageHandler.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random value for Quantity.
        CreateAndReleasePurchaseOrderWithMultipleLocations(
          PurchaseHeader, PurchaseLine, Location.Code, '', Item."No.", '', Quantity, 0, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // Exercise: Create Warehouse Receipt from Purchase Order with dialog
        GetSourceDocInbound.CreateFromPurchOrder(PurchaseHeader);

        // Verify: Warehouse Receipt Card has been displayed
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WarehouseReceiptListPageHandler')]
    procedure OpeningWarehouseReceiptListFromPurchaseOrderWithMultipleLocations()
    var
        Item: Record Item;
        Item2: Record Item;
        Location1: Record Location;
        Location2: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEmployee: Record "Warehouse Employee";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Create and release Purchase Order with two lines for different Locations.
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location1, false, true, false, true, false); // Create location require put-away and receive.
        LibraryWarehouse.CreateLocationWMS(Location2, false, true, false, true, false); // Create location require put-away and receive.
        LibraryVariableStorage.Enqueue(StrSubstNo(MultipleWarehouseReceiptsCreatedMsg, 2));  // Enqueue for MessageHandler.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random value for Quantity.
        CreateAndReleasePurchaseOrderWithMultipleLocations(
          PurchaseHeader, PurchaseLine, Location1.Code, Location2.Code, Item."No.", Item2."No.", Quantity, Quantity, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location1.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location2.Code, false);

        // Exercise: Create Warehouse Receipt from Purchase Order with dialog
        GetSourceDocInbound.CreateFromPurchOrder(PurchaseHeader);

        // Verify: Warehouse Receipt List has been displayed
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWarehouseShipmentFromSalesOrderWithMultipleLocation()
    var
        Item: Record Item;
        Location1: Record Location;
        Location2: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Create and release Sales Order with two lines for different Locations.
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location1, false, false, true, false, true); // Create location require pick and shipment.
        LibraryWarehouse.CreateLocationWMS(Location2, false, false, true, false, false); // Create location require pick.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2); // Taking Random value for Quantity.
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, Location1.Code, Location2.Code, Item."No.", Item."No.", Quantity, Quantity, true, false);

        // Exercise: Create Warehouse Shipment from Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify:  The first Sales line created Warehouse Shipment Line and the second not.
        VerifyWarehouseShipmentCreated(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Location1.Code, Item."No.", true);
        VerifyWarehouseShipmentCreated(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Location2.Code, Item."No.", false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CheckAllocationLotInPick()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        Delta: Decimal;
        QuantityToShip: Decimal;
        QuantityInItemTrackingLines: Decimal;
        LotNo: array[2] of Code[20];
        QuantityForPartialPick: array[2] of Decimal;
    begin
        // [FEATURE] [Tracking Specification]
        // [SCENARIO 378604] Item Tracking Lines with 2 lots lines should have correct quantities after two partial picks.

        Initialize();
        Delta := LibraryRandom.RandDecInRange(5, 20, 2);
        QuantityToShip := LibraryRandom.RandDecInDecimalRange(4 * Delta, 100, 2);
        QuantityInItemTrackingLines := QuantityToShip / 2;
        QuantityForPartialPick[1] := Delta / 2;
        QuantityForPartialPick[2] := Delta / 2;

        // [GIVEN] Create Whse Pick for Lot-Tracked Item, where Quantity=64 in Sales Line, "Quantity to handle"=32 in both Item tracking Lines connected to this Sales Line.
        CreateWarehousePickforLotTrackedItem(SalesHeader, LotNo, LocationWhite.Code, QuantityToShip, QuantityInItemTrackingLines);

        // [GIVEN] Register partial pick for both lots with quantities 8 and 8.
        ChangeQtyToHandleInWarehouseActivityLines(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick,
          QuantityForPartialPick, LotNo);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick);

        // [WHEN] Register partial pick for both lots again with quantities 0 and 16.
        QuantityForPartialPick[1] := 0;
        QuantityForPartialPick[2] := Delta;
        ChangeQtyToHandleInWarehouseActivityLines(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick,
          QuantityForPartialPick, LotNo);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick);

        // [THEN] Item Tracking Lines should have quantities 8 and 24.
        QuantityForPartialPick[1] := -(QuantityForPartialPick[1] + Delta / 2);
        QuantityForPartialPick[2] := -(QuantityForPartialPick[2] + Delta / 2);
        VerifyReservationEntryLine(
          SalesHeader."No.", LotNo[1], QuantityForPartialPick[1], -QuantityInItemTrackingLines - QuantityForPartialPick[1]);
        VerifyReservationEntryLine(
          SalesHeader."No.", LotNo[2], QuantityForPartialPick[2], -QuantityInItemTrackingLines - QuantityForPartialPick[2]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckWareHouseActivityLineWithShippingValues()
    var
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        // Verify that Shipping Agent Code,Shipping Agent Service Code and Shipment method code populated when create Inventory Put-away/Pick from transfer order.
        Initialize();
        ShipmentMethod.FindFirst();
        Evaluate(ShippingTime, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));
        CreateShippingAgentWithServices(ShippingAgent, ShippingAgentServices, ShippingTime, 1);
        ShippingValuesInWarehouseActivityLine(ShipmentMethod.Code, ShippingAgent.Code, ShippingAgentServices.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckWareHouseActivityLineWithOutShippingValues()
    begin
        // Verify that Shipping Agent Code,Shipping Agent Service Code and Shipment method code does not populated when create Inventory Put-away/Pick from transfer order.
        Initialize();
        ShippingValuesInWarehouseActivityLine('', '', ''); // All Shipping Values Blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckInventoryErrorOnTransferOrder()
    var
        Location: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        Quantity: Decimal;
    begin
        // Verify inventory error when posting transfer shipment.

        // Setup: Create and post sales and purchase order.Create and release transfer order.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateAndPostPurchaseOrder(Location, LibraryInventory.CreateItem(Item), Quantity);
        CreateAndPostSalesOrder(Location.Code, Item."No.", Quantity);
        CreateAndReleaseTransferOrder(TransferHeader, Location.Code, LocationRed.Code, Item."No.", Quantity, false);

        // Exercise: Post transfer order as ship.
        asserterror LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // Verify: Verifying inventory error.
        Assert.ExpectedError(StrSubstNo(ItemInventoryInErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckPostingOnTransferOrder()
    var
        Location: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        PostedShipmentNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify transfer shipment posted successfully with undo sales shipment.

        // Setup: Create and post sales and purchase order and undo sales shipment.Create and release transfer order.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateAndPostPurchaseOrder(Location, LibraryInventory.CreateItem(Item), Quantity);
        PostedShipmentNo := CreateAndPostSalesOrder(Location.Code, Item."No.", Quantity);
        UndoSalesShipment(PostedShipmentNo, Item."No.");
        CreateAndReleaseTransferOrder(TransferHeader, Location.Code, LocationRed.Code, Item."No.", Quantity, false);

        // Exercise: Post transfer order as ship.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // Verify: Verifying that transfer shipment header exist.
        TransferShipmentHeader.Get(TransferHeader."Last Shipment No.")
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForUndoPosetReceipt')]
    [Scope('OnPrem')]
    procedure CheckErrorOnTransferOrderWithUndoShipmentAndUndoReceipt()
    var
        Location: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
        PostedReceiptNo: Code[20];
        PostedShipmentNo: Code[20];
    begin
        // Verify remaining quantity error with undo shipment and with undo receipt.

        // Setup: Create and post sales and purchase order and undo sales shipment.Create and release transfer order.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        PostedReceiptNo := CreateAndPostPurchaseOrder(Location, LibraryInventory.CreateItem(Item), Quantity);
        PostedShipmentNo := CreateAndPostSalesOrder(Location.Code, Item."No.", Quantity);
        UndoSalesShipment(PostedShipmentNo, Item."No.");
        CreateAndReleaseTransferOrder(TransferHeader, Location.Code, LocationRed.Code, Item."No.", Quantity, false);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // Exercise: Undo purchase recept line.
        PurchRcptLine.SetRange("Document No.", PostedReceiptNo);
        PurchRcptLine.FindFirst();
        asserterror LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // Verify: Verifying remaining quanitity error.
        Assert.ExpectedTestFieldError(ItemLedgEntry.FieldCaption("Remaining Quantity"), Format(PurchRcptLine.Quantity));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckInventoryErrorOnTransferOrderWithUndoShipment()
    var
        Location: Record Location;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        Quantity: Decimal;
        PostedShipmentNo: Code[20];
    begin
        // Verify inventory error with undo shipment and with posting transfer shipment.

        // Setup: Create and post sales and purchase order and undo sales shipment.Create and release transfer order.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesLine."Document Type"::Order,
          Customer."No.", Location.Code, LibraryInventory.CreateItem(Item), Quantity);
        PostedShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        UndoSalesShipment(PostedShipmentNo, Item."No.");
        CreateAndReleaseTransferOrder(TransferHeader, Location.Code, LocationRed.Code, Item."No.", Quantity, false);

        // Exercise: Post transfer order as ship.
        asserterror LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // Verify: Verifying inventory error.
        Assert.ExpectedError(StrSubstNo(ItemInventoryInErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckInventoryErrorOnTransferOrderMultipleLinesWithUndoShipment()
    var
        ItemX: Record Item;
        ItemY: Record Item;
        TransferHeader: Record "Transfer Header";
        Quantity: Decimal;
        PostedShipmentNo: Code[20];
    begin
        // [FEATURE] [Undo Shipment] [Transfer Order]
        // [SCENARIO 362491] Verify inventory error with Undo Shipment and Posting Transfer Order for multiple lines
        Initialize();

        // [GIVEN] Item "X" with Inventory and Item "Y" without Inventory
        Quantity := LibraryRandom.RandInt(10);
        LibraryInventory.CreateItem(ItemX);
        CreateAndPostItemJournalLine(ItemX."No.", Quantity + 1, LocationOrange.Code, '', false);
        LibraryInventory.CreateItem(ItemY);

        // [GIVEN] Create and post Sales Order for both Items "X" and "Y"
        PostedShipmentNo := CreateAndPostSalesOrderWithTwoLines(ItemX."No.", ItemY."No.", LocationOrange.Code, Quantity);

        // [GIVEN] Undo Sales Shipment for Item "Y"
        UndoSalesShipment(PostedShipmentNo, ItemY."No.");

        // [GIVEN] Create and release Transfer Order for "X" and "Y"
        CreateAndReleaseTransferOrderWithTwoLines(
          TransferHeader, LocationOrange.Code, LocationRed.Code, ItemX."No.", ItemY."No.", Quantity);

        // [WHEN] Post Transfer Order as Ship
        asserterror LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [THEN] Verifying inventory error
        Assert.ExpectedError(StrSubstNo(ItemInventoryInErr, ItemY."No."));
    end;

    local procedure FindBinsAndSetLocationParemeters(var Bin: array[3] of Record Bin; var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
        ShipmentBin: Record Bin;
    begin
        LibraryWarehouse.FindBin(ShipmentBin, Location.Code, '', 4);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        Location.Validate("Require Shipment", true);
        Location.Validate("Shipment Bin Code", ShipmentBin.Code);
        Location.Modify(true);
        LibraryWarehouse.FindBin(Bin[1], Location.Code, '', 1);
        LibraryWarehouse.FindBin(Bin[2], Location.Code, '', 2);
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, LibraryUtility.GenerateGUID(), '', '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure QtyToShipInTransferOrderAfterInvPick()
    var
        Item: Record Item;
        Item2: Record Item;
        TransferHeaderNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup and Exercise: Create 2 items, update the inventory for the Item1, create Transfer Order, create Inventory Pick
        Quantity := LibraryRandom.RandDecInRange(3, 10, 2);
        TransferHeaderNo :=
          CreateAndPostInvPickFromTransferOrderForTwoItems(
            LibraryInventory.CreateItem(Item), LibraryInventory.CreateItem(Item2), Quantity, 0, Quantity);

        // Verify: Qty. to Ship is correct in Transfer Order for Item2
        // Inventory Pick is not created for Item2 because there is no Item2 in Inventory,
        // So now, for Item2, Qty. to Ship = Quantity, Quantity Shipped = 0
        VerifyTransferOrderLine(TransferHeaderNo, Item2."No.", Quantity, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure QtyToReceiveInTransferOrderAfterInvPutaway()
    var
        Item: Record Item;
        Item2: Record Item;
        TransferHeaderNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create 2 items, update the inventory for the Item1 and Item2, create Transfer Order, create Inventory Pick
        Quantity := LibraryRandom.RandDecInRange(3, 10, 2);
        TransferHeaderNo :=
          CreateAndPostInvPickFromTransferOrderForTwoItems(
            LibraryInventory.CreateItem(Item), LibraryInventory.CreateItem(Item2), Quantity, Quantity, Quantity);

        // Update the Qty to Receive in the Transfer Order for Item2
        UpdateTransferOrderLineForQtyToReceive(TransferHeaderNo, Item2."No.", 0);

        // Exercise: Create and Post Inventory Put Away from Transfer Order.
        CreateAndPostInvPutAwayFromTransferOrder(TransferHeaderNo);

        // Verify: Qty. to Receive is correct in Transfer Order for Item2
        // Inventory Put-away is not created for Item2 because we updated the Qty. to Receive = 0 before create Inv. Put-away
        // So now, for Item2, Qty. to Ship = Quantity, Quantity Shipped = 0
        VerifyTransferOrderLineForQtyToReceive(TransferHeaderNo, Item2."No.", Quantity, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionPopulatedOnTransferOrderLine()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: array[2] of Record "Dimension Value";
        Quantity: Decimal;
    begin
        // Setup: Create Item and update the inventory.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2); // Taking Random value for Quantity.
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationBlue.Code, '', false); // Taking Blank for Bin Code and false for Item Tracking.

        // Create a Transfer Header and set the Dimension Value
        CreateTransferHeaderAndUpdateDimension(TransferHeader, DimensionValue);

        // Exercise: Update the Item No. and Quantity in Transfer Line
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Quantity);

        // Verify: Dimension Code is filled in transfer line
        TransferLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        TransferLine.TestField("Shortcut Dimension 2 Code", DimensionValue[2].Code);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingEditSeveralLinesLOT')]
    [Scope('OnPrem')]
    procedure RegisterTwoPickLinesWithSpecificQtyAndChangedLOT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        WhseActivityLine: Record "Warehouse Activity Line";
        OrderQuantity: Decimal;
        QtyPerLOT: array[2] of Decimal;
        AutoReserveLotNo: array[2] of Code[20];
        NewPickLineQty: array[2] of Decimal;
        NewLotNo: array[2] of Code[20];
        i: Integer;
    begin
        // Verify Reservation Entries after register pick lines with changing LOT and pick line's qty
        Initialize();
        OrderQuantity := 9; // Sales Order Item Qty
        QtyPerLOT[1] := 5; // Invt. Positive Adj. for 20 Qty: 5 Qty for each LOT
        QtyPerLOT[2] := 1; // Invt. Positive Adj. for 4 Qty: 1 Qty for each LOT
        NewPickLineQty[1] := 6; // new Pick Line1 Qty
        NewPickLineQty[2] := 3; // new Pick Line2 Qty
        AutoReserveLotNo[1] := StrSubstNo(LotNoTxt, 1);
        AutoReserveLotNo[2] := StrSubstNo(LotNoTxt, 2);
        NewLotNo[1] := StrSubstNo(LotNoTxt, 3);
        NewLotNo[2] := StrSubstNo(LotNoTxt, 4);

        CreateItemWithLOTAndAutoReserve(Item);

        for i := 1 to ArrayLen(QtyPerLOT) do begin
            CreatePostPositiveInvtAdjWithSeveralLOTs(Item, AutoReserveLotNo, QtyPerLOT[i]);
            CreatePostPositiveInvtAdjWithSeveralLOTs(Item, NewLotNo, QtyPerLOT[i]);
        end;
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationWhite2.Code, '', Item."No.", '', OrderQuantity, 0, false, false);
        SalesLine.AutoReserve();

        // Verify auto reserve status: 5 Qty for 'L01' LOT; 4 Qty for 'L02' LOT
        VerifyReservEntryLineExist(LocationWhite2.Code, Item."No.", AutoReserveLotNo[1], 5);
        VerifyReservEntryLineExist(LocationWhite2.Code, Item."No.", AutoReserveLotNo[2], 4);

        CreatePickFromWhseShipment(SalesHeader);

        // Change pick lines LOTs to following:
        // pick line1: 6 Qty for 'L03' LOT
        // pick line2: 3 Qty for 'L04' LOT
        SplitWhseActivityLines(SalesHeader."No.", NewPickLineQty);
        for i := 1 to ArrayLen(NewPickLineQty) do
            UpdatePickLinesLot(SalesHeader."No.", NewPickLineQty[i], NewLotNo[i]);
        RegisterWarehouseActivity(
          WhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WhseActivityLine."Activity Type"::Pick);

        // Reserve status should be: 5 Qty for 'L03' LOT; 1 Qty for 'L03' LOT; 3 Qty for 'L04' LOT
        VerifyReservEntryLineExist(LocationWhite2.Code, Item."No.", NewLotNo[1], 5);
        VerifyReservEntryLineExist(LocationWhite2.Code, Item."No.", NewLotNo[1], 1);
        VerifyReservEntryLineExist(LocationWhite2.Code, Item."No.", NewLotNo[2], 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostedTransferShipmentPostingDate()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        // [FEATURE] [Posting Date] [Transfer Order] [Warehouse Shipment]
        // [SCENARIO 372023] Posting date is updated in Posted Transfer Shipment if the Posting Date of the Whse. Shipment is less than the Posting Date of the Transfer Order
        Initialize();

        SetRequirePickOnLocation(LocationBlue, false);

        // [GIVEN] Transfer Order "TO" with Posting Date = "X"
        CreateAndReleaseTransferOrderWithPostingDate(TransferHeader);

        // [GIVEN] Warehouse Shipment "WS" for "TO" with Posting Date = "Y", "Y" < "X"
        CreateWarehouseShipmentFromTransferOrderWithPostingDate(WarehouseShipmentHeader, TransferHeader);

        // [WHEN] Post "WS"
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        // [THEN] Posted Transfer Shipment is created with Posting Date = "Y"
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        TransferShipmentHeader.FindFirst();
        TransferShipmentHeader.TestField("Posting Date", WarehouseShipmentHeader."Posting Date");

        // Tear Down
        SetRequirePickOnLocation(LocationBlue, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerSimple')]
    [Scope('OnPrem')]
    procedure CheckPostedSalesShipmentPostingDate()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [Posting Date] [Sales Order] [Warehouse Shipment]
        // [SCENARIO 372023] Posting date is updated in Posted Sales Shipment if the Posting Date of the Whse. Shipment is less than the Posting Date of the Sales Order
        Initialize();

        SetRequirePickOnLocation(LocationBlue, false);

        // [GIVEN] Sales Order "SO" with Posting Date = "X"
        CreateAndReleaseSalesOrderWithPostingDate(SalesHeader, SalesHeader."Document Type"::Order, LocationBlue.Code);

        // [GIVEN] Warehouse Shipment "WS" for "SO" with Posting Date = "Y", "Y" < "X"
        CreateWarehouseShipmentFromSOWithPostingDate(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Post "WS"
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        // [THEN] Posted Sales Shipment is created with Posting Date = "Y"
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        SalesShipmentHeader.TestField("Posting Date", WarehouseShipmentHeader."Posting Date");

        // Tear Down
        SetRequirePickOnLocation(LocationBlue, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerSimple')]
    [Scope('OnPrem')]
    procedure CheckPostedReturnShipmentPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // [FEATURE] [Posting Date] [Purchase Return Order] [Warehouse Shipment]
        // [SCENARIO 372023] Posting date is updated in Posted Return Shipment if the Posting Date of the Whse. Shipment is less than the Posting Date of the Purchase Return Order
        Initialize();

        SetRequirePickOnLocation(LocationBlue, false);

        // [GIVEN] Purchase Return Order "PRO" with Posting Date = "X"
        CreateAndReleasePurchaseOrderWithPostingDate(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LocationBlue.Code);

        // [GIVEN] Warehouse Shipment "WS" for "PRO" with Posting Date = "Y", "Y" < "X"
        CreateWarehouseShipmentFromPurchReturnOrderWithPostingDate(WarehouseShipmentHeader, PurchaseHeader);

        // [WHEN] Post "WS"
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        // [THEN] Posted Return Shipment is created with Posting Date = "Y"
        ReturnShipmentHeader.SetRange("Return Order No.", PurchaseHeader."No.");
        ReturnShipmentHeader.FindFirst();
        ReturnShipmentHeader.TestField("Posting Date", WarehouseShipmentHeader."Posting Date");

        // Tear Down
        SetRequirePickOnLocation(LocationBlue, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerSimple')]
    [Scope('OnPrem')]
    procedure CheckPostedPurchaseReceiptPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        // [FEATURE] [Posting Date] [Purchase Order] [Warehouse Receipt]
        // [SCENARIO 372023] Posting date is updated in Posted Purchase Receipt if the Posting Date of the Whse. Receipt is less than the Posting Date of the Purchase Order
        Initialize();

        // [GIVEN] Purchase Order "PO" with Posting Date = "X"
        CreateAndReleasePurchaseOrderWithPostingDate(PurchaseHeader, PurchaseHeader."Document Type"::Order, LocationWhite.Code);

        // [GIVEN] Warehouse Receipt "WR" for "PO" with Posting Date = "Y", "Y" < "X"
        CreateWarehouseReceiptFromPurchOrderWithPostingDate(WarehouseReceiptHeader, PurchaseHeader);

        // [WHEN] Post "WR"
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        // [THEN] Posted Purchase Receipt is created with Posting Date = "Y"
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        PurchRcptHeader.TestField("Posting Date", WarehouseReceiptHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerSimple')]
    [Scope('OnPrem')]
    procedure CheckPostedSalesReceiptPostingDate()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        // [FEATURE] [Posting Date] [Sales Return Order] [Warehouse Receipt]
        // [SCENARIO 372023] Posting date is updated in Posted Return Receipt if the Posting Date of the Whse. Receipt is less than the Posting Date of the Sales Return Order
        Initialize();

        // [GIVEN] Sales Return Order "SRO" with Posting Date = "X"
        CreateAndReleaseSalesOrderWithPostingDate(SalesHeader, SalesHeader."Document Type"::"Return Order", LocationWhite.Code);

        // [GIVEN] Warehouse Receipt "WR" for "SRO" with Posting Date = "Y", "Y" < "X"
        CreateWarehouseReceiptFromSalesOrderWithPostingDate(WarehouseReceiptHeader, SalesHeader);

        // [WHEN] Post "WR"
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        // [THEN] Posted Return Receipt is created with Posting Date = "Y"
        ReturnReceiptHeader.SetRange("Return Order No.", SalesHeader."No.");
        ReturnReceiptHeader.FindFirst();
        ReturnReceiptHeader.TestField("Posting Date", WarehouseReceiptHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPostedTransferReceiptPostingDate()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        TransferHeader: Record "Transfer Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        // [FEATURE] [Posting Date] [Transfer Order] [Warehouse Receipt]
        // [SCENARIO 372023] Posting date is updated in Posted Transfer Receipt if the Posting Date of the Whse. Receipt is less than the Posting Date of the Transfer Order
        Initialize();

        // [GIVEN] Transfer Order "TO" with Posting Date = "X"
        CreateAndReleaseTransferOrderWithPostingDate(TransferHeader);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Warehouse Receipt "WR" for "TO" with Posting Date = "Y", "Y" < "X"
        CreateWarehouseReceiptFromTransferOrderWithPostingDate(WarehouseReceiptHeader, TransferHeader);

        // [WHEN] Post "WR"
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        // [THEN] Posted Transfer Receipt is created with Posting Date = "Y"
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        TransferReceiptHeader.FindFirst();
        TransferReceiptHeader.TestField("Posting Date", WarehouseReceiptHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPostedSalesShipmentForPickedItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Bin: Record Bin;
        Qty: Decimal;
    begin
        // [FEATURE] [Undo Shipment] [Warehouse Pick]
        // [SCENARIO 380265] Undo Sales Shipment for partially picked Item sets "Qty. Shipped" and "Qty. Shipped (Base)" in Warehouse Shipment Line to zero.

        Initialize();

        // [GIVEN] Item is on hand in Warehouse Location.
        LibraryInventory.CreateItem(Item);
        Qty := 4 * LibraryRandom.RandIntInRange(10, 20);
        FindBinWithBinTypeCode(Bin, LocationWhite2.Code, false, true, true);  // Find PICK Bin.
        UpdateInventoryUsingWhseJournal(Bin, Item, Qty, '', Item."Base Unit of Measure", false);

        // [GIVEN] Create Sales Order, release, create Warehouse Shipment, create Pick, then pick partially, register and delete pick.
        CreatePickFromSalesOrder(SalesHeader, LocationWhite2.Code, Item."No.", Qty / 2, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Qty. to Handle", Qty / 4);
                WarehouseActivityLine.Modify();
            until WarehouseActivityLine.Next() = 0;

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        DeletePick(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [GIVEN] Post Warehouse Shipment as Ship.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [WHEN] Undo Sales Shipment.
        LibraryVariableStorage.Enqueue(UndoShipmentConfirmMsg);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(UndoPickedShipmentConfirmMsg);  // Enqueue for ConfirmHandler.
        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
        // [THEN] For Warehouse Shipment Line: "Qty. Shipped" and "Qty. Shipped (Base)" equals to 0.
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentLine.TestField("Qty. Shipped", 0);
        WarehouseShipmentLine.TestField("Qty. Shipped (Base)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingAgentServicesAreDeletedOnShippingAgentDeletion()
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        PeriodLength: DateFormula;
    begin
        // [FEATURE] [Shipping Agent]
        // [SCENARIO 380407] Shipping Agent Services are deleted on Shipping Agent deletion.
        Initialize();

        // [GIVEN] Shipping Agent with several Shipping Agent Services.
        Evaluate(PeriodLength, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));
        CreateShippingAgentWithServices(ShippingAgent, ShippingAgentServices, PeriodLength, LibraryRandom.RandInt(10));

        // [WHEN] Delete the Shipping Agent.
        ShippingAgent.Delete(true);

        // [THEN] Shipping Agent Services for the Shipping Agent are deleted.
        ShippingAgentServices.SetRange("Shipping Agent Code", ShippingAgent.Code);
        Assert.RecordIsEmpty(ShippingAgentServices);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentForShipmentLinesWithQuantityZero()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        PostedShipmentNo: Code[20];
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 378965] Undo Sales Shipment Job should not consider Shipment Lines with Quantity = 0
        Initialize();

        // [GIVEN] Sales Order with two Lines: "L1" and "L2"
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [GIVEN] Set "Qty. to Ship" on "L2" to 0
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);

        // [GIVEN] Post Shipment for Sales Order
        PostedShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Undo Shipment
        UndoSalesShipment(PostedShipmentNo, Item."No.");

        // [THEN] Sales Shipment Line "L2" is not considered for Undo Job
        SalesShipmentLine.SetRange("No.", Item."No.");
        SalesShipmentLine.SetRange(Quantity, 0);
        Assert.AreEqual(1, SalesShipmentLine.Count, UndoSalesShipmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentExternalDocumentNoIsEqualToSalesHeaderExternalDocumentNo()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ExternalDocumentNo: Code[35];
        ExternalDocumentNoLength: Integer;
    begin
        // [FEATURE] [Warehouse Shipment]
        // [SCENARIO 380429] "External Document No." in Warehouse Shipment must be same as in Source Sales Order
        Initialize();

        // [GIVEN] Sales Order with not blank "External Document No."
        ExternalDocumentNoLength := MaxStrLen(SalesHeader."External Document No.");
        ExternalDocumentNo := CopyStr(LibraryUtility.GenerateRandomText(ExternalDocumentNoLength), 1, ExternalDocumentNoLength);
        CreateAndReleaseSalesOrderWithExternalDocumentNo(SalesHeader, LocationGreen.Code, ExternalDocumentNo);

        // [WHEN] Create Warehouse Shipment for this Sales Order
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] "External Document No." in Warehouse Shipment must be same
        FindWarehouseShipmentHeaderBySalesHeader(WarehouseShipmentHeader, SalesHeader);
        Assert.AreEqual(ExternalDocumentNo, WarehouseShipmentHeader."External Document No.", WhsShpmtHeaderExternalDocumentNoIsWrongErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentExternalDocumentNoIsEqualToPurchaseHeaderVendorShipmentNo()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ExternalDocumentNo: Code[35];
        ExternalDocumentNoLength: Integer;
    begin
        // [FEATURE] [Warehouse Shipment]
        // [SCENARIO 380429] "External Document No." in Warehouse Shipment must be same as "Vendor Shipment No." of Source Purchase Return Order
        Initialize();

        // [GIVEN] Purchase Return Order with not blank "Vendor Shipment No."
        ExternalDocumentNoLength := MaxStrLen(PurchaseHeader."Vendor Shipment No.");
        ExternalDocumentNo := CopyStr(LibraryUtility.GenerateRandomText(ExternalDocumentNoLength), 1, ExternalDocumentNoLength);
        CreateAndReleasePurchaseReturnOrderWithVendorShipmentNo(PurchaseHeader, LocationGreen.Code, ExternalDocumentNo);

        // [WHEN] Create Warehouse Shipment for this Purchase Return Order
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);

        // [THEN] "External Document No." in Warehouse Shipment must be same as "Vendor Shipment No." of Source Purchase Return Order
        FindWarehouseShipmentHeaderByPurchaseHeader(WarehouseShipmentHeader, PurchaseHeader);
        Assert.AreEqual(ExternalDocumentNo, WarehouseShipmentHeader."External Document No.", WhsShpmtHeaderExternalDocumentNoIsWrongErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentExternalDocumentNoIsEqualToTransferHeaderExternalDocumentNo()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ExternalDocumentNo: Code[35];
        ExternalDocumentNoLength: Integer;
    begin
        // [FEATURE] [Warehouse Shipment]
        // [SCENARIO 380429] "External Document No." in Warehouse Shipment must be same as in Source Transfer Order
        Initialize();

        // [GIVEN] Transfer Order with not blank "External Document No."
        ExternalDocumentNoLength := MaxStrLen(TransferHeader."External Document No.");
        ExternalDocumentNo := CopyStr(LibraryUtility.GenerateRandomText(ExternalDocumentNoLength), 1, ExternalDocumentNoLength);
        CreateAndReleaseTransferOrderWithExternalDocumentNo(TransferHeader, LocationGreen.Code, LocationWhite.Code, ExternalDocumentNo);

        // [WHEN] Create Warehouse Shipment for this Transfer Order
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [THEN] "External Document No." in Warehouse Shipment must be same as "External Document No." of Transfer Order
        FindWarehouseShipmentHeaderByTransferHeader(WarehouseShipmentHeader, TransferHeader);
        Assert.AreEqual(ExternalDocumentNo, WarehouseShipmentHeader."External Document No.", WhsShpmtHeaderExternalDocumentNoIsWrongErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseReceiptVendorShipmentNoIsEqualToPurchaseHeaderVendorShipmentNo()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        VendorShipmentNo: Code[35];
        ExternalDocumentNoLength: Integer;
    begin
        // [FEATURE] [Warehouse Receipt]
        // [SCENARIO 380429] "Vendor Shipment No." in Warehouse Receipt must be the same as in source Purchase Order
        Initialize();

        // [GIVEN] Purchase Order with not blank "Vendor Shipment No."
        ExternalDocumentNoLength := MaxStrLen(PurchaseHeader."Vendor Shipment No.");
        VendorShipmentNo := CopyStr(LibraryUtility.GenerateRandomText(ExternalDocumentNoLength), 1, ExternalDocumentNoLength);
        CreateAndReleasePurchaseOrderWithVendorShipmentNo(PurchaseHeader, LocationGreen.Code, VendorShipmentNo);

        // [WHEN] Create Warehouse Receipt for this Purchase Order
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] "Vendor Shipment No." in Warehouse Receipt must be the same as in source Purchase Order
        FindWarehouseReceiptHeaderByPurchaseHeader(WarehouseReceiptHeader, PurchaseHeader);
        Assert.AreEqual(VendorShipmentNo, WarehouseReceiptHeader."Vendor Shipment No.", WhsRcptHeaderVendorShpmntNoIsWrongErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,GetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PartiallyPostedShipmentCanBeCompletedIfInvoiceForShippedQtyIsCreatedWithSameLot()
    var
        Item: Record Item;
        SalesHeaderOrder: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        LotNo: Code[50];
        Qty: Decimal;
        ShipQty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Warehouse Shipment] [Sales Invoice]
        // [SCENARIO 382336] Available quantity to ship of a given lot should not be reduced by outstanding tracked sales invoice for previously shipped quantity.
        Initialize();

        // [GIVEN] Lot-tracked Item.
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);

        // [GIVEN] Location with required shipment.
        // [GIVEN] Sales Order for "X" units of the item. Lot No. = "L".
        // [GIVEN] Sales Order is partially shipped. Shipped quantity = "Y" < "X".
        Qty := LibraryRandom.RandIntInRange(20, 30);
        ShipQty := LibraryRandom.RandInt(10);
        CreateAndPartiallyPostSalesShipmentForLotTrackedItem(SalesHeaderOrder, LotNo, Item."No.", Qty, ShipQty);

        // [GIVEN] Sales invoice for the shipped "Y" units.
        CreateSalesInvoiceForPostedShipment(SalesHeaderOrder);

        // [GIVEN] Item tracking lines page for the partially posted warehouse shipment is opened.
        // [GIVEN] Available quantity to ship is updated by viewing the item tracking summary for lot "L".
        SelectAvailableLotOnWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeaderOrder."No.", Qty);

        // [WHEN] Ship the remaining ("X" - "Y") quantity.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeaderOrder."No.");
        // [THEN] The sales order is completely shipped.
        SalesHeaderOrder.Find();
        SalesHeaderOrder.CalcFields("Completely Shipped");
        SalesHeaderOrder.TestField("Completely Shipped", true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PartiallyPostedShipmentShouldConsiderUnrelatedDemandWithSameLot()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        LotNo: Code[50];
        Qty: Decimal;
        ShipQty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Warehouse Shipment]
        // [SCENARIO 382336] Available quantity to ship of a given lot should be reduced by other invoice if it has same lot tracking and does not relate to previously shipped quantity.
        Initialize();
        UpdateShipmentPostingPolicyOnWarehouseSetup();

        // [GIVEN] Lot-tracked Item.
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);

        // [GIVEN] Location with required shipment.
        // [GIVEN] Sales Order for "X" units of the item. Lot No. = "L".
        // [GIVEN] Sales Order is partially shipped. Shipped quantity = "Y" < "X".
        Qty := LibraryRandom.RandIntInRange(20, 30);
        ShipQty := LibraryRandom.RandInt(10);
        CreateAndPartiallyPostSalesShipmentForLotTrackedItem(SalesHeader, LotNo, Item."No.", Qty, ShipQty);

        FindSalesLine(SalesLine, SalesHeader);
        CreateSalesInvoiceWithLotTracking(SalesLine."Sell-to Customer No.", SalesLine."Location Code", Item."No.", LotNo, ShipQty);

        // [GIVEN] Item tracking lines page for the partially posted warehouse shipment is opened.
        // [GIVEN] Available quantity to ship is updated by viewing the item tracking summary for lot "L".
        SelectAvailableLotOnWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Qty);

        // [WHEN] Ship the remaining ("X" - "Y") quantity.
        asserterror PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [THEN] Error is raised reading that some of being shipped quantity is not tracked.
        Assert.ExpectedError(
          StrSubstNo(
            WrongQtyToHandleInTrackingSpecErr,
            Item."No.", Qty - ShipQty * 2, Qty - ShipQty, '', LotNo, ''));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShipmentCreatesValueEntryWithCurrentUserId()
    var
        Item: Record Item;
        PostedShipmentNo: Code[20];
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO 203164] "User ID" field on corrective Value Entry created by Undo Shipment procedure should be populated with USERID of the current user.
        Initialize();

        // [GIVEN] Posted sales shipment.
        LibraryInventory.CreateItem(Item);
        PostedShipmentNo := CreateAndPostSalesOrder('', Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] "User ID" is changed from USERID to "XXX" on Value Entry representing the shipment.
        UpdateValueEntryUserID(Item."No.");

        // [WHEN] Undo the shipment.
        LibraryVariableStorage.Enqueue(UndoShipmentConfirmMsg);
        UndoSalesShipment(PostedShipmentNo, Item."No.");

        // [THEN] New Value Entry related to the reversed shipment has "User ID" = USERID.
        VerifyValueEntryUserID(Item."No.", UserId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseShpmtWithShippingAdviceCompleteAndServiceItem()
    var
        ItemInventory: Record Item;
        ItemService: Record Item;
        ItemNonStock: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Shipment] [Shipping Advice]
        // [SCENARIO 252330] Whse Shipment must be created and posted when Sales Order contains one line with Inventory item and one with Service item. Shipping Advice is Complete.

        Initialize();

        // [GIVEN] Create location with Require Pick and Require Shipment
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);

        // [GIVEN] Create inventory type Item with some stock
        Quantity := LibraryRandom.RandInt(10);
        CreateItemWithInventory(ItemInventory, Location.Code, Quantity);

        // [GIVEN] Create Item of a service type
        LibraryInventory.CreateItem(ItemService);
        ItemService.Validate(Type, ItemService.Type::Service);
        ItemService.Modify(true);

        // [GIVEN] Create Item of a Non-Inventory type
        LibraryInventory.CreateNonInventoryTypeItem(ItemNonStock);

        // [GIVEN] Create Sales Order with two lines: 1 inventory and 1 non-inventory
        CreateSalesOrderWithInventoryServiceLinesAndNonStockLines(
          SalesHeader, Location.Code, ItemInventory."No.", LibraryRandom.RandInt(Quantity), ItemService."No.", 1, ItemNonStock."No.", 1);

        // [WHEN] Trying to create Whse Shipment
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] Whse Shipment is created. No errors occured.
        WarehouseShipmentHeader.Get(LibraryWarehouse.FindWhseShipmentNoBySourceDoc(37, 1, SalesHeader."No."));

        // [GIVEN] Create and register Whse Pick in order to post Shipment later
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        GetPickByWhseShpmtNo(WarehouseActivityHeader, WarehouseShipmentHeader."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post the warehouse shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // [THEN] Both inventory and non-inventory items are shipped and invoiced.
        Assert.IsFalse(SalesHeader.Find(), '');

        // [THEN] 1 Posted Sales Shipmnt created; 1 Posted Sales Invoice created; no errors occured
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.AreEqual(1, SalesShipmentHeader.Count, PostedShpmtsQtyErr);
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.AreEqual(1, SalesInvoiceHeader.Count, PostedInvoicesQtyErr);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingEditSeveralLinesLOT,ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure TransferWhseShipmentWithPickedAndNotPickedLotIsShippedAndTrackingAutoUpdated()
    var
        Item: Record Item;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        LotNos: array[2] of Code[20];
        LotQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Transfer Order] [Warehouse Shipment] [Pick] [Item Tracking]
        // [SCENARIO 253142] Warehouse shipment from transfer order with one lot fully picked and another lot not picked, can only be shipped for picked lot. Item tracking is automatically updated after the posting.
        Initialize();

        // [GIVEN] Lot-tracked item. Lot nos. = "L1", "L2".
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
        LotQty := LibraryRandom.RandIntInRange(10, 20);

        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true);

        // [GIVEN] "X" pcs of each lot are in inventory on location with directed put-away and pick.
        UpdateInventoryWithItemTrackingUsingWhseJournal(Bin, Item, LotNos, LotQty);

        // [GIVEN] Transfer order with one line for 2 * "X" pcs. Item tracking is defined on the line - "X" pcs of "L1", "X" pcs of "L2".
        // [GIVEN] Warehouse shipment for the transfer order.
        CreateWarehouseShipmentFromTransferOrderWithLotNo(
          TransferHeader, LocationWhite.Code, LocationRed.Code, Item."No.", LotQty * ArrayLen(LotNos));
        FindWarehouseShipmentHeaderByTransferHeader(WarehouseShipmentHeader, TransferHeader);

        // [GIVEN] Warehouse pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] Set quantity to handle for lot "L1" = 0, lot "L2" = "X" and register warehouse pick.
        AutoFillQtyToHandleOnWhseActivity(
          WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        WarehouseActivityLine.SetRange("Lot No.", LotNos[1]);
        UpdateQuantityToHandleOnWarehouseActivityLine(
          WarehouseActivityLine,
          WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick, 0, true);

        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Outbound Transfer",
          TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [WHEN] Post the warehouse shipment that is now partially picked.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // [THEN] Lot "L1" is not shipped.
        FilterItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Transfer, LotNos[1]);
        Assert.RecordIsEmpty(ItemLedgerEntry);

        // [THEN] Lot "L2" is shipped in full ("X" pcs).
        FilterItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Transfer, LotNos[2]);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, -LotQty);

        // [THEN] Quantity to handle in the item tracking for lot "L1" remained "X".
        FilterReservEntryForTransferLine(ReservationEntry, TransferHeader."No.", Item."No.", LotNos[1]);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Qty. to Handle (Base)", -LotQty);

        // [THEN] Item tracking for lot "L2" is deleted, as the lot is fully handled.
        FilterReservEntryForTransferLine(ReservationEntry, TransferHeader."No.", Item."No.", LotNos[2]);
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingEditSeveralLinesLOT,ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure TransferWhseShipmentWithTwoPartiallyPickedLotsIsShippedAndTrackingAutoUpdated()
    var
        Item: Record Item;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        LotNos: array[2] of Code[20];
        LotQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Transfer Order] [Warehouse Shipment] [Pick] [Item Tracking]
        // [SCENARIO 253142] Warehouse shipment from transfer order with two partially picked lots, can only be shipped for picked quantity of each lot. Item tracking is automatically updated after the posting.
        Initialize();

        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true);

        // [GIVEN] Lot-tracked item. Lot nos. = "L1", "L2".
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
        LotQty := 2 * 3 * LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] 12 pcs of each lot are in inventory on location with directed put-away and pick.
        UpdateInventoryWithItemTrackingUsingWhseJournal(Bin, Item, LotNos, LotQty);

        // [GIVEN] Transfer order with one line for 24 pcs. Item tracking is defined on the line - 12 pcs of "L1", 12 pcs of "L2".
        // [GIVEN] Warehouse shipment for the transfer order.
        CreateWarehouseShipmentFromTransferOrderWithLotNo(
          TransferHeader, LocationWhite.Code, LocationRed.Code, Item."No.", LotQty * ArrayLen(LotNos));
        FindWarehouseShipmentHeaderByTransferHeader(WarehouseShipmentHeader, TransferHeader);

        // [GIVEN] Warehouse pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] Set quantity to handle for lot "L1" = 6, lot "L2" = 4 and register warehouse pick.
        WarehouseActivityLine.SetRange("Lot No.", LotNos[1]);
        UpdateQuantityToHandleOnWarehouseActivityLine(
          WarehouseActivityLine,
          WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick, LotQty / 2, true);

        WarehouseActivityLine.SetRange("Lot No.", LotNos[2]);
        UpdateQuantityToHandleOnWarehouseActivityLine(
          WarehouseActivityLine,
          WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick, LotQty / 3, true);

        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Outbound Transfer",
          TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [WHEN] Post the warehouse shipment that is now partially picked.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // [THEN] 6 pcs of lot "L1" are shipped.
        FilterItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Transfer, LotNos[1]);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, -LotQty / 2);

        // [THEN] 4 pcs of lot "L2" are shipped.
        FilterItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Transfer, LotNos[2]);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, -LotQty / 3);

        // [THEN] Quantity to handle in the item tracking for lot "L1" is equal to 6 (12 total - 6 shipped).
        FilterReservEntryForTransferLine(ReservationEntry, TransferHeader."No.", Item."No.", LotNos[1]);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Qty. to Handle (Base)", -(LotQty - LotQty / 2));

        // [THEN] Quantity to handle in the item tracking for lot "L1" is equal to 8 (12 total - 4 shipped).
        FilterReservEntryForTransferLine(ReservationEntry, TransferHeader."No.", Item."No.", LotNos[2]);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Qty. to Handle (Base)", -(LotQty - LotQty / 3));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferWhseShipmentIsShippedWithoutPickWhenPickNotRequiredOnLocation()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNos: array[2] of Code[20];
        LotQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Transfer Order] [Warehouse Shipment] [Item Tracking]
        // [SCENARIO 253142] Warehouse shipment from transfer order can be shipped without additional warehouse handling, if pick is not required on location.
        Initialize();

        // [GIVEN] WMS location "L" with two bins "B1", "B2" and required shipment. Pick is not required.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, true);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Lot-tracked item. Lot nos. = "L1", "L2".
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
        LotQty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] "X" pcs of each lot are in inventory in bin "B1" on location "L".
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Multiple Lines");
        LibraryVariableStorage.Enqueue(ArrayLen(LotNos));
        LibraryVariableStorage.Enqueue(LotQty);
        for i := 1 to ArrayLen(LotNos) do
            LibraryVariableStorage.Enqueue(LotNos[i]);
        CreateAndPostItemJournalLine(Item."No.", LotQty * ArrayLen(LotNos), Location.Code, Bin[1].Code, true);

        // [GIVEN] Transfer order with one line for 2 * "X" pcs. Item tracking is defined on the line - "X" pcs of "L1", "X" pcs of "L2".
        // [GIVEN] Warehouse shipment for the transfer order. Set "Bin Code" on the shipment = "B2".
        CreateWarehouseShipmentFromTransferOrderWithLotNo(
          TransferHeader, Location.Code, LocationRed.Code, Item."No.", LotQty * ArrayLen(LotNos));
        FindWarehouseShipmentHeaderByTransferHeader(WarehouseShipmentHeader, TransferHeader);
        LibraryVariableStorage.Enqueue(ChangedBinCodeOnWhseShptTxt);
        WarehouseShipmentHeader.Validate("Bin Code", Bin[2].Code);
        WarehouseShipmentHeader.Modify(true);

        // [WHEN] Post the warehouse shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // [THEN] Both lots are shipped in full.
        for i := 1 to ArrayLen(LotNos) do begin
            FilterItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Transfer, LotNos[i]);
            ItemLedgerEntry.FindFirst();
            ItemLedgerEntry.TestField(Quantity, -LotQty);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSourceDocumentsOnWarehouseReceiptDoNotFillQtyToHandle()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 302715] Quantity to Receive is not filled for Warehouse Receipt lines in case "Do Not Fill Qty. to Handle" is set on "Filters to Get Source Docs" report.
        Initialize();

        // [GIVEN] Sales Return Order, Purchase Order, Posted Transfer Order with the same Location code "White".
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDecInRange(10, 20, 2);
        CreateAndReleaseSalesReturnOrder(SalesHeader, Item."No.", Quantity);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", Quantity);

        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationOrange.Code, '', false);
        CreateAndReleaseTransferOrder(TransferHeader, LocationOrange.Code, LocationWhite.Code, Item."No.", Quantity, false);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [WHEN] Create Warehouse Receipt Header and get source documents. "Do Not Fill Qty. to Handle" is set.
        GetSourceDocumentOnWarehouseReceipt(WarehouseReceiptHeader, LocationWhite.Code, true);

        // [THEN] "Qty. to Receive" is not filled for Warehouse Receipt Lines.
        VerifyWarehouseReceiptLine(
          WarehouseReceiptLine."Source Document"::"Sales Return Order", SalesHeader."No.", Item."No.", Quantity, 0);
        VerifyWarehouseReceiptLine(
          WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Item."No.", Quantity, 0);
        VerifyWarehouseReceiptLine(
          WarehouseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.", Item."No.", Quantity, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotPostTransferViaInvtPickAfterChangingLotToOneNotAssignedOnSource()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[3] of Code[10];
        LotQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Transfer] [Item Tracking] [Inventory Pick]
        // [SCENARIO 344442] Stan cannot post inventory pick for transfer shipment with item tracking different from what has been assigned on the transfer line.
        Initialize();

        // [GIVEN] Location set up for inventory pick.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Lot-tracked item with "Lot Warehouse Tracking" = TRUE.
        CreateItemTrackingCode(ItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Lots "L1", "L2", "L3".
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();
        LotQty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Post 10 pcs of each lot to the inventory.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Multiple Lines");
        LibraryVariableStorage.Enqueue(ArrayLen(LotNos));
        LibraryVariableStorage.Enqueue(LotQty);
        for i := 1 to ArrayLen(LotNos) do
            LibraryVariableStorage.Enqueue(LotNos[i]);
        CreateAndPostItemJournalLine(Item."No.", LotQty * ArrayLen(LotNos), Location.Code, Bin.Code, true);

        // [GIVEN] Create transfer order for 30 pcs. Assign three lots.
        // [GIVEN] Set "Qty. to Ship" = 10 on the transfer line and zero out "Qty. to Handle" on every lot but "L1".
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Multiple Lines");
        LibraryVariableStorage.Enqueue(ArrayLen(LotNos));
        LibraryVariableStorage.Enqueue(LotQty);
        for i := 1 to ArrayLen(LotNos) do
            LibraryVariableStorage.Enqueue(LotNos[i]);
        CreateAndReleaseTransferOrder(TransferHeader, Location.Code, LocationRed.Code, Item."No.", LotQty * ArrayLen(LotNos), true);
        FindTransferLine(TransferLine, TransferHeader."No.", Item."No.");
        TransferLine.Validate("Qty. to Ship", LotQty);
        TransferLine.Modify(true);

        UpdateQtyToHandleOnItemTrackingLineForTransfer(TransferHeader."No.", Item."No.", LotNos[2], 0);
        UpdateQtyToHandleOnItemTrackingLineForTransfer(TransferHeader."No.", Item."No.", LotNos[3], 0);

        // [GIVEN] Create inventory pick.
        LibraryVariableStorage.Enqueue(InvPickMsg);
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Outbound Transfer", TransferHeader."No.", false, true);

        // [GIVEN] Change lot no. on the pick line from "L1" to "L2".
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.Validate("Lot No.", LotNos[2]);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);

        // [WHEN] Post the inventory pick.
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        asserterror LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] An error of item tracking mismatch is thrown.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(WrongQtyToHandleInTrackingSpecErr, Item."No.", LotQty * 2, LotQty, '', LotNos[2], ''));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostingInvtPickForSalesWithAlternateUoM()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Qty: Decimal;
        QtyPer: Decimal;
        LotNo: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Inventory Pick] [Unit of Measure]
        // [SCENARIO 360085] Posting inventory pick from sales line with item tracking and alternate unit of measure.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);
        QtyPer := LibraryRandom.RandIntInRange(2, 5);

        // [GIVEN] Location set up for inventory pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Lot-tracked item with "Lot Warehouse Tracking" = TRUE.
        // [GIVEN] Create alternate unit of measure "BOX" and set it as a "Sales Unit of Measure".
        CreateItemTrackingCode(ItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPer);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Post two lots to inventory.
        for i := 1 to ArrayLen(LotNo) do begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
            CreateAndPostItemJournalLine(Item."No.", Qty * QtyPer, Location.Code, '', true);
            LotNo[i] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[i]));
        end;

        // [GIVEN] Create sales order, open item tracking and select the two lots.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Location.Code, Item."No.", ArrayLen(LotNo) * Qty);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
        SalesLine.OpenItemTrackingLines();
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create inventory pick from the sales order.
        LibraryVariableStorage.Enqueue(InvPickMsg);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);

        // [WHEN] Post the inventory pick.
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] The sales order is fully shipped.
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);

        // [THEN] Two lots are shipped.
        for i := 1 to ArrayLen(LotNo) do begin
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            ItemLedgerEntry.SetRange("Lot No.", LotNo[i]);
            ItemLedgerEntry.FindFirst();
            ItemLedgerEntry.TestField(Quantity, -Qty * QtyPer);
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostProdOrderInvtPickWithSplitPickLinesOfDifferentLotNo()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionBOMHeader: Record "Production BOM Header";
        ItemTrackingCode: Record "Item Tracking Code";
        ParentItem: Record Item;
        CompItem: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNos: array[3] of Code[10];
        Quantity: Decimal;
        QtyToHandle: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Inventory Pick] [Production Order Component] [Lot]
        // [SCENARIO 368018] Stan can post inventory pick for prod. order components with split pick lines for different lots for first component with total "Qty. to handle" more than the total quantity of second component
        Initialize();

        // [GIVEN] Location set up for inventory pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Lot-tracked items "COMP1","COMP2" with "Lot Warehouse Tracking" = TRUE.
        CreateItemTrackingCode(ItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(CompItem[1], LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
        LibraryInventory.CreateTrackedItem(CompItem[2], LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Production BOM for Item "PARENT" with Item Components "COMP1" and "COMP2"
        CreateItemWithReplenishmentSystem(ParentItem, ParentItem."Replenishment System"::"Prod. Order");
        CreateAndCertifyBOMWithMultipleLines(
          ProductionBOMHeader, ParentItem."Base Unit of Measure", CompItem[1]."No.",
          CompItem[2]."No.", '', CompItem[2]."Base Unit of Measure");
        UpdateProductionBOMOnItem(ParentItem, ProductionBOMHeader."No.");

        // [GIVEN] Lots "L1", "L2" for "COMP1", "L3" for "COMP2"
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Post 10 PCS of lots "L1","L2" for "COMP1" and 10 PCS of lot "L3" for "COMP2" to inventory
        Quantity := LibraryRandom.RandInt(10);
        CreateAndPostItemJournalLineWithLotNoEnqueued(CompItem[1]."No.", Quantity, Location.Code, '', LotNos[1]);
        CreateAndPostItemJournalLineWithLotNoEnqueued(CompItem[1]."No.", Quantity, Location.Code, '', LotNos[2]);
        CreateAndPostItemJournalLineWithLotNoEnqueued(CompItem[2]."No.", Quantity, Location.Code, '', LotNos[3]);

        // [GIVEN] Create released production order for 10 PCS of "PARENT"
        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", Quantity, Location.Code, '');

        // [GIVEN] Create inventory pick for the production order
        LibraryVariableStorage.Enqueue(InvPickMsg);
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true);

        // [GIVEN] Set "Qty. to Handle"= 8 with Lot "L1" on "COMP1" line
        // [GIVEN] Split inventory pick line for "COMP1"
        // [GIVEN] Set "Qty. to Handle"= 2 with Lot "L2" on second "COMP1" line
        // [GIVEN] Set "Qty. to Handle"= 8 with Lot "L3" on "COMP2" line
        QtyToHandle := LibraryRandom.RandDecInDecimalRange(Quantity / 3, Quantity, 2);
        FindWarehouseActivityLinesWithItemNo(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", CompItem[1]."No.");
        UpdatePickLineQtyToHandleAndLotNo(WarehouseActivityLine, QtyToHandle, LotNos[1]);
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);
        WarehouseActivityLine.Next();
        UpdatePickLineQtyToHandleAndLotNo(WarehouseActivityLine, Quantity - QtyToHandle, LotNos[2]);
        FindWarehouseActivityLinesWithItemNo(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", CompItem[2]."No.");
        UpdatePickLineQtyToHandleAndLotNo(WarehouseActivityLine, QtyToHandle, LotNos[3]);

        // [WHEN] Post the inventory pick.
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Inventory pick posted with consumption Item Ledger Entries:
        // [THEN] Quantity = -8 for Item "COMP1", Lot "L1"
        // [THEN] Quantity = -2 for Item "COMP1", Lot "L2"
        // [THEN] Quantity = -8 for Item "COMP2", Lot "L3"
        VerifyItemLedgerEntryWithLotNo(CompItem[1]."No.", ItemLedgerEntry."Entry Type"::Consumption, LotNos[1], -QtyToHandle);
        VerifyItemLedgerEntryWithLotNo(CompItem[1]."No.", ItemLedgerEntry."Entry Type"::Consumption, LotNos[2], -Quantity + QtyToHandle);
        VerifyItemLedgerEntryWithLotNo(CompItem[2]."No.", ItemLedgerEntry."Entry Type"::Consumption, LotNos[3], -QtyToHandle);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingAgentAndAgentServiceCodeCopiedFromSalesOrderToWhseShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and release Sales Order with 'Shipping Agent Code' and 'Shipping Agent Service Code'
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);  // Taking Random Quantity.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), LocationWhite.Code, Item."No.", Quantity);
        UpdateShippingAgentCodeAndShippingAgentServiceCode(SalesHeader);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise: Invoke Create Warehouse Shipment from Sales Order
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Validation: 'Shipping Agent Code' and 'Shipping Agent Services Code' is copied from Sales Header to Warehouse Shipment Header
        FindWarehouseShipmentHeaderBySalesHeader(WarehouseShipmentHeader, SalesHeader);
        WarehouseShipmentHeader.TestField("Shipping Agent Code", SalesHeader."Shipping Agent Code");
        WarehouseShipmentHeader.TestField("Shipping Agent Service Code", SalesHeader."Shipping Agent Service Code");
    end;

    [Test]
    procedure GetSourceDocumentsOnWarehouseShipmentDoNotFillQtyToHandle()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Qty: Decimal;
    begin
        // [SCENARIO 436708] "Qty. to Ship" is not filled for Warehouse Shipment Lines in case "Do Not Fill Qty. to Handle" is set on "Filters to Get Source Docs" report.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Location with required shipment.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Sales order.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Location.Code, Item."No.", Qty);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create warehouse shipment header and get source documents. Set "Do Not Fill Qty. to Handle" = TRUE.
        GetSourceDocumentOnWarehouseShipment(WarehouseShipmentHeader, Location.Code, true);

        // [THEN] "Qty. to Ship" = 0 on warehouse shipment line.
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentLine.SetRange("Location Code", Location.Code);
        WarehouseShipmentLine.SetRange("Item No.", Item."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField(Quantity, Qty);
        WarehouseShipmentLine.TestField("Qty. to Ship", 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForUndoPosetReceipt')]
    procedure VerifyWareHouseShipmentRequiredWhenCustomerLocationDirectPutAwayAndPick()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 573331] Verify WareHouse Shipment Required When Customer Location have Direct Put Away And Pick.
        Initialize();

        // [GIVEN] Create WMS Location .
        LibraryWarehouse.CreateFullWMSLocation(Location, LibraryRandom.RandIntInRange(1, 5));

        // [GIVEN] Create First Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Second Customer.
        LibrarySales.CreateCustomer(Customer2);

        // [GIVEN] Add location code in second customer.
        Customer2.Validate("Location Code", Location.Code);
        Customer2.Modify(true);

        // [GIVEN] Create sales invoice with first customer.
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        Commit();

        // [WHEN] Change the customer from second customer to first customer.
        asserterror SalesHeader.Validate("Sell-to Customer No.", Customer2."No.");

        // [THEN] Verify warehouse shipment is required error occur.
        Assert.ExpectedError(WhseShipmentIsRequiredErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    procedure WarehouseShipmentLotTrackingUpdateAfterPickRegistration()
    var
        Item: Record Item;
        Location: Record Location;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        LotNos: array[3] of Code[10];
        Quantity: array[3] of Decimal;
    begin
        // [SCENARIO 592123] Warehouse Shipment Item Tracking Lines should update after Pick Registration with partial quantities
        Initialize();

        // [GIVEN] Create Location without bins and warehouse employee
        CreateAndUpdateLocation(Location, false, true, false, true, false);

        // [GIVEN] Create Warehouse Employee
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Item with Lot Tracking
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);

        // [GIVEN] Post positive adjustment with three lots: LOT001, LOT002, LOT003
        CreateInventoryForMultipleLotItem(Item, Location.Code, LotNos, Quantity);

        // [GIVEN] Create Sales Order for total quantity 
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
            Customer."No.", Item."No.", Quantity[1] + Quantity[2] + Quantity[3], Location.Code, WorkDate());

        // [GIVEN] Assign lot tracking to sales line
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
        SalesLine.OpenItemTrackingLines();
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create warehouse shipment
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        // [GIVEN] Create and modify pick with partial quantities: LOT001(3), LOT002(1), LOT003(1)
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // Modify pick quantities to partial quantity for each lot
        UpdateWarehouseActivityLineQtyToHandleForMultipleLots(SalesHeader."No.", WarehouseActivityHeader.Type::Pick, Item."No.", LotNos, Quantity);

        // [WHEN] Register the pick
        RegisterWarehouseActivity(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick);

        // [THEN] Warehouse shipment should post successfully
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [THEN] Qty. Outstanding (Base) on Warehouse Shipment Line should be greater than 0
        WarehouseShipmentLine.FindLast();
        Assert.IsTrue(WarehouseShipmentLine."Qty. Outstanding (Base)" > 0, OutstandingQtyErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse - Shipping");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse - Shipping");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        CreateLocationSetup();
        NoSeriesSetup();
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        CreateTransferRoute();
        LibraryWarehouse.WarehouseJournalSetup(LocationWhite.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        ConsumptionJournalSetup();
        OutputJournalSetup();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Warehouse Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse - Shipping");
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        CreateFullWarehouseSetup(LocationWhite2);  // Location: White2.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite2.Code, false);
        CreateFullWarehouseSetup(LocationWhite3);  // Location: White3.
        LibraryWarehouse.CreateLocationWMS(LocationGreen, false, true, true, true, true);  // Location Green with Require Put Away,Pick,Receive and Shipment.
        LibraryWarehouse.CreateLocationWMS(LocationGreen2, false, true, true, true, true);  // Location Green2 with Require Put Away,Pick,Receive and Shipment.
        LibraryWarehouse.CreateLocationWMS(LocationOrange, false, true, true, false, false);  // Location Orange with Require Put Away and Require Pick.
        LibraryWarehouse.CreateLocationWMS(LocationOrange2, false, true, true, false, false);  // Location Orange2 with Require Put Away and Require Pick.
        LibraryWarehouse.CreateLocationWMS(LocationOrange3, true, true, true, true, true);  // Location Orange3.
        LibraryWarehouse.CreateNumberOfBins(LocationOrange3.Code, '', '', 2, false);  // Value required for No. of Bins.
        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, false, true, false, false);  // Location Silver with Require Pick and Bin Mandatory.
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value required.
        LibraryWarehouse.CreateLocationWMS(LocationSilver2, true, false, true, false, true);  // Location Silver with Require Shipment, Require Pick and Bin Mandatory.
        LibraryWarehouse.CreateNumberOfBins(LocationSilver2.Code, '', '', 2, false);  // Value required for No. of Bins.
        LibraryWarehouse.CreateLocationWMS(LocationSilver3, true, false, false, false, false);  // Location Silver3 with Bin Mandatory.
        LibraryWarehouse.CreateLocationWMS(LocationRed, false, false, true, false, true);  // Location Red with Require Pick and Require Shipment.
        LibraryWarehouse.CreateLocationWMS(LocationBlue, false, false, true, false, true);  // Location Blue with Require Pick and Require Shipment.
        LibraryWarehouse.CreateLocationWMS(LocationWithRequirePick, false, false, true, false, false);  // Location with Require Pick.
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);  // Location: Location In Transit.
    end;

    local procedure ConsumptionJournalSetup()
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch2, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
    end;

    local procedure OutputJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate2, ItemJournalTemplate2.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch3, ItemJournalTemplate2.Type, ItemJournalTemplate2.Name);
    end;

    local procedure RegisterPickFromProdOrderWithLotNo(var ComponentItem: Record Item)
    var
        Bin: Record Bin;
        ParentItem: Record Item;
        Quantity: Decimal;
    begin
        CreateProdItemWithComponentWithTrackingAndReorderingPolicy(
          ParentItem, ComponentItem, false, true, '', LibraryUtility.GetGlobalNoSeriesCode()); // Taking Lot No. as True. Taking Blank value for Lot Nos. on Item card.
        Quantity := LibraryRandom.RandInt(10);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true); // Find PICK Bin.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No."); // Enqueue ItemTrackingMode for WhseItemTrackingLinesHandler.
        UpdateInventoryUsingWhseJournal(Bin, ComponentItem, Quantity, '', ComponentItem."Base Unit of Measure", true); // Taking True for Item Tracking.

        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssitEditLotNo); // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);
        CreateAndRegisterPickFromProdOrderWithTrackingForComponent(
          ParentItem."No.", ComponentItem."No.", LocationWhite.Code, Bin.Code, Quantity);
    end;

    local procedure AddNewLineInSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        CreateSalesLine(SalesHeader, SalesLine, LocationCode, ItemNo, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure AssignLotNoOnItemTrackingLine(var ItemTrackingLines: TestPage "Item Tracking Lines"; Quantity: Decimal)
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);  // Dequeue for ItemTrackingPageHandler.
    end;

    local procedure AutoFillQtyToHandleOnWhseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
    end;

    local procedure ShippingValuesInWarehouseActivityLine(ShipmentMethodCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10])
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        // Setup: Create item and Create and release transfer order with shipping values.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationWithRequirePick.Code, '', false);
        CreateAndUpdateTransferOrder(
          TransferHeader, TransferLine, ShipmentMethodCode, ShippingAgentCode, ShippingAgentServiceCode, Item."No.", Quantity);

        // Exercise: Create Inventory Put-away/Pick from Transfer Order.
        LibraryVariableStorage.Enqueue(InvPickMsg);
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Outbound Transfer", TransferHeader."No.", false, true);

        // Verify: Verifying Shipping values on Warehouse Activity line.
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseRequest."Source Document"::"Outbound Transfer",
          TransferHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        VerifyShippingValuesInWarehouseActiityLine(WarehouseActivityLine, TransferHeader, TransferLine);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Require Put-away", RequirePutAway);
        Location.Validate("Require Pick", RequirePick);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Shipment", RequireShipment);
        Location."Bin Mandatory" := BinMandatory;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20]; ItemTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalBatch.Validate("No. Series", '');  // Blank value required for the test.
        ItemJournalBatch.Modify(true);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        if ItemTracking then
            ItemJournalLine.OpenItemTrackingLines(false);  // Opens Item tracking lines page which is handled in the ItemTrackingPageHandler.
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineWithLotNoEnqueued(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20]; LotNo: Code[50])
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Set Lot No.");
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(LotNo);
        CreateAndPostItemJournalLine(ItemNo, Quantity, LocationCode, BinCode, true);
    end;

    local procedure CreateAndPostInvPickFromTransferOrder(TransferHeaderNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
    begin
        LibraryVariableStorage.Enqueue(InvPickMsg);  // Enqueue for MessageHandler.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Outbound Transfer", TransferHeaderNo, false, true);  // Taking True for Pick.
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeaderNo,
          WarehouseActivityHeader.Type::"Invt. Pick");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);  // Taking True for posting as Invoice.
    end;

    local procedure CreateAndPostInvPickFromTransferOrderForTwoItems(ItemNo: Code[20]; ItemNo2: Code[20]; UpdateQtyForItem: Decimal; UpdateQtyForItem2: Decimal; TransferQty: Decimal): Code[20]
    var
        TransferHeader: Record "Transfer Header";
    begin
        Initialize();
        CreateAndPostItemJournalLine(ItemNo, UpdateQtyForItem, LocationOrange.Code, '', false);
        if UpdateQtyForItem2 <> 0 then
            CreateAndPostItemJournalLine(ItemNo2, UpdateQtyForItem2, LocationOrange.Code, '', false);

        // Create and release transfer order
        CreateAndReleaseTransferOrderWithTwoLines(
          TransferHeader, LocationOrange.Code, LocationOrange2.Code, ItemNo, ItemNo2, TransferQty);

        // Create and Post Inventory Pick
        CreateAndPostInvPickFromTransferOrder(TransferHeader."No.");
        exit(TransferHeader."No.");
    end;

    local procedure CreateAndPostInvPutAwayFromTransferOrder(TransferHeaderNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
    begin
        LibraryVariableStorage.Enqueue(InvPutAwayMsg);  // Enqueue for MessageHandler.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Inbound Transfer", TransferHeaderNo, true, false);  // Taking True for Put Away.
        LibraryVariableStorage.Enqueue(StrSubstNo(TransferOrderDeletedMsg, TransferHeaderNo));  // Enqueue for MessageHandler.
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Inbound Transfer", TransferHeaderNo,
          WarehouseActivityHeader.Type::"Invt. Put-away");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);  // Taking True for posting as Invoice.
    end;

    local procedure CreateAndPostSalesOrderWithTwoLines(ItemXNo: Code[20]; ItemYNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal): Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Order, Customer."No.");
        CreateSalesLine(SalesHeader, SalesLine, LocationCode, ItemXNo, Quantity);
        CreateSalesLine(SalesHeader, SalesLine, LocationCode, ItemYNo, Quantity);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; LocationCode2: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; Quantity2: Decimal; MultipleLines: Boolean; ItemTracking: Boolean)
    begin
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', LocationCode, ItemNo, Quantity);
        if MultipleLines then
            CreateSalesLine(SalesHeader, SalesLine, LocationCode2, ItemNo2, Quantity2);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        if ItemTracking then
            SalesLine.OpenItemTrackingLines();  // Assign Item Tracking on single line.
    end;

    local procedure CreateAndReleasePurchaseOrderWithMultipleLocations(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; LocationCode2: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; Quantity2: Decimal; MultipleLines: Boolean)
    begin
        CreatePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        if MultipleLines then begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo2, Quantity2);
            PurchaseLine.Validate("Location Code", LocationCode2);
            PurchaseLine.Modify(true);
        end;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithMultipleLinesUsingShippingAdvice(var SalesHeader: Record "Sales Header"; ShippingAdvice: Enum "Sales Header Shipping Advice"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; Quantity2: Decimal; LocationCode: Code[10]; LocationCode2: Code[10]; MultipleLines: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipping Advice", ShippingAdvice);   // Handling the Confirm Dialog.
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, LocationCode, ItemNo, Quantity);
        if MultipleLines then
            CreateSalesLine(SalesHeader, SalesLine, LocationCode2, ItemNo2, Quantity2);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithPostingDate(var SalesHeader: Record "Sales Header"; Type: Enum "Sales Document Type"; LocationCode: Code[10])
    begin
        CreateSalesOrderWithPostingDate(SalesHeader, Type, LocationCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithPostingDate(var PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Document Type"; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.PostPositiveAdjustment(
          Item, LocationCode, '', '', LibraryRandom.RandIntInRange(10, 100), WorkDate(), LibraryRandom.RandInt(10));
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, Type, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseTransferOrderWithPostingDate(var TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.PostPositiveAdjustment(
          Item, LocationBlue.Code, '', '', LibraryRandom.RandIntInRange(10, 100), WorkDate(), LibraryRandom.RandInt(10));
        LibraryInventory.PostPositiveAdjustment(
          Item, LocationWhite.Code, '', '', LibraryRandom.RandIntInRange(10, 100), WorkDate(), LibraryRandom.RandInt(10));
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationBlue.Code, LocationWhite.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(2, 10));
        TransferLine.Validate("Qty. to Ship", TransferLine.Quantity - 1);
        TransferLine.Modify(true);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleaseSalesReturnOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', LocationWhite.Code, ItemNo,
          Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', LocationWhite.Code, ItemNo, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndRegisterPickFromProductionOrder(ProductionOrder: Record "Production Order"; Bin: Record Bin)
    begin
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        ProductionOrder.Validate("Location Code", Bin."Location Code");
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        RegisterPickFromProdOrder(ProductionOrder);
    end;

    local procedure CreateAndRegisterPickFromProdOrderWithTrackingForComponent(ParentItemNo: Code[20]; ComponentItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ProdOrder: Record "Production Order";
    begin
        CreateAndRefreshProductionOrder(ProdOrder, ParentItemNo, Quantity, LocationCode, BinCode);
        SelectItemTrackingForProdOrderComponents(ComponentItemNo);
        RegisterPickFromProdOrder(ProdOrder);
    end;

    local procedure CreateAndRegisterPutAwayFromPurchaseOrderAndPostReceipt(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ItemTracking: Boolean; ItemTrackingMode: Option; UpdateBinCode: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        if ItemTracking then begin
            FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
            LibraryVariableStorage.Enqueue(ItemTrackingMode);  // Enqueue for ItemTrackingPageHandler.
            WarehouseReceiptLine.OpenItemTrackingLines();  // Item Tracking Lines page is handled using ItemTrackingLinesHandlerWithSerialNo
        end;
        PostWarehouseReceipt(PurchaseHeader."No.");
        if UpdateBinCode then
            ModifyZoneAndBinCodeOnPutAwayLine(PurchaseHeader."No.", LocationCode);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ItemTracking: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        if ItemTracking then
            TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleaseTransferOrderWithTwoLines(var TransferHeader: Record "Transfer Header"; TransferFromCode: Code[10]; TransferToCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, TransferFromCode, TransferToCode, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo2, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleaseWarehouseShipmentFromSalesOrder(SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndReserveProdOrderComponentWithItemTracking(ProductionOrder: Record "Production Order")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ProductionOrder."Source No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ProductionOrder."Source No.");
        ProdOrderComponent.Validate("Quantity per", 1);  // Value required for Quantity Per in the test.
        ProdOrderComponent.Validate("Location Code", ProductionOrder."Location Code");
        ProdOrderComponent.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        ProdOrderComponent.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());  // Enqueue for ConfirmHandler.
        ProdOrderComponent.ShowReservation();
    end;

    local procedure CreateAndReleasePurchaseOrderWithDifferentPutAwayUOM(Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Unit of Measure Code", Item."Put-away Unit of Measure Code");
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithItemTrackingOnMultipleLines(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, SalesLine, LocationCode, ItemNo, Quantity);
        CreateSalesLine(SalesHeader, SalesLine2, LocationCode, ItemNo2, Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for ItemTrackingPageHandler.
        SalesLine.OpenItemTrackingLines();  // Assign Item Tracking on First line.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for ItemTrackingPageHandler.
        SalesLine2.OpenItemTrackingLines(); // Assign Item Tracking on second line.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithDifferentPutAwayUOM(var SalesHeader: Record "Sales Header"; Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', LocationCode, Item."No.", Quantity);
        SalesLine.Validate("Unit of Measure Code", Item."Put-away Unit of Measure Code");
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithTrackingOnMultipleLines(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; ItemNo2: Code[20]; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
        Variant: Variant;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithTracking(PurchaseLine, PurchaseHeader, ItemNo, Quantity, LocationCode, ItemTrackingMode::"Assign Serial No.");
        CreatePurchaseLineWithTracking(PurchaseLine, PurchaseHeader, ItemNo2, Quantity, LocationCode, ItemTrackingMode::"Assign Lot No.");
        LibraryVariableStorage.Dequeue(Variant);  // Dequeue for ItemTrackingPageHandler.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithExternalDocumentNo(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ExternalDocumentNo: Code[35])
    begin
        CreateSalesOrderWithExternalDocumentNo(SalesHeader, LocationCode, ExternalDocumentNo);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleasePurchaseReturnOrderWithVendorShipmentNo(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; VendorShipmentNo: Code[35])
    begin
        CreatePurchaseReturnOrderWithVendorShipmentNo(PurchaseHeader, LocationCode, VendorShipmentNo);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseTransferOrderWithExternalDocumentNo(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ExternalDocumentNo: Code[35])
    begin
        CreateTransferOrderWithExternalDocumentNo(TransferHeader, FromLocationCode, ToLocationCode, ExternalDocumentNo);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithVendorShipmentNo(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; VendorShipmentNo: Code[35])
    begin
        CreatePurchaseOrderWithVendorShipmentNo(PurchaseHeader, LocationCode, VendorShipmentNo);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndPostPurchaseOrder(var Location: Record Location; ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreatePurchaseOrder(PurchaseHeader, Location.Code, ItemNo, Quantity);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure CreateAndPostSalesOrder(LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", LocationCode, ItemNo, Quantity);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateAndPartiallyPostSalesShipmentForLotTrackedItem(var SalesHeader: Record "Sales Header"; var LotNo: Code[50]; ItemNo: Code[20]; Qty: Decimal; ShipQty: Decimal)
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
        CreateAndPostItemJournalLine(ItemNo, Qty, Location.Code, '', true);
        LotNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo));

        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
        CreateWarehouseShipmentFromSalesOrderWithLotNo(SalesHeader, ItemNo, Location.Code, Qty);

        FindWarehouseShipmentLine(
          WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentLine.Validate("Qty. to Ship", ShipQty);
        WarehouseShipmentLine.Modify(true);

        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreateAndPostWarehouseReceipt(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.");
    end;

    local procedure CreateAndCertifyBOMWithMultipleLines(var ProductionBOMHeader: Record "Production BOM Header"; UnitOfMeasureCode: Code[10]; ComponentItemNo: Code[20]; ComponentItemNo2: Code[20]; VariantCode: Code[10]; ComponentUnitOfMeasure: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItemNo, 1);  // Value required for QuantityPer.
        if ComponentItemNo2 <> '' then begin
            LibraryManufacturing.CreateProductionBOMLine(
              ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItemNo2, 1);  // Value required for QuantityPer.
            ProductionBOMLine.Validate("Variant Code", VariantCode);
            ProductionBOMLine.Validate("Unit of Measure Code", ComponentUnitOfMeasure);
            ProductionBOMLine.Modify(true);
        end;
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndUpdateTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ShipmentMethodCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationWithRequirePick.Code, LocationBlue.Code, LocationInTransit.Code);
        TransferHeader.Validate("Shipping Agent Code", ShippingAgentCode);
        TransferHeader.Validate("Shipping Agent Service Code", ShippingAgentServiceCode);
        TransferHeader.Validate("Shipment Method Code", ShipmentMethodCode);
        TransferHeader.Modify(true);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateBinWithWarehouseClassCode(var Bin: Record Bin; Zone: Record Zone; WarehouseClassCode: Code[10])
    begin
        LibraryWarehouse.CreateBin(Bin, Zone."Location Code", LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");
        Bin.Validate("Warehouse Class Code", WarehouseClassCode);
        Bin.Modify(true);
    end;

    local procedure CreateItemWithReplenishmentSystem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Flushing Method", Item."Flushing Method"::"Pick + Manual");
        Item.Modify(true);
    end;

    local procedure CreateItemWithLOTAndAutoReserve(var Item: Record Item)
    begin
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify();
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreatePick(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreateWarehouseShipmentFromSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ItemTracking: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader, SalesLine, LocationCode, '', ItemNo, '', Quantity, 0, false, ItemTracking);  // Multiple Lines as FALSE. // Taking O for Quantity of blank line.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreatePickFromSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ItemTracking: Boolean)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateWarehouseShipmentFromSalesOrder(SalesHeader, LocationCode, ItemNo, Quantity, ItemTracking);
        CreatePick(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreatePickFromSalesOrderWithWarehouseClassCode(var SalesHeader: Record "Sales Header"; var Bin: Record Bin; LocationCode: Code[10]; WarehouseClassCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Zone: Record Zone;
    begin
        LibraryWarehouse.CreateZone(
          Zone,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Zone.FieldNo(Code), DATABASE::Zone), 1,
            LibraryUtility.GetFieldLength(DATABASE::Zone, Zone.FieldNo(Code))),
          LocationCode, LibraryWarehouse.SelectBinType(false, true, false, false), WarehouseClassCode, '', 0, false);  // Value required for Zone Rank. Taking True for Ship Zone.
        CreateBinWithWarehouseClassCode(Bin, Zone, WarehouseClassCode);
        CreateWarehouseShipmentFromSalesOrder(SalesHeader, LocationCode, ItemNo, Quantity, false);
        UpdateBinOnWarehouseShipmentLine(Bin, SalesHeader."No.");
        CreatePick(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreatePickFromWhseShipment(var SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreatePick(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreatePickFromWarehouseInternalPickWithMultipleLines(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; Bin: Record Bin; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal; ItemNo2: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode2: Code[10])
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhseInternalPickRelease: Codeunit "Whse. Internal Pick Release";
    begin
        CreateWarehouseInternalPickHeader(WhseInternalPickHeader, Bin."Location Code", Bin.Code);
        CreateWarehouseInternalPickLine(WhseInternalPickHeader, ItemNo, Quantity, '', UnitOfMeasureCode);
        CreateWarehouseInternalPickLine(WhseInternalPickHeader, ItemNo2, Quantity, VariantCode, UnitOfMeasureCode2);
        WhseInternalPickRelease.Release(WhseInternalPickHeader);
        LibraryVariableStorage.Enqueue(PickActivityCreatedMsg);  // Enqueue for MessageHandler.
        WhseInternalPickLine.SetRange("No.", WhseInternalPickHeader."No.");
        WhseInternalPickLine.CreatePickDoc(WhseInternalPickLine, WhseInternalPickHeader);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; Serial: Boolean; Lot: Boolean; SerialNos: Code[20]; LotNos: Code[20]; ManExprDateEntryReqd: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, Serial, Lot, ManExprDateEntryReqd);
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, ItemTrackingCode.Code);
    end;

    local procedure CreateItemWithProductionBOM(var ParentItem: Record Item; var ComponentItem: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithReplenishmentSystem(ParentItem, ReplenishmentSystem);
        CreateItemWithReplenishmentSystem(ComponentItem, ReplenishmentSystem);
        CreateAndCertifyBOMWithMultipleLines(ProductionBOMHeader, ParentItem."Base Unit of Measure", ComponentItem."No.", '', '', '');
        UpdateProductionBOMOnItem(ParentItem, ProductionBOMHeader."No.");
    end;

    local procedure CreateProdItemWithComponentWithTrackingAndReorderingPolicy(var ParentItem: Record Item; var ComponentItem: Record Item; Serial: Boolean; Lot: Boolean; SerialNos: Code[20]; LotNos: Code[20])
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithReplenishmentSystem(ParentItem, ParentItem."Replenishment System"::"Prod. Order");
        CreateItemWithItemTrackingCode(ComponentItem, Serial, Lot, SerialNos, LotNos, false);
        ComponentItem.Validate("Reordering Policy", ComponentItem."Reordering Policy"::"Lot-for-Lot");
        ComponentItem.Modify(true);
        CreateAndCertifyBOMWithMultipleLines(ProdBOMHeader, ParentItem."Base Unit of Measure", ComponentItem."No.", '', '', '');
        UpdateProductionBOMOnItem(ParentItem, ProdBOMHeader."No.");
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, 1 + LibraryRandom.RandInt(5));
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Serial: Boolean; Lot: Boolean; ManExprDateEntryReqd: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("Use Expiration Dates", ManExprDateEntryReqd);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManExprDateEntryReqd);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemWithDifferentSalesUnitOfMeasure(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemWithPutAwayUOM(var Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        Item.Validate("Put-away Unit of Measure Code", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemWithFlushingMethodForward(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Flushing Method", Item."Flushing Method"::Forward);
        Item.Modify(true);
    end;

    local procedure CreateItemWithVariantAndFlushingMethod(var ItemVariant: Record "Item Variant")
    var
        Item: Record Item;
    begin
        CreateItemWithFlushingMethodForward(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
    end;

    local procedure CreateItemWithWarehouseClass(var WarehouseClass: Record "Warehouse Class"; var Item: Record Item)
    begin
        LibraryWarehouse.CreateWarehouseClass(WarehouseClass);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Warehouse Class Code", WarehouseClass.Code);
        Item.Modify(true);
    end;

    local procedure CreateInventoryActivity(SourceDocument: Enum "Warehouse Request Source Document"; SourceNo: Code[20]; PutAway: Boolean; Pick: Boolean)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Source Document", SourceDocument);
        WarehouseRequest.SetRange("Source No.", SourceNo);
        WarehouseRequest.FindFirst();
        LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, PutAway, Pick, false);
    end;

    local procedure CreateTransferRoute()
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationOrange.Code, LocationOrange2.Code);
        TransferRoute.Validate("In-Transit Code", LocationInTransit.Code);
        TransferRoute.Modify(true);
    end;

    local procedure CreateTransferHeaderAndUpdateDimension(var TransferHeader: Record "Transfer Header"; var DimensionValue: array[2] of Record "Dimension Value")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationBlue.Code, LocationRed.Code, LocationInTransit.Code);

        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue[1], GeneralLedgerSetup."Shortcut Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[2], GeneralLedgerSetup."Shortcut Dimension 2 Code");

        TransferHeader.Validate("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        TransferHeader.Validate("Shortcut Dimension 2 Code", DimensionValue[2].Code);
        TransferHeader.Modify(true);
    end;

    local procedure CreateThreeSalesOrderForDifferentBins(var SalesHeader: array[3] of Record "Sales Header"; Item: Record Item; Bin: array[3] of Record Bin; LocationCode: Code[10]; Quantity: array[3] of Decimal; QtyperUnitofMeasure: Decimal)
    var
        SalesLine: array[3] of Record "Sales Line";
    begin
        LibraryInventory.PostPositiveAdjustment(
          Item, LocationCode, '', Bin[1].Code, Quantity[1], WorkDate(), LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostPositiveAdjustment(
          Item, LocationCode, '', Bin[2].Code, Quantity[2], WorkDate(), LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostPositiveAdjustment(
          Item, LocationCode, '', Bin[3].Code, Quantity[3], WorkDate(), LibraryRandom.RandDec(100, 2));

        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader[1],
          SalesLine[1], LocationCode, '', Item."No.", '', Quantity[1] / QtyperUnitofMeasure, 0, false, false);

        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader[2],
          SalesLine[2], LocationCode, '', Item."No.", '', Quantity[2] / QtyperUnitofMeasure, 0, false, false);

        CreateAndReleaseSalesOrderWithMultipleLinesAndItemTracking(
          SalesHeader[3],
          SalesLine[3], LocationCode, '', Item."No.", '', Quantity[3] / QtyperUnitofMeasure, 0, false, false);

        SalesLine[3].Validate("Unit of Measure Code", Item."Base Unit of Measure");
        SalesLine[3].Validate(Quantity, Round(SalesLine[3].Quantity * QtyperUnitofMeasure));
        SalesLine[3].Modify(true);
    end;

    local procedure CreateRequisitionLineAndCarryOutPlanForFirmPlanned(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        NewProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
        NewPurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh";
        NewTransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh";
        NewAsmOrderChoice: Option " ","Make Assembly Orders","Make Assembly Orders & Print";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::Planning);
        RequisitionWkshName.FindFirst();
        Clear(RequisitionLine);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Validate("Location Code", LocationCode);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutPlanWksh(
          RequisitionLine, NewProdOrderChoice::"Firm Planned", NewPurchOrderChoice::" ", NewTransOrderChoice::" ", NewAsmOrderChoice::" ",
          '', '', '', '');
    end;

    local procedure CreateRequisitionLineAndCarryOutActionMessagePlan(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::"Req.");
        RequisitionWkshName.FindFirst();
        Clear(RequisitionLine);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Validate("Location Code", LocationCode);
        RequisitionLine.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CreatePurchaseLineWithTracking(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemTrackingMode: Option)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode);  // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesOrderWithDeterminedQuantity(var SalesHeader: Record "Sales Header"; Type: Enum "Sales Document Type"; LocationCode: Code[10]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrderWithPostingDate(SalesHeader, Type, LocationCode);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        exit(SalesLine.Quantity);
    end;

    local procedure CreateSalesOrderWithPostingDate(var SalesHeader: Record "Sales Header"; Type: Enum "Sales Document Type"; LocationCode: Code[10])
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          LibraryRandom.RandIntInRange(10, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        CreateSalesDocument(
          SalesHeader, SalesLine, Type, LibrarySales.CreateCustomerNo(), LocationCode, Item."No.",
          LibraryRandom.RandIntInRange(2, 10));
    end;

    local procedure CreateSalesOrderWithExternalDocumentNo(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ExternalDocumentNo: Code[35])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        CreateItemWithInventory(Item, LocationCode, 1);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), LocationCode, Item."No.", 1);
        SalesHeader.Validate("External Document No.", ExternalDocumentNo);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesOrderWithInventoryServiceLinesAndNonStockLines(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; InventoryItemNo: Code[20]; InventoryItemQty: Decimal; ServiceItemNo: Code[20]; ServiceItemQty: Decimal; NonStockItemNo: Code[20]; NonStockItemQty: Decimal)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Shipping Advice", SalesHeader."Shipping Advice"::Complete);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, LocationCode, InventoryItemNo, InventoryItemQty);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, '', ServiceItemNo, ServiceItemQty);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, '', NonStockItemNo, NonStockItemQty);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceForPostedShipment(SalesHeaderOrder: Record "Sales Header")
    var
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineInvoice: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");

        SalesLineInvoice."Document Type" := SalesHeaderInvoice."Document Type";
        SalesLineInvoice."Document No." := SalesHeaderInvoice."No.";
        LibrarySales.GetShipmentLines(SalesLineInvoice);
    end;

    local procedure CreateSalesInvoiceWithLotTracking(CustomerNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo, LocationCode, ItemNo, Qty);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Set Lot No.");
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(AvailWarningMsg);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseOrderWithVendorShipmentNo(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; VendorShipmentNo: Code[35])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        CreateItemWithInventory(Item, LocationCode, 1);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), LocationCode, Item."No.", 1);
        PurchaseHeader.Validate("Vendor Shipment No.", VendorShipmentNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseReturnOrderWithVendorShipmentNo(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; VendorShipmentNo: Code[35])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        CreateItemWithInventory(Item, LocationCode, 1);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order",
          LibraryPurchase.CreateVendorNo(), LocationCode, Item."No.", 1);
        PurchaseHeader.Validate("Vendor Shipment No.", VendorShipmentNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateTransferOrderWithExternalDocumentNo(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ExternalDocumentNo: Code[35])
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
    begin
        CreateItemWithInventory(Item, FromLocationCode, 1);
        CreateTransferDocument(TransferHeader, TransferLine, FromLocationCode, ToLocationCode, Item."No.", 1);
        TransferHeader.Validate("External Document No.", ExternalDocumentNo);
        TransferHeader.Modify(true);
    end;

    local procedure CreateItemWithInventory(var Item: Record Item; LocationCode: Code[10]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, LocationCode, ItemNo, Quantity);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LocationCode, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateTransferDocument(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
    end;

    local procedure CreateShippingAgentWithServices(var ShippingAgent: Record "Shipping Agent"; var ShippingAgentServices: Record "Shipping Agent Services"; PeriodLength: DateFormula; NoOfServices: Integer)
    var
        i: Integer;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        for i := 1 to NoOfServices do
            LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, PeriodLength);
    end;

    local procedure CreateMultipleItemsWithTrackingCodes(var Item: Record Item; var Item2: Record Item; ManExprDateEntryReqd: Boolean)
    begin
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '', false);  // Taking Serial No. as True. Taking Blank value for Lot Nos. on Item card.
        CreateItemWithItemTrackingCode(Item2, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), ManExprDateEntryReqd);  // Taking Lot No. as True. Taking Blank value for Serial Nos. on Item card.
    end;

    local procedure CreateWarehouseInternalPutAway(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateWhseInternalPutawayHdr(WhseInternalPutAwayHeader, Bin."Location Code");
        WhseInternalPutAwayHeader.Validate("From Zone Code", Bin."Zone Code");
        WhseInternalPutAwayHeader.Validate("From Bin Code", Bin.Code);
        WhseInternalPutAwayHeader.Modify(true);
        LibraryWarehouse.CreateWhseInternalPutawayLine(WhseInternalPutAwayHeader, WhseInternalPutAwayLine, ItemNo, Quantity);
    end;

    local procedure CreateWarehouseInternalPickHeader(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseInternalPickHeader(WhseInternalPickHeader, LocationCode);
        WhseInternalPickHeader.Validate("To Zone Code", '');
        WhseInternalPickHeader.Validate("To Bin Code", BinCode);
        WhseInternalPickHeader.Modify(true);
    end;

    local procedure CreateWarehouseInternalPickLine(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10]; UnitOfMeasureCode: Code[10])
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        LibraryWarehouse.CreateWhseInternalPickLine(WhseInternalPickHeader, WhseInternalPickLine, ItemNo, Quantity);
        WhseInternalPickLine.Validate("Variant Code", VariantCode);
        WhseInternalPickLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WhseInternalPickLine.Modify(true);
    end;

    local procedure CreateWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateWarehouseReceiptFromPurchOrderWithPostingDate(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(
          WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        WarehouseReceiptHeader.Validate("Posting Date", PurchaseHeader."Posting Date" - LibraryRandom.RandInt(10));
        // Date less then in Purchase Order
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreateWarehouseReceiptHeaderWithLocation(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        WarehouseReceiptHeader.Validate("Location Code", LocationCode);
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreateWarehouseReceiptFromSalesOrderWithPostingDate(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesHeader: Record "Sales Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        FindWarehouseReceiptLine(
          WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Sales Return Order", SalesHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        WarehouseReceiptHeader.Validate("Posting Date", SalesHeader."Posting Date" - LibraryRandom.RandInt(10));
        // Date less then in Sales Order
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreateWarehouseReceiptFromTransferOrderWithPostingDate(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferHeader: Record "Transfer Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
        FindWarehouseReceiptLine(
          WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        WarehouseReceiptHeader.Validate("Posting Date", TransferHeader."Posting Date" - LibraryRandom.RandInt(10));
        // Date less then in Transfer Order
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreateWarehouseShipmentHeaderWithLocation(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", LocationCode);
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure CreateWarehouseShipmentFromSOWithPostingDate(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentLine(
          WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        WarehouseShipmentHeader.Validate("Posting Date", SalesHeader."Posting Date" - LibraryRandom.RandInt(10));
        // Date less then in Sales Order
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure CreateWarehouseShipmentFromPurchReturnOrderWithPostingDate(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseHeader: Record "Purchase Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        FindWarehouseShipmentLine(
          WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        WarehouseShipmentHeader.Validate("Posting Date", PurchaseHeader."Posting Date" - LibraryRandom.RandInt(10));
        // Date less then in Return Order
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure CreateWarehouseShipmentFromTransferOrderWithPostingDate(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferHeader: Record "Transfer Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentLine(
          WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        WarehouseShipmentHeader.Validate("Posting Date", TransferHeader."Posting Date" - LibraryRandom.RandInt(10));
        // Date less then in Transfer Order
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure CreateWarehouseShipmentFromTransferOrderWithLotNo(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for ItemTrackingPageHandler.
        CreateAndReleaseTransferOrder(TransferHeader, FromLocation, ToLocation, ItemNo, Quantity, true);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
    end;

    local procedure CreateWarehouseReceiptFromPurchaseOrderWithLotNo(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateWarehouseShipmentFromPurchaseReturnOrderWithLotNo(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');
        CreatePurchaseLineWithTracking(PurchaseLine, PurchaseHeader, ItemNo, Quantity, LocationCode, ItemTrackingMode::"Select Entries");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
    end;

    local procedure CreateWarehouseShipmentFromSalesOrderWithLotNo(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesHeader, SalesLine, SalesLine."Document Type"::Order, Customer."No.", LocationCode, ItemNo, Quantity);
        SalesLine.OpenItemTrackingLines();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateWarehousePickforLotTrackedItem(var SalesHeader: Record "Sales Header"; var LotNo: array[2] of Code[20]; LocationCode: Code[10]; QuantityToShip: Decimal; QuantityInItemTrackingLines: Decimal)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode(), false);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Split Lot No."); // Enqueue for ItemTrackingPageHandler
        CreateWarehouseReceiptFromPurchaseOrderWithLotNo(PurchaseHeader, Item."No.", LocationCode, QuantityToShip);
        PostWarehouseReceipt(PurchaseHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");
        LotNo[1] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[1]));
        LotNo[2] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[2]));
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Multiple Lines"); // Enqueue for ItemTrackingPageHandler
        LibraryVariableStorage.Enqueue(ArrayLen(LotNo));
        LibraryVariableStorage.Enqueue(QuantityInItemTrackingLines); // Enqueue for ItemTrackingPageHandler
        LibraryVariableStorage.Enqueue(LotNo[1]); // Enqueue for ItemTrackingPageHandler
        LibraryVariableStorage.Enqueue(LotNo[2]); // Enqueue for ItemTrackingPageHandler
        CreateWarehouseShipmentFromSalesOrderWithLotNo(SalesHeader, Item."No.", LocationWhite.Code, QuantityToShip);
        CreatePick(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreatePostPositiveInvtAdjWithSeveralLOTs(Item: Record Item; LOT: array[4] of Code[20]; QtyPerLOT: Decimal)
    var
        Bin: Record Bin;
        i: Integer;
    begin
        LibraryVariableStorage.Enqueue(ArrayLen(LOT));
        for i := 1 to ArrayLen(LOT) do begin
            LibraryVariableStorage.Enqueue(QtyPerLOT);
            LibraryVariableStorage.Enqueue(LOT[i]);
        end;
        FindBinWithBinTypeCode(Bin, LocationWhite2.Code, false, true, true);  // Find PICK Bin.
        UpdateInventoryUsingWhseJournal(Bin, Item, ArrayLen(LOT) * QtyPerLOT, '', Item."Base Unit of Measure", true);
    end;

    local procedure DeleteQuantityToHandleOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.DeleteQtyToHandle(WarehouseActivityLine);
    end;

    local procedure DeleteReservationEntry(ItemNo: Code[20]; LotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.DeleteAll(true);
    end;

    local procedure DeletePick(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeader.Delete(true);
    end;

    local procedure FilterItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; LotNo: Code[50])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
    end;

    local procedure FilterReservEntryForTransferLine(var ReservationEntry: Record "Reservation Entry"; TransferHeaderNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50])
    begin
        ReservationEntry.SetRange("Source Type", DATABASE::"Transfer Line");
        ReservationEntry.SetRange("Source Subtype", 0);
        ReservationEntry.SetRange("Source ID", TransferHeaderNo);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10])
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.FindFirst();
    end;

    local procedure FindBinWithBinTypeCode(var Bin: Record Bin; LocationCode: Code[10]; Ship: Boolean; PutAway: Boolean; Pick: Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, false, Ship, PutAway, Pick);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, 1); // Use 1 for Index.
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; IsPositive: Boolean)
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Positive, IsPositive);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindTransferLine(var TransferLine: Record "Transfer Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst();
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemNo: Code[20]; Positive: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, Positive);
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.FindFirst();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLinesWithItemNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ItemNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.SetRange("Item No.", ItemNo);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentHeaderBySalesHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        FindWarehouseShipmentHeaderBySource(
          WarehouseShipmentHeader, DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", SalesLine."Line No.");
    end;

    local procedure FindWarehouseShipmentHeaderByPurchaseHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        FindWarehouseShipmentHeaderBySource(
          WarehouseShipmentHeader, DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", PurchaseLine."Line No.");
    end;

    local procedure FindWarehouseShipmentHeaderByTransferHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        FindWarehouseShipmentHeaderBySource(
          WarehouseShipmentHeader, DATABASE::"Transfer Line", 0, TransferHeader."No.", TransferLine."Line No.");
    end;

    local procedure FindWarehouseShipmentHeaderBySource(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLineBySource(WarehouseShipmentLine, SourceType, SourceSubtype, SourceNo, SourceLineNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FindWarehouseShipmentLineBySource(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
        WarehouseShipmentLine.SetRange("Source Type", SourceType);
        WarehouseShipmentLine.SetRange("Source Subtype", SourceSubtype);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.SetRange("Source Line No.", SourceLineNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptHeaderByPurchaseHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        FindWarehouseReceiptHeaderBySource(
          WarehouseReceiptHeader, DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", PurchaseLine."Line No.");
    end;

    local procedure FindWarehouseReceiptHeaderBySource(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLineBySource(WarehouseReceiptLine, SourceType, SourceSubtype, SourceNo, SourceLineNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
    end;

    local procedure FindWarehouseReceiptLineBySource(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
        WarehouseReceiptLine.SetRange("Source Type", SourceType);
        WarehouseReceiptLine.SetRange("Source Subtype", SourceSubtype);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.SetRange("Source Line No.", SourceLineNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; Receive: Boolean; Ship: Boolean; PutAway: Boolean; Pick: Boolean)
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(Receive, Ship, PutAway, Pick));
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure GetSourceDocumentOnWarehouseReceipt(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10]; DoNotFillQtyToHandle: Boolean)
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        CreateWarehouseReceiptHeaderWithLocation(WarehouseReceiptHeader, LocationWhite.Code);
        GetSourceDocuments.SetOneCreatedReceiptHeader(WarehouseReceiptHeader);
        WarehouseSourceFilter.SetFilters(GetSourceDocuments, LocationCode);
        GetSourceDocuments.SetDoNotFillQtytoHandle(DoNotFillQtyToHandle);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.SetSkipBlockedItem(true);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.RunModal();
    end;

    local procedure GetSourceDocumentOnWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10]; DoNotFillQtyToHandle: Boolean)
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        CreateWarehouseShipmentHeaderWithLocation(WarehouseShipmentHeader, LocationCode);
        GetSourceDocuments.SetOneCreatedShptHeader(WarehouseShipmentHeader);
        WarehouseSourceFilter.SetFilters(GetSourceDocuments, LocationCode);
        GetSourceDocuments.SetDoNotFillQtytoHandle(DoNotFillQtyToHandle);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.SetSkipBlockedItem(true);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.RunModal();
    end;

    local procedure GetWarehouseDocumentOnWhseWorksheetLine(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhsePickRequest.SetRange(Status, WhsePickRequest.Status::Released);
        WhsePickRequest.SetRange("Completely Picked", false);
        WhsePickRequest.SetRange("Location Code", LocationCode);
        LibraryWarehouse.GetOutboundSourceDocuments(WhsePickRequest, WhseWorksheetName, LocationCode);
    end;

    [Scope('OnPrem')]
    procedure GetPickByWhseShpmtNo(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WhseShpmtNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type"::Shipment);
        WarehouseActivityLine.SetRange("Whse. Document No.", WhseShpmtNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
    end;

    local procedure ModifyAllowBreakBulkOnLocation(var Location: Record Location; BreakBulk: Boolean)
    begin
        Location.Validate("Allow Breakbulk", BreakBulk);
        Location.Modify(true);
    end;

    local procedure ModifyBinOnWarehouseActivityLineAndRegisterWarehouseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; BinCode: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure ModifyDirectedPutAwayAndPickInLocationWhite(var Location: Record Location)
    begin
        Location.Validate("Directed Put-away and Pick", false);
        Location.Modify(true);
    end;

    local procedure ModifyOrderTrackingPolicyInItem(var Item: Record Item)
    begin
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);
    end;

    local procedure ModifyRequisitionLineAndCarryOutActionMessagePlan(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure ModifyAlwaysCreatePickLineOnLocation(var Location: Record Location; var OldAlwaysCreatePickLine: Boolean; NewAlwaysCreatePickLine: Boolean)
    begin
        OldAlwaysCreatePickLine := Location."Always Create Pick Line";
        Location.Validate("Always Create Pick Line", NewAlwaysCreatePickLine);
        Location.Modify(true);
    end;

    local procedure ModifyAlwaysCreatePutAwayLineOnLocation(var Location: Record Location; var OldAlwaysCreatePutAwayLine: Boolean; NewAlwaysCreatePutAwayLine: Boolean)
    begin
        OldAlwaysCreatePutAwayLine := Location."Always Create Put-away Line";
        Location.Validate("Always Create Put-away Line", NewAlwaysCreatePutAwayLine);
        Location.Modify(true);
    end;

    local procedure ModifyZoneAndBinCodeOnPutAwayLine(SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindSet();
        FindBinWithBinTypeCode(Bin, LocationCode, false, true, true);  // Bin Type Code as PUTPICK.
        repeat
            WarehouseActivityLine.Validate("Zone Code", Bin."Zone Code");
            WarehouseActivityLine.Validate("Bin Code", Bin.Code);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure SplitWhseActivityLines(SourceDocNo: Code[20]; PickLineQty: array[2] of Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        SplitWhseActivityLine(WhseActivityLine, SourceDocNo, PickLineQty);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Place);
        SplitWhseActivityLine(WhseActivityLine, SourceDocNo, PickLineQty);
    end;

    local procedure SplitWhseActivityLine(var WhseActivityLine: Record "Warehouse Activity Line"; SourceDocNo: Code[20]; PickLineQty: array[2] of Decimal)
    begin
        FindWarehouseActivityLine(WhseActivityLine, WhseActivityLine."Source Document"::"Sales Order", SourceDocNo, WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.Validate("Qty. to Handle", PickLineQty[1]);
        WhseActivityLine.Modify();
        WhseActivityLine.SplitLine(WhseActivityLine);

        UpdatePickLineZoneCodeAndBinCode(SourceDocNo, WhseActivityLine."Action Type", WhseActivityLine."Zone Code", WhseActivityLine."Bin Code", PickLineQty[2]);
    end;

    local procedure SetLotNoAndQuantityInItemTrackingLine(ItemTrackingLines: TestPage "Item Tracking Lines"; QtyInTrackingSpecification: Decimal)
    var
        LotNo: Code[50];
    begin
        LotNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo));
        ItemTrackingLines."Lot No.".SetValue(LotNo);
        ItemTrackingLines."Quantity (Base)".SetValue(QtyInTrackingSpecification);
    end;

    local procedure OpenOrderPromisingPage(SalesOrderNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesOrderNo);
        SalesOrder.SalesLines.OrderPromising.Invoke();
    end;

    local procedure PostConsumptionJournal(ItemNo: Code[20]; Quantity: Decimal; OrderNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch2."Journal Template Name", ItemJournalBatch2.Name, ItemJournalLine."Entry Type"::Consumption,
          ItemNo, Quantity);
        ItemJournalLine.Validate("Source No.", ItemNo);
        ItemJournalLine.Validate("Order No.", OrderNo);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch2."Journal Template Name", ItemJournalBatch2.Name);
    end;

    local procedure PostOutputJournal(ItemNo: Code[20]; OrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate2, ItemJournalBatch3);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate2, ItemJournalBatch3, ItemNo, OrderNo);
        ItemJournalLine.Validate("Output Quantity", Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate2.Name, ItemJournalBatch3.Name);
    end;

    local procedure PostInventoryActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);  // Post as Receive.
    end;

    local procedure PostPurchaseDocument(PurchaseHeader: Record "Purchase Header"; var DocumentNo: Code[20])
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Posting as Receive and Invoice.
    end;

    local procedure PostSalesDocument(SalesHeader: Record "Sales Header"; var DocumentNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Posting as Ship and Invoice.
    end;

    local procedure PostWarehouseReceiptFromPurchaseOrderWithWarehouseClassCode(var PurchaseHeader: Record "Purchase Header"; var Bin: Record Bin; LocationCode: Code[10]; WarehouseClassCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        Zone: Record Zone;
    begin
        LibraryWarehouse.CreateZone(
          Zone,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Zone.FieldNo(Code), DATABASE::Zone), 1,
            LibraryUtility.GetFieldLength(DATABASE::Zone, Zone.FieldNo(Code))),
          LocationCode, LibraryWarehouse.SelectBinType(true, false, false, false), WarehouseClassCode, '', 0, false);  // Value required for Zone Rank. Taking True for Receive Zone.
        CreateBinWithWarehouseClassCode(Bin, Zone, WarehouseClassCode);
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        UpdateZoneAndBinCodeOnWarehouseReceiptLine(Bin, PurchaseHeader."No.");
        PostWarehouseReceipt(PurchaseHeader."No.");
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

    local procedure PostWarehouseShipment(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure RegisterPickFromProdOrder(ProdOrder: Record "Production Order")
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryVariableStorage.Enqueue(PickActivityCreatedMsg); // Enqueue for MessageHandler.
        ProdOrder.CreatePick(UserId, 0, false, false, false); // SetBreakBulkFilter False,DoNotFillQtyToHandle False,PrintDocument False.
        RegisterWarehouseActivity(
          WhseActivityHeader."Source Document"::"Prod. Consumption", ProdOrder."No.",
          WhseActivityLine."Activity Type"::Pick);
    end;

    local procedure RegisterPutAwayFromPurchaseOrder(ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");
    end;

    local procedure RegisterWarehouseActivity(SourceDocument: Enum "Whse. Activity Sorting Method"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure ChangeQtyToHandleInWarehouseActivityLines(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; Quantity: array[2] of Decimal; LotNo: array[2] of Code[20])
    begin
        ChangeQtyToHandleInOneWarehouseActivityLine(SourceDocument, SourceNo, ActivityType, Quantity[1], LotNo[1]);
        ChangeQtyToHandleInOneWarehouseActivityLine(SourceDocument, SourceNo, ActivityType, Quantity[2], LotNo[2]);
    end;

    local procedure ChangeQtyToHandleInOneWarehouseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; QuantityToHandle: Decimal; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        WarehouseActivityLine.FindSet(true);
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QuantityToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure RunGetBinContentOnWhseInternalPutAway(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; ItemNo: Code[20])
    var
        BinContent: Record "Bin Content";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Movement);
        WhseWorksheetTemplate.FindFirst();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationWhite.Code);
        WhseWorksheetLine.Init();
        WhseWorksheetLine.Validate("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.Validate(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.Validate("Location Code", LocationWhite.Code);
        BinContent.SetRange("Location Code", LocationWhite.Code);
        BinContent.SetRange("Item No.", ItemNo);
        LibraryWarehouse.WhseGetBinContent(
            BinContent, WhseWorksheetLine, WhseInternalPutAwayHeader, "Warehouse Destination Type 2"::MovementWorksheet);
    end;

    local procedure SetRequirePickOnLocation(var Location: Record Location; RequirePick: Boolean)
    begin
        Location."Require Pick" := RequirePick;
        Location.Modify(true);
    end;

    local procedure SelectAvailableLotOnWarehouseShipmentLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; Qty: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssitEditLotNo);
        LibraryVariableStorage.Enqueue(Qty);
        WarehouseShipmentLine.OpenItemTrackingLines();
    end;

    local procedure UndoSalesShipment(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(UndoShipmentConfirmMsg);
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange("No.", ItemNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UpdateBinOnWarehouseShipmentLine(Bin: Record Bin; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SourceNo);
        WarehouseShipmentLine.Validate("Zone Code", Bin."Zone Code");
        WarehouseShipmentLine.Validate("Bin Code", Bin.Code);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure UpdateExpirationDateOnReservationEntry(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Expiration Date", WorkDate());  // Value required for test.
    end;

    local procedure UpdateZoneAndBinCodeOnWarehouseReceiptLine(Bin: Record Bin; SourceNo: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptLine.Validate("Zone Code", Bin."Zone Code");
        WarehouseReceiptLine.Validate("Bin Code", Bin.Code);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure UpdateQuantityToHandleOnWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        FindWarehouseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode, ItemNo);
        WhseWorksheetLine.DeleteQtyToHandle(WhseWorksheetLine);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.Validate("Qty. to Handle", Quantity);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure UpdateQuantityToHandleOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; QuantityToHandle: Decimal; NextLine: Boolean)
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.Validate("Qty. to Handle", QuantityToHandle);
        WarehouseActivityLine.Modify(true);
        if NextLine then
            WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Qty. to Handle", QuantityToHandle);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateQtyToHandleOnItemTrackingLineForTransfer(TransferHeaderNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; QtyToHandle: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FilterReservEntryForTransferLine(ReservationEntry, TransferHeaderNo, ItemNo, LotNo);
        ReservationEntry.FindFirst();
        ReservationEntry.Validate("Qty. to Handle (Base)", QtyToHandle);
        ReservationEntry.Modify(true);
    end;

    local procedure UpdateProductionOrderAndRefresh(var ProductionOrder: Record "Production Order"; SourceNo: Code[20])
    begin
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Released, SourceNo);
        ProductionOrder.Validate("Due Date", WorkDate());
        ProductionOrder.Validate("Starting Date-Time", CurrentDateTime);
        ProductionOrder.Validate("Ending Date-Time", CurrentDateTime);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure UpdateInventoryUsingWhseJournal(Bin: Record Bin; Item: Record Item; Quantity: Decimal; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; ItemTracking: Boolean)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        WarehouseJournalLine.Validate("Variant Code", VariantCode);
        WarehouseJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseJournalLine.Modify(true);
        if ItemTracking then
            WarehouseJournalLine.OpenItemTrackingLines();
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure UpdateInventoryWithItemTrackingUsingWhseJournal(Bin: Record Bin; Item: Record Item; LotNos: array[2] of Code[20]; LotQty: Decimal)
    var
        NoOfLots: Integer;
        i: Integer;
    begin
        NoOfLots := ArrayLen(LotNos);
        LibraryVariableStorage.Enqueue(NoOfLots);
        for i := 1 to NoOfLots do begin
            LibraryVariableStorage.Enqueue(LotQty);
            LibraryVariableStorage.Enqueue(LotNos[i]);
        end;
        UpdateInventoryUsingWhseJournal(Bin, Item, LotQty * NoOfLots, '', Item."Base Unit of Measure", true);
    end;

    local procedure UpdateProductionBOMOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateReserveOnItem(var Item: Record Item)
    begin
        Item.Find();
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
    end;

    local procedure UpdateTransferOrderLineForQtyToReceive(DocumentNo: Code[20]; ItemNo: Code[20]; QtyToReceive: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        FindTransferLine(TransferLine, DocumentNo, ItemNo);
        TransferLine.Validate("Qty. to Receive", QtyToReceive);
        TransferLine.Modify(true);
    end;

    local procedure UpdatePickLineZoneCodeAndBinCode(SourceDocNo: Code[20]; ActionType: Enum "Warehouse Action Type"; ZoneCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.SetRange(Quantity, Qty);
        WhseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(WhseActivityLine, WhseActivityLine."Source Document"::"Sales Order", SourceDocNo, WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.Validate("Qty. to Handle", 0);
        WhseActivityLine.Validate("Zone Code", ZoneCode);
        WhseActivityLine.Validate("Bin Code", BinCode);
        WhseActivityLine.Validate("Qty. to Handle", Qty);
        WhseActivityLine.Modify();
    end;

    local procedure UpdatePickLineQtyToHandleAndLotNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyToHandle: Decimal; LotNo: Code[50])
    begin
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateShippingAgentCodeInWhseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ShippingAgent: Record "Shipping Agent")
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        WarehouseShipmentHeader.Validate("Shipping Agent Code", ShippingAgent.Code);
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure UpdateWhseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ShippingAgentServices: Record "Shipping Agent Services"; QtyToShip: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentHeader.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        WarehouseShipmentHeader.Modify(true);
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure UpdateShippingAgentCodeAndShippingAgentServiceCode(var SalesHeader: Record "Sales Header")
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        PeriodLength: DateFormula;
    begin
        Evaluate(PeriodLength, '<1D>');
        CreateShippingAgentWithServices(ShippingAgent, ShippingAgentServices, PeriodLength, 1);
        SalesHeader.Validate("Shipping Agent Code", ShippingAgent.Code);
        SalesHeader.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        SalesHeader.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure UpdatePickLinesLot(SourceDocNo: Code[20]; PickLineQty: Decimal; NewLotNo: Code[50])
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.SetRange(Quantity, PickLineQty);
        FindWarehouseActivityLine(WhseActivityLine, WhseActivityLine."Source Document"::"Sales Order", SourceDocNo, WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.ModifyAll("Lot No.", NewLotNo);
    end;

    local procedure UpdateShipmentPostingPolicyOnWarehouseSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Shipment Posting Policy", WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify(true);
    end;

    local procedure UpdateValueEntryUserID(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, ItemNo, false);
        ValueEntry."User ID" := LibraryUtility.GenerateGUID();
        ValueEntry.Modify();
    end;

    local procedure SelectItemTrackingForProdOrderComponents(ComponentItemNo: Code[20])
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.OpenView();
        ProdOrderComponents.FILTER.SetFilter("Item No.", ComponentItemNo);
        ProdOrderComponents.ItemTrackingLines.Invoke(); // Open ItemTrackingPageHandler and select Item Tracking on page handler.
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, TemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal; VariantCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Variant Code", VariantCode);
    end;

    local procedure VerifyItemLedgerEntryWithLotNo(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; LotNo: Code[50]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemLedgerEntryForUndoShipment(ItemNo: Code[20]; Positive: Boolean; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, Positive);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedInventoryPutLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
    begin
        PostedInvtPutAwayLine.SetRange("Source Document", SourceDocument);
        PostedInvtPutAwayLine.SetRange("Source No.", SourceNo);
        PostedInvtPutAwayLine.FindFirst();
        PostedInvtPutAwayLine.TestField("Location Code", LocationCode);
        PostedInvtPutAwayLine.TestField("Item No.", ItemNo);
        PostedInvtPutAwayLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedInventoryPickLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; Next: Boolean)
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        PostedInvtPickLine.SetRange("Source Document", SourceDocument);
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.FindSet();
        if Next then
            PostedInvtPickLine.Next();
        PostedInvtPickLine.TestField("Location Code", LocationCode);
        PostedInvtPickLine.TestField("Item No.", ItemNo);
        PostedInvtPickLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedInventoryPickLineForTransferOrder(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; LotNo: Code[10])
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        PostedInvtPickLine.SetRange("Source Document", PostedInvtPickLine."Source Document"::"Outbound Transfer");
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.FindFirst();
        PostedInvtPickLine.TestField("Item No.", ItemNo);
        PostedInvtPickLine.TestField(Quantity, Quantity);
        PostedInvtPickLine.TestField("Location Code", LocationCode);
        PostedInvtPickLine.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyPostedPurchaseInvoice(No: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.Get(No);
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("No.", ItemNo);
        PurchInvLine.TestField("Location Code", LocationCode);
        PurchInvLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedSalesInvoice(No: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.Get(No);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("No.", ItemNo);
        SalesInvoiceLine.TestField("Location Code", LocationCode);
        SalesInvoiceLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedSalesShipmentLine(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.FindSet();
        SalesShipmentLine.TestField(Quantity, Quantity);
        SalesShipmentLine.Next();
        SalesShipmentLine.TestField(Quantity, -Quantity);
    end;

    local procedure VerifyPostedWhseShipmentLine(SourceDocument: Enum "Whse. Activity Sorting Method"; SourceNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        Bin: Record Bin;
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        Bin.Get(LocationCode, BinCode);
        PostedWhseShipmentLine.SetRange("Source Document", SourceDocument);
        PostedWhseShipmentLine.SetRange("Source No.", SourceNo);
        PostedWhseShipmentLine.SetRange("Location Code", LocationCode);
        PostedWhseShipmentLine.SetRange("Item No.", ItemNo);
        PostedWhseShipmentLine.FindFirst();
        PostedWhseShipmentLine.TestField(Quantity, Quantity);
        PostedWhseShipmentLine.TestField("Zone Code", Bin."Zone Code");
        PostedWhseShipmentLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyPurchaseReturnOrderLine(DocumentNo: Code[20]; ItemNo: Code[20]; ReturnQuantityShipped: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Return Qty. to Ship", 0);  // Value required for the test.
        PurchaseLine.TestField("Return Qty. Shipped", ReturnQuantityShipped);
    end;

    local procedure VerifyRegisteredWarehouseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.FindFirst();
        RegisteredWhseActivityLine.TestField("Item No.", ItemNo);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
        RegisteredWhseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyReservationEntry(LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesHeaderAndSalesShipmentHeader(SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeaderNo);
        SalesHeader.TestField("Shipping Agent Service Code", '');
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        SalesShipmentHeader.TestField("Shipping Agent Service Code", '');
    end;

    local procedure VerifyShippingAgentServiceInSalesHeaderAndSalesShipmentHeader(ShippingAgentServices: Record "Shipping Agent Services"; SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeaderNo);
        SalesHeader.TestField("Shipping Agent Service Code", ShippingAgentServices.Code);
        SalesShipmentHeader.Init();
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.SetRange("Shipping Agent Service Code", ShippingAgentServices.Code);
        Assert.RecordIsNotEmpty(SalesShipmentHeader);
    end;

    local procedure VerifySerialNoOnWarehouseActivityLine(SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        "Count": Integer;
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet();
        Count := 1;
        repeat
            WarehouseActivityLine.TestField("Serial No.", Format(Count));  // Value required for the Serial No.
            WarehouseActivityLine.TestField(Quantity, 1);  // Value required for the Quantity.
            Count += 1;
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyShippingValuesInWarehouseActiityLine(WarehouseActivityLine: Record "Warehouse Activity Line"; TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line")
    begin
        WarehouseActivityLine.TestField("Shipment Method Code", TransferHeader."Shipment Method Code");
        WarehouseActivityLine.TestField("Shipping Agent Code", TransferLine."Shipping Agent Code");
        WarehouseActivityLine.TestField("Shipping Agent Service Code", TransferLine."Shipping Agent Service Code");
    end;

    local procedure VerifyTransferOrderLine(DocumentNo: Code[20]; ItemNo: Code[20]; QtyToShip: Decimal; QuantityShipped: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        FindTransferLine(TransferLine, DocumentNo, ItemNo);
        TransferLine.TestField("Qty. to Ship", QtyToShip);  // Value required for the test.
        TransferLine.TestField("Quantity Shipped", QuantityShipped);
    end;

    local procedure VerifyTransferOrderLineForQtyToReceive(DocumentNo: Code[20]; ItemNo: Code[20]; QtyToReceive: Decimal; QuantityReceived: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        FindTransferLine(TransferLine, DocumentNo, ItemNo);
        TransferLine.TestField("Qty. to Receive", QtyToReceive);
        TransferLine.TestField("Quantity Received", QuantityReceived);
    end;

    local procedure VerifyValueEntryUserID(ItemNo: Code[20]; CheckedUserId: Code[50])
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, ItemNo, true);
        ValueEntry.TestField("User ID", CheckedUserId);
    end;

    local procedure VerifyWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseActivityLineWithBin(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        VerifyWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Action Type"::Take, ItemNo, Quantity);
        WarehouseActivityLine.TestField("Location Code", LocationCode);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyWarehouseReceiptLine(SourceDocument: Enum "Whse. Activity Sorting Method"; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; QtyToReceive: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo);
        WarehouseReceiptLine.TestField("Item No.", ItemNo);
        WarehouseReceiptLine.TestField(Quantity, Quantity);
        WarehouseReceiptLine.TestField("Qty. to Receive", QtyToReceive);
    end;

    local procedure VerifyWarehouseReceiptCreated(SourceDocument: Enum "Whse. Activity Sorting Method"; SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Expected: Boolean)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo);
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.SetRange("Location Code", LocationCode);
        Assert.AreNotEqual(Expected, WarehouseReceiptLine.IsEmpty,
          'Expect the receipt line with location ' + LocationCode + ' exist: ' + Format(Expected) +
          ', contrary to the actual result');
    end;

    local procedure VerifyWarehouseShipmentCreated(SourceDocument: Enum "Whse. Activity Sorting Method"; SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Expected: Boolean)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.SetRange("Location Code", LocationCode);
        Assert.AreNotEqual(Expected, WarehouseShipmentLine.IsEmpty,
          'Expect the shipment line with location ' + LocationCode + ' exist: ' + Format(Expected) +
          ', contrary to the actual result');
    end;

    local procedure VerifyWarehouseShipmentLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentLine.SetRange("Location Code", LocationCode);
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseEntry(ItemNo: Code[20]; EntryType: Option; VariantCode: Code[10]; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Variant Code", VariantCode);
        WarehouseEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyBinContent(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal; WarehouseClassCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
        BinContent.TestField("Variant Code", VariantCode);
        BinContent.CalcFields(Quantity);
        BinContent.TestField(Quantity, Quantity);
        BinContent.TestField("Warehouse Class Code", WarehouseClassCode);
    end;

    local procedure VerifyBinCodeAndQuantityOnWarehouseActivityLine(SourceNo: Code[20]; ExpectedBinCode: Code[20]; ExpectedQty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", ExpectedBinCode);
        WarehouseActivityLine.TestField(Quantity, ExpectedQty);
    end;

    local procedure VerifyRequsitionLine(ItemNo: Code[20]; ExpectedQty: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        Assert.IsFalse(RequisitionLine.IsEmpty, RequsitionLineShouldCreatedErr);
        RequisitionLine.FindFirst();
        Assert.AreEqual(ExpectedQty, RequisitionLine.Quantity, QuantityErr);
    end;

    local procedure VerifyReservEntryLineExist(LocationCode: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; LotQty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.SetRange(Positive, true);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange(Quantity, LotQty);
        Assert.IsFalse(ReservationEntry.IsEmpty, ReservEntryNotExistErr);
    end;

    local procedure VerifyReservationEntryLine(SalesHeaderNo: Code[20]; LotNo: Code[50]; ExpectedReservedQuantityForLotNo: Decimal; ExpectedSurplusQuantityForLotNo: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        ReservedQty: Decimal;
        SurplusQty: Decimal;
    begin
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Source ID", SalesHeaderNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.CalcSums("Qty. to Handle (Base)");
        ReservedQty := ReservationEntry."Qty. to Handle (Base)";

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.CalcSums("Qty. to Handle (Base)");
        SurplusQty := ReservationEntry."Qty. to Handle (Base)";
        Assert.AreEqual(ExpectedReservedQuantityForLotNo, ReservedQty, QuantityMustBeEqualErr);
        Assert.AreEqual(ExpectedSurplusQuantityForLotNo, SurplusQty, QuantityMustBeEqualErr);
    end;

    local procedure UpdateWarehouseActivityLineQtyToHandleForMultipleLots(DocNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ItemNo: Code[20]; var LotNos: array[3] of Code[10]; var Quantity: array[3] of Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", DocNo, ActivityType);

        // Modify pick quantities to partial quantity for each lot
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        for i := 1 to ArrayLen(LotNos) do begin
            WarehouseActivityLine.SetRange("Lot No.", LotNos[i]);
            WarehouseActivityLine.FindFirst();
            WarehouseActivityLine.Validate("Qty. to Handle", Quantity[i] - i);
            WarehouseActivityLine.Modify(true);
        end;
    end;

    local procedure CreateInventoryForMultipleLotItem(Item: Record Item; LocationCode: Code[10]; var LotNos: array[3] of Code[10]; var Quantity: array[3] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(LotNos) do begin
            LotNos[i] := LibraryUtility.GenerateGUID();
            Quantity[i] := LibraryRandom.RandInt(20 * i);
            CreateAndPostItemJournalLineWithLotNoEnqueued(Item."No.", Quantity[i], LocationCode, '', LotNos[i]);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingQuantity: Variant;
        DequeueVariable: Variant;
        LineCount: Integer;
        Quantity: Decimal;
        QtyInTrackingSpecification: Decimal;
        NoOfLots: Integer;
        i: Integer;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::"Assign Serial No.":
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingMode::"Assign Lot No.":
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
                end;
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::VerifyTracking:
                begin
                    ItemTrackingLines.Last();
                    repeat
                        ItemTrackingLines."Quantity (Base)".AssertEquals(1);  // Using One for Serial No.
                        ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(1);  // Using One for Serial No.
                        Assert.IsTrue(ItemTrackingLines."Serial No.".Value > ' ', SerialNoErr);
                        LineCount += 1;
                    until not ItemTrackingLines.Previous();
                    LibraryVariableStorage.Dequeue(TrackingQuantity);
                    Assert.AreEqual(TrackingQuantity, LineCount, NumberOfLineEqualErr);  // Verify Number of line - Tracking Line.
                end;
            ItemTrackingMode::"Split Lot No.":
                begin
                    Quantity := ItemTrackingLines.Quantity3.AsDecimal() / 2;  // Value required for test.
                    AssignLotNoOnItemTrackingLine(ItemTrackingLines, Quantity);
                    ItemTrackingLines.Next();
                    AssignLotNoOnItemTrackingLine(ItemTrackingLines, Quantity);
                end;
            ItemTrackingMode::AssitEditLotNo:
                begin
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines."Lot No.".AssistEdit();
                end;
            ItemTrackingMode::"Set Lot No.":
                SetLotNoAndQuantityInItemTrackingLine(ItemTrackingLines, LibraryVariableStorage.DequeueDecimal());
            ItemTrackingMode::"Assign Multiple Lines":
                begin
                    NoOfLots := LibraryVariableStorage.DequeueInteger();
                    QtyInTrackingSpecification := LibraryVariableStorage.DequeueDecimal();
                    for i := 1 to NoOfLots do begin
                        ItemTrackingLines.New();
                        SetLotNoAndQuantityInItemTrackingLine(ItemTrackingLines, QtyInTrackingSpecification);
                    end;
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        DequeueVariable: Variant;
        TrackingQuantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        TrackingQuantity := WhseItemTrackingLines.Quantity3.AsDecimal();
        case ItemTrackingMode of
            ItemTrackingMode::"Assign Serial No.":
                begin
                    WhseItemTrackingLines.First();
                    repeat
                        WhseItemTrackingLines."Serial No.".SetValue(Format(TrackingQuantity));
                        WhseItemTrackingLines.Quantity.SetValue(1);
                        TrackingQuantity -= 1;
                        WhseItemTrackingLines.Next();
                    until TrackingQuantity = 0;
                end;
            ItemTrackingMode::"Assign Lot No.":
                begin
                    WhseItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
                    WhseItemTrackingLines.Quantity.SetValue(TrackingQuantity);
                end;
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingEditSeveralLinesLOT(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        DequeueVariable: Variant;
        NumOfLines: Integer;
        LOTQty: Decimal;
        LOTCode: Code[20];
        i: Integer;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        NumOfLines := DequeueVariable;

        for i := 1 to NumOfLines do begin
            LibraryVariableStorage.Dequeue(DequeueVariable);
            LOTQty := DequeueVariable;
            LibraryVariableStorage.Dequeue(DequeueVariable);
            LOTCode := DequeueVariable;
            WhseItemTrackingLines."Lot No.".SetValue(LOTCode);
            WhseItemTrackingLines.Quantity.SetValue(LOTQty);
            WhseItemTrackingLines.Next();
        end;

        WhseItemTrackingLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderPromisingHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.CapableToPromise.Invoke();
        OrderPromisingLines.AcceptButton.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure WarehouseActivityLinesHandler(var WarehouseActivityLines: TestPage "Warehouse Activity Lines")
    begin
        WarehouseActivityLines.ShowDocument.Invoke();
    end;

    [PageHandler]
    procedure WarehouseShipmentCardPageHandler(var WarehouseShipment: TestPage "Warehouse Shipment")
    begin
    end;

    [PageHandler]
    procedure WarehouseShipmentListPageHandler(var WarehouseShipmentList: TestPage "Warehouse Shipment List")
    begin
    end;

    [PageHandler]
    procedure WarehouseReceiptCardPageHandler(var WarehouseReceipt: TestPage "Warehouse Receipt")
    begin
    end;

    [PageHandler]
    procedure WarehouseReceiptListPageHandler(var WarehouseReceipts: TestPage "Warehouse Receipts")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WarehousePickHandler(var WarehousePick: TestPage "Warehouse Pick")
    begin
        LibraryVariableStorage.Enqueue(RegisterPickConfirmMsg);  // Enqueue for MessageHandler.
        WarehousePick.RegisterPick.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInventoryPutAwayPickHandler(var CreateInvtPutAwayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        LibraryVariableStorage.Enqueue(InvPickMsg);
        CreateInvtPutAwayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutAwayPickMvmt.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, LocalMessage) > 0, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(
          StrPos(ConfirmMessage, LocalMessage) > 0, StrSubstNo('ConfirmHandler got message %1, expected %2', ConfirmMessage, LocalMessage));
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerForUndoPosetReceipt(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerSimple(ConfirmMessage: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
