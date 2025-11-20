codeunit 137158 "SCM Orders V"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationBlue: Record Location;
        LocationRed: Record Location;
        LocationYellow: Record Location;
        LocationInTransit: Record Location;
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryResource: Codeunit "Library - Resource";
        isInitialized: Boolean;
        UndoReceiptMsg: Label 'Do you really want to undo the selected Receipt lines?';
        AmountMustBeEqualErr: Label 'Amount must be equal.';
        FieldShouldNotBeEditableErr: Label 'Field should not be editable.';
        FieldShouldBeEditableErr: Label 'Field should be editable.';
        ChangeBillToCustomerNoConfirmQst: Label 'Do you want to change';
        QuantityToAssembleErr: Label 'Quantity to Assemble cannot be higher than the Remaining Quantity, which is %1.', Comment = '%1 = Quantity Value';
        AvailabilityWarningsConfirmMsg: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        OrderDateOnSalesHeaderMsg: Label 'You have changed the Order Date on the sales header, which might affect the prices and discounts on the sales lines. You should review the lines and manually update prices and discounts if needed.';
        NoGLEntryWithinFilterErr: Label 'There is no G/L Entry within the filter';
        ReservationEntryExistMsg: Label 'One or more reservation entries exist for the item';
        QuantityBaseErr: Label 'Quantity (Base) is not sufficient to complete this action';
        QuantityMustBeSameErr: Label 'Quantity must be same.';
        ExtendedTxt: Label 'Extended text of the BOM component.';
        ItemTrackingMode: Option AssignLotNo,SelectEntries,AssignSerialNo,UpdateQtyOnFirstLine,UpdateQtyOnLastLine,VerifyLot,AssignGivenLotNos,UpdateLotQty,"Set Lot No.","Get Lot Quantity";
        UndoReturnShipmentMsg: Label 'Do you really want to undo the selected Return Shipment lines?';
        SpecialOrderSalesNoErr: Label 'Special Order Sales No in Purchase Line must be equal to Sales Order No';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        WrongNoOfDocumentsListErr: Label 'There must be %1 documents in the list.';
        PostedSalesDocType: Option "Posted Shipments","Posted Invoices","Posted Return Receipts","Posted Cr. Memos";
        SalesHeaderErr: Label 'You cannot delete the order line because it is associated with purchase order';
        MustBeDeletedErr: Label 'Sales order %1 must be deleted';
        ItemTrackingNotMatchErr: Label 'Item Tracking does not match';
        QtyToInvoiceDoesNotMatchItemTrackingErr: Label 'The quantity to invoice does not match the quantity defined in item tracking.';
        WrongLotQtyOnPurchaseLineErr: Label 'Wrong lot quantity in Item Tracking on Purchase Line.';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';

    [Test]
    [Scope('OnPrem')]
    procedure ChangeExpectedReceiptDateOnPurchaseOrderReservedAgainstSalesOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        NewExpectedReceiptDate: Date;
    begin
        // [FEATURE] [Reservation] [Expected Receipt Date]
        // [SCENARIO 244862] It should be possible to change the Expected Delivery date on Purchase order after updating reservation on sales order

        // [GIVEN] Create Purchase Order. Create Sales Order and Reserve Quantity.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Item."No.", LibraryRandom.RandDec(10, 2), '', false);
        UpdateExpectedReceiptDateOnPurchaseLine(PurchaseLine, WorkDate());  // Updating Expected Receipt Date on Purchase Line for Reservation on Sales Line.
        CreateSalesOrder(SalesHeader, '', Item."No.", PurchaseLine.Quantity, '', true);  // Reserve as TRUE
        NewExpectedReceiptDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());  // Must be less than WorkDate.

        // [WHEN] Update Expected Receipt Date on Purchase Line.
        UpdateExpectedReceiptDateOnPurchaseLine(PurchaseLine, NewExpectedReceiptDate);

        // [THEN] Verify Expected Receipt Date on Purchase Line.
        PurchaseLine.TestField("Expected Receipt Date", NewExpectedReceiptDate);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure GetSpecialSalesOrderFromPurchaseOrderWithDifferentShipToCode()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesShipToCode: Code[20];
        PurchaseShipToCode: Code[20];
    begin
        // [FEATURE] [Special Order]
        // [SCENARIO 360247.1] Ship-to error on multi line purchase order (special order) that is linked to multiple special orders with different "Ship-to Code"
        Initialize();

        // [GIVEN] Create Customer and Ship to Address. Create Sales Order with Special Order. Create Purchase Header with Sell to Customer No. and different Ship-to Code
        CreateSpecialSaleOrderAndPurchaseOrderWithDifferentShipToCode(PurchaseHeader, SalesShipToCode, PurchaseShipToCode);

        // [WHEN] Get Sales Order for Special Order.
        asserterror LibraryPurchase.GetSpecialOrder(PurchaseHeader);

        // [THEN] Verify Different Ship-to Code error message
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption("Ship-to Code"), '');
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure GetSpecialSalesOrderFromPurchaseOrderWithShipToCodeBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Special Order]
        // [SCENARIO 360247.2] Ship-to error on multi line purchase order (special order) that is linked to multiple special orders with blank "Ship-to Code"
        Initialize();

        // [GIVEN] Create Customer and Ship to Address. Create Sales Order with Special Order. Create Purchase Header with Sell to Customer No. and empty Ship-to Code
        CreateSpecialSaleOrderAndPurchaseOrder(PurchaseHeader, SalesHeaderNo);

        // [WHEN] Get Sales Order for Special Order.
        LibraryPurchase.GetSpecialOrder(PurchaseHeader);

        // [THEN] Verify that Purchase Line has correct Sales Orders No
        VerifyPurchLineHasCorrectSalesOrdersNo(PurchaseHeader."No.", SalesHeaderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlannedReceiptDateOnPurchaseLineUsingLeadTimeCalculation()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Lead Time] [Purchase]
        // [SCENARIO 135586] Test the Lead Time Calculation and Planned Receipt Date on Purchase Line after Updating Lead Time Calculation on Purchase Header.

        // [GIVEN] Create Purchase Header with Lead Time Calculation.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseHeaderWithLeadTimeCalculation(PurchaseHeader);

        // [WHEN] Create Purchase Line.
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item."No.", LibraryRandom.RandDec(10, 2), '', false);  // Use Tracking as FALSE.

        // [THEN] Verify Lead Time Calculation and Planned Receipt Date calculated from Lead Time Calculation and Order Date on Purchase Line.
        PurchaseLine.TestField("Lead Time Calculation", PurchaseHeader."Lead Time Calculation");
        PurchaseLine.TestField("Planned Receipt Date", CalcDate(PurchaseHeader."Lead Time Calculation", PurchaseHeader."Order Date"));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptWithAndWithoutLotItemTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DequeueVariable: Variant;
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // [FEATURE] [Undo Purchase Receipt] [Item Tracking]
        // [SCENARIO 135535] Test the Receipt Line and Item Ledger Entry after Post Purchase Order as Receive with multiple Lines with Lot Item Tracking on Single Line and Undo Purchase Receipt.

        // [GIVEN] Create Item with Lot Item Tracking Code. Create and Post Purchase Order with multiple Items and assign Tracking on Single Item.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateItemWithItemTrackingCode(Item2, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '');  // True for Lot.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        CreateAndPostPurchaseOrderWithMultipleItems(PurchaseHeader, PurchaseLine, Item."No.", Quantity, Item2."No.");
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LotNo := DequeueVariable;

        // [WHEN] Undo Purchase Receipt.
        UndoPurchaseReceipt(PurchaseLine."Document No.", Item."No.", Item2."No.");

        // [THEN] Verify Receipt Line and Item Ledger Entry.
        VerifyReceiptLineAfterUndo(PurchaseLine."Document No.", Item."No.", Item2."No.", Quantity);
        VerifyItemLedgerEntryForLot(ItemLedgerEntry."Entry Type"::Purchase, Item2."No.", LotNo, Quantity, false);  // Use MoveNext as FALSE.
        VerifyItemLedgerEntryForLot(ItemLedgerEntry."Entry Type"::Purchase, Item2."No.", LotNo, -Quantity, true);  // Use MoveNext as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculatePlanOnRequistionWorkSheetAfterSalesOrderWithCurrency()
    begin
        // [FEATURE] [Requisition Worksheet] [Currency]
        // [SCENARIO 263291] Test to verify Currency Factor on Requisition Worksheet after Calculate Plan with Sales Order.

        Initialize();
        CalculatePlanAndCarryOutActionMessageOnRequisitionWorkSheetWithCurrency(false);  // CarryOutActionMessage as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderAfterCarryOutActionMessageOnRequisitionWorkSheetWithCurrency()
    begin
        // [FEATURE] [Requisition Worksheet] [Currency]
        // [SCENARIO 263291] Test to post Purchase Order created after Calculate Plan and Carry out Action Message on Requisition Worksheet after creating Sales Order with Currency.

        Initialize();
        CalculatePlanAndCarryOutActionMessageOnRequisitionWorkSheetWithCurrency(true);  // CarryOutActionMessage as TRUE.
    end;

    local procedure CalculatePlanAndCarryOutActionMessageOnRequisitionWorkSheetWithCurrency(CarryOutActionMessage: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        CurrencyFactor: Decimal;
        DocumentNo: Code[20];
    begin
        // Create Currency with different exchange rate. Create Sales Order with Currency Code.
        CurrencyFactor := CreateVendorWithCurrencyExchangeRate(Vendor);
        CreateItemWithVendorNoAndReorderingPolicy(Item, Vendor."No.", Item."Reordering Policy"::Order);
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesHeader, Customer."No.", Item."No.", LibraryRandom.RandInt(100), LocationBlue.Code, false);

        LibraryPlanning.CalcRequisitionPlanForReqWkshAndGetLines(
          RequisitionLine, Item, CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'Y>', WorkDate()),
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));

        // Verify.
        RequisitionLine.TestField("Currency Factor", CurrencyFactor);

        if CarryOutActionMessage then begin
            // Exercise.
            LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
            VendorPostingGroup.Get(Vendor."Vendor Posting Group");
            GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
            UpdateUnitCostOnPurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
            DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

            // Verify.
            VerifyGLEntry(DocumentNo, GeneralPostingSetup."Purch. Account", PurchaseLine."Line Amount" / CurrencyFactor);  // Value required for the test.
            VerifyGLEntry(DocumentNo, VendorPostingGroup."Payables Account", -PurchaseLine."Amount Including VAT" / CurrencyFactor);  // Value required for the test.
        end;
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceAfterPurchaseOrderOfPartialQuantityFromBlanketOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Blanket Order] [Invoice]
        // [SCENARIO 229614] Test the Purchase Invoice Line after Purchase Order Created from Blanket Order with Partial Quantity. And Purchase Invoice created from Get Receipt Line.

        // [GIVEN] Create Purchase Order with Partial Quantity from Blanket Purchase Order. Post Purchase Order. Get Receipt Line on Purchase Invoice. Create Purchase Order with Remaining Quantity from Blanket Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreatePurchaseOrderFromBlanketPurchaseOrderWithPartialQuantity(PurchaseHeader, Item."No.", Quantity);
        PostPurchaseOrder(PurchaseHeader."Buy-from Vendor No.");
        GetReceiptLineOnPurchaseInvoice(PurchaseHeader2, PurchaseHeader."Buy-from Vendor No.");
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // [WHEN] Post Purchase Invoice.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, false, false);

        // [THEN] Verify Purchase Invoice Line.
        VerifyPurchaseInvoiceLine(PostedDocumentNo, Item."No.", Quantity / 2);  // Calculated Value Required.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithNegativeLineAndApplyFromItemEntry()
    begin
        // [FEATURE] [Sales] [Applies-from Entry]
        // [SCENARIO 298819] Test the Item Ledger Entry after Post Sales Order with Negative Line and Update Apply From Item Entry on Sales Line.

        Initialize();
        PostSalesOrderWithNegativeLineAndGetPostedDocumentLinesOnSalesReturnOrder(false);  // Post Sales Return Order as FALSE.
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocumentLinesToReverseOnSalesReturnOrder()
    begin
        // [FEATURE] [Sales Return] [Get Posted Document Lines To Reverse]
        // [SCENARIO 298819] Test the Item Ledger Entry after Post Sales Return Order with Get Posted Document Lines To reverse on Sales Return Order.

        Initialize();
        PostSalesOrderWithNegativeLineAndGetPostedDocumentLinesOnSalesReturnOrder(true);  // Post Sales Return Order as TRUE.
    end;

    local procedure PostSalesOrderWithNegativeLineAndGetPostedDocumentLinesOnSalesReturnOrder(PostSalesReturnOrder: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        OldExactCostReversingMandatory: Boolean;
        PostedDocumentNo: Code[20];
        PostedDocumentNo2: Code[20];
        PostedDocumentNo3: Code[20];
        Quantity: Decimal;
    begin
        // Update Exact Cost Reversing Mandatory On Sales and Receivable Setup. Create and Post Sales Order. Reopen Sales Order. Add Negative Sales Line and Apply from Item Entry.
        OldExactCostReversingMandatory := UpdateExactCostReversingMandatoryOnSalesReceivableSetup(true);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo := CreateAndPostSalesOrder(SalesHeader, Item."No.", Quantity, LocationRed.Code);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        CreateNegativeSalesLineAndApplyFromItemEntry(SalesHeader, SalesLine, Item."No.", -Quantity, LocationRed.Code, PostedDocumentNo);

        // Exercise: Post Sales Order.
        PostedDocumentNo2 := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Ship as TRUE.

        // Verify: Verify Item Ledger Entry.
        VerifyItemLedgerEntryForPostedDocument(
          ItemLedgerEntry."Document Type"::"Sales Shipment", ItemLedgerEntry."Entry Type"::Sale, PostedDocumentNo, Item."No.", -Quantity,
          -Quantity);
        VerifyItemLedgerEntryForPostedDocument(
          ItemLedgerEntry."Document Type"::"Sales Shipment", ItemLedgerEntry."Entry Type"::Sale, PostedDocumentNo2, Item."No.", Quantity,
          Quantity);

        if PostSalesReturnOrder then begin
            // Exercise: Create and Post Sales Return Order with Get Posted Document Lines to Reserve.
            PostedDocumentNo3 := CreateAndPostSalesReturnOrderWithGetPostedDocumentLinesToReverse(SalesHeader."Sell-to Customer No.");

            // Verify: Verify Item Ledger Entry.
            VerifyItemLedgerEntryForPostedDocument(
              ItemLedgerEntry."Document Type"::"Sales Shipment", ItemLedgerEntry."Entry Type"::Sale, PostedDocumentNo, Item."No.", -Quantity,
              -Quantity);
            VerifyItemLedgerEntryForPostedDocument(
              ItemLedgerEntry."Document Type"::"Sales Shipment", ItemLedgerEntry."Entry Type"::Sale, PostedDocumentNo2, Item."No.", 0,
              Quantity);  // Value required for test
            VerifyItemLedgerEntryForPostedDocument(
              ItemLedgerEntry."Document Type"::"Sales Return Receipt", ItemLedgerEntry."Entry Type"::Sale, PostedDocumentNo3, Item."No.", 0,
              -Quantity);  // Value required for test.
        end;

        // Tear Down.
        UpdateExactCostReversingMandatoryOnSalesReceivableSetup(OldExactCostReversingMandatory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithNegativeLineAndApplyToItemEntry()
    begin
        // [FEATURE] [Purchase Return] [Applies-to Entry]
        // [SCENARIO 298819] Test the Item Ledger Entry after Post Purchase Order with Negative Line and Update Apply to Item Entry on Purchase Line.

        Initialize();
        PostPurchaseOrderWithNegativeLineAndGetPostedDocumentLinesOnPurchaseReturnOrder(false);  // Post Purchase Return Order as FALSE.
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocumentLinesToReverseOnPurchaseReturnOrder()
    begin
        // [FEATURE] [Purchase Return] [Get Posted Document Lines To Reverse]
        // [SCENARIO 298819] Test the Item Ledger Entry after Post Purchase Return Order with Get Posted Document Lines To reverse on Purchase Return Order.

        Initialize();
        PostPurchaseOrderWithNegativeLineAndGetPostedDocumentLinesOnPurchaseReturnOrder(true);  // Post Purchase Return Order as TRUE.
    end;

    local procedure PostPurchaseOrderWithNegativeLineAndGetPostedDocumentLinesOnPurchaseReturnOrder(PostPurchaseReturnOrder: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        OldExactCostReversingMandatory: Boolean;
        PostedDocumentNo: Code[20];
        PostedDocumentNo2: Code[20];
        PostedDocumentNo3: Code[20];
        Quantity: Decimal;
    begin
        // Update Exact Cost Reversing Mandatory On Purchase and Payable Setup. Create and Post Purchase Order. Reopen Purchase Order. Add Negative Purchase Line and Apply to Item Entry.
        OldExactCostReversingMandatory := UpdateExactCostReversingMandatoryOnPurchaseSetup(true);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo := CreateAndPostPurchaseOrder(PurchaseHeader, Item."No.", Quantity, LocationRed.Code);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        CreateNegativePurchaseLineAndApplyToItemEntry(
          PurchaseHeader, PurchaseLine, Item."No.", -Quantity, LocationRed.Code, PostedDocumentNo);

        // Exercise: Post Purchase Order.
        PostedDocumentNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Receive as TRUE.

        // Verify: Verify Item Ledger Entry.
        VerifyItemLedgerEntryForPostedDocument(
          ItemLedgerEntry."Document Type"::"Purchase Receipt", ItemLedgerEntry."Entry Type"::Purchase, PostedDocumentNo, Item."No.", 0,
          Quantity);
        VerifyItemLedgerEntryForPostedDocument(
          ItemLedgerEntry."Document Type"::"Purchase Receipt", ItemLedgerEntry."Entry Type"::Purchase, PostedDocumentNo2, Item."No.", 0,
          -Quantity);

        if PostPurchaseReturnOrder then begin
            // Exercise: Post Purchase Return Order with Get Posted Document Lines to Reserve.
            PostedDocumentNo3 := CreateAndPostPurchaseReturnOrderWithGetPostedDocumentLinesToReverse(PurchaseHeader."Buy-from Vendor No.");

            // Verify: Verify Item Ledger Entry.
            VerifyItemLedgerEntryForPostedDocument(
              ItemLedgerEntry."Document Type"::"Purchase Receipt", ItemLedgerEntry."Entry Type"::Purchase, PostedDocumentNo, Item."No.", 0,
              Quantity);
            VerifyItemLedgerEntryForPostedDocument(
              ItemLedgerEntry."Document Type"::"Purchase Receipt", ItemLedgerEntry."Entry Type"::Purchase, PostedDocumentNo2, Item."No.", 0,
              -Quantity);
            VerifyItemLedgerEntryForPostedDocument(
              ItemLedgerEntry."Document Type"::"Purchase Return Shipment", ItemLedgerEntry."Entry Type"::Purchase, PostedDocumentNo3,
              Item."No.", Quantity, Quantity);
        end;

        // Tear Down.
        UpdateExactCostReversingMandatoryOnPurchaseSetup(OldExactCostReversingMandatory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseAsInTransitBecomesUneditableAfterCreateAndReleaseTransferOrder()
    begin
        // [FEATURE] [Location] [Transit Location] [Transfer Order]
        // [SCENARIO 264085] Test and verify Use as in-Transit is Un-editable after create and release Transfer Order.

        Initialize();
        CreateAndPostTransferOrderAfterPostPurchaseOrderWithLocationInTransit(false);  // PostTransferOrder as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseAsInTransitBecomesEditableAfterPostTransferOrderAsReceive()
    begin
        // [FEATURE] [Location] [Transit Location] [Transfer Order]
        // [SCENARIO 264085] Test and verify Use as in-Transit is Editable after post Transfer Order as Receive.

        Initialize();
        CreateAndPostTransferOrderAfterPostPurchaseOrderWithLocationInTransit(true);  // PostTransferOrder as TRUE.
    end;

    local procedure CreateAndPostTransferOrderAfterPostPurchaseOrderWithLocationInTransit(PostTransferOrder: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
    begin
        // Create and Post Purchase Order as Receive and Invoice.
        CreateItemWithVendorNoAndReorderingPolicy(Item, '', Item."Reordering Policy"::" ");
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Item."No.", LibraryRandom.RandDec(10, 2), LocationBlue.Code, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as RECEIVE and INVOICE.

        // Exercise.
        CreateAndReleaseTransferOrder(TransferHeader, LocationBlue.Code, LocationRed.Code, Item."No.", PurchaseLine.Quantity);

        // Verify.
        VerifyEditablePropertyOfUseAsInTransitFieldOnLocationCard(LocationInTransit.Code, false);

        if PostTransferOrder then begin
            // Exercise.
            PostAllTransferOrdersWithLocationInTransit();  // Posting of All Transfers Orders is required for verification of this test.

            // Verify.
            VerifyEditablePropertyOfUseAsInTransitFieldOnLocationCard(LocationInTransit.Code, true);  // Editable as TRUE.
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreatePageHandler,SalesListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostingPurchaseOrderForDifferentSerialNoOfSalesOrderWithDropShipment()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SerialNo: Variant;
    begin
        // [FEATURE] [Purchase] [Item Tracking] [Drop Shipment]
        // [SCENARIO 267057] Test and verify error on posting Purchase Order for different Serial No of Sales Order with Drop Shipment.

        // [GIVEN] Create Purchase Order with Get Drop Shipment from Sales Order with Serial Item Tracking.
        // [GIVEN] Both sales and purchase order have "Quantity" = 2 and two serial numbers assigned: "SN1" and "SN2"
        Initialize();
        CreateSalesOrderWithDropShipmentAndSerialItemTracking(SalesHeader, SalesLine);
        LibraryVariableStorage.Dequeue(SerialNo);
        CreatePurchaseOrderWithGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [GIVEN] Update Quantity to Invoice on the sales line from 2 to 1. Open item tracking lines and set "Qty. to Invoice" = 0 for serial number "SN2"
        UpdateQuantityToInvoiceOnSalesAndItemTrackingLine(SalesLine, SalesLine.Quantity - 1);  // Value required for the test.

        // [GIVEN] Update Quantity to Invoice on the purchase line from 2 to 1. Open item tracking lines and set "Qty. to Invoice" = 0 for serial number "SN1"
        UpdateQuantityToInvoiceOnPurchaseAndItemTrackingLine(SalesLine."No.", SalesLine.Quantity - 1);  // Value required for the test.

        // [WHEN] Post the sales order
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posting fails with an error reading that item tracking is not synchronized
        Assert.ExpectedError(ItemTrackingNotMatchErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderAsInvoiceWithDifferentBillToCustomer()
    begin
        // [FEATURE] [Sales] [Bill-to Customer]
        // [SCENARIO 237016] Test and verify posting of Sales Order as Invoice with different Bill-to Customer.

        Initialize();
        PostSalesCreditMemoAgainstSalesReturnOrderWithDifferentBillToCustomer(false, false);  // SalesReturnOrder and SalesCreditMemo as FALSE.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderWithGetPostedDocLinesToReverseWithDifferentBillToCustomer()
    begin
        // [FEATURE] [Sales Return] [Bill-to Customer] [Get Posted Document lines to Reverse]
        // [SCENARIO 237016] Test and verify posting of Sales Return Order with Get Posted Document lines to reverse with different Bill-to Customer.

        Initialize();
        PostSalesCreditMemoAgainstSalesReturnOrderWithDifferentBillToCustomer(true, false);  // SalesReturnOrder as TRUE and SalesCreditMemo as FALSE.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoWithGetPostedDocLinesToReverseWithDifferentBillToCustomer()
    begin
        // [FEATURE] [Sales] [Credit Memo] [Get Posted Document lines to Reverse] [Bill-to Customer]
        // [SCENARIO 237016] Test and verify posting of Sales Credit Memo with Get Posted Document lines to reverse with different Bill-to Customer.

        Initialize();
        PostSalesCreditMemoAgainstSalesReturnOrderWithDifferentBillToCustomer(true, true);  // SalesReturnOrder and SalesCreditMemo as TRUE.
    end;

    local procedure PostSalesCreditMemoAgainstSalesReturnOrderWithDifferentBillToCustomer(SalesReturnOrder: Boolean; SalesCreditMemo: Boolean)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
    begin
        // Create Sales Order with different Bill to Customer.
        CreateSalesOrderWithDifferentBillToCustomerNo(SalesHeader, SalesLine, Customer, Item);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        VATPostingSetup.Get(Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");

        // Exercise.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as SHIP and INVOICE.

        // Verify.
        VerifyGLEntry(PostedDocumentNo, GeneralPostingSetup."Sales Account", -SalesLine."Line Amount");
        VerifyGLEntry(PostedDocumentNo, VATPostingSetup."Sales VAT Account", -SalesLine."Line Amount" * SalesLine."VAT %" / 100);  // Value required for verification.
        VerifyGLEntry(PostedDocumentNo, CustomerPostingGroup."Receivables Account", SalesLine."Amount Including VAT");

        if SalesReturnOrder then begin
            // Exercise.
            CreateAndPostSalesReturnOrderWithGetPostedDocumentLinesToReverse(Customer."No.");

            // Verify.
            VerifyItemLedgerEntryForLot(ItemLedgerEntry."Entry Type"::Sale, Item."No.", '', -SalesLine.Quantity, false);
        end;

        if SalesCreditMemo then begin
            // Exercise.
            PostedDocumentNo := CreateAndPostSalesCreditMemoWithGetPostedDocLinesToReverse(SalesLine, Customer."No.", Item."No.");

            // Verify.
            VerifyGLEntry(PostedDocumentNo, GeneralPostingSetup."Sales Account", SalesLine."Line Amount");
            VerifyGLEntry(PostedDocumentNo, VATPostingSetup."Sales VAT Account", SalesLine."Line Amount" * SalesLine."VAT %" / 100);  // Value required for verification.
            VerifyGLEntry(PostedDocumentNo, CustomerPostingGroup."Receivables Account", -SalesLine."Amount Including VAT");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateDescriptionOnTaskCardOfSameOrganizerTaskOfContactByPage()
    var
        Contact: Record Contact;
        Description: Variant;
    begin
        // [FEATURE] [Task] [UI]
        // [SCENARIO 268715] Test and verify Description gets updated on all Tasks of same Organizer Task of Contact by updating one Task card by page.

        // Setup: Create Contact. Create two Task for the Contact.
        Initialize();
        CreateContactWithTasks(Contact);
        Description := LibraryUtility.GenerateGUID();

        // Exercise: Update Description on Task Card opened from Task list page.
        OpenTaskListPageFromContactCard(Contact."No.", Description);

        // Verify: Description gets updated on both Tasks of the Contact.
        VerifyDescriptionOnTask(Contact."No.", Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenCommentsFromTaskCardPage()
    var
        Contact: Record Contact;
        Task: Record "To-do";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
    begin
        // [FEATURE] [Task] [UI]
        // [SCENARIO 363277] Open comments from the Task Card page the link is set to the organizer Task.
        Initialize();
        // [GIVEN] Contact and Task for the Contact.
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateAndUpdateTask(Task, Contact);

        // [GIVEN] Comment "X" for Task.
        LibraryMarketing.CreateRlshpMgtCommentLine(RlshpMgtCommentLine, RlshpMgtCommentLine."Table Name"::"To-do", Task."No.", 0);
        RlshpMgtCommentLine.Validate(Comment, LibraryUtility.GenerateGUID());
        RlshpMgtCommentLine.Modify(true);

        // [WHEN] Open page Comment from Task Page.
        OpenCommentPageFromTaskCard(Task, RlshpMgtCommentLine.Comment);
        // [THEN] Page Comment from Task Page shows comment "X".
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingQuantityToAssembleOnAssemblyOrder()
    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
    begin
        // [FEATURE] [Assembly]
        // [SCENARIO 255695] Test and verify Error on updating Quantity to Assemble on Assembly Order.

        // Setup: Create Item. Create Assembly Header.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', LibraryRandom.RandDec(10, 2), '');

        // Exercise.
        asserterror AssemblyHeader.Validate("Quantity to Assemble", AssemblyHeader.Quantity + LibraryRandom.RandDec(10, 2));  // Greater value is required to generate the error.

        // Verify.
        Assert.ExpectedError(StrSubstNo(QuantityToAssembleErr, AssemblyHeader.Quantity));
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure ShipmentMethodOnPurchaseOrderBySpecialSalesOrder()
    begin
        // [FEATURE] [Sales] [Purchase] [Special Order]
        // [SCENARIO 255986] Test and verify Shipment Method on Purchase Order by Special Sales Order.

        Initialize();
        PostPurchaseOrderWithShptMethodBySpecialSalesOrder(false);  // Use False for Posted Purchase Invoice.
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure ShipmentMethodOnPostedPurchInvBySpecialSalesOrder()
    begin
        // [FEATURE] [Sales] [Purchase] [Special Order]
        // [SCENARIO 255986] Test and verify Shipment Method on Posted Purchase Invoice by Special Sales Order.

        Initialize();
        PostPurchaseOrderWithShptMethodBySpecialSalesOrder(true);  // Use True for Posted Purchase Invoice.
    end;

    local procedure PostPurchaseOrderWithShptMethodBySpecialSalesOrder(PostedPurchaseInvoice: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Create Customer and Vendor with Shipment Method. Create Sales Order with Special Order. Create Purchase Order with Sell to Customer.
        LibraryInventory.CreateItem(Item);
        CreateCustomerWithShipmentMethod(Customer);
        CreateVendorWithShipmentMethod(Vendor, Customer."Shipment Method Code");
        CreateSalesOrderWithSpecialOrder(SalesHeader, Customer."No.", '', Item."No.");
        CreatePurchaseHeaderWithSellToCustomerNo(PurchaseHeader, Vendor."No.", SalesHeader."Sell-to Customer No.");

        // Exercise.
        LibraryPurchase.GetSpecialOrder(PurchaseHeader);

        // Verify.
        PurchaseHeader.TestField("Shipment Method Code", Vendor."Shipment Method Code");

        if PostedPurchaseInvoice then begin
            // Exercise.
            DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post Receive and Invoice.

            // Verify.
            PurchInvHeader.Get(DocumentNo);
            PurchInvHeader.TestField("Shipment Method Code", Vendor."Shipment Method Code");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnPostingSalesOrderWithoutExternalDocument()
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 252383] Test and verify Error on Posting Sales Order without External Document.

        Initialize();
        PostSalesOrderWithMultipleSeriesLine(false);  // Use False for without External Document.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithMultipleSeriesLineAndExtDocument()
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 252383] Test and verify Post Sales Order with Multiple Series Line and External Document.

        Initialize();
        PostSalesOrderWithMultipleSeriesLine(true);  // Use True for with External Document.
    end;

    local procedure PostSalesOrderWithMultipleSeriesLine(WithExternalDocumentNo: Boolean)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        NoSeriesLine: Record "No. Series Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // Create Series with different starting dates. Update External Document Mandatory and Posted Invoice Series on Sales Setup. Create Sales Order without External Document.
        SalesReceivablesSetup.Get();
        CreateNoSeriesWithDifferentStartingDates(NoSeriesLine);
        UpdateExtDocNoMandatoryAndPostedInvNosOnSalesSetup(true, NoSeriesLine."Series Code");
        CreateSalesOrderWithoutExternalDocumentNo(SalesHeader, Customer);

        // Exercise.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post Ship and Invoice.

        // Verify.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption("External Document No."), '');

        if WithExternalDocumentNo then begin
            // Exercise.
            PostSalesOrderAfterUpdateDatesWithExternalDocNo(SalesLine, SalesHeader, NoSeriesLine."Starting Date");
            GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
            CustomerPostingGroup.Get(Customer."Customer Posting Group");

            // Tear Down.
            UpdateExtDocNoMandatoryAndPostedInvNosOnSalesSetup(
              SalesReceivablesSetup."Ext. Doc. No. Mandatory", SalesReceivablesSetup."Posted Invoice Nos.");

            // Verify.
            asserterror
              VerifyGLEntry(NoSeriesLine."Starting No.", GeneralPostingSetup."Sales Account", -SalesLine."Line Amount");
            Assert.ExpectedError(NoGLEntryWithinFilterErr);
            asserterror
              VerifyGLEntry(NoSeriesLine."Starting No.", CustomerPostingGroup."Receivables Account", SalesLine."Amount Including VAT");
            Assert.ExpectedError(NoGLEntryWithinFilterErr);
        end;

        // Tear Down.
        UpdateExtDocNoMandatoryAndPostedInvNosOnSalesSetup(
          SalesReceivablesSetup."Ext. Doc. No. Mandatory", SalesReceivablesSetup."Posted Invoice Nos.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithStandardCostItemUsingLot()
    begin
        // [FEATURE] [Purchase] [Item Tracking]
        // [SCENARIO 267967] Test and verify Post Purchase Order with Standard Cost Item using Lot.

        Initialize();
        PostInvtCostAfterPostingPurchaseReturnOrderWithLot(false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyToEntryOnPurchRetOrderWithReverseDocument()
    begin
        // [FEATURE] [Purchase Return] [Applies-to Entry]
        // [SCENARIO 267967] Test and verify Apply to Entry on Purchase Return Order with Reverse Document.

        Initialize();
        PostInvtCostAfterPostingPurchaseReturnOrderWithLot(true, false, false, false);  // Use True for GetPostedDocumentLines.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure LotOnPurchaseReturnOrderWithReverseDocument()
    begin
        // [FEATURE] [Purchase Return] [Item Tracking]
        // [SCENARIO 267967] Test and verify Lot on Purchase Return Order with Reverse Document.

        Initialize();
        PostInvtCostAfterPostingPurchaseReturnOrderWithLot(true, true, false, false);  // Use True for GetPostedDocumentLines and LotAfterGetPostedDocumentLines.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderWithReverseDocument()
    begin
        // [FEATURE] [Purchase Return] [Item Tracking]
        // [SCENARIO 267967] Test and verify Post Purchase Return Order with Reverse Document.

        Initialize();
        PostInvtCostAfterPostingPurchaseReturnOrderWithLot(true, true, true, false);  // Use True for GetPostedDocumentLines, LotAfterGetPostedDocumentLines and PostPurchaseReturnOrder.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,PostedPurchaseDocumentLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryCostAfterPostingPurchaseReturnOrder()
    begin
        // [FEATURE] [Purchase Return] [Item Tracking]
        // [SCENARIO 267967] Test and verify Post Inventory Cost after Posting Purchase Return Order.

        Initialize();
        PostInvtCostAfterPostingPurchaseReturnOrderWithLot(true, true, true, true);  // Use True for GetPostedDocumentLines, LotAfterGetPostedDocumentLines, PostPurchaseReturnOrder and PostCostToGL.
    end;

    local procedure PostInvtCostAfterPostingPurchaseReturnOrderWithLot(GetPostedDocumentLines: Boolean; LotAfterGetPostedDocumentLines: Boolean; PostPurchaseReturnOrder: Boolean; PostCostToGL: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        OldExactCostReversingMandatory: Boolean;
        LotNo: Code[50];
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Create Purchase Order with Standard Cost Item using Lot Item Tracking.
        OldExactCostReversingMandatory := UpdateExactCostReversingMandatoryOnPurchaseSetup(true);
        LotNo := CreatePurchaseOrderWithStandardCostItemUsingLot(PurchaseHeader, PurchaseLine, Vendor);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post Purchase Order as Receive and Invoice.

        // Verify.
        VerifyGLEntry(DocumentNo, GeneralPostingSetup."Purch. Account", PurchaseLine."Line Amount");
        VerifyGLEntry(DocumentNo, VendorPostingGroup."Payables Account", -PurchaseLine."Amount Including VAT");
        VerifyValueEntry(
          DocumentNo, ValueEntry."Document Type"::"Purchase Invoice", PurchaseLine."No.",
          ValueEntry."Entry Type"::"Direct Cost", PurchaseLine."Line Amount", PurchaseLine."Direct Unit Cost", false);
        VerifyValueEntry(
          DocumentNo, ValueEntry."Document Type"::"Purchase Invoice", PurchaseLine."No.",
          ValueEntry."Entry Type"::Variance, -PurchaseLine."Line Amount", -PurchaseLine."Direct Unit Cost", false);

        if GetPostedDocumentLines then begin
            // Exercise.
            CreatePurchReturnOrderWithGetPstdDocLinesToReverse(PurchaseHeader);

            // Verify.
            FindPurchaseLine(PurchaseLine2, PurchaseLine."No.");
            PurchaseLine2.TestField("Appl.-to Item Entry", 0);  // Use 0 for Apply To Item Entry.
        end;

        if LotAfterGetPostedDocumentLines then begin
            // Exercise.
            LibraryVariableStorage.Enqueue(ItemTrackingMode::VerifyLot);  // Enqueue for ItemTrackingPageHandler.
            LibraryVariableStorage.Enqueue(LotNo);  // Enqueue for ItemTrackingPageHandler.
            PurchaseLine2.OpenItemTrackingLines();

            // Verify: Verification performed on ItemTrackingPageHandler.
        end;

        if PostPurchaseReturnOrder then begin
            // Exercise.
            DocumentNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post Purchase Return Order as Ship and Invoice.

            // Verify.
            VerifyGLEntry(DocumentNo2, GeneralPostingSetup."Purch. Credit Memo Account", -PurchaseLine."Line Amount");
            VerifyGLEntry(DocumentNo2, VendorPostingGroup."Payables Account", PurchaseLine."Amount Including VAT");
            VerifyValueEntry(
              DocumentNo2, ValueEntry."Document Type"::"Purchase Credit Memo", PurchaseLine."No.",
              ValueEntry."Entry Type"::"Direct Cost", 0, 0, false);  // Use 0 for Cost Amount Actual and Cost Per Unit.
        end;

        if PostCostToGL then begin
            // Exercise.
            LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');
            LibraryVariableStorage.Enqueue(ValueEntriesWerePostedTxt);
            LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

            // Verify.
            VerifyGLEntry(DocumentNo, GeneralPostingSetup."Direct Cost Applied Account", -PurchaseLine."Line Amount");
            VerifyGLEntry(DocumentNo, GeneralPostingSetup."Purchase Variance Account", PurchaseLine."Line Amount");
            VerifyGLEntry(DocumentNo2, GeneralPostingSetup."Purchase Variance Account", -PurchaseLine."Line Amount");
            VerifyGLEntry(DocumentNo2, GeneralPostingSetup."Direct Cost Applied Account", PurchaseLine."Line Amount");
            VerifyValueEntry(
              DocumentNo2, ValueEntry."Document Type"::"Purchase Credit Memo", PurchaseLine."No.",
              ValueEntry."Entry Type"::"Direct Cost", -PurchaseLine."Line Amount", PurchaseLine."Direct Unit Cost",
              true);  // Use True for Adjustment.
            VerifyValueEntry(
              DocumentNo2, ValueEntry."Document Type"::"Purchase Credit Memo", PurchaseLine."No.",
              ValueEntry."Entry Type"::Variance, PurchaseLine."Line Amount", -PurchaseLine."Direct Unit Cost",
              true);  // Use True for Adjustment.
        end;

        // Tear Down.
        UpdateExactCostReversingMandatoryOnPurchaseSetup(OldExactCostReversingMandatory);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPurchaseOrderWithDropShipmentAndJobNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        Job: Record Job;
    begin
        // [FEATURE] [Drop Shipment] [Job]
        // [SCENARIO 48248] Error should be thrown when adding Job No. in Purchase Order whith Drop Shipment purchasing code.

        // Setup: Create Purchase Order with Get Drop Shipment from Sales Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrderWithDropShipment(SalesHeader, Customer."No.", Item."No.");

        CreatePurchaseOrderWithGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // Exercise: Update Job No. in Purchase Order
        FindPurchaseLineByHeader(PurchaseLine, PurchaseHeader);
        LibraryJob.CreateJob(Job);
        asserterror PurchaseLine.Validate("Job No.", Job."No.");

        // Verify: Error message pops up when add the Job No.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Drop Shipment"), Format(false));
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPurchaseOrderWithSpecialOrderAndJobNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        Job: Record Job;
    begin
        // [FEATURE] [Special Order] [Job]
        // [SCENARIO 48248] Error should be thrown when adding Job No. in Purchase Order with Special Order purchasing code.

        // Setup: Create Purchase Order with Get Special Order from Sales Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrderWithSpecialOrder(SalesHeader, Customer."No.", '', Item."No.");

        CreatePurchaseOrderWithGetSpecialOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // Exercise: Update Job No. in Purchase Order
        FindPurchaseLineByHeader(PurchaseLine, PurchaseHeader);
        LibraryJob.CreateJob(Job);
        asserterror PurchaseLine.Validate("Job No.", Job."No.");

        // Verify: Error message pops up when add the Job No.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Special Order"), '');
    end;

    [Test]
    [HandlerFunctions('ShipAndInvoiceMenuHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithChangeUOM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure1: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Item Unit of Measure]
        // [SCENARIO 48494] Quantity on sales line should be recalculated after chainging unit of measure

        // Setup: Create Item with Order Reorder Policy and Multiple UOM.
        Initialize();
        CreateItemWithMultipleUOM(Item, ItemUnitOfMeasure, ItemUnitOfMeasure1);

        // Exercise: Create Sales Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateSalesOrder(SalesHeader, '', Item."No.", Quantity, '', false);

        // Exercise: Change the Unit of Measure Code on Sales Order page to trigger the avail. warning and post the order.
        // PS: The automation case cannot detect the error "The following C/AL functionts..." due to testability issue.
        Commit();
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines."Unit of Measure Code".SetValue(ItemUnitOfMeasure1.Code); // Trigger the avail.warning.
        SalesOrder.Post.Invoke();

        // Verify: Verify the Quantity(calculated by ItemUnitOfMeasure1) on Item Ledger Entry.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Sale, Item."No.", -Quantity * ItemUnitOfMeasure1."Qty. per Unit of Measure", '', '', '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWhenReservationEntryExistsForAnotherSalesOrder()
    var
        Outbound: Option ,SalesOrder,SalesInvoice,PurchaseReturnOrder,PurchaseCreditMemo;
    begin
        // [FEATURE] [Sales] [Reservation]
        // [SCENARIO 68631] Confirmation should be requested when posting Sales Order when all stock reserved for another Sales Order.

        Initialize();
        PostOutboundWhenReservationEntryExistsForSalesOrder(Outbound::SalesOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWhenReservationEntryExistsForSalesOrder()
    var
        Outbound: Option ,SalesOrder,SalesInvoice,PurchaseReturnOrder,PurchaseCreditMemo;
    begin
        // [FEATURE] [Sales] [Reservation]
        // [SCENARIO 68631] Confirmation should be requested when posting Sales Invoice when all stock reserved for another Sales Order.

        Initialize();
        PostOutboundWhenReservationEntryExistsForSalesOrder(Outbound::SalesInvoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderWhenReservationEntryExistsForSalesOrder()
    var
        Outbound: Option ,SalesOrder,SalesInvoice,PurchaseReturnOrder,PurchaseCreditMemo;
    begin
        // [FEATURE] [Purchase Return] [Reservation]
        // [SCENARIO 68631] Confirmation should be requested when posting Purchase Return Order when all stock is reserved for Sales Order.

        Initialize();
        PostOutboundWhenReservationEntryExistsForSalesOrder(Outbound::PurchaseReturnOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoWhenReservationEntryExistsForSalesOrder()
    var
        Outbound: Option ,SalesOrder,SalesInvoice,PurchaseReturnOrder,PurchaseCreditMemo;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 68631] Confirmation should be requested when posting Purchase Credit Memo when all stock is reserved for Sales Order.

        Initialize();
        PostOutboundWhenReservationEntryExistsForSalesOrder(Outbound::PurchaseCreditMemo);
    end;

    [Test]
    [HandlerFunctions('ExplodeBomHandler')]
    [Scope('OnPrem')]
    procedure ExplodedBOMWhenComponentExistsExtendedTxtOnSalesLine()
    var
        CompItem: Record Item;
        CompItem2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Assembly] [Extended Text]
        // [SCENARIO 72977] Assembly BOM can be exploded on the Sales line and the Extended Text to be automatic inserted accordingly when the Assembly contains an Item with an associated Extended Text and Automatic Ext. Texts=Yes.

        // [GIVEN] Create two component items, one with Extended Text. Create assembly item with the two BOM Components.
        Initialize();
        UpdateStockoutWarningOnSalesReceivableSetup(false);
        AssemblyItemNo := CreateAssemblyItemWithMultipleBOMComponents(CompItem, CompItem2);

        // [GIVEN] Create a Sales Order.
        CreateSalesOrder(
          SalesHeader, '', AssemblyItemNo, LibraryRandom.RandDec(10, 2), '', false);

        // [WHEN] Find the sales line with assembly item, and Explode BOM.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.ExplodeBOM(SalesLine);

        // [THEN] Verify Assembly BOM can be exploded on the Sales line and  Extended Text to be automatic inserted accordingly.
        VerifySalesLine(
          SalesHeader."Document Type", SalesHeader."No.", CompItem."No.", CompItem2."No.");
    end;

    [Test]
    [HandlerFunctions('ExplodeBomHandler')]
    [Scope('OnPrem')]
    procedure ExplodedBOMWhenComponentExistsExtendedTxtOnPurchaseLine()
    var
        CompItem: Record Item;
        CompItem2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AssemblyItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Assembly] [Extended Text]
        // [SCENARIO 72977] Assembly BOM can be exploded on the Purchase line and the Extended Text to be automatic inserted accordingly when the Assembly contains an Item with an associated Extended Text and Automatic Ext. Texts=Yes.

        // [GIVEN] Create two components item, one with Extended Text. Create assembly item with the two BOM Components.
        Initialize();
        AssemblyItemNo := CreateAssemblyItemWithMultipleBOMComponents(CompItem, CompItem2);

        // [GIVEN] Create a Purchases Order.
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', AssemblyItemNo, LibraryRandom.RandDec(10, 2), '', false);

        // [WHEN] Find the Purchase line with assembly item, and Explode BOM.
        FindPurchaseLine(PurchaseLine, AssemblyItemNo);
        LibraryPurchase.ExplodeBOM(PurchaseLine);

        // [THEN] Verify Assembly BOM can be exploded on the Sales line and  Extended Text to be automatic inserted accordingly.
        VerifyPurchaseLine(
          PurchaseHeader."Document Type", PurchaseHeader."No.", CompItem."No.", CompItem2."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptWithDimensionAndJobNo()
    var
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: array[2] of Code[20];
        OrderNo: Code[20];
        Quantity: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Undo PurchaseReceipt] [Job] [Dimension]
        // [SCENARIO 359952] Test the Receipt Line and Item Ledger Entry after Undo Purchase Receipt with Job No. and Dimension set as Code mandatory

        // [GIVEN] Create 2 Items with Dimension set as Code mandatory and Lot Tracking.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        for i := 1 to ArrayLen(Item) do begin
            CreateItemWithItemTrackingCode(Item[i], true, false, LibraryUtility.GetGlobalNoSeriesCode(), '');  // True for Lot.
            CreateDimensionForItem(Item[i]."No.");
        end;

        // [GIVEN] Create and Post Purchase Order with multiple Items and Job No.
        OrderNo := CreateAndPostPurchaseOrderWithMultipleItemsAndJobNo(Item, Quantity, LotNo);

        // [WHEN] Undo Purchase Receipt.
        UndoPurchaseReceipt(OrderNo, Item[1]."No.", Item[2]."No.");

        // [THEN] Verify Receipt Line and Item Ledger Entry.
        VerifyReceiptLineAfterUndo(OrderNo, Item[1]."No.", Item[2]."No.", Quantity);
        VerifyItemLedgerEntryForLot(ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", LotNo[2], Quantity, false);  // Use MoveNext as FALSE.
        VerifyItemLedgerEntryForLot(ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", LotNo[2], -Quantity, true);  // Use MoveNext as TRUE.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReturnShipmentWithDimensionAndJobNo()
    var
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        OrderNo: Code[20];
        Quantity: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Undo Return Shipment] [Job] [Dimension]
        // [SCENARIO 359952] Test the Return Shipment Line and Item Ledger Entry after Undo Purchase Return Shipment with Job No. and Dimension set as Code mandatory

        // [GIVEN] Create 2 Items with Dimension set as Code mandatory.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            CreateDimensionForItem(Item[i]."No.");
        end;

        // [GIVEN] Create and Post Purchase Return Order with multiple Items and Job No
        OrderNo := CreateAndPostPurchaseReturnOrderWithMultipleItemsAndJobNo(Item, Quantity);

        // [WHEN] Undo Purchase Return Shipment.
        UndoReturnShipment(OrderNo, Item[1]."No.", Item[2]."No.");

        // [THEN] Verify Return Shipment Line and Item Ledger Entry.
        VerifyReturnShipmentLineAfterUndo(OrderNo, Item[1]."No.", Item[2]."No.", Quantity);
        VerifyItemLedgerEntryForLot(ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", '', -Quantity, false);  // Use MoveNext as FALSE.
        VerifyItemLedgerEntryForLot(ItemLedgerEntry."Entry Type"::Purchase, Item[2]."No.", '', Quantity, true);  // Use MoveNext as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeQuantityOnSalesLineDefaultQtyToShipBlank()
    var
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        PrevDefQtyToShip: Integer;
    begin
        // [FEATURE] [Default Qty]
        // [SCENARIO 361885] "Qty. to Ship" shoud be set to zero for non-Item Sales Line when Quantity is modified.

        // [GIVEN] Set "Default Quantity to Ship" to "Blank" in Sales & Receivable Setup, create SalesLine with Resource of Quantity X.
        Initialize();
        PrevDefQtyToShip := UpdateDefQtyToShipOnSalesReceivableSetup(1); // Blank
        LibraryResource.FindResource(Resource);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", LibraryRandom.RandIntInRange(10, 100));

        // [GIVEN] Set Sales Line "Qty. to Ship" to X.
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity);
        SalesLine.Modify();

        // [WHEN] Change Quantity in Sales Line to X + 1 (VALIDATE).
        SalesLine.Validate(Quantity, SalesLine.Quantity + 1);

        // [THEN] Verify "Qty. to Ship" is zero.
        SalesLine.TestField("Qty. to Ship", 0);

        // Teardown.
        UpdateDefQtyToShipOnSalesReceivableSetup(PrevDefQtyToShip);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,PostedITLPageHandler,PostedSalesDocTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesInGetPostedShptLinesShowsCorrectTrackingLines()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        LotNo: Code[50];
        Qty: Integer;
    begin
        // [FEATURE] [Get Posted Document Lines to Reverse] [Item Tracking]
        // [SCENARIO 166286] "Item Tracking Lines" action in page 5851 "Get Post.Doc - S.ShptLn Sbfrm" should open item tracking lines related to selected document line

        // [GIVEN] Item with lot tracking
        Qty := LibraryRandom.RandInt(100);
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '');
        // [GIVEN] Post purchase receipt with lot no. = "L"
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, '', Item."No.", Qty, '', true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Post sales shipment for lot "L"
        LotNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo));
        CreateSalesOrderWithItemTracking(SalesHeader, '', Item."No.", Qty, '');
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create sales credit memo for lot "L" and run "Get Posted Document Lines to Reverse"
        LibraryVariableStorage.Enqueue(LotNo);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");

        // [WHEN] Open posted item tracking lines
        // [THEN] Item tracking line with lot no. = "L" is displayed
        // Verified in PostedITLPageHandler
        SalesHeader.GetPstdDocLinesToReverse();
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocTrackingVerifyFilterPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesInGetPostedShptLinesDoesNotResetFilters()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Get Posted Document Lines to Reverse]
        // [SCENARIO 166286] "Item Tracking Lines" action in page 5851 "Get Post.Doc - S.ShptLn Sbfrm" should not affect filters in the current page

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Customer "C"
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Post 2 sales shipments "S1" and "S2" for customer "C"
        LibraryVariableStorage.Enqueue(PostSalesShipment(Customer."No.", Item."No.", LibraryRandom.RandInt(100)));
        LibraryVariableStorage.Enqueue(PostSalesShipment(Customer."No.", Item."No.", LibraryRandom.RandInt(100)));

        // [GIVEN] Create sales credit memo for customer "C" and run "Get Posted Document Lines to Reverse"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesHeader.GetPstdDocLinesToReverse();

        // [WHEN] Open posted item tracking lines
        // [THEN] 2 sales shipments are in the list: "S1" and "S2"
        // Verified in PostedSalesDocTrackingVerifyFilterPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetItemNoOnSalesLine()
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [FEATURE] [Sales] [Default Item Quantity] [UT]
        // [SCENARIO 161629] Quantity is set to "0" after filling in "Item No." in sales line if "Default Item Quantity" is not set in Sales & Receivable Setup
        Initialize();

        // [GIVEN] Sales & Receivables Setup with "Default Item Quantity" = FALSE
        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales line with type = "Item"
        MockSalesLineWithItemType(SalesLine);

        // [WHEN] Set "Item No." on sales line to "I"
        SalesLine.Validate("No.", Item."No.");

        // [THEN] Quantity is "0"
        SalesLine.TestField(Quantity, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetItemNoOnSalesLineWithDefaultItemQuantity()
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [FEATURE] [Sales] [Default Item Quantity] [UT]
        // [SCENARIO 161629] Quantity is set to "1" after filling in "Item No." in sales line if "Default Item Quantity" is set in Sales & Receivable Setup
        Initialize();
        UpdateStockoutWarningOnSalesReceivableSetup(false);

        // [GIVEN] Sales & Receivables Setup with "Default Item Quantity" = TRUE
        UpdateDefaultItemQuantityOnSalesSetup(true);

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales line with type = "Item"
        MockSalesLineWithItemType(SalesLine);

        // [WHEN] Set "Item No." on sales line to "I"
        SalesLine.Validate("No.", Item."No.");

        // [THEN] Quantity is updated to default value "1"
        SalesLine.TestField(Quantity, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearItemNoOnSalesLineWithDefaultItemQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [FEATURE] [Sales] [Default Item Quantity] [UT]
        // [SCENARIO 161629] Quantity is set to "0" after deleting "Item No." in sales line if "Default Item Quantity" is set in Sales & Receivable Setup
        Initialize();
        UpdateStockoutWarningOnSalesReceivableSetup(false);

        // [GIVEN] Sales & Receivables Setup with "Default Item Quantity" = TRUE
        UpdateDefaultItemQuantityOnSalesSetup(true);

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales line for Item "I" and Quantity <> 0
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Set "Item No." on sales line to blank
        SalesLine.Validate("No.", '');

        // [THEN] Quantity is updated to default value "0"
        SalesLine.TestField(Quantity, 0);
    end;

    [Test]
    procedure SetGLAccountNoOnSalesLine()
    var
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Sales] [Default G/L Account Quantity] [UT]
        // [SCENARIO 161630] Quantity is set to "0" after filling in "G/L Account No." in sales line if "Default G/L Account Quantity" is not set in Sales & Receivable Setup
        Initialize();

        // [GIVEN] Sales & Receivable Setup with "Default G/L Account Quantity" = FALSE
        UpdateDefaultGLAccountQuantityOnSalesSetup(false);

        // [GIVEN] G/L Account "A"
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] Sales line with type = "G/L Account"
        MockSalesLineWithGLAccountType(SalesLine);

        // [WHEN] Set "G/L Account No." on sales line to "A"
        SalesLine.Validate("No.", GLAccount."No.");

        // [THEN] Quantity is "0"
        SalesLine.TestField(Quantity, 0);
    end;

    [Test]
    procedure SetGLAccountNoOnSalesLineWithDefaultGLAccountQuantity()
    var
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Sales] [Default G/L Account Quantity] [UT]
        // [SCENARIO 161630] Quantity is set to "1" after filling in "G/L Account No." in sales line if "Default G/L Account Quantity" is set in Sales & Receivable Setup
        Initialize();

        // [GIVEN] Sales & Receivables Setup with "Default G/L Account Quantity" = TRUE
        UpdateDefaultGLAccountQuantityOnSalesSetup(true);

        // [GIVEN] G/L Account "A"
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] Sales line with type = "G/L Account"
        MockSalesLineWithGLAccountType(SalesLine);

        // [WHEN] Set "G/L Account No." on sales line to "A"
        SalesLine.Validate("No.", GLAccount."No.");

        // [THEN] Quantity is updated to default value "1"
        SalesLine.TestField(Quantity, 1);
    end;

    [Test]
    procedure ClearGLAccountOnSalesLineWithDefaultGLAccountQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Sales] [Default G/L Account Quantity] [UT]
        // [SCENARIO 161630] Quantity is set to "0" after deleting "G/L Account No." in sales line if "Default G/L Account Quantity" is set in Sales & Receivable Setup
        Initialize();

        // [GIVEN] Sales & Receivables Setup with "Default G/L Account Quantity" = TRUE
        UpdateDefaultGLAccountQuantityOnSalesSetup(true);

        // [GIVEN] G/L Account "A"
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] Sales line for  G/L Account "A" and Quantity <> 0
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(10));

        // [WHEN] Set "G/L Account No." on sales line to blank
        SalesLine.Validate("No.", '');

        // [THEN] Quantity is updated to default value "0"
        SalesLine.TestField(Quantity, 0);
    end;

    [Test]
    procedure SetGLAccountNoOnPurchaseLine()
    var
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Purchase] [Default G/L Account Quantity] [UT]
        // [SCENARIO 161631] Quantity is set to "0" after filling in "G/L Account No." in purchase line if "Default G/L Account Quantity" is not set in Purchases & Payables Setup
        Initialize();

        // [GIVEN] Purchases & Payables Setup Setup with "Default G/L Account Quantity" = FALSE
        UpdateDefaultGLAccountQuantityOnPurchaseSetup(false);

        // [GIVEN] G/L Account "A"
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());

        // [GIVEN] Purchase line with type = "G/L Account"
        MockPurchaseLineWithGLAccountType(PurchaseLine);

        // [WHEN] Set "G/L Account No." on purchase line to "A"
        PurchaseLine.Validate("No.", GLAccount."No.");

        // [THEN] Quantity is "0"
        PurchaseLine.TestField(Quantity, 0);
    end;

    [Test]
    procedure SetGLAccountNoOnPurchaseLineWithDefaultGLAccountQuantity()
    var
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Purchase] [Default G/L Account Quantity] [UT]
        // [SCENARIO 161631] Quantity is set to "1" after filling in "G/L Account No." in purchase line if "Default G/L Account Quantity" is set in Purchases & Payables Setup
        Initialize();

        // [GIVEN] Purchases & Payables Setup with "Default G/L Account Quantity" = TRUE
        UpdateDefaultGLAccountQuantityOnPurchaseSetup(true);

        // [GIVEN] G/L Account "A"
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());

        // [GIVEN] Purchase line with type = "G/L Account"
        MockPurchaseLineWithGLAccountType(PurchaseLine);

        // [WHEN] Set "G/L Account No." on purchase line to "A"
        PurchaseLine.Validate("No.", GLAccount."No.");

        // [THEN] Quantity is updated to default value "1"
        PurchaseLine.TestField(Quantity, 1);
    end;

    [Test]
    procedure ClearGLAccountOnPurchaseLineWithDefaultGLAccountQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Purchase] [Default G/L Account Quantity] [UT]
        // [SCENARIO 161631] Quantity is set to "0" after deleting "G/L Account No." in purchase line if "Default G/L Account Quantity" is set in Purchases & Payables Setup
        Initialize();

        // [GIVEN] Purchases & Payables Setup with "Default G/L Account Quantity" = TRUE
        UpdateDefaultGLAccountQuantityOnPurchaseSetup(true);

        // [GIVEN] G/L Account "A"
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());

        // [GIVEN] Purchase line for  G/L Account "A" and Quantity <> 0
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(10));

        // [WHEN] Set "G/L Account No." on purchase line to blank
        PurchaseLine.Validate("No.", '');

        // [THEN] Quantity is updated to default value "0"
        PurchaseLine.TestField(Quantity, 0);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AvailabilityWarningRaisedWithDefaultQuantityNoItemStock()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [FEATURE] [Sales] [Default Item Quantity] [Stockout Warning]
        // [SCENARIO] Availability warning is raised when default quantity is set in sales line and item is not in stock
        Initialize();

        // [GIVEN] Enable stockout warning and default item quantity in Sales & Receivables Setup
        UpdateStockoutWarningOnSalesReceivableSetup(true);
        UpdateDefaultItemQuantityOnSalesSetup(true);

        // [GIVEN] Create item "I" without stock
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create sales order with one line
        MockSalesLineWithItemType(SalesLine);

        // [WHEN] Set "No." = "I" in sales line
        SalesLine.Validate("No.", Item."No.");

        // [THEN] Availability warning is raised
        // Verified in CheckAvailabilityHandler
        // [THEN] After accepting the warning quantity is set to "1" in sales line
        SalesLine.TestField(Quantity, 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoAvailabilityWarningWithDefaultQuantityItemInStock()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Default Item Quantity] [Stockout Warning]
        // [SCENARIO] Availability warning is not raised when default quantity is set in sales line and item is in stock
        Initialize();

        // [GIVEN] Enable stockout warning and default item quantity in Sales & Receivables Setup
        UpdateStockoutWarningOnSalesReceivableSetup(true);
        UpdateDefaultItemQuantityOnSalesSetup(true);

        // [GIVEN] Create item "I" and post positive adjustment for this item
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", 1, '', '');

        // [GIVEN] Create sales order with one line for item "I"
        MockSalesLineWithItemType(SalesLine);

        // [WHEN] Set "No." = "I" in sales line
        SalesLine.Validate("No.", Item."No.");

        // [THEN] Quantity in sales line is set to "1" without availability warning
        SalesLine.TestField(Quantity, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQtyInLineDetailsUpdatedWithDefaultItemQuantity()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales] [Default Item Quantity] [Item Availability]
        // [SCENARIO] "Sales Line Details" factbox should be updated when sales line is created with default quantity
        Initialize();

        // [GIVEN] Enable default item quantity in Sales & Receivables Setup
        UpdateStockoutWarningOnSalesReceivableSetup(false);
        UpdateDefaultItemQuantityOnSalesSetup(true);

        // [GIVEN] New sales order
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);

        // [WHEN] In sales order line, set an item that is not on inventory
        SalesOrder.SalesLines."No.".SetValue(Item."No.");
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.Previous();

        // [THEN] "Item Availability" in "Sales Line Details" factbox is -1
        SalesOrder.Control1906127307."Item Availability".AssertEquals(-1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQtyInSalesLineFactBoxUsesQtyRoundingPrecision()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        AvailQty: Decimal;
    begin
        // [FEATURE] [Sales] [Sales Line Factbox] [UI]
        // [SCENARIO 226030] "Item Availability" value in Sales Line Details Factbox is rounded to 0.00001.
        Initialize();

        // [GIVEN] Item "I" with 1.555555 pcs (6 digits) in inventory.
        LibraryInventory.CreateItem(Item);
        MockItemInventory(Item."No.", 1.555555);

        // [GIVEN] Sales Order Line with "I".
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer No.".SetValue(LibrarySales.CreateCustomerNo());
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesOrder.SalesLines."No.".SetValue(Item."No.");

        // [WHEN] Set Quantity = 1 on the sales line.
        SalesOrder.SalesLines.Quantity.SetValue(1);

        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.Previous();

        // [THEN] Item Availability in Sales Line Details Factbox is equal to 0.55556 (rounded to the 5th digit).
        Evaluate(AvailQty, SalesOrder.Control1906127307."Item Availability".Value);
        Assert.AreEqual(0.55556, AvailQty, 'Wrong rounding precision of Item Availability value in the factbox.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQtyInPurchaseLineFactBoxUsesQtyRoundingPrecision()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        AvailQty: Decimal;
    begin
        // [FEATURE] [Purchase] [Purchase Line Factbox] [UI]
        // [SCENARIO 305591] "Item Availability" value in Purchase Line Details Factbox is rounded to 0.00001.
        Initialize();

        // [GIVEN] Item "I" with 1.555555 pcs (6 digits) in inventory.
        LibraryInventory.CreateItem(Item);
        MockItemInventory(Item."No.", 1.555555);

        // [GIVEN] Purchase Order Line with "I".
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor No.".SETVALUE(LibraryPurchase.CreateVendorNo());
        PurchaseOrder.PurchLines.New();
        PurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseOrder.PurchLines."No.".SetValue(Item."No.");

        // [WHEN] Set Quantity = -1 on the sales line.
        PurchaseOrder.PurchLines.Quantity.SetValue(-1);

        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.Previous();

        // [THEN] Item Availability in Purchase Line Details Factbox is equal to 0.55556 (rounded to 5 digits).
        Evaluate(AvailQty, PurchaseOrder.Control3.Availability.Value);
        Assert.AreEqual(0.55556, AvailQty, 'Wrong rounding precision of Item Availability value in the factbox.');
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,GetShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteFullyInvoicedSalesOrderWithSpecialOrderPurchOrderNotInvoiced()
    var
        SalesHeaderOrder: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Shipment] [Get Shipment Lines] [Special Order]
        // [SCENARIO 381247] Stan can delete fully shipped Sales Order tied with Purchase "Special Order" when it is fully Invoiced by another document
        Initialize();

        // [GIVEN] Sales order "SO" marked as "Special Order" and linked to purchase order "PO"
        ItemNo := LibraryInventory.CreateItemNo();
        CreateSalesOrderWithSpecialOrder(SalesHeaderOrder, LibrarySales.CreateCustomerNo(), '', ItemNo);

        // [GIVEN] "PO" with line "PL" received and not invoiced
        CreateSpecialPurchaseOrderAndPostReceipt(PurchaseHeader, SalesHeaderOrder, ItemNo);

        // [GIVEN] "SO" shipped fully
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Sales invoice "SI" created from shipped "SO" using "Get Shipment Lines"
        // [GIVEN] "SI" fully invoiced
        CreateAndPostSalesInvoiceFromShipment(SalesHeaderOrder);

        // [WHEN] Delete "SO"
        SalesHeaderOrder.Find();
        SalesHeaderOrder.Delete(true);

        // [THEN] "SO" deleted without any error and "PL" updated
        // [THEN] "PL"."Special Order Sales No." = <blank>
        // [THEN] "PL"."Special Order Sales Line No." = 0
        // [THEN] "PL"."Special Order" = FALSE
        FindPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.TestField("Special Order", false);
        PurchaseLine.TestField("Special Order Sales No.", '');
        PurchaseLine.TestField("Special Order Sales Line No.", 0);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,GetShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteFullyInvoicedSalesOrderWithSpecialOrderPurchOrderFullyInvoiced()
    var
        SalesHeaderOrder: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Shipment] [Get Shipment Lines] [Special Order]
        // [SCENARIO 381247] Stan can delete fully shipped Sales Order tied with Purchase "Special Order" when it is fully Invoiced by another document and special order fully receipt and invoiced
        Initialize();

        // [GIVEN] Sales order "SO" marked as "Special Order" and linked to purchase order "PO"
        ItemNo := LibraryInventory.CreateItemNo();
        CreateSalesOrderWithSpecialOrder(SalesHeaderOrder, LibrarySales.CreateCustomerNo(), '', ItemNo);

        // [GIVEN] "PO" with line "PL" received and not invoiced
        CreateSpecialPurchaseOrderAndPostReceipt(PurchaseHeader, SalesHeaderOrder, ItemNo);

        // [GIVEN] "SO" shipped fully
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);
        // [GIVEN] "PO" invoiced fully
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Sales invoice "SI" created from shipped "SO" using "Get Shipment Lines"
        // [GIVEN] "SI" fully invoiced
        CreateAndPostSalesInvoiceFromShipment(SalesHeaderOrder);

        // [WHEN] Delete "SO"
        SalesHeaderOrder.Find();
        SalesHeaderOrder.Delete(true);

        // [THEN] "SO" deleted without any error
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceUsesQtyPerUOMFromSalesShipment()
    var
        Customer: Record Customer;
        Location: Record Location;
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice] [Get Shipment Line] [Item Unit of Measure]
        // [SCENARIO 381806] When the proportion between "Quantity (Base)" and Quantity in sales shipment is not equal to "Qty. per Unit of Measure", that changed proportion should be also applied to sales invoice created from that shipment.
        Initialize();

        // [GIVEN] Item "I" with alternate sales unit of measure "BOX". Qty. in base UOM for "BOX" = 6.
        // [GIVEN] Item "I" is in stock in Location set up for required shipment.
        ItemNo := CreateItemWithSalesUOM(6);
        ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        ItemUnitOfMeasure.FindFirst();
        ItemUnitOfMeasure.Validate("Qty. Rounding Precision", 1);
        ItemUnitOfMeasure.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        CreateAndPostItemJournalLine(ItemNo, LibraryRandom.RandIntInRange(10, 20), Location.Code, '');

        // [GIVEN] Sales Order "SO" for 1 "BOX" of item "I".
        // [GIVEN] Posted warehouse shipment for the sales order. "Qty. to Ship" = 0.66667. "Qty. to Ship (Base)" = 4, which is not equal to 0.66667 * 6 = 4.00002
        CreateAndPartiallyShipSalesOrderWithAlternateUOM(
          SalesHeaderOrder, Customer."No.", ItemNo, Location.Code, 1, 0.66667, 4);

        // [WHEN] Create Sales Invoice "SI" from shipped "SO" using "Get Shipment Lines".
        CreateSalesInvoiceFromShipment(SalesHeaderInvoice, SalesHeaderOrder);

        // [THEN] SI."Quantity (Base)" = 4
        // [THEN] SI."Outstanding Qty. (Base)" = 4
        // [THEN] SI."Qty. to Invoice (Base)" = 4
        VerifyBaseQtysOnSalesLine(SalesHeaderInvoice, ItemNo, 4);
    end;

    [Test]
    [HandlerFunctions('ExplodeBomHandler')]
    [Scope('OnPrem')]
    procedure ExplodedBOMInSalesLinesAfterAttachedExtendedTexts()
    var
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CompItemNo: Code[20];
        ExtendedText: Text;
    begin
        // [FEATURE] [BOM] [Explode BOM] [Sales] [Extended Text]
        // [SCENARIO 382083] The Assembly BOM is exploded on the Sales Line after attached extended texts

        // [GIVEN] Assembly BOM with extended text
        Initialize();
        UpdateStockoutWarningOnSalesReceivableSetup(false);
        CompItemNo := LibraryInventory.CreateItemNo();
        CreateAssemblyItemWithAsseblyBOM(AssemblyItem, CompItemNo, LibraryRandom.RandInt(10));
        ExtendedText := LibraryInventory.CreateExtendedTextForItem(AssemblyItem."No.");

        // [GIVEN] Sales Order with Assembly BOM and inserted extended text
        CreateSalesOrderWithInsertedExtendedText(SalesHeader, SalesLine, AssemblyItem."No.");

        // [WHEN] Explode Assembly BOM
        LibrarySales.ExplodeBOM(SalesLine);

        // [THEN] The Sales Line with component is inserted after extended text from BOM
        VerifySalesLineExtTextBeforeItem(SalesHeader, ExtendedText, CompItemNo);
    end;

    [Test]
    [HandlerFunctions('ExplodeBomHandler')]
    [Scope('OnPrem')]
    procedure ExplodedBOMInSalesLinesAfterAttachedExtendedTextsAndBeforeNextLine()
    var
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewSalesLine: Record "Sales Line";
        CompItemNo: Code[20];
        ExtendedText: Text;
    begin
        // [FEATURE] [BOM] [Explode BOM] [Sales] [Extended Text]
        // [SCENARIO 382083] The Assembly BOM is exploded on the Sales Line after attached extended texts but before next line

        // [GIVEN] Assembly BOM with extended text
        Initialize();
        UpdateStockoutWarningOnSalesReceivableSetup(false);
        CompItemNo := LibraryInventory.CreateItemNo();
        CreateAssemblyItemWithAsseblyBOM(AssemblyItem, CompItemNo, LibraryRandom.RandInt(10));
        ExtendedText := LibraryInventory.CreateExtendedTextForItem(AssemblyItem."No.");

        // [GIVEN] Sales Order with Assembly BOM and inserted extended text
        CreateSalesOrderWithInsertedExtendedText(SalesHeader, SalesLine, AssemblyItem."No.");

        // [GIVEN] Additional line in the end of Sales Order
        CreateSalesLine(SalesHeader, NewSalesLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '');

        // [WHEN] Explode Assembly BOM
        LibrarySales.ExplodeBOM(SalesLine);

        // [THEN] The Sales Line with component is inserted after extended text from BOM and before next additional line
        VerifySalesLineExtTextBeforeItem(SalesHeader, ExtendedText, CompItemNo);
    end;

    [Test]
    [HandlerFunctions('ExplodeBomHandler')]
    [Scope('OnPrem')]
    procedure ExplodedBOMInPurchLinesAfterAttachedExtendedTexts()
    var
        AssemblyItem: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CompItemNo: Code[20];
        ExtendedText: Text;
    begin
        // [FEATURE] [BOM] [Explode BOM] [Purchase] [Extended Text]
        // [SCENARIO 382083] The Assembly BOM is exploded on the Purchase Line after attached extended texts

        // [GIVEN] Assembly BOM with extended text
        Initialize();
        CompItemNo := LibraryInventory.CreateItemNo();
        CreateAssemblyItemWithAsseblyBOM(AssemblyItem, CompItemNo, LibraryRandom.RandInt(10));
        ExtendedText := LibraryInventory.CreateExtendedTextForItem(AssemblyItem."No.");

        // [GIVEN] Purchase Order with Assembly BOM and inserted extended text
        CreatePurchOrderWithInsertedExtendedText(PurchHeader, PurchLine, AssemblyItem."No.");

        // [WHEN] Explode Assembly BOM
        LibraryPurchase.ExplodeBOM(PurchLine);

        // [THEN] The Purchase Line with component is inserted after extended text from BOM
        VerifyPurchLineExtTextBeforeItem(PurchHeader, ExtendedText, CompItemNo);
    end;

    [Test]
    [HandlerFunctions('ExplodeBomHandler')]
    [Scope('OnPrem')]
    procedure ExplodedBOMInPurchLinesAfterAttachedExtendedTextsAndBeforeNextLine()
    var
        AssemblyItem: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        NewPurchLine: Record "Purchase Line";
        CompItemNo: Code[20];
        ExtendedText: Text;
    begin
        // [FEATURE] [BOM] [Explode BOM] [Purchase] [Extended Text]
        // [SCENARIO 382083] The Assembly BOM is exploded on the Purchase Line after attached extended texts but before next line

        // [GIVEN] Assembly BOM with extended text
        Initialize();
        CompItemNo := LibraryInventory.CreateItemNo();
        CreateAssemblyItemWithAsseblyBOM(AssemblyItem, CompItemNo, LibraryRandom.RandInt(10));
        ExtendedText := LibraryInventory.CreateExtendedTextForItem(AssemblyItem."No.");

        // [GIVEN] Purchase Order with Assembly BOM and inserted extended text
        CreatePurchOrderWithInsertedExtendedText(PurchHeader, PurchLine, AssemblyItem."No.");

        // [GIVEN] Additional line in the end of Purchase Order
        CreatePurchaseLine(PurchHeader, NewPurchLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', false);

        // [WHEN] Explode Assembly BOM
        LibraryPurchase.ExplodeBOM(PurchLine);

        // [THEN] The Purchase Line with component is inserted after extended text from BOM and before next additional line
        VerifyPurchLineExtTextBeforeItem(PurchHeader, ExtendedText, CompItemNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithLotTrackingAndPartialQtyShipAndInvoiceQtyToInvoiceLessQtyShipped()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Item Tracking]
        // [SCENARIO 217787] Sales order for a lot-tracked item can be simultaneously shipped and invoiced, if "Qty. to Invoice" < "Quantity Shipped" for a current iteration of posting.
        Initialize();
        Qty := 10;

        // [GIVEN] Lot-tracked item.
        // [GIVEN] Two lots are in the inventory. Purchased quantity of each lot = 5 pcs.
        // [GIVEN] Lot-tracked sales order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Ship" ("QS-1") = 3, "Qty. to Invoice" ("QI-1") = 2.
        // [GIVEN] At the 2nd iteration "QS-2" = 2, "QI-2" = 2. Thereby, "QI-2" < "QS-1".
        // [GIVEN] At the 3rd iteration the order is completely posted.
        CreateSalesOrderForPurchasedTrackedItem(SalesHeader, Item, LotNos, Qty);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '1,1,3', '1,0,4');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '2,1,2', '1,2,2');

        // [WHEN] Carry out three iterations of posting the order.
        PostSalesOrderIterativelyWithShipAndInvoiceOption(SalesHeader, TempTrackingSpec, LotNos, 3);

        // [THEN] Each iteration of posting generated value entries with "Item Ledger Entry Quantity" = "QS-i" and "Invoiced Quantity" = "QI-i".
        // The verification done in VerifyValueEntriesAfterGivenEntryNo function.

        // [THEN] Sum of quantity in the item ledger each lot = 5.
        // [THEN] Sum of shipped and invoiced quantity on Sales Shipment Lines = 10.
        // [THEN] The sales order is deleted after posting.
        VerifyPostedSalesOrder(SalesHeader, Item."No.", LotNos, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithLotTrackingAndPartialQtyShipAndInvoiceQtyToInvoiceEqQtyShipped()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Item Tracking]
        // [SCENARIO 217787] Sales order for a lot-tracked item can be simultaneously shipped and invoiced if "Qty. to Invoice" = "Quantity Shipped" for a current iteration of posting.
        Initialize();
        Qty := 10;

        // [GIVEN] Lot-tracked item.
        // [GIVEN] Two lots are in the inventory. Purchased quantity of each lot = 5 pcs.
        // [GIVEN] Lot-tracked sales order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Ship" ("QS-1") = 4, "Qty. to Invoice" ("QI-1") = 2.
        // [GIVEN] At the 2nd iteration "QS-2" = 2, "QI-2" = 4. Thereby, "QI-2" = "QS-1".
        // [GIVEN] At the 3rd iteration the order is completely posted.
        CreateSalesOrderForPurchasedTrackedItem(SalesHeader, Item, LotNos, Qty);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '3,0,2', '2,1,2');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '1,2,2', '0,3,2');

        // [WHEN] Carry out three iterations of posting the order.
        PostSalesOrderIterativelyWithShipAndInvoiceOption(SalesHeader, TempTrackingSpec, LotNos, 3);

        // [THEN] Each iteration of posting generated value entries with "Item Ledger Entry Quantity" = "QS-i" and "Invoiced Quantity" = "QI-i".
        // The verification done in VerifyValueEntriesAfterGivenEntryNo function.

        // [THEN] Sum of quantity in the item ledger each lot = 5.
        // [THEN] Sum of shipped and invoiced quantity on Sales Shipment Lines = 10.
        // [THEN] The sales order is deleted after posting.
        VerifyPostedSalesOrder(SalesHeader, Item."No.", LotNos, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithLotTrackingAndPartialQtyShipAndInvoiceQtyToInvoiceLittleLessFullQty()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Item Tracking]
        // [SCENARIO 217787] Sales order for a lot-tracked item can be posted if "Qty. to Invoice" > "Quantity Shipped" for a current iteration of posting, yet overall shipped quantity will be little greater than overall invoiced quantity after the posting
        Initialize();
        Qty := 10;

        // [GIVEN] Lot-tracked item.
        // [GIVEN] Two lots are in the inventory. Purchased quantity of each lot = 5 pcs.
        // [GIVEN] Lot-tracked sales order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Ship" ("QS-1") = 3, "Qty. to Invoice" ("QI-1") = 0.
        // [GIVEN] At the 2nd iteration "QS-2" = 2, "QI-2" = 4. Thereby, "QI-2" > "QS-1", but ("QI-1" + "QI-2") < ("QS-1" + "QS-2").
        // [GIVEN] At the 3rd iteration the order is completely posted.
        CreateSalesOrderForPurchasedTrackedItem(SalesHeader, Item, LotNos, Qty);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '3,0,2', '0,2,3');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '0,2,3', '0,2,3');

        // [WHEN] Carry out three iterations of posting the order.
        PostSalesOrderIterativelyWithShipAndInvoiceOption(SalesHeader, TempTrackingSpec, LotNos, 3);

        // [THEN] Each iteration of posting generated value entries with "Item Ledger Entry Quantity" = "QS-i" and "Invoiced Quantity" = "QI-i".
        // The verification done in VerifyValueEntriesAfterGivenEntryNo function.

        // [THEN] Sum of quantity in the item ledger each lot = 5.
        // [THEN] Sum of shipped and invoiced quantity on Sales Shipment Lines = 10.
        // [THEN] The sales order is deleted after posting.
        VerifyPostedSalesOrder(SalesHeader, Item."No.", LotNos, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithLotTrackingAndPartialQtyShipAndInvoiceQtyToInvoiceMuchLessFullQty()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Item Tracking]
        // [SCENARIO 217787] Sales order for a lot-tracked item can be posted if "Qty. to Invoice" > "Quantity Shipped" for a current iteration of posting, yet overall shipped quantity will be much greater than overall invoiced quantity after the posting.
        Initialize();
        Qty := 10;

        // [GIVEN] Lot-tracked item.
        // [GIVEN] Two lots are in the inventory. Purchased quantity of each lot = 5 pcs.
        // [GIVEN] Lot-tracked sales order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Ship" ("QS-1") = 1, "Qty. to Invoice" ("QI-1") = 0.
        // [GIVEN] At the 2nd iteration "QS-2" = 8, "QI-2" = 4. Thereby, "QI-2" > "QS-1", but ("QI-1" + "QI-2") << ("QS-1" + "QS-2").
        // [GIVEN] At the 3rd iteration the order is completely posted.
        CreateSalesOrderForPurchasedTrackedItem(SalesHeader, Item, LotNos, Qty);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '0,4,1', '0,2,3');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '1,4,0', '0,2,3');

        // [WHEN] Carry out three iterations of posting the order.
        PostSalesOrderIterativelyWithShipAndInvoiceOption(SalesHeader, TempTrackingSpec, LotNos, 3);

        // [THEN] Each iteration of posting generated value entries with "Item Ledger Entry Quantity" = "QS-i" and "Invoiced Quantity" = "QI-i".
        // The verification done in VerifyValueEntriesAfterGivenEntryNo function.

        // [THEN] Sum of quantity in the item ledger each lot = 5.
        // [THEN] Sum of shipped and invoiced quantity on Sales Shipment Lines = 10.
        // [THEN] The sales order is deleted after posting.
        VerifyPostedSalesOrder(SalesHeader, Item."No.", LotNos, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithLotTrackingAndPartialQtyShipAndInvoiceQtyToInvoiceEqFullQty()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Item Tracking]
        // [SCENARIO 217787] Sales order for a lot-tracked item can be posted if "Qty. to Invoice" > "Quantity Shipped" for a current iteration of posting, yet overall shipped quantity will be equal to overall invoiced quantity after the posting.
        Initialize();
        Qty := 10;

        // [GIVEN] Lot-tracked item.
        // [GIVEN] Two lots are in the inventory. Purchased quantity of each lot = 5 pcs.
        // [GIVEN] Lot-tracked sales order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Ship" ("QS-1") = 4, "Qty. to Invoice" ("QI-1") = 0.
        // [GIVEN] At the 2nd iteration "QS-2" = 1, "QI-2" = 5. Thereby, "QI-2" > "QS-1" and ("QI-1" + "QI-2") = ("QS-1" + "QS-2").
        // [GIVEN] At the 3rd iteration the order is completely posted.
        CreateSalesOrderForPurchasedTrackedItem(SalesHeader, Item, LotNos, Qty);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '2,1,2', '0,3,2');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '2,0,3', '0,2,3');

        // [WHEN] Carry out three iterations of posting the order.
        PostSalesOrderIterativelyWithShipAndInvoiceOption(SalesHeader, TempTrackingSpec, LotNos, 3);

        // [THEN] Each iteration of posting generated value entries with "Item Ledger Entry Quantity" = "QS-i" and "Invoiced Quantity" = "QI-i".
        // The verification done in VerifyValueEntriesAfterGivenEntryNo function.

        // [THEN] Sum of quantity in the item ledger each lot = 5.
        // [THEN] Sum of shipped and invoiced quantity on Sales Shipment Lines = 10.
        // [THEN] The sales order is deleted after posting.
        VerifyPostedSalesOrder(SalesHeader, Item."No.", LotNos, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithLotTrackingAndPartialQtyShipAndInvoiceCheckItemTrackingLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Order] [Item Tracking]
        // [SCENARIO 217787] "Quantity Handled" and "Quantity Invoiced" in item tracking lines should be equal to actually shipped and invoiced quantity in lot-tracked sales order.
        Initialize();

        // [GIVEN] Lot-tracked item.
        // [GIVEN] Two lots are in the inventory. Purchased quantity of each lot = 5 pcs.
        // [GIVEN] Lot-tracked sales order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Ship" ("QS-1") = 8, "Qty. to Invoice" ("QI-1") = 3.
        CreateSalesOrderForPurchasedTrackedItem(SalesHeader, Item, LotNos, 10);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '4,0,0', '0,0,0');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '4,0,0', '3,0,0');

        // [WHEN] Carry out the first iteration of posting the order.
        PostSalesOrderIterativelyWithShipAndInvoiceOption(SalesHeader, TempTrackingSpec, LotNos, 1);

        // [THEN] "Quantity Handled" in item tracking lines = 8, "Quantity Invoiced" = 3.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        VerifyTrackingSpecification(
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", LotNos[1], -4, 0);
        VerifyTrackingSpecification(
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", LotNos[2], -4, -3);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderWithLotTrackingAndPartialQtyReceiveAndInvoiceQtyToInvoiceLessQtyReceived()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [Item Tracking]
        // [SCENARIO 217787] Purchase order for a lot-tracked item can be simultaneously received and invoiced, if "Qty. to Invoice" < "Quantity Received" for a current iteration of posting.
        Initialize();
        Qty := 10;

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Lot-tracked Purchase Order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Receive" ("QR-1") = 3, "Qty. to Invoice" ("QI-1") = 2.
        // [GIVEN] At the 2nd iteration "QR-2" = 2, "QI-2" = 2. Thereby, "QI-2" < "QR-1".
        // [GIVEN] At the 3rd iteration the order is completely posted.
        CreatePurchaseOrderWithItemTracking(PurchaseHeader, LotNos, Item."No.", Qty);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '1,1,3', '1,0,4');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '2,1,2', '1,2,2');

        // [WHEN] Carry out three iterations of posting the order.
        PostPurchaseOrderIterativelyWithReceiveAndInvoiceOption(PurchaseHeader, TempTrackingSpec, LotNos, 3);

        // [THEN] Each iteration of posting generated value entries with "Item Ledger Entry Quantity" = "QR-i" and "Invoiced Quantity" = "QI-i".
        // The verification done in VerifyValueEntriesAfterGivenEntryNo function.

        // [THEN] Sum of quantity in the item ledger each lot = 5.
        // [THEN] Sum of received and invoiced quantity on Purch. Receipt Lines = 10.
        // [THEN] The purchase order is deleted after posting.
        VerifyPostedPurchaseOrder(PurchaseHeader, Item."No.", LotNos, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderWithLotTrackingAndPartialQtyReceiveAndInvoiceQtyToInvoiceEqQtyReceived()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [Item Tracking]
        // [SCENARIO 217787] Purchase order for a lot-tracked item can be simultaneously received and invoiced if "Qty. to Invoice" = "Quantity Received" for a current iteration of posting.
        Initialize();
        Qty := 10;

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Lot-tracked Purchase Order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Receive" ("QR-1") = 4, "Qty. to Invoice" ("QI-1") = 2.
        // [GIVEN] At the 2nd iteration "QR-2" = 2, "QI-2" = 4. Thereby, "QI-2" = "QR-1".
        // [GIVEN] At the 3rd iteration the order is completely posted.
        CreatePurchaseOrderWithItemTracking(PurchaseHeader, LotNos, Item."No.", Qty);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '3,0,2', '2,1,2');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '1,2,2', '0,3,2');

        // [WHEN] Carry out three iterations of posting the order.
        PostPurchaseOrderIterativelyWithReceiveAndInvoiceOption(PurchaseHeader, TempTrackingSpec, LotNos, 3);

        // [THEN] Each iteration of posting generated value entries with "Item Ledger Entry Quantity" = "QR-i" and "Invoiced Quantity" = "QI-i".
        // The verification done in VerifyValueEntriesAfterGivenEntryNo function.

        // [THEN] Sum of quantity in the item ledger each lot = 5.
        // [THEN] Sum of received and invoiced quantity on Purch. Receipt Lines = 10.
        // [THEN] The purchase order is deleted after posting.
        VerifyPostedPurchaseOrder(PurchaseHeader, Item."No.", LotNos, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderWithLotTrackingAndPartialQtyReceiveAndInvoiceQtyToInvoiceLittleLessFullQty()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [Item Tracking]
        // [SCENARIO 217787] Purchase order for a lot-tracked item can be posted if "Qty. to Invoice" > "Quantity Received" for a current iteration of posting, yet overall received quantity will be little greater than overall invoiced quantity after postin
        Initialize();
        Qty := 10;

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Lot-tracked Purchase Order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Receive" ("QR-1") = 3, "Qty. to Invoice" ("QI-1") = 0.
        // [GIVEN] At the 2nd iteration "QR-2" = 2, "QI-2" = 4. Thereby, "QI-2" > "QR-1", but ("QI-1" + "QI-2") < ("QR-1" + "QR-2").
        // [GIVEN] At the 3rd iteration the order is completely posted.
        CreatePurchaseOrderWithItemTracking(PurchaseHeader, LotNos, Item."No.", Qty);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '3,0,2', '0,2,3');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '0,2,3', '0,2,3');

        // [WHEN] Carry out three iterations of posting the order.
        PostPurchaseOrderIterativelyWithReceiveAndInvoiceOption(PurchaseHeader, TempTrackingSpec, LotNos, 3);

        // [THEN] Each iteration of posting generated value entries with "Item Ledger Entry Quantity" = "QR-i" and "Invoiced Quantity" = "QI-i".
        // The verification done in VerifyValueEntriesAfterGivenEntryNo function.

        // [THEN] Sum of quantity in the item ledger each lot = 5.
        // [THEN] Sum of received and invoiced quantity on Purch. Receipt Lines = 10.
        // [THEN] The purchase order is deleted after posting.
        VerifyPostedPurchaseOrder(PurchaseHeader, Item."No.", LotNos, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderWithLotTrackingAndPartialQtyReceiveAndInvoiceQtyToInvoiceMuchLessFullQty()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [Item Tracking]
        // [SCENARIO 217787] Purchase order for a lot-tracked item can be posted if "Qty. to Invoice" > "Quantity Received" for a current iteration of posting, yet overall received quantity will be much greater than overall invoiced quantity after posting.
        Initialize();
        Qty := 10;

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Lot-tracked Purchase Order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Receive" ("QR-1") = 1, "Qty. to Invoice" ("QI-1") = 0.
        // [GIVEN] At the 2nd iteration "QR-2" = 8, "QI-2" = 4. Thereby, "QI-2" > "QR-1", but ("QI-1" + "QI-2") << ("QR-1" + "QR-2").
        // [GIVEN] At the 3rd iteration the order is completely posted.
        CreatePurchaseOrderWithItemTracking(PurchaseHeader, LotNos, Item."No.", Qty);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '0,4,1', '0,2,3');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '1,4,0', '0,2,3');

        // [WHEN] Carry out three iterations of posting the order.
        PostPurchaseOrderIterativelyWithReceiveAndInvoiceOption(PurchaseHeader, TempTrackingSpec, LotNos, 3);

        // [THEN] Each iteration of posting generated value entries with "Item Ledger Entry Quantity" = "QR-i" and "Invoiced Quantity" = "QI-i".
        // The verification done in VerifyValueEntriesAfterGivenEntryNo function.

        // [THEN] Sum of quantity in the item ledger each lot = 5.
        // [THEN] Sum of received and invoiced quantity on Purch. Receipt Lines = 10.
        // [THEN] The purchase order is deleted after posting.
        VerifyPostedPurchaseOrder(PurchaseHeader, Item."No.", LotNos, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderWithLotTrackingAndPartialQtyReceiveAndInvoiceQtyToInvoiceEqFullQty()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [Item Tracking]
        // [SCENARIO 217787] Purchase order for a lot-tracked item can be posted if "Qty. to Invoice" > "Quantity Shipped" for a current iteration of posting, yet overall received quantity will be equal to overall invoiced quantity after posting.
        Initialize();
        Qty := 10;

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Lot-tracked Purchase Order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Receive" ("QR-1") = 4, "Qty. to Invoice" ("QI-1") = 0.
        // [GIVEN] At the 2nd iteration "QR-2" = 1, "QI-2" = 5. Thereby, "QI-2" > "QR-1" and ("QI-1" + "QI-2") = ("QR-1" + "QR-2").
        // [GIVEN] At the 3rd iteration the order is completely posted.
        CreatePurchaseOrderWithItemTracking(PurchaseHeader, LotNos, Item."No.", Qty);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '2,1,2', '0,3,2');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '2,0,3', '0,2,3');

        // [WHEN] Carry out three iterations of posting the order.
        PostPurchaseOrderIterativelyWithReceiveAndInvoiceOption(PurchaseHeader, TempTrackingSpec, LotNos, 3);

        // [THEN] Each iteration of posting generated value entries with "Item Ledger Entry Quantity" = "QR-i" and "Invoiced Quantity" = "QI-i".
        // The verification done in VerifyValueEntriesAfterGivenEntryNo function.

        // [THEN] Sum of quantity in the item ledger each lot = 5.
        // [THEN] Sum of received and invoiced quantity on Purch. Receipt Lines = 10.
        // [THEN] The purchase order is deleted after posting.
        VerifyPostedPurchaseOrder(PurchaseHeader, Item."No.", LotNos, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderWithLotTrackingAndPartialQtyReceiveAndInvoiceCheckItemTrackingLines()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        LotNos: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Order] [Item Tracking]
        // [SCENARIO 217787] "Quantity Handled" and "Quantity Invoiced" in item tracking lines should be equal to actually received and invoiced quantity in lot-tracked purchase order.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Lot-tracked Purchase Order for 10 pcs.
        // [GIVEN] At the 1st iteration of posting "Qty. to Ship" ("QR-1") = 8, "Qty. to Invoice" ("QI-1") = 3.
        CreatePurchaseOrderWithItemTracking(PurchaseHeader, LotNos, Item."No.", 10);
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[1], '4,0,0', '0,0,0');
        FillTempItemTrackingBuf(TempTrackingSpec, LotNos[2], '4,0,0', '3,0,0');

        // [WHEN] Carry out the first iteration of posting the order.
        PostPurchaseOrderIterativelyWithReceiveAndInvoiceOption(PurchaseHeader, TempTrackingSpec, LotNos, 1);

        // [THEN] "Quantity Handled" in item tracking lines = 8, "Quantity Invoiced" = 3.
        FindPurchaseLineByHeader(PurchaseLine, PurchaseHeader);
        VerifyTrackingSpecification(
          DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", LotNos[1], 4, 0);
        VerifyTrackingSpecification(
          DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", LotNos[2], 4, 3);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,GetShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostInvoiceOnDropShipmentSalesOrderDoesNotDeletePurchaseLink()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 230306] When a sales order associated with a purchase order via drop shipment, is invoiced by another document, purchase order reference should not be removed

        Initialize();

        // [GIVEN] Sales order "SO" with a "Drop Shipment" purchasing code
        // [GIVEN] Create a purchase order and get drop shipment lines into it
        CreateDropShipmentSalesAndPurchase(SalesHeaderOrder, PurchaseHeader);

        // [GIVEN] Post shipment from the sales order
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [WHEN] Create a sales invoice for the sales order "SO", post the invoice
        CreateSalesInvoiceFromShipment(SalesHeaderInvoice, SalesHeaderOrder);
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, true);

        // [THEN] Purchase line retains the reference to the sales order line in fields "Sales Order No." and "Sales Order Line No."
        // [THEN] Sales line is linked to the purchase via fields "Purchase Order No," and "Purchase Line No."
        FindPurchaseLineByHeader(PurchaseLine, PurchaseHeader);
        FindSalesLine(SalesLine, SalesHeaderOrder."Document Type", SalesHeaderOrder."No.");

        PurchaseLine.TestField("Sales Order No.", SalesLine."Document No.");
        PurchaseLine.TestField("Sales Order Line No.", SalesLine."Line No.");

        SalesLine.TestField("Purchase Order No.", PurchaseLine."Document No.");
        SalesLine.TestField("Purch. Order Line No.", PurchaseLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,GetShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CanDeleteSalesOrderWithDropShipmentAfterInvoicing()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 230306] Sales order associated with a purchase via drop shipment, can be deleted after it is invoiced by a separate Invoice document

        Initialize();

        // [GIVEN] Sales order "SO" with a "Drop Shipment" purchasing code
        // [GIVEN] Create a purchase order and get drop shipment lines into it
        CreateDropShipmentSalesAndPurchase(SalesHeaderOrder, PurchaseHeader);

        // [GIVEN] Post shipment from the sales order
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Create a sales invoice for the sales order "SO", post the invoice
        CreateSalesInvoiceFromShipment(SalesHeaderInvoice, SalesHeaderOrder);
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, true);

        // [WHEN] Delete the sales order "SO"
        SalesHeaderOrder.Find();
        SalesHeaderOrder.Delete(true);

        // [THEN] Sales order is deleted
        Assert.IsFalse(SalesHeaderOrder.Find(), StrSubstNo(MustBeDeletedErr, SalesHeaderOrder."No."));
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure CannotDeleteSalesOrderWithDropShipmentBeforeInvoicing()
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 230306] Sales order associated with a purchase via drop shipment, cannot be deleted while it is not invoiced

        Initialize();

        // [GIVEN] Sales order "SO" with a "Drop Shipment" purchasing code
        CreateSalesOrderWithDropShipment(SalesHeader, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());

        // [GIVEN] Create a purchase order and get drop shipment lines into it
        CreatePurchaseOrderWithGetDropShipment(PurchHeader, SalesHeader."Sell-to Customer No.");

        // [WHEN] Try to delete the sales order
        asserterror SalesHeader.Delete(true);

        // [THEN] Error: "You cannot delete the order line because it is associated with purchase order"
        Assert.ExpectedError(SalesHeaderErr);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure LinkToBlanketOrderLineCanBeSetOnSalesLineForDropShipment()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderBlanketOrder: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        SalesLineBlanketOrder: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment] [Sales] [Order] [Blanket Order]
        // [SCENARIO 253613] You can set a link to blanket order line on sales line for drop shipment with the same location, variant and unit of measure code.
        Initialize();

        // [GIVEN] Blanket sales order with customer "C", item "I" and unit price "X".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeaderBlanketOrder, SalesLineBlanketOrder, SalesHeaderBlanketOrder."Document Type"::"Blanket Order",
          LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesLineBlanketOrder.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLineBlanketOrder.Modify(true);

        // [GIVEN] Sales order with customer "C", item "I" is set up for drop shipment.
        // [GIVEN] Create purchase order by getting sales order line.
        CreateSalesOrderWithDropShipment(
          SalesHeaderOrder, SalesLineBlanketOrder."Sell-to Customer No.", SalesLineBlanketOrder."No.");
        CreatePurchaseOrderWithGetDropShipment(PurchaseHeader, SalesHeaderOrder."Sell-to Customer No.");

        // [WHEN] Set a link to the blanket order line on the sales order line.
        FindSalesLine(SalesLineOrder, SalesHeaderOrder."Document Type", SalesHeaderOrder."No.");
        SalesLineOrder.Validate("Blanket Order No.", SalesLineBlanketOrder."Document No.");
        SalesLineOrder.Validate("Blanket Order Line No.", SalesLineBlanketOrder."Line No.");

        // [THEN] Unit price on the sales line is updated to "X".
        SalesLineOrder.TestField("Unit Price", SalesLineBlanketOrder."Unit Price");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure LinkToBlanketOrderLineCanBeSetOnPurchaseLineForDropShipment()
    var
        PurchHeaderOrder: Record "Purchase Header";
        PurchHeaderBlanketOrder: Record "Purchase Header";
        PurchLineOrder: Record "Purchase Line";
        PurchLineBlanketOrder: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Drop Shipment] [Purchase] [Order] [Blanket Order]
        // [SCENARIO 253613] You can set a link to blanket order line on purchase line for drop shipment with the same location, variant and unit of measure code.
        Initialize();

        // [GIVEN] Sales order with item "I" is set up for drop shipment.
        // [GIVEN] Create purchase order for vendor "V" by getting the sales order line.
        CreateSalesOrderWithDropShipment(
          SalesHeader, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        CreatePurchaseOrderWithGetDropShipment(PurchHeaderOrder, SalesHeader."Sell-to Customer No.");
        FindPurchaseLineByHeader(PurchLineOrder, PurchHeaderOrder);

        // [GIVEN] Blanket purchase order with vendor "V", item "I" and direct unit cost "X".
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchHeaderBlanketOrder, PurchLineBlanketOrder, PurchHeaderBlanketOrder."Document Type"::"Blanket Order",
          PurchLineOrder."Buy-from Vendor No.", PurchLineOrder."No.", LibraryRandom.RandInt(10), '', WorkDate());
        PurchLineBlanketOrder.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchLineBlanketOrder.Modify(true);

        // [WHEN] Set a link to the blanket order line on the purchase order line.
        PurchLineOrder.Validate("Blanket Order No.", PurchLineBlanketOrder."Document No.");
        PurchLineOrder.Validate("Blanket Order Line No.", PurchLineBlanketOrder."Line No.");

        // [THEN] Direct unit cost on the purchase line is updated to "X".
        PurchLineOrder.TestField("Direct Unit Cost", PurchLineBlanketOrder."Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ConfirmOnDeleteSalesReturnOrderWithTrackedLine()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo: Text;
    begin
        // [FEATURE] [Sales] [Return Order] [Item Tracking] [UI]
        // [SCENARIO 256931] When you delete a sales document with a tracked line, the confirmation message for deletion should include the caption of document type ("Quote", "Order", "Invoice", etc.) you intend to delete.
        Initialize();

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Sales return order "SRO" with a lot-tracked line.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo(),
          Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignGivenLotNos);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Delete the sales return order.
        LibraryVariableStorage.Enqueue(StrSubstNo('Return Order %1 has item reservation.', SalesHeader."No."));
        SalesHeader.Delete(true);

        // [THEN] A confirmation message "Return Order "SRO" has item reservation." is shown.
        // Verification is done in ConfirmHandler.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ConfirmOnDeletePurchaseOrderWithTrackedLine()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LotNo: Text;
    begin
        // [FEATURE] [Purchase] [Order] [Item Tracking] [UI]
        // [SCENARIO 256931] When you delete a purchase document with a tracked line, the confirmation message for deletion should include the caption of document type ("Quote", "Order", "Invoice", etc.) you intend to delete.
        Initialize();

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Purchase order "PO" with a lot-tracked line.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(),
          Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignGivenLotNos);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        PurchaseLine.OpenItemTrackingLines();

        // [WHEN] Delete the purchase order.
        LibraryVariableStorage.Enqueue(StrSubstNo('Order %1 has item reservation.', PurchaseHeader."No."));
        PurchaseHeader.Delete(true);

        // [THEN] A confirmation message "Order "PO" has item reservation." is shown.
        // Verification is done in ConfirmHandler.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ConfirmOnDeleteProdOrderLineWithTrackedLine()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        LotNo: Text;
    begin
        // [FEATURE] [Production Order] [Item Tracking] [UI]
        // [SCENARIO 256931] When you delete a production order with a tracked line, the confirmation message for deletion should include the caption of prod. order status ("Simulated", "Planned", "Released", etc.) you intend to delete.
        Initialize();

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Released production order "RPO" with a lot-tracked line.
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignGivenLotNos);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ProductionOrder.Quantity);
        ProdOrderLine.OpenItemTrackingLines();

        // [WHEN] Delete the production order.
        LibraryVariableStorage.Enqueue(StrSubstNo('Released production order %1 has item reservation.', ProductionOrder."No."));
        ProductionOrder.Delete(true);

        // [THEN] A confirmation message "Released production order "RPO" has item reservation." is shown.
        // Verification is done in ConfirmHandler.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ConfirmOnDeleteTransferLineWithTrackedLine()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LotNo: Text;
    begin
        // [FEATURE] [Transfer] [Item Tracking] [UI]
        // [SCENARIO 256931] When you delete a transfer order with a tracked line, the confirmation message for deletion should begin as follows: "Transfer Order ... has item reservation."
        Initialize();

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Transfer order "TO" with a lot-tracked line.
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationBlue.Code, LocationRed.Code, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10));
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignGivenLotNos);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(TransferLine.Quantity);
        LibraryVariableStorage.Enqueue(AvailabilityWarningsConfirmMsg);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);

        // [WHEN] Delete the transfer order.
        LibraryVariableStorage.Enqueue(StrSubstNo('Transfer order %1 has item reservation.', TransferHeader."No."));
        TransferHeader.Delete(true);

        // [THEN] A confirmation message "Transfer order "TO" has item reservation." is shown.
        // Verification is done in ConfirmHandler.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptWithJobTaskWhenInventorySetupPreventNegativeInventory()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemRegister: Record "Item Register";
        Quantity: Decimal;
        OrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Undo] [Receipt] [Job]
        // [SCENARIO 258978] Undo purchase receipt with job and task is posting with prevent negative inventory in inventory setup.
        Initialize();

        // [GIVEN] "Prevent Negative Inventory" in "Inventory Setup" is on
        LibraryInventory.SetPreventNegativeInventory(true);

        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Item "I" is bought with "Job Task" "T" in Quantity "Q"
        OrderNo := CreateAndPostPurchaseDocumentWithItemAndJob(JobTask, PurchaseHeader."Document Type"::Order, Item."No.", Quantity);

        // [WHEN] Undo purchase receipt
        FindReceiptLine(PurchRcptLine, OrderNo, Item."No.", '');

        LibraryVariableStorage.Enqueue(UndoReceiptMsg);  // Used in ConfirmHandler.
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] Last item register contains two item ledger entries, first positive with quantity "Q", second negative with quantity -"Q", second is applied to first
        // [THEN] Type of first is "Neg. Adjmnt", type of second is Purchase
        VerifyLastItemRegister(ItemRegister, Quantity);
        VerifyItemLedgerEntryNegativeAdjmtPurchase(ItemRegister);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReturnShipmentWithJobTaskWhenInventorySetupPreventNegativeInventory()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        ItemRegister: Record "Item Register";
        Quantity: Decimal;
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Undo] [Return Shipment] [Job]
        // [SCENARIO 258978] Undo purchase return shipment with job and task is posting with prevent negative inventory in inventory setup.
        Initialize();

        // [GIVEN] "Prevent Negative Inventory" in "Inventory Setup" is on
        LibraryInventory.SetPreventNegativeInventory(true);

        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Item "I" is bought with "Job Task" "T" in Quantity "Q"
        CreateAndPostPurchaseDocumentWithItemAndJob(JobTask, PurchaseHeader."Document Type"::Order, Item."No.", Quantity);

        // [GIVEN] Item "I" is returned to vendor with same "Job Task" "T" in Quantity "Q"
        ReturnOrderNo := CreateAndPostPurchaseDocumentWithItemAndJob(
            JobTask, PurchaseHeader."Document Type"::"Return Order", Item."No.", Quantity);

        // [WHEN] Undo purchase return shipment
        FindReturnShipmentLine(ReturnShipmentLine, ReturnOrderNo, Item."No.");
        LibraryVariableStorage.Enqueue(UndoReturnShipmentMsg);  // Used in ConfirmHandler.
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);

        // [THEN] Last item register contains two item ledger entries, first positive with quantity "Q", second negative with quantity -"Q", second is applied to first
        // [THEN] Type of first is Purchase, type of second is "Neg. Adjmnt"
        VerifyLastItemRegister(ItemRegister, Quantity);
        VerifyItemLedgerEntryPurchaseNegativeAdjmt(ItemRegister);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LeadTimeFromItemCardGoesFirstIfLeadTimeFromItemVendorIsEmpty()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemVendor: Record "Item Vendor";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LeadTimeCalculation: DateFormula;
    begin
        // [FEATURE] [Lead Time] [Purchase]
        // [SCENARIO 266514] If lead time is empty in Item Vendor it must be taken from Item Card

        Initialize();

        // [GIVEN] Create Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Item with lead time
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Evaluate(LeadTimeCalculation, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        Item.Validate("Lead Time Calculation", LeadTimeCalculation);
        Item.Modify(true);

        // [GIVEN] Create Item Vendor with empty Lead Time Calculation
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");

        // [GIVEN] Create Purch. Header
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [WHEN] Create Purchase Line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Verify Lead Time Calculation is equal to that field in Item Card
        PurchaseLine.TestField("Lead Time Calculation", LeadTimeCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LeadTimeFromItemVendorPrioritizedOverLeadTimeFromItemCardIfNotEmpty()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemVendor: Record "Item Vendor";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LeadTimeCalculationItemCard: DateFormula;
        LeadTimeCalculationItemVendor: DateFormula;
    begin
        // [FEATURE] [Lead Time] [Purchase]
        // [SCENARIO 266514] If lead time is NOT empty in Item Vendor it must be prioritized over lead time from Item Card

        Initialize();

        // [GIVEN] Create Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Item with Lead Time Calculation
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Evaluate(LeadTimeCalculationItemCard, '<' + Format(LibraryRandom.RandIntInRange(1, 10)) + 'D>');
        Item.Validate("Lead Time Calculation", LeadTimeCalculationItemCard);
        Item.Modify(true);

        // [GIVEN] Create Item Vendor with different Lead Time Calculation
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");
        Evaluate(LeadTimeCalculationItemVendor, '<' + Format(LibraryRandom.RandIntInRange(11, 20)) + 'D>');
        ItemVendor.Validate("Lead Time Calculation", LeadTimeCalculationItemVendor);
        ItemVendor.Modify(true);

        // [GIVEN] Create Purch. Header
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [WHEN] Create Purchase Line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Verify Lead Time Calculation is equal to that field from Item Vendor, not from Item Card
        PurchaseLine.TestField("Lead Time Calculation", LeadTimeCalculationItemVendor);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PartialPurchaseInvoiceFailsQtyToInvoiceInPurchLineLessThanItemTrackingLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Receipt] [Invoice]
        // [SCENARIO 272485] When "Qty. to Invoice" in purchase line is less than "Qty. to Invoice" in item tracking lines, the posting fails.

        Initialize();

        // [GIVEN] Purchase order for a lot tracked item, Quantity = 30 pcs
        CreateItemWithItemTrackingCode(Item, true, false, '', '');
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 30);

        // [GIVEN] Assign 3 lot nos on the purchase line, 10 pcs in each lot, and post purchase receipt
        EnqueueLotAssignment(3, 10);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Set "Qty. to Invoice" = 12 in the purchase line, do not update "Qty. to Invoice" in item tracking lines, and post the purchase invoice
        asserterror PostPartialPurchaseInvoice(PurchaseHeader, PurchaseLine, 12);

        // [THEN] Error message "The quantity to invoice does not match the quantity defined in item tracking" is thrown.
        Assert.ExpectedError(QtyToInvoiceDoesNotMatchItemTrackingErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PartialPurchaseInvoiceSucceedsQtyToInvoiceInPurchLineEqualsItemTrackingLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Receipt] [Invoice]
        // [SCENARIO 272485] When "Qty. to Invoice" in purchase line is equal to "Qty. to Invoice" in item tracking lines, the invoice is successfully posted.

        Initialize();

        // [GIVEN] Purchase order for a lot tracked item, Quantity = 30 pcs
        CreateItemWithItemTrackingCode(Item, true, false, '', '');
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 30);

        // [GIVEN] Assign 3 lot nos on the purchase line, 10 pcs in each lot, and post purchase receipt
        EnqueueLotAssignment(3, 10);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Set "Qty. to Invoice" = 20 in the purchase line, set "Qty. to Invoice" = 0 on the first lot in item tracking lines, and post the purchase invoice.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::UpdateQtyOnFirstLine);
        PurchaseLine.Find();
        PurchaseLine.OpenItemTrackingLines();
        PostPartialPurchaseInvoice(PurchaseHeader, PurchaseLine, 20);

        // [THEN] Invoice is successfully posted.
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.SetRange("No.", Item."No.");
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Quantity, 20);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSalesInvoiceFailsQtyToInvoiceInSalesLineLessThanItemTrackingLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [FEATURE] [Item Tracking] [Sales] [Shipment] [Invoice]
        // [SCENARIO 272485] When "Qty. to Invoice" in sales line is less than "Qty. to Invoice" in item tracking lines, the posting fails.

        Initialize();

        // [GIVEN] Lot tracked item with inventory stock of 30 pcs. Item purchased in 3 lots, 10 pcs in each lot.
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 30);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create and ship sales order for the whole stock
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 30);
        EnqueueLotAssignment(3, 10);
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Set "Qty. to Invoice" = 12 in the sales line, do not update "Qty. to Invoice" in item tracking lines, and post the sales invoice
        asserterror PostPartialSalesInvoice(SalesHeader, SalesLine, 12);

        // [THEN] Error message "The quantity to invoice does not match the quantity defined in item tracking" is thrown.
        Assert.ExpectedError(QtyToInvoiceDoesNotMatchItemTrackingErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSalesInvoiceSucceedsQtyToInvoiceInSalesLineEqualsItemTrackingLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // [FEATURE] [Item Tracking] [Sales] [Shipment] [Invoice]
        // [SCENARIO 272485] When "Qty. to Invoice" in sales line is equal to "Qty. to Invoice" in item tracking lines, the invoice is successfully posted.

        Initialize();

        // [GIVEN] Lot tracked item with inventory stock of 30 pcs. Item purchased in 3 lots, 10 pcs in each lot.
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 30);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create and ship sales order for the whole stock
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 30);
        EnqueueLotAssignment(3, 10);
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Set "Qty. to Invoice" = 20 in the sales line, set "Qty. to Invoice" = 0 on the first lot in item tracking lines, and post the sales invoice.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::UpdateQtyOnFirstLine);
        SalesLine.Find();
        SalesLine.OpenItemTrackingLines();
        PostPartialSalesInvoice(SalesHeader, SalesLine, 20);

        // [THEN] Invoice is successfully posted
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.SetRange("No.", Item."No.");
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Quantity, 20);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExplodeBomHandler')]
    [Scope('OnPrem')]
    procedure ExplodeBOMDiffResourceUnitOfMeasure()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        Resource: Record Resource;
        UnitOfMeasure: Record "Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        Customer: Record Customer;
        QtyPerUoM: Decimal;
        QtyPerLine: Decimal;
        ItemQuantity: Decimal;
    begin
        // [FEATURE] [Sales] [Explode BOM] [Resource Unit of Measure]
        // [SCENARIO 288842] Function "Explode BOM" uses Resource's additional "Unit of Measure" as chosen in BOM Component

        Initialize();

        // [GIVEN] Created Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Resource "RES01" with "Unit Price" = 100 for Base Unit of Measure "HOUR" compatible with Customer's VAT Posting Setup
        LibraryResource.CreateResource(Resource, Customer."VAT Bus. Posting Group");

        // [GIVEN] Additional Unit of Measure for "RES01": "MIN" = 0.01667 "HOUR"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        QtyPerUoM := LibraryRandom.RandDec(10, 5);
        LibraryResource.CreateResourceUnitOfMeasure(ResourceUnitOfMeasure, Resource."No.", UnitOfMeasure.Code, QtyPerUoM);

        // [GIVEN] Item "IT01" Created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] BOM Component for "IT01": Resource "RES01" with "Quantity per" = 30 and "Unit of Measure Code" = "MIN"
        QtyPerLine := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateBOMComponent(
          BOMComponent,
          Item."No.",
          BOMComponent.Type::Resource,
          Resource."No.",
          QtyPerLine,
          UnitOfMeasure.Code);

        // [GIVEN] Created Sales Order "SO01"
        // [GIVEN] Sales Line "SL01" for "SO01" with Item "IT01", Quantity = 2
        ItemQuantity := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ItemQuantity);

        // [WHEN] Run "Explode BOM" function on the item "IT01"
        LibrarySales.ExplodeBOM(SalesLine);

        // [THEN] Sales Line "SL02"for Resource "RES01" is created
        // [THEN] "Unit of Measure" on "SL02" = "MIN"
        // [THEN] "Quantity (Base)" on "SL02" = 1
        // [THEN] "Quantity" on "SL02" = 60
        // [THEN] "Amount" on "SL02" = 100
        // [THEN] "Unit Price" on "SL02" = 1.667

        VerifyResourceSalesLine(
          SalesHeader,
          Resource."No.",
          UnitOfMeasure.Code,
          ItemQuantity * QtyPerLine * QtyPerUoM,
          ItemQuantity * QtyPerLine,
          Resource."Unit Price" * ItemQuantity * QtyPerLine * QtyPerUoM,
          Resource."Unit Price" * QtyPerUoM);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure QtyToInvoicePermittedMismatchBetweenPurchaseLineAndTrackingForSingleLot()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Order]
        // [SCENARIO 287310] "Qty. to Invoice" in item tracking can be greater than "Qty. to Invoice" on purchase line if the item tracking contains a single lot.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Purchase order for 10 pcs of the item.
        // [GIVEN] Open item tracking lines on the purchase line and assign one lot with "Qty. to Handle" = "Qty. to Invoice" = 10.
        // [GIVEN] Post the receipt for 2 pcs.
        EnqueueLotAssignment(1, 10);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, '', Item."No.", 10, '', true);
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 2, 0);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Post the invoice for 2 pcs.
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 0, 2);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] 2 pcs have been invoiced on the purchase line. 8 pcs remain to invoice.
        VerifyInvoiceQtyOnPurchaseLine(PurchaseLine, 8, 2);

        // [THEN] "Qty. to Invoice" in the item tracking = 8 pcs.
        VerifyQtyToInvoiceInItemTrackingOnPurchLine(PurchaseLine, 8);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure QtyToInvoicePermittedMismatchBetweenPurchaseLineAndTrackingForMultipleLots()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LotNos: array[2] of Code[20];
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Order]
        // [SCENARIO 287310] "Qty. to Invoice" in item tracking can be greater than "Qty. to Invoice" on purchase line if there are several lots in the item tracking, but only one lot remains to be invoiced.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Purchase order for 20 pcs of the item.
        // [GIVEN] Open item tracking lines on the purchase line and assign two lots "L1" and "L2", each for 10 pcs.
        CreatePurchaseOrderWithItemTracking(PurchaseHeader, LotNos, Item."No.", 20);

        // [GIVEN] Update "Qty. to Handle" = "Qty. to Invoice" for lot "L1" to 0.
        // [GIVEN] Receive and invoice 10 pcs. Lot "L2" is now fully posted.
        FindPurchaseLineByHeader(PurchaseLine, PurchaseHeader);
        EnqueueLotUpdate(LotNos[1], 0, 0);
        PurchaseLine.OpenItemTrackingLines();
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 10, 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        EnqueueLotUpdate(LotNos[1], 0, 0);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Update "Qty. to Handle" = "Qty. to Invoice" for lot "L1" to 10 pcs.
        // [GIVEN] Post the receipt for 2 pcs.
        EnqueueLotUpdate(LotNos[1], 10, 10);
        PurchaseLine.OpenItemTrackingLines();
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 2, 2);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Post the invoice for 2 pcs.
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] 12 pcs have been invoiced on the purchase line (10 pcs of lot "L2", 2 pcs of lot "L1"); 8 pcs remain to invoice.
        VerifyInvoiceQtyOnPurchaseLine(PurchaseLine, 8, 12);

        // [THEN] "Qty. to Invoice" in the item tracking = 8 pcs.
        VerifyQtyToInvoiceInItemTrackingOnPurchLine(PurchaseLine, 8);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure InvoicingPartiallyReceivedPurchaseWithQtyToInvoiceMismatch()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Order]
        // [SCENARIO 287310] Partially invoicing partially received purchase order with "Qty. to Invoice" on the item tracking greater than "Qty. to Invoice" on the purchase line.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Purchase order for 10 pcs of the item.
        // [GIVEN] Open item tracking lines on the purchase line and assign one lot with "Qty. to Handle" = "Qty. to Invoice" = 10.
        EnqueueLotAssignment(1, 10);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, '', Item."No.", 10, '', true);

        // [GIVEN] Post the receipt for 4 pcs twice, a total of 8 pcs.
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 4, 0);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 4, 0);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Post the invoice for 5 pcs.
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 0, 5);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] 5 pcs have been invoiced on the purchase line. 5 pcs remain to invoice.
        VerifyInvoiceQtyOnPurchaseLine(PurchaseLine, 5, 5);

        // [THEN] "Qty. to Invoice" in the item tracking = 5 pcs.
        VerifyQtyToInvoiceInItemTrackingOnPurchLine(PurchaseLine, 5);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ReceivingAndInvoicingPartiallyReceivedPurchaseWithQtyToInvoiceMismatch()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Order]
        // [SCENARIO 287310] Simultaneously receiving and invoicing partially received purchase order with "Qty. to Invoice" on the item tracking greater than "Qty. to Invoice" on the purchase line.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Purchase order for 10 pcs of the item.
        // [GIVEN] Open item tracking lines on the purchase line and assign one lot with "Qty. to Handle" = "Qty. to Invoice" = 10.
        EnqueueLotAssignment(1, 10);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, '', Item."No.", 10, '', true);

        // [GIVEN] Post the receipt for 4 pcs twice, a total of 8 pcs.
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 4, 0);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 4, 0);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Post the receipt for 2 pcs and the invoice for 9 pcs at the same time using "Receive and Invoice" option.
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 2, 9);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] 9 pcs have been invoiced on the purchase line. 1 pc remain to invoice.
        VerifyInvoiceQtyOnPurchaseLine(PurchaseLine, 1, 9);

        // [THEN] "Qty. to Invoice" in the item tracking = 1 pc.
        VerifyQtyToInvoiceInItemTrackingOnPurchLine(PurchaseLine, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure QtyToInvoiceMismatchNotAllowedInCaseOfLotNoUncertainty()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LotNos: array[2] of Code[20];
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Order]
        // [SCENARIO 287310] A user cannot invoice a purchase order if "Qty. to Handle" in item tracking does not match "Qty. to Invoice" on the purchase line and there is an uncertainty which lot to invoice.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Purchase order for 20 pcs of the item.
        // [GIVEN] Open item tracking lines on the purchase line and assign two lots "L1" and "L2", each for 10 pcs.
        CreatePurchaseOrderWithItemTracking(PurchaseHeader, LotNos, Item."No.", 20);
        FindPurchaseLineByHeader(PurchaseLine, PurchaseHeader);

        // [GIVEN] Post the receipt.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Set "Qty. to Invoice" on the purchase line to 15.
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 0, 15);

        // [WHEN] Post the invoice.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] "The quantity to invoice does not match the quantity defined in item tracking." error message is thrown.
        Assert.ExpectedError(QtyToInvoiceDoesNotMatchItemTrackingErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ReceivingAndInvoicingNewPurchaseWithQtyToInvoiceMismatch()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Order]
        // [SCENARIO 287310] Simultaneously receiving and invoicing new purchase order with "Qty. to Invoice" on the item tracking greater than "Qty. to Invoice" on the purchase line.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Purchase order for 10 pcs of the item.
        // [GIVEN] Open item tracking lines on the purchase line and assign one lot with "Qty. to Handle" = "Qty. to Invoice" = 10.
        EnqueueLotAssignment(1, 10);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, '', Item."No.", 10, '', true);
        UpdateQtysToPostOnPurchaseLine(PurchaseLine, 4, 2);

        // [WHEN] Post the receipt for 4 pcs and post the invoice for 2 pcs at the same time using "Receive and Invoice" option.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] 2 pcs have been invoiced on the purchase line. 8 pcs remain to invoice.
        VerifyInvoiceQtyOnPurchaseLine(PurchaseLine, 8, 2);

        // [THEN] "Qty. to Invoice" in the item tracking = 8 pcs.
        VerifyQtyToInvoiceInItemTrackingOnPurchLine(PurchaseLine, 8);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ReceivingAndInvoicingPartiallyShippedSalesWithQtyToInvoiceMismatch()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Item Tracking] [Sales] [Order]
        // [SCENARIO 287310] Simultaneously shipping and invoicing partially shipped sales order with "Qty. to Invoice" on the item tracking greater than "Qty. to Invoice" on the sales line.
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Purchase order for 10 pcs of the item.
        // [GIVEN] Open item tracking lines on the purchase line and assign one lot with "Qty. to Handle" = "Qty. to Invoice" = 10.
        // [GIVEN] Receive and invoice the purchase order.
        EnqueueLotAssignment(1, 10);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, '', Item."No.", 10, '', true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Sales order for 10 pcs of the item.
        // [GIVEN] Open item tracking lines on the sales line and select the purchased lot.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, SalesLine, Item."No.", 10, '');
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Post the shipment for 4 pcs twice, a total of 8 pcs.
        UpdateQtysToPostOnSalesLine(SalesLine, 4, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        UpdateQtysToPostOnSalesLine(SalesLine, 4, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Post the shipment for 2 pcs and the invoice for 9 pcs at the same time using "Ship and Invoice" option.
        UpdateQtysToPostOnSalesLine(SalesLine, 2, 9);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] 9 pcs have been invoiced on the sales line. 1 pc remain to invoice.
        VerifyInvoiceQtyOnSalesLine(SalesLine, 1, 9);

        // [THEN] "Qty. to Invoice" in the item tracking = 1 pc.
        VerifyQtyToInvoiceInItemTrackingOnSalesLine(SalesLine, -1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure PostDropShipmentPurchOrderWithIncorrectSalesOrderDimensions()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Purchase] [Drop Shipment] [Check] [Dimensions]
        // [SCENARIO 294326] Drop Shipments Purchase Order posting fails on incorrect Dimensions of the associated Sales Order
        Initialize();

        // [GIVEN] Customer "CU1", where dimension value 'Department','ADM' is default with "Code Mandatory"
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // [GIVEN] Sales Order "SO01", where "Sell-To Customer No." is "CU1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // [GIVEN] Dimension 'Department' deleted on Sales Order
        SalesHeader.Validate("Dimension Set ID", 0);
        SalesHeader.Modify(true);

        // [GIVEN] Sales Line 10000 with Drop Shipment purchasing code
        CreateSalesLineWithPurchasingCode(
          SalesHeader, SalesLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2), '', CreatePurchasingCode(false, true));

        // [GIVEN] Purchase Order "PO01" with linked Drop Shipment for sales line "SO01",10000
        CreatePurchaseOrderWithGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [WHEN] Post Purchase Order "PO01" with "Receive"
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Posting failed on Dimension Check for the Sales Order
        Assert.ExpectedError(
          StrSubstNo(
            'The dimensions used in Order %1 are invalid Select a Dimension Value Code for the Dimension Code %2 for Customer %3.',
            SalesHeader."No.", DimensionValue."Dimension Code", CustomerNo));
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure PostDropShipmentSalesOrderWithIncorrectPurchOrderDimensions()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Sales] [Purchase] [Drop Shipment] [Check] [Dimensions]
        // [SCENARIO 294326] Drop Shipments Purchase Order posting fails on incorrect Dimensions of the associated Sales Order
        Initialize();

        // [GIVEN] Vendor "VE01", where dimension value 'Department','ADM' is default with "Code Mandatory"
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // [GIVEN] Sales Order "SO01"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line 10000 with Drop Shipment purchasing code
        CreateSalesLineWithPurchasingCode(
          SalesHeader, SalesLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2), '', CreatePurchasingCode(false, true));

        // [GIVEN] Purchase Order "PO01" with linked Drop Shipment for sales line "SO01",10000 for Vendor "VE01" and Dimension 'Department' deleted
        CreatePurchaseHeaderWithSellToCustomerNo(PurchaseHeader, VendorNo, SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Validate("Dimension Set ID", 0);
        PurchaseHeader.Modify(true);
        LibraryPurchase.GetDropShipment(PurchaseHeader);

        // [WHEN] Post Purchase Order "PO01" with "Receive"
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Posting failed on Dimension Check for the Purchase Order
        Assert.ExpectedError(
          StrSubstNo(
            'The dimensions used in Order %1 are invalid Select a Dimension Value Code for the Dimension Code %2 for Vendor %3.',
            PurchaseHeader."No.", DimensionValue."Dimension Code", VendorNo));
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,GetShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderNormalLinesAfterDropShipmentIsPosted()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderInvoice: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 364833] Post sales order with normal lines after drop shipment line is posted
        Initialize();

        // [GIVEN] Sales Order has one line with drop shipment and a normal line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineWithPurchasingCode(
          SalesHeader, SalesLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(5, 10), '', CreatePurchasingCode(false, true));
        CreateSalesLine(SalesHeader, SalesLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(5, 10), '');

        // [GIVEN] Drop shipment line is posted entirely: posted and invoiced with associated purchase order
        CreatePurchaseOrderWithGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        CreateSalesInvoiceFromShipment(SalesHeaderInvoice, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, true);
        PurchaseHeader.Find();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Sales Order is finally posted
        SalesHeader.Find();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales shipment lines created for the second sales line
        VerifySalesShipmentLine(SalesLine."No.", SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiptDateOnDerivedTransferLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        NewDate: Date;
    begin
        // [FEATURE] [Transfer Order] [Receipt]
        // [SCENARIO 366904] Changing Receipt Date on a Transfer Line changes Receipt Dates on derived transfer lines
        Initialize();

        // [GIVEN] 100 PCS of Item on Location "BLUE" on 01-01-2022
        LibraryInventory.CreateItem(Item);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Item."No.", LibraryRandom.RandDec(100, 0), LocationBlue.Code, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Transfer Order from Location "BLUE" to Location "RED" for 10 PCS of Item with "Receipt Date" = 02-01-2022
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationBlue.Code, LocationRed.Code, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(
          TransferHeader, TransferLine, Item."No.",
          LibraryRandom.RandDec(PurchaseLine.Quantity, 2));
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] Change "Receipt Date" on Transfer Line to 09-01-2022
        LibraryWarehouse.ReopenTransferOrder(TransferHeader);
        NewDate := LibraryRandom.RandDateFrom(WorkDate(), 14);
        TransferLine.Validate("Receipt Date", NewDate);
        TransferLine.Modify(true);

        // [THEN] Derived Transfer Line has "Receipt Date" = 09-01-2022
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetFilter("Derived From Line No.", '<>%1', 0);
        TransferLine.FindFirst();
        TransferLine.TestField("Receipt Date", NewDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxLiableTakenFromAlternateShippingAddress()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
    begin
        // [SCENARIO 378102] When Customer has alternative shipping address, Tax Liable is taken from the shipping address to Sales Order
        Initialize();

        // [GIVEN] Customer with alternative ship-to code and "Tax Liable" = False
        CreateCustomerWithAlternateShippingAddress(Customer, ShipToAddress);

        // [GIVEN] Alternative address has "Tax Liable" = True
        ModifyTaxFieldsShipToAddress(ShipToAddress, true);

        // [WHEN] Create Sales Header for the Customer
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        // [THEN] "Tax Liable" is taken from Alternative Shipping address and is TRUE
        SalesHeader.TestField("Tax Liable", ShipToAddress."Tax Liable");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxLiableTakenFromBillToCustomer()
    var
        SalesHeader: Record "Sales Header";
        Customer: array[2] of Record Customer;
        ShipToAddress: Record "Ship-to Address";
    begin
        // [SCENARIO 378102] When Customer has alternative shipping address and Bill-to Customer No., Tax Liable is taken from the Bill-to Customer to Sales Order
        Initialize();

        // [GIVEN] Customer with alternative ship-to code and "Tax Liable" = False
        CreateCustomerWithAlternateShippingAddress(Customer[1], ShipToAddress);

        // [GIVEN] Alternative address has "Tax Liable" = True
        ModifyTaxFieldsShipToAddress(ShipToAddress, true);

        // [GIVEN] Another Customer 2 with "Tax Liable" = False
        CreateCustomerWithTaxAreaCode(Customer[2]);

        // [GIVEN] Customer 1 has "Bill-To" Customer 2
        Customer[1].Validate("Bill-to Customer No.", Customer[2]."No.");
        Customer[1].Modify(true);

        // [WHEN] Create Sales Header for the Customer 1
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer[1]."No.");

        // [THEN] "Tax Liable" is taken from Customer 2 and is False
        SalesHeader.TestField("Tax Liable", Customer[2]."Tax Liable");
    end;

    [Test]
    [HandlerFunctions('ReservationModalPageHandler')]
    procedure CannotExplodeBOMOnReservedPurchaseLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Purchase] [Explode BOM] [Reservation]
        // [SCENARIO 398112] Cannot run "Explode BOM" on reserved purchase line.
        Initialize();

        CreateAssemblyItemWithAsseblyBOM(Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, '', Item."No.", LibraryRandom.RandIntInRange(11, 20), '', false);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), '',
          LibraryRandom.RandDate(30));
        SalesLine.ShowReservation();

        asserterror LibraryPurchase.ExplodeBOM(PurchaseLine);

        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Reserved Qty. (Base)"), Format(0));
    end;

    [Test]
    procedure PurchaseOrderWithJobHavingNegativeAndPositiveLines()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Job] [Negative Line]
        // [SCENARIO 411787] Inventory and warehouse integrity when posting purchase order with job having negative and positive lines.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Location with mandatory bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Item, job.
        LibraryInventory.CreateItem(Item);
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Create purchase order at the location, add one line -
        // [GIVEN] Line 1: quantity = 1, select bin code and job no.
        // [GIVEN] Post the purchase as receipt.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item."No.", Qty, Location.Code, false);
        UpdateBinCodeJobNoAndJobTaskNoOnPurchaseLine(PurchaseLine, JobTask, Bin.Code);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Reopen the purchase order, add two lines -
        // [GIVEN] Line 2: quantity = -1, select bin code and job no.
        // [GIVEN] Line 3: quantity = 1, select bin code and job no.
        PurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item."No.", -Qty, Location.Code, false);
        UpdateBinCodeJobNoAndJobTaskNoOnPurchaseLine(PurchaseLine, JobTask, Bin.Code);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item."No.", Qty, Location.Code, false);
        UpdateBinCodeJobNoAndJobTaskNoOnPurchaseLine(PurchaseLine, JobTask, Bin.Code);

        // [WHEN] Post the purchase as receipt.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Six item entries have been posted in total (3 lines + 3 job consumptions), resulting in zero inventory.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.RecordCount(ItemLedgerEntry, 6);
        ItemLedgerEntry.TestField(Quantity, 0);

        // [THEN] Six warehouse entries have been posted in total too, resulting in zero quantity in bin.
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.CalcSums("Qty. (Base)");
        Assert.RecordCount(WarehouseEntry, 6);
        WarehouseEntry.TestField("Qty. (Base)", 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure LineShouldNotBeDeletedWhenModifyLotNoInItemTracking()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        Qty2: Decimal;
        Qty3: Decimal;
        LotNoCode: Code[20];
        LotNo4: Code[20];
        LotNo: array[3] of Code[20];
    begin
        // [SCENARIO 478837] Purchase Order Line with Item Tracking results in a deleted Lot No. Line in the Item Tracking window when closing the window after changing the Lot Nos. through swapping of the lines.
        Initialize();

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create an Item Tracking Code.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true);

        // [GIVEN] Create an Item & Validate Item Tracking Code.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        // [GIVEN] Create a No Series for Lot No.
        LotNoCode := LibraryERM.CreateNoSeriesCode();

        // [GIVEN] Create 3 Lot Nos from No Series.
        LotNo[1] := NoSeriesBatch.GetNextNo(LotNoCode);
        LotNo[2] := NoSeriesBatch.GetNextNo(LotNoCode);
        LotNo[3] := NoSeriesBatch.GetNextNo(LotNoCode);

        // [GIVEN] Create two Quantities and save each in a Variable.
        Qty2 := LibraryRandom.RandIntInRange(200, 200);
        Qty3 := LibraryRandom.RandIntInRange(300, 300);

        // [GIVEN] Create Lot No 4 from No Series.
        LotNo4 := NoSeriesBatch.GetNextNo(LotNoCode);

        // [GIVEN] Create a Purchase Order with three Item Tracking Lines & Assign Lot No to each.
        CreatePurchaseOrderWithItemTrackingMultipleLotNo(PurchaseHeader, LotNo, Vendor."No.", Item."No.", LibraryRandom.RandIntInRange(1000, 1000));

        // [GIVEN] Open Item Tracking Lines & Verify Lot No & Quantity Base of last two Lines.
        VerifyItemTrackingOnPurchaseOrderLine(PurchaseLine, PurchaseHeader, LotNo[2], Qty2);
        VerifyItemTrackingOnPurchaseOrderLine(PurchaseLine, PurchaseHeader, LotNo[3], Qty3);

        // [WHEN] Open Item Tracking Lines & Change Lot No of last two Lines.
        SetLotNoOnPurchaseOrderItemTracking(PurchaseLine, PurchaseHeader, LotNo[2], LotNo4);
        SetLotNoOnPurchaseOrderItemTracking(PurchaseLine, PurchaseHeader, LotNo[3], LotNo[2]);
        SetLotNoOnPurchaseOrderItemTracking(PurchaseLine, PurchaseHeader, LotNo4, LotNo[3]);

        // [VERIFY] Open Item Tracking Lines & Verify Lot No of last two Lines is changed.
        VerifyItemTrackingOnPurchaseOrderLine(PurchaseLine, PurchaseHeader, LotNo[2], Qty3);
        VerifyItemTrackingOnPurchaseOrderLine(PurchaseLine, PurchaseHeader, LotNo[3], Qty2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure VerifyDueDateTimeShouldBeUpdatedInProdOrderComponentWhenRoutingLinkCodeIsUpdatedInRoutingLine()
    var
        Item: Record Item;
        Location: Record Location;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        RoutingLink: array[2] of Record "Routing Link";
        ProdOrderComponent: Record "Prod. Order component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [SENARIO 399971] Verify the "Due DateTime" is updated in Prod. Order Component When "Routing Link Code" is updated in Prod Order Routing Line.
        Initialize();

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Create a Routing Link.
        LibraryManufacturing.CreateRoutingLink(RoutingLink[1]);

        // [GIVEN] Create another Routing Link.
        LibraryManufacturing.CreateRoutingLink(RoutingLink[2]);

        // [GIVEN] Create a Routing Header with Status.
        CreateRoutingHeaderWithStatus(RoutingHeader, "Routing Status"::Certified);

        // [GIVEN] Create an Item with Routing No.
        CreateItemWithRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Create a Work Center.
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Create a Planned Production Order with Routing No.
        CreateProductionOrderWithRoutingNo(ProductionOrder, "Production Order Status"::Planned, Item."No.", LibraryRandom.RandInt(10), RoutingHeader."No.", Location.Code);

        // [GIVEN] Create a Production Order Line.
        CreateProdOrderlineFromProdOrder(ProdOrderLine, ProductionOrder, Item."No.", '', Location.Code);

        // [GIVEN] Create two Prod. Order Routing Line with Routing Link Code.
        CreateProdOrderRoutingLineWithRoutingLinkCode(ProdOrderLine, WorkCenter, ProdOrderRoutingLine.Type::"Work Center", RoutingLink[1].Code, 2);

        // [GIVEN] Create two Prod. Order Routing Line with another Routing Link Code.
        CreateProdOrderRoutingLineWithRoutingLinkCode(ProdOrderLine, WorkCenter, ProdOrderRoutingLine.Type::"Work Center", RoutingLink[2].Code, 2);

        // [GIVEN] Create three Prod. Order Component with Routing Link Code.
        CreateProdOrderComponentWithRountingLinkCode(ProdOrderComponent, ProdOrderLine, RoutingLink[1].Code, 3);

        // [GIVEN] Create three Prod. Order Component with another Routing Link Code.
        CreateProdOrderComponentWithRountingLinkCode(ProdOrderComponent, ProdOrderLine, RoutingLink[2].Code, 3);

        // [WHEN] Update "Routing Link Code" in Prod. Order Routing Line with the same Routing Code.
        UpdateRoutingLinkCodeInRoutingLine(ProductionOrder."No.", RoutingLink[1].Code, RoutingLink[1].Code, 0);
        UpdateRoutingLinkCodeInRoutingLine(ProductionOrder."No.", RoutingLink[2].Code, RoutingLink[2].Code, 0);

        // [VERIFY] Prod. Order Component should have "Due Date-Time" equal to the earliest "Startig Date-Time" of the Prod. Order Routing Line if the "Routing Link Code" is same.
        FindProdOrderRoutingLineForRoutingLinkCode(ProdOrderRoutingLine, ProdOrderLine, RoutingLink[1].Code);
        VerifyDueDateTimeInProdOrderComponent(ProdOrderRoutingLine);
        FindProdOrderRoutingLineForRoutingLinkCode(ProdOrderRoutingLine, ProdOrderLine, RoutingLink[2].Code);
        VerifyDueDateTimeInProdOrderComponent(ProdOrderRoutingLine);

        // [WHEN] Update all the routing line records that have the second "Routing Link Code" to the first "Routing Link Code".
        UpdateRoutingLinkCodeInRoutingLine(ProductionOrder."No.", RoutingLink[2].Code, RoutingLink[1].Code, 0);

        // [VERIFY] Prod. Order Component with first "Routing Link Code" should have "Due Date-Time" equal to the earliest "Startig Date-Time" of the Prod. Order Routing Line with same first "Routing Link Code".
        FindProdOrderRoutingLineForRoutingLinkCode(ProdOrderRoutingLine, ProdOrderLine, RoutingLink[1].Code);
        VerifyDueDateTimeInProdOrderComponent(ProdOrderRoutingLine);

        // [WHEN] Update the last routing line record, which has the first "Routing Link Code," to the second "Routing Link Code".
        UpdateRoutingLinkCodeInRoutingLine(ProductionOrder."No.", RoutingLink[1].Code, RoutingLink[2].Code, 2);

        // [VERIFY] Prod. Order Component with second "Routing Link Code" should have "Due Date-Time" equal to the earliest "Startig Date-Time" of the Prod. Order Routing Line with same second "Routing Link Code".
        FindProdOrderRoutingLineForRoutingLinkCode(ProdOrderRoutingLine, ProdOrderLine, RoutingLink[2].Code);
        VerifyDueDateTimeInProdOrderComponent(ProdOrderRoutingLine);
    end;

    local procedure Initialize()
    var
        SalesHeader: Record "Sales Header";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Orders V");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Orders V");
        LibraryERMCountryData.CreateVATData();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LocationSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Orders V");
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate2: Record "Item Journal Template"; var ItemJournalBatch2: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate2, ItemJournalTemplateType);
        ItemJournalTemplate2.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate2.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch2, ItemJournalTemplate2.Type, ItemJournalTemplate2.Name);
        ItemJournalBatch2.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch2.Modify(true);
    end;

    local procedure LocationSetup()
    begin
        CreateAndUpdateLocation(LocationBlue, true, true, false, false, false);  // Location Blue with Require Put-Away and Require Pick.
        CreateAndUpdateLocation(LocationYellow, false, false, false, false, true);  // Location Yellow with Bin Mandatory.
        CreateAndUpdateLocation(LocationRed, false, false, false, false, false);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        UpdateLocationAndBinOnItemJournalLine(ItemJournalLine, LocationCode, BinCode);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]) PostedDocumentNo: Code[20]
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, LocationCode, false);  // Use Tracking as FALSE.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Receive as TRUE.
    end;

    local procedure CreateAndPostPurchaseOrderWithMultipleItems(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; ItemNo2: Code[20])
    begin
        CreatePurchaseOrderWithMultipleItems(PurchaseHeader, PurchaseLine, ItemNo, Quantity, '', ItemNo2, true);  // Use Tracking as TRUE.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.
    end;

    local procedure CreateAndPostPurchaseReturnOrderWithGetPostedDocumentLinesToReverse(VendorNo: Code[20]) PostedDocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        PurchaseHeader.GetPstdDocLinesToReverse();
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Receive as TRUE.
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, LocationCode, false);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesCreditMemoWithGetPostedDocLinesToReverse(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibraryVariableStorage.Enqueue(PostedSalesDocType::"Posted Return Receipts");  // Enqueue for PostedSalesDocumentLinesPageHandler.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.GetPstdDocLinesToReverse();
        UpdateUnitPriceOnSalesCreditMemoLine(SalesLine, ItemNo, SalesHeader."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as SHIP and INVOICE.
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]) PostedDocumentNo: Code[20]
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Ship as TRUE.
    end;

    local procedure CreateAndPostSalesOrderWithQtyToAssembleToOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Quantity2: Decimal)
    var
        InventorySetup: Record "Inventory Setup";
        SalesLine: Record "Sales Line";
    begin
        InventorySetup.Get();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Shipment Date", CalcDate(InventorySetup."Default Safety Lead Time", WorkDate())); // To avoid Due Date Before Work Date message.
        SalesLine.Validate("Qty. to Assemble to Order", Quantity2);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesReturnOrderWithGetPostedDocumentLinesToReverse(CustomerNo: Code[20]) PostedDocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        LibraryVariableStorage.Enqueue(PostedSalesDocType::"Posted Shipments");  // Enqueue for PostedSalesDocumentLinesPageHandler.
        SalesHeader.GetPstdDocLinesToReverse();
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Receive.
    end;

    local procedure CreateAndPartiallyShipSalesOrderWithAlternateUOM(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; SalesQty: Decimal; ShipQty: Decimal; ShipQtyBase: Decimal)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, CustomerNo, ItemNo, SalesQty, LocationCode);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentLine.Validate("Qty. to Ship", ShipQty);
        WarehouseShipmentLine."Qty. to Ship (Base)" := ShipQtyBase;
        WarehouseShipmentLine.Modify(true);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseOrderWithMultipleItemsAndJobNo(Item: array[2] of Record Item; Quantity: Decimal; var LotNo: array[2] of Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        for i := 1 to ArrayLen(Item) do begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
            CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item[i]."No.", Quantity, '', true);
            CreateJobWithJobTask(JobTask);
            UpdateBinCodeJobNoAndJobTaskNoOnPurchaseLine(PurchaseLine, JobTask, '');
            GetLotNoFromItemTrackingPageHandler(LotNo[i]);
        end;

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateAndPostPurchaseReturnOrderWithMultipleItemsAndJobNo(Item: array[2] of Record Item; Quantity: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');

        for i := 1 to ArrayLen(Item) do begin
            CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item[i]."No.", Quantity, '', false);
            CreateJobWithJobTask(JobTask);
            UpdateBinCodeJobNoAndJobTaskNoOnPurchaseLine(PurchaseLine, JobTask, '');
        end;

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateAndPostPurchaseDocumentWithItemAndJob(JobTask: Record "Job Task"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocumentType, '', ItemNo, Quantity, '', WorkDate());
        UpdateBinCodeJobNoAndJobTaskNoOnPurchaseLine(PurchaseLine, JobTask, '');
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateAndUpdateTask(var Task: Record "To-do"; Contact: Record Contact)
    begin
        LibraryMarketing.CreateTask(Task);
        Task.Validate(Date, WorkDate());
        Task.Validate("Contact No.", Contact."No.");
        Task.Validate("Salesperson Code", Contact."Salesperson Code");
        Task.Modify(true);
    end;

    local procedure CreateContactWithTasks(var Contact: Record Contact)
    var
        Task: Record "To-do";
        Task2: Record "To-do";
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateAndUpdateTask(Task, Contact);
        CreateAndUpdateTask(Task2, Contact);
        UpdateOrganizerTaskNoOnTask(Task2, Task."Organizer To-do No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency."Invoice Rounding Precision" := LibraryERM.GetAmountRoundingPrecision();
        Currency.Modify();

        CreateCurrencyExchangeRate(
          CurrencyExchangeRate, Currency.Code, CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        CreateCurrencyExchangeRate(CurrencyExchangeRate, Currency.Code, WorkDate());
    end;

    local procedure CreateCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; StartingDate: Date)
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDec(50, 2));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCustomerWithShipmentMethod(var Customer: Record Customer)
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipment Method Code", ShipmentMethod.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithVATBusPostingGroup(var Customer: Record Customer; VATBusPostingGroup: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithTaxAreaCode(var Customer: Record Customer)
    var
        TaxArea: Record "Tax Area";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateTaxArea(TaxArea);
        Customer.Validate("Tax Area Code", TaxArea.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithAlternateShippingAddress(var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    begin
        CreateCustomerWithTaxAreaCode(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);
    end;

    local procedure ModifyTaxFieldsShipToAddress(var ShipToAddress: Record "Ship-to Address"; NewTaxLiable: Boolean)
    var
        TaxArea: Record "Tax Area";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        ShipToAddress.Validate("Tax Liable", NewTaxLiable);
        ShipToAddress.Validate("Tax Area Code", TaxArea.Code);
        ShipToAddress.Modify(true);
    end;

    local procedure CreateDimensionForItem(ItemNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Item, ItemNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
    end;

    local procedure CreateDropShipmentSalesAndPurchase(var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header")
    begin
        CreateSalesOrderWithDropShipment(SalesHeader, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo());
        CreatePurchaseOrderWithGetDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; Qty: Decimal)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasure.Code, Qty);
    end;

    local procedure CreateItemWithSalesUOM(QtyPerUOM: Decimal) ItemNo: Code[20]
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemNo := LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", QtyPerUOM);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemWithMultipleUOM(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; var ItemUnitOfMeasure1: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order); // Reordering Policy should not be blank.
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure1, Item."No.", LibraryRandom.RandInt(5) + 1);
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; Lot: Boolean; Serial: Boolean; LotNos: Code[20]; SerialNos: Code[20])
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, ItemTrackingCode.Code);
    end;

    local procedure CreateItemWithVendorNoAndReorderingPolicy(var Item: Record Item; VendorNo: Code[20]; ReorderingPolicy: Enum "Reordering Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", VendorNo);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateAssemblyItemWithAsseblyBOM(var AssemblyItem: Record Item; CompItem: Code[20]; QuantityPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryAssembly.CreateItem(AssemblyItem, AssemblyItem."Costing Method", AssemblyItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompItem, AssemblyItem."No.", '', BOMComponent."Resource Usage Type", QuantityPer, true);
    end;

    local procedure CreateAssemblyItemWithMultipleBOMComponents(var CompItem: Record Item; var CompItem2: Record Item): Code[20]
    var
        AssemblyItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateItemWithExtendedText(CompItem, ExtendedTxt, CompItem."Costing Method"::FIFO, 0);
        LibraryAssembly.CreateItem(CompItem2, CompItem2."Costing Method", CompItem."Replenishment System"::Purchase, '', '');
        CreateAssemblyItemWithAsseblyBOM(AssemblyItem, CompItem."No.", LibraryRandom.RandDec(10, 2));
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, CompItem2."No.", AssemblyItem."No.", '',
          BOMComponent."Resource Usage Type", LibraryRandom.RandDec(10, 2), true);
        exit(AssemblyItem."No.");
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateLotItemWithStandardCostingMethod(var Item: Record Item)
    begin
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '');  // TRUE for Lot.
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Modify(true);
    end;

    local procedure CreateNegativePurchaseLineAndApplyToItemEntry(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntryWithDocumentNo(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, DocumentNo, ItemNo);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, LocationCode, false);  // Use Tracking as FALSE.
        PurchaseLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateNegativeSalesLineAndApplyFromItemEntry(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntryWithDocumentNo(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, DocumentNo, ItemNo);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        SalesLine.Modify(true);
    end;

    local procedure CreateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeriesCode: Code[20]; StartingDate: Date)
    begin
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeriesCode, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        NoSeriesLine.Validate("Starting Date", StartingDate);
        NoSeriesLine.Modify(true);
    end;

    local procedure CreateNoSeriesWithDifferentStartingDates(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeries: Record "No. Series";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);  // Use True for Default and Manual.
        CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, WorkDate());
        CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
    end;

    local procedure CreatePurchaseHeaderWithLeadTimeCalculation(var PurchaseHeader: Record "Purchase Header")
    var
        LeadTimeCalculation: DateFormula;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        Evaluate(LeadTimeCalculation, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        PurchaseHeader.Validate("Lead Time Calculation", LeadTimeCalculation);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseHeaderWithSellToCustomerNo(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; SellToCustomerNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UseTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        if UseTracking then
            PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, LocationCode, ItemTracking);
    end;

    local procedure CreatePurchaseOrderWithItemTracking(var PurchaseHeader: Record "Purchase Header"; var AssignedLotNos: array[2] of Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignGivenLotNos);
        LibraryVariableStorage.Enqueue(ArrayLen(AssignedLotNos));
        for i := 1 to ArrayLen(AssignedLotNos) do begin
            AssignedLotNos[i] := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(AssignedLotNos[i]);
            LibraryVariableStorage.Enqueue(Qty / ArrayLen(AssignedLotNos));
        end;
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, '', ItemNo, Qty, '', true);
    end;

    local procedure CreateSpecialSaleOrderAndPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var SalesHeaderNo: Code[20])
    var
        Item: Record Item;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        CreateSalesOrderWithSpecialOrder(SalesHeader, Customer."No.", ShipToAddress.Code, Item."No.");
        SalesHeaderNo := SalesHeader."No.";
        CreatePurchaseHeaderWithSellToCustomerNo(PurchaseHeader, '', SalesHeader."Sell-to Customer No.");
    end;

    local procedure CreatePurchaseOrderFromBlanketPurchaseOrderWithPartialQuantity(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Qty. to Receive", Quantity / 2);  // Making Purchase Order of Half Quantity.
        PurchaseLine.Modify(true);
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);
    end;

    local procedure CreatePurchaseOrderWithMultipleItems(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemNo2: Code[20]; UseTracking: Boolean)
    var
        PurchaseLine2: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemNo, Quantity, LocationCode, false);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine2, ItemNo2, Quantity, LocationCode, UseTracking);
    end;

    local procedure CreatePurchaseOrderWithGetDropShipment(var PurchaseHeader: Record "Purchase Header"; CustomerNo: Code[20])
    begin
        CreatePurchaseHeaderWithSellToCustomerNo(PurchaseHeader, '', CustomerNo);
        LibraryPurchase.GetDropShipment(PurchaseHeader);
    end;

    local procedure CreatePurchaseOrderWithGetSpecialOrder(var PurchaseHeader: Record "Purchase Header"; CustomerNo: Code[20])
    begin
        CreatePurchaseHeaderWithSellToCustomerNo(PurchaseHeader, '', CustomerNo);
        LibraryPurchase.GetSpecialOrder(PurchaseHeader);
    end;

    local procedure CreatePurchaseOrderWithStandardCostItemUsingLot(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var Vendor: Record Vendor) LotNo: Code[50]
    var
        Item: Record Item;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateLotItemWithStandardCostingMethod(Item);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingPageHandler.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", Item."No.", LibraryRandom.RandDec(100, 2), LocationBlue.Code, true);  // Value required for the test. TRUE for Tracking.
        UpdateUnitCostOnPurchaseLine(PurchaseLine);
        GetLotNoFromItemTrackingPageHandler(LotNo);
    end;

    local procedure CreatePurchOrderWithInsertedExtendedText(var PurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        CreatePurchaseOrder(
          PurchaseHeader, PurchLine, '', ItemNo, LibraryRandom.RandDec(10, 2), '', false);
        FindPurchaseLine(PurchLine, ItemNo);
        TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, true);
        TransferExtendedText.InsertPurchExtText(PurchLine);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchReturnOrderWithGetPstdDocLinesToReverse(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        PurchaseHeader.GetPstdDocLinesToReverse();
    end;

    local procedure CreatePurchasingCode(SpecialOrder: Boolean; DropShipment: Boolean): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", SpecialOrder);
        Purchasing.Validate("Drop Shipment", DropShipment);
        Purchasing.Modify(true);
        exit(Purchasing.Code);
    end;

    local procedure CreateSalesHeaderWithShipToCode(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ShipToCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Ship-to Code", ShipToCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(50));
        SalesLine.Modify(true);
    end;

    local procedure CreateSpecialSaleOrderAndPurchaseOrderWithDifferentShipToCode(var PurchaseHeader: Record "Purchase Header"; var SalesShipToCode: Code[20]; var PurchaseShipToCode: Code[20])
    var
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        SalesHeaderNo: Code[20];
    begin
        CreateSpecialSaleOrderAndPurchaseOrder(PurchaseHeader, SalesHeaderNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesHeaderNo);
        SalesHeader.FindFirst();
        SalesShipToCode := SalesHeader."Ship-to Code";
        LibrarySales.CreateShipToAddress(ShipToAddress, SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Validate("Ship-to Code", ShipToAddress.Code);
        PurchaseHeader.Modify();
        PurchaseShipToCode := PurchaseHeader."Ship-to Code";
    end;

    local procedure CreateSalesLineWithPurchasingCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; PurchasingCode: Code[10])
    begin
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Reserve: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        if Reserve then
            SalesLine.AutoReserve();
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateSalesOrder(SalesHeader, CustomerNo, ItemNo, Quantity, LocationCode, false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateSalesOrderWithDifferentBillToCustomerNo(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var Customer: Record Customer; var Item: Record Item)
    var
        Customer2: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type");
        CreateItemWithVendorNoAndReorderingPolicy(Item, '', Item."Reordering Policy"::" ");
        UpdateVATProdPostingGroupOnItem(Item, VATPostingSetup."VAT Prod. Posting Group");
        CreateCustomerWithVATBusPostingGroup(Customer, VATPostingSetup."VAT Bus. Posting Group");
        CreateCustomerWithVATBusPostingGroup(Customer2, VATPostingSetup."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibraryVariableStorage.Enqueue(ChangeBillToCustomerNoConfirmQst);  // Enqueue for ConfirmHandler.
        SalesHeader.Validate("Bill-to Customer No.", Customer2."No.");
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2), '');
    end;

    local procedure CreateSalesOrderWithSpecialOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ShipToCode: Code[10]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderWithShipToCode(SalesHeader, CustomerNo, ShipToCode);
        CreateSalesLineWithPurchasingCode(
          SalesHeader, SalesLine, ItemNo, LibraryRandom.RandDec(10, 2), '', CreatePurchasingCode(true, false));  // TRUE for Special Order.
    end;

    local procedure CreateSalesOrderWithDropShipment(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLineWithPurchasingCode(
          SalesHeader, SalesLine, ItemNo, LibraryRandom.RandDec(10, 2), '', CreatePurchasingCode(false, true));  // TRUE for Drop Shipment.
    end;

    local procedure CreateSalesOrderWithDropShipmentAndSerialItemTracking(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateItemWithItemTrackingCode(Item, false, true, '', LibraryUtility.GetGlobalNoSeriesCode());  // TRUE for Serial.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLineWithPurchasingCode(
          SalesHeader, SalesLine, Item."No.", 1 + LibraryRandom.RandInt(10), '', CreatePurchasingCode(false, true));  // TRUE for Drop Shipment. Quantity required greater than 1 for the test.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);  // Enqueue for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarningsConfirmMsg);  // Enqueue for ConfirmHandler.
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesOrderWithItemTracking(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, CustomerNo, ItemNo, Quantity, LocationCode, false);
        FindSalesLine(SalesLine, SalesHeader."Document Type"::Order, SalesHeader."No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingPageHandler.
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesOrderWithoutExternalDocumentNo(var SalesHeader: Record "Sales Header"; var Customer: Record Customer)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesHeader, Customer."No.", Item."No.", LibraryRandom.RandDec(100, 2), '', false);
        UpdateExternalDocumentNoOnSalesOrder(SalesHeader, '');
    end;

    local procedure CreateSalesOrderWithInsertedExtendedText(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        CreateSalesOrder(
          SalesHeader, '', ItemNo, LibraryRandom.RandDec(10, 2), '', false);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);
        TransferExtendedText.InsertSalesExtText(SalesLine);
    end;

    local procedure CreateSalesOrderForPurchasedTrackedItem(var SalesHeader: Record "Sales Header"; var Item: Record Item; var LotNos: array[2] of Code[20]; Qty: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateItemWithItemTrackingCode(Item, true, false, '', '');
        CreatePurchaseOrderWithItemTracking(PurchaseHeader, LotNos, Item."No.", Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateSalesOrderWithItemTracking(SalesHeader, '', Item."No.", Qty, '');
    end;

    local procedure CreateVendorWithCurrencyExchangeRate(var Vendor: Record Vendor): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        LibraryPurchase.CreateVendor(Vendor);
        UpdateCurrencyCodeOnVendor(Vendor, CurrencyExchangeRate."Currency Code");
        exit(CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount"); // Value required for calculating Currency factor.
    end;

    local procedure CreateVendorWithShipmentMethod(var Vendor: Record Vendor; ShipmentMethodCode: Code[10])
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.SetFilter(Code, '<>%1', ShipmentMethodCode);
        ShipmentMethod.FindFirst();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Shipment Method Code", ShipmentMethod.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoiceFromShipment(SalesHeaderOrder: Record "Sales Header")
    var
        SalesHeaderInvoice: Record "Sales Header";
    begin
        CreateSalesInvoiceFromShipment(SalesHeaderInvoice, SalesHeaderOrder);
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, true);
    end;

    local procedure CreateSpecialPurchaseOrderAndPostReceipt(var PurchaseHeader: Record "Purchase Header"; SalesHeaderOrder: Record "Sales Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrderWithGetSpecialOrder(PurchaseHeader, SalesHeaderOrder."Sell-to Customer No.");
        FindPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.TestField("Special Order Sales No.", SalesHeaderOrder."No.");
        PurchaseLine.TestField("Special Order Sales Line No.");
        PurchaseLine.TestField("Special Order");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateSalesInvoiceFromShipment(var SalesHeaderInvoice: Record "Sales Header"; SalesHeaderOrder: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");
        SalesLine."Document Type" := SalesHeaderInvoice."Document Type";
        SalesLine."Document No." := SalesHeaderInvoice."No.";
        LibrarySales.GetShipmentLines(SalesLine);
    end;

    local procedure EnqueueLotAssignment(NoOfLots: Integer; QtyPerLot: Decimal)
    var
        I: Integer;
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignGivenLotNos);
        LibraryVariableStorage.Enqueue(NoOfLots);
        for I := 1 to NoOfLots do begin
            LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
            LibraryVariableStorage.Enqueue(QtyPerLot);
        end;
    end;

    local procedure EnqueueLotUpdate(LotNo: Code[50]; QtyToHandle: Decimal; QtyToInvoice: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::UpdateLotQty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QtyToHandle);
        LibraryVariableStorage.Enqueue(QtyToInvoice);
    end;

    local procedure FillTempItemTrackingBuf(var TempTrackingSpec: Record "Tracking Specification" temporary; LotNo: Code[50]; QtyToShipValues: Text; QtytoInvoiceValues: Text)
    var
        LastEntryNo: Integer;
        i: Integer;
    begin
        LastEntryNo := TempTrackingSpec.Count();
        for i := 1 to 3 do begin
            LastEntryNo += 1;
            TempTrackingSpec.Init();
            TempTrackingSpec."Entry No." := LastEntryNo;
            TempTrackingSpec."Lot No." := LotNo;
            Evaluate(TempTrackingSpec."Qty. to Handle", SelectStr(i, QtyToShipValues));
            Evaluate(TempTrackingSpec."Qty. to Invoice", SelectStr(i, QtytoInvoiceValues));
            TempTrackingSpec.Insert();
        end;
    end;

    local procedure FilterPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.SetFilter("No.", '%1|%2', ItemNo, ItemNo2);
    end;

    local procedure FilterReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; OrderNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        ReturnShipmentLine.SetRange("Return Order No.", OrderNo);
        ReturnShipmentLine.SetFilter("No.", '%1|%2', ItemNo, ItemNo2);
        ReturnShipmentLine.FindSet();
    end;

    local procedure FindReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; OrderNo: Code[20]; ItemNo: Code[20])
    begin
        ReturnShipmentLine.SetRange("Return Order No.", OrderNo);
        ReturnShipmentLine.SetRange("No.", ItemNo);
        ReturnShipmentLine.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
    end;

    local procedure FindItemLedgerEntryWithDocumentNo(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchaseLineByHeader(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindSet();
    end;

    local procedure FindReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        FilterPurchRcptLine(PurchRcptLine, OrderNo, ItemNo, ItemNo2);
        PurchRcptLine.FindSet();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure GetLotNoFromItemTrackingPageHandler(var LotNo: Code[50])
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LotNo := DequeueVariable;
    end;

    local procedure GetReceiptLineOnPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        LibraryPurchase.GetPurchaseReceiptLine(PurchaseLine);
    end;

    local procedure MockSalesLineWithItemType(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.Type := SalesLine.Type::Item;
    end;

    local procedure MockSalesLineWithGLAccountType(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.Type := SalesLine.Type::"G/L Account";
    end;

    local procedure MockPurchaseLineWithGLAccountType(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Type := PurchaseLine.Type::"G/L Account";
    end;

    local procedure MockItemInventory(ItemNo: Code[20]; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry.Quantity := Qty;
        ItemLedgerEntry."Remaining Quantity" := ItemLedgerEntry.Quantity;
        ItemLedgerEntry.Insert();
    end;

    local procedure OpenTaskListPageFromContactCard(ContactNo: Code[20]; Description: Text[50])
    var
        ContactCard: TestPage "Contact Card";
        TaskList: TestPage "Task List";
        TaskCard: TestPage "Task Card";
    begin
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", ContactNo);
        TaskList.Trap();
        ContactCard."T&asks".Invoke();
        TaskCard.Trap();
        TaskList."Edit Organizer Task".Invoke();
        TaskCard.Description.SetValue(Description);
        TaskCard.OK().Invoke();
    end;

    local procedure OpenCommentPageFromTaskCard(Task: Record "To-do"; Comment: Text[80])
    var
        TaskCard: TestPage "Task Card";
        RlshpMgtCommentSheet: TestPage "Rlshp. Mgt. Comment Sheet";
    begin
        TaskCard.OpenEdit();
        TaskCard.GotoRecord(Task);
        RlshpMgtCommentSheet.Trap();
        TaskCard."Co&mment".Invoke();
        RlshpMgtCommentSheet.Comment.AssertEquals(Comment);
        RlshpMgtCommentSheet.OK().Invoke();
        TaskCard.OK().Invoke();
    end;

    local procedure PostAllTransferOrdersWithLocationInTransit()
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.SetRange("In-Transit Code", LocationInTransit.Code);
        TransferHeader.FindSet();
        repeat
            LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);  // Post as SHIP and RECEIVE.
        until TransferHeader.Next() = 0;
    end;

    local procedure PostPartialPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; QtyToInvoice: Decimal)
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        UpdateQuantityToInvoiceOnPurchaseLine(PurchaseLine, QtyToInvoice);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure PostPartialSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; QtyToInvoice: Decimal)
    begin
        UpdateQuantityToInvoiceOnSalesLine(SalesLine, QtyToInvoice);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure PostPurchaseOrder(BuyfromVendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyfromVendorNo);
        PurchaseHeader.FindFirst();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Receive as TRUE.
    end;

    local procedure PostPurchaseOrderIterativelyWithReceiveAndInvoiceOption(var PurchaseHeader: Record "Purchase Header"; var TempTrackingSpec: Record "Tracking Specification" temporary; LotNos: array[2] of Code[20]; Iterations: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        QtyToReceive: Decimal;
        QtyToInvoice: Decimal;
        LastValueEntryNo: Integer;
        i: Integer;
    begin
        for i := 1 to Iterations do begin
            FindPurchaseLineByHeader(PurchaseLine, PurchaseHeader);
            UpdateItemTrackingOnPurchaseLine(PurchaseLine, TempTrackingSpec, LotNos, QtyToReceive, QtyToInvoice);
            PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
            PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
            PurchaseLine.Modify(true);

            ValueEntry.FindLast();
            LastValueEntryNo := ValueEntry."Entry No.";

            PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
            PurchaseHeader.Modify(true);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

            VerifyValueEntriesAfterGivenEntryNo(
              LastValueEntryNo, PurchaseLine."No.", ValueEntry."Item Ledger Entry Type"::Purchase, QtyToReceive, QtyToInvoice);
        end;
    end;

    local procedure PostSalesOrderAfterUpdateDatesWithExternalDocNo(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; PostingDate: Date)
    var
        OldWorkDate: Date;
    begin
        FindSalesLine(SalesLine, SalesLine."Document Type"::Order, SalesHeader."No.");
        LibraryVariableStorage.Enqueue(OrderDateOnSalesHeaderMsg);  // Enqueue for MessageHandler.
        SalesHeader.Find();
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Order Date", PostingDate);
        SalesHeader.Validate("Document Date", PostingDate);
        UpdateExternalDocumentNoOnSalesOrder(SalesHeader, SalesHeader."No.");
        OldWorkDate := WorkDate();
        WorkDate := PostingDate;  // Fix for GB.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post Ship and Invoice.
        WorkDate := OldWorkDate;
    end;

    local procedure PostSalesOrderIterativelyWithShipAndInvoiceOption(var SalesHeader: Record "Sales Header"; var TempTrackingSpec: Record "Tracking Specification" temporary; LotNos: array[2] of Code[20]; Iterations: Integer)
    var
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        QtyToShip: Decimal;
        QtyToInvoice: Decimal;
        LastValueEntryNo: Integer;
        i: Integer;
    begin
        for i := 1 to Iterations do begin
            FindSalesLine(SalesLine, SalesHeader."Document Type"::Order, SalesHeader."No.");
            UpdateItemTrackingOnSalesLine(SalesLine, TempTrackingSpec, LotNos, QtyToShip, QtyToInvoice);
            SalesLine.Validate("Qty. to Ship", QtyToShip);
            SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
            SalesLine.Modify(true);

            ValueEntry.FindLast();
            LastValueEntryNo := ValueEntry."Entry No.";

            LibrarySales.PostSalesDocument(SalesHeader, true, true);

            VerifyValueEntriesAfterGivenEntryNo(
              LastValueEntryNo, SalesLine."No.", ValueEntry."Item Ledger Entry Type"::Sale, -QtyToShip, -QtyToInvoice);
        end;
    end;

    local procedure PostSalesShipment(CustomerNo: Code[20]; ItemNo: Code[20]; Qty: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, CustomerNo, ItemNo, Qty, '', false);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure PostOutboundWhenReservationEntryExistsForSalesOrder(Outbound: Option ,SalesOrder,SalesInvoice,PurchaseReturnOrder,PurchaseCreditMemo)
    var
        CompItem: Record Item;
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        Bin: Record Bin;
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Assembly Item with Assembly BOM. Create Bin for Loation Yellow.
        Quantity := LibraryRandom.RandInt(10);
        Quantity2 := LibraryRandom.RandInt(5);
        LibraryWarehouse.CreateBin(Bin, LocationYellow.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryInventory.CreateItem(CompItem);
        CreateAssemblyItemWithAsseblyBOM(AssemblyItem, CompItem."No.", 1);

        // Post Item Journal for two items.
        CreateAndPostItemJournalLine(AssemblyItem."No.", Quantity, LocationYellow.Code, Bin.Code);
        CreateAndPostItemJournalLine(CompItem."No.", Quantity2, LocationYellow.Code, Bin.Code);

        // Create 1st Sales Order for Assembly Item and Reserve.
        CreateSalesOrder(SalesHeader, '', AssemblyItem."No.", Quantity, LocationYellow.Code, true);

        // Exercise & Verify: Create and post the 2nd Sales Order/Sales Invoice/Purchase Return Order/Purchase Credit Memo.
        // Verify the confirm message in ConfirmHandler.
        LibraryVariableStorage.Enqueue(ReservationEntryExistMsg); // Enqueue for ConfirmHandler.
        case Outbound of
            Outbound::SalesOrder:
                CreateAndPostSalesOrderWithQtyToAssembleToOrder(
                  SalesHeader2, '', AssemblyItem."No.", Quantity + Quantity2, LocationYellow.Code, Quantity2);
            Outbound::SalesInvoice:
                CreateAndPostSalesInvoice(
                  SalesHeader2, '', AssemblyItem."No.", Quantity, LocationYellow.Code);
            Outbound::PurchaseReturnOrder:
                CreateAndPostPurchaseDocument(
                  PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '',
                  AssemblyItem."No.", Quantity, LocationYellow.Code);
            Outbound::PurchaseCreditMemo:
                CreateAndPostPurchaseDocument(
                  PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '',
                  AssemblyItem."No.", Quantity, LocationYellow.Code);
        end;

        // Post 1st Sales Order. Verify the error message.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(QuantityBaseErr);
    end;

    local procedure UndoPurchaseReceipt(OrderNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        LibraryVariableStorage.Enqueue(UndoReceiptMsg);  // UndoReceiptMessage Used in ConfirmHandler.
        FindReceiptLine(PurchRcptLine, OrderNo, ItemNo, ItemNo2);
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    local procedure UndoReturnShipment(OrderNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(UndoReturnShipmentMsg);  // UndoReturnShipmentMsg Used in ConfirmHandler.
        FilterReturnShipmentLine(ReturnShipmentLine, OrderNo, ItemNo, ItemNo2);
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);
    end;

    local procedure UpdateBinCodeJobNoAndJobTaskNoOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; JobTask: Record "Job Task"; BinCode: Code[20])
    begin
        if BinCode <> '' then
            PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateCurrencyCodeOnVendor(var Vendor: Record Vendor; CurrencyCode: Code[10])
    begin
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
    end;

    local procedure UpdateExactCostReversingMandatoryOnPurchaseSetup(NewExactCostReversingMandatory: Boolean) OldExactCostReversingMandatory: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldExactCostReversingMandatory := PurchasesPayablesSetup."Exact Cost Reversing Mandatory";
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", NewExactCostReversingMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateExactCostReversingMandatoryOnSalesReceivableSetup(NewExactCostReversingMandatory: Boolean) OldExactCostReversingMandatory: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldExactCostReversingMandatory := SalesReceivablesSetup."Exact Cost Reversing Mandatory";
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", NewExactCostReversingMandatory);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateStockoutWarningOnSalesReceivableSetup(NewStockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateDefQtyToShipOnSalesReceivableSetup(NewDefQtyToShip: Integer) OldDefQtyToShip: Integer
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldDefQtyToShip := SalesReceivablesSetup."Default Quantity to Ship";
        SalesReceivablesSetup.Validate("Default Quantity to Ship", NewDefQtyToShip);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateExpectedReceiptDateOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; ExpectedReceiptDate: Date)
    begin
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateExtDocNoMandatoryAndPostedInvNosOnSalesSetup(ExtDocNoMandatory: Boolean; PostedInvoiceNos: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Ext. Doc. No. Mandatory", ExtDocNoMandatory);
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", PostedInvoiceNos);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateDefaultItemQuantityOnSalesSetup(DefaultItemQuantity: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Item Quantity", DefaultItemQuantity);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateDefaultGLAccountQuantityOnSalesSetup(DefaultGLQuantity: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default G/L Account Quantity", DefaultGLQuantity);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateDefaultGLAccountQuantityOnPurchaseSetup(DefaultGLQuantity: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default G/L Account Quantity", DefaultGLQuantity);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateExternalDocumentNoOnSalesOrder(var SalesHeader: Record "Sales Header"; ExternalDocumentNo: Code[35])
    begin
        SalesHeader.Validate("External Document No.", ExternalDocumentNo);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateItemTrackingOnSalesLine(var SalesLine: Record "Sales Line"; var TempTrackingSpec: Record "Tracking Specification" temporary; LotNos: array[2] of Code[20]; var QtyToShip: Decimal; var QtyToInvoice: Decimal)
    var
        i: Integer;
    begin
        QtyToShip := 0;
        QtyToInvoice := 0;
        for i := 1 to ArrayLen(LotNos) do begin
            TempTrackingSpec.SetRange("Lot No.", LotNos[i]);
            TempTrackingSpec.FindFirst();
            LibraryVariableStorage.Enqueue(ItemTrackingMode::UpdateLotQty);
            LibraryVariableStorage.Enqueue(LotNos[i]);
            LibraryVariableStorage.Enqueue(TempTrackingSpec."Qty. to Handle");
            LibraryVariableStorage.Enqueue(TempTrackingSpec."Qty. to Invoice");
            SalesLine.OpenItemTrackingLines();
            QtyToShip += TempTrackingSpec."Qty. to Handle";
            QtyToInvoice += TempTrackingSpec."Qty. to Invoice";
            TempTrackingSpec.Delete();
        end;
    end;

    local procedure UpdateItemTrackingOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; var TempTrackingSpec: Record "Tracking Specification" temporary; LotNos: array[2] of Code[20]; var QtyToReceive: Decimal; var QtyToInvoice: Decimal)
    var
        i: Integer;
    begin
        QtyToReceive := 0;
        QtyToInvoice := 0;
        for i := 1 to ArrayLen(LotNos) do begin
            TempTrackingSpec.SetRange("Lot No.", LotNos[i]);
            TempTrackingSpec.FindFirst();
            LibraryVariableStorage.Enqueue(ItemTrackingMode::UpdateLotQty);
            LibraryVariableStorage.Enqueue(LotNos[i]);
            LibraryVariableStorage.Enqueue(TempTrackingSpec."Qty. to Handle");
            LibraryVariableStorage.Enqueue(TempTrackingSpec."Qty. to Invoice");
            PurchaseLine.OpenItemTrackingLines();
            QtyToReceive += TempTrackingSpec."Qty. to Handle";
            QtyToInvoice += TempTrackingSpec."Qty. to Invoice";
            TempTrackingSpec.Delete();
        end;
    end;

    local procedure UpdateLocationAndBinOnItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateOrganizerTaskNoOnTask(Task: Record "To-do"; OrganizerTaskNo: Code[20])
    begin
        Task.Validate("Organizer To-do No.", OrganizerTaskNo);
        Task.Modify(true);
    end;

    local procedure UpdateQtysToPostOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal; QtyToInvoice: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQuantityToInvoiceOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QuantityToInvoice: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Invoice", QuantityToInvoice);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQuantityToInvoiceOnPurchaseAndItemTrackingLine(ItemNo: Code[20]; QuantityToInvoice: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        ItemTrackingMode: Option AssignLotNo,SelectEntries,AssignSerialNo,UpdateQtyOnFirstLine,UpdateQtyOnLastLine;
    begin
        FindPurchaseLine(PurchaseLine, ItemNo);
        UpdateQuantityToInvoiceOnPurchaseLine(PurchaseLine, QuantityToInvoice);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::UpdateQtyOnLastLine);  // Enqueue for ItemTrackingPageHandler.
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure UpdateQtysToPostOnSalesLine(var SalesLine: Record "Sales Line"; QtyToShip: Decimal; QtyToInvoice: Decimal)
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQuantityToInvoiceOnSalesLine(var SalesLine: Record "Sales Line"; QuantityToInvoice: Decimal)
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Invoice", QuantityToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQuantityToInvoiceOnSalesAndItemTrackingLine(var SalesLine: Record "Sales Line"; QuantityToInvoice: Decimal)
    var
        ItemTrackingMode: Option AssignLotNo,SelectEntries,AssignSerialNo,UpdateQtyOnFirstLine,UpdateQtyOnLastLine;
    begin
        UpdateQuantityToInvoiceOnSalesLine(SalesLine, QuantityToInvoice);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::UpdateQtyOnFirstLine);  // Enqueue for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarningsConfirmMsg);  // Enqueue for ConfirmHandler.
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure UpdateUnitCostOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(50));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateUnitCostOnPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        FindPurchaseLine(PurchaseLine, ItemNo);
        UpdateUnitCostOnPurchaseLine(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
    end;

    local procedure UpdateUnitPriceOnSalesCreditMemoLine(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("No.", ItemNo);
        FindSalesLine(SalesLine, SalesLine."Document Type"::"Credit Memo", DocumentNo);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 100, 2));
        SalesLine.Modify(true);
    end;

    local procedure UpdateVATProdPostingGroupOnItem(var Item: Record Item; VATProdPostingGroup: Code[20])
    begin
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyDescriptionOnTask(ContactNo: Code[20]; Description: Text[50])
    var
        Task: Record "To-do";
    begin
        Task.SetRange("Contact No.", ContactNo);
        Task.FindSet();
        Task.TestField(Description, Description);
        Task.Next();
        Task.TestField(Description, Description);
    end;

    local procedure VerifyEditablePropertyOfUseAsInTransitFieldOnLocationCard(LocationCode: Code[10]; Editable: Boolean)
    var
        LocationCard: TestPage "Location Card";
    begin
        LocationCard.OpenEdit();
        LocationCard.FILTER.SetFilter(Code, LocationCode);
        if Editable then
            Assert.IsTrue(LocationCard."Use As In-Transit".Editable(), FieldShouldBeEditableErr)
        else
            Assert.IsFalse(LocationCard."Use As In-Transit".Editable(), FieldShouldNotBeEditableErr);
        LocationCard.OK().Invoke();
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        if Amount > 0 then
            GLEntry.SetFilter(Amount, '>0')
        else
            GLEntry.SetFilter(Amount, '<0');
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualErr);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Location Code", LocationCode);
        ItemLedgerEntry.TestField("Job No.", JobNo);
        ItemLedgerEntry.TestField("Job Task No.", JobTaskNo);
    end;

    local procedure VerifyItemLedgerEntryForLot(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal; MoveNext: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        if MoveNext then
            ItemLedgerEntry.Next();
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField(Quantity, Quantity)
    end;

    local procedure VerifyItemLedgerEntryForPostedDocument(DocumentType: Enum "Item Ledger Document Type"; EntryType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; ItemNo: Code[20]; RemainingQuantity: Decimal; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        FindItemLedgerEntryWithDocumentNo(ItemLedgerEntry, EntryType, DocumentNo, ItemNo);
        ItemLedgerEntry.TestField("Remaining Quantity", RemainingQuantity);
        ItemLedgerEntry.TestField(Quantity, Quantity)
    end;

    local procedure VerifyItemTrackingInItemLedgerEntry(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LotNos: array[2] of Code[20]; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        i: Integer;
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        for i := 1 to ArrayLen(LotNos) do begin
            ItemLedgerEntry.SetRange("Lot No.", LotNos[i]);
            ItemLedgerEntry.CalcSums(Quantity, "Invoiced Quantity");
            ItemLedgerEntry.TestField(Quantity, Qty / ArrayLen(LotNos));
            ItemLedgerEntry.TestField("Invoiced Quantity", Qty / ArrayLen(LotNos));
        end;
    end;

    local procedure VerifyPurchaseInvoiceLine(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange("No.", ItemNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchReceiptLine(ItemNo: Code[20]; Qty: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.CalcSums(Quantity, "Quantity Invoiced", "Qty. Invoiced (Base)", "Qty. Rcd. Not Invoiced");
        PurchRcptLine.TestField(Quantity, Qty);
        PurchRcptLine.TestField("Quantity Invoiced", Qty);
        PurchRcptLine.TestField("Qty. Invoiced (Base)", Qty);
        PurchRcptLine.TestField("Qty. Rcd. Not Invoiced", 0);
    end;

    local procedure VerifyReceiptLineAfterUndo(OrderNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FilterPurchRcptLine(PurchRcptLine, OrderNo, ItemNo, ItemNo2);
        PurchRcptLine.FindSet();
        Assert.AreEqual(Quantity, PurchRcptLine.Quantity, QuantityMustBeSameErr);
        PurchRcptLine.Next();
        Assert.AreEqual(-Quantity, PurchRcptLine.Quantity, QuantityMustBeSameErr);
    end;

    local procedure VerifyReturnShipmentLineAfterUndo(OrderNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        FilterReturnShipmentLine(ReturnShipmentLine, OrderNo, ItemNo, ItemNo2);
        Assert.AreEqual(Quantity, ReturnShipmentLine.Quantity, QuantityMustBeSameErr);
        ReturnShipmentLine.Next();
        Assert.AreEqual(-Quantity, ReturnShipmentLine.Quantity, QuantityMustBeSameErr);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; DocumentType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; EntryType: Enum "Cost Entry Type"; CostAmountActual: Decimal; CostPerUnit: Decimal; Adjustment: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Entry Type", EntryType);
        ValueEntry.SetRange(Adjustment, Adjustment);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Actual)", CostAmountActual);
        ValueEntry.TestField("Cost per Unit", CostPerUnit);
    end;

    local procedure VerifyValueEntriesAfterGivenEntryNo(LastEntryNo: Integer; ItemNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Document Type"; ItemLedgerEntryQuantity: Decimal; InvoicedQuantity: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetFilter("Entry No.", '>%1', LastEntryNo);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.CalcSums("Item Ledger Entry Quantity", "Invoiced Quantity");
        ValueEntry.TestField("Item Ledger Entry Quantity", ItemLedgerEntryQuantity);
        ValueEntry.TestField("Invoiced Quantity", InvoicedQuantity);
    end;

    local procedure VerifySalesLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; CompItemNo: Code[20]; CompItemNo2: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
        SalesLine.Next();
        SalesLine.TestField("No.", CompItemNo);
        SalesLine.Next();
        SalesLine.TestField(Description, ExtendedTxt);
        SalesLine.Next();
        SalesLine.TestField("No.", CompItemNo2);
    end;

    local procedure VerifyInvoiceQtyOnSalesLine(SalesLine: Record "Sales Line"; QtyToInvoice: Decimal; QtyInvoiced: Decimal)
    begin
        SalesLine.Find();
        SalesLine.TestField("Qty. to Invoice", QtyToInvoice);
        SalesLine.TestField("Quantity Invoiced", QtyInvoiced);
    end;

    local procedure VerifySalesLineExtTextBeforeItem(SalesHeader: Record "Sales Header"; ExtendedText: Text; CompItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Next(); // the first line is description of Assembly BOM, just skip
        SalesLine.TestField(Type, 0);
        SalesLine.TestField(Description, ExtendedText);
        SalesLine.Next();
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", CompItemNo);
    end;

    local procedure VerifySalesShipmentLine(ItemNo: Code[20]; Qty: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.CalcSums(Quantity, "Quantity Invoiced", "Qty. Invoiced (Base)", "Qty. Shipped Not Invoiced");
        SalesShipmentLine.TestField(Quantity, Qty);
        SalesShipmentLine.TestField("Quantity Invoiced", Qty);
        SalesShipmentLine.TestField("Qty. Invoiced (Base)", Qty);
        SalesShipmentLine.TestField("Qty. Shipped Not Invoiced", 0);
    end;

    local procedure VerifyPostedSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LotNos: array[2] of Code[20]; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        VerifyItemTrackingInItemLedgerEntry(ItemLedgerEntry."Entry Type"::Sale, ItemNo, LotNos, -Qty);
        VerifySalesShipmentLine(ItemNo, Qty);

        SalesHeader.SetRecFilter();
        Assert.RecordIsEmpty(SalesHeader);
    end;

    local procedure VerifyBaseQtysOnSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; QtyBase: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
        SalesLine.TestField("Quantity (Base)", QtyBase);
        SalesLine.TestField("Outstanding Qty. (Base)", QtyBase);
        SalesLine.TestField("Qty. to Invoice (Base)", QtyBase);
    end;

    local procedure VerifyResourceSalesLine(SalesHeader: Record "Sales Header"; ResourceNo: Code[20]; UnitOfMeasureCode: Code[20]; ExpectedQtyBase: Decimal; ExpectedQuantity: Decimal; ExpectedAmount: Decimal; ExpectedUnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Resource);
        SalesLine.SetRange("No.", ResourceNo);
        SalesLine.FindFirst();
        SalesLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        SalesLine.TestField("Quantity (Base)", Round(ExpectedQtyBase, 0.00001));
        SalesLine.TestField(Quantity, Round(ExpectedQuantity, 0.00001));
        SalesLine.TestField(Amount, Round(ExpectedAmount, 0.01));
        SalesLine.TestField("Unit Price", Round(ExpectedUnitPrice, 0.00001));
    end;

    local procedure VerifyPurchaseLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; CompItemNo: Code[20]; CompItemNo2: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
        PurchaseLine.Next();
        PurchaseLine.TestField("No.", CompItemNo);
        PurchaseLine.Next();
        PurchaseLine.TestField(Description, ExtendedTxt);
        PurchaseLine.Next();
        PurchaseLine.TestField("No.", CompItemNo2);
    end;

    local procedure VerifyInvoiceQtyOnPurchaseLine(PurchaseLine: Record "Purchase Line"; QtyToInvoice: Decimal; QtyInvoiced: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.TestField("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.TestField("Quantity Invoiced", QtyInvoiced);
    end;

    local procedure VerifyPurchLineHasCorrectSalesOrdersNo(PurchHeaderNo: Code[20]; SalesHeaderNo: Code[20])
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document No.", PurchHeaderNo);
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.FindFirst();
        Assert.AreEqual(SalesHeaderNo, PurchLine."Special Order Sales No.", SpecialOrderSalesNoErr);
    end;

    local procedure VerifyPurchLineExtTextBeforeItem(PurchHeader: Record "Purchase Header"; ExtendedText: Text; CompItemNo: Code[20])
    var
        PurchLine: Record "Purchase Line";
    begin
        FindPurchaseLineByHeader(PurchLine, PurchHeader);
        PurchLine.Next(); // the first line is description of Assembly BOM, just skip
        PurchLine.TestField(Type, 0);
        PurchLine.TestField(Description, ExtendedText);
        PurchLine.Next();
        PurchLine.TestField(Type, PurchLine.Type::Item);
        PurchLine.TestField("No.", CompItemNo);
    end;

    local procedure VerifyPostedPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LotNos: array[2] of Code[20]; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        VerifyItemTrackingInItemLedgerEntry(ItemLedgerEntry."Entry Type"::Purchase, ItemNo, LotNos, Qty);
        VerifyPurchReceiptLine(ItemNo, Qty);

        PurchaseHeader.SetRecFilter();
        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    local procedure VerifyTrackingSpecification(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer; LotNo: Code[50]; HandledQty: Decimal; InvoicedQty: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        TrackingSpecification.SetRange("Lot No.", LotNo);
        TrackingSpecification.CalcSums("Quantity Handled (Base)", "Quantity Invoiced (Base)");
        TrackingSpecification.TestField("Quantity Handled (Base)", HandledQty);
        TrackingSpecification.TestField("Quantity Invoiced (Base)", InvoicedQty);
    end;

    local procedure VerifyQtyToInvoiceInItemTrackingOnPurchLine(PurchaseLine: Record "Purchase Line"; QtyToInvoice: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
    begin
        ReservationEntry.SetSourceFilter(
          DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", false);
        ReservationEntry.CalcSums("Qty. to Invoice (Base)");

        TrackingSpecification.SetSourceFilter(
          DATABASE::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", false);
        TrackingSpecification.CalcSums("Qty. to Invoice (Base)");

        Assert.AreEqual(
          QtyToInvoice, ReservationEntry."Qty. to Invoice (Base)" + TrackingSpecification."Qty. to Invoice (Base)",
          'Wrong Qty. to Invoice in item tracking on the purchase line.');
    end;

    local procedure VerifyQtyToInvoiceInItemTrackingOnSalesLine(SalesLine: Record "Sales Line"; QtyToInvoice: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
    begin
        ReservationEntry.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", false);
        ReservationEntry.CalcSums("Qty. to Invoice (Base)");

        TrackingSpecification.SetSourceFilter(
          DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", false);
        TrackingSpecification.CalcSums("Qty. to Invoice (Base)");

        Assert.AreEqual(
          QtyToInvoice, ReservationEntry."Qty. to Invoice (Base)" + TrackingSpecification."Qty. to Invoice (Base)",
          'Wrong Qty. to Invoice in item tracking on the sales line.');
    end;

    local procedure VerifyLastItemRegister(var ItemRegister: Record "Item Register"; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemRegister.SetFilter("From Entry No.", '>0');
        ItemRegister.FindLast();
        ItemLedgerEntry.SetRange("Entry No.", ItemRegister."From Entry No.", ItemRegister."To Entry No.");
        ItemLedgerEntry.SetFilter("Item Register No.", '0|%1', ItemRegister."No.");
        Assert.RecordCount(ItemLedgerEntry, 2);
        VerifyItemApplicationEntry(ItemRegister."From Entry No.", ItemRegister."From Entry No.", 0, Quantity);
        VerifyItemApplicationEntry(ItemRegister."To Entry No.", ItemRegister."From Entry No.", ItemRegister."To Entry No.", -Quantity);
    end;

    local procedure VerifyItemLedgerEntryPurchaseNegativeAdjmt(ItemRegister: Record "Item Register")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        VerifyItemLedgerEntryType(ItemRegister."From Entry No.", ItemLedgerEntry."Entry Type"::Purchase);
        VerifyItemLedgerEntryType(ItemRegister."To Entry No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
    end;

    local procedure VerifyItemLedgerEntryNegativeAdjmtPurchase(ItemRegister: Record "Item Register")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        VerifyItemLedgerEntryType(ItemRegister."From Entry No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        VerifyItemLedgerEntryType(ItemRegister."To Entry No.", ItemLedgerEntry."Entry Type"::Purchase);
    end;

    local procedure VerifyItemLedgerEntryType(EntryNo: Integer; EntryType: Enum "Item Ledger Document Type")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Get(EntryNo);
        ItemLedgerEntry.TestField("Entry Type", EntryType);
    end;

    local procedure VerifyItemApplicationEntry(ItemLedgerEntryNo: Integer; InboundItemEntryNo: Integer; OutboundItemEntryNo: Integer; Quantity: Decimal)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ItemApplicationEntry.FindFirst();
        ItemApplicationEntry.TestField("Inbound Item Entry No.", InboundItemEntryNo);
        ItemApplicationEntry.TestField("Outbound Item Entry No.", OutboundItemEntryNo);
        ItemApplicationEntry.TestField(Quantity, Quantity);
    end;

    local procedure CreatePurchaseOrderWithItemTrackingMultipleLotNo(var PurchaseHeader: Record "Purchase Header"; var AssignedLotNos: array[3] of Code[20]; VendorNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
        IncrementQty: Decimal;
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignGivenLotNos);
        LibraryVariableStorage.Enqueue(ArrayLen(AssignedLotNos));
        IncrementQty := 0;
        for i := 1 to ArrayLen(AssignedLotNos) do begin
            LibraryVariableStorage.Enqueue(AssignedLotNos[i]);
            IncrementQty += 100;
            LibraryVariableStorage.Enqueue(IncrementQty);
        end;
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, Qty, '', true);
    end;

    local procedure SetLotNoOnPurchaseOrderItemTracking(PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LotNo: Code[50]; NewLotNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Set Lot No.");
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(NewLotNo);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure VerifyItemTrackingOnPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LotNo: Code[50]; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Get Lot Quantity");
        LibraryVariableStorage.Enqueue(LotNo);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.OpenItemTrackingLines();
        Assert.AreEqual(Qty, LibraryVariableStorage.DequeueDecimal(), WrongLotQtyOnPurchaseLineErr);
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
    procedure GetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        LotNo: Code[50];
        NoOfLots: Integer;
        i: Integer;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);  // Enqueue Lot No.
                end;
            ItemTrackingMode::AssignGivenLotNos:
                begin
                    NoOfLots := LibraryVariableStorage.DequeueInteger();
                    for i := 1 to NoOfLots do begin
                        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                        ItemTrackingLines.Next();
                    end;
                end;
            ItemTrackingMode::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::AssignSerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    ItemTrackingLines.First();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Serial No.".Value);
                end;
            ItemTrackingMode::UpdateQtyOnFirstLine:
                begin
                    ItemTrackingLines.First();
                    ItemTrackingLines."Qty. to Invoice (Base)".SetValue(0);  // Value 0 required for the test.
                end;
            ItemTrackingMode::UpdateQtyOnLastLine:
                begin
                    ItemTrackingLines.Last();
                    ItemTrackingLines."Qty. to Invoice (Base)".SetValue(0);  // Value 0 required for the test.
                end;
            ItemTrackingMode::UpdateLotQty:
                begin
                    ItemTrackingLines.FILTER.SetFilter("Lot No.", LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines."Qty. to Invoice (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingMode::VerifyLot:
                begin
                    GetLotNoFromItemTrackingPageHandler(LotNo);
                    ItemTrackingLines."Lot No.".AssertEquals(LotNo);
                end;
            ItemTrackingMode::"Set Lot No.":
                begin
                    ItemTrackingLines.FILTER.SetFilter("Lot No.", LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                end;
            ItemTrackingMode::"Get Lot Quantity":
                begin
                    ItemTrackingLines.FILTER.SetFilter("Lot No.", LibraryVariableStorage.DequeueText());
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Quantity (Base)".AsDecimal());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    local procedure CreateProdOrderRoutingLineWithRoutingLinkCode(ProdOrderLine: Record "Prod. Order Line"; WorkCenter: Record "Work Center"; CapacityType: Enum "Capacity Type"; RoutingLinkCode: Code[10]; RoutingLineCount: Integer)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        i: Integer;
    begin
        for i := 1 to RoutingLineCount do begin
            ProdOrderRoutingLine.Init();
            ProdOrderRoutingLine.Validate(Status, ProdOrderLine.Status);
            ProdOrderRoutingLine.Validate("Prod. Order No.", ProdOrderLine."Prod. Order No.");
            ProdOrderRoutingLine.Validate("Routing No.", ProdOrderLine."Routing No.");
            ProdOrderRoutingLine.Validate("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            ProdOrderRoutingLine.Validate("Operation No.", Format(LibraryRandom.RandInt(100)));
            ProdOrderRoutingLine.Insert(true);

            ProdOrderRoutingLine.Validate(Type, CapacityType);
            ProdOrderRoutingLine.Validate("Work Center No.", WorkCenter."No.");
            ProdOrderRoutingLine.Validate("No.", WorkCenter."No.");
            ProdOrderRoutingLine.Validate("Setup Time", LibraryRandom.RandInt(100));
            ProdOrderRoutingLine.Validate("Run Time", LibraryRandom.RandInt(100));
            ProdOrderRoutingLine.Validate("Wait Time", LibraryRandom.RandInt(100));
            ProdOrderRoutingLine.Validate("Move Time", LibraryRandom.RandInt(100));
            ProdOrderRoutingLine.Validate("Routing Link Code", RoutingLinkCode);
            ProdOrderRoutingLine.Modify(true);
        end;
    end;

    local procedure FindProdOrderRoutingLineForRoutingLinkCode(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: record "Prod. Order Line"; RoutingLinkCode: code[20])
    begin
        Clear(ProdOrderRoutingLine);
        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing Link Code", RoutingLinkCode);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure CreateProductionOrderWithRoutingNo(var ProductionOrder: Record "Production Order"; ProductionOrderStatus: Enum "Production Order Status"; ItemNo: Code[20]; Quantity: Decimal; RoutingNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Routing No.", RoutingNo);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
    end;

    local procedure CreateItemWithRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateProdOrderlineFromProdOrder(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ItemNo: Code[20]; ItemVariant: Code[10]; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", ItemNo, ItemVariant, LocationCode, ProductionOrder.Quantity);
        ProdOrderLine.Validate("Routing No.", ProductionOrder."Routing No.");
        ProdOrderLine.Modify(true);
    end;

    local procedure CreateProdOrderComponentWithRountingLinkCode(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; RoutingLinkCode: Code[20]; ComponentCount: Integer)
    var
        Item: Record Item;
        i: Integer;
    begin
        for i := 1 to ComponentCount do begin
            LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
            ProdOrderComponent.Validate(Status, ProdOrderLine.Status);
            ProdOrderComponent.Validate("Item No.", LibraryInventory.CreateItem(Item));
            ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandInt(10));
            ProdOrderComponent.Validate("Routing Link Code", RoutingLinkCode);
            ProdOrderComponent.Modify(true);
        end;
    end;

    local procedure CreateRoutingHeaderWithStatus(var RoutingHeader: Record "Routing Header"; RoutingStatus: Enum "Routing Status")
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        RoutingHeader.Validate(Status, RoutingStatus);
        RoutingHeader.Modify(true);
    end;

    local procedure UpdateRoutingLinkCodeInRoutingLine(ProdOrderNo: Code[20]; RoutingLinkCode: Code[20]; NewRoutingLinkCode: Code[20]; UpdateMode: Option " ","First Record","Last Record")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Link Code", RoutingLinkCode);
        case UpdateMode of
            UpdateMode::" ":
                if ProdOrderRoutingLine.FindSet() then
                    repeat
                        ProdOrderRoutingLine.Validate("Routing Link Code", NewRoutingLinkCode);
                        ProdOrderRoutingLine.Modify(true);
                    until ProdOrderRoutingLine.Next() = 0;
            UpdateMode::"First Record":
                if ProdOrderRoutingLine.FindFirst() then begin
                    ProdOrderRoutingLine.Validate("Routing Link Code", NewRoutingLinkCode);
                    ProdOrderRoutingLine.Modify(true);
                end;
            UpdateMode::"Last Record":
                if ProdOrderRoutingLine.FindLast() then begin
                    ProdOrderRoutingLine.Validate("Routing Link Code", NewRoutingLinkCode);
                    ProdOrderRoutingLine.Modify(true);
                end;
        end;
    end;

    local procedure VerifyDueDateTimeInProdOrderComponent(ProdOrderRouteLine: Record "Prod. Order Routing Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetLoadFields("Due Date-Time", "Due Date", "Due Time");
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderRouteLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRouteLine."Routing Link Code");
        if ProdOrderComponent.FindSet() then
            repeat
                Assert.AreEqual(
                    ProdOrderRouteLine."Starting Date-Time",
                    ProdOrderComponent."Due Date-Time",
                    StrSubstNo(ValueMustBeEqualErr, ProdOrderComponent.FieldCaption("Due Date-Time"), ProdOrderRouteLine."Starting Date-Time", ProdOrderComponent.TableCaption()));
                Assert.AreEqual(
                    ProdOrderRouteLine."Starting Date",
                    ProdOrderComponent."Due Date",
                    StrSubstNo(ValueMustBeEqualErr, ProdOrderComponent.FieldCaption("Due Date"), ProdOrderRouteLine."Starting Date", ProdOrderComponent.TableCaption()));
                Assert.AreEqual(
                    ProdOrderRouteLine."Starting Time",
                    ProdOrderComponent."Due Time",
                    StrSubstNo(ValueMustBeEqualErr, ProdOrderComponent.FieldCaption("Due Time"), ProdOrderRouteLine."Starting Date", ProdOrderComponent.TableCaption()));
            until ProdOrderComponent.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 3;  // Value 3 is used for Ship and Invoice.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedITLPageHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
        PostedItemTrackingLines."Lot No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentType: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
    begin
        PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Receipts"));
        PostedPurchaseDocumentLines.PostedRcpts.Last();
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        DocumentType: Option;
    begin
        DocumentType := LibraryVariableStorage.DequeueInteger();
        case DocumentType of
            PostedSalesDocType::"Posted Shipments":
                begin
                    PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(PostedSalesDocType::"Posted Shipments"));
                    PostedSalesDocumentLines.PostedShpts.Last();
                end;
            PostedSalesDocType::"Posted Return Receipts":
                begin
                    PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(PostedSalesDocType::"Posted Return Receipts"));
                    PostedSalesDocumentLines.PostedReturnRcpts.First();
                end;
        end;
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocTrackingPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(PostedSalesDocType::"Posted Shipments"));
        PostedSalesDocumentLines.PostedShpts.ItemTrackingLines.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocTrackingVerifyFilterPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(PostedSalesDocType::"Posted Shipments"));
        PostedSalesDocumentLines.PostedShpts.ItemTrackingLines.Invoke();

        PostedSalesDocumentLines.PostedShpts.First();
        PostedSalesDocumentLines.PostedShpts."Document No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PostedSalesDocumentLines.PostedShpts.Next();
        PostedSalesDocumentLines.PostedShpts."Document No.".AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(PostedSalesDocumentLines.Next(), StrSubstNo(WrongNoOfDocumentsListErr, 2));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateNewLotNo.SetValue(false);  // False required for the CreateNewLotNo in the tests.
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesModalPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ExplodeBomHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        // Take 1 for "Retrieve dimensions from components".
        Choice := 1;
    end;

    [ModalPageHandler]
    procedure ReservationModalPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

