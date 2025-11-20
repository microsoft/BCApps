codeunit 137059 "SCM RTAM Item Tracking-II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Tracking] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        LocationYellow2: Record Location;
        LocationYellow: Record Location;
        LocationSilver: Record Location;
        LocationBlue: Record Location;
        LocationWhite: Record Location;
        LocationIntransit: Record Location;
        ItemTrackingCodeSerialSpecificWithWarehouse: Record "Item Tracking Code";
        ItemTrackingCodeSerialSpecific: Record "Item Tracking Code";
        ItemTrackingCodeLotSpecific: Record "Item Tracking Code";
        ItemTrackingCodeLotSpecificWithWarehouse: Record "Item Tracking Code";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        UpdateTracking: Boolean;
        CreateNewLotNo: Boolean;
        PartialTracking: Boolean;
        ItemTrackingSummaryCancel: Boolean;
        AssignTracking: Option "None",SerialNo,LotNo,SelectTrackingEntries,GivenLotNo,GetQty;
        ItemTrackingAction: Option "None",AvailabilitySerialNo,AvailabilityLotNo;
        TrackingQuantity: Decimal;
        MessageCounter: Integer;
        NumberOfLineEqualError: Label 'Number of Lines must be same.';
        GlobalDocumentNo: Code[20];
        SynchronizeItemTracking: Label 'Do you want to synchronize item tracking on the line with item tracking on the related drop shipment sales order line?';
        AvailabilityWarnings: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        SynchronizationCancelled: Label 'Synchronization cancel';
        ItemTrackingNotMatch: Label 'Item Tracking does not match.';
        PostPurchaseOrderError: Label 'You cannot invoice this purchase order before the associated sales orders have been invoiced. Please invoice sales order %1 before invoicing this purchase order.';
        GlobalItemNo: Code[20];
        QuantityBase: Decimal;
        WarehouseActivityLineError: Label 'There is no Warehouse Activity Line within the filter.';
        NosOfLineError: Label 'Nos of Line must be same.';
        PickActivityCreated: Label 'Pick activity no. ';
        PutAwayActivityCreated: Label 'Put-away activity no. ';
        MovementActivityCreated: Label 'Movement activity no';
        TransferOrderDeleted: Label 'was successfully posted and is now deleted.';
        SerialNoError: Label 'Serial No does not exist.';
        LotNoError: Label 'Lot No does not exist.';
        WhseItemTrackingNotEnabledError: Label 'Warehouse item tracking is not enabled for No. %1.';
        PostJournalLines: Label 'Do you want to post the journal lines?';
        JournalLinesSuccessfullyPosted: Label 'The journal lines were successfully posted.';
        SerialNumberRequiredError: Label 'You must assign a serial number for item %1.', Comment = '%1 - Item No.';
        SerialNoValueError: Label 'Serial No. must have a value in Warehouse Activity Line';
        ValueNotEqual: Label 'The Cost Amount(Actual) is not equal to Amount';
        ItemTracingOutputErr: Label 'There is no Parent Item Output Entry on Item Tracing Page.';
        IncorrectShippedQtyMsg: Label '%1 is not equal to %2 of the original Sales Line.', Comment = '%1: Field(Quantity Shipped), %2: Field(Qty. to Ship)';
        RemainingQtyMustBeEqualErr: Label 'Remaining Qty must be equal to %1 in %2', Comment = '%1 = Expected Value , %2 = Table Caption';

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,SalesListPageHandler,ItemTrackingConfirmHandler,SynchronizeMessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithDropShipmentSerialNoSynchronizationError()
    begin
        // Setup.
        Initialize();
        PurchaseOrderWithDropShipmentSerialNo(false);  // Post Sales Order -False.
    end;

    local procedure PurchaseOrderWithDropShipmentSerialNo(PostSalesOrder: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Create Item with Serial Specific Tracking Code, Create Sales Order with Purchasing Code, Create Purchase Order and Drop Shipment.
        Quantity := 10 * LibraryRandom.RandInt(5);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", '', Quantity, false);  // Multiple line as False.

        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Assign Tracking as SerialNo.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingDropShipmentPageHandler.
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, 0);  // Assign Global variable for Page Handler. PartialTracking as True.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Update Tracking on Page Handler ItemTrackingDropShipmentPageHandler.

        if PostSalesOrder then begin
            PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, false);
            // Exercise.
            asserterror PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);
            // Verify: Verify Error for Posting Purchase Invoice without Post Sales with Invoice Option.
            Assert.ExpectedError(StrSubstNo(PostPurchaseOrderError, SalesHeader."No."));
        end else begin
            // Exercise.
            asserterror PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", true, false);
            // Verify: Verify Error for Posting Purchase Invoice for cancelled Synchronization message.
            Assert.ExpectedError(ItemTrackingNotMatch);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,SalesListPageHandler,AvailabilityConfirmHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithDropShipmentPartialChangedSerialNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Tracking Code, Create Sales Order with Purchasing Code, Create Purchase Order and Drop Shipment.
        Initialize();
        Quantity := 10 * LibraryRandom.RandInt(5);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", '', Quantity, false);  // Multiple line as False.

        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Assign Tracking as SerialNo.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingDropShipmentPageHandler.
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, 0);  // Assign Global variable for Page Handler. PartialTracking as True.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Update Tracking on Page Handler ItemTrackingDropShipmentPageHandler.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, false);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, true, false, AssignTracking::None, Quantity / 2);  // UpdateTracking as True and Tracking Quantity.
        ItemTrackingAction := ItemTrackingAction::AvailabilitySerialNo;

        SalesLine.OpenItemTrackingLines();  // Change Tracking on Page Handler ItemTrackingDropShipmentPageHandler.
        UpdateQtyToInvoiceOnSalesLine(SalesHeader."No.", Quantity / 2);  // Partial Qty to Invoice.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", false, true);
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Change Tracking line on page handler ItemTrackingDropShipmentPageHandler.
        UpdateQtyToInvoiceOnPurchaseLine(PurchaseHeader."No.", Quantity / 2);  // Update Quantity to Invoice Partially on Purchase Order.

        // Exercise: Post Purchase Order as Invoice.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // Verify: Verify Serial No in Posted Sales Invoice and Purchase Invoice.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.");
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,SalesListPageHandler,QuantityToCreatePageHandler,SynchronizeItemTrackingConfirmHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithMultipleLinesDropShipmentSerialNo()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Setup: Create Items with Tracking Code, Create Sales Order with two Lines with Purchasing Code, Create Purchase Order and Drop Shipment.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateItem(Item2, ItemTrackingCodeSerialSpecific.Code);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", Item2."No.", Quantity, true);  // Multiple line as True.
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Assign Tracking as SerialNo.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking line on page handler ItemTrackingDropShipmentPageHandler.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", true, false);
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", false, true);

        // Exercise: Post Purchase Order as Invoice.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // Verify: Verify Serial No in Posted Sales Invoice and Purchase Invoice.
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.");
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,SalesListPageHandler,SynchronizeItemTrackingConfirmHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithDropShipmentPartialLotNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Tracking Code, Create Sales Order with Purchasing Code, Create Purchase Order and Drop Shipment.
        Initialize();
        Quantity := 10 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeLotSpecific.Code);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", '', Quantity, false);  // Multiple line as false.
        QuantityBase := Quantity;  // Assign Global Variable for Page Handler.
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::LotNo, 0);  // Assign Global variable for Page Handler. Assign Tracking as Lot No.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking line on page handler ItemTrackingDropShipmentPageHandler.

        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, Quantity / 2);  // Assign Global variable for Page Handler. PartialTracking as True and Tracking Quantity.
        ItemTrackingAction := ItemTrackingAction::AvailabilityLotNo;  // Assign Global variable for Page Handler.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking line on page handler ItemTrackingDropShipmentPageHandler.
        SelectSalesLine(SalesLine, SalesHeader."No.");
        UpdateQtyToShipOnSalesLine(SalesLine, Quantity / 2);  // Partial Quantity for ship.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, false);

        SetGlobalValue(Item."No.", false, true, false, AssignTracking::None, Quantity / 2);  // Assign Global variable for Page Handler. Update Tracking as True and Tracking Quantity.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, false);
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", false, true);

        // Exercise: Post Purchase Order as Invoice.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // Verify: Verify Lot No in Posted Sales Invoice and Purchase Invoice.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::LotNo, 0);
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.");
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,SalesListPageHandler,SynchronizeItemTrackingConfirmHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithDropShipmentItemLotNoAndOrderTrackingPolicy()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 475023] For Drop Shipment Purchase Order, when setting Lot No and want to sync tracking with related sales lines, system freezes  
        Initialize();

        // [GIVEN] New item with LOT tracking and Order Tracking Policy = Lot-for-Lot and Order Tracking Policy = Tracking & Action Msg.
        CreateItem(Item, ItemTrackingCodeLotSpecific.Code);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item."Order Tracking Policy" := Item."Order Tracking Policy"::"Tracking & Action Msg.";
        Item.Modify();

        // [GIVEN] several existing  released Sales Orders.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", '', 1, false);
        Clear(SalesHeader);
        Clear(SalesLine);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", '', 2, false);
        Clear(SalesHeader);
        Clear(SalesLine);

        // [GIVEN] Item on stock - Item Journal with positive adjustment.
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", '', 100, 0, AssignTracking::LotNo);

        // [GIVEN] Sales Order with new item and purchasing code.
        Quantity := 10 * LibraryRandom.RandInt(10);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", '', Quantity, false);  // Multiple line as false.
        QuantityBase := Quantity;  // Assign Global Variable for Page Handler.

        // [GIVEN] Purchase Order with Drop Shipment.
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::LotNo, 0);  // Assign Global variable for Page Handler. Assign Tracking as Lot No.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking line on page handler ItemTrackingDropShipmentPageHandler.

        // [GIVEN] Post Sales Order.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, false);
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", false, true);

        // [WHEN] Post Purchase Order as Invoice.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // [THEN] Verify Lot No in Posted Sales Invoice and Purchase Invoice.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::LotNo, 0);
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.");
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,SalesListPageHandler,QuantityToCreatePageHandler,SynchronizeItemTrackingConfirmHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithMultipleLinesDropShipmentPartialSerialNoLotNo()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // Setup: Create Items with Tracking Code, Create Sales Order with Purchasing Code, Create Purchase Order and Drop Shipment.
        Initialize();
        Quantity := 10 * LibraryRandom.RandInt(5);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateItem(Item2, ItemTrackingCodeSerialSpecific.Code);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", Item2."No.", Quantity, true);  // Multiple line as True.
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True and assign Tracking as SerialNo.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");

        SetGlobalValue(Item."No.", true, false, true, AssignTracking::None, Quantity / 2);  // Create New Lot as True,PartialTracking - True and Tracking Quantity.
        ItemTrackingAction := ItemTrackingAction::AvailabilitySerialNo;  // Assign Global variable for Page Handler.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Tracking on Page handler ItemTrackingDropShipmentPageHandler.
        UpdateQuantityToReceiveOnMultiplePurchaseLines(PurchaseLine, PurchaseHeader."No.", Quantity / 2);  // Partial Quantity.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", true, false);

        // Exercise: Post Purchase Order and Sales Order as Invoice.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", false, true);
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // Verify: Verify Serial No in Posted Sales Invoice and Purchase Invoice.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.");
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,AvailabilityConfirmHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionWorksheetWithDropShipmentSerialNo()
    var
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Tracking Code, Create Sales Order with Purchasing Code, Drop Shipment for Sales Line on Requisition Worksheet.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", '', Quantity, false);

        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Assign Tracking as SerialNo.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingDropShipmentPageHandler.
        GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(SalesLine, RequisitionLine, false);  // Drop Shipment On Requisition Line.
        FindPurchaseHeader(PurchaseHeader, Item."No.");
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise: Post Purchase Order as Invoice and Sales Order with Ship and Invoice Option.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // Verify: Verify Serial No in Posted Sales Invoice and Purchase Invoice.
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.");
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,SynchronizeItemTrackingConfirmHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionWorksheetWithDropShipmentForMultipleLinesSerialNo()
    var
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Tracking Code, Create Sales Order with Purchasing Code on multiple Lines, Drop Shipment for Sales Line on Requisition Worksheet.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", Item."No.", Quantity, true);

        GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(SalesLine, RequisitionLine, false);  // Drop Shipment On Requisition Line.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Assign Tracking as SerialNo.
        FindPurchaseHeader(PurchaseHeader, Item."No.");
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking on Page Handler ItemTrackingDropShipmentPageHandler.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", true, false);
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);  // Post with Ship and Invoice option.
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);  // Update Vendor Invoice No On Purchase order created.

        // Exercise: Post Purchase Order with Invoice option.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // Verify: Verify Serial No in Posted Sales Invoice and Purchase Invoice.
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.");
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,SynchronizeItemTrackingConfirmHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionWorksheetWithDropShipmentPartialLotNo()
    var
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Tracking Code, Create Sales Order with Purchasing Code on multiple Lines, Drop Shipment for Sales Line on Requisition Worksheet.
        Initialize();
        Quantity := 10 * LibraryRandom.RandInt(5);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeLotSpecific.Code);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", '', Quantity, false);
        GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(SalesLine, RequisitionLine, false);  // Drop Shipment On Requisition Line.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::LotNo, 0);  // Assign Global variable for Page Handler. Assign Tracking as LotNo.
        FindPurchaseHeader(PurchaseHeader, Item."No.");
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking on Page Handler ItemTrackingDropShipmentPageHandler.

        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, Quantity / 2);  // PartialTracking as True and Tracking Quantity.
        ItemTrackingAction := ItemTrackingAction::AvailabilityLotNo;  // Assign Global variable for Page Handler.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");
        SelectSalesLine(SalesLine, SalesHeader."No.");
        UpdateQtyToShipOnSalesLine(SalesLine, Quantity / 2);  // Partial Quantity to ship.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, false);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise: Post Purchase Order and Sales Order with Invoice Option.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", false, true);
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // Verify: Verify Lot No in Posted Sales Invoice and Purchase Invoice.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::LotNo, 0);
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.");
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,SynchronizeItemTrackingConfirmHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionWorksheetWithDropShipmentForMultipleLinesPartialSerialNoLotNo()
    var
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Tracking Code, Create Sales Order with Purchasing Code on multiple Lines, Drop Shipment for Sales Line on Requisition Worksheet.
        Initialize();
        Quantity := 10 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", Item."No.", Quantity, true);
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True and assign Tracking as SerialNo.
        GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(SalesLine, RequisitionLine, true);  // Drop Shipment On Requisition Line and Assign Serial No.
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, Quantity / 2);  // Assign Global variable for Page Handler. PartialTracking as True and Tracking Quantity.
        ItemTrackingAction := ItemTrackingAction::AvailabilitySerialNo;  // Assign Global variable for Page Handler.
        FindPurchaseHeader(PurchaseHeader, Item."No.");
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");

        FindPurchaseHeader(PurchaseHeader, Item."No.");
        UpdateQuantityToReceiveOnMultiplePurchaseLines(PurchaseLine, PurchaseHeader."No.", Quantity / 2);
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", true, false);  // Partially Receive.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", true, false);
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // Exercise: Post Purchase Orders with Invoice option.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // Verify: Verify Serial No in Posted Sales Invoice and Purchase Invoice.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.");
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PickSelectionPageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentPartialPickFromPickWorksheetSerialLotNo()
    begin
        // Setup.
        Initialize();
        PickFromPickWorksheetSerialLotNo(true);  // Partial Pick - True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PickSelectionPageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentPickFromPickWorksheetSerialLotNo()
    begin
        // Setup.
        Initialize();
        PickFromPickWorksheetSerialLotNo(false);  // Partial Pick - False.
    end;

    local procedure PickFromPickWorksheetSerialLotNo(PartialPick: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        Quantity: Decimal;
    begin
        // Create Item with SN Specific, Post Warehouse Receipt from Purchase Order with Tracking, Warehouse Shipment form Sales Order with Tracking, Create and Register Pick from Pick Worksheet.
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True,Assign Tracking as SerialNo.
        CreateAndPostWarehouseReceiptFromPurchaseOrderWithTracking(
          PurchaseHeader, WarehouseReceiptHeader, Item."No.", LocationWhite.Code, Quantity, true, false);  // Post Receipt as True.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SelectTrackingEntries, 0);  // Assign Global variable for Page Handler. Assign Tracking as SelectTrackingEntries.
        CreateAndReleaseWhseShipmentFromSalesOrderWithTracking(
          SalesHeader, WarehouseShipmentHeader, Item."No.", LocationWhite.Code, Quantity, true);  // Tracking as True.
        GlobalDocumentNo := WarehouseShipmentHeader."No.";  // Assign Global variable for Page Handler.

        CreateWhseWorksheetName(WhseWorksheetName, LocationWhite.Code, WhseWorksheetTemplate.Type::Pick);
        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationWhite.Code);
        if PartialPick then begin
            UpdateQtyToHandleCreateAndRegisterPickFromPickWorksheet(
              WhseWorksheetLine, WhseWorksheetName, SalesHeader."No.", Item."No.", LocationWhite.Code, Quantity / 2);  // Partial.
            UpdateQtyToHandleCreateAndRegisterPickFromPickWorksheet(
              WhseWorksheetLine, WhseWorksheetName, SalesHeader."No.", Item."No.", LocationWhite.Code, Quantity / 2);  // Partial.
            SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, Quantity / 2);  // Assign Global variable for Page Handler. PartialTracking as True and Tracking Quantity.
            ItemTrackingAction := ItemTrackingAction::AvailabilitySerialNo;  // Assign Global variable for Page Handler.
            UpdateQtyToShipAndPostWhseShipment(WarehouseShipmentHeader, SalesHeader."No.", Quantity / 2);  // Partial Shipment Posting.
        end else begin
            FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationWhite.Code);
            LibraryWarehouse.CreatePickFromPickWorksheet(
              WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
              LocationWhite.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
            RegisterWarehouseActivity(
              SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order", LocationWhite.Code, Item."No.",
              WarehouseActivityLine."Activity Type"::Pick, true);
        end;
        SelectWarehouseShipmentLine(WarehouseShipmentLine, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");

        // Exercise.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify Tracking line on Posted Sales Shipments.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);
        VerifyTrackingOnSalesShipment(SalesHeader."No.", PartialPick);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,WhseSourceCreateDocumentReportHandler,WarehouseActivityMessageHandler')]
    [Scope('OnPrem')]
    procedure MovementAndPickFromInternalPickSerialLotNo()
    var
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        Bin: Record Bin;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Setup: Create Item with SN Specific, Production Order and Post Output with Tracking, Create Internal Put-away, Create and Register Put-away, Movement and Create Internal Pick.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True,Assign Tracking as SerialNo.

        Bin.Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");
        CreateProductionOrderAndPostOutputJournalWithTracking(ProductionOrder, Item."No.", LocationWhite.Code, Bin.Code, Quantity);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, Quantity);  // Tracking Quantity.
        CreateWhseInternalPutawayWithTracking(WhseInternalPutAwayLine, Bin."Zone Code", Bin.Code, Item."No.", Quantity, true);  // Tracking as True.
        CreatePutAwayDocAndRegisterWarehouseActivity(WhseInternalPutAwayLine, WarehouseActivityLine, Item."No.", LocationWhite.Code, true);  // Register Activity as True.

        CreateWhseWorksheetName(WhseWorksheetName, LocationWhite.Code, WhseWorksheetTemplate.Type::Movement);
        CreateMovementFormMovementWorkSheet(WhseWorksheetName, WarehouseActivityLine, Item."No.", LocationWhite.Code, Quantity);
        RegisterWarehouseActivity(
          WhseWorksheetName."Worksheet Template Name", WarehouseActivityLine."Source Document"::" ", LocationWhite.Code, Item."No.",
          WarehouseActivityLine."Activity Type"::Movement, false);  // AutoFillQuantity as False.

        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        CreateWhseInternalPick(WhseInternalPickHeader, WhseInternalPickLine, Bin."Zone Code", Bin.Code, Item."No.", Quantity, true);  // Tracking as True.

        // Exercise.
        WhseInternalPickLine.CreatePickDoc(WhseInternalPickLine, WhseInternalPickHeader);

        // Verify: Verify Serial and Lot No on Warehouse Activity Line.
        VerifyWarehouseActivityLine(
          WhseInternalPickHeader."No.", WarehouseActivityLine."Source Document"::" ", LocationWhite.Code, Item."No.", Quantity,
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,PutAwaySelectionPageHandler,WhseSourceCreateDocumentReportHandler,PickSelectionPageHandler,WarehouseActivityMessageHandler')]
    [Scope('OnPrem')]
    procedure MovementAndPickFromPickWorksheetSerialLotNo()
    begin
        // Setup.
        Initialize();
        MovementAndPickFromPickWorksheet(false);  // Delete Pick as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,PutAwaySelectionPageHandler,WhseSourceCreateDocumentReportHandler,PickSelectionPageHandler,WarehouseActivityMessageHandler')]
    [Scope('OnPrem')]
    procedure MovementAndPickFromPickWorksheetRecreatePickSerialLotNo()
    begin
        // Setup.
        Initialize();
        MovementAndPickFromPickWorksheet(true);  // Delete Pick as True.
    end;

    local procedure MovementAndPickFromPickWorksheet(DeletePick: Boolean)
    var
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        Bin: Record Bin;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Create Item with SN Specific, Production Order and Post Output with Tracking,Create Internal Put-away,Create Put-away for worksheet,Create Movement,Internal Pick and Create Pick for Pick Worksheet.
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True,Assign Tracking as SerialNo.
        Bin.Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");

        CreateProductionOrderAndPostOutputJournalWithTracking(ProductionOrder, Item."No.", LocationWhite.Code, Bin.Code, Quantity);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, Quantity);  // Tracking Quantity.
        CreateWhseInternalPutawayWithTracking(WhseInternalPutAwayLine, Bin."Zone Code", Bin.Code, Item."No.", Quantity, false);  // Tracking as False.
        GlobalDocumentNo := WhseInternalPutAwayLine."No.";  // Assign Global variable for Page Handler.

        CreatePutAwayFromPutAwayWorksheet(WarehouseActivityLine, LocationWhite.Code, Item."No.", true);  // Tracking as True.
        RegisterWarehouseActivity(
          '', WarehouseActivityLine."Source Document"::" ", LocationWhite.Code, Item."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", false);  // AutoFillQuantity as False.
        CreateWhseWorksheetName(WhseWorksheetName, LocationWhite.Code, WhseWorksheetTemplate.Type::Movement);
        CreateMovementFormMovementWorkSheet(WhseWorksheetName, WarehouseActivityLine, Item."No.", LocationWhite.Code, Quantity);
        RegisterWarehouseActivity(
          WhseWorksheetName."Worksheet Template Name", WarehouseActivityLine."Source Document"::" ", LocationWhite.Code, Item."No.",
          WarehouseActivityLine."Activity Type"::Movement, false);  // AutoFillQuantity as False.

        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        CreateWhseInternalPick(WhseInternalPickHeader, WhseInternalPickLine, Bin."Zone Code", Bin.Code, Item."No.", Quantity, false);
        GlobalDocumentNo := WhseInternalPickHeader."No.";  // Assign Global variable for Page Handler.
        CreateWhseWorksheetName(WhseWorksheetName, LocationWhite.Code, WhseWorksheetTemplate.Type::Pick);

        // Exercise: Create Pick from Pick Worksheet, Delete Pick and Recreate.
        CreatePickFromPickWorksheet(WhseWorksheetName, LocationWhite.Code, Item."No.", true);  // Tracking as True.
        if DeletePick then begin
            FindWarehouseActivityHeader(
              WarehouseActivityHeader, '', WarehouseActivityLine."Source Document"::" ", LocationWhite.Code, Item."No.",
              WarehouseActivityLine."Activity Type"::Pick);
            WarehouseActivityHeader.Delete(true);
            CreatePickFromPickWorksheet(WhseWorksheetName, LocationWhite.Code, Item."No.", false);
        end;

        // Verify: Verify Serial and Lot No on Warehouse Activity Line.
        VerifyWarehouseActivityLine(
          '', WarehouseActivityLine."Source Document"::" ", LocationWhite.Code, Item."No.", Quantity,
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,WhseSourceCreateDocumentReportHandler,PutAwaySelectionPageHandler,PutAwayActivityMessageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayFromPutAwayWorksheetRecreatePutAwaySerialLotNo()
    var
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        Bin: Record Bin;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Setup: Create Item with SN Specific, Production Order and Post Output with Tracking, Create Internal Put-away, Create Movement and Delete Put-away.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True,Assign Tracking as SerialNo.

        Bin.Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");
        CreateProductionOrderAndPostOutputJournalWithTracking(ProductionOrder, Item."No.", LocationWhite.Code, Bin.Code, Quantity);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, Quantity);  // Tracking Quantity.
        CreateWhseInternalPutawayWithTracking(WhseInternalPutAwayLine, Bin."Zone Code", Bin.Code, Item."No.", Quantity, true);  // Tracking as True.
        GlobalDocumentNo := WhseInternalPutAwayLine."No.";  // Assign Global variable for Page Handler.

        CreatePutAwayDocAndRegisterWarehouseActivity(WhseInternalPutAwayLine, WarehouseActivityLine, Item."No.", LocationWhite.Code, false);  // RegisterActivity as False.
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeader.Delete(true);

        // Exercise: Recreate Put-away from Put-away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WarehouseActivityLine, LocationWhite.Code, Item."No.", false);  // Tracking false.

        // Verify: Verify Serial and Lot No on Warehouse Activity Line.
        VerifyWarehouseActivityLine(
          '', WarehouseActivityLine."Source Document"::" ", LocationWhite.Code, Item."No.", Quantity,
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,WhseSourceCreateDocumentReportHandler,PutAwayMovementMessageHandler')]
    [Scope('OnPrem')]
    procedure MovementFromMovementWorksheetRecreateMovementSerialLotNo()
    var
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        Bin: Record Bin;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Setup: Create Item with SN Specific, Production Order and Post Output with Tracking,Create Internal Put-away,Create Movement and Delete Movement.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True,Assign Tracking as SerialNo.

        Bin.Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");
        CreateProductionOrderAndPostOutputJournalWithTracking(ProductionOrder, Item."No.", LocationWhite.Code, Bin.Code, Quantity);
        SetGlobalValue(Item."No.", false, true, false, AssignTracking::None, Quantity);  // Tracking Quantity..
        CreateWhseInternalPutawayWithTracking(WhseInternalPutAwayLine, Bin."Zone Code", Bin.Code, Item."No.", Quantity, true);  // Tracking as True.
        CreatePutAwayDocAndRegisterWarehouseActivity(WhseInternalPutAwayLine, WarehouseActivityLine2, Item."No.", LocationWhite.Code, true);  // RegisterActivity as True.

        CreateWhseWorksheetName(WhseWorksheetName, LocationWhite.Code, WhseWorksheetTemplate.Type::Movement);
        CreateMovementFormMovementWorkSheet(WhseWorksheetName, WarehouseActivityLine2, Item."No.", LocationWhite.Code, Quantity);
        FindWarehouseActivityHeader(
          WarehouseActivityHeader, WhseWorksheetName."Worksheet Template Name", WarehouseActivityLine."Source Document"::" ",
          LocationWhite.Code, Item."No.", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityHeader.Delete(true);

        // Exercise: Recreate Movement From Movement Worksheet.
        CreateMovementFormMovementWorkSheet(WhseWorksheetName, WarehouseActivityLine2, Item."No.", LocationWhite.Code, Quantity);

        // Verify: Verify Serial and Lot No on Warehouse Activity Line.
        VerifyWarehouseActivityLine(
          WhseWorksheetName."Worksheet Template Name", WarehouseActivityLine."Source Document"::" ", LocationWhite.Code, Item."No.",
          Quantity, WarehouseActivityLine."Activity Type"::Movement);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayErrorWhenUsePutAwayWorksheetSerialLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Update White location,Create Item with SN Specific, Create and Post Warehouse Receipt from Purchase Order.
        Initialize();
        UpdateWarehouseAndBinPoliciesOnLocation(LocationWhite, true, true);
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True,Assign Tracking as SerialNo.
        CreateAndPostWarehouseReceiptFromPurchaseOrderWithTracking(
          PurchaseHeader, WarehouseReceiptHeader, Item."No.", LocationWhite.Code, LibraryRandom.RandInt(10), false, false);  // PostReceipt as False.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Exercise: Find Warehouse Activity line for Put-away.
        asserterror FindWarehouseActivityLine(
            WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order", LocationWhite.Code,
            Item."No.", '', WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify: Verify error message.
        Assert.IsTrue(StrPos(GetLastErrorText, WarehouseActivityLineError) > 0, GetLastErrorText);

        // Tear Down.
        UpdateWarehouseAndBinPoliciesOnLocation(LocationWhite, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,PutAwaySelectionPageHandler,WhseSourceCreateDocumentReportHandler,WhseReceiptPutAwayMessageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayUsingWorksheetWhenUsePutAwayWorksheetSerialLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Update White location,Create Item with SN Specific, Create and Post Warehouse Receipt from Purchase Order.
        Initialize();
        UpdateWarehouseAndBinPoliciesOnLocation(LocationWhite, true, true);
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True,Assign Tracking as SerialNo.
        CreateAndPostWarehouseReceiptFromPurchaseOrderWithTracking(
          PurchaseHeader, WarehouseReceiptHeader, Item."No.", LocationWhite.Code, Quantity, false, false);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        FindPostedWhseReceiptHeader(WarehouseReceiptHeader."No.");

        // Exercise: Create Put-away from Put-away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WarehouseActivityLine, LocationWhite.Code, Item."No.", false);

        // Verify: Verify Warehouse Activity Line for Put-away.
        VerifyWarehouseActivityLine(
          PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order", LocationWhite.Code, Item."No.", Quantity,
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Tear Down.
        UpdateWarehouseAndBinPoliciesOnLocation(LocationWhite, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PutAwaySelectionPageHandler,WhseSourceCreateDocumentReportHandler,TransferOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayUsingWorksheetForTransferWhenUsePutAwayWorksheetSerialLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Update White location,Create Item with SN Specific,Create and Post Purchase Order,Create Transfer Order and Post Warehouse Receipt.
        Initialize();
        UpdateWarehouseAndBinPoliciesOnLocation(LocationWhite, true, true);
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationBlue.Code, Quantity);

        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True,Assign Tracking as SerialNo.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SelectTrackingEntries, 0);  // Assign Global variable for Page Handler.Assign Tracking as Select Tracking Entries.
        CreateTransferOrderAndPostWhseReceipt(
          TransferHeader, WarehouseReceiptHeader, LocationBlue.Code, LocationWhite.Code, Item."No.", Quantity);
        FindPostedWhseReceiptHeader(WarehouseReceiptHeader."No.");

        // Exercise: Create Put-away from Putaway Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WarehouseActivityLine, LocationWhite.Code, Item."No.", false);

        // Verify: Verify Warehouse Activity Line for Put-away.
        VerifyWarehouseActivityLine(
          TransferHeader."No.", WarehouseActivityLine."Source Document"::"Inbound Transfer", LocationWhite.Code, Item."No.", Quantity,
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Tear Down.
        UpdateWarehouseAndBinPoliciesOnLocation(LocationWhite, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,TransferOrderMessageHandler')]
    [Scope('OnPrem')]
    procedure TransferReceiptAndRegisterPutAwaySerialLotNo()
    var
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        TransferHeader: Record "Transfer Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Update White location,Create Item with SN Specific,Create and Post Purchase Order,Create Transfer Order and Post Warehouse Receipt.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationBlue.Code, Quantity);

        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True,Assign Tracking as SerialNo.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SelectTrackingEntries, 0);  // Assign Global variable for Page Handler.Assign Tracking as Select Tracking Entries.
        CreateTransferOrderAndPostWhseReceipt(
          TransferHeader, WarehouseReceiptHeader, LocationBlue.Code, LocationWhite.Code, Item."No.", Quantity);
        FindWarehouseActivityHeader(
          WarehouseActivityHeader, TransferHeader."No.", WarehouseActivityLine."Source Document"::"Inbound Transfer", LocationWhite.Code,
          Item."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // Exercise: Create Put-away from Put-away Worksheet.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // Verify: Verify Registered Warehouse Activity Line for Put-away.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Activity Type"::"Put-away", RegisteredWhseActivityLine."Source Document"::"Inbound Transfer",
          Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CustomizedSerialPageHandler,ItemTrackingCustomizedPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithCustomizedTrackingForSerialNo()
    begin
        // Setup.
        Initialize();
        PurchaseOrderWithCustomizedTracking(false, AssignTracking::SerialNo);  // New Lot No as false.
    end;

    [Test]
    [HandlerFunctions('CustomizedSerialPageHandler,ItemTrackingCustomizedPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithCustomizedTrackingForSerialLotNo()
    begin
        // Setup.
        Initialize();
        PurchaseOrderWithCustomizedTracking(true, AssignTracking::LotNo);  // New Lot No as false.
    end;

    local procedure PurchaseOrderWithCustomizedTracking(NewLotNo: Boolean; ItemTrackingAction2: Option)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Create Item With SN Specific and Create a Purchase Order.
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationBlue.Code, Quantity);
        SetGlobalValue(Item."No.", NewLotNo, false, false, AssignTracking::SerialNo, 0);

        // Exercise: Assign Customized SN Tracking on Purchase line.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign tracking on Page handler ItemTrackingCustomizedPageHandler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, Quantity);
        ItemTrackingAction := ItemTrackingAction2;

        // Verify: Verify Customized Tracking on Page handler.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Verify Tracking on Page handler ItemTrackingCustomizedPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure PickForProductionOrderSerialLotNo()
    var
        Item2: Record Item;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        ProductionOrder: Record "Production Order";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ProductionBOMHeader: Record "Production BOM Header";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        Quantity: Decimal;
        ComponentsAtLocation: Code[10];
    begin
        // Setup: Create Item With SN Specific Tracking include SN Warehouse Tracking, Post Warehouse Receipt from Purchase Order with Tracking, Create Production Order, Create and Register Pick.
        Initialize();
        ComponentsAtLocation := UpdateComponentsAtLocationSetup(LocationWhite.Code);
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateItem(Item2, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."Base Unit of Measure", Item."No.");
        UpdateProductionBOMNoOnItem(Item2, ProductionBOMHeader."No.");

        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True,Assign Tracking as SerialNo.
        CreateAndPostWarehouseReceiptFromPurchaseOrderWithTracking(
          PurchaseHeader, WarehouseReceiptHeader, Item."No.", LocationWhite.Code, Quantity, true, false);  // Post Receipt as True.
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item2."No.", LocationWhite.Code, LocationWhite."To-Production Bin Code", Quantity);
        GlobalDocumentNo := ProductionOrder."No.";  // Assign Global variable for Page Handler.

        CreateWhseWorksheetName(WhseWorksheetName, LocationWhite.Code, WhseWorksheetTemplate.Type::Pick);
        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationWhite.Code);
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationWhite.Code);
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          LocationWhite.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        UpdateSerialAndLotNoOnWarehouseActivityLine(
          Item."No.", ProductionOrder."No.", LocationWhite.Code, WarehouseActivityLine."Action Type"::Place);
        UpdateSerialAndLotNoOnWarehouseActivityLine(
          Item."No.", ProductionOrder."No.", LocationWhite.Code, WarehouseActivityLine."Action Type"::Take);

        // Exercise.
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", LocationWhite.Code, Item."No.",
          WarehouseActivityLine."Activity Type"::Pick, true);

        // Verify: Verify Registered Warehouse Activity Line for Pick.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Activity Type"::Pick, RegisteredWhseActivityLine."Source Document"::"Prod. Consumption",
          Item."No.", Quantity);

        // Tear Down.
        UpdateComponentsAtLocationSetup(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,WhseSourceCreateDocumentReportHandler,WhseReceiptPutAwayMessageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayFromProductionOrderSerialLotNo()
    var
        Item2: Record Item;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProductionOrder: Record "Production Order";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Bin: Record Bin;
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        ProductionBOMHeader: Record "Production BOM Header";
        Quantity: Decimal;
        ComponentsAtLocation: Code[10];
    begin
        // Setup: Create Item With SN Specific Tracking include SN Warehouse Tracking, Post Warehouse Receipt from Purchase Order with Tracking, Create Production Order, Create Internal Put-Away.
        Initialize();
        ComponentsAtLocation := UpdateComponentsAtLocationSetup(LocationWhite.Code);
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        Bin.Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateItem(Item2, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."Base Unit of Measure", Item."No.");
        UpdateProductionBOMNoOnItem(Item2, ProductionBOMHeader."No.");

        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler. Create New Lot as True,Assign Tracking as SerialNo.
        CreateAndPostWarehouseReceiptFromPurchaseOrderWithTracking(
          PurchaseHeader, WarehouseReceiptHeader, Item."No.", LocationWhite.Code, Quantity, true, false);  // Post Receipt as True.
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item2."No.", LocationWhite.Code, LocationWhite."To-Production Bin Code", Quantity);
        CreateWhseInternalPutawayHeader(WhseInternalPutAwayHeader, Bin."Zone Code", Bin.Code);
        WhseGetBinContentAndReleaseWhseIntPutAway(WhseInternalPutAwayHeader, LocationWhite.Code);
        FindWhseInternalPutAwayLine(WhseInternalPutAwayLine, WhseInternalPutAwayHeader."No.", Item."No.");

        // Exercise.
        CreatePutAwayDocAndRegisterWarehouseActivity(WhseInternalPutAwayLine, WarehouseActivityLine, Item."No.", LocationWhite.Code, true);

        // Verify: Verify Registered Warehouse Activity Line for Put-away.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Activity Type"::"Put-away", RegisteredWhseActivityLine."Source Document"::"Purchase Order",
          Item."No.", Quantity);

        // Tear Down.
        UpdateComponentsAtLocationSetup(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TrackingLineOnInternalPutAwayWithoutSNWarehouseTrackingError()
    var
        Item: Record Item;
        Bin: Record Bin;
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
    begin
        // Setup : Create Item with SN Specific, Create Warehouse Internal Put-Away.
        Initialize();
        Bin.Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateWhseInternalPutawayHeader(WhseInternalPutAwayHeader, Bin."Zone Code", Bin.Code);
        LibraryWarehouse.CreateWhseInternalPutawayLine(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, Item."No.", LibraryRandom.RandInt(10));

        // Exercise: Open Tracking line from Warehouse Internal Put-Away line.
        asserterror WhseInternalPutAwayLine.OpenItemTrackingLines();

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(WhseItemTrackingNotEnabledError, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TrackingLineOnInternalPickWithoutSNWarehouseTrackingError()
    var
        Item: Record Item;
        Bin: Record Bin;
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
    begin
        // Setup: Create Item with SN Specific, Create Warehouse Internal Pick.
        Initialize();
        Bin.Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateWhseInternalPickHeader(WhseInternalPickHeader, Bin."Zone Code", Bin.Code);
        LibraryWarehouse.CreateWhseInternalPickLine(
          WhseInternalPickHeader, WhseInternalPickLine, Item."No.", LibraryRandom.RandInt(10));

        // Exercise: Open Tracking line from Warehouse Internal Pick Line.
        asserterror WhseInternalPickLine.OpenItemTrackingLines();

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(WhseItemTrackingNotEnabledError, Item."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,PutAwaySelectionPageHandler')]
    [Scope('OnPrem')]
    procedure TrackingLineOnPutAwayWorksheetWithoutSNWarehouseTrackingError()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
    begin
        // Setup: Update White location,Create Item with SN Specific, Create and Post Warehouse Receipt from Purchase Order, Create Put-away from Put-away Worksheet.
        Initialize();
        UpdateWarehouseAndBinPoliciesOnLocation(LocationWhite, true, true);
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler,Assign Tracking as SerialNo.
        CreateAndPostWarehouseReceiptFromPurchaseOrderWithTracking(
          PurchaseHeader, WarehouseReceiptHeader, Item."No.", LocationWhite.Code, LibraryRandom.RandInt(10), false, false);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        FindPostedWhseReceiptHeader(WarehouseReceiptHeader."No.");

        CreateWhseWorksheetName(WhseWorksheetName, LocationWhite.Code, WhseWorksheetTemplate.Type::"Put-away");
        FilterOnWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationWhite.Code, Item."No.");
        GetSourceDocInbound.GetSingleWhsePutAwayDoc(
          WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationWhite.Code);
        WhseWorksheetLine.FindFirst();

        // Exercise: Open Tracking line from Warehouse Worksheet Line.
        asserterror WhseWorksheetLine.OpenItemTrackingLines();

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(WhseItemTrackingNotEnabledError, Item."No."));

        // Tear Down.
        UpdateWarehouseAndBinPoliciesOnLocation(LocationWhite, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PickSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure TrackingLineOnPickWorksheetWithoutSNWarehouseTrackingError()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        Quantity: Decimal;
    begin
        // Setup: Create Item with SN Specific, Create and Post Warehouse Receipt from Purchase Order, Create Warehouse Shipment from Sales Order, Create Pick from Pick Worksheet.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler,Assign Tracking as SerialNo.
        CreateAndPostWarehouseReceiptFromPurchaseOrderWithTracking(
          PurchaseHeader, WarehouseReceiptHeader, Item."No.", LocationWhite.Code, Quantity, true, false);  // Post Receipt as True.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SelectTrackingEntries, 0);  // Assign Global variable for Page Handler. Assign Tracking as SelectTrackingEntries.
        CreateAndReleaseWhseShipmentFromSalesOrderWithTracking(
          SalesHeader, WarehouseShipmentHeader, Item."No.", LocationWhite.Code, Quantity, true);  // Tracking as True.
        GlobalDocumentNo := WarehouseShipmentHeader."No.";  // Assign Global variable for Page Handler.

        CreateWhseWorksheetName(WhseWorksheetName, LocationWhite.Code, WhseWorksheetTemplate.Type::Pick);
        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationWhite.Code);
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationWhite.Code);

        // Exercise: Open Tracking line from Warehouse Worksheet Line.
        asserterror WhseWorksheetLine.OpenItemTrackingLines();

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(WhseItemTrackingNotEnabledError, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TrackingLineOnMovementWorksheetWithoutSNWarehouseTrackingError()
    var
        Item: Record Item;
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // Setup: Create Item with SN Specific, Create Warehouse Worksheet line.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateWhseWorksheetName(WhseWorksheetName, LocationWhite.Code, WhseWorksheetTemplate.Type::Movement);
        CreateWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          WhseWorksheetLine."Whse. Document Type"::"Whse. Mov.-Worksheet", Item."No.", LocationWhite.Code,
          LibraryRandom.RandInt(10));

        // Exercise: Open Tracking line from Warehouse Worksheet Line.
        asserterror WhseWorksheetLine.OpenItemTrackingLines();

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(WhseItemTrackingNotEnabledError, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TrackingLineOnWarehouseJournalLineWithoutSNWarehouseTrackingError()
    var
        Item: Record Item;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Setup : Create Item with SN Specific, Create Warehouse Journal line.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        LibraryWarehouse.WarehouseJournalSetup(LocationWhite.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, '', '',
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(10));

        // Exercise: Open Tracking line from Warehouse Journal Line.
        asserterror WarehouseJournalLine.OpenItemTrackingLines();

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(WhseItemTrackingNotEnabledError, Item."No."));
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhseJournalLineWithSNWarehouseTracking()
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Setup: Create Item With SN Specific Tracking include SN Warehouse Tracking, Create Warehouse Journal line and Assign Tracking.
        Initialize();
        Bin.Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        LibraryWarehouse.WarehouseJournalSetup(LocationWhite.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code,
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          LibraryRandom.RandInt(10) + 5);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, WarehouseJournalLine.Quantity);
        WarehouseJournalLine.OpenItemTrackingLines();

        // Exercise.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, true);

        // Verify: Verify Registered Warehouse Activity Line for Put-away.
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", WarehouseJournalLine.Quantity, 1);  // 1 as Positive Sign Factor.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityShipFromItemJournalLineWithoutSNWarehouseTracking()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with SN Specific,Create and Post Warehouse Receipt from Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler, Assign Tracking as SerialNo.
        CreateAndPostWarehouseReceiptFromPurchaseOrderWithTracking(
          PurchaseHeader, WarehouseReceiptHeader, Item."No.", LocationYellow2.Code, Quantity, false, false);  // Post Receipt as True.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Exercise: Create and Post Item Journal line for Sales with Tracking.
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::Sale, Item."No.", LocationYellow2.Code, Quantity, 0, AssignTracking::SelectTrackingEntries);

        // Verify: Verify Serial Number in Item Ledger Entry.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Sale, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostJournalLinesMessageHandler,PostJournalConfirmHandler')]
    [Scope('OnPrem')]
    procedure QuantityShipFromOutputJournalWithoutSNWarehouseTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionBOMHeader: Record "Production BOM Header";
        OutputJournal: TestPage "Output Journal";
        Quantity: Decimal;
    begin
        // Setup: Create Item with SN Specific, Create Released Production Order and Post Output with Tracking and again create Output journal with negative Quantity.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Large Random Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateItem(Item2, ItemTrackingCodeSerialSpecific.Code);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."Base Unit of Measure", Item."No.");
        UpdateProductionBOMNoOnItem(Item2, ProductionBOMHeader."No.");
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler, Assign Tracking as SerialNo.

        CreateProductionOrderAndPostOutputJournalWithTracking(ProductionOrder, Item2."No.", LocationYellow2.Code, '', Quantity);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SelectTrackingEntries, 0);  // Assign Global variable for Page Handler,Assign Tracking as SelectTrackingEntries.
        CreateOutputJournalWithTracking(ProductionOrder."No.", Item2."No.", -Quantity + 1);  // Reducing Output Quantity with Negative Quantity.

        // Exercise: Post Output Journal.
        OutputJournal.OpenEdit();
        OutputJournal.CurrentJnlBatchName.SetValue(OutputItemJournalBatch.Name);
        OutputJournal.Post.Invoke();  // Use Page Testability for Apply Entry code on page.

        // Verify: Verify Serial Number in Item Ledger Entry.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Output, Item2."No.", 2 * Quantity - 1);  // Total Quantity including Positive and Negative.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityShipFromConsumptionJournalLineWithoutSNWarehouseTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionBOMHeader: Record "Production BOM Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with SN Specific, Create and Post Item Journal line, Create Released Production Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateItem(Item2, ItemTrackingCodeSerialSpecific.Code);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."Base Unit of Measure", Item."No.");
        UpdateProductionBOMNoOnItem(Item2, ProductionBOMHeader."No.");
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler,Assign Tracking as SerialNo.
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationYellow2.Code, Quantity, 0, AssignTracking::SerialNo);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item2."No.", LocationYellow2.Code, '', Quantity);

        // Exercise: Create and Post Consumption Journal with Tracking.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SelectTrackingEntries, Quantity);  // Assign Global variable for Page Handler, Assign Tracking as SelectTrackingEntries, Tracking Quantity required.
        CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // Verify: Verify Serial Number in Item Ledger Entry.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Consumption, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure QuantityReceiveFromItemJournalLineWithSNWarehouseTracking()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        Bin: Record Bin;
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // Setup : Create Item With SN Specific Tracking include SN Warehouse Tracking, Create Bin and Bin Content.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateBinAndBinContent(Bin, Item, LocationSilver.Code);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler,Assign Tracking as SerialNo.

        // Exercise. Create and Post Item journal Line with Tracking.
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::Purchase, Item."No.", LocationSilver.Code, Quantity, 0, AssignTracking::SerialNo);

        // Verify: Verify Serial Number in Item Ledger Entry and Warehouse Entry.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Quantity);
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", Quantity, 1);  // 1 as Positive Sing Factor,
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure QuantityReceiveFromOutputJournalWithSNWarehouseTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Bin: Record Bin;
        WarehouseEntry: Record "Warehouse Entry";
        ProductionBOMHeader: Record "Production BOM Header";
        Quantity: Decimal;
    begin
        // Setup : Create Item With SN Specific Tracking include SN Warehouse Tracking , Create Bin,Bin Content and Production BOM, Create Released Prodcution Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateItem(Item2, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateBinAndBinContent(Bin, Item, LocationSilver.Code);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."Base Unit of Measure", Item."No.");
        UpdateProductionBOMNoOnItem(Item2, ProductionBOMHeader."No.");
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item2."No.", LocationSilver.Code, Bin.Code, Quantity);

        // Exercise: Create and Post Output journal with Tracking.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);  // Assign Global variable for Page Handler,Assign Tracking as SerialNo.
        CreateAndPostOutputJournalWithTracking(ProductionOrder."No.");

        // Verify: Verify Serial Number in Item Ledger Entry and Warehouse Entry.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Output, Item2."No.", Quantity);
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Positive Adjmt.", Item2."No.", Quantity, 1);  // 1 as Positive Sing Factor,
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityReceiveFromConsumptionJournalLineWithSNWarehouseTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Bin: Record Bin;
        WarehouseEntry: Record "Warehouse Entry";
        ProductionBOMHeader: Record "Production BOM Header";
        Quantity: Decimal;
    begin
        // Setup : Create Item With SN Specific Tracking include SN Warehouse Tracking , Create Bin,Bin Content and Production BOM, Create and Post Item journal Line, Create Released Prodcution Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateItem(Item2, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateBinAndBinContent(Bin, Item, LocationSilver.Code);

        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."Base Unit of Measure", Item."No.");
        UpdateProductionBOMNoOnItem(Item2, ProductionBOMHeader."No.");
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationSilver.Code, Quantity, 0, AssignTracking::SerialNo);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item2."No.", LocationSilver.Code, Bin.Code, Quantity);

        // Exercise: Create and Post Consumption journal with Tracking.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SelectTrackingEntries, Quantity);  // Tracking Quantity required.
        CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // Verify: Verify Serial Number in Item Ledger Entry and Warehouse Entry.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Consumption, Item."No.", Quantity);
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Negative Adjmt.", Item."No.", Quantity, -1);  // -1 as Negative Sing Factor,
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseReceiptFromPurchaseOrderWithoutSNWarehouseTracking()
    begin
        // Setup.
        Initialize();
        WarehouseReceiptFromPurchaseOrderSerialNo(ItemTrackingCodeSerialSpecific.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseReceiptFromPurchaseOrderWithSNWarehouseTracking()
    begin
        // Setup.
        Initialize();
        WarehouseReceiptFromPurchaseOrderSerialNo(ItemTrackingCodeSerialSpecificWithWarehouse.Code);
    end;

    local procedure WarehouseReceiptFromPurchaseOrderSerialNo(ItemTrackingCode: Code[10])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseSetup: Record "Warehouse Setup";
        PostingPolicy: Integer;
    begin
        // Create Item with SN Tracking, Create Warehouse Receipt from Purchase Order.
        PostingPolicy :=
          UpdateWarehouseSetupPostingPolicy(WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item, ItemTrackingCode);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Exercise: Assign Tracking on Warehouse Receipt line.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);
        SelectWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingSerialNoPageHandler.

        // Verify: Verify Tracking on Purchase line on Page handler.
        SetGlobalValue(Item."No.", false, true, false, AssignTracking::None, WarehouseReceiptLine.Quantity);  // Update Trackig as True,Tracking Quantity required.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Verify Tracking on Page Handler ItemTrackingSerialNoPageHandler.

        // Tear Down.
        UpdateWarehouseSetupPostingPolicy(PostingPolicy);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseReceiptFromSalesReturnOrderWithoutSNWarehouseTracking()
    begin
        // Setup.
        Initialize();
        WarehouseReceiptFromSalesReturnOrderSerialNo(ItemTrackingCodeSerialSpecific.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseReceiptFromSalesReturnOrderWithSNWarehouseTracking()
    begin
        // Setup.
        Initialize();
        WarehouseReceiptFromSalesReturnOrderSerialNo(ItemTrackingCodeSerialSpecificWithWarehouse.Code);
    end;

    local procedure WarehouseReceiptFromSalesReturnOrderSerialNo(ItemTrackingCode: Code[10])
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PostingPolicy: Integer;
    begin
        // Create Item with SN Tracking, Create Warehouse Receipt from Sales Retrun Order.
        PostingPolicy :=
          UpdateWarehouseSetupPostingPolicy(WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item, ItemTrackingCode);
        CreateAndReleaseSalesReturnOrder(SalesHeader, SalesLine, Item."No.", LocationWhite.Code, LibraryRandom.RandInt(10), true);
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);

        // Exercise: Assign Tracking on Warehouse Receipt line.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);
        SelectWarehouseReceiptLine(WarehouseReceiptLine, SalesHeader."No.", WarehouseReceiptLine."Source Document"::"Sales Return Order");
        WarehouseReceiptLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingSerialNoPageHandler.

        // Verify: Verify Tracking on Sales Line line on Page handler.
        SetGlobalValue(Item."No.", false, true, false, AssignTracking::None, SalesLine.Quantity);  // Update Trackig as True,Tracking Quantity required.
        SalesLine.OpenItemTrackingLines();  // Verify Tracking on Page Handler ItemTrackingSerialNoPageHandler.

        // Tear Down.
        UpdateWarehouseSetupPostingPolicy(PostingPolicy);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromSalesOrderWithoutSNWarehouseTracking()
    var
        Item: Record Item;
        WarehouseSetup: Record "Warehouse Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PostingPolicy: Integer;
    begin
        // Setup: Create Item with SN Specific Tracking, Create and Post Positive Adjustment, Create Warehouse Shipment from Sales Order.
        Initialize();
        PostingPolicy :=
          UpdateWarehouseSetupPostingPolicy(WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationYellow2.Code, 10 + LibraryRandom.RandInt(10), 0,
          AssignTracking::SerialNo);  // Large Random value for Quantity.
        CreateAndReleaseWhseShipmentFromSalesOrderWithTracking(
          SalesHeader, WarehouseShipmentHeader, Item."No.", LocationYellow2.Code, LibraryRandom.RandInt(10), false);  // Tracking as False.

        // Exercise: Assign Tracking on Warehouse Shipment line.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SelectTrackingEntries, 0);
        SelectWarehouseShipmentLine(WarehouseShipmentLine, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingSerialNoPageHandler.

        // Verify: Verify Tracking on Purchase line on Page handler.
        SelectSalesLine(SalesLine, SalesHeader."No.");
        SetGlobalValue(Item."No.", false, true, false, AssignTracking::None, SalesLine.Quantity);  // Update Trackig as True,Tracking Quantity required.
        SalesLine.OpenItemTrackingLines();  // Verify Tracking on Page Handler ItemTrackingSerialNoPageHandler.

        // Tear Down.
        UpdateWarehouseSetupPostingPolicy(PostingPolicy);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler,AvailabilityConfirmHandler')]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromPurchaseReturnOrderWithoutSNWarehouseTracking()
    var
        Item: Record Item;
        WarehouseSetup: Record "Warehouse Setup";
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseHeader: Record "Purchase Header";
        PostingPolicy: Integer;
    begin
        // Setup: Create Item with SN Specific Tracking, Create and Post Positive Adjustment, Create Warehouse Shipment from Purchase Return Order.
        Initialize();
        PostingPolicy :=
          UpdateWarehouseSetupPostingPolicy(WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, Item."No.", LocationYellow2.Code, LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);

        // Exercise: Assign Tracking on Warehouse Shipment line.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);
        SelectWarehouseShipmentLine(
          WarehouseShipmentLine, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Return Order");
        WarehouseShipmentLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingSerialNoPageHandler.

        // Verify: Verify Tracking on Purchase line on Page handler.
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        SetGlobalValue(Item."No.", false, true, false, AssignTracking::None, PurchaseLine.Quantity);  // Update Trackig as True,Tracking Quantity required.
        ClearGlobals();
        PurchaseLine.OpenItemTrackingLines();  // Verify Tracking on Page Handler ItemTrackingSerialNoPageHandler.

        // Tear Down.
        UpdateWarehouseSetupPostingPolicy(PostingPolicy);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickForSalesOrderWithSNWarehouseTrackingError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Create Item With SN Specific Tracking include SN Warehouse Tracking, Create and Post Positive Adjustment, Create Warehouse Shipment from Sales Order and Pick.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationYellow.Code, 10 + LibraryRandom.RandInt(10), 0,
          AssignTracking::SerialNo);  // Large Random value for Quantity.
        CreateAndReleaseWhseShipmentFromSalesOrderWithTracking(
          SalesHeader, WarehouseShipmentHeader, Item."No.", LocationYellow.Code, LibraryRandom.RandInt(10), false);  // Tracking as false.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Exercise: Register Pick.
        asserterror RegisterWarehouseActivity(
            SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order", LocationYellow.Code, Item."No.",
            WarehouseActivityLine."Activity Type"::Pick, false);

        // Verify: Verify error message.
        Assert.ExpectedError(SerialNoValueError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickForPurchaseReturnOrderWithSNWarehouseTrackingError()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Create Item With SN Specific Tracking include SN Warehouse Tracking, Create and Post Positive Adjustment, Create Warehouse Shipment from Purchase Return Order and Pick.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationYellow.Code, 10 + LibraryRandom.RandInt(10), 0,
          AssignTracking::SerialNo);  // Large Random value for Quantity.
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, Item."No.", LocationYellow.Code, LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);

        FindWarehouseShipmentHeader(
          WarehouseShipmentHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Return Order");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Exercise: Register Pick.
        asserterror RegisterWarehouseActivity(
            PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Return Order", LocationYellow.Code, Item."No.",
            WarehouseActivityLine."Activity Type"::Pick, false);

        // Verify: Verify error message.
        Assert.ExpectedError(SerialNoValueError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPickForSalesOrderWithBindingOrderToOrder()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        DummyWarehouseActivityLine: Record "Warehouse Activity Line";
        QtyToShip: Integer;
    begin
        // [FEATURE] [SN Warehouse Tracking] [Inventory Pick] [Binding]
        // [SCENARIO 380088] Inventory Pick should perform successful partial shipment of Sales Line, which is linked to a supply by Binding = "Order-to-Order".
        Initialize();

        // [GIVEN] Location that requires Pick.
        // [GIVEN] Item with Serial Nos. tracking.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);

        // [GIVEN] Posted Purchase with tracking.
        // [GIVEN] Released and fully reserved Sales Order, which is set to be shipped partially ("Qty. to Ship" = "X").
        CreateAndPostTrackedPurchaseAndCreateSalesOrderWithPartialShip(SalesLine, Item."No.", Location.Code);
        QtyToShip := SalesLine."Qty. to Ship";

        // [GIVEN] Binding in Reservation Entries of Sale is set to "Order-to-Order".
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.ModifyAll(Binding, ReservationEntry.Binding::"Order-to-Order");

        // [GIVEN] Inventory Pick for quantity "X".
        CreateInventoryPick(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.");

        // [WHEN] Post Inventory Pick.
        PostInventoryActivity(
          SalesLine."Document No.", DummyWarehouseActivityLine."Source Document"::"Sales Order", Location.Code, Item."No.",
          DummyWarehouseActivityLine."Activity Type"::"Invt. Pick");
        // [THEN] "Quantity Shipped" on Sales Line = "X".
        SalesLine.Find();
        Assert.AreEqual(
          QtyToShip, SalesLine."Quantity Shipped",
          StrSubstNo(IncorrectShippedQtyMsg, SalesLine.FieldCaption("Quantity Shipped"), SalesLine.FieldCaption("Qty. to Ship")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseReceiptFromPurchaseOrderWithoutSNWarehouseTrackingError()
    begin
        // Setup.
        Initialize();
        PostWarehouseReceiptFromPurchaseOrder(ItemTrackingCodeSerialSpecific.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseReceiptFromPurchaseOrderWithSNWarehouseTrackingError()
    begin
        // Setup.
        Initialize();
        PostWarehouseReceiptFromPurchaseOrder(ItemTrackingCodeSerialSpecificWithWarehouse.Code);
    end;

    local procedure PostWarehouseReceiptFromPurchaseOrder(ItemTrackingCode: Code[10])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseSetup: Record "Warehouse Setup";
        PostingPolicy: Integer;
    begin
        // Create Item with SN Tracking, Create Warehouse Receipt from Purchase Order.
        PostingPolicy :=
          UpdateWarehouseSetupPostingPolicy(WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item, ItemTrackingCode);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptHeader(WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");

        // Exercise.
        asserterror LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(SerialNumberRequiredError, Item."No."));

        // Tear Down.
        UpdateWarehouseSetupPostingPolicy(PostingPolicy);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseReceiptFromSalesReturnOrderWithoutSNWarehouseTrackingError()
    begin
        // Setup.
        Initialize();
        PostWarehouseReceiptFromSalesReturnOrder(ItemTrackingCodeSerialSpecific.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseReceiptFromSalesReturnOrderWithSNWarehouseTrackingError()
    begin
        // Setup.
        Initialize();
        PostWarehouseReceiptFromSalesReturnOrder(ItemTrackingCodeSerialSpecificWithWarehouse.Code);
    end;

    local procedure PostWarehouseReceiptFromSalesReturnOrder(ItemTrackingCode: Code[10])
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PostingPolicy: Integer;
    begin
        // Create Item with SN Tracking, Create Warehouse Receipt from Sales Retrun Order.
        PostingPolicy :=
          UpdateWarehouseSetupPostingPolicy(WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item, ItemTrackingCode);
        CreateAndReleaseSalesReturnOrder(SalesHeader, SalesLine, Item."No.", LocationWhite.Code, LibraryRandom.RandInt(10), true);
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        FindWarehouseReceiptHeader(
          WarehouseReceiptHeader, SalesHeader."No.", WarehouseReceiptLine."Source Document"::"Sales Return Order");

        // Exercise.
        asserterror LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(SerialNumberRequiredError, Item."No."));

        // Tear Down.
        UpdateWarehouseSetupPostingPolicy(PostingPolicy);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentFromSalesOrderWithoutSNWarehouseTrackingError()
    var
        Item: Record Item;
        WarehouseSetup: Record "Warehouse Setup";
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PostingPolicy: Integer;
    begin
        // Setup: Create Item with SN Specific Tracking, Create and Post Positive Adjustment, Create Warehouse Shipment from Sales Order.
        Initialize();
        PostingPolicy :=
          UpdateWarehouseSetupPostingPolicy(WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationYellow2.Code, 10 + LibraryRandom.RandInt(10), 0,
          AssignTracking::SerialNo);  // Large Random value for Quantity.
        CreateAndReleaseWhseShipmentFromSalesOrderWithTracking(
          SalesHeader, WarehouseShipmentHeader, Item."No.", LocationYellow2.Code, LibraryRandom.RandInt(10), false);  // Tracking as False.

        // Exercise.
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(SerialNumberRequiredError, Item."No."));

        // Tear Down.
        UpdateWarehouseSetupPostingPolicy(PostingPolicy);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentFromPurchaseReturnOrderWithoutSNWarehouseTrackingError()
    var
        Item: Record Item;
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseHeader: Record "Purchase Header";
        PostingPolicy: Integer;
    begin
        // Setup: Create Item with SN Specific Tracking, Create and Post Positive Adjustment, Create Warehouse Shipment from Purchase Return Order.
        Initialize();
        PostingPolicy :=
          UpdateWarehouseSetupPostingPolicy(WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, Item."No.", LocationYellow2.Code, LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        FindWarehouseShipmentHeader(
          WarehouseShipmentHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Return Order");

        // Exercise.
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(SerialNumberRequiredError, Item."No."));

        // Tear Down.
        UpdateWarehouseSetupPostingPolicy(PostingPolicy);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure RoundCostAmountOnItemLedgerEntryWithItemJournaForlPositiveAdjustment()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        Amount: Decimal;
    begin
        // Setup: Create Item with SN Specific Tracking, Create and Post ItemJournal with Positive Adjustment.
        Initialize();
        Quantity := LibraryRandom.RandInt(10); // For Random Value
        Amount := LibraryRandom.RandDec(10, 2); // For Random Value
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);

        // Exercise: Create and Post Item Journal line for Positive Adjmt. with Item Tracking.
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, Quantity, Amount, AssignTracking::SerialNo);

        // Verify: Verify Cost Amont(Actual) in Item Ledger Entry.
        VerifyCostAmountInItemLedgerEntryType(ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Amount);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure RoundCostAmountOnItemLedgerEntryWithItemJournalForPurchase()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        Amount: Decimal;
    begin
        // Setup: Create Item with SN Specific Tracking, Create and Post ItemJournal with Purchase.
        Initialize();
        Quantity := LibraryRandom.RandInt(10); // For Random Value
        Amount := LibraryRandom.RandDec(10, 2); // For Random Value
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);

        // Exercise: Create and Post Item Journal line for Positive Adjmt. with Item Tracking.
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::Purchase, Item."No.", LocationBlue.Code, Quantity, Amount, AssignTracking::SerialNo);

        // Verify: Verify Cost Amont(Actual) in Item Ledger Entry.
        VerifyCostAmountInItemLedgerEntryType(ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Amount);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ProductionJournalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ParentItemOutputOnItemTracingPage()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ItemTracing: TestPage "Item Tracing";
        Quantity: Decimal;
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output," ","Assembly Consumption","Assembly Output";
    begin
        // [SCENARIO] Verify Parent Item Output is present on Item Tracing Page when run trace by SN No. assigned to Consumption Item
        Initialize();
        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Create SN-specific ChildItem 'CI' and simple ParentItem 'PI' with Production BOM that uses 'CI'
        CreateItem(ChildItem, ItemTrackingCodeSerialSpecific.Code);
        LibraryInventory.CreateItem(ParentItem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ParentItem."Base Unit of Measure", ChildItem."No.");
        UpdateProductionBOMNoOnItem(ParentItem, ProductionBOMHeader."No.");

        // [GIVEN] Make positive Adjustment for 'CI', Create and Refresh Released Production Order for 'PI'
        SetGlobalValue(ChildItem."No.", false, false, false, AssignTracking::SerialNo, 0); // Assign Global variable for Page Handler,Assign Tracking as SerialNo.
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ChildItem."No.", LocationYellow2.Code, Quantity, 0, AssignTracking::SerialNo);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ParentItem."No.", LocationYellow2.Code, '', Quantity);

        // [GIVEN] Create and Post Consumption for 'CI', Post Production Output for 'PI'
        SetGlobalValue(ChildItem."No.", false, false, false, AssignTracking::SelectTrackingEntries, Quantity); // Assign Global variable for Page Handler, Assign Tracking as SelectTrackingEntries, Tracking Quantity required.
        CreateAndPostConsumptionJournal(ProductionOrder."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, 10000);

        // [WHEN] Run Item Tracing Page with SN filter used in 'CI'
        RunItemTracing(ItemTracing, ChildItem."No.");

        // [THEN] Item 'PI' is present on Item Tracing lines
        ItemTracing.FILTER.SetFilter("Item No.", ParentItem."No.");
        ItemTracing.FILTER.SetFilter("Entry Type", Format(EntryType::Output));
        Assert.IsTrue(ItemTracing.First(), ItemTracingOutputErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure KeepExpirationDateLotTrackedItem()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ExpirationDate: Date;
        Quantity: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Warehouse] [Expiration Date]
        // [SCENARIO 376162] Expiration Date is preserved in Pick Line when lookup in Pick is cancelled.

        // [GIVEN] Lot tracked Item on stock with Lot and Expiration Date.
        Initialize();
        CreateItem(Item, ItemTrackingCodeLotSpecificWithWarehouse.Code);
        Quantity := LibraryRandom.RandDecInRange(10, 100, 2);
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::LotNo, Quantity);
        CreateAndPostWarehouseReceiptFromPurchaseOrderWithTracking(
          PurchaseHeader, WarehouseReceiptHeader, Item."No.", LocationWhite.Code, Quantity, true, true);

        // [GIVEN] Create Sales Order, Warehouse Shipment and Pick.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SelectTrackingEntries, 0);
        CreateAndReleaseWhseShipmentFromSalesOrderWithTracking(
          SalesHeader, WarehouseShipmentHeader, Item."No.", LocationWhite.Code, Quantity, true);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        // [WHEN] Open Pick, lookup "Lot No." on a line, then press Cancel.
        FindWarehouseActivityLine(
            WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order", LocationWhite.Code,
            Item."No.", '', WarehouseActivityLine."Activity Type"::Pick);
        ExpirationDate := WarehouseActivityLine."Expiration Date";

        ItemTrackingSummaryCancel := true;
        // Cancel in ItemTrackingSummaryPageHandler
        WarehouseActivityLine.LookUpTrackingSummary(
            WarehouseActivityLine,
            (WarehouseActivityLine."Activity Type".AsInteger() <= WarehouseActivityLine."Activity Type"::Movement.AsInteger()) or (WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::Place),
            -1, "Item Tracking Type"::"Lot No.");
        // LOOKUP
        // [THEN] "Expiration Date" is preserved in Pick lines.
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.TestField("Expiration Date", ExpirationDate);
        until WarehouseActivityLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterInventoryMovementWithLotTrackingWhenBinTypesDoesNotExist()
    var
        ItemJournalLine: Record "Item Journal Line";
        Bin: Record Bin;
        BinType: Record "Bin Type";
        TempBinType: Record "Bin Type" temporary;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        LotNo: Code[50];
    begin
        // [FEATURE] [Warehouse] [Lot Tracking] [Inventory Movement]
        // [SCENARIO 378930] Inventory movement is registered for item with Lot Tracking and Bin Code when Bin Types does not exist

        Initialize();
        // [GIVEN] No Bin Types in current database
        MoveFromBinTypeToBinType(BinType, TempBinType);

        // [GIVEN] Item with "Lot Tracking"
        ItemNo := CreateItemWithLotTracking();

        // [GIVEN] Posted positive adjustment with "Lot Tracking" and location "SILVER"
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        PostItemJnlLineWithLotTrackingAndBinCode(ItemJournalLine, LocationSilver.Code, ItemNo, Bin.Code);
        LotNo := GetLotNoFromItemLedgEntry(ItemJournalLine."Item No.", ItemJournalLine."Document No.");

        // [GIVEN] Inventory movement created from Internal Movement
        CreateInvtMvtFromInternalMvtWithLotNo(LocationSilver.Code, ItemNo, Bin.Code, LotNo);

        // [WHEN] Register Inventory Movement
        RegisterWarehouseActivity('', "Warehouse Activity Source Document"::" ", LocationSilver.Code, ItemNo, WarehouseActivityLine."Activity Type"::"Invt. Movement", true);

        // [THEN] Inventory movement is registered
        VerifyRegistedInvtMovementLine(ItemNo, LotNo, Bin.Code);

        // Tear down
        MoveFromBinTypeToBinType(TempBinType, BinType);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayForPartiallyPutAwayReceiptWhenItemEntryDoesNotMatchWhseEntry()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
        Qty: Decimal;
        QtyRemToPutaway: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Posted Whse. Receipt] [Put-away] [Transfer Order]
        // [SCENARIO 206372] Put-away can be created from partially put-away posted warehouse receipt in case the way item entries and warehouse entries are split by quantity is different for these two ledgers.
        Initialize();

        // [GIVEN] Lot-tracked item, lot warehouse tracking is enabled.
        CreateItem(Item, ItemTrackingCodeLotSpecificWithWarehouse.Code);

        LotNo := LibraryUtility.GenerateGUID();
        Qty := 3 * 2 * LibraryRandom.RandIntInRange(20, 40);
        QtyRemToPutaway := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] The item is purchased on location "L1". The Purchase Order has three lines, each for "2Q" pcs. Overall purchased qty. = "6Q".
        CreateAndPostPurchaseOrderWithLotTrackedLines(LocationBlue.Code, Item."No.", LotNo, Qty / 3, 3);

        // [GIVEN] The item is transferred from location "L1" to WMS-location "L2". The Transfer Order has two lines, each for "3Q" pcs. Overall transferred qty. = "6Q".
        CreateAndShipTransferOrderWithLotTrackedLines(
          TransferHeader, LocationBlue.Code, LocationWhite.Code, LocationIntransit.Code, Item."No.", LotNo, Qty / 2, 2);
        CreateAndPostWhseReceiptFromInboundTransfer(TransferHeader, WarehouseReceiptHeader);

        // [GIVEN] After the receipt to "L2" is posted, two pairs of put-away lines are created.
        // [GIVEN] "Qty. to Handle" in the first pair = "3Q", in the second pair = "3Q" - "Delta".
        UpdateQtyToHandleOnWhsePutawayLine(
          TransferHeader."No.", WarehouseActivityLine."Source Document"::"Inbound Transfer", LocationWhite.Code,
          Item."No.", LotNo, Qty / 2 - QtyRemToPutaway);

        // [GIVEN] The put-away is registered and deleted.
        RegisterAndDeleteWarehouseActivity(
          TransferHeader."No.", WarehouseActivityLine."Source Document"::"Inbound Transfer", LocationWhite.Code, Item."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // [WHEN] Create put-away from the posted receipt to "L2".
        CreatePutAwayFromPostedWhseReceipt(WarehouseReceiptHeader."No.");

        // [THEN] Put-away for quantity = "Delta" is created.
        FindWarehouseActivityLine(
          WarehouseActivityLine, TransferHeader."No.", WarehouseActivityLine."Source Document"::"Inbound Transfer", LocationWhite.Code,
          Item."No.", LotNo, WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.TestField("Qty. (Base)", QtyRemToPutaway);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler')]
    [Scope('OnPrem')]
    procedure HandledQtyForEachLotIsCalculatedSeparately()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: array[2] of Code[20];
        Qty: array[2] of Decimal;
        QtyRemToPutaway: array[2] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Posted Whse. Receipt] [Put-away]
        // [SCENARIO 206372] "Qty. (Base)" on put-away lines created from partially put-away posted warehouse receipt should be equal to quantity left to be handled for each lot.
        Initialize();

        // [GIVEN] Lot-tracked item, lot warehouse tracking is enabled.
        CreateItem(Item, ItemTrackingCodeLotSpecificWithWarehouse.Code);

        // [GIVEN] Purchase Order for the item with two lot-tracked lines. Lot Nos. "L1" and "L2".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        for i := 1 to 2 do begin
            LotNo[i] := LibraryUtility.GenerateGUID();
            Qty[i] := LibraryRandom.RandIntInRange(50, 100);
            QtyRemToPutaway[i] := LibraryRandom.RandIntInRange(5, 10);
            CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item."No.", LocationWhite.Code, Qty[i]);
            LibraryVariableStorage.Enqueue(AssignTracking::GivenLotNo);
            LibraryVariableStorage.Enqueue(LotNo[i]);
            LibraryVariableStorage.Enqueue(Qty[i]);
            PurchaseLine.OpenItemTrackingLines();
        end;

        // [GIVEN] The Purchase Order is released, Whse. Receipt is created and posted.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptHeader(WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [GIVEN] Set "Qty. to Handle" < "Qty. (Base)" on put-away lines, the remaining quantity to be put-away for lot "L1" = "Rem1", for lot "L2" = "Rem2".
        for i := 1 to 2 do
            UpdateQtyToHandleOnWhsePutawayLine(
              PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order", LocationWhite.Code,
              Item."No.", LotNo[i], Qty[i] - QtyRemToPutaway[i]);

        // [GIVEN] The put-away is registered and deleted.
        RegisterAndDeleteWarehouseActivity(
          PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order", LocationWhite.Code, Item."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // [WHEN] Create put-away from the posted warehouse receipt.
        CreatePutAwayFromPostedWhseReceipt(WarehouseReceiptHeader."No.");

        // [THEN] "Qty. (Base)" for lot "L1" in the new put-away is equal to "Rem1", for lot "L2" = "Rem2".
        for i := 1 to 2 do begin
            FindWarehouseActivityLine(
              WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order", LocationWhite.Code,
              Item."No.", LotNo[i], WarehouseActivityLine."Activity Type"::"Put-away");
            WarehouseActivityLine.TestField("Qty. (Base)", QtyRemToPutaway[i]);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayForWhseReceiptWhenLotConsistsOfSeveralItemEntries()
    var
        Item: Record Item;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TransferHeader: Record "Transfer Header";
        LotNo: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Whse. Receipt] [Put-away] [Transfer Order]
        // [SCENARIO 209278] Put-away should be created for all lots in whse. receipt line, if quantity of each lot consists of several item entries.
        Initialize();

        // [GIVEN] Lot-tracked item, lot warehouse tracking is enabled.
        CreateItem(Item, ItemTrackingCodeLotSpecificWithWarehouse.Code);
        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Two purchase orders of the item: "PO1" and "PO2".
        // [GIVEN] "PO1" has three lines with lot = "L1" and quantity = 2 pcs.
        // [GIVEN] "PO2" has two lines with lot = "L2" and quantity = 3 pcs.
        // [GIVEN] Transfer all purchased quantity of the item to the WMS-location. Transfer Order No. = "TO".
        // [GIVEN] "TO" has one line with "L1" and "L2" lots and quantity = 12 pcs.
        // [GIVEN] "TO" is shipped.
        CreateAndPostTrackedPurchaseLinesAndTransferFullQtyInSingleLine(TransferHeader, Item."No.", LotNo);

        // [WHEN] Create and post warehouse receipt of "TO".
        CreateAndPostWhseReceiptFromInboundTransfer(TransferHeader, WarehouseReceiptHeader);

        // [THEN] Put-away is created for both "L1" and "L2" lots, each for 6 pcs.
        for i := 1 to ArrayLen(LotNo) do begin
            FindWarehouseActivityLine(
              WarehouseActivityLine, TransferHeader."No.", WarehouseActivityLine."Source Document"::"Inbound Transfer",
              LocationWhite.Code, Item."No.", LotNo[i], WarehouseActivityLine."Activity Type"::"Put-away");
            WarehouseActivityLine.TestField("Qty. (Base)", 2 * 3);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayForPostedWhseReceiptWhenLotConsistsOfSeveralItemEntries()
    var
        Item: Record Item;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TransferHeader: Record "Transfer Header";
        LotNo: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Posted Whse. Receipt] [Put-away]
        // [SCENARIO 209278] Put-away should be created for all lots in posted whse. receipt line, if quantity of each lot consists of several item entries.
        Initialize();

        // [GIVEN] Lot-tracked item, lot warehouse tracking is enabled.
        CreateItem(Item, ItemTrackingCodeLotSpecificWithWarehouse.Code);
        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Two purchase orders of the item: "PO1" and "PO2".
        // [GIVEN] "PO1" has three lines with lot = "L1" and quantity = 2 pcs.
        // [GIVEN] "PO2" has two lines with lot = "L2" and quantity = 3 pcs.
        // [GIVEN] Transfer all purchased quantity of the item to the WMS-location. Transfer Order No. = "TO".
        // [GIVEN] "TO" has one line with "L1" and "L2" lots and quantity = 12 pcs.
        // [GIVEN] "TO" is shipped.
        CreateAndPostTrackedPurchaseLinesAndTransferFullQtyInSingleLine(TransferHeader, Item."No.", LotNo);

        // [GIVEN] Create and post warehouse receipt of "TO".
        CreateAndPostWhseReceiptFromInboundTransfer(TransferHeader, WarehouseReceiptHeader);

        // [GIVEN] Delete put-away.
        FindWarehouseActivityHeader(
          WarehouseActivityHeader, TransferHeader."No.", WarehouseActivityLine."Source Document"::"Inbound Transfer",
          LocationWhite.Code, Item."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityHeader.Delete(true);

        // [WHEN] Create put-away from the posted warehouse receipt.
        CreatePutAwayFromPostedWhseReceipt(WarehouseReceiptHeader."No.");

        // [THEN] Put-away is created for both "L1" and "L2" lots, each for 6 pcs.
        for i := 1 to ArrayLen(LotNo) do begin
            FindWarehouseActivityLine(
              WarehouseActivityLine, TransferHeader."No.", WarehouseActivityLine."Source Document"::"Inbound Transfer",
              LocationWhite.Code, Item."No.", LotNo[i], WarehouseActivityLine."Activity Type"::"Put-away");
            WarehouseActivityLine.TestField("Qty. (Base)", 2 * 3);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DropShipmentSalesArchiveThroughPostPurchase()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesLineArchive: Record "Sales Line Archive";
        RequisitionLine: Record "Requisition Line";
        OrderQty: Decimal;
        ResidualQty: Decimal;
        ShipReceiveQty: Decimal;
    begin
        // [FEATURE] [Drop Shipment] [Sales] [Archive]
        // [SCENARIO 225698] When partly post Drop Shipment Sales through Purchase Order "Sales Line Archive"."Qty. to Ship" = "Purchase Line"."Qty. to Receive"
        Initialize();

        // [GIVEN] "Archive Quotes and Orders" set in "Sales & Receivables Setup", "Default Quantity to Ship" = Remainder
        LibrarySales.SetArchiveOrders(true);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Quantity to Ship", SalesReceivablesSetup."Default Quantity to Ship"::Remainder);
        SalesReceivablesSetup.Modify(true);

        ShipReceiveQty := LibraryRandom.RandIntInRange(10, 20);
        ResidualQty := LibraryRandom.RandIntInRange(10, 20);
        OrderQty := ShipReceiveQty + ResidualQty;

        // [GIVEN] Drop Shipment Sales Order "DSO"
        CreateItemWithVendorNo(Item);
        CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), Item."No.", OrderQty);
        GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(SalesLine, RequisitionLine, false);

        // [WHEN] Post receive of corresponding Purchase Order "PO" with "Qty. to Receive" < "DSO"."Quantity"
        FindPurchaseLine(PurchaseLine, Item."No.");
        PurchaseLine.Validate("Qty. to Receive", ShipReceiveQty);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] "Sales Line Archive" is created, "Qty. to Ship" = "PO"."Qty. to Receive"
        SalesLineArchive.SetRange("Document Type", SalesLine."Document Type");
        SalesLineArchive.SetRange("Document No.", SalesLine."Document No.");
        SalesLineArchive.FindFirst();
        SalesLineArchive.TestField("Qty. to Ship", ShipReceiveQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DropShipmentPurchaseArchiveThroughPostSales()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLineArchive: Record "Purchase Line Archive";
        RequisitionLine: Record "Requisition Line";
        OrderQty: Decimal;
        ResidualQty: Decimal;
        ShipReceiveQty: Decimal;
    begin
        // [FEATURE] [Drop Shipment] [Purchase] [Archive]
        // [SCENARIO 225698] When partly post Drop Shipment Purchase through Sales Order "Sales Line Archive"."Qty. to Ship" = "Purchase Line"."Qty. to Receive"
        Initialize();

        // [GIVEN] "Archive Quotes and Orders" set in "Purchases & Payables Setup", "Default Qty. to Receive" = Remainder
        LibraryPurchase.SetArchiveOrders(true);
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Qty. to Receive", PurchasesPayablesSetup."Default Qty. to Receive"::Remainder);
        PurchasesPayablesSetup.Modify(true);

        ShipReceiveQty := LibraryRandom.RandIntInRange(10, 20);
        ResidualQty := LibraryRandom.RandIntInRange(10, 20);
        OrderQty := ShipReceiveQty + ResidualQty;

        // [GIVEN] Drop Shipment Sales Order "DSO"
        CreateItemWithVendorNo(Item);
        CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), Item."No.", OrderQty);
        GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(SalesLine, RequisitionLine, false);

        // [WHEN] Post shipment of "DSO" with "Qty. to Ship" < "Quantity"
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", ShipReceiveQty);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] "Purchase Line Archive" is created, "Qty. to Receive" = "DSO"."Qty. to Ship"
        PurchaseLineArchive.SetRange("No.", Item."No.");
        PurchaseLineArchive.FindFirst();
        PurchaseLineArchive.TestField("Qty. to Receive", ShipReceiveQty);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ItemTrackingDropShipmentPageHandler,ConfirmFalseHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostDropShipmentSalesSideDifferentLotNosTrackingNotSynchedError()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 263607] Drop shipment with a lot tracked item cannot be posted when item tracking on purchase and sales sides is not synchronized

        Initialize();

        // [GIVEN] Item "I" with outbound item tracking by lot nos.
        // [GIVEN] Drop shipment for item "I". Assign lot no. "L1" in the sales line
        // [GIVEN] Assign lot no. "L2" in the purchase line
        CreateDropShipmentSalesAndPurchaseTracked(SalesLine, LibraryRandom.RandIntInRange(3, 6), AssignTracking::LotNo);

        // [WHEN] Post the sales order
        asserterror PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", true, false);

        // [THEN] Posting failed with an error reading that item tracking is not synchronized
        Assert.ExpectedError(ItemTrackingNotMatch);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ConfirmFalseHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostDropShipmentSalesSideDifferentSerialNosTrackingNotSynchedError()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 263607] Drop shipment with an SN tracked item cannot be posted when item tracking on purchase and sales sides is not synchronized

        Initialize();

        // [GIVEN] Item "I" with outbound item tracking by serial nos.
        // [GIVEN] Drop shipment for 3 pcs item "I". Assign serial numbers "S1" through "S3" in the sales line
        // [GIVEN] Assign serial nos. "S4" through "S6" in the purchase line
        CreateDropShipmentSalesAndPurchaseTracked(SalesLine, LibraryRandom.RandIntInRange(3, 6), AssignTracking::SerialNo);

        // [WHEN] Post the sales order
        asserterror PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", true, false);

        // [THEN] Posting failed with an error reading that item tracking is not synchronized
        Assert.ExpectedError(ItemTrackingNotMatch);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ItemTrackingDropShipmentPageHandler')]
    [Scope('OnPrem')]
    procedure PostDropShipmentSalesSideLotTrackingEntriesApplied()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 263607] Drop shipment can be posted on the sales side when the purchase order has no item tracking, and the sales order is tracked by lot no.

        Initialize();

        // [GIVEN] Item "I" with outbound item tracking by lot nos.
        // [GIVEN] Drop shipment for item "I". Assign lot no. "L1" in the sales line
        CreateDropShipmentSalesTracked(SalesLine, PurchaseLine, LibraryRandom.RandIntInRange(3, 6), AssignTracking::LotNo);

        // [WHEN] Post shipment from the sales order
        PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", true, false);

        // [THEN] Purchase order is received, sales order is shipped
        VerifyPurchaseLineReceived(PurchaseLine);
        VerifySalesLineShipped(SalesLine);

        // [THEN] Outbound item ledger entry is applied to the inbound entry
        VerifyItemLedgerEntryApplied(SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ItemTrackingDropShipmentPageHandler')]
    [Scope('OnPrem')]
    procedure PostDropShipmentPurchaseSideLotTrackingEntriesApplied()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 263607] Drop shipment can be posted on the purchase side when the purchase order has no item tracking, and the sales order is tracked by lot no.

        Initialize();

        // [GIVEN] Item "I" with outbound item tracking by lot nos.
        // [GIVEN] Drop shipment for item "I". Assign lot no. "L1" in the sales line
        CreateDropShipmentSalesTracked(SalesLine, PurchaseLine, LibraryRandom.RandIntInRange(3, 6), AssignTracking::LotNo);

        // [GIVEN] Post receipt from the purchase order
        PostPurchaseDocument(PurchaseLine."Document Type", PurchaseLine."Document No.", true, false);

        // [THEN] Purchase order is received, sales order is shipped
        VerifyPurchaseLineReceived(PurchaseLine);
        VerifySalesLineShipped(SalesLine);

        // [THEN] Outbound item ledger entry is applied to the inbound entry
        VerifyItemLedgerEntryApplied(SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostDropShipmentSalesSideSerialNoTrackingEntriesApplied()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 263607] Drop shipment can be posted on the sales side when the purchase order has no item tracking, and the sales order is tracked by serial no.
        Initialize();

        // [GIVEN] Item "I" with outbound item tracking by serial nos.
        // [GIVEN] Drop shipment for 3 pcs of item "I". Assign serial numbers in the sales line
        CreateDropShipmentSalesTracked(SalesLine, PurchaseLine, LibraryRandom.RandIntInRange(3, 6), AssignTracking::SerialNo);

        // [WHEN] Post shipment in the sales order
        PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", true, false);

        // [THEN] Purchase order is received, sales order is shipped
        VerifyPurchaseLineReceived(PurchaseLine);
        VerifySalesLineShipped(SalesLine);

        // [THEN] Outbound item ledger entries are applied to the inbound entry
        VerifyItemLedgerEntryApplied(SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostDropShipmentPurchaseSideSerialNoTrackingEntriesApplied()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 263607] Drop shipment can be posted on the purchase side when the purchase order has no item tracking, and the sales order is tracked by serial no.

        Initialize();

        // [GIVEN] Item "I" with outbound item tracking by serial nos.
        // [GIVEN] Drop shipment for 3 pcs of item "I". Assign serial numbers in the sales line
        CreateDropShipmentSalesTracked(SalesLine, PurchaseLine, LibraryRandom.RandIntInRange(3, 6), AssignTracking::SerialNo);

        // [GIVEN] Post receipt in the purchase order
        PostPurchaseDocument(PurchaseLine."Document Type", PurchaseLine."Document No.", true, false);

        // [THEN] Purchase order is received, sales order is shipped
        VerifyPurchaseLineReceived(PurchaseLine);
        VerifySalesLineShipped(SalesLine);

        // [THEN] Outbound item ledger entries are applied to the inbound entry
        VerifyItemLedgerEntryApplied(SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ConfirmFalseHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostDropShipmentSalesSideTrackingOnPurchaseError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 263607] Drop shipment cannot be posted on the sales side when the sales order has no item tracking, and the purchase order is tracked by serial no.

        Initialize();

        // [GIVEN] Item "I" with outbound item tracking by serial nos.
        CreateItem(Item, CreateNonSpecificPurchItemTrackingCode(false, true));

        // [GIVEN] Drop shipment for 3 pcs of item "I". Assign serial numbers in the purchase line, sales side has no tracking
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", '', 1, false);
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        AssignTracking := AssignTracking::SerialNo;
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        PurchaseLine.OpenItemTrackingLines();

        // [WHEN] Post the sales order
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Posting failed with an error reading that item tracking is not synchronized
        Assert.ExpectedError(ItemTrackingNotMatch);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,ConfirmFalseHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostDropShipmentPurchaseSideTrackingOnPurchaseError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 263607] Drop shipment cannot be posted on the purchase side when the sales order has no item tracking, and the purchase order is tracked by serial no.

        Initialize();

        // [GIVEN] Item "I" with outbound item tracking by serial nos.
        CreateItem(Item, CreateNonSpecificPurchItemTrackingCode(false, true));

        // [GIVEN] Drop shipment for 3 pcs of item "I". Assign serial numbers in the purchase line, sales side has no tracking
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", '', 1, false);
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        AssignTracking := AssignTracking::SerialNo;
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        PurchaseLine.OpenItemTrackingLines();

        // [WHEN] Post the purchase order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Posting failed with an error reading that item tracking is not synchronized
        Assert.ExpectedError(ItemTrackingNotMatch);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ItemTrackingDropShipmentPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingDropShipmentSalesAfterReceivingTwoLinesOneTrackedAnotherNot()
    var
        TrackedItem: Record Item;
        NonTrackedItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 267926] Drop shipment sales order with two item lines - the first is lot-tracked, the second has no tracking - can be invoiced after you receive the linked purchase order.
        Initialize();

        // [GIVEN] Lot-tracked item "LI".
        // [GIVEN] Non-tracked item "NI".
        LibraryItemTracking.CreateLotItem(TrackedItem);
        LibraryInventory.CreateItem(NonTrackedItem);

        // [GIVEN] Sales order "SO" with two lines - "LI" and "NI". The sales order is set up for drop shipment.
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, TrackedItem."No.", NonTrackedItem."No.", LibraryRandom.RandInt(10), true);

        // [GIVEN] Create a purchase order via using "Get Drop Shipment".
        // [GIVEN] Assign a lot no. to the purchase line with "LI" item.
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        AssignTracking := AssignTracking::LotNo;
        PurchaseLine.OpenItemTrackingLines();

        // [GIVEN] The purchase is received.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Post the sales invoice.
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] The sales order is successfully invoiced.
        SelectSalesInvoiceLine(SalesInvoiceLine, SalesHeader."No.");
        SalesInvoiceLine.TestField("No.", TrackedItem."No.");
        SalesInvoiceLine.Next();
        SalesInvoiceLine.TestField("No.", NonTrackedItem."No.");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ItemTrackingDropShipmentPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingDropShipmentSalesAfterShippingTwoLinesOneTrackedAnotherNot()
    var
        TrackedItem: Record Item;
        NonTrackedItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 267926] Drop shipment sales order with two item lines - the first is lot-tracked, the second has no tracking - can be invoiced after you post the shipment.
        Initialize();

        // [GIVEN] Lot-tracked item "LI".
        // [GIVEN] Non-tracked item "NI".
        LibraryItemTracking.CreateLotItem(TrackedItem);
        LibraryInventory.CreateItem(NonTrackedItem);

        // [GIVEN] Sales order "SO" with two lines - "LI" and "NI". The sales order is set up for drop shipment.
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, TrackedItem."No.", NonTrackedItem."No.", LibraryRandom.RandInt(10), true);

        // [GIVEN] Create a purchase order via using "Get Drop Shipment".
        // [GIVEN] Assign a lot no. to the sales line for "LI" item.
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        SelectSalesLine(SalesLine, SalesHeader."No.");
        AssignTracking := AssignTracking::LotNo;
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] The sales order is shipped.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Post the sales invoice.
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] The sales order is successfully invoiced.
        SelectSalesInvoiceLine(SalesInvoiceLine, SalesHeader."No.");
        SalesInvoiceLine.TestField("No.", TrackedItem."No.");
        SalesInvoiceLine.Next();
        SalesInvoiceLine.TestField("No.", NonTrackedItem."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingCreatedOnlyForQtyToShipWhenCopiedFromBlanketSalesOrder()
    var
        Item: Record Item;
        BlanketSalesHeader: Record "Sales Header";
        BlanketSalesLine: Record "Sales Line";
        SalesLine: Record "Sales Line";
        SalesOrderNo: Code[20];
        LotNo: Code[50];
    begin
        // [FEATURE] [Sales] [Blanket Order] [Order]
        // [SCENARIO 340083] Item Tracking on a sales order line created from blanket order matches the quantity being ordered.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Lot-tracked item with inventory.
        LibraryItemTracking.CreateLotItem(Item);
        CreateAndPostItemJnlLineWithLot(Item."No.", LotNo, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Blanket sales order for 100 pcs, assign lot no.
        LibrarySales.CreateSalesDocumentWithItem(
          BlanketSalesHeader, BlanketSalesLine, BlanketSalesHeader."Document Type"::"Blanket Order", '',
          Item."No.", LibraryRandom.RandIntInRange(50, 100), '', WorkDate());
        LibraryVariableStorage.Enqueue(AssignTracking::GivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(BlanketSalesLine.Quantity);
        BlanketSalesLine.OpenItemTrackingLines();

        // [GIVEN] Set "Qty. to Ship" on the blanket line to 10 pcs.
        UpdateQtyToShipOnSalesLine(BlanketSalesLine, LibraryRandom.RandInt(10));

        // [WHEN] Make sales order from the blanket order.
        SalesOrderNo := LibrarySales.BlanketSalesOrderMakeOrder(BlanketSalesHeader);

        // [THEN] Sales order for 10 pcs is created.
        SelectSalesLine(SalesLine, SalesOrderNo);
        SalesLine.TestField(Quantity, BlanketSalesLine."Qty. to Ship");
        SalesLine.TestField(Quantity, BlanketSalesLine."Qty. to Ship");

        // [THEN] Quantity and "Qty. to Ship" in item tracking assigned to the sales order line are equal to 10 pcs.
        LibraryVariableStorage.Enqueue(AssignTracking::GetQty);
        LibraryVariableStorage.Enqueue(LotNo);
        SalesLine.OpenItemTrackingLines();
        Assert.AreEqual(SalesLine.Quantity, LibraryVariableStorage.DequeueDecimal(), '');
        Assert.AreEqual(SalesLine."Qty. to Ship", LibraryVariableStorage.DequeueDecimal(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandler,ItemTrackingLotPageHandler')]
    [Scope('OnPrem')]
    procedure PartialPickWithItemTrackingDefinedInBothSourceDocAndPick()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ReservationEntry: Record "Reservation Entry";
        ItemNo: Code[20];
        LotNos: array[2] of Code[20];
        LotQty: array[2] of Decimal;
        TotalQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Warehouse Pick]
        // [SCENARIO 373704] Posting pick of some lots inherited from the source document and others suggested by the picking engine.
        Initialize();

        // [GIVEN] Lot-tracked item.
        ItemNo := CreateItemWithLotTracking();

        // [GIVEN] Post 10 pcs of lot "L1" and 15 pcs of lot "L2" to inventory.
        for i := 1 to ArrayLen(LotNos) do begin
            LotNos[i] := LibraryUtility.GenerateGUID();
            LotQty[i] := LibraryRandom.RandIntInRange(10, 20);
            TotalQty += LotQty[i];
            UpdateInventoryWithLotViaWhseJournal(ItemNo, LocationWhite.Code, LotNos[i], LotQty[i]);
        end;

        // [GIVEN] Sales order for 25 pcs.
        // [GIVEN] Open item tracking lines and assign only 10 pcs of lot "L1".
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, SalesLine.Type::Item, '', ItemNo, TotalQty, LocationWhite.Code);
        LibraryVariableStorage.Enqueue(AssignTracking::GivenLotNo);
        LibraryVariableStorage.Enqueue(LotNos[1]);
        LibraryVariableStorage.Enqueue(LotQty[1]);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Release the sales order, create shipment and pick.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] Zoom to the pick line with lot "L1" and set "Qty. to Handle" = 5.
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order", LocationWhite.Code,
          ItemNo, LotNos[1], WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.ModifyAll("Qty. to Handle (Base)", LotQty[1] / 2);

        // [GIVEN] Assign lot "L2" to another pick line for 15 pcs.
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order", LocationWhite.Code,
          ItemNo, '''''', WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.ModifyAll("Lot No.", LotNos[2]);

        // [WHEN] Register the pick.
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] 20 pcs have been picked.
        RegisteredWhseActivityLine.SetRange("Action Type", RegisteredWhseActivityLine."Action Type"::Take);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.CalcSums("Qty. (Base)");
        RegisteredWhseActivityLine.TestField("Qty. (Base)", TotalQty - LotQty[1] / 2);

        // [THEN] Item tracking lines show 25 pcs for the sales line.
        ReservationEntry.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", true);
        ReservationEntry.CalcSums(Quantity, "Qty. to Handle (Base)");
        ReservationEntry.TestField(Quantity, -TotalQty);
        ReservationEntry.TestField("Qty. to Handle (Base)", -TotalQty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler,SynchronizeItemTrackingConfirmHandler,MessageHandler')]
    procedure ClearSurplusForDropShipmentSalesAfterSynchronizeItemTrackingFromPurchase()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        LotNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Order Tracking]
        // [SCENARIO 414437] Order tracking surplus entry for drop shipment sales is deleted when you synchronize item tracking from purchase side.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Lot-tracked item with order tracking.
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] Sales order for drop shipment.
        CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, '', Item."No.", Qty);

        // [GIVEN] Create purchase order using "Get Sales Orders" in requisition worksheet.
        GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(SalesLine, RequisitionLine, false);

        // [GIVEN] Ensure that order tracking entries are created.
        FindPurchaseLine(PurchaseLine, Item."No.");
        VerifyTrackingOnDropShipment(SalesLine, PurchaseLine, '');

        // [WHEN] Assign lot no. "L" on the purchase line and synchronize the item tracking with the sales line.
        LibraryVariableStorage.Enqueue(AssignTracking::GivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        PurchaseLine.OpenItemTrackingLines();

        // [THEN] Item tracking is synchronized.
        // [THEN] Only reservation entries with lot no. "L" exist for both purchase and sales.
        VerifyTrackingOnDropShipment(SalesLine, PurchaseLine, LotNo);

        // [THEN] Purchase order can be posted together with the sales order.
        // [THEN] None of reservation entries and action message entries exist for the item.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VerifyReservEntriesNotExist(Item."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler,ConfirmHandler,MessageHandler')]
    procedure ClearSurplusForDropShipmentSalesAfterSynchronizeItemTrackingFromSales()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        LotNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Order Tracking]
        // [SCENARIO 414437] Order tracking surplus entry for drop shipment sales is deleted when you synchronize item tracking from sales side.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Lot-tracked item with order tracking.
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] Sales order for drop shipment.
        CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, '', Item."No.", Qty);

        // [GIVEN] Create purchase order using "Get Sales Orders" in requisition worksheet.
        GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(SalesLine, RequisitionLine, false);

        // [GIVEN] Ensure that order tracking entries are created.
        FindPurchaseLine(PurchaseLine, Item."No.");
        VerifyTrackingOnDropShipment(SalesLine, PurchaseLine, '');

        // [WHEN] Assign lot no. "L" on the sales line and synchronize the item tracking with the purchase line.
        SalesLine.Find();
        LibraryVariableStorage.Enqueue(AssignTracking::GivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        SalesLine.OpenItemTrackingLines();

        // [THEN] Item tracking is synchronized.
        // [THEN] Only reservation entries with lot no. "L" exist for both purchase and sales.
        VerifyTrackingOnDropShipment(SalesLine, PurchaseLine, LotNo);

        // [THEN] Purchase order can be posted together with the sales order.
        // [THEN] None of reservation entries and action message entries exist for the item.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VerifyReservEntriesNotExist(Item."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandler')]
    procedure ItemTrackingNotSynchronizedToShipmentFromWhsePickSortedByBin()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        Zone: Record Zone;
        Bin: array[3] of Record Bin;
        ItemA: Record Item;
        ItemB: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LotA1: Code[20];
        LotA2: Code[20];
        LotB1: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Warehouse] [Shipment] [Pick] [Sorting]
        // [SCENARIO 420049] Item tracking on all pick lines must be synchronized to the source document regardless of how the pick lines are sorted.
        Initialize();

        // [GIVEN] Location set up for directed put-away and pick.
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Items "A" and "B" with lot tracking.
        ItemA.Get(CreateItemWithLotTracking());
        LotA1 := LibraryUtility.GenerateGUID();
        LotA2 := LibraryUtility.GenerateGUID();

        ItemB.Get(CreateItemWithLotTracking());
        LotB1 := LibraryUtility.GenerateGUID();

        // [GIVEN] Bins "B1", "B2", "B3" in pick zone.
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        for i := 1 to ArrayLen(Bin) do
            LibraryWarehouse.FindBin(Bin[i], Location.Code, Zone.Code, i);

        // [GIVEN] Post three warehouse journal lines -
        // [GIVEN] Item "A", lot "L1" to bin "B1".
        // [GIVEN] Item "A", lot "L2" to bin "B3" (important!).
        // [GIVEN] Item "B", lot "L3" to bin "B2".
        UpdateInventoryInBinWithLotNo(Bin[1], ItemA."No.", LotA1, 1);
        UpdateInventoryInBinWithLotNo(Bin[3], ItemA."No.", LotA2, 2);
        UpdateInventoryInBinWithLotNo(Bin[2], ItemB."No.", LotB1, 3);

        // [GIVEN] Transfer order for items "A" and "B".
        // [GIVEN] Release the order, create warehouse shipment and pick.
        LibraryInventory.CreateTransferHeader(TransferHeader, Location.Code, LocationBlue.Code, LocationIntransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemA."No.", 3);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemB."No.", 3);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(
          WarehouseShipmentHeader, TransferHeader."No.", WarehouseActivityLine."Source Document"::"Outbound Transfer");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] Select lots in the pick.
        UpdateLotNoOnWhseActivityLines(ItemA."No.", 1, LotA1);
        UpdateLotNoOnWhseActivityLines(ItemA."No.", 2, LotA2);
        UpdateLotNoOnWhseActivityLines(ItemB."No.", 3, LotB1);

        // [GIVEN] Set "Sorting Method" for the pick to "Shelf or Bin".
        // [GIVEN] Thus, the pick lines related to the first transfer line will be split by those for the second transfer line, as follows:
        // [GIVEN] PICK LINES:
        // [GIVEN] Item "A", lot "L1", transfer line 1
        // [GIVEN] Item "B", lot "L3", transfer line 2
        // [GIVEN] Item "A", lot "L2", transfer line 1
        FindWarehouseActivityLine(
          WarehouseActivityLine, TransferHeader."No.", WarehouseActivityLine."Source Document"::"Outbound Transfer",
          Location.Code, ItemA."No.", '', WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeader.Validate("Sorting Method", WarehouseActivityHeader."Sorting Method"::"Shelf or Bin");
        WarehouseActivityHeader.SortWhseDoc();
        WarehouseActivityHeader.Modify(true);

        // [WHEN] Register the pick.
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetCurrentKey("Sorting Sequence No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Whse.-Activity-Register", WarehouseActivityLine);

        // [THEN] The lots are properly assigned to the transfer lines.
        VerifyReservationEntryExists(ItemA."No.", LotA1);
        VerifyReservationEntryExists(ItemA."No.", LotA2);
        VerifyReservationEntryExists(ItemB."No.", LotB1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler,ConfirmHandler,MessageHandler')]
    procedure NegativeConsumptionDoesNotStartBranchInItemTracing()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ProductionBOMHeader: Record "Production BOM Header";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ProductionOrder: Record "Production Order";
        TempItemTracingBuffer: Record "Item Tracing Buffer" temporary;
        TempItemTracingBuffer2: Record "Item Tracing Buffer" temporary;
        ItemTracingMgt: Codeunit "Item Tracing Mgt.";
        Direction: Option Forward,Backward;
        ShowComponents: Option No,"Item-tracked only",All;
        CompLotNo: Code[20];
        ProdLotNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracing] [Consumption] [Reverse]
        // [SCENARIO 447643] Reversed consumption does not make a root node in item tracing.
        // [SCENARIO 447643] Usage of reversed consumption in another production order is shown as its sub-tree.
        Initialize();
        CompLotNo := LibraryUtility.GenerateGUID();
        ProdLotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Lot-tracked production item "P" and component item "C".
        LibraryItemTracking.CreateLotItem(CompItem);
        ItemTrackingCode.Get(CompItem."Item Tracking Code");
        UpdateItemTrackingCode(ItemTrackingCode, ItemTrackingCodeSerialSpecific.FieldNo("Lot Warehouse Tracking"), false);
        LibraryItemTracking.CreateLotItem(ProdItem);
        ItemTrackingCode.Get(ProdItem."Item Tracking Code");
        UpdateItemTrackingCode(ItemTrackingCode, ItemTrackingCodeSerialSpecific.FieldNo("Lot Warehouse Tracking"), false);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ProdItem."Base Unit of Measure", CompItem."No.");
        UpdateProductionBOMNoOnItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Post item "C" to inventory, assign lot no. = "LC".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItem."No.", LocationYellow2.Code, '', Qty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, '', CompLotNo, ItemJournalLine."Quantity (Base)");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] First production order for item "P".
        // [GIVEN] Assign lot no. "LP" for the production item, select lot "LC" for the component.
        // [GIVEN] Post output and consumption.
        CreateRefreshAndPostProductionOrderWithItemTracking(ProductionOrder, ProdItem."No.", ProdLotNo, CompItem."No.", CompLotNo, Qty);

        // [GIVEN] Reverse the consumption, lot "LC" will be used for another production.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", CompItem."No.", CompLotNo, -Qty);

        // [GIVEN] Second production order for item "P".
        // [GIVEN] Assign lot no. "LP" for the production item, select lot "LC" for the component.
        // [GIVEN] Post output and consumption.
        CreateRefreshAndPostProductionOrderWithItemTracking(ProductionOrder, ProdItem."No.", ProdLotNo, CompItem."No.", CompLotNo, Qty);

        // [WHEN] Run item tracing for lot "LC" in Origin->Usage direction.
        ItemTracingMgt.FindRecords(
          TempItemTracingBuffer, TempItemTracingBuffer2, '', CompLotNo, '', CompItem."No.", '', Direction::Forward, ShowComponents::All);

        // [THEN] Find the reversed consumption. Ensure it has indentation > 0, which means it is not a root node.
        // [THEN] The item tracing tree will be as follows:
        // [THEN] Invt. adjmt. +1 qty.
        // [THEN] |__Consumption -1 qty., prod. order "1"
        // [THEN] |____Consumption +1 qty., prod. order "1"
        // [THEN] |______Consumption -1 qty., prod. order "2"
        // [THEN] |________Output +1 qty., prod. order "2"
        // [THEN] |____Output +1 qty., prod. order "1"
        TempItemTracingBuffer.SetRange("Entry Type", TempItemTracingBuffer."Entry Type"::Consumption);
        TempItemTracingBuffer.SetRange(Quantity, Qty);
        TempItemTracingBuffer.FindFirst();
        Assert.IsTrue(TempItemTracingBuffer.Level > 0, 'Reversed consumption cannot be the top node in Item Tracing tree.');
        TempItemTracingBuffer.Reset();
        TempItemTracingBuffer.Next();
        TempItemTracingBuffer.TestField("Entry Type", TempItemTracingBuffer."Entry Type"::Consumption);
        TempItemTracingBuffer.TestField("Document No.", ProductionOrder."No.");
        TempItemTracingBuffer.TestField("Lot No.", CompLotNo);
        TempItemTracingBuffer.Next();
        TempItemTracingBuffer.TestField("Entry Type", TempItemTracingBuffer."Entry Type"::Output);
        TempItemTracingBuffer.TestField("Document No.", ProductionOrder."No.");
        TempItemTracingBuffer.TestField("Lot No.", ProdLotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandlerTrackingOptionWithLot,MessageHandler,ConfirmHandler')]
    procedure VerifyReservationEntryMustExistWhenItemTrackingPageIsClosed()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingOption: Option AssignLotNoManual,AssignLotNos,ChangeLotQty;
        SalesOrderSubform: TestPage "Sales Order Subform";
        LotNos: array[2] of Code[50];
        LotQty: array[2] of Decimal;
        TotalQty: Decimal;
        i, ExpectedQty : Integer;
    begin
        // [SCENARIO 491329] Verify Reservation Entry must exist When Item Tracking Page is closed.
        Initialize();

        // [GIVEN] Change the work date to today.
        WorkDate(Today);

        // [GIVEN] Generate a random expected quantity.
        ExpectedQty := LibraryRandom.RandInt(2);

        // [GIVEN] Create an item with item tracking.
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(20, 2));
        Item.Validate("Unit Price", LibraryRandom.RandDec(50, 2));
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);

        // [GIVEN] Create a location with the inventory posting setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create an item journal template.
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);

        // [GIVEN] Create an item journal batch.
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [GIVEN] Create lot numbers and quantities to assign on item tracking lines, and post positive adjustments with item tracking.
        for i := 1 to ArrayLen(LotNos) do begin
            LotNos[i] := LibraryUtility.GenerateGUID();
            LotQty[i] := LibraryRandom.RandInt(10);
            TotalQty += LotQty[i];

            PostItemJournalLineWithItemTracking(Location, Item, LotNos[i], LotQty[i]);
        end;

        // [GIVEN] Create a sales order with a shipment date and location.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Shipment Date", WorkDate());
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        // [GIVEN] Create a sales line.
        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Item,
            Item."No.",
            TotalQty - ExpectedQty);

        // [GIVEN] Update the shipment date in the sales line.
        SalesLine.Validate("Shipment Date", CalcDate('<1M-CM>', WorkDate()));
        SalesLine.Modify(true);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Change item No. to a non-existent item in the sales line.
        SalesOrderSubform.OpenEdit();
        SalesOrderSubform.GotoRecord(SalesLine);
        asserterror SalesOrderSubform."No.".SetValue(LibraryRandom.RandText(5));
        SalesOrderSubform.Close();

        // [GIVEN] Change item number to old item in the sales line.
        SalesLine.Validate("No.", Item."No.");
        SalesLine.Modify(true);

        // [GIVEN] Assign Lot No. in the sales line.
        for i := 1 to ArrayLen(LotNos) do begin
            LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNoManual);
            LibraryVariableStorage.Enqueue(LotNos[i]);

            if i = ArrayLen(LotNos) then
                LibraryVariableStorage.Enqueue(LotQty[i] - ExpectedQty)
            else
                LibraryVariableStorage.Enqueue(LotQty[i]);

            SalesLine.OpenItemTrackingLines();
        end;

        // [GIVEN] Change the shipment date to workdate in the sales line.
        SalesOrderSubform.OpenEdit();
        SalesOrderSubform.GotoRecord(SalesLine);
        SalesOrderSubform."Shipment Date".SetValue(CalcDate('<1M-CM>', WorkDate()));
        SalesOrderSubform.Close();

        // [WHEN] Delete the item tracking lines from the sales line.
        for i := 1 to ArrayLen(LotNos) do begin
            LibraryVariableStorage.Enqueue(ItemTrackingOption::ChangeLotQty);
            LibraryVariableStorage.Enqueue(LotNos[i]);
            LibraryVariableStorage.Enqueue(0);

            SalesLine.OpenItemTrackingLines();
        end;

        // [VERIFY] Verify the remaining quantity of the item from the reservation entry.
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.CalcSums(Quantity);
        Assert.AreEqual(
            ExpectedQty,
            ReservationEntry.Quantity,
            StrSubstNo(
                RemainingQtyMustBeEqualErr,
                ExpectedQty,
                ReservationEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPick_AllowsPartialLotShipment()
    var
        ComPItem, FinishItem : Record Item;
        FromLocation, ToLocation : Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionBOMHeader: Record "Production BOM Header";
        WorkCenter: Record "Work Center";
        TransferRoute: Record "Transfer Route";
        SKU: array[2] of Record "Stockkeeping Unit";
        ProductionOrder: Record "Production Order";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RoutingNo: Code[20];
        FinishItemNo: Code[20];
        LotNo: Code[50];
    begin
        // [SCENARIO 580075] Inventory Pick allows partial shipment of Sales Line with Lot tracking.
        Initialize();

        // [GIVEN] Create locations.
        LibraryWarehouse.CreateLocationWMS(FromLocation, false, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(ToLocation, false, false, true, false, false);

        // [GIVEN] Create warehouse employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ToLocation.Code, false);

        // [GIVEN] Create transfer route.
        LibraryInventory.CreateAndUpdateTransferRoute(TransferRoute, FromLocation.Code, ToLocation.Code, LocationInTransit.Code, '', '');

        // [GIVEN] Create work center with calendar.
        CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Create component item with Purchase Replenishment System.
        LibraryInventory.CreateItem(ComPItem);
        ComPItem.Validate("Replenishment System", ComPItem."Replenishment System"::Purchase);
        ComPItem.Modify();

        // [GIVEN] Create inventory for component item.
        CreateInventory(ComPItem, 1000, '', 1);

        // [GIVEN] Create finished item with Lot tracking.
        FinishItemNo := CreateItemWithLotTracking();
        FinishItem.Get(FinishItemNo);
        FinishItem.Validate("Lot Nos.", '');
        FinishItem.Modify();

        // [GIVEN] Create routing with work center.
        RoutingNo := CreateRoutingWithWorkCenter(WorkCenter."No.", 10, 10, 0);

        // [GIVEN] Create and certify production BOM for finished item.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, FinishItem."Base Unit of Measure", ComPItem."No.");

        // [GIVEN] Update production BOM and routing number on finished item.
        UpdateProductionBOMAndRoutingNoOnItem(FinishItem, ProductionBOMHeader."No.", RoutingNo);

        // [GIVEN] Set replenishment system, manufacturing policy, reordering policy, and order tracking policy for finished item.
        FinishItem.Validate("Replenishment System", ComPItem."Replenishment System"::"Prod. Order");
        FinishItem.Validate("Manufacturing Policy", FinishItem."Manufacturing Policy"::"Make-to-Order");
        FinishItem.Validate("Reordering Policy", FinishItem."Reordering Policy"::" ");
        FinishItem.Validate("Order Tracking Policy", FinishItem."Order Tracking Policy"::None);
        FinishItem.Modify(true);

        // [GIVEN] Create stockkeeping units for finished item at FromLocation
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU[1], FromLocation.Code, FinishItem."No.", '');
        SKU[1].Validate("Replenishment System", SKU[1]."Replenishment System"::"Prod. Order");
        SKU[1].Validate("Reordering Policy", SKU[1]."Reordering Policy"::Order);
        SKU[1].Modify(true);

        // [GIVEN] Create stockkeeping unit for finished item at ToLocation.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU[2], ToLocation.Code, FinishItem."No.", '');
        SKU[2].Validate("Replenishment System", SKU[1]."Replenishment System"::Transfer);
        SKU[2].Validate("Reordering Policy", SKU[1]."Reordering Policy"::Order);
        SKU[2].Validate("Transfer-From Code", FromLocation.Code);
        SKU[2].Modify(true);

        // [GIVEN] Sales Order for 500 at ToLocation
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, FinishItem."No.", ToLocation.Code, 10, true);

        // [GIVEN] Generate a random Lot No. for tracking.
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create and release production order for 2 units of FinishItem
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, FinishItem."No.", FromLocation.Code, '', 2);
        LibraryVariableStorage.Enqueue(AssignTracking::GivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(2);

        // [GIVEN] Post output journal with tracking for the production order.
        CreateAndPostOutputJournalWithTracking(ProductionOrder."No.");

        // [GIVEN] Create transfer order for 10 units of FinishItem from FromLocation to ToLocation.
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, FinishItem."No.", 10);

        // [GIVEN] Add item tracking to transfer line with Lot No. and quantity 2.
        TransferLine.Validate("Qty. to Ship", 2);
        TransferLine.Modify();
        AddItemTrackingToTransferLine(TransferLine, LotNo, 2);

        // [GIVEN] Post transfer header with item tracking.
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [GIVEN] Create and Refresh released production order for FinishItem for 1 unit.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, FinishItem."No.", FromLocation.Code, '', 1);
        LibraryVariableStorage.Enqueue(AssignTracking::GivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(1);

        // [GIVEN] Post output journal with tracking for the production order.
        CreateAndPostOutputJournalWithTracking(ProductionOrder."No.");

        // [GIVEN] Sales Line is set to be shipped partially ("Qty. to Ship" = "X").
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Modify(true);

        // [GIVEN] Binding in Reservation Entries of Sale is set to "Order-to-Order".
        LibraryVariableStorage.Enqueue(AssignTracking::GivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(2);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Create Inventory Pick for Sales Line
        CreateInventoryPick(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.");

        // [WHEN] Post Inventory Pick.
        PostInventoryActivity(
            SalesLine."Document No.",
            WarehouseActivityLine."Source Document"::"Sales Order",
            ToLocation.Code,
            FinishItem."No.",
            WarehouseActivityLine."Activity Type"::"Invt. Pick"
        );

        // [VERIFY] Quantity Shipped on Sales Line = 2
        SalesLine.Find();
        Assert.AreEqual(
            2, SalesLine."Quantity Shipped",
            StrSubstNo(
                IncorrectShippedQtyMsg,
                SalesLine.FieldCaption("Quantity Shipped"),
                SalesLine.FieldCaption("Qty. to Ship"))
        );
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,SalesListPageHandler,AvailabilityConfirmHandler')]
    procedure PurchaseOrderMustBePostedWithDropShipmentSerialNoWithoutPostingOfSalesInvoice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO 295310] Verify that system must allow to post a Purchase Invoice against a drop shipment Purchase Order prior to posting a Sales Invoice against the related Sales Order.
        Initialize();

        // [GIVEN] Create an item with Serial No. tracking.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);

        // [GIVEN] Create a sales order with drop shipment.
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", '', LibraryRandom.RandIntInRange(50, 100), false);

        // [GIVEN] Assign Global variable for Page Handler. Assign Tracking as SerialNo.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);

        // [GIVEN] Open Item Tracking Lines for Sales Line.
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Create a purchase order for drop shipment.
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [GIVEN] Assign Global variable for Page Handler. PartialTracking as True.
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, 0);

        // [GIVEN] Assign Tracking on Purchase Line.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");

        // [GIVEN] Post Sales Document with shipment only.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, false);

        // [WHEN] Post Purchase Document with invoice.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // [THEN] Verify that the Posted Purchase Invoice has been created and that the Posted Sales Invoice has not been created yet.
        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.RecordIsEmpty(SalesInvoiceHeader);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingDropShipmentPageHandler,QuantityToCreatePageHandler,SalesListPageHandler,AvailabilityConfirmHandler')]
    procedure PurchaseInvoiceMustBePostedWithDropShipmentSerialNoWithoutPostingOfSalesInvoice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO 295310] Verify that system must allow to post a Purchase Invoice via "Get Receipt Lines" from against a drop shipment Purchase Order prior to posting a Sales Invoice against the related Sales Order.
        Initialize();

        // [GIVEN] Create an item with Serial No. tracking.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code);

        // [GIVEN] Create a sales order with drop shipment.
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", '', LibraryRandom.RandIntInRange(50, 100), false);

        // [GIVEN] Assign Global variable for Page Handler. Assign Tracking as SerialNo.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0);

        // [GIVEN] Open Item Tracking Lines for Sales Line.
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Create a purchase order for drop shipment.
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [GIVEN] Assign Global variable for Page Handler. PartialTracking as True.
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, 0);

        // [GIVEN] Assign Tracking on Purchase Line.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");

        // [GIVEN] Post Sales Document with shipment only.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, false);

        // [WHEN] Create Purchase Invoice for previous receipt and post it.
        CreateAndPostPurchInvoice(PurchaseHeader);

        // [THEN] Verify that the Posted Purchase Invoice has been created and that the Posted Sales Invoice has not been created yet.
        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.RecordIsEmpty(SalesInvoiceHeader);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM RTAM Item Tracking-II");
        LibrarySetupStorage.Restore();
        ClearGlobals();
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM RTAM Item Tracking-II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        NoSeriesSetup();
        ItemTrackingCodeSetup();
        ItemJournalSetup();
        CreateLocationSetup();
        OutputJournalSetup();
        ConsumptionJournalSetup();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM RTAM Item Tracking-II");
    end;

    local procedure CreateWorkCenterWithCalendar(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Work Center Group Code", '1');
        WorkCenter.Validate("Direct Unit Cost", 50);
        WorkCenter.Validate("Unit of Measure Code", 'HOURS');
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Validate(Efficiency, 100);
        WorkCenter.Validate("Shop Calendar Code", '1');
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1Y>', WorkDate()), CalcDate('<2M>', WorkDate()));
    end;

    local procedure CreateRoutingWithWorkCenter(WorkCenterNo: Code[20]; SetupTime: Decimal; RunTime: Decimal; LotSize: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Lot Size", LotSize);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure ClearGlobals()
    begin
        Clear(CreateNewLotNo);
        Clear(UpdateTracking);
        Clear(AssignTracking);
        Clear(PartialTracking);
        Clear(TrackingQuantity);
        Clear(MessageCounter);
        Clear(GlobalDocumentNo);
        Clear(ItemTrackingAction);
        Clear(QuantityBase);
        Clear(GlobalItemNo);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateInTransitLocation(LocationIntransit);

        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, false, false, false, false);
        LibraryWarehouse.CreateLocationWMS(LocationYellow, false, true, true, true, true);
        LibraryWarehouse.CreateLocationWMS(LocationYellow2, false, false, false, true, true);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationYellow.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationYellow2.Code, false);
    end;

    local procedure ItemTrackingCodeSetup()
    begin
        CreateItemTrackingCode(ItemTrackingCodeSerialSpecific, ItemTrackingCodeSerialSpecific.FieldNo("SN Specific Tracking"), true);  // Tracking for SN Specific Tracking.
        UpdateItemTrackingCode(ItemTrackingCodeSerialSpecific, ItemTrackingCodeSerialSpecific.FieldNo("SN Warehouse Tracking"), false);
        CreateItemTrackingCode(ItemTrackingCodeSerialSpecificWithWarehouse, ItemTrackingCodeSerialSpecificWithWarehouse.FieldNo("SN Specific Tracking"), true);
        CreateItemTrackingCode(ItemTrackingCodeLotSpecific, ItemTrackingCodeLotSpecific.FieldNo("Lot Specific Tracking"), true);  // Tracking for Lot Specific Tracking.
        UpdateItemTrackingCode(ItemTrackingCodeLotSpecific, ItemTrackingCodeLotSpecificWithWarehouse.FieldNo("Lot Warehouse Tracking"), false);
        CreateItemTrackingCode(ItemTrackingCodeLotSpecificWithWarehouse, ItemTrackingCodeLotSpecificWithWarehouse.FieldNo("Lot Specific Tracking"), true);
    end;

    local procedure OutputJournalSetup()
    begin
        Clear(OutputItemJournalTemplate);
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);

        Clear(OutputItemJournalBatch);
        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
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
        ItemJournalBatch.Validate("No. Series", '');
        ItemJournalBatch.Modify(true);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        Clear(ConsumptionItemJournalTemplate);
        ConsumptionItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);

        Clear(ConsumptionItemJournalBatch);
        ConsumptionItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type, ConsumptionItemJournalTemplate.Name);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; FieldNo: Integer; Value: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        UpdateItemTrackingCode(ItemTrackingCode, FieldNo, Value);
    end;

    local procedure UpdateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Update Item Tracking Code based on Field and its corresponding value.
        RecRef.GetTable(ItemTrackingCode);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(ItemTrackingCode);
        ItemTrackingCode.Modify(true);
    end;

    local procedure SetGlobalValue(ItemNo: Code[20]; NewLotNo: Boolean; UpdateTrackingValue: Boolean; PartialTrackingValue: Boolean; AssignTrackingValue: Option; TrackingQuantity2: Decimal)
    begin
        GlobalItemNo := ItemNo;
        CreateNewLotNo := NewLotNo;
        UpdateTracking := UpdateTrackingValue;
        PartialTracking := PartialTrackingValue;
        AssignTracking := AssignTrackingValue;
        TrackingQuantity := TrackingQuantity2;
    end;

    local procedure CreateItem(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);  // Assign Tracking Code.
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateItemWithLotTracking(): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(
          ItemTrackingCode, ItemTrackingCode.FieldNo("Lot Specific Tracking"), true);
        UpdateItemTrackingCode(
          ItemTrackingCode, ItemTrackingCode.FieldNo("Lot Warehouse Tracking"), true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithVendorNo(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateAndPostItemJnlLineWithLot(ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        LibraryVariableStorage.Enqueue(AssignTracking::GivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        // Purchase Order.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, ItemNo, LocationCode, Quantity);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        // Purchase Return Order.
        CreateAndReleasePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", ItemNo, LocationCode, Quantity);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocumentType, '', ItemNo, Quantity, LocationCode, 0D);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreatePurchasingCodeWithDropShipment(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
    end;

    local procedure PostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; No: Code[20]; Receive: Boolean; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, No);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, Receive, Invoice);
    end;

    local procedure CreateAndPostPurchaseOrderWithLotTrackedLines(LocationCode: Code[10]; ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal; NoOfLines: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        for i := 1 to NoOfLines do begin
            CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, LocationCode, Qty);
            LibraryVariableStorage.Enqueue(AssignTracking::GivenLotNo);
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue(Qty);
            PurchaseLine.OpenItemTrackingLines();
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Release: Boolean)
    begin
        // Create Sales Order
        CreateAndReleaseSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, ItemNo, LocationCode, Quantity, Release);
    end;

    local procedure CreateAndReleaseSalesReturnOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Release: Boolean)
    begin
        // Create Sales Order
        CreateAndReleaseSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", ItemNo, LocationCode, Quantity, Release);
    end;

    local procedure CreateAndReleaseSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Release: Boolean)
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocumentType, '', ItemNo, Quantity, LocationCode, 0D);
        if Release then
            LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateDropShipmentSalesTracked(var SalesLine: Record "Sales Line"; var PurchaseLine: Record "Purchase Line"; Quantity: Integer; TrackingOption: Option)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateItem(
          Item,
          CreateNonSpecificSalesItemTrackingCode(TrackingOption = AssignTracking::LotNo, TrackingOption = AssignTracking::SerialNo));

        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", '', Quantity, false);
        CreatePurchaseHeaderAndGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.");

        AssignTracking := TrackingOption;
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateDropShipmentSalesAndPurchaseTracked(var SalesLine: Record "Sales Line"; Quantity: Decimal; TrackingOption: Option)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreateDropShipmentSalesTracked(SalesLine, PurchaseLine, Quantity, TrackingOption);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateNonSpecificPurchItemTrackingCode(LotInboundTracking: Boolean; SNInboundTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Purchase Inbound Tracking", LotInboundTracking);
        ItemTrackingCode.Validate("SN Purchase Inbound Tracking", SNInboundTracking);
        ItemTrackingCode.Modify(true);

        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateNonSpecificSalesItemTrackingCode(LotOutboundTracking: Boolean; SNOutboundTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", LotOutboundTracking);
        ItemTrackingCode.Validate("SN Sales Outbound Tracking", SNOutboundTracking);
        ItemTrackingCode.Modify(true);

        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateSalesOrderWithDropShipment(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        Purchasing: Record Purchasing;
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, SalesLine.Type::Item, CustomerNo, ItemNo, Quantity, '');
        CreatePurchasingCodeWithDropShipment(Purchasing);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, Type, ItemNo, Quantity, LocationCode);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQtyToShipOnSalesLine(var SalesLine: Record "Sales Line"; QtyToShip: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure PostSalesDocument(DocumentType: Enum "Sales Document Type"; No: Code[20]; Ship: Boolean; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, No);
        LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);
    end;

    local procedure CreateAndShipTransferOrderWithLotTrackedLines(var TransferHeader: Record "Transfer Header"; LocationFromCode: Code[10]; LocationToCode: Code[10]; LocationInTransitCode: Code[10]; ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal; NoOfLines: Integer)
    var
        TransferLine: Record "Transfer Line";
        i: Integer;
    begin
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFromCode, LocationToCode, LocationInTransitCode);
        for i := 1 to NoOfLines do begin
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
            AddItemTrackingToTransferLine(TransferLine, LotNo, Qty);
        end;
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
    end;

    local procedure AddItemTrackingToTransferLine(var TransferLine: Record "Transfer Line"; LotNo: Code[50]; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(AssignTracking::GivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure SelectSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure SelectPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchInvHeader(var PurchInvHeader: Record "Purch. Inv. Header"; OrderNo: Code[20])
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst();
    end;

    local procedure SelectPurchInvLine(var PurchInvLine: Record "Purch. Inv. Line"; OrderNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        FindPurchInvHeader(PurchInvHeader, OrderNo);
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.FindFirst();
    end;

    local procedure FindSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; OrderNo: Code[20])
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst();
    end;

    local procedure SelectSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; OrderNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        FindSalesInvoiceHeader(SalesInvoiceHeader, OrderNo);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
    end;

    local procedure UpdatePurchasingCodeOnSalesLine(DocumentNo: Code[20]; PurchasingCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SelectSalesLine(SalesLine, DocumentNo);
        repeat
            SalesLine.Validate("Purchasing Code", PurchasingCode);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure AssignTrackingOnRequisitionLine(var RequisitionLine: Record "Requisition Line"; ReqWkshTemplateName: Code[10]; RequisitionWkshNameName: Code[10])
    begin
        RequisitionLine.SetRange("Worksheet Template Name", ReqWkshTemplateName);
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshNameName);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.FindFirst();
        repeat
            RequisitionLine.OpenItemTrackingLines();
        until RequisitionLine.Next() = 0;
    end;

    local procedure CreateRequisitionWorksheetName(var ReqWkshTemplate: Record "Req. Wksh. Template"; var RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Planning);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure UpdateQtyToInvoiceOnSalesLine(DocumentNo: Code[20]; QtyToInvoice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SelectSalesLine(SalesLine, DocumentNo);
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQtyToInvoiceOnPurchaseLine(DocumentNo: Code[20]; QtyToInvoice: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseLine(PurchaseLine, DocumentNo);
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQtyToReceiveOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    begin
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");  // Get Latest Instance, Important for Test.
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure AssignTrackingOnPurchaseLine(DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseLine(PurchaseLine, DocumentNo);
        repeat
            PurchaseLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler.
        until PurchaseLine.Next() = 0;
    end;

    local procedure GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(var SalesLine: Record "Sales Line"; var RequisitionLine: Record "Requisition Line"; TrackingOnRequisition: Boolean)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        CreateRequisitionWorksheetName(ReqWkshTemplate, RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");

        if TrackingOnRequisition then
            AssignTrackingOnRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure UpdateQuantityToReceiveOnMultiplePurchaseLines(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; QtyToReceive: Decimal)
    begin
        SelectPurchaseLine(PurchaseLine, DocumentNo);
        repeat
            UpdateQtyToReceiveOnPurchaseLine(PurchaseLine, PurchaseLine.Quantity - QtyToReceive);  // Update Quantity to receive partially on Purchase lines.
        until PurchaseLine.Next() = 0;
    end;

    local procedure CreateSalesOrderWithPurchasingCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; MultipleLines: Boolean)
    var
        Purchasing: Record Purchasing;
    begin
        CreatePurchasingCodeWithDropShipment(Purchasing);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, ItemNo, '', Quantity, false);
        if MultipleLines then
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo2, Quantity);
        UpdatePurchasingCodeOnSalesLine(SalesHeader."No.", Purchasing.Code);
        GlobalDocumentNo := SalesHeader."No.";  // Assign Global Variable for page handler.
    end;

    local procedure CreatePurchaseHeaderAndGetDropShipment(var PurchaseHeader: Record "Purchase Header"; SellToCustomerNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.GetDropShipment(PurchaseHeader);
    end;

    local procedure CreateAndPostTrackedPurchaseAndCreateSalesOrderWithPartialShip(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(0);
        CreateAndPostItemJournalLineWithTracking(
          ItemJournalLine."Entry Type"::Purchase, ItemNo, LocationCode, LibraryRandom.RandIntInRange(20, 30), 0, 0);

        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, ItemNo, LocationCode, LibraryRandom.RandIntInRange(11, 20), true);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        SalesLine.Validate("Qty. to Ship", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity - SalesLine."Qty. to Ship");
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateAndPostTrackedPurchaseLinesAndTransferFullQtyInSingleLine(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; LotNo: array[2] of Code[20])
    var
        TransferLine: Record "Transfer Line";
        i: Integer;
    begin
        CreateAndPostPurchaseOrderWithLotTrackedLines(LocationBlue.Code, ItemNo, LotNo[1], 2, 3); // 3 lines, each for 2 pcs
        CreateAndPostPurchaseOrderWithLotTrackedLines(LocationBlue.Code, ItemNo, LotNo[2], 3, 2); // 2 lines, each for 3 pcs

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationBlue.Code, LocationWhite.Code, LocationIntransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, 2 * 3 + 3 * 2);
        for i := 1 to ArrayLen(LotNo) do
            AddItemTrackingToTransferLine(TransferLine, LotNo[i], 2 * 3);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
    end;

    local procedure FindWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        SelectWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, SourceDocument);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
    end;

    local procedure SelectWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; LocationCode: Code[10]; ItemNo: Code[20]; LotNoFilter: Text; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetFilter("Lot No.", LotNoFilter);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; LocationCode: Code[10]; ItemNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, SourceDocument, LocationCode, ItemNo, '', ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; LocationCode: Code[10]; ItemNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; AutoFillQuantity: Boolean) WhseActivityHeaderNo: Code[20]
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo, SourceDocument, LocationCode, ItemNo, ActivityType);
        if AutoFillQuantity then
            LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        WhseActivityHeaderNo := WarehouseActivityHeader."No.";
    end;

    local procedure RegisterAndDeleteWarehouseActivity(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; LocationCode: Code[10]; ItemNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.Get(
          ActivityType, RegisterWarehouseActivity(SourceNo, SourceDocument, LocationCode, ItemNo, ActivityType, false));
        WarehouseActivityHeader.Delete(true);
    end;

    local procedure PostInventoryActivity(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; LocationCode: Code[10]; ItemNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo, SourceDocument, LocationCode, ItemNo, ActivityType);
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;

    local procedure PostWhseReceiptAndRegisterWarehouseActivity(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; LocationCode: Code[10]; ItemNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; AutoFillQuantity: Boolean)
    begin
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        RegisterWarehouseActivity(SourceNo, SourceDocument, LocationCode, ItemNo, ActivityType, AutoFillQuantity);
    end;

    local procedure SelectWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        SelectWarehouseShipmentLine(WarehouseShipmentLine, SourceNo, SourceDocument);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure CreateWhseWorksheetName(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; Type: Enum "Warehouse Worksheet Template Type")
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, Type);
        WhseWorksheetTemplate.FindFirst();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    local procedure FindWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateRefreshAndPostProductionOrderWithItemTracking(var ProductionOrder: Record "Production Order"; ProdItemNo: Code[20]; ProdLotNo: Code[20]; CompItemNo: Code[20]; CompLotNo: Code[20]; Qty: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationEntry: Record "Reservation Entry";
    begin
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItemNo, LocationYellow2.Code, '', Qty);
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, '', ProdLotNo, ProdOrderLine."Quantity (Base)");
        FindProdOrderComponent(ProdOrderComponent, ProdOrderLine, CompItemNo);
        if ProdOrderComponent.Quantity <> ProdOrderComponent."Expected Quantity" then begin
            ProdOrderComponent.Validate(Quantity, ProdOrderComponent."Expected Quantity");
            ProdOrderComponent.Validate("Quantity (Base)", ProdOrderComponent."Expected Qty. (Base)");
            ProdOrderComponent.Modify();
        end;
        LibraryManufacturing.CreateProdOrderCompItemTracking(
          ReservationEntry, ProdOrderComponent, '', CompLotNo, ProdOrderComponent."Quantity (Base)");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure CreateAndPostOutputJournalWithTracking(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExlpodeRouting(ProductionOrderNo);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        ItemJournalLine.OpenItemTrackingLines(false);  // Assign Tracking on Page handler ItemTrackingDropShipmentPageHandler.
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournalWithExlpodeRouting(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindBin(var Zone: Record Zone; var Bin: Record Bin; ZoneCode: Code[10]; BinCode: Code[20]; LocationCode: Code[10])
    begin
        Zone.Get(LocationWhite.Code, ZoneCode);
        Bin.SetRange(Code, '<>%1', BinCode);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, 1);  // Index.
    end;

    local procedure CreateWhseInternalPutawayHeader(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; FromZonecode: Code[10]; FromBinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseInternalPutawayHdr(WhseInternalPutAwayHeader, LocationWhite.Code);
        WhseInternalPutAwayHeader.Validate("From Zone Code", FromZonecode);
        WhseInternalPutAwayHeader.Validate("From Bin Code", FromBinCode);
        WhseInternalPutAwayHeader.Modify(true);
    end;

    local procedure CreateWhseInternalPickHeader(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; FromZonecode: Code[10]; FromBinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseInternalPickHeader(WhseInternalPickHeader, LocationWhite.Code);
        WhseInternalPickHeader.Validate("To Zone Code", FromZonecode);
        WhseInternalPickHeader.Validate("To Bin Code", FromBinCode);
        WhseInternalPickHeader.Modify(true);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
    end;

    local procedure CreateWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WorksheetTemplateName: Code[10]; Name: Code[10]; WhseDocumentType: Enum "Warehouse Worksheet Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateWhseWorksheetLine(WhseWorksheetLine, WorksheetTemplateName, Name, LocationCode, WhseDocumentType);
        WhseWorksheetLine.Validate("Item No.", ItemNo);
        WhseWorksheetLine.Validate(Quantity, Quantity);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure UpdateBinAndZoneCodeOnWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; FromZoneCode: Code[10]; FromBinCode: Code[20]; ToZoneCode: Code[10]; ToBinCode: Code[20])
    begin
        WhseWorksheetLine.Validate("From Zone Code", FromZoneCode);
        WhseWorksheetLine.Validate("From Bin Code", FromBinCode);
        WhseWorksheetLine.Validate("To Zone Code", ToZoneCode);
        WhseWorksheetLine.Validate("To Bin Code", ToBinCode);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure FilterOnWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WorksheetTemplateName: Code[10]; Name: Code[10]; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WorksheetTemplateName);
        WhseWorksheetLine.SetRange(Name, Name);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.SetRange("Item No.", ItemNo);
    end;

    local procedure SelectWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, LocationIntransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrderWithTracking(var PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; PostReceipt: Boolean; SetExpirationDate: Boolean)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, ItemNo, LocationCode, Quantity);
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking on Page handler ItemTrackingDropShipmentPageHandler.
        if SetExpirationDate then
            UpdateReservationEntry(ItemNo, CalcDate('<+1Y>', WorkDate()));
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptHeader(WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");
        if PostReceipt then
            PostWhseReceiptAndRegisterWarehouseActivity(
              WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order", LocationWhite.Code,
              ItemNo, WarehouseActivityLine."Activity Type"::"Put-away", true);
    end;

    local procedure CreateAndReleaseWhseShipmentFromSalesOrderWithTracking(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Tracking: Boolean)
    var
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, Quantity, true);  // Release.
        if Tracking then
            SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingDropShipmentPageHandler.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure UpdateQtyToHandleOnWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; QtyToHandle: Decimal)
    begin
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode);
        WhseWorksheetLine.Validate("Qty. to Handle", QtyToHandle);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure UpdateQtyToShipOnWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20]; QtyToShip: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        SelectWarehouseShipmentLine(WarehouseShipmentLine, SourceNo, WarehouseActivityLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.Validate("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure CreateProductionOrderAndPostOutputJournalWithTracking(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ItemNo, LocationCode, BinCode, Quantity);
        CreateAndPostOutputJournalWithTracking(ProductionOrder."No.");
    end;

    local procedure CreateWhseInternalPutawayWithTracking(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal; Tracking: Boolean)
    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseIntPutAwayRelease: Codeunit "Whse. Int. Put-away Release";
    begin
        CreateWhseInternalPutawayHeader(WhseInternalPutAwayHeader, ZoneCode, BinCode);
        LibraryWarehouse.CreateWhseInternalPutawayLine(WhseInternalPutAwayHeader, WhseInternalPutAwayLine, ItemNo, Quantity);
        WhseIntPutAwayRelease.Release(WhseInternalPutAwayHeader);
        ItemTrackingAction := ItemTrackingAction::AvailabilitySerialNo;  // Assign Global variable for Page Handler.
        if Tracking then
            WhseInternalPutAwayLine.OpenItemTrackingLines();  // Assign Tracking on Page handler ItemTrackingPageHandler.
    end;

    local procedure CreatePutAwayDocAndRegisterWarehouseActivity(WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; LocationCode: Code[10]; RegisterActivity: Boolean)
    begin
        WhseInternalPutAwayLine.CreatePutAwayDoc(WhseInternalPutAwayLine);
        SelectWarehouseActivityLine(WarehouseActivityLine, ItemNo);
        if RegisterActivity then
            RegisterWarehouseActivity(
              '', WarehouseActivityLine."Source Document"::" ", LocationCode, ItemNo, WarehouseActivityLine."Activity Type"::"Put-away", false);
    end;

    local procedure CreatePutAwayFromPutAwayWorksheet(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; ItemNo: Code[20]; Tracking: Boolean)
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
    begin
        CreateWhseWorksheetName(WhseWorksheetName, LocationCode, WhseWorksheetTemplate.Type::"Put-away");
        FilterOnWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode, ItemNo);
        GetSourceDocInbound.GetSingleWhsePutAwayDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode);
        WhseWorksheetLine.FindFirst();

        WhseWorksheetLine.AutofillQtyToHandle(WhseWorksheetLine);
        if Tracking then
            WhseWorksheetLine.OpenItemTrackingLines();  // Assign Tracking on Page handler ItemTrackingPageHandler.
        Commit();  // Commit is requried for Test Cases.
        WhseWorksheetLine.PutAwayCreate(WhseWorksheetLine);
        SelectWarehouseActivityLine(WarehouseActivityLine, ItemNo);
    end;

    local procedure CreatePutAwayFromPostedWhseReceipt(WhseReceiptNo: Code[20])
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WhseReceiptNo);
        PostedWhseReceiptHeader.FindFirst();

        PostedWhseReceiptLine.SetHideValidationDialog(true);
        PostedWhseReceiptLine.SetRange("No.", PostedWhseReceiptHeader."No.");
        PostedWhseReceiptLine.FindFirst();
        PostedWhseReceiptLine.CreatePutAwayDoc(PostedWhseReceiptLine, '');
    end;

    local procedure CreateMovementFormMovementWorkSheet(WhseWorksheetName: Record "Whse. Worksheet Name"; WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetLine2: Record "Whse. Worksheet Line";
        Bin: Record Bin;
        Zone: Record Zone;
    begin
        FindBin(Zone, Bin, WarehouseActivityLine."Zone Code", WarehouseActivityLine."Bin Code", LocationCode);
        CreateWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          WhseWorksheetLine."Whse. Document Type"::"Whse. Mov.-Worksheet", ItemNo, LocationCode, Quantity);
        UpdateBinAndZoneCodeOnWhseWorksheetLine(
          WhseWorksheetLine, WarehouseActivityLine."Zone Code", WarehouseActivityLine."Bin Code", Zone.Code, Bin.Code);
        FilterOnWhseWorksheetLine(
          WhseWorksheetLine2, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode, ItemNo);
        WhseWorksheetLine.AutofillQtyToHandle(WhseWorksheetLine2);
        WhseWorksheetLine.OpenItemTrackingLines();  // Assign Tracking on Page handler ItemTrackingPageHandler.
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine2);
    end;

    local procedure CreatePickFromPickWorksheet(WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; ItemNo: Code[20]; Tracking: Boolean)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode);
        FilterOnWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode, ItemNo);
        WhseWorksheetLine.FindFirst();
        if Tracking then
            WhseWorksheetLine.OpenItemTrackingLines();  // Assign Tracking on Page handler ItemTrackingPageHandler.
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          LocationCode, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
    end;

    local procedure CreateWhseInternalPick(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; var WhseInternalPickLine: Record "Whse. Internal Pick Line"; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal; Tracking: Boolean)
    var
        WhseInternalPickRelease: Codeunit "Whse. Internal Pick Release";
    begin
        CreateWhseInternalPickHeader(WhseInternalPickHeader, ZoneCode, BinCode);
        LibraryWarehouse.CreateWhseInternalPickLine(WhseInternalPickHeader, WhseInternalPickLine, ItemNo, Quantity);
        if Tracking then
            WhseInternalPickLine.OpenItemTrackingLines();  // Assign Tracking on Page handler ItemTrackingPageHandler.
        WhseInternalPickRelease.Release(WhseInternalPickHeader);
    end;

    local procedure CreateInventoryPick(SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20])
    var
        WarehouseRequest: Record "Warehouse Request";
        CreateInvtPutAwayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
    begin
        WarehouseRequest.SetRange("Source Type", SourceType);
        WarehouseRequest.SetRange("Source Subtype", SourceSubtype);
        WarehouseRequest.SetRange("Source No.", SourceNo);
        Commit();
        CreateInvtPutAwayPickMvmt.InitializeRequest(false, true, false, false, false);
        CreateInvtPutAwayPickMvmt.SuppressMessages(true);
        CreateInvtPutAwayPickMvmt.UseRequestPage(false);
        CreateInvtPutAwayPickMvmt.SetTableView(WarehouseRequest);
        CreateInvtPutAwayPickMvmt.RunModal();
    end;

    local procedure UpdateWarehouseAndBinPoliciesOnLocation(var Location: Record Location; UsePutAwayWorksheet: Boolean; AlwaysCreatePutAwayLine: Boolean)
    begin
        Location.Validate("Use Put-away Worksheet", UsePutAwayWorksheet);
        Location.Validate("Always Create Put-away Line", AlwaysCreatePutAwayLine);
        Location.Modify(true);
    end;

    local procedure CreateTransferOrderAndPostWhseReceipt(var TransferHeader: Record "Transfer Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, FromLocation, ToLocation, ItemNo, Quantity);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);  // Assign Tracking on Page handler ItemTrackingDropShipmentPageHandler.
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        CreateAndPostWhseReceiptFromInboundTransfer(TransferHeader, WarehouseReceiptHeader);
    end;

    local procedure CreateAndPostWhseReceiptFromInboundTransfer(var TransferHeader: Record "Transfer Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
        FindWarehouseReceiptHeader(
          WarehouseReceiptHeader, TransferHeader."No.", WarehouseReceiptLine."Source Document"::"Inbound Transfer");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure UpdateQtyToHandleCreateAndRegisterPickFromPickWorksheet(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        UpdateQtyToHandleOnWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode, QtyToHandle);
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          LocationCode, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        RegisterWarehouseActivity(
          SourceNo, WarehouseActivityLine."Source Document"::"Sales Order", LocationCode, ItemNo,
          WarehouseActivityLine."Activity Type"::Pick, true);
    end;

    local procedure UpdateQtyToHandleOnWhsePutawayLine(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; LocationCode: Code[10]; ItemNo: Code[20]; LotNo: Code[50]; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, SourceNo, SourceDocument, LocationCode, ItemNo, LotNo, WarehouseActivityLine."Activity Type"::"Put-away");
        for i := WarehouseActivityLine."Action Type"::Take.AsInteger() to WarehouseActivityLine."Action Type"::Place.AsInteger() do begin
            WarehouseActivityLine.SetRange("Action Type", i);
            WarehouseActivityLine.FindLast();
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        end;
    end;

    local procedure UpdateQtyToShipAndPostWhseShipment(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20]; QtyToShip: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        UpdateQtyToShipOnWarehouseShipmentLine(WarehouseShipmentLine, SourceNo, QtyToShip);
        WarehouseShipmentLine.OpenItemTrackingLines();  // Assign Tracking on Page handler ItemTrackingDropShipmentPageHandler.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure UpdateSerialAndLotNoOnWarehouseActivityLine(ItemNo: Code[20]; ProductionOrderNo: Code[20]; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, ItemNo);
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", LocationCode, ItemNo, '',
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Serial No.", ItemLedgerEntry."Serial No.");
            WarehouseActivityLine.Validate("Lot No.", ItemLedgerEntry."Lot No.");
            WarehouseActivityLine.Modify(true);
            ItemLedgerEntry.Next();
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure FindPostedWhseReceiptHeader(WhseReceiptNo: Code[20])
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
    begin
        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WhseReceiptNo);
        PostedWhseReceiptHeader.FindFirst();
        GlobalDocumentNo := PostedWhseReceiptHeader."No.";  // Assign Global variable for Page Handler.
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateComponentsAtLocationSetup(NewComponentsAtLocation: Code[10]) ComponentsAtLocation: Code[10]
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ComponentsAtLocation := ManufacturingSetup."Components at Location";
        ManufacturingSetup.Validate("Components at Location", NewComponentsAtLocation);
        ManufacturingSetup.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLineWithTracking(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Amount: Decimal; AssignTrackingValue: Option)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJnlLine(ItemJournalLine, EntryType, ItemNo, LocationCode, Quantity, Amount);
        AssignTracking := AssignTrackingValue;  // Assign Global variable for Page Handler.
        ItemJournalLine.OpenItemTrackingLines(false);  // Assign Tracking on Page Handler.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AssignTracking := AssignTracking::None;  // Assign Global variable for Page Handler.
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        UpdateItemJnlLineDocNo(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        ItemJournalLine.OpenItemTrackingLines(false);  // Assign Tracking Line on Page Handler.
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CreateAndPostConsumptionJournalWithItemTracking(ProductionOrderNo: Code[20]; ItemNo: Code[20]; LotNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Consumption, ItemNo, Qty);
        ItemJournalLine.Validate("Order No.", ProductionOrderNo);
        ItemJournalLine.Validate("Location Code", LocationYellow2.Code);
        ItemJournalLine.Modify(true);
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine."Quantity (Base)");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateBinAndBinContent(var Bin: Record Bin; Item: Record Item; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBin(
          Bin, LocationSilver.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure UpdateItemJnlLineDocNo(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.ModifyAll("Document No.", LibraryUtility.GenerateGUID());
    end;

    local procedure UpdateWarehouseSetupPostingPolicy(NewPostingPolicy: Option) PostingPolicy: Integer
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        PostingPolicy := WarehouseSetup."Shipment Posting Policy";
        WarehouseSetup.Validate("Shipment Posting Policy", NewPostingPolicy);
        WarehouseSetup.Validate("Receipt Posting Policy", NewPostingPolicy);
        WarehouseSetup.Modify(true);
    end;

    local procedure WhseGetBinContentAndReleaseWhseIntPutAway(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseIntPutAwayRelease: Codeunit "Whse. Int. Put-away Release";
    begin
        WhseWorksheetLine.Init();  // Required for PRECAL.
        BinContent.SetRange("Location Code", LocationCode);
        LibraryWarehouse.WhseGetBinContent(
            BinContent, WhseWorksheetLine, WhseInternalPutAwayHeader, "Warehouse Destination Type 2"::WhseInternalPutawayHeader);
        WhseIntPutAwayRelease.Release(WhseInternalPutAwayHeader);
    end;

    local procedure CreateOutputJournalWithTracking(ProductionOrderNo: Code[20]; ItemNo: Code[20]; OutputQuantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ItemNo, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure FindWhseInternalPutAwayLine(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; No: Code[20]; ItemNo: Code[20])
    begin
        WhseInternalPutAwayLine.SetRange("No.", No);
        WhseInternalPutAwayLine.SetRange("Item No.", ItemNo);
        WhseInternalPutAwayLine.FindFirst();
    end;

    local procedure UpdateProductionBOMNoOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure RunItemTracing(var ItemTracing: TestPage "Item Tracing"; ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ShowComponents: Option No,"Item-tracked Only",All;
        TraceMethod: Option "Origin->Usage","Usage->Origin";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Consumption, ItemNo);
        ItemTracing.OpenView();
        ItemTracing.SerialNoFilter.SetValue(ItemLedgerEntry."Serial No.");
        ItemTracing.ShowComponents.SetValue(ShowComponents::All);
        ItemTracing.TraceMethod.SetValue(TraceMethod::"Origin->Usage");
        ItemTracing.Trace.Invoke();
    end;

    local procedure UpdateReservationEntry(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Expiration Date", ExpirationDate, true);
    end;

    local procedure UpdateLotNoOnInventoryMovementLine(ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; ItemNo: Code[20]; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(
          WarehouseActivityLine, '', "Warehouse Activity Source Document"::" ", LocationCode, ItemNo, '', WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure MoveFromBinTypeToBinType(var BinType: Record "Bin Type"; var BinTypeBuffer: Record "Bin Type")
    begin
        BinTypeBuffer.Reset();
        BinTypeBuffer.DeleteAll();

        BinType.Reset();
        if BinType.FindSet() then
            repeat
                BinTypeBuffer := BinType;
                BinTypeBuffer.Insert();
            until BinType.Next() = 0;
        BinType.DeleteAll();
    end;

    local procedure GetLotNoFromItemLedgEntry(ItemNo: Code[20]; DocNo: Code[20]): Code[20]
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Document No.", DocNo);
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.FindFirst();
        exit(ItemLedgEntry."Lot No.");
    end;

    local procedure CreateInvtMvtFromInternalMvtWithLotNo(LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20]; LotNo: Code[50])
    var
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, LocationCode, BinCode);
        LibraryWarehouse.GetBinContentInternalMovement(
          InternalMovementHeader, LocationCode, ItemNo, BinCode);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
        UpdateLotNoOnInventoryMovementLine(WarehouseActivityLine."Action Type"::Take, LocationCode, ItemNo, LotNo);
        UpdateLotNoOnInventoryMovementLine(WarehouseActivityLine."Action Type"::Place, LocationCode, ItemNo, LotNo);
    end;

    local procedure PostItemJnlLineWithLotTrackingAndBinCode(var ItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20])
    begin
        CreateItemJnlLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LocationCode, LibraryRandom.RandInt(100), 0);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        SetGlobalValue(ItemNo, true, false, false, AssignTracking::LotNo, 0);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Amount: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate(Amount, Amount);
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateInventoryWithLotViaWhseJournal(ItemNo: Code[20]; LocationCode: Code[10]; LotNo: Code[50]; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(ItemNo, LocationCode, Qty, true);
    end;

    local procedure UpdateInventoryInBinWithLotNo(Bin: Record Bin; ItemNo: Code[20]; LotNo: Code[20]; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, ItemNo, Qty, true);
    end;

    local procedure UpdateLotNoOnWhseActivityLines(ItemNo: Code[20]; Qty: Decimal; LotNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange(Quantity, Qty);
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo);
    end;

    local procedure VerifyPurchaseLineReceived(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Find();
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
    end;

    local procedure VerifySalesLineShipped(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
    end;

    local procedure VerifyTrackingOnPostedSalesInvoice(OrderNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // Verify Tracking line.
        SelectSalesInvoiceLine(SalesInvoiceLine, OrderNo);
        repeat
            TrackingQuantity := SalesInvoiceLine.Quantity;  // Assign Global Variable for Page Handler.
            SalesInvoiceLine.ShowItemTrackingLines();  // Open Item Tracking Line for Verify on PostedLinesPageHandler.
        until SalesInvoiceLine.Next() = 0;
    end;

    local procedure VerifyTrackingOnPostedPurchaseInvoice(OrderNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Verify Tracking line.
        SelectPurchInvLine(PurchInvLine, OrderNo);
        repeat
            TrackingQuantity := PurchInvLine.Quantity;  // Assign Global Variable for Page Handler.
            PurchInvLine.ShowItemTrackingLines();  // Open Item Tracking Line for Verify on PostedLinesPageHandler.
        until PurchInvLine.Next() = 0;
    end;

    local procedure VerifyTrackingOnSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; DocumentNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.FindFirst();
        TrackingQuantity := SalesShipmentLine.Quantity;  // Assign Global Variable for Page handler.
        SalesShipmentLine.ShowItemTrackingLines();  // Open Item Tracking Line for Verify on PostedLinesPageHandler.
    end;

    local procedure VerifyTrackingOnSalesShipment(OrderNo: Code[20]; Partial: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindSet();
        VerifyTrackingOnSalesShipmentLine(SalesShipmentLine, SalesShipmentHeader."No.");
        if Partial then begin
            SalesShipmentHeader.Next();
            VerifyTrackingOnSalesShipmentLine(SalesShipmentLine, SalesShipmentHeader."No.");
        end;
    end;

    local procedure VerifyTrackingOnDropShipment(SalesLine: Record "Sales Line"; PurchaseLine: Record "Purchase Line"; LotNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
    begin
        SalesLineReserve.FindReservEntry(SalesLine, ReservationEntry);
        ReservationEntry.TestField("Lot No.", LotNo);
        ReservationEntry.SetFilter("Lot No.", '<>%1', LotNo);
        Assert.RecordIsEmpty(ReservationEntry);

        PurchLineReserve.FindReservEntry(PurchaseLine, ReservationEntry);
        ReservationEntry.TestField("Lot No.", LotNo);
        ReservationEntry.SetFilter("Lot No.", '<>%1', LotNo);
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    local procedure VerifyWarehouseActivityLine(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, SourceDocument, LocationCode, ItemNo, '', ActivityType);
        Assert.AreEqual(2 * Quantity, WarehouseActivityLine.Count, NosOfLineError);  // Value is important for Test. Multiply 2 for take and place.
        repeat
            WarehouseActivityLine.TestField("Serial No.");
            WarehouseActivityLine.TestField("Lot No.");
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyRegisteredWhseActivityLine(ActivityType: Enum "Warehouse Activity Type"; SourceDocument: Enum "Warehouse Activity Source Document"; ItemNo: Code[20]; Quantity: Decimal)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.FindSet();
        Assert.AreEqual(2 * Quantity, RegisteredWhseActivityLine.Count, NosOfLineError);  // Value is important for Test. Multiply 2 for take and place.
        repeat
            RegisteredWhseActivityLine.TestField("Serial No.");
            RegisteredWhseActivityLine.TestField("Lot No.");
        until RegisteredWhseActivityLine.Next() = 0;
    end;

    local procedure VerifyRegistedInvtMovementLine(ItemNo: Code[20]; LotNo: Code[50]; BinCode: Code[20])
    var
        DummyRegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
    begin
        DummyRegisteredInvtMovementLine.Init();
        DummyRegisteredInvtMovementLine.SetRange("Item No.", ItemNo);
        DummyRegisteredInvtMovementLine.SetRange("Lot No.", LotNo);
        DummyRegisteredInvtMovementLine.SetRange("Bin Code", BinCode);
        Assert.RecordIsNotEmpty(DummyRegisteredInvtMovementLine);
    end;

    local procedure VerifyReservEntriesNotExist(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
        ActionMessageEntry: Record "Action Message Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        Assert.RecordIsEmpty(ReservationEntry);
        ActionMessageEntry.SetRange("Item No.", ItemNo);
        Assert.RecordIsEmpty(ActionMessageEntry);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LineCount: Integer;
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        repeat
            ItemLedgerEntry.TestField("Serial No.");
            LineCount += 1;
        until ItemLedgerEntry.Next() = 0;
        Assert.AreEqual(Quantity, LineCount, NumberOfLineEqualError);  // Verify Number of line - Tracking Line.
    end;

    local procedure VerifyItemLedgerEntryApplied(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField(Open, false);
            ItemLedgerEntry.TestField("Remaining Quantity", 0);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyWarehouseEntry(EntryType: Option; ItemNo: Code[20]; Quantity: Decimal; SignFactor: Integer)
    var
        WarehouseEntry: Record "Warehouse Entry";
        LineCount: Integer;
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.FindSet();
        repeat
            WarehouseEntry.TestField(Quantity, SignFactor);
            WarehouseEntry.TestField("Serial No.");
            LineCount += 1;
        until WarehouseEntry.Next() = 0;
        Assert.AreEqual(Quantity, LineCount, NumberOfLineEqualError);  // Verify Number of line - Tracking Line.
    end;

    local procedure VerifyCostAmountInItemLedgerEntryType(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Amount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SumCostAmountActual: Decimal;
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            SumCostAmountActual += ItemLedgerEntry."Cost Amount (Actual)";
        until ItemLedgerEntry.Next() = 0;
        Assert.AreEqual(SumCostAmountActual, Amount, ValueNotEqual);  // Veriy that sum of Cost Amount(Actual) equals to assigned amount.
    end;

    local procedure VerifyReservationEntryExists(ItemNo: Code[20]; LotNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        Assert.RecordIsNotEmpty(ReservationEntry);
    end;

    local procedure PostItemJournalLineWithItemTracking(
        Location: Record Location;
        Item: Record Item;
        LotNo: Code[50];
        LotQty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingOption: Option AssignLotNoManual,AssignLotNos,ChangeLotQty;
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNoManual);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(LotQty);

        CreateAndPostItemJournalLineWithTracking(
            ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code,
            LotQty, 0, AssignTracking::GivenLotNo);
    end;

    local procedure UpdateProductionBOMAndRoutingNoOnItem(var Item: Record Item; ProductionBOMNo: Code[20]; RoutingNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateInventory(Item: Record Item; Quantity: Decimal; LocationCode: Code[10]; UnitAmount: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);

        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, LocationCode, '', WorkDate(),
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, UnitAmount);

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure CreateAndPostPurchInvoice(var PurchHeader: Record "Purchase Header")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.");

        PurchRcptLine.SetCurrentKey("Buy-from Vendor No.");
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");

        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateNewLotNo.SetValue(CreateNewLotNo);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomizedSerialPageHandler(var EnterCustomizedSN: TestPage "Enter Customized SN")
    begin
        EnterCustomizedSN.CustomizedSN.SetValue(LibraryRandom.RandText(40));  // Random Text40 for Serial No.
        EnterCustomizedSN.CreateNewLotNo.SetValue(CreateNewLotNo);
        EnterCustomizedSN.Increment.SetValue(LibraryRandom.RandInt(10));  // Random Value for Increment.
        EnterCustomizedSN.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedLinesPageHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    var
        LineCount: Integer;
    begin
        // Verify Quantity and Number of Line on Tracking Page.
        case AssignTracking of
            AssignTracking::SerialNo:
                begin
                    PostedItemTrackingLines.First();
                    repeat
                        PostedItemTrackingLines.Quantity.AssertEquals(1);  // Using One for Serial No.
                        LineCount += 1;
                    until not PostedItemTrackingLines.Next();
                    Assert.AreEqual(TrackingQuantity, LineCount, NumberOfLineEqualError);  // Verify Number of line Tracking Line.
                end;
            AssignTracking::LotNo:
                PostedItemTrackingLines.Quantity.AssertEquals(TrackingQuantity);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.FILTER.SetFilter("No.", GlobalDocumentNo);
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSerialNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        LineCount: Integer;
    begin
        // Assign Serial and Lot No based on requirements.
        case AssignTracking of
            AssignTracking::SerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();  // Open Enter Quantity to Create Page for Create Serial No or with Lot No.
            AssignTracking::SelectTrackingEntries:
                begin
                    ItemTrackingLines."Select Entries".Invoke();  // Open Page Item Tracking Summary for Select Line on Page handler ItemTrackingSummaryPageHandler.
                    ItemTrackingLines.OK().Invoke();
                end;
        end;

        if UpdateTracking then begin
            ItemTrackingLines.Last();
            repeat
                ItemTrackingLines."Quantity (Base)".AssertEquals(1);  // Using One for Serial No.
                ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(1);  // Using One for Serial No.
                Assert.IsTrue(ItemTrackingLines."Serial No.".Value > ' ', SerialNoError);
                LineCount += 1;
            until not ItemTrackingLines.Previous();
            Assert.AreEqual(TrackingQuantity, LineCount, NumberOfLineEqualError);  // Verify Number of line - Tracking Line.
            ItemTrackingLines.OK().Invoke();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLotPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Qty: Decimal;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            AssignTracking::GivenLotNo:
                begin
                    ItemTrackingLines.Last();
                    ItemTrackingLines.Next();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    Qty := LibraryVariableStorage.DequeueDecimal();
                    ItemTrackingLines."Quantity (Base)".SetValue(Qty);
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(Qty);
                end;
            AssignTracking::GetQty:
                begin
                    ItemTrackingLines.FILTER.SetFilter("Lot No.", LibraryVariableStorage.DequeueText());
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Quantity (Base)".AsDecimal());
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Qty. to Handle (Base)".AsDecimal());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingDropShipmentPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        SerialNoInformation: Record "Serial No. Information";
        TrackingQuantity2: Decimal;
    begin
        // Assign Serial and Lot No based on requirements.
        case AssignTracking of
            AssignTracking::SerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();  // Open Enter Quantity to Create Page for Create Serial No or with Lot No.
            AssignTracking::LotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
            AssignTracking::SelectTrackingEntries:
                begin
                    ItemTrackingLines."Select Entries".Invoke();  // Open Page Item Tracking Summary for Select Line on Page handler ItemTrackingSummaryPageHandler.
                    ItemTrackingLines.OK().Invoke();
                end;
        end;

        if PartialTracking then
            case ItemTrackingAction of
                ItemTrackingAction::None:
                    begin
                        ItemTrackingLines.Last();
                        ItemTrackingLines."Serial No.".SetValue(
                          LibraryUtility.GenerateRandomCode(SerialNoInformation.FieldNo("Serial No."), DATABASE::"Serial No. Information"));
                        ItemTrackingLines.OK().Invoke();
                    end;
                ItemTrackingAction::AvailabilitySerialNo:
                    begin
                        TrackingQuantity2 := TrackingQuantity;
                        ItemTrackingLines.Last();
                        while TrackingQuantity2 > 0 do begin
                            TrackingQuantity2 -= 1;
                            ItemTrackingLines."Qty. to Handle (Base)".SetValue(0);  // Set Value to partially track the Items.
                            ItemTrackingLines.Previous();
                        end;
                    end;
                ItemTrackingAction::AvailabilityLotNo:
                    begin
                        ItemTrackingLines.First();
                        ItemTrackingLines."Qty. to Handle (Base)".SetValue(TrackingQuantity);
                        ItemTrackingLines.OK().Invoke();
                    end;
            end;

        if UpdateTracking then
            case ItemTrackingAction of
                ItemTrackingAction::AvailabilitySerialNo:
                    begin
                        TrackingQuantity2 := TrackingQuantity;
                        ItemTrackingLines.Last();
                        while TrackingQuantity2 > 0 do begin
                            TrackingQuantity2 -= 1;
                            ItemTrackingLines."Qty. to Invoice (Base)".SetValue(0);  // Set Value to partially track the Items.
                            ItemTrackingLines.Previous();
                        end;
                        ItemTrackingLines.OK().Invoke();
                    end;
                ItemTrackingAction::AvailabilityLotNo:
                    begin
                        ItemTrackingLines.First();
                        ItemTrackingLines."Quantity (Base)".SetValue(QuantityBase);
                        ItemTrackingLines."Qty. to Handle (Base)".SetValue(TrackingQuantity);
                        ItemTrackingLines.OK().Invoke();
                    end;
            end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingCustomizedPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        LineCount: Integer;
    begin
        // Assign Serial and Lot No based on requirements.
        if AssignTracking = AssignTracking::SerialNo then begin
            ItemTrackingLines.CreateCustomizedSN.Invoke();  // Open Page "Enter Customized SN" on Page handler CustomizedSerialPageHandler
            ItemTrackingLines.OK().Invoke();
        end else begin  // Verify Tracking Line.
            ItemTrackingLines.Last();
            repeat
                ItemTrackingLines."Quantity (Base)".AssertEquals(1);  // Using One for Serial No.
                ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(1);  // Using One for Serial No.
                Assert.IsTrue(ItemTrackingLines."Serial No.".Value > ' ', SerialNoError);
                if ItemTrackingAction = ItemTrackingAction::AvailabilitySerialNo then
                    Assert.IsFalse(ItemTrackingLines."Lot No.".Value > ' ', LotNoError)
                else
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value > ' ', SerialNoError);
                LineCount += 1;
            until not ItemTrackingLines.Previous();
            Assert.AreEqual(TrackingQuantity, LineCount, NumberOfLineEqualError);  // Verify Number of line - Tracking Line.
            ItemTrackingLines.OK().Invoke();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        IsAssign: Boolean;
        QtyNotToHandle: Integer;
    begin
        IsAssign := LibraryVariableStorage.DequeueBoolean();
        QtyNotToHandle := LibraryVariableStorage.DequeueInteger();

        if IsAssign then
            ItemTrackingLines."Assign Serial No.".Invoke()
        else begin
            ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingLines.Last();
            while QtyNotToHandle > 0 do begin
                QtyNotToHandle -= 1;
                ItemTrackingLines."Qty. to Handle (Base)".SetValue(0);
                ItemTrackingLines.Previous();
            end;
        end;

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var WhseItemTrackingLine: TestPage "Whse. Item Tracking Lines")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TrackingQuantity2: Decimal;
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Output, GlobalItemNo);
        TrackingQuantity2 := TrackingQuantity;
        while TrackingQuantity2 > 0 do begin
            TrackingQuantity2 -= 1;
            WhseItemTrackingLine.New();
            WhseItemTrackingLine."Serial No.".SetValue(ItemLedgerEntry."Serial No.");
            WhseItemTrackingLine."Lot No.".SetValue(ItemLedgerEntry."Lot No.");
            WhseItemTrackingLine.Quantity.SetValue(1);  // Using One for Serial No.
            ItemLedgerEntry.Next();
        end;
        Commit();  // Commit required for Test Cases.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingPageHandler(var WhseItemTrackingLine: TestPage "Whse. Item Tracking Lines")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TrackingQuantity2: Decimal;
    begin
        if AssignTracking = AssignTracking::SerialNo then begin
            TrackingQuantity2 := TrackingQuantity;
            while TrackingQuantity2 > 0 do begin
                TrackingQuantity2 -= 1;
                WhseItemTrackingLine.New();
                WhseItemTrackingLine."Serial No.".SetValue(TrackingQuantity2 + AssignTracking);
                WhseItemTrackingLine.Quantity.SetValue(1);  // Using One for Serial No.
                ItemLedgerEntry.Next();
            end;
        end;
        Commit();  // Commit required for Test Cases.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        if ItemTrackingSummaryCancel then
            ItemTrackingSummary.Cancel().Invoke()
        else
            ItemTrackingSummary.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SynchronizeMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, SynchronizationCancelled) > 0, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SynchronizeItemTrackingConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, SynchronizeItemTracking) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        MessageCounter += 1;
        case MessageCounter of
            1:
                begin
                    Assert.IsTrue(StrPos(ConfirmMessage, AvailabilityWarnings) > 0, ConfirmMessage);
                    Reply := true;
                end;
            2:
                begin
                    Assert.IsTrue(StrPos(ConfirmMessage, SynchronizeItemTracking) > 0, ConfirmMessage);
                    Reply := false;
                end;
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TransferOrderMessageHandler(Message: Text[1024])
    begin
        MessageCounter += 1;
        case MessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, TransferOrderDeleted) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, PutAwayActivityCreated) > 0, Message);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure WhseReceiptPutAwayMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, PutAwayActivityCreated) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure WarehouseActivityMessageHandler(Message: Text[1024])
    begin
        MessageCounter += 1;
        case MessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, PutAwayActivityCreated) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, MovementActivityCreated) > 0, Message);
            3:
                Assert.IsTrue(StrPos(Message, PickActivityCreated) > 0, Message);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PutAwayActivityMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, PutAwayActivityCreated) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PutAwayMovementMessageHandler(Message: Text[1024])
    begin
        MessageCounter += 1;
        case MessageCounter of
            1:
                Assert.IsTrue(StrPos(Message, PutAwayActivityCreated) > 0, Message);
            2, 3:
                Assert.IsTrue(StrPos(Message, MovementActivityCreated) > 0, Message);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PostJournalLinesMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, JournalLinesSuccessfullyPosted) > 0, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AvailabilityConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        MessageCounter += 1;
        case MessageCounter of
            1:
                Assert.IsTrue(StrPos(ConfirmMessage, AvailabilityWarnings) > 0, ConfirmMessage);
            2:
                Assert.IsTrue(StrPos(ConfirmMessage, SynchronizeItemTracking) > 0, ConfirmMessage);
        end;
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PostJournalConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, PostJournalLines) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionPageHandler(var PickSelection: TestPage "Pick Selection")
    begin
        PickSelection.FILTER.SetFilter("Location Code", LocationWhite.Code);
        PickSelection.FILTER.SetFilter("Document No.", GlobalDocumentNo);
        PickSelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PutAwaySelectionPageHandler(var PutAwaySelection: TestPage "Put-away Selection")
    begin
        PutAwaySelection.FILTER.SetFilter("Location Code", LocationWhite.Code);
        PutAwaySelection.FILTER.SetFilter("Document No.", GlobalDocumentNo);
        PutAwaySelection.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentReportHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmFalseHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandlerTrackingOptionWithLot(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ItemTrackingOption: Option AssignLotNoManual,AssignLotNos,ChangeLotQty;
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
            ItemTrackingOption::ChangeLotQty:
                begin
                    ItemTrackingLines.FILTER.SetFilter("Lot No.", LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
        end;

        ItemTrackingLines.OK().Invoke();
    end;
}

