codeunit 137163 "SCM Orders VI"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        LocationRed: Record Location;
        LocationGreen: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryJob: Codeunit "Library - Job";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryService: Codeunit "Library - Service";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryResource: Codeunit "Library - Resource";
        isInitialized: Boolean;
        ReserveItemsManuallyConfirmQst: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
        UndoReceiptMsg: Label 'Do you really want to undo the selected Receipt lines?';
        UndoReturnShipmentMsg: Label 'Do you really want to undo the selected Return Shipment lines?';
        UndoShipmentQst: Label 'Do you really want to undo the selected Shipment lines?';
        UndoServiceShipmentQst: Label 'Do you want to undo the selected shipment line(s)?';
        RecordMustBeDeletedTxt: Label 'Order must be deleted.';
        ExpectedReceiptDateErr: Label 'The change leads to a date conflict with existing reservations.';
        NegativeValueErr: Label 'The value must be greater than or equal to 0.';
        StartingDateErr: Label 'Starting Date cannot be after Ending Date';
        QuantityToInvoiceDoesNotMatchErr: Label 'The quantity to invoice does not match the quantity defined in item tracking.';
        ReturnOrderPostedMsg: Label 'All the documents were posted.';
        RecordCountErr: Label 'No of record must be same.';
        ExpectedCostPostingEnableToGLQst: Label 'If you enable the Expected Cost Posting to G/L, the program must update table Post Value Entry to G/L.';
        ExpectedCostPostingDisableToGLQst: Label 'If you disable the Expected Cost Posting to G/L, the program must update table Post Value Entry to G/L.';
        ExpectedCostPostingToGLMsg: Label 'Expected Cost Posting to G/L has been changed to Yes. You should now run Post Inventory Cost to G/L.';
        ConfirmTextForChangeOfSellToCustomerOrBuyFromVendorQst: Label 'Do you want to change';
        DiscountErr: Label 'The Discount Amount is not correct.';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        MissingMandatoryLocationTxt: Label 'Location Code must have a value in Requisition Line';
        CannotReserveFromSpecialOrderErr: Label 'You cannot reserve from this item ledger entry because the associated special sales order %1 has not been posted yet.', Comment = '%1: Sales Order No.';
        CannotInsertSalesLineWithoutHeaderErr: Label 'You cannot insert a sales line without a sales header.';
        CannotInsertPurchLineWithoutHeaderErr: Label 'You cannot insert a purchase line without a purchase header.';
        ValueMustBeEqualErr: Label '%1 value must be equal to %2 in %3', Comment = '%1 = Field Name, %2= Expected Value, %3 = Table Name';
        CannotCreatePurchaseOrderWithoutVendorErr: Label 'You cannot create purchase orders without specifying a vendor for all lines.';
        CannotCreatePurchaseOrderIsAlreadyWithSalesOrderErr: Label '%1 on sales order %2 is already associated with purchase order %3.', Comment = '%1 = number of item, %2 = number of document, %3 = number of purchase order';
        NoSalesLineToRetrieveErr: Label 'There are no sales lines to retrieve.';

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderAsReceiveAfterApplyingBlanketPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Vendor: Record Vendor;
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Blanket Purchase Order. Create Purchase Order and update Blanket Order No. on Purchase Order line.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);  // Value required for the test.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseBlanketOrder(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, Vendor."No.", Item."No.", Quantity2);
        CreatePurchaseOrder(PurchaseHeader2, PurchaseLine2, PurchaseLine.Type::Item, Vendor."No.", Item."No.", Quantity);
        UpdateBlanketOrderNoOnPurchaseLine(PurchaseLine2, PurchaseHeader."No.", PurchaseLine."Line No.");

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, false);  // Post as RECEIVE.

        // Verify.
        VerifyPurchaseBlanketOrderLine(PurchaseHeader."No.", Quantity2 - Quantity, Quantity);  // Value required for the test.
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchPageHandler,PurchReceiptLinePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptAfterPurchaseInvoiceWithItemCharge()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        Item: Record Item;
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and post Purchase Order. Create Purchase Invoice with Item Charge.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);  // Using Item Charge.
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
            Quantity, false);
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ItemChargeAssignmentPurchPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);  // Quantity used in ItemChargeAssignmentPurchPageHandler.
        LibraryVariableStorage.Enqueue(PostedDocumentNo);  // PostedDocumentNo used in PurchReceiptLinePageHandler.
        CreatePurchaseInvoice(
          PurchaseHeader2, PurchaseLine, PurchaseLine.Type::"Charge (Item)", PurchaseHeader."Buy-from Vendor No.",
          LibraryInventory.CreateItemChargeNo(), Quantity);
        PurchaseLine.ShowItemChargeAssgnt();

        // Exercise: Undo Purchase Receipt.
        UndoPurchaseReceiptLine(PostedDocumentNo);

        // Verify: Undo Purchase Receipt line.
        VerifyReceiptLine(PostedDocumentNo, Item."No.", Quantity, false);
        VerifyReceiptLine(PostedDocumentNo, Item."No.", -Quantity, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderAfterUndoPurchaseReceipt()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and post Purchase Order. Undo Purchase Receipt.
        Initialize();
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
            Quantity, false);
        UndoPurchaseReceiptLine(PostedDocumentNo);

        // Exercise: Post Purchase Order after Undo Purchase Receipt.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as RECEIVE.

        // Verify: Undo Purchase Receipt Line Created on Posting Purchase Order after Undo Purchase Receipt.
        VerifyReceiptLine(PostedDocumentNo, Item."No.", Quantity, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptWithNegativeQuantity()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and post Purchase Order with Negative Quantity.
        Initialize();
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
            -Quantity, false);

        // Exercise: Undo Purchase Receipt.
        UndoPurchaseReceiptLine(PostedDocumentNo);

        // Verify: Undo Purchase Receipt Line for Negative Lines.
        VerifyReceiptLine(PostedDocumentNo, Item."No.", -Quantity, false);
        VerifyReceiptLine(PostedDocumentNo, Item."No.", Quantity, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeletePurchaseOrderAfterUndoPurchaseReceipt()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and post Purchase Order. Undo Purchase Receipt.
        Initialize();
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
            -Quantity, false);
        UndoPurchaseReceiptLine(PostedDocumentNo);

        // Exercise: Delete Purchase Order.
        PurchaseHeader.Delete(true);

        // Verify: Purchase Order is Deleted.
        Assert.IsFalse(PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No."), RecordMustBeDeletedTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderAfterUndoReturnShipment()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and Post Purchase Return Order. Undo Return Shipment Line.
        Initialize();
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(),
            Item."No.", Quantity, false);
        UndoReturnShipmentLine(PostedDocumentNo);

        // Exercise: Post Purchase Return Order after Undo Return Shipment Line.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as RECEIVE.

        // Verify: Posted Return Shipment.
        VerifyReturnShipmentLine(PostedDocumentNo, Item."No.", Quantity, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnShipmentWithNegativeQuantity()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and post Purchase Return Order with Negative Quantity.
        Initialize();
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(),
            Item."No.", -Quantity, false);

        // Exercise: Undo Return Shipment Line.
        UndoReturnShipmentLine(PostedDocumentNo);

        // Verify: Undo Return Shipment Line for Negative Lines.
        VerifyReturnShipmentLine(PostedDocumentNo, Item."No.", -Quantity, false);
        VerifyReturnShipmentLine(PostedDocumentNo, Item."No.", Quantity, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure CannotUndoReturnShipmentForReservedQuantity()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and post Purchase Return Order with Negative Quantity. Create Sales Order and Reserve Quantity.
        Initialize();
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(),
            Item."No.", -Quantity, false);
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', Item."No.", Quantity, '');
        SalesLine.ShowReservation();

        // Exercise: Undo Return Shipment Line.
        asserterror UndoReturnShipmentLine(PostedDocumentNo);

        // Verify: Error Message Cannot Undo as Quantity is Already Reserved.
        Assert.ExpectedTestFieldError(ItemLedgEntry.FieldCaption("Reserved Quantity"), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithBlockedItemError()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Block Item.
        Initialize();
        CreateBlockedItem(Item);

        // Exercise: Create Purchase Order.
        asserterror CreatePurchaseOrder(
            PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
            LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderExpectedReceiptDateError()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase] [Reservation] [Date Conflict]
        // [SCENARIO 211625] Expected Receipt Date on Purchase Line cannot be updated if it becomes later than Shipment Date of sales reserved from this line.
        Initialize();

        // [GIVEN] Item "I" with Reserve = "Always".
        // [GIVEN] Purchase Order with item "I" and Expected Receipt Date = WORKDATE.
        // [GIVEN] Sales Order with item "I" reserved from the purchase.
        CreatePurchaseOrderWithReservedItem(PurchaseOrder);

        // [WHEN] Update Expected Receipt Date to a later date on the Purchase Line.
        asserterror PurchaseOrder.PurchLines."Expected Receipt Date".SetValue(
            CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));

        // [THEN] The error message is thrown reading that the date change has lead to a date conflict with existing reservation.
        Assert.ExpectedError(ExpectedReceiptDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineExpectedReceiptDateNotUpdatedIfDateErasedOnHeader()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase] [Reservation]
        // [SCENARIO 211625] Expected Receipt Date on Purchase Line should not be updated after this date is erased on Purchase Header.
        Initialize();

        // [GIVEN] Item "I" with Reserve = "Always".
        // [GIVEN] Purchase Order with item "I" and Expected Receipt Date = WORKDATE.
        // [GIVEN] Sales Order with item "I" reserved from the purchase.
        CreatePurchaseOrderWithReservedItem(PurchaseOrder);

        // [WHEN] Erase Expected Receipt Date on the Purchase Header.
        PurchaseOrder."Expected Receipt Date".SetValue(0D);

        // [THEN] Expected Receipt Date on the Purchase Line = WORKDATE.
        PurchaseOrder.PurchLines."Expected Receipt Date".AssertEquals(WorkDate());
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLineExpectedReceiptDateUpdatedIfDateSetEarlierOnHeader()
    var
        PurchaseOrder: TestPage "Purchase Order";
        NewDate: Date;
    begin
        // [FEATURE] [Purchase] [Reservation] [Date Conflict]
        // [SCENARIO 211625] Expected Receipt Date on Purchase Line can be updated if this date is set to an earlier value on Purchase Header.
        Initialize();

        // [GIVEN] Item "I" with Reserve = "Always".
        // [GIVEN] Purchase Order with item "I" and Expected Receipt Date = WORKDATE.
        // [GIVEN] Sales Order with item "I" reserved from the purchase.
        CreatePurchaseOrderWithReservedItem(PurchaseOrder);

        // [WHEN] Update Expected Receipt Date to an earlier date "D" on the Purchase Header.
        NewDate := LibraryRandom.RandDate(-10);
        PurchaseOrder."Expected Receipt Date".SetValue(NewDate);

        // [THEN] Expected Receipt Date on the Purchase Line = "D".
        PurchaseOrder.PurchLines."Expected Receipt Date".AssertEquals(NewDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineExpectedReceiptDateCannotBeErasedIfLineReserved()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase] [Reservation] [Date Conflict]
        // [SCENARIO 211625] Expected Receipt Date on Purchase Line cannot be erased if this line is reserved.
        Initialize();

        // [GIVEN] Item "I" with Reserve = "Always".
        // [GIVEN] Purchase Order with item "I" and Expected Receipt Date = WORKDATE.
        // [GIVEN] Sales Order with item "I" reserved from the purchase.
        CreatePurchaseOrderWithReservedItem(PurchaseOrder);

        // [WHEN] Erase Expected Receipt Date on the Purchase Line.
        asserterror PurchaseOrder.PurchLines."Expected Receipt Date".SetValue(0D);

        // [THEN] The error message is thrown reading that the date change has lead to a date conflict with existing reservation.
        Assert.ExpectedError(ExpectedReceiptDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePriceNegativeQuantityError()
    var
        PurchasePrices: TestPage "Purchase Prices";
    begin
        // Setup: Create Vendor and open Purchase Prices page from Vendor Card.
        Initialize();
        CreateVendorAndOpenPurchasePricesPageFromVendorCard(PurchasePrices);

        // Exercise: Enter Negative Minimum Quantity on Purchase Prices Page.
        asserterror PurchasePrices."Minimum Quantity".SetValue(-LibraryRandom.RandDec(10, 2));

        // Verify: Verify error message.
        Assert.ExpectedError(NegativeValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePriceNegativeDirectUnitCostError()
    var
        PurchasePrices: TestPage "Purchase Prices";
    begin
        // Setup: Create Vendor and open Purchase Prices page from Vendor Card.
        Initialize();
        CreateVendorAndOpenPurchasePricesPageFromVendorCard(PurchasePrices);

        // Exercise: Enter Negative Direct Unit Cost on Purchase Prices Page.
        asserterror PurchasePrices."Direct Unit Cost".SetValue(-LibraryRandom.RandDec(10, 2));

        // Verify: Verify error message.
        Assert.ExpectedError(NegativeValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePriceStartingDateAfterEndingDateError()
    var
        PurchasePrices: TestPage "Purchase Prices";
    begin
        // Setup: Create Vendor and open Purchase Prices page from Vendor Card.
        Initialize();
        CreateVendorAndOpenPurchasePricesPageFromVendorCard(PurchasePrices);

        // Exercise: Enter Ending Date Earlier to Starting Date on Purchase Prices Page.
        PurchasePrices."Starting Date".SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        asserterror PurchasePrices."Ending Date".SetValue(WorkDate());  // Ending Date is Earlier than Starting Date.

        // Verify: Verify error message.
        Assert.ExpectedError(StartingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePriceVendorValidation()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        VendorCard: TestPage "Vendor Card";
        PurchasePrices: TestPage "Purchase Prices";
    begin
        // [FEATURE] [Purchase Price]
        // [SCENARIO 378579] Validating "Vendor No." in Purchase Price Page should keep valid "Item No."
        Initialize();

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Vendor "V"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Purchase Price Page with "Item No." = "I"
        OpenVendorCard(VendorCard, Vendor."No.");
        PurchasePrices.Trap();
        VendorCard.Prices.Invoke();
        PurchasePrices."Item No.".SetValue(Item."No.");

        // [WHEN] Set "Vendor No." to "V" on Purchase Price Page
        PurchasePrices."Vendor No.".SetValue(Vendor."No.");

        // [THEN] Purchase Price Page keeps "Item No." = "I"
        PurchasePrices."Item No.".AssertEquals(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePriceVendorValidationErr()
    var
        PurchasePrice: Record "Purchase Price";
        PurchasePrices: TestPage "Purchase Prices";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase Price] [UT]
        // [SCENARIO 379639] No Purchase Price should be created if "Vendor No. Filter" is validated with non-existing value and then reset to blank.
        Initialize();

        // [GIVEN] Vendor "V".
        // [GIVEN] Purchase Price Page with "Vendor No. Filter" = "V".
        CreateVendorAndOpenPurchasePricesPageFromVendorCard(PurchasePrices);

        // [GIVEN] "Vendor No. Filter" = Non-existing Vendor.
        VendorNo := LibraryUtility.GenerateGUID();
        asserterror PurchasePrices.VendNoFilterCtrl.SetValue(VendorNo);

        // [WHEN] Set "Vendor No. Filter" to blank on Purchase Price Page.
        PurchasePrices.VendNoFilterCtrl.SetValue('');

        // [THEN] Purchase Price is not created.
        PurchasePrice.Init();
        PurchasePrice.SetRange("Vendor No.", VendorNo);
        Assert.RecordIsEmpty(PurchasePrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePriceItemValidationErr()
    var
        PurchasePrice: Record "Purchase Price";
        PurchasePrices: TestPage "Purchase Prices";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Purchase Price] [UT]
        // [SCENARIO 379639] No Purchase Price should be created if "Item No. Filter" is validated with non-existing value and then reset to blank.
        Initialize();

        // [GIVEN] Vendor "V".
        // [GIVEN] Purchase Price Page with "Vendor No. Filter" = "V".
        CreateVendorAndOpenPurchasePricesPageFromVendorCard(PurchasePrices);

        // [GIVEN] "Item No. Filter" = Non-existing Item.
        ItemNo := LibraryUtility.GenerateGUID();
        asserterror PurchasePrices.ItemNoFIlterCtrl.SetValue(ItemNo);

        // [WHEN] Set "Item No. Filter" to blank on Purchase Price Page.
        PurchasePrices.ItemNoFIlterCtrl.SetValue('');

        // [THEN] Purchase Price is not created.
        PurchasePrice.Init();
        PurchasePrice.SetRange("Item No.", ItemNo);
        Assert.RecordIsEmpty(PurchasePrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountNegativeQuantityError()
    var
        PurchaseLineDiscounts: TestPage "Purchase Line Discounts";
    begin
        // Setup: Create Vendor and open Purchase Line Discount page from Vendor Card.
        Initialize();
        CreateVendorAndOpenPurchaseLineDiscountsPageFromVendorCard(PurchaseLineDiscounts);

        // Exercise: Enter Negative Minimum Quantity on Purchase Line Discount Page.
        asserterror PurchaseLineDiscounts."Minimum Quantity".SetValue(-LibraryRandom.RandDec(10, 2));

        // Verify: Verify error message.
        Assert.ExpectedError(NegativeValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountNegativeLineDiscountError()
    var
        PurchaseLineDiscounts: TestPage "Purchase Line Discounts";
    begin
        // Setup: Create Vendor and open Purchase Line Discount page from Vendor Card.
        Initialize();
        CreateVendorAndOpenPurchaseLineDiscountsPageFromVendorCard(PurchaseLineDiscounts);

        // Exercise: Enter Negative Line Discount on Purchase Line Discount Page.
        asserterror PurchaseLineDiscounts."Line Discount %".SetValue(-LibraryRandom.RandDec(10, 2));

        // Verify: Verify error message.
        Assert.ExpectedError(NegativeValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountStartingDateAfterEndingDateError()
    var
        PurchaseLineDiscounts: TestPage "Purchase Line Discounts";
    begin
        // Setup:  Create Vendor and open Purchase Line Discount page from Vendor Card.
        Initialize();
        CreateVendorAndOpenPurchaseLineDiscountsPageFromVendorCard(PurchaseLineDiscounts);

        // Exercise: Enter Ending Date Earlier to Starting Date on Purchase Line Discount Page.
        PurchaseLineDiscounts."Starting Date".SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        asserterror PurchaseLineDiscounts."Ending Date".SetValue(WorkDate());  // Ending Date is Earlier than Starting Date.

        // Verify: Verify error message.
        Assert.ExpectedError(StartingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderWithExactCostReversingMandatoryTrue()
    begin
        // Setup.
        Initialize();
        PostPurchaseReturnOrderWithExactCostReversingMandatory(true);  // ExactCostReversingMandatory as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderWithExactCostReversingMandatoryFalse()
    begin
        // Setup.
        Initialize();
        PostPurchaseReturnOrderWithExactCostReversingMandatory(false);  // ExactCostReversingMandatory as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentFromPurchaseReturnOrderAfterRegisterPick()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Setup: Create and register Put-away from Purchase Order. Create and Register Pick from Purchase Return Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromPurchaseOrder(PurchaseLine, Item."No.", LocationGreen.Code);
        CreatePickFromPurchaseReturnOrder(
          PurchaseHeader, LocationGreen.Code, Item."No.", PurchaseLine."Buy-from Vendor No.", PurchaseLine.Quantity);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          Item."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Exercise.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");

        // Verify.
        VerifyPostedWhseShipmentLine(PurchaseHeader."No.", Item."No.", PurchaseLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteInvoicedPurchaseReturnOrdersReport()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // Setup: Create and post Purchase Order. Create and Post Purchase Credit Memo with Get Return Shipment Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item, Vendor."No.", Item."No.",
            LibraryRandom.RandDec(50, 2), false);
        CreateAndPostPurchaseCreditMemoAfterGetReturnShipmentLine(PurchaseHeader2, PostedDocumentNo, Vendor."No.", 0);

        // Exercise.
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        LibraryPurchase.RunDeleteInvoicedPurchaseReturnOrdersReport(PurchaseHeader);

        // Verify.
        FilterPurchaseHeader(PurchaseHeader, PurchaseHeader."No.");
        Assert.IsTrue(PurchaseHeader.IsEmpty, RecordMustBeDeletedTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveNegativePurchaseLineReport()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        Quantity: Decimal;
        FromDocumentType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo";
        ToDocumentType: Option ,,,,"Return Order","Credit Memo";
        ToDocumentType2: Option ,,"Order",Invoice;
    begin
        // Setup: Copy Document after create and post Purchase Order. Create negative Purchase Line in the Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        CopyDocumentAfterCreateAndPostPurchaseOrder(PurchaseHeader, Vendor."No.", Item."No.", Quantity);
        CreateNegativePurchaseLine(PurchaseHeader, Item."No.", -Quantity);

        // Exercise.
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        LibraryPurchase.RunMoveNegativePurchaseLinesReport(
          PurchaseHeader, FromDocumentType::Order, ToDocumentType::"Return Order", ToDocumentType2::Order);

        // Verify.
        VerifyPurchaseReturnOrder(PurchaseHeader."Buy-from Vendor No.", Vendor.Name, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithDifferentQuantityToInvoiceError()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
        Quantity2: Decimal;
        ItemTrackingMode: Option AssignLotNo,UpdateQuantityToInvoice;
    begin
        // Setup: Create and Post Purchase Order as SHIP with Lot No. Update Quantity to Invoice on Item Tracking line.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);  // Quantity Shipped is greater than Quantity to Invoice.
        LibraryItemTracking.CreateLotItem(Item);
        CreateAndPostPurchaseOrderWithLotNo(PurchaseHeader, PurchaseLine, Item."No.", Quantity2);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::UpdateQuantityToInvoice);  // Enqueue for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();

        // Exercise.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Post as INVOICE.

        // Verify.
        Assert.ExpectedError(StrSubstNo(QuantityToInvoiceDoesNotMatchErr));
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchRetOrderPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseReturnOrderReport()
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        Quantity: Decimal;
    begin
        // Setup: Create two Purchase Return Orders.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreatePurchaseReturnOrder(PurchaseHeader, Item."No.", Quantity);
        CreatePurchaseReturnOrder(PurchaseHeader2, Item2."No.", Quantity);

        // Exercise.
        LibraryVariableStorage.Enqueue(ReturnOrderPostedMsg);  // Enqueue for MessageHandler.
        PurchaseHeader.SetFilter("No.", '%1|%2', PurchaseHeader."No.", PurchaseHeader2."No.");
        LibraryPurchase.RunBatchPostPurchaseReturnOrdersReport(PurchaseHeader);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader2.RecordId);

        // Verify.
        VerifyPurchaseCreditMemoLine(Item."No.", Quantity);
        VerifyPurchaseCreditMemoLine(Item2."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CannotUndoReceiptWithAppliedQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();
        UndoPurchaseDocumentForAppliedQuantity(PurchaseHeader."Document Type"::Order, 1);  // Undo Purchase Receipt for Applied Quantity.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CannotUndoReturnShipmentOfAppliedNegativeQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();
        UndoPurchaseDocumentForAppliedQuantity(PurchaseHeader."Document Type"::"Return Order", -1);  // Undo Sales Shipment for Applied Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptPageAfterPostPurchaseOrderWithSpecialOrder()
    begin
        Initialize();
        PostPurchaseOrderWithSpecialOrder(false);  // Post Special Order Fully.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptsPageAfterPartiallyPostPurchaseOrderWithSpecialOrder()
    begin
        Initialize();
        PostPurchaseOrderWithSpecialOrder(true);  // Post Special Order Partially.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure StatusRemainsReleasedAfterUndoPostedPurchaseReceipt()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // Setup: Create and Post Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
            LibraryRandom.RandDec(10, 2), false);

        // Exercise.
        UndoPurchaseReceiptLine(PostedDocumentNo);

        // Verify.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure StatusRemainsOpenAfterUndoPurchaseReceiptOfReopenedPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // Setup: Create and Post Purchase Order. Reopen the Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
            LibraryRandom.RandDec(10, 2), false);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // Exercise.
        UndoPurchaseReceiptLine(PostedDocumentNo);

        // Verify.
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptWithUpdatedQuantityOnPurchaseLineAfterReopenPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
        Quantity2: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Setup: Create and Post Purchase Order. Reopen Purchase Order and update Quantity on Purchase line.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);  // Greater value required for the Quantity in the test.
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
            Quantity, false);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, Item."No.");
        UpdateQuantityOnPurchaseLine(PurchaseLine, Quantity2);

        // Exercise.
        UndoPurchaseReceiptLine(PostedDocumentNo);

        // Verify.
        FindPurchaseLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField("Qty. to Receive", Quantity2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunPostInventoryCostToGLAfterUndoPurchaseReceipt()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Quantity: Decimal;
        PostedDocumentNo: Code[20];
        OldExpectedCostPostingToGL: Boolean;
        LineNo: Integer;
    begin
        // Setup: Set Expected Cost Posting to GL on Inventory Setup. Create and Post Purchase Order. Undo Posted Purchase Receipt.
        Initialize();
        OldExpectedCostPostingToGL := UpdateExpectedCostPostingToGLOnInventorySetup(true);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
            Quantity, false);
        UndoPurchaseReceiptLine(PostedDocumentNo);
        LineNo := FindPurchaseReceiptLine(PurchRcptLine, PostedDocumentNo);

        // Exercise.
        LibraryVariableStorage.Enqueue(ValueEntriesWerePostedTxt);
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Item Ledger entries and Value entries.
        VerifyQuantityOnItemLedgerEntry(PostedDocumentNo, LineNo, Item."No.", Quantity);
        VerifyQuantityOnItemLedgerEntry(PostedDocumentNo, PurchRcptLine."Line No.", Item."No.", -Quantity);
        VerifyValueEntry(PostedDocumentNo, LineNo, Quantity);
        VerifyValueEntry(PostedDocumentNo, PurchRcptLine."Line No.", -Quantity);

        // Tear Down.
        UpdateExpectedCostPostingToGLOnInventorySetup(OldExpectedCostPostingToGL);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithDifferentItemChargeAfterUndoPurchaseReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create Purchase Order with Item Charge Assignment. Post the Order as Receive. Undo the Purchase Receipt. Create new Purchase Line and assign Item Charge.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.", Quantity);
        CreatePurchaseLineAndAssignItemCharge(PurchaseHeader, ItemCharge."No.", Quantity);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.
        UndoPurchaseReceiptLine(PostedDocumentNo);
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        CreatePurchaseLineAndAssignItemCharge(PurchaseHeader, ItemCharge."No.", Quantity);

        // Exercise.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify.
        VerifyPurchInvoiceLine(PostedDocumentNo, ItemCharge."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderAsReceiveAndInvoiceWithDifferentBuyFromVendorAndPayToVendor()
    begin
        // Setup.
        Initialize();
        PostCreditMemoAgainstPurchaseReturnOrderUsingPayToVendorDifferentFromPurchaseOrder(false, false);  // Use Return Order as False and Credit Memo as False.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PostedPurchaseDocumentLinePageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderAsShipUsingPayToVendorDifferentFromPurchaseOrder()
    begin
        // Setup.
        Initialize();
        PostCreditMemoAgainstPurchaseReturnOrderUsingPayToVendorDifferentFromPurchaseOrder(true, false);  // Use Return Order as True and Credit Memo as False.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PostedPurchaseDocumentLinePageHandler')]
    [Scope('OnPrem')]
    procedure PostCreditMemoUsingPayToVendorDifferentFromPurchaseOrder()
    begin
        // Setup.
        Initialize();
        PostCreditMemoAgainstPurchaseReturnOrderUsingPayToVendorDifferentFromPurchaseOrder(true, true);  // Use Return Order as True and Credit Memo as True.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeBuyFromVendorNoOnPurchaseOrderPage()
    var
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseOrderNo: Code[20];
    begin
        // Setup: Create Vendor. Create Purchase Order By Page.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrderByPage(PurchaseOrder);

        // Exercise: Change Buy From Vendor No. on Purchase Order.
        PurchaseOrderNo := PurchaseOrder."No.".Value();
        PurchaseOrder."Buy-from Vendor Name".SetValue(Vendor."No.");

        // Verify: Buy From Vendor No. is Changed on the Purchase Order.
        PurchaseOrder."No.".AssertEquals(PurchaseOrderNo);
        PurchaseOrder."Buy-from Vendor Name".AssertEquals(Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchPageWithSuggestHandler,ItemChargeAssignmentMenuHandler,PurchReceiptLinePageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithItemChargeWithPricesIncludingVATUnchecked()
    var
        PurchaseHeader: Record "Purchase Header";
        GeneralPostingSetup: Record "General Posting Setup";
        ExpdTotalDisAmt: Decimal;
        PostedDocNo: Code[20];
    begin
        // [SCENARIO 339745] Check total Discount Amount after posting Purchase Invoice with Item Charge
        // [GIVEN] Purchase Invoice with Charge Item with line discount and invoice discount.
        Initialize();

        ExpdTotalDisAmt :=
          CreatePurchInvoiceWithItemChargeWithLnDiscAndInvDisc(
            PurchaseHeader, GeneralPostingSetup, false); // Prices Including VAT is disabled.

        // [WHEN] Post purchase invoice.
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify the Discount Amount in Value Entry and G/L Entry.
        VerifyDiscountAmountInValueEntry(PostedDocNo, ExpdTotalDisAmt);
        VerifyDiscountAmountInGLEntry(
          PostedDocNo, GeneralPostingSetup."Purch. Line Disc. Account", GeneralPostingSetup."Purch. Inv. Disc. Account", -ExpdTotalDisAmt);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchPageWithSuggestHandler,PurchReceiptLinePageHandler,ItemChargeAssignmentMenuHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithItemChargeWithPricesIncludingVATChecked()
    var
        PurchaseHeader: Record "Purchase Header";
        GeneralPostingSetup: Record "General Posting Setup";
        ExpdTotalDisAmt: Decimal;
        PostedDocNo: Code[20];
    begin
        // Setup: Create vendor, item, create and post purchase order with item.
        // Create and post purchase invoice with charge item with line discount and invoice discount.
        Initialize();

        ExpdTotalDisAmt :=
          CreatePurchInvoiceWithItemChargeWithLnDiscAndInvDisc(
            PurchaseHeader, GeneralPostingSetup, true); // Prices Including VAT is enabled.

        // Exercise: Post purchase invoice.
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify the Discount Amount in Value Entry.
        VerifyDiscountAmountInValueEntry(PostedDocNo, ExpdTotalDisAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillPurchasingCodeAsSpecialOrderWhenReservationEntryExist()
    begin
        // Test an error pops up when filling Purchasing Code as Special Order when Reservation Entry exists.
        Initialize();
        FillPurchasingCodeWhenReservationEntryExist(false, true); // Speical Order as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillPurchasingCodeAsDropShipmentWhenReservationEntryExist()
    begin
        // Test an error pops up when filling Purchasing Code as Drop Shiment when Reservation Entry exists.
        Initialize();
        FillPurchasingCodeWhenReservationEntryExist(true, false); // Drop Shiment as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeReserveOptionAfterFillingPurchasingCodeAsSpecialOrder()
    begin
        // Test an error pops up when changing Reserve from Never to Always when Sales Order is marked to Special Order.
        Initialize();
        ChangeReserveOptionAfterFillingPurchasingCode(false, true); // Speical Order as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeReserveOptionAfterFillingPurchasingCodeAsDropShipment()
    begin
        // Test an error pops up when changing Reserve from Never to Always when Sales Order is marked to Drop Shipment.
        Initialize();
        ChangeReserveOptionAfterFillingPurchasingCode(true, false); // Drop Shiment as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyPostingPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create Location and Item. Create and register Put-away from Purchase Order.
        Initialize();
        GeneralSetupForRegisterPutAway(PurchaseLine);
        FindPurchaseReceiptLine2(PurchaseLine."Buy-from Vendor No.", PurchaseLine."No.", DocumentNo);

        // Exercise: Create Purchase Invoice by Get Receipt Lines. Partially posting the Invoice.
        CreateAndPostPurchaseInvoiceAfterGetReceiptLine(
          PurchaseHeader, PurchaseLine."Buy-from Vendor No.", DocumentNo, PurchaseLine.Quantity / 2);

        // Verify: Verify Qty. to Invoice on orignal Purchase Order Line.
        VerifyQtyToInvoiceOnPurchaseLine(
          PurchaseLine."No.", PurchaseLine."Document Type"::Order, PurchaseLine.Quantity / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyPostingPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Setup: Create and register Put-away from Purchase Order. Create and Register Pick from Purchase Return Order. Post Warehouse Shipment.
        Initialize();
        GeneralSetupForRegisterPutAway(PurchaseLine);
        PostWhseShipmentAfterPickFromPurchReturnOrder(
          PurchaseLine."Buy-from Vendor No.", PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine."No.");

        // Exercise: Create Purchase Credit Memo by Get Return Shipment Lines. Partially posting the Credit Memo.
        CreateAndPostPurchaseCreditMemoAfterGetReturnShipmentLine(
          PurchaseHeader, ReturnShipmentLine."Document No.",
          PurchaseLine."Buy-from Vendor No.", ReturnShipmentLine.Quantity / 2);

        // Verify: Verify Qty. to Invoice on orignal Purchase Return Order Line.
        VerifyQtyToInvoiceOnPurchaseLine(
          PurchaseLine."No.", PurchaseLine."Document Type"::"Return Order", ReturnShipmentLine.Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AutoReservePurchaseOrderWithSpecialOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Special Order] [Reservation]
        // [SCENARIO 375318] Purchase Order with Special Order option should not be Auto Reserved by another Sales Order
        Initialize();

        // [GIVEN] Purchase Order "P" for Special Sales Order "S1"
        CreateSpecialOrderSalesAndPurchase(SalesHeader, SalesLine);

        // [GIVEN] Sales Order "S2"
        CreateSalesOrderDiscardManualReservation(
          SalesHeader, SalesLine, SalesHeader."Sell-to Customer No.", SalesLine."No.", SalesLine.Quantity);

        // [WHEN] Auto Reserve Sales Line for "S2"
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [THEN] Reserved Quantity on Sales Line "S2" is blank
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AutoReserveItemLedgEntryPostedFromSpecialPurchaseOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Special Order] [Reservation]
        // [SCENARIO 376890] Item ledger entry posted from special order cannot be reserved for another sales order

        Initialize();

        // [GIVEN] Create sales order "SO1" and purchase order "PO" with special order link
        CreateSpecialOrderSalesAndPurchase(SalesHeader, SalesLine);

        // [GIVEN] Post purchase order "PO"
        SalesLine.Find();
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, SalesLine."Special Order Purchase No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create sales order "SO2"
        CreateSalesOrderDiscardManualReservation(
          SalesHeader, SalesLine, SalesHeader."Sell-to Customer No.", SalesLine."No.", SalesLine.Quantity);

        // [WHEN] Auto reserve sales order "SO2"
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [THEN] Reserved quantity on sales order "SO2" is 0
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoReserveItemLedgEntryPostedFromFinishedSpecialOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Special Order] [Reservation]
        // [SCENARIO 376890] Item ledger entry posted from special order can be reserved for another sales order after the special sales order is shipped.
        Initialize();

        // [GIVEN] Create sales order "SO1" and purchase order "PO" with special order link.
        CreateSpecialOrderSalesAndPurchase(SalesHeader, SalesLine);

        // [GIVEN] Double quantity on the purchase order line.
        // [GIVEN] Receive "PO".
        FindPurchaseLine(PurchaseLine, SalesLine."No.");
        UpdateQuantityOnPurchaseLine(PurchaseLine, PurchaseLine.Quantity * 2);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Ship "SO1".
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create sales order "SO2".
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', SalesLine."No.", SalesLine.Quantity, '');

        // [WHEN] Auto reserve sales order "SO2"
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [THEN] "SO2" is fully reserved.
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationPerItemEntryModalPageHandler,AvailableItemLedgEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure AutoReserveItemLedgEntryPostedFromUnfinishedSpecialPurchOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Special Order] [Reservation]
        // [SCENARIO 376890] Item ledger entry posted from special order cannot be reserved for another sales order before the special sales order is shipped.
        Initialize();

        // [GIVEN] Create sales order "SO1" and purchase order "PO" with special order link.
        CreateSpecialOrderSalesAndPurchase(SalesHeader, SalesLine);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] Double quantity on the purchase order line.
        // [GIVEN] Receive "PO".
        FindPurchaseLine(PurchaseLine, SalesLine."No.");
        UpdateQuantityOnPurchaseLine(PurchaseLine, PurchaseLine.Quantity * 2);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create sales order "SO2".
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', SalesLine."No.", SalesLine.Quantity, '');

        // [WHEN] Open reservation page for "SO2" and reserve from the posted "PO".
        asserterror SalesLine.ShowReservation();

        // [THEN] An error message is shown pointing that the special sales order "SO1" has not been posted yet.
        Assert.ExpectedError(StrSubstNo(CannotReserveFromSpecialOrderErr, SalesHeaderNo));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedTextForMoveNegativeLinesOnPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ItemNo: array[2] of Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase Order] [Extended Text]
        // [SCENARIO 376033] Move Negative Lines should not copy Extended Text lines that are attached to Purchase Lines with positive Quantity
        Initialize();

        // [GIVEN] Purchase Order with two Lines
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);

        // [GIVEN] Purchase Order Line with Quantity > 0; Extended Text = "T1"
        ItemNo[1] := CreateItemWithExtText();
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo[1], LibraryRandom.RandInt(100));
        if TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, true) then
            TransferExtendedText.InsertPurchExtText(PurchLine);

        // [GIVEN] Purchase Order Line with Quantity < 0; Extended Text = "T2"
        ItemNo[2] := CreateItemWithExtText();
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo[2], -LibraryRandom.RandInt(100));
        if TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, true) then
            TransferExtendedText.InsertPurchExtText(PurchLine);

        // [WHEN] Move Negative Lines
        MoveNegativeLinesOnPurchOrder(PurchHeader);

        // [THEN] Purchase Return Order is created with "T2" Line but not with "T1" Line
        FilterPurchReturnExtLine(PurchLine, VendorNo);
        PurchLine.SetRange(Description, ItemNo[2]);
        Assert.RecordIsNotEmpty(PurchLine);
        PurchLine.SetRange(Description, ItemNo[1]);
        Assert.RecordIsEmpty(PurchLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippedPurchaseReturnOrderUom()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase Return Order] [Unit of Measure] [UT]
        // [SCENARIO 376171] Validating of Unit of Measure code should be prohibited if "Return Qty. Shipped" is not zero
        Initialize();

        // [GIVEN] Purchase Return Order Line with "Return Qty. Shipped" <> 0
        CreatePurchOrderWithQuantityShipped(PurchaseLine, 0, LibraryRandom.RandInt(10));

        // [WHEN] Validate Unit Of Measure Code
        asserterror PurchaseLine.Validate("Unit of Measure Code");

        // [THEN] Error is thrown: "Return Qty. Shipped must be equal to '0'  in Purchase Line"
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Return Qty. Shipped"), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippedPurchaseReturnOrderUomBase()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase Return Order] [Unit of Measure] [UT]
        // [SCENARIO 376171] Validating of Unit of Measure code should be prohibited if "Return Qty. Shipped (Base)" is not zero.
        Initialize();

        // [GIVEN] Purchase Return Order Line with "Return Qty. Shipped (Base)" <> 0
        CreatePurchOrderWithQuantityShipped(PurchaseLine, LibraryRandom.RandInt(10), 0);

        // [WHEN] Validate Unit Of Measure Code
        asserterror PurchaseLine.Validate("Unit of Measure Code");

        // [THEN] Error is thrown: "Return Qty. Shipped (Base) must be equal to '0'  in Purchase Line"
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Return Qty. Shipped (Base)"), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderForDropShipmentCreatedWithReqWkshMandatoryLocationCheck()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment] [Location Mandatory]
        // [SCENARIO 381228] Purchase Order for drop shipment with blank location cannot be created from the Requisition Line when "Location Mandatory" is selected in Inventory Setup.
        Initialize();

        // [GIVEN] "Location Mandatory" is set to TRUE.
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Sales Order with drop shipment and blank Location Code.
        CreateItemWithVendorNo(Item);
        CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), Item."No.", 10);

        // [WHEN] Create Requisition Line and try to carry out action message.
        asserterror GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(SalesLine);

        // [THEN] Error is thrown indicating the Location Code is missing on the Requisition Line.
        Assert.ExpectedError(MissingMandatoryLocationTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Description2FromItemReferenceOnValidateRequisitionLineVendorNo()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        ItemReference: Record "Item Reference";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Item Reference] [Planning]
        // [SCENARIO 257873] "Description 2" is populated from "Item Reference" when validate "Vendor No." in "Requisition Line"
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] "Item Reference" "R" for Item "I" and Vendor "V" with populated "Description 2"
        CreateItemReferenceForVendor(ItemReference, Item."No.", Vendor."No.");
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);

        // [WHEN] validate fields "No." and "Vendor No." of "Requisition Line" "L" with "I" and "V"
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate("Vendor No.", Vendor."No.");

        // [THEN] "L"."Description 2" = "R"."Description 2"
        RequisitionLine.TestField("Description 2", ItemReference."Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Description2FromItemReferenceOnValidatePurchaseLineItemReferenceFields()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        ItemReference: Record "Item Reference";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Reference] [Purchase]
        // [SCENARIO 257873] "Description 2" is populated from "Item Reference" when validate item reference fields in "Purchase Line"
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase document with Item "I" contains line "L"
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          Vendor."No.", Item."No.", LibraryRandom.RandInt(10), '', WorkDate());

        // [GIVEN] "Item Reference" "R" for "I" and Vendor "V" with populated "Description 2"
        CreateItemReferenceForVendor(ItemReference, Item."No.", Vendor."No.");

        // [WHEN] validate Item Reference fields of "L" with "R"
        PurchaseLine.Validate("Item Reference Type", PurchaseLine."Item Reference Type"::Vendor);
        PurchaseLine.Validate("Item Reference Type No.", Vendor."No.");
        PurchaseLine.Validate("Item Reference No.", ItemReference."Reference No.");

        // [THEN] "L"."Description 2" = "R"."Description 2"
        PurchaseLine.TestField("Description 2", ItemReference."Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Description2FromItemReferenceOnValidateSalesLineItemReferenceFields()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemReference: Record "Item Reference";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Item Reference] [Sales]
        // [SCENARIO 257873] "Description 2" is populated from "Item Reference" when validate item reference fields in "Sales Line"
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales document with Item "I" contains line "L"
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", Item."No.", LibraryRandom.RandInt(10), '', WorkDate());

        // [GIVEN] "Item Reference" "R" for "I" and Customer "C" with populated "Description 2"
        CreateItemReferenceForCustomer(ItemReference, Item."No.", Customer."No.");

        // [WHEN] validate Item Reference fields of "L" with "R"
        SalesLine.Validate("Item Reference Type", SalesLine."Item Reference Type"::Customer);
        SalesLine.Validate("Item Reference Type No.", Customer."No.");
        SalesLine.Validate("Item Reference No.", ItemReference."Reference No.");

        // [THEN] "L"."Description 2" = "R"."Description 2"
        SalesLine.TestField("Description 2", ItemReference."Description 2");
    end;

    [Test]
    [HandlerFunctions('SalesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure Description2FromItemReferenceOnGetDropShipment()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        ItemReference: Record "Item Reference";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Reference] [Drop Shipment]
        // [SCENARIO 257873] "Description 2" is populated from "Item Reference" when get drop shipment
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] "Item Reference" "R" for Item "I" and Vendor "V" with populated "Description 2"
        CreateItemReferenceForVendor(ItemReference, Item."No.", Vendor."No.");

        // [GIVEN] Sales order with drop shipment and corresponding purchase order
        CreatePurchOrderWithSelltoCustomerNo(PurchaseHeader, Vendor."No.", Customer."No.");
        LibraryVariableStorage.Enqueue(CreateDropShipmentSalesOrder(Customer."No.", Item."No."));

        // [WHEN] Run "Get Sales Orders" from the purchase order and select the sales order with drop shipment
        LibraryPurchase.GetDropShipment(PurchaseHeader);
        FindPurchaseLine(PurchaseLine, Item."No.");

        // [THEN] Purchase line "L" is created and "L"."Description 2" = "R"."Description 2"
        PurchaseLine.TestField("Description 2", ItemReference."Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Description2FromItemReferenceOnValidatePurchaseLineNo()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        ItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Reference] [Purchase]
        // [SCENARIO 257873] "Description 2" is populated from "Item Reference" when validate "No." in "Purchase Line"
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] "Item Reference" "R" for Item "I" and Vendor "V" with populated "Description 2"
        CreateItemReferenceForVendor(ItemReference, Item."No.", Vendor."No.");

        // [GIVEN] Blank line "L" of purchase order with "Buy-from Vendor No." = "V"
        CreatePurchaseOrderWithBlankLine(PurchaseLine, Vendor."No.");

        // [WHEN] validate "L" with "I"
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate("No.", Item."No.");

        // [THEN] "L"."Description 2" = "R"."Description 2"
        PurchaseLine.TestField("Description 2", ItemReference."Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Description2FromItemReferenceOnValidateSalesLineNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Item Reference] [Sales]
        // [SCENARIO 257873] "Description 2" is populated from "Item Reference" when validate "No." in "Sales Line"
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] "Item Reference" "R" for "I" and Customer "C" with populated "Description 2"
        CreateItemReferenceForCustomer(ItemReference, Item."No.", Customer."No.");

        // [GIVEN] Blank line "L" of sales order with "Sell-to Customer No." = "C"
        CreateSalesOrderWithBlankLine(SalesLine, Customer."No.");

        // [WHEN] validate "L" with "I"
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", Item."No.");

        // [THEN] "L"."Description 2" = "R"."Description 2"
        SalesLine.TestField("Description 2", ItemReference."Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionFromItemReferenceOnCreateItemVendor()
    var
        Language: Record Language;
        Vendor: Record Vendor;
        Item: Record Item;
        ItemVendor: Record "Item Vendor";
        ItemReference: Record "Item Reference";
        ItemTranslation: Record "Item Translation";
    begin
        // [FEATURE] [Item Reference] [Item Vendor]
        // [SCENARIO 257873] Description and "Description 2" in "Item Reference" must stay empty when "Item Vendor" is created
        Initialize();

        Language.Get(LibraryERM.GetAnyLanguageDifferentFromCurrent());
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Vendor "V" with language code
        Vendor.Validate("Language Code", Language.Code);
        Vendor.Modify(true);

        // [GIVEN] Create Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Item Translation "T" for "I" with "Description" and "Description 2"
        CreateItemTranslation(ItemTranslation, Item."No.", Language.Code);

        // [WHEN] create "Item Vendor" for "I" and "V"
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");

        // [THEN] "Item Reference" is created; "Description" and "Description 2" are empty
        FindItemReferenceByVendorNo(ItemReference, Item."No.", Vendor."No.");
        ItemReference.TestField(Description, '');
        ItemReference.TestField("Description 2", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActionInsertProductionOrderTakesEarliestStartingDateTime()
    var
        RequisitionLine: array[3] of Record "Requisition Line";
        ProductionOrder: Record "Production Order";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        TempDocumentEntry: Record "Document Entry" temporary;
        MfgCarryOutAction: Codeunit "Mfg. Carry Out Action";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        "Count": Integer;
    begin
        // [FEATURE] [Planning]
        // [SCENARIO 289230] Carry Out Action.InsertProductionOrder takes the earliest Starting Date and Time when created from multiple Requisition Lines
        Initialize();

        // [GIVEN] A Requisition Worksheet Template and Name
        CreateReqWkshTemplateName(ReqWkshTemplate, RequisitionWkshName);

        // [GIVEN] ItemNo and DocumentNo needed for Requisition Lines
        ItemNo := LibraryInventory.CreateItemNo();
        DocumentNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Requisition Line [1] with Starting Date = 11-01-2020 and Starting Time = 01:00:00
        CreateRequisitionLine(RequisitionLine[1], ReqWkshTemplate, RequisitionWkshName, WorkDate(), 020000T, ItemNo, DocumentNo);

        // [GIVEN] Requisition Line [2] with Starting Date = 01-01-2020 and Starting Time = 02:00:00
        CreateRequisitionLine(
          RequisitionLine[2], ReqWkshTemplate, RequisitionWkshName, WorkDate() - LibraryRandom.RandInt(10), 010000T, ItemNo, DocumentNo);

        // [GIVEN] Requisition Line [3] with Starting Date = 21-01-2020 and Starting Time = 03:00:00
        CreateRequisitionLine(
          RequisitionLine[3], ReqWkshTemplate, RequisitionWkshName, WorkDate() + LibraryRandom.RandInt(10), 030000T, ItemNo, DocumentNo);

        // [WHEN] InsertProductionOrder is called for all 3 lines (2 = Firm Production Order)
        for Count := 1 to ArrayLen(RequisitionLine) do
            MfgCarryOutAction.InsertProductionOrder(
                RequisitionLine[Count], "Planning Create Prod. Order"::"Firm Planned", TempDocumentEntry);

        // [THEN] Production order is created
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", ItemNo);
        ProductionOrder.FindFirst();

        // [THEN] Production Order Starting Date = 01-01-2018
        ProductionOrder.TestField("Starting Date", RequisitionLine[2]."Starting Date");

        // [THEN] Production Order Starting Time = 02:00:00
        ProductionOrder.TestField("Starting Time", RequisitionLine[2]."Starting Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderLineInsertDoesNotChangeProdOrderCompLines()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production Order] [Prod. Order Component] [Make-to-Order]
        // [SCENARIO 293010] Validating Item No on a new Production Order line doesn't change Planning Level Code for Production Order Components
        Initialize();

        // [GIVEN] Production Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, '', LibraryRandom.RandDec(10, 2));

        // [GIVEN] Production Order Line
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status::Planned, ProductionOrder."No.",
          LibraryInventory.CreateItemNo(), '', '', LibraryRandom.RandDec(10, 2));

        // [GIVEN] Production Order Component Line with Supplied by Line No. = 0
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderComponent.Status::Planned, ProductionOrder."No.", ProdOrderLine."Line No.");

        // [WHEN] Changing Item No on a new Production Order Line
        ProdOrderLine.Init();
        ProdOrderLine.Validate("Line No.", 0);
        ProdOrderLine.Validate("Item No.", LibraryInventory.CreateItemNo());

        // [THEN] Planning Code on Production Order Component Line isn't changed
        ProdOrderComponent.Find();
        ProdOrderComponent.TestField("Planning Level Code", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderLineChangingItemNoChangesPlanningCodeOnProdOrderCompLine()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production Order] [Prod. Order Component] [Make-to-Order]
        // [SCENARIO 293010] Validating Item No on an existing Production Order line changes Planning Level Code for Production Order Components Supplied by this line
        Initialize();

        // [GIVEN] Production Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, '', LibraryRandom.RandDec(10, 2));

        // [GIVEN] Production Order Line, Line No = 1
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine[1], ProductionOrder.Status::Planned, ProductionOrder."No.",
          LibraryInventory.CreateItemNo(), '', '', LibraryRandom.RandDec(10, 2));

        // [GIVEN] Second Production Order Line, Line No = 2
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine[2], ProductionOrder.Status::Planned, ProductionOrder."No.",
          LibraryInventory.CreateItemNo(), '', '', LibraryRandom.RandDec(10, 2));

        // [GIVEN] Production Order Component Line with Supplied by Line No. = 2 and Planning Level Code = 1
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderComponent.Status::Planned, ProductionOrder."No.", ProdOrderLine[1]."Line No.");
        ProdOrderComponent.Validate("Supplied-by Line No.", ProdOrderLine[2]."Line No.");
        ProdOrderComponent.Validate("Planning Level Code", 1);
        ProdOrderComponent.Modify(true);

        // [WHEN] Changing Item No on Production Order Line with Line No = 2
        ProdOrderLine[2].Validate("Item No.", LibraryInventory.CreateItemNo());

        // [THEN] Planning Level Code on Production Order Component Line is 0
        ProdOrderComponent.Find();
        ProdOrderComponent.TestField("Planning Level Code", 0);

        // [THEN] Supplied by Line No on Production Order Component Line is 0
        ProdOrderComponent.TestField("Supplied-by Line No.", 0);
    end;

    [Test]
    [HandlerFunctions('CreateInventoryPutAwayPickHandler,EmptyMessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPickForProductionComponentPartiallyReservedFromPurchaseOrder()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        ReservationManagement: Codeunit "Reservation Management";
        StockQty: Decimal;
        PurchQty: Decimal;
        PerQty: Decimal;
        ProdQty: Decimal;
        FullAutoReserve: Boolean;
    begin
        // [FEATURE] [Production Order] [Prod. Order Component] [Inventory Pick] [Reservation]
        // [SCENARIO 301474] Inventory Pick posted for Production Order when there is a partial reservation from Production Order Component to a Purchase Order
        Initialize();

        PerQty := LibraryRandom.RandIntInRange(2, 5);
        PurchQty := LibraryRandom.RandIntInRange(2, 5) * PerQty;
        StockQty := LibraryRandom.RandIntInRange(2, 5) * PerQty;
        ProdQty := (PurchQty + StockQty) / PerQty;

        // [GIVEN] Location "Red" require pick with a warehouse user assigned
        LocationRed.TestField("Require Pick", true);

        // [GIVEN] Production item "ProdItem" with production BOM assigned having component item "Component" with quantity per = 2
        LibraryInventory.CreateItem(CompItem);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", PerQty);
        LibraryManufacturing.CreateItemManufacturing(
          ProdItem, ProdItem."Costing Method"::Standard, 0, ProdItem."Reordering Policy"::" ",
          ProdItem."Flushing Method"::Backward, '', ProductionBOMHeader."No.");

        // [GIVEN] Purchase Order "PO" for "Component", quantity = 4 for location code "Red"
        CreatePurchaseOrderWithItemQtyLocationExpectedDate(CompItem."No.", PurchQty, LocationRed.Code, CalcDate('<-CY>', WorkDate()));

        // [GIVEN] Production Order "Prod" for "ProdItem" quantity = 6 for "Red" location
        CreateProductionOrderWithItemQtyLocationWithRefreshAction(ProdItem."No.", ProdQty, LocationRed.Code);

        // [GIVEN] Production Order Component for "Prod" has a reservation from "PO" for quantity = 4 for "Red" location
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();
        ReservationManagement.SetReservSource(ProdOrderComponent);
        ReservationManagement.AutoReserve(FullAutoReserve, '', ProdOrderComponent."Due Date", PurchQty, PurchQty);

        // [GIVEN] "Component" stock quantity = 8 added to "Red" location
        CreateAndPostItemJournalLine(CompItem."No.", StockQty, LocationRed.Code, 1);

        // [GIVEN] Inventory Pick created for "Prod" for "Component" with quantity = 8
        ProductionOrder.Get(ProductionOrder.Status::Released, ProdOrderComponent."Prod. Order No.");
        ProductionOrder.CreateInvtPutAwayPick();

        // [WHEN] Post Inventory Pick for "Component"
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Prod. Consumption");
        WarehouseActivityHeader.SetRange("Source No.", ProdOrderComponent."Prod. Order No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Inventory Pick for "Component" is posted
        PostedInvtPickLine.SetRange("Item No.", CompItem."No.");
        PostedInvtPickLine.FindFirst();
        PostedInvtPickLine.TestField(Quantity, StockQty);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptWithTwoLinesWithJobNo()
    var
        Item: array[2] of Record Item;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReceiptNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Undo Receipt] [Job]
        // [SCENARIO 306371] Undo Purchase Receipt Lines works for 2 receipt lines with Job No.
        Initialize();

        // [GIVEN] Create 2 Items
        for i := 1 to ArrayLen(Item) do
            LibraryInventory.CreateItem(Item[i]);

        // [GIVEN] Create and Post Purchase Order with 2 lines, each with a Job No.
        ReceiptNo := CreateAndPostPurchaseOrderWithMultipleItemsAndJobNo(Item, LibraryRandom.RandDec(10, 2));

        // [WHEN] Undo Purchase Receipt lines.
        UndoPurchaseReceiptLine(ReceiptNo);

        // [THEN] Verify There are 4 Purchase Receipt Lines. (2 original + 2 reversing)
        PurchRcptLine.SetRange("Document No.", ReceiptNo);
        Assert.RecordCount(PurchRcptLine, 4);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure QtyToShipOnSalesOrderNonInventoriableWhenShipmentRequired()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Order] [Non-Inventoriable]
        // [SCENARIO 348918] "Qty. To Ship" is set to "Outstanding Quantity" in Sales Order Lines for Non-Inventoriable Items when Shipment Required On Warehouse Setup
        Initialize();

        // [GIVEN] Shipment Required on Warehouse Setup
        LibraryWarehouse.SetRequireShipmentOnWarehouseSetup(true);

        // [GIVEN] Sales Order Line for Non-Inventory item
        LibraryInventory.CreateNonInventoryTypeItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [WHEN] Set Quantity = 10 on Sales Line
        SalesLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));

        // [THEN] "Qty. to Ship" = 10
        SalesLine.TestField("Qty. to Ship", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure QtyToReceiveOnPurchOrderNonInventoriableWhenReceiveRequired()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Order] [Non-Inventoriable]
        // [SCENARIO 348918] "Qty. To Receive" is set to "Outstanding Quantity" in Purchase Order Lines for Non-Inventoriable Items when Receive Required On Warehouse Setup
        Initialize();

        // [GIVEN] Receive Required on Warehouse Setup
        LibraryWarehouse.SetRequireReceiveOnWarehouseSetup(true);

        // [GIVEN] Purchase Order Line for Non-Inventory item
        LibraryInventory.CreateNonInventoryTypeItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 0);

        // [WHEN] Set Quantity = 10 on Purchase Line
        PurchaseLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));

        // [THEN] "Qty. to Receive" = 10
        PurchaseLine.TestField("Qty. to Receive", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseRequestIncompleteOnUndoPurchaseLine()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        ReceiptNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Order] [Undo Receipt] [Warehouse Request]
        // [SCENARIO 373082] Stan can create warehouse receipt from purchase order for which a purchase receipt has been undone.
        Initialize();

        // [GIVEN] Location "L" with required receipt.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase order on location "L".
        // [GIVEN] Post receipt.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10),
          Location.Code, WorkDate());
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity);
        PurchaseLine.Modify(true);
        ReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Undo the purchase receipt line.
        UndoPurchaseReceiptLine(ReceiptNo);

        // [WHEN] Create warehouse receipt from the purchase order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] A warehouse receipt has been created.
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseRequestIncompleteOnUndoSalesLine()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Order] [Undo Receipt] [Warehouse Request]
        // [SCENARIO 373082] Stan can create warehouse shipment from sales order for which a sales shipment has been undone.
        Initialize();

        // [GIVEN] Location "L" with required shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales order on location "L".
        // [GIVEN] Post shipment.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10),
          Location.Code, WorkDate());
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity);
        SalesLine.Modify(true);
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Undo the sales shipment line.
        UndoSalesShipmentLine(ShipmentNo);

        // [WHEN] Create warehouse shipment from the sales order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] A warehouse shipment has been created.
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseRequestIncompleteOnUndoServiceLine()
    var
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Service] [Order] [Undo Shipment] [Warehouse Request]
        // [SCENARIO 373082] Stan can create warehouse shipment from service order for which a service shipment has been undone.
        Initialize();

        // [GIVEN] Location "L" with required shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);

        // [GIVEN] Service order with service line on location "L".
        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.Validate("Location Code", Location.Code);
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity);
        ServiceLine.Modify(true);

        // [GIVEN] Post shipment.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [GIVEN] Undo the service shipment line.
        ServiceHeader.Find();
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        UndoServiceShipmentLine(ServiceHeader."No.");

        // [WHEN] Create warehouse shipment from the service order.
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);

        // [THEN] A warehouse shipment has been created.
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Service Order", ServiceHeader."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesLineDropShipmentRemainsTrueOnRecreateSalesLinesWhenItemDropShipmentTrue()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 374832] Change "Bill-to Customer No." on Sales Order when Drop Shipment is set for Sales Line and Item from Sales Line has Drop Shipment = true.
        Initialize();

        // [GIVEN] Purchasing Code "P" with Drop Shipment = true. Item with Purchasing Code "P". Sales Order that has Sales Line with Item.
        // [GIVEN] Drop Shipment value for Sales Line is true and it is taken from item's Purchasing Code "P".
        LibraryInventory.CreateItem(Item);
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');
        SalesLine.TestField("Purchasing Code", Item."Purchasing Code");
        SalesLine.TestField("Drop Shipment");

        // [WHEN] Change "Bill-to Customer No." for Sales Order.
        SalesHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Modify(true);

        // [THEN] Sales Line is recreated. Purchasing Code = "P" and Drop Shipment = true for Sales Line. Drop Shipment value is saved after recreation.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Purchasing Code", Item."Purchasing Code");
        SalesLine.TestField("Drop Shipment");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesLineDropShipmentRemainsFalseOnRecreateSalesLinesWhenItemDropShipmentTrue()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 374832] Change "Bill-to Customer No." on Sales Order when Drop Shipment is not set for Sales Line and Item from Sales Line has Drop Shipment = true.
        Initialize();

        // [GIVEN] Purchasing Code "P" with Drop Shipment = true. Item with Purchasing Code "P". Sales Order that has Sales Line with Item.
        // [GIVEN] Drop Shipment value for Sales Line is manually set to false.
        LibraryInventory.CreateItem(Item);
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');
        UpdateDropShipmentOnSalesLine(SalesLine, false);

        // [WHEN] Change "Bill-to Customer No." for Sales Order.
        SalesHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Modify(true);

        // [THEN] Sales Line is recreated. Purchasing Code = "P" and Drop Shipment = false for Sales Line. Drop Shipment value is saved after recreation.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Purchasing Code", Item."Purchasing Code");
        SalesLine.TestField("Drop Shipment", false);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesLineDropShipmentRemainsTrueOnRecreateSalesLinesWhenItemDropShipmentFalse()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 374832] Change "Bill-to Customer No." on Sales Order when Drop Shipment is set for Sales Line and Item from Sales Line has Drop Shipment = false.
        Initialize();

        // [GIVEN] Purchasing Code "P" with Drop Shipment = false. Item with Purchasing Code "P". Sales Order that has Sales Line with Item.
        // [GIVEN] Drop Shipment value for Sales Line is manually set to true.
        LibraryInventory.CreateItem(Item);
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(false, false));
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');
        UpdateDropShipmentOnSalesLine(SalesLine, true);

        // [WHEN] Change "Bill-to Customer No." for Sales Order.
        SalesHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Modify(true);

        // [THEN] Sales Line is recreated. Purchasing Code = "P" and Drop Shipment = true for Sales Line. Drop Shipment value is saved after recreation.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Purchasing Code", Item."Purchasing Code");
        SalesLine.TestField("Drop Shipment");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesLineDropShipmentRemainsFalseOnRecreateSalesLinesWhenItemDropShipmentFalse()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 374832] Change "Bill-to Customer No." on Sales Order when Drop Shipment is not set for Sales Line and Item from Sales Line has Drop Shipment = false.
        Initialize();

        // [GIVEN] Purchasing Code "P" with Drop Shipment = false. Item with Purchasing Code "P". Sales Order that has Sales Line with Item.
        // [GIVEN] Drop Shipment value for Sales Line is false and it is taken from item's Purchasing Code "P".
        LibraryInventory.CreateItem(Item);
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(false, false));
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');
        SalesLine.TestField("Drop Shipment", false);

        // [WHEN] Change "Bill-to Customer No." for Sales Order.
        SalesHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Modify(true);

        // [THEN] Sales Line is recreated. Purchasing Code = "P" and Drop Shipment = false for Sales Line. Drop Shipment value is saved after recreation.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Purchasing Code", Item."Purchasing Code");
        SalesLine.TestField("Drop Shipment", false);
    end;

    [Test]
    [HandlerFunctions('SalesListModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesLineDropShptOnRecreateSalesLinesWhenItemDropShptTrueAndPurchaseOrderLinked()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 374832] Change "Bill-to Customer No." on Sales Order when Drop Shipment is set for Sales Line and Sales Order has linked Purchase Order for drop shipment.
        Initialize();

        // [GIVEN] Purchasing Code "P" with Drop Shipment = true. Item with Purchasing Code "P". Sales Order that has Sales Line with Item.
        // [GIVEN] Purchase Order that is prepared for drop shipment, it is linked to Sales Order.
        LibraryInventory.CreateItem(Item);
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');
        CreatePurchOrderWithSelltoCustomerNo(PurchaseHeader, LibraryPurchase.CreateVendorNo(), SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryPurchase.GetDropShipment(PurchaseHeader);
        Commit();

        // [WHEN] Change "Bill-to Customer No." for Sales Order.
        asserterror SalesHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());

        // [THEN] Sales Line is not recreated. Purchasing Code = "P" and Drop Shipment = true for Sales Line.
        Assert.ExpectedError('You cannot delete the order line because it is associated with purchase order');
        Assert.ExpectedErrorCode('Dialog');
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Purchasing Code", Item."Purchasing Code");
        SalesLine.TestField("Drop Shipment");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnPostingWhseShipmentWithNewPostingDateForSalesOrder()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        CurrencyCode: Code[10];
        InvDiscountPercent: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Sales] [Order] [Warehouse Shipment]
        // [SCENARIO 383047] Keep invoice discount when posting warehouse shipment with a new posting date for a sales order.
        Initialize();
        ExecuteUIHandlers();
        InvDiscountPercent := LibraryRandom.RandIntInRange(30, 70);

        // [GIVEN] Currency Code "ACY" with two different exchange rates on dates "D1" and "D2".
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(
            WorkDate(), LibraryRandom.RandDecInRange(51, 100, 2), LibraryRandom.RandDecInRange(51, 100, 2));
        LibraryERM.CreateExchangeRate(
          CurrencyCode, WorkDate() + 30, LibraryRandom.RandDec(50, 2), LibraryRandom.RandDec(50, 2));

        // [GIVEN] Location "L" with required shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create an item and update inventory on the location "L".
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", LibraryRandom.RandIntInRange(20, 40), Location.Code, 0);

        // [GIVEN] Create sales order with Posting Date = "D1".
        // [GIVEN] Set invoice discount = 30%, Currency Code = "ACY".
        CreateSalesDocumentWithCurrencyCodeAndInvoiceDiscount(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CurrencyCode, Location.Code, Item."No.", InvDiscountPercent);

        // [GIVEN] Release the sales order and create warehouse shipment.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Set posting date = "D2" on the warehouse shipment.
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindFirst();
        WarehouseShipmentHeader.Validate("Posting Date", WorkDate() + 30);
        WarehouseShipmentHeader.Modify(true);

        // [WHEN] Post the warehouse shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] The invoice discount on the sales line = 30%.
        SalesLine.Find();
        Assert.AreNearlyEqual(
          SalesLine."Line Amount" * (1 - InvDiscountPercent / 100), SalesLine."Inv. Discount Amount",
          LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode), '');
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnPostingWhseReceiptWithNewPostingDateForPurchaseOrder()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        CurrencyCode: Code[10];
        InvDiscountPercent: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Purchase] [Order] [Warehouse Receipt]
        // [SCENARIO 383047] Keep invoice discount when posting warehouse receipt with a new posting date for a purchase order.
        Initialize();
        ExecuteUIHandlers();
        InvDiscountPercent := LibraryRandom.RandIntInRange(30, 70);

        // [GIVEN] Currency Code "ACY" with two different exchange rates on dates "D1" and "D2".
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(
            WorkDate(), LibraryRandom.RandDecInRange(51, 100, 2), LibraryRandom.RandDecInRange(51, 100, 2));
        LibraryERM.CreateExchangeRate(
          CurrencyCode, WorkDate() + 30, LibraryRandom.RandDec(50, 2), LibraryRandom.RandDec(50, 2));

        // [GIVEN] Location "L" with required receipt.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create purchase order with Posting Date = "D1".
        // [GIVEN] Set invoice discount = 30%, Currency Code = "ACY".
        CreatePurchDocumentWithCurrencyCodeAndInvoiceDiscount(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, CurrencyCode, Location.Code, Item."No.", InvDiscountPercent);

        // [GIVEN] Release the purchase order and create warehouse receipt.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Set posting date = "D2" on the warehouse receipt.
        WarehouseReceiptHeader.SetRange("Location Code", Location.Code);
        WarehouseReceiptHeader.FindFirst();
        WarehouseReceiptHeader.Validate("Posting Date", WorkDate() + 30);
        WarehouseReceiptHeader.Modify(true);

        // [WHEN] Post the warehouse receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] The invoice discount on the purchase line = 30%.
        PurchaseLine.Find();
        Assert.AreNearlyEqual(
          PurchaseLine."Line Amount" * (1 - InvDiscountPercent / 100), PurchaseLine."Inv. Discount Amount",
          LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode), '');
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnPostingWhseShipmentWithNewPostingDateForPurchReturnOrder()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        CurrencyCode: Code[10];
        InvDiscountPercent: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Purchase] [Return Order] [Warehouse Shipment]
        // [SCENARIO 383047] Keep invoice discount when posting warehouse shipment with a new posting date for a purchase return order.
        Initialize();
        ExecuteUIHandlers();
        InvDiscountPercent := LibraryRandom.RandIntInRange(30, 70);

        // [GIVEN] Currency Code "ACY" with two different exchange rates on dates "D1" and "D2".
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(
            WorkDate(), LibraryRandom.RandDecInRange(51, 100, 2), LibraryRandom.RandDecInRange(51, 100, 2));
        LibraryERM.CreateExchangeRate(
          CurrencyCode, WorkDate() + 30, LibraryRandom.RandDec(50, 2), LibraryRandom.RandDec(50, 2));

        // [GIVEN] Location "L" with required shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create an item and update inventory on the location "L".
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", LibraryRandom.RandIntInRange(20, 40), Location.Code, 0);

        // [GIVEN] Create purchase return order with Posting Date = "D1".
        // [GIVEN] Set invoice discount = 30%, Currency Code = "ACY".
        CreatePurchDocumentWithCurrencyCodeAndInvoiceDiscount(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", CurrencyCode, Location.Code,
          Item."No.", InvDiscountPercent);

        // [GIVEN] Release the purchase return order and create warehouse shipment.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);

        // [GIVEN] Set posting date = "D2" on the warehouse shipment.
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindFirst();
        WarehouseShipmentHeader.Validate("Posting Date", WorkDate() + 30);
        WarehouseShipmentHeader.Modify(true);

        // [WHEN] Post the warehouse shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] The invoice discount on the purchase line = 30%.
        PurchaseLine.Find();
        Assert.AreNearlyEqual(
          PurchaseLine."Line Amount" * (1 - InvDiscountPercent / 100), PurchaseLine."Inv. Discount Amount",
          LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode), '');
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnPostingWhseReceiptWithNewPostingDateForSalesReturnOrder()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        CurrencyCode: Code[10];
        InvDiscountPercent: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Sales] [Return Order] [Warehouse Receipt]
        // [SCENARIO 383047] Keep invoice discount when posting warehouse receipt with a new posting date for a sales return order.
        Initialize();
        ExecuteUIHandlers();
        InvDiscountPercent := LibraryRandom.RandIntInRange(30, 70);

        // [GIVEN] Currency Code "ACY" with two different exchange rates on dates "D1" and "D2".
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(
            WorkDate(), LibraryRandom.RandDecInRange(51, 100, 2), LibraryRandom.RandDecInRange(51, 100, 2));
        LibraryERM.CreateExchangeRate(
          CurrencyCode, WorkDate() + 30, LibraryRandom.RandDec(50, 2), LibraryRandom.RandDec(50, 2));

        // [GIVEN] Location "L" with required receipt.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create an item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create sales return order with Posting Date = "D1".
        // [GIVEN] Set invoice discount = 30%, Currency Code = "ACY".
        CreateSalesDocumentWithCurrencyCodeAndInvoiceDiscount(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CurrencyCode, Location.Code,
          Item."No.", InvDiscountPercent);

        // [GIVEN] Release the sales return order and create warehouse receipt.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);

        // [GIVEN] Set posting date = "D2" on the warehouse receipt.
        WarehouseReceiptHeader.SetRange("Location Code", Location.Code);
        WarehouseReceiptHeader.FindFirst();
        WarehouseReceiptHeader.Validate("Posting Date", WorkDate() + 30);
        WarehouseReceiptHeader.Modify(true);

        // [WHEN] Post the warehouse receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] The invoice discount on the sales return line = 30%.
        SalesLine.Find();
        Assert.AreNearlyEqual(
          SalesLine."Line Amount" * (1 - InvDiscountPercent / 100), SalesLine."Inv. Discount Amount",
          LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode), '');
    end;

    [Test]
    procedure QtyToReceiveBaseRoundingInPurchOrderAfterPostingSeveralWhseReceipts()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Order] [Warehouse Receipt] [Rounding] [Item Unit of Measure]
        // [SCENARIO 396153] Correction of "Qty. to Receive (Base)" on purchase line because of rounding after posting several warehouse receipts.
        Initialize();

        // [GIVEN] Set "Default Qty. to Receive" = "Blank" in purchase setup.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Qty. to Receive", PurchasesPayablesSetup."Default Qty. to Receive"::Blank);
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Location "L" that requires receipt.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Item with base unit of measure = "KG" and alternate unit of measure "BUCKET" = 5.55555 "KG".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 5.55555);
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Purchase order at location "L" for 1 "BUCKET" = 5.55555 "KG".
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", 1, Location.Code, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create warehouse receipt.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Receive 0.3 "BUCKET" = 1.66667 "KG", then another 0.3 "BUCKET".
        // [GIVEN] That leaves 0.4 "BUCKET" and 2.22221 "KG".
        PostWhseReceiptForPurchaseOrder(PurchaseHeader."No.", 0.3);
        PostWhseReceiptForPurchaseOrder(PurchaseHeader."No.", 0.3);

        // [WHEN] Post remaining 0.4 "BUCKET", which is precisely 2.22222 "KG", but there is only 2.22221 "KG" remaining.
        PostWhseReceiptForPurchaseOrder(PurchaseHeader."No.", 0.4);

        // [THEN] The purchase order is fully received (1 "BUCKET" or 5.55555 "KG")
        PurchaseLine.Find();
        PurchaseLine.TestField("Quantity Received", PurchaseLine.Quantity);
        PurchaseLine.TestField("Qty. Received (Base)", PurchaseLine."Quantity (Base)");
    end;

    [Test]
    procedure QtyBaseRoundingInPurchInvoiceViaGetReceiptLines()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        // [FEATURE] [Purchase] [Order] [Invoice] [Rounding] [Item Unit of Measure] [Get Receipt Lines]
        // [SCENARIO 396153] Rounding in purchase invoice created via "Get Receipt Lines".
        Initialize();

        // [GIVEN] Item with base unit of measure = "KG" and alternate unit of measure "BUCKET" = 5.55555 "KG".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 5.55555);
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Purchase order for 1 "BUCKET" = 5.55555 "KG".
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", 1, '', WorkDate());

        // [GIVEN] Receive the purchase in three iterations - 0.3, 0.3 and 0.4 "BUCKET".
        PostReceiptForPurchaseOrder(PurchaseHeader, PurchaseLine, 0.3);
        PostReceiptForPurchaseOrder(PurchaseHeader, PurchaseLine, 0.3);
        PostReceiptForPurchaseOrder(PurchaseHeader, PurchaseLine, 0.4);

        // [GIVEN] Create purchase invoice via "Get Receipt Lines".
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [WHEN] Post the purchase invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        // [THEN] The purchase invoice is completely posted.
        PurchaseLine.Find();
        PurchaseLine.TestField("Quantity Invoiced", PurchaseLine.Quantity);
        PurchaseLine.TestField("Qty. Invoiced (Base)", PurchaseLine."Quantity (Base)");
    end;

    [Test]
    procedure QtyToShipBaseRoundingInSalesOrderAfterPostingSeveralWhseShipments()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Order] [Warehouse Shipment] [Rounding] [Item Unit of Measure]
        // [SCENARIO 396153] Correction of "Qty. to Ship (Base)" on sales line because of rounding after posting several warehouse shipments.
        Initialize();

        // [GIVEN] Set "Default Quantity to Ship" = "Blank" in sales setup.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Quantity to Ship", SalesReceivablesSetup."Default Quantity to Ship"::Blank);
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Location "L" that requires shipment.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Item with base unit of measure = "KG" and alternate unit of measure "BUCKET" = 5.55555 "KG".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 5.55555);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Sales order at location "L" for 1 "BUCKET" = 5.55555 "KG".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 1, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create warehouse shipment.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Ship 0.3 "BUCKET" = 1.66667 "KG", then another 0.3 "BUCKET".
        // [GIVEN] That leaves 0.4 "BUCKET" and 2.22221 "KG".
        PostWhseShipmentForSalesOrder(SalesHeader."No.", 0.3);
        PostWhseShipmentForSalesOrder(SalesHeader."No.", 0.3);

        // [WHEN] Post remaining 0.4 "BUCKET", which is precisely 2.22222 "KG", but there is only 2.22221 "KG" remaining.
        PostWhseShipmentForSalesOrder(SalesHeader."No.", 0.4);

        // [THEN] The sales order is fully shipped (1 "BUCKET" or 5.55555 "KG")
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
        SalesLine.TestField("Qty. Shipped (Base)", SalesLine."Quantity (Base)");
    end;

    [Test]
    procedure QtyBaseRoundingInSalesInvoiceViaGetShipmentLines()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderInvoice: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        // [FEATURE] [Sales] [Order] [Invoice] [Rounding] [Item Unit of Measure] [Get Shipment Lines]
        // [SCENARIO 396153] Rounding in sales invoice created via "Get Shipment Lines".
        Initialize();

        // [GIVEN] Item with base unit of measure = "KG" and alternate unit of measure "BUCKET" = 5.55555 "KG".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 5.55555);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Sales order for 1 "BUCKET" = 5.55555 "KG".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 1, '', WorkDate());

        // [GIVEN] Ship the sales order in three iterations - 0.3, 0.3 and 0.4 "BUCKET".
        PostShipmentForSalesOrder(SalesHeader, SalesLine, 0.3);
        PostShipmentForSalesOrder(SalesHeader, SalesLine, 0.3);
        PostShipmentForSalesOrder(SalesHeader, SalesLine, 0.4);

        // [GIVEN] Create sales invoice via "Get Shipment Lines".
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);

        // [WHEN] Post the sales invoice.
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [THEN] The sales invoice is completely posted.
        SalesLine.Find();
        SalesLine.TestField("Quantity Invoiced", SalesLine.Quantity);
        SalesLine.TestField("Qty. Invoiced (Base)", SalesLine."Quantity (Base)");
    end;

    [Test]
    procedure BinCodeInSalesInvoiceViaGetShipmentLines()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        WarehouseEmployee: Record "Warehouse Employee";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesHeaderInvoice: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        BinCode1: Code[20];
        BinCode2: Code[20];
    begin
        // [FEATURE] [Sales] [Order] [Invoice] [Bin Code] [Get Shipment Lines]
        // [SCENARIO 573407] BinCode in sales invoice created via "Get Shipment Lines".
        Initialize();

        // [GIVEN] Item and location with required receive and ship and with Bin mandatory.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, true, true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        BinCode1 := Bin.Code;
        Bin.FindLast();
        BinCode2 := Bin.Code;
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Item on stock in the location "L" with Bin Code "B1" and B2.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, BinCode1, LibraryRandom.RandInt(10) + 10);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, BinCode2, LibraryRandom.RandInt(10) + 10);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order for Item and created Warehouse Shipment.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());
        SalesLine.TestField("Bin Code", BinCode1);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Update warehouse shipment line Bin Code from "B1" to "B2".
        WarehouseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        WarehouseShipmentLine.SetRange("Item No.", Item."No.");
        WarehouseShipmentLine.SetRange("Location Code", Location.Code);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField("Bin Code", BinCode1);
        WarehouseShipmentLine.Validate("Bin Code", BinCode2);
        WarehouseShipmentLine.Modify(true);

        // [GIVEN] Post the warehouse shipment.
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [WHEN] Create sales invoice via "Get Shipment Lines".
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);

        // [THEN] The sales invoice is created with Bin Code "B2".
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeaderInvoice."Document Type");
        SalesLine.SetRange("Document No.", SalesHeaderInvoice."No.");
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Bin Code", BinCode2);

        // [THEN] Post the sales invoice.
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);
    end;

    [Test]
    procedure CannotCarryOutPlanningForDropShipWithLocationMandatory()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment] [Location Mandatory]
        // [SCENARIO 397813] Purchase order for drop shipment at blank location cannot be created via requisition worksheet when "Location Mandatory" is on.
        Initialize();

        // [GIVEN] "Location Mandatory" is set to TRUE.
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Sales Order with drop shipment and blank Location Code.
        CreateItemWithVendorNo(Item);
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', Item."No.", LibraryRandom.RandInt(10), '');
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);

        // [GIVEN] Open requisition worksheet, get sales orders for drop shipment.
        // [WHEN] Try to carry out action message.
        asserterror GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(SalesLine);

        // [THEN] Error is thrown indicating the Location Code is missing on the Requisition Line.
        Assert.ExpectedError(MissingMandatoryLocationTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksCertifyProdBOM()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        CreateMandatoryVariant(Item, ItemVariant);

        // [GIVEN] Production BOM with given item on line
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1.0);
        Commit();

        // [WHEN] User tries to change status to "Certified"
        asserterror LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [THEN] Error is thrown indicating the Variant Code is missing
        Assert.ExpectedError(ProductionBOMLine.FieldCaption(ProductionBOMLine."Variant Code"));

        ProductionBOMHeader.Get(ProductionBOMHeader."No.");

        // [GIVEN] Variant is specified
        ProductionBOMLine.Validate("Variant Code", ItemVariant.Code);
        ProductionBOMLine.Modify();

        // [WHEN] User tries to change status to "Certified"
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksReleasingSO()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        CreateMandatoryVariant(Item, ItemVariant);

        // [GIVEN] Sales Order with specified item and NO variant chosen
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', Item."No.", 1, '');
        Commit();

        // [WHEN] User tries to release sales document
        asserterror LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] Error is thrown indicating the Variant Code is missing on the sales line.
        Assert.ExpectedError(SalesLine.FieldCaption(SalesLine."Variant Code"));

        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");

        // [GIVEN] Variant is specified
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify();

        // [WHEN] User tries to release document
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksPostingSO()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        CreateMandatoryVariant(Item, ItemVariant);

        // [GIVEN] Sales Order with specified item and NO variant chosen
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', Item."No.", 1, '');
        // Commit to avoid rollback deleting the created order
        Commit();

        // [WHEN] User tries to post sales document
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Error is thrown indicating the Variant Code is missing on the sales line.
        Assert.ExpectedError(SalesLine.FieldCaption(SalesLine."Variant Code"));

        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");

        // [GIVEN] Variant is specified
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify();

        // [WHEN] User tries to post document
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksReleasingPO()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchhaseLine: Record "Purchase Line";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        CreateMandatoryVariant(Item, ItemVariant);

        // [GIVEN] Purchase Order with specified item and NO variant chosen
        CreatePurchaseOrder(PurchaseHeader, PurchhaseLine, PurchhaseLine.Type::Item, '', Item."No.", 1);
        Commit();

        // [WHEN] User tries to release document
        asserterror LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] Error is thrown indicating the Variant Code is missing on the purchase line.
        Assert.ExpectedError(PurchhaseLine.FieldCaption(PurchhaseLine."Variant Code"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Variant is specified
        PurchhaseLine.Validate("Variant Code", ItemVariant.Code);
        PurchhaseLine.Modify();

        // [WHEN] User tries to release document
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksPostingPO()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchhaseLine: Record "Purchase Line";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        CreateMandatoryVariant(Item, ItemVariant);

        // [GIVEN] Purchase Order with specified item and NO variant chosen
        CreatePurchaseOrder(PurchaseHeader, PurchhaseLine, PurchhaseLine.Type::Item, '', Item."No.", 1);
        // Commit to avoid rollback deleting the created order
        Commit();

        // [WHEN] User tries to post document
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Error is thrown indicating the Variant Code is missing on the purchase line.
        Assert.ExpectedError(PurchhaseLine.FieldCaption(PurchhaseLine."Variant Code"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Variant is specified
        PurchhaseLine.Validate("Variant Code", ItemVariant.Code);
        PurchhaseLine.Modify();

        // [WHEN] User tries to post document
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksServiceOrder()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record "Customer";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        CreateMandatoryVariant(Item, ItemVariant);

        // [GIVEN] Order with specified item and NO variant chosen
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, "Service Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Modify();
        Commit();

        // [WHEN] User tries to post document
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Error is thrown indicating the Variant Code is missing on the line.
        Assert.ExpectedError(ServiceLine.FieldCaption(ServiceLine."Variant Code"));

        // [GIVEN] A variant is chosen before the order is posted
        ServiceLine.Validate("Variant Code", ItemVariant.Code);
        ServiceLine.Modify();

        // [WHEN] User tries to post document
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksAssemblyOrder()
    var
        ParentItem: Record Item;
        ParentItemVariant: Record "Item Variant";
        ChildItem: Record Item;
        ChildItemVariant: Record "Item Variant";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Two items with available variants and Item."Variant Mandatory if Exists" = Yes
        InitVariantMandatoryAssemblyTestVariables(ChildItem, ParentItem, ChildItemVariant, ParentItemVariant);

        // [GIVEN] Line (ChildItem) has no variant chosen and header (ParentItem) has variant chosen
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, AddDays(WorkDate(), 10), ParentItem."No.", '', 1, '');

        AssemblyHeader.Validate("Variant Code", ParentItemVariant.Code);
        AssemblyHeader.Modify();

        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ChildItem."No.", ChildItem."Base Unit of Measure", 1, 1, '');
        AssemblyLine.Validate("Variant Code", '');
        AssemblyLine.Modify();

        // [WHEN] Assembly header is posted
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, AssemblyLine.FieldCaption(AssemblyLine."Variant Code"));
        // [THEN] Error is thrown on post indicating that the child Variant Code is missing on the line. (PostAssemblyHeader asserts error)

        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");

        // [GIVEN] Line (ChildItem) has variant is set, but header (ParentItem) hasn't
        AssemblyLine.Validate("Variant Code", ChildItemVariant.Code);
        AssemblyLine.Modify();

        AssemblyHeader.Validate("Variant Code", '');
        AssemblyHeader.Modify();
        Commit();

        // [WHEN] Header is posted
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, AssemblyHeader.FieldCaption(AssemblyHeader."Variant Code"));
        // [THEN] Error is thrown indicating the parent Variant Code is missing on the header. (PostAssemblyHeader asserts error)

        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");

        // [GIVEN] Child variant and parent variant are both set
        AssemblyHeader.Validate("Variant Code", ParentItemVariant.Code);
        AssemblyHeader.Modify();

        // [WHEN] Header is posted
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksInvtDocument()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        InvtDocHeader: Record "Invt. Document Header";
        InvtDocLine: Record "Invt. Document Line";
        Location: Record Location;
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        CreateMandatoryVariant(Item, ItemVariant);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Inventory Document with specified item and NO variant chosen
        LibraryInventory.CreateInvtDocument(InvtDocHeader, InvtDocHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(InvtDocHeader, InvtDocLine, Item."No.", 1, 1);
        Commit();

        // [WHEN] User tries to post inventory document
        asserterror LibraryInventory.PostInvtDocument(InvtDocHeader);

        // [THEN] Error is thrown indicating the Variant Code is missing
        Assert.ExpectedError(InvtDocLine.FieldCaption(InvtDocLine."Variant Code"));

        // [GIVEN] Variant is specified
        InvtDocHeader.Get(InvtDocHeader."Document Type", InvtDocHeader."No.");
        InvtDocLine.Validate("Variant Code", ItemVariant.Code);
        InvtDocLine.Modify();

        // [WHEN] Header is posted
        LibraryInventory.PostInvtDocument(InvtDocHeader);

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksItemJnlLine()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        CreateMandatoryVariant(Item, ItemVariant);

        // [GIVEN] Item Jnl line with specified item and NO variant chosen
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::Sale, Item."No.", 100);
        Commit();

        // [WHEN] User tries to post item journal batch
        asserterror LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [THEN] Error is thrown indicating the Variant Code is missing
        Assert.ExpectedError(ItemJournalLine.FieldCaption(ItemJournalLine."Variant Code"));

        // [GIVEN] Variant is specified
        ItemJournalLine.Validate("Variant Code", ItemVariant.Code);
        ItemJournalLine.Modify();

        // [WHEN] Batch is posted
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksOrderPromisingLine()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderPromisingLine: Record "Order Promising Line";
        AvailabilityManagement: Codeunit AvailabilityManagement;
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        CreateMandatoryVariant(Item, ItemVariant);

        // [GIVEN] Sales order
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', Item."No.", 1, '');
        Commit();

        // [WHEN] Lines on Order promising lines page is set (triggered by SetSalesHeader)
        asserterror AvailabilityManagement.SetSourceRecord(OrderPromisingLine, SalesHeader);

        // [THEN] Error is thrown indicating the Variant Code is missing
        Assert.ExpectedError(OrderPromisingLine.FieldCaption(OrderPromisingLine."Variant Code"));

        // [GIVEN] Variant is specified
        SalesLine.Validate("Variant Code", ItemVariant.Code); // Variant is set on SalesLine and transferred to OrderPromisingLine
        SalesLine.Modify();

        // [WHEN] Lines on Order promising lines page is set (triggered by SetSalesHeader)
        AvailabilityManagement.SetSourceRecord(OrderPromisingLine, SalesHeader);

        // [THEN] No error is thrown
    end;

    [Test]
    [HandlerFunctions('EmptyMessageHandler')]
    procedure InventoryPutawayCreatedBothForPurchaseLinesWithJobAndWithoutJob()
    var
        Location: Record Location;
        JobTask: Record "Job Task";
        Item: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Purchase] [Order] [Put-away] [Job]
        // [SCENARIO 408137] [545709] Inventory put-away is created for purchase lines regardless of link to Job.
        Initialize();

        // [GIVEN] Location "L" with required put-away.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Job with job task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Purchase order at location "L".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);

        // [GIVEN] First purchase line is linked to the job.
        // [GIVEN] Second purchase line is not.
        LibraryInventory.CreateItem(Item[1]);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item[1]."No.", LibraryRandom.RandInt(10));
        UpdateJobNoAndJobTaskNoOnPurchaseLine(PurchaseLine, JobTask);

        LibraryInventory.CreateItem(Item[2]);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item[2]."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Release the purchase order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Create inventory put-away.
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        // [THEN] Put-away contains both the first line (with Job) and the second purchase line
        WarehouseActivityLine.SetRange("Item No.", Item[1]."No.");
        Assert.RecordIsNotEmpty(WarehouseActivityLine);

        WarehouseActivityLine.SetRange("Item No.", Item[2]."No.");
        Assert.RecordIsNotEmpty(WarehouseActivityLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S461213_PostAssemblyOrderWithOutputItemVariantAndResourceConsumption()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ParentItem: Record Item;
        ParentItemVariant: Record "Item Variant";
        ChildItem: Record Item;
        ChildResource: Record Resource;
        ItemJournalLine: Record "Item Journal Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: array[2] of Record "Assembly Line";
    begin
        // [FEATURE] [Assembly Order] [Item Variant] [Resource]
        // [SCENARIO 461213] Assembly Order can be posted with Output Item Variant in Header. Child Item and Resource are consumed.
        Initialize();

        // [GIVEN] Create "Unit of Measure"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create "Parent Item" and "Parent Item Variant" with "Variant Mandatory if Exists" = true
        CreateMandatoryVariant(ParentItem, ParentItemVariant);
        ParentItem.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        ParentItem.Modify();

        // [GIVEN] Create "Child Item"
        LibraryAssembly.SetupAssemblyItem(ChildItem, ChildItem."Costing Method"::Standard, ChildItem."Costing Method"::Standard, ChildItem."Replenishment System"::Assembly, '', false, 5, 5, 5, 5);
        ChildItem.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        ChildItem.Modify();

        // [GIVEN] Put "Child Item" on Inventory
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, '', ItemJournalLine."Entry Type"::"Positive Adjmt.", ChildItem."No.", 10);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create "Child Resource"
        LibraryResource.CreateResourceNew(ChildResource);

        // [GIVEN] Create Assembly Order Header for "Parent Item" and "Parent Item Variant"
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, AddDays(WorkDate(), 10), ParentItem."No.", '', 1, '');
        AssemblyHeader.Validate("Variant Code", ParentItemVariant.Code);
        AssemblyHeader.Modify();

        // [GIVEN] Create Assembly Order Line for "Child Item"
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine[1], "BOM Component Type"::Item, ChildItem."No.", ChildItem."Base Unit of Measure", 1, 1, '');

        // [GIVEN] Create Assembly Order Line for "Child Resource"
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine[2], "BOM Component Type"::Resource, ChildResource."No.", ChildResource."Base Unit of Measure", 1, 1, '');

        // [WHEN] Assembly Order is posted
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] No error is thrown
    end;

    [Test]
    procedure WarehouseRequestDeletedBeforeOrderOnPosting()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseRequest: Record "Warehouse Request";
        SCMOrdersVI: Codeunit "SCM Orders VI";
    begin
        // [FEATURE] [Warehouse Request] [Inventory Pick]
        // [SCENARIO 474505] Warehouse Request is deleted before order during posting.
        Initialize();

        // [GIVEN] Location "L" with required pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Sales order at location "L".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        // [GIVEN] Release the sales order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Check that warehouse request is created.
        WarehouseRequest.SetSourceFilter(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        WarehouseRequest.FindFirst();

        // [WHEN] Ship and invoice the sales order.
        BindSubscription(SCMOrdersVI);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Warehouse request is deleted by the moment the posting engine comes to deletion of the sales order.
        // [THEN] The verification is done in the event subscriber CheckWarehouseRequestDeletedBeforeSalesOrder.
        UnbindSubscription(SCMOrdersVI);

        // [THEN] Finally, the order is also deleted.
        Assert.IsFalse(SalesHeader.Find(), '');
    end;

    [Test]
    procedure ValueEntryTypeBlankOnPostingPurchase()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
    begin
        // [SCENARIO 556628] Field "Type" in Value Entry for purchase is blank on posting.
        Initialize();

        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, '', LibraryInventory.CreateItemNo(), 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        ValueEntry.SetRange("Item No.", PurchaseLine."No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField(Type, ValueEntry.Type::" ");
    end;

    [Test]
    procedure ValueEntryTypeBlankOnPostingSales()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
    begin
        // [SCENARIO 556628] Field "Type" in Value Entry for sales is blank on posting.
        Initialize();

        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, SalesLine.Type::Item, '', LibraryInventory.CreateItemNo(), 1, '');
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ValueEntry.SetRange("Item No.", SalesLine."No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField(Type, ValueEntry.Type::" ");
    end;

    [Test]
    procedure InsertingSalesLineBeforeSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 593432] It is possible to insert Sales Line before Sales Header if SalesHeader variable is initialized in the Sales Line table.
        Initialize();

        // Sales Header is initialized but not inserted.
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateGUID();

        // Initialize Sales Line with the Sales Header passed as parameter.
        SalesLine.Init();
        SalesLine.SetSalesHeader(SalesHeader);
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));

        // The Sales Line can be inserted.
        SalesLine.Insert(true);

        // Initialize another Sales Line, do not invoke SetSalesHeader.
        Clear(SalesLine);
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));

        // The Sales Line cannot be inserted, because Sales Header is not inserted yet.
        Commit();
        asserterror SalesLine.Insert(true);

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(CannotInsertSalesLineWithoutHeaderErr);

        // After inserting the Sales Header, the Sales Line can be inserted.
        SalesHeader.Insert();
        SalesLine.Insert(true);
    end;

    [Test]
    procedure InsertingPurchaseLineBeforePurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 593432] It is possible to insert Purchase Line before Purchase Header if PurchaseHeader variable is initialized in the Purchase Line table.
        Initialize();

        // Purchase Header is initialized but not inserted.
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUtility.GenerateGUID();

        // Initialize Purchase Line with the Purchase Header passed as parameter.
        PurchaseLine.Init();
        PurchaseLine.SetPurchHeader(PurchaseHeader);
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LibraryUtility.GetNewRecNo(PurchaseLine, PurchaseLine.FieldNo("Line No."));

        // The Purchase Line can be inserted.
        PurchaseLine.Insert(true);

        // Initialize another Purchase Line, do not invoke SetPurchHeader.
        Clear(PurchaseLine);
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := LibraryUtility.GetNewRecNo(PurchaseLine, PurchaseLine.FieldNo("Line No."));

        // The Purchase Line cannot be inserted, because Purchase Header is not inserted yet.
        Commit();
        asserterror PurchaseLine.Insert(true);

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(CannotInsertPurchLineWithoutHeaderErr);

        // After inserting the Purchase Header, the Purchase Line can be inserted.
        PurchaseHeader.Insert();
        PurchaseLine.Insert(true);
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandlerSetVendorsOnLine')]
    procedure PurchaseOrderMustBeCreatedFromDropShipmentSalesOrder()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 386698] Verify that purchase order is created from sales order when "Create Purchase Order" action is invoked.
        Initialize();

        // [GIVEN] Create Item and Vendor.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Enqueue "Vendor No.".
        LibraryVariableStorage.Enqueue(Vendor."No.");

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [GIVEN] Open Sales Order page.
        PurchaseOrder.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);

        // [WHEN] Create Purchase Order from Sales Order.
        SalesOrder.CreatePurchaseOrder.Invoke();

        // [THEN] Verify that Purchase Order is created.
        PurchaseOrder."Sell-to Customer No.".AssertEquals(SalesHeader."Sell-to Customer No.");

        // [WHEN] Find the Purchase Order created from Sales Order.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseOrder."No.".Value);
        PurchaseHeader.FindFirst();

        // [THEN] Verify that Purchase Line is created.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader."No.", SalesLine);
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandler')]
    procedure PurchaseOrderMustBeCreatedFromDropShipmentSalesOrderWithMultipleLines()
    var
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 386698] Verify that purchase order is created from drop shipment sales order when "Create Purchase Order" action is invoked with muliple lines.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item[1]);

        // [GIVEN] Create another item with the same Vendor No.
        CreateItemWithVendorNo(Item[2]);
        Item[2].Validate("Vendor No.", Item[1]."Vendor No.");
        Item[2].Modify(true);

        // [GIVEN] Sales Order with drop shipment.
        CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), Item[1]."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Create another sales line with the another item.
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type, Item[2]."No.", LibraryRandom.RandInt(10), '');
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(true, false));  // Drop Shipment as TRUE.
        SalesLine.Modify(true);

        // [GIVEN] Find Sales Line for Sales Header.
        FindSalesLine(SalesLine, SalesHeader);

        // [GIVEN] Open Sales Order page.
        PurchaseOrder.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);

        // [WHEN] Create Purchase Order from Sales Order.
        SalesOrder.CreatePurchaseOrder.Invoke();

        // [THEN] Verify that Purchase Order is created.
        PurchaseOrder."Sell-to Customer No.".AssertEquals(SalesHeader."Sell-to Customer No.");

        // [WHEN] Find the Purchase Order created from Sales Order.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseOrder."No.".Value);
        PurchaseHeader.FindFirst();

        // [THEN] Verify that Purchase Line is created.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader."No.", SalesLine);
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandler')]
    procedure MultiplePurchaseOrderMustBeCreatedFromDropShipmentSalesOrderWithMultipleLinesForDifferentVendor()
    var
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO 386698] Verify that purchase order is created from drop shipment sales order when "Create Purchase Order" action is invoked with muliple lines and different vendor.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item[1]);

        // [GIVEN] Create another item with the different Vendor No.
        CreateItemWithVendorNo(Item[2]);

        // [GIVEN] Sales Order with drop shipment.
        CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), Item[1]."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Create another sales line with the another item.
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type, Item[2]."No.", LibraryRandom.RandInt(10), '');
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(true, false));  // Drop Shipment as TRUE.
        SalesLine.Modify(true);

        // [GIVEN] Find Sales Line for Sales Header.
        FindSalesLine(SalesLine, SalesHeader);

        // [GIVEN] Open Sales Order page.
        PurchaseOrderList.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);

        // [WHEN] Create Purchase Order from Sales Order.
        SalesOrder.CreatePurchaseOrder.Invoke();

        // [THEN] Find the Purchase Order created from sales order.
        FindPurchaseHeader(PurchaseHeader[1], Item[1]."Vendor No.");
        FindPurchaseHeader(PurchaseHeader[2], Item[2]."Vendor No.");

        // [THEN] Verify that Purchase Line is created.
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseOrderList.Filter.GetFilter("No."), SalesLine);

        // [GIVEN] Update "Vendor Invoice No." on a first Purchase Order.
        PurchaseHeader[1].Validate("Your Reference", LibraryUtility.GenerateGUID());
        PurchaseHeader[1].Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader[1].Modify(true);

        // [GIVEN] Update "Vendor Invoice No." on a second Purchase Order.
        PurchaseHeader[2].Validate("Your Reference", LibraryUtility.GenerateGUID());
        PurchaseHeader[2].Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader[2].Modify(true);

        // [GIVEN] Post Sales Document with shipment and invoice.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // [WHEN] Post Purchase Document with invoice.
        PostPurchaseDocument(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No.", false, true);
        PostPurchaseDocument(PurchaseHeader[2]."Document Type", PurchaseHeader[2]."No.", false, true);

        // [THEN] Verify that the Posted Purchase Invoice and Posted Sales Invoice has been created.
        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader[1]."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader[2]."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandlerSetVendorsOnLine,MessageHandler')]
    procedure PurchaseOrderMustNotBeCreatedFromDropShipmentSalesOrderMoreThanOnce()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 386698] Verify that purchase order is not created from drop shipment sales order more than once.
        Initialize();

        // [GIVEN] Create Item and Vendor.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Enqueue "Vendor No.".
        LibraryVariableStorage.Enqueue(Vendor."No.");

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [GIVEN] Open Sales Order page.
        PurchaseOrder.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);

        // [WHEN] Create Purchase Order from Sales Order.
        SalesOrder.CreatePurchaseOrder.Invoke();

        // [THEN] Verify that Purchase Order is created.
        PurchaseOrder."Sell-to Customer No.".AssertEquals(SalesHeader."Sell-to Customer No.");

        // [GIVEN] Enqueue "Vendor No." and expected messages.
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(CannotCreatePurchaseOrderIsAlreadyWithSalesOrderErr, SalesLine."No.", SalesLine."Document No.", SalesLine."Purchase Order No."));

        // [WHEN] Create Purchase Order from Sales Order more than once.
        FindSalesLine(SalesLine, SalesHeader);
        asserterror SalesOrder.CreatePurchaseOrder.Invoke();

        // [THEN] Verify that purchase order is not created from drop shipment sales order more than once through Handler.
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandlerSetVendorsOnLine')]
    procedure PurchaseInvoiceMustBePostedWithDropShipmentWitPostingOfSalesInvoice()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 386698] Verify that purchase order is created from drop shipment sales order when "Create Purchase Order" action is invoked and purchase invoice is posted with posting of sales invoice.
        Initialize();

        // [GIVEN] Create Item and Vendor.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Enqueue "Vendor No".
        LibraryVariableStorage.Enqueue(Vendor."No.");

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [GIVEN] Open Sales Order page.
        PurchaseOrder.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);

        // [WHEN] Create Purchase Order from Sales Order.
        SalesOrder.CreatePurchaseOrder.Invoke();

        // [THEN] Verify that Purchase Order is created.
        PurchaseOrder."Sell-to Customer No.".AssertEquals(SalesHeader."Sell-to Customer No.");

        // [GIVEN] Find the Purchase Order created from Sales Order.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseOrder."No.".Value);
        PurchaseHeader.FindFirst();

        // [GIVEN] Update "Vendor Invoice No." on Purchase Header.
        PurchaseHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // [GIVEN] Post Sales Document with shipment and invoice.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // [WHEN] Post Purchase Document with invoice.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // [THEN] Verify that the Posted Purchase Invoice and Posted Sales Invoice has been created.
        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderModalPageHandlerSetVendorsOnLine,MessageHandler')]
    procedure PurchaseOrderMustNotBeCreatedFromDropShipmentSalesOrderSubformWhenVendorIsNotSelected()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 386698] Verify that purchase order is not created from drop shipment sales order When Vendor is not selected.
        Initialize();

        // [GIVEN] Create Item and Vendor.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Enqueue "Vendor No.".
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(CannotCreatePurchaseOrderWithoutVendorErr);

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [GIVEN] Open Sales Order page.
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);

        // [WHEN] Create Purchase Order from Sales Order.
        SalesOrder.CreatePurchaseOrder.Invoke();

        // [THEN] Verify that Purchase Order is not created.
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    [Test]
    procedure PurchaseOrderMustBeCreatedFromDropShipmentPlanningWorksheet()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 386698] Verify that purchase order is created from planning worksheet.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item);

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [WHEN] Create Requisition Line and Carry out action message.
        GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(SalesLine);

        // [THEN] Find the Purchase Order created from planning worksheet.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.FindFirst();

        // [THEN] Verify that Purchase Line is created.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader."No.", SalesLine);
    end;

    [Test]
    procedure PurchaseOrderMustBeCreatedFromDropShipmentPlanningWorksheetWithMultipleLines()
    var
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasingCode: Code[20];
    begin
        // [SCENARIO 386698] Verify that purchase order is created from drop shipment planning worksheet when "Get Sales Orders" action is invoked with muliple lines.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item[1]);

        // [GIVEN] Create another item with the same Vendor No.
        CreateItemWithVendorNo(Item[2]);
        Item[2].Validate("Vendor No.", Item[1]."Vendor No.");
        Item[2].Modify(true);

        // [GIVEN] Sales Order with drop shipment.
        CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), Item[1]."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Save Purchasing Code of first line.
        PurchasingCode := SalesLine."Purchasing Code";

        // [GIVEN] Create another sales line with the another item.
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type, Item[2]."No.", LibraryRandom.RandInt(10), '');
        SalesLine.Validate("Purchasing Code", PurchasingCode);  // Drop Shipment as TRUE.
        SalesLine.Modify(true);

        // [GIVEN] Find Sales Line for Sales Header.
        FindSalesLine(SalesLine, SalesHeader);

        // [WHEN] Create Requisition Line and Carry out action message.
        GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(SalesLine);

        // [THEN] Find the Purchase Order created from planning worksheet.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.FindFirst();

        // [THEN] Verify that Purchase Line is created.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader."No.", SalesLine);
    end;

    [Test]
    procedure MultiplePurchaseOrderMustBeCreatedFromDropShipmentPlanningWorksheetWithMultipleLinesForDifferentVendor()
    var
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchasingCode: Code[20];
    begin
        // [SCENARIO 386698] Verify that purchase order is created from drop shipment planning worksheet when "Get Sales Orders" action is invoked with muliple lines and different vendor.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item[1]);

        // [GIVEN] Create another item with the different Vendor No.
        CreateItemWithVendorNo(Item[2]);

        // [GIVEN] Sales Order with drop shipment.
        CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), Item[1]."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Save Purchasing Code of first line.
        PurchasingCode := SalesLine."Purchasing Code";

        // [GIVEN] Create another sales line with the another item.
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type, Item[2]."No.", LibraryRandom.RandInt(10), '');
        SalesLine.Validate("Purchasing Code", PurchasingCode);  // Drop Shipment as TRUE.
        SalesLine.Modify(true);

        // [GIVEN] Find Sales Line for Sales Header.
        FindSalesLine(SalesLine, SalesHeader);

        // [WHEN] Create Requisition Line and Carry out action message.
        GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(SalesLine);

        // [THEN] Find the Purchase Order created from planning worksheet.
        FindPurchaseHeader(PurchaseHeader[1], Item[1]."Vendor No.");
        FindPurchaseHeader(PurchaseHeader[2], Item[2]."Vendor No.");

        // [THEN] Verify that Purchase Line is created.
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", SalesLine);

        // [GIVEN] Update "Vendor Invoice No." on a first Purchase Order.
        PurchaseHeader[1].Validate("Your Reference", LibraryUtility.GenerateGUID());
        PurchaseHeader[1].Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader[1].Modify(true);

        // [GIVEN] Update "Vendor Invoice No." on a second Purchase Order.
        PurchaseHeader[2].Validate("Your Reference", LibraryUtility.GenerateGUID());
        PurchaseHeader[2].Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader[2].Modify(true);

        // [GIVEN] Post Sales Document with shipment and invoice.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // [WHEN] Post Purchase Document with invoice.
        PostPurchaseDocument(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No.", false, true);
        PostPurchaseDocument(PurchaseHeader[2]."Document Type", PurchaseHeader[2]."No.", false, true);

        // [THEN] Verify that the Posted Purchase Invoice and Posted Sales Invoice has been created.
        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader[1]."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader[2]."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);
    end;

    [Test]
    procedure PurchaseOrderMustNotBeCreatedFromDropShipmentPlanningWorksheetMoreThanOnce()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 386698] Verify that purchase order is not created from drop shipment planning worksheet more than once.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item);

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [WHEN] Create Requisition Line and Carry out action message.
        GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(SalesLine);

        // [THEN] Find the Purchase Order created from planning worksheet.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.FindFirst();

        // [THEN] Verify that Purchase Line is created.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader."No.", SalesLine);

        // [WHEN] Create Requisition Line and Carry out action message.
        FindSalesLine(SalesLine, SalesHeader);
        asserterror GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(SalesLine);

        // [THEN] Verify that purchase order is not created from drop shipment planning worksheet more than once.
        Assert.ExpectedError(NoSalesLineToRetrieveErr);
    end;

    [Test]
    procedure PurchaseInvoiceMustBePostedWithDropShipmentPlanningWorksheetWitPostingOfSalesInvoice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO 386698] Verify that purchase order is created from drop shipment planning worksheet when "Get Sales Order" action is invoked and purchase invoice is posted with posting of sales invoice.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item);

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [WHEN] Create Requisition Line and Carry out action message.
        GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(SalesLine);

        // [THEN] Find the Purchase Order created from planning worksheet.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.FindFirst();

        // [GIVEN] Update "Vendor Invoice No." on Purchase Header.
        PurchaseHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // [GIVEN] Post Sales Document with shipment and invoice.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // [WHEN] Post Purchase Document with invoice.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // [THEN] Verify that the Posted Purchase Invoice and Posted Sales Invoice has been created.
        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);
    end;

    [Test]
    procedure PurchaseOrderMustNotBeCreatedFromDropShipmentPlanningWorkseetWhenVendorIsNotSelected()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 386698] Verify that purchase order is not created from drop shipment planning worksheet When Vendor is not selected.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [WHEN] Create Requisition Line and Carry out action message.
        asserterror GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(SalesLine);

        // [THEN] Verify that Purchase Order is not created.
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsEmpty(PurchaseHeader);
        Assert.ExpectedTestFieldError(RequisitionLine.FieldCaption("Vendor No."), '');
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure PurchaseOrderMustBeCreatedFromDropShipmentOrderPlanningWorksheet()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 386698] Verify that purchase order is created from order planning worksheet.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item);

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [GIVEN] CalculatePlan on Order Planning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // [WHEN]] Run Make order from Order Planning Worksheet.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // [THEN] Find the Purchase Order created from order planning worksheet.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.FindFirst();

        // [THEN] Verify that Purchase Line is created.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader."No.", SalesLine);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure PurchaseOrderMustBeCreatedFromDropShipmentOrderPlanningWorksheetWithMultipleLines()
    var
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        PurchasingCode: Code[20];
    begin
        // [SCENARIO 386698] Verify that purchase order is created from drop shipment order planning worksheet when "Calculate Plan" action is invoked with multiple lines.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item[1]);

        // [GIVEN] Create another item with the same Vendor No.
        CreateItemWithVendorNo(Item[2]);
        Item[2].Validate("Vendor No.", Item[1]."Vendor No.");
        Item[2].Modify(true);

        // [GIVEN] Sales Order with drop shipment.
        CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), Item[1]."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Save Purchasing Code of first line.
        PurchasingCode := SalesLine."Purchasing Code";

        // [GIVEN] Create another sales line with the another item.
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type, Item[2]."No.", LibraryRandom.RandInt(10), '');
        SalesLine.Validate("Purchasing Code", PurchasingCode);  // Drop Shipment as TRUE.
        SalesLine.Modify(true);

        // [GIVEN] Find Sales Line for Sales Header.
        FindSalesLine(SalesLine, SalesHeader);

        // [GIVEN] CalculatePlan on OrderPlanning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // [WHEN]] Run Make order from Order Planning Worksheet.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // [THEN] Find the Purchase Order created from order planning worksheet.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.FindFirst();

        // [THEN] Verify that Purchase Line is created.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader."No.", SalesLine);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure MultiplePurchaseOrderMustBeCreatedFromDropShipmentOrderPlanningWorksheetWithMultipleLinesForDifferentVendor()
    var
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchasingCode: Code[20];
    begin
        // [SCENARIO 386698] Verify that purchase order is created from drop shipment order planning worksheet when "Calculate Plan" action is invoked with multiple lines and different vendor.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item[1]);

        // [GIVEN] Create another item with the different Vendor No.
        CreateItemWithVendorNo(Item[2]);

        // [GIVEN] Sales Order with drop shipment.
        CreateSalesOrderWithDropShipment(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), Item[1]."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Save Purchasing Code of first line.
        PurchasingCode := SalesLine."Purchasing Code";

        // [GIVEN] Create another sales line with the another item.
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type, Item[2]."No.", LibraryRandom.RandInt(10), '');
        SalesLine.Validate("Purchasing Code", PurchasingCode);  // Drop Shipment as TRUE.
        SalesLine.Modify(true);

        // [GIVEN] Find Sales Line for Sales Header.
        FindSalesLine(SalesLine, SalesHeader);

        // [GIVEN] CalculatePlan on OrderPlanning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // [WHEN]] Run Make order from Order Planning Worksheet.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // [THEN] Find the Purchase Order created from order planning worksheet.
        FindPurchaseHeader(PurchaseHeader[1], Item[1]."Vendor No.");
        FindPurchaseHeader(PurchaseHeader[2], Item[2]."Vendor No.");

        // [THEN] Verify that Purchase Line is created.
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", SalesLine);

        // [GIVEN] Update "Vendor Invoice No." on a first Purchase Order.
        PurchaseHeader[1].Validate("Your Reference", LibraryUtility.GenerateGUID());
        PurchaseHeader[1].Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader[1].Modify(true);

        // [GIVEN] Update "Vendor Invoice No." on a second Purchase Order.
        PurchaseHeader[2].Validate("Your Reference", LibraryUtility.GenerateGUID());
        PurchaseHeader[2].Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader[2].Modify(true);

        // [GIVEN] Post Sales Document with shipment and invoice.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // [WHEN] Post Purchase Document with invoice.
        PostPurchaseDocument(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No.", false, true);
        PostPurchaseDocument(PurchaseHeader[2]."Document Type", PurchaseHeader[2]."No.", false, true);

        // [THEN] Verify that the Posted Purchase Invoice and Posted Sales Invoice has been created.
        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader[1]."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader[2]."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure PurchaseOrderMustNotBeCreatedFromDropShipmentOrderPlanningWorksheetMoreThanOnce()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 386698] Verify that purchase order is not created from drop shipment order planning worksheet more than once.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item);

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [GIVEN] CalculatePlan on OrderPlanning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // [WHEN]] Run Make order from Order Planning Worksheet.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // [THEN] Find the Purchase Order created from order planning worksheet.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.FindFirst();

        // [THEN] Verify that Purchase Line is created.
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        VerifyPurchaseLinesCreatedFromSalesLines(PurchaseHeader."No.", SalesLine);

        // [GIVEN] CalculatePlan on OrderPlanning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // [WHEN]] Run Make order from Order Planning Worksheet.
        asserterror MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // [THEN] Verify that purchase order is not created from drop shipment order planning worksheet more than once.
        Assert.ExpectedError(StrSubstNo(CannotCreatePurchaseOrderIsAlreadyWithSalesOrderErr, SalesLine."No.", SalesLine."Document No.", SalesLine."Purchase Order No."));
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure PurchaseInvoiceMustBePostedWithDropShipmentOrderPlanningWorksheetWitPostingOfSalesInvoice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO 386698] Verify that purchase order is created from drop shipment order planning worksheet when "Calculate Plan" action is invoked and purchase invoice is posted with posting of sales invoice.
        Initialize();

        // [GIVEN] Create Item.
        CreateItemWithVendorNo(Item);

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [GIVEN] CalculatePlan on OrderPlanning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // [WHEN]] Run Make order from Order Planning Worksheet.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // [THEN] Find the Purchase Order created from planning worksheet.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.FindFirst();

        // [GIVEN] Update "Vendor Invoice No." on Purchase Header.
        PurchaseHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // [GIVEN] Post Sales Document with shipment and invoice.
        PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.", true, true);

        // [WHEN] Post Purchase Document with invoice.
        PostPurchaseDocument(PurchaseHeader."Document Type", PurchaseHeader."No.", false, true);

        // [THEN] Verify that the Posted Purchase Invoice and Posted Sales Invoice has been created.
        PurchaseInvoiceHeader.SetRange("Order No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(PurchaseInvoiceHeader);

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure PurchaseOrderMustNotBeCreatedFromDropShipmentOrderPlanningWorkseetWhenVendorIsNotSelected()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 386698] Verify that purchase order is not created from drop shipment order planning worksheet When Vendor is not selected.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Update Purchasing Code on Item.
        UpdatePurchasingCodeOnItem(Item, CreatePurchasingCode(true, false));

        // [GIVEN] Create Sales Order with drop shipment.
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandDecInRange(10, 20, 2), '');

        // [GIVEN] CalculatePlan on OrderPlanning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // [WHEN]] Run Make order from Order Planning Worksheet.
        asserterror MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // [THEN] Verify that Purchase Order is not created.
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsEmpty(PurchaseHeader);
        Assert.ExpectedTestFieldError(RequisitionLine.FieldCaption("Supply From"), '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Orders VI");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        LibraryERM.SetWorkDate(); // IT.
        DisableNotifications();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Orders VI");

        InitializeCountryData();

        NoSeriesSetup();
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        LocationSetup();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Warehouse Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Orders VI");
    end;

    local procedure InitializeCountryData()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
    end;

    local procedure DisableNotifications()
    var
        PurchaseHeader: Record "Purchase Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());
    end;

    local procedure NoSeriesSetup()
    begin
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure LocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        CreateAndUpdateLocation(LocationRed, false, false);  // Location Blue2 with Require put-away and Require Pick.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, true);
        CreateAndUpdateLocation(LocationGreen, true, true);  // Location Green with Require put-away, Require Pick, Require Receive and Require Shipment.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);
    end;

    local procedure InvoiceDiscountSetupForPurch(var VendInvoiceDisc: Record "Vendor Invoice Disc."; VendorNo: Code[20]; InvoiceDiscPct: Decimal)
    begin
        LibraryERM.CreateInvDiscForVendor(VendInvoiceDisc, VendorNo, '', 0);
        VendInvoiceDisc.Validate("Discount %", InvoiceDiscPct);
        VendInvoiceDisc.Modify(true);
    end;

    local procedure ChangeReserveOptionAfterFillingPurchasingCode(DropShipment: Boolean; SpecialOrder: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Setup: Create sales Order with Item. Create and fill Purchasing Code on Sales Line.
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(
          SalesHeader, SalesLine, SalesLine.Type::Item, '', Item."No.", LibraryRandom.RandDec(50, 2), LocationBlue.Code);
        CreateAndFillPurchasingCodeOnSalesLine(SalesLine, DropShipment, SpecialOrder);

        // Exercise: Update Reserve to Always on Sales Line.
        asserterror SalesLine.Validate(Reserve, SalesLine.Reserve::Always);

        // Verify: Test an error pops up when changing Reserve from Never to Always
        // when Sales Order is marked to Special Order / Drop Shipment.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption(Reserve), Format(SalesLine.Reserve::Never));
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
    end;

    local procedure CopyDocumentAfterCreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        PostedPurchaseInvoice: Code[20];
    begin
        PostedPurchaseInvoice :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, VendorNo, ItemNo, Quantity, true);  // Post as INVOICE.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CopyPurchaseDocument(
            PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", PostedPurchaseInvoice, false, true);  // TRUE for RecalculateLines.
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UnitAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; Invoice: Boolean) PostedDocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, DocumentType, Type, VendorNo, ItemNo, Quantity);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);  // Post as Receive.
    end;

    local procedure CreateAndPostPurchaseOrderWithLotNo(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemTrackingMode: Option AssignLotNo,UpdateQuantityToInvoice;
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as RECEIVE.
    end;

    local procedure CreateAndPostPurchaseOrderWithMultipleItemsAndJobNo(Item: array[2] of Record Item; Quantity: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        for i := 1 to ArrayLen(Item) do begin
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item[i]."No.", Quantity);
            CreateJobWithJobTask(JobTask);
            UpdateJobNoAndJobTaskNoOnPurchaseLine(PurchaseLine, JobTask);
        end;

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure CreateAndPostPurchaseReturnOrderWithCopyPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; PostedPurchaseInvoiceNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        LibraryPurchase.CopyPurchaseDocument(
            PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", PostedPurchaseInvoiceNo, false, true);  // TRUE for RecalculateLines.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as RECEIVE.
    end;

    local procedure CreateAndPostPurchasePurchaseReturnOrderAfterGetPostedDocumentLinesToReverse(VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        PurchaseHeader.GetPstdDocLinesToReverse();
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));  // Post as Ship.
    end;

    local procedure CreateAndPostPurchaseCreditMemoAfterGetReturnShipmentLine(var PurchaseHeader: Record "Purchase Header"; PostedDocumentNo: Code[20]; VendorNo: Code[20]; Qty: Decimal): Code[20]
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        UpdateReasonCodeAndVendorCreditMemoNoOnPurchaseHeader(PurchaseHeader);
        GetReturnShipmentLine(PurchaseHeader, PostedDocumentNo, Qty);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));
    end;

    local procedure CreateAndPostPurchaseInvoiceAfterGetReceiptLine(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocumentNo: Code[20]; Qty: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        UpdateReasonCodeAndVendorCreditMemoNoOnPurchaseHeader(PurchaseHeader);
        GetReceiptLine(PurchaseHeader, DocumentNo, Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);
    end;

    local procedure CreateAndPostWarehouseReceiptFromPO(var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), ItemNo, LibraryRandom.RandDec(10, 2));
        UpdateLocationOnPurchaseLine(PurchaseLine, LocationCode);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndRegisterPutAwayFromPurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, LocationCode);
        CreateAndPostWarehouseReceiptFromPO(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          ItemNo, WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequireReceive: Boolean; RequireShipment: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Shipment", RequireShipment);
        if Location."Require Pick" then
            if Location."Require Shipment" then
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)"
            else
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";

        if Location."Require Put-away" then
            Location."Prod. Output Whse. Handling" := Location."Prod. Output Whse. Handling"::"Inventory Put-away";
        Location.Modify(true);
    end;

    local procedure CreateBlockedItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Blocked, true);
        Item.Modify(true);
    end;

    local procedure CreateItemWithReserveAsAlways(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
    end;

    local procedure CreateItemWithReserveAlwaysAndVendorNo(): Code[20]
    var
        Item: Record Item;
    begin
        CreateItemWithVendorNo(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithVendorNo(var Item: Record Item)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);
    end;

    local procedure CreateItemWithExtText(): Code[20]
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, Item."No.");
        ExtendedTextLine.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateNegativePurchaseLine(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, ItemNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreatePickFromPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; VendorNo: Code[20]; Quantity: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, VendorNo, ItemNo, LocationCode, Quantity);
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        FindWarehouseShipmentLine(
          WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreateProductionOrderWithItemQtyLocationWithRefreshAction(ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10])
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Qty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);
    end;

    local procedure CreatePurchaseBlanketOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", Type, VendorNo, ItemNo, Quantity);
    end;

    local procedure CreatePurchDocumentWithCurrencyCodeAndInvoiceDiscount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; LocationCode: Code[10]; ItemNo: Code[20]; InvDiscountPercent: Decimal)
    var
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(PurchaseLine."Line Amount" * (1 - InvDiscountPercent / 100), PurchaseHeader);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, Type, VendorNo, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Type, VendorNo, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseOrderByPage(var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor Name".SetValue(LibraryPurchase.CreateVendorNo());
        EnqueueForChangeOfSellToCustomerOrBuyFromVendor();
        EnqueueForChangeOfSellToCustomerOrBuyFromVendor();
    end;

    local procedure CreatePurchaseOrderWithItemQtyLocationExpectedDate(ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; ExpectedReceiptDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LocationRed.TestField("Require Pick", true);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), ItemNo, Qty);
        FindPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item,
          LibraryPurchase.CreateVendorNo(), ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", 0);
        PurchaseLine.Modify(true);  // Required for IT.
        UpdateReasonCodeAndVendorCreditMemoNoOnPurchaseHeader(PurchaseHeader);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(50, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineAndAssignItemCharge(PurchaseHeader: Record "Purchase Header"; ItemChargeNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryVariableStorage.Enqueue(false);  // Enqueue for ItemChargeAssignmentPurchPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue for ItemChargeAssignmentPurchPageHandler.
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemChargeNo, Quantity);
        PurchaseLine.ShowItemChargeAssgnt();
    end;

    local procedure CreatePurchaseOrderWithDifferentBuyFromVendorAndPayToVendor(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var Vendor: Record Vendor; var Vendor2: Record Vendor)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryVariableStorage.Enqueue(ConfirmTextForChangeOfSellToCustomerOrBuyFromVendorQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryPurchase.CreateVendor(Vendor2);
        PurchaseHeader.Validate("Pay-to Vendor No.", Vendor2."No.");
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePurchasingCode(DropShipment: Boolean; SpecialOrder: Boolean) PurchasingCode: Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", DropShipment);
        Purchasing.Validate("Special Order", SpecialOrder);
        Purchasing.Modify(true);
        PurchasingCode := Purchasing.Code
    end;

    local procedure CreatePurchaseDocumentWithItemChargeAssignmentWithLnDiscAndInvDisc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PricesIncludingVAT: Boolean; Quantity: Decimal; DirectCost: Decimal; LnDiscPct: Decimal): Decimal
    var
        ItemCharge: Record "Item Charge";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", Quantity);
        PurchaseLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", DirectCost);
        PurchaseLine.Validate("Line Discount %", LnDiscPct);
        PurchaseLine.Validate("Allow Invoice Disc.", true);
        PurchaseLine.Modify(true);
        exit(VATPostingSetup."VAT %");
    end;

    local procedure CreatePurchOrderWithQuantityShipped(var PurchaseLine: Record "Purchase Line"; ReturnQtyShippedBase: Decimal; ReturnQtyShipped: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, '', '', LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Return Qty. Shipped (Base)", ReturnQtyShippedBase);
        PurchaseLine.Validate("Return Qty. Shipped", ReturnQtyShipped);

        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchInvoiceWithItemChargeWithLnDiscAndInvDisc(var PurchaseHeader2: Record "Purchase Header"; var GeneralPostingSetup: Record "General Posting Setup"; PricesIncludingVAT: Boolean) ExpdTotalDisAmt: Decimal
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: array[3] of Record "Purchase Header";
        PurchaseLine: array[3] of Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PostedDocNo: array[3] of Code[20];
        i: Integer;
        VATPct: Decimal;
    begin
        // General preparation for create purchase invoice with item charge with line discount and invoice discount.
        CreateVendorWithInvoiceDiscount(Vendor, 5); // Using hardcode to test rounding.
        LibraryInventory.CreateItem(Item);

        for i := 1 to 3 do
            PostedDocNo[i] :=
              CreateAndPostPurchaseDocument(PurchaseHeader[i], PurchaseHeader[i]."Document Type"::Order, PurchaseLine[i].Type::Item,
                Vendor."No.", Item."No.", LibraryRandom.RandDec(10, 2), false); // Post as Receive.

        VATPct :=
          CreatePurchaseDocumentWithItemChargeAssignmentWithLnDiscAndInvDisc(
            PurchaseHeader2, PurchaseLine2, PurchaseHeader2."Document Type"::Invoice, Vendor."No.", PricesIncludingVAT, 3.333, 6.999, 10);

        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine2); // Calculate Invoice Discount.

        for i := 1 to 3 do begin
            LibraryVariableStorage.Enqueue(PostedDocNo[i]);  // PostedDocumentNo used in PurchReceiptLinePageHandler.
            if i > 1 then
                LibraryVariableStorage.Enqueue(1); // Select Equally when suggest item charge.
            PurchaseLine2.ShowItemChargeAssgnt();
        end;

        ExpdTotalDisAmt := FindPurchaseInvoice(PurchaseHeader2, PurchaseLine2); // Need find it before posting.

        if PricesIncludingVAT then
            ExpdTotalDisAmt := Round(ExpdTotalDisAmt / (1 + VATPct / 100));

        GeneralPostingSetup.Get(PurchaseLine2."Gen. Bus. Posting Group", PurchaseLine2."Gen. Prod. Posting Group");
    end;

    local procedure CreatePurchaseOrderWithReservedItem(var PurchaseOrder: TestPage "Purchase Order")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        CreateItemWithReserveAsAlways(Item);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.",
          LibraryRandom.RandDec(10, 2));
        UpdateLocationOnPurchaseLine(PurchaseLine, LocationBlue.Code);
        UpdateExpectedReceiptDateOnPurchaseLine(PurchaseLine);
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', Item."No.", 0, LocationBlue.Code);
        OpenSalesOrderByPage(SalesOrder, SalesHeader."No.");
        SalesOrder.SalesLines.Quantity.SetValue(PurchaseLine.Quantity);

        OpenPurchaseOrderByPage(PurchaseOrder, PurchaseHeader."No.");
    end;

    local procedure CreateReasonCode() "Code": Code[10]
    var
        ReasonCode: Record "Reason Code";
    begin
        LibraryERM.CreateReasonCode(ReasonCode);
        Code := ReasonCode.Code;
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line"; ReqWkshTemplate: Record "Req. Wksh. Template"; RequisitionWkshName: Record "Requisition Wksh. Name"; StartingDate: Date; StartingTime: Time; ItemNo: Code[20]; DocumentNo: Code[20])
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("Ref. Order No.", DocumentNo);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate("Starting Date", StartingDate);
        RequisitionLine.Validate("Starting Time", StartingTime);
        RequisitionLine.Validate("Ref. Order Status", RequisitionLine."Ref. Order Status"::Planned);
        RequisitionLine.Modify();
    end;

    local procedure CreateReqWkshTemplateName(var ReqWkshTemplate: Record "Req. Wksh. Template"; var RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Tax Area Code", '');  // Required for CA.
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, Type, ItemNo, Quantity, LocationCode);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Type, CustomerNo, ItemNo, Quantity, LocationCode);
    end;

    local procedure CreateSalesDocumentWithCurrencyCodeAndInvoiceDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]; LocationCode: Code[10]; ItemNo: Code[20]; InvDiscountPercent: Decimal)
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10), LocationCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(SalesLine."Line Amount" * (1 - InvDiscountPercent / 100), SalesHeader);
    end;

    local procedure CreateSalesOrderDiscardManualReservation(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        Clear(SalesHeader);
        Clear(SalesLine);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        LibraryVariableStorage.Enqueue(ReserveItemsManuallyConfirmQst);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(false);  // Enqueue for ConfirmHandler.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesOrderWithDropShipment(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, CustomerNo, ItemNo, Quantity, '');
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(true, false));  // Drop Shipment as TRUE.
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithSpecialOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, CustomerNo, ItemNo, Quantity, '');
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(false, true));  // Special Order as TRUE.
        SalesLine.Modify(true);
    end;

    local procedure CreateSpecialOrderSalesAndPurchase(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        ItemNo: Code[20];
    begin
        ItemNo := CreateItemWithReserveAlwaysAndVendorNo();
        CreateSpecialSalesOrderForItem(SalesHeader, SalesLine, ItemNo);
        GetSalesOrderForSpecialOrderOnRequisitionWkshtAndCarryOutActionMsg(ItemNo);
    end;

    local procedure CreateSpecialSalesOrderForItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLineWithPurchasingCode(
          SalesHeader, SalesLine, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10), '', CreatePurchasingCode(false, true));
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithPurchasingCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; PurchasingCode: Code[10])
    begin
        CreateSalesLine(SalesHeader, SalesLine, Type, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateVendorAndOpenPurchaseLineDiscountsPageFromVendorCard(var PurchaseLineDiscounts: TestPage "Purchase Line Discounts")
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseLineDiscounts.Trap();
        OpenVendorCard(VendorCard, Vendor."No.");
        VendorCard."Line Discounts".Invoke();  // Open Purchase Line Discount Page from Vendor Card.
    end;

    local procedure CreateVendorAndOpenPurchasePricesPageFromVendorCard(var PurchasePrices: TestPage "Purchase Prices")
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Commit();
        PurchasePrices.Trap();
        OpenVendorCard(VendorCard, Vendor."No.");
        VendorCard.Prices.Invoke();  // Open Purchase Price Page from Vendor Card.
    end;

    local procedure CreateVendorWithInvoiceDiscount(var Vendor: Record Vendor; InvoiceDiscPct: Decimal)
    var
        VendInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        InvoiceDiscountSetupForPurch(VendInvoiceDisc, Vendor."No.", InvoiceDiscPct);
    end;

    local procedure CreateAndFillPurchasingCodeOnSalesLine(var SalesLine: Record "Sales Line"; DropShipment: Boolean; SpecialOrder: Boolean)
    begin
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(DropShipment, SpecialOrder));
        SalesLine.Modify(true);
    end;

    local procedure CreateItemTranslation(var ItemTranslation: Record "Item Translation"; ItemNo: Code[20]; LanguageCode: Code[10])
    begin
        ItemTranslation.Validate("Item No.", ItemNo);
        ItemTranslation.Validate("Language Code", LanguageCode);
        ItemTranslation.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(ItemTranslation.Description)));
        ItemTranslation.Validate("Description 2", LibraryUtility.GenerateRandomText(MaxStrLen(ItemTranslation."Description 2")));
        ItemTranslation.Insert(true);
    end;

    local procedure CreateItemReferenceForVendor(var ItemReference: Record "Item Reference"; ItemNo: Code[20]; VendorNo: Code[20])
    begin
        LibraryItemReference.CreateItemReference(
            ItemReference, ItemNo, "Item Reference Type"::Vendor, VendorNo);
        UpdateItemReferenceDescriptions(ItemReference);
    end;

    local procedure CreateItemReferenceForCustomer(var ItemReference: Record "Item Reference"; ItemNo: Code[20]; CustomerNo: Code[20])
    begin
        LibraryItemReference.CreateItemReference(
            ItemReference, ItemNo, "Item Reference Type"::Customer, CustomerNo);
        UpdateItemReferenceDescriptions(ItemReference);
    end;

    local procedure CreatePurchaseOrderWithBlankLine(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
    end;

    local procedure CreateSalesOrderWithBlankLine(var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
    end;

    local procedure CreateDropShipmentSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, ItemNo, LibraryRandom.RandInt(10), '', WorkDate());
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(true, false));
        SalesLine.Modify(true);
        exit(SalesHeader."No.");
    end;

    local procedure CreatePurchOrderWithSelltoCustomerNo(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; CustomerNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Sell-to Customer No.", CustomerNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure EnqueueForChangeOfSellToCustomerOrBuyFromVendor()
    begin
        LibraryVariableStorage.Enqueue(ConfirmTextForChangeOfSellToCustomerOrBuyFromVendorQst);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ConfirmHandler.
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindPostedWhseShipmentLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; ItemNo: Code[20])
    begin
        PostedWhseShipmentLine.SetRange("Source Document", SourceDocument);
        PostedWhseShipmentLine.SetRange("Item No.", ItemNo);
        PostedWhseShipmentLine.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; DocumentNo: Code[20]) LineNo: Integer
    begin
        FilterPurchaseReceiptLine(PurchRcptLine, DocumentNo);
        LineNo := PurchRcptLine."Line No.";
        PurchRcptLine.Next();  // To go to next line.
    end;

    local procedure FindPurchaseReceiptLine2(VendorNo: Code[20]; ItemNo: Code[20]; var DocumentNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
        DocumentNo := PurchRcptLine."Document No.";
    end;

    local procedure FindReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; ItemNo: Code[20])
    begin
        ReturnShipmentLine.SetRange("No.", ItemNo);
        ReturnShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FilterPurchReturnExtLine(var PurchLine: Record "Purchase Line"; VendorNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::"Return Order");
        PurchHeader.FindFirst();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::"Return Order");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange("No.", '');
    end;

    local procedure FilterPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20])
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Return Order");
        PurchaseHeader.SetRange("No.", DocumentNo);
    end;

    local procedure FilterPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; DocumentNo: Code[20])
    begin
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchRcptLine.FindSet();
    end;

    local procedure FindPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line") ExpdTotalDisAmt: Decimal
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        PurchaseHeader.FindFirst();
        ExpdTotalDisAmt := PurchaseLine."Line Discount Amount" + PurchaseLine."Inv. Discount Amount";
    end;

    local procedure FindItemReferenceByVendorNo(var ItemReference: Record "Item Reference"; ItemNo: Code[20]; VendorNo: Code[20])
    begin
        ItemReference.SetRange("Item No.", ItemNo);
        ItemReference.SetRange("Variant Code", '');
        ItemReference.SetRange("Reference Type", "Item Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", VendorNo);
        ItemReference.FindFirst();
    end;

    local procedure FillPurchasingCodeWhenReservationEntryExist(DropShipment: Boolean; SpecialOrder: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Setup: Create Item with Reserve is Always. Update inventory by posting Item Journal.
        // Create Sales Order. Update Quantity on Sales Line by page. Then calculate Reserved Quantity.
        CreateItemWithReserveAsAlways(Item);
        CreateAndPostItemJournalLine(Item."No.", LibraryRandom.RandInt(10) + 100, LocationBlue.Code, 0);
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, '', Item."No.", 0, LocationBlue.Code);

        // Update Quantity from page to ensure that Reserved Quantity has value.
        UpdateQuantityOnSalesLineByPage(SalesHeader, LibraryRandom.RandInt(10));
        SalesLine.CalcFields("Reserved Quantity");

        // Exercise: Create and fill Purchasing Code on Sales Line.
        asserterror CreateAndFillPurchasingCodeOnSalesLine(SalesLine, DropShipment, SpecialOrder);

        // Verify: Verify an error pops up when filling Purchasing Code when Reservation Entry exists.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Reserved Qty. (Base)"), Format(0));
    end;

    local procedure GeneralSetupForRegisterPutAway(var PurchaseLine: Record "Purchase Line")
    var
        Location: Record Location;
        Item: Record Item;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        CreateFullWarehouseSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromPurchaseOrder(PurchaseLine, Item."No.", Location.Code);
    end;

    local procedure GetReturnShipmentLine(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20]; Qty: Decimal)
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        ReturnShipmentLine.SetRange("Document No.", DocumentNo);
        PurchGetReturnShipments.SetPurchHeader(PurchaseHeader);
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);
        if Qty <> 0 then
            UpdateQuantityOnPurchaseCreditMemoLineByPage(PurchaseHeader."No.", ReturnShipmentLine."No.", Qty);
    end;

    local procedure GetReceiptLine(var PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20]; Qty: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        if Qty <> 0 then
            UpdateQuantityOnPurchInvoiceLineByPage(PurchaseHeader."No.", PurchRcptLine."No.", Qty);
    end;

    local procedure GetPurchaseReceiptHeader(OrderNo: Code[20]) PurchaseReceiptHeaderNo: Code[20]
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
        PurchaseReceiptHeaderNo := PurchRcptHeader."No.";
    end;

    local procedure GetSalesOrderForDropShipmentOnRequisitionWkshtAndCarryOutActionMsg(var SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, SelectRequisitionTemplate());
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure GetSalesOrderForSpecialOrderOnRequisitionWkshtAndCarryOutActionMsg(ItemNo: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, SelectRequisitionTemplate());
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure MoveNegativeLinesOnPurchOrder(PurchHeader: Record "Purchase Header")
    var
        MoveNegPurchLines: Report "Move Negative Purchase Lines";
        FromDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo";
        ToDocType: Option ,,"Order",Invoice,"Return Order","Credit Memo";
    begin
        MoveNegPurchLines.SetPurchHeader(PurchHeader);
        MoveNegPurchLines.InitializeRequest(FromDocType::Order, ToDocType::"Return Order", ToDocType::"Return Order");
        MoveNegPurchLines.UseRequestPage(false);
        MoveNegPurchLines.RunModal();
    end;

    local procedure OpenPurchaseOrderByPage(var PurchaseOrder: TestPage "Purchase Order"; PurchaseHeaderNo: Code[20])
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeaderNo);
    end;

    local procedure OpenSalesOrderByPage(var SalesOrder: TestPage "Sales Order"; SalesHeaderNo: Code[20])
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeaderNo);
    end;

    local procedure OpenVendorCard(var VendorCard: TestPage "Vendor Card"; VendorNo: Code[20])
    begin
        VendorCard.OpenEdit();  // Open Vendor Card.
        VendorCard.FILTER.SetFilter("No.", VendorNo);
    end;

    local procedure PostCreditMemoAgainstPurchaseReturnOrderUsingPayToVendorDifferentFromPurchaseOrder(ReturnOrder: Boolean; CreditMemo: Boolean)
    var
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup2: Record "General Posting Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PostedDocumentNo: Code[20];
        PurchCMGLAccNo: Code[20];
    begin
        // Create Purchase Order with Different Buy from Vendor and Pay to Vendor.
        CreatePurchaseOrderWithDifferentBuyFromVendorAndPayToVendor(PurchaseHeader, PurchaseLine, Vendor, Vendor2);

        // Exercise.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify:
        GeneralPostingSetup2.Get(Vendor2."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VendorPostingGroup.Get(Vendor2."Vendor Posting Group");
        VerifyGLEntry(GLEntry."Document Type"::Invoice, PostedDocumentNo, GeneralPostingSetup2."Purch. Account", PurchaseLine.Amount);
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, PostedDocumentNo, VendorPostingGroup."Payables Account", -PurchaseLine."Amount Including VAT");

        if ReturnOrder then begin
            // Exercise.
            PostedDocumentNo :=
              CreateAndPostPurchasePurchaseReturnOrderAfterGetPostedDocumentLinesToReverse(PurchaseHeader."Buy-from Vendor No.");

            // Verify.
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Document Type"::"Purchase Return Shipment", PostedDocumentNo, ItemLedgerEntry."Entry Type"::Purchase,
              PurchaseLine."No.", 0);  // Value required for test.
        end;

        if CreditMemo then begin
            // Exercise.
            PostedDocumentNo :=
              CreateAndPostPurchaseCreditMemoAfterGetReturnShipmentLine(
                PurchaseHeader, PostedDocumentNo, PurchaseHeader."Buy-from Vendor No.", 0);

            // Verify.
            GeneralPostingSetup2.Get(Vendor."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
            VendorPostingGroup.Get(Vendor."Vendor Posting Group");
            PurchCMGLAccNo := GeneralPostingSetup2."Purch. Credit Memo Account";
            VerifyGLEntry(
              GLEntry."Document Type"::"Credit Memo", PostedDocumentNo, PurchCMGLAccNo, -PurchaseLine.Amount);
            VerifyGLEntry(
              GLEntry."Document Type"::"Credit Memo", PostedDocumentNo, VendorPostingGroup."Payables Account",
              PurchaseLine."Amount Including VAT");
        end;
    end;

    local procedure PostPurchaseOrderWithSpecialOrder(PartialPosting: Boolean)
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        PostedPurchaseReceipts: TestPage "Posted Purchase Receipts";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
        Quantity: Decimal;
        PurchaseHeaderNo: Code[20];
    begin
        // Setup: Create Sales order with special order. Get Sales Order for Special Order on Requisition Worksheet and carry out action Message.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithVendorNo(Item);
        CreateSalesOrderWithSpecialOrder(SalesHeader, '', Item."No.", Quantity);
        GetSalesOrderForSpecialOrderOnRequisitionWkshtAndCarryOutActionMsg(Item."No.");

        // Exercise:  Post Purchase Order and get Special Purchase Order From Sales Order Page.
        if PartialPosting then begin
            UpdateAndPostPurchaseOrder(Item."No.", Quantity / 2);  // Partial Posting of Purchase Order.
            PurchaseHeaderNo := UpdateAndPostPurchaseOrder(Item."No.", Quantity / 2)
        end else
            PurchaseHeaderNo := UpdateAndPostPurchaseOrder(Item."No.", Quantity);
        SpecialPurchaseOrderFromSalesOrderPage(PostedPurchaseReceipt, PostedPurchaseReceipts, SalesHeader."No.");

        // Verify.
        if PartialPosting then
            VerifyPostedPurchaseReceiptsPage(PostedPurchaseReceipts, PurchaseHeaderNo)
        else
            VerifyPostedPurchaseReceiptPage(PostedPurchaseReceipt, Item."No.", Quantity, PurchaseHeaderNo);
    end;

    local procedure PostPurchaseReturnOrderWithExactCostReversingMandatory(ExactCostReversingMandatory: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseHeader3: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
        Quantity: Decimal;
        Quantity2: Decimal;
        PostedPurchaseInvoiceNo: Code[20];
        OldExactCostReversingMandatory: Boolean;
    begin
        // Create and post two Purchase Orders and set Exact Cost Reversing Mandatory.
        OldExactCostReversingMandatory := UpdatePurchasePayableSetup(ExactCostReversingMandatory);
        Quantity := LibraryRandom.RandInt(50);
        Quantity2 := Quantity + LibraryRandom.RandInt(10);  // Greater Value required for the Quantity.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, Vendor."No.", Item."No.", Quantity2, true);  // True for INVOICE.
        PostedPurchaseInvoiceNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader2, PurchaseHeader2."Document Type"::Order, PurchaseLine.Type::Item, Vendor."No.", Item."No.", Quantity, true);  // True for INVOICE.

        // Exercise.
        CreateAndPostPurchaseReturnOrderWithCopyPurchaseDocument(PurchaseHeader3, Vendor."No.", PostedPurchaseInvoiceNo);

        // Verify.
        if ExactCostReversingMandatory then begin
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Document Type"::"Purchase Receipt", GetPurchaseReceiptHeader(PurchaseHeader."No."),
              ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Quantity2);
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Document Type"::"Purchase Receipt", GetPurchaseReceiptHeader(PurchaseHeader2."No."),
              ItemLedgerEntry."Entry Type"::Purchase, Item."No.", 0);  // Value 0 required for test.
        end else begin
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Document Type"::"Purchase Receipt", GetPurchaseReceiptHeader(PurchaseHeader."No."),
              ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Quantity2 - Quantity);  // Value required for the test.
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Document Type"::"Purchase Receipt", GetPurchaseReceiptHeader(PurchaseHeader2."No."),
              ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Quantity);
        end;

        // Tear Down.
        UpdatePurchasePayableSetup(OldExactCostReversingMandatory);
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostReceiptForPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Qty: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Receive", Qty);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure PostWhseReceiptForPurchaseOrder(PurchaseOrderNo: Code[20]; Qty: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseOrderNo);
        WarehouseReceiptLine.Validate("Qty. to Receive", Qty);
        WarehouseReceiptLine.Modify(true);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseOrderNo);
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

    local procedure PostWhseShipmentAfterPickFromPurchReturnOrder(BuyfromVendorNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreatePickFromPurchaseReturnOrder(
          PurchaseHeader, LocationCode, ItemNo, BuyfromVendorNo, Qty);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          ItemNo, WarehouseActivityLine."Activity Type"::Pick);
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");
    end;

    local procedure PostShipmentForSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Qty: Decimal)
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", Qty);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure PostWhseShipmentForSalesOrder(SalesOrderNo: Code[20]; Qty: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesOrderNo);
        WarehouseShipmentLine.Validate("Qty. to Ship", Qty);
        WarehouseShipmentLine.Modify(true);
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesOrderNo);
    end;

    local procedure RegisterWarehouseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure SelectRequisitionTemplate() ReqWkshTemplateName: Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Planning);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        ReqWkshTemplateName := ReqWkshTemplate.Name
    end;

    local procedure SpecialPurchaseOrderFromSalesOrderPage(var PostedPurchaseReceipt: TestPage "Posted Purchase Receipt"; var PostedPurchaseReceipts: TestPage "Posted Purchase Receipts"; SalesHeaderNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeaderNo);
        PostedPurchaseReceipt.Trap();
        PostedPurchaseReceipts.Trap();
        SalesOrder.SalesLines.OpenSpecialPurchaseOrder.Invoke();
    end;

    local procedure UndoPurchaseReceiptLine(DocumentNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        LibraryVariableStorage.Enqueue(UndoReceiptMsg);  // UndoReceiptMessage Used in ConfirmHandler.
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ConfirmHandler.
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    local procedure UndoReturnShipmentLine(DocumentNo: Code[20])
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(UndoReturnShipmentMsg);  // UndoReturnShipmentMessage Used in ConfirmHandler.
        LibraryVariableStorage.Enqueue(true);  // Enqueue for ConfirmHandler.
        ReturnShipmentLine.SetRange("Document No.", DocumentNo);
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);
    end;

    local procedure UndoPurchaseDocumentForAppliedQuantity(DocumentType: Enum "Purchase Document Type"; SignFactor: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and Post Purchase Document. Create Sales Order Apply with Posted Purchase Document and Post.
        Quantity := LibraryRandom.RandDec(50, 2);
        LibraryInventory.CreateItem(Item);
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader, DocumentType, PurchaseLine.Type::Item, LibraryPurchase.CreateVendorNo(), Item."No.", Quantity * SignFactor, false);
        CreateSalesOrder(SalesHeader, SalesLine, SalesLine.Type::Item, LibrarySales.CreateCustomerNo(), Item."No.", Quantity, '');
        if DocumentType = PurchaseHeader."Document Type"::Order then
            FindItemLedgerEntry(
              ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Purchase Receipt", PostedDocumentNo,
              ItemLedgerEntry."Entry Type"::Purchase, Item."No.")
        else
            FindItemLedgerEntry(
              ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Purchase Return Shipment", PostedDocumentNo,
              ItemLedgerEntry."Entry Type"::Purchase, Item."No.");
        UpdateApplyToItemEntryOnSalesLine(SalesLine, ItemLedgerEntry."Entry No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice

        // Exercise.
        if DocumentType = PurchaseHeader."Document Type"::Order then
            asserterror UndoPurchaseReceiptLine(PostedDocumentNo)
        else
            asserterror UndoReturnShipmentLine(PostedDocumentNo);

        // Verify: Error Message Cannot Undo Applied Quantity.
        Assert.ExpectedTestFieldError(ItemLedgerEntry.FieldCaption("Remaining Quantity"), Format(Quantity));
    end;

    local procedure UndoSalesShipmentLine(DocumentNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(UndoShipmentQst);
        LibraryVariableStorage.Enqueue(true);
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UndoServiceShipmentLine(DocumentNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(UndoServiceShipmentQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryService.UndoShipmentLinesByServiceOrderNo(DocumentNo);
    end;

    local procedure UpdateAndPostPurchaseOrder(ItemNo: Code[20]; QuantityToReceive: Decimal) PurchaseHeaderNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, ItemNo);
        UpdateQuantityToReceiveOnPurchaseLine(PurchaseLine, QuantityToReceive);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        PurchaseHeaderNo := PurchaseHeader."No.";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Receive and Invoice.
    end;

    local procedure UpdateApplyToItemEntryOnSalesLine(var SalesLine: Record "Sales Line"; ApplToItemEntry: Integer)
    begin
        SalesLine.Validate("Appl.-to Item Entry", ApplToItemEntry);
        SalesLine.Modify(true);
    end;

    local procedure UpdateBlanketOrderNoOnPurchaseLine(PurchaseLine: Record "Purchase Line"; BlanketOrderNo: Code[20]; BlanketOrderLineNo: Integer)
    begin
        PurchaseLine.Validate("Blanket Order No.", BlanketOrderNo);
        PurchaseLine.Validate("Blanket Order Line No.", BlanketOrderLineNo);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateExpectedCostPostingToGLOnInventorySetup(NewExpectedCostPostingToGL: Boolean) OldExpectedCostPostingToGL: Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if NewExpectedCostPostingToGL then
            LibraryVariableStorage.Enqueue(ExpectedCostPostingEnableToGLQst)
        else
            LibraryVariableStorage.Enqueue(ExpectedCostPostingDisableToGLQst);
        LibraryVariableStorage.Enqueue(true);
        if NewExpectedCostPostingToGL then
            LibraryVariableStorage.Enqueue(ExpectedCostPostingToGLMsg);
        OldExpectedCostPostingToGL := InventorySetup."Expected Cost Posting to G/L";
        InventorySetup.Validate("Expected Cost Posting to G/L", NewExpectedCostPostingToGL);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateExpectedReceiptDateOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Expected Receipt Date", WorkDate());
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateLocationOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    begin
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchasePayableSetup(NewExactCostReversingMandatory: Boolean) OldExactCostReversingMandatory: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldExactCostReversingMandatory := PurchasesPayablesSetup."Exact Cost Reversing Mandatory";
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", NewExactCostReversingMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateQuantityOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; Quantity: Decimal)
    begin
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQuantityToReceiveOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QuantityToReceive: Decimal)
    begin
        PurchaseLine.Validate("Qty. to Receive", QuantityToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateReasonCodeAndVendorCreditMemoNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Reason Code", CreateReasonCode());
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateQuantityOnSalesLineByPage(var SalesHeader: Record "Sales Header"; Quantity: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        OpenSalesOrderByPage(SalesOrder, SalesHeader."No.");
        SalesOrder.SalesLines.Quantity.SetValue(Quantity);
    end;

    local procedure UpdateQuantityOnPurchInvoiceLineByPage(No: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", No);
        PurchaseInvoice.PurchLines.FILTER.SetFilter("No.", ItemNo);
        PurchaseInvoice.PurchLines.Quantity.SetValue(Qty); // Update Quantity for posting Sales Invoice partially.
        PurchaseInvoice.OK().Invoke();
    end;

    local procedure UpdateQuantityOnPurchaseCreditMemoLineByPage(No: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", No);
        PurchaseCreditMemo.PurchLines.FILTER.SetFilter("No.", ItemNo);
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(Qty); // Update Quantity for posting Purchase Credit Memo partially.
        PurchaseCreditMemo.OK().Invoke();
    end;

    local procedure UpdateItemReferenceDescriptions(var ItemReference: Record "Item Reference")
    begin
        ItemReference.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(ItemReference.Description)));
        ItemReference.Validate("Description 2", LibraryUtility.GenerateRandomText(MaxStrLen(ItemReference."Description 2")));
        ItemReference.Modify(true);
    end;

    local procedure UpdatePurchasingCodeOnItem(var Item: Record Item; PurchasingCode: Code[10])
    begin
        Item.Validate("Purchasing Code", PurchasingCode);
        Item.Modify(true);
    end;

    local procedure UpdateDropShipmentOnSalesLine(var SalesLine: Record "Sales Line"; DropShipment: Boolean)
    begin
        SalesLine.Validate("Drop Shipment", DropShipment);
        SalesLine.Modify(true);
    end;

    local procedure UpdateJobNoAndJobTaskNoOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; JobTask: Record "Job Task")
    begin
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyItemLedgerEntry(DocumentType: Enum "Item Ledger Document Type"; OrderNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, DocumentType, OrderNo, EntryType, ItemNo);
        ItemLedgerEntry.TestField("Remaining Quantity", ExpectedQuantity);
    end;

    local procedure VerifyPostedWhseShipmentLine(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        PostedWhseShipmentLine.SetRange("Source No.", SourceNo);
        FindPostedWhseShipmentLine(PostedWhseShipmentLine, PostedWhseShipmentLine."Source Document"::"Purchase Return Order", ItemNo);
        PostedWhseShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseCreditMemoLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("No.", ItemNo);
        PurchCrMemoLine.FindFirst();
        PurchCrMemoLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseReturnOrder(VendorNo: Code[20]; ShipToName: Text[100]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Return Order");
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField("Ship-to Name", ShipToName);

        // Verify Purchase Line.
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        FindPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseBlanketOrderLine(DocumentNo: Code[20]; QuantityToReceive: Decimal; QuantityReceived: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type"::"Blanket Order");
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Qty. to Receive", QuantityToReceive);
        PurchaseLine.TestField("Quantity Received", QuantityReceived);
    end;

    local procedure VerifyQtyToInvoiceOnPurchaseLine(ItemNo: Code[20]; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        FindPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.TestField("Qty. to Invoice", Quantity);
    end;

    local procedure VerifyPurchInvoiceLine(DocumentNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange("No.", No);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReceiptLine(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; Next: Boolean)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("No.", ItemNo);
        FilterPurchaseReceiptLine(PurchRcptLine, DocumentNo);
        if Next then
            PurchRcptLine.Next();
        PurchRcptLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedPurchaseReceiptPage(PostedPurchaseReceipt: TestPage "Posted Purchase Receipt"; ItemNo: Code[20]; Quantity: Decimal; PurchaseHeaderNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", PurchaseHeaderNo);
        PurchRcptHeader.FindFirst();
        PostedPurchaseReceipt."No.".AssertEquals(PurchRcptHeader."No.");
        PostedPurchaseReceipt.PurchReceiptLines."No.".AssertEquals(ItemNo);
        PostedPurchaseReceipt.PurchReceiptLines.Quantity.AssertEquals(Quantity);
    end;

    local procedure VerifyPostedPurchaseReceiptsPage(PostedPurchaseReceipts: TestPage "Posted Purchase Receipts"; PurchaseHeaderNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        "Count": Integer;
    begin
        PurchRcptHeader.SetRange("Order No.", PurchaseHeaderNo);
        PurchRcptHeader.FindSet();
        PostedPurchaseReceipts.Last();
        repeat
            Count += 1;  // Used to count No. Of Lines on the Posted Purchase Receipts Page.
            PostedPurchaseReceipts."No.".AssertEquals(PurchRcptHeader."No.");
            PurchRcptHeader.Next();
        until not PostedPurchaseReceipts.Previous();
        Assert.AreEqual(Count, PurchRcptHeader.Count, RecordCountErr);
    end;

    local procedure VerifyQuantityOnItemLedgerEntry(DocumentNo: Code[20]; DocumentLineNo: Integer; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Line No.", DocumentLineNo);
        FindItemLedgerEntry(
          ItemLedgerEntry, ItemLedgerEntry."Document Type"::"Purchase Receipt", DocumentNo, ItemLedgerEntry."Entry Type"::Purchase, ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReturnShipmentLine(PostedDocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; Next: Boolean)
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SetRange("Document No.", PostedDocumentNo);
        ReturnShipmentLine.SetRange("No.", ItemNo);
        ReturnShipmentLine.FindSet();
        if Next then
            ReturnShipmentLine.Next();
        ReturnShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; DocumentLineNo: Integer; ValuedQuantity: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Receipt");
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Document Line No.", DocumentLineNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Valued Quantity", ValuedQuantity);
    end;

    local procedure VerifyDiscountAmountInValueEntry(PostedDocNo: Code[20]; ExpdTotalDisAmt: Decimal)
    var
        ValueEntry: Record "Value Entry";
        ActualTotalDisAmt: Decimal;
    begin
        ValueEntry.SetRange("Document No.", PostedDocNo);
        ValueEntry.FindSet();
        repeat
            ActualTotalDisAmt := ActualTotalDisAmt + Abs(ValueEntry."Discount Amount");
        until ValueEntry.Next() = 0;
        Assert.AreEqual(ExpdTotalDisAmt, ActualTotalDisAmt, DiscountErr);
    end;

    local procedure VerifyDiscountAmountInGLEntry(PostedDocNo: Code[20]; LineDiscAccount: Code[20]; InvDiscAccount: Code[20]; ExpdTotalDisAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
        TotalAMount: Decimal;
    begin
        GLEntry.SetRange("Document No.", PostedDocNo);
        GLEntry.SetFilter("G/L Account No.", '%1|%2', LineDiscAccount, InvDiscAccount);
        GLEntry.FindSet();
        repeat
            TotalAMount += GLEntry.Amount;
        until GLEntry.Next() = 0;

        Assert.AreEqual(ExpdTotalDisAmt, TotalAMount, DiscountErr);
    end;

    local procedure ExecuteUIHandlers()
    begin
        if Confirm('') then;
    end;

    local procedure AddDays(ToDate: Date; NumberOfDays: Integer): Date
    var
        DayDateFormulaTxt: Label '<%1D>', Locked = false, Comment = '%1 = no. of days';
    begin
        exit(CalcDate(StrSubstNo(DayDateFormulaTxt, NumberOfDays), ToDate));
    end;

    local procedure CreateMandatoryVariant(var Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Yes);
        Item.Modify();
        LibraryInventory.CreateVariant(ItemVariant, Item);
    end;

    local procedure InitVariantMandatoryAssemblyTestVariables(var ChildItem: Record Item; var ParentItem: Record Item; var ChildItemVariant: Record "Item Variant"; var ParentItemVariant: Record "Item Variant")
    var
        ItemJournalLine: Record "Item Journal Line";
        UOM: Record "Unit of Measure";
    begin
        // Create Unit of measure for assembly line (Required for RU tests, where "Unit of Measure Mandatory" is true)
        LibraryInventory.CreateUnitOfMeasureCode(UOM);

        CreateMandatoryVariant(ParentItem, ParentItemVariant);
        ParentItem.Validate("Base Unit of Measure", UOM.Code);
        ParentItem.Modify();

        LibraryAssembly.SetupAssemblyItem(
          ChildItem, ChildItem."Costing Method"::Standard, ChildItem."Costing Method"::Standard, ChildItem."Replenishment System"::Assembly, '', false, 5, 5, 5, 5);

        ChildItem.Validate("Variant Mandatory if Exists", ChildItem."Variant Mandatory if Exists"::Yes);
        ChildItem.Validate("Base Unit of Measure", UOM.Code);
        ChildItem.Modify();

        LibraryInventory.CreateVariant(ChildItemVariant, ChildItem);

        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, '',
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ChildItem."No.", 100);
        ItemJournalLine.Validate("Variant Code", ChildItemVariant.Code);
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; No: Code[20]; Receive: Boolean; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, No);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, Receive, Invoice);
    end;

    local procedure PostSalesDocument(DocumentType: Enum "Sales Document Type"; No: Code[20]; Ship: Boolean; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, No);
        LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
    end;

    local procedure FindPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; BuyfromVendorNo: Code[20])
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyfromVendorNo);
        PurchaseHeader.FindFirst();
    end;

    local procedure MakeSupplyOrdersActiveOrder(DemandOrderNo: Code[20])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.FindFirst();
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::" ");
    end;

    local procedure MakeSupplyOrders(var RequisitionLine: Record "Requisition Line"; MakeOrders: Option; CreateProductionOrder: Enum "Planning Create Prod. Order")
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        GetManufacturingUserTemplate(ManufacturingUserTemplate, MakeOrders, CreateProductionOrder);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure GetManufacturingUserTemplate(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option; CreateProductionOrder: Enum "Planning Create Prod. Order")
    begin
        if not ManufacturingUserTemplate.Get(UserId) then
            LibraryPlanning.CreateManufUserTemplate(
              ManufacturingUserTemplate, CopyStr(UserId, 1, 50), MakeOrder, ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders",
              CreateProductionOrder, ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
    end;

    local procedure VerifyPurchaseLinesCreatedFromSalesLines(DocNo: Text; var SalesLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetFilter("Document No.", DocNo);

        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");

        Assert.AreEqual(SalesLine.Count, PurchaseLine.Count, RecordCountErr);

        PurchaseLine.FindSet();
        SalesLine.FindSet();
        repeat
            Assert.AreEqual(
                PurchaseLine."No.",
                SalesLine."No.",
                StrSubstNo(ValueMustBeEqualErr, PurchaseLine.FieldCaption("No."), SalesLine."No.", PurchaseLine.TableCaption()));
            Assert.AreEqual(
                PurchaseLine.Quantity,
                SalesLine.Quantity,
                StrSubstNo(ValueMustBeEqualErr, PurchaseLine.FieldCaption(Quantity), SalesLine.Quantity, PurchaseLine.TableCaption()));
            SalesLine.Next();
        until PurchaseLine.Next() = 0;
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure EmptyMessageHandler(Message: Text[1024])
    begin
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
        LibraryVariableStorage.Dequeue(DequeueVariable);
        Reply := DequeueVariable;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    var
        GetReceiptLines: Variant;
        Quantity: Variant;
        GetReceiptLines2: Boolean;
    begin
        LibraryVariableStorage.Dequeue(GetReceiptLines);
        GetReceiptLines2 := GetReceiptLines;
        LibraryVariableStorage.Dequeue(Quantity);
        if GetReceiptLines2 then
            ItemChargeAssignmentPurch.GetReceiptLines.Invoke();
        ItemChargeAssignmentPurch."Qty. to Assign".SetValue(Quantity);
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchPageWithSuggestHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.GetReceiptLines.Invoke();
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        OptionCount: Variant;
    begin
        LibraryVariableStorage.Dequeue(OptionCount);  // Dequeue variable.
        Choice := OptionCount;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinePageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchReceiptLinePageHandler(var PurchReceiptLines: TestPage "Purch. Receipt Lines")
    var
        PostedDocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostedDocumentNo);
        PurchReceiptLines.FILTER.SetFilter("Document No.", PostedDocumentNo);
        PurchReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPerItemEntryModalPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Total Quantity".DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableItemLedgEntriesModalPageHandler(var AvailableItemLedgEntries: TestPage "Available - Item Ledg. Entries")
    begin
        AvailableItemLedgEntries.Reserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        ItemTrackingMode: Option AssignLotNo,UpdateQuantityToInvoice;
        Quantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingMode::UpdateQuantityToInvoice:
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    Quantity := DequeueVariable;
                    ItemTrackingLines."Qty. to Invoice (Base)".SetValue(Quantity);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchRetOrderPageHandler(var BatchPostPurchRetOrders: TestRequestPage "Batch Post Purch. Ret. Orders")
    begin
        BatchPostPurchRetOrders.Ship.SetValue(true);
        BatchPostPurchRetOrders.Invoice.SetValue(true);
        BatchPostPurchRetOrders.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListModalPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PurchOrderFromSalesOrderModalPageHandlerSetVendorsOnLine(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        PurchOrderFromSalesOrder.Vendor.SetValue(LibraryVariableStorage.DequeueText());
        PurchOrderFromSalesOrder.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PurchOrderFromSalesOrderModalPageHandler(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        PurchOrderFromSalesOrder.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrdersPage: Page "Make Supply Orders"; var Response: Action)
    begin
        Response := Action::LookupOK;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInventoryPutAwayPickHandler(var CreateInvtPutAwayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutAwayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutAwayPickMvmt.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnDeleteAfterPostingOnBeforeDeleteSalesHeader', '', false, false)]
    local procedure CheckWarehouseRequestDeletedBeforeSalesOrder(var SalesHeader: Record "Sales Header")
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetSourceFilter(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        Assert.RecordIsEmpty(WarehouseRequest);

        Assert.IsTrue(SalesHeader.Find(), '');
    end;
}
