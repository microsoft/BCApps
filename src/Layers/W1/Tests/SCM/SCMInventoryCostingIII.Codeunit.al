codeunit 137288 "SCM Inventory Costing III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Undo] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        AvailabilityWarning: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        DeletionError: Label 'Order must be deleted.';
        ItemFilter: Label '%1|%2', Locked = true;
        InvoicedChargeItemError: Label 'You cannot undo line %1 because an item charge has already been invoiced.';
        UndoReceiptError: Label 'This receipt has already been invoiced. Undo %1 can be applied only to posted, but not invoiced receipts.';
        UndoReceiptMessage: Label 'Do you really want to undo the selected Receipt lines?';
        UndoReturnShipmentMessage: Label 'Do you really want to undo the selected Return Shipment lines?';
        UndoReturnReceiptMessage: Label 'Do you really want to undo the selected Return Receipt lines?';
        UndoShipmentInvoicedErr: Label 'This shipment has already been invoiced. Undo %1 can be applied only to posted, but not invoiced shipments.';
        UndoShipmentMessage: Label 'Do you really want to undo the selected Shipment lines?';
        ShipmentAlreadyReversedErr: Label 'There are no lines with quantity to reverse.';
        ReturnShipmentAlreadyReversedErr: Label 'This return shipment has already been reversed.';

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptTrackedBySerialNumber()
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        DummyValue: Variant;
    begin
        // Verify Receipt Lines, Item Tracking Lines and Value Entries when undo a Purchase Receipt Line Tracked by Serial Number.

        // Setup: Create Serial Tracked Item. Create Purchase Order and assign Serial No. Receive Purchase Order.
        Initialize();
        CreateAndPostPurchaseDocumentWithTracking(
          TempReservationEntry, PurchaseLine."Document Type"::Order, CreateTrackedItem(true, '', LibraryUtility.GetGlobalNoSeriesCode()), '', 1);  // 1 is Sign Factor.
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, TempReservationEntry."Item No.");
        LibraryVariableStorage.Dequeue(DummyValue);  // Dequeue dummy value to balance blank Enqueued value for ComfirmHandler.
        EnqueueValuesForPostedItemTrackingLines(TempReservationEntry, UndoReceiptMessage, 1);  // Enqueue value for PostedItemTrackingLinesHandler.

        // Exercise: Undo Purchase Receipt Line.
        UndoPurchaseReceipt(PurchaseLine);

        // Verify: Verify Receipt Lines, Value Entry and Item Tracking Lines.
        VerifyReceiptLineWithValueEntry(PurchRcptLine, PurchaseLine, 1, 1, PurchaseLine.Quantity);  // 1 is Sign Factor.
        VerifyReceiptLineWithValueEntry(PurchRcptLine, PurchaseLine, -1, 1, PurchaseLine.Quantity);  // 1 and -1 are Sign Factors.
        PurchRcptLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnPurchaseLineAfterUndo(PurchaseLine, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseInvoicedReceipt()
    var
        Item: Record Item;
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error when undo a Invoiced Purchase Receipt.

        // Setup: Create and Invoice Purchase Order.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateVendor(), CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostPurchaseDocument(PurchaseLine, true);  // True for Invoice.
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Purchase Receipt Line.
        asserterror UndoPurchaseReceipt(PurchaseLine);

        // Verify: Verify error after undo Invoiced Receipt.
        Assert.ExpectedError(StrSubstNo(UndoReceiptError, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptWithAppliedQuantity()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        DummyValue: Variant;
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verify error when undo a Purchase Receipt Line with applied Quantity Tracked by Serial Number.

        // Setup: Create Serial Tracked Item. Create Purchase Order and assign Serial No. Receive Purchase Order.
        Initialize();
        CreatePurchaseDocumentWithTracking(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateTrackedItem(true, '', LibraryUtility.GetGlobalNoSeriesCode()),
          TrackingOption::AssignSerialNo, '', 1);  // 1 is Sign Factor.
        PostPurchaseDocument(PurchaseLine, false);  // False for Invoice.
        LibraryVariableStorage.Dequeue(DummyValue);  // Dequeue dummy value to balance blank Enqueued value for ComfirmHandler.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.", 0, true);

        // Create Sales Order and assign Serial No. Ship and Invoice Sales Order.
        CreateSalesOrderWithTracking(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity, TrackingOption::SelectEntries);
        PostSalesDocument(SalesLine, true);
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Purchase Receipt Line.
        asserterror UndoPurchaseReceipt(PurchaseLine);

        // Verify: Verify error after undo Receipt with applied Quantity.
        Assert.ExpectedTestFieldError(ItemLedgerEntry.FieldCaption("Remaining Quantity"), Format(1));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptWithChargeAssignment()
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        DummyValue: Variant;
    begin
        // Verify Item Tracking Lines and Value Entries when undo a Purchase Receipt Line With Charge Assignment.

        // Setup: Create Serial Tracked Item. Create Purchase Order and assign Serial No. Receive Purchase Order. Create Purchase Invoice for Charge Item and assign it to previous Posted Receipt.
        Initialize();
        CreateAndPostPurchaseDocumentWithTracking(
          TempReservationEntry, PurchaseLine."Document Type"::Order, CreateTrackedItem(true, '', LibraryUtility.GetGlobalNoSeriesCode()), '', 1);  // 1 is sign factor.
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, TempReservationEntry."Item No.");
        LibraryVariableStorage.Dequeue(DummyValue);  // Dequeue dummy value to balance blank Enqueued value for ComfirmHandler.
        EnqueueValuesForPostedItemTrackingLines(TempReservationEntry, UndoReceiptMessage, 1);  // Enqueue value for PostedItemTrackingLinesHandler.
        FindReceiptLine(PurchRcptLine, PurchaseLine, 1);  // 1 is for Sign Factor.
        PurchaseInvoiceItemChargeAssign(
          PurchaseHeader, PurchRcptLine."Buy-from Vendor No.", ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");

        // Exercise: Undo Purchase Receipt Line.
        UndoPurchaseReceipt(PurchaseLine);

        // Verify: Verify Receipt Lines, Value Entry and Item Tracking Lines.
        VerifyReceiptLineWithValueEntry(PurchRcptLine, PurchaseLine, 1, 1, PurchaseLine.Quantity);  // 1 is Sign Factor.
        VerifyReceiptLineWithValueEntry(PurchRcptLine, PurchaseLine, -1, 1, PurchaseLine.Quantity);  // 1 and -1 are Sign Factors.
        PurchRcptLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnPurchaseLineAfterUndo(PurchaseLine, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptWithInvoicedChargeAssignment()
    var
        Item: Record Item;
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Verify error when undo a Purchase Receipt Line With Invoiced Charge Assignment.

        // Setup: Create and Receive Purchase Order.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Order, CreateVendor(), CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostPurchaseDocument(PurchaseLine, false);  // False for Invoice.

        // Create Purchase Invoice for Charge Item and assign it to previous Posted Receipt. Post Purchase Invoice.
        FindReceiptLine(PurchRcptLine, PurchaseLine, 1);  // 1 is for Sign Factor.
        PurchaseInvoiceItemChargeAssign(
          PurchaseHeader, PurchRcptLine."Buy-from Vendor No.", ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Purchase Receipt Line.
        asserterror UndoPurchaseReceipt(PurchaseLine);

        // Verify: Verify error after undo Receipt Invoiced Charge Assignment.
        Assert.ExpectedError(StrSubstNo(InvoicedChargeItemError, PurchaseLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CorrectionLinesUnavailableForSalesOrder()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        DummyValue: Variant;
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verify Serial numbers for the line in the undone Purchase Receipt are not available for Sales Order.

        // Setup: Create Serial Tracked Item. Create Purchase Order and assign Serial No. Receive Purchase Order.
        Initialize();
        CreatePurchaseDocumentWithTracking(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateTrackedItem(true, '', LibraryUtility.GetGlobalNoSeriesCode()),
          TrackingOption::AssignSerialNo, '', 1);  // 1 is Sign Factor.
        PostPurchaseDocument(PurchaseLine, false);  // False for Invoice.
        LibraryVariableStorage.Dequeue(DummyValue);  // Dequeue dummy value to balance blank Enqueued value for ComfirmHandler.
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue value for ConfirmHandler.
        UndoPurchaseReceipt(PurchaseLine);

        // Exercise: Create Sales Order and assign Serial No.
        CreateSalesOrderWithTracking(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity, TrackingOption::VerifyEntries);

        // Verify: Verification done in ItemTrackingSummaryPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CorrectionLinesUnavailableForPurchaseReturnOrder()
    var
        PurchaseLine: Record "Purchase Line";
        DummyValue: Variant;
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verify Serial numbers for the line in the undone Purchase Receipt are not available for Purchase Return Order.

        // Setup: Create Serial Tracked Item. Create Purchase Order and assign Serial No. Receive Purchase Order.
        Initialize();
        CreatePurchaseDocumentWithTracking(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateTrackedItem(true, '', LibraryUtility.GetGlobalNoSeriesCode()),
          TrackingOption::AssignSerialNo, '', 1);  // 1 is Sign Factor.
        PostPurchaseDocument(PurchaseLine, false);  // False for Invoice.
        LibraryVariableStorage.Dequeue(DummyValue);  // Dequeue dummy value to balance blank Enqueued value for ComfirmHandler.
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue value for ConfirmHandler.
        UndoPurchaseReceipt(PurchaseLine);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.

        // Exercise: Create Purchase Return Order and assign Serial No.
        CreatePurchaseDocumentWithTracking(
          PurchaseLine, PurchaseLine."Document Type"::"Return Order", PurchaseLine."No.", TrackingOption::VerifyEntries, '', 1);  // 1 is Sign Factor.

        // Verify: Verification done in ItemTrackingSummaryPageHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoMultipleLinesFromPurchaseReceipt()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Verify corrective Receipt Lines when undo Multiple Lines from Purchase Receipt.

        // Setup: Create and Receive Purchase Order.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Order, CreateVendor(), CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostPurchaseDocument(PurchaseLine2, false);  // False for Invoice.
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Purchase Receipt Line.
        UndoMultiplePurchaseReceiptLines(PurchaseLine, PurchaseLine2."No.");

        // Verify: Verify corrective Receipt Lines.
        VerifyReceiptLine(PurchRcptLine, PurchaseLine, -1);  // -1 is Quantity factor.
        VerifyReceiptLine(PurchRcptLine, PurchaseLine2, -1);  // -1 is Quantity factor.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoNegativePurchaseReceiptTrackedBySerialNumber()
    var
        PurchaseLine: Record "Purchase Line";
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verify Receipt Lines, Item Tracking Lines and Value Entries when undo a Purchase Receipt Line with Negative Quantity Tracked by Serial Number.

        // Setup: Create Item with Item Tracking Code which is neither SN Specific nor Lot Specific. Create Purchase Order and assign Serial No. Receive Purchase Order.
        Initialize();
        CreatePurchaseDocumentWithTracking(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateTrackedItem(false, '', LibraryUtility.GetGlobalNoSeriesCode()),
          TrackingOption::AssignSerialNo, AvailabilityWarning, -1);  // -1 is for SignFactor.

        // Exercise and Verification.
        PostPurchaseOrderAndVerifyUndoReceipt(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptTrackedByLotNumber()
    var
        PurchaseLine: Record "Purchase Line";
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verify Receipt Lines, Item Tracking Lines and Value Entries when undo a Purchase Receipt Line Tracked by Lot Number.

        // Setup: Create Item with Item Tracking Code which is neither SN Specific nor Lot Specific. Create Purchase Order and assign Lot No. Receive Purchase Order.
        Initialize();
        CreatePurchaseDocumentWithTracking(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateTrackedItem(false, LibraryUtility.GetGlobalNoSeriesCode(), ''),
          TrackingOption::AssignLotNo, '', 1);  // 1 is for SignFactor.

        // Exercise and Verification.
        PostPurchaseOrderAndVerifyUndoReceipt(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnShipmentTrackedBySerialNumber()
    var
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
    begin
        // Verify Return Shipment Lines, Item Tracking Lines and Value Entries when undo a Purchase Return Shipment Line Tracked by Serial Number.

        // Setup: Create Item for tracking. Create Purchase Return Order and assign Serial No. Ship Purchase Return Order.
        Initialize();
        CreateAndPostPurchaseDocumentWithTracking(
          TempReservationEntry, PurchaseLine."Document Type"::"Return Order",
          CreateTrackedItem(false, '', LibraryUtility.GetGlobalNoSeriesCode()), AvailabilityWarning, 1);  // 1 is Sign Factor.
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::"Return Order", TempReservationEntry."Item No.");
        EnqueueValuesForPostedItemTrackingLines(TempReservationEntry, UndoReturnShipmentMessage, -1);  // Enqueue value for PostedItemTrackingLinesHandler.

        // Exercise: Undo Purchase Return Shipment Line.
        UndoReturnShipment(PurchaseLine);

        // Verify: Verify Return Shipment Lines, Value Entry and Item Tracking Lines.
        VerifyReturnShipmentLineWithValueEntry(ReturnShipmentLine, PurchaseLine, 1, -1, PurchaseLine.Quantity);  // 1 and -1 are Sign Factors.
        VerifyReturnShipmentLineWithValueEntry(ReturnShipmentLine, PurchaseLine, -1, -1, PurchaseLine.Quantity);  // -1 is Sign Factor.
        ReturnShipmentLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnPurchaseLineAfterUndo(PurchaseLine, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoInvoicedReturnShipmentError()
    var
        Item: Record Item;
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error when undo Invoiced Purchase Return Shipment.

        // Setup: Create and Invoice Purchase Return Order.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Return Order", CreateVendor(), CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostPurchaseDocument(PurchaseLine, true);  // True for Invoice.
        LibraryVariableStorage.Enqueue(UndoReturnShipmentMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Purchase Return Shipment Line.
        asserterror UndoReturnShipment(PurchaseLine);

        // Verify: Verify error after undo Invoiced Return Shipment.
        Assert.ExpectedError(StrSubstNo(UndoShipmentInvoicedErr, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Shipment"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoAlreadyUndoneUninvoicedReturnShipmentError()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error when undo Shipped Purchase Return Shipment.

        // Setup: Create and Ship Purchase Return Order.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Return Order", CreateVendor(), CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostPurchaseDocument(PurchaseLine, false);  // Only Ship.
        LibraryVariableStorage.Enqueue(UndoReturnShipmentMessage);  // Enqueue value for ConfirmHandler.

        // Setup: Undo Purchase Return Shipment Line.
        UndoReturnShipment(PurchaseLine);

        // Exercise: Undo again
        LibraryVariableStorage.Enqueue(UndoReturnShipmentMessage);  // Enqueue value for ConfirmHandler.
        asserterror UndoReturnShipment(PurchaseLine);

        // Verify: Verify error after undo Invoiced Return Shipment.
        Assert.ExpectedError(ReturnShipmentAlreadyReversedErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnShipmentWithChargeAssignment()
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
    begin
        // Verify Item Tracking Lines and Value Entries when undo a Purchase Return Shipment Line With Charge Assignment.

        // Setup: Create Item for tracking. Create Purchase Return Order and assign Serial No. Receive Purchase Return Order. Create Purchase Invoice for Charge Item and assign it to previous Posted Return Shipment.
        Initialize();
        CreateAndPostPurchaseDocumentWithTracking(
          TempReservationEntry, PurchaseLine."Document Type"::"Return Order",
          CreateTrackedItem(false, '', LibraryUtility.GetGlobalNoSeriesCode()), AvailabilityWarning, 1);  // 1 is Sign Factor.
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::"Return Order", TempReservationEntry."Item No.");
        EnqueueValuesForPostedItemTrackingLines(TempReservationEntry, UndoReturnShipmentMessage, -1);  // Enqueue value for PostedItemTrackingLinesHandler.
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine, 1);  // 1 is for Sign Factor.
        PurchaseInvoiceItemChargeAssign(
          PurchaseHeader, ReturnShipmentLine."Buy-from Vendor No.", ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Shipment",
          ReturnShipmentLine."Document No.", ReturnShipmentLine."Line No.", ReturnShipmentLine."No.");

        // Exercise: Undo Purchase Return Shipment Line.
        UndoReturnShipment(PurchaseLine);

        // Verify: Verify Return Shipment Lines, Value Entry and Item Tracking Lines.
        VerifyReturnShipmentLineWithValueEntry(ReturnShipmentLine, PurchaseLine, 1, -1, PurchaseLine.Quantity);  // 1 and -1 are Sign Factors.
        VerifyReturnShipmentLineWithValueEntry(ReturnShipmentLine, PurchaseLine, -1, -1, PurchaseLine.Quantity);  // -1 is Sign Factor.
        ReturnShipmentLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnPurchaseLineAfterUndo(PurchaseLine, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnShipmentWithInvoicedChargeAssignmentError()
    var
        Item: Record Item;
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Verify error when undo a Purchase Return Shipment Line With Invoiced Charge Assignment.

        // Setup: Create and Ship Purchase Return Order.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::"Return Order", CreateVendor(), CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostPurchaseDocument(PurchaseLine, false);  // False for Invoice.

        // Create Purchase Invoice for Charge Item and assign it to previous Posted Return Shipment. Post Purchase Invoice.
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine, 1);  // 1 is for Sign Factor.
        PurchaseInvoiceItemChargeAssign(
          PurchaseHeader, ReturnShipmentLine."Buy-from Vendor No.", ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Shipment",
          ReturnShipmentLine."Document No.", ReturnShipmentLine."Line No.", ReturnShipmentLine."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryVariableStorage.Enqueue(UndoReturnShipmentMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Purchase Return Shipment Line.
        asserterror UndoReturnShipment(PurchaseLine);

        // Verify: Verify error after undo Return Shipment with Invoiced Charge Assignment.
        Assert.ExpectedError(StrSubstNo(InvoicedChargeItemError, PurchaseLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoMultipleLinesFromReturnShipment()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Verify corrective Return Shipment Lines when undo Multiple Lines from Return Shipment.

        // Setup: Create and Ship Purchase Return Order.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::"Return Order", CreateVendor(), CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostPurchaseDocument(PurchaseLine2, false);  // False for Invoice.
        LibraryVariableStorage.Enqueue(UndoReturnShipmentMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Purchase Return Shipment Line.
        UndoMultipleReturnShipmentLines(PurchaseLine, PurchaseLine2."No.");

        // Verify: Verify corrective Return Shipment Lines.
        VerifyReturnShipmentLine(ReturnShipmentLine, PurchaseLine, -1);  // -1 is Quantity factor.
        VerifyReturnShipmentLine(ReturnShipmentLine, PurchaseLine2, -1);  // -1 is Quantity factor.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeletePurchaseReturnOrderAfterUndo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify deletion of Purchase Return Order is allowed after undo because nothing has been posted.

        // Setup: Create and Ship Purchase Return Order. Undo Return Shipment and reopen the Purchase Return Order.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::"Return Order", CreateVendor(), CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostPurchaseDocument(PurchaseLine, false);  // False for Invoice.
        LibraryVariableStorage.Enqueue(UndoReturnShipmentMessage);  // Enqueue value for ConfirmHandler.
        UndoReturnShipment(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise: Delete Purchase Return Order.
        PurchaseHeader.Delete(true);

        // Verify: Purchase Return Order is deleted.
        Assert.IsFalse(PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No."), DeletionError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnShipmentOfNegativeQuantity()
    var
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        DummyValue: Variant;
    begin
        // Verify Return Shipment Lines, Item Tracking Lines and Value Entries when undo a Purchase Return Shipment Line with Negative Quantity Tracked by Serial Number.

        // Setup: Create Serial tracked Item. Create Purchase Return Order and assign Serial No. Ship Purchase Return Order.
        Initialize();
        CreateAndPostPurchaseDocumentWithTracking(
          TempReservationEntry, PurchaseLine."Document Type"::"Return Order",
          CreateTrackedItem(true, '', LibraryUtility.GetGlobalNoSeriesCode()), '', -1);  // -1 is sign factor.
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::"Return Order", TempReservationEntry."Item No.");
        LibraryVariableStorage.Dequeue(DummyValue);  // Dequeue dummy value to balance blank Enqueued value for ComfirmHandler.
        EnqueueValuesForPostedItemTrackingLines(TempReservationEntry, UndoReturnShipmentMessage, 1);  // Enqueue value for PostedItemTrackingLinesHandler.

        // Exercise: Undo Purchase Return Shipment Line.
        UndoReturnShipment(PurchaseLine);

        // Verify: Verify Return Shipment Lines, Value Entry and Item Tracking Lines.
        VerifyReturnShipmentLineWithValueEntry(ReturnShipmentLine, PurchaseLine, -1, 1, PurchaseLine.Quantity);  // 1 and -1 are Sign Factors.
        VerifyReturnShipmentLineWithValueEntry(ReturnShipmentLine, PurchaseLine, 1, 1, PurchaseLine.Quantity);  // 1 is Sign Factor.
        ReturnShipmentLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnPurchaseLineAfterUndo(PurchaseLine, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShptAfterRcdPurchOrd()
    begin
        // Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each other when Undo Sales Shipment after receiving Purchase Order.
        UndoShptAfterPstdPurchOrd(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShptAfterInvdPurchOrd()
    begin
        // Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each other when Undo Sales Shipment after invoicing Purchase Order.
        UndoShptAfterPstdPurchOrd(true);
    end;

    local procedure UndoShptAfterPstdPurchOrd(Invoice: Boolean)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create and Post Purchase Order. Create and Ship Sales Order. Undo Sales Shipment.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateVendor(), CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostPurchaseDocument(PurchaseLine, Invoice);
        CreateShipSalesOrderAndUndoShipment(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(SalesLine."No.", '');

        // Verify: Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each.
        VerifyItemLedgerEntry(SalesLine."No.", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShptAfterRcdPurchOrdWithSalesDocuments()
    begin
        // Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each other when Undo Shipment after receiving Purchase Order and posting Sales Order and Sales Return Order.
        UndoShptAfterPstdPurchOrdPstdSalesOrdAndSaleRetOrd(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShptAfterInvdPurchOrdWithSalesDocuments()
    begin
        // Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each other when Undo Shipment after invoicing Purchase Order and posting Sales Order and Sales Return Order.
        UndoShptAfterPstdPurchOrdPstdSalesOrdAndSaleRetOrd(true);
    end;

    local procedure UndoShptAfterPstdPurchOrdPstdSalesOrdAndSaleRetOrd(Invoice: Boolean)
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create and Post Purchase Order. Create and Invoice Sales Order.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateVendor(), CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostPurchaseDocument(PurchaseLine, Invoice);
        CreateAndPostSalesDocWithApplFromItemEntry(
          SalesLine, SalesLine."Document Type"::Order, PurchaseLine."No.", PurchaseLine.Quantity, 0, true);  // Use zero value for Entry No.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, PurchaseLine."No.", SalesLine.Amount, false);

        // Create Sales Return Order, apply with previous Sales Shipment and Invoice it.
        CreateAndPostSalesDocWithApplFromItemEntry(
          SalesLine, SalesLine."Document Type"::"Return Order", PurchaseLine."No.", PurchaseLine.Quantity, ItemLedgerEntry."Entry No.", true);

        // Create and Ship Sales Order. Undo Sales Shipment.
        CreateShipSalesOrderAndUndoShipment(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(SalesLine."No.", '');

        // Verify: Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each.
        VerifyItemLedgerEntry(SalesLine."No.", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShptAfterMultiplePurchaseSaleUndo()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each other.

        // Setup: Create and Receive Purchase Order. Undo Purchase Receipt.
        Initialize();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateVendor(), CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostPurchaseDocument(PurchaseLine, false);
        LibraryVariableStorage.Enqueue(UndoReceiptMessage);  // Enqueue for Confirm Handler.
        UndoPurchaseReceipt(PurchaseLine);

        // Create and Ship Sales Order. Undo Sales Shipment. Again Invoice Sales Order.
        CreateShipSalesOrderAndUndoShipment(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity);
        PostSalesDocument(SalesLine, true);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, PurchaseLine."No.", 0, false);

        // Create Sales Return Order, apply with previous Sales Shipment and Invoice it.
        CreateAndPostSalesDocWithApplFromItemEntry(
          SalesLine, SalesLine."Document Type"::"Return Order", PurchaseLine."No.", PurchaseLine.Quantity, 0, true);  // Use zero value for Entry No.

        // Create and Ship Sales Order. Undo Sales Shipment.
        CreateShipSalesOrderAndUndoShipment(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(SalesLine."No.", '');

        // Verify: Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each.
        VerifyItemLedgerEntry(SalesLine."No.", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShptAfterUndoShptPstdSalesOrd()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each other.

        // Setup: Create and Ship Sales Order. Undo Sales Shipment. Post Sales Order as Invoice.
        Initialize();
        CreateShipSalesOrderAndUndoShipment(
          SalesLine, CreateItem(Item."Replenishment System"::Purchase), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostSalesDocument(SalesLine, true);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(SalesLine."No.", '');

        // Verify: Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each.
        VerifyItemLedgerEntry(SalesLine."No.", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShptAfterPostingConsumption()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        SalesLine: Record "Sales Line";
    begin
        // Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each other.

        // Setup: Create Production Order and Post Comsumption. Create and Ship Sales Order. Undo Sales Shipment.
        Initialize();
        CreateProductionOrderAndPostConsumptionOutput(ItemJournalLine, ItemJournalTemplate.Type::Consumption);
        CreateShipSalesOrderAndUndoShipment(SalesLine, ItemJournalLine."Item No.", LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PostSalesDocument(SalesLine, true);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(SalesLine."No.", '');

        // Verify: Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each.
        VerifyItemLedgerEntry(SalesLine."No.", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoShptAfterPostingOutput()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        SalesLine: Record "Sales Line";
    begin
        // Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each other.

        // Setup: Create Production Order and Post Output. Create and Ship Sales Order. Undo Sales Shipment.
        Initialize();
        CreateProductionOrderAndPostConsumptionOutput(ItemJournalLine, ItemJournalTemplate.Type::Output);
        CreateShipSalesOrderAndUndoShipment(SalesLine, ItemJournalLine."Item No.", LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(SalesLine."No.", '');

        // Verify: Verify Cost Amount (actual) of the Undone and the corrected Item Ledger Entry, should balance each.
        VerifyItemLedgerEntry(SalesLine."No.", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoInvoicedSalesShipmentError()
    var
        Item: Record Item;
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesLine: Record "Sales Line";
    begin
        // Verify error when undo Invoiced Sales Shipment.

        // Setup: Create and Invoice Sales Order.
        Initialize();
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, CreateItem(Item."Replenishment System"::Purchase), LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostSalesDocument(SalesLine, true);  // True for Invoice.
        LibraryVariableStorage.Enqueue(UndoShipmentMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Sales Shipment Line.
        asserterror UndoSalesShipment(SalesLine);

        // Verify: Verify error after undo Invoiced Sales Shipment.
        Assert.ExpectedError(StrSubstNo(UndoShipmentInvoicedErr, ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoAlreadyUndoneUninvoicedSalesShipmentError()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Verify error when undo un- invoiced Sales Shipment.

        // Setup: Create and Ship Sales Order.
        Initialize();
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, CreateItem(Item."Replenishment System"::Purchase), LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostSalesDocument(SalesLine, false);  // Ship only.
        LibraryVariableStorage.Enqueue(UndoShipmentMessage);  // Enqueue value for ConfirmHandler.

        // Setup: Undo Sales Shipment Line.
        UndoSalesShipment(SalesLine);

        // Exercise: Undo again
        LibraryVariableStorage.Enqueue(UndoShipmentMessage);  // Enqueue value for ConfirmHandler.
        asserterror UndoSalesShipment(SalesLine);

        // Verify: Verify error after undo Invoiced Sales Shipment.
        Assert.ExpectedError(ShipmentAlreadyReversedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentWithInvoicedChargeAssignmentError()
    var
        Item: Record Item;
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Verify error when undo a Sales Shipment Line With Invoiced Charge Assignment.

        // Setup: Create and Ship Sales Order.
        Initialize();
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, CreateItem(Item."Replenishment System"::Purchase), LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostSalesDocument(SalesLine, false);  // False for Invoice.

        // Create Sales Invoice for Charge Item and assign it to previous Posted Sales Shipment. Post Sales Invoice.
        FindShipmentLine(SalesShipmentLine, SalesLine, 1);  // 1 is Sign Factor.
        SalesInvoiceItemChargeAssign(
          SalesHeader, SalesShipmentLine."Sell-to Customer No.", ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
          SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryVariableStorage.Enqueue(UndoShipmentMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Sales Shipment Line.
        asserterror UndoSalesShipment(SalesLine);

        // Verify: Verify error after undo Sales Shipment with Invoiced Charge Assignment.
        Assert.ExpectedError(StrSubstNo(InvoicedChargeItemError, SalesLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteSalesOrderAfterUndo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify deletion of Sales Order is allowed after undo because nothing has been posted.

        // Setup: Create and Ship Sales Order. Undo Sales Shipment and reopen the Sales Order.
        Initialize();
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostSalesDocument(SalesLine, false);  // False for Invoice.
        LibraryVariableStorage.Enqueue(UndoShipmentMessage);  // Enqueue value for ConfirmHandler.
        UndoSalesShipment(SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Delete Sales Order.
        SalesHeader.Delete(true);

        // Verify: Sales Order is deleted.
        Assert.IsFalse(SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No."), DeletionError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentTrackedBySerialNumber()
    var
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Verify Shipment Lines, Item Tracking Lines and Value Entries when undo a Sales Shipment Line Tracked by Serial Number.

        // Setup: Create and Receive Purchase Order with Serial Tracking. Create and Ship Sales Order with Serial Tracking.
        Initialize();
        PostPurchaseAndSalesOrderWithTracking(SalesLine);

        // Exercise: Undo Sales Shipment Line.
        UndoSalesShipment(SalesLine);

        // Verify: Verify Shipment Lines, Value Entry and Item Tracking Lines.
        VerifyShipmentLineWithValueEntry(SalesShipmentLine, SalesLine, 1, -1);  // 1 and -1 are Sign Factors.
        VerifyShipmentLineWithValueEntry(SalesShipmentLine, SalesLine, -1, -1);  // -1 is Sign Factor.
        SalesShipmentLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnSalesLineAfterUndo(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentWithChargeAssignment()
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Verify Item Tracking Lines and Value Entries when undo a Sales Shipment Line Tracked by Serial Number With Charge Assignment.

        // Setup: Create and Receive Purchase Order with Serial Tracking. Create and Ship Sales Order with Serial Tracking. Create Sales Invoice for Charge Item and assign it to previous Posted Shipment.
        Initialize();
        PostPurchaseAndSalesOrderWithTracking(SalesLine);
        FindShipmentLine(SalesShipmentLine, SalesLine, 1);  // 1 is for Sign Factor.
        SalesInvoiceItemChargeAssign(
          SalesHeader, SalesShipmentLine."Sell-to Customer No.", ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
          SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");

        // Exercise: Undo Sales Shipment Line.
        UndoSalesShipment(SalesLine);

        // Verify: Verify Shipment Lines, Value Entry and Item Tracking Lines.
        VerifyShipmentLineWithValueEntry(SalesShipmentLine, SalesLine, 1, -1);  // 1 and -1 are Sign Factors.
        VerifyShipmentLineWithValueEntry(SalesShipmentLine, SalesLine, -1, -1);  // -1 is Sign Factor.
        SalesShipmentLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnSalesLineAfterUndo(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoMultipleLinesFromSalesShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Verify corrective Sales Shipment Lines when undo Multiple Lines from Sales Shipment.

        // Setup: Create and Ship Sales Order with multiple lines.
        Initialize();
        CreateSalesDocument(
          SalesLine, SalesHeader."Document Type"::Order, CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine.Type::Item, CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use random value for Quantity.
        PostSalesDocument(SalesLine2, false);  // False for Invoice.
        LibraryVariableStorage.Enqueue(UndoShipmentMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo multiple Sales Shipment Lines.
        UndoMultipleShipmentLines(SalesLine, SalesLine2."No.");

        // Verify: Verify corrective Sales Shipment Lines.
        VerifyShipmentLine(SalesShipmentLine, SalesLine, -1);  // -1 is Quantity factor.
        VerifyShipmentLine(SalesShipmentLine, SalesLine2, -1);  // -1 is Quantity factor.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentOfNegativeQuantity()
    var
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verify Sales Shipment Lines, Item Tracking Lines and Value Entries when undo a Sales Shipment Line with Negative Quantity Tracked by Serial Number.

        // Setup: Create and Ship Sales Order with Serial Tracking.
        Initialize();
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, CreateTrackedItem(false, '', LibraryUtility.GetGlobalNoSeriesCode()),
          -LibraryRandom.RandInt(5));
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
        FindReservationEntry(TempReservationEntry, SalesLine."No.");
        PostSalesDocument(SalesLine, false);  // False for Invoice.
        EnqueueValuesForPostedItemTrackingLines(TempReservationEntry, UndoShipmentMessage, -1);  // Enqueue value for PostedItemTrackingLinesHandler.

        // Exercise: Undo Sales Shipment Line.
        UndoSalesShipment(SalesLine);

        // Verify: Verify Shipment Lines, Value Entry and Item Tracking Lines.
        VerifyShipmentLineWithValueEntry(SalesShipmentLine, SalesLine, 1, 1);  // 1 is Sign Factor.
        VerifyShipmentLineWithValueEntry(SalesShipmentLine, SalesLine, -1, 1);  // 1 and -1 are Sign Factors.
        SalesShipmentLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnSalesLineAfterUndo(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoRetRcptTrackedBySN()
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesLine: Record "Sales Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        DummyValue: Variant;
    begin
        // Verify Return Receipt Lines, Item Tracking Lines and Value Entries when undo a Return Receipt Line Tracked by Serial Number.

        // Setup: Create Serial Tracked Item. Create Sales Return Order and assign Serial No. Receive Sales Return Order.
        Initialize();
        CreateAndPostSalesReturnOrderWithTracking(TempReservationEntry, true, 1, '');  // 1 is for Sign factor.
        FindSalesLine(SalesLine, SalesLine."Document Type"::"Return Order", TempReservationEntry."Item No.");
        LibraryVariableStorage.Dequeue(DummyValue);  // Dequeue dummy value to balance blank Enqueued value.
        EnqueueValuesForPostedItemTrackingLines(TempReservationEntry, UndoReturnReceiptMessage, 1);  // Enqueue value for PostedItemTrackingLinesHandler.

        // Exercise: Undo Return Receipt Line.
        UndoReturnReceipt(SalesLine);

        // Verify: Verify Receipt Lines, Value Entry and Item Tracking Lines.
        VerifyReturnReceiptLineWithValueEntry(ReturnReceiptLine, SalesLine, 1, 1);  // 1 is Sign Factor.
        VerifyReturnReceiptLineWithValueEntry(ReturnReceiptLine, SalesLine, -1, 1);  // 1 and -1 are Sign Factors.
        ReturnReceiptLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnSalesLineAfterUndo(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoInvdRetRcptError()
    var
        Item: Record Item;
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesLine: Record "Sales Line";
    begin
        // Verify error when undo a Invoiced Return Receipt.

        // Setup: Create and Invoice Sales Return Order.
        Initialize();
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use Random Quantity.
        PostSalesDocument(SalesLine, true);  // True for Invoice.
        LibraryVariableStorage.Enqueue(UndoReturnReceiptMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Return Receipt Line.
        asserterror UndoReturnReceipt(SalesLine);

        // Verify: Verify error after undo Invoiced Return Receipt.
        Assert.ExpectedError(StrSubstNo(UndoReceiptError, ItemChargeAssignmentSales."Applies-to Doc. Type"::"Return Receipt"));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoRetRcptWithAppliedQuantityError()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        DummyValue: Variant;
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verify error when undo a Return Receipt Line with applied Quantity Tracked by Serial Number.

        // Setup: Create Serial Tracked Item. Create Sales Return Order and assign Serial No. Receive Sales Return Order.
        Initialize();
        CreateAndPostSalesReturnOrderWithTracking(TempReservationEntry, true, 1, '');  // 1 is for Sign factor.
        FindSalesLine(SalesLine, SalesLine."Document Type"::"Return Order", TempReservationEntry."Item No.");
        LibraryVariableStorage.Dequeue(DummyValue);  // Dequeue dummy value to balance blank Enqueued value.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, SalesLine."No.", 0, true);

        // Create Sales Order with Tracking. Ship and Invoice Sales Order.
        CreateSalesOrderWithTracking(
          SalesLine2, TempReservationEntry."Item No.", TempReservationEntry.Quantity, TrackingOption::SelectEntries);
        PostSalesDocument(SalesLine2, true);  // True for Invoice.
        LibraryVariableStorage.Enqueue(UndoReturnReceiptMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Return Receipt Line.
        asserterror UndoReturnReceipt(SalesLine);

        // Verify: Verify error after undo Receipt with applied Quantity.
        Assert.ExpectedTestFieldError(ItemLedgerEntry.FieldCaption("Remaining Quantity"), Format(1));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoRetRcptWithChargeAssgntTrackedBySN()
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        DummyValue: Variant;
    begin
        // Verify Return Receipt Lines, Item Tracking Lines and Value Entries when undo a Return Receipt Line Tracked by Serial Number With Charge Assignment.

        // Setup: Create Serial Tracked Item. Create Sales Return Order and assign Serial No. Receive Sales Return Order.
        Initialize();
        CreateAndPostSalesReturnOrderWithTracking(TempReservationEntry, true, 1, '');  // 1 is for Sign factor.
        FindSalesLine(SalesLine, SalesLine."Document Type"::"Return Order", TempReservationEntry."Item No.");
        LibraryVariableStorage.Dequeue(DummyValue);  // Dequeue dummy value to balance blank Enqueued value.

        // Create Sales Invoice for Charge Item and assign it to previous Posted Receipt.
        FindReturnReceiptLine(ReturnReceiptLine, SalesLine, 1);  // 1 is for Sign Factor.
        SalesInvoiceItemChargeAssign(
          SalesHeader, ReturnReceiptLine."Sell-to Customer No.", ItemChargeAssignmentSales."Applies-to Doc. Type"::"Return Receipt",
          ReturnReceiptLine."Document No.", ReturnReceiptLine."Line No.", ReturnReceiptLine."No.");
        EnqueueValuesForPostedItemTrackingLines(TempReservationEntry, UndoReturnReceiptMessage, 1);  // Enqueue value for PostedItemTrackingLinesHandler.

        // Exercise: Undo Return Receipt Line.
        UndoReturnReceipt(SalesLine);

        // Verify: Verify Receipt Lines, Value Entry and Item Tracking Lines.
        VerifyReturnReceiptLineWithValueEntry(ReturnReceiptLine, SalesLine, 1, 1);  // 1 is Sign Factor.
        VerifyReturnReceiptLineWithValueEntry(ReturnReceiptLine, SalesLine, -1, 1);  // 1 and -1 are Sign Factors.
        ReturnReceiptLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnSalesLineAfterUndo(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoRetRcptWithInvdChargeAssgntError()
    var
        Item: Record Item;
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify error when undo a Return Receipt Line With Invoiced Charge Assignment.

        // Setup: Create and Receive Sales Return Order.
        Initialize();
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use Random Quantity.
        PostSalesDocument(SalesLine, false);  // False for Invoice.

        // Create Sales Invoice for Charge Item and assign it to previous Posted Receipt. Post Sales Invoice.
        FindReturnReceiptLine(ReturnReceiptLine, SalesLine, 1);  // 1 is for Sign Factor.
        SalesInvoiceItemChargeAssign(
          SalesHeader, ReturnReceiptLine."Sell-to Customer No.", ItemChargeAssignmentSales."Applies-to Doc. Type"::"Return Receipt",
          ReturnReceiptLine."Document No.", ReturnReceiptLine."Line No.", ReturnReceiptLine."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryVariableStorage.Enqueue(UndoReturnReceiptMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Return Receipt Line.
        asserterror UndoReturnReceipt(SalesLine);

        // Verify: Verify error after undo Receipt Invoiced Charge Assignment.
        Assert.ExpectedError(StrSubstNo(InvoicedChargeItemError, SalesLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoMultipleLinesFromRetRcpt()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        // Verify corrective Return Receipt Lines when undo Multiple Lines from Return Receipt.

        // Setup: Create and Receive Sales Return Order with multiple lines.
        Initialize();
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use Random Quantity.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine.Type::Item, CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use Random Quantity.
        PostSalesDocument(SalesLine2, false);  // False for Invoice.
        LibraryVariableStorage.Enqueue(UndoReturnReceiptMessage);  // Enqueue value for ConfirmHandler.

        // Exercise: Undo Return Receipt Line.
        UndoMultipleReturnReceiptLines(SalesLine, SalesLine2."No.");

        // Verify: Verify corrective Receipt Lines.
        VerifyReturnReceiptLine(ReturnReceiptLine, SalesLine, -1);  // -1 is Quantity factor.
        VerifyReturnReceiptLine(ReturnReceiptLine, SalesLine2, -1);  // -1 is Quantity factor.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteSalesRetOrdAfterUndo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify deletion of Sales Return Order is allowed after undo because nothing has been posted.

        // Setup: Create and Receive Sales Return Order. Undo Return Receipt.
        Initialize();
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandInt(5));  // Use Random Quantity.
        PostSalesDocument(SalesLine, false);  // False for Invoice.
        LibraryVariableStorage.Enqueue(UndoReturnReceiptMessage);  // Enqueue value for ConfirmHandler.
        UndoReturnReceipt(SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Delete Purchase Return Order.
        SalesHeader.Delete(true);

        // Verify: Purchase Return Order is deleted.
        Assert.IsFalse(SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No."), DeletionError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoRetRcptWithNegQtyTrackedBySN()
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesLine: Record "Sales Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
    begin
        // Verify Return Receipt Lines, Item Tracking Lines and Value Entries when undo a Return Receipt Line with Negative Quantity Tracked by Serial Number.

        // Setup: Create Sales Return Order with negative quantity and Serial Tracking. Receive Sales Return Order.
        Initialize();
        CreateAndPostSalesReturnOrderWithTracking(TempReservationEntry, false, -1, AvailabilityWarning);  // -1 is for Sign factor.
        FindSalesLine(SalesLine, SalesLine."Document Type"::"Return Order", TempReservationEntry."Item No.");
        EnqueueValuesForPostedItemTrackingLines(TempReservationEntry, UndoReturnReceiptMessage, 1);  // Enqueue value for PostedItemTrackingLinesHandler.

        // Exercise: Undo Return Receipt Line.
        UndoReturnReceipt(SalesLine);

        // Verify: Verify Receipt Lines, Value Entry and Item Tracking Lines.
        VerifyReturnReceiptLineWithValueEntry(ReturnReceiptLine, SalesLine, 1, -1);  // 1 and -1 are Sign Factors.
        VerifyReturnReceiptLineWithValueEntry(ReturnReceiptLine, SalesLine, -1, -1);  // -1 is Sign Factor.
        ReturnReceiptLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnSalesLineAfterUndo(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TrackingForSalesOrdAfterUndoRetRcpt()
    var
        SalesLine: Record "Sales Line";
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verify Serial numbers for the line in the undone Return Receipt are not available for Sales Order.

        // Setup: Create Sales Return Order and assign Serial No. Receive Sales Return Order. Undo Return Receipt.
        Initialize();
        PostSalesReturnOrderAndUndoReturnReceipt(SalesLine);

        // Exercise: Create Sales Order and select Serial No.
        CreateSalesOrderWithTracking(SalesLine, SalesLine."No.", SalesLine.Quantity, TrackingOption::VerifyEntries);

        // Verify: Verify Serial numbers on Sales Order. Verification done in ItemTrackingSummaryPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TrackingForPurchRetOrdAfterUndoRetRcpt()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verify Serial numbers for the line in the undone Return Receipt are not available for Purchase Return Order.

        // Setup: Create Sales Return Order and assign Serial No. Receive Sales Return Order. Undo Return Receipt.
        Initialize();
        PostSalesReturnOrderAndUndoReturnReceipt(SalesLine);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.

        // Exercise: Create Purchase Return Order.
        CreatePurchaseDocumentWithTracking(
          PurchaseLine, PurchaseLine."Document Type"::"Return Order", SalesLine."No.", TrackingOption::VerifyEntries, '', 1);  // 1 is Sign Factor.

        // Verify: Verify Serial numbers on Purchase Return Order. Verification done in ItemTrackingSummaryPageHandler.
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Costing III");
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Costing III");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Costing III");
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);  // Use 1 for Quantity Per.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; TemplateType: Enum "Item Journal Template Type"; EntryType: Enum "Item Ledger Document Type")
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo,
          LibraryRandom.RandDec(10, 2));  // Use Random Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostPurchaseDocumentWithTracking(var TempReservationEntry: Record "Reservation Entry" temporary; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; ComfirmMessage: Text[1024]; SignFactor: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        CreatePurchaseDocumentWithTracking(PurchaseLine, DocumentType, ItemNo, TrackingOption::AssignSerialNo, ComfirmMessage, SignFactor);
        FindReservationEntry(TempReservationEntry, PurchaseLine."No.");
        PostPurchaseDocument(PurchaseLine, false);  // False for Invoice.
    end;

    local procedure CreateAndPostSalesDocWithApplFromItemEntry(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; No: Code[20]; Quantity: Decimal; ApplyFromItemEntry: Integer; Invoice: Boolean)
    begin
        CreateSalesDocument(SalesLine, DocumentType, No, Quantity);
        SalesLine.Validate("Appl.-from Item Entry", ApplyFromItemEntry);
        SalesLine.Modify(true);
        PostSalesDocument(SalesLine, Invoice);
    end;

    local procedure CreateAndPostSalesReturnOrderWithTracking(var TempReservationEntry: Record "Reservation Entry" temporary; SNSpecific: Boolean; SignFactor: Integer; ConfirmMessage: Text[1024])
    var
        SalesLine: Record "Sales Line";
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", CreateTrackedItem(SNSpecific, '', LibraryUtility.GetGlobalNoSeriesCode()),
          SignFactor * LibraryRandom.RandInt(5));  // Use Random Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        if SNSpecific then
            LibraryVariableStorage.Enqueue(ConfirmMessage);
        SalesLine.OpenItemTrackingLines();
        FindReservationEntry(TempReservationEntry, SalesLine."No.");
        PostSalesDocument(SalesLine, false);  // False for Invoice.
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItem(ReplenishmentSystem: Enum "Replenishment System"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(10, 2));  // Using Random value for Last Direct Cost.
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemTrackingCode(SNSpecific: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, false);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreatePurchaseDocumentWithTracking(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; TrackingOption: Option; WarningsMessage: Text[1024]; SignFactor: Integer)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreatePurchaseDocument(PurchaseLine, DocumentType, CreateVendor(), ItemNo, SignFactor * LibraryRandom.RandInt(5));  // Use random value for Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        Item.Get(ItemNo);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        if ItemTrackingCode."SN Specific Tracking" or ItemTrackingCode."Lot Specific Tracking" then
            LibraryVariableStorage.Enqueue(WarningsMessage);  // Enqueue value for ConfirmHandler.
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; No: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, Quantity);
    end;

    local procedure CreateSalesOrderWithTracking(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Integer; TrackingSummaryOption: Option)
    var
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(TrackingSummaryOption);  // Enqueue value for ItemTrackingSummaryPageHandler.
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateShipSalesOrderAndUndoShipment(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateAndPostSalesDocWithApplFromItemEntry(SalesLine, SalesLine."Document Type"::Order, ItemNo, Quantity, 0, false);  // Use zero value for Entry No.
        LibraryVariableStorage.Enqueue(UndoShipmentMessage);  // Enqueue for Confirm Handler.
        UndoSalesShipment(SalesLine);
    end;

    local procedure CreateTrackedItem(SNSpecific: Boolean; LotNos: Code[20]; SerialNos: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, CreateItemTrackingCode(SNSpecific));
        exit(Item."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure EnqueueValuesForPostedItemTrackingLines(var TempReservationEntry: Record "Reservation Entry" temporary; Message: Text[1024]; SignFactor: Integer)
    begin
        LibraryVariableStorage.Enqueue(Message);  // Enqueue value for ConfirmHandler.
        TempReservationEntry.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(TempReservationEntry."Serial No.");
            LibraryVariableStorage.Enqueue(SignFactor * -TempReservationEntry.Quantity);
        until TempReservationEntry.Next() = 0;
    end;

    local procedure FilterForReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetFilter("No.", ItemFilter, PurchaseLine."No.", ItemNo);
    end;

    local procedure FilterForReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        ReturnReceiptLine.SetRange("Return Order No.", SalesLine."Document No.");
        ReturnReceiptLine.SetFilter("No.", ItemFilter, SalesLine."No.", ItemNo);
    end;

    local procedure FilterForReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        ReturnShipmentLine.SetRange("Return Order No.", PurchaseLine."Document No.");
        ReturnShipmentLine.SetFilter("No.", ItemFilter, PurchaseLine."No.", ItemNo);
    end;

    local procedure FilterForShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Order No.", SalesLine."Document No.");
        SalesShipmentLine.SetFilter("No.", ItemFilter, SalesLine."No.", ItemNo);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; SalesAmountActual: Decimal; Open: Boolean)
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Sales Amount (Actual)", SalesAmountActual);
        ItemLedgerEntry.SetRange(Open, Open);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line"; QuantityFactor: Integer)
    begin
        FilterForReceiptLine(PurchRcptLine, PurchaseLine, PurchaseLine."No.");
        PurchRcptLine.SetRange(Quantity, QuantityFactor * PurchaseLine.Quantity);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line"; QuantityFactor: Integer)
    begin
        FilterForReturnReceiptLine(ReturnReceiptLine, SalesLine, SalesLine."No.");
        ReturnReceiptLine.SetRange(Quantity, QuantityFactor * SalesLine.Quantity);
        ReturnReceiptLine.FindFirst();
    end;

    local procedure FindReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; PurchaseLine: Record "Purchase Line"; QuantityFactor: Integer)
    begin
        FilterForReturnShipmentLine(ReturnShipmentLine, PurchaseLine, PurchaseLine."No.");
        ReturnShipmentLine.SetRange(Quantity, QuantityFactor * PurchaseLine.Quantity);
        ReturnShipmentLine.FindFirst();
    end;

    local procedure FindReservationEntry(var TempReservationEntry: Record "Reservation Entry" temporary; ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindSet();
        repeat
            TempReservationEntry := ReservationEntry;
            TempReservationEntry.Insert();
        until ReservationEntry.Next() = 0;
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; No: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
    end;

    local procedure FindShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; SignFactor: Integer)
    begin
        FilterForShipmentLine(SalesShipmentLine, SalesLine, SalesLine."No.");
        SalesShipmentLine.SetRange(Quantity, SignFactor * SalesLine.Quantity);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemNo: Code[20]; DocumentType: Enum "Item Ledger Document Type"; DocumentLineNo: Integer)
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Document Line No.", DocumentLineNo);
    end;

    local procedure PostPurchaseDocument(PurchaseLine: Record "Purchase Line"; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
    end;

    local procedure PostPurchaseOrderAndVerifyUndoReceipt(PurchaseLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
    begin
        FindReservationEntry(TempReservationEntry, PurchaseLine."No.");
        PostPurchaseDocument(PurchaseLine, false);  // False for Invoice.
        EnqueueValuesForPostedItemTrackingLines(TempReservationEntry, UndoReceiptMessage, 1);  // Enqueue value for PostedItemTrackingLinesHandler.

        // Exercise: Undo Purchase Receipt Line.
        UndoPurchaseReceipt(PurchaseLine);

        // Verify: Verify Receipt Lines, Value Entry and Item Tracking Lines.
        VerifyReceiptLineWithValueEntry(PurchRcptLine, PurchaseLine, 1, 1, TempReservationEntry.Count);  // 1 is Sign Factor.
        VerifyReceiptLineWithValueEntry(PurchRcptLine, PurchaseLine, -1, 1, TempReservationEntry.Count);   // 1 and -1 are Sign Factors.
        PurchRcptLine.ShowItemTrackingLines();  // Verify Tracking Lines in PostedItemTrackingLinesHandler.
        VerifyTrackingOnPurchaseLineAfterUndo(PurchaseLine, TempReservationEntry.Count);
    end;

    local procedure PostSalesDocument(SalesLine: Record "Sales Line"; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, Invoice);
    end;

    local procedure PostSalesReturnOrderAndUndoReturnReceipt(var SalesLine: Record "Sales Line")
    var
        TempReservationEntry: Record "Reservation Entry" temporary;
        DummyValue: Variant;
    begin
        CreateAndPostSalesReturnOrderWithTracking(TempReservationEntry, true, 1, '');
        FindSalesLine(SalesLine, SalesLine."Document Type"::"Return Order", TempReservationEntry."Item No.");
        LibraryVariableStorage.Dequeue(DummyValue);  // Dequeue dummy value to balance blank Enqueued value.
        LibraryVariableStorage.Enqueue(UndoReturnReceiptMessage);  // Enqueue value for ConfirmHandler.
        UndoReturnReceipt(SalesLine);
    end;

    local procedure PurchaseInvoiceItemChargeAssign(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; AppliesToDocType: Enum "Purchase Applies-to Document Type"; DocumentNo: Code[20]; LineNo: Integer; No: Code[20])
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(),
          LibraryRandom.RandInt(5), LibraryRandom.RandDec(10, 2));  // Use Random value for Direct Unit Cost and Quantity.
        LibraryInventory.CreateItemChargeAssignPurchase(ItemChargeAssignmentPurch, PurchaseLine, AppliesToDocType, DocumentNo, LineNo, No);
    end;

    local procedure PostPurchaseAndSalesOrderWithTracking(var SalesLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        DummyValue: Variant;
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        CreateAndPostPurchaseDocumentWithTracking(
          TempReservationEntry, PurchaseLine."Document Type"::Order, CreateTrackedItem(true, '', LibraryUtility.GetGlobalNoSeriesCode()), '', 1);  // 1 is Sign Factor.
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, TempReservationEntry."Item No.");
        LibraryVariableStorage.Dequeue(DummyValue);  // Dequeue dummy value to balance blank Enqueued value.
        CreateSalesOrderWithTracking(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity, TrackingOption::SelectEntries);
        PostSalesDocument(SalesLine, false);  // False for Invoice.
        EnqueueValuesForPostedItemTrackingLines(TempReservationEntry, UndoShipmentMessage, 1);  // Enqueue value for PostedItemTrackingLinesHandler.
    end;

    local procedure SalesInvoiceItemChargeAssign(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; AppliesToDocType: Enum "Sales Applies-to Document Type"; DocumentNo: Code[20]; LineNo: Integer; No: Code[20])
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(),
          LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Price.
        SalesLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignment(ItemChargeAssignmentSales, SalesLine, AppliesToDocType, DocumentNo, LineNo, No);
    end;

    local procedure UpdateProductionBOMOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UndoMultiplePurchaseReceiptLines(PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FilterForReceiptLine(PurchRcptLine, PurchaseLine, ItemNo);
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    local procedure UndoMultipleReturnReceiptLines(SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        FilterForReturnReceiptLine(ReturnReceiptLine, SalesLine, ItemNo);
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);
    end;

    local procedure UndoMultipleReturnShipmentLines(PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        FilterForReturnShipmentLine(ReturnShipmentLine, PurchaseLine, ItemNo);
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);
    end;

    local procedure UndoMultipleShipmentLines(SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        FilterForShipmentLine(SalesShipmentLine, SalesLine, ItemNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UndoPurchaseReceipt(PurchaseLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FindReceiptLine(PurchRcptLine, PurchaseLine, 1);  // 1 is Sign Factor.
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    local procedure UndoReturnReceipt(SalesLine: Record "Sales Line")
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        FindReturnReceiptLine(ReturnReceiptLine, SalesLine, 1);  // 1 is Sign Factor.
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);
    end;

    local procedure UndoReturnShipment(PurchaseLine: Record "Purchase Line")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine, 1);  // 1 is Sign Factor.
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);
    end;

    local procedure UndoSalesShipment(SalesLine: Record "Sales Line")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        FindShipmentLine(SalesShipmentLine, SalesLine, 1);  // 1 is Sign Factor.
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure CreateProductionOrderAndPostConsumptionOutput(var ItemJournalLine: Record "Item Journal Line"; TemplateType: Enum "Item Journal Template Type")
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
    begin
        // Create Item and Post Item Journal Line.
        CreateAndPostItemJournalLine(
          ItemJournalLine, CreateItem(Item."Replenishment System"::Purchase), ItemJournalTemplate.Type::Item,
          ItemJournalLine."Entry Type"::"Positive Adjmt.");

        // Create Production BOM and update Production Item.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ItemJournalLine."Item No.", ItemJournalLine."Unit of Measure Code");
        Item.Get(CreateItem(Item."Replenishment System"::"Prod. Order"));
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");

        // Create Production Order and Post Item Journal for Consumption/Output.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ItemJournalLine.Quantity);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.", TemplateType, ItemJournalLine."Entry Type"::"Negative Adjmt.");
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; Open: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, ItemNo, 0, Open);  // 0 for Sales Amount (Actual).
        FindItemLedgerEntry(ItemLedgerEntry2, ItemLedgerEntry."Entry Type"::Sale, ItemNo, 0, true);  // 0 for Sales Amount (Actual).
        ItemLedgerEntry.TestField("Cost Amount (Actual)", -ItemLedgerEntry2."Cost Amount (Actual)");
    end;

    local procedure VerifyReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line"; QuantitySignFactor: Integer)
    begin
        FindReceiptLine(PurchRcptLine, PurchaseLine, QuantitySignFactor);
        PurchRcptLine.TestField(Correction, true);
    end;

    local procedure VerifyReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line"; QuantitySignFactor: Integer)
    begin
        FindReturnReceiptLine(ReturnReceiptLine, SalesLine, QuantitySignFactor);
        ReturnReceiptLine.TestField(Correction, true);
    end;

    local procedure VerifyReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; PurchaseLine: Record "Purchase Line"; QuantitySignFactor: Integer)
    begin
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine, QuantitySignFactor);
        ReturnShipmentLine.TestField(Correction, true);
    end;

    local procedure VerifyReceiptLineWithValueEntry(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line"; QuantitySignFactor: Integer; ValueQuantitySignFactor: Integer; "Count": Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        VerifyReceiptLine(PurchRcptLine, PurchaseLine, QuantitySignFactor);
        VerifyValueEntry(
          ValueEntry."Document Type"::"Purchase Receipt", PurchRcptLine."No.", PurchRcptLine."Line No.",
          ValueQuantitySignFactor * PurchRcptLine.Quantity / Count);
    end;

    local procedure VerifyReturnReceiptLineWithValueEntry(var ReturnReceiptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line"; QuantitySignFactor: Integer; ValueQuantitySignFactor: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        VerifyReturnReceiptLine(ReturnReceiptLine, SalesLine, QuantitySignFactor);
        VerifyValueEntry(
          ValueEntry."Document Type"::"Sales Return Receipt", ReturnReceiptLine."No.", ReturnReceiptLine."Line No.",
          ValueQuantitySignFactor * ReturnReceiptLine.Quantity / SalesLine.Quantity);
    end;

    local procedure VerifyReturnShipmentLineWithValueEntry(var ReturnShipmentLine: Record "Return Shipment Line"; PurchaseLine: Record "Purchase Line"; QuantitySignFactor: Integer; ValueQuantitySignFactor: Integer; "Count": Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        VerifyReturnShipmentLine(ReturnShipmentLine, PurchaseLine, QuantitySignFactor);
        VerifyValueEntry(
          ValueEntry."Document Type"::"Purchase Return Shipment", ReturnShipmentLine."No.", ReturnShipmentLine."Line No.",
          ValueQuantitySignFactor * ReturnShipmentLine.Quantity / Count);
    end;

    local procedure VerifyShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; QuantitySignFactor: Integer)
    begin
        FindShipmentLine(SalesShipmentLine, SalesLine, QuantitySignFactor);
        SalesShipmentLine.TestField(Correction, true);
    end;

    local procedure VerifyShipmentLineWithValueEntry(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; QuantitySignFactor: Integer; ValueQuantitySignFactor: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        VerifyShipmentLine(SalesShipmentLine, SalesLine, QuantitySignFactor);
        VerifyValueEntry(
          ValueEntry."Document Type"::"Sales Shipment", SalesShipmentLine."No.", SalesShipmentLine."Line No.",
          ValueQuantitySignFactor * SalesShipmentLine.Quantity / SalesLine.Quantity);
    end;

    local procedure VerifyTrackingOnPurchaseLineAfterUndo(PurchaseLine: Record "Purchase Line"; "Count": Integer)
    var
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verification done in ItemTrackingLinesPageHandler. Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryVariableStorage.Enqueue(TrackingOption::ShowEntries);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        LibraryVariableStorage.Enqueue(Count);
        LibraryVariableStorage.Enqueue(AvailabilityWarning);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure VerifyTrackingOnSalesLineAfterUndo(SalesLine: Record "Sales Line")
    var
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verification done in ItemTrackingLinesPageHandler. Enqueue values for ItemTrackingLinesPageHandler.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        LibraryVariableStorage.Enqueue(TrackingOption::ShowEntries);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        LibraryVariableStorage.Enqueue(AvailabilityWarning);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure VerifyValueEntry(DocumentType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; DocumentLineNo: Integer; ValuedQuantity: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, ItemNo, DocumentType, DocumentLineNo);
        ValueEntry.FindSet();
        repeat
            ValueEntry.TestField("Valued Quantity", ValuedQuantity);
        until ValueEntry.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Iteration: Variant;
        OptionValue: Variant;
        Quantity: Variant;
        "Count": Integer;
        IterationCount: Integer;
        OptionString: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
        QuantityToHandle: Integer;
        TrackingOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        TrackingOption := OptionValue;  // To convert Variant into Option.
        case TrackingOption of
            OptionString::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            OptionString::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            OptionString::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            OptionString::ShowEntries:
                begin
                    LibraryVariableStorage.Dequeue(Quantity);  // Dequeue variable.
                    QuantityToHandle := Quantity;  // To convert Variant into Integer.
                    LibraryVariableStorage.Dequeue(Iteration);  // Dequeue variable.
                    IterationCount := Iteration;  // To convert Variant into Integer.
                    ItemTrackingLines.First();
                    for Count := 1 to IterationCount do begin
                        ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(QuantityToHandle / IterationCount);
                        ItemTrackingLines.Next();
                    end;
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    var
        OptionValue: Variant;
        OptionString: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
        TrackingOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        TrackingOption := OptionValue;  // To convert Variant into Option.
        case TrackingOption of
            OptionString::VerifyEntries:
                ItemTrackingSummary."Serial No.".AssertEquals('');  // Blank Serial No. as no Item Tracking Lines found.
            OptionString::SelectEntries:
                ItemTrackingSummary.OK().Invoke();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    var
        Quantity: Variant;
        TrackingCode: Variant;
    begin
        PostedItemTrackingLines.First();
        repeat
            LibraryVariableStorage.Dequeue(TrackingCode);  // Dequeue variable.
            LibraryVariableStorage.Dequeue(Quantity);  // Dequeue variable.
            PostedItemTrackingLines."Serial No.".AssertEquals(TrackingCode);
            PostedItemTrackingLines.Quantity.AssertEquals(Quantity);
        until not PostedItemTrackingLines.Next();
        PostedItemTrackingLines.OK().Invoke();
    end;
}

