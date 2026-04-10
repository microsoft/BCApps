codeunit 137152 "SCM Warehouse - Receiving"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        isInitialized := false;
    end;

    var
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationWhite: Record Location;
        LocationWhite2: Record Location;
        LocationWhite3: Record Location;
        LocationOrange: Record Location;
        LocationSilver: Record Location;
        LocationSilver2: Record Location;
        LocationWhite4: Record Location;
        LocationRed: Record Location;
        LocationRed2: Record Location;
        LocationBlue: Record Location;
        LocationGreen: Record Location;
        LocationBrown: Record Location;
        LocationInTransit: Record Location;
        LocationWithRequirePick: Record Location;
        LocationWithRequirePick2: Record Location;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        isInitialized: Boolean;
        InvPutAwayMessage: Label 'Number of Invt. Put-away activities created';
        InvPickMessage: Label 'Number of Invt. Pick activities created';
        NothingToCreateMessage: Label 'There is nothing to create.';
        InventoryPickActivitiesCreatedMessage: Label 'Number of Invt. Pick activities created: 2 out of a total of 3.';
        PutawayNotCreatedError: Label 'Put-away not created for one or more items based on the template and capacity.';
        UnexpectedError: Label 'Unexpected Error.';
        PutAwayActivityCreatedMessage: Label 'Put-away activity no.';
        PickActivityCreatedMessage: Label 'Pick activity no. ';
        CannotHandleMoreUnitsError: Label 'You cannot handle more than the outstanding';
        ExceedsAvailableCapacity: Label '%1 to place (%2) exceeds the available capacity (%3) on %4 %5.\Do you still want to use this %4 ?', Comment = '%1= Field Caption,%2= Current capacity value,%3= Available Capacity,%4= Table Caption, %5= Field value.';
        ExceedsMaximumCubage: Label 'The total cubage %1 of the %2 for the %5 exceeds the %3 %4 of the %5.\Do you still want enter this %2?', Comment = '%1 = Cubage Value, %2 = Maximum Quantity, %3 =  Maximum Cubage Caption, %4 = Maximum Cubage Value, %5 = Bin Table Caption';
        TransferOrderDeletedMessage: Label 'Transfer order %1 was successfully posted and is now deleted.';
        WarehouseRequestCreatedMessage: Label 'Inbound Whse. Requests are created.';
        QuantityMustBeSame: Label 'Quantity must be same.';
        NoOfLinesMustBeGreater: Label 'No. of lines must be greater on Header.';
        NothingToHandle: Label 'Nothing to handle.';
        CancelAllReservationsConfirm: Label 'Do you want to cancel all reservations';
        QuantityBaseError: Label 'Quantity (Base) must not be %1 in Bin Content Location Code=''%2'',Bin Code=''%3'',Item No.=''%4'',Variant Code='''',Unit of Measure Code=''%5''.', Comment = '%1 = Quantity, %2 = Location Code, %3 = Bin Code, %4 = Item No., %5 = Unit of Measure Code';
        ItemNoMustNotBeChangedWhenWarehouseActivityLineExists: Label '%1 must not be changed when a Warehouse Activity Line for this %2 exists', Comment = '%1 = Item No.,%2 = Table Caption, %3 = Document No., %4 = Line No.';
        NegativeAdjustmentConfirmMessage: Label 'One or more reservation entries exist for the item with';
        PostJournalLinesConfirmationMessage: Label 'Do you want to post the journal lines';
        JournalLinesPostedMessage: Label 'The journal lines were successfully posted';
        ItemLedgerEntryErr: Label 'It should generate the right count Item Ledger Entry';
        ShipmentBinCodeErr: Label 'Bin Code Should be Shipment Bin Code of Location';
        ReceiptBinCodeErr: Label 'Bin Code Should be Receipt Bin Code of Location';
        PickQuantityBaseErr: Label 'Pick Quantity (Base) was Calculated incorrectly';
        WarehouseHeaderDeleteConfirmationMsg: Label 'The Whse. Receipt is not completely received.\Do you really want to delete the Whse. Receipt?';
        ExceedsErr: Label 'exceeds the available capacity';
        FromBinBlankErr: Label 'From Bin Should be blank';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure NothingToCreateForInventoryPuAwayWithRequirePick()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Item and Post Item Journal. Create Sales Order with multiple lines with Shipping Advice Complete.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(
          Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", LibraryRandom.RandDec(10, 2), LocationWithRequirePick.Code,
          false);
        CreateAndReleaseSalesOrderWithMultipleLinesUsingShippingAdvice(
          SalesHeader, SalesHeader."Shipping Advice"::Complete, Item."No.", Item."No.", LibraryRandom.RandDec(10, 2),
          LocationWithRequirePick.Code, true);
        LibraryVariableStorage.Enqueue(NothingToCreateMessage);  // Handled in Message Handler.

        // Exercise: Invoke Create Inventory Put-Away and handle the Message.
        CreateInventoryActivity(
          WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", LocationWithRequirePick.Code, true, false);

        // Verify: Nothing to Create Message in the Message Handler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateInventoryPickWithDifferentShippingAdvice()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        Quantity: Decimal;
    begin
        // Setup: Create two Items. Post Item Journal line for one Item. Create and release Sales Orders with different Shipping Advice.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostItemJournalLine(
          Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", 100 + LibraryRandom.RandDec(10, 2),
          LocationWithRequirePick2.Code, false);  // Large value required for the test.
        CreateAndReleaseSalesOrderWithMultipleLinesUsingShippingAdvice(
          SalesHeader, SalesHeader."Shipping Advice"::Partial, Item."No.", '', Quantity, LocationWithRequirePick2.Code, false);
        CreateAndReleaseSalesOrderWithMultipleLinesUsingShippingAdvice(
          SalesHeader2, SalesHeader."Shipping Advice"::Complete, Item."No.", Item2."No.", Quantity, LocationWithRequirePick2.Code, true);
        CreateAndReleaseSalesOrderWithMultipleLinesUsingShippingAdvice(
          SalesHeader3, SalesHeader."Shipping Advice"::Partial, Item."No.", Item2."No.", Quantity, LocationWithRequirePick2.Code, true);
        LibraryVariableStorage.Enqueue(InventoryPickActivitiesCreatedMessage);  // Handled in Message Handler.

        // Exercise: Create Inventory Pick for all Sales Orders on the Location.
        WarehouseRequest.SetRange("Location Code", LocationWithRequirePick2.Code);
        WarehouseRequest.FindFirst();
        LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, false, true, false);

        // Verify: Warehouse Activity Lines.
        asserterror FindWarehouseActivityLine(
            WarehouseActivityLine, WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader2."No.",
            WarehouseActivityLine."Activity Type"::"Invt. Pick");
        Assert.AssertNothingInsideFilter();
        VerifyWarehouseActivityLine(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Action Type"::" ", Item."No.",
          Quantity, LocationWithRequirePick2.Code, Item."Base Unit of Measure", '', '', '');
        VerifyWarehouseActivityLine(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader3."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Action Type"::" ", Item."No.",
          Quantity, LocationWithRequirePick2.Code, Item."Base Unit of Measure", '', '', '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartialPostInventoryPutAwayWithLotAndBin()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        WarehouseRequest: Record "Warehouse Request";
        LotNo: Variant;
        Quantity: Decimal;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        // Setup: Create Item with Lot Specific Tracking. Create and release Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());  // Taking True for Lot.
        FindBin(Bin, LocationSilver.Code);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for ItemTrackingPageHandler.
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationSilver.Code, Bin.Code, Item."No.", Quantity, Item."Base Unit of Measure", true);
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Enqueue(InvPutAwayMessage);  // Enqueue for MessageHandler.
        CreateInventoryActivity(
          WarehouseRequest."Source Document"::"Purchase Order", PurchaseHeader."No.", LocationSilver.Code, true, false);

        // Exercise: Update Bin Code and Lot No. on Inventory Put-Away line and Post with Partial Quantity.
        PostInventoryPutAwayWithPartialQuantity(PurchaseHeader."No.", Bin.Code, LotNo, Quantity / 2);  // Value required for the test.
        PostInventoryPutAwayWithPartialQuantity(PurchaseHeader."No.", Bin.Code, LotNo, Quantity / 2);  // Value required for the test.

        // Verify: Posted Inventory Put-Away line.
        VerifyPostedInventoryPutLine(
          PostedInvtPutAwayLine."Source Document"::"Purchase Order", PurchaseHeader."No.", LocationSilver.Code, Item."No.", Quantity / 2,
          Item."Base Unit of Measure", LotNo);  // Value required for the test.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayErrorWithCarryOutActionMessagePlan()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Reordering Policy as Order. Post Item Journal line. Create and Release Sales Order.
        Initialize();
        CreateItemWithOrderReorderingPolicy(Item);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostItemJournalLine(Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, LocationOrange.Code, false);
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, LocationOrange.Code, Item."No.", Quantity, false);

        // Exercise: Calculate Plan on Requisition line and Carry out Action Message to create a Purchase Order.
        CarryOutActionMessageAfterCalculatePlanOnRequisitionLine(Item);

        // Verify: Reserved Quantity on Purchase Line.
        VerifyReservedQuantityOnPurchaseLine(Item."No.", Quantity);

        // Exercise: Create Inventory Put-Away from Sales Order.
        CreateAndReleaseSalesDocument(SalesHeader2, SalesHeader."Document Type"::Order, LocationOrange.Code, Item."No.", Quantity, false);
        LibraryVariableStorage.Enqueue(NothingToCreateMessage);  // Handled in Message Handler.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", LocationOrange.Code, true, false);

        // Verify: Nothing to Create Message in the Message Handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PartialPostInventoryPickWithLotNo()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseRequest: Record "Warehouse Request";
        LotNo: Variant;
        Quantity: Decimal;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        // Setup: Create Item with Lot Specific Tracking. Release and Post Purchase Order with Lot No. Create and Release Sales Order.
        // Create Inventory Pick. Update Lot No. and Quantity to Handle on Inventory Pick Line.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());  // Taking True for Lot.
        FindBin(Bin, LocationSilver.Code);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for ItemTrackingPageHandler.
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationSilver.Code, Bin.Code, Item."No.", Quantity, Item."Base Unit of Measure", true);
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, LocationSilver.Code, Item."No.", Quantity, false);
        LibraryVariableStorage.Enqueue(InvPickMessage);  // Handled in Message Handler.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", LocationSilver.Code, false, true);
        UpdatePartialQuantityOnInventoryPickLine(WarehouseActivityHeader, SalesHeader."No.", LotNo, Quantity / 2);

        // Exercise: Post Inventory Pick with Partial Quantity.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);  // Post as Ship.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);  // Post as Ship.

        // Verify: Posted Inventory Pick Lines.
        VerifyPostedInventoryPickLine(SalesHeader."No.", LocationSilver.Code, Item."No.", Quantity / 2, LotNo, 0D, false);  // Value required for the test.
        VerifyPostedInventoryPickLine(SalesHeader."No.", LocationSilver.Code, Item."No.", Quantity / 2, LotNo, 0D, true);  // Value required for the test.
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,PutAwaySelectionPageHandler')]
    [Scope('OnPrem')]
    procedure BinCapacityErrorForCreatePutAwayFromPutAwayWorksheet()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PutAwayWorksheet: TestPage "Put-away Worksheet";
        Quantity: Decimal;
        SortActivity: Option;
    begin
        // Setup: Create Item. Set Maximum Quantity in Bin Content of Receive Bin of Location. Update Item Inventory using Warehouse Journal. Create and Release Purchase Order.
        // Create and Post the Warehouse Receipt. Open Put Away Worksheet page and invoke Get Warehouse Document.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(10);
        FindBinWithBinTypeCode(Bin, LocationWhite2.Code, true, false, false, false);  // Find Receive Bin.
        CreateBinContentWithMaxQuantity(Bin, Item, Quantity);
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '');
        CreatePurchaseOrderAndPostWarehouseReceipt(
          PurchaseHeader, LocationWhite2.Code, Item."No.", Quantity + LibraryRandom.RandDec(10, 2), Item."Base Unit of Measure");
        PutAwayWorksheet.OpenEdit();
        PutAwayWorksheet.GetWarehouseDocuments.Invoke();
        Commit();  // Commit is required here.

        // Exercise: Invoke Create Put-Away from Put-Away Worksheet and handle the Error.
        LibraryVariableStorage.Enqueue(SortActivity);  // Enqueue for WhseSourceCreateDocumentHandler.
        asserterror PutAwayWorksheet.CreatePutAway.Invoke();

        // Verify: Error Message.
        Assert.AreEqual(StrSubstNo(PutawayNotCreatedError), GetLastErrorText, UnexpectedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayFromPutAwayWorksheetWithSKU()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with different Put-Away Unit of Measure. Create Stock keeping Unit. Create and Release Purchase Order with multiple lines.
        // Create and Post Warehouse Receipt. Delete the Warehouse Put-Away.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithDifferentPutAwayUnitOfMeasure(Item, ItemUnitOfMeasure);
        CreateStockkeepingUnit(LocationWhite.Code, Item."No.", LocationWhite."Put-away Template Code");
        CreateAndReleasePurchaseOrderWithMultipleLines(
          PurchaseHeader, LocationWhite.Code, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure", ItemUnitOfMeasure.Code,
          '', '');
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationWhite.Code);
        LibraryVariableStorage.Enqueue(PutAwayActivityCreatedMessage);  // Handled in Message Handler.
        DeleteWarehouseActivityLine(PurchaseHeader."No.");
        NotificationLifecycleMgt.RecallAllNotifications();
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, true);  // Find Last Bin in PICK Zone.

        // Exercise: Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, LocationWhite.Code, Item."No.", Item."No.", 0, "Whse. Activity Sorting Method"::None, false);  // Taking 0 for Quantity.

        // Verify: Warehouse Activity Line.
        VerifyWarehouseActivityLine(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity,
          LocationWhite.Code, ItemUnitOfMeasure.Code, LocationWhite."Receipt Bin Code", '', '');
        VerifyWarehouseActivityLine(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity,
          LocationWhite.Code, ItemUnitOfMeasure.Code, Bin.Code, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SortingByActionTypeOnPutAwayFromPutAwayWorksheet()
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
        OldUsePutAwayWorksheet: Boolean;
    begin
        // Setup: Modify Use Put-Away Worksheet as True on Location. Create Items. Create Put-Away from two Purchase Orders.
        Initialize();
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, true);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CreatePurchaseOrderAndPostWarehouseReceipt(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure");
        CreatePurchaseOrderAndPostWarehouseReceipt(PurchaseHeader2, LocationWhite.Code, Item2."No.", Quantity, Item2."Base Unit of Measure");

        // Exercise.
        CreatePutAwayFromPutAwayWorksheet(
          WhseWorksheetLine, LocationWhite.Code, Item."No.", Item2."No.", 0, "Whse. Activity Sorting Method"::"Action Type", false);  // Taking 0 for Quantity.

        // Verify: Warehouse Activity Lines gets sorted with Action Type.
        FindWarehouseActivityLineForMultipleSourceDocuments(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", PurchaseHeader2."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        VerifyWarehouseActivityLinesForMultipleItemsWithTakeActionType(WarehouseActivityLine, Item."No.", Item2."No.", Quantity);
        VerifyWarehouseActivityLinesForMultipleItemsWithPlaceActionType(WarehouseActivityLine, Item2."No.", Item."No.", Quantity);

        // Tear Down.
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, OldUsePutAwayWorksheet);
    end;

    [Test]
    [HandlerFunctions('WhseShipmentCreatePickHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SortingByActionTypeOnPickFromGetSourceDocumentOnWarehouseShipment()
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        Quantity: Decimal;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        // Setup: Create Items. Create and register Put-Away from two Purchase Orders. Create two Sales Orders. Get Source Documents on Warehouse Shipment.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CreateAndRegisterPutAwayFromPurchaseOrder(
          PurchaseHeader, LocationWhite3.Code, Item."No.", Quantity, Item."Base Unit of Measure", false, ItemTrackingMode, '');
        CreateAndRegisterPutAwayFromPurchaseOrder(
          PurchaseHeader2, LocationWhite3.Code, Item2."No.", Quantity, Item2."Base Unit of Measure", false, ItemTrackingMode, '');
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, LocationWhite3.Code, Item."No.", Quantity, false);  // New Location required for the test.
        CreateAndReleaseSalesDocument(SalesHeader2, SalesHeader."Document Type"::Order, LocationWhite3.Code, Item2."No.", Quantity, false);
        CreateWarehouseShipmentHeaderWithLocation(WarehouseShipmentHeader, LocationWhite3.Code);
        WarehouseSourceFilter.SetFilter("Source No. Filter", '%1|%2', SalesHeader."No.", SalesHeader2."No.");
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, LocationWhite3.Code);
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        LibraryVariableStorage.Enqueue("Whse. Activity Sorting Method"::"Action Type");  // Enqueue for WhseSourceCreateDocumentHandler.
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetFilter("Source No.", '%1|%2', SalesHeader."No.", SalesHeader2."No.");
        LibraryVariableStorage.Enqueue(PickActivityCreatedMessage);  // Enqueue for Message Handler.

        // Exercise: Create Pick from Warehouse Shipment with Sort Activity as Action Type.
        WarehouseShipmentLine.CreatePickDoc(WarehouseShipmentLine, WarehouseShipmentHeader);

        // Verify: Warehouse Activity Lines gets sorted with Action Type.
        FindWarehouseActivityLineForMultipleSourceDocuments(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", SalesHeader2."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        VerifyWarehouseActivityLinesForMultipleItemsWithTakeActionType(WarehouseActivityLine, Item2."No.", Item."No.", Quantity);
        VerifyWarehouseActivityLinesForMultipleItemsWithPlaceActionType(WarehouseActivityLine, Item."No.", Item2."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSourceCreateDocumentHandler')]
    [Scope('OnPrem')]
    procedure SortingByActionTypeOnPutAwayFromInternalPutAway()
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Create and Release Warehouse Internal Put-Away.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        FindAdjustmentBin(Bin, LocationWhite);
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '');
        UpdateInventoryUsingWhseJournal(Bin, Item2, Quantity, '');
        CreateAndReleaseWarehouseInternalPutAway(WhseInternalPutAwayLine, Bin, Item."No.", Item2."No.", Quantity, Quantity);
        LibraryVariableStorage.Enqueue("Whse. Activity Sorting Method"::"Action Type");  // Enqueue for WhseSourceCreateDocumentHandler.
        LibraryVariableStorage.Enqueue(PutAwayActivityCreatedMessage);  // Enqueue for MessageHandler.
        WhseInternalPutAwayLine.SetFilter("Item No.", '%1|%2', Item."No.", Item2."No.");

        // Exercise: Create Put-Away from Internal Put-Away.
        WhseInternalPutAwayLine.CreatePutAwayDoc(WhseInternalPutAwayLine);

        // Verify: Warehouse Activity Lines gets sorted with Action Type.
        WarehouseActivityLine.SetFilter("Item No.", '%1|%2', Item."No.", Item2."No.");
        FindWarehouseActivityLineForMultipleSourceDocuments(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '', '', WarehouseActivityLine."Activity Type"::"Put-away");
        VerifyWarehouseActivityLinesForMultipleItemsWithTakeActionType(WarehouseActivityLine, Item."No.", Item2."No.", Quantity);
        VerifyWarehouseActivityLinesForMultipleItemsWithPlaceActionType(WarehouseActivityLine, Item."No.", Item2."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSourceCreateDocumentHandler')]
    [Scope('OnPrem')]
    procedure SortingByActionTypeOnPickFromInternalPick()
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Update Inventory using Warehouse Item Journal. Create Put-Away from Warehouse Internal Put-Away and Register it.
        // Create and Release Warehouse Internal Pick.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        FindAdjustmentBin(Bin, LocationWhite);
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '');
        UpdateInventoryUsingWhseJournal(Bin, Item2, Quantity, '');
        CreateAndReleaseWarehouseInternalPutAway(WhseInternalPutAwayLine, Bin, Item."No.", Item2."No.", Quantity, Quantity);
        LibraryVariableStorage.Enqueue("Whse. Activity Sorting Method"::None);  // Enqueue for WhseSourceCreateDocumentHandler.
        LibraryVariableStorage.Enqueue(PutAwayActivityCreatedMessage);  // Enqueue for MessageHandler.
        WhseInternalPutAwayLine.SetFilter("Item No.", '%1|%2', Item."No.", Item2."No.");
        WhseInternalPutAwayLine.CreatePutAwayDoc(WhseInternalPutAwayLine);
        WarehouseActivityLine.SetFilter("Item No.", '%1|%2', Item."No.", Item2."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '', WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndReleaseWarehouseInternalPick(WhseInternalPickHeader, WhseInternalPickLine, Bin, Item."No.", Item2."No.", Quantity, Quantity);
        LibraryVariableStorage.Enqueue("Whse. Activity Sorting Method"::"Action Type");  // Enqueue for WhseSourceCreateDocumentHandler.
        LibraryVariableStorage.Enqueue(PickActivityCreatedMessage);  // Enqueue for MessageHandler.
        WhseInternalPickLine.SetFilter("Item No.", '%1|%2', Item."No.", Item2."No.");

        // Exercise: Create Pick from Warehouse Internal Pick.
        WhseInternalPickLine.CreatePickDoc(WhseInternalPickLine, WhseInternalPickHeader);

        // Verify: Warehouse Activity Lines gets sorted with Action Type.
        WarehouseActivityLine.SetFilter("Item No.", '%1|%2', Item."No.", Item2."No.");
        FindWarehouseActivityLineForMultipleSourceDocuments(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.", '',
          WarehouseActivityLine."Activity Type"::Pick);
        VerifyWarehouseActivityLinesForMultipleItemsWithTakeActionType(WarehouseActivityLine, Item."No.", Item2."No.", Quantity);
        VerifyWarehouseActivityLinesForMultipleItemsWithPlaceActionType(WarehouseActivityLine, Item."No.", Item2."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SortingByActionTypeOnMovementFromMovementWorksheet()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Update Inventory using Warehouse Item Journal. Create Movement Worksheet Lines for both Items.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        FindAdjustmentBin(Bin, LocationWhite);
        UpdateInventoryUsingWhseJournal(Bin, Item, Quantity, '');
        UpdateInventoryUsingWhseJournal(Bin, Item2, Quantity, '');
        FindBinWithBinTypeCode(Bin2, LocationWhite.Code, false, true, false, false);  // Find BULK Bin.
        CreateWarehouseWorksheetNameForMovement(WhseWorksheetName);
        CreateMovementWorksheetLine(WhseWorksheetName, Item."No.", Bin, Bin2, Quantity);
        CreateMovementWorksheetLine(WhseWorksheetName, Item2."No.", Bin, Bin2, Quantity);

        // Exercise: Create Movement from Movement Worksheet Lines.
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::"Action Type", false, false, false);

        // Verify: Warehouse Activity Lines gets sorted with Action Type.
        WarehouseActivityLine.SetFilter("Item No.", '%1|%2', Item."No.", Item2."No.");
        FindWarehouseActivityLineForMultipleSourceDocuments(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '', '', WarehouseActivityLine."Activity Type"::Movement);
        VerifyWarehouseActivityLinesForMultipleItemsWithTakeActionType(WarehouseActivityLine, Item."No.", Item2."No.", Quantity);
        VerifyWarehouseActivityLinesForMultipleItemsWithPlaceActionType(WarehouseActivityLine, Item."No.", Item2."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPutAwayWithPurchaseUnitOfMeasureAndLotNo()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        LotNo: Variant;
        Quantity: Decimal;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        // Setup: Create Item with Lot specific Tracking and different Purchase Unit of Measure.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());  // Taking True for Lot.
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", 0);  // Taking 0 for Blank Length.
        UpdatePurchaseUnitOfMeasureOnItem(Item, ItemUnitOfMeasure.Code);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, false);  // Find PICK Bin.

        // Exercise: Create and Register Put-Away from Purchase Order with Lot No.
        CreateAndRegisterPutAwayFromPurchaseOrder(
          PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, ItemUnitOfMeasure.Code, true, ItemTrackingMode::"Assign Lot No.", Bin.Code);  // Taking True for Item Tracking.
        LibraryVariableStorage.Dequeue(LotNo);

        // Verify: Registered Warehouse Activity Lines and Bin Content.
        VerifyRegisteredPutAwayLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Action Type"::Take, Item."No.", Quantity, ItemUnitOfMeasure.Code, LotNo, '',
          LocationWhite."Receipt Bin Code");
        VerifyRegisteredPutAwayLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Action Type"::Place, Item."No.", Quantity, ItemUnitOfMeasure.Code, LotNo, '', Bin.Code);
        VerifyBinContent(LocationWhite.Code, Bin.Code, Item."No.", Quantity, Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure");  // Value required for the test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityToReceiveMoreThanOutstandingOnWarehouseReceiptError()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        SCMWarehouseReceiving: Codeunit "SCM Warehouse - Receiving";
        Quantity: Decimal;
    begin
        BindSubscription(SCMWarehouseReceiving);
        // Setup: Create Item. Create and release Purchase Order. Create Warehouse Receipt Header and Get Source Document to create Receipt line.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationWhite.Code, '', Item."No.", Quantity, Item."Base Unit of Measure", false);
        GetSourceDocumentOnWarehouseReceipt(WarehouseReceiptHeader, LocationWhite.Code, true, false, false, Item."No.", Item."No.");
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();

        // Exercise: Enter Quantity to Receive more than the Quantity in Purchase Line.
        asserterror WarehouseReceiptLine.Validate("Qty. to Receive", Quantity + LibraryRandom.RandDec(10, 2));  // Value is required to generate the Error.

        // Verify: Error message.
        Assert.ExpectedError(StrSubstNo(CannotHandleMoreUnitsError));

        UnbindSubscription(SCMWarehouseReceiving);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPutAwayWithSerialAndLot()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        LotNo: Variant;
        Quantity: Decimal;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        // Setup: Create Item with Serial and Lot specific Tracking.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItemWithItemTrackingCode(Item, true, true, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode());  // Taking True for Serial and Lot.

        // Exercise: Create and register Put-Away from Purchase Order.
        CreateAndRegisterPutAwayFromPurchaseOrder(
          PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure", true,
          ItemTrackingMode::"Assign Lot And Serial", '');
        LibraryVariableStorage.Dequeue(LotNo);

        // Verify.
        VerifyLotAndSerialOnRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::"Put-away", RegisteredWhseActivityLine."Action Type"::Take, LotNo, 0D);  // Use 0D for blank Expiration Date.
        VerifyLotAndSerialOnRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::"Put-away", RegisteredWhseActivityLine."Action Type"::Place, LotNo, 0D);  // Use 0D for blank Expiration Date.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BinMaximumCubageConfirmWithWarehouseReceipt()
    begin
        // Setup.
        Initialize();
        BinMaximumCubageAndMaximumQuantityConfirmWithWarehouseReceipt(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BinContentMaximumQuantityConfirmWithWarehouseReceipt()
    begin
        // Setup.
        Initialize();
        BinMaximumCubageAndMaximumQuantityConfirmWithWarehouseReceipt(true);  // Taking True for Maximum Quantity Confirm Message.
    end;

    local procedure BinMaximumCubageAndMaximumQuantityConfirmWithWarehouseReceipt(MaximumQuantityConfirm: Boolean)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        Zone: Record Zone;
        Quantity: Decimal;
        Quantity2: Decimal;
        OldBinCapacityPolicy: Option;
    begin
        // Update Bin Capacity Policy on Location. Create Item with different Item Unit of Measure. Create Bin for Receive Zone with Maximum Cubage. Create Warehouse Receipt from Purchase Order.
        UpdateBinCapacityPolicyOnLocation(
          LocationWhite, OldBinCapacityPolicy, LocationWhite."Bin Capacity Policy"::"Prohibit More Than Max. Cap.");
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(5));  // Taking Width and Height as Length as value is not important for test.
        Quantity := LibraryRandom.RandInt(5);
        Quantity2 := Quantity + LibraryRandom.RandInt(5);  // Value required for the test.
        FindZone(Zone, LocationWhite.Code, true, false, false);  // Find Receive Zone.
        CreateBinWithMaximumCubage(Bin, Zone, Quantity * ItemUnitOfMeasure.Cubage);  // Value required for the test.
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity2, ItemUnitOfMeasure.Code);

        // Values required for the test. Enqueue for MessageHandler.
        LibraryVariableStorage.Enqueue(
          StrSubstNo(
            ExceedsAvailableCapacity, ItemUnitOfMeasure.FieldCaption(Cubage), Quantity2 * ItemUnitOfMeasure.Cubage, Bin."Maximum Cubage",
            Bin.TableCaption(), Bin.Code));

        // Exercise: Validate Bin Code on Warehouse Receipt Line to generate a Confirm Message.
        UpdateBinCodeOnWarehouseReceiptLine(PurchaseHeader."No.", Bin.Code, '', LocationWhite.Code);

        // Verify: Verification is done by Confirm Handler.

        if MaximumQuantityConfirm then begin
            // Exercise: Create Bin Content and validate Maximum Quantity to generate a Confirm Message.
            LibraryWarehouse.CreateBinContent(
              BinContent, LocationWhite.Code, Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");

            // Enqueue for MessageHandler. Values required for the test.
            LibraryVariableStorage.Enqueue(
              StrSubstNo(
                ExceedsMaximumCubage, Quantity2 * ItemUnitOfMeasure.Cubage, BinContent.FieldCaption("Max. Qty."),
                Bin.FieldCaption("Maximum Cubage"), Bin."Maximum Cubage", Bin.TableCaption()));
            BinContent.Validate("Max. Qty.", Quantity2);

            // Verify: Verification is done by Confirm Handler.
        end;

        // Tear Down.
        UpdateBinCapacityPolicyOnLocation(LocationWhite, OldBinCapacityPolicy, OldBinCapacityPolicy);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangingFromUnitofMeasureInMovementWorksheetLine()
    var
        Item: Record Item;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // [FEATURE] [Whse. Worksheet]
        // [SCENARIO 378278] Field "From Unit of Measure Code" in Whse. Worksheet Line should be validated successfully when "Unit of Measure" is not set for this line.

        // [GIVEN] Create Item and Item Unit of Measure assigned with this item.
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Whse. Worksheet Line.
        CreateMovementWorksheetLineWithNoUoM(WhseWorksheetLine, Item."No.");

        // [WHEN] Validate "From Unit of Measure Code" on warehouse worksheet line.
        WhseWorksheetLine.Validate("From Unit of Measure Code", Item."Base Unit of Measure");

        // [THEN] Field "From Unit of Measure Code" should be validated successfully.
        WhseWorksheetLine.TestField("From Unit of Measure Code", Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetBlankFromUnitofMeasureInMovementWorksheetLine()
    var
        Item: Record Item;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // [FEATURE] [Whse. Worksheet]
        // [SCENARIO 378278] Field "Qty. per From Unit of Measure" in Whse. Worksheet Line should be equal to "1" when "From Unit of Measure Code" is blank

        // [GIVEN] Create Item and Item Unit of Measure assigned to this item.
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Whse. Worksheet Line.
        CreateMovementWorksheetLineWithNoUoM(WhseWorksheetLine, Item."No.");

        // [WHEN] Set blank "From Unit of Measure Code"
        WhseWorksheetLine.Validate("From Unit of Measure Code", '');

        // [THEN] Field "Qty. per From Unit of Measure" should be "1"
        WhseWorksheetLine.TestField("Qty. per From Unit of Measure", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayFromPurchaseOrderUsingMultipleBinsWithMaximumCubageAndWeight()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        Zone: Record Zone;
        Quantity: Decimal;
        Cubage: Decimal;
    begin
        // Setup: Create Item with different Put-Away Unit of Measure. Update Cubage and Weight on both Item Units of Measures. Create Zone with Bin Type as Put-Away and Pick. Create Warehouse Receipt from Purchase Order.
        Initialize();
        Cubage := LibraryRandom.RandInt(5);
        Quantity := LibraryRandom.RandInt(5);
        CreateItemWithDifferentPutAwayUnitOfMeasure(Item, ItemUnitOfMeasure);
        ItemUnitOfMeasure2.Get(Item."No.", Item."Base Unit of Measure");
        UpdateCubageAndWeightOnItemUnitOfMeasure(ItemUnitOfMeasure2, Cubage);
        UpdateCubageAndWeightOnItemUnitOfMeasure(ItemUnitOfMeasure, Cubage * ItemUnitOfMeasure."Qty. per Unit of Measure");  // Value required for the test.
        CreateBinsForPickZoneWithBinRanking(Zone, LocationWhite4.Code, Quantity);
        UpdateMaximumCubageAndWeightOnBins(Bin, Zone, Cubage * ItemUnitOfMeasure."Qty. per Unit of Measure");  // Value required for the test.
        CreateWarehouseReceiptFromPurchaseOrder(
          PurchaseHeader, LocationWhite4.Code, Item."No.", Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure",
          Item."Base Unit of Measure");  // Value required for the test.

        // Exercise.
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationWhite4.Code);

        // Verify: Put-Away lines.
        VerifyPutAwayLinesWithMultipleBins(
          Bin, Item, ItemUnitOfMeasure, LocationWhite4, PurchaseHeader."No.", Quantity, ItemUnitOfMeasure2."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPutAwayFromReleasedProductionOrderWithDifferentUnitOfMeasureAndLotNo()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseRequest: Record "Warehouse Request";
        LotNo: Code[50];
    begin
        // Setup: Create Item with Lot specific Tracking. Create and refresh Production Order with different Unit of Measure. Create Inbound Warehouse Request and create Inventory Put-Away.
        Initialize();
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());  // Taking True for Lot.
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", 0);  // Taking Blank Length.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), LocationBrown.Code);
        UpdateUnitOfMeasureOnProductionOrderLine(ProductionOrder, ItemUnitOfMeasure.Code);
        LibraryVariableStorage.Enqueue(WarehouseRequestCreatedMessage);  // Enqueue for MessageHandler.
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);
        LibraryVariableStorage.Enqueue(InvPutAwayMessage);  // Enqueue for MessageHandler.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Prod. Output", ProductionOrder."No.", LocationBrown.Code, true, false);
        LotNo := LibraryUtility.GenerateGUID();
        UpdateLotNoAndQuantityToHandleOnInventoryPutAwayLine(WarehouseActivityHeader, ProductionOrder."No.", LotNo);

        // Exercise.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // Verify.
        VerifyPostedInventoryPutLine(
          PostedInvtPutAwayLine."Source Document"::"Prod. Output", ProductionOrder."No.", LocationBrown.Code, Item."No.",
          ProductionOrder.Quantity, ItemUnitOfMeasure.Code, LotNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayFromPurchaseOrderWithMultipleLocationsAndVariantCode()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Variant. Create and release Purchase Order with multiple lines of different locations. Create Warehouse Receipts from Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateAndReleasePurchaseOrderWithMultipleLines(
          PurchaseHeader, LocationWhite.Code, LocationGreen.Code, Item."No.", Quantity, Item."Base Unit of Measure",
          Item."Base Unit of Measure", ItemVariant.Code, '');
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, true);  // Find Last Bin in PICK Zone.

        // Exercise.
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationWhite.Code);
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationGreen.Code);

        // Verify.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", LocationWhite."Receipt Bin Code", ItemVariant.Code, '');
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, ItemVariant.Code, '');
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::" ",
          Item."No.", Quantity, LocationGreen.Code, Item."Base Unit of Measure", '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSourceDocumentOnWarehouseReceiptWithMultiplePurchaseOrders()
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create Items. Create and release two Purchase Orders. Get Source Document on Warehouse Receipt for both Purchase Orders.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationWhite.Code, '', Item."No.", Quantity, Item."Base Unit of Measure", false);
        CreateAndReleasePurchaseOrder(PurchaseHeader2, LocationWhite.Code, '', Item2."No.", Quantity, Item2."Base Unit of Measure", false);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, true);  // Find Last Bin in PICK Zone.
        GetSourceDocumentOnWarehouseReceipt(WarehouseReceiptHeader, LocationWhite.Code, true, false, false, Item."No.", Item2."No.");

        // Exercise.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", LocationWhite."Receipt Bin Code", '', '');
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, '', '');
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader2."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take,
          Item2."No.", Quantity, LocationWhite.Code, Item2."Base Unit of Measure", LocationWhite."Receipt Bin Code", '', '');
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader2."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place,
          Item2."No.", Quantity, LocationWhite.Code, Item2."Base Unit of Measure", Bin.Code, '', '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GetSourceDocumentOnWarehouseReceiptWithMultipleTransferOrdersFromDifferentLocations()
    var
        Bin: Record Bin;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferHeader2: Record "Transfer Header";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Post Item Journal on two Locations. Create and Post two Transfer Orders. Get Source Document on Warehouse Receipt for both Transfer Orders.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, LocationBlue.Code, false);
        CreateAndPostItemJournalLine(Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, LocationRed.Code, false);
        CreateAndShipTransferOrder(TransferHeader, LocationBlue.Code, LocationWhite.Code, Item."No.", Quantity, false);
        CreateAndShipTransferOrder(TransferHeader2, LocationRed.Code, LocationWhite.Code, Item."No.", Quantity, false);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, true);  // Find Last Bin in PICK Zone.
        GetSourceDocumentOnWarehouseReceipt(WarehouseReceiptHeader, LocationWhite.Code, false, true, false, Item."No.", Item."No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(TransferOrderDeletedMessage, TransferHeader."No."));  // Enqueue for MessageHandler.
        LibraryVariableStorage.Enqueue(StrSubstNo(TransferOrderDeletedMessage, TransferHeader2."No."));  // Enqueue for MessageHandler.

        // Exercise.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Inbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", LocationWhite."Receipt Bin Code", '', '');
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Inbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, '', '');
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Inbound Transfer", TransferHeader2."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", LocationWhite."Receipt Bin Code", '', '');
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Inbound Transfer", TransferHeader2."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSourceDocumentOnWarehouseReceiptWithMultipleSalesReturnOrders()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and release two Sales Return Orders. Get Source Document on Warehouse Receipt for both Sales Return Orders.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndReleaseSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Return Order", LocationWhite.Code, Item."No.", Quantity, false);
        CreateAndReleaseSalesDocument(
          SalesHeader2, SalesHeader."Document Type"::"Return Order", LocationWhite.Code, Item."No.", Quantity, false);
        GetSourceDocumentOnWarehouseReceipt(WarehouseReceiptHeader, LocationWhite.Code, false, false, true, Item."No.", Item."No.");
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, true);  // Find Last Bin in PICK Zone.

        // Exercise.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", LocationWhite."Receipt Bin Code", '', '');
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, '', '');
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader2."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", LocationWhite."Receipt Bin Code", '', '');
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader2."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, '', '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPutAwayAndPickWithSerialLotAndExpirationDateOnPurchaseOrder()
    begin
        Initialize();
        PostInventoryPutAwayAndPickWithSerialLotAndExpirationDate(false);  // Expiration Date on Inventory Put Away as FALSE.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPutAwayAndPickWithSerialLotAndExpirationDateModifiedOnInventoryPutAway()
    begin
        Initialize();
        PostInventoryPutAwayAndPickWithSerialLotAndExpirationDate(true);  // Expiration Date on Inventory Put Away as TRUE.
    end;

    local procedure PostInventoryPutAwayAndPickWithSerialLotAndExpirationDate(ExpirationDateOnInventoryPutAway: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        LotNo: Variant;
        Quantity: Decimal;
        ExpirationDate: Date;
    begin
        // Setup: Create Items with Item Tracking Code, create and release Purchase Order with Tracking, update Expiration Date on Reservation Entry. Create Inventory Put Away. Modify Expiration Date on Put Away, Post Inventory Put Away.
        // Create and Release Sales Order with Tracking. Create Inventory Pick.
        Quantity := LibraryRandom.RandInt(5);
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '');  // Taking True for Serial.
        CreateItemWithItemTrackingCode(Item2, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());  // Taking True for Lot.
        CreateAndReleasePurchaseOrderWithTrackingOnMultipleLines(PurchaseHeader, Item."No.", Quantity, Item2."No.", LocationSilver2.Code);
        LibraryVariableStorage.Dequeue(LotNo);  // Dequeue for ItemTrackingPageHandler.
        UpdateExpirationDateOnReservationEntry(Item."No.", WorkDate());
        UpdateExpirationDateOnReservationEntry(Item2."No.", WorkDate());
        LibraryVariableStorage.Enqueue(InvPutAwayMessage);  // Enqueue for MessageHandler.
        CreateInventoryActivity(
          WarehouseRequest."Source Document"::"Purchase Order", PurchaseHeader."No.", LocationSilver2.Code, true, false);
        if ExpirationDateOnInventoryPutAway then begin
            ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
            UpdateExpirationDateOnInventoryPutAway(PurchaseHeader."No.", Item."No.", ExpirationDate);
            UpdateExpirationDateOnInventoryPutAway(PurchaseHeader."No.", Item2."No.", ExpirationDate);
        end;
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away", true);  // Post as Invoice.
        CreateAndReleaseSalesDocWithMultipleLines(
          SalesHeader, SalesHeader."Document Type"::Order,
          LocationSilver2.Code, LocationSilver2.Code, Item."No.", Item2."No.", '', '', Quantity, true);
        LibraryVariableStorage.Enqueue(InvPickMessage);  // Enqueue for MessageHandler.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", LocationSilver2.Code, false, true);
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");

        // Exercise: Post Inventory Pick.
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          true);  // Post as Invoice.

        // Verify: Posted Inventory Pick Lines for Expiration Date.
        if ExpirationDateOnInventoryPutAway then begin
            VerifyPostedInventoryPickLine(SalesHeader."No.", LocationSilver2.Code, Item2."No.", Quantity, LotNo, ExpirationDate, false);
            VerifyPostedInventoryPickLineForSerialNo(SalesHeader."No.", Item."No.", LocationSilver2.Code, ExpirationDate, Quantity);
        end else begin
            VerifyPostedInventoryPickLine(SalesHeader."No.", LocationSilver2.Code, Item2."No.", Quantity, LotNo, WorkDate(), false);
            VerifyPostedInventoryPickLineForSerialNo(SalesHeader."No.", Item."No.", LocationSilver2.Code, WorkDate(), Quantity);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPutAwayWithUpdatingBinAsCrossDock()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
    begin
        // Setup: Create and Post Warehouse Receipt. Update Cross-Dock Bin on Warehouse Put Away.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseOrderAndPostWarehouseReceipt(
          PurchaseHeader, LocationWhite.Code, Item."No.", LibraryRandom.RandDec(10, 2), Item."Base Unit of Measure");
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");  // Get Cross-Dock Bin.
        UpdateBinCodeOnPutAwayLine(
          WarehouseActivityLine, Bin, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Exercise: Register Warehouse Put Away after Updating Cross-Dock Bin.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify: Warehouse Entry for Cross-Dock.
        VerifyWarehouseEntry(Bin, Item."No.", WarehouseActivityLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWareHouseReceiptWithChangedPutAwayTemplate()
    var
        PutAwayTemplateHeader: Record "Put-away Template Header";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Bin: Record Bin;
        OldPutAwayTemplateCode: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Create Item with Put-Away Unit of Measure.Create Bin and update Bin Content. Create Put-Away Template.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        UpdatePutAwayUnitOfMeasureOnItem(Item, Item."Base Unit of Measure");
        CreateBinAndUpdateBinContent(Bin, Item, LocationWhite.Code, 0, true);  // Taking TRUE for Fixed Bin.
        CreatePutAwayTemplate(PutAwayTemplateHeader, true, false, true, true);  // Taking TRUE for Fixed and FindBinLessthanMinQty.
        OldPutAwayTemplateCode := UpdatePutAwayTemplateCodeOnLocation(LocationWhite, PutAwayTemplateHeader.Code);

        // Exercise.
        CreatePurchaseOrderAndPostWarehouseReceipt(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure");

        // Verify: Bin is Placed According to Put Away Template Code in Warehouse Activity Line.
        VerifyWarehouseActivityLine(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Item."No.",
          Quantity, LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, '', '');

        // TearDown: Update Location with Old Put-Away Template Code.
        UpdatePutAwayTemplateCodeOnLocation(LocationWhite, OldPutAwayTemplateCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseReceiptWithDifferentPutAwayTemplateItem()
    begin
        Initialize();
        PostWarehouseReceiptWithDifferentPutAwayTemplate(false);  // Taking False for UsestockKeepingUnit.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseReceiptWithDifferentPutAwayTemplateSKU()
    begin
        Initialize();
        PostWarehouseReceiptWithDifferentPutAwayTemplate(true);  // Taking True for UsestockKeepingUnit.
    end;

    local procedure PostWarehouseReceiptWithDifferentPutAwayTemplate(UseStockKeepingUnit: Boolean)
    var
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateHeader2: Record "Put-away Template Header";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Bin: Record Bin;
        Bin2: Record Bin;
        OldPutAwayTemplateCode: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Create Put-Away Template. Create purchase order and Post Partial Warehouse Receipt. Update Put-Away Template.
        Quantity := LibraryRandom.RandInt(50) + 10;  // Value Required for Test.
        LibraryInventory.CreateItem(Item);
        UpdatePutAwayUnitOfMeasureOnItem(Item, Item."Base Unit of Measure");
        CreateBinAndUpdateBinContent(Bin, Item, LocationWhite.Code, 0, true);  // Taking TRUE for Fixed Bin.
        CreatePutAwayTemplate(PutAwayTemplateHeader, true, false, true, true);  // Taking TRUE for Fixed.
        CreateBinAndUpdateBinContent(Bin2, Item, LocationWhite.Code, 0, false);
        CreatePutAwayTemplate(PutAwayTemplateHeader2, false, true, false, true);  // Taking TRUE for FindFloatingBin.
        OldPutAwayTemplateCode := UpdatePutAwayTemplateCodeOnLocation(LocationWhite, PutAwayTemplateHeader.Code);
        if UseStockKeepingUnit then
            UpdatePutAwayTemplateCodeOnItem(Item."No.", PutAwayTemplateHeader2.Code);
        CreateAndPostPartialWarehouseReceipt(PurchaseHeader, Item, LocationWhite.Code, Quantity);
        if UseStockKeepingUnit then
            CreateStockkeepingUnit(LocationWhite.Code, Item."No.", PutAwayTemplateHeader.Code)
        else
            UpdatePutAwayTemplateCodeOnItem(Item."No.", PutAwayTemplateHeader2.Code);

        // Exercise: Post Partial Warehouse Receipt With Different Put-Away Template.
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationWhite.Code);

        // Verify.
        if UseStockKeepingUnit then
            VerifyWarehouseActivityLine(
              WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Item."No.",
              Quantity / 4, LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, '', '')
        else
            VerifyWarehouseActivityLine(
              WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Item."No.",
              Quantity / 4, LocationWhite.Code, Item."Base Unit of Measure", Bin2.Code, '', '');  // Value required for the test as Quantity To Receive is Update Twice on Warehouse Receipt Line.

        // TearDown: Update Location with Old Put-Away Template Code.
        UpdatePutAwayTemplateCodeOnLocation(LocationWhite, OldPutAwayTemplateCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SortingByDueDateOnPutAwayFromPutAwayWorksheet()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
        OldUsePutAwayWorksheet: Boolean;
        DueDate: Date;
        ExpectedReceiptDate: Date;
    begin
        // Setup: Create Purchase Order with two lines. Create Warehouse Receipt and update different Due dates on two Receipt lines. Post the Warehouse Receipt.
        Initialize();
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, true);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateBinAndUpdateBinContent(Bin, Item, LocationWhite.Code, 0, true);  // Taking TRUE for Fixed Bin.
        CreateAndReleasePurchaseOrderWithMultipleLines(
          PurchaseHeader, LocationWhite.Code, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure",
          Item."Base Unit of Measure", '', '');
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        GetExpectedReceiptDateFromPurchaseLine(ExpectedReceiptDate, PurchaseHeader."No.");
        DueDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', ExpectedReceiptDate);
        UpdateDueDateOnWarehouseReceiptLine(PurchaseHeader."No.", LocationWhite.Code, DueDate);
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationWhite.Code);

        // Exercise.
        CreatePutAwayFromPutAwayWorksheet(
            WhseWorksheetLine, LocationWhite.Code, Item."No.", Item."No.", 0, "Whse. Activity Sorting Method"::"Due Date", false);  // Taking 0 for Quantity.

        // Verify: Put-Away lines get sorted by Due Date.
        FindWarehouseActivityLineForMultipleSourceDocuments(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", '',
          WarehouseActivityLine."Activity Type"::"Put-away");
        VerifyDueDateAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", Quantity, LocationWhite."Receipt Bin Code", ExpectedReceiptDate, false);
        VerifyDueDateAndBinCodeOnWarehouseActivityLine(WarehouseActivityLine, Item."No.", Quantity, Bin.Code, ExpectedReceiptDate, true);  // TRUE for NextLine.
        VerifyDueDateAndBinCodeOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", Quantity, LocationWhite."Receipt Bin Code", DueDate, true);  // TRUE for NextLine.
        VerifyDueDateAndBinCodeOnWarehouseActivityLine(WarehouseActivityLine, Item."No.", Quantity, Bin.Code, DueDate, true);  // TRUE for NextLine.

        // Tear Down.
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, OldUsePutAwayWorksheet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SortingByBinRankingOnPutAwayFromPutAwayWorksheet()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
        OldUsePutAwayWorksheet: Boolean;
        ExpectedReceiptDate: Date;
    begin
        // Setup: Create Purchase Order with two lines. Create Warehouse Receipt and update Bin Codes with different Bin Ranking on two Receipt lines. Post the Warehouse Receipt.
        Initialize();
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, true);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateBinAndUpdateBinContent(Bin, Item, LocationWhite.Code, 0, true);  // Taking TRUE for Fixed Bin.
        CreateBinForReceiveZoneWithBinRanking(Bin2, LocationWhite.Code, LibraryRandom.RandInt(50));
        CreateBinForReceiveZoneWithBinRanking(Bin3, LocationWhite.Code, Bin2."Bin Ranking" + LibraryRandom.RandInt(10));  // Greater value required for the test.
        CreateAndReleasePurchaseOrderWithMultipleLines(
          PurchaseHeader, LocationWhite.Code, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure",
          Item."Base Unit of Measure", '', '');
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        UpdateBinCodeOnWarehouseReceiptLine(PurchaseHeader."No.", Bin3.Code, Bin2.Code, LocationWhite.Code);
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationWhite.Code);
        GetExpectedReceiptDateFromPurchaseLine(ExpectedReceiptDate, PurchaseHeader."No.");

        // Exercise.
        CreatePutAwayFromPutAwayWorksheet(
          WhseWorksheetLine, LocationWhite.Code, Item."No.", Item."No.", 0, "Whse. Activity Sorting Method"::"Bin Ranking", false);  // Taking 0 for Quantity.

        // Verify: Put-Away lines get sorted by Bin Ranking.
        FindWarehouseActivityLineForMultipleSourceDocuments(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", '',
          WarehouseActivityLine."Activity Type"::"Put-away");
        VerifyDueDateAndBinCodeOnWarehouseActivityLine(WarehouseActivityLine, Item."No.", Quantity, Bin2.Code, ExpectedReceiptDate, false);
        VerifyDueDateAndBinCodeOnWarehouseActivityLine(WarehouseActivityLine, Item."No.", Quantity, Bin3.Code, ExpectedReceiptDate, true);  // TRUE for NextLine.
        VerifyDueDateAndBinCodeOnWarehouseActivityLine(WarehouseActivityLine, Item."No.", Quantity, Bin.Code, ExpectedReceiptDate, true);  // TRUE for NextLine.
        VerifyDueDateAndBinCodeOnWarehouseActivityLine(WarehouseActivityLine, Item."No.", Quantity, Bin.Code, ExpectedReceiptDate, true);  // TRUE for NextLine.

        // Tear Down.
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, OldUsePutAwayWorksheet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayFromPutAwayWorksheetWithBreakBulkFilterTrueOnCreatePutAwayPage()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
        OldUsePutAwayWorksheet: Boolean;
    begin
        // Setup: Create Purchase Order with different Unit of Measure. Create Warehouse Receipt and post it.
        Initialize();
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, true);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", 0);  // Taking 0 for Blank Length.
        UpdatePutAwayUnitOfMeasureOnItem(Item, Item."Base Unit of Measure");
        CreatePurchaseOrderAndPostWarehouseReceipt(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, ItemUnitOfMeasure.Code);

        // Exercise.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, LocationWhite.Code, Item."No.", Item."No.", 0, "Whse. Activity Sorting Method"::None, true);  // Taking 0 for Quantity and TRUE for BreakBulkFilter.

        // Verify: Break Bulk Filter is TRUE on Warehouse Activity Header. Also, No. of lines on Warehouse Activity Header is greater than that on Warehouse Put-Away page.
        VerifyBreakBulkFilterOnPutAway(WarehouseActivityHeader, PurchaseHeader."No.");
        WarehouseActivityHeader.CalcFields("No. of Lines");
        VerifyNoOfLinesOnPutAway(WarehouseActivityHeader."No.", WarehouseActivityHeader."No. of Lines");

        // Tear Down.
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, OldUsePutAwayWorksheet);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPutAwayFromPurchaseOrderWithMultipleLotNo()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Variant;
        LotNo2: Variant;
        Quantity: Decimal;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        // Setup: Create Purchase Order with multiple Lot No for partial Quantity. Create Warehouse Receipt and post it.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());  // Taking True for Lot.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Multiple Lot No");
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationWhite.Code, '', Item."No.", Quantity, Item."Base Unit of Measure", true);
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Dequeue(LotNo2);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationWhite.Code);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, false);  // Find PICK Bin.
        UpdateBinCodeOnPutAwayLine(
          WarehouseActivityLine, Bin, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Exercise.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify.
        VerifyRegisteredPutAwayLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Action Type"::Take, Item."No.", Quantity / 2,
          Item."Base Unit of Measure", LotNo, '', LocationWhite."Receipt Bin Code");  // Value required for the test.
        VerifyRegisteredPutAwayLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Action Type"::Place, Item."No.", Quantity / 2,
          Item."Base Unit of Measure", LotNo, '', Bin.Code);  // Value required for the test.
        VerifyRegisteredPutAwayLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Action Type"::Take, Item."No.", Quantity / 2,
          Item."Base Unit of Measure", LotNo2, '', LocationWhite."Receipt Bin Code");  // Value required for the test.
        VerifyRegisteredPutAwayLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Action Type"::Place, Item."No.", Quantity / 2,
          Item."Base Unit of Measure", LotNo2, '', Bin.Code);  // Value required for the test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayItemAccordingToBinMaximumQuantity()
    var
        Item: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Bins with Maximum Quantity. Create and Release Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);
        Quantity2 := LibraryRandom.RandInt(50);
        LibraryInventory.CreateItem(Item);
        CreateBinAndUpdateBinContent(Bin, Item, LocationWhite.Code, Quantity, true);
        CreateBinAndUpdateBinContent(Bin2, Item, LocationWhite.Code, Quantity2, true);

        // Exercise.
        CreatePurchaseOrderAndPostWarehouseReceipt(
          PurchaseHeader, LocationWhite.Code, Item."No.", Quantity + Quantity2, Item."Base Unit of Measure");  // Value Required for test cases.

        // Verify: Item is placed in Bin According to Bin Quantity.
        VerifyWarehouseActivityLine(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Item."No.",
          Quantity, LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, '', '');  // Value required for the test.
        VerifyWarehouseActivityLine(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Item."No.",
          Quantity2, LocationWhite.Code, Item."Base Unit of Measure", Bin2.Code, '', '');  // Value required for the test.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseReceiptFromTransferOrderWithLot()
    var
        Bin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Variant;
        Quantity: Decimal;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries";
    begin
        // Setup: Create and Post Item Journal Line, Transfer Order from Red location to White location.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());  // Taking True for Lot.
        FindBinAndCreateBinContent(Bin, Item, LocationWhite.Code);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for ItemTrackingPageHandler.
        CreateAndPostItemJournalLine(Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, LocationRed.Code, true);
        LibraryVariableStorage.Dequeue(LotNo);  // Lot No. value required in the test.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for ItemTrackingPageHandler.
        CreateAndShipTransferOrder(TransferHeader, LocationRed.Code, LocationWhite.Code, Item."No.", Quantity, true);

        // Exercise: Post Warehouse Receipt from Transfer Order.
        CreateAndPostWarehouseReceiptFromTransferOrder(TransferHeader, LocationWhite.Code);

        // Verify: Warehouse Activity Line.
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Inbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", LocationWhite."Receipt Bin Code", '', LotNo);
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Inbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place,
          Item."No.", Quantity, LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, '', LotNo);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayFromWarehouseInternalPutAwayAfterOutputJournalAndProductionOrder()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Bin: Record Bin;
        Bin2: Record Bin;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Variant and Flushing Method Forward, Find Bin, Create and Refresh Released Production Order. Create and Post Output Journal.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Using Random for Quantity.
        CreateItemwithReplenishment(Item, '');
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");  // Update Variant on Item.
        Bin.Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");
        CreateBinAndUpdateBinContent(Bin2, Item, LocationWhite.Code, 0, false);
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", Quantity, LocationWhite.Code);
        CreateAndPostOutputJournal(ItemJournalLine, Item."No.", ProductionOrder."No.", ItemVariant.Code, Bin.Code, Quantity);

        // Exercise: Create Put Away From Warehouse Internal Put Away.
        LibraryVariableStorage.Enqueue(PutAwayActivityCreatedMessage);
        CreatePutAwayFromWhseInternalPutAway(Bin, Item."No.", ItemVariant.Code, Quantity);

        // Verify: Warehouse Activity Line.
        VerifyWarehouseActivityLine(WarehouseActivityLine."Source Document"::" ", '',
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity,
          LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, ItemVariant.Code, '');
        VerifyWarehouseActivityLine(WarehouseActivityLine."Source Document"::" ", '',
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity,
          LocationWhite.Code, Item."Base Unit of Measure", Bin2.Code, ItemVariant.Code, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayFromPurchaseOrderWithItemPutAwayTemplateCode()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Put Away Template Code and UOM, Find Bin. Create Warehouse Receipt from Purchase Order. Post Warehouse Receipt.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Using Random for Quantity.
        CreateItemWithDifferentPutAwayUnitOfMeasure(Item, ItemUnitOfMeasure);
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure");
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationWhite.Code);

        // Exercise: Register Warehouse Activity.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify: Registered Warehouse Activity Line.
        VerifyRegisteredPutAwayLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Action Type"::Take, Item."No.", Quantity, Item."Base Unit of Measure", '', '',
          LocationWhite."Receipt Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayFromPutAwayWorksheetAfterDeletingWarehouseActivity()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Put-away] [Unit of Measure] [Bin Content]
        // [SCENARIO 362996] UOM of Whse. Receipt Line is used for getting Bin Content while creating Put-Away from Posted Whse. Receipt when Directed Put-away is set
        // Setup: Create Item with UOM. Create and Release Purchase Order for Multiple Lines with different UOM. Create and Post Warehouse Receipt. Delete Put Away.
        Initialize();

        // [GIVEN] Location with "Directed Put-away and Pick" = TRUE
        Quantity := LibraryRandom.RandDec(10, 2);  // Using Random for Quantity.

        // [GIVEN] Tracked Item "I" with Base UOM = "X" and additional UOM = "Y"
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", 0);  // Taking 0 for Blank Length.
        CreateBinAndUpdateBinContent(Bin, Item, LocationWhite.Code, 0, false);

        // [GIVEN] Posted Whse. Receipt for Item "I" with 2 lines: first -> UOM = "X"; second -> UOM = "Y"
        // [GIVEN] Bin Content "A" with UOM = "X"
        // [GIVEN] Bin Content "B" with UOM = "Y"
        CreateAndReleasePurchaseOrderWithMultipleLines(
          PurchaseHeader, LocationWhite.Code, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure", ItemUnitOfMeasure.Code,
          '', '');
        GetSourceDocumentOnWarehouseReceipt(WarehouseReceiptHeader, LocationWhite.Code, true, false, false, Item."No.", Item."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        DeletePutAway(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        // [WHEN] Create Put-away for Item "I" from Posted Whse. Receipt
        CreatePutAwayFromPutAwayWorksheet(
          WhseWorksheetLine, LocationWhite.Code, Item."No.", Item."No.", 0, "Whse. Activity Sorting Method"::"Action Type", false);  // Taking 0 for Quantity.

        // Verify: Warehouse Activity Line.
        // [THEN] Put-away is created with 2 Lines: first -> UOM = "X"; second -> UOM = "Y"
        VerifyWarehouseActivityLine(WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity,
          LocationWhite.Code, ItemUnitOfMeasure.Code, Bin.Code, '', '');
        VerifyWarehouseActivityLine(WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity,
          LocationWhite.Code, Item."Base Unit of Measure", Bin.Code, '', '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSourceCreateDocumentHandler')]
    [Scope('OnPrem')]
    procedure RegisterPutAwayFromInternalPutAwayAfterCalculateAndPostConsumptionJournalForComponentItemWithVariant()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        ComponentItem: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemVariant: Record "Item Variant";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        QuantityPer: Decimal;
    begin
        // Setup: Create Item with Production BOM. Create and register Pick from Production Order. Calculate and post Consumption Journal for partial Quantity. Create Put-Away from Internal Put-Away for remaining Quantity.
        Initialize();
        QuantityPer := LibraryRandom.RandInt(5);
        Quantity := LibraryRandom.RandInt(10);
        CreateItemWithProductionBOM(ParentItem, ComponentItem, ItemVariant, QuantityPer);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, false);  // Find PICK Bin.
        UpdateInventoryUsingWhseJournal(Bin, ComponentItem, Quantity * QuantityPer, ItemVariant.Code);  // Value required for the test.
        CreatePickFromProductionOrder(ProductionOrder, ParentItem."No.", Quantity, LocationWhite.Code);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        CalculateAndPostConsumptionJournal(ProductionOrder."No.", Quantity * QuantityPer / 2);  // Value required for the test.
        Bin2.Get(LocationWhite.Code, LocationWhite."From-Production Bin Code");
        LibraryVariableStorage.Enqueue("Whse. Activity Sorting Method"::None);  // Enqueue for WhseSourceCreateDocumentHandler.
        LibraryVariableStorage.Enqueue(PutAwayActivityCreatedMessage);  // Enqueue for MessageHandler.
        CreatePutAwayFromWhseInternalPutAway(Bin2, ComponentItem."No.", ItemVariant.Code, Quantity * QuantityPer / 2);  // Value required for the test.

        // Exercise: Update Bin on Put-Away line and register it.
        WarehouseActivityLine.SetRange("Item No.", ComponentItem."No.");
        UpdateBinCodeOnPutAwayLine(WarehouseActivityLine, Bin, WarehouseActivityLine."Source Document"::" ", '');
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '', WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify.
        VerifyRegisteredPutAwayLine(
          RegisteredWhseActivityLine."Source Document", '', RegisteredWhseActivityLine."Action Type"::Take, ComponentItem."No.",
          Quantity * QuantityPer / 2, ComponentItem."Base Unit of Measure", '', ItemVariant.Code, Bin2.Code);  // Value required for the test.
        VerifyRegisteredPutAwayLine(
          RegisteredWhseActivityLine."Source Document", '', RegisteredWhseActivityLine."Action Type"::Place, ComponentItem."No.",
          Quantity * QuantityPer / 2, ComponentItem."Base Unit of Measure", '', ItemVariant.Code, Bin.Code);  // Value required for the test.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPutAwayWithPartialQuantityFromPutAwayWorksheetWithMultipleLotNoOnPurchaseOrder()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayFromPutAwayWorksheetWithMultipleLotNoOnPurchaseOrder(false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPutAwayWithRemainingQuantityFromPutAwayWorksheetWithMultipleLotNoOnPurchaseOrder()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayFromPutAwayWorksheetWithMultipleLotNoOnPurchaseOrder(true);  // TRUE for Register Put-Away for remaining Quantity.
    end;

    local procedure RegisterPutAwayFromPutAwayWorksheetWithMultipleLotNoOnPurchaseOrder(RegisterPutAwayForRemainingQuantity: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        LotNo: Variant;
        LotNo2: Variant;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
        OldUsePutAwayWorksheet: Boolean;
        Quantity: Decimal;
    begin
        // Create and release Purchase Order with multiple Lot No. Create and Post Warehouse Receipt. Create and register Put-Away from Put-Away Worksheet for partial Quantity.
        Quantity := LibraryRandom.RandDec(10, 2);
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, true);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, false);  // Find PICK Bin.
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());  // Taking TRUE for Lot.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Multiple Lot No");  // Enqueue for ItemTrackingPageHandler.
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationWhite.Code, '', Item."No.", Quantity, Item."Base Unit of Measure", true);  // TRUE for Item Tracking.
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Dequeue(LotNo2);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationWhite.Code);
        CreatePutAwayFromPutAwayWorksheet(
            WhseWorksheetLine, LocationWhite.Code, Item."No.", Item."No.", Quantity / 2, "Whse. Activity Sorting Method"::None, false);  // Value required for the test.
        UpdateBinCodeOnPutAwayLine(
          WarehouseActivityLine, Bin, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify.
        VerifyRegisteredPutAwayLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Action Type"::Take, Item."No.",
          Quantity / 2, Item."Base Unit of Measure", LotNo, '', LocationWhite."Receipt Bin Code");  // Value required for the test.
        VerifyRegisteredPutAwayLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Action Type"::Place, Item."No.",
          Quantity / 2, Item."Base Unit of Measure", LotNo, '', Bin.Code);  // Value required for the test.

        if RegisterPutAwayForRemainingQuantity then begin
            // Exercise: Create and register Put-Away for remaining Quantity.
            LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::None, false, false, false);
            UpdateBinCodeOnPutAwayLine(
              WarehouseActivityLine, Bin, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Put-away");

            // Verify.
            VerifyRegisteredPutAwayLine(
              RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              RegisteredWhseActivityLine."Action Type"::Take, Item."No.",
              Quantity / 2, Item."Base Unit of Measure", LotNo2, '', LocationWhite."Receipt Bin Code");  // Value required for the test.
            VerifyRegisteredPutAwayLine(
              RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              RegisteredWhseActivityLine."Action Type"::Place, Item."No.",
              Quantity / 2, Item."Base Unit of Measure", LotNo2, '', Bin.Code);  // Value required for the test.
        end;

        // Tear Down.
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, OldUsePutAwayWorksheet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseReceiptFromPurchaseOrderWithMultipleItemVariant()
    begin
        // Setup.
        Initialize();
        PostWarehouseReceiptAndWarehouseShipmentWithMultipleItemVariant(false, false);  // Use RegisterPick as False and PostWhseShipment as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentAfterRegisterPickWithMultipleItemVariant()
    begin
        // Setup.
        Initialize();
        PostWarehouseReceiptAndWarehouseShipmentWithMultipleItemVariant(true, false);  // Use RegisterPick as True and PostWhseShipment as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentAfterRegisterPickWithMultipleItemVariant()
    begin
        // Setup.
        Initialize();
        PostWarehouseReceiptAndWarehouseShipmentWithMultipleItemVariant(true, true);  // Use RegisterPick as True and PostWhseShipment as True.
    end;

    local procedure PostWarehouseReceiptAndWarehouseShipmentWithMultipleItemVariant(RegisterPick: Boolean; PostWhseShipment: Boolean)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create and release Purchase Order with multiple Item Variant. Create Warehouse Receipt. Update Quantity to Receive on Warehouse Receipt Line for One Item Variant.
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");
        CreateAndReleasePurchaseOrderWithMultipleLines(
          PurchaseHeader, LocationWhite.Code, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure",
          Item."Base Unit of Measure", ItemVariant.Code, ItemVariant2.Code);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        UpdateQuantityOnWarehouseReceiptLineFromPurchaseOrder(PurchaseHeader."No.", Item."No.", LocationWhite.Code, ItemVariant.Code, 0);  // Use 0 for Quantity to Receive required for test.

        // Exercise.
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationWhite.Code);

        // Verify.
        VerifyPostedWarehouseReceiptLine(
          PostedWhseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Item."No.", ItemVariant2.Code, Quantity);
        VerifyWarehouseReceiptLine(PurchaseHeader."No.", Item."No.", LocationWhite.Code, ItemVariant.Code, Quantity, 0);  // Use 0 for Quantity to Receive required for test.

        if RegisterPick then begin
            // Exercise.
            RegisterPutAwayAfterUpdatingBinCodeOnPutAwayLine(PurchaseHeader."No.");
            CreateAndReleaseSalesDocWithMultipleLines(
              SalesHeader, SalesHeader."Document Type"::Order,
              LocationWhite.Code, LocationWhite.Code, Item."No.", Item."No.", ItemVariant.Code, ItemVariant2.Code, Quantity, false);
            CreateWarehouseShipmentFromSalesOrder(SalesHeader);
            CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);

            // Verify.
            VerifyWarehouseShipmentLine(ItemVariant, SalesHeader."No.", Quantity, 0);  // Use 0 for Quantity to Ship required for test.
            VerifyWarehouseShipmentLine(ItemVariant2, SalesHeader."No.", Quantity, Quantity);
        end;

        if PostWhseShipment then begin
            // Exercise.
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.

            // Verify.
            VerifyWarehouseShipmentLine(ItemVariant, SalesHeader."No.", Quantity, 0);  // Use 0 for Quantity to Ship required for test.
            VerifyPostedWarehouseShipmentLine(
              PostedWhseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", ItemVariant2.Code, Quantity);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentFromTransferOrderUsingFromLocationWithRequireShipmentAndToLocationWithDirectedPutAwayAndPick()
    begin
        // Setup.
        Initialize();
        PostWhseShpmntAndWhseRcptFromTransferOrderUsingFromLocWithRequireShpmntAndToLocWithDirectedPutAwayAndPick(
          false);  // Use WarehouseReceipt as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseReceiptFromTransferOrderUsingFromLocationWithRequireShipmentAndToLocationWithDirectedPutAwayAndPick()
    begin
        // Setup.
        Initialize();
        PostWhseShpmntAndWhseRcptFromTransferOrderUsingFromLocWithRequireShpmntAndToLocWithDirectedPutAwayAndPick(true);  // Use WarehouseReceipt as True.
    end;

    local procedure PostWhseShpmntAndWhseRcptFromTransferOrderUsingFromLocWithRequireShpmntAndToLocWithDirectedPutAwayAndPick(WarehouseReceipt: Boolean)
    var
        Item: Record Item;
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ItemJournalLine: Record "Item Journal Line";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        TransferHeader: Record "Transfer Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create and post Item Journal Line with Location having Require Shipment. Create Warehouse Shipment from Transfer Order.
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, LocationRed2.Code, false);
        CreateWarehouseShipmentFromTransferOrder(TransferHeader, LocationRed2.Code, LocationWhite.Code, Item."No.", Quantity);

        // Exercise.
        ReleaseWarehouseShipment(
          WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.

        // Verify.
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", '', Quantity);

        if WarehouseReceipt then begin
            // Exercise.
            GetSourceDocumentOnWarehouseReceipt(WarehouseReceiptHeader, LocationWhite.Code, false, true, false, Item."No.", Item."No.");
            LibraryVariableStorage.Enqueue(StrSubstNo(TransferOrderDeletedMessage, TransferHeader."No."));  // Enqueue for MessageHandler.
            LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

            // Verify.
            VerifyPostedWarehouseReceiptLine(
              PostedWhseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.", Item."No.", '', Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnCreatePickFromTransferOrderBeforeCancelReservationOnSalesOrder()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentFromTransferOrderForQuantityReservedAgainstSalesOrder(false);  // Use CancelReservation as False.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentFromTransferOrderAfterCancelReservationOnSalesOrder()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentFromTransferOrderForQuantityReservedAgainstSalesOrder(true);  // Use CancelReservation as True.
    end;

    local procedure PostWarehouseShipmentFromTransferOrderForQuantityReservedAgainstSalesOrder(CancelReservation: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        // Create and register Put Away from Purchase Order. Create and release Sales Order with reservation. Create Warehouse Shipment from Transfer Order.
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, false);  // Find PICK Bin.
        CreateAndRegisterPutAwayFromPurchaseOrder(
          PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure", false, ItemTrackingMode, Bin.Code);
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", LocationWhite.Code, Quantity);
        CreateWarehouseShipmentFromTransferOrder(TransferHeader, LocationWhite.Code, LocationBlue.Code, Item."No.", Quantity);

        // Exercise.
        asserterror CreatePick(
            WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");

        // Verify.
        Assert.ExpectedError(NothingToHandle);

        if CancelReservation then begin
            // Exercise.
            CancelReservationOnSalesOrder(SalesHeader."No.");
            CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.

            // Verify.
            VerifyPostedWarehouseShipmentLine(
              PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", '', Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryPageHandler,DimensionSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryOnPhysicalInventoryJournalUsingDimension()
    var
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PhysInventoryJournal: TestPage "Phys. Inventory Journal";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Default Dimension. Create and post Purchase Order as receive.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateDefaultDimensionItem(DimensionValue, Item."No.");
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationBlue.Code, '', Item."No.", Quantity, Item."Base Unit of Measure", false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as receive.

        // Exercise.
        LibraryVariableStorage.Enqueue(Item."No.");  // Enqueue for CalculateInventoryPageHandler.
        PhysInventoryJournal.OpenEdit();
        PhysInventoryJournal.CalculateInventory.Invoke();

        // Verify.
        VerifyItemJournalLine(Item."No.", DimensionValue.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure QuantityBaseErrorOnPostInventoryPickWithLotItemTracking()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Variant;
        Quantity: Decimal;
    begin
        // Setup: Create and post Inventory Put Away from Purchase Order using multiple Bin and Lot. Create Inventory Pick from Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());  // Taking True for Lot.
        CreateAndPostInventoryPutAwayFromPurchaseOrderUsingMultipleBinAndLot(Bin, LotNo, Item."No.", LocationSilver.Code, Quantity);
        CreateInventoryPickFromSalesOrder(SalesHeader, Item."No.", Bin."Location Code", Quantity);
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        UpdateLotNoOnInventoryPickLine(SalesHeader."No.", LotNo);

        // Exercise: Post Inventory Pick.
        asserterror PostInventoryActivity(
            WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
            WarehouseActivityLine."Activity Type"::"Invt. Pick", true);  // Post as Invoice.

        // Verify.
        Assert.ExpectedError(StrSubstNo(QuantityBaseError, -Quantity, Bin."Location Code", Bin.Code, Item."No.", Item."Base Unit of Measure"))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQuantityToPickOnPickWorksheetBeforeRegisterPutAway()
    begin
        // Setup.
        Initialize();
        AvailableQuantityToPickOnPickWorksheet(false);  // Use RegisterPutAway as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQuantityToPickOnPickWorksheetAfterRegisterPutAway()
    begin
        // Setup.
        Initialize();
        AvailableQuantityToPickOnPickWorksheet(true);  // Use RegisterPutAway as True.
    end;

    local procedure AvailableQuantityToPickOnPickWorksheet(RegisterPutAway: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create and post Warehouse Receipt from Purchase Order. Create and release Warehouse Shipment from Sales Order.
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        CreatePurchaseOrderAndPostWarehouseReceipt(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure");
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, LocationWhite.Code, Item."No.", Quantity, false);
        CreateWarehouseShipmentFromSalesOrder(SalesHeader);
        ReleaseWarehouseShipment(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Exercise.
        GetWarehouseDocumentOnPickWorksheet(WhseWorksheetName, LocationWhite.Code);

        // Verify.
        VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity, 0);  // Value required for test.

        if RegisterPutAway then begin
            // Exercise.
            FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, false);  // Find PICK Bin.
            UpdateBinCodeOnPutAwayLine(
              WarehouseActivityLine, Bin, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Put-away");

            // Verify.
            VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity, Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure AvailableQuantityToPickOnPickWorksheetBeforeCancelReservationOnSalesOrder()
    begin
        // Setup.
        Initialize();
        AvailableQuantityToPickOnPickWorksheetWithSalesOrderReservation(false);  // Use CancelReservation as False.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AvailableQuantityToPickOnPickWorksheetAfterCancelReservationOnSalesOrder()
    begin
        // Setup.
        Initialize();
        AvailableQuantityToPickOnPickWorksheetWithSalesOrderReservation(true);  // Use CancelReservation as True.
    end;

    local procedure AvailableQuantityToPickOnPickWorksheetWithSalesOrderReservation(CancelReservation: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        // Create and register Put Away from Purchase Order. Create and release two Sales Orders with reservation. Create and release Warehouse Shipment from second Sales Order.
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, false);  // Find PICK Bin.
        CreateAndRegisterPutAwayFromPurchaseOrder(
          PurchaseHeader, LocationWhite.Code, Item."No.", Quantity + Quantity, Item."Base Unit of Measure", false, ItemTrackingMode, Bin.Code);  // Value required for test.
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", LocationWhite.Code, Quantity);
        CreateAndReleaseSalesOrderWithReservation(SalesHeader2, Item."No.", LocationWhite.Code, Quantity);
        CreateWarehouseShipmentFromSalesOrder(SalesHeader2);
        ReleaseWarehouseShipment(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader2."No.");

        // Exercise.
        GetWarehouseDocumentOnPickWorksheet(WhseWorksheetName, LocationWhite.Code);

        // Verify.
        VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity, Quantity);

        if CancelReservation then begin
            // Exercise.
            CancelReservationOnSalesOrder(SalesHeader."No.");

            // Verify.
            VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity, Quantity + Quantity);  // Value required for test.
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorChangingItemOnPurchaseOrderAfterCreateInventoryPutAway()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Inventory Put Away from Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateInventoryPutAwayFromPurchaseOrder(PurchaseHeader, Item, LocationSilver.Code, LibraryRandom.RandDec(100, 2));

        // Exercise.
        asserterror UpdateItemNoOnPurchaseLineAfterReopenPurchaseOrder(PurchaseHeader);

        // Verify: Verify error Item No. must not be changed on Purchase Line when Warehouse Activity Line exists.
        Assert.IsTrue(
          StrPos(
            GetLastErrorText,
            StrSubstNo(ItemNoMustNotBeChangedWhenWarehouseActivityLineExists, PurchaseLine.FieldCaption("No."), PurchaseLine.TableCaption())) >
          0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorChangingItemOnSalesOrderAfterCreateInventoryPick()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create and post Inventory Put Away from Purchase Order. Create Inventory Pick from Sales Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateInventoryPutAwayFromPurchaseOrder(PurchaseHeader, Item, LocationSilver.Code, Quantity);
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityHeader.Type::"Invt. Put-away", false);
        CreateInventoryPickFromSalesOrder(SalesHeader, Item."No.", LocationSilver.Code, Quantity);

        // Exercise.
        asserterror UpdateItemNoOnSalesLineAfterReopenSalesOrder(SalesHeader);

        // Verify: Verify error Item No. must not be changed on Sales Line when Warehouse Activity Line exists.
        Assert.IsTrue(
          StrPos(
            GetLastErrorText,
            StrSubstNo(ItemNoMustNotBeChangedWhenWarehouseActivityLineExists, SalesLine.FieldCaption("No."), SalesLine.TableCaption())) >
          0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorChangingItemOnTransferOrderAfterCreateInventoryPick()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        Quantity: Decimal;
    begin
        // Setup: Create and post Inventory Put Away from Purchase Order. Create Inventory Pick from Transfer Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateInventoryPutAwayFromPurchaseOrder(PurchaseHeader, Item, LocationSilver.Code, Quantity);
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityHeader.Type::"Invt. Put-away", false);
        CreateAndReleaseTransferOrder(TransferHeader, LocationSilver.Code, LocationBlue.Code, Item."No.", Quantity, false);
        LibraryVariableStorage.Enqueue(InvPickMessage);  // Enqueue for MessageHandler.
        CreateInventoryActivity(
          WarehouseRequest."Source Document"::"Outbound Transfer", TransferHeader."No.", LocationSilver.Code, false, true);

        // Exercise.
        asserterror UpdateItemNoOnTransferLineAfterReopenTransferOrder(TransferHeader);

        // Verify: Verify error Item No. must not be changed on Transfer Line when Warehouse Activity Line exists.
        Assert.IsTrue(
          StrPos(
            GetLastErrorText,
            StrSubstNo(
              ItemNoMustNotBeChangedWhenWarehouseActivityLineExists, TransferLine.FieldCaption("Item No."), TransferLine.TableCaption())) >
          0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhseJournalWithNegQtyAfterRegisterPutAway()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
        Bin2: Record Bin;
        Quantity: Decimal;
    begin
        // Setup: Create Item with Order Reordering Policy. Create and Release Sales Order. Carry Out Action Message after Calculate Plan On Requisition Line. Register Put away from Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithOrderReorderingPolicy(Item);
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, true);  // Find Receive Bin.
        Bin2.Get(LocationWhite.Code, LocationWhite."Receipt Bin Code");
        CreateAndUpdateBinContent(Bin, Item, Quantity, true);  // Fixed as TRUE.
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, LocationWhite.Code, Item."No.", Quantity, false);
        CarryOutActionMessageAfterCalculatePlanOnRequisitionLine(Item);
        RegisterPutAwayFromPurchaseOrder(Item."No.", LocationWhite.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", -Quantity);

        // Exercise.
        LibraryVariableStorage.Enqueue(NegativeAdjustmentConfirmMessage);  // Enqueue is used for Confirm Handler.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);  // UseBatchJob as TRUE.

        // Verify.
        VerifyWarehouseEntry(Bin, Item."No.", Quantity);
        VerifyWarehouseEntry(Bin2, Item."No.", -Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ExpirationDateOnPutAwayAfterPostWarehouseReceipt()
    begin
        // Setup.
        Initialize();
        CreateAndRegisterPickAfterRegisterPutAway(false, false, false);  // Register Put Away, Warehouse Pick and Register Pick as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ExpirationDateOnRegisteredPutAway()
    begin
        // Setup.
        Initialize();
        CreateAndRegisterPickAfterRegisterPutAway(true, false, false);  // Register Put Away as True. Warehouse Pick and Register Pick as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure ExpirationDateOnPickAfterCreateWarehouseShipment()
    begin
        // Setup.
        Initialize();
        CreateAndRegisterPickAfterRegisterPutAway(true, true, false);  // Register Put Away and Warehouse Pick as True. Register Pick as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure ExpirationDateOnRegisteredPick()
    begin
        // Setup.
        Initialize();
        CreateAndRegisterPickAfterRegisterPutAway(true, true, true);  // Register Put Away, Warehouse Pick and Register Pick as True.
    end;

    local procedure CreateAndRegisterPickAfterRegisterPutAway(RegisterPutAway: Boolean; WarehousePick: Boolean; RegisterPick: Boolean)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        LotNo: Variant;
        Quantity: Decimal;
        ExpirationDate: Date;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        // Create Item with Lot and Serial tracking. Create and Release Purchase Order. Update Expiration Date on Reservation Entry.
        CreateItemWithItemTrackingCode(Item, true, true, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode());  // Lot and Serial as TRUE.
        Quantity := LibraryRandom.RandInt(10);
        ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot And Serial");  // Enqueue for ItemTrackingPageHandler.
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationWhite.Code, '', Item."No.", Quantity, Item."Base Unit of Measure", true);  // Use Tracking as TRUE.
        LibraryVariableStorage.Dequeue(LotNo);
        UpdateExpirationDateOnReservationEntry(Item."No.", ExpirationDate);

        // Exercise.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationWhite.Code);

        // Verify.
        VerifyWarehouseActivityWithExpirationDate(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", ExpirationDate);

        if RegisterPutAway then begin
            // Exercise.
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Put-away");

            // Verify.
            VerifyLotAndSerialOnRegisteredWhseActivityLine(
              WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Take, LotNo, ExpirationDate);
            VerifyLotAndSerialOnRegisteredWhseActivityLine(
              WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place, LotNo, ExpirationDate);
        end;

        if WarehousePick then begin
            // Exercise.
            CreatePickFromSalesOrder(SalesHeader, Item."No.", LocationWhite.Code, Quantity);

            // Verify.
            VerifyWarehouseActivityWithExpirationDate(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
              ExpirationDate);
        end;

        if RegisterPick then begin
            // Exercise.
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);

            // Verify.
            VerifyLotAndSerialOnRegisteredWhseActivityLine(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
              WarehouseActivityLine."Action Type"::Take, LotNo, ExpirationDate);
            VerifyLotAndSerialOnRegisteredWhseActivityLine(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
              WarehouseActivityLine."Action Type"::Place, LotNo, ExpirationDate);
        end;
    end;

    [Test]
    [HandlerFunctions('ProductionJournalHandler,ReservationPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostNegOutputOnprodJnlAfterReserveSalesOrd()
    begin
        // Setup.
        Initialize();
        CreateAndPostNegativeOutputOnProductionJournal(true, false);  // Show Error as TRUE and Cancel Reservation as FALSE.
    end;

    [Test]
    [HandlerFunctions('ProductionJournalHandler,ReservationPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostNegOutputOnProdJnlAfterCancelReservOnSalesOrd()
    begin
        // Setup.
        Initialize();
        CreateAndPostNegativeOutputOnProductionJournal(false, true);  // Show Error as FALSE and Cancel Reservation as TRUE.
    end;

    local procedure CreateAndPostNegativeOutputOnProductionJournal(ShowError: Boolean; CancelReservation: Boolean)
    var
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        // Create Item with routing and post Production Journal. Create and release Sales Order with Reservation.
        Quantity := LibraryRandom.RandInt(10);
        CreateRoutingSetup(RoutingHeader);
        CreateItemwithReplenishment(Item, RoutingHeader."No.");
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", Quantity, '');
        PostProductionJournal(ProductionOrder, Quantity);
        CreateAndPostItemJournalLine(Item."No.", ItemJournalLine."Entry Type"::"Negative Adjmt.", Quantity, '', false);
        PostProductionJournal(ProductionOrder, Quantity / 2);
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", '', Quantity / 2);  // Calculated Value Required.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.");

        if ShowError then begin
            // Exercise.
            LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationMessage);  // Enqueue for ConfirmHandler.
            LibraryVariableStorage.Enqueue(NegativeAdjustmentConfirmMessage);  // Enqueue for ConfirmHandler.
            asserterror CreateAndPostProductionJournal(ProductionOrder."No.", Item."No.", -Quantity / 2, ItemLedgerEntry."Entry No.");  // Calculated Value Required.

            // Verify: Verification is covered in Confirm Handler.
        end;

        if CancelReservation then begin
            // Exercise.
            CancelReservationOnSalesOrder(SalesHeader."No.");
            LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationMessage);  // Enqueue for ConfirmHandler.
            LibraryVariableStorage.Enqueue(JournalLinesPostedMessage);  // Enqueue for MessageHandler.
            CreateAndPostProductionJournal(ProductionOrder."No.", Item."No.", -Quantity / 2, ItemLedgerEntry."Entry No.");  // Calculated Value required.

            // Verify.
            VerifyItemLedgerEntry(Item."No.", -Quantity / 2, 0);  // Calculated Value required, Use 0 for Remaining Quantity.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SortingByBinRankingOnMovementFromMovementWorksheet()
    var
        FromBin: Record Bin;
        ToBin: Record Bin;
        ToBin2: Record Bin;
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        Quantity: Decimal;
    begin
        // Setup: Create Item
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);

        // Create 1 Bins for Ajustment Zone and 2 Bins for Pick Zone with Bin Ranking Value
        // The Bin Ranking value from low to High is : ToBin, FromBin, ToBin2
        CreateBinForPickZoneWithBinRanking(ToBin, LocationWhite.Code, LibraryRandom.RandInt(10));
        CreateBinForAdjustmentZoneWithBinRanking(FromBin, LocationWhite.Code, ToBin."Bin Ranking" + LibraryRandom.RandInt(10));
        CreateBinForPickZoneWithBinRanking(ToBin2, LocationWhite.Code, FromBin."Bin Ranking" + LibraryRandom.RandInt(10));

        // Update Inventory and create movement worksheet line
        UpdateInventoryUsingWhseJournal(FromBin, Item, 2 * Quantity, ''); // Will create 2 movement worksheet line, each line with 1 Quantity of Item

        CreateWarehouseWorksheetNameForMovement(WhseWorksheetName);
        CreateMovementWorksheetLine(WhseWorksheetName, Item."No.", FromBin, ToBin2, Quantity);
        CreateMovementWorksheetLine(WhseWorksheetName, Item."No.", FromBin, ToBin, Quantity);

        // Exercise: Create Movement from Movement Worksheet Lines.
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::"Bin Ranking", false, false, false);

        // Verify: Warehouse Activity Lines gets sorted with Action Type.
        WarehouseActivityLine.SetFilter("Item No.", Item."No.");
        FindWarehouseActivityLineForMultipleSourceDocuments(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '', '', WarehouseActivityLine."Activity Type"::Movement);

        // Expected Line sequence is like below
        // 1. Take: FromBin
        // 2. Take: FromBin
        // 3. Place: ToBin
        // 4: Place: ToBin2
        VerifyActionTypeBinCodeAndBreakbulkOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", FromBin.Code, WarehouseActivityLine."Action Type"::Take, 0, Quantity, false); // Breakbulk No. is 0
        VerifyActionTypeBinCodeAndBreakbulkOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", FromBin.Code, WarehouseActivityLine."Action Type"::Take, 0, Quantity, true); // TRUE for NextLine. Breakbulk No. is 0
        VerifyActionTypeBinCodeAndBreakbulkOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", ToBin.Code, WarehouseActivityLine."Action Type"::Place, 0, Quantity, true); // TRUE for NextLine. Breakbulk No. is 0
        VerifyActionTypeBinCodeAndBreakbulkOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", ToBin2.Code, WarehouseActivityLine."Action Type"::Place, 0, Quantity, true); // TRUE for NextLine. Breakbulk No. is 0
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SortingByBinRankingOnPutAwayFromPutAwayWorksheetWithBreakBulk()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
        BreakBulkQty: Decimal;
        OldUsePutAwayWorksheet: Boolean;
    begin
        // Setup: Create Item, Unit Of Measure, which is multiple of Base Unit of Measure. Set Put Away Unit of Measure
        Initialize();
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, true);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", 0);  // Taking 0 for Blank Length.
        UpdatePutAwayUnitOfMeasureOnItem(Item, Item."Base Unit of Measure");

        // Create 3 Bins,Bin Ranking value from low to High is: Bin, Bin2, Bin3
        CreateBinAndUpdateBinContent(Bin, Item, LocationWhite.Code, 0, true);  // Taking TRUE for Fixed Bin.
        CreateBinForReceiveZoneWithBinRanking(Bin2, LocationWhite.Code, LibraryRandom.RandInt(50));
        CreateBinForReceiveZoneWithBinRanking(Bin3, LocationWhite.Code, Bin2."Bin Ranking" + LibraryRandom.RandInt(10));  // Greater value required for the test.

        // Create Purchase Order with two lines. The first line with base unit of measure of the item.
        // The second line with another Unit of Measure, multiple of base unit of measure. Make sure breakbulk lines will be generated during put away
        CreateAndReleasePurchaseOrderWithMultipleLines(
          PurchaseHeader, LocationWhite.Code, LocationWhite.Code,
          Item."No.", Quantity, Item."Base Unit of Measure", ItemUnitOfMeasure.Code, '', '');

        // Create Warehouse Receipt and update Bin Codes with different Bin Ranking on two Receipt lines. Post the Warehouse Receipt.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        UpdateBinCodeOnWarehouseReceiptLine(PurchaseHeader."No.", Bin3.Code, Bin2.Code, LocationWhite.Code);
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationWhite.Code);

        // Exercise.
        CreatePutAwayFromPutAwayWorksheet(
          WhseWorksheetLine, LocationWhite.Code, Item."No.", Item."No.", 0, "Whse. Activity Sorting Method"::"Bin Ranking", false);  // Taking 0 for Quantity.

        // Verify: Put-Away lines get sorted by Bin Ranking.
        FindWarehouseActivityLineForMultipleSourceDocuments(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", '',
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Expected Line sequence is like below
        // 1. Take: Bin2    Breakbulk No. is 1
        // 2. Place: Bin2   Breakbulk No. is 1
        // 3. Take: Bin2    Breakbulk No. is 0
        // 4. Take: Bin3    Breakbulk No. is 0
        // 5. Place: Bin    Breakbulk No. is 0
        // 6: Place: Bin    Breakbulk No. is 0
        BreakBulkQty := Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure";
        VerifyActionTypeBinCodeAndBreakbulkOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", Bin2.Code, WarehouseActivityLine."Action Type"::Take, 1, Quantity, false); // Breakbulk No. is 1
        VerifyActionTypeBinCodeAndBreakbulkOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", Bin2.Code, WarehouseActivityLine."Action Type"::Place, 1, BreakBulkQty, true); // TRUE for NextLine. Breakbulk No. is 1
        VerifyActionTypeBinCodeAndBreakbulkOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", Bin2.Code, WarehouseActivityLine."Action Type"::Take, 0, BreakBulkQty, true); // TRUE for NextLine. Breakbulk No. is 0
        VerifyActionTypeBinCodeAndBreakbulkOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", Bin3.Code, WarehouseActivityLine."Action Type"::Take, 0, Quantity, true); // TRUE for NextLine. Breakbulk No. is 0
        VerifyActionTypeBinCodeAndBreakbulkOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", Bin.Code, WarehouseActivityLine."Action Type"::Place, 0, Quantity, true); // TRUE for NextLine. Breakbulk No. is 0
        VerifyActionTypeBinCodeAndBreakbulkOnWarehouseActivityLine(
          WarehouseActivityLine, Item."No.", Bin.Code, WarehouseActivityLine."Action Type"::Place, 0, BreakBulkQty, true); // TRUE for NextLine. Breakbulk No. is 0

        // Tear Down.
        UpdateUsePutAwayWorksheetOnLocation(LocationWhite, OldUsePutAwayWorksheet, OldUsePutAwayWorksheet);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithSerialLotAndExpirationCalculation()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        LotNo: Variant;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
        Quantity: Integer;
    begin
        // Setup: Create Item with Item Tracking and Expiration Calculation.
        Initialize();
        CreateItemWithItemTrackingCode(Item, true, true, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode()); // Lot and Serial as TRUE.
        UpdateExpirationCalculationOnItem(Item);
        Quantity := LibraryRandom.RandIntInRange(2, 10); // Integer type was reuqired for Serial Tracking.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot And Serial"); // Enqueue value for ItemTrackingPageHandler.

        // Exercise: Create and post Purchase Order with Lot and Serial Tracking.
        CreateAndPostPurchaseOrder(PurchaseHeader, Item."No.", Quantity, true);
        LibraryVariableStorage.Dequeue(LotNo);

        // Verify the Count of Item Ledger Entry.
        // 1 quantity has one serial. So it generate Quantity Item Ledger Entry.
        VerifyNoOfLinesOfItemLedgerEntry(Item."No.", LotNo, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeOnWhseShipmentByGetSourceDocument()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create Item. Create Location with Shipment Bin Code. Create and release Sales Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateLocationSetupWithBins(Location, false, true, false, true, true); // Create Location with Require Pick and Require Shipment and Bin Mandatory.
        CreateAndReleaseSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, Location.Code, Item."No.", LibraryRandom.RandDec(10, 2), false);

        // Exercise: Create Warehouse Shipment and Get Source Document to create Shipment line.
        GetSourceDocumentOnWarehouseShipment(WarehouseShipmentHeader, Location.Code, true, false, false, Item."No.");

        // Verify: Verify the Bin Code on Warehouse Shipment Header and Warehouse Shipment Line shoule be the Shipment Bin Code of Location.
        Assert.AreEqual(WarehouseShipmentHeader."Bin Code", Location."Shipment Bin Code", ShipmentBinCodeErr);
        VerifyBinCodeForWarehouseShipmentLine(SalesHeader."No.", Location."Shipment Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeOnWhseReceiptByGetSourceDocument()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        // Setup: Create Item. Create Location with Receipt Bin Code. Create and release Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateLocationSetupWithBins(Location, true, false, true, false, true); // Create Location with Require Put-away and Require Receive and Bin Mandatory.
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Location.Code, '', Item."No.", LibraryRandom.RandDec(10, 2), Item."Base Unit of Measure", false);

        // Exercise: Create Warehouse Receipt and Get Source Document to create Receipt line.
        GetSourceDocumentOnWarehouseReceipt(WarehouseReceiptHeader, Location.Code, true, false, false, Item."No.", Item."No.");

        // Verify: Verify the Bin Code on Warehouse Receipt Header and Warehouse Receipt Line shoule be the Receipt Bin Code of Location.
        Assert.AreEqual(Location."Receipt Bin Code", WarehouseReceiptHeader."Bin Code", ReceiptBinCodeErr);
        VerifyBinCodeForWarehouseReceiptLine(PurchaseHeader."No.", Location."Receipt Bin Code", Location.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingFromReceiptHandler')]
    [Scope('OnPrem')]
    procedure NonDirectedPutAwayUsesItemsBaseUOMforGettingBinContent()
    var
        Location: Record Location;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // [FEATURE] [Put-away] [Unit of Measure] [Bin Content]
        // [SCENARIO 362996] Base UOM of Item is used for getting Bin Content while creating Put-Away from Posted Whse. Receipt when Directed Put-away is not set
        Initialize();

        // [GIVEN] Location with "Directed Put-away and Pick" = FALSE
        CreateLocationSetupWithBins(Location, true, true, true, true, true);

        // [GIVEN] Tracked Item "I" with Base UOM = "X" and additional UOM = "Y"
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Posted Whse. Receipt for Item "I" with UOM = "Y"
        // [GIVEN] Bin Content "B" with UOM = "X"
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, Location.Code, '', Item."No.", LibraryRandom.RandDec(9, 2), ItemUnitOfMeasure.Code, false);
        CreatedAndPostWarehouseReceiptWithTracking(Location, PurchaseHeader."No.", Item."No.");
        DeletePutAway(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        // [WHEN] Create Put-away for Item "I" from Posted Whse. Receipt
        CreatePutAwayFromPutAwayWorksheet(
          WhseWorksheetLine, Location.Code, Item."No.", Item."No.", 0, "Whse. Activity Sorting Method"::None, false);
        // [THEN] Put-away is created using BinContent "B".
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromWhseShipmentWithAssemblyAndPickWorksheet()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesHeaderNo: Code[20];
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        // [FEATURE] [Warehouse Pick] [Warehouse Shipment] [Assembly Order]
        // [SCENARIO 371965] Creating Pick from Warehouse Shipment with Assembly while having Pick Worksheet from that Shipment should be prohibited
        Initialize();

        Qty := LibraryRandom.RandInt(10);
        QtyPer := LibraryRandom.RandInt(10);

        // [GIVEN] Assembed Item "AI" and Component Item "CI" on Location with "Directed Put-Away and Pick"
        CreateAssembledItem(ParentItem, ComponentItem, QtyPer);
        PostItemJournalThroughCalculateWhseAdjmt(ComponentItem, Qty * QtyPer);

        // [GIVEN] Sales Order "SO" with two Lines for "AI" and "CI" respectively
        SalesHeaderNo := CreateAndReleaseSalesOrderWithAssembly(ParentItem, ComponentItem, Qty);

        // [GIVEN] Warehouse Shipment "WS" for "SO"
        GetSourceDocumentOnWarehouseShipment(
          WarehouseShipmentHeader, LocationWhite.Code, true, false, false, StrSubstNo('%1|%2', ParentItem."No.", ComponentItem."No."));
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // [GIVEN] Pick Worksheet for "WS"
        GetWarehouseDocumentOnPickWorksheet(WhseWorksheetName, LocationWhite.Code);

        // [WHEN] Create Pick from "WS"
        asserterror CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeaderNo);

        // [THEN] Error is thrown: "Nothing to handle."
        Assert.ExpectedError(NothingToHandle);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickQuantityBaseIsFilteredByUOMWhileDirectedPutAwayAndPickIsOn()
    var
        UnitOfMeasure: Record "Unit of Measure";
        BinContent: Record "Bin Content";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Bin Content]
        // [SCENARIO 363334] FlowField "Pick Quantity (Base)" of Bin Content table is filtered by UOM of Whse. Active Line while "Directed Put-Away and Pick" = TRUE
        Initialize();

        // [GIVEN] Location with "Directed Put-away and Pick" = TRUE
        // [GIVEN] Warehouse Activity Line with "Item Unit of Measure" = "X" and "Qty. Outstanding (Base)" = "Q"
        CreateWarehouseActivityLine(WarehouseActivityLine, LocationWhite.Code);

        // [GIVEN] Bin Content with "Item Unit of Measure" = "Y"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        BinContent."Location Code" := LocationWhite.Code;
        BinContent."Unit of Measure Code" := UnitOfMeasure.Code;
        BinContent.Insert();
        // [WHEN] Calculate Field "Pick Quantity (Base)" on Bin Content
        BinContent.SetFilterOnUnitOfMeasure();
        BinContent.CalcFields("Pick Quantity (Base)");
        // [THEN] "Pick Quantity (Base)" = 0
        Assert.AreEqual(0, BinContent."Pick Quantity (Base)", PickQuantityBaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickQuantityBaseIsNotFilteredByUOMWhileDirectedPutAwayAndPickIsOff()
    var
        Location: Record Location;
        UnitOfMeasure: Record "Unit of Measure";
        BinContent: Record "Bin Content";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Bin Content]
        // [SCENARIO 363334] FlowField "Pick Quantity (Base)" of Bin Content table is not filtered by UOM of Whse. Active Line while "Directed Put-Away and Pick" = FALSE
        Initialize();

        // [GIVEN] Location with "Directed Put-away and Pick" = FALSE
        CreateLocationSetupWithBins(Location, true, true, true, true, true);

        // [GIVEN] Warehouse Activity Line with "Item Unit of Measure" = "X" and "Qty. Outstanding (Base)" = "Q"
        CreateWarehouseActivityLine(WarehouseActivityLine, Location.Code);

        // [GIVEN] Bin Content with "Item Unit of Measure" = "Y"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        BinContent."Location Code" := Location.Code;
        BinContent."Unit of Measure Code" := UnitOfMeasure.Code;
        BinContent.Insert();
        // [WHEN] Calculate Field "Pick Quantity (Base)" on Bin Content
        BinContent.SetFilterOnUnitOfMeasure();
        BinContent.CalcFields("Pick Quantity (Base)");
        // [THEN] "Pick Quantity (Base)" = "Q"
        Assert.AreEqual(WarehouseActivityLine."Qty. Outstanding (Base)", BinContent."Pick Quantity (Base)", PickQuantityBaseErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreateAdditionalWarehouseReceiptFromPurchaseOrderAfterPartialReceipt()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Receipt] [Document Status] [Purchase Order]
        // [SCENARIO 216481] Warehouse Receipt Document Status is set to "Partially Received" when additional Warehouse Receipt is created from Purchase Order after partial receipts have been posted
        Initialize();

        // [GIVEN] Purchase Order "PO" with non-zero Quantity = "Q"
        Quantity := LibraryRandom.RandIntInRange(10, 100);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Post Warehouse Receipt "WR1" with Quantity = "Q"/2
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity, Item."Base Unit of Measure");
        UpdateQuantityOnWarehouseReceiptLineFromPurchaseOrder(PurchaseHeader."No.", Item."No.", LocationWhite.Code, '', Quantity / 2);
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationWhite.Code);
        FindWarehouseReceiptHeaderFromPurchaseOrder(WarehouseReceiptHeader, PurchaseHeader."No.", LocationWhite.Code);

        // [GIVEN] "WR1" Document Status = "Partially Received"
        WarehouseReceiptHeader.TestField("Document Status", WarehouseReceiptHeader."Document Status"::"Partially Received");

        // [GIVEN]  "WR1" is deleted
        LibraryVariableStorage.Enqueue(WarehouseHeaderDeleteConfirmationMsg);
        WarehouseReceiptHeader.Delete(true);

        // [WHEN] New Warehouse Receipt "WR2" is created from "PO"
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptHeaderFromPurchaseOrder(WarehouseReceiptHeader, PurchaseHeader."No.", LocationWhite.Code);

        // [THEN] "WR2" Document Status = "Partially Received"
        WarehouseReceiptHeader.TestField("Document Status", WarehouseReceiptHeader."Document Status"::"Partially Received");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreateAdditionalWarehouseReceiptFromTransferOrderAfterPartialReceipt()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Receipt] [Document Status] [TransferOrder]
        // [SCENARIO 216481] Warehouse Receipt Document Status is set to "Partially Received" when additional Warehouse Receipt is created from Transfer Order after partial receipts have been posted
        Initialize();

        // [GIVEN] Transfer Order "TO" with non-zero Quantity = "Q"
        Quantity := LibraryRandom.RandIntInRange(10, 100);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Post Warehouse Receipt "WR1" with Quantity = "Q"/2
        CreateWarehouseReceiptFromTransferOrder(TransferHeader, LocationBlue.Code, LocationWhite.Code, Item."No.", Quantity);
        UpdateQuantityOnWarehouseReceiptLineFromTransferOrder(TransferHeader."No.", Item."No.", LocationWhite.Code, '', Quantity / 2);
        PostWarehouseReceiptFromTransferOrder(TransferHeader."No.", LocationWhite.Code);
        FindWarehouseReceiptHeaderFromTransferOrder(WarehouseReceiptHeader, TransferHeader."No.", LocationWhite.Code);

        // [GIVEN] "WR1" Document Status = "Partially Received"
        WarehouseReceiptHeader.TestField("Document Status", WarehouseReceiptHeader."Document Status"::"Partially Received");

        // [GIVEN]  "WR1" is deleted
        LibraryVariableStorage.Enqueue(WarehouseHeaderDeleteConfirmationMsg);
        WarehouseReceiptHeader.Delete(true);

        // [WHEN] New Warehouse Receipt "WR2" is created from "TO"
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
        FindWarehouseReceiptHeaderFromTransferOrder(WarehouseReceiptHeader, TransferHeader."No.", LocationWhite.Code);

        // [THEN] "WR2" Document Status = "Partially Received"
        WarehouseReceiptHeader.TestField("Document Status", WarehouseReceiptHeader."Document Status"::"Partially Received");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreateAdditionalWarehouseReceiptFromSalesReturnOrderAfterPartialReceipt()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Receipt] [Document Status] [Sales Order]
        // [SCENARIO 216481] Warehouse Receipt Document Status is set to "Partially Received" when additional Warehouse Receipt is created from Sales Return Order after partial receipts have been posted
        Initialize();

        // [GIVEN] Sales Order "SO" with non-zero Quantity = "Q"
        Quantity := LibraryRandom.RandIntInRange(10, 100);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Post Warehouse Receipt "WR1" with Quantity = "Q"/2
        CreateWarehouseReceiptFromSalesReturnOrder(SalesHeader, LocationWhite.Code, Item."No.", Quantity);
        UpdateQuantityOnWarehouseReceiptLineFromSalesReturnOrder(SalesHeader."No.", Item."No.", LocationWhite.Code, '', Quantity / 2);
        PostWarehouseReceiptFromSalesReturnOrder(SalesHeader."No.", LocationWhite.Code);
        FindWarehouseReceiptHeaderFromSalesReturnOrder(WarehouseReceiptHeader, SalesHeader."No.", LocationWhite.Code);

        // [GIVEN] "WR1" Document Status = "Partially Received"
        WarehouseReceiptHeader.TestField("Document Status", WarehouseReceiptHeader."Document Status"::"Partially Received");

        // [GIVEN]  "WR1" is deleted
        LibraryVariableStorage.Enqueue(WarehouseHeaderDeleteConfirmationMsg);
        WarehouseReceiptHeader.Delete(true);

        // [WHEN] New Warehouse Receipt "WR2" is created from "SO"
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        FindWarehouseReceiptHeaderFromSalesReturnOrder(WarehouseReceiptHeader, SalesHeader."No.", LocationWhite.Code);

        // [THEN] "WR2" Document Status = "Partially Received"
        WarehouseReceiptHeader.TestField("Document Status", WarehouseReceiptHeader."Document Status"::"Partially Received");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreateAdditionalMultiplyWarehouseReceiptsFromPurchaseOrderAfterPartialReceipt()
    var
        WarehouseReceiptHeader: array[2] of Record "Warehouse Receipt Header";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Receipt] [Document Status] [Purchase Order]
        // [SCENARIO 220473] Document Status is set to "Partially Received" in all Warehouse Receipts when multiple additional Warehouse Receipts is created from Purchase Order after partial receipts have been posted
        Initialize();

        // [GIVEN] Purchase Order "PO" with two items "I" from different Warehouses with non-zero Quantities = "Q"
        Quantity := LibraryRandom.RandIntInRange(10, 100);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Post two Warehouse Receipts "WR1" and "WR2" with Quantities = "Q"/2 and "Q"/3
        CreateAndReleasePurchaseOrderWithMultipleLines(
          PurchaseHeader, LocationWhite.Code, LocationGreen.Code, Item."No.", Quantity, Item."Base Unit of Measure",
          Item."Base Unit of Measure", '', '');
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        UpdateQuantityOnWarehouseReceiptLineFromPurchaseOrder(PurchaseHeader."No.", Item."No.", LocationWhite.Code, '', Quantity / 2);
        UpdateQuantityOnWarehouseReceiptLineFromPurchaseOrder(PurchaseHeader."No.", Item."No.", LocationGreen.Code, '', Quantity / 3);
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationWhite.Code);
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationGreen.Code);

        FindWarehouseReceiptHeaderFromPurchaseOrder(WarehouseReceiptHeader[1], PurchaseHeader."No.", LocationWhite.Code);
        FindWarehouseReceiptHeaderFromPurchaseOrder(WarehouseReceiptHeader[2], PurchaseHeader."No.", LocationGreen.Code);

        // [GIVEN] "WR1" and "WR2" Document Status = "Partially Received"
        WarehouseReceiptHeader[1].TestField("Document Status", WarehouseReceiptHeader[1]."Document Status"::"Partially Received");
        WarehouseReceiptHeader[2].TestField("Document Status", WarehouseReceiptHeader[2]."Document Status"::"Partially Received");

        // [GIVEN]  "WR1" and "WR2" are deleted
        LibraryVariableStorage.Enqueue(WarehouseHeaderDeleteConfirmationMsg);
        LibraryVariableStorage.Enqueue(WarehouseHeaderDeleteConfirmationMsg);
        WarehouseReceiptHeader[1].Delete(true);
        WarehouseReceiptHeader[2].Delete(true);

        // [WHEN] New Warehouse Receipts "WR3" and "WR4" is created from "PO"
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptHeaderFromPurchaseOrder(WarehouseReceiptHeader[1], PurchaseHeader."No.", LocationWhite.Code);
        FindWarehouseReceiptHeaderFromPurchaseOrder(WarehouseReceiptHeader[2], PurchaseHeader."No.", LocationGreen.Code);

        // [THEN] "WR3" and "WR4" Document Status = "Partially Received"
        WarehouseReceiptHeader[1].TestField("Document Status", WarehouseReceiptHeader[1]."Document Status"::"Partially Received");
        WarehouseReceiptHeader[2].TestField("Document Status", WarehouseReceiptHeader[2]."Document Status"::"Partially Received");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreateAdditionalMultiplyWarehouseReceiptsFromSalesReturnOrderAfterPartialReceipt()
    var
        WarehouseReceiptHeader: array[2] of Record "Warehouse Receipt Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Receipt] [Document Status] [Sales Order]
        // [SCENARIO 220473] Document Status is set to "Partially Received" in all Warehouse Receipts when multiple additional Warehouse Receipts is created from Sales Return Order after partial receipts have been posted
        Initialize();

        // [GIVEN] Sales Order "SO" with two items "I" from different Warehouses with non-zero Quantities = "Q"
        Quantity := LibraryRandom.RandIntInRange(10, 100);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Post two Warehouse Receipts "WR1" and "WR2" with Quantities = "Q"/2 and "Q"/3
        CreateAndReleaseSalesDocWithMultipleLines(
          SalesHeader, SalesHeader."Document Type"::"Return Order",
          LocationWhite.Code, LocationGreen.Code, Item."No.", Item."No.", '', '', Quantity, false);
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        UpdateQuantityOnWarehouseReceiptLineFromSalesReturnOrder(SalesHeader."No.", Item."No.", LocationWhite.Code, '', Quantity / 2);
        UpdateQuantityOnWarehouseReceiptLineFromSalesReturnOrder(SalesHeader."No.", Item."No.", LocationGreen.Code, '', Quantity / 3);
        PostWarehouseReceiptFromSalesReturnOrder(SalesHeader."No.", LocationWhite.Code);
        PostWarehouseReceiptFromSalesReturnOrder(SalesHeader."No.", LocationGreen.Code);

        FindWarehouseReceiptHeaderFromSalesReturnOrder(WarehouseReceiptHeader[1], SalesHeader."No.", LocationWhite.Code);
        FindWarehouseReceiptHeaderFromSalesReturnOrder(WarehouseReceiptHeader[2], SalesHeader."No.", LocationGreen.Code);

        // [GIVEN] "WR1" and "WR2" Document Status = "Partially Received"
        WarehouseReceiptHeader[1].TestField("Document Status", WarehouseReceiptHeader[1]."Document Status"::"Partially Received");
        WarehouseReceiptHeader[2].TestField("Document Status", WarehouseReceiptHeader[2]."Document Status"::"Partially Received");

        // [GIVEN]  "WR1" and "WR2" are deleted
        LibraryVariableStorage.Enqueue(WarehouseHeaderDeleteConfirmationMsg);
        LibraryVariableStorage.Enqueue(WarehouseHeaderDeleteConfirmationMsg);
        WarehouseReceiptHeader[1].Delete(true);
        WarehouseReceiptHeader[2].Delete(true);

        // [WHEN] New Warehouse Receipts "WR3" and "WR4" is created from "PO"
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        FindWarehouseReceiptHeaderFromSalesReturnOrder(WarehouseReceiptHeader[1], SalesHeader."No.", LocationWhite.Code);
        FindWarehouseReceiptHeaderFromSalesReturnOrder(WarehouseReceiptHeader[2], SalesHeader."No.", LocationGreen.Code);

        // [THEN] "WR3" and "WR4" Document Status = "Partially Received"
        WarehouseReceiptHeader[1].TestField("Document Status", WarehouseReceiptHeader[1]."Document Status"::"Partially Received");
        WarehouseReceiptHeader[2].TestField("Document Status", WarehouseReceiptHeader[2]."Document Status"::"Partially Received");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyBinContentNotCreatedForAutoGeneratedPutAwayLineWithActionTypePlace()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BinContent: Record "Bin Content";
    begin
        // [FEATURE] [Warehouse Receipt] [Put-away] [Bin Content]
        // [SCENARIO 229915] When a put-away is created automatically after posting warehouse receipt, and the place-to bin is empty so far, no bin content record is created for this bin.
        Initialize();

        // [GIVEN] Location with directed put-away and pick.
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryInventory.CreateItem(Item);

        // [WHEN] Purchase order is released, warehouse receipt is for the order is posted.
        CreatePurchaseOrderAndPostWarehouseReceipt(
          PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandInt(10), Item."Base Unit of Measure");
        // [THEN] Put-away is created.
        // [THEN] Bin Content does not exist for the bin, into which items will be placed.
        FilterWarehouseActivityLines(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", '', WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.DeleteBinContent(Enum::"Warehouse Action Type"::Place.AsInteger());

        FilterBinContent(BinContent, WarehouseActivityLine."Location Code", WarehouseActivityLine."Bin Code", WarehouseActivityLine."Item No.");
        if BinContent.FindFirst() then begin
            BinContent.CalcFields(Quantity);
            Assert.AreEqual(0, BinContent.Quantity, 'Bin Content must be empty.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyBinContentNotCreatedForManualGeneratedPutAwayLineWithActionTypePlace()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        BinContent: Record "Bin Content";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        // [FEATURE] [Warehouse Receipt] [Put-away] [Bin Content]
        // [SCENARIO 229915] When a put-away is created manually by user from posted warehouse receipt, and the place-to bin is empty so far, no bin content record is created for this bin.
        Initialize();

        // [GIVEN] Location with directed put-away and pick.
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase order is released, warehouse receipt is for the order is posted.
        CreatePurchaseOrderAndPostWarehouseReceipt(
          PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandInt(10), Item."Base Unit of Measure");

        // [GIVEN] Automatically generated put-away is deleted.
        DeletePutAway(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        // [WHEN] Create put-away from the posted receipt.
        FindPostedWhseReceiptLine(
          PostedWhseReceiptLine, PostedWhseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Item."No.", '');
        PostedWhseReceiptLine.SetHideValidationDialog(true);
        PostedWhseReceiptLine.CreatePutAwayDoc(PostedWhseReceiptLine, '');
        // [THEN] Put-away is created.
        // [THEN] Bin Content does not exist for the bin, into which items will be placed.
        FilterWarehouseActivityLines(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", '', WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.DeleteBinContent(Enum::"Warehouse Action Type"::Place.AsInteger());

        FilterBinContent(BinContent, WarehouseActivityLine."Location Code", WarehouseActivityLine."Bin Code", WarehouseActivityLine."Item No.");
        if BinContent.FindFirst() then begin
            BinContent.CalcFields(Quantity);
            Assert.AreEqual(0, BinContent.Quantity, 'Bin Content must be empty.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePutAwaySkipsOverloadedBinContent()
    var
        Item: Record Item;
        Location: Record Location;
        Zone: Record Zone;
        Bin: array[2] of Record Bin;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Put-away] [Bin Content]
        // [SCENARIO 252119] When bin content is already above its maximum capacity, the program does not suggest this bin for a new put-away.
        Initialize();

        // [GIVEN] Item "I".
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location with directed put-away and pick.
        // [GIVEN] There are two bins "B1" and "B2" in the pick zone.
        // [GIVEN] Create bin content for item "I" in bin "B2". Set "Max. Qty." = "X".
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        FindZone(Zone, Location.Code, false, true, true);
        LibraryWarehouse.FindBin(Bin[1], Location.Code, Zone.Code, 1);
        LibraryWarehouse.FindBin(Bin[2], Location.Code, Zone.Code, 2);
        CreateAndUpdateBinContent(Bin[2], Item, LibraryRandom.RandIntInRange(10, 20), false);

        // [GIVEN] Place "Y" >= "X" pcs of item "I" into bin "B2", thereby overloading the bin.
        UpdateInventoryUsingWhseJournal(Bin[2], Item, LibraryRandom.RandIntInRange(20, 40), '');

        // [WHEN] Create and post warehouse receipt from a purchase order for item "I". That creates a put-away.
        CreatePurchaseOrderAndPostWarehouseReceipt(
          PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandInt(10), Item."Base Unit of Measure");
        // [THEN] "Bin Code" on the put-away line is equal to "B1", instead of "B2".
        FilterWarehouseActivityLines(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", '', WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", Bin[1].Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure UndoPostedPurchaseReceiptForOneOfMultipleLocations()
    var
        Location: array[2] of Record Location;
        Item: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
        Index: Integer;
        WhseManagement: Codeunit "Whse. Management";
    begin
        // [FEATURES] [Undo Receipt] [Purchase Order]
        // [SCENARIO 292815] Undo Purchase Receipt should consider Location Code for each Purchase Line.
        Initialize();

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.SetRecFilter();

        // [GIVEN] Two Items in two Purchase Lines with Two Location Codes "A" and "B"
        // [GIVEN] Each Location Code with Require Receive
        for Index := 1 to ArrayLen(Location) do begin
            CreateAndUpdateLocation(Location[Index], false, false, true, false, false);
            LibraryInventory.CreateItem(Item[Index]);
            LibraryPurchase.CreatePurchaseLine(PurchaseLine[Index], PurchaseHeader, PurchaseLine[Index].Type::Item, Item[Index]."No.", 1);
            PurchaseLine[Index].Validate("Location Code", Location[Index].Code);
            PurchaseLine[Index].Modify(true);
        end;

        // [GIVEN] Purchase Order released and Whse. Receipts created and posted for both lines
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source Subtype", PurchaseLine[1]."Document Type");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseLine[1]."Document No.");
        WarehouseReceiptLine.FindSet();
        repeat
            WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
            LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        until WarehouseReceiptLine.Next() = 0;

        // [GIVEN] Receipt for the Line 2 with Location Code "B" is being Undo
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine[2]."Line No.");
        PurchRcptLine.SetRange(Quantity, PurchaseLine[2].Quantity);
        PurchRcptLine.FindFirst();
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [WHEN] Create new Whse. Receipt for the Line 2
        GetSourceDocInbound.CreateFromPurchOrderHideDialog(PurchaseHeader);

        // [THEN] Whse. Receipt created for the Line 2
        WhseManagement.SetSourceFilterForWhseRcptLine(
          WarehouseReceiptLine, DATABASE::"Purchase Line", PurchaseLine[2]."Document Type".AsInteger(),
          PurchaseLine[2]."Document No.", PurchaseLine[2]."Line No.", true);
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.TestField("Location Code", PurchaseLine[2]."Location Code");
        WarehouseReceiptLine.TestField(Quantity, PurchaseLine[2].Quantity);
    end;

    [Test]
    procedure CreatePutAwayWithFloatingBinSkipsOverloadedBinContent()
    var
        Item: Record Item;
        Location: Record Location;
        Zone: Record Zone;
        Bin: array[2] of Record Bin;
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Put-away] [Bin Content]
        // [SCENARIO 401645] Floating bin case - when bin content is already above its maximum capacity, the program does not suggest this bin for a new put-away.
        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create put-away template, set "Floating Bin" = TRUE, all other parameters to FALSE.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(
          PutAwayTemplateHeader, PutAwayTemplateLine, false, true, false, false, false, false);

        // [GIVEN] Location with directed put-away and pick, assign the new put-away template code.
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        Location.Validate("Put-away Template Code", PutAwayTemplateHeader.Code);
        Location.Modify(true);

        // [GIVEN] Find "B1", "B2" in the pick zone.
        // [GIVEN] Set maximum quantity = 20 for bin "B2".
        FindZone(Zone, Location.Code, false, true, true);
        LibraryWarehouse.FindBin(Bin[1], Location.Code, Zone.Code, 1);
        LibraryWarehouse.FindBin(Bin[2], Location.Code, Zone.Code, 2);
        CreateAndUpdateBinContent(Bin[2], Item, LibraryRandom.RandIntInRange(10, 20), false);

        // [GIVEN] Post 40 pcs to bin "B2" using warehouse journal, thereby overloading the bin.
        UpdateInventoryUsingWhseJournal(Bin[2], Item, LibraryRandom.RandIntInRange(20, 40), '');

        // [GIVEN] Create purchase order for 10 pcs, release.
        // [GIVEN] Create and post warehouse receipt.
        // [WHEN] Create put-away.
        CreatePurchaseOrderAndPostWarehouseReceipt(
          PurchaseHeader, Location.Code, Item."No.", LibraryRandom.RandInt(10), Item."Base Unit of Measure");
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);

        // [THEN] "Bin Code" on the put-away line is equal to "B1", instead of "B2".
        // [THEN] Quantity on the "Place" put-away line = 10.
        FilterWarehouseActivityLines(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", '',
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", Bin[1].Code);
        WarehouseActivityLine.TestField(Quantity, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('CreateWhsePutAwayPickHandler,SimpleMessageHandler')]
    procedure PurchaseOrderWithNonInventoryItemsForLocationRequiringPutAway()
    var
        Location: Record Location;
        ItemInventory: Record Item;
        ItemNonInventory: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO]
        Initialize();

        // [GIVEN] Location with put-away required.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Inventory- and non-inventory item.
        LibraryInventory.CreateItem(ItemInventory);
        CreateAndPostItemJournalLine(
            ItemInventory."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", 1, Location.Code, false
        );
        LibraryInventory.CreateNonInventoryTypeItem(ItemNonInventory);

        // [GIVEN] A released purchase order with inventory- and non-inventory item.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemInventory."No.", 1);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNonInventory."No.", 1);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Creating pick.
        Commit();
        PurchaseHeader.CreateInvtPutAwayPick();

        // [THEN] A warehouse pick for the inventory item has been created.
        WarehouseActivityLine.SetRange("Item No.", ItemInventory."No.");
        WarehouseActivityLine.FindFirst();

        // [THEN] No warehouse pick for the non-inventory item has been created.
        WarehouseActivityLine.SetRange("Item No.", ItemNonInventory."No.");
        Assert.IsTrue(WarehouseActivityLine.IsEmpty(), 'Expected no warehouse activity line for non-inventory item');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure UndoPurchReceiptWithWarehouseWhenLineNoAndOrderLineNoDoNotMatch()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        WarehouseEntry: Record "Warehouse Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Undo Receipt]
        // [SCENARIO 422503] Undo warehouse entries for purchase receipt line with Line No. <> Order Line No.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Location with mandatory bin and required receipt.
        CreateAndUpdateLocation(Location, false, false, true, false, true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Location.Validate("Receipt Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Create purchase order and post warehouse receipt.
        LibraryInventory.CreateItem(Item);
        CreatePurchaseOrderAndPostWarehouseReceipt(PurchaseHeader, Location.Code, Item."No.", Qty, Item."Base Unit of Measure");

        // [GIVEN] Verify that warehouse entry is posted.
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", Qty);

        // [GIVEN] Make "Line No." on purchase receipt line be not equal to "Order Line No.".
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("No.", Item."No.");
        PurchRcptLine.FindFirst();
        PurchRcptLine2 := PurchRcptLine;
        PurchRcptLine2."Line No." += 1;
        PurchRcptLine2.Insert();
        PurchRcptLine.Delete();

        // [WHEN] Undo the purchase receipt line.
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] The warehouse entry has been correctly reversed.
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", 0);
    end;

    [Test]
    procedure PostWarehouseReceiptForOrderOnlyAttachedNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        i: Integer;
    begin
        // [FEATURE] [Attached to Line No] [Non-Inventory Item] [Purchase] [Order] [Receipt]
        // [SCENARIO 456417] Automatic posting of attached non-inventory purchase order lines using warehouse receipt.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in purchase setup to "Attached/Assigned".
        UpdateNonInvtPostingPolicyInPurchaseSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required receipt.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);

        // [GIVEN] Create purchase order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2". Attach "NI1" to "I1" and "NI2" to "I2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreatePurchaseDocumentWithVariousLines(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create warehouse receipt.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Set "Qty. to Receive" on warehouse receipt line for "I2" to zero.
        FindWarehouseReceiptHeaderFromPurchaseOrder(WarehouseReceiptHeader, PurchaseHeader."No.", Location.Code);
        UpdateQuantityOnWarehouseReceiptLineFromPurchaseOrder(PurchaseHeader."No.", Item[2]."No.", Location.Code, '', 0);

        // [WHEN] Post the warehouse receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Item line "I1" is fully received.
        // [THEN] Item line "I2" is not received.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[1]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[2]."No.");
        PurchaseLine.TestField("Quantity Received", 0);

        // [THEN] Non-inventory line "NI1" is fully received.
        // [THEN] Non-inventory line "NI2" is not received.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[1]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[2]."No.");
        PurchaseLine.TestField("Quantity Received", 0);

        // [THEN] Item charge line "IC1" is received for half quantity.
        // [THEN] Item charge line "IC2" is received for half quantity.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[1]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity / 2);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[2]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure PostInventoryPutAwayForOrderOnlyAttachedNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        // [FEATURE] [Attached to Line No] [Non-Inventory Item] [Purchase] [Order] [Inventory Put-away]
        // [SCENARIO 456417] Automatic posting of attached non-inventory purchase order lines using inventory put-away.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in purchase setup to "Attached/Assigned".        
        UpdateNonInvtPostingPolicyInPurchaseSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required put-away.        
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Create purchase order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2". Attach "NI1" to "I1" and "NI2" to "I2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreatePurchaseDocumentWithVariousLines(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create inventory put-away.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        // [GIVEN] Set "Qty. to Handle" on inventory put-away line for "I2" to zero.
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        UpdateQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away", Item[2]."No.", 0);

        // [WHEN] Post the inventory put-away.
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away", false);

        // [THEN] Item line "I1" is fully received.
        // [THEN] Item line "I2" is not received.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[1]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[2]."No.");
        PurchaseLine.TestField("Quantity Received", 0);

        // [THEN] Non-inventory line "NI1" is fully received.
        // [THEN] Non-inventory line "NI2" is not received.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[1]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[2]."No.");
        PurchaseLine.TestField("Quantity Received", 0);

        // [THEN] Item charge line "IC1" is received for half quantity.
        // [THEN] Item charge line "IC2" is received for half quantity.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[1]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity / 2);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[2]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity / 2);
    end;

    [Test]
    procedure PostWarehouseShipmentForReturnOrderOnlyAttachedNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        i: Integer;
    begin
        // [FEATURE] [Attached to Line No] [Non-Inventory Item] [Purchase] [Return Order] [Shipment]
        // [SCENARIO 456417] Automatic posting of attached non-inventory purchase return order lines using warehouse shipment.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in purchase setup to "Attached/Assigned".
        UpdateNonInvtPostingPolicyInPurchaseSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);

        // [GIVEN] Create purchase return order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2". Attach "NI1" to "I1" and "NI2" to "I2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreatePurchaseDocumentWithVariousLines(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create warehouse shipment.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);

        // [GIVEN] Set "Qty. to Ship" on warehouse shipment line for "I2" to zero.
        FindWarehouseShipmentHeaderFromPurchaseReturnOrder(WarehouseShipmentHeader, PurchaseHeader."No.", Location.Code);
        UpdateQuantityOnWarehouseShipmentLineFromPurchaseReturnOrder(PurchaseHeader."No.", Item[2]."No.", Location.Code, '', 0);

        // [WHEN] Post the warehouse shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Item line "I1" is fully shipped.
        // [THEN] Item line "I2" is not shipped.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[1]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[2]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", 0);

        // [THEN] Non-inventory line "NI1" is fully shipped.
        // [THEN] Non-inventory line "NI2" is not shipped.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[1]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[2]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", 0);

        // [THEN] Item charge line "IC1" is shipped for half quantity.
        // [THEN] Item charge line "IC2" is shipped for half quantity.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[1]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity / 2);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[2]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure PostInventoryPickForReturnOrderOnlyAttachedNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        // [FEATURE] [Attached to Line No] [Non-Inventory Item] [Purchase] [Return Order] [Inventory Pick]
        // [SCENARIO 456417] Automatic posting of attached non-inventory purchase return order lines using inventory pick.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in purchase setup to "Attached/Assigned".
        UpdateNonInvtPostingPolicyInPurchaseSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Post items to inventory.
        for i := 1 to 2 do
            CreateAndPostItemJournalLine(
              Item[i]."No.", "Item Ledger Entry Type"::"Positive Adjmt.", LibraryRandom.RandIntInRange(50, 100), Location.Code, false);

        // [GIVEN] Create purchase return order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2". Attach "NI1" to "I1" and "NI2" to "I2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreatePurchaseDocumentWithVariousLines(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create inventory pick.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        // [GIVEN] Set "Qty. to Handle" on inventory pick line for "I2" to zero.
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick");
        UpdateQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", Item[2]."No.", 0);

        // [WHEN] Post the inventory pick.
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", false);

        // [THEN] Item line "I1" is fully shipped.
        // [THEN] Item line "I2" is not shipped.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[1]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[2]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", 0);

        // [THEN] Non-inventory line "NI1" is fully shipped.
        // [THEN] Non-inventory line "NI2" is not shipped.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[1]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[2]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", 0);

        // [THEN] Item charge line "IC1" is shipped for half quantity.
        // [THEN] Item charge line "IC2" is shipped for half quantity.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[1]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity / 2);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[2]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity / 2);
    end;

    [Test]
    procedure PostWarehouseReceiptForOrderAllNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        i: Integer;
    begin
        // [FEATURE] [Non-Inventory Item] [Purchase] [Order] [Receipt]
        // [SCENARIO 456417] Automatic posting of all non-inventory purchase order lines using warehouse receipt.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in purchase setup to "All".
        UpdateNonInvtPostingPolicyInPurchaseSetup("Non-Invt. Item Whse. Policy"::All);

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required receipt.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);

        // [GIVEN] Create purchase order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreatePurchaseDocumentWithVariousLines(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create warehouse receipt.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Set "Qty. to Receive" on warehouse receipt line for "I2" to zero.
        FindWarehouseReceiptHeaderFromPurchaseOrder(WarehouseReceiptHeader, PurchaseHeader."No.", Location.Code);
        UpdateQuantityOnWarehouseReceiptLineFromPurchaseOrder(PurchaseHeader."No.", Item[2]."No.", Location.Code, '', 0);

        // [WHEN] Post the warehouse receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Item line "I1" is fully received.
        // [THEN] Item line "I2" is not received.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[1]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[2]."No.");
        PurchaseLine.TestField("Quantity Received", 0);

        // [THEN] Non-inventory line "NI1" is fully received.
        // [THEN] Non-inventory line "NI2" is fully received.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[1]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[2]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);

        // [THEN] Item charge line "IC1" is fully received.
        // [THEN] Item charge line "IC2" is fully received.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[1]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[2]."No.");
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure PostInventoryPickForReturnOrderAllNonInvtLines()
    var
        Item: array[2] of Record Item;
        NonInvtItem: array[2] of Record Item;
        ItemCharge: array[2] of Record "Item Charge";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        // [FEATURE] [Non-Inventory Item] [Purchase] [Return Order] [Inventory Pick]
        // [SCENARIO 456417] Automatic posting of all non-inventory purchase return order lines using inventory pick.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in purchase setup to "All".
        UpdateNonInvtPostingPolicyInPurchaseSetup("Non-Invt. Item Whse. Policy"::All);

        // [GIVEN] Create two items, two non-inventory items, and two item charges.
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem[i]);
            LibraryInventory.CreateItemCharge(ItemCharge[i]);
        end;

        // [GIVEN] Location set up for required pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Post items to inventory.
        for i := 1 to 2 do
            CreateAndPostItemJournalLine(
              Item[i]."No.", "Item Ledger Entry Type"::"Positive Adjmt.", LibraryRandom.RandIntInRange(50, 100), Location.Code, false);

        // [GIVEN] Create purchase return order with the following lines:
        // [GIVEN] Two item lines "I1" and "I2".
        // [GIVEN] Two non-inventory item lines "NI1" and "NI2".
        // [GIVEN] Two item charge lines "IC1" and "IC2". Assign each item charge equally to two item lines.
        CreatePurchaseDocumentWithVariousLines(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Item, NonInvtItem, ItemCharge, Location.Code);

        // [GIVEN] Create inventory pick.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        // [GIVEN] Set "Qty. to Handle" on inventory pick line for "I2" to zero.
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick");
        UpdateQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", Item[2]."No.", 0);

        // [WHEN] Post the inventory pick.
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick", false);

        // [THEN] Item line "I1" is fully shipped.
        // [THEN] Item line "I2" is not shipped.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[1]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, Item[2]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", 0);

        // [THEN] Non-inventory line "NI1" is fully shipped.
        // [THEN] Non-inventory line "NI2" is fully shipped.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[1]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, NonInvtItem[2]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity);

        // [THEN] Item charge line "IC1" is fully shipped.
        // [THEN] Item charge line "IC2" is fully shipped.
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[1]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity);
        FindPurchaseLine(PurchaseLine, PurchaseHeader, ItemCharge[2]."No.");
        PurchaseLine.TestField("Return Qty. Shipped", PurchaseLine.Quantity);
    end;

    [Test]
    procedure GetReceiptLinesInPurchInvoiceWithAttachedNonInvtLine()
    var
        Item: Record Item;
        NonInvtItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineNonInvtItem: Record "Purchase Line";
    begin
        // [FEATURE] [Non-Inventory Item] [Purchase] [Order] [Invoice] [Get Receipt Lines]
        // [SCENARIO 477047] Get Receipt Lines in Purchase Invoice with attached non-inventory line does not produce duplicate lines.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in purchase setup to "Attached/Assigned".
        UpdateNonInvtPostingPolicyInPurchaseSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create item and non-inventory item.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem);

        // [GIVEN] Create purchase order with two lines: item and non-inventory item.
        // [GIVEN] Attach the non-inventory item to the item line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineItem, PurchaseHeader, PurchaseLineItem.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineNonInvtItem, PurchaseHeader, PurchaseLineNonInvtItem.Type::Item, NonInvtItem."No.", LibraryRandom.RandInt(10));
        PurchaseLineNonInvtItem."Attached to Line No." := PurchaseLineItem."Line No.";
        PurchaseLineNonInvtItem.Modify();

        // [GIVEN] Post the purchase order as Receive.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Create purchase invoice using "Get Receipt Lines".
        CreatePurchInvoiceFromReceipt(PurchaseHeaderInvoice, PurchaseHeader);

        // [THEN] Purchase invoice has two lines: item and non-inventory item.
        // [THEN] No duplicate lines.
        FindPurchaseLine(PurchaseLineNonInvtItem, PurchaseHeaderInvoice, NonInvtItem."No.");
        Assert.RecordCount(PurchaseLineNonInvtItem, 1);
        FindPurchaseLine(PurchaseLineNonInvtItem, PurchaseHeaderInvoice, Item."No.");
        Assert.RecordCount(PurchaseLineNonInvtItem, 1);
    end;

    [Test]
    procedure GetReturnShipmentLinesInPurchCrMemoWithAttachedNonInvtLine()
    var
        Item: Record Item;
        NonInvtItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderCrMemo: Record "Purchase Header";
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineNonInvtItem: Record "Purchase Line";
    begin
        // [FEATURE] [Non-Inventory Item] [Purchase] [Return Order] [Credit Memo] [Get Return Shipment Lines]
        // [SCENARIO 477047] Get Return Shipment Lines in Purchase Credit Memo with attached non-inventory line does not produce duplicate lines.
        Initialize();

        // [GIVEN] Set "Non-Invt. Item Whse. Policy" in purchase setup to "Attached/Assigned".
        UpdateNonInvtPostingPolicyInPurchaseSetup("Non-Invt. Item Whse. Policy"::"Attached/Assigned");

        // [GIVEN] Create item and non-inventory item.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvtItem);

        // [GIVEN] Create purchase return order with two lines: item and non-inventory item.
        // [GIVEN] Attach the non-inventory item to the item line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineItem, PurchaseHeader, PurchaseLineItem.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineNonInvtItem, PurchaseHeader, PurchaseLineNonInvtItem.Type::Item, NonInvtItem."No.", LibraryRandom.RandInt(10));
        PurchaseLineNonInvtItem."Attached to Line No." := PurchaseLineItem."Line No.";
        PurchaseLineNonInvtItem.Modify();

        // [GIVEN] Post the purchase return as Ship.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Create purchase credit memo using "Get Return Shipment Lines".
        CreatePurchCrMemoFromReturnShipment(PurchaseHeaderCrMemo, PurchaseHeader);

        // [THEN] Purchase credit memo has two lines: item and non-inventory item.
        // [THEN] No duplicate lines.
        FindPurchaseLine(PurchaseLineNonInvtItem, PurchaseHeaderCrMemo, NonInvtItem."No.");
        Assert.RecordCount(PurchaseLineNonInvtItem, 1);
        FindPurchaseLine(PurchaseLineNonInvtItem, PurchaseHeaderCrMemo, Item."No.");
        Assert.RecordCount(PurchaseLineNonInvtItem, 1);
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler,ItemTrackingPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPutAwayFromReleasedProductionOrderWithDifferentSerialNo()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        OldSerialNo, NewSerialNo : Code[50];
        SerialNo: array[10] of Code[50];
        i: Integer;
    begin
        // [SCENARIO 488048] Verify the serial number in the item ledger entry when changing the serial number in the warehouse activity line.
        Initialize();

        // [GIVEN] Create a warehouse location.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);

        // [GIVEN] Create an item with the Item Tracking Code.
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Create a bin and bin content.
        CreateBinAndBinContent(Bin, Item, Location.Code);

        // [GIVEN] Create and refresh the production order.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandIntInRange(5, 10), Location.Code);

        // [GIVEN] Update the bin code in the production order.
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Assign a serial number in production order.
        UpdateItemTrackingInProductionOrder(ProductionOrder);

        // [GIVEN] Create an inbound warehouse request from the production order.
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);

        // [GIVEN] Get the serial number from reservation entry.
        GetSerialNoFromReservationEntry(SerialNo, ProductionOrder);

        // [GIVEN] Create an inventory activity document.
        CreateInventoryActivity(
            WarehouseRequest."Source Document"::"Prod. Output",
            ProductionOrder."No.",
            Location.Code,
            true,
            false);

        // [GIVEN] Generate a new serial number.
        NewSerialNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Modify serial number at a random position.
        i := LibraryRandom.RandIntInRange(2, 4);
        OldSerialNo := SerialNo[i];
        SerialNo[i] := NewSerialNo;

        // [GIVEN] Update the new serial number in the warehouse activity line.
        UpdateSerialNoAndQuantityToHandleInInventoryPutAwayLine(
            WarehouseActivityHeader,
            ProductionOrder."No.",
            OldSerialNo,
            NewSerialNo);

        // [GIVEN] Post an inventory activity document.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [VERIFY] Verify the serial number in the item ledger entry when changing the serial number in the warehouse activity line.
        VerifySerialNoInItemLedgerEntry(SerialNo, ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler,ItemTrackingLinesPageHandlerTrackingOptionWithLot')]
    [Scope('OnPrem')]
    procedure VerifyPostingOfInventoryPutAwayAfterDeletingFirstLineWithLotShouldPostILEWithOtherLots()
    var
        Location: Record Location;
        Item: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseRequest: Record "Warehouse Request";
        ItemTrackingOption: Option AssignLotNoManual,AssignLotNos;
        LotNos: array[3] of Code[50];
        LotQty: array[3] of Decimal;
        TotalQty: Decimal;
        i: Integer;
    begin
        // [SCENARIO 491615] Inventory Put-Away with Lot Number - Verify Item Ledger Entry created with Lot Numbers that assigned on other lines on warehouse activity line when first line with lot is deleted
        Initialize();

        // [GIVEN] Create a warehouse location.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);

        // [GIVEN] Create an item with the Item Tracking Code.
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());  // Taking True for Lot.

        // [GIVEN] Create a bin and bin content.
        CreateBinAndBinContent(Bin, Item, Location.Code);

        // [GIVEN] Create Lot Nos and Quantity to assign on item tracking lines
        for i := 1 to ArrayLen(LotNos) do begin
            LotNos[i] := LibraryUtility.GenerateGUID();
            LotQty[i] := LibraryRandom.RandInt(10);
            TotalQty += LotQty[i];
        end;

        // [THEN] Create and refresh the production order with total quantity and update bin
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", TotalQty, Location.Code);
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Enqueue Lot Nos and quantity to Prepare item tracking lines
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNos);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNos));
        for i := 1 to ArrayLen(LotNos) do begin
            LibraryVariableStorage.Enqueue(LotNos[i]);
            LibraryVariableStorage.Enqueue(LotQty[i]);
        end;

        // [THEN] Find production order line and assign lot numbers "L1" - "X" pcs, "L2" - "Y" pcs, "L3" - "Z" pcs respectively
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.OpenItemTrackingLines();

        // [GIVEN] Create an inbound warehouse request from the production order.
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);

        // [GIVEN] Create an inventory activity document.
        CreateInventoryActivity(
            WarehouseRequest."Source Document"::"Prod. Output",
            ProductionOrder."No.",
            Location.Code,
            true,
            false);

        // [THEN] Delete the first line form inventory activity document and Update Quantity to Handle on other lines
        DeleteFirstInventoryPutAwayLine(ProductionOrder."No.", LotNos[1]);
        UpdateQuantityToHandleInInventoryPutAwayLine(WarehouseActivityHeader, ProductionOrder."No.");

        // [GIVEN] Post an inventory activity document.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [VERIFY] Verify: Item Ledger Entry created with Lot Numbers "L2", and "L3"
        VerifyLotNoInItemLedgerEntry(LotNos);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCapacityPolicySetToProhibitMoreThanMaxCapRespectsMaxWeightOnBin()
    var
        MunichLocation: Record Location;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReceiveBin: Record Bin;
        PutawayBin1: Record Bin;
        PutawayBin2: Record Bin;
    begin
        // [BUG 495153] Creting Put-away lines does not respect max. weight on the bin when 'Bin Capacity Policy' is set to 'Prohibit More Than Max. Cap.'
        // Bug https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_workitems/edit/495153
        Initialize();

        // [GIVEN] Create a warehouse location.
        CreateFullWMSLocationWithReceiveAndPutawaybins(MunichLocation, ReceiveBin, PutawayBin1, PutawayBin2);
        MunichLocation.Validate("Always Create Put-away Line", false);
        MunichLocation.Validate("Bin Capacity Policy", MunichLocation."Bin Capacity Policy"::"Prohibit More Than Max. Cap.");
        MunichLocation.Validate("Put-away Bin Policy", MunichLocation."Put-away Bin Policy"::"Put-away Template");
        MunichLocation.Modify(true);

        // [GIVEN] Create an item with weight set on UOM.
        LibraryInventory.CreateItem(Item);
        ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
        ItemUnitOfMeasure.Validate(Weight, 1);
        ItemUnitOfMeasure.Modify(true);

        // [GIVEN] Create Purchase order with item and quantity.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 15);
        PurchaseLine.Validate("Location Code", MunichLocation.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Warehouse receipt is created and posted to create put-away lines.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, MunichLocation.Code);

        // [THEN] Verify that the put-away lines are created with the correct bin.
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Put-away");
        WarehouseActivityHeader.SetRange("Location Code", MunichLocation.Code);
        WarehouseActivityHeader.FindFirst();

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");

        Assert.RecordCount(WarehouseActivityLine, 3); // 1 take and 2 place lines.

        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", ReceiveBin.Code);

        // Verify that the line is created with the correct bin.
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        Assert.RecordCount(WarehouseActivityLine, 2);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", PutawayBin2.Code);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField("Bin Code", PutawayBin1.Code);
    end;

    [Test]
    [HandlerFunctions('CalculateMultipleInventoryPageHandler,DimensionSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryOnPhysicalInventoryJournalForMultipleItemUsingDimension()
    var
        DimensionValue: array[3] of Record "Dimension Value";
        Item: array[2] of Record Item;
        Location: array[3] of Record Location;
        PurchaseHeader: Record "Purchase Header";
        PhysInventoryJournal: TestPage "Phys. Inventory Journal";
        Quantity: Decimal;
    begin
        // [SCENARIO 547458] When Item and Location both have Default Dimensions and Location has same dimensions but dimension values are different then
        // no error will come on Calculate Inventory
        Initialize();

        // [GIVEN] Crate first item with default dimension
        LibraryInventory.CreateItem(Item[1]);
        CreateDefaultDimensionItem(DimensionValue[1], Item[1]."No.");

        // [GIVEN] Create item
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Define quantity
        Quantity := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Create location with posting setups
        CreateLocationWithPostingSetup(Location);

        // [GIVEN] Define default dimension for 2 locations
        CreateDefaultDimensionLocation(DimensionValue[2], Location[2].Code);
        CreateDefaultDimensionLocation(DimensionValue[3], Location[3].Code);

        // [GIVEN] Create Purchase Order with 2 items and 3 locations 
        CreatePurchaseOrderWithMultipleItems(PurchaseHeader, Location, Item, Quantity);

        // [GIVEN] Post the Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Enqueue the bith item to calculate inventory on them
        LibraryVariableStorage.Enqueue(Item[1]."No.");
        LibraryVariableStorage.Enqueue(Item[2]."No.");

        // [WHEN] Open Physical Inventory Journal and run Calculate Inventory
        PhysInventoryJournal.OpenEdit();
        PhysInventoryJournal.CalculateInventory.Invoke();

        // [THEN] Verify the Item Journal line created with correct default dimensions
        VerifyItemJournalLine(Item[2]."No.", DimensionValue[2].Code, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure AllowCheckBinPolicyOnPutAwayWithMaxQtyViolationTest()
    begin
        CheckBinCapacityPolicyHandledAsDifferentCapacitySetups(LocationWhite."Bin Capacity Policy"::"Allow More Than Max. Capacity");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProhibitCheckBinPolicyOnPutAwayWithMaxQtyViolationTest()
    begin
        CheckBinCapacityPolicyHandledAsDifferentCapacitySetups(LocationWhite."Bin Capacity Policy"::"Prohibit More Than Max. Cap.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProhibitCheckBinPolicyWithNoMaxQtySetAndCubViolationTest()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Bins with Maximum Quantity. Create and Release Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);
        Quantity2 := Quantity + LibraryRandom.RandInt(50);
        LibraryInventory.CreateItem(Item);
        CreateBinAndUpdateBinContent(Bin, Item, LocationWhite.Code, Quantity, true);
        CreateBinAndUpdateBinContent(Bin2, Item, LocationWhite.Code, Quantity2, true);

        // [GIVEN] 'Bin Capacity Policy' is set
        LocationWhite.Validate("Bin Capacity Policy", LocationWhite."Bin Capacity Policy"::"Prohibit More Than Max. Cap.");
        LocationWhite.Modify(true);

        // [GIVEN] Max weight on the Bin is set
        Bin.Validate("Maximum Cubage", Quantity);
        Bin.Modify(true);

        // [GIVEN] Current user added as an warehouse employee
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, false);

        // [GIVEN] Item with weight set on the unit of measure
        ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
        ItemUnitOfMeasure.Validate(Cubage, 1);
        ItemUnitOfMeasure.Modify(true);

        // [WHEN] Create and Post Warehouse Receipt
        CreatePurchaseOrderAndPostWarehouseReceipt(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity + Quantity2, Item."Base Unit of Measure");
        FilterWarehouseActivityLinesWithBinCode(
            WarehouseActivityLine, WarehouseActivityHeader."Source Document"::"Purchase Order",
            PurchaseHeader."No.", '', WarehouseActivityLine."Activity Type"::"Put-away", Item."No.", Bin2.Code);

        // [THEN] Error is thrown for max. Qty. violation
        asserterror UpdateWarehouseActivityLineQty(WarehouseActivityLine, Bin.Code);
        Assert.ExpectedError(ExceedsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SetLotItemWithQtyToHandleTrackingPageHandler,ConfirmHandlerTrue')]
    procedure CreateMovementFromMovementWorksheetWithExpirationDateOfFEFOItem()
    var
        Bin: array[5] of Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Replenishmt: Codeunit Replenishment;
        Quantity: Decimal;
        LotNo: array[2] of Code[20];
        ExpirationDate: array[2] of Date;
    begin
        // [SCENARIO 557919] With a basic Warehouse Location, the Movement Worksheet is incorrectly suggesting a From Zone/Bin, and also which is not the earlier Expiration Date of the FEFO Item]
        Initialize();

        // [GIVEN] Create Location with Require Put Away, Require Pick, Bin Mandatory, Require Shipment and Require Receive and Pick According to FEFO as True.

        Quantity := LibraryRandom.RandDecInRange(50, 50, 2);
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify();

        // [GIVEN] Create Warehouse Employee for Location.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Bins with Bin Ranking. 
        CreateBinWithBinRanking(Bin[1], Location.Code, 450);
        CreateBinWithBinRanking(Bin[2], Location.Code, 400);
        CreateBinWithBinRanking(Bin[3], Location.Code, 370);

        // [GIVEN] Create Item Tracking with Lot and Expiration Date.
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(ItemTrackingCode, false, true);

        // [GIVEN] Create an Item and assign Item Tracking.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify();

        // [GIVEN] Create and post Item Journal Line with LOT and Expiration Date 
        LotNo[1] := LibraryRandom.RandText(10);
        LotNo[2] := LibraryRandom.RandText(10);
        ExpirationDate[1] := WorkDate() + 20;
        ExpirationDate[2] := WorkDate() + 10;

        PostItemPositiveAdjustmentWithLotTracking(Item, Location, Bin[2].code, LotNo[1], ExpirationDate[1], Quantity);
        PostItemPositiveAdjustmentWithLotTracking(Item, Location, Bin[3].code, LotNo[2], ExpirationDate[2], Quantity);

        // [GIVEN] Create and Update BinContent with Min, Max Quantity, Fixed,Default and Bin Ranking.
        FindAndUpdateBinContent(Bin[1], Item, Quantity, Quantity, true, false, 450);
        FindAndUpdateBinContent(Bin[2], Item, 0, 0, true, true, 0);

        // [GIVEN] Create Warehouse Worksheet for Movement.
        CreateWarehouseWorksheetNameForWarehouseLocation(WhseWorksheetName, Location.Code);

        // [GIVEN] Create Movement Worksheet Line
        Replenishmt.SetWhseWorksheet(
                  WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Location.Code, false);
        BinContent.Reset();
        BinContent.SetCurrentKey("Location Code", "Item No.", "Variant Code", "Warehouse Class Code", Fixed, "Bin Ranking");
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange(Fixed, true);
        if BinContent.FindSet() then
            repeat
                Replenishmt.ReplenishBin(BinContent, false);
            until BinContent.Next() = 0;

        Replenishmt.InsertWhseWkshLine();

        // [WHEN] Create Movement from Movement Worksheet Lines.
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsNotEmpty(WhseWorksheetLine);

        WhseWorksheetLine.FindFirst();
        Assert.AreEqual(WhseWorksheetLine."From Bin Code", '', FromBinBlankErr);
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // [THEN] Verify Warehouse Activity Lines gets sorted with Action Type and Bin Code.
        VerifyWarehouseActivityLineWithBin(Item."No.", Bin[3].Code, Bin[1].Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure RegisterPutAwayWithBreakBulkFilterShouldRegisterAllLines()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        UOM: Record "Unit of Measure";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        PutAwayPage: TestPage "Warehouse Put-away";
        ExpectedLinesCount: Integer;
    begin
        // [SCENARIO 592107] Verify all put away lines are registered, when register a warehouse put away with the break bulk filter set to yes
        Initialize();

        // [GIVEN] Create Warehouse Employee for location WHITE.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);

        // [GIVEN] Create an Item and assign Put-away Unit of Measure Code.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Put-away Unit of Measure Code", Item."Base Unit of Measure");
        Item.Modify(true);

        // [GIVEN] Create Unit of Measure and Item Unit of Measure with Qty. per Unit of Measure as 48.
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UOM.Code, 48);

        // [GIVEN] Create Purchase Order and Post Warehouse Receipt.
        CreatePurchaseOrderAndPostWarehouseReceipt(
            PurchaseHeader, LocationWhite.Code, Item."No.", LibraryRandom.RandDec(10, 2), UOM.Code);

        // [GIVEN] Find Warehouse Put-away
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Purchase Order");
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseActivityLine.FindSet();
        ExpectedLinesCount := WarehouseActivityLine.Count();

        // [GIVEN] Open Warehouse Put-away page
        PutAwayPage.OpenEdit();
        PutAwayPage.FILTER.SetFilter("No.", WarehouseActivityLine."No.");

        // [GIVEN] Set Break Bulk filter = Yes
        PutAwayPage."Breakbulk Filter".SetValue(true);

        // [WHEN] Register Warehouse Put-Away.
        PutAwayPage."&Register Put-away".Invoke();

        // [THEN] Verify Put-Away should be registered and all lines should be posted in Warehouse Entry table
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"P. Order");
        WarehouseEntry.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordCount(WarehouseEntry, ExpectedLinesCount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse - Receiving");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse - Receiving");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.SavePurchasesSetup();

        CreateLocationSetup();
        NoSeriesSetup();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);
        ItemJournalSetup(OutputItemJournalTemplate, OutputItemJournalBatch, OutputItemJournalTemplate.Type::Output);
        LibraryWarehouse.WarehouseJournalSetup(LocationWhite2.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.WarehouseJournalSetup(LocationWhite.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        ConsumptionJournalSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse - Receiving");
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
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

    local procedure ConsumptionJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type, ConsumptionItemJournalTemplate.Name);
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, false);

        CreateWhiteLocationWithTwoZones();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite2.Code, true);

        CreateFullWarehouseSetup(LocationWhite3);  // Location: White3.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite3.Code, false);

        CreateFullWarehouseSetup(LocationWhite4);  // Location: White4.

        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, true, true, false, false);  // Location Silver with Require Put Away, Require Pick and Bin Mandatory.
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value required.

        LibraryWarehouse.CreateLocationWMS(LocationSilver2, false, true, true, false, false);  // Location Silver with Require Put Away and Require Pick.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver2.Code, false);

        LibraryWarehouse.CreateLocationWMS(LocationOrange, false, true, true, false, false);  // Location Orange with Require Put Away and Require Pick.
        LibraryWarehouse.CreateLocationWMS(LocationWithRequirePick, false, false, true, false, false);  // Location with Require Pick.
        LibraryWarehouse.CreateLocationWMS(LocationWithRequirePick2, false, false, true, false, false);  // Location with Require Pick.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationRed);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateLocationWMS(LocationGreen, false, true, true, true, true);  // Location Green with Require Put Away, Require Pick, Require Receive and Require Shipment.
        LibraryWarehouse.CreateLocationWMS(LocationBrown, false, true, false, false, false);  // Location Brown with Require Put-Away.
        LibraryWarehouse.CreateLocationWMS(LocationRed2, false, false, false, false, true);  // Location Red with Require Shipment.

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed2.Code, false);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);  // Location: Location In Transit.
    end;

    local procedure CreateLocationSetupWithBins(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', LibraryRandom.RandInt(3), false); // Value required.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        if RequireReceive then begin
            LibraryWarehouse.FindBin(Bin, Location.Code, '', 1); // Use 1 for Bin Index.
            Location.Validate("Receipt Bin Code", Bin.Code);
            Location.Modify(true);
        end;
        if RequireShipment then begin
            LibraryWarehouse.FindBin(Bin, Location.Code, '', 1); // Use 1 for Bin Index.
            Location.Validate("Shipment Bin Code", Bin.Code);
            Location.Modify(true);
        end;
    end;

    local procedure AutoFillQtyToHandleOnWarehouseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
    end;

    local procedure CalculateAndPostConsumptionJournal(ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        ItemJournalLine.SetRange("Journal Template Name", ConsumptionItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ConsumptionItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CancelReservationOnSalesOrder(DocumentNo: Code[20])
    var
        ReservationMode: Option ReserveFromCurrentLine,CancelReservationCurrentLine;
    begin
        LibraryVariableStorage.Enqueue(ReservationMode::CancelReservationCurrentLine);  // Enqueue for ReservationPageHandler.
        LibraryVariableStorage.Enqueue(CancelAllReservationsConfirm);  // Enqueue for ConfirmHandler.
        ShowReservationOnSalesLine(DocumentNo);
    end;

    local procedure CreateWhiteLocationWithTwoZones()
    var
        Zone: Record Zone;
        Bin: Record Bin;
        PutAwayTemplateHeader: Record "Put-away Template Header";
    begin
        LibraryWarehouse.CreateLocationWMS(LocationWhite2, true, false, true, true, true);
        LocationWhite2.Validate("Directed Put-away and Pick", true);
        LocationWhite2.Modify(true);
        LibraryWarehouse.CreateZone(
          Zone,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Zone.FieldNo(Code), DATABASE::Zone), 1,
            LibraryUtility.GetFieldLength(DATABASE::Zone, Zone.FieldNo(Code))),
          LocationWhite2.Code, LibraryWarehouse.SelectBinType(false, false, false, false), '', '', 0, false);  // Value required for test.
        LibraryWarehouse.CreateNumberOfBins(
          LocationWhite2.Code, Zone.Code, LibraryWarehouse.SelectBinType(false, false, false, false), 1, false);  // Value required for the No. of Bin in the test.
        LibraryWarehouse.FindBin(Bin, LocationWhite2.Code, Zone.Code, 1);
        LocationWhite2.Validate("Adjustment Bin Code", Bin.Code);
        LibraryWarehouse.CreateZone(
          Zone,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Zone.FieldNo(Code), DATABASE::Zone), 1,
            LibraryUtility.GetFieldLength(DATABASE::Zone, Zone.FieldNo(Code))),
          LocationWhite2.Code, LibraryWarehouse.SelectBinType(true, false, false, false), '', '', 10, false);  // Value required for test.
        LibraryWarehouse.CreateNumberOfBins(
          LocationWhite2.Code, Zone.Code, LibraryWarehouse.SelectBinType(true, false, false, false), 1, false);  // Value required for the No. of Bin in the test.
        LibraryWarehouse.FindBin(Bin, LocationWhite2.Code, Zone.Code, 1);
        LocationWhite2.Validate("Receipt Bin Code", Bin.Code);
        CreatePutAwayTemplate(PutAwayTemplateHeader, true, false, true, false);  // Taking Fixed Bin.
        LocationWhite2.Validate("Put-away Template Code", PutAwayTemplateHeader.Code);
        LocationWhite2.Modify(true);
    end;

    local procedure CreateAndCertifyBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ItemVariant: Record "Item Variant"; UnitOfMeasureCode: Code[10]; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemVariant."Item No.", QuantityPer);
        ProductionBOMLine.Validate("Variant Code", ItemVariant.Code);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CarryOutActionMessageAfterCalculatePlanOnRequisitionLine(Item: Record Item)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::"Req.");
        RequisitionWkshName.FindFirst();
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate(), WorkDate());
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        LibraryManufacturing: Codeunit "Library - Manufacturing";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndPostInventoryPutAwayFromPurchaseOrderUsingMultipleBinAndLot(var Bin: Record Bin; var LotNo: Variant; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        Bin2: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        FindBin(Bin, LocationCode);
        LibraryWarehouse.CreateBin(Bin2, Bin."Location Code", LibraryUtility.GenerateGUID(), Bin."Zone Code", Bin."Bin Type Code");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithTracking(
          PurchaseLine, PurchaseHeader, ItemNo, Quantity, Bin."Location Code", ItemTrackingMode::"Assign Lot No.", Bin.Code);
        LibraryVariableStorage.Dequeue(LotNo);
        CreatePurchaseLineWithTracking(
          PurchaseLine, PurchaseHeader, ItemNo, Quantity, Bin2."Location Code", ItemTrackingMode::"Assign Lot No.", Bin2.Code);
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryVariableStorage.Enqueue(InvPutAwayMessage);  // Enqueue for MessageHandler.
        CreateInventoryActivity(
          WarehouseRequest."Source Document"::"Purchase Order", PurchaseHeader."No.", LocationSilver.Code, true, false);
        AutoFillQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityHeader.Type::"Invt. Put-away", true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal; LocationCode: Code[10]; UseTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        if UseTracking then
            ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; ItemTracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        if ItemTracking then
            PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPartialWarehouseReceipt(var PurchaseHeader: Record "Purchase Header"; Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, '', Item."No.", Quantity, Item."Base Unit of Measure", false);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        UpdateQuantityOnWarehouseReceiptLineFromPurchaseOrder(PurchaseHeader."No.", Item."No.", LocationCode, '', Quantity / 2);
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationCode);
        UpdateQuantityOnWarehouseReceiptLineFromPurchaseOrder(PurchaseHeader."No.", Item."No.", LocationCode, '', Quantity / 4);  // Value required for the test.
    end;

    local procedure CreateAndPostProductionJournal(ProductionOrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; EntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Output, ItemNo, 0);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProductionOrderNo);
        ItemJournalLine.Validate("Order Line No.", FindProductionOrderLine(ProductionOrderNo));

        FindProdOrderRoutingLine(ProdOrderRoutingLine, ItemJournalLine);
        ItemJournalLine.Validate("Operation No.", ProdOrderRoutingLine."Operation No.");

        ItemJournalLine.Validate("Output Quantity", Quantity);
        ItemJournalLine.Validate("Applies-to Entry", EntryNo);
        ItemJournalLine.Modify(true);
        ItemJournalLine.PostingItemJnlFromProduction(false);
    end;

    local procedure CreateAndPostOutputJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; ProductionOrderNo: Code[20]; VariantCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        UpdateNoSeriesOnItemJournalBatch(OutputItemJournalBatch, '');
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ItemNo, ProductionOrderNo);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Output Quantity", Quantity);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreatedAndPostWarehouseReceiptWithTracking(Location: Record Location; PurchaseHeaderNo: Code[20]; ItemNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        GetSourceDocumentOnWarehouseReceipt(WarehouseReceiptHeader, Location.Code, true, false, false, ItemNo, ItemNo);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeaderNo, Location.Code);
        WarehouseReceiptLine."Bin Code" := Location."Shipment Bin Code";
        WarehouseReceiptLine.Modify();
        WarehouseReceiptLine.OpenItemTrackingLines(); // Assign "Lot No." through ItemTrackingFromReceiptHandler
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationCode);
    end;

    local procedure CreateAndPostWarehouseReceiptFromTransferOrder(TransferHeader: Record "Transfer Header"; LocationCode: Code[10])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
        FindWarehouseReceiptLine(
          WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.", LocationCode);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(TransferOrderDeletedMessage, TransferHeader."No."));  // Enqueue for MessageHandler.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateAndRegisterPutAwayFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasure: Code[10]; ItemTracking: Boolean; ItemTrackingMode: Option; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Bin: Record Bin;
    begin
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity, UnitOfMeasure);
        if ItemTracking then begin
            FindWarehouseReceiptLine(
              WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.", LocationCode);
            LibraryVariableStorage.Enqueue(ItemTrackingMode);  // Enqueue for ItemTrackingPageHandler.
            WarehouseReceiptLine.OpenItemTrackingLines();  // Item Tracking Lines page is handled using ItemTrackingLinesHandlerWithSerialNo
        end;
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationCode);
        if BinCode <> '' then begin
            Bin.Get(LocationCode, BinCode);
            UpdateBinCodeOnPutAwayLine(
              WarehouseActivityLine, Bin, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        end;
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndReleaseSalesOrderWithMultipleLinesUsingShippingAdvice(var SalesHeader: Record "Sales Header"; ShippingAdvice: Enum "Sales Header Shipping Advice"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; LocationCode: Code[10]; MultipleLines: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipping Advice", ShippingAdvice);   // Handling the Confirm Dialog.
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, LocationCode, ItemNo, '', Quantity);
        if MultipleLines then
            CreateSalesLine(SalesHeader, SalesLine, LocationCode, ItemNo2, '', Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; UseTraking: Boolean)
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

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10]; ItemTracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
        if ItemTracking then
            PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithMultipleLines(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; LocationCode2: Code[10]; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10]; UnitOfMeasureCode2: Code[10]; VariantCode: Code[10]; VariantCode2: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithUOMLocationAndVariantCode(PurchaseHeader, ItemNo, Quantity, UnitOfMeasureCode, LocationCode, VariantCode);
        CreatePurchaseLineWithUOMLocationAndVariantCode(PurchaseHeader, ItemNo, Quantity, UnitOfMeasureCode2, LocationCode2, VariantCode2);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithTrackingOnMultipleLines(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; ItemNo2: Code[20]; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithTracking(
          PurchaseLine, PurchaseHeader, ItemNo, Quantity, LocationCode, ItemTrackingMode::"Assign Serial No.", '');
        CreatePurchaseLineWithTracking(PurchaseLine, PurchaseHeader, ItemNo2, Quantity, LocationCode, ItemTrackingMode::"Assign Lot No.", '');
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreatePurchaseDocumentWithVariousLines(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type";
                                                                                                                           Item: array[2] of Record Item; NonInvtItem: array[2] of Record Item;
                                                                                                                           ItemCharge: array[2] of Record "Item Charge"; LocationCode: Code[10])
    var
        PurchaseLineItem: array[2] of Record "Purchase Line";
        PurchaseLineNonInvtItem: array[2] of Record "Purchase Line";
        PurchaseLineItemCharge: array[2] of Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        i: Integer;
        j: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);

        for i := 1 to 2 do
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLineItem[i], PurchaseHeader, PurchaseLineItem[i].Type::Item, Item[i]."No.", LibraryRandom.RandInt(10));

        for i := 1 to 2 do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLineNonInvtItem[i], PurchaseHeader, PurchaseLineNonInvtItem[i].Type::Item, NonInvtItem[i]."No.", LibraryRandom.RandInt(10));
            PurchaseLineNonInvtItem[i]."Attached to Line No." := PurchaseLineItem[i]."Line No.";
            PurchaseLineNonInvtItem[i].Modify();
        end;

        for i := 1 to 2 do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLineItemCharge[i], PurchaseHeader, PurchaseLineItemCharge[i].Type::"Charge (Item)", ItemCharge[i]."No.", 2);
            PurchaseLineItemCharge[i].Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLineItemCharge[i].Modify(true);
            for j := 1 to 2 do begin
                LibraryPurchase.CreateItemChargeAssignment(
                  ItemChargeAssignmentPurch, PurchaseLineItemCharge[i], ItemCharge[i],
                  PurchaseLineItem[j]."Document Type", PurchaseLineItem[j]."Document No.", PurchaseLineItem[j]."Line No.",
                  PurchaseLineItem[j]."No.", 1, PurchaseLineItemCharge[i]."Unit Cost");
                ItemChargeAssignmentPurch.Insert(true);
            end;
        end;
    end;

    local procedure CreateAndReleaseSalesDocWithMultipleLines(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; LocationCode: Code[10]; LocationCode2: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; VariantCode: Code[10]; VariantCode2: Code[10]; Quantity: Decimal; Tracking: Boolean)
    var
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        CreateSalesLine(SalesHeader, SalesLine, LocationCode, ItemNo, VariantCode, Quantity);
        CreateSalesLine(SalesHeader, SalesLine2, LocationCode2, ItemNo2, VariantCode2, Quantity);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for ItemTrackingPageHandler.
            SalesLine.OpenItemTrackingLines();  // Assign Item Tracking on First line.
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for ItemTrackingPageHandler.
            SalesLine2.OpenItemTrackingLines(); // Assign Item Tracking on second line.
        end;
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithReservation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ReservationMode: Option ReserveFromCurrentLine,CancelReservationCurrentLine;
    begin
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, LocationCode, ItemNo, Quantity, false);
        LibraryVariableStorage.Enqueue(ReservationMode::ReserveFromCurrentLine);  // Enqueue for ReservationPageHandler.
        ShowReservationOnSalesLine(SalesHeader."No.");
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal; UseTracking: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        if UseTracking then
            TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleaseWarehouseInternalPutAway(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; Bin: Record Bin; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; Quantity2: Decimal)
    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseIntPutAwayRelease: Codeunit "Whse. Int. Put-away Release";
    begin
        LibraryWarehouse.CreateWhseInternalPutawayHdr(WhseInternalPutAwayHeader, Bin."Location Code");
        WhseInternalPutAwayHeader.Validate("From Zone Code", Bin."Zone Code");
        WhseInternalPutAwayHeader.Validate("From Bin Code", Bin.Code);
        WhseInternalPutAwayHeader.Modify(true);
        LibraryWarehouse.CreateWhseInternalPutawayLine(WhseInternalPutAwayHeader, WhseInternalPutAwayLine, ItemNo, Quantity);
        LibraryWarehouse.CreateWhseInternalPutawayLine(WhseInternalPutAwayHeader, WhseInternalPutAwayLine, ItemNo2, Quantity2);
        WhseIntPutAwayRelease.Release(WhseInternalPutAwayHeader);
    end;

    local procedure CreateAndReleaseWarehouseInternalPick(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; var WhseInternalPickLine: Record "Whse. Internal Pick Line"; Bin: Record Bin; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; Quantity2: Decimal)
    var
        WhseInternalPickRelease: Codeunit "Whse. Internal Pick Release";
    begin
        LibraryWarehouse.CreateWhseInternalPickHeader(WhseInternalPickHeader, Bin."Location Code");
        WhseInternalPickHeader.Validate("To Zone Code", Bin."Zone Code");
        WhseInternalPickHeader.Validate("To Bin Code", Bin.Code);
        WhseInternalPickHeader.Modify(true);
        LibraryWarehouse.CreateWhseInternalPickLine(WhseInternalPickHeader, WhseInternalPickLine, ItemNo, Quantity);
        LibraryWarehouse.CreateWhseInternalPickLine(WhseInternalPickHeader, WhseInternalPickLine, ItemNo2, Quantity2);
        WhseInternalPickRelease.Release(WhseInternalPickHeader);
    end;

    local procedure CreateAndShipTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal; UseTracking: Boolean)
    begin
        CreateAndReleaseTransferOrder(TransferHeader, FromLocation, ToLocation, ItemNo, Quantity, UseTracking);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);  // Post as Ship.
    end;

    local procedure CreateAndUpdateBinContent(Bin: Record Bin; Item: Record Item; MaxQuantity: Decimal; "Fixed": Boolean)
    var
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBinContent(
          BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate("Bin Type Code", Bin."Bin Type Code");
        BinContent.Validate("Max. Qty.", MaxQuantity);
        BinContent.Validate(Fixed, Fixed);
        BinContent.Modify(true);
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

    local procedure CreateBinAndUpdateBinContent(var Bin: Record Bin; Item: Record Item; LocationCode: Code[10]; Quantity: Decimal; "Fixed": Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, false, true, true);  // Find PICK Bin.
        LibraryWarehouse.CreateBin(Bin, Zone."Location Code", LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");
        CreateAndUpdateBinContent(Bin, Item, Quantity, Fixed);
    end;

    local procedure CreateBinForReceiveZoneWithBinRanking(var Bin: Record Bin; LocationCode: Code[10]; BinRanking: Integer)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, true, false, false); // Find RECEIVE Zone.
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");
        Bin.Validate("Bin Ranking", BinRanking);
        Bin.Modify(true);
    end;

    local procedure CreateBinForAdjustmentZoneWithBinRanking(var Bin: Record Bin; LocationCode: Code[10]; BinRanking: Integer)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, false, false, false); // Find Adjustment Zone.
        CreateBinForZoneWithBinRanking(Bin, Zone, LocationCode, BinRanking);
    end;

    local procedure CreateBinForPickZoneWithBinRanking(var Bin: Record Bin; LocationCode: Code[10]; BinRanking: Integer)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, false, true, true); // Find PICK Zone.
        CreateBinForZoneWithBinRanking(Bin, Zone, LocationCode, BinRanking);
    end;

    local procedure CreateBinForZoneWithBinRanking(var Bin: Record Bin; Zone: Record Zone; LocationCode: Code[10]; BinRanking: Integer)
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");
        Bin.Validate("Bin Ranking", BinRanking);
        Bin.Modify(true);
    end;

    local procedure CreateBinWithMaximumCubage(var Bin: Record Bin; Zone: Record Zone; MaximumCubage: Decimal)
    begin
        LibraryWarehouse.CreateBin(Bin, Zone."Location Code", LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");
        Bin.Validate("Maximum Cubage", MaximumCubage);
        Bin.Modify(true);
    end;

    local procedure CreateBinContentWithMaxQuantity(Bin: Record Bin; Item: Record Item; MaxQuantity: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBinContent(
          BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate("Max. Qty.", MaxQuantity);
        BinContent.Modify(true);
    end;

    local procedure CreateBinsForPickZoneWithBinRanking(var Zone: Record Zone; LocationCode: Code[10]; NoOfBins: Integer)
    var
        Bin: Record Bin;
    begin
        FindZone(Zone, LocationCode, false, true, true);  // Find Pick Zone.
        LibraryWarehouse.CreateNumberOfBins(LocationCode, Zone.Code, Zone."Bin Type Code", NoOfBins, false);
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.ModifyAll("Bin Ranking", LibraryRandom.RandInt(100), true);
    end;

    local procedure CreateDefaultDimensionItem(var DimensionValue: Record "Dimension Value"; ItemNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateItemWithOrderReorderingPolicy(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        UpdateReorderingPolicyAsOrderInItem(Item);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreateItemWithProductionBOM(var ParentItem: Record Item; var ComponentItem: Record Item; var ItemVariant: Record "Item Variant"; QuantityPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(ComponentItem);
        LibraryInventory.CreateItemVariant(ItemVariant, ComponentItem."No.");
        CreateAndCertifyBOM(ProductionBOMHeader, ItemVariant, ParentItem."Base Unit of Measure", QuantityPer);
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateItemwithReplenishment(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; Length: Integer)
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, 1 + LibraryRandom.RandInt(5));
        ItemUnitOfMeasure.Validate(Length, Length);
        ItemUnitOfMeasure.Validate(Width, Length);  // Taking Width as Length.
        ItemUnitOfMeasure.Validate(Height, Length);  // Taking Height as Length.
        ItemUnitOfMeasure.Modify(true);
    end;

    local procedure CreateAssembledItem(var ParentItem: Record Item; var ComponentItem: Record Item; QtyPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryAssembly.CreateItem(ComponentItem, ComponentItem."Costing Method", ComponentItem."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateItem(ParentItem, ParentItem."Costing Method", ParentItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", ParentItem."No.", '', BOMComponent."Resource Usage Type", QtyPer, true);
    end;

    local procedure CreateItemWithDifferentPutAwayUnitOfMeasure(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", 0);  // Taking 0 for Blank Length.
        UpdatePutAwayUnitOfMeasureOnItem(Item, ItemUnitOfMeasure.Code);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; Serial: Boolean; Lot: Boolean; SerialNos: Code[20]; LotNos: Code[20])
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, ItemTrackingCode.Code);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Serial: Boolean; Lot: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemTrackingLine(var ItemTrackingLines: TestPage "Item Tracking Lines"; Quantity: Decimal)
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
    end;

    local procedure CreateInventoryActivity(SourceDocument: Enum "Warehouse Request Source Document"; SourceNo: Code[20]; LocationCode: Code[10]; PutAway: Boolean; Pick: Boolean)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Source Document", SourceDocument);
        WarehouseRequest.SetRange("Source No.", SourceNo);
        WarehouseRequest.SetRange("Location Code", LocationCode);
        WarehouseRequest.FindFirst();
        LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, PutAway, Pick, false);
    end;

    local procedure CreateInventoryPickFromSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, LocationCode, ItemNo, Quantity, false);
        LibraryVariableStorage.Enqueue(InvPickMessage);  // Handled in Message Handler.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", LocationCode, false, true);
    end;

    local procedure CreateInventoryPutAwayFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        Bin: Record Bin;
        WarehouseRequest: Record "Warehouse Request";
    begin
        FindBin(Bin, LocationCode);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Bin."Location Code", Bin.Code, Item."No.", Quantity, Item."Base Unit of Measure", false);
        LibraryVariableStorage.Enqueue(InvPutAwayMessage);  // Enqueue for MessageHandler.
        CreateInventoryActivity(
          WarehouseRequest."Source Document"::"Purchase Order", PurchaseHeader."No.", LocationSilver.Code, true, false);  // Use True for Put Away.
    end;

    local procedure CreateMovementWorksheetLine(WhseWorksheetName: Record "Whse. Worksheet Name"; ItemNo: Code[20]; Bin: Record Bin; Bin2: Record Bin; Quantity: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        LibraryWarehouse.CreateWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Bin."Location Code",
          WhseWorksheetLine."Whse. Document Type"::"Whse. Mov.-Worksheet");
        WhseWorksheetLine.Validate("Item No.", ItemNo);
        WhseWorksheetLine.Validate("From Zone Code", Bin."Zone Code");
        WhseWorksheetLine.Validate("From Bin Code", Bin.Code);
        WhseWorksheetLine.Validate("To Zone Code", Bin2."Zone Code");
        WhseWorksheetLine.Validate("To Bin Code", Bin2.Code);
        WhseWorksheetLine.Validate(Quantity, Quantity);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure CreateMovementWorksheetLineWithNoUoM(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ItemNo: Code[20])
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        CreateWarehouseWorksheetNameForMovement(WhseWorksheetName);
        LibraryWarehouse.CreateWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, WhseWorksheetName."Location Code",
          "Warehouse Worksheet Document Type"::" ");
        WhseWorksheetLine."Item No." := ItemNo;
        WhseWorksheetLine.Modify(true);
    end;

    local procedure CreatePick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePickFromProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SortActivity: Option;
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ItemNo, Quantity, LocationCode);
        LibraryVariableStorage.Enqueue(SortActivity);  // Enqueue for WhseShipmentCreatePickHandler.
        LibraryVariableStorage.Enqueue(PickActivityCreatedMessage);  // Enqueue for MessageHandler.
        ProductionOrder.CreatePick(UserId, 0, false, false, false);  // SetBreakBulkFilter,DoNotFillQtyToHandle and PrintDocument False.
    end;

    local procedure CreatePickFromSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, LocationCode, ItemNo, Quantity, true);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreatePutAwayFromPutAwayWorksheet(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; QuantityToHandle: Decimal; SortActivity: Enum "Whse. Activity Sorting Method"; BreakbulkFilter: Boolean)
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::"Put-away");
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhsePutAwayRequest.SetRange("Completely Put Away", false);
        WhsePutAwayRequest.SetRange("Location Code", LocationCode);
        LibraryWarehouse.GetInboundSourceDocuments(WhsePutAwayRequest, WhseWorksheetName, LocationCode);
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplate.Name);
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetFilter("Item No.", ItemNo + '|' + ItemNo2);
        WhseWorksheetLine.FindFirst();
        if QuantityToHandle <> 0 then begin
            WhseWorksheetLine.Validate("Qty. to Handle", QuantityToHandle);
            WhseWorksheetLine.Modify(true);
        end;
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, SortActivity, false, false, BreakbulkFilter);
    end;

    local procedure CreatePutAwayFromWhseInternalPutAway(Bin: Record Bin; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
    begin
        CreateWhseInternalPutawayHeader(WhseInternalPutAwayHeader, Bin."Location Code", Bin."Zone Code", Bin.Code);
        LibraryWarehouse.CreateWhseInternalPutawayLine(WhseInternalPutAwayHeader, WhseInternalPutAwayLine, ItemNo, Quantity);
        WhseInternalPutAwayLine.Validate("Variant Code", VariantCode);
        WhseInternalPutAwayLine.Modify(true);
        LibraryWarehouse.ReleaseWarehouseInternalPutAway(WhseInternalPutAwayHeader);
        WhseInternalPutAwayLine.CreatePutAwayDoc(WhseInternalPutAwayLine);
    end;

    local procedure CreatePutAwayTemplate(var PutAwayTemplateHeader: Record "Put-away Template Header"; "Fixed": Boolean; FindFloatingBin: Boolean; FindBinLessthanMinQty: Boolean; FindEmptyBin: Boolean)
    var
        PutAwayTemplateLine: Record "Put-away Template Line";
    begin
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(
          PutAwayTemplateHeader, PutAwayTemplateLine, Fixed, FindFloatingBin, true, true, FindBinLessthanMinQty, FindEmptyBin);
    end;

    local procedure CreatePurchaseLineWithTracking(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemTrackingMode: Option; BinCode: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode);  // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseLineWithUOMLocationAndVariantCode(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10]; LocationCode: Code[10]; VariantCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderAndPostWarehouseReceipt(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, '', ItemNo, Quantity, UnitOfMeasureCode, false);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, LocationCode);
    end;

    local procedure CreatePurchInvoiceFromReceipt(var PurchaseHeaderInvoice: Record "Purchase Header"; PurchaseHeader: Record "Purchase Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        FindPurchaseReceiptLine(PurchRcptLine, PurchaseHeader."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure CreatePurchCrMemoFromReturnShipment(var PurchaseHeaderCrMemo: Record "Purchase Header"; PurchaseHeader: Record "Purchase Header")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseHeader."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderCrMemo, PurchaseHeaderCrMemo."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        PurchGetReturnShipments.SetPurchHeader(PurchaseHeaderCrMemo);
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
    begin
        WorkCenter.FindFirst();
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, WorkCenter."No.", Format(LibraryRandom.RandInt(5)), LibraryRandom.RandInt(5),
          LibraryRandom.RandInt(5));
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateStockkeepingUnit(LocationCode: Code[10]; ItemNo: Code[20]; PutAwayTemplateCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');  // Variant Code as Blank.
        StockkeepingUnit.Validate("Put-away Template Code", PutAwayTemplateCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateWhseInternalPutawayHeader(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; LocationCode: Code[10]; FromZonecode: Code[10]; FromBinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseInternalPutawayHdr(WhseInternalPutAwayHeader, LocationCode);
        WhseInternalPutAwayHeader.Validate("From Zone Code", FromZonecode);
        WhseInternalPutAwayHeader.Validate("From Bin Code", FromBinCode);
        WhseInternalPutAwayHeader.Modify(true);
    end;

    local procedure CreateWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::"Invt. Pick";
        WarehouseActivityLine."No." := LibraryUtility.GenerateGUID();
        WarehouseActivityLine."Location Code" := LocationCode;
        WarehouseActivityLine."Action Type" := WarehouseActivityLine."Action Type"::Take;
        WarehouseActivityLine."Unit of Measure Code" := UnitOfMeasure.Code;
        WarehouseActivityLine."Qty. Outstanding (Base)" := LibraryRandom.RandDec(10, 2);
        WarehouseActivityLine.Insert();
    end;

    local procedure CreateWarehouseReceiptHeaderWithLocation(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        WarehouseReceiptHeader.Validate("Location Code", LocationCode);
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreateWarehouseShipmentHeaderWithLocation(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", LocationCode);
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure CreateWarehouseShipmentFromSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateWarehouseShipmentFromTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateAndReleaseTransferOrder(TransferHeader, FromLocationCode, ToLocationCode, ItemNo, Quantity, false);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
    end;

    local procedure CreateWarehouseReceiptFromSalesReturnOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateAndReleaseSalesDocument(
          SalesHeader, SalesHeader."Document Type"::"Return Order", LocationCode, ItemNo, Quantity, false);
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
    end;

    local procedure CreateWarehouseReceiptFromTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateAndPostItemJournalLine(ItemNo, ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, FromLocationCode, false);
        CreateAndShipTransferOrder(TransferHeader, FromLocationCode, ToLocationCode, ItemNo, Quantity, false);
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
    end;

    local procedure CreateWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, '', ItemNo, Quantity, UnitOfMeasureCode, false);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateWarehouseWorksheetNameForMovement(var WhseWorksheetName: Record "Whse. Worksheet Name")
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Movement);
        WhseWorksheetTemplate.FindFirst();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationWhite.Code);
    end;

    local procedure DeleteWarehouseActivityLine(SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.Delete(true);  // Delete the Put-Away.
    end;

    local procedure DeletePutAway(SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo, Type);
        WarehouseActivityHeader.Get(Type, WarehouseActivityLine."No.");
        WarehouseActivityHeader.Delete(true);  // Delete the Put Away.
    end;

    local procedure FindAdjustmentBin(var Bin: Record Bin; Location: Record Location)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, Location.Code, false, false, false);
        Bin.SetFilter(Code, '<>%1', Location."Adjustment Bin Code");
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindFirst();
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10])
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.FindFirst();
    end;

    local procedure FindBinAndCreateBinContent(var Bin: Record Bin; Item: Record Item; LocationCode: Code[10])
    begin
        FindBinWithBinTypeCode(Bin, LocationCode, false, true, true, true);  // Find Last Bin in PICK Zone.
        CreateAndUpdateBinContent(Bin, Item, 0, true);
    end;

    local procedure FindBinWithBinTypeCode(var Bin: Record Bin; LocationCode: Code[10]; Receive: Boolean; PutAway: Boolean; Pick: Boolean; FindLastBin: Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, Receive, PutAway, Pick);
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, LibraryRandom.RandInt(Bin.Count));  // Find Random Bin.
        if FindLastBin then
            Bin.FindLast();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.FindLast();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; No: Code[20])
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("No.", No);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
    end;

    local procedure FindPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.FindFirst();
    end;

    local procedure FindReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; ReturnOrderNo: Code[20])
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        ReturnShipmentHeader.SetRange("Return Order No.", ReturnOrderNo);
        ReturnShipmentHeader.FindFirst();
        ReturnShipmentLine.SetRange("Document No.", ReturnShipmentHeader."No.");
        ReturnShipmentLine.FindFirst();
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ItemJournalLine: Record "Item Journal Line")
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ItemJournalLine."Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ItemJournalLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ItemJournalLine."Routing No.");
        ProdOrderRoutingLine.FindLast();
    end;

    local procedure FindProductionOrderLine(ProductionOrderNo: Code[20]): Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindFirst();
        exit(ProdOrderLine."Line No.");
    end;

    local procedure FindRegisteredWarehouseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type")
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.FindSet();
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; Receive: Boolean; PutAway: Boolean; Pick: Boolean)
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(Receive, false, PutAway, Pick));
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        FilterWarehouseActivityLines(WarehouseActivityLine, SourceDocument, SourceNo, '', ActivityType);
    end;

    local procedure FindWarehouseActivityLineForMultipleSourceDocuments(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; SourceNo2: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");  // Setting the current key for validation.
        FilterWarehouseActivityLines(WarehouseActivityLine, SourceDocument, SourceNo, SourceNo2, ActivityType);
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.SetRange("Location Code", LocationCode);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptHeaderFromPurchaseOrder(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptHeader(
          WarehouseReceiptHeader, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo, LocationCode);
    end;

    local procedure FindWarehouseReceiptHeaderFromSalesReturnOrder(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptHeader(
          WarehouseReceiptHeader, WarehouseReceiptLine."Source Document"::"Sales Return Order", SourceNo, LocationCode);
    end;

    local procedure FindWarehouseReceiptHeaderFromTransferOrder(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptHeader(
          WarehouseReceiptHeader, WarehouseReceiptLine."Source Document"::"Inbound Transfer", SourceNo, LocationCode);
    end;

    local procedure FindWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo, LocationCode);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
    end;

    local procedure FindWarehouseShipmentHeaderFromPurchaseReturnOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentHeader(
          WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Purchase Return Order", SourceNo, LocationCode);
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Location Code", LocationCode);
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindPostedWhseReceiptLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        PostedWhseReceiptLine.SetRange("Source Document", SourceDocument);
        PostedWhseReceiptLine.SetRange("Source No.", SourceNo);
        PostedWhseReceiptLine.SetRange("Item No.", ItemNo);
        PostedWhseReceiptLine.SetRange("Variant Code", VariantCode);
        PostedWhseReceiptLine.FindFirst();
    end;

    local procedure FilterBinContent(var BinContent: Record "Bin Content"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20])
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
    end;

    local procedure FilterPostedInvtPickLine(var PostedInvtPickLine: Record "Posted Invt. Pick Line"; SourceNo: Code[20]; ItemNo: Code[20])
    begin
        PostedInvtPickLine.SetRange("Source Document", PostedInvtPickLine."Source Document"::"Sales Order");
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.SetRange("Item No.", ItemNo);
        PostedInvtPickLine.FindSet();
    end;

    local procedure FilterWarehouseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; SourceNo2: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetFilter("Source No.", '%1|%2', SourceNo, SourceNo2);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure GetExpectedReceiptDateFromPurchaseLine(var ExpectedReceiptDate: Date; DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        ExpectedReceiptDate := PurchaseLine."Expected Receipt Date";
    end;

    local procedure GetSourceDocumentOnWarehouseReceipt(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10]; PurchaseOrders: Boolean; InboundTransfers: Boolean; SalesReturnOrders: Boolean; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        CreateWarehouseReceiptHeaderWithLocation(WarehouseReceiptHeader, LocationCode);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Inbound);
        WarehouseSourceFilter.Validate("Purchase Orders", PurchaseOrders);
        WarehouseSourceFilter.Validate("Inbound Transfers", InboundTransfers);
        WarehouseSourceFilter.Validate("Sales Return Orders", SalesReturnOrders);
        WarehouseSourceFilter.Validate("Item No. Filter", ItemNo + '|' + ItemNo2);
        WarehouseSourceFilter.Modify(true);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, LocationCode);
    end;

    local procedure GetSourceDocumentOnWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10]; SalesOrders: Boolean; OutboundTransfers: Boolean; PurchaseReturnOrders: Boolean; ItemNo: Code[100])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        CreateWarehouseShipmentHeaderWithLocation(WarehouseShipmentHeader, LocationCode);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Validate("Sales Orders", SalesOrders);
        WarehouseSourceFilter.Validate("Outbound Transfers", OutboundTransfers);
        WarehouseSourceFilter.Validate("Purchase Return Orders", PurchaseReturnOrders);
        WarehouseSourceFilter.Validate("Item No. Filter", ItemNo);
        WarehouseSourceFilter.Modify(true);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, LocationCode);
    end;

    local procedure GetWarehouseDocumentOnPickWorksheet(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
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

    local procedure PostProductionJournal(var ProductionOrder: Record "Production Order"; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue for Production Journal Handler.
        LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationMessage);  // Enqueue for Confirm Handler.
        LibraryVariableStorage.Enqueue(JournalLinesPostedMessage);  // Enqueue for Message Handler.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, FindProductionOrderLine(ProductionOrder."No."));
    end;

    local procedure RegisterWarehouseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure PostInventoryActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; Invoice: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, Invoice);
    end;

    local procedure PostInventoryPutAwayWithPartialQuantity(SourceNo: Code[20]; BinCode: Code[20]; LotNo: Code[50]; QuantityToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityHeader.Type::"Invt. Put-away");
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Validate("Qty. to Handle", QuantityToHandle);
        WarehouseActivityLine.Modify(true);
        PostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo, WarehouseActivityHeader.Type::"Invt. Put-away", false);
    end;

    local procedure PostWarehouseReceiptFromPurchaseOrder(SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo, LocationCode);
    end;

    local procedure PostWarehouseReceiptFromSalesReturnOrder(SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Sales Return Order", SourceNo, LocationCode);
    end;

    local procedure PostWarehouseReceiptFromTransferOrder(SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Inbound Transfer", SourceNo, LocationCode);
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo, LocationCode);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostItemJournalThroughCalculateWhseAdjmt(Item: Record Item; Qty: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
    begin
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, true); // Find Bin for PICK
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          LocationWhite.Code, '', Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, true);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndReleaseSalesOrderWithAssembly(ParentItem: Record Item; ComponentItem: Record Item; Qty: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, SalesLine, LocationWhite.Code, ParentItem."No.", '', Qty);
        SalesLine.Validate("Qty. to Assemble to Order", Qty);
        SalesLine.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine2, LocationWhite.Code, ComponentItem."No.", '', LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        exit(SalesHeader."No.");
    end;

    local procedure RegisterPutAwayAfterUpdatingBinCodeOnPutAwayLine(SourceNo: Code[20])
    var
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindBinWithBinTypeCode(Bin, LocationWhite.Code, false, true, true, false);  // Find PICK Bin.
        UpdateBinCodeOnPutAwayLine(WarehouseActivityLine, Bin, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure RegisterPutAwayFromPurchaseOrder(ItemNo: Code[20]; LocationCode: Code[10])
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
        PostWarehouseReceiptFromPurchaseOrder(PurchaseHeader."No.", LocationCode);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityHeader.Type::"Put-away");
    end;

    local procedure ReleaseWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure ShowReservationOnSalesLine(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        SalesLine.ShowReservation();
    end;

    local procedure UpdatePutAwayUnitOfMeasureOnItem(var Item: Record Item; UnitOfMeasureCode: Code[10])
    begin
        Item.Validate("Put-away Unit of Measure Code", UnitOfMeasureCode);
        Item.Modify(true);
    end;

    local procedure UpdateQuantityOnWarehouseReceiptLineFromPurchaseOrder(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; QtyToReceive: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        UpdateQuantityOnWarehouseReceiptLine(
          WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo, ItemNo, LocationCode, VariantCode, QtyToReceive);
    end;

    local procedure UpdateQuantityOnWarehouseReceiptLineFromSalesReturnOrder(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; QtyToReceive: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        UpdateQuantityOnWarehouseReceiptLine(
          WarehouseReceiptLine."Source Document"::"Sales Return Order", SourceNo, ItemNo, LocationCode, VariantCode, QtyToReceive);
    end;

    local procedure UpdateQuantityOnWarehouseReceiptLineFromTransferOrder(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; QtyToReceive: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        UpdateQuantityOnWarehouseReceiptLine(
          WarehouseReceiptLine."Source Document"::"Inbound Transfer", SourceNo, ItemNo, LocationCode, VariantCode, QtyToReceive);
    end;

    local procedure UpdateQuantityOnWarehouseReceiptLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; QtyToReceive: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.SetRange("Variant Code", VariantCode);
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo, LocationCode);
        WarehouseReceiptLine.Validate("Qty. to Receive", QtyToReceive);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure UpdateQuantityOnWarehouseShipmentLineFromPurchaseReturnOrder(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; QtyToShip: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        UpdateQuantityOnWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Purchase Return Order", SourceNo, ItemNo, LocationCode, VariantCode, QtyToShip);
    end;

    local procedure UpdateQuantityOnWarehouseShipmentLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; QtyToShip: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.SetRange("Variant Code", VariantCode);
        WarehouseShipmentLine.SetRange("Location Code", LocationCode);
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentLine.Validate("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure UpdateQtyToHandleOnWarehouseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ItemNo: Code[20]; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateLotNoAndQuantityToHandleOnInventoryPutAwayLine(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Prod. Output");
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure UpdateUnitOfMeasureOnProductionOrderLine(ProductionOrder: Record "Production Order"; UnitOfMeasureCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateBinCodeOnWarehouseReceiptLine(SourceNo: Code[20]; BinCode: Code[20]; BinCode2: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo, LocationCode);
        WarehouseReceiptLine.Validate("Bin Code", BinCode);
        WarehouseReceiptLine.Modify(true);
        if BinCode2 <> '' then begin
            WarehouseReceiptLine.Next();
            WarehouseReceiptLine.Validate("Bin Code", BinCode2);
            WarehouseReceiptLine.Modify(true);
        end;
    end;

    local procedure UpdateBinCodeOnPutAwayLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; Bin: Record Bin; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Zone Code", Bin."Zone Code");
            WarehouseActivityLine.Validate("Bin Code", Bin.Code);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateBinCapacityPolicyOnLocation(var Location: Record Location; var OldBinCapacityPolicy: Option; NewBinCapacityPolicy: Option)
    begin
        OldBinCapacityPolicy := Location."Bin Capacity Policy";
        Location.Validate("Bin Capacity Policy", NewBinCapacityPolicy);
        Location.Modify(true);
    end;

    local procedure UpdateDueDateOnWarehouseReceiptLine(SourceNo: Code[20]; LocationCode: Code[10]; DueDate: Date)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo, LocationCode);
        WarehouseReceiptLine.Validate("Due Date", DueDate);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure UpdateExpirationCalculationOnItem(var Item: Record Item)
    var
        ExpirationCalculation: DateFormula;
    begin
        Evaluate(ExpirationCalculation, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        EnsureTrackingCodeUsesExpirationDate(Item."Item Tracking Code");
        Item.Validate("Expiration Calculation", ExpirationCalculation);
        Item.Modify(true);
    end;

    local procedure UpdateExpirationDateOnInventoryPutAway(SourceNo: Code[20]; ItemNo: Code[20]; ExpirationDate: Date)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.ModifyAll("Expiration Date", ExpirationDate, true);
    end;

    local procedure UpdateExpirationDateOnReservationEntry(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Expiration Date", ExpirationDate, true);  // Value required for test.
    end;

    local procedure EnsureTrackingCodeUsesExpirationDate(ItemTrackingCode: Code[10])
    var
        ItemTrackingCodeRec: Record "Item Tracking Code";
    begin
        ItemTrackingCodeRec.Get(ItemTrackingCode);
        if not ItemTrackingCodeRec."Use Expiration Dates" then begin
            ItemTrackingCodeRec.Validate("Use Expiration Dates", true);
            ItemTrackingCodeRec.Modify();
        end;
    end;

    local procedure UpdateCubageAndWeightOnItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; Cubage: Decimal)
    begin
        ItemUnitOfMeasure.Validate(Cubage, Cubage);
        ItemUnitOfMeasure.Validate(Weight, Cubage);  // Taking Weight as Cubage.
        ItemUnitOfMeasure.Modify(true);
    end;

    local procedure UpdateInventoryUsingWhseJournal(Bin: Record Bin; Item: Record Item; Quantity: Decimal; VariantCode: Code[10])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        WarehouseJournalLine.Validate("Variant Code", VariantCode);
        WarehouseJournalLine.Modify(true);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure UpdateItemNoOnPurchaseLineAfterReopenPurchaseOrder(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        LibraryInventory.CreateItem(Item);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("No.", Item."No.");
    end;

    local procedure UpdateItemNoOnSalesLineAfterReopenSalesOrder(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        LibraryInventory.CreateItem(Item);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("No.", Item."No.");
    end;

    local procedure UpdateItemNoOnTransferLineAfterReopenTransferOrder(TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        LibraryWarehouse.ReopenTransferOrder(TransferHeader);
        LibraryInventory.CreateItem(Item);
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        TransferLine.Validate("Item No.", Item."No.");
    end;

    local procedure UpdateLotNoOnInventoryPickLine(SourceNo: Code[20]; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdatePutAwayTemplateCodeOnLocation(var Location: Record Location; PutAwayTemplateCode: Code[10]) OldPutAwayTemplateCode: Code[10]
    begin
        OldPutAwayTemplateCode := Location."Put-away Template Code";
        Location.Validate("Put-away Template Code", PutAwayTemplateCode);
        Location.Modify(true);
    end;

    local procedure UpdateMaximumCubageAndWeightOnBins(var Bin: Record Bin; Zone: Record Zone; MaximumCubage: Decimal)
    begin
        Bin.SetRange("Location Code", Zone."Location Code");
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindSet();
        repeat
            Bin.Validate("Maximum Cubage", MaximumCubage);
            Bin.Validate("Maximum Weight", MaximumCubage);  // Taking Maximum Weight as Maximum Cubage.
            Bin.Modify(true);
        until Bin.Next() = 0;
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdatePurchaseUnitOfMeasureOnItem(var Item: Record Item; ItemUnitOfMeasureCode: Code[10])
    begin
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasureCode);
        Item.Modify(true);
    end;

    local procedure UpdatePutAwayTemplateCodeOnItem(ItemNo: Code[20]; PutAwayTemplateCode: Code[10])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Put-away Template Code", PutAwayTemplateCode);
        Item.Modify(true);
    end;

    local procedure UpdatePartialQuantityOnInventoryPickLine(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; LotNo: Code[50]; QuantityToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Validate("Qty. to Handle", QuantityToHandle);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure UpdateReorderingPolicyAsOrderInItem(var Item: Record Item)
    begin
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);
    end;

    local procedure UpdateUsePutAwayWorksheetOnLocation(var Location: Record Location; var OldUsePutAwayWorksheet: Boolean; NewUsePutAwayWorksheet: Boolean)
    begin
        OldUsePutAwayWorksheet := Location."Use Put-away Worksheet";
        Location.Validate("Use Put-away Worksheet", NewUsePutAwayWorksheet);
        Location.Modify(true);
    end;

    local procedure UpdateNonInvtPostingPolicyInPurchaseSetup(NonInvtItemWhsePolicy: Enum "Non-Invt. Item Whse. Policy")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Auto Post Non-Invt. via Whse.", NonInvtItemWhsePolicy);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure VerifyBinContent(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal; QuantityBase: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        FilterBinContent(BinContent, LocationCode, BinCode, ItemNo);
        BinContent.FindFirst();
        BinContent.CalcFields(Quantity);
        BinContent.TestField(Quantity, Quantity);
        BinContent.CalcFields("Quantity (Base)");
        BinContent.TestField("Quantity (Base)", QuantityBase);
    end;

    local procedure VerifyBreakBulkFilterOnPutAway(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeader.TestField("Breakbulk Filter", true);
    end;

    local procedure VerifyItemJournalLine(ItemNo: Code[20]; ShortcutDimension1Code: Code[20]; QtyCalculated: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        ItemJournalLine.TestField("Qty. (Calculated)", QtyCalculated);
    end;

    local procedure VerifyNoOfLinesOfItemLedgerEntry(ItemNo: Code[20]; LotNo: Code[10]; ItemLedgerEntryCount: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetFilter("Lot No.", LotNo);
        Assert.AreEqual(ItemLedgerEntry.Count, ItemLedgerEntryCount, ItemLedgerEntryErr)
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; Quantity: Decimal; RemainingQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Remaining Quantity", RemainingQuantity);
    end;

    local procedure VerifyNoOfLinesOnPutAway(WarehousePutAwayNo: Code[20]; WarehouseActivityHeaderLinesCount: Integer)
    var
        WarehousePutAway: TestPage "Warehouse Put-away";
        WarehousePutAwayLinesCount: Integer;
    begin
        WarehousePutAway.OpenEdit();
        WarehousePutAway.FILTER.SetFilter("No.", WarehousePutAwayNo);
        WarehousePutAwayLinesCount := 1;
        repeat
            WarehousePutAwayLinesCount += 1;
        until WarehousePutAway.WhseActivityLines.Next();
        Assert.IsTrue(WarehouseActivityHeaderLinesCount > WarehousePutAwayLinesCount, NoOfLinesMustBeGreater);
    end;

    local procedure VerifyPickWorksheetLine(WhseWorksheetName: Record "Whse. Worksheet Name"; ItemNo: Code[20]; Quantity: Decimal; AvailableQtyToPick: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", WhseWorksheetName."Location Code");
        WhseWorksheetLine.SetRange("Item No.", ItemNo);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.TestField(Quantity, Quantity);
        Assert.AreEqual(AvailableQtyToPick, WhseWorksheetLine.AvailableQtyToPick(), QuantityMustBeSame);
    end;

    local procedure VerifyPostedInventoryPutLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[20]; LotNo: Code[50])
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
    begin
        PostedInvtPutAwayLine.SetRange("Source Document", SourceDocument);
        PostedInvtPutAwayLine.SetRange("Source No.", SourceNo);
        PostedInvtPutAwayLine.FindFirst();
        PostedInvtPutAwayLine.TestField("Location Code", LocationCode);
        PostedInvtPutAwayLine.TestField("Item No.", ItemNo);
        PostedInvtPutAwayLine.TestField(Quantity, Quantity);
        PostedInvtPutAwayLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        PostedInvtPutAwayLine.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyPostedInventoryPickLine(SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[50]; ExpirationDate: Date; NextLine: Boolean)
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        FilterPostedInvtPickLine(PostedInvtPickLine, SourceNo, ItemNo);
        if NextLine then
            PostedInvtPickLine.Next();
        PostedInvtPickLine.TestField("Location Code", LocationCode);
        PostedInvtPickLine.TestField(Quantity, Quantity);
        PostedInvtPickLine.TestField("Lot No.", LotNo);
        PostedInvtPickLine.TestField("Expiration Date", ExpirationDate);
    end;

    local procedure VerifyPostedInventoryPickLineForSerialNo(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; ExpirationDate: Date; Quantity: Decimal)
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        TrackingQuantity: Decimal;
    begin
        FilterPostedInvtPickLine(PostedInvtPickLine, SourceNo, ItemNo);
        repeat
            PostedInvtPickLine.TestField("Location Code", LocationCode);
            PostedInvtPickLine.TestField("Expiration Date", ExpirationDate);
            PostedInvtPickLine.TestField("Serial No.");
            TrackingQuantity += PostedInvtPickLine.Quantity;
        until PostedInvtPickLine.Next() = 0;
        Assert.AreEqual(TrackingQuantity, Quantity, QuantityMustBeSame);
    end;

    local procedure VerifyPostedWarehouseReceiptLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        FindPostedWhseReceiptLine(PostedWhseReceiptLine, SourceDocument, SourceNo, ItemNo, VariantCode);
        PostedWhseReceiptLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedWarehouseShipmentLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        PostedWhseShipmentLine.SetRange("Source Document", SourceDocument);
        PostedWhseShipmentLine.SetRange("Source No.", SourceNo);
        PostedWhseShipmentLine.SetRange("Item No.", ItemNo);
        PostedWhseShipmentLine.SetRange("Variant Code", VariantCode);
        PostedWhseShipmentLine.FindFirst();
        PostedWhseShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPutAwayLinesWithMultipleBins(var Bin: Record Bin; Item: Record Item; ItemUnitOfMeasure: Record "Item Unit of Measure"; Location: Record Location; SourceNo: Code[20]; Quantity: Decimal; Quantity2: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        VerifyWarehouseActivityLine(
          WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo, WarehouseActivityLine."Activity Type"::"Put-away",
          WarehouseActivityLine."Action Type"::Take,
          Item."No.", Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", Location.Code, Item."Base Unit of Measure",
          Location."Receipt Bin Code", '', '');  // Value required for the test.

        repeat
            VerifyWarehouseActivityLine(
              WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo, WarehouseActivityLine."Activity Type"::"Put-away",
              WarehouseActivityLine."Action Type"::Place,
              Item."No.", Quantity2, Location.Code, ItemUnitOfMeasure.Code, Bin.Code, '', '');  // Value required for the test.
            Bin.Next(-1);
            Quantity -= 1;
        until Quantity = 0;
    end;

    local procedure VerifyWarehouseActivityWithExpirationDate(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ExpirationDate: Date)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        repeat
            WarehouseActivityLine.TestField("Expiration Date", ExpirationDate);
            WarehouseActivityLine.TestField("Serial No.");
            WarehouseActivityLine.TestField("Lot No.");
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyReservedQuantityOnPurchaseLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseLine.CalcFields("Reserved Qty. (Base)");
        PurchaseLine.TestField("Reserved Qty. (Base)", Quantity);
    end;

    local procedure VerifyRegisteredPutAwayLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[20]; LotNo: Code[10]; VariantCode: Code[10]; BinCode: Code[20])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine, SourceDocument, SourceNo, RegisteredWhseActivityLine."Activity Type"::"Put-away", ActionType);
        RegisteredWhseActivityLine.SetRange("Lot No.", LotNo);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.FindFirst();
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
        RegisteredWhseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        RegisteredWhseActivityLine.TestField("Variant Code", VariantCode);
        RegisteredWhseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyLotAndSerialOnRegisteredWhseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; LotNo: Code[50]; ExpirationDate: Date)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine, SourceDocument, SourceNo,
          ActivityType, ActionType);
        repeat
            RegisteredWhseActivityLine.TestField("Lot No.", LotNo);
            RegisteredWhseActivityLine.TestField("Serial No.");
            RegisteredWhseActivityLine.TestField(Quantity, 1);  // Value required for the Quantity.
            RegisteredWhseActivityLine.TestField("Expiration Date", ExpirationDate);
        until RegisteredWhseActivityLine.Next() = 0;
    end;

    local procedure VerifyDueDateAndBinCodeOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; DueDate: Date; NextLine: Boolean)
    begin
        if NextLine then
            WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
        WarehouseActivityLine.TestField("Due Date", DueDate);
    end;

    local procedure VerifyActionTypeBinCodeAndBreakbulkOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; BinCode: Code[20]; ActionType: Enum "Warehouse Action Type"; BreakbulkNo: Integer; Quantity: Decimal; NextLine: Boolean)
    begin
        if NextLine then
            WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
        WarehouseActivityLine.TestField("Action Type", ActionType);
        WarehouseActivityLine.TestField("Breakbulk No.", BreakbulkNo);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UnitOfMeasureCode: Code[10]; BinCode: Code[20]; VariantCode: Code[10]; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Bin Code", BinCode);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Variant Code", VariantCode);
        WarehouseActivityLine.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyWarehouseActivityLineWithActionType(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; Quantity: Decimal; NextLine: Boolean)
    begin
        if NextLine then
            WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField("Action Type", ActionType);
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseActivityLinesForMultipleItemsWithTakeActionType(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    begin
        VerifyWarehouseActivityLineWithActionType(WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, ItemNo, Quantity, false);
        VerifyWarehouseActivityLineWithActionType(WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, ItemNo2, Quantity, true);
    end;

    local procedure VerifyWarehouseActivityLinesForMultipleItemsWithPlaceActionType(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    begin
        VerifyWarehouseActivityLineWithActionType(WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, ItemNo, Quantity, true);
        VerifyWarehouseActivityLineWithActionType(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, ItemNo2, Quantity, true);
    end;

    local procedure VerifyWarehouseEntry(Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", Bin."Location Code");
        WarehouseEntry.SetRange("Zone Code", Bin."Zone Code");
        WarehouseEntry.FindFirst();
        WarehouseEntry.Validate("Bin Code", Bin.Code);
        WarehouseEntry.Validate(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseReceiptLine(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Quantity: Decimal; QtyToReceive: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.SetRange("Variant Code", VariantCode);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo, LocationCode);
        WarehouseReceiptLine.TestField(Quantity, Quantity);
        WarehouseReceiptLine.TestField("Qty. to Receive", QtyToReceive);
    end;

    local procedure VerifyWarehouseShipmentLine(ItemVariant: Record "Item Variant"; SourceNo: Code[20]; Quantity: Decimal; QtyToShip: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Item No.", ItemVariant."Item No.");
        WarehouseShipmentLine.SetRange("Variant Code", ItemVariant.Code);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SourceNo);
        WarehouseShipmentLine.TestField(Quantity, Quantity);
        WarehouseShipmentLine.TestField("Qty. to Ship", QtyToShip);
    end;

    local procedure VerifyBinCodeForWarehouseShipmentLine(SourceNo: Code[20]; BinCode: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SourceNo);
        Assert.AreEqual(BinCode, WarehouseShipmentLine."Bin Code", ShipmentBinCodeErr);
    end;

    local procedure VerifyBinCodeForWarehouseReceiptLine(SourceNo: Code[20]; BinCode: Code[20]; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo, LocationCode);
        Assert.AreEqual(BinCode, WarehouseReceiptLine."Bin Code", ReceiptBinCodeErr);
    end;

    local procedure GetSerialNoFromReservationEntry(
        var SerialNo: array[10] of Code[50];
        ProductionOrder: Record "Production Order")
    var
        ReservationEntry: Record "Reservation Entry";
        i: Integer;
    begin
        ReservationEntry.SetRange("Source ID", ProductionOrder."No.");
        if ReservationEntry.FindSet() then
            repeat
                i += 1;
                SerialNo[i] := ReservationEntry."Serial No.";
            until ReservationEntry.Next() = 0;
    end;

    local procedure UpdateSerialNoAndQuantityToHandleInInventoryPutAwayLine(
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SourceNo: Code[20];
        OldSerialNo: Code[50];
        NewSerialNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Prod. Output");
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        WarehouseActivityLine.SetRange("Serial No.", OldSerialNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Serial No.", NewSerialNo);
        WarehouseActivityLine.Modify(true);

        WarehouseActivityLine.SetRange("Serial No.");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure UpdateItemTrackingInProductionOrder(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
    begin
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Serial No.");
        LibraryVariableStorage.Enqueue(false);
        ProdOrderLine.OpenItemTrackingLines();
    end;

    local procedure FindProductionOrderLine(
        var ProdOrderLine: Record "Prod. Order Line";
        Status: Enum "Production Order Status";
        ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure CreateBinAndBinContent(var Bin: Record Bin; Item: Record Item; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure VerifySerialNoInItemLedgerEntry(SerialNo: array[10] of Code[50]; ProductionOrder: Record "Production Order")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        i: Integer;
    begin
        for i := 1 to ProductionOrder.Quantity do begin
            ItemLedgerEntry.SetRange("Serial No.", SerialNo[i]);
            Assert.RecordIsNotEmpty(ItemLedgerEntry);
        end;
    end;

    local procedure DeleteFirstInventoryPutAwayLine(SourceNo: Code[20]; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Prod. Output");
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Delete();
    end;

    local procedure UpdateQuantityToHandleInInventoryPutAwayLine(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
            WarehouseActivityLine,
            WarehouseActivityLine."Source Document"::"Prod. Output",
            SourceNo,
            WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure VerifyLotNoInItemLedgerEntry(LotNos: array[3] of Code[50])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        i: Integer;
    begin
        for i := 2 to ArrayLen(LotNos) do begin
            ItemLedgerEntry.SetRange("Lot No.", LotNos[i]);
            Assert.RecordIsNotEmpty(ItemLedgerEntry);
        end;
    end;

    procedure CreateFullWMSLocationWithReceiveAndPutawaybins(var Location: Record Location; var ReceiveBin: Record Bin; var PutawayBin1: Record Bin; var PutawayBin2: Record Bin)
    var
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        Zone: Record Zone;
    begin
        Clear(Location);
        Location.Init();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        // Skip validate trigger for bin mandatory to improve performance.
        Location."Bin Mandatory" := true;
        Location.Validate("Directed Put-away and Pick", true);
        if Location."Require Pick" then
            if Location."Require Shipment" then begin
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
                Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
            end else begin
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
                Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Inventory Movement";
                Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Inventory Pick";
            end
        else begin
            Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)";
            Location."Asm. Consump. Whse. Handling" := Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)";
            Location."Job Consump. Whse. Handling" := Location."Job Consump. Whse. Handling"::"Warehouse Pick (optional)";
        end;

        if Location."Require Put-away" and not Location."Require Receive" then
            Location."Prod. Output Whse. Handling" := Location."Prod. Output Whse. Handling"::"Inventory Put-away";
        Location.Modify(true);

        // Create Zones and bins
        // Pick zone
        LibraryWarehouse.CreateZone(Zone, 'PICK', Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), '', '', 100, false);
        LibraryWarehouse.CreateBin(PutawayBin1, Location.Code, 'Bin1', Zone.Code, LibraryWarehouse.SelectBinType(false, false, true, true));
        PutawayBin1.Validate("Bin Ranking", 100);
        PutawayBin1.Validate("Maximum Weight", 20);
        PutawayBin1.Modify(true);
        LibraryWarehouse.CreateBin(PutawayBin2, Location.Code, 'Bin2', Zone.Code, LibraryWarehouse.SelectBinType(false, false, true, true));
        PutawayBin2.Validate("Bin Ranking", 200);
        PutawayBin2.Validate("Maximum Weight", 10);
        PutawayBin2.Modify(true);

        // Receive Zone
        LibraryWarehouse.CreateZone(Zone, 'RECEIVE', Location.Code, LibraryWarehouse.SelectBinType(true, false, false, false), '', '', 10, false);
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, 'Bin3', Zone.Code, LibraryWarehouse.SelectBinType(true, false, false, false));
        Location.Validate("Receipt Bin Code", ReceiveBin.Code);

        // Bin policies fast tab
        // Created the STD put-away template - same as the one in the demo data
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, true, true, true, false);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, true, true, false, false);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, false, true, true, true, false, false);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, false, true, true, false, false, false);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, false, true, false, false, false, true);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, false, true, false, false, false, false);
        Location.Validate("Put-away Template Code", PutAwayTemplateHeader.Code);

        Location.Validate("Allow Breakbulk", true);

        Location.Modify(true);
    end;

    local procedure CreateDefaultDimensionLocation(var DimensionValue: Record "Dimension Value"; LocationCode: Code[10])
    var
        DefaultDimension: Record "Default Dimension";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        CreateDefaultDimension(DefaultDimension, DATABASE::Location, LocationCode, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    procedure CreateDefaultDimension(var DefaultDimension: Record "Default Dimension"; TableID: Integer; No: Code[20]; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    begin
        DefaultDimension.Init();
        DefaultDimension.Validate("Table ID", TableID);
        DefaultDimension.Validate("No.", No);
        DefaultDimension.Validate("Dimension Code", DimensionCode);
        DefaultDimension.Validate("Dimension Value Code", DimensionValueCode);
        DefaultDimension.Insert(true);
    end;

    local procedure CreatePurchaseOrderWithMultipleItems(var PurchaseHeader: Record "Purchase Header"; Location: array[3] of Record Location; Item: array[2] of Record Item; Quantity: Decimal)
    var
        PurchaseLine: array[3] of Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::Item, Item[1]."No.", Quantity);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::Item, Item[2]."No.", Quantity);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[3], PurchaseHeader, PurchaseLine[3].Type::Item, Item[2]."No.", Quantity);

        PurchaseLine[1].Validate("Location Code", Location[1].Code);
        PurchaseLine[1].Validate("Unit of Measure Code", Item[2]."Base Unit of Measure");
        PurchaseLine[1].Modify(true);

        PurchaseLine[2].Validate("Location Code", Location[2].Code);
        PurchaseLine[2].Validate("Unit of Measure Code", Item[2]."Base Unit of Measure");
        PurchaseLine[2].Modify(true);

        PurchaseLine[3].Validate("Location Code", Location[3].Code);
        PurchaseLine[3].Validate("Unit of Measure Code", Item[2]."Base Unit of Measure");
        PurchaseLine[3].Modify(true);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateLocationWithPostingSetup(var Location: Array[3] of Record Location)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(Location) do
            LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[i]);
    end;

    procedure CheckBinCapacityPolicyHandledAsDifferentCapacitySetups(BinCapacityPolicy: Option "Never Check Capacity","Allow More Than Max. Capacity","Prohibit More Than Max. Cap.")
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Bins with Maximum Quantity. Create and Release Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);
        Quantity2 := Quantity + LibraryRandom.RandInt(50);

        LibraryInventory.CreateItem(Item);
        CreateBinAndUpdateBinContent(Bin, Item, LocationWhite.Code, Quantity, true);
        CreateBinAndUpdateBinContent(Bin2, Item, LocationWhite.Code, Quantity2, true);

        // [GIVEN] 'Bin Capacity Policy' is set
        LocationWhite.Validate("Always Create Put-away Line", true);
        LocationWhite.Validate("Bin Capacity Policy", BinCapacityPolicy);
        LocationWhite.Modify(true);

        // [WHEN] Create and Post Warehouse Receipt
        CreatePurchaseOrderAndPostWarehouseReceipt(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity + Quantity2, Item."Base Unit of Measure");
        FilterWarehouseActivityLinesWithBinCode(
            WarehouseActivityLine, WarehouseActivityHeader."Source Document"::"Purchase Order",
            PurchaseHeader."No.", '', WarehouseActivityLine."Activity Type"::"Put-away", Item."No.", Bin2.Code);
        WarehouseActivityHeader.Get(WarehouseActivityLine."activity Type", WarehouseActivityLine."No.");

        // [THEN] Error is thrown for max. Qty. violation
        LibraryVariableStorage.Enqueue(true);
        if (BinCapacityPolicy = BinCapacityPolicy::"Prohibit More Than Max. Cap.") then begin
            asserterror UpdateWarehouseActivityLineQty(WarehouseActivityLine, Bin.Code);
            Assert.ExpectedError(ExceedsErr);
        end else
            UpdateWarehouseActivityLineQty(WarehouseActivityLine, Bin.Code);

        // [THEN] Expected confirmations are shown
        if BinCapacityPolicy = BinCapacityPolicy::"Allow More Than Max. Capacity" then
            Assert.ExpectedConfirm(ExceedsErr, LibraryVariableStorage.DequeueText());
    end;

    local procedure FilterWarehouseActivityLinesWithBinCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; SourceNo2: Code[20]; ActivityType: Enum "Warehouse Activity Type"; Itemno: code[20]; BinCode: Code[20])
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetFilter("Source No.", '%1|%2', SourceNo, SourceNo2);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Bin Code", BinCode);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindSet();
    end;

    local procedure UpdateWarehouseActivityLineQty(var WarehouseActivityLine: Record "Warehouse Activity Line"; BinCode: Code[20])
    var
        WarehousePutAwayPage: TestPage "Warehouse Put-away";
    begin
        WarehousePutAwayPage.OpenEdit();
        WarehousePutAwayPage.Filter.SetFilter("No.", WarehouseActivityLine."No.");
        WarehousePutAwayPage.WhseActivityLines.Filter.SetFilter("Line No.", Format(WarehouseActivityLine."Line No."));
        WarehousePutAwayPage.WhseActivityLines."Bin Code".SetValue(BinCode);
        WarehousePutAwayPage.Close();
    end;

    local procedure VerifyWarehouseActivityLineWithBin(ItemNo: Code[20]; TakeBin: Code[20]; PlaceBin: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Bin Code", TakeBin);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        Assert.RecordIsNotEmpty(WarehouseActivityLine);

        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Bin Code", PlaceBin);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        Assert.RecordIsNotEmpty(WarehouseActivityLine);
    end;

    local procedure CreateBinWithBinRanking(var Bin: Record Bin; LocationCode: Code[10]; BinRanking: Integer)
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), '', '');
        Bin.Validate("Bin Ranking", BinRanking);
        Bin.Modify(true);
    end;

    local procedure FindAndUpdateBinContent(Bin: Record Bin; Item: Record Item; MinQuantity: Decimal; MaxQuantity: Decimal; "Fixed": Boolean; Default: Boolean; BinRanking: Integer)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", Bin."Location Code");
        BinContent.SetRange("Bin Code", Bin.Code);
        BinContent.SetRange("Item No.", Item."No.");
        if not BinContent.FindFirst() then
            LibraryWarehouse.CreateBinContent(
              BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate("Bin Type Code", Bin."Bin Type Code");
        BinContent.Validate("Min. Qty.", MinQuantity);
        BinContent.Validate("Max. Qty.", MaxQuantity);
        BinContent.Validate(Fixed, Fixed);
        BinContent.Validate(Default, Default);
        if BinRanking <> 0 then
            BinContent.Validate("Bin Ranking", BinRanking);
        BinContent.Modify(true);
    end;

    local procedure CreateWarehouseWorksheetNameForWarehouseLocation(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Movement);
        WhseWorksheetTemplate.FindFirst();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    local procedure PostItemPositiveAdjustmentWithLotTracking(Item: Record Item; Location: Record Location; BinCode: Code[20]; LotNo: Code[20]; ExpirationDate: Date; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, BinCode, Qty);

        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(ExpirationDate);
        ItemJournalLine.OpenItemTrackingLines(false);

        LibraryInventory.PostItemJournalLine(
          ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateInventoryPageHandler(var CalculateInventory: TestRequestPage "Calculate Inventory")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        CalculateInventory.ByDimensions.AssistEdit();
        CalculateInventory.Item.SetFilter("No.", DequeueVariable);
        CalculateInventory.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateMultipleInventoryPageHandler(var CalculateInventory: TestRequestPage "Calculate Inventory")
    var
        Item1: Text;
        Item2: Text;
        FilterText: Text;
    begin
        Item1 := LibraryVariableStorage.DequeueText();
        Item2 := LibraryVariableStorage.DequeueText();
        FilterText := Item1 + '|' + Item2;
        CalculateInventory.ByDimensions.AssistEdit();
        CalculateInventory.Item.SetFilter("No.", FilterText);
        CalculateInventory.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectionPageHandler(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        DimensionSelectionMultiple.First();
        repeat
            DimensionSelectionMultiple.Selected.SetValue(true);
        until not DimensionSelectionMultiple.Next();
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingFromReceiptHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        ItemTrackingMode: Option "Assign Lot No.","Assign Lot And Serial","Assign Serial No.","Select Entries","Assign Multiple Lot No";
        TrackingQuantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::"Assign Lot No.":
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);  // Lot No. value required in the test.
                end;
            ItemTrackingMode::"Assign Lot And Serial":
                begin
                    LibraryVariableStorage.Enqueue(true);
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);  // Lot No. value required in the test.
                end;
            ItemTrackingMode::"Assign Serial No.":
                begin
                    LibraryVariableStorage.Enqueue(false);
                    ItemTrackingLines."Assign Serial No.".Invoke();
                end;
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::"Assign Multiple Lot No":
                begin
                    TrackingQuantity := ItemTrackingLines.Quantity3.AsDecimal();
                    CreateItemTrackingLine(ItemTrackingLines, TrackingQuantity / 2);
                    ItemTrackingLines.Next();
                    CreateItemTrackingLine(ItemTrackingLines, TrackingQuantity / 2);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    var
        DequeueVariable: Variant;
        CreateNewLotNo: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        CreateNewLotNo := DequeueVariable;
        EnterQuantityToCreate.CreateNewLotNo.SetValue(CreateNewLotNo);
        EnterQuantityToCreate.OK().Invoke();
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

    [ModalPageHandler]
    procedure SetLotItemWithQtyToHandleTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines."Expiration Date".SetValue(LibraryVariableStorage.DequeueDate());
        ItemTrackingLines.OK().Invoke();
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
        Assert.IsTrue(StrPos(ConfirmMessage, LocalMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PutAwaySelectionPageHandler(var PutAwaySelection: TestPage "Put-away Selection")
    begin
        PutAwaySelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    var
        DequeueVariable: Variant;
        Quantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        Quantity := DequeueVariable;
        ProductionJournal."Output Quantity".SetValue(Quantity);
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    var
        DequeueVariable: Variant;
        ReservationMode: Option ReserveFromCurrentLine,CancelReservationCurrentLine;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ReservationMode := DequeueVariable;
        Reservation.Last();
        case ReservationMode of
            ReservationMode::ReserveFromCurrentLine:
                Reservation."Reserve from Current Line".Invoke();
            ReservationMode::CancelReservationCurrentLine:
                Reservation.CancelReservationCurrentLine.Invoke();
        end;
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandlerTrackingOptionWithLot(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ItemTrackingOption: Option AssignLotNoManual,AssignLotNos;
        NoOfLines: Integer;
        i: Integer;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingOption::AssignLotNoManual:
                begin
                    ItemTrackingLines.New();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingOption::AssignLotNos:
                begin
                    NoOfLines := LibraryVariableStorage.DequeueInteger();
                    for i := 1 to NoOfLines do begin
                        ItemTrackingLines.New();
                        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    end;
                end;
        end;

        ItemTrackingLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    var
        SortActivity: Variant;
    begin
        LibraryVariableStorage.Dequeue(SortActivity);
        WhseSourceCreateDocument.SortingMethodForActivityLines.SetValue(SortActivity);
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseShipmentCreatePickHandler(var WhseShipmentCreatePick: TestRequestPage "Whse.-Shipment - Create Pick")
    var
        SortActivity: Variant;
    begin
        LibraryVariableStorage.Dequeue(SortActivity);
        WhseShipmentCreatePick.SortingMethodForActivityLines.SetValue(SortActivity);
        WhseShipmentCreatePick.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentPageHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Over-Receipt Mgt.", 'OnIsOverReceiptAllowed', '', false, false)]
    local procedure OnIsOverReceiptAllowedHandler(var OverReceiptAllowed: Boolean)
    begin
        OverReceiptAllowed := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateWhsePutAwayPickHandler(var CreateWhsePutAwayPick: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateWhsePutAwayPick.CreateInventorytPutAway.SetValue(true);
        CreateWhsePutAwayPick.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerEnqueueQuestion(Question: Text; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.Enqueue(Question);
    end;

}

