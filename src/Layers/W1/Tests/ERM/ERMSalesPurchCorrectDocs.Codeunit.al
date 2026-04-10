codeunit 134398 "ERM Sales/Purch. Correct. Docs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Corrective Documents]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;
        QtyErr: Label '%1 is wrong';
        CancelQtyErr: Label '%1 is wrong after cancel';
        CannotCancelSalesInvInventoryPeriodClosedErr: Label 'You cannot cancel this posted sales invoice because the posting inventory period is already closed.';
        CannotCancelPurchInvInventoryPeriodClosedErr: Label 'You cannot cancel this posted purchase invoice because the posting inventory period is already closed.';
        SalesBlockedGLAccountErr: Label 'You cannot correct this posted sales invoice because G/L Account %1 is blocked.';
        PurchaseBlockedGLAccountErr: Label 'You cannot correct this posted purchase invoice because G/L Account %1 is blocked.';
        WMSLocationCancelCorrectErr: Label 'You cannot cancel or correct this posted sales invoice because Warehouse Receive is required';
        NoShouldNotBeBlankErr: Label 'No. should not be blank.';
        TotalToDeferErr: Label 'The sum of the deferred amounts must be equal to the amount in the Amount to Defer field.';
        CancelPostedPurchaseInvoiceQst: Label 'This invoice was posted from a purchase order. To cancel it, a purchase credit memo will be created and posted. The quantities from the original purchase order will be restored, provided the purchase order still exists.\ \Do you want to continue?';
        CancelPostedSalesInvoiceQst: Label 'This invoice was posted from a sales order. To cancel it, a sales credit memo will be created and posted. The quantities from the original sales order will be restored, provided the sales order still exists.\ \Do you want to continue?';

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithLinePointingRoundingAccount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 224605] Cassie can correct posted sales invoice with line pointing to customer's rounding G/L Account.
        Initialize();

        // [GIVEN] Invoice rounding is enabled in sales setup
        LibrarySales.SetInvoiceRounding(true);

        // [GIVEN] Posted invoice with line pointed to customer's rounding G/L Account.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLinesWithRoundingGLAcccount(SalesHeader, Customer);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.Get(DocumentNo);

        // [WHEN] Correct posted invoice
        Clear(SalesHeader);
        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeader);

        // [THEN] System created new invoice with two lines copied from posted invoice
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.RecordCount(SalesLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithLinePointingRoundingAccount()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 224605] Cassie can correct posted zero balanced purchase invoice
        Initialize();

        // [GIVEN] Cassie can correct posted purchase invoice with line pointing to customer's rounding G/L Account.
        LibraryPurchase.SetInvoiceRounding(true);

        // [GIVEN] Posted invoice with line pointed to vendor's rounding G/L Account.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreatePurchaseLinesWithRoundingGLAcccount(PurchaseHeader, Vendor);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(DocumentNo);

        // [WHEN] Correct posted invoice
        Clear(PurchaseHeader);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeader);

        // [THEN] System created new invoice with two lines copied from posted invoice
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithoutDiscountPosting()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 299514] Cassie can correct posted sales invoice when "Sales Line Disc. Account" is not set and "Discount Posting" = "No Discounts" in setup
        Initialize();

        LibrarySales.SetDiscountPosting(SalesReceivablesSetup."Discount Posting"::"No Discounts");

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        CleanSalesLineDiscAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.Get(DocumentNo);

        Clear(SalesHeader);
        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeader);

        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithoutDiscountPosting()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 299514] Cassie can correct posted purchase invoice when "Purch. Line Disc. Account" is not set and "Discount Posting" = "No Discounts" in setup
        Initialize();

        LibraryPurchase.SetDiscountPosting(PurchasesPayablesSetup."Discount Posting"::"No Discounts");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
        CleanPurchLineDiscAccountOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(DocumentNo);

        Clear(PurchaseHeader);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeader);

        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Invoice);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCancelSalesInvoiceWithServiceItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 322909] Cassie can cancel Posted Sales Invoice with Item of Type Service when COGS account is empty in General Posting Setup.
        Initialize();

        CreateSalesHeaderWithItemWithType(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Item.Type::Service);
        CleanCOGSAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCancelSalesInvoiceWithNonInventoryItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 322909] Cassie can cancel Posted Sales Invoice with Item of Type Non-Inventory when COGS account is empty in General Posting Setup.
        Initialize();

        CreateSalesHeaderWithItemWithType(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Item.Type::"Non-Inventory");
        CleanCOGSAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CantCancelSalesInvoiceWithInventoryItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 322909] Cassie can't cancel Posted Sales Invoice with Item of Type Inventory when COGS account is empty in General Posting Setup.
        Initialize();

        CreateSalesHeaderWithItemWithType(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Item.Type::Inventory);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CleanCOGSAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);

        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
            LibraryErrorMessage.GetMissingAccountErrorMessage(
                GeneralPostingSetup.FieldCaption("COGS Account"),
                GeneralPostingSetup));

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelMadeFromOrderSalesInvoiceWithOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PstdDocNo: Code[20];
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCANARIO] Partially ship and invoice order, then cancel posted invoice
        Initialize();

        // [GIVEN] Order, "Quantity" = 9, "Qty. to Ship" = 7, "Qty. to Invoice" = 5
        CreateSalesOrder(SalesHeader, SalesLine);
        // [GIVEN] Posted invoice
        PstdDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PstdDocNo);
        SalesLine.Find();
        Assert.AreEqual(4, SalesLine."Qty. to Invoice", StrSubstNo(QtyErr, SalesLine.FieldName("Quantity Invoiced")));
        Assert.AreEqual(5, SalesLine."Quantity Invoiced", StrSubstNo(QtyErr, SalesLine.FieldName("Quantity Invoiced")));
        Assert.AreEqual(2, SalesLine."Qty. Shipped Not Invoiced", StrSubstNo(QtyErr, SalesLine.FieldName("Qty. Shipped Not Invoiced")));
        // [WHEN] Cancel posted invoice
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        // [THEN] "Qty. to Invoice" = 9, "Quantity Invoiced" = 0, "Qty. Shipped Not Invoiced" = 2
        SalesLine.Find();
        Assert.AreEqual(9, SalesLine."Qty. to Invoice", StrSubstNo(CancelQtyErr, SalesLine.FieldName("Quantity Invoiced")));
        Assert.AreEqual(0, SalesLine."Quantity Invoiced", StrSubstNo(CancelQtyErr, SalesLine.FieldName("Quantity Invoiced")));
        Assert.AreEqual(2, SalesLine."Qty. Shipped Not Invoiced", StrSubstNo(CancelQtyErr, SalesLine.FieldName("Qty. Shipped Not Invoiced")));
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure CancelMadeFromShipmentSalesInvoiceWithOrder()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PstdDocNo: Code[20];
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCANARIO] Partially ship order, create invoice from shipment lines, post it, then cancel posted invoice
        Initialize();

        // [GIVEN] Order, "Quantity" = 9, "Qty. to Ship" = 7
        CreateSalesOrder(SalesHeader[1], SalesLine[1]);
        // [GIVEN] Posted shipment
        LibrarySales.PostSalesDocument(SalesHeader[1], true, false);
        // [GIVEN] Posted invoice from shipment
        CreateSalesInvoiceFromShipment(SalesHeader[2], SalesLine[2], SalesHeader[1]."Sell-to Customer No.");
        PstdDocNo := LibrarySales.PostSalesDocument(SalesHeader[2], true, true);
        SalesLine[1].Find();
        Assert.AreEqual(2, SalesLine[1]."Qty. to Invoice", StrSubstNo(QtyErr, SalesLine[1].FieldName("Quantity Invoiced")));
        Assert.AreEqual(7, SalesLine[1]."Quantity Invoiced", StrSubstNo(QtyErr, SalesLine[1].FieldName("Quantity Invoiced")));
        Assert.AreEqual(0, SalesLine[1]."Qty. Shipped Not Invoiced", StrSubstNo(QtyErr, SalesLine[1].FieldName("Qty. Shipped Not Invoiced")));
        // [WHEN] Cancel posted invoice
        SalesInvoiceHeader.Get(PstdDocNo);
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        // [THEN] "Qty. to Invoice" = 9, "Quantity Invoiced" = 0, "Qty. Shipped Not Invoiced" = 0
        SalesLine[1].Find();
        Assert.AreEqual(9, SalesLine[1]."Qty. to Invoice", StrSubstNo(CancelQtyErr, SalesLine[1].FieldName("Quantity Invoiced")));
        Assert.AreEqual(0, SalesLine[1]."Quantity Invoiced", StrSubstNo(CancelQtyErr, SalesLine[1].FieldName("Quantity Invoiced")));
        Assert.AreEqual(0, SalesLine[1]."Qty. Shipped Not Invoiced", StrSubstNo(CancelQtyErr, SalesLine[1].FieldName("Qty. Shipped Not Invoiced")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelMadeFromOrderPurchaseInvoiceWithOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PstdDocNo: Code[20];
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase]
        // [SCANARIO] Partially receive and invoice order, then cancel posted invoice
        Initialize();

        // [GIVEN] Order, "Quantity" = 9, "Qty. to Receive" = 7, "Qty. to Invoice" = 5
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [GIVEN] Posted invoice
        PstdDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(PstdDocNo);
        PurchaseLine.Find();
        Assert.AreEqual(4, PurchaseLine."Qty. to Invoice", StrSubstNo(QtyErr, PurchaseLine.FieldName("Qty. to Invoice")));
        Assert.AreEqual(5, PurchaseLine."Quantity Invoiced", StrSubstNo(QtyErr, PurchaseLine.FieldName("Quantity Invoiced")));
        Assert.AreEqual(2, PurchaseLine."Qty. Rcd. Not Invoiced", StrSubstNo(QtyErr, PurchaseLine.FieldName("Qty. Rcd. Not Invoiced")));
        // [WHEN] Cancel posted invoice
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        // [THEN] "Qty. to Invoice" = 9, "Quantity Invoiced" = 0, "Qty. Rcd. Not Invoiced" = 7
        PurchaseLine.Find();
        Assert.AreEqual(9, PurchaseLine."Qty. to Invoice", StrSubstNo(CancelQtyErr, PurchaseLine.FieldName("Qty. to Invoice")));
        Assert.AreEqual(0, PurchaseLine."Quantity Invoiced", StrSubstNo(CancelQtyErr, PurchaseLine.FieldName("Quantity Invoiced")));
        Assert.AreEqual(2, PurchaseLine."Qty. Rcd. Not Invoiced", StrSubstNo(CancelQtyErr, PurchaseLine.FieldName("Qty. Rcd. Not Invoiced")));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure UndoShipmentAfterCancelMadeFromOrderSalesInvoiceWithOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        RevertedSalesShipmentLine: Record "Sales Shipment Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        PstdDocNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCANARIO] Partially ship and invoice order, then cancel posted invoice and undo shipment
        Initialize();

        // [GIVEN] Order, "Quantity" = 9, "Qty. to Ship" = 7, "Qty. to Invoice" = 5
        CreateSalesOrder(SalesHeader, SalesLine);
        // [GIVEN] Posted invoice
        PstdDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PstdDocNo);
        // [GIVEN] Cancel posted invoice
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        // [WHEN] Undo shipment
        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentLine.FindLast();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
        // [THEN] "Qty. to Invoice" = 9, "Qty. to Ship" = 9, "Quantity Invoiced" = 0, "Quantity Shipped" = 0, "Qty. Shipped Not Invoiced" = 0
        SalesLine.Find();
        VerifySalesOrderLineQuantitiesAfterUndoShipment(SalesLine, 9);
        // [THEN] Opposite shipment line inserted
        RevertedSalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        RevertedSalesShipmentLine.FindLast();
        VerifyRevertedShipmentLine(SalesShipmentLine, RevertedSalesShipmentLine);
        // [THEN] Revert Item Ledger Entry is created, Quantity = 2
        VerifyRevertedItemLedgerEntry(Database::"Sales Shipment Line", RevertedSalesShipmentLine."Document No.", RevertedSalesShipmentLine."Line No.", 2);

        // [THEN] Post full document and verify after Undo
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        PostAndVerifySalesDocumentAfterUndo(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GetShipmentLinesHandler,ConfirmHandlerYes')]
    procedure UndoShipmentAfterCancelMadeFromShipmentSalesInvoiceWithOrder()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        RevertedSalesShipmentLine: Record "Sales Shipment Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PstdDocNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCANARIO] Fully ship and invoice order, then cancel posted invoice and undo shipment
        Initialize();

        CreateSalesOrder(SalesHeader[1], SalesLine[1]);
        SalesLine[1].Validate("Qty. to Ship", 9);
        SalesLine[1].Modify();
        // [GIVEN] Posted shipment
        LibrarySales.PostSalesDocument(SalesHeader[1], true, false);
        // [GIVEN] Posted invoice from shipment
        CreateSalesInvoiceFromShipment(SalesHeader[2], SalesLine[2], SalesHeader[1]."Sell-to Customer No.");
        PstdDocNo := LibrarySales.PostSalesDocument(SalesHeader[2], true, true);
        // [GIVEN] Cancelled posted invoice
        SalesInvoiceHeader.Get(PstdDocNo);
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        // [WHEN] Undo shipment
        SalesShipmentLine.SetRange("Order No.", SalesHeader[1]."No.");
        SalesShipmentLine.FindFirst();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
        // [THEN] "Qty. to Invoice" = 9, "Qty. to Ship" = 9, "Quantity Invoiced" = 0, "Quantity Shipped" = 0, "Qty. Shipped Not Invoiced" = 0
        SalesLine[1].Find();
        VerifySalesOrderLineQuantitiesAfterUndoShipment(SalesLine[1], 9);
        // [THEN] Opposite shipment line inserted
        RevertedSalesShipmentLine.SetRange("Order No.", SalesHeader[1]."No.");
        RevertedSalesShipmentLine.FindLast();
        VerifyRevertedShipmentLine(SalesShipmentLine, RevertedSalesShipmentLine);
        // [THEN] No item ledger entry is created
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.SetRange("Document No.", RevertedSalesShipmentLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", RevertedSalesShipmentLine."Line No.");
        Assert.RecordCount(ItemLedgerEntry, 0);

        // [THEN] Post full document and verify after Undo
        SalesHeader[1].Get(SalesHeader[1]."Document Type", SalesHeader[1]."No.");
        PostAndVerifySalesDocumentAfterUndo(SalesHeader[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure UndoReceiveAfterCancelMadeFromOrderPurchaseInvoiceWithOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        RevertedPurchRcptLine: Record "Purch. Rcpt. Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PstdDocNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCANARIO] Partially receive and invoice order, then cancel posted invoice
        Initialize();

        // [GIVEN] Order, "Quantity" = 9, "Qty. to Receive" = 7, "Qty. to Invoice" = 5
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [GIVEN] Posted invoice
        PstdDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(PstdDocNo);
        // [GIVEN] Cancelled posted invoice
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        // [WHEN] Undo receive
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.FindLast();
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
        // [THEN] "Qty. to Invoice" = 9, "Qty. to Receive" = 9, "Quantity Invoiced" = 0, "Quantity Received" = 0, "Qty. Received Not Invoiced" = 0
        PurchaseLine.Find();
        VerifyPurchaseOrderLineQuantitiesAfterUndoReceive(PurchaseLine, 9);
        // [THEN] Opposite receive line inserted
        RevertedPurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        RevertedPurchRcptLine.FindLast();
        VerifyRevertedReceiptLine(PurchRcptLine, RevertedPurchRcptLine);
        // [THEN] Revert Item Ledger Entry is created, Quantity = 2
        VerifyRevertedItemLedgerEntry(Database::"Purch. Rcpt. Line", RevertedPurchRcptLine."Document No.", RevertedPurchRcptLine."Line No.", -2);

        // [THEN] Post full document and verify after Undo
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PostAndVerifyPurchaseDocumentAfterUndo(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingLinesPageHandler')]
    procedure ItemTrackingUndoReceiveAfterCancelMadeFromOrderPurchaseInvoiceWithOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        RevertedPurchRcptLine: Record "Purch. Rcpt. Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PstdDocNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCANARIO] Partially receive and invoice order, then cancel posted invoice
        Initialize();

        // [GIVEN] Order, "Quantity" = 9, "Qty. to Receive" = 7, "Qty. to Invoice" = 5
        CreatePurchaseOrderWithTrackedItem(PurchaseHeader, PurchaseLine);
        // [GIVEN] Posted invoice
        PstdDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(PstdDocNo);
        // [GIVEN] Cancelled posted invoice
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        // [WHEN] Undo receive
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.FindLast();
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
        // [THEN] "Qty. to Invoice" = 9, "Qty. to Receive" = 9, "Quantity Invoiced" = 0, "Quantity Received" = 0, "Qty. Received Not Invoiced" = 0
        PurchaseLine.Find();
        VerifyPurchaseOrderLineQuantitiesAfterUndoReceive(PurchaseLine, 9);
        // [THEN] Opposite receive line inserted
        RevertedPurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        RevertedPurchRcptLine.FindLast();
        VerifyRevertedReceiptLine(PurchRcptLine, RevertedPurchRcptLine);
        // [THEN] Revert Item Ledger Entry is created, Quantity = 2
        VerifyRevertedItemLedgerEntry(Database::"Purch. Rcpt. Line", RevertedPurchRcptLine."Document No.", RevertedPurchRcptLine."Line No.", -2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithGLAccountWithoutSalesAccountInGenPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 337408] Cassie can cancel Posted Sales Invoice with G/L Account that does not have "Sales Account" in General Posting Setup.
        Initialize();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Modify(true);
        CleanSalesAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithGLAccountWithoutSalesCreditMemoAccountInGenPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 337408] Cassie can cancel Posted Sales Invoice with G/L Account that does not have "Sales Credit Memo Account" in General Posting Setup.
        Initialize();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Modify(true);
        CleanSalesCreditMemoAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithGLAccountWithoutSalesAccountInGenPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 337408] Cassie can cancel Posted Purchase Invoice with G/L Account that does not have "Sales Account" in General Posting Setup.
        Initialize();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        CleanPurchAccountOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithGLAccountWithoutSalesCreditMemoAccountInGenPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 337408] Cassie can cancel Posted Purchase Invoice with G/L Account that does not have "Sales Credit Memo Account" in General Posting Setup.
        Initialize();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        CleanPurchCreditMemoAccountOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelPurchaseInvoiceWithResource()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        CancelledDocument: Record "Cancelled Document";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Resource]
        // [SCENARIO 343833] Cancel posted purchase invoice with resource line
        Initialize();

        // [GIVEN] Posted purchase invoice with resource
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, '', LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Cancel posted purchase invoice with resource line
        PurchInvHeader.Get(DocNo);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [THEN] Posted purchase invoice cancelled via credit memo with resource line
        CancelledDocument.FindPurchCancelledInvoice(PurchInvHeader."No.");
        PurchCrMemoLine.SetRange("Document No.", CancelledDocument."Cancelled By Doc. No.");
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::Resource);
        PurchCrMemoLine.SetRange("No.", PurchaseLine."No.");
        Assert.RecordCount(PurchCrMemoLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelPurchaseInvoiceWithResourceAndEmptyDirectCostAppliedAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        CancelledDocument: Record "Cancelled Document";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocNo: Code[20];
        SavedDirecCostAppliedAcc: Code[20];
    begin
        // [FEATURE] [Purchase] [Resource]
        // [SCENARIO 343833] Cancel posted purchase invoice with resource line and empty "Direct Cost Appplied Account" in the "Gen. Posting Setup"
        Initialize();

        // [GIVEN] Posted purchase invoice with resource
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, '', LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] "Direct Cost Applied Account" is empty in the "Gen. Posting Setup"
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        SavedDirecCostAppliedAcc := GeneralPostingSetup."Direct Cost Applied Account";
        GeneralPostingSetup."Direct Cost Applied Account" := '';
        GeneralPostingSetup.Modify();
        Commit();

        // [WHEN] Cancel posted purchase invoice with resource line
        PurchInvHeader.Get(DocNo);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [THEN] Posted purchase invoice cancelled via credit memo with resource line
        CancelledDocument.FindPurchCancelledInvoice(PurchInvHeader."No.");
        PurchCrMemoLine.SetRange("Document No.", CancelledDocument."Cancelled By Doc. No.");
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::Resource);
        PurchCrMemoLine.SetRange("No.", PurchaseLine."No.");
        Assert.RecordCount(PurchCrMemoLine, 1);

        GeneralPostingSetup."Direct Cost Applied Account" := SavedDirecCostAppliedAcc;
        GeneralPostingSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelPurchaseInvoiceWithGLAccountAndEmptyDirectCostAppliedAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        CancelledDocument: Record "Cancelled Document";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocNo: Code[20];
        No: Code[20];
        SavedDirecCostAppliedAcc: Code[20];
    begin
        // [FEATURE] [Purchase] [Finance]
        // [SCENARIO 347253] Cancel posted purchase invoice with G/L Account line and empty "Direct Cost Appplied Account" in the "Gen. Posting Setup"
        Initialize();

        // [GIVEN] Posted purchase invoice with resource
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        No := LibraryERM.CreateGLAccountWithPurchSetup();
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", No, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] "Direct Cost Applied Account" is empty in the "Gen. Posting Setup"
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        SavedDirecCostAppliedAcc := GeneralPostingSetup."Direct Cost Applied Account";
        GeneralPostingSetup."Direct Cost Applied Account" := '';
        GeneralPostingSetup.Modify();
        Commit();

        // [WHEN] Cancel posted purchase invoice with resource line
        PurchInvHeader.Get(DocNo);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [THEN] Posted purchase invoice cancelled via credit memo with resource line
        CancelledDocument.FindPurchCancelledInvoice(PurchInvHeader."No.");
        PurchCrMemoLine.SetRange("Document No.", CancelledDocument."Cancelled By Doc. No.");
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::"G/L Account");
        PurchCrMemoLine.SetRange("No.", PurchaseLine."No.");
        Assert.RecordCount(PurchCrMemoLine, 1);

        GeneralPostingSetup."Direct Cost Applied Account" := SavedDirecCostAppliedAcc;
        GeneralPostingSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure UndoReceiveAfterCancelPurchaseInvoiceWithResource()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        RevertedPurchRcptLine: Record "Purch. Rcpt. Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PstdDocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Resource]
        // [SCANARIO 344832] Partially receive and invoice order, then cancel posted invoice and undo receive with resource
        Initialize();

        // [GIVEN] Order with resource, "Quantity" = 9, "Qty. to Receive" = 7, "Qty. to Invoice" = 5
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, '', 9);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Qty. to Receive", 7);
        PurchaseLine.Validate("Qty. to Invoice", 5);
        PurchaseLine.Modify(true);

        // [GIVEN] Posted invoice
        PstdDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(PstdDocNo);

        // [GIVEN] Cancelled posted invoice
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [WHEN] Undo receive
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.FindLast();
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] "Qty. to Invoice" = 9, "Qty. to Receive" = 9, "Quantity Invoiced" = 0, "Quantity Received" = 0, "Qty. Received Not Invoiced" = 0
        PurchaseLine.Find();
        VerifyPurchaseOrderLineQuantitiesAfterUndoReceive(PurchaseLine, 9);

        // [THEN] Opposite receive line inserted
        RevertedPurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        RevertedPurchRcptLine.FindLast();
        VerifyRevertedReceiptLine(PurchRcptLine, RevertedPurchRcptLine);

        // [THEN] Post full document and verify after Undo
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PostAndVerifyPurchaseDocumentAfterUndoWithResource(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure UndoShipmentAfterCancelSalesInvoiceWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        RevertedSalesShipmentLine: Record "Sales Shipment Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        PstdDocNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCANARIO 344832] Partially ship and invoice order, then cancel posted invoice and undo shipment with g/l account
        Initialize();

        // [GIVEN] Order, "Quantity" = 9, "Qty. to Ship" = 7, "Qty. to Invoice" = 5
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 9);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Validate("Qty. to Ship", 7);
        SalesLine.Validate("Qty. to Invoice", 5);
        SalesLine.Modify(true);

        // [GIVEN] Posted invoice
        PstdDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PstdDocNo);

        // [GIVEN] Cancelled posted invoice
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [WHEN] Undo shipment
        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentLine.FindLast();
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [THEN] "Qty. to Invoice" = 9, "Qty. to Ship" = 9, "Quantity Invoiced" = 0, "Quantity Shipped" = 0, "Qty. Shipped Not Invoiced" = 0
        SalesLine.Find();
        VerifySalesOrderLineQuantitiesAfterUndoShipment(SalesLine, 9);

        // [THEN] Opposite shipment line inserted
        RevertedSalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        RevertedSalesShipmentLine.FindLast();
        VerifyRevertedShipmentLine(SalesShipmentLine, RevertedSalesShipmentLine);

        // [THEN] Post full document and verify after Undo
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        PostAndVerifySalesDocumentAfterUndoWithGLAccount(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_GLAccount_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice with G/L Account only when Inventory Period is closed
        Initialize();

        InventoryPeriod.DeleteAll();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate() + 1, true);

        Commit();

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_GLAccount_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice with G/L Account only when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate() + 1, false);

        Commit();

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_Item_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item when Inventory Period is closed
        Initialize();

        InventoryPeriod.DeleteAll();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate() + 1, true);

        Commit();

        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        Assert.ExpectedError(CannotCancelSalesInvInventoryPeriodClosedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_Item_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item only when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate() + 1, false);

        Commit();

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_ItemCharge_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item Charge only when Inventory Period is closed
        Initialize();

        InventoryPeriod.DeleteAll();

        CreateSalesHeaderWithItemAndChargeItem(SalesHeader);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate() + 1, true);

        Commit();

        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        Assert.ExpectedError(CannotCancelSalesInvInventoryPeriodClosedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_ItemCharge_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item Charge when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        CreateSalesHeaderWithItemAndChargeItem(SalesHeader);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate() + 1, false);

        Commit();

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_GLAccount_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice with G/L Account only when Inventory Period is closed
        Initialize();

        InventoryPeriod.DeleteAll();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CreateInventoryPeriod(WorkDate() + 1, true);

        Commit();

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_GLAccount_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice with G/L Account only when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CreateInventoryPeriod(WorkDate() + 1, false);

        Commit();

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_Item_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item when Inventory Period is closed
        Initialize();

        InventoryPeriod.DeleteAll();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CreateInventoryPeriod(WorkDate() + 1, true);

        Commit();

        asserterror CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);

        Assert.ExpectedError(CannotCancelPurchInvInventoryPeriodClosedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_Item_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CreateInventoryPeriod(WorkDate() + 1, false);

        Commit();

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_ItemCharge_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item Charge when Inventory Period is closed
        Initialize();
        InitializeSetupData();

        InventoryPeriod.DeleteAll();

        CreatePurchaseHeaderWithItemAndChargeItem(PurchaseHeader);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        UpdateGLAccountsInGeneralPostingSetupFromPurchaseInvoiceLine(PurchInvHeader);

        CreateInventoryPeriod(WorkDate() + 1, true);

        Commit();

        asserterror CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);

        Assert.ExpectedError(CannotCancelPurchInvInventoryPeriodClosedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_ItemCharge_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item Charge when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        CreatePurchaseHeaderWithItemAndChargeItem(PurchaseHeader);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        UpdateGLAccountsInGeneralPostingSetupFromPurchaseInvoiceLine(PurchInvHeader);

        CreateInventoryPeriod(WorkDate() + 1, false);

        Commit();

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithAllDiscountPostingAndWithoutAccountInSetup()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 348811] Cassie can correct posted sales invoice when "Sales Line Disc. Account" is not set and "Discount Posting" = "All Discounts" in setup
        Initialize();

        LibrarySales.SetDiscountPosting(SalesReceivablesSetup."Discount Posting"::"All Discounts");

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        CleanSalesLineDiscAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.Get(DocumentNo);

        Clear(SalesHeader);
        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeader);

        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);

        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesReceivablesSetup.RecordId);
        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithAllDiscountPostingAndWithoutAccountInSetup()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 348811] Cassie can correct posted purchase invoice when "Purch. Line Disc. Account" is not set and "Discount Posting" = "All Discounts" in setup
        Initialize();

        LibraryPurchase.SetDiscountPosting(PurchasesPayablesSetup."Discount Posting"::"All Discounts");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
        CleanPurchLineDiscAccountOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(DocumentNo);

        Clear(PurchaseHeader);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeader);

        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Invoice);

        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchasesPayablesSetup.RecordId);
        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithLineDiscountPostingAndWithoutAccountInSetup()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 348811] Cassie can correct posted sales invoice when "Sales Line Disc. Account" is not set and "Discount Posting" = "Line Discounts" in setup
        Initialize();

        LibrarySales.SetDiscountPosting(SalesReceivablesSetup."Discount Posting"::"Line Discounts");

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        CleanSalesLineDiscAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.Get(DocumentNo);

        Clear(SalesHeader);
        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeader);

        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);

        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesReceivablesSetup.RecordId);
        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithLineDiscountPostingAndWithoutAccountInSetup()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 348811] Cassie can correct posted purchase invoice when "Purch. Line Disc. Account" is not set and "Discount Posting" = "Line Discounts" in setup
        Initialize();

        LibraryPurchase.SetDiscountPosting(PurchasesPayablesSetup."Discount Posting"::"Line Discounts");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
        CleanPurchLineDiscAccountOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(DocumentNo);

        Clear(PurchaseHeader);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeader);

        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Invoice);

        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchasesPayablesSetup.RecordId);
        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithAllDiscountPostingAndWithBlockedAccountInSetup()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 348811] Cassie can't correct posted sales invoice when "Sales Line Disc. Account" is blocked and "Discount Posting" = "All Discounts" in setup
        Initialize();

        LibrarySales.SetDiscountPosting(SalesReceivablesSetup."Discount Posting"::"All Discounts");

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(1, 10));
        SalesLine.Modify(true);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SetSalesLineDiscAccountBlockedOnGenPostingSetup(SalesLine, GeneralPostingSetup);

        SalesInvoiceHeader.Get(DocumentNo);

        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);

        Assert.ExpectedError(StrSubstNo(SalesBlockedGLAccountErr, GeneralPostingSetup."Sales Line Disc. Account"));
        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesReceivablesSetup.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithAllDiscountPostingAndWithBlockedAccountInSetup()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 348811] Cassie can't correct posted purchase invoice when "Purch. Line Disc. Account" is blocked and "Discount Posting" = "All Discounts" in setup
        Initialize();

        LibraryPurchase.SetDiscountPosting(PurchasesPayablesSetup."Discount Posting"::"All Discounts");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(1, 10));
        PurchaseLine.Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        SetPurchLineDiscAccountBlockedOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);

        PurchInvHeader.Get(DocumentNo);

        asserterror CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);

        Assert.ExpectedError(StrSubstNo(PurchaseBlockedGLAccountErr, GeneralPostingSetup."Purch. Line Disc. Account"));
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchasesPayablesSetup.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithLineDiscountPostingAndWithBlockedAccountInSetup()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 348811] Cassie can't correct posted sales invoice when "Sales Line Disc. Account" is blocked and "Discount Posting" = "All Discounts" in setup
        Initialize();

        LibrarySales.SetDiscountPosting(SalesReceivablesSetup."Discount Posting"::"All Discounts");

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(1, 10));
        SalesLine.Modify(true);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SetSalesLineDiscAccountBlockedOnGenPostingSetup(SalesLine, GeneralPostingSetup);

        SalesInvoiceHeader.Get(DocumentNo);

        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);

        Assert.ExpectedError(StrSubstNo(SalesBlockedGLAccountErr, GeneralPostingSetup."Sales Line Disc. Account"));
        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesReceivablesSetup.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithLineDiscountPostingAndWithBlockedAccountInSetup()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 348811] Cassie can't correct posted purchase invoice when "Purch. Line Disc. Account" is blocked and "Discount Posting" = "All Discounts" in setup
        Initialize();

        LibraryPurchase.SetDiscountPosting(PurchasesPayablesSetup."Discount Posting"::"All Discounts");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(1, 10));
        PurchaseLine.Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        SetPurchLineDiscAccountBlockedOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);

        PurchInvHeader.Get(DocumentNo);

        asserterror CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);

        Assert.ExpectedError(StrSubstNo(PurchaseBlockedGLAccountErr, GeneralPostingSetup."Purch. Line Disc. Account"));
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchasesPayablesSetup.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithAllDiscountPostingAndWithBlockedAccountInSetupAndLineDiscountPctIsZero()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 393882] Cassie can correct posted sales invoice when "Sales Line Disc. Account" is blocked and "Discount Posting" = "All Discounts" in setup and Line Discount % = 0 in document line
        Initialize();

        LibrarySales.SetDiscountPosting(SalesReceivablesSetup."Discount Posting"::"All Discounts");

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Validate("Line Discount %", 0);
        SalesLine.Modify(true);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SetSalesLineDiscAccountBlockedOnGenPostingSetup(SalesLine, GeneralPostingSetup);
        Commit();

        SalesInvoiceHeader.Get(DocumentNo);

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);

        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesReceivablesSetup.RecordId);
        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithAllDiscountPostingAndWithBlockedAccountInSetupAndLineDiscountPctIsZero()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 393882] Cassie can correct posted purchase invoice when "Purch. Line Disc. Account" is blocked and "Discount Posting" = "All Discounts" in setup and Line Discount % = 0 in document line
        Initialize();

        LibraryPurchase.SetDiscountPosting(PurchasesPayablesSetup."Discount Posting"::"All Discounts");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Line Discount %", 0);
        PurchaseLine.Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        SetPurchLineDiscAccountBlockedOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);
        Commit();

        PurchInvHeader.Get(DocumentNo);

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);

        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchasesPayablesSetup.RecordId);
        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithLineDiscountPostingAndWithBlockedAccountInSetupAndLineDiscountPctIsZero()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 393882] Cassie can correct posted sales invoice when "Sales Line Disc. Account" is blocked and "Discount Posting" = "All Discounts" in setup and Line Discount % = 0 in document line
        Initialize();

        LibrarySales.SetDiscountPosting(SalesReceivablesSetup."Discount Posting"::"All Discounts");

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Validate("Line Discount %", 0);
        SalesLine.Modify(true);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SetSalesLineDiscAccountBlockedOnGenPostingSetup(SalesLine, GeneralPostingSetup);
        Commit();

        SalesInvoiceHeader.Get(DocumentNo);

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);

        LibraryNotificationMgt.RecallNotificationsForRecordID(SalesReceivablesSetup.RecordId);
        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithLineDiscountPostingAndWithBlockedAccountInSetupAndLineDiscountPctIsZero()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 393882] Cassie can correct posted purchase invoice when "Purch. Line Disc. Account" is blocked and "Discount Posting" = "All Discounts" in setup and Line Discount % = 0 in document line
        Initialize();

        LibraryPurchase.SetDiscountPosting(PurchasesPayablesSetup."Discount Posting"::"All Discounts");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Line Discount %", 0);
        PurchaseLine.Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        SetPurchLineDiscAccountBlockedOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);
        Commit();

        PurchInvHeader.Get(DocumentNo);

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);

        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchasesPayablesSetup.RecordId);
        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPostedPurchInvoiceWithZeroQuantityItemCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Order] 
        // [SCENARIO 417381] It is be possible to correct posted invoice with zero quantity item charge
        Initialize();

        // [GIVEN] Create purchase order with item "I" line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
        // [GIVEN] Create purchase line for item charge "IC", unit cost = 1000 and quantity to receipt/invoice = 0
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Validate("Qty. to Invoice", 0);
        PurchaseLine.Modify(true);

        // [GIVEN] Post purchase order
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Run "Correct" action for posted invoice
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [THEN] Purchase order corrected
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Quantity Invoiced", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPostedSalesInvoiceWithZeroQuantityItemCharge()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Order] 
        // [SCENARIO 417381] It is be possible to correct posted invoice with zero quantity item charge
        Initialize();

        // [GIVEN] Create sales order with item "I" line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        // [GIVEN] Create sales line for item charge "IC", unit price = 1000 and quantity to ship/invoice = 0
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Validate("Qty. to Invoice", 0);
        SalesLine.Modify(true);

        // [GIVEN] Post sales order
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Run "Correct" action for posted invoice
        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Sales order corrected
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Quantity Invoiced", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithWMSLocationUT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Location: Record Location;
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";

    begin
        // [SCENARIO 417759] Correct posted sales invoice with location has "Directed Put-away and Pick"
        Initialize();

        // [GIVEN] Posted sales invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Validate("Location Code", LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location));
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Mock WMS location
        Location."Directed Put-away and Pick" := true;
        Location.Modify();

        // [WHEN] Run check procedure on "Correct" action for posted invoice
        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);

        // [THEN] Error message is appeared
        Assert.ExpectedError(WMSLocationCancelCorrectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoicewhenItemIsNonInventoriableType()
    var
        VatPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 492364] When tried to correct a posted purchase invoice, system showed "Direct Cost Applied Account must have a value".
        Initialize();

        // [GIVEN] Create VAT Posting Setup.
        CreateVATPostingSetup(VatPostingSetup);

        // [GIVEN] Create General Posting Setup.
        CreateGeneralPostingSetup(GeneralPostingSetup, VatPostingSetup);

        // [GIVEN] Create Item & Vendor.
        CreateItemAndVendor(Item, Vendor, GeneralPostingSetup, VatPostingSetup);

        // [GIVEN] Create Purchase Order.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, Vendor);

        // [GIVEN] Post Purchase Order.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Run "Correct" action for posted invoice.
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        PurchCrMemoHdr.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
        PurchCrMemoHdr.FindFirst();

        // [VERIFY] Direct cost Applied Account is not involved when it's service or non-inventory.
        Assert.AreNotEqual('', PurchCrMemoHdr."No.", NoShouldNotBeBlankErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoicewhenItemIsNonInventoriableTypeWithLocation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 492810] Error when trying to Correct Posted Purchase Invoice for a Non-Inventory Type item:  "Warehouse Shipment is required for Line No. 
        Initialize();

        // [GIVEN] Create Purchase Order with Item Type Service and Non Inventory.
        CreatePurchaseOrderWithItemTypeServiceAndNonInventory(PurchaseHeader);

        // [GIVEN] Post Purchase Order.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Run "Correct" action for posted invoice.
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        PurchCrMemoHdr.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
        PurchCrMemoHdr.FindFirst();

        // [VERIFY] Warehouse Shipment is not required when Item Type service or non-inventory & Location have "Directed Put-away and Pick".
        Assert.AreNotEqual('', PurchCrMemoHdr."No.", NoShouldNotBeBlankErr);
    end;

    [Test]
    procedure SalesInvoiceShouldNotPostWithIncorrectDeferralScheduleValues()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        GLAccount: Record "G/L Account";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        // [SCENARIO 504969] Incorrect Deferral Schedule Values are wrongly kept if you refresh the page or close the browser.
        Initialize();

        // [GIVEN] Create Deferral Template with "Calculation Method" = "User-Defined","Start Date" ="Beginning of Next Calendar Year" and No. of Periods is 4.
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"User-Defined",
          DeferralTemplate."Start Date"::"Beginning of Next Calendar Year", LibraryRandom.RandIntInRange(4, 4));

        // [GIVEN] Create Sales Invoice withG/L Account and Deferral Template applied in line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateGLAccountWithVATPostSetup(GLAccount, SalesHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(5, 20));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandIntInRange(1, 1));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(1000, 1000));
        SalesLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        SalesLine.Modify(true);

        // [GIVEN] Update Amount in Deferral Schedule Line.
        DeferralHeader.Get(DeferralHeader."Deferral Doc. Type"::Sales, '', '', SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        UpdateDeferralScheduleForNMonth(
          "Deferral Document Type"::Sales, SalesHeader."Document Type".AsInteger(), SalesHeader."No.",
          SalesLine."Line No.", DeferralHeader."Start Date", SalesLine."Unit Price", DeferralTemplate."No. of Periods", 1);

        // [WHEN] Update Deferral Amounts.
        FindDeferralSalesLine(DeferralLine, SalesLine);
        DeferralLine.Validate(Amount, LibraryRandom.RandDecInDecimalRange(500, 1000, 2));
        DeferralLine.Modify(true);

        // [VERIFY] Verify: Expected Error - The sum of the deferred amounts must be equal to the amount in the Amount to Defer field.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(TotalToDeferErr);
    end;

    [Test]
    procedure PurchaseInvoiceShouldNotPostWithIncorrectDeferralScheduleValues()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        // [SCENARIO 504969] Incorrect Deferral Schedule Values are wrongly kept if you refresh the page or close the browser.
        Initialize();

        // [GIVEN] Create Deferral Template with "Calculation Method" = "User-Defined","Start Date" ="Beginning of Next Calendar Year" and No. of Periods is 4.
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"User-Defined",
          DeferralTemplate."Start Date"::"Beginning of Next Calendar Year", LibraryRandom.RandIntInRange(4, 4));

        // [GIVEN] Create Purchase Invoice withG/L Account and Deferral Template applied in line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
          LibraryRandom.RandIntInRange(1, 1));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 1000));
        PurchaseLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        PurchaseLine.Modify(true);

        // [GIVEN] Update Amount in Deferral Schedule Line.
        DeferralHeader.Get("Deferral Document Type"::Purchase, '', '', PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        UpdateDeferralScheduleForNMonth(
          "Deferral Document Type"::Purchase, PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.",
          PurchaseLine."Line No.", DeferralHeader."Start Date", PurchaseLine."Direct Unit Cost", DeferralTemplate."No. of Periods", 1);

        // [WHEN] Update Deferral Amounts.
        FindDeferralPurchaseLine(DeferralLine, PurchaseLine);
        DeferralLine.Validate(Amount, LibraryRandom.RandDecInDecimalRange(500, 1000, 2));
        DeferralLine.Modify(true);

        // [VERIFY] Verify: Expected Error - The sum of the deferred amounts must be equal to the amount in the Amount to Defer field.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(TotalToDeferErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerSalesVerifyQuestion')]
    procedure VerifyConfirmMessageWhenCorrectedThePostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 578414] Verify the expected confirmation message appears upon canceling the posted sales invoice.
        Initialize();

        // [GIVEN] Create a Sales Order.
        CreateSalesHeaderWithItemWithType(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Order, SalesLine.Type::Item);

        // [GIVEN] Modify the 'Qty to Ship' field.
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity - 1);
        SalesLine.Modify(true);

        // [GIVEN] Post the Sales Order partially.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Commit();

        // [GIVEN] Open the posted sales invoice page.
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.Filter.SetFilter("No.", InvoiceNo);

        // [WHEN] Cancel the posted sales invoice.
        PostedSalesInvoice.CancelInvoice.Invoke();

        // [THEN] Verify the expected confirmation message appears upon canceling the posted sales invoice.
        Assert.AreEqual(CancelPostedSalesInvoiceQst, LibraryVariableStorage.DequeueText(), 'Invalid confirmation question');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerPurchaseVerifyQuestion')]
    procedure VerifyConfirmMessageWhenCorrectedThePostedPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 578414] Verify the expected confirmation message appears upon canceling the posted purchase invoice. 
        Initialize();

        // [GIVEN] Create a Purchase Order.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] Modify the 'Qty to Receive' field.
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity - 1);
        PurchaseLine.Modify(true);

        // [GIVEN] Post the Purchase Order partially.
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Commit();

        // [GIVEN] Open the posted purchase invoice page.
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.Filter.SetFilter("No.", InvoiceNo);

        // [WHEN] Cancel the posted purchase invoice.
        PostedPurchaseInvoice.CancelInvoice.Invoke();

        // [THEN] Verify the expected confirmation message appears upon canceling the posted purchase invoice.
        Assert.AreEqual(CancelPostedPurchaseInvoiceQst, LibraryVariableStorage.DequeueText(), 'Invalid confirmation question');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales/Purch. Correct. Docs");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales/Purch. Correct. Docs");

        InitializeSetupData();

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales/Purch. Correct. Docs");
    end;

    local procedure InitializeSetupData()
    begin
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
    end;

    local procedure UpdateGLAccountsInGeneralPostingSetupFromPurchaseInvoiceLine(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindSet();
        repeat
            GeneralPostingSetup.Get(PurchInvLine."Gen. Bus. Posting Group", PurchInvLine."Gen. Prod. Posting Group");
            GeneralPostingSetup."Sales Credit Memo Account" := LibraryERM.CreateGLAccountNo();
            GeneralPostingSetup."Purch. Credit Memo Account" := LibraryERM.CreateGLAccountNo();
            GeneralPostingSetup.Modify();
        until PurchInvLine.Next() = 0;
    end;

    local procedure CreateSalesHeaderWithItemWithType(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemType: Enum "Item Type")
    var
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, ItemType);
        Item.Validate("Unit Price", LibraryRandom.RandInt(10));
        Item.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesLinesWithRoundingGLAcccount(SalesHeader: Record "Sales Header"; Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(20, 40));
        SalesLine.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", -LibraryRandom.RandIntInRange(5, 10));
        SalesLine.Modify(true);

        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate("Invoice Rounding Account", SalesLine."No.");
        CustomerPostingGroup.Modify(true);
    end;

    local procedure CreatePurchaseLinesWithRoundingGLAcccount(PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    var
        PurchaseLine: Record "Purchase Line";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(20, 40));
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", -LibraryRandom.RandIntInRange(5, 10));
        PurchaseLine.Modify(true);

        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VendorPostingGroup.Validate("Invoice Rounding Account", PurchaseLine."No.");
        VendorPostingGroup.Modify(true);
    end;

    local procedure CleanSalesLineDiscAccountOnGenPostingSetup(SalesLine: Record "Sales Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanPurchLineDiscAccountOnGenPostingSetup(PurchaseLine: Record "Purchase Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure SetSalesLineDiscAccountBlockedOnGenPostingSetup(SalesLine: Record "Sales Line"; var GeneralPostingSetup: Record "General Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Sales Line Disc. Account", GLAccount."No.");
        GeneralPostingSetup.Modify(true);

        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);
    end;

    local procedure SetPurchLineDiscAccountBlockedOnGenPostingSetup(PurchaseLine: Record "Purchase Line"; var GeneralPostingSetup: Record "General Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", GLAccount."No.");
        GeneralPostingSetup.Modify(true);

        GLAccount.Validate(Blocked, true);
        GLAccount.Modify(true);
    end;

    local procedure CleanCOGSAccountOnGenPostingSetup(SalesLine: Record "Sales Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("COGS Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanSalesAccountOnGenPostingSetup(SalesLine: Record "Sales Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Account", '');
        GeneralPostingSetup.Validate("Sales Credit Memo Account", LibraryERM.CreateGLAccountWithSalesSetup());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanSalesCreditMemoAccountOnGenPostingSetup(SalesLine: Record "Sales Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountWithSalesSetup());
        GeneralPostingSetup.Validate("Sales Credit Memo Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanPurchAccountOnGenPostingSetup(PurchaseLine: Record "Purchase Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Purch. Account", '');
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", LibraryERM.CreateGLAccountWithPurchSetup());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanPurchCreditMemoAccountOnGenPostingSetup(PurchaseLine: Record "Purchase Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountWithPurchSetup());
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure RestoreGenPostingSetup(OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(OldGeneralPostingSetup."Gen. Bus. Posting Group", OldGeneralPostingSetup."Gen. Prod. Posting Group");
        GeneralPostingSetup."Sales Line Disc. Account" := OldGeneralPostingSetup."Sales Inv. Disc. Account";
        GeneralPostingSetup."Purch. Line Disc. Account" := OldGeneralPostingSetup."Purch. Line Disc. Account";
        GeneralPostingSetup."COGS Account" := OldGeneralPostingSetup."COGS Account";
        GeneralPostingSetup."Sales Credit Memo Account" := OldGeneralPostingSetup."Sales Credit Memo Account";
        GeneralPostingSetup."Sales Account" := OldGeneralPostingSetup."Sales Account";
        GeneralPostingSetup.Modify();
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        GetSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Quantity, 9);
        SalesLine.Validate("Qty. to Ship", 7);
        SalesLine.Validate("Qty. to Invoice", 5);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        GetPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Quantity, 9);
        PurchaseLine.Validate("Qty. to Receive", 7);
        PurchaseLine.Validate("Qty. to Invoice", 5);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithTrackedItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateTrackedItem(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Validate(Quantity, 9);
        PurchaseLine.Validate("Qty. to Receive", 7);
        PurchaseLine.Validate("Qty. to Invoice", 5);
        PurchaseLine.Modify(true);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateTrackedItem(): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        exit(Item."No.");
    end;

    local procedure CreateSalesHeaderWithItemAndChargeItem(var SalesHeader: Record "Sales Header")
    var
        SalesLineItem: Record "Sales Line";
        SalesLineChargeItem: Record "Sales Line";
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        LibrarySales.CreateSalesLine(
            SalesLineItem, SalesHeader, SalesLineItem.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLineItem.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        SalesLineItem.Modify(true);

        LibrarySales.CreateSalesLine(
            SalesLineChargeItem, SalesHeader, SalesLineChargeItem.Type::"Charge (Item)",
            LibraryInventory.CreateItemChargeNo(), 1);
        SalesLineChargeItem.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        SalesLineChargeItem.Modify(true);

        ItemCharge.Get(SalesLineChargeItem."No.");
        LibrarySales.CreateItemChargeAssignment(
            ItemChargeAssignmentSales, SalesLineChargeItem, ItemCharge,
            SalesLineItem."Document Type"::Invoice, SalesLineItem."Document No.", SalesLineItem."Line No.",
            SalesLineItem."No.", SalesLineChargeItem.Quantity, LibraryRandom.RandIntInRange(10, 20));
        ItemChargeAssignmentSales.Insert(true);
    end;

    local procedure CreatePurchaseHeaderWithItemAndChargeItem(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineChargeItem: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLineItem, PurchaseHeader, PurchaseLineItem.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLineItem.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLineItem.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLineChargeItem, PurchaseHeader, PurchaseLineChargeItem.Type::"Charge (Item)",
            LibraryInventory.CreateItemChargeNo(), 1);
        PurchaseLineChargeItem.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLineChargeItem.Modify(true);

        ItemCharge.Get(PurchaseLineChargeItem."No.");
        LibraryPurchase.CreateItemChargeAssignment(
            ItemChargeAssignmentPurch, PurchaseLineChargeItem, ItemCharge,
            PurchaseLineItem."Document Type"::Invoice, PurchaseLineItem."Document No.", PurchaseLineItem."Line No.",
            PurchaseLineItem."No.", PurchaseLineChargeItem.Quantity, LibraryRandom.RandIntInRange(10, 20));
        ItemChargeAssignmentPurch.Insert(true);
    end;

    local procedure GetSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure GetPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
    end;

    local procedure CreateSalesInvoiceFromShipment(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        LibrarySales.GetShipmentLines(SalesLine);
    end;

    local procedure CreateInventoryPeriod(EndingDate: Date; IsClosed: Boolean)
    var
        InventoryPeriod: Record "Inventory Period";
    begin
        InventoryPeriod.Init();
        InventoryPeriod."Ending Date" := EndingDate;
        InventoryPeriod.Closed := IsClosed;
        InventoryPeriod.Insert(true);
    end;

    local procedure VerifySalesOrderLineQuantitiesAfterUndoShipment(SalesLine: Record "Sales Line"; Qty: Decimal)
    begin
        Assert.AreEqual(Qty, SalesLine."Qty. to Invoice", StrSubstNo(CancelQtyErr, SalesLine.FieldName("Qty. to Invoice")));
        Assert.AreEqual(Qty, SalesLine."Qty. to Ship", StrSubstNo(CancelQtyErr, SalesLine.FieldName("Qty. to Ship")));
        Assert.AreEqual(0, SalesLine."Quantity Invoiced", StrSubstNo(CancelQtyErr, SalesLine.FieldName("Quantity Invoiced")));
        Assert.AreEqual(0, SalesLine."Quantity Shipped", StrSubstNo(CancelQtyErr, SalesLine.FieldName("Quantity Shipped")));
        Assert.AreEqual(0, SalesLine."Qty. Shipped Not Invoiced", StrSubstNo(CancelQtyErr, SalesLine.FieldName("Qty. Shipped Not Invoiced")));
    end;

    local procedure VerifyRevertedShipmentLine(SalesShipmentLine: Record "Sales Shipment Line"; RevertedSalesShipmentLine: Record "Sales Shipment Line")
    begin
        Assert.AreNotEqual(SalesShipmentLine."Line No.", RevertedSalesShipmentLine."Line No.", 'Shipment line should be reverted.');
        Assert.IsTrue(SalesShipmentLine.Quantity = RevertedSalesShipmentLine.Quantity * (-1), 'Shipment line should be reverted.');
    end;

    local procedure VerifyRevertedItemLedgerEntry(TableId: Integer; DocNo: Code[20]; DocLineNo: Integer; RevertedQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        case TableId of
            Database::"Sales Shipment Line":
                ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
            Database::"Purch. Rcpt. Line":
                ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Purchase Receipt");
        end;
        ItemLedgerEntry.SetRange("Document No.", DocNo);
        ItemLedgerEntry.SetRange("Document Line No.", DocLineNo);
        ItemLedgerEntry.FindFirst();
        Assert.RecordCount(ItemLedgerEntry, 1);
        Assert.AreEqual(ItemLedgerEntry.Quantity, RevertedQuantity, 'Item ledger entry quantity is incorrect.');
        Assert.AreEqual(ItemLedgerEntry.Quantity, ItemLedgerEntry."Invoiced Quantity", 'Item ledger entry invoiced quantity is incorrect.');
        Assert.IsTrue(ItemLedgerEntry."Completely Invoiced", 'Item ledger entry completely invoiced is incorrect.');
    end;

    local procedure VerifyPurchaseOrderLineQuantitiesAfterUndoReceive(PurchaseLine: Record "Purchase Line"; Qty: Decimal)
    begin
        Assert.AreEqual(Qty, PurchaseLine."Qty. to Invoice", StrSubstNo(CancelQtyErr, PurchaseLine.FieldName("Qty. to Invoice")));
        Assert.AreEqual(Qty, PurchaseLine."Qty. to Receive", StrSubstNo(CancelQtyErr, PurchaseLine.FieldName("Qty. to Receive")));
        Assert.AreEqual(0, PurchaseLine."Quantity Invoiced", StrSubstNo(CancelQtyErr, PurchaseLine.FieldName("Quantity Invoiced")));
        Assert.AreEqual(0, PurchaseLine."Quantity Received", StrSubstNo(CancelQtyErr, PurchaseLine.FieldName("Quantity Received")));
        Assert.AreEqual(0, PurchaseLine."Qty. Rcd. Not Invoiced", StrSubstNo(CancelQtyErr, PurchaseLine.FieldName("Qty. Rcd. Not Invoiced")));
    end;

    local procedure VerifyRevertedReceiptLine(PurchRcptLine: Record "Purch. Rcpt. Line"; RevertedPurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        Assert.AreNotEqual(PurchRcptLine."Line No.", RevertedPurchRcptLine."Line No.", 'Receipt line should be reverted.');
        Assert.IsTrue(PurchRcptLine.Quantity = RevertedPurchRcptLine.Quantity * (-1), 'Receipt line should be reverted.');
    end;

    local procedure PostAndVerifySalesDocumentAfterUndo(var SalesHeader: Record "Sales Header")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        asserterror SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.ExpectedError('The Sales Header does not exist.');

        SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentLine.FindLast();
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.SetRange("Document No.", SalesShipmentLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", SalesShipmentLine."Line No.");
        ItemLedgerEntry.FindFirst();
        Assert.RecordCount(ItemLedgerEntry, 1);
        Assert.AreEqual(ItemLedgerEntry.Quantity, -9, 'Item ledger entry quantity is wrong after full post.');
    end;

    local procedure PostAndVerifyPurchaseDocumentAfterUndo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        asserterror PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.ExpectedError('The Purchase Header does not exist.');

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.FindLast();
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Purchase Receipt");
        ItemLedgerEntry.SetRange("Document No.", PurchRcptLine."Document No.");
        ItemLedgerEntry.SetRange("Document Line No.", PurchRcptLine."Line No.");
        ItemLedgerEntry.FindFirst();
        Assert.RecordCount(ItemLedgerEntry, 1);
        Assert.AreEqual(ItemLedgerEntry.Quantity, 9, 'Item ledger entry quantity is wrong after full post.');
    end;

    local procedure PostAndVerifyPurchaseDocumentAfterUndoWithResource(var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        asserterror PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.ExpectedError('The Purchase Header does not exist.');

        PurchInvLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvLine.FindLast();

        ResLedgerEntry.SetRange("Entry Type", ResLedgerEntry."Entry Type"::Purchase);
        ResLedgerEntry.SetRange("Document No.", PurchInvLine."Document No.");
        ResLedgerEntry.SetRange("Resource No.", PurchInvLine."No.");
        ResLedgerEntry.FindFirst();
        Assert.RecordCount(ResLedgerEntry, 1);
        Assert.AreEqual(ResLedgerEntry.Quantity, 9, 'Resource ledger entry quantity is wrong after full post.');
    end;

    local procedure PostAndVerifySalesDocumentAfterUndoWithGLAccount(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        asserterror SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.ExpectedErrorCannotFind(Database::"Sales Header");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VatPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VatPostingSetup.Modify(true);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; VatPostingSetup: Record "VAT Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccNo: Code[20];
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VatPostingSetup."VAT Prod. Posting Group");
        GenProductPostingGroup.Modify(true);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GLAccNo := LibraryERM.CreateGLAccountNoWithDirectPosting();
        GeneralPostingSetup.Validate("Purch. Account", GLAccNo);
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", GLAccNo);
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", GLAccNo);
        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", GLAccNo);
        GeneralPostingSetup.Validate("COGS Account", GLAccNo);
        GeneralPostingSetup.Validate("COGS Account (Interim)", GLAccNo);
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", GLAccNo);
        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GLAccNo);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateItemAndVendor(var Item: Record Item; var Vendor: Record Vendor; GeneralPostingSetup: Record "General Posting Setup"; VatPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Service);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VatPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; Vendor: Record Vendor)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithItemTypeServiceAndNonInventory(var PurchaseHeader: Record "Purchase Header")
    var
        Item: array[2] of Record Item;
        PurchaseLine: array[2] of Record "Purchase Line";
        Location: Record Location;
        i: Integer;
    begin
        LibraryInventory.CreateServiceTypeItem(Item[1]);
        LibraryInventory.CreateNonInventoryTypeItem(Item[2]);
        LibraryWarehouse.CreateFullWMSLocation(Location, LibraryRandom.RandInt(5));
        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, LibraryPurchase.CreateVendorNo(), Location.Code);

        for i := 1 to ArrayLen(Item) do
            LibraryPurchase.CreatePurchaseLineWithUnitCost(
                PurchaseLine[i],
                PurchaseHeader,
                Item[i]."No.",
                LibraryRandom.RandInt(100),
                LibraryRandom.RandInt(10));
    end;

    local procedure CreateGLAccountWithVATPostSetup(var GLAccount: Record "G/L Account"; VATBusPostGrCode: Code[20]; VATPct: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        CreateVATPostingSetup(VATBusPostGrCode, VATProductPostingGroup.Code, VATPct);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostGrCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount.Modify(true);
    end;

    local procedure CreateVATPostingSetup(VATBusPostGr: Code[20]; VATProdPostGr: Code[20]; VATPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGr, VATProdPostGr);
        VATPostingSetup."VAT Identifier" := VATProdPostGr;
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateDeferralScheduleForNMonth(DefDocType: Enum "Deferral Document Type"; DocType: Option; DocNo: Code[20]; DocLineNo: Integer; StartDateDeferralHeader: Date; DefAmount1: Decimal; NoOfPeriod: Integer; LineNo: Integer)
    var
        DeferralLine: Record "Deferral Line";
    begin
        DeferralLine.SetRange("Posting Date", StartDateDeferralHeader);
        LibraryERM.FindDeferralLine(DeferralLine, DefDocType, '', '', DocType, DocNo, DocLineNo);
        UpdateDefScheduleLine(DeferralLine, (DefAmount1 / NoOfPeriod), Format(LineNo) + '1');
        DeferralLine.SetRange("Posting Date", CalcDate('<-CM+1M>', StartDateDeferralHeader));
        DeferralLine.FindFirst();
        UpdateDefScheduleLine(DeferralLine, (DefAmount1 / NoOfPeriod), Format(LineNo) + '2');
        DeferralLine.SetRange("Posting Date", CalcDate('<-CM+2M>', StartDateDeferralHeader));
        DeferralLine.FindFirst();
        UpdateDefScheduleLine(DeferralLine, (DefAmount1 / NoOfPeriod), Format(LineNo) + '3');
        DeferralLine.SetRange("Posting Date", CalcDate('<-CM+3M>', StartDateDeferralHeader));
        DeferralLine.FindFirst();
        UpdateDefScheduleLine(DeferralLine, (DefAmount1 / NoOfPeriod), Format(LineNo) + '4');
    end;

    local procedure UpdateDefScheduleLine(var DeferralLine: Record "Deferral Line"; DefAmount: Decimal; DefLineDescr: Text[100])
    begin
        DeferralLine.Validate(Description, PadStr(DefLineDescr, MaxStrLen(DeferralLine.Description), '0'));
        DeferralLine.Validate(Amount, DefAmount);
        DeferralLine.Modify(true);
    end;

    local procedure FindDeferralSalesLine(var DeferralLine: Record "Deferral Line"; SalesLine: Record "Sales Line")
    begin
        DeferralLine.SetRange("Deferral Doc. Type", DeferralLine."Deferral Doc. Type"::Sales);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", SalesLine."Document Type");
        DeferralLine.SetRange("Document No.", SalesLine."Document No.");
        DeferralLine.FindFirst();
    end;

    local procedure FindDeferralPurchaseLine(var DeferralLine: Record "Deferral Line"; PurchaseLine: Record "Purchase Line")
    begin
        DeferralLine.SetRange("Deferral Doc. Type", DeferralLine."Deferral Doc. Type"::Purchase);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", PurchaseLine."Document Type");
        DeferralLine.SetRange("Document No.", PurchaseLine."Document No.");
        DeferralLine.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.New();
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(5);
        ItemTrackingLines."Qty. to Handle (Base)".SetValue(5);
        ItemTrackingLines."Qty. to Invoice (Base)".SetValue(5);
        ItemTrackingLines.New();
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(4);
        ItemTrackingLines."Qty. to Handle (Base)".SetValue(2);
        ItemTrackingLines."Qty. to Invoice (Base)".SetValue(0);
        ItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerSalesVerifyQuestion(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerPurchaseVerifyQuestion(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
    end;
}

