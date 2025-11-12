codeunit 137052 "SCM RTAM Item Tracking"
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
        LocationGreen: Record Location;
        LocationBlue: Record Location;
        LocationBlue2: Record Location;
        LocationSilver: Record Location;
        LocationIntransit: Record Location;
        ItemTrackingCodeSerialSpecific: Record "Item Tracking Code";
        ItemTrackingCodeLotSpecific: Record "Item Tracking Code";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        isInitialized: Boolean;
        VerifyQtyToHandle: Boolean;
        CreateNewLotNo: Boolean;
        Partial: Boolean;
        CancelReservationCurrentLine: Boolean;
        UpdateSerialNo: Boolean;
        UpdateLotNo: Boolean;
        AssignTracking: Option "None",SerialNo,LotNo;
        ItemTrackingAction: Option "None",AvailabilitySerialNo,AvailabilityLotNo;
        TrackingQuantity: Decimal;
        Description: Text[50];
        Comment: Text[80];
        ReservationsCancelQst: Label 'Do you want to cancel all reservations';
        ItemTrackingSerialNumberErr: Label 'Variant  cannot be fully applied';
        SerialNumberErr: Label 'You must assign a serial number';
        ConsumptionMissingQst: Label '\\  * Some consumption is still missing.\\ Do you still want to finish the order?';
        MessageCounter: Integer;
        SignFactor: Integer;
        NumberOfLineEqualErr: Label 'Number of Lines must be same.';
        DocumentNo: Code[20];
        SynchronizeItemTrackingQst: Label 'Do you want to synchronize item tracking on the line with item tracking on the related drop shipment sales order line?';
        AvailabilityWarningsMsg: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        SerialNumberRequiredErr: Label 'You must assign a serial number for item %1.', Comment = '%1 = Item No.';
        WarrantyDateErr: Label 'Warranty Date must have a value in Tracking Specification';
        LotNumberRequiredErr: Label 'You must assign a lot number for item %1', Comment = '%1 = Item No.';
        QtyToHandleErr: Label 'Qty. to Handle (Base) in the item tracking assigned to the document line for item %1', Comment = '%1 = Item No.';
        SomeOutputMissingMsg: Label 'Some output is still missing';
        ItemLedgerEntrySummaryTypeTxt: Label 'Item Ledger Entry';
        TransferLineSummaryTypeTxt: Label 'Transfer Line, Inbound';
        GlobalItemNo: Code[20];
        TrackingAlreadyExistMsg: Label 'Tracking specification with Serial No';
        VariantFullyAppliedErr: Label 'Item No. %1 Variant  cannot be fully applied', Comment = '%1 = Variant Code';
        AlreadyOnInventoryErr: Label 'already on inventory.';
        CombinedShipmentsMsg: Label 'The shipments are now combined and the number of invoices created is 1.';
        CombinedReturnReceiptMsg: Label 'The return receipts are now combined and the number of credit memos created is 1.';
        SerialNumberPossibleValuesErr: Label 'must be -1, 0 or 1 ';
        ItemLedgerEntryFilterTxt: Label 'Sales Shipment|Sales Invoice|Sales Return Receipt|Sales Credit Memo|Purchase Receipt|Purchase Invoice|Purchase Return Shipment|Purchase Credit Memo|Transfer Shipment|Transfer Receipt|Service Shipment|Service Invoice|Service Credit Memo|Posted Assembly';
        ItemLedgerEntryFilteringErr: Label 'Filter was not set to Item Ledger Entries correctly.';
        QtyToInvoiceDoesNotMatchItemTrackingErr: Label 'The quantity to invoice does not match the quantity defined in item tracking.';

    [Test]
    [HandlerFunctions('ItemTrackingPurchasePageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure WhseReceiptForPartialWhsePutAwaySerialNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Integer;
    begin
        // Setup: Create Purchase Order, Warehouse Receipt and Partial Qty to Receive.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, 0, true);  // Partial Receipt-True and Tracking Quantity not required.
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationGreen.Code, Quantity, 1);  // No. of Lines value required.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWhseReceiptHeaderForPurchase(WarehouseReceiptHeader, PurchaseHeader."No.");
        UpdateQtyToReceiveOnWhseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", Item."No.", Quantity - 1);  // Partial Quantity Value.
        WarehouseReceiptLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPurchasePageHandler .

        // Exercise: Post and Register Warehouse Activity.
        PostWhseReceiptAndRegisterWarehouseActivity(
          WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order");

        // Verify: Verify Quantity to Handle on Tracking line on Page Handler.
        SetGlobalValue(Item."No.", false, true, true, AssignTracking::None, 0, false);  // Verify Qty To Handle-True.
        VerifyTrackingOnWarehouseReceipt(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPurchasePageHandler,QuantityToCreatePageHandler,SerialPostedLinesPageHandler,SerialNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvWhsePutAwaySerialNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Integer;
    begin
        // Setup: Create Purchase Order, Warehouse Receipt, Partial Qty to Receive, Warehouse Receipt Post, Register Warehouse Activity and again Warehouse Receipt Post.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, 0, true);  // Partial Receipt-True and Tracking Quantity not required.

        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationGreen.Code, Quantity, 1);  // No. of Lines value required.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWhseReceiptHeaderForPurchase(WarehouseReceiptHeader, PurchaseHeader."No.");
        UpdateQtyToReceiveOnWhseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", Item."No.", Quantity - 1);  // Partial Quantity Value.
        WarehouseReceiptLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPurchasePageHandler.
        PostWhseReceiptAndRegisterWarehouseActivity(
          WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order");
        PostWhseReceiptAndRegisterWarehouseActivity(
          WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order");

        // Exercise: Post Purchase Order with Invoice Option.
        PostPurchaseDocument(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.", false, true);

        // Verify: Verify Serial No comment on Posted Purchase Order on Page Handler.
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPurchasePageHandler,QuantityToCreatePageHandler,SerialPostedLinesPageHandler,SerialNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvFullWhsePutAwaySerialNoLotNo()
    begin
        // Setup.
        Initialize();
        WhsePutAwaySerialNoLotNo(ItemTrackingCodeSerialSpecific.Code, AssignTracking::SerialNo);  // Tracking Code for Serial No,Assign Serial as True,Assign Tracking as Serial No.
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,LotPostedLinesPageHandler,LotNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvFullWhsePutAwayLotNo()
    begin
        // Setup.
        Initialize();
        WhsePutAwaySerialNoLotNo(ItemTrackingCodeLotSpecific.Code, AssignTracking::LotNo);  // Tracking Code for Lot No Assign Serial as False,Assign Tracking as Lot No.
    end;

    local procedure WhsePutAwaySerialNoLotNo(ItemTrackingCode: Code[10]; AssignTrackingValue: Option)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Quantity: Integer;
    begin
        Quantity := LibraryRandom.RandInt(10);  // Using Random Value for Quantity.
        CreateItem(Item, ItemTrackingCode, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTrackingValue, 0, true);  // Create New Lot No -True and Tracking Quantity not required.
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationGreen.Code, Quantity, 1);  // No. of Lines value required.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        SelectWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPurchasePageHandler/LotItemTrackingPageHandler.
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        PostWhseReceiptAndRegisterWarehouseActivity(
          WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order");

        // Exercise: Post Purchase Order with Invoice Option.
        PostPurchaseDocument(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.", false, true);

        // Verify: Verify Serial No or Lot No comment on Posted Purchase Order on Page Handler.
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPurchasePageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure WhseReceiptForMultiLinePartialWhsePutAwaySerialNoLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Integer;
    begin
        // Setup: Create Purchase Order with Multiple Lines, Warehouse Receipt and Partial Qty to Receive.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, true, AssignTracking::None, 0, true);  // Create New Lot No -True, Receipt Partial -True and Tracking Quantity not required.
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationGreen.Code, Quantity, 3);  // No. of Lines value required.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWhseReceiptHeaderForPurchase(WarehouseReceiptHeader, PurchaseHeader."No.");
        UpdateQtyToReceiveOnWhseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", Item."No.", Quantity - 1);  // Partial Quantity Value.
        AssignTrackingMultipleWhseReceiptLines(PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");  // Assign Tracking on Page Handler ItemTrackingPurchasePageHandler.

        // Exercise: Assign Serial No and Lot No on Multiple Warehouse Receipt line, Post and Register Warehouse Activity.
        PostWhseReceiptAndRegisterWarehouseActivity(
          WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order");

        // Verify: Verify Quantity to Handle on Tracking line on Page Handler.
        SetGlobalValue(Item."No.", true, true, true, AssignTracking::None, 0, false);  // Verify Qty To Handle -True.
        VerifyTrackingOnWarehouseReceipt(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPurchasePageHandler,QuantityToCreatePageHandler,SerialPostedLinesPageHandler,SerialNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvMultiLineWhsePutAwaySerialNoLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Integer;
    begin
        // Setup: Create Purchase Order with Multiple Lines, Warehouse Receipt, Partial Qty to Receive, Warehouse Receipt Post, Register Warehouse Activity and again Warehouse Receipt Post.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, true, AssignTracking::None, 0, true);  // Create New Lot No -True, Receipt Partial -True and Tracking Quantity not required.
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationGreen.Code, Quantity, 3);  // No. of Lines value required.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWhseReceiptHeaderForPurchase(WarehouseReceiptHeader, PurchaseHeader."No.");
        UpdateQtyToReceiveOnWhseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", Item."No.", Quantity - 1);
        AssignTrackingMultipleWhseReceiptLines(PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");  // Assign Tracking on Page Handler ItemTrackingPurchasePageHandler.
        PostWhseReceiptAndRegisterWarehouseActivity(
          WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order");
        PostWhseReceiptAndRegisterWarehouseActivity(
          WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order");

        // Exercise: Post Purchase Order with Invoice Option.
        PostPurchaseDocument(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.", false, true);

        // Verify: Verify Serial No comment on Posted Purchase Order on Page Handler.
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,LotPostedLinesPageHandler,LotNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvMultiLineFullWhsePutAwayLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Integer;
    begin
        // Setup: Create Purchase Order with Multiple Lines, Warehouse Receipt, Warehouse Receipt Post, Register Warehouse Activity.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Using Random Value for Quantity.
        CreateItem(Item, ItemTrackingCodeLotSpecific.Code, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::LotNo, 0, true);  // Assign Lot No -True, Assign Tracking as Lot No,Tracking Quantity not required.
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationGreen.Code, Quantity, 3);  // No. of Lines value required.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWhseReceiptHeaderForPurchase(WarehouseReceiptHeader, PurchaseHeader."No.");
        AssignTrackingMultipleWhseReceiptLines(PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");  // Assign Tracking on Page Handler LotItemTrackingPageHandler.
        PostWhseReceiptAndRegisterWarehouseActivity(
          WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order");

        // Exercise: Post Purchase Order with Invoice Option.
        PostPurchaseDocument(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.", false, true);

        // Verify: Verify Lot No comment on Posted Purchase Order on Page Handler.
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,SerialPostedLinesPageHandler,SerialNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvForFullWarehouseShipmentSerialNo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item, Sales Order,Create Warehouse Shipment from Sales Order, add tracking and Post Shipment.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, 0, true);  // Tracking Quantity not required.
        Quantity := LibraryRandom.RandInt(10);  // Using Random Value for Quantity.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationGreen.Code, Quantity, 0, false, AssignTracking::SerialNo);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationGreen.Code, Quantity);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        AssignTrackingOnWarehouseShipmentLine(
          WarehouseShipmentLine, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");  // Assign Tracking on Page Handler ItemTrackingSalesPageHandler.
        CreatePickFromWarehouseShipment(
          WarehouseShipmentHeader, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");
        RegisterWarehouseActivityAndPostWhseShipment(
          WarehouseShipmentHeader, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");

        // Exercise: Post Sales Order with Invoice Option.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", false, true);

        // Verify: Verify Tracking line for Posted Sales Invoice on Page Handler.
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.", false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,QuantityToCreatePageHandler,PickSelectionPageHandler,ItemTrackingSummaryPageHandler,SerialPostedLinesPageHandler,SerialNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentForPartialWhseShipmentSerialNoLotNo()
    begin
        // Setup.
        Initialize();
        WhseShipmentSerialNoLotNo(false);  // Invoice-False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,QuantityToCreatePageHandler,PickSelectionPageHandler,ItemTrackingSummaryPageHandler,SerialPostedLinesPageHandler,SerialNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvForPartialWhseShipmentSerialLotNo()
    begin
        // Setup.
        Initialize();
        WhseShipmentSerialNoLotNo(true);  // Invoice-True.
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostingSalesShipmentDeletesWhseItemTrackingLine()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        ItemNo: Code[20];
        SourceDocType: Enum "Warehouse Activity Source Document";
        SourceDocNo: Code[20];
    begin
        // [FEATURE] [Lot Warehouse Tracking] [Whse. Item Tracking Line]
        // [SCENARIO 380081] Whse. Item Tracking Line should be deleted after source Whse. Shipment is posted.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Lot-tracked Item. "Lot Warehouse Tracking" switch in Item Tracking Code is on.
        // [GIVEN] Positive inventory on Location that requires Shipment and Pick.
        // [GIVEN] Released Sales Order, Shipment and Pick.
        CreateLotTrackedPositiveAdjmtAndSalesWithShipmentAndPick(WarehouseShipmentHeader, SourceDocType, SourceDocNo, ItemNo);

        // [WHEN] Register Pick and post Shipment.
        RegisterWarehouseActivityAndPostWhseShipment(WarehouseShipmentHeader, SourceDocNo, SourceDocType);

        // [THEN] Whse. Item Tracking Line is deleted.
        WhseItemTrackingLine.Init();
        WhseItemTrackingLine.SetRange("Item No.", ItemNo);
        Assert.RecordIsEmpty(WhseItemTrackingLine);
    end;

    local procedure WhseShipmentSerialNoLotNo(Invoice: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, true, AssignTracking::None, 1, true);  // Create New Lot No -True, Partial Shipment-True and Tracking Quantity required.

        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationGreen.Code, Quantity, 0, false, AssignTracking::SerialNo);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationGreen.Code, Quantity);
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingSalesPageHandler.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        DocumentNo := WarehouseShipmentHeader."No.";  // Assign Global variable for Page Handler.
        CreatePickFromPickWorksheet(LocationGreen.Code, Quantity - 1);  // Partial Quantity.
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");

        AssignTrackingOnWarehouseShipmentLine(
          WarehouseShipmentLine, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");  // Assign Tracking on Page Handler ItemTrackingSalesPageHandler.
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");

        // Exercise: Post Warehouse shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, Invoice);

        // Verify: Verify Tracking line for Posted Sales Shipment and Posted Sales Invoice on Page Handler.
        if Invoice then
            VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.", false)
        else
            VerifyTrackingOnPostedSalesShipment(SalesHeader."No.", Quantity - 1);  // Value required.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,SerialPostedLinesPageHandler,SerialNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvForMultiLineShipmentSerialLotNo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // [SCENARIO] Post sales order with several lines with tracked items and partial quatities
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        Quantity := 3 * LibraryRandom.RandInt(10);  // Value required for Test.

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::None, 0, true);  // Create New Lot No -True and Tracking Quantity not required.

        // [GIVEN] Item with serial tracking and positive location balance
        // [GIVEN] Sales order with several lines for the item with assigned serial tracking and partial quantity to ship
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, Quantity, 0, false, AssignTracking::SerialNo);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity / 3);  // Partial Quantity.
        CreateSalesLine(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity / 3);  // Partial Quantity.
        CreateSalesLine(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity / 3);  // Partial Quantity.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        AssignTrackingOnSalesLines(SalesHeader."No.");  // Assign Tracking on Multiple Line on Page Handler ItemTrackingSalesPageHandler.

        // [WHEN] Post Sales Order
        Assert.RecordIsNotEmpty(WarehouseShipmentLine); // check is needed for permission test
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        LibraryLowerPermissions.AddSalesDocsPost();
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // [THEN] There is a correct tracking line for posted sales invoice
        // [THEN] Stan can post tracked sales order without warehouse permissions (TFS 256649)
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.", true);
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler,LotPostedLinesPageHandler,LotNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvForPartialShipmentLotNo()
    var
        Quantity: Decimal;
    begin
        // Setup.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        PartialShipmentLotNo(Quantity, Quantity, Quantity / 2);  // Positive Adjustment Qty, Sales Order Quantity, Qty to Ship.
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler,LotPostedLinesPageHandler,LotNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvForAvailablePartialShipmentLotNo()
    var
        Quantity: Decimal;
    begin
        // Setup.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        PartialShipmentLotNo(Quantity, Quantity + LibraryRandom.RandInt(10), Quantity);  // Positive Adjustment Qty, Sales Order Quantity, Qty to Ship.
    end;

    local procedure PartialShipmentLotNo(PositiveQuantity: Decimal; Quantity: Decimal; QtyToShip: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item and Sales order with Partial Quantity.
        CreateItem(Item, ItemTrackingCodeLotSpecific.Code, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, QtyToShip, true);

        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, PositiveQuantity, 0, false, AssignTracking::LotNo);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity);
        UpdateSalesLineAndReleaseOrder(SalesHeader, SalesLine, QtyToShip);  // Partial Quantity.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler LotItemTrackingPageHandler.

        // Exercise.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // Verify: Verify Tracking line for Posted Sales Invoice on Page Handler.
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.", false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,SerialPostedLinesPageHandler,SerialNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvForPartialShipmentSerialNoLotNo()
    begin
        // Setup.
        Initialize();
        ShipmentSerialNoLotNo(false);  // Complete Invoice -False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,SerialPostedLinesPageHandler,SerialNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvForMultiPartialShipmentSerialNoLotNo()
    begin
        // Setup.
        Initialize();
        ShipmentSerialNoLotNo(true);  // Complete Invoice -True.
    end;

    local procedure ShipmentSerialNoLotNo(CompleteInvoice: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        Quantity2 := 2 * Quantity;  // Different Value required for Test.

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, true, AssignTracking::SerialNo, Quantity - 1, true);  // Create New Lot No -True, Partial Shipment-True,Assign Tracking as Serial No and Tracking Quantity required.

        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, Quantity, Quantity2, true, AssignTracking::SerialNo);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity + Quantity2);
        UpdateSalesLineAndReleaseOrder(SalesHeader, SalesLine, Quantity2 + 1);  // Partial Quantity.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingSalesPageHandler.

        if CompleteInvoice then begin
            SetGlobalValue(Item."No.", true, false, false, AssignTracking::None, Quantity - 1, false);  // Partial Quantity -False.
            PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);
            SelectSalesLine(SalesLine, SalesHeader."No.");
            UpdateQtyToShipOnSalesLine(SalesLine, Quantity - 1);  // Update Qty to ship.
            SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingSalesPageHandler.
        end;

        // Exercise: Post Sales Order Ship and invoice.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // Verify: Verify Tracking line for Posted Sales Invoice on Page Handler.
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.", false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderReservedSerialLotNoError()
    begin
        // Setup.
        Initialize();
        SalesOrderReservationSerialLotNo(true);  // Reserve -True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,ConfirmHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderCancelReservationSerialLotNo()
    begin
        // Setup.
        Initialize();
        SalesOrderReservationSerialLotNo(false);  // Reserve -False.
    end;

    local procedure SalesOrderReservationSerialLotNo(Reserve: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Create Item, create and Post Item Journal, create Sales order with tracking and create another Sales order and reserve.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::None, 0, true);  // Create New Lot No -True and Tracking Quantity not required.

        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, Quantity, 0, false, AssignTracking::SerialNo);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity / 2);  // Partial Qty.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingSalesPageHandler.

        CreateAndReleaseSalesOrder(SalesHeader2, SalesLine2, Item."No.", LocationBlue.Code, Quantity);
        SalesLine2.ShowReservation();  // Reserve from Current Line on Page Handler ReservationPageHandler.

        // Exercise & Verify: Post Sales Order/cancel reservation and post Sales Order. Verify Error message/Quantity on Posted Sales Invoice Line.
        PostSalesOrderAndVerifyLine(SalesHeader, SalesHeader2, Item."No.", Quantity / 2, Reserve);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler')]
    procedure SalesOrderReservedForOutboundOrderError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Reservation]
        // [SCENARIO 405154] Cannot post sales order with item tracking when quantity is non-specifically reserved for another sales.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);

        // [GIVEN] Serial no.-tracked item.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        SetGlobalValue(Item."No.", true, false, false, AssignTracking::None, 0, true);

        // [GIVEN] Post 2 serial nos. to inventory.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, Quantity, 0, false, AssignTracking::SerialNo);

        // [GIVEN] Create sales order "SO1" for 2 pcs, open item tracking lines and select 2 serial nos.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Create sales order "SO2" for 1 pc, reserve 1 pc from the inventory, do not specify serial no.
        CreateAndReleaseSalesOrder(SalesHeader2, SalesLine2, Item."No.", LocationBlue.Code, Quantity / 2);
        SalesLine2.ShowReservation();

        // [WHEN] Post the sales order "SO1".
        asserterror PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, false);

        // [THEN] "Item tracking cannot be fully applied..." error message is thrown.
        Assert.ExpectedError(ItemTrackingSerialNumberErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,ConfirmHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler')]
    procedure SalesOrderCancelReservationForOutboundOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Reservation]
        // [SCENARIO 405154] Posting sales order with item tracking when quantity is reserved for another sales and the reservation is then canceled.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);

        // [GIVEN] Serial no.-tracked item.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        SetGlobalValue(Item."No.", true, false, false, AssignTracking::None, 0, true);

        // [GIVEN] Post 2 serial nos. to inventory.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, Quantity, 0, false, AssignTracking::SerialNo);

        // [GIVEN] Create sales order "SO1" for 2 pcs, open item tracking lines and select 2 serial nos.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Create sales order "SO2" for 1 pc, reserve 1 pc from the inventory, do not specify serial no.
        CreateAndReleaseSalesOrder(SalesHeader2, SalesLine2, Item."No.", LocationBlue.Code, Quantity / 2);
        SalesLine2.ShowReservation();

        // [WHEN] Cancel the reservation for "SO2" and post "SO1".
        CancelReservationCurrentLine := true;
        SalesLine2.Find();
        SalesLine2.ShowReservation();
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // [THEN] The sales order "SO1" is posted.
        VerifyPostedSalesInvoiceLine(SalesHeader."No.", Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler')]
    procedure SelectEntriesWithConsiderationOfNonSpecificReservation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Reservation]
        // [SCENARIO 405154] Select entries in item tracking does not suggest full quantity when part of inventory is non-specifically reserved for another sales order.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);

        // [GIVEN] Serial no.-tracked item.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        SetGlobalValue(Item."No.", true, false, false, AssignTracking::None, 0, true);

        // [GIVEN] Post 2 serial nos. to inventory.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, Quantity, 0, false, AssignTracking::SerialNo);

        // [GIVEN] Create sales order "SO1" for 1 pc, reserve 1 pc from the inventory, do not specify serial no.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity / 2);
        SalesLine.ShowReservation();

        // [GIVEN] Create sales order "SO2" for 2 pcs, open item tracking lines and run "Select entries".
        CreateAndReleaseSalesOrder(SalesHeader2, SalesLine2, Item."No.", LocationBlue.Code, Quantity);
        SalesLine2.OpenItemTrackingLines();

        // [WHEN] Post the sales order "SO2".
        asserterror PostSalesDocument(SalesHeader2."Document Type", SalesHeader2."No.", true, false);

        // [THEN] Only 1 pc is automatically tracked, so the "SO2" cannot be posted.
        Assert.ExpectedError(StrSubstNo(QtyToHandleErr, ''));
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler,LotPostedLinesPageHandler,LotNoListPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceLineDifferentLots()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Item and Sales order with Partial Quantity.
        Initialize();
        CreateItem(Item, ItemTrackingCodeLotSpecific.Code, Item."Costing Method"::FIFO);
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        Quantity2 := 2 * Quantity;  // Different Value required for Test.

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, 1, true);  // Partial Shipment-True,Assign Serial And Lot-True and Tracking Quantity required.

        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, Quantity, Quantity2, true, AssignTracking::LotNo);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity + Quantity2);
        UpdateSalesLineAndReleaseOrder(SalesHeader, SalesLine, Quantity2 + 1);  // Partial Quantity.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler LotItemTrackingPageHandler.

        // Exercise: Post Sales Order Ship and invoice.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // Verify: Verify Tracking line for Posted Sales Invoice on Page Handler.
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.", false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderReserveSerialNoWithInventoryError()
    begin
        // Setup.
        Initialize();
        SalesOrderReserveSerialNoWithDiffInventory(true);  // Reserve -True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSalesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderCancelReserveSerialNoWithoutInventoryError()
    begin
        // Setup.
        Initialize();
        SalesOrderReserveSerialNoWithDiffInventory(false);  // Reserve -False.
    end;

    local procedure SalesOrderReserveSerialNoWithDiffInventory(Reserve: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Create Item, create and Post Item Journal, create Sales order with tracking and create another Sales order with reserve.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        Quantity2 := 2 * Quantity;  // Value required for Test.

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::None, 0, true);  // Create New Lot No -True and Tracking Quantity not required.

        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, Quantity, Quantity2, true, AssignTracking::SerialNo);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity + 1);  // Different Value required for Test.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingSalesPageHandler.

        CreateAndReleaseSalesOrder(SalesHeader2, SalesLine2, Item."No.", LocationBlue.Code, Quantity2 / 2);  // Value required for Test.
        SalesLine2.ShowReservation();  // Reserve from Current Line on Page Handler ReservationPageHandler.

        // Exercise: Post Sales Order/Add Item tracking and Post both Sales Order.
        if Reserve then
            asserterror PostSalesDocument(SalesHeader2."Document Type", SalesHeader2."No.", true, false)
        else begin
            SalesLine2.OpenItemTrackingLines();  // Assign Tracking on Page Handler.
            PostSalesDocument(SalesHeader2."Document Type", SalesHeader2."No.", true, true);
            PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);
        end;

        // Verify: Verify Error message/Quantity on Posted Sales Invoice Line.
        if Reserve then
            Assert.IsTrue(StrPos(GetLastErrorText, SerialNumberErr) > 0, GetLastErrorText)
        else begin
            VerifyPostedSalesInvoiceLine(SalesHeader2."No.", Item."No.", Quantity2 / 2);
            VerifyPostedSalesInvoiceLine(SalesHeader."No.", Item."No.", Quantity + 1);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderPartialInvoiceWithMethodSpecific()
    begin
        // Setup.
        Initialize();
        PurchOrderWithMethodSpecificLotNo(false);  // Complete Invoice-False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderCompleteInvoiceWithMethodSpecific()
    begin
        // Setup.
        Initialize();
        PurchOrderWithMethodSpecificLotNo(true);  // Complete Invoice -True.
    end;

    local procedure PurchOrderWithMethodSpecificLotNo(CompleteInvoice: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        Quantity: Integer;
        Quantity2: Integer;
        DirectUnitCost: Decimal;
    begin
        // Create Item, Purchase Order with Tracking line,Post Purchase Order with Receipt Option and  Post Partial Invoice.
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        Quantity2 := 2 * Quantity;
        DirectUnitCost := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::Specific);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0, false);  // Create New Lot No -True, Partial Receipt-True, Assign Tracking as Serial No and Tracking Quantity not required.

        CreateAndReleasePurchaseOrderWithTracking(PurchaseHeader, Item."No.", LocationBlue.Code, Quantity + Quantity2, 1);  // No. of Lines value required.
        PostPurchaseDocument(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.", true, false);  // Receive only.

        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, Quantity2, false);  // Partial Receipt-True and Tracking Quantity required.
        ReopenPurchaseOrder(PurchaseHeader);
        UpdatePurchaseLineAndReleaseOrder(PurchaseHeader, DirectUnitCost, Quantity);  // Update Direct Unit Cost and Qty to Invoice.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking on Page Handler ItemTrackingPageHandler.

        // Exercise: Post Purchase Order with Invoice Option/Change Direct Unit Cost and again Post Purchase Order with Invoice Option.
        PostPurchaseDocument(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.", false, true);  // Invoice.
        if CompleteInvoice then
            UpdateAndPostPurchaseOrder(PurchaseHeader, DirectUnitCost + 1, Quantity2);

        // Verify: Verify Cost Amount (Actual) on Item Ledger Entry.
        FindPurchRcptHeader(PurchRcptHeader, PurchaseHeader."No.");
        SelectItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Purchase Receipt", PurchRcptHeader."No.", Item."No.");
        VerifyItemLedgerEntry(ItemLedgerEntry, DirectUnitCost);
        if CompleteInvoice then begin
            ItemLedgerEntry.FindLast();
            VerifyItemLedgerEntry(ItemLedgerEntry, DirectUnitCost + 1);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPartialPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceWithMethodSpecific()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Integer;
        Quantity2: Integer;
        DirectUnitCost: Decimal;
    begin
        // [FEATURE] [Adjust Cost Item Entries]
        // [SCENARIO] Check Cost on ILE after receive Purchase Order with Tracking, then invoice in two steps (with different costs), then post Sales Order with Tracking, then run Adjust Cost.

        // [GIVEN] Create Item, Purchase Order with Tracking line,Post Purchase Order with Receipt Option and Post Partial Invoice.Create Sales Order and Post it.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test.
        Quantity2 := 2 * Quantity;
        DirectUnitCost := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::Specific);

        // [GIVEN] Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0, false);  // Create New Lot No -True, Partial Receipt-True, Assign Tracking as Serial No and Tracking Quantity not required.
        CreateAndReleasePurchaseOrderWithTracking(PurchaseHeader, Item."No.", LocationBlue.Code, Quantity + Quantity2, 1);  // No. of Lines value required.
        PostPurchaseDocument(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.", true, false);  // Receive only.

        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, Quantity2, false);  // Partial Receipt-True and Tracking Quantity is required.
        ReopenPurchaseOrder(PurchaseHeader);
        UpdatePurchaseLineAndPost(PurchaseHeader, DirectUnitCost, Quantity);  // Partial Invoice.

        UpdateAndPostPurchaseOrder(PurchaseHeader, DirectUnitCost + 1, Quantity2);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, Quantity, false);  // Tracking Quantity is required.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, Quantity);
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // [WHEN] Run Adjust Cost Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Verify Cost Amount (Actual) on Item Ledger Entry.
        FindSalesShipmentHeader(SalesShipmentHeader, SalesHeader."No.");
        SelectItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Shipment", SalesShipmentHeader."No.", Item."No.");
        VerifyItemLedgerEntry(ItemLedgerEntry, -(DirectUnitCost + 1));  // Negative value for Sales.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,PostedLinesPageHandler,ConsumptionMissingConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderWithTrackingAndMultipleOutputSerialNoLotNo()
    begin
        // [FEATURE] [Item Tracking] [Production]
        // [SCENARIO] Create Released Production Order with serial tracked Item and Post Output in two steps, then finish Production Order, then verify item tracking lines are correct.

        // Setup.
        Initialize();
        ProductionOrderWithOutputSerialNoLotNo(true);  // Multiple Output Line as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,PostedLinesPageHandler,ConsumptionMissingConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderWithTrackingAndOutputSerialNoLotNo()
    begin
        // [FEATURE] [Item Tracking] [Production]
        // [SCENARIO] Create Released Production Order with serial tracked Item and Post Output, then finish Production Order, then verify item tracking lines are correct.

        // Setup.
        Initialize();
        ProductionOrderWithOutputSerialNoLotNo(false);  // Multiple Output Line as False.
    end;

    local procedure ProductionOrderWithOutputSerialNoLotNo(MultipleOutputLine: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Create Item with Tracking Code, Child Item setup, Create Released Production Order and Post Output.
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test. More than one Quantity.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        CreateAndCertifyProdBOMWithMultipleComponent(Item, Item2, Item3, ItemTrackingCodeSerialSpecific.Code, true);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0, false);  // Create New Lot No -True, Assign Tracking as Serial No and Tracking Quantity not required.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LocationBlue.Code, Quantity);
        if MultipleOutputLine then begin
            CreateAndPostOutputJournal(ProductionOrder."No.", Quantity - 1, true);  // Partial Qty,Tracking as True, Assign Tracking on Page Handler ItemTrackingPageHandler.
            CreateAndPostOutputJournal(ProductionOrder."No.", 1, true);  // Partial Qty, Tracking as True, Assign Tracking on Page Handler ItemTrackingPageHandler.
        end else
            CreateAndPostOutputJournal(ProductionOrder."No.", Quantity, true);  // Tracking as True, Assign Tracking on Page Handler ItemTrackingPageHandler.

        // Exercise: Change Status of Production Order Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify Tracking line on Finished Production Order on Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, Quantity, false);  // Assign Tracking as Serial No and Tracking Quantity.
        OpenItemTrackingLinesForProduction(ProductionOrder."No.");  // Open Item Tracking Lines and Verify on Page Handler PostedLinesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,PostedLinesPageHandler,ConsumptionMissingConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderWithTrackingSerialNoLotNo()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Production]
        // [SCENARIO] Create Firm Planned Production Order with serial tracked Item, assign tracking, release Production Order, then post Output, then finish Production Order, then verify item tracking lines are correct.

        // [GIVEN] Create Item with Tracking Code, Child Item Setup, Create Released Production Order with Tracking and Post Output.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Using Random Value.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        CreateAndCertifyProdBOMWithMultipleComponent(Item, Item2, Item3, ItemTrackingCodeSerialSpecific.Code, true);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0, false);  // Create New Lot No -True, Assign Tracking as Serial No and Tracking Quantity not required.
        CreateAndRefreshFirmPlannedProductionOrder(ProductionOrder, Item."No.", LocationBlue.Code, Quantity);
        OpenItemTrackingLinesForProduction(ProductionOrder."No.");  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        ProductionOrderNo :=
          LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProductionOrder."No.");
        CreateAndPostOutputJournal(ProductionOrderNo, Quantity, false);  // Tracking As False.

        // [WHEN] Change Status of Production Order Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // [THEN] Verify Tracking line on Finished Production Order on Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, Quantity, false);  // Assign Tracking as Serial No and Tracking Quantity.
        OpenItemTrackingLinesForProduction(ProductionOrderNo);  // Open Item Tracking Lines and Verify on Page Handler PostedLinesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderTrackingOnComponentSerialNoLotNo()
    begin
        // [FEATURE] [Item Tracking] [Production]
        // [SCENARIO] Create Released Production Order with Tracking on Components, Post Consumption and Output, finish Produciton Order, verify Item Tracking lines.

        // Setup.
        Initialize();
        ProductionOrderWithConsumptionAndOutputSerialNoLotNo(true, false);  // Tracking On Component as True, and Tracking On Consumption as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderTrackingOnConsumptionSerialNoLotNo()
    begin
        // [FEATURE] [Item Tracking] [Production]
        // [SCENARIO] Create Released Production Order, Post Consumption with Tracking and Output, finish Produciton Order, verify Item Tracking lines.

        // Setup.
        Initialize();
        ProductionOrderWithConsumptionAndOutputSerialNoLotNo(false, true);  // Tracking On Component as False, and Tracking On Consumption as True.
    end;

    local procedure ProductionOrderWithConsumptionAndOutputSerialNoLotNo(TrackingOnComponent: Boolean; TrackingOnConsumption: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Create Item with Tracking Code, Child Item Setup, Create Released Production Order with Tracking, Post Output and Consumption with Tracking.
        Quantity := LibraryRandom.RandInt(10);  // Using Random Value.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        CreateAndCertifyProdBOMWithMultipleComponent(Item, Item2, Item3, ItemTrackingCodeLotSpecific.Code, true);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::None, 0, false);  // Create New Lot No -True and Tracking Quantity not required.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item2."No.", LocationBlue.Code, Quantity, 0, false, AssignTracking::LotNo);
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item3."No.", LocationBlue.Code, Quantity, 0, false, AssignTracking::SerialNo);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0, false);  // Create New Lot No -True, Assign Tracking as Serial No and Tracking Quantity not required.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LocationBlue.Code, Quantity);
        OpenItemTrackingLinesForProduction(ProductionOrder."No.");  // Assign Tracking on Page Handler ItemTrackingPageHandler.

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::None, 0, false);  // Create New Lot No -True, Assign Tracking as None and Tracking Quantity not required.
        if TrackingOnComponent then begin
            OpenItemTrackingLinesForProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", Item2."No.");  // Assign Tracking on Page Handler ItemTrackingPageHandler.
            OpenItemTrackingLinesForProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", Item3."No.");  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        end;
        CreateAndPostConsumptionJournal(ProductionOrder."No.", TrackingOnConsumption);
        CreateAndPostOutputJournal(ProductionOrder."No.", Quantity, false);  // Tracking as False.

        // Exercise: Change Status of Production Order Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify Tracking line on Finished Production Order and Production Order Component on Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, Quantity, false);  // Assign Tracking as Serial No and Tracking Quantity.
        OpenItemTrackingLinesForProduction(ProductionOrder."No.");  // Open Item Tracking Lines and Verify on Page Handler PostedLinesPageHandler.
        VerifyTrackingOnProdOrderComponent(ProductionOrder."No.", Item3."No.");
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::LotNo, Quantity, false);  // Assign Tracking as Lot No and Tracking Quantity.
        VerifyTrackingOnProdOrderComponent(ProductionOrder."No.", Item2."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderWithWhseShipmentConsumptionAndOutputSerialNoLotNo()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Production]
        // [SCENARIO] Verify Tracking line after: create Released Production Order, create Warehouse Pick from it, Post Output and Consumption with Tracking, finish Production Order.

        // [GIVEN] Create Item with Tracking Code, Child Item Setup, Create Released Production Order, Create Warehouse Pick from Production Order, Post Output and Consumption with Tracking.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test. More than one Quantity.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        CreateAndCertifyProdBOMWithMultipleComponent(Item, Item2, Item3, ItemTrackingCodeLotSpecific.Code, true);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::None, 0, false);  // Create New Lot No -True, Assign Tracking as None and Tracking Quantity not required.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item2."No.", LocationGreen.Code, Quantity, 0, false, AssignTracking::LotNo);
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item3."No.", LocationGreen.Code, Quantity, 0, false, AssignTracking::SerialNo);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0, false);  // Create New Lot No -True, Assign Tracking as Serial No and Tracking Quantity not required.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LocationGreen.Code, Quantity);
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        FindWarehouseActivityHeader(
          WarehouseActivityHeader, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption");
        UpdateQtyToHandleOnWarehouseActivityLine(
          WarehouseActivityHeader, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", Quantity - 1);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        CreateAndPostOutputJournal(ProductionOrder."No.", Quantity, true);  // Tracking as True, Assign Tracking on Page Handler ItemTrackingPageHandler.

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, 0, false);  // Assign Tracking as None and Tracking Quantity not required.
        CreateAndPostConsumptionJournal(ProductionOrder."No.", true);  // Tracking as True, Assign Tracking on Page Handler ItemTrackingPageHandler.

        // [WHEN] Change Status of Production Order Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Verify Tracking line on Finished Production Order and Production Order Component on Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, Quantity, false);  // Assign Tracking as Serial No and Tracking Quantity.
        OpenItemTrackingLinesForProduction(ProductionOrder."No.");  // Open Item Tracking Lines and Verify on Page Handler PostedLinesPageHandler.
        VerifyTrackingOnProdOrderComponent(ProductionOrder."No.", Item3."No.");
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::LotNo, Quantity, false);  // Assign Tracking as Lot No and Tracking Quantity.
        VerifyTrackingOnProdOrderComponent(ProductionOrder."No.", Item2."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure WhsePickFromTransferOrderSerialNo()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Tracking Code, Create and Post Item Journal and Create Transfer Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Using Random Value.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationGreen.Code, Quantity, 0, false, AssignTracking::SerialNo);
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, LocationGreen.Code, LocationBlue.Code, Item."No.", Quantity);

        // Exercise: Create Warehouse Shipment from Transfer Order.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // Verify: Verify Warehouse Shipment line.
        SelectWarehouseShipmentLine(
          WarehouseShipmentLine, TransferHeader."No.", WarehouseShipmentLine."Source Document"::"Outbound Transfer");
        WarehouseShipmentLine.TestField("Item No.", Item."No.");
        WarehouseShipmentLine.TestField(Quantity, TransferLine.Quantity);
        WarehouseShipmentLine.TestField("Location Code", LocationGreen.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,SalesListPageHandler,SynchronizeItemTrackingConfirmHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithDropShipmentSerialNoLotNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Create Item with Tracking Code, Create Sales Order with Purchasing Code, Create Purchase Order and Drop Shipment.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", '', LibraryRandom.RandInt(10));
        UpdatePurchasingCodeOnSalesLine(SalesLine);
        DocumentNo := SalesHeader."No.";  // Assign Global Variable for page handler.

        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        UpdateSellToCustomerOnPurchaseHeader(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        LibraryPurchase.GetDropShipment(PurchaseHeader);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, SalesLine.Quantity, false);  // Create New Lot No -True, Assign Tracking as Serial No and Tracking Quantity.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking line on page handler ItemTrackingPageHandler.
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Post Purchase Order.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", true, true);

        // Verify: Verify Serial and Lot No in Posted Sales Invoice and Purchase Invoice.
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.", false);
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnSerialNoLotNo()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Tracking Code, Create and Post Purchase Order with Tracking, Post Warehouse Receipt.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test. More than one Quantity.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0, false);  // Create New Lot No -True, Assign Tracking as Serial No and Tracking Quantity not required.
        CreateAndReleasePurchaseOrderWithTracking(PurchaseHeader, Item."No.", LocationGreen.Code, Quantity, 1);  // No. of Lines value required.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWhseReceiptHeaderForPurchase(WarehouseReceiptHeader, PurchaseHeader."No.");
        PostWhseReceiptAndRegisterWarehouseActivity(
          WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order");

        // Exercise: Post Purchase Order.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // Verify: Verify Tracking line on Posted Purchase Receipt Line.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, Quantity, false);
        VerifyTrackingOnPostedPurchaseReceipt(PurchaseHeader."No.");

        // Create Purchase Return Order with Tracking, Post Warehouse Shipment.
        FindPurchRcptHeader(PurchRcptHeader, PurchaseHeader."No.");
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, 0, false);  // Assign Global variable for Page Handler.
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, Item."No.", LocationGreen.Code, Quantity / 2, 1);  // Partial Quantity, No. of Lines value required.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking on Page HandlerItemTrackingPageHandler.
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        CreatePickFromWarehouseShipment(
          WarehouseShipmentHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Return Order");
        RegisterWarehouseActivityAndPostWhseShipment(
          WarehouseShipmentHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Return Order");

        // Exercise: Post Purchase Return Order.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // Verify: Verify Serial and Lot No in Item Ledger Entry.
        FindReturnShipmentHeader(ReturnShipmentHeader, PurchaseHeader."No.");
        VerifySerialAndLotNoOnItemLedgerEntry(
          Item."No.", ItemLedgerEntry."Document Type"::"Purchase Return Shipment", ReturnShipmentHeader."No.",
          ItemLedgerEntry."Document Type"::"Purchase Receipt", PurchRcptHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnSerialNoLotNo()
    var
        SalesHeader: Record "Sales Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesShipmentLine: Record "Sales Shipment Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Tracking Code, Create and Post Sales Order with Tracking, Post Warehouse Shipment.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Value required for Test. More than one Quantity.
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::None, 0, false);  // Create New Lot No -True, Assign Tracking as None and Tracking Quantity not required.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationGreen.Code, Quantity, 0, false, AssignTracking::SerialNo);

        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationGreen.Code, Quantity);
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreatePickFromWarehouseShipment(
          WarehouseShipmentHeader, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");
        RegisterWarehouseActivityAndPostWhseShipment(
          WarehouseShipmentHeader, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");

        // Exercise: Post Sales Order.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", false, true);

        // Verify: Verify Tracking line on Posted Sales Shipment.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, SalesLine.Quantity, false);
        SelectSalesShipmentLine(SalesShipmentLine, SalesHeader."No.");
        SalesShipmentLine.ShowItemTrackingLines();  // Verify Item Tracking line on Page handler PostedLinesPageHandler.
        DocumentNo := SalesShipmentLine."Document No.";  // Assign Global variable for Page Handler.

        // Create and Post Sales Return Order with Tracking, Post Warehouse Receipt and Assign Global variable for Page Handler.
        CreateAndReleaseSalesReturnOrder(SalesHeader, SalesLine, Item."No.", LocationGreen.Code, 1);  // Partial Quantity required for Test.
        SetGlobalValue(Item."No.", false, true, true, AssignTracking::None, 0, false);  // Partial -True, Verify Qty To Handle -True and Tracking Quantity not required.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler.
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        FindWhseReceiptHeaderForSalesReturn(WarehouseReceiptHeader, SalesHeader."No.");
        PostWhseReceiptAndRegisterWarehouseActivity(
          WarehouseReceiptHeader, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Return Order");

        // Exercise: Post Sales Return Order.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", false, true);

        // Verify: Verify Serial and Lot No in Item Ledger Entry.
        FindReturnReceiptHeader(ReturnReceiptHeader, SalesHeader."No.");
        VerifySerialAndLotNoOnItemLedgerEntry(
          Item."No.", ItemLedgerEntry."Document Type"::"Sales Return Receipt", ReturnReceiptHeader."No.",
          ItemLedgerEntry."Document Type"::"Sales Shipment", SalesShipmentLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseTrackingInboundSerialNo()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Item with Tracking Code for SN Purchase Inbound Tracking, Create Purchase Order.
        Initialize();
        CreateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("SN Purchase Inbound Tracking"), true);
        CreateItem(Item, ItemTrackingCode.Code, Item."Costing Method"::FIFO);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10), 1);  // No. of Lines value required.
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        // Commit so created records are not rolled back on the next asserterror
        Commit();

        // Exercise: Post Purchase Order without Tracking.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Error message.
        Assert.ExpectedError(StrSubstNo(SerialNumberRequiredErr, Item."No."));

        // Exercise: Assign Tracking and Post Purchase Order. Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, PurchaseLine.Quantity, false);  // Assign Tracking as Serial No and Tracking Quantity.
        PurchaseLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        PurchaseHeader.Find();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Tracking and No of Line on Posted Purchase Invoive.
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseTrackingInboundAndOutboundSerialNo()
    begin
        // Setup.
        Initialize();
        PurchaseDocumentWithTrackingInboundAndOutboundSerialNo(true);  // SN Purchase Inbound Tracking as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseTrackingOutboundSerialNo()
    begin
        // Setup.
        Initialize();
        PurchaseDocumentWithTrackingInboundAndOutboundSerialNo(false);  // SN Purchase Inbound Tracking as False.
    end;

    local procedure PurchaseDocumentWithTrackingInboundAndOutboundSerialNo(SNPurchaseInboundTracking: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Item with Tracking Code for SN Purchase Outbound Tracking or SN Purchase Inbound Tracking", Create and Post Purchase Order, Create Return Order.
        CreateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("SN Purchase Outbound Tracking"), true);
        if SNPurchaseInboundTracking then
            UpdateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("SN Purchase Inbound Tracking"), true);
        CreateItem(Item, ItemTrackingCode.Code, Item."Costing Method"::FIFO);
        if not SNPurchaseInboundTracking then begin
            CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10), 1);  // No. of Lines value required.
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        end;
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10), 1);  // No. of Lines value required.
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        // Commit so created records are not rolled back on the next asserterror
        Commit();

        // Exercise: Post Purchase Return Order without Tracking.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Error message.
        Assert.ExpectedError(StrSubstNo(SerialNumberRequiredErr, Item."No."));

        // Exercise: Assign Tracking and Post Purchase Return Order. Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, PurchaseLine.Quantity, false);  // Assign Tracking as Serial No and Tracking Quantity not required.
        PurchaseLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        PurchaseHeader.Find();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Tracking and No of Line on Posted Return Shipment.
        VerifyTrackingOnPostedReturnShipment(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTrackingOutboundSerialNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // Setup: Create Item with Tracking Code for SN Sales Outbound Tracking,Create Sales Order.
        Initialize();
        CreateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("SN Sales Outbound Tracking"), true);
        CreateItem(Item, ItemTrackingCode.Code, Item."Costing Method"::FIFO);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));
        // Commit so created records are not rolled back on the next asserterror
        Commit();

        // Exercise: Post Sales Order without Tracking.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Error message.
        Assert.ExpectedError(StrSubstNo(SerialNumberRequiredErr, Item."No."));

        // Exercise: Assign Tracking and Post Sales Order. Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, SalesLine.Quantity, false);  // Assign Tracking as Serial No and Tracking Quantity not required.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Tracking and No of Line on Posted Sales Invoice.
        VerifyTrackingOnPostedSalesInvoice(SalesHeader."No.", false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTrackingInboundAndOutboundSerialNo()
    begin
        // Setup.
        Initialize();
        SalesDocumentWithTrackingInboundAndOutboundSerialNo(true);  // SN Sales Outbound Tracking as True;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTrackingInboundSerialNo()
    begin
        // Setup.
        Initialize();
        SalesDocumentWithTrackingInboundAndOutboundSerialNo(false);  // SN Sales Outbound Tracking as False;
    end;

    local procedure SalesDocumentWithTrackingInboundAndOutboundSerialNo(SNSalesOutboundTracking: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // Create Item with Tracking Code for SN Sales Outbound Tracking or SN Sales Inbound Tracking, Create and Post Sales Order, Create Sales Return Order.
        CreateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("SN Sales Inbound Tracking"), true);
        if SNSalesOutboundTracking then
            UpdateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("SN Sales Outbound Tracking"), true);
        CreateItem(Item, ItemTrackingCode.Code, Item."Costing Method"::FIFO);

        if not SNSalesOutboundTracking then begin
            CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;
        CreateAndReleaseSalesReturnOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));
        // Commit so created records are not rolled back on the next asserterror
        Commit();

        // Exercise: Post Sales Return Order without Tracking.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Error message.
        Assert.ExpectedError(StrSubstNo(SerialNumberRequiredErr, Item."No."));

        // Exercise: Assign Tracking and Post Sales Return Order. Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, SalesLine.Quantity, false);  // Assign Tracking as Serial and Tracking Quantity not required.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Tracking and No of Line on Posted Return Receipt.
        VerifyTrackingOnPostedReturnReceipt(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PositiveAdjmtTrackingInboundSerialNo()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup.
        Initialize();
        PositiveAndNegativeAdjmtTrackingSerialNo(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemTrackingCode.FieldNo("SN Pos. Adjmt. Inb. Tracking"), 1);  // 1 for Sign Factor as Positive.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PositiveAdjmtTrackingOutboundSerialNo()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup.
        Initialize();
        PositiveAndNegativeAdjmtTrackingSerialNo(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemTrackingCode.FieldNo("SN Pos. Adjmt. Outb. Tracking"), -1);  // -1 for Sign Factor as Negative.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure NegativeAdjmtTrackingInboundSerialNo()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup.
        Initialize();
        PositiveAndNegativeAdjmtTrackingSerialNo(
          ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemTrackingCode.FieldNo("SN Neg. Adjmt. Inb. Tracking"), -1);  // -1 for Sign Factor as Negative.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure NegativeAdjmtTrackingOutboundSerialNo()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup.
        Initialize();
        PositiveAndNegativeAdjmtTrackingSerialNo(
          ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemTrackingCode.FieldNo("SN Neg. Adjmt. Outb. Tracking"), 1);  // 1 for Sign Factor as Positive.
    end;

    local procedure PositiveAndNegativeAdjmtTrackingSerialNo(EntryType: Enum "Item Ledger Document Type"; FieldNo: Integer; SignFactor: Integer)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Quantity: Decimal;
    begin
        // Create Item with Tracking Code for SN Positive/Negative adjustment Inbound/Outbound Tracking, Create Item Journal Line.
        Quantity := LibraryRandom.RandInt(10);
        CreateItemTrackingCode(ItemTrackingCode, FieldNo, true);
        CreateItem(Item, ItemTrackingCode.Code, Item."Costing Method"::FIFO);
        CreateItemJournaLine(EntryType, Item."No.", LocationBlue.Code, SignFactor * Quantity, 0, false);
        Commit();  // Commit required for Test.

        // Exercise: Post Item Journal Line without Tracking.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Verify: Verify Error message.
        Assert.ExpectedError(StrSubstNo(SerialNumberRequiredErr, Item."No."));

        // Exercise: Assign Tracking and Post Item journal line.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0, false);  // Assign Tracking as SerialNo and Tracking Quantity not required.
        AssignTrackingOnItemJournalLines(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);  // Assign Item Tracking Line on Page Handler ItemTrackingPageHandler.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Verify: Verify Serial No and Number of line on Item Ledger Entry.
        VerifySerialNoOnItemLedgerEntry(Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseWithWarehouseTrackingSerialNo()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseSetup: Record "Warehouse Setup";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Create Item with Tracking Code for SN Specific Tracking and SN Warehouse Tracking. Create Purchase Order and Create Warehouse Receipt from Purchase Order.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        WarehouseSetup.Get();
        UpdatePostingPolicyOnWarehouseSetup(
          WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error",
          WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        CreateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("SN Specific Tracking"), true);
        UpdateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("SN Warehouse Tracking"), true);
        CreateItem(Item, ItemTrackingCode.Code, Item."Costing Method"::FIFO);

        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationGreen.Code, LibraryRandom.RandInt(10), 1);  // No. of Lines value required.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        SelectWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        // Exercise: Post Warehouse Receipt without Tracking.
        asserterror LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify Error message.
        Assert.ExpectedError(StrSubstNo(SerialNumberRequiredErr, Item."No."));

        // Exercise: Assign Tracking on Warehouse Receipt Line, Post Warehouse Receipt and Register Warehouse Activity. Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0, false);  // Assign Tracking as SerialNo and Tracking Quantity not required.
        WarehouseReceiptLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        PostWhseReceiptAndRegisterWarehouseActivity(
          WarehouseReceiptHeader, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order");

        // Verify: Verify Tracking line on Posted Purchase Receipt.Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, WarehouseReceiptLine.Quantity, false);  // Assign Tracking as SerialNo and Tracking Quantity not required.
        VerifyTrackingOnPostedPurchaseReceipt(PurchaseHeader."No.");

        // Tear Down.
        UpdatePostingPolicyOnWarehouseSetup(WarehouseSetup."Receipt Posting Policy", WarehouseSetup."Shipment Posting Policy");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderWithTransferTrackingSerialNoError()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Item with Tracking Code for SN Transfer Tracking, Create Transfer Order.
        Initialize();
        CreateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("SN Transfer Tracking"), true);
        CreateItem(Item, ItemTrackingCode.Code, Item."Costing Method"::FIFO);
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, LibraryRandom.RandInt(100), 0, false,
          AssignTracking::SerialNo);
        CreateAndReleaseTransferOrder(
          TransferHeader, TransferLine, LocationBlue.Code, LocationGreen.Code, Item."No.", LibraryRandom.RandInt(10));

        // Exercise: Create Warehouse Shipment from Transfer Order.
        asserterror LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // Verify: Verify Error message.
        Assert.ExpectedError(StrSubstNo(SerialNumberRequiredErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedLinesWarrantyDatePageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithWarrantyDateFormulaAndSerialNo()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DateFormulaVariable: DateFormula;
    begin
        // Setup: Create Item with Tracking Code for SN Specific Tracking with Warranty Date Formula, Create and Post Item Journal. Create and Post Sales Order.
        Initialize();
        Evaluate(DateFormulaVariable, '<1M>');
        UpdateItemTrackingCode(
          ItemTrackingCodeSerialSpecific, ItemTrackingCodeSerialSpecific.FieldNo("Warranty Date Formula"), DateFormulaVariable);
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 0, false,
          AssignTracking::SerialNo);

        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.

        // Exercise: Post Sales Order with Tracking.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify Tracking Entries and Warranty Date on Posted Sales Shipment on Page Handler PostedLinesWarrantyDatePageHandler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, SalesLine.Quantity, false);
        VerifyTrackingOnPostedSalesShipment(SalesHeader."No.", SalesLine.Quantity);

        // Tear Down.
        UpdateItemTrackingCode(ItemTrackingCodeSerialSpecific, ItemTrackingCodeSerialSpecific.FieldNo("Warranty Date Formula"), '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithWarrantyDateRequiredAndSerialNoError()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item with Tracking Code for SN Specific Tracking with "Man. Warranty Date Entry Reqd.", Create and Post Item Journal. Create and Post Sales Order.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 0, false,
          AssignTracking::SerialNo);

        UpdateItemTrackingCode(
          ItemTrackingCodeSerialSpecific, ItemTrackingCodeSerialSpecific.FieldNo("Man. Warranty Date Entry Reqd."), true);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.

        // Exercise: Post Sales Order with Tracking.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify Error message.
        Assert.ExpectedError(WarrantyDateErr);

        // Tear Down.
        UpdateItemTrackingCode(
          ItemTrackingCodeSerialSpecific, ItemTrackingCodeSerialSpecific.FieldNo("Man. Warranty Date Entry Reqd."), false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedLinesWarrantyDatePageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithWarrantyDateRequiredAndSerialNo()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Setup: Create Item with Tracking Code for SN Specific Tracking with "Man. Warranty Date Entry Reqd.", Create and Post Item Journal. Create and Post Sales Order.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 0, false,
          AssignTracking::SerialNo);
        UpdateItemTrackingCode(
          ItemTrackingCodeSerialSpecific, ItemTrackingCodeSerialSpecific.FieldNo("Man. Warranty Date Entry Reqd."), true);

        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler.
        UpdateWarrantyDateOnReservationEntry(ReservationEntry, Item."No.", DATABASE::"Sales Line", SalesHeader."No.");

        // Exercise: Post Sales Order with Tracking.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify Tracking Entries and Warranty Date on Posted Sales Shipment on Page Handler PostedLinesWarrantyDatePageHandler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, SalesLine.Quantity, false);
        VerifyTrackingOnPostedSalesShipment(SalesHeader."No.", SalesLine.Quantity);

        // Tear Down.
        UpdateItemTrackingCode(
          ItemTrackingCodeSerialSpecific, ItemTrackingCodeSerialSpecific.FieldNo("Man. Warranty Date Entry Reqd."), false);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,StrMenuHandler,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveLotNoOnPurchaseOrderFromTransferOrderPostingError()
    begin
        // Setup.
        Initialize();
        ReserveLotAndSerialNoOnPurchaseOrderFromTransferOrderWithPosting(ItemTrackingCodeLotSpecific.Code, AssignTracking::LotNo);  // Tracking Code for Lot No,Assign Tracking as Lot No.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,StrMenuHandler,ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSerialNoOnPurchaseOrderFromTransferOrderPostingError()
    begin
        // Setup.
        Initialize();
        ReserveLotAndSerialNoOnPurchaseOrderFromTransferOrderWithPosting(ItemTrackingCodeSerialSpecific.Code, AssignTracking::SerialNo);  // Tracking Code for Serial No,Assign Tracking as Serial No.
    end;

    local procedure ReserveLotAndSerialNoOnPurchaseOrderFromTransferOrderWithPosting(ItemTrackingCode: Code[10]; AssignTrackingValue: Option)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Item with Tracking Code for Lot / Serial Specific, Create Purchase Order and Transfer Order, Reserve from Purchase Order.
        CreateItem(Item, ItemTrackingCode, Item."Costing Method"::FIFO);

        SetGlobalValue(Item."No.", false, false, false, AssignTrackingValue, 0, false);  // Assign Tracking and Tracking Quantity not required.
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 1);  // No. of Lines value required.
        CreateAndReleaseTransferOrder(
          TransferHeader, TransferLine, LocationBlue.Code, LocationGreen.Code, Item."No.", LibraryRandom.RandInt(10));

        // Exercise: Reserve Transfer to Purchase.
        TransferLine.ShowReservation();  // Reservation on Page Handler ReservationPageHandler.

        // Verify : Verify Reserved Quantity on Purchase Line.
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        PurchaseLine.CalcFields("Reserved Quantity");
        PurchaseLine.TestField("Reserved Quantity", TransferLine.Quantity);

        // Exercise: Assign Tracking on Purchase line, Post Purchase and Transfer Order.
        PurchaseLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        asserterror LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // Verify: Verify Error message.
        if AssignTrackingValue = AssignTracking::LotNo then
            Assert.ExpectedError(StrSubstNo(LotNumberRequiredErr, Item."No."))
        else
            Assert.ExpectedError(StrSubstNo(SerialNumberRequiredErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,StrMenuHandler,ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveLotNoOnPurchaseOrderFromTransferOrder()
    begin
        // Setup.
        Initialize();
        ReserveLotAndSerialNoOnPurchaseOrderFromTransferOrder(ItemTrackingCodeLotSpecific.Code, AssignTracking::LotNo);  // Tracking Code for Lot No,Assign Tracking as Lot No.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,StrMenuHandler,ItemTrackingPageQtyToHandleHandler,ItemTrackingSummaryPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSerialNoOnPurchaseOrderFromTransferOrder()
    begin
        // Setup.
        Initialize();
        ReserveLotAndSerialNoOnPurchaseOrderFromTransferOrder(ItemTrackingCodeSerialSpecific.Code, AssignTracking::SerialNo);  // Tracking Code for Serial No,Assign Tracking as Serial No.
    end;

    local procedure ReserveLotAndSerialNoOnPurchaseOrderFromTransferOrder(ItemTrackingCode: Code[10]; AssignTrackingValue: Option)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // Setup: Create Item with Tracking Code for Lot / Serial Specific, Create Purchase Order and Transfer Order, Reserve from Purchase Order.
        CreateItem(Item, ItemTrackingCode, Item."Costing Method"::FIFO);

        SetGlobalValue(Item."No.", false, false, false, AssignTrackingValue, 0, false);  // Assign Tracking and Tracking Quantity not required.
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 1);  // No. of Lines value required.
        CreateAndReleaseTransferOrder(
          TransferHeader, TransferLine, LocationBlue.Code, LocationGreen.Code, Item."No.", LibraryRandom.RandInt(10));

        TransferLine.ShowReservation();  // Reservation on Page Handler ReservationPageHandler.
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking on Page Handler ItemTrackingPageHandler for Lot No and ItemTrackingPageQtyToHandleHandler for Serial No.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, 0, false);  // Assign Tracking as NONE.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);  // Assign Ship Tracking on Page Handler ItemTrackingPageHandler for Lot No and ItemTrackingPageQtyToHandleHandler for Serial No.

        // Exercise: Post -Ship Transfer Order with Tracking.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // Verify: Verify Receipt Tracking Entries on Transfer Order.
        SetGlobalValue(Item."No.", false, true, false, AssignTracking::None, TransferLine.Quantity, false);  // Tracking Quantity;
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Inbound);  // Verify Receipt Tracking on Page Handler ItemTrackingPageHandler for Lot No and ItemTrackingPageQtyToHandleHandler for Serial No.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingProductionPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,AvailabilityWarningsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReserveLotNoOnProdOrderFromSalesOrderPartialOutputPostingError()
    begin
        // Setup.
        Initialize();
        ReserveLotAndSerialNoOnProdOrderFromSalesOrderPartialOutputPosting(ItemTrackingCodeLotSpecific.Code, AssignTracking::LotNo);  // Tracking Code for Lot No,Assign Tracking as Lot No.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingProductionSerialNoPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,AvailabilityWarningsConfirmHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSerialNoOnProdOrderFromSalesOrderPartialOutputPostingError()
    begin
        // Setup.
        Initialize();
        ReserveLotAndSerialNoOnProdOrderFromSalesOrderPartialOutputPosting(ItemTrackingCodeSerialSpecific.Code, AssignTracking::SerialNo);  // Tracking Code for Serial No,Assign Tracking as Serial No.
    end;

    local procedure ReserveLotAndSerialNoOnProdOrderFromSalesOrderPartialOutputPosting(ItemTrackingCode: Code[10]; AssignTrackingValue: Option)
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Create Item with Tracking Code for Lot / Serial Specific Tracking, Create Sales and Production Order, Reserve Sales.
        Quantity := LibraryRandom.RandInt(10) + 20;  // Large Value required.
        CreateSalesProductionSetup(Item, Item2, SalesLine, ProductionOrder, Quantity, LocationBlue.Code, ItemTrackingCode, AssignTrackingValue);

        OpenItemTrackingLinesForProdOrderComponent(ProductionOrder.Status::Released, ProductionOrder."No.", Item2."No.");  // Assign Item Tracking Line on Page Handler ItemTrackingProductionPageHandler.
        SetGlobalValue(Item."No.", false, false, false, AssignTrackingValue, 0, false);  // Assign Tracking.
        OpenItemTrackingLinesForProduction(ProductionOrder."No.");  // Assign Tracking on Page Handler ItemTrackingProductionPageHandler.
        DocumentNo := ProductionOrder."No.";  // Assign Global Variable.
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, SalesLine.Quantity, false);  // Partial -True and Tracking Quantity.

        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingProductionPageHandler.
        SalesLine.ShowReservation();  // Reserve current line -Production Order on Page Handler ReservationPageHandler.

        // Verify: Verify Reserved Quantity on Sales line.
        SalesLine.CalcFields("Reserved Quantity");
        if AssignTrackingValue = AssignTracking::LotNo then
            SalesLine.TestField("Reserved Quantity", SalesLine.Quantity)
        else
            SalesLine.TestField("Reserved Quantity", 1);  // Value requried for Specific Serial No.

        // Exercise: Create Output Journal and Update Output Quantity.
        CreateOutputJournalWithExlpodeRouting(ProductionOrder."No.");
        UpdateOutputQuantityOnItemJournalLine(
          ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name, Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingProductionPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,AvailabilityWarningsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReserveLotNoOnProdOrderFromSalesOrderAndSalesWithPartialTrackingPostingError()
    begin
        // [FEATURE] [Item Tracking] [Sales]
        // [SCENARIO] Verify Error message when trying to ship Sales Order with Partial Lot specific Tracking, after create Sales and Production Order, Reserve Sales, Post Output and Consumption.

        // Setup.
        Initialize();
        ReserveLotNoOnProdOrderFromSalesOrder(true);  // Post Sales Order as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingProductionPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ItemLedgerEntriesPageHandler,AvailabilityWarningsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReserveLotNoOnProdOrderFromSalesOrderReservedQuantity()
    begin
        // [FEATURE] [Item Tracking] [Sales]
        // [SCENARIO] Verify Reservation on ILE after Create Sales and Production Order, Reserve Sales, Post Output and Consumption, finish Production Order.

        // Setup.
        Initialize();
        ReserveLotNoOnProdOrderFromSalesOrder(false);  // Post Sales Order as False.
    end;

    local procedure ReserveLotNoOnProdOrderFromSalesOrder(PostSalesOrder: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        ReservationEntries: TestPage "Reservation Entries";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Tracking Code for Lot Specific Tracking, Create Sales and Production Order, Reserve Sales,Post Output and Consumption, finish Production Order.
        Quantity := LibraryRandom.RandInt(10) + 20;  // Large Value required.
        CreateSalesProductionSetup(
          Item, Item2, SalesLine, ProductionOrder, Quantity, LocationBlue.Code, ItemTrackingCodeLotSpecific.Code, AssignTracking::LotNo);

        OpenItemTrackingLinesForProdOrderComponent(ProductionOrder.Status::Released, ProductionOrder."No.", Item2."No.");  // Assign Item Tracking Line on Page Handler ItemTrackingProductionPageHandler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::LotNo, 0, false);  // Assign Tracking as LotNo.
        OpenItemTrackingLinesForProduction(ProductionOrder."No.");  // Assign Tracking on Page Handler ItemTrackingProductionPageHandler.
        DocumentNo := ProductionOrder."No.";  // Assign Global Variable.
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, SalesLine.Quantity - 1, false);  // Partial as True and Tracking Quantity.

        SalesLine.OpenItemTrackingLines();  // Assign Partial Tracking on Page Handler ItemTrackingProductionPageHandler.
        SalesLine.ShowReservation();  // Reserve current line-Production Order on Page Handler ReservationPageHandler.

        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, SalesLine.Quantity, false);  // Partial as True and Tracking Quantity.
        CreateOutputJournalWithExlpodeRouting(ProductionOrder."No.");
        AssignTrackingOnItemJournalLines(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        UpdateQuantityAndPostOutputJournal(SalesLine.Quantity, false);  // Partial Quantity.

        CreateAndPostConsumptionJournal(ProductionOrder."No.", false);
        OpenItemTrackingLinesForProduction(ProductionOrder."No.");  // Assign Partial Tracking on Page Handler ItemTrackingProductionPageHandler.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        if PostSalesOrder then begin
            // Exercise: Post Sales Order with Partial Tracking.
            asserterror PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", true, false);

            // Verify: Verify Error message.
            Assert.ExpectedError(StrSubstNo(QtyToHandleErr, Item."No."));
        end else begin
            // Exercise: Drill down Reserved Quantity.
            ReservationEntries.Trap();
            OpenReservedQuantityOnSalesOrder(SalesLine."Document No.");

            // Verify: Verify Reservation on Item Ledger Entry on Page Handler ItemLedgerEntriesPageHandler.
            ReservationEntries.ReservedFrom.Drilldown();
        end;
    end;

    [Test]
    [HandlerFunctions('AvailabilityItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithItemTrackingLotNoAvailability()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Availability Lot No. field must be Yes on the Item Tracking Lines page after creating a Purchase Order with Lot No.

        // 1. Setup: Create Item with Lot No., Create a Purchase Order and assign Lot No.
        Initialize();
        CreateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("Lot Specific Tracking"), true);
        CreateItem(Item, ItemTrackingCode.Code, Item."Costing Method"::FIFO);

        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item."No.", '', 1 + LibraryRandom.RandInt(10));  // Random Integer value greater than 1 required for test.
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        ItemTrackingAction := ItemTrackingAction::AvailabilityLotNo;

        // 2. Exercise.
        PurchaseLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Availability Lot No. field must be Yes on the Item Tracking Lines page. Verification done in the 'ItemTrackingPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('AvailabilityItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithItemTrackingSerialNoAvailability()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify warning message when assigning wrong Serial No.

        // 1. Setup: Create Item with Serial No., create Purchase Order with Item Tracking.
        Initialize();
        CreateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("SN Specific Tracking"), true);
        CreateItem(Item, ItemTrackingCode.Code, Item."Costing Method"::FIFO);
        CreateNewLotNo := true;  // Assign to global variable.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item."No.", '', 1 + LibraryRandom.RandInt(10));  // Random Integer value greater than 1 required for test.
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        ItemTrackingAction := ItemTrackingAction::AvailabilitySerialNo;

        // 2. Exercise.
        PurchaseLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        // 3. Verify: Verify Availability Serial No. field must be Yes on the Item Tracking Lines page. Verification done in the 'ItemTrackingPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingProductionSerialNoPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,AvailabilityWarningsWithQtyZeroConfirmHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSerialNoOnProdOrderFromSalesOrderAndSalesWithPartialTrackingPostingError()
    begin
        // Setup.
        Initialize();
        ReserveSerialNoOnProdOrderFromSalesOrder(true);  // Partial Tracking as True.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingProductionSerialNoPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,AvailabilityWarningsWithQtyZeroConfirmHandler,QuantityToCreatePageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSerialNoOnProdOrderFromSalesOrderAndSalesWithTrackingPosting()
    begin
        // Setup.
        Initialize();
        ReserveSerialNoOnProdOrderFromSalesOrder(false);  // Partial Tracking as False.
    end;

    local procedure ReserveSerialNoOnProdOrderFromSalesOrder(PartialTracking: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Create Item with Tracking Code for Lot Specific Tracking, Create Sales and Production Order, Reserve Sales,Post Output and Consumption.
        Quantity := LibraryRandom.RandInt(10) + 20;  // Large Value required.
        CreateSalesProductionSetup(
          Item, Item2, SalesLine, ProductionOrder, Quantity, LocationBlue.Code, ItemTrackingCodeSerialSpecific.Code, AssignTracking::SerialNo);

        OpenItemTrackingLinesForProdOrderComponent(ProductionOrder.Status::Released, ProductionOrder."No.", Item2."No.");  // Assign Item Tracking Line on Page Handler ItemTrackingProductionSerialNoPageHandler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0, false);  // Assign Tracking as LotNo.
        OpenItemTrackingLinesForProduction(ProductionOrder."No.");  // Assign Tracking on Page Handler ItemTrackingProductionSerialNoPageHandler.
        DocumentNo := ProductionOrder."No.";  // Assign Global Variable.
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, SalesLine.Quantity - 1, false);  // Partial as True and Tracking Quantity.

        SalesLine.OpenItemTrackingLines();  // Assign Partial Tracking on Page Handler ItemTrackingProductionSerialNoPageHandler.
        SalesLine.ShowReservation();  // Reserve current line-Production Order on Page Handler ReservationPageHandler.

        SetGlobalValue(Item."No.", false, true, true, AssignTracking::None, Quantity - SalesLine.Quantity, false);  // Partial as True and Tracking Quantity.
        CreateOutputJournalWithExlpodeRouting(ProductionOrder."No.");
        AssignTrackingOnItemJournalLines(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        UpdateQuantityAndPostOutputJournal(SalesLine.Quantity, false);  // Partial Quantity.

        if PartialTracking then begin
            // Exercise: Post Sales Order with Partial Tracking.
            asserterror PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", true, true);

            // Verify: Verify Error message.
            Assert.ExpectedError(QtyToInvoiceDoesNotMatchItemTrackingErr);
        end else begin
            // Exercise:
            DeleteReservationEntry(Item."No.", DATABASE::"Sales Line", SalesLine."Document No.");  // Delete Tracking on Sales line.
            SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, 0, false);
            SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingProductionSerialNoPageHandler.
            PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", true, true);

            // Verify: Verify Tracking line on Post Sales Invoice.
            SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, SalesLine.Quantity, false);  // Assign Tracking as Serial No and Tracking Quantity.
            VerifyTrackingOnPostedSalesInvoice(SalesLine."Document No.", false);  // Verify on Page handler PostedLinesPageHandler.
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,QuantityToCreatePageHandler,ItemLedgerEntriesPositiveAdjmtPageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSerialNoOnItemLedgerEntryFromSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Item, create and Post Item Journal, Create Sales order and Reserve with Item Ledger Entry.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, 0, false);

        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 0, false,
          AssignTracking::SerialNo);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));

        // Exercise: Reserve Sales to Item Ledger Entry.
        SalesLine.ShowReservation();  // Reserve Sales to Item Ledger Entry on Page Handler ReservationPageHandler.

        // Verify: Verify Reservation on Item Ledger Entry on Page Handler ItemLedgerEntriesPositiveAdjmtPageHandler.
        VerifyReservedQuantity(SalesLine);

        // Exercise: Assign Item Tracking on Sales Line and Post.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify Tracking line on Post Sales Shipment.
        VerifyTrackingOnPostedSalesShipment(SalesHeader."No.", SalesLine.Quantity);  // Verify on Page Handler PostedLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,ReservationAvailablePageHandler')]
    [Scope('OnPrem')]
    procedure ReserveOnTransferOrderFromProdOrderComponentAvailableLotNo()
    begin
        // Setup.
        Initialize();
        AvailableReserveLotAndSerialNoOnTransferOrderFromProdOrderComponent(ItemTrackingCodeLotSpecific.Code, AssignTracking::LotNo);  // Tracking Code for Lot No,Assign Tracking as Lot No.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,QuantityToCreatePageHandler,ReservationAvailablePageHandler')]
    [Scope('OnPrem')]
    procedure ReserveOnTransferOrderFromProdOrderComponentAvailableSerialNo()
    begin
        // Setup.
        Initialize();
        AvailableReserveLotAndSerialNoOnTransferOrderFromProdOrderComponent(
          ItemTrackingCodeSerialSpecific.Code, AssignTracking::SerialNo);  // Tracking Code for Serial No,Assign Tracking as Serial No.
    end;

    local procedure AvailableReserveLotAndSerialNoOnTransferOrderFromProdOrderComponent(ItemTrackingCode: Code[10]; AssignTrackingValue: Option)
    var
        Item: Record Item;
        Item2: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Create Item, Create and Post Item Journal, Create Transfer Order and Production Order.
        CreateTransferOrderSetup(Item, Item2, TransferHeader, TransferLine, ItemTrackingCode, AssignTrackingValue);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 30);
        UpdateDueDateOnReleasedProductionOrder(ProductionOrder);

        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", Item2."No.");

        // Exercise and Verify: Reservation on Production Order Component.Verify Available Reservation line on Page Handler ReservationAvailablePageHandler.
        ProdOrderComponent.ShowReservation();  // Verify on Page Handler ReservationAvailablePageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingProductionPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,AvailabilityWarningsAndReserveConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReserveLotNoOnTransferOrderFromConsumption()
    begin
        // Setup.
        Initialize();
        ReserveLotAndSerialNoOnTransferOrderFromConsumption(ItemTrackingCodeLotSpecific.Code, AssignTracking::LotNo);  // Tracking Code for Lot No,Assign Tracking as Lot No.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingProductionPageHandler,ItemTrackingSummaryPageHandler,QuantityToCreatePageHandler,ItemTrackingListPageHandler,ReservationPageHandler,NegativeAdjustmentConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReserveSerialNoOnTransferOrderFromConsumption()
    begin
        // Setup.
        Initialize();
        ReserveLotAndSerialNoOnTransferOrderFromConsumption(ItemTrackingCodeSerialSpecific.Code, AssignTracking::SerialNo);  // Tracking Code for Serial No,Assign Tracking as Serial No.
    end;

    local procedure ReserveLotAndSerialNoOnTransferOrderFromConsumption(ItemTrackingCode: Code[10]; AssignTrackingValue: Option)
    var
        Item: Record Item;
        Item2: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Create Item, Create and Post Item Journal, Create Transfer Order and Production Order.
        CreateTransferOrderSetup(Item, Item2, TransferHeader, TransferLine, ItemTrackingCode, AssignTrackingValue);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 30);
        UpdateDueDateOnReleasedProductionOrder(ProductionOrder);

        DocumentNo := TransferHeader."No.";  // Assign Global Variable.
        SetGlobalValue(Item2."No.", false, false, true, AssignTracking::None, ProductionOrder.Quantity, false);  // Partial as True and Tracking Quantity.
        if AssignTrackingValue = AssignTracking::LotNo then
            ItemTrackingAction := ItemTrackingAction::AvailabilityLotNo
        else
            ItemTrackingAction := ItemTrackingAction::AvailabilitySerialNo;
        OpenItemTrackingLinesForProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", Item2."No.");
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", Item2."No.");

        // Exercise: Reserve Production Order Component to Transfer Order and Post Transfer Order.
        ProdOrderComponent.ShowReservation();  // Reservation on Page Handler ReservationPageHandler.
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // Verify: Verify Reserved Quantity on Production Order Component.
        VerifyReservedQuantityProdOrderComponent(ProdOrderComponent, TransferLine.Quantity, AssignTrackingValue);

        // Exercise: Calculate Consumption.
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // Verify: Verify Tracking line on Consumption Item Journal.
        SetGlobalValue(Item2."No.", false, true, false, AssignTracking::None, ProductionOrder.Quantity, false);  // VerifyQtyToHandle as True.
        VerifyTrackingOnConsumptionItemJournal();  // Verify on Page Handler ItemTrackingProductionPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithSameSerialNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Create Item With Tracking Code Serial Specific, Create Purchase Order and assign Tracking.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0, false);  // New Lot No -True,Assign Tracking as Serial No.
        CreateAndReleasePurchaseOrderWithTracking(PurchaseHeader, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 1);  // Using Large random value for Quantity, No. of Lines value required.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, 0, false);  // Assign Tracking as None.
        ItemTrackingAction := ItemTrackingAction::AvailabilitySerialNo;  // Assign Global Variable for Page Handler.

        // Exercise: Change Serial No as duplicate on Page Handler.
        asserterror AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Change Identical Tracking on Page Handler ItemTrackingSerialNoPageHandler.

        // Verify: Verify Message of Error
        Assert.ExpectedError(TrackingAlreadyExistMsg);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler,AvailabilityConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithSameSerialNo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item With Tracking Code Serial Specific, Create Sales Order and assign Tracking.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0, false);  // New Lot No -True,Assign Tracking as Serial No.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationGreen.Code, LibraryRandom.RandInt(10) + 10);  // Using Large random value for Quantity.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingSerialNoPageHandler.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, 0, false);  // Assign Tracking as None.
        ItemTrackingAction := ItemTrackingAction::AvailabilitySerialNo;  // Assign Global Variable for Page Handler.

        // Exercise: Change Serial No as duplicate on Page Handler.
        asserterror SalesLine.OpenItemTrackingLines();  // Change Identical Tracking on Page Handler ItemTrackingSerialNoPageHandler.

        // Verify: Verify Message on Message Handler TrackingAlreadyExistMessageHandler.
        Assert.ExpectedError(TrackingAlreadyExistMsg);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrdersWithSameSerialNoOnInventoryPostingError()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Item With Tracking Code Serial Specific, Create Two Purchase Order and assign Tracking.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0, false);  // New Lot No -True,Assign Tracking as Serial No.
        CreateAndReleasePurchaseOrderWithTracking(PurchaseHeader, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 1);  // Using Large random value for Quantity, No. of Lines value required.
        CreateAndReleasePurchaseOrderWithTracking(PurchaseHeader2, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 1);  // Using Large random value for Quantity, No. of Lines value required.

        DocumentNo := PurchaseHeader."No.";  // Assign Global Variable for Page Handler.
        SetGlobalValue(Item."No.", false, false, true, AssignTracking::None, 0, false);  // Partial as True.
        AssignTrackingOnPurchaseLine(PurchaseHeader2."No.");  // Assign Change Identical Tracking as Previous Purchase Order Tracking on Page Handler ItemTrackingSerialNoPageHandler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Exercise: Post Purchase Order with Identical Tracking.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify Error Message.
        Assert.ExpectedError(AlreadyOnInventoryErr);

        // Exercise: Delete Tracking,Assign Tracking and post Purchase Order.
        DeleteReservationEntry(Item."No.", DATABASE::"Purchase Line", PurchaseHeader2."No.");
        SelectPurchaseLine(PurchaseLine, PurchaseHeader2."No.");
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, PurchaseLine.Quantity, false);  // New Lot No -True,Assign Tracking as Serial No and Tracking Quantity.
        AssignTrackingOnPurchaseLine(PurchaseHeader2."No.");
        PostPurchaseDocument(PurchaseHeader2."Document Type", PurchaseHeader2."No.", true, true);

        // Verify: Verify Tracking and No of Line on Posted Purchase Invoive.
        VerifyTrackingOnPostedPurchaseInvoice(PurchaseHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler,AvailabilityWarningsConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithoutSerialNoOnInventoryPostingError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item With Tracking Code Serial Specific, Create Sales Order and assign Tracking.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        // Assign Global variable for Page Handler.
        SetGlobalValue(Item."No.", true, false, false, AssignTracking::SerialNo, 0, false);  // New Lot No -True,Assign Tracking as Serial No.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingSerialNoPageHandler.

        // Exercise: Post Sales Order.
        asserterror PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, false);

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(VariantFullyAppliedErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,CombinedShipmentsMessageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvForCombinedShipmentWithSerialNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Setup: Create Item With Tracking Code Serial Specific, Create Customer, Create two Sales Order and assign Tracking and Post with Ship option.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        CreateItem(Item2, ItemTrackingCodeSerialSpecific.Code, Item2."Costing Method"::FIFO);
        CreateCustomerWithCombineShipments(Customer);  // Create Customer require for Combine Shipments.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 0, false,
          AssignTracking::SerialNo);  // Using Large random value for Quantity.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item2."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 0, false,
          AssignTracking::SerialNo);  // Using Large random value for Quantity.

        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, 0, false);
        CreateAndPostSalesOrderWithTracking(
          SalesHeader, SalesLine, Customer."No.", Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));
        CreateAndPostSalesOrderWithTracking(
          SalesHeader2, SalesLine2, Customer."No.", Item2."No.", LocationBlue.Code, LibraryRandom.RandInt(10));

        // Exercise: Combine Sales Shipments and Post Invoice.
        SalesHeader2.SetRange("Sell-to Customer No.", Customer."No.");
        SalesShipmentHeader.SetRange("Sell-to Customer No.", Customer."No.");
        LibrarySales.CombineShipments(SalesHeader2, SalesShipmentHeader, WorkDate(), WorkDate(), false, true, false, false);

        // Verify: Verify Tracking line on Posted Sales Invoive Line.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, SalesLine.Quantity, false);  // Tracking Quantity required.
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindFirst();

        VerifyTrackingOnSalesInvoiceLine(SalesInvoiceHeader."No.", Item."No.");
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, SalesLine2.Quantity, false);  // Tracking Quantity required.
        VerifyTrackingOnSalesInvoiceLine(SalesInvoiceHeader."No.", Item2."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,CombinedReturnReceiptMessageHandler,PostedLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoForCombinedReceiptWithSerialNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Setup: Create Item With Tracking Code Serial Specific, Create Customer, Create two Sales Return Order and assign Tracking and Post with Receive option.
        Initialize();
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        CreateItem(Item2, ItemTrackingCodeSerialSpecific.Code, Item2."Costing Method"::FIFO);
        CreateCustomerWithCombineShipments(Customer);  // Create Customer require for Combine Return Receipt.

        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0, false);
        CreateAndPostSalesReturnOrderWithTracking(
          SalesHeader, SalesLine, Customer."No.", Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));
        CreateAndPostSalesReturnOrderWithTracking(
          SalesHeader2, SalesLine2, Customer."No.", Item2."No.", LocationBlue.Code, LibraryRandom.RandInt(10));

        // Exercise: Combine Sales Return Receipt and Post Invoice.
        SalesHeader2.SetRange("Sell-to Customer No.", Customer."No.");
        ReturnReceiptHeader.SetRange("Sell-to Customer No.", Customer."No.");
        LibrarySales.CombineReturnReceipts(SalesHeader2, ReturnReceiptHeader, WorkDate(), WorkDate(), false, true);

        // Verify: Verify Tracking line on Posted Sales Credit Memo Line.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, SalesLine.Quantity, false);  // Tracking Quantity required.
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesCrMemoHeader.FindFirst();

        VerifyTrackingOnSalesCrMemoLine(SalesCrMemoHeader."No.", Item."No.");
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, SalesLine2.Quantity, false);  // Tracking Quantity required.
        VerifyTrackingOnSalesCrMemoLine(SalesCrMemoHeader."No.", Item2."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure VSTF307923_PostFractionOfSerialNo()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Posting of fractional quantity of serial number
        Initialize();

        // SETUP: Create item with serial no. and post a fractional quantity
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
        AssignTracking := AssignTracking::SerialNo;  // Assign Global variable for Page Handler.
        CreateItemJournaLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", '', 1, 0, false);
        AssignTrackingOnItemJournalLines(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);  // Assign Item Tracking Line on Page Handler.

        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindLast();
        ItemJournalLine.Quantity := 0.5;
        ItemJournalLine."Invoiced Quantity" := 0.5;
        ItemJournalLine."Quantity (Base)" := 0.5;
        ItemJournalLine."Invoiced Qty. (Base)" := 0.5;
        ItemJournalLine.Modify();

        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.FindLast();
        ReservationEntry.Quantity := ItemJournalLine.Quantity;
        ReservationEntry."Quantity (Base)" := ItemJournalLine."Quantity (Base)";
        ReservationEntry."Qty. to Handle (Base)" := ReservationEntry."Quantity (Base)";
        ReservationEntry."Qty. to Invoice (Base)" := ReservationEntry."Quantity (Base)";
        ReservationEntry.Modify();

        // EXERCISE: post the item journal line
        // VERIFY: catch the error message
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        Assert.IsTrue(StrPos(GetLastErrorText, SerialNumberPossibleValuesErr) > 0, '');
        ClearLastError();
        AssignTracking := AssignTracking::None;  // Assign Global variable for Page Handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF307923_QtyToHandle()
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        // Unit test - Posting of serial numbers in fractions should not be allowed.
        Initialize();

        // SETUP: Create a Tracking Specification record
        TrackingSpecification.Init();
        TrackingSpecification."Serial No." :=
          LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("Serial No."), DATABASE::"Tracking Specification");
        TrackingSpecification."Quantity (Base)" := 1;

        // EXERCISE: Validate the Quantity to Handle to a fraction
        // VERIFY: Catch the error message
        asserterror TrackingSpecification.Validate("Qty. to Handle (Base)", 0.5); // fractionalize Qty to Handle
        Assert.IsTrue(StrPos(GetLastErrorText, SerialNumberPossibleValuesErr) > 0, '');
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF307923_QtyToInvoice()
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        // Unit test - Posting of serial numbers in fractions should not be allowed.

        Initialize();

        // SETUP: Create a Tracking Specification record
        TrackingSpecification.Init();
        TrackingSpecification."Serial No." :=
          LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("Serial No."), DATABASE::"Tracking Specification");
        TrackingSpecification."Quantity (Base)" := -1;
        TrackingSpecification."Qty. to Handle (Base)" := -1;

        // EXERCISE: Validate the Quantity to Invoice to a fraction
        // VERIFY: Catch the error message
        asserterror TrackingSpecification.Validate("Qty. to Invoice (Base)", -0.5); // fractionalize Qty to Invoice
        Assert.IsTrue(StrPos(GetLastErrorText, SerialNumberPossibleValuesErr) > 0, '');
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithSerialItemTracking()
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Customer. Create Item. Create Item Journal Line with Serial Item Tracking.
        // Create and Ship the Sales Order with Serial Item Tracking.
        Initialize();
        InitSetupForUpdateItemTrackingLines(SalesLine, ItemTrackingCodeSerialSpecific.Code, false, AssignTracking::SerialNo); // Using large random value.

        // Exercise: Update the Serial No on Item Tracking Lines.
        // Verify: Verify the error message when update the Serial No by ASSISTEDIT.
        UpdateSerialNo := true;
        VerifyErrorMsgByUpdateItemTrackingLines(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryFindLastModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithLotItemTracking()
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Customer. Create Item. Create multiple Item Journal Lines with Lot Item Tracking.
        // Create and Ship the Sales Order with Lot Item Tracking.
        Initialize();
        InitSetupForUpdateItemTrackingLines(SalesLine, ItemTrackingCodeLotSpecific.Code, true, AssignTracking::LotNo);

        // Exercise: Update the Lot No on Item Tracking Lines.
        // Verify: Verify the error message when update the Lot No by ASSISTEDIT.
        UpdateLotNo := true;
        VerifyErrorMsgByUpdateItemTrackingLines(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSerialNoPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure VSTF359616_ItemWithSerialNoAndMultipleUoM()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemTrackingCodeSerialWMSSpecific: Record "Item Tracking Code";
        UnitOfMeasure: Record "Unit of Measure";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Customer. Create Item with 2 unit of measures, PCS and BOX (3 PCS)  and SN tracking
        // Create and Ship the Sales Order with BOX

        Initialize();

        // Create item with PCS and BOX, Serial No. tracking
        CreateItemTrackingCode(
          ItemTrackingCodeSerialWMSSpecific, ItemTrackingCodeSerialWMSSpecific.FieldNo("SN Specific Tracking"), true);
        ItemTrackingCodeSerialWMSSpecific.Validate("SN Warehouse Tracking", true);
        ItemTrackingCodeSerialWMSSpecific.Modify();
        CreateItem(Item, ItemTrackingCodeSerialWMSSpecific.Code, Item."Costing Method"::FIFO);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 3);

        // Post inventory with serial numbers in base UOM
        CreateAndPostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationSilver.Code,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(10, 20), false, AssignTracking::SerialNo);

        // Create and post sales order with 1 BOX
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Item."No.", LocationSilver.Code, 1, Customer."No.", true);
        SalesLine.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify();
        SalesLine.OpenItemTrackingLines();  // Assign Item Tracking on Page Handler.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostingTrackedSalesReturnOrderWithBlankUnitCost()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Sales Return Order] [Item Tracking]
        // [SCENARIO 375644] Posting Tracked Sales Return Order with zero Unit Cost should not fill "Cost Amount (Actual)" of Item Ledger Entry
        Initialize();

        // [GIVEN] Item with SN tracking
        CreateItem(Item, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);

        // [GIVEN] Tracked Sales Rerun Order for Item with Unit Cost = 0 and Unit Price = "X"
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::SerialNo, 0, false);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order",
          Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10), CreateCustomer(), false);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        SalesLine.OpenItemTrackingLines();  // Assign Item Tracking on Page Handler.

        // [WHEN] Post Sales Return Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [THEN] Item Ledger Entry is created where Cost Amount (Actual) = 0
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryPageLongDocTypeFilter()
    var
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [FEATURE] [Item Ledger Entries] [Filter] [UT]
        // [SCENARIO 375688] It should be possible to set >250 symbols long filter on "Document Type" in Item Ledger Entries page
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.FILTER.SetFilter("Document Type", ItemLedgerEntryFilterTxt);
        Assert.AreEqual(
          Format(ItemLedgerEntryFilterTxt), ItemLedgerEntries.FILTER.GetFilter("Document Type"), ItemLedgerEntryFilteringErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyItemTrackingFromSalesShipmentLineToInvoiceLine()
    var
        FromSalesLine: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        ItemEntryRelation: Record "Item Entry Relation";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [UT]
        // [SCENARIO 379129] Item Tracking field in Reservation Entry for Sales Invoice Line should be filled with Lot Tracking option when Item Tracking is copied from another Sales Line.

        // [GIVEN] Source and destination Sales Lines.
        ItemNo := LibraryUtility.GenerateGUID();

        MockSalesLine(FromSalesLine, FromSalesLine."Document Type"::Order, ItemNo, '');
        MockSalesLine(ToSalesLine, ToSalesLine."Document Type"::Invoice, ItemNo, LibraryUtility.GenerateGUID());

        // [GIVEN] Item Entry Relation with "Lot No." and "Serial No." not empty.
        MockItemEntryRelation(ItemEntryRelation, DATABASE::"Sales Shipment Line", ToSalesLine."Shipment No.");

        // [GIVEN] Tracking Specification.
        MockTrackingSpecificationFromItemEntryRelation(ItemEntryRelation, ItemNo);

        // [WHEN] Call CopyHandledItemTrkgToInvLine procedure from Item Tracking Management.
        ItemTrackingManagement.CopyHandledItemTrkgToInvLine(FromSalesLine, ToSalesLine);
        // [THEN] "Item Tracking" option field in Reservation Entry created by the call of the procedure contains "Lot and Serial No." value.
        FilterReservationEntryBySource(
          ReservationEntry, 0, ToSalesLine."Document Type".AsInteger(), ToSalesLine."Document No.", Format(ToSalesLine."Line No."));
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Item Tracking", ReservationEntry."Item Tracking"::"Lot and Serial No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyItemTrackingFromPurchReturnLineToCrMemoLine()
    var
        FromPurchaseLine: Record "Purchase Line";
        ToPurchaseLine: Record "Purchase Line";
        ItemEntryRelation: Record "Item Entry Relation";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [UT]
        // [SCENARIO 379129] Item Tracking field in Reservation Entry for Purch. Cr. Memo Line should be filled with Lot Tracking option when Item Tracking is copied from another Purchase Line.

        // [GIVEN] Source and destination Purchase Lines.
        ItemNo := LibraryUtility.GenerateGUID();

        MockPurchaseLine(FromPurchaseLine, FromPurchaseLine."Document Type"::"Return Order", ItemNo, '');
        MockPurchaseLine(ToPurchaseLine, ToPurchaseLine."Document Type"::"Credit Memo", ItemNo, LibraryUtility.GenerateGUID());

        // [GIVEN] Item Entry Relation with "Lot No." and "Serial No." not empty.
        MockItemEntryRelation(ItemEntryRelation, DATABASE::"Return Shipment Line", ToPurchaseLine."Return Shipment No.");

        // [GIVEN] Tracking Specification.
        MockTrackingSpecificationFromItemEntryRelation(ItemEntryRelation, ItemNo);

        // [WHEN] Call CopyHandledItemTrkgToInvLine2 procedure from Item Tracking Management.
        ItemTrackingManagement.CopyHandledItemTrkgToInvLine(FromPurchaseLine, ToPurchaseLine);
        // [THEN] "Item Tracking" option field in Reservation Entry created by the call of the procedure contains "Lot and Serial No." value.
        FilterReservationEntryBySource(
          ReservationEntry, 0, ToPurchaseLine."Document Type".AsInteger(), ToPurchaseLine."Document No.", Format(ToPurchaseLine."Line No."));
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Item Tracking", ReservationEntry."Item Tracking"::"Lot and Serial No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,GetShipmentLinesPageHandler,DeleteLinesWithTrackingConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DeleteSalesInvoiceWithTrackedLines()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        SalesLineInvoice: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        SalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Sales Invoice]
        // [SCENARIO 379129] Sales Invoice can be deleted with all its lines and tracking which were created from the posted Sales Shipment with Lot Tracking.
        Initialize();

        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Item with Lot Tracking Code, posted positive Item Journal Line with Lot Item Tracking.
        CreateItem(Item, ItemTrackingCodeLotSpecific.Code, Item."Costing Method"::FIFO);
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(10, 20), false, AssignTracking::LotNo);

        // [GIVEN] Shipped Sales Order with Lot Item Tracking.
        CreateAndPostSalesOrderWithTracking(
          SalesHeaderOrder, SalesLineOrder, Customer."No.", Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Sales Invoice with lines copied from Sales Shipment by GetShipmentLines function.
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, Customer."No.");
        SalesInvoiceNo := SalesHeaderInvoice."No.";
        SalesLineInvoice."Document Type" := SalesHeaderInvoice."Document Type";
        SalesLineInvoice."Document No." := SalesHeaderInvoice."No.";
        LibrarySales.GetShipmentLines(SalesLineInvoice);

        // [WHEN] Delete Sales Invoice Header.
        SalesHeaderInvoice.Delete(true);

        // [THEN] Sales Invoice is deleted successfully with all its lines.
        SalesHeaderInvoice.SetRange("Document Type", SalesHeaderInvoice."Document Type"::Invoice);
        SalesHeaderInvoice.SetRange("No.", SalesInvoiceNo);
        Assert.RecordIsEmpty(SalesHeaderInvoice);

        // [THEN] Item Tracking for Sales Invoice is deleted.
        FilterReservationEntryBySource(
          ReservationEntry, DATABASE::"Sales Header", SalesHeaderInvoice."Document Type"::Invoice.AsInteger(), SalesInvoiceNo, '');
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,GetReturnShipmentLinesPageHandler,DeleteLinesWithTrackingConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DeletePurchCrMemoWithTrackedLines()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeaderReturnOrder: Record "Purchase Header";
        PurchaseHeaderCreditMemo: Record "Purchase Header";
        PurchaseLineReturnOrder: Record "Purchase Line";
        PurchaseLineCreditMemo: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PurchCreditMemoNo: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Purch. Credit Memo]
        // [SCENARIO 379129] Purch. Credit Memo can be deleted with all its lines and tracking which were created from the posted Return Shipment with Lot Tracking.
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Item with Lot Tracking Code, posted positive Item Journal Line with Lot Item Tracking.
        CreateItem(Item, ItemTrackingCodeLotSpecific.Code, Item."Costing Method"::FIFO);
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(10, 20), false, AssignTracking::LotNo);

        // [GIVEN] Shipped Purch. Return Order with Lot Item Tracking.
        CreateAndPostPurchReturnOrderWithTracking(
          PurchaseHeaderReturnOrder, PurchaseLineReturnOrder, Vendor."No.", Item."No.", LocationBlue.Code, LibraryRandom.RandInt(10));

        // [GIVEN] Purch. Credit Memo with lines copied from Return Shipment by GetReturnShipmentLines function.
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderCreditMemo, PurchaseHeaderCreditMemo."Document Type"::"Credit Memo", Vendor."No.");
        PurchCreditMemoNo := PurchaseHeaderCreditMemo."No.";
        PurchaseLineCreditMemo."Document Type" := PurchaseHeaderCreditMemo."Document Type";
        PurchaseLineCreditMemo."Document No." := PurchaseHeaderCreditMemo."No.";
        GetReturnShipmentLines(PurchaseLineCreditMemo);

        // [WHEN] Delete Purch. Credit Memo Header.
        PurchaseHeaderCreditMemo.Delete(true);

        // [THEN] Purch. Credit Memo is deleted successfully with all its lines and tracking.
        PurchaseHeaderCreditMemo.SetRange("Document Type", PurchaseHeaderCreditMemo."Document Type"::"Credit Memo");
        PurchaseHeaderCreditMemo.SetRange("No.", PurchCreditMemoNo);
        Assert.RecordIsEmpty(PurchaseHeaderCreditMemo);

        // [THEN] Item Tracking for Purch. Credit Memo is deleted.
        FilterReservationEntryBySource(
          ReservationEntry, DATABASE::"Purchase Header", PurchaseHeaderCreditMemo."Document Type"::"Credit Memo".AsInteger(), PurchCreditMemoNo, '');
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingAssignSerialPageHandler,QuantityToCreateOKPageHandler,SalesListDocPageHandler,SynchronizeItemTrackingConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithDropShipmentSerialNo()
    var
        Item: Record Item;
        Purchasing: Record Purchasing;
        PurchaseHeader: Record "Purchase Header";
        ItemTrackingCode: Record "Item Tracking Code";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 380496] Service Items generated are equipped with Serial Numbers when two Sales Orders are applied to the same Drop Shipment Purchase Order.
        Initialize();

        CreatePurchasingCode(Purchasing);
        CreateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("SN Specific Tracking"), true);
        CustomerNo := CreateCustomer();

        // [GIVEN] Item with Tracking Code
        CreateItem(Item, ItemTrackingCode.Code, Item."Costing Method"::FIFO);

        // [GIVEN] Item registered as Service Item
        UpdateItemWithServiceItem(Item, CreateServiceItemGroup());

        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        UpdateSellToCustomerOnPurchaseHeader(PurchaseHeader, CustomerNo);

        // [GIVEN] 2 Sales Orders with Drop Shipment option
        // [GIVEN] Purchase Order is linked to 2 sales orders for the Item.
        CreateDropShippmentSalesOrderWithItemTracking(PurchaseHeader, Item."No.", Purchasing.Code);
        CreateDropShippmentSalesOrderWithItemTracking(PurchaseHeader, Item."No.", Purchasing.Code);

        // [WHEN] Post Purchase Order
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", true, false);

        // [THEN] Service Items generated have got Serial Numbers
        VerifyServiceItemSerialNoIsNotEmpty(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesAssistEditLotNoModalPageHandler,ItemTrackingSummaryVerifyLotModalPageHandler')]
    procedure EntrySummaryPositionedOnCurrentLot()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNos: array[3] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Entry Summary]
        // [SCENARIO 433723] When Stan clicks AssistEdit on Lot No. field in item tracking, the system will open Entry Summary page positioned on the current lot.
        Initialize();
        Qty := LibraryRandom.RandInt(100);

        LibraryItemTracking.CreateLotItem(Item);

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', ArrayLen(LotNos) * Qty);
        for i := 1 to ArrayLen(LotNos) do begin
            LotNos[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNos[i], Qty);
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());
        LibraryVariableStorage.Enqueue(LotNos[2]);
        LibraryVariableStorage.Enqueue(LotNos[2]);
        SalesLine.OpenItemTrackingLines();

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
    begin
        LibraryCRMIntegration.DisableConnection();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM RTAM Item Tracking");
        ClearGlobals();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM RTAM Item Tracking");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        NoSeriesSetup();
        CreateLocationSetup();
        ItemTrackingCodeSetup();
        ItemJournalSetup();
        OutputJournalSetup();
        ConsumptionJournalSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM RTAM Item Tracking");
    end;

    local procedure InitSetupForUpdateItemTrackingLines(var SalesLine: Record "Sales Line"; ItemTrackingCode: Code[10]; MultipleLines: Boolean; AssignTracking: Option)
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateItem(Item, ItemTrackingCode, Item."Costing Method"::FIFO);
        CreateAndPostItemJournalLine(ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LocationBlue.Code,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(10, 20), MultipleLines, AssignTracking); // Using large random value.
        CreateAndPostSalesOrderWithTracking(SalesHeader, SalesLine, Customer."No.", Item."No.", LocationBlue.Code,
          LibraryRandom.RandInt(10)); // Random value is small than the item inventory.
    end;

    local procedure ClearGlobals()
    begin
        Clear(GlobalItemNo);
        Clear(CreateNewLotNo);
        Clear(VerifyQtyToHandle);
        Clear(AssignTracking);
        SignFactor := 1;  // Assign Sign Factor as Positive 1.
        Clear(Partial);
        Clear(TrackingQuantity);
        Clear(Description);
        Clear(Comment);
        Clear(CancelReservationCurrentLine);
        Clear(MessageCounter);
        Clear(DocumentNo);
        Clear(ItemTrackingAction);
        Clear(UpdateSerialNo);
        Clear(UpdateLotNo);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        WarehouseSetup: Record "Warehouse Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Return Shpt. Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Credit Memo Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Credit Memo Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
    begin
        // Location -Blue.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue2);

        // Location -Green.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationGreen);
        LocationGreen.Validate("Require Put-away", true);
        LocationGreen.Validate("Require Receive", true);
        LocationGreen.Validate("Require Pick", true);
        LocationGreen.Validate("Require Shipment", true);
        LocationGreen.Validate("Prod. Output Whse. Handling", "Prod. Output Whse. Handling"::"Inventory Put-away");
        LocationGreen.Validate("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        LocationGreen.Modify(true);

        // Location -Intransit.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationIntransit);
        LocationIntransit.Validate("Use As In-Transit", true);
        LocationIntransit.Modify(true);

        // Location -Silver.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationSilver);
        LocationSilver.Validate("Bin Mandatory", true);
        LocationSilver.Modify(true);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LocationSilver.Code, '', '');

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);
    end;

    local procedure ItemTrackingCodeSetup()
    begin
        CreateItemTrackingCode(ItemTrackingCodeSerialSpecific, ItemTrackingCodeSerialSpecific.FieldNo("SN Specific Tracking"), true);  // Tracking for SN Specific Tracking.
        UpdateItemTrackingCode(ItemTrackingCodeSerialSpecific, ItemTrackingCodeSerialSpecific.FieldNo("SN Warehouse Tracking"), false);
        CreateItemTrackingCode(ItemTrackingCodeLotSpecific, ItemTrackingCodeLotSpecific.FieldNo("Lot Specific Tracking"), true);  // Tracking for Lot Specific Tracking.
        UpdateItemTrackingCode(ItemTrackingCodeLotSpecific, ItemTrackingCodeLotSpecific.FieldNo("Lot Warehouse Tracking"), false);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; FieldNo: Integer; Value: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        UpdateItemTrackingCode(ItemTrackingCode, FieldNo, Value);
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

    local procedure SetGlobalValue(ItemNo: Code[20]; NewLotNo: Boolean; VerifyQtyToHandle2: Boolean; Partial2: Boolean; AssignTracking2: Option; TrackingQuantity2: Decimal; GlobalComments: Boolean)
    begin
        GlobalItemNo := ItemNo;
        CreateNewLotNo := NewLotNo;
        VerifyQtyToHandle := VerifyQtyToHandle2;
        Partial := Partial2;
        AssignTracking := AssignTracking2;
        TrackingQuantity := TrackingQuantity2;

        if GlobalComments then
            SetGlobalDescriptionAndComments();
    end;

    local procedure SetGlobalDescriptionAndComments()
    var
        SerialNoInformation: Record "Serial No. Information";
        ItemTrackingComment: Record "Item Tracking Comment";
    begin
        Description :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(SerialNoInformation.FieldNo(Description), DATABASE::"Serial No. Information"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Serial No. Information", SerialNoInformation.FieldNo(Description)));
        Comment :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(ItemTrackingComment.FieldNo(Comment), DATABASE::"Item Tracking Comment"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Item Tracking Comment", ItemTrackingComment.FieldNo(Comment)));
    end;

    local procedure CreateItem(var Item: Record Item; ItemTrackingCode: Code[10]; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);  // Assign Tracking Code.
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    local procedure CreateDropShippmentSalesOrderWithItemTracking(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; PurchasingCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          ItemNo, '', 2, PurchaseHeader."Sell-to Customer No.", true);
        UpdateSalesLineWithPurchasingCode(SalesLine, PurchasingCode);

        LibraryVariableStorage.Enqueue(SalesHeader."No."); // for SalesListEnqPageHandler
        LibraryPurchase.GetDropShipment(PurchaseHeader);

        FindPurchaseLineFromSalesLine(PurchaseLine, PurchaseHeader."No.", SalesLine);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateServiceItemGroup(): Code[10]
    var
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroup.Validate("Create Service Item", true);
        ServiceItemGroup.Modify(true);
        exit(ServiceItemGroup.Code);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());  // For Posting of Purchase Order.
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());  // For Posting of Purchase Return Order.
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; NoOfLine: Integer)
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        CreatePurchaseLinesAndReleaseDocument(PurchaseHeader, ItemNo, LocationCode, Quantity, NoOfLine);
    end;

    local procedure CreateAndReleasePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; NoOfLine: Integer)
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");
        CreatePurchaseLinesAndReleaseDocument(PurchaseHeader, ItemNo, LocationCode, Quantity, NoOfLine);
    end;

    local procedure CreatePurchaseLinesAndReleaseDocument(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; NoOfLine: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        Counter: Integer;
    begin
        for Counter := 1 to NoOfLine do
            CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, LocationCode, Quantity);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemJournaLine(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Quantity2: Decimal; MultipleLines: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        DocumentNo: Code[20];
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        UpdateItemJournalLine(ItemJournalLine, LibraryUtility.GenerateGUID(), LocationCode);
        if MultipleLines then begin
            DocumentNo := ItemJournalLine."Document No.";
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity2);
            UpdateItemJournalLine(ItemJournalLine, DocumentNo, LocationCode);
        end;
    end;

    local procedure UpdateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; DocumentNo: Code[20]; LocationCode: Code[10])
    var
        Bin: Record Bin;
    begin
        ItemJournalLine.Validate("Document No.", DocumentNo);
        ItemJournalLine.Validate("Location Code", LocationCode);
        if LocationCode = LocationSilver.Code then begin
            LibraryWarehouse.FindBin(Bin, LocationCode, '', 1);
            ItemJournalLine.Validate("Bin Code", Bin.Code);
        end;
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Quantity2: Decimal; MultipleLines: Boolean; AssignTracking2: Option)
    begin
        AssignTracking := AssignTracking2;  // Assign Global variable for Page Handler.
        CreateItemJournaLine(EntryType, ItemNo, LocationCode, Quantity, Quantity2, MultipleLines);
        AssignTrackingOnItemJournalLines(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);  // Assign Item Tracking Line on Page Handler.

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AssignTracking := AssignTracking::None;  // Assign Global variable for Page Handler.
    end;

    local procedure AssignTrackingMultipleWhseReceiptLines(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FilterWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, SourceDocument);
        WarehouseReceiptLine.FindSet();
        repeat
            WarehouseReceiptLine.OpenItemTrackingLines();  // Open Tracking on Page Handler.
        until WarehouseReceiptLine.Next() = 0;
    end;

    local procedure FindWhseReceiptHeaderForPurchase(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptHeader(WarehouseReceiptHeader, SourceNo, WarehouseReceiptLine."Source Document"::"Purchase Order");
    end;

    local procedure FindWhseReceiptHeaderForSalesReturn(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptHeader(WarehouseReceiptHeader, SourceNo, WarehouseReceiptLine."Source Document"::"Sales Return Order");
    end;

    local procedure FindWarehouseReceiptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        SelectWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, SourceDocument);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
    end;

    local procedure FilterWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, SourceDocument);
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure FindPurchInvHeader(var PurchInvHeader: Record "Purch. Inv. Header"; OrderNo: Code[20])
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst();
    end;

    local procedure FindPurchaseLineFromSalesLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; SalesLine: Record "Sales Line")
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", SalesLine."No.");
        PurchaseLine.SetRange("Sales Order No.", SalesLine."Document No.");
        PurchaseLine.SetRange("Sales Order Line No.", SalesLine."Line No.");
        PurchaseLine.FindFirst();
    end;

    local procedure PostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; No: Code[20]; Receive: Boolean; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, No);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, Receive, Invoice);
    end;

    local procedure UpdateQtyToReceiveOnWhseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; ItemNo: Code[20]; QtyToReceive: Decimal)
    begin
        FilterWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindSet();
        repeat
            WarehouseReceiptLine.Validate("Qty. to Receive", QtyToReceive);
            WarehouseReceiptLine.Modify(true);
        until WarehouseReceiptLine.Next() = 0;
    end;

    local procedure UpdateSalesLineWithPurchasingCode(var SalesLine: Record "Sales Line"; PurchacingCode: Code[10])
    begin
        SalesLine.Validate("Purchasing Code", PurchacingCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateItemWithServiceItem(var Item: Record Item; ServiceItemGroup: Code[10])
    begin
        Item.Validate("Service Item Group", ServiceItemGroup);
        Item.Modify(true);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo, SourceDocument);
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure PostWhseReceiptAndRegisterWarehouseActivity(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        RegisterWarehouseActivity(SourceNo, SourceDocument);
    end;

    local procedure RegisterWarehouseActivityAndPostWhseShipment(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        RegisterWarehouseActivity(SourceNo, SourceDocument);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        // Create Sales Order.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, ItemNo, LocationCode, Quantity, CreateCustomer(), false);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        // Create Sales Order and Release Order.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, ItemNo, LocationCode, Quantity, CreateCustomer(), true);
    end;

    local procedure CreateAndReleaseSalesReturnOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        // Create Sales Return Order and Release.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", ItemNo, LocationCode, Quantity, CreateCustomer(), true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; CustomerNo: Code[20]; Release: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, LocationCode, Quantity);
        if Release then
            LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", CalcDate('<' + Format(LibraryRandom.RandInt(5) + 5) + 'D>', WorkDate()));
        SalesLine.Modify(true);
    end;

    local procedure FilterWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        SelectWarehouseShipmentLine(WarehouseShipmentLine, SourceNo, SourceDocument);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FindSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; OrderNo: Code[20])
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst();
    end;

    local procedure CreateWhseWorksheetName(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Pick);
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

    local procedure UpdateWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; QtyToHandle: Decimal)
    begin
        WhseWorksheetLine.Validate("Qty. to Handle", QtyToHandle);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure CreatePickFromPickWorksheet(LocationCode: Code[10]; QtyToHandle: Decimal)
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        CreateWhseWorksheetName(WhseWorksheetName, LocationCode);
        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode);
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationGreen.Code);
        UpdateWhseWorksheetLine(WhseWorksheetLine, QtyToHandle);
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          LocationCode, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
    end;

    local procedure UpdateQtyToShipOnSalesLine(var SalesLine: Record "Sales Line"; QtyToShip: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesLineAndReleaseOrder(var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; QtyToShip: Decimal)
    begin
        UpdateQtyToShipOnSalesLine(SalesLine, QtyToShip);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure UpdateSerialNoInformationAndComments(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        SerialNoInformationCard: TestPage "Serial No. Information Card";
        ItemTrackingComments: TestPage "Item Tracking Comments";
    begin
        // Update Description on Serial No information list and add Comments for Serial No.
        SerialNoInformationCard.Trap();
        ItemTrackingLines.Reclass_SerialNoInfoCard.Invoke();
        ItemTrackingComments.Trap();
        SerialNoInformationCard.Description.SetValue(Description);
        SerialNoInformationCard.Comment.Invoke();
        ItemTrackingComments.Date.SetValue(WorkDate());
        ItemTrackingComments.Comment.SetValue(Comment);
        ItemTrackingLines.OK().Invoke();
    end;

    local procedure PostSalesDocument(DocumentType: Enum "Sales Document Type"; No: Code[20]; Ship: Boolean; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, No);
        LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);
    end;

    local procedure SelectItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure UpdatePurchaseLineAndReleaseOrder(var PurchaseHeader: Record "Purchase Header"; DirectUnitCost: Decimal; QtyToInvoice: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure ReopenPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
    end;

    local procedure ReopenAndUpdatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        ReopenPurchaseOrder(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePurchaseLineAndPost(var PurchaseHeader: Record "Purchase Header"; DirectUnitCost: Decimal; Quantity: Decimal)
    begin
        UpdatePurchaseLineAndReleaseOrder(PurchaseHeader, DirectUnitCost, Quantity);
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");
        PostPurchaseDocument(PurchaseHeader."Document Type"::Order, PurchaseHeader."No.", false, true);  // Invoice
    end;

    local procedure FindPurchRcptHeader(var PurchRcptHeader: Record "Purch. Rcpt. Header"; OrderNo: Code[20])
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
    end;

    local procedure FindSalesShipmentHeader(var SalesShipmentHeader: Record "Sales Shipment Header"; OrderNo: Code[20])
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
    end;

    local procedure PostSalesOrderAndVerifyLine(var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; Reserve: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        // Post Sales Order/cancel reservation and post Sales Order.
        if Reserve then begin
            asserterror PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, false);
            Assert.IsTrue(StrPos(GetLastErrorText, ItemTrackingSerialNumberErr) > 0, GetLastErrorText);
        end else begin
            CancelReservationCurrentLine := true;  // Assign Global variable for Page Handler.
            SelectSalesLine(SalesLine, SalesHeader2."No.");
            SalesLine.ShowReservation();  // Cancel Reservation from Current Line.
            PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);
            VerifyPostedSalesInvoiceLine(SalesHeader."No.", ItemNo, Quantity);
        end;
    end;

    local procedure UpdateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; DirectUnitCost: Decimal; Quantity: Decimal)
    begin
        ReopenAndUpdatePurchaseOrder(PurchaseHeader);
        UpdatePurchaseLineAndPost(PurchaseHeader, DirectUnitCost, Quantity);
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

    local procedure SelectWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        FilterWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, SourceDocument);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure SelectWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        FilterWarehouseShipmentLine(WarehouseShipmentLine, SourceNo, SourceDocument);
        WarehouseShipmentLine.FindFirst();
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

    local procedure SelectSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; OrderNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        FindSalesInvoiceHeader(SalesInvoiceHeader, OrderNo);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();
    end;

    local procedure SelectSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; OrderNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        FindSalesShipmentHeader(SalesShipmentHeader, OrderNo);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.FindFirst();
    end;

    local procedure AssignTrackingOnPurchaseLine(DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseLine(PurchaseLine, DocumentNo);
        PurchaseLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler.
    end;

    local procedure AssignTrackingOnSalesLines(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SelectSalesLine(SalesLine, DocumentNo);
        repeat
            SalesLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler.
        until SalesLine.Next() = 0;
    end;

    local procedure AssignTrackingOnItemJournalLines(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalLine(ItemJournalLine, JournalTemplateName, JournalBatchName);
        repeat
            ItemJournalLine.OpenItemTrackingLines(false);  // Assign Tracking on Page Handler.
        until ItemJournalLine.Next() = 0;
    end;

    local procedure AssignTrackingOnWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        SelectWarehouseShipmentLine(WarehouseShipmentLine, SourceNo, SourceDocument);
        WarehouseShipmentLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler.
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        // Create Released Production Order and Refresh.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ItemNo, LocationCode, Quantity);
    end;

    local procedure CreateAndRefreshFirmPlannedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        // Create Firm Planned Production Order and Refresh.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ItemNo, LocationCode, Quantity);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndPostOutputJournal(ProductionOrderNo: Code[20]; Quantity: Decimal; Tracking: Boolean)
    begin
        CreateOutputJournalWithExlpodeRouting(ProductionOrderNo);
        UpdateQuantityAndPostOutputJournal(Quantity, Tracking);
    end;

    local procedure CreateOutputJournalWithExlpodeRouting(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure UpdateQuantityAndPostOutputJournal(OutputQuantity: Decimal; TrackingLine: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateOutputQuantityOnItemJournalLine(
          ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name, OutputQuantity);
        if TrackingLine then
            ItemJournalLine.OpenItemTrackingLines(false);  // Assign Item Tracking on Page Handler.
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndCertifyProdBOMWithMultipleComponent(var Item: Record Item; var Item2: Record Item; var Item3: Record Item; ItemTrackingCode: Code[10]; MultipleComponent: Boolean)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        CreateItem(Item2, ItemTrackingCode, Item."Costing Method"::FIFO);
        if MultipleComponent then begin
            CreateItem(Item3, ItemTrackingCodeSerialSpecific.Code, Item."Costing Method"::FIFO);
            LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, Item2."No.", Item3."No.", 1);  // Use One for Quantity per.
        end else begin
            LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
            LibraryManufacturing.CreateProductionBOMLine(
              ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item2."No.", 1);
            ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
            ProductionBOMHeader.Modify(true);
        end;
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure OpenItemTrackingLinesForProduction(ProdOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.OpenItemTrackingLines();  // Open Item Tracking Lines on Page Handler.
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure OpenItemTrackingLinesForProdOrderComponent(Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProdOrderComponent(ProdOrderComponent, Status, ProdOrderNo, ItemNo);
        ProdOrderComponent.OpenItemTrackingLines();  // Open Tracking Line on Page Handler.
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrderNo: Code[20]; TrackingLine: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        if TrackingLine then begin
            SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
            repeat
                ItemJournalLine.OpenItemTrackingLines(false);  // Assign Tracking Line on Page Handler.
            until ItemJournalLine.Next() = 0;
        end;
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure UpdateQtyToHandleOnWarehouseActivityLine(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, SourceDocument);
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", Quantity);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure UpdatePurchasingCodeOnSalesLine(var SalesLine: Record "Sales Line")
    var
        Purchasing: Record Purchasing;
    begin
        CreatePurchasingCode(Purchasing);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchasingCode(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
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

    local procedure CreatePickFromWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SourceNo, SourceDocument);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure UpdateSellToCustomerOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; SellToCustomerNo: Code[20])
    begin
        PurchaseHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure FindReturnShipmentHeader(var ReturnShipmentHeader: Record "Return Shipment Header"; ReturnOrderNo: Code[20])
    begin
        ReturnShipmentHeader.SetRange("Return Order No.", ReturnOrderNo);
        ReturnShipmentHeader.FindFirst();
    end;

    local procedure FindReturnReceiptHeader(var ReturnReceiptHeader: Record "Return Receipt Header"; ReturnOrderNo: Code[20])
    begin
        ReturnReceiptHeader.SetRange("Return Order No.", ReturnOrderNo);
        ReturnReceiptHeader.FindFirst();
    end;

    local procedure SelectReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; ReturnOrderNo: Code[20])
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        FindReturnShipmentHeader(ReturnShipmentHeader, ReturnOrderNo);
        ReturnShipmentLine.SetRange("Document No.", ReturnShipmentHeader."No.");
        ReturnShipmentLine.SetRange(Type, ReturnShipmentLine.Type::Item);
        ReturnShipmentLine.FindFirst();
    end;

    local procedure SelectReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; ReturnOrderNo: Code[20])
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        FindReturnReceiptHeader(ReturnReceiptHeader, ReturnOrderNo);
        ReturnReceiptLine.SetRange("Document No.", ReturnReceiptHeader."No.");
        ReturnReceiptLine.SetRange(Type, ReturnReceiptLine.Type::Item);
        ReturnReceiptLine.FindFirst();
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocation: Code[10]; ToLocation: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation, ToLocation, LocationIntransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Shipment Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        TransferLine.Modify(true);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure UpdatePostingPolicyOnWarehouseSetup(ReceiptPostingPolicy: Option; ShipmentPostingPolicy: Option)
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Receipt Posting Policy", ReceiptPostingPolicy);
        WarehouseSetup.Validate("Shipment Posting Policy", ShipmentPostingPolicy);
        WarehouseSetup.Modify(true);
    end;

    local procedure FindReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; SourceType: Integer; SourceID: Code[20])
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.FindFirst();
    end;

    local procedure FilterReservationEntryBySource(var ReservationEntry: Record "Reservation Entry"; SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Text[100])
    begin
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source Subtype", SourceSubtype);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetFilter("Source Ref. No.", SourceRefNo);
    end;

    local procedure UpdateWarrantyDateOnReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; SourceType: Integer; SourceID: Code[20])
    begin
        FindReservationEntry(ReservationEntry, ItemNo, SourceType, SourceID);
        repeat
            ReservationEntry.Validate("Warranty Date", WorkDate());
            ReservationEntry.Modify(true);
        until ReservationEntry.Next() = 0;
    end;

    local procedure UpdateOutputQuantityOnItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; OutPutQuantity: Decimal)
    begin
        SelectItemJournalLine(ItemJournalLine, JournalTemplateName, JournalBatchName);
        ItemJournalLine.Validate("Output Quantity", OutPutQuantity);
        ItemJournalLine.Modify(true);
    end;

    local procedure OpenReservedQuantityOnSalesOrder(SalesHeaderNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeaderNo);
        SalesOrder.SalesLines."Reserved Quantity".DrillDown();  // Open Page Reservation Entries.
    end;

    local procedure CreateSalesProductionSetup(var Item: Record Item; var Item2: Record Item; var SalesLine: Record "Sales Line"; var ProductionOrder: Record "Production Order"; Quantity: Decimal; LocationCode: Code[10]; ItemTrackingCode: Code[10]; AssignTrackingValue: Option)
    var
        Item3: Record Item;
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItem(Item, ItemTrackingCode, Item."Costing Method"::FIFO);
        CreateAndCertifyProdBOMWithMultipleComponent(Item, Item2, Item3, ItemTrackingCode, false);  // Multiple Component as False.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item2."No.", LocationCode, Quantity, 0, false, AssignTrackingValue);

        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LocationCode, LibraryRandom.RandIntInRange(Round(Quantity / 2, 1, '>') + 1, Quantity - 1));
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LocationCode, Quantity);
    end;

    local procedure DeleteReservationEntry(ItemNo: Code[20]; SourceType: Integer; SourceID: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FindReservationEntry(ReservationEntry, ItemNo, SourceType, SourceID);
        ReservationEntry.DeleteAll();
    end;

    local procedure UpdateDueDateOnReleasedProductionOrder(var ProductionOrder: Record "Production Order")
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProductionOrder."No.");
        ReleasedProductionOrder."Due Date".SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(5) + 10) + 'D>', WorkDate()));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateTransferOrderSetup(var Item: Record Item; var Item2: Record Item; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemTrackingCode: Code[10]; AssignTrackingValue: Option)
    var
        Item3: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItem(Item, ItemTrackingCode, Item."Costing Method"::FIFO);
        CreateAndCertifyProdBOMWithMultipleComponent(Item, Item2, Item3, ItemTrackingCode, false);

        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item2."No.", LocationBlue.Code, LibraryRandom.RandInt(10) + 10, 0, false,
          AssignTrackingValue);  // Value required.
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item2."No.", LocationBlue2.Code, LibraryRandom.RandInt(10) + 10, 0,
          false, AssignTrackingValue);  // Value required.

        CreateAndReleaseTransferOrder(
          TransferHeader, TransferLine, LocationBlue2.Code, LocationBlue.Code, Item2."No.", LibraryRandom.RandInt(10) + 5);  // Value required.
        SetGlobalValue(Item."No.", false, false, false, AssignTracking::None, 0, false);  // Assign Tracking as NONE.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);  // Assign Ship Tracking on Page Handler ItemTrackingProductionPageHandler.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
    end;

    local procedure CreateAndPostSalesOrderWithTracking(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        // Create Sales Order and Post with Ship Option.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, ItemNo, LocationCode, Quantity, CustomerNo, true);
        SalesLine.OpenItemTrackingLines();  // Assign Item Tracking on Page Handler.
        LibrarySales.PostSalesDocument(SalesHeader, true, false)
    end;

    local procedure CreateAndPostSalesReturnOrderWithTracking(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        // Create Sales Return Order and Post with Receive Option.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", ItemNo, LocationCode, Quantity, CustomerNo, true);
        SalesLine.OpenItemTrackingLines();  // Assign Item Tracking on Page Handler.
        LibrarySales.PostSalesDocument(SalesHeader, true, false)
    end;

    local procedure CreateAndPostPurchReturnOrderWithTracking(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, LocationCode, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        PurchaseLine.OpenItemTrackingLines();  // Assign Item Tracking on Page Handler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false)
    end;

    local procedure CreateCustomerWithCombineShipments(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Combine Shipments", true);
        Customer.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateAndReleasePurchaseOrderWithTracking(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; NoOfLine: Integer)
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, ItemNo, LocationCode, Quantity, NoOfLine);
        AssignTrackingOnPurchaseLine(PurchaseHeader."No.");  // Assign Tracking on Page Handler.
    end;

    local procedure CreateLotTrackedPositiveAdjmtAndSalesWithShipmentAndPick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var SourceDocType: Enum "Warehouse Activity Source Document"; var SourceDocNo: Code[20]; var ItemNo: Code[20])
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("Lot Specific Tracking"), true);
        UpdateItemTrackingCode(ItemTrackingCode, ItemTrackingCode.FieldNo("Lot Warehouse Tracking"), true);
        CreateItem(Item, ItemTrackingCode.Code, Item."Costing Method"::FIFO);
        ItemNo := Item."No.";
        SetGlobalValue(ItemNo, false, false, false, AssignTracking::None, 0, true);

        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LocationGreen.Code,
          LibraryRandom.RandIntInRange(10, 20), 0, false, AssignTracking::LotNo);

        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, ItemNo, LocationGreen.Code, LibraryRandom.RandInt(10));
        SalesLine.OpenItemTrackingLines();
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");
        CreatePickFromWarehouseShipment(
          WarehouseShipmentHeader, SalesHeader."No.", WarehouseActivityLine."Source Document"::"Sales Order");

        SourceDocType := WarehouseActivityLine."Source Document"::"Sales Order";
        SourceDocNo := SalesHeader."No.";
    end;

    local procedure MockSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; ShipmentNo: Code[20])
    begin
        SalesLine.Init();
        SalesLine."Document Type" := DocumentType;
        SalesLine."Document No." := LibraryUtility.GenerateGUID();
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine."Shipment No." := ShipmentNo;
        SalesLine.Insert();
    end;

    local procedure MockPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; ShipmentNo: Code[20])
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := DocumentType;
        PurchaseLine."Document No." := LibraryUtility.GenerateGUID();
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := ItemNo;
        PurchaseLine."Return Shipment No." := ShipmentNo;
        PurchaseLine.Insert();
    end;

    local procedure MockItemEntryRelation(var ItemEntryRelation: Record "Item Entry Relation"; SourceType: Integer; SourceID: Code[20])
    var
        RecRef: RecordRef;
    begin
        ItemEntryRelation.Init();
        RecRef.GetTable(ItemEntryRelation);
        ItemEntryRelation."Item Entry No." := LibraryUtility.GetNewLineNo(RecRef, ItemEntryRelation.FieldNo("Item Entry No."));
        ItemEntryRelation."Source Type" := SourceType;
        ItemEntryRelation."Source ID" := SourceID;
        ItemEntryRelation."Lot No." := LibraryUtility.GenerateGUID();
        ItemEntryRelation."Serial No." := LibraryUtility.GenerateGUID();
        ItemEntryRelation.Insert();
    end;

    local procedure MockTrackingSpecificationFromItemEntryRelation(ItemEntryRelation: Record "Item Entry Relation"; ItemNo: Code[20])
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.Init();
        TrackingSpecification."Entry No." := ItemEntryRelation."Item Entry No.";
        TrackingSpecification."Item No." := ItemNo;
        TrackingSpecification."Lot No." := ItemEntryRelation."Lot No.";
        TrackingSpecification."Serial No." := ItemEntryRelation."Serial No.";
        TrackingSpecification."Quantity (Base)" := LibraryRandom.RandIntInRange(11, 20);
        TrackingSpecification."Quantity Invoiced (Base)" := LibraryRandom.RandInt(10);
        // document is not fully invoiced
        TrackingSpecification.Insert();
    end;

    local procedure GetReturnShipmentLines(var PurchaseLine: Record "Purchase Line")
    var
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        Clear(PurchGetReturnShipments);
        PurchGetReturnShipments.Run(PurchaseLine);
    end;

    local procedure SetValueSerialAndLotNoOnItemTrackingLines(var ItemTrackingLines: TestPage "Item Tracking Lines"; SerialNo: Code[50]; LotNo: Code[50])
    begin
        ItemTrackingLines."Serial No.".SetValue(SerialNo);
        ItemTrackingLines."Lot No.".SetValue(LotNo);
    end;

    local procedure SelectEntriesOnItemTrackingLines(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Select Entries".Invoke();  // Open Item Tracking Summary for Select Line.
        ItemTrackingLines.OK().Invoke();
    end;

    local procedure VerifyTrackingOnPostedPurchaseInvoice(OrderNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Verify Tracking line.
        SelectPurchInvLine(PurchInvLine, OrderNo);
        PurchInvLine.ShowItemTrackingLines();  // Open item tracking line for Verify.
    end;

    local procedure VerifyTrackingOnWarehouseReceipt(PurchaseHeaderNo: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // Verify Tracking line.
        SelectWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeaderNo, WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.OpenItemTrackingLines();  // Open item tracking line for Verify.
    end;

    local procedure VerifyTrackingOnPostedSalesInvoice(OrderNo: Code[20]; LastLine: Boolean)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // Verify Tracking line.
        SelectSalesInvoiceLine(SalesInvoiceLine, OrderNo);
        if LastLine then  // Find Last record in Posted Sales Invoice lines and verify accordingly.
            SalesInvoiceLine.FindLast();
        SalesInvoiceLine.ShowItemTrackingLines();  // Open item tracking line for Verify.
    end;

    local procedure VerifyTrackingOnPostedSalesShipment(OrderNo: Code[20]; Quantity: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SelectSalesShipmentLine(SalesShipmentLine, OrderNo);
        SalesShipmentLine.TestField(Quantity, Quantity);
        SalesShipmentLine.ShowItemTrackingLines();  // Open item tracking line for Verify.
    end;

    local procedure VerifyPostedSalesInvoiceLine(OrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SelectSalesInvoiceLine(SalesInvoiceLine, OrderNo);
        SalesInvoiceLine.TestField("No.", ItemNo);
        SalesInvoiceLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; CostAmountActual: Decimal)
    begin
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmountActual);
        ItemLedgerEntry.TestField("Serial No.");  // Serial No. exist.
    end;

    local procedure VerifyTrackingOnProdOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        SignFactor := -1;  // Assign Sign Factor for Page Handler.
        OpenItemTrackingLinesForProdOrderComponent(ProductionOrder.Status::Finished, ProductionOrderNo, ItemNo);  // Open Item Tracking Lines and Verify on Page Handler PostedLinesPageHandler.
    end;

    local procedure VerifySerialAndLotNoOnItemLedgerEntry(ItemNo: Code[20]; DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; DocumentType2: Enum "Item Ledger Document Type"; DocumentNo2: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
    begin
        SelectItemLedgerEntry(ItemLedgerEntry, DocumentType, DocumentNo, ItemNo);
        repeat
            SelectItemLedgerEntry(ItemLedgerEntry2, DocumentType2, DocumentNo2, ItemNo);
            ItemLedgerEntry2.SetRange("Serial No.", ItemLedgerEntry."Serial No.");
            ItemLedgerEntry2.FindFirst();
            ItemLedgerEntry2.TestField("Lot No.", ItemLedgerEntry."Lot No.");
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyTrackingOnPostedReturnShipment(ReturnOrderNo: Code[20])
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Verify Tracking line.
        SelectReturnShipmentLine(ReturnShipmentLine, ReturnOrderNo);
        ReturnShipmentLine.ShowItemTrackingLines();  // Open Item Tracking page for verify.
    end;

    local procedure VerifyTrackingOnPostedReturnReceipt(ReturnOrderNo: Code[20])
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        // Verify Tracking line.
        SelectReturnReceiptLine(ReturnReceiptLine, ReturnOrderNo);
        ReturnReceiptLine.ShowItemTrackingLines();  // Open Item Tracking page for verify.
    end;

    local procedure VerifySerialNoOnItemLedgerEntry(ItemNo: Code[20]; Quantity: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LineCount: Integer;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField("Serial No.");
            LineCount += 1;
        until ItemLedgerEntry.Next() = 0;
        Assert.AreEqual(Quantity, LineCount, NumberOfLineEqualErr);  // Verify Number of Item Ledger Entry line.
    end;

    local procedure VerifyTrackingOnPostedPurchaseReceipt(OrderNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FindPurchRcptHeader(PurchRcptHeader, OrderNo);
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.FindFirst();
        PurchRcptLine.ShowItemTrackingLines();  // Open Item Tracking Lines and Verify on Page Handler PostedLinesPageHandler.
    end;

    local procedure VerifyItemLedgerEntries(var ItemLedgerEntries: TestPage "Item Ledger Entries"; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal)
    begin
        ItemLedgerEntries."Entry Type".AssertEquals(EntryType);
        ItemLedgerEntries."Item No.".AssertEquals(GlobalItemNo);
        ItemLedgerEntries.Quantity.AssertEquals(Quantity);
    end;

    local procedure VerifyReservedQuantity(SalesLine: Record "Sales Line")
    begin
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine.Quantity);
        VerifyReservedItemLedgerEntry(SalesLine."Document No.", SalesLine."Reserved Quantity");
    end;

    local procedure VerifyReservedQuantityProdOrderComponent(ProdOrderComponent: Record "Prod. Order Component"; ReservedQuantity: Decimal; AssignTrackingValue: Option)
    begin
        ProdOrderComponent.CalcFields("Reserved Quantity");
        if AssignTrackingValue = AssignTracking::LotNo then
            ProdOrderComponent.TestField("Reserved Quantity", ReservedQuantity)
        else
            ProdOrderComponent.TestField("Reserved Quantity", 1);  // One for Serial No.
    end;

    local procedure VerifyTrackingOnConsumptionItemJournal()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        DocumentNo := ItemJournalLine."Document No.";  // Assign Global Variable.
        ItemJournalLine.OpenItemTrackingLines(false);  // Verify Tracking on Page Handler ItemTrackingProductionPageHandler.
    end;

    local procedure VerifyTrackingOnSalesInvoiceLine(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.SetRange("No.", ItemNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.ShowItemTrackingLines();  // Verify Tracking on Page Handler PostedLinesPageHandler.
    end;

    local procedure VerifyTrackingOnSalesCrMemoLine(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
        SalesCrMemoLine.SetRange("No.", ItemNo);
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.ShowItemTrackingLines();  // Verify Tracking on Page Handler PostedLinesPageHandler.
    end;

    local procedure VerifyReservedItemLedgerEntry(DocumentNo: Code[20]; ReservedQuantity: Decimal)
    var
        ReservationEntries: TestPage "Reservation Entries";
        "Count": Integer;
    begin
        ReservationEntries.Trap();
        OpenReservedQuantityOnSalesOrder(DocumentNo);
        for Count := 1 to ReservedQuantity do
            ReservationEntries.ReservedFrom.Drilldown();  // Verify Reservation on Item Ledger Entry on Page Handler ItemLedgerEntriesPositiveAdjmtPageHandler.
    end;

    local procedure VerifyErrorMsgByUpdateItemTrackingLines(SalesLine: Record "Sales Line")
    var
        TrackingSpec: Record "Tracking Specification";
    begin
        asserterror SalesLine.OpenItemTrackingLines();
        Assert.ExpectedTestFieldError(TrackingSpec.FieldCaption("Quantity Handled (Base)"), Format(0));
    end;

    local procedure VerifyServiceItemSerialNoIsNotEmpty(ItemNo: Code[20])
    var
        ServiceItem: Record "Service Item";
    begin
        ServiceItem.SetRange("Item No.", ItemNo);
        ServiceItem.FindSet();
        repeat
            ServiceItem.TestField("Serial No.");
        until ServiceItem.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailabilityItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        Commit();
        case ItemTrackingAction of
            ItemTrackingAction::AvailabilityLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    ItemTrackingLines.AvailabilityLotNo.AssertEquals(true);
                end;
            ItemTrackingAction::AvailabilitySerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    ItemTrackingLines.AvailabilitySerialNo.AssertEquals(true);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPurchasePageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        SerialNoInformation: Record "Serial No. Information";
    begin
        // Assign Serial and Lot no based on requirments.
        if not VerifyQtyToHandle then begin
            ItemTrackingLines."Assign Serial No.".Invoke();  // Open Enter Quantity to Create for create Serial No or with Lot No.
            ItemTrackingLines.Last();
            if Partial then
                ItemTrackingLines."Qty. to Handle (Base)".SetValue(0);  // Value to partially track the items.
            LibraryItemTracking.CreateSerialNoInformation(SerialNoInformation, GlobalItemNo, '', ItemTrackingLines."Serial No.".Value);
            UpdateSerialNoInformationAndComments(ItemTrackingLines);
            exit;
        end;

        // Verify: Qty to Handle- Tracking on unit quantity.
        ItemTrackingLines.Last();
        ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(1);  // For Serial No tracking - as per standard, Quantity (Base) must be -1,0,1 when Serial No. is stated.
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSalesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        SerialNoInformation: Record "Serial No. Information";
    begin
        // Assign Serial and Lot no based on requirments.
        if AssignTracking = AssignTracking::SerialNo then begin
            ItemTrackingLines."Assign Serial No.".Invoke();  // Open Enter Quantity to Create for Create Serial No or with Lot No.
            ItemTrackingLines.Last();
            LibraryItemTracking.CreateSerialNoInformation(SerialNoInformation, GlobalItemNo, '', ItemTrackingLines."Serial No.".Value);
            UpdateSerialNoInformationAndComments(ItemTrackingLines);
            exit;
        end;
        ItemTrackingLines."Select Entries".Invoke();  // Open Item Tracking Summary for Select Line.

        if Partial then begin
            ItemTrackingLines.First();
            while TrackingQuantity > 0 do begin
                TrackingQuantity -= 1;
                ItemTrackingLines."Qty. to Handle (Base)".SetValue(0);  // Value to partially track the Items.
                ItemTrackingLines."Qty. to Invoice (Base)".SetValue(0);
                ItemTrackingLines.Next();
            end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Assign Serial and Lot no based on requirments.
        case AssignTracking of
            AssignTracking::SerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();  // Open Enter Quantity to Create Page for Create Serial No or with Lot No.
                    exit;
                end;
            AssignTracking::LotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
                    exit;
                end;
        end;

        if Partial and (TrackingQuantity <> 0) then begin
            ItemTrackingLines.Last();
            while TrackingQuantity > 0 do begin
                TrackingQuantity -= 1;
                ItemTrackingLines."Qty. to Invoice (Base)".SetValue(0);  // Value to partially track the Items for Invoice.
                ItemTrackingLines.Previous();
            end;
            exit;
        end;

        if Partial and VerifyQtyToHandle then begin  // Using For Return Order.
            SelectItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Sales Shipment", DocumentNo, GlobalItemNo);
            SetValueSerialAndLotNoOnItemTrackingLines(ItemTrackingLines, ItemLedgerEntry."Serial No.", ItemLedgerEntry."Lot No.");
            ItemTrackingLines."Quantity (Base)".SetValue(1);
            exit;
        end;

        if VerifyQtyToHandle then begin  // Using For Transfer Receipt.
            ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(TrackingQuantity);
            exit;
        end;

        if UpdateLotNo then begin // Using for Sales Order
            ItemTrackingLines."Lot No.".AssistEdit(); // Open Item Tracking Summary for update line.
            exit;
        end;

        SelectEntriesOnItemTrackingLines(ItemTrackingLines);  // Open Item Tracking Summary for Select Line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSerialNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ReservationEntry: Record "Reservation Entry";
        SerialNo: Code[50];
        LotNo: Code[50];
    begin
        // Assign Serial no based on requirments.
        if AssignTracking = AssignTracking::SerialNo then begin
            ItemTrackingLines."Assign Serial No.".Invoke();  // Open Enter Quantity to Create Page for Create Serial No or with Lot No.
            exit;
        end;

        if Partial then begin
            FindReservationEntry(ReservationEntry, GlobalItemNo, DATABASE::"Purchase Line", DocumentNo);
            ItemTrackingLines.Last();
            SetValueSerialAndLotNoOnItemTrackingLines(ItemTrackingLines, ReservationEntry."Serial No.", ReservationEntry."Lot No.");
            exit;
        end;

        if ItemTrackingAction = ItemTrackingAction::AvailabilitySerialNo then begin
            ItemTrackingLines.First();
            SerialNo := ItemTrackingLines."Serial No.".Value();
            LotNo := ItemTrackingLines."Lot No.".Value();
            ItemTrackingLines.Last();
            SetValueSerialAndLotNoOnItemTrackingLines(ItemTrackingLines, SerialNo, LotNo);
            exit;
        end;

        if UpdateSerialNo then begin
            ItemTrackingLines."Serial No.".AssistEdit(); // Open Item Tracking Summary for update line.
            exit;
        end;

        SelectEntriesOnItemTrackingLines(ItemTrackingLines);  // Open Item Tracking Summary for Select Line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingProductionPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Assign Serial and Lot no based on requirments.
        case AssignTracking of
            AssignTracking::SerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();  // Open Enter Quantity to Create Page for Create Serial No or with Lot No.
                    exit;
                end;
            AssignTracking::LotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
                    exit;
                end;
        end;

        if Partial then begin  // For Lot No.
            case ItemTrackingAction of
                ItemTrackingAction::AvailabilityLotNo:
                    begin
                        FindReservationEntry(ReservationEntry, GlobalItemNo, DATABASE::"Transfer Line", DocumentNo);
                        ItemTrackingLines."Lot No.".SetValue(ReservationEntry."Lot No.");
                        ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity);
                    end;
                ItemTrackingAction::AvailabilitySerialNo:
                    begin
                        FindReservationEntry(ReservationEntry, GlobalItemNo, DATABASE::"Transfer Line", DocumentNo);
                        repeat
                            ItemTrackingLines."Serial No.".SetValue(ReservationEntry."Serial No.");
                            ItemTrackingLines."Quantity (Base)".SetValue(1);  // 1 For Serial No.
                            ItemTrackingLines.Next();
                        until ReservationEntry.Next() = 0;
                    end;
                ItemTrackingAction::None:
                    begin
                        FindReservationEntry(ReservationEntry, GlobalItemNo, DATABASE::"Prod. Order Line", DocumentNo);
                        ItemTrackingLines."Lot No.".SetValue(ReservationEntry."Lot No.");
                        ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity);
                    end;
            end;
            exit;
        end;
        if VerifyQtyToHandle then begin
            case ItemTrackingAction of
                ItemTrackingAction::AvailabilityLotNo:
                    begin
                        FindReservationEntry(ReservationEntry, GlobalItemNo, DATABASE::"Prod. Order Component", DocumentNo);
                        ItemTrackingLines."Lot No.".AssertEquals(ReservationEntry."Lot No.");
                        ItemTrackingLines."Quantity (Base)".AssertEquals(TrackingQuantity);
                    end;
                ItemTrackingAction::AvailabilitySerialNo:
                    begin
                        ItemTrackingLines.First();
                        FindReservationEntry(ReservationEntry, GlobalItemNo, DATABASE::"Prod. Order Component", DocumentNo);
                        repeat
                            ItemTrackingLines."Serial No.".AssertEquals(ReservationEntry."Serial No.");
                            ItemTrackingLines."Quantity (Base)".AssertEquals(1);
                            ItemTrackingLines.Next();
                        until ReservationEntry.Next() = 0;
                    end;
            end;
            exit;
        end;

        SelectEntriesOnItemTrackingLines(ItemTrackingLines);  // Open Item Tracking Summary for Select Line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingProductionSerialNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Assign Serial and Lot no based on requirments.
        case AssignTracking of
            AssignTracking::SerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();  // Open Enter Quantity to Create Page for Create Serial No or with Lot No.
                    exit;
                end;
            AssignTracking::LotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
                    exit;
                end;
        end;

        if Partial and VerifyQtyToHandle then begin
            ItemTrackingLines.First();
            while TrackingQuantity > 0 do begin
                TrackingQuantity -= 1;
                ItemTrackingLines."Quantity (Base)".SetValue(0);  // Set Quantity (Base) as Zero.
                ItemTrackingLines.Next();
            end;
            exit;
        end;

        if Partial then begin
            FindReservationEntry(ReservationEntry, GlobalItemNo, DATABASE::"Prod. Order Line", DocumentNo);
            while TrackingQuantity > 0 do begin
                TrackingQuantity -= 1;
                ItemTrackingLines.New();
                ItemTrackingLines."Serial No.".SetValue(ReservationEntry."Serial No.");
                ItemTrackingLines."Quantity (Base)".SetValue(1);
                ReservationEntry.Next();
            end;
            exit;
        end;

        SelectEntriesOnItemTrackingLines(ItemTrackingLines);  // Open Item Tracking Summary for Select Line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LotItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        LotNoInformation: Record "Lot No. Information";
        LotNoInformationCard: TestPage "Lot No. Information Card";
        ItemTrackingComments: TestPage "Item Tracking Comments";
    begin
        // Assign Lot no based on requirments.
        if AssignTracking = AssignTracking::LotNo then begin
            ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
            ItemTrackingLines.Last();
            LibraryItemTracking.CreateLotNoInformation(LotNoInformation, GlobalItemNo, '', ItemTrackingLines."Lot No.".Value);
            LotNoInformationCard.Trap();
            ItemTrackingLines.Reclass_LotNoInfoCard.Invoke();

            ItemTrackingComments.Trap();
            LotNoInformationCard.Description.SetValue(Description);
            LotNoInformationCard.Comment.Invoke();
            ItemTrackingComments.Date.SetValue(WorkDate());
            ItemTrackingComments.Comment.SetValue(Comment);
            ItemTrackingLines.OK().Invoke();
            exit;
        end;

        ItemTrackingLines."Select Entries".Invoke();  // Open Item Tracking Summary for Select Line.

        // Select Lot no based on requirments.
        if Partial then begin
            ItemTrackingLines.First();
            ItemTrackingLines."Qty. to Handle (Base)".SetValue(TrackingQuantity);
            ItemTrackingLines."Qty. to Invoice (Base)".SetValue(TrackingQuantity);
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageQtyToHandleHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        LineCount: Integer;
    begin
        // Assign Serial and Lot no based on requirments.
        case AssignTracking of
            AssignTracking::SerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();  // Open Enter Quantity to Create Page for Create Serial No or with Lot No.
                    exit;
                end;
            AssignTracking::LotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
                    exit;
                end;
        end;

        if VerifyQtyToHandle then begin  // Using For Transfer Receipt.
            ItemTrackingLines.Last();
            repeat
                ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(1);  // For Serial No.
                LineCount += 1;
            until not ItemTrackingLines.Previous();
            Assert.AreEqual(TrackingQuantity, LineCount, NumberOfLineEqualErr);  // Verify Number of line Tracking Line.
            exit;
        end;

        SelectEntriesOnItemTrackingLines(ItemTrackingLines);  // Open Item Tracking Summary for Select Line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPartialPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    var
        TrackingQuantity2: Decimal;
    begin
        // For Partial Tracking Set all Selected Quantity as 0.
        if TrackingQuantity <> 0 then begin
            ItemTrackingSummary.First();
            TrackingQuantity2 := TrackingQuantity;
            while TrackingQuantity2 > 0 do begin
                TrackingQuantity2 -= 1;
                ItemTrackingSummary."Selected Quantity".SetValue(0);  // Set Value to partially track the Items.
                ItemTrackingSummary.Next();
            end;

            // For Partial Tracking Set Selected Quantity as 1.
            ItemTrackingSummary.Last();
            while TrackingQuantity > 0 do begin
                TrackingQuantity -= 1;
                ItemTrackingSummary."Selected Quantity".SetValue(1);  // Set Value to partially track the Items.
                ItemTrackingSummary.Previous();
            end;
        end;

        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
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
    procedure SerialPostedLinesPageHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
        PostedItemTrackingLines.Last();
        PostedItemTrackingLines."Serial No.".Lookup();  // Open Serial No Information List for verify.
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
                        PostedItemTrackingLines.Quantity.AssertEquals(SignFactor);  // Using SignFactor for Negative Value- Consumption.
                        LineCount += 1;
                    until not PostedItemTrackingLines.Next();
                    Assert.AreEqual(TrackingQuantity, LineCount, NumberOfLineEqualErr);  // Verify Number of line Tracking Line.
                end;
            AssignTracking::LotNo:
                PostedItemTrackingLines.Quantity.AssertEquals(TrackingQuantity * SignFactor);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedLinesWarrantyDatePageHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    var
        LineCount: Integer;
    begin
        // Verify Quantity and Number of Line on Tracking Page.
        PostedItemTrackingLines.First();
        repeat
            PostedItemTrackingLines.Quantity.AssertEquals(1);
            PostedItemTrackingLines."Warranty Date".AssertEquals(
              CalcDate(ItemTrackingCodeSerialSpecific."Warranty Date Formula", WorkDate()));
            LineCount += 1;
        until not PostedItemTrackingLines.Next();
        Assert.AreEqual(TrackingQuantity, LineCount, NumberOfLineEqualErr);  // Verify Number of line Tracking Line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LotPostedLinesPageHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
        PostedItemTrackingLines.Last();
        PostedItemTrackingLines."Lot No.".Lookup();  // Open Lot No Information List for verify.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SerialNoListPageHandler(var SerialNoInformationList: TestPage "Serial No. Information List")
    var
        ItemTrackingComments: TestPage "Item Tracking Comments";
    begin
        // Verify Item Tracking for Serial.
        ItemTrackingComments.Trap();
        SerialNoInformationList.Description.AssertEquals(Description);
        SerialNoInformationList.Comment.Invoke();
        ItemTrackingComments.Date.AssertEquals(WorkDate());
        ItemTrackingComments.Comment.AssertEquals(Comment);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LotNoListPageHandler(var LotNoInformationList: TestPage "Lot No. Information List")
    var
        ItemTrackingComments: TestPage "Item Tracking Comments";
    begin
        // Verify Item Tracking for Lot.
        ItemTrackingComments.Trap();
        LotNoInformationList.Description.AssertEquals(Description);
        LotNoInformationList.Comment.Invoke();
        ItemTrackingComments.Date.AssertEquals(WorkDate());
        ItemTrackingComments.Comment.AssertEquals(Comment);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionPageHandler(var PickSelection: Page "Pick Selection"; var Response: Action)
    var
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        // Create Pick.
        WhsePickRequest.SetRange("Location Code", LocationGreen.Code);
        WhsePickRequest.SetRange("Document No.", DocumentNo);
        WhsePickRequest.FindFirst();
        PickSelection.SetRecord(WhsePickRequest);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        if not CancelReservationCurrentLine then begin
            Reservation."Reserve from Current Line".Invoke();  // Reserve.
            Reservation.OK().Invoke();
            exit;
        end;
        Reservation.CancelReservationCurrentLine.Invoke();  // Cancel Reservation.
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationAvailablePageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.First();
        Reservation."Summary Type".AssertEquals(ItemLedgerEntrySummaryTypeTxt);
        Reservation.Next();
        Reservation."Summary Type".AssertEquals(TransferLineSummaryTypeTxt);
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.FILTER.SetFilter("No.", DocumentNo);
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesPageHandler(var ItemLedgerEntries: TestPage "Item Ledger Entries")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        VerifyItemLedgerEntries(ItemLedgerEntries, ItemLedgerEntry."Entry Type"::Output, TrackingQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesPositiveAdjmtPageHandler(var ItemLedgerEntries: TestPage "Item Ledger Entries")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        VerifyItemLedgerEntries(ItemLedgerEntries, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", 1);  // One for Serial No.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnShipmentLinesPageHandler(var GetReturnShipmentLinesPage: TestPage "Get Return Shipment Lines")
    begin
        GetReturnShipmentLinesPage.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CombinedShipmentsMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, CombinedShipmentsMsg) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CombinedReturnReceiptMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, CombinedReturnReceiptMsg) > 0, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, ReservationsCancelQst) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NegativeAdjustmentConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConsumptionMissingConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, ConsumptionMissingQst) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SynchronizeItemTrackingConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, SynchronizeItemTrackingQst) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AvailabilityWarningsConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        MessageCounter += 1;
        case MessageCounter of
            1:
                Assert.IsTrue(StrPos(ConfirmMessage, AvailabilityWarningsMsg) > 0, ConfirmMessage);
            2:
                Assert.IsTrue(StrPos(ConfirmMessage, LibraryInventory.GetReservConfirmText()) > 0, ConfirmMessage);
            3:
                Assert.IsTrue(StrPos(ConfirmMessage, SomeOutputMissingMsg) > 0, ConfirmMessage);
        end;
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AvailabilityWarningsWithQtyZeroConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        MessageCounter += 1;
        case MessageCounter of
            1:
                Assert.IsTrue(StrPos(ConfirmMessage, AvailabilityWarningsMsg) > 0, ConfirmMessage);
            2:
                Assert.IsTrue(StrPos(ConfirmMessage, LibraryInventory.GetReservConfirmText()) > 0, ConfirmMessage);
            3:
                Assert.IsTrue(StrPos(ConfirmMessage, 'One or more lines have tracking specified, but Quantity (Base) is zero') > 0, ConfirmMessage);
            4:
                Assert.IsTrue(StrPos(ConfirmMessage, SomeOutputMissingMsg) > 0, ConfirmMessage);
        end;
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AvailabilityWarningsAndReserveConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        MessageCounter += 1;
        case MessageCounter of
            1, 3:
                Assert.IsTrue(StrPos(ConfirmMessage, AvailabilityWarningsMsg) > 0, ConfirmMessage);
            2:
                Assert.IsTrue(StrPos(ConfirmMessage, LibraryInventory.GetReservConfirmText()) > 0, ConfirmMessage);
        end;
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AvailabilityConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, AvailabilityWarningsMsg) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DeleteLinesWithTrackingConfirmHandlerTrue(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;  // Outbound.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingAssignSerialPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreateOKPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListDocPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesAssistEditLotNoModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Lot No.".AssistEdit();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingSummaryVerifyLotModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary."Lot No.".AssertEquals(LibraryVariableStorage.DequeueText());
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingSummaryFindLastModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.Last();
        ItemTrackingSummary.OK().Invoke();
    end;
}

