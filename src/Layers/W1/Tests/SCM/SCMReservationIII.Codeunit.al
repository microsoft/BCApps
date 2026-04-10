codeunit 137270 "SCM Reservation III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Reservation] [SCM]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ItemTrackingLinesControl: Option CallingFromPO,CallingFromTO;
        isInitialized: Boolean;
        AvailabilityError: Label 'There is nothing available to reserve.';
        BinCodeError: Label 'Bin Code must have a value in Warehouse Activity Line';
        BinContentError: Label 'The field Bin Code of table Warehouse Activity Line contains a value';
        LocationCodeError: Label 'You are not allowed to use location code %1.';
        OrderTrackingMessage: Label 'There are no order tracking entries for this line.';
        PickActivityMessage: Label 'Pick activity no. %1 has been created.';
        PlaceBinCodeError: Label 'The Place bin code must be different from the Take bin code on location';
        PutAwayActivityMessage: Label 'Put-away activity no. %1 has been created.';
        SourceDocumentError: Label 'The Source Document is not defined.';
        CurrencyCodeMessage: Label 'the existing sales lines will be deleted and new sales lines based on the new information on the header will be created.';
        LotNoTC324960Tok: Label 'L1', Locked = true;
        AvailabilityWarningsMsg: Label 'There are availability warnings on one or more lines';
        AvailabilityWarningsQst: Label 'There are availability warnings on one or more lines?';
        InvalidControlErr: Label 'This is not a valid control option for the Item Tracking Lines handler.';
        NothingToHandleErr: Label 'Nothing to handle.';
        VariantCodeMandatoryErr: Label 'Variant Code must have a value in Warehouse Journal Line: Journal Template Name=%1, Journal Batch Name=%2, Location Code=%3, Line No.=%4. It cannot be zero or empty.', Comment = '%1=Journal Template Name, %2=Journal Batch Name, %3=Location Code, %4=Line No.';

    [Test]
    [HandlerFunctions('ConfirmHandler,ItemTrackingLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyQtyOnWhsePickWithItemTracking()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine1: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        PurchLine3: Record "Purchase Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        BaseUOMCode: Code[10];
        AltUOMCode1: Code[10];
        AltUOMCode2: Code[10];
        VendorNo: Code[20];
        SimpleLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        FullWMSLocationCode: Code[10];
    begin
        // RFH 324960
        Initialize();

        // Setup
        SetupVendorAndLocations(SimpleLocationCode, InTransitLocationCode, FullWMSLocationCode, VendorNo);

        // Create an item with three UOMs (Base UOM: x, Alt. UOM 1 = 10.8x, Alt. UOM2 = 0.45x) and enable lot whse tracking on it
        CreateItemWithAdditionalUOMs(Item, BaseUOMCode, AltUOMCode1, 10.8, AltUOMCode2, 0.45);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
        EnableLotWhseTrackingOnItem(Item."No.");

        // Purchase the item using the alternative UOMs
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLineUsingUOM(PurchLine1, PurchHeader, FullWMSLocationCode, Item."No.", AltUOMCode2, 4);
        CreatePurchaseLineUsingUOM(PurchLine2, PurchHeader, FullWMSLocationCode, Item."No.", AltUOMCode2, 4);
        CreatePurchaseLineUsingUOM(PurchLine3, PurchHeader, FullWMSLocationCode, Item."No.", AltUOMCode1, 10);

        // For each line, open Item Tracking Lines and assign same Lot No. 'L1'
        AssignLotNoOnPurchaseLine(PurchLine1);
        AssignLotNoOnPurchaseLine(PurchLine2);
        AssignLotNoOnPurchaseLine(PurchLine3);

        // Release Purch. Order, create Warehouse Receipt, post as received and register Whse Put-Away
        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);
        CreateWhseReceipt(PurchHeader);
        PostWhseReceipt(WhseReceiptHeader, FullWMSLocationCode);
        RegisterWhsePutAway(PurchHeader."No.");

        // Create Transfer Order from Full WMS location to simplest location
        PrepareTransferOrder(TransferHeader, TransferLine, FullWMSLocationCode, SimpleLocationCode,
          InTransitLocationCode, Item."No.", 10, AltUOMCode1);

        // Exercise: Open Item Tracking Lines and assign lot no's using greater quantities each time
        // The quantities are chosen to create a rounding issue with the alternative UOM (3.3333)
        AssignLotNoOnTransferLine(TransferLine, 36);
        AssignLotNoOnTransferLine(TransferLine, 72);
        AssignLotNoOnTransferLine(TransferLine, 108);

        // Release Transfer Order and create Warehouse Shipment.
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        CreateWhseShipmentFromTO(TransferHeader);

        // Create Warehouse Pick using Warehouse Shipment
        CreateWhsePick(FullWMSLocationCode);

        // Verify: originally, there was a rounding issue:
        // Qty was 9.99999 instead of 10
        // Qty (base) was 107.99999 instead of 108
        WhseActivityLine.SetRange("Item No.", Item."No.");
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
        WhseActivityLine.FindSet();
        repeat
            Assert.AreEqual(108, WhseActivityLine."Qty. (Base)", 'Quantity (Base UOM) value in Pick line does not match expectations');
            Assert.AreEqual(10, WhseActivityLine.Quantity,
              'Quantity (alternative UOM) value in Pick line does not match expectations')
        until WhseActivityLine.Next() = 0
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure WhseShptWithITAndReserv()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Warehouse Shipment using Reservation and Item Tracking.

        // Setup: Create Sales Order using Item Tracking and Reservation.
        Initialize();
        CreateAndReserveSalesOrder(SalesLine);

        // Exercise:
        CreateWarehouseShipment(SalesLine."Document No.");

        // Verify: Verify Warehouse Shipment Line before Posting Warehouse Shipment.
        VerifyWarehouseShipmentLine(SalesLine."No.", SalesLine."Document No.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure PickActivityUsingSalesOrderWithReservAndIT()
    var
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Verify Pick Activity Line using Sales Order and Item Journal Line with Item Tracking.

        // Setup: Create Sales Order using Item Tracking and Reservation.
        Initialize();
        CreateAndReserveSalesOrder(SalesLine);

        // Exercise: Create Pick.
        CreatePick(SalesLine."Location Code", SalesLine."Document No.");

        // Verify: Verify Warehouse Activity Line.
        VerifyWhseActivityLine(
          WarehouseActivityLine."Activity Type"::Pick, SalesLine."Document No.", SalesLine."No.", SalesLine."Location Code",
          SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesPageHandler,SalesShipmentLinePageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPostWithItemChrgAssgnt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
        ItemChargeAssignmentOption: Option AssignmentOnly,GetShipmentLine;
    begin
        // Verify Sales Invoice Line for Item Charge using Sales Order with Item Charge Assignment.

        // Setup: Create Sales Order with Item Charge and Assignment Item Charge.
        CreateSalesOrderAndAssignItemCharge(SalesLine);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        DeleteSalesLine(SalesLine."Document No.");
        LibraryVariableStorage.Enqueue(ItemChargeAssignmentOption::GetShipmentLine);  // Enqueue value for ItemChargeAssignmentSalesPageHandler.
        SalesLine.ShowItemChargeAssgnt();

        // Exercise.
        DocumentNo := PostSalesOrder(SalesLine."Document Type", SalesLine."Document No.");

        // Verify: Verify Posted Invoice for Charge Item.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"Charge (Item)");
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("No.", SalesInvoiceLine."No.");
        SalesInvoiceLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure PickWkshUsingSalesOrderWithReserv()
    var
        PurchaseLine: Record "Purchase Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // Verify Warehouse Worksheet Line using Purchase and Sales Order with Reservation and Item Tracking.

        // Setup.
        Initialize();

        // Exercise: Create Location, Purchase and Sales Order with Item Tracking, Create and Register Warehouse Activity.
        RegisterWhseActivityAndCreateWkshLine(PurchaseLine);

        // Verify: Verify Warehouse Worksheet Line.
        FindWhseWkshLine(WhseWorksheetLine, PurchaseLine."No.", PurchaseLine."Location Code");
        WhseWorksheetLine.TestField("Qty. to Handle", PurchaseLine.Quantity);
        WhseWorksheetLine.TestField("Qty. Outstanding", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithPickWkshUsingCreatePick()
    var
        PurchaseLine: Record "Purchase Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // Verify Create Pick from Worksheet error.

        // Setup: Create Location, Purchase and Sales Order with Item Tracking, Create and Register Warehouse Activity.
        Initialize();
        RegisterWhseActivityAndCreateWkshLine(PurchaseLine);

        // Exercise: Create Worksheet Line.
        FindWhseWkshLine(WhseWorksheetLine, PurchaseLine."No.", PurchaseLine."Location Code");
        asserterror LibraryWarehouse.CreatePickFromPickWorksheet(
            WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name,
            PurchaseLine."Location Code", '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        // Verify: Verify Create Pick from Worksheet error.
        Assert.ExpectedError(SourceDocumentError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingListPageHandler,EnterQuantitytoCreatePageHandler,AvailConfirmHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure AvailabilityErrorUsingSalesOrderReserv()
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        TrackingOption: Option AssignSerialNo,SelectEntries;
    begin
        // Verify Availability error with Sales Order Reservation.

        // Setup: Create Sales Order with Item Tracking.
        Initialize();
        CreateWarehouseLocation(Location);
        CreateSalesDocument(
          SalesLine, SalesLine.Type::Item, CreateAndModifyTrackedItem(false, false, true), Location.Code, LibraryRandom.RandInt(10));
        UpdateSalesLineUnitPrice(SalesLine, LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();

        // Exercise.
        asserterror SalesLine.ShowReservation();

        // Verify: Verify Availability error with Sales Order Reservation.
        Assert.ExpectedError(AvailabilityError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithRegisterPickUsingBlankBin()
    var
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Verify error while Registering Pick without Bin Code.

        // Setup: Create Item Journal Line with Item Tracking Code, Create and Release a Sales Order with Item Tracking and Reservation.
        Initialize();
        CreateAndReserveSalesOrder(SalesLine);
        CreatePick(SalesLine."Location Code", SalesLine."Document No.");

        // Exercise: Register Pick without Bin Code.
        asserterror RegisterWarehouseActivity(SalesLine."Document No.", WarehouseActivityHeader.Type::Pick, SalesLine."Location Code");

        // Verify: Verify error while Registering Pick without Bin Code.
        Assert.ExpectedError(BinCodeError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure BinCodeErrorUsingCreatePick()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Verify error while validation blank Bin Code on Warehouse Activity Line with Action Type 'Place'.

        // Setup: Create Item Journal Line with Item Tracking Code, Create and Release a Sales Order with Item Tracking.
        Initialize();
        ErrorUsingCreatePick(WarehouseActivityLine."Action Type"::Place, '', PlaceBinCodeError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure BinContentErrorUsingWhseActivityLine()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Verify error while validation Bin Code on Warehouse Activity Line with Action Type 'Take'.

        // Setup: Create Item Journal Line with Item Tracking Code, Create and Release a Sales Order with Item Tracking.
        Initialize();
        ErrorUsingCreatePick(WarehouseActivityLine."Action Type"::Take, LibraryUtility.GenerateGUID(), BinContentError);
    end;

    local procedure ErrorUsingCreatePick(ActionType: Enum "Warehouse Action Type"; BinCode: Code[20]; ExpectedError: Text[1024])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Create Item Journal Line with Item Tracking Code, Create and Release a Sales Order with Item Tracking.
        CreateAndFindWhseActivityLine(WarehouseActivityLine, ActionType);

        // Exercise: Modify Pick Bin Code.
        asserterror WarehouseActivityLine.Validate("Bin Code", BinCode);

        // Verify: Verify error while modifying Bin Code on created Pick for Action Type 'Place'.
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWithCreateInvtPutAwayPickUsingSalesOrder()
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // Verify Warehouse Request error using Sales Order while creating Inventory Put Away Pick.

        // Setup: Create Sales Order with Item Tracking.
        Initialize();
        CreateWarehouseLocation(Location);
        CreateSalesDocument(SalesLine, SalesLine.Type::Item, CreateItem(), Location.Code, LibraryRandom.RandInt(10));

        // Exercise.
        asserterror LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, true, true, false);

        // Verify: Verify Availability error with Sales Order Reservation.
        Assert.ExpectedErrorCannotFind(Database::"Warehouse Request");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandlerForItemNo,AvailConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemOnEnterQuantityToCreatePage()
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        TrackingOption: Option AssignSerialNo,SelectEntries;
    begin
        // Verify Item No. On Enter Quantity to Create page.

        // Setup: Create Sales Order and assign Item Tracking.
        Initialize();
        CreateWarehouseLocation(Location);
        CreateSalesDocument(
          SalesLine, SalesLine.Type::Item, CreateAndModifyTrackedItem(false, false, true), Location.Code, LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."No.");  // Enqueue value for EnterQuantityToCreatePageHandlerForItemNo.

        // Exercise.
        SalesLine.OpenItemTrackingLines();

        // Verify: Verify Item No. On Enter Quantity to Create page, verification done in 'EnterQuantityToCreatePageHandlerForItemNo' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,MessageHandler,ReservationFromCurrentLineHandler,ConfirmHandler,PickSelectionPageHandler,CreatePickPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromPickWkshUsingIT()
    var
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseSetup: Record "Warehouse Setup";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
        PickNo: Code[20];
    begin
        // Verify Pick Lines created after Get Warehouse Documents.

        // Setup: Create and post Warehouse Receipt, create Warehouse Shipment and create Pick from Pick Worksheet after Get Warehouse Documents.
        Initialize();
        WarehouseSetup.Get();
        DocumentNo := PostWhseRcptAndCreateWhseShpt(PurchaseLine);
        GetWhseDocFromPickWksh();
        Commit();
        PickNo := NoSeries.PeekNextNo(WarehouseSetup."Whse. Pick Nos.");
        LibraryVariableStorage.Enqueue(StrSubstNo(PickActivityMessage, PickNo));  // Enqueue for Message Handler.

        // Exercise.
        CreatePickFromPickWkshPage(PurchaseLine."No.");

        // Verify: Verify Pick Lines create after Get Warehouse Documents.
        VerifyWhseActivityLine(
          WarehouseActivityLine."Activity Type"::Pick, DocumentNo, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler,ConfirmHandler,PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure GetWhseDocFromPickWkshUsingIT()
    var
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Pick Worksheet created after Get Warehouse Documents.

        // Setup: Create and post Warehouse Receipt and create Warehouse Shipment.
        Initialize();
        DocumentNo := PostWhseRcptAndCreateWhseShpt(PurchaseLine);

        // Exercise: Get Warehouse Documents from Pick Worksheet.
        GetWhseDocFromPickWksh();

        // Verify: Verify Pick Worksheet after Get Warehouse Documents.
        VerifyWkshLine(PurchaseLine."No.", PurchaseLine.Quantity, DocumentNo, PurchaseLine."Location Code");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayUsingWhseRcptWithIT()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // Verify Warehouse Activity Line for Put Away after post Warehouse Receipt.

        // Setup: Create Location, create and release Purchase Order with Item Tracking and create Warehouse Receipt.
        Initialize();
        CreateWarehouseLocation(Location);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, CreateAndModifyTrackedItem(false, false, true), Location.Code);  // Using Random Quantity.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Exercise:.
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Verify: Verify Warehouse Activity Line for Put Away after post Warehouse Receipt.
        VerifyWhseActivityLine(
          WarehouseActivityLine."Activity Type"::"Put-away", PurchaseLine."Document No.", PurchaseLine."No.",
          PurchaseLine."Location Code", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,PutAwaySelectionPageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayWkshUsingGetWhseDoc()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PutAwayWorksheet: TestPage "Put-away Worksheet";
    begin
        // Verify Put Away Worksheet Line using Get Warehouse Documents.

        // Setup: Create Location, create and release Purchase Order with Item Tracking, create and post Warehouse Receipt.
        Initialize();
        CreateWarehouseLocation(Location);
        Location.Validate("Use Put-away Worksheet", true);
        Location.Modify(true);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, CreateAndModifyTrackedItem(false, false, true), Location.Code);  // Using Random Quantity.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        PutAwayWorksheet.OpenEdit();

        // Exercise: Get Warehouse Documents from Put Away Worksheet.
        PutAwayWorksheet.GetWarehouseDocuments.Invoke();

        // Verify: Verify Put Away Worksheet Line using Get Warehouse Documents.
        PutAwayWorksheet.OK().Invoke();
        VerifyWkshLine(PurchaseLine."No.", PurchaseLine.Quantity, PurchaseHeader."No.", PurchaseLine."Location Code");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithLocationUsingWhseShpt()
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Verify error while validation Location Code on the Warehouse Shipment Header.

        // Setup: Create Location, Sales Order with Reservation and create Warehouse Shipment Header.
        Initialize();
        CreateWarehouseLocation(Location);
        CreateAndReserveSalesOrder(SalesLine);
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);

        // Exercise.
        asserterror WarehouseShipmentHeader.Validate("Location Code", Location.Code);

        // Verify: Verify error while validation Location Code on the Warehouse Shipment Header.
        Assert.ExpectedError(StrSubstNo(LocationCodeError, Location.Code));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GetSourceDocFromWhseShpt()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        DocumentNo: Code[20];
    begin
        // Verify Warehouse Shipment Lines created through Get Source Documents.

        // Setup: Create Location, create and release Purchase Order with Item Tracking, create Warehouse Receipt, create Sales Order and create Warehouse Shipment Header.
        Initialize();
        CreateAndPostWhseReceipt(PurchaseLine);
        DocumentNo := CreateWhseShptWithIT(SalesLine, PurchaseLine);
        WarehouseShipmentHeader.Get(DocumentNo);

        // Exercise.
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, PurchaseLine."Location Code");

        // Verify: Verify Warehouse Shipment Lines created through Get Source Documents.
        FindWhseShptLine(WarehouseShipmentLine, SalesLine."Document No.", SalesLine."Location Code");
        WarehouseShipmentLine.TestField("Item No.", SalesLine."No.");
        WarehouseShipmentLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreatePickUsingGetSourceDocOnWhseShpt()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        DocumentNo: Code[20];
    begin
        // Verify Warehouse Activity Line created through Get Source Documents.

        // Setup: Create Location, create and release Purchase Order with Item Tracking, create Warehouse Receipt, create Sales Order and create Warehouse Shipment Header.
        Initialize();
        CreateAndPostWhseReceipt(PurchaseLine);
        RegisterWarehouseActivity(PurchaseLine."Document No.", WarehouseActivityHeader.Type::"Put-away", PurchaseLine."Location Code");
        DocumentNo := CreateWhseShptWithIT(SalesLine, PurchaseLine);
        WarehouseShipmentHeader.Get(DocumentNo);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, PurchaseLine."Location Code");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // Exercise.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify Warehouse Activity line.
        if PurchaseLine.Quantity < SalesLine.Quantity then
            VerifyWhseActivityLine(WarehouseActivityLine."Activity Type"::Pick, SalesLine."Document No.", SalesLine."No.", SalesLine."Location Code", PurchaseLine.Quantity)
        else
            VerifyWhseActivityLine(WarehouseActivityLine."Activity Type"::Pick, SalesLine."Document No.", SalesLine."No.", SalesLine."Location Code", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler,WhseSourceCreateDocumentReportHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromWhseInternalPick()
    var
        SalesLine: Record "Sales Line";
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        NoSeries: Codeunit "No. Series";
        PickNo: Code[20];
        No: Code[20];
    begin
        // Verify that Bin Code must be blank on Warehouse Activity Line's Action Type 'Take'.

        // Setup: Create Sales Order with Item Tracking and Reservation, find Zone, find Bin, create Warehouse Internal Pick.
        Initialize();
        WarehouseSetup.Get();
        No := CreateWhseInternalPickLine(SalesLine);
        PickNo := NoSeries.PeekNextNo(WarehouseSetup."Whse. Pick Nos.");
        LibraryVariableStorage.Enqueue(StrSubstNo(PickActivityMessage, PickNo));  // Enqueue for Message Handler.

        // Exercise: Create Pick from Warehouse Internal Pick page.
        CreatePickFromWhseInternalPickPage(SalesLine."Location Code");

        // Verify: Verify that Bin Code must be blank on Warehouse Activity Line's Action Type 'Take'.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, SalesLine."Location Code", No,
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField("Bin Code", '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseInternalPickUsingSalesOrder()
    var
        SalesLine: Record "Sales Line";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        // Verify values on Warehouse Internal Pick Line.

        // Setup: Create Sales Order with Item Tracking and Reservation, find Zone, find Bin, create Warehouse Internal Pick.
        Initialize();

        // Exercise.
        CreateWhseInternalPickLine(SalesLine);

        // Verify: Verify values on Warehouse Internal Pick Line.
        WhseInternalPickLine.SetRange("Location Code", SalesLine."Location Code");
        WhseInternalPickLine.FindFirst();
        WhseInternalPickLine.TestField("Item No.", SalesLine."No.");
        WhseInternalPickLine.TestField("Qty. Outstanding", SalesLine.Quantity);
        WhseInternalPickLine.TestField("Pick Qty.", 0);  // Here taken zero for Pick Qty. Pick Activity is not created.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler,WhseSourceCreateDocumentReportHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayFromWhseInternalPutAway()
    var
        SalesLine: Record "Sales Line";
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        NoSeries: Codeunit "No. Series";
        PutAwayNo: Code[20];
        BinCode: Code[20];
    begin
        // Verify that Bin Code must not be blank on Warehouse Activity Line's Action Type 'Take'.

        // Setup: Create Sales Order with Item Tracking and Reservation, find Zone, find Bin, create Warehouse Internal Put Away.
        Initialize();
        BinCode := CreateWhseInternalPutAwayLine(SalesLine);
        WarehouseSetup.Get();
        PutAwayNo := NoSeries.PeekNextNo(WarehouseSetup."Whse. Put-away Nos.");
        LibraryVariableStorage.Enqueue(StrSubstNo(PutAwayActivityMessage, PutAwayNo));  // Enqueue for Message Handler.

        // Exercise: Create Put Away from Warehouse Internal Put Away.
        CreatePutAwayFromWhseInternalPutAwayPage(SalesLine."Location Code");

        // Verify: Verify that Bin Code must not be blank on Warehouse Activity Line's Action Type 'Take'.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", SalesLine."Location Code", '',
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField("Source No.", '');
        WarehouseActivityLine.TestField("Bin Code", BinCode);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseInternalPutAwayUsingSalesOrder()
    var
        SalesLine: Record "Sales Line";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
    begin
        // Verify values on Warehouse Internal Put Away Line.

        // Setup: Create Sales Order with Item Tracking and Reservation, find Zone, find Bin, create Warehouse Internal Put Away.
        Initialize();

        // Exercise.
        CreateWhseInternalPutAwayLine(SalesLine);

        // Verify: Verify values on Warehouse Internal Put Away Line.
        WhseInternalPutAwayLine.SetRange("Location Code", SalesLine."Location Code");
        WhseInternalPutAwayLine.FindFirst();
        WhseInternalPutAwayLine.TestField("Item No.", SalesLine."No.");
        WhseInternalPutAwayLine.TestField("Qty. Outstanding", SalesLine.Quantity);
        WhseInternalPutAwayLine.TestField("Qty. Put Away", 0);  // Here taken zero for Pick Qty. Pick Activity is not created.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure WhseEntryAfterRegisterWhseItemJournal()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Verify values on Warehouse Entry after Registering Whse. Journal Line.

        // Setup: Create and Register Warehouse Journal Line.
        Initialize();
        CreateAndRegisterWhseItemJnlLine(WarehouseJournalLine);

        // Verify: Verify Serial No and Quantity on Warehouse Entry after Registering Whse. Journal Line.
        VerifyWarehouseEntries(WarehouseJournalLine."Item No.", WarehouseJournalLine."Location Code", 1);  // Verify Serial Quantity.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ItemJnlLineAfterCalcWhseAdjmt()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Verify that Item Journal Line must be generated after Calculate Whse. Adjustment.

        // Setup: Create and Register Warehouse Journal Line.
        Initialize();
        CreateAndRegisterWhseItemJnlLine(WarehouseJournalLine);
        Item.Get(WarehouseJournalLine."Item No.");

        // Exercise: Calculate Warehouse Adjustment on Item Journal Line.
        CalculateWhseAdjustment(ItemJournalBatch, Item, WarehouseJournalLine."Item No.", true);

        // Verify: Verify that Item Journal Line must be generated after Calculate Whse. Adjustment.
        ItemJournalLine.SetRange("Item No.", WarehouseJournalLine."Item No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Location Code", WarehouseJournalLine."Location Code");
        ItemJournalLine.TestField(Quantity, WarehouseJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryAfterCalcWhseAdjmt()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Verify that Item Journal Line must be generated after Calculate Whse. Adjustment.

        // Setup: Create and Register Warehouse Journal Line.
        Initialize();
        CreateAndRegisterWhseItemJnlLine(WarehouseJournalLine);
        Item.Get(WarehouseJournalLine."Item No.");
        CalculateWhseAdjustment(ItemJournalBatch, Item, WarehouseJournalLine."Item No.", true);

        // Exercise.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Verify: Verify Item Ledger Entry after Calculate Whse. Adjustment and post Item Journal Line.
        ItemLedgerEntry.SetRange("Item No.", WarehouseJournalLine."Item No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Location Code", WarehouseJournalLine."Location Code");
        ItemLedgerEntry.TestField(Quantity, WarehouseJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickAfterCalcWhseAdjmt()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Verify Warehouse Activity line for Pick.

        // Setup: Create and Register Warehouse Activity line, Calculate Adjustment, Post Item Journal Line, create and release Sales Order.
        Initialize();
        CreateAndRegisterWhseItemJnlLine(WarehouseJournalLine);
        Item.Get(WarehouseJournalLine."Item No.");
        CalculateWhseAdjustment(ItemJournalBatch, Item, WarehouseJournalLine."Item No.", true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        CreateAndReleaseSalesOrderWithITAndReserv(
          SalesLine, WarehouseJournalLine."Item No.", WarehouseJournalLine."Location Code", WarehouseJournalLine.Quantity);

        // Exercise.
        CreatePick(SalesLine."Location Code", SalesLine."Document No.");

        // Verify: Verify Warehouse Activity line for Pick.
        VerifyWhseActivityLine(
          WarehouseActivityLine."Activity Type"::Pick, SalesLine."Document No.", SalesLine."No.", SalesLine."Location Code",
          SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickUsingGetSourceDoc()
    var
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Verify Warehouse Activity line for Pick using Get Source Documents from Warehouse Shipment.

        // Setup: Create and Register Warehouse Activity line, Calculate Adjustment, Post Item Journal Line, create and release Sales Order.
        Initialize();
        CreatePickUsingGetSourceDocWithWhseJournal(SalesLine);

        // Verify: Verify Warehouse Activity line for Pick using Get Source Documents from Warehouse Shipment.
        VerifyWhseActivityLine(
          WarehouseActivityLine."Activity Type"::Pick, SalesLine."Document No.", SalesLine."No.", SalesLine."Location Code",
          SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithPostShptUsingCreatePick()
    var
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        DocumentNo: Code[20];
    begin
        // Verify error message while posting Warehouse Shipment without Registering Pick.

        // Setup: Create and Register Warehouse Activity line, Calculate Adjustment, Post Item Journal Line, create and release Sales Order.
        Initialize();
        DocumentNo := CreatePickUsingGetSourceDocWithWhseJournal(SalesLine);

        // Exercise.
        WarehouseShipmentHeader.Get(DocumentNo);
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify error message while posing Warehouse Shipment without Registering Pick.
        Assert.ExpectedError(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemInvtAfterPostRcpt()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
        InventoryQuantity: Decimal;
    begin
        // Verify that Item Inventory must be equal to combined Quantity on Item Journal and Purchase Line.

        // Setup: Create and post a Item Journal Line, create and post a Warehouse Receipt Line.
        Initialize();
        CreateAndPosteItenJnlLine(ItemJournalLine);
        CreateAndPostWhseRcpt(PurchaseLine, ItemJournalLine."Item No.", ItemJournalLine."Location Code");
        InventoryQuantity := ItemJournalLine.Quantity + PurchaseLine.Quantity;

        // Exercise.
        Item.Get(PurchaseLine."No.");
        Item.CalcFields(Inventory);

        // Verify: Verify that Item Inventory must be equal to combined Quantity on Item Journal and Purchase Line.
        Item.TestField(Inventory, InventoryQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickUsingItemJnlLineAndSalesOrder()
    var
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        InventoryQuantity: Decimal;
    begin
        // Verify Warehouse Activity Line after creating Pick.

        // Setup: Create and post a Item Journal Line, create and post a Warehouse Receipt Line.
        Initialize();
        CreateAndPosteItenJnlLine(ItemJournalLine);
        CreateAndPostWhseRcpt(PurchaseLine, ItemJournalLine."Item No.", ItemJournalLine."Location Code");
        InventoryQuantity := ItemJournalLine.Quantity + PurchaseLine.Quantity;
        CreateSalesDocument(SalesLine, SalesLine.Type::Item, PurchaseLine."No.", ItemJournalLine."Location Code", InventoryQuantity);
        UpdateSalesLineUnitPrice(SalesLine, LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise.
        CreatePick(SalesLine."Location Code", SalesLine."Document No.");

        // Verify: Verify Warehouse Activity Line Quanity for Pick.
        VerifyWhseActivityLine(
          WarehouseActivityLine."Activity Type"::Pick, SalesLine."Document No.", SalesLine."No.", SalesLine."Location Code",
          InventoryQuantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,MessageHandler,ReservationFromCurrentLineHandler,ConfirmHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingMessageAfterWhseRcpt()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Message 'There are no order tracking entries for this line. must be come after opening Order Tracking Page', verification done in MessageHandler.

        // Setup: Create and post Warehouse Receipt, create Sales Order with Reservation, creare Warehouse Shipment and Create Pick.
        Initialize();
        CreatePOAndWhseRcptUsingReqLine(PurchaseLine);

        // Exercise.
        RunOrderTracking(PurchaseLine);

        // Verify: Verify Message 'There are no order tracking entries for this line. must be come after opening Order Tracking Page', verification done in MessageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,MessageHandler,ReservationFromCurrentLineHandler,ConfirmHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingMessageAfterRegisterPick()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Message 'There are no order tracking entries for this line. must be come while opening Order Tracking Page' after Registering Pick, verification done in MessageHandler.

        // Setup: Create and post Warehouse Receipt, create Sales Order with Reservation, creare Warehouse Shipment, Create and Register Pick.
        Initialize();
        DocumentNo := CreatePOAndWhseRcptUsingReqLine(PurchaseLine);
        RegisterWarehouseActivity(DocumentNo, WarehouseActivityHeader.Type::Pick, PurchaseLine."Location Code");

        // Exercise.
        RunOrderTracking(PurchaseLine);

        // Verify: Verify Message 'There are no order tracking entries for this line. must be come after opening Order Tracking Page', verification done in MessageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservMenuHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithReservUsingTransferOrder()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TrackingOption: Option AssignSerialNo,SelectEntries,AssignLotNo,SetValues;
    begin
        // Verify error while assigning Reservation on Transfer Line.

        // Setup: Create Location, create Purchase Order with Item Tracking.
        Initialize();
        CreateWarehouseLocation(Location);
        CreatePurchaseOrder(PurchaseLine, Location.Code, CreateAndModifyTrackedItem(false, false, true));
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");

        // Exercise.
        asserterror CreateTransferOrder(TransferHeader, PurchaseLine."Location Code", PurchaseLine."No.", PurchaseLine.Quantity);

        // Verify: Verify error while assigning Reservation on Transfer Line.
        Assert.ExpectedError(AvailabilityError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservMenuHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ITErrorOnPurchOrderUsingTransferOrder()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TrackingSpec: Record "Tracking Specification";
        TrackingOption: Option AssignSerialNo,SelectEntries,AssignLotNo,SetValues;
    begin
        // Verify error while reassigning Item Tracking values on Purchase Line.

        // Setup: Create Location, create and post Purchase Order with Item Tracking, create Transfer Order with Item Tracking.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreatePurchaseOrder(PurchaseLine, Location.Code, CreateAndModifyTrackedItem(false, true, false));
        LibraryVariableStorage.Enqueue(TrackingOption::SetValues);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        CreateTransferOrder(TransferHeader, PurchaseLine."Location Code", PurchaseLine."No.", PurchaseLine.Quantity);
        PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryVariableStorage.Enqueue(TrackingOption::SetValues);  // Enqueue value for ItemTrackingLinesPageHandler.

        // Exercise.
        asserterror PurchaseLine.OpenItemTrackingLines();

        // Verify: Verify error while reassigning Item Tracking values on Purchase Line.
        Assert.ExpectedTestFieldError(TrackingSpec.FieldCaption("Quantity Handled (Base)"), Format(0));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ReservMenuHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ILEAfterPostTransferOrderWithIT()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TrackingOption: Option AssignSerialNo,SelectEntries,AssignLotNo,SetValues;
    begin
        // Verify Item Ledger Entry after Posting Transfer Order with Item Tracking and Reservation.

        // Setup: Create Location, create Purchase Order with Item Tracking, create Transfer Order with Item Tracking.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreatePurchaseOrder(PurchaseLine, Location.Code, CreateAndModifyTrackedItem(false, true, false));
        LibraryVariableStorage.Enqueue(TrackingOption::SetValues);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateTransferOrder(TransferHeader, PurchaseLine."Location Code", PurchaseLine."No.", PurchaseLine.Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);

        // Exercise.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);

        // Verify: Verify Item Ledger Entry after Posting Transfer Order with Item Tracking and Reservation.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Item No.", TransferLine."Item No.");
        ItemLedgerEntry.SetRange("Location Code", TransferLine."Transfer-to Code");
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, TransferLine.Quantity / 2);  // Divided by 2 because half value is assigned in Item tracking and posted.
        ItemLedgerEntry.TestField("Invoiced Quantity", TransferLine.Quantity / 2);  // Divided by 2 because half value is assigned in Item tracking and posted.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationFromCurrentLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithReCreateWhseShptFromPO()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        DocumentNo: Code[20];
    begin
        // Verify error message while posting Warehouse Shipment.

        // Setup: Create Warehouse Receipt, create Warehouse Shipment and release.
        Initialize();
        CreateAndPostWhseReceipt(PurchaseLine);
        RegisterWarehouseActivity(PurchaseLine."Document No.", WarehouseActivityHeader.Type::"Put-away", PurchaseLine."Location Code");
        DocumentNo := CreateWhseShptWithIT(SalesLine, PurchaseLine);
        WarehouseShipmentHeader.Get(DocumentNo);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, PurchaseLine."Location Code");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // Exercise.
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // Verify: Verify error message while posting Warehouse Shipment.
        Assert.ExpectedError(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [HandlerFunctions('ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ReservEntryUsingSalesOrderWithShptDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Verify Reservation Entry values after modifying the Shipment Date on Sales Line.

        // Setup: Create and post Purchase Order, create Sales Order and reserve Sales Line.
        Initialize();
        ReservOnSalesOrderUsingPO(SalesLine);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");

        // Exercise: Modify Shipment Date on Sales Header.
        SalesHeader.Validate("Shipment Date", CalcDate('<1D>', WorkDate()));
        SalesHeader.Modify(true);

        // Verify: Verify Reservation Entry values after modifying the Shipment Date on Sales Line.
        ReservationEntry.SetRange("Item No.", SalesLine."No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, -SalesLine.Quantity);
        ReservationEntry.TestField("Qty. to Handle (Base)", -SalesLine.Quantity);
        ReservationEntry.TestField("Shipment Date", SalesHeader."Shipment Date");
    end;

    [Test]
    [HandlerFunctions('ReservationFromCurrentLineHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CurrencyErrorWithSalesOrder()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify message 'the existing sales lines will be deleted...', verification done in Confirm Handler.

        // Setup: Create Location, create and release Purchase Order with Item Tracking, create Warehouse Receipt, create Sales Order and create Warehouse Shipment Header.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        ReservOnSalesOrderUsingPO(SalesLine);
        SalesHeader.Get(SalesLine."Document Type"::Order, SalesLine."Document No.");
        LibraryVariableStorage.Enqueue(CurrencyCodeMessage);  // Enqueue value for ItemTrackingLinesPageHandler.

        // Exercise: Modify Currency Code on Sales Header.
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Modify(true);

        // Verify: Verify message 'the existing sales lines will be deleted...', verification done in Confirm Handler.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromShpmtWhenStockAvail0()
    var
        Item: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        BinShpmt: Record Bin;
        BinPick: Record Bin;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        i: Integer;
    begin
        // [FEATURE] [Sales] [Order] [Pick] [Reservation]
        // [SCENARIO 226023] Trying to create Whse. Pick from shpmt for stock qty, which is reserved for another Shpmt; error must occur.

        Initialize();

        // [GIVEN] Create new Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create new Location with 2 bins onboard: for pick and for shipment
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateBin(BinShpmt, Location.Code, '', '', '');
        Location.Validate("Shipment Bin Code", BinShpmt.Code);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(BinPick, Location.Code, '', '', '');

        // [GIVEN] Purchase and receive Items on new Location (Quantities 4-1-1-1)
        CreateAndPostItemJnlLineQty(Item."No.", Location.Code, BinPick.Code, 4);
        for i := 1 to 3 do
            CreateAndPostItemJnlLineQty(Item."No.", Location.Code, BinPick.Code, 1);

        // [GIVEN] Create Sales Order for 5 pcs and 5 pcs reserved; create Whse. Shipment #1
        CreateSOReserveAndCreateWhseShpmt(SalesLine, SalesLine.Type::Item, Item."No.", Location.Code, 5);

        // [GIVEN] Create another Sales Order for 5 pcs and reserve 2 pcs;  create Whse. Shipment #2
        CreateSOReserveAndCreateWhseShpmt(SalesLine, SalesLine.Type::Item, Item."No.", Location.Code, 5);
        GetWhseShpmtBySONo(WarehouseShipmentHeader, SalesLine."Document No.");

        // [GIVEN] Create Whse. Pick for 2 pcs from Whse. Shipment #2
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [WHEN] Trying to create one more Whse Pick from Whse. Shipment #2
        asserterror LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Error message: Nothing to handle.
        Assert.ExpectedError(NothingToHandleErr);
    end;

    [Normal]
    local procedure SetupVendorAndLocations(var SimpleLocationCode: Code[10]; var InTransitLocationCode: Code[10]; var FullWMSLocationCode: Code[10]; var VendorNo: Code[20])
    var
        SimpleLocation: Record Location;
        InTransitLocation: Record Location;
        FullWMSLocation: Record Location;
        Vendor: Record Vendor;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocation(SimpleLocation);

        LibraryWarehouse.CreateLocation(InTransitLocation);
        InTransitLocation.Validate("Use As In-Transit", true);
        InTransitLocation.Modify(true);

        LibraryWarehouse.CreateFullWMSLocation(FullWMSLocation, 10);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FullWMSLocation.Code, true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Location Code", FullWMSLocation.Code);
        Vendor.Modify(true);

        SimpleLocationCode := SimpleLocation.Code;
        InTransitLocationCode := InTransitLocation.Code;
        FullWMSLocationCode := FullWMSLocation.Code;
        VendorNo := Vendor."No.";
    end;

    [Normal]
    local procedure CreateItemWithAdditionalUOMs(var Item: Record Item; var BaseUOMCode: Code[10]; var AltUOMCode1: Code[10]; QtyPerAltUOM1: Decimal; var AltUOMCode2: Code[10]; QtyPerAltUOM2: Decimal)
    var
        AdditionalItemUOM1: Record "Item Unit of Measure";
        AdditionalItemUOM2: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(10, 2));
        LibraryInventory.CreateItemUnitOfMeasureCode(AdditionalItemUOM1, Item."No.", QtyPerAltUOM1);
        LibraryInventory.CreateItemUnitOfMeasureCode(AdditionalItemUOM2, Item."No.", QtyPerAltUOM2);

        BaseUOMCode := Item."Base Unit of Measure";
        AltUOMCode1 := AdditionalItemUOM1.Code;
        AltUOMCode2 := AdditionalItemUOM2.Code;
    end;

    [Normal]
    local procedure EnableLotWhseTrackingOnItem(ItemNo: Code[20])
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.Get(ItemNo);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);

        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    [Normal]
    local procedure CreatePurchaseLineUsingUOM(var PurchLine: Record "Purchase Line"; var PurchHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; UOMCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, Quantity);

        PurchLine.Validate("Unit of Measure Code", UOMCode);
        PurchLine.Validate("Location Code", LocationCode);
        PurchLine.Modify(true);
    end;

    [Normal]
    local procedure AssignLotNoOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        ListLength: Integer;
    begin
        // This function assumes that an availability warning confirm dialog may be shown to the user
        // However, depending on the state of the database, this might not occur
        // Check whether all enqueued elements have been used to avoid dangling elements in the list
        ListLength := LibraryVariableStorage.Length();

        LibraryVariableStorage.Enqueue(ItemTrackingLinesControl::CallingFromPO);
        LibraryVariableStorage.Enqueue(AvailabilityWarningsMsg);
        PurchaseLine.OpenItemTrackingLines();

        if LibraryVariableStorage.Length() > ListLength then
            if Confirm(AvailabilityWarningsQst) then;
    end;

    [Normal]
    local procedure CreateWhseReceipt(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    [Normal]
    local procedure PostWhseReceipt(var WhseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    begin
        WhseReceiptHeader.SetRange("Location Code", LocationCode);
        WhseReceiptHeader.FindFirst();
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);
    end;

    [Normal]
    local procedure RegisterWhsePutAway(SourceNo: Code[20])
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // Find Whse activity no.
        WhseActivityLine.SetRange("Source No.", SourceNo);
        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type::"Put-away");
        WhseActivityLine.FindFirst();

        WhseActivityHeader.Get(WhseActivityHeader.Type::"Put-away", WhseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
    end;

    [Normal]
    local procedure AssignLotNoOnTransferLine(var TransferLine: Record "Transfer Line"; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingLinesControl::CallingFromTO);
        LibraryVariableStorage.Enqueue(Qty);

        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    [Normal]
    local procedure CreateWhseShipmentFromTO(var TransferHeader: Record "Transfer Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
    end;

    [Normal]
    local procedure CreateWhsePick(LocationCode: Code[10])
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        WhseShipmentHeader.SetRange("Location Code", LocationCode);
        WhseShipmentHeader.FindFirst();
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);

        WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::Pick);
        WhseActivityHeader.SetRange("Location Code", LocationCode);
        WhseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
    end;

    [Normal]
    local procedure PrepareTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; UOMCode: Code[10])
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Unit of Measure Code", UOMCode);
        TransferLine.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,AvailableToReserveHandler')]
    [Scope('OnPrem')]
    procedure ReservedQuantityInDifferentUnitOfMeasure()
    var
        Location: Record Location;
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine1: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BaseUOMCode: Code[10];
        AltUOMCode1: Code[10];
        AltUOMCode2: Code[10];
        QtyPer1: Decimal;
        QtyPer2: Decimal;
        QtyPurch: Decimal;
        QtySale: Decimal;
    begin
        // [FEATURE] [Reservation] [Unit of Measure]
        // [SCENARIO 140608] Reserved Quantity should be calculated correct when reserving SO in different UoM then PO
        Initialize();

        // [GIVEN] Item with two nonbasic UoM: "A" with Qty Per= "0.1" and "B" with Qty Per = "100"
        QtyPer1 := LibraryRandom.RandDec(10, 2);
        QtyPer2 := LibraryRandom.RandDecInRange(10, 100, 2);
        CreateItemWithAdditionalUOMs(Item, BaseUOMCode, AltUOMCode1, QtyPer1, AltUOMCode2, QtyPer2);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        // [GIVEN] Purchase Order for Item in UoM = "X" of Quantity = "500"
        QtyPurch := QtyPer1 * LibraryRandom.RandDec(10, 2);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '');
        CreatePurchaseLineUsingUOM(PurchLine1, PurchHeader, Location.Code, Item."No.", AltUOMCode1, QtyPurch);

        // [GIVEN] Sales Line for Item in UoM = "Y" of Quantity "1"
        QtySale := LibraryRandom.RandDecInRange(100, 1000, 2);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", QtySale);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit of Measure Code", AltUOMCode2);
        SalesLine.Validate("Planned Delivery Date", CalcDate('<1M>', SalesHeader."Posting Date"));
        SalesLine.Modify(true);

        // [WHEN] Reserve Item from Purchase Order
        SalesLine.ShowReservation();

        // [THEN] Sales Line has fully reserved Quantity "0.5" of PO in UoM "Y"
        SalesLine.Find();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", Round(QtyPurch * QtyPer1 / QtyPer2, 0.00001));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedQtyFromInventoryIsAdjustedByPickedQty()
    var
        ReservationEntry: Record "Reservation Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
        QtyReservedAndPicked: Decimal;
    begin
        // [FEATURE] [Pick] [UT]
        // [SCENARIO 374777] Function "CalcReservQtyOnPicksShips" calculates reserved quantity from inventory that is prepared for picking.
        Initialize();

        // [GIVEN] Pair of reservation entries representing 20 pcs on sales line reserved from inventory.
        // [GIVEN] Warehouse pick for 10 pcs for the sales line.
        MockPairedReservationEntries(ReservationEntry, DATABASE::"Item Ledger Entry");
        MockPickLine(WarehouseActivityLine, ReservationEntry);

        // [WHEN] Calculate quantity that is both reserved and prepared for picking.
        QtyReservedAndPicked :=
          WarehouseAvailabilityMgt.CalcReservQtyOnPicksShips(
            ReservationEntry."Location Code", ReservationEntry."Item No.", '', TempWarehouseActivityLine);

        // [THEN] Quantity = 10 pcs.
        Assert.AreEqual(WarehouseActivityLine."Qty. Outstanding (Base)", QtyReservedAndPicked, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedQtyFromOtherSourcesNotAdjustedByPickedQty()
    var
        ReservationEntry: Record "Reservation Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
        QtyReservedAndPicked: Decimal;
    begin
        // [FEATURE] [Pick] [UT]
        // [SCENARIO 374777] Function "CalcReservQtyOnPicksShips" returns 0 when the quantity is reserved not from inventory.
        Initialize();

        // [GIVEN] Pair of reservation entries representing 20 pcs on sales line reserved from assembly.
        // [GIVEN] Warehouse pick for 10 pcs for the sales line.
        MockPairedReservationEntries(ReservationEntry, DATABASE::"Assembly Header");
        MockPickLine(WarehouseActivityLine, ReservationEntry);

        // [WHEN] Calculate quantity that is both reserved and prepared for picking.
        QtyReservedAndPicked :=
          WarehouseAvailabilityMgt.CalcReservQtyOnPicksShips(
            ReservationEntry."Location Code", ReservationEntry."Item No.", '', TempWarehouseActivityLine);

        // [THEN] Quantity = 0 pcs.
        Assert.AreEqual(0, QtyReservedAndPicked, '');
    end;

    [Test]
    procedure CheckVariantMandatoryForWarehouseItemJournal()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [SCENARIO 543616] Check Variant Code is Mandatory when register Warehouse Item Journal.
        Initialize();

        // [GIVEN] Create Item with Variant Mandatory.
        CreateItemWithVariantMandatory(Item, ItemVariant);

        // [GIVEN] Create Warehouse Item Journal Line for Warehouse Location.
        CreateWhseItemJnlLine(WarehouseJournalLine, Location, Item."No.");

        // [WHEN] Register Warehouse Item Journal Line.
        asserterror LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, true);

        // [THEN] Verify Error message
        Assert.ExpectedError(
            StrSubstNo(
                VariantCodeMandatoryErr,
                WarehouseJournalLine."Journal Template Name",
                WarehouseJournalLine."Journal Batch Name",
                WarehouseJournalLine."Location Code",
                WarehouseJournalLine."Line No."));
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Reservation III");
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Reservation III");

        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Reservation III");
    end;

    local procedure CalcRegenPlanAndCarryOutActionMsg(LocationCode: Code[10]; ItemNo: Code[20]): Code[20]
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));  // Dates based on WORKDATE.
        FindRequisitionLine(RequisitionLine, ItemNo, LocationCode);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
        exit(RequisitionLine."Ref. Order No.");
    end;

    local procedure CalculateWhseAdjustment(var ItemJournalBatch: Record "Item Journal Batch"; Item: Record Item; ItemNo: Code[20]; NoSeries: Boolean)
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        Item.Get(ItemNo);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        if NoSeries then begin
            ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
            ItemJournalBatch.Modify(true);
        end;
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
    end;

    local procedure CreateAndFindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateAndReserveSalesOrder(SalesLine);
        CreatePick(SalesLine."Location Code", SalesLine."Document No.");
        WarehouseActivityLine.SetRange("Source No.", SalesLine."Document No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure CreateAndPostWhseReceipt(var PurchaseLine: Record "Purchase Line")
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        CreateWarehouseLocation(Location);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, CreateAndModifyTrackedItem(false, false, true), Location.Code);  // Using Random Quantity.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure CreateAndReleaseSalesOrderWithITAndReserv(var SalesLine: Record "Sales Line"; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        TrackingOption: Option AssignSerialNo,SelectEntries;
    begin
        CreateSalesDocument(SalesLine, SalesLine.Type::Item, No, LocationCode, Quantity);
        UpdateSalesLineUnitPrice(SalesLine, LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());  // Enqueue values for Confirm Handlers.
        SalesLine.ShowReservation();
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseWhseShptFromSalesOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        SalesHeader.Get(SalesLine."Document Type", DocumentNo);
        CreateWarehouseShipment(SalesHeader."No.");
        FindWhseShptLine(WarehouseShipmentLine, SalesHeader."No.", SalesLine."Location Code");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        TrackingOption: Option AssignSerialNo,SelectEntries;
    begin
        CreatePurchaseOrder(PurchaseLine, LocationCode, ItemNo);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndRegisterWhseItemJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Location: Record Location;
        TrackingOption: Option AssignSerialNo,SelectEntries;
    begin
        CreateWarehouseLocation(Location);
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, '',
          Location."Cross-Dock Bin Code", WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
          CreateAndModifyTrackedItem(true, false, true), 1);  // Using 1 for Quantity because value is important for the case.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        WarehouseJournalLine.OpenItemTrackingLines();
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, true);
    end;

    local procedure CreateAndRegisterWhseItemJnlLineWithoutItemTracking(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, '',
          BinCode, WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
          ItemNo, Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationCode, true);
    end;

    local procedure CreateAndModifyTrackedItem(SNWarehouseTracking: Boolean; LotSpecific: Boolean; SerialSpecific: Boolean): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(LotSpecific, SerialSpecific, SNWarehouseTracking));
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostItemJnlLineWithIT(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Location: Record Location;
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        CreateWarehouseLocation(Location);
        CreateItemJnlLineWithTrackedItem(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, CreateAndModifyTrackedItem(false, false, true),
          Location.Code);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPosteItenJnlLine(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Location: Record Location;
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        CreateWarehouseLocation(Location);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", CreateItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        ModifyItemJnlLine(ItemJournalLine, Location.Code, LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Amount.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJnlLineQty(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostWhseRcpt(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        CreatePurchaseOrder(PurchaseLine, LocationCode, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure CreateAndReserveSalesOrder(var SalesLine: Record "Sales Line")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateAndPostItemJnlLineWithIT(ItemJournalLine);
        CreateAndReleaseSalesOrderWithITAndReserv(
          SalesLine, ItemJournalLine."Item No.", ItemJournalLine."Location Code", LibraryRandom.RandInt(10));  // Using Random Quantity.
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateWarehouseLocation(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        Location.Validate("Require Receive", true);
        Location.Validate("Always Create Pick Line", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 1));  // Using Random value for Unit Price.
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemJnlLineWithTrackedItem(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; ItemNo: Code[20]; LocationCode: Code[10])
    var
        TrackingOption: Option AssignSerialNo,SelectEntries;
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, JournalTemplateName, JournalBatchName, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo,
          LibraryRandom.RandInt(10 + 10));  // Using Random value for Quantity.
        ModifyItemJnlLine(ItemJournalLine, LocationCode, LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Amount.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(true);
    end;

    local procedure CreateItemTrackingCode(LotSpecific: Boolean; SerialSpecific: Boolean; SNWarehouseTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SerialSpecific, LotSpecific);
        ItemTrackingCode.Validate("SN Warehouse Tracking", SNWarehouseTracking);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreatePick(LocationCode: Code[10]; DocumentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        exit(WarehouseShipmentHeader."No.");
    end;

    local procedure CreatePickFromPickWkshPage(No: Code[20])
    var
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        PickWorksheet.OpenEdit();
        PickWorksheet.FILTER.SetFilter("Item No.", No);
        PickWorksheet.CreatePick.Invoke();
        PickWorksheet.OK().Invoke();
    end;

    local procedure CreatePickFromWhseInternalPickPage(LocationCode: Code[10])
    var
        WhseInternalPick: TestPage "Whse. Internal Pick";
    begin
        WhseInternalPick.OpenEdit();
        WhseInternalPick.FILTER.SetFilter("Location Code", LocationCode);
        WhseInternalPick.CreatePick.Invoke();
        WhseInternalPick.OK().Invoke();
    end;

    local procedure CreatePickUsingGetSourceDocWithWhseJournal(var SalesLine: Record "Sales Line"): Code[20]
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateAndRegisterWhseItemJnlLine(WarehouseJournalLine);
        Item.Get(WarehouseJournalLine."Item No.");
        CalculateWhseAdjustment(ItemJournalBatch, Item, WarehouseJournalLine."Item No.", true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        CreateAndReleaseSalesOrderWithITAndReserv(
          SalesLine, WarehouseJournalLine."Item No.", WarehouseJournalLine."Location Code", WarehouseJournalLine.Quantity);

        // Create Warehouse Shipment Header, Get Source Document, Release the Warehouse Shipment and create Pick.
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, SalesLine."Location Code");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        exit(WarehouseShipmentHeader."No.");
    end;

    local procedure CreatePutAwayFromWhseInternalPutAwayPage(LocationCode: Code[10])
    var
        WhseInternalPutAway: TestPage "Whse. Internal Put-away";
    begin
        WhseInternalPutAway.OpenEdit();
        WhseInternalPutAway.FILTER.SetFilter("Location Code", LocationCode);
        WhseInternalPutAway.CreatePutAway.Invoke();
        WhseInternalPutAway.OK().Invoke();
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));  // Taking Random value for Quantity.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Using Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePOAndWhseRcptUsingReqLine(var PurchaseLine: Record "Purchase Line"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        TemplateType: Option Planning;
    begin
        // Create and post Warehouse Receipt, create Sales Order with Reservation, creare Warehouse Shipment and Create Pick.
        CreateAndPostWhseReceipt(PurchaseLine);
        RegisterWarehouseActivity(PurchaseLine."Document No.", WarehouseActivityHeader.Type::"Put-away", PurchaseLine."Location Code");
        CreateAndReleaseSalesOrderWithITAndReserv(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
        CreatePick(SalesLine."Location Code", SalesLine."Document No.");

        // Create Vendor for Vendor Number on Requisition Line, create Requisition Line and Calculate Regenerative Plan and Carry Out Action Message.
        LibraryPurchase.CreateVendor(Vendor);
        CreateReqisitiontLine(
          RequisitionLine, TemplateType::Planning, PurchaseLine."No.", PurchaseLine."Location Code", Vendor."No.", PurchaseLine.Quantity,
          WorkDate());
        CalcRegenPlanAndCarryOutActionMsg(PurchaseLine."Location Code", PurchaseLine."No.");

        // Open Purchase Order created after Carry Out Action Message, Release Purchase Order and Create Warehouse Receipt.
        PurchaseHeader.SetRange("Buy-from Vendor No.", RequisitionLine."Vendor No.");
        PurchaseHeader.FindFirst();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        exit(SalesLine."Document No.");
    end;

    local procedure CreateReqisitiontLine(var RequisitionLine: Record "Requisition Line"; TemplateType: Option; No: Code[20]; LocationCode: Code[10]; VendorNo: Code[20]; Quantity: Integer; DueDate: Date)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        FindWorksheetTemplate(RequisitionWkshName, TemplateType);
        RequisitionLine.DeleteAll(true);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", No);
        RequisitionLine.Validate("Location Code", LocationCode);
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Validate("Due Date", DueDate);  // Required Due Date less Prod. Order Date.
        RequisitionLine.Validate("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.Validate("Starting Date", CalcDate('<-1D>', DueDate));  // Take 1 because Starting Date and Ending Date should be just less than 1day of Due Date.
        RequisitionLine.Validate("Ending Date", RequisitionLine."Starting Date");
        RequisitionLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderAndAssignItemCharge(var SalesLine2: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemChargeAssignmentOption: Option AssignmentOnly,GetShipmentLine;
    begin
        CreateSalesDocument(
          SalesLine2, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), '', 1);
        UpdateSalesLineUnitPrice(SalesLine2, LibraryRandom.RandDec(100, 2));  // Using Random value for Unit Price.

        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine2."Document No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Using Random value for Quantity.

        LibraryVariableStorage.Enqueue(ItemChargeAssignmentOption::AssignmentOnly);  // Enqueue value for ItemChargeAssignmentSalesPageHandler.
        SalesLine2.ShowItemChargeAssgnt();
        SalesLine.Validate("Qty. to Ship", 0);  // Set Quantity to Ship 0 for Item Line.
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSOReserveAndCreateWhseShpmt(var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, Type, No, LocationCode, Quantity);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        Location: Record Location;
        Location2: Record Location;
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateInTransitLocation(Location2);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationCode, Location.Code, Location2.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(1);  // Enqueue option value for ReservMenuHandler.
        TransferLine.ShowReservation();
    end;

    local procedure CreateWhseShptWithIT(var SalesLine: Record "Sales Line"; PurchaseLine: Record "Purchase Line"): Code[20]
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateAndReleaseSalesOrderWithITAndReserv(
          SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", PurchaseLine."Location Code");
        WarehouseShipmentHeader.Modify(true);
        exit(WarehouseShipmentHeader."No.");
    end;

    local procedure CreateWhseWkshName(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; Type: Enum "Warehouse Worksheet Template Type")
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, Type);
        WhseWorksheetTemplate.FindFirst();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    local procedure CreateWarehouseShipment(DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateWhseInternalPickHeader(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; LocationCode: Code[10]; ToZoneCode: Code[10]; ToBinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseInternalPickHeader(WhseInternalPickHeader, LocationCode);
        WhseInternalPickHeader.Validate("To Zone Code", ToZoneCode);
        WhseInternalPickHeader.Validate("To Bin Code", ToBinCode);
        WhseInternalPickHeader.Modify(true);
    end;

    local procedure CreateWhseInternalPutawayHeader(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; LocationCode: Code[10]; FromZonecode: Code[10]; FromBinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseInternalPutawayHdr(WhseInternalPutAwayHeader, LocationCode);
        WhseInternalPutAwayHeader.Validate("From Zone Code", FromZonecode);
        WhseInternalPutAwayHeader.Validate("From Bin Code", FromBinCode);
        WhseInternalPutAwayHeader.Modify(true);
    end;

    local procedure CreateWhseInternalPickLine(var SalesLine: Record "Sales Line"): Code[20]
    var
        Bin: Record Bin;
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        Zone: Record Zone;
        WhseInternalPickRelease: Codeunit "Whse. Internal Pick Release";
    begin
        // Create and reserve a Sales Order, find Zone, find Bin, create Warehouse Internal Pick and Release.
        CreateAndReserveSalesOrder(SalesLine);
        FindZone(Zone, SalesLine."Location Code");
        LibraryWarehouse.FindBin(Bin, SalesLine."Location Code", Zone.Code, 2);  // Find Bin for Zone with Bin Index 2.
        CreateWhseInternalPickHeader(WhseInternalPickHeader, SalesLine."Location Code", Zone.Code, Bin.Code);
        LibraryWarehouse.CreateWhseInternalPickLine(WhseInternalPickHeader, WhseInternalPickLine, SalesLine."No.", SalesLine.Quantity);
        WhseInternalPickRelease.Release(WhseInternalPickHeader);
        exit(WhseInternalPickHeader."No.");
    end;

    local procedure CreateWhseInternalPutAwayLine(var SalesLine: Record "Sales Line"): Code[20]
    var
        Bin: Record Bin;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        Zone: Record Zone;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseIntPutAwayRelease: Codeunit "Whse. Int. Put-away Release";
    begin
        // Create Sales Order with Item Tracking and Reservation, find Zone, find Bin, create Warehouse Internal Put Away and Release.
        CreateAndReserveSalesOrder(SalesLine);
        FindZone(Zone, SalesLine."Location Code");
        LibraryWarehouse.FindBin(Bin, SalesLine."Location Code", Zone.Code, 2);  // Find Bin for Zone with Bin Index 2.

        // Add this line due to one bug fixed in TFS49498.
        // Item should in Bin code so that put-away can be created from internal put-away from page.
        CreateAndRegisterWhseItemJnlLineWithoutItemTracking(WarehouseJournalLine, SalesLine."Location Code", Bin.Code, SalesLine."No.",
          LibraryRandom.RandInt(10) + 10); // Quantity should be greater than 10.

        CreateWhseInternalPutawayHeader(WhseInternalPutAwayHeader, SalesLine."Location Code", Zone.Code, Bin.Code);
        LibraryWarehouse.CreateWhseInternalPutawayLine(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, SalesLine."No.", SalesLine.Quantity);
        WhseIntPutAwayRelease.Release(WhseInternalPutAwayHeader);
        exit(Bin.Code);
    end;

    local procedure MockPairedReservationEntries(var ReservEntry: Record "Reservation Entry"; SourceType: Integer)
    var
        PairedReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.Init();
        ReservEntry."Entry No." := LibraryUtility.GetNewRecNo(ReservEntry, ReservEntry.FieldNo("Entry No."));
        ReservEntry.Positive := false;
        ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Reservation;
        ReservEntry."Item No." := LibraryUtility.GenerateGUID();
        ReservEntry."Location Code" := LibraryUtility.GenerateGUID();
        ReservEntry."Quantity (Base)" := -LibraryRandom.RandIntInRange(11, 20);
        ReservEntry.SetSource(DATABASE::"Sales Line", 0, LibraryUtility.GenerateGUID(), LibraryRandom.RandInt(10), '', 0);
        ReservEntry.Insert();

        PairedReservEntry := ReservEntry;
        PairedReservEntry.Positive := not PairedReservEntry.Positive;
        PairedReservEntry."Quantity (Base)" *= -1;
        PairedReservEntry.SetSource(SourceType, 0, '', LibraryRandom.RandInt(10), '', 0);
        PairedReservEntry.Insert();
    end;

    local procedure MockPickLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ReservEntry: Record "Reservation Entry")
    begin
        WarehouseActivityLine.Init();
        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Pick;
        WarehouseActivityLine."No." := LibraryUtility.GenerateGUID();
        WarehouseActivityLine."Line No." := LibraryUtility.GetNewRecNo(WarehouseActivityLine, WarehouseActivityLine.FieldNo("Line No."));
        WarehouseActivityLine.SetSource(
          ReservEntry."Source Type", ReservEntry."Source Subtype", ReservEntry."Source ID",
          ReservEntry."Source Ref. No.", 0);
        WarehouseActivityLine."Qty. Outstanding (Base)" := LibraryRandom.RandInt(10);
        WarehouseActivityLine.Insert();
    end;

    local procedure DeleteSalesLine(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindLast();  // Using Findlast to delete the last line of Sales Order because value is not important for the test.
        SalesLine.Delete(true);
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20]; LocationCode: Code[10])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.FindFirst();
    end;

    local procedure FindWorksheetTemplate(var RequisitionWkshName: Record "Requisition Wksh. Name"; TemplateType: Option)
    begin
        RequisitionWkshName.SetRange("Template Type", TemplateType);
        RequisitionWkshName.SetRange(Recurring, false);
        RequisitionWkshName.FindFirst();
    end;

    local procedure FindWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20]; LocationCode: Code[10])
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.SetRange("Location Code", LocationCode);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type"): Code[20]
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindLast();  // Using Findlast to take value from last line of Activity Type.
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

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, ActivityType, LocationCode, ActionType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindWhseWkshLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        WhseWorksheetLine.SetRange("Item No.", ItemNo);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[20])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.FindFirst();
    end;

    local procedure GetWhseDocFromPickWksh()
    var
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        PickWorksheet.OpenEdit();
        PickWorksheet."Get Warehouse Documents".Invoke();
        PickWorksheet.OK().Invoke();
    end;

    [Scope('OnPrem')]
    procedure GetWhseShpmtBySONo(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesOrderNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SalesOrderNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure ModifyItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10]; UnitAmount: Decimal)
    begin
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure PostWhseRcptAndCreateWhseShpt(var PurchaseLine: Record "Purchase Line"): Code[20]
    var
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Create and post Warehouse Receipt, create Sales Order with Reservation and creare Warehouse Shipment.
        CreateAndPostWhseReceipt(PurchaseLine);
        RegisterWarehouseActivity(PurchaseLine."Document No.", WarehouseActivityHeader.Type::"Put-away", PurchaseLine."Location Code");
        CreateAndReleaseSalesOrderWithITAndReserv(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
        CreateAndReleaseWhseShptFromSalesOrder(WarehouseShipmentHeader, SalesLine, SalesLine."Document No.");
        exit(SalesLine."Document No.");
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(FindWarehouseReceiptNo(SourceDocument, SourceNo));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostSalesOrder(DocumentType: Enum "Sales Document Type"; No: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, No);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure ReservOnSalesOrderUsingPO(var SalesLine: Record "Sales Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseLine, '', CreateItem());
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateSalesDocument(SalesLine, SalesLine.Type::Item, PurchaseLine."No.", '', PurchaseLine.Quantity);
        SalesLine.ShowReservation();
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityHeader.SetRange(
          "No.",
          FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, ActivityType, LocationCode, WarehouseActivityLine."Action Type"::Place));
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterWhseActivityAndCreateWkshLine(var PurchaseLine: Record "Purchase Line")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        // Create Location, Purchase and Sales Order with Item Tracking, Create and Register Warehouse Activity.
        PostWhseRcptAndCreateWhseShpt(PurchaseLine);
        CreateWhseWkshName(WhseWorksheetName, PurchaseLine."Location Code", WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.CreateWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, PurchaseLine."Location Code",
          WhseWorksheetTemplate.Type::Pick);
        WhseWorksheetLine.Validate("Item No.", PurchaseLine."No.");
        WhseWorksheetLine.Validate(Quantity, PurchaseLine.Quantity);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure RunOrderTracking(PurchaseLine: Record "Purchase Line")
    begin
        LibraryVariableStorage.Enqueue(OrderTrackingMessage);  // Enqueue for Message Handler.
        PurchaseLine.ShowOrderTracking();
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure UpdateSalesLineUnitPrice(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure VerifyWarehouseEntries(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::"Positive Adjmt.");
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField(Quantity, Quantity);
        WarehouseEntry.TestField("Qty. (Base)", Quantity);
    end;

    local procedure VerifyWhseActivityLine(ActivityType: Enum "Warehouse Activity Type"; SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, SourceNo, WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Qty. to Handle", Quantity);
    end;

    local procedure VerifyWkshLine(ItemNo: Code[20]; Quantity: Decimal; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindWhseWkshLine(WhseWorksheetLine, ItemNo, LocationCode);
        WhseWorksheetLine.TestField(Quantity, Quantity);
        WhseWorksheetLine.TestField("Qty. to Handle", Quantity);
        WhseWorksheetLine.TestField("Source No.", SourceNo);
    end;

    local procedure VerifyWarehouseShipmentLine(ItemNo: Code[20]; SourceNo: Code[20]; Quantity: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField(Quantity, Quantity);
        WarehouseShipmentLine.TestField("Qty. Outstanding (Base)", Quantity);
    end;

    local procedure CreateItemWithVariantMandatory(var Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Yes);
        Item.Modify(true);

        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
    end;

    local procedure CreateWhseItemJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var Location: Record Location; ItemNo: Code[20])
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        CreateWarehouseLocation(Location);
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.SelectWhseJournalBatchName(WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
            WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name",
            WarehouseJournalBatch.Name, Location.Code, '',
            Location."Cross-Dock Bin Code", WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
            ItemNo, LibraryRandom.RandInt(10));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentReportHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantitytoCreatePageHandler(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantitytoCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandlerForItemNo(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        EnterQuantitytoCreate.ItemNo.AssertEquals(ItemNo);
        EnterQuantitytoCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    var
        OptionValue: Variant;
        OptionString: Option AssignmentOnly,GetShipmentLine;
        ItemChargeAssignmentOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        ItemChargeAssignmentOption := OptionValue;  // To convert Variant into Option.
        case ItemChargeAssignmentOption of
            OptionString::AssignmentOnly:
                begin
                    ItemChargeAssignmentSales.First();
                    repeat
                        ItemChargeAssignmentSales."Qty. to Assign".SetValue(1);  // Added Qty. to Assign as 1 for Item Charge.
                    until not ItemChargeAssignmentSales.Next();
                end;
            OptionString::GetShipmentLine:
                begin
                    ItemChargeAssignmentSales.GetShipmentLines.Invoke();
                    ItemChargeAssignmentSales."Qty. to Assign".SetValue(1);  // Added Qty. to Assign as 1 for Item Charge.
                    ItemChargeAssignmentSales.RemAmountToAssign.SetValue(0);
                end;
        end;
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        OptionValue: Variant;
        OptionString: Option AssignSerialNo,SelectEntries,AssignLotNo,SetValues;
        TrackingOption: Option;
        TrackingQuantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        TrackingOption := OptionValue;  // To convert Variant into Option.
        case TrackingOption of
            OptionString::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            OptionString::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            OptionString::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            OptionString::SetValues:
                begin
                    TrackingQuantity := ItemTrackingLines.Quantity3.AsDecimal();
                    ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
                    ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity / 2);  // Using half value to assign the Quantity equally in both the ITem Tracking Line.
                    ItemTrackingLines.Next();
                    ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
                    ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity / 2);  // Using half value to assign the Quantity equally in both the ITem Tracking Line.
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationFromCurrentLineHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ReservMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        OptionCount: Variant;
    begin
        LibraryVariableStorage.Dequeue(OptionCount);  // Dequeue variable.
        Choice := OptionCount;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentLinePageHandler(var SalesShipmentLines: TestPage "Sales Shipment Lines")
    begin
        SalesShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        OptionValue: Variant;
        OptionString: Option AssignSerialNo,SelectEntries;
        TrackingOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        TrackingOption := OptionValue;  // To convert Variant into Option.
        case TrackingOption of
            OptionString::AssignSerialNo:
                begin
                    WhseItemTrackingLines."Serial No.".SetValue(LibraryUtility.GenerateGUID());
                    WhseItemTrackingLines.Quantity.SetValue(1);  // Using 1 because value is important.
                end;
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionPageHandler(var PickSelection: TestPage "Pick Selection")
    begin
        PickSelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PutAwaySelectionPageHandler(var PutAwaySelection: TestPage "Put-away Selection")
    begin
        PutAwaySelection.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickPageHandler(var CreatePick: TestRequestPage "Create Pick")
    begin
        CreatePick.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AvailConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Control: Variant;
        QtyVar: Variant;
        QtyDec: Decimal;
        Option: Option CallingFromPO,CallingFromTO;
        QtyTxt: Text;
    begin
        LibraryVariableStorage.Dequeue(Control);
        Option := Control;

        case Option of
            ItemTrackingLinesControl::CallingFromPO:
                begin
                    // Assign Lot No. to the yet untracked quantity
                    QtyTxt := ItemTrackingLines.Quantity3.Value();
                    Evaluate(QtyDec, QtyTxt);
                    ItemTrackingLines."Lot No.".SetValue(LotNoTC324960Tok);
                    ItemTrackingLines."Quantity (Base)".SetValue(QtyDec);
                    ItemTrackingLines.OK().Invoke();
                end;
            ItemTrackingLinesControl::CallingFromTO:
                begin
                    // Set quantity and Lot No. to track
                    LibraryVariableStorage.Dequeue(QtyVar);
                    ItemTrackingLines."Quantity (Base)".SetValue(QtyVar);
                    ItemTrackingLines."Lot No.".SetValue(LotNoTC324960Tok);
                    ItemTrackingLines.OK().Invoke();
                end;
            else
                Error(InvalidControlErr);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.AvailableToReserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableToReserveHandler(var AvailablePurchaseLines: TestPage "Available - Purchase Lines")
    begin
        AvailablePurchaseLines.Reserve.Invoke();
    end;
}

