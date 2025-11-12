codeunit 137212 "SCM Copy Document Mgt."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Copy Document]
        IsInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryAssembly: Codeunit "Library - Assembly";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryResource: Codeunit "Library - Resource";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        MsgCorrectedInvoiceNo: Label 'have a Corrected Invoice No. Do you want to continue?';
        WrongDimensionsCopiedErr: Label 'Wrong dimensions in copied document';
        ItemTrackingMode: Option "Assign Lot No.","Select Entries","Assign Serial Nos.";
        CaptionNotMatchErr: Label 'Incorrect caption';
        OverReceiveError: Label 'Type must be equal to ''Item''  in Purchase Line: Document Type=%1, Document No.=%2, Line No.=%3. Current value is ''%4''.', Comment = '%1 = Document Type, %2 = Document No., %3 = Line No., %4 = Type';

    local procedure CopyDocument(SourceType: Enum "Sales Document Type From"; SourceUnpostedType: Enum "Sales Document Type"; DestType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SourceNo: Code[20];
        DestNo: Code[20];
    begin
        Initialize();
        SourceNo := CreateSourceDocument(SourceType, SourceUnpostedType);
        CreateEmptySalesHeader(SalesHeader, DestType);
        DestNo := CopyToDestinationSalesDocument(SourceType, SourceNo, SalesHeader);
        VerifyCopy(SourceType, SourceNo, DestType, DestNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrderToSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        CopyDocument("Sales Document Type From"::Order, SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyQuoteToSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        CopyDocument("Sales Document Type From"::Quote, SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyInvoiceToReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        CopyDocument("Sales Document Type From"::"Posted Invoice", SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyShipmentToQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        CopyDocument(
            "Sales Document Type From"::"Posted Shipment", SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyReturnOrderToCrMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        CopyDocument(
            "Sales Document Type From"::"Return Order", SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyCrMemoToInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        ExecuteConfirmHandler();
        CopyDocument(
            "Sales Document Type From"::"Posted Credit Memo", SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyReceiptToBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        ExecuteConfirmHandler();
        CopyDocument(
            "Sales Document Type From"::"Posted Return Receipt",
            SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyItemChargeAssignment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SourceNo: Code[20];
    begin
        // [FEATURE] [Item Charge]
        Initialize();

        SourceNo := CreateSourceDocument("Sales Document Type From"::"Posted Shipment", SalesHeader."Document Type"::Order);
        SalesShipmentHeader.Get(SourceNo);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.FindFirst();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesShipmentHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", CreateItemCharge(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10000) / 100);
        SalesLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignment(ItemChargeAssignmentSales,
          SalesLine, ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
          SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");

        LibrarySales.CreateSalesHeader(SalesHeader2,
          SalesHeader2."Document Type"::Order, SalesShipmentHeader."Sell-to Customer No.");

        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Order, SalesHeader."No.", SalesHeader2);

        VerifyShipmntItemChargeAssngmt(SalesHeader2, SalesShipmentLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOverwriteHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SourceType: Enum "Sales Document Type From";
        DestType: Enum "Sales Document Type";
        SourceNo: Code[20];
        DestNo: Code[20];
    begin
        Initialize();

        SourceType := "Sales Document Type From"::Order;
        DestType := SalesHeader."Document Type"::Order;
        SourceNo := CreateSourceDocument(SourceType, SalesHeader."Document Type"::Order);

        LibrarySales.CreateSalesHeader(SalesHeader,
          CopyDocumentMgt.GetSalesDocumentType(SourceType), CreateCustomer());
        DestNo := CopyToDestinationSalesDocument(SourceType, SourceNo, SalesHeader);
        VerifyCopy(SourceType, SourceNo, DestType, DestNo);

        CopyDocumentMgt.SetProperties(false, true, false, false, true, false, false);
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader,
          CopyDocumentMgt.GetSalesDocumentType(SourceType), CreateCustomer());

        DestNo := CopyToDestinationSalesDocument(SourceType, SourceNo, SalesHeader);
        SalesHeader2.Get(CopyDocumentMgt.GetSalesDocumentType(SourceType), SourceNo);

        asserterror VerifyCopy(SourceType, SourceNo, DestType, DestNo);
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption("Sell-to Customer No."), SalesHeader2."Sell-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesQuoteWithoutCustomer()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
    begin
        // [SCENARIO 71922] No error occurs while creating Sales Quote from Copy Document.
        // [GIVEN] Create Sales Quote without Sell-to Customer No.
        Initialize();
        CreateSalesQuote(SalesHeader);
        CreateEmptySalesHeader(SalesHeader2, SalesHeader2."Document Type"::Quote);

        // [WHEN] Create a Sales Quote with Copy Document.
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Quote, SalesHeader."No.", SalesHeader2);

        // [THEN] Sales Quote Created With Copy Document.
        ValidateCopiedSalesHeaderAndSalesLines(SalesHeader2, SalesHeader2."Document Type", SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDimensionsSalesDocumentRecalculateLines()
    begin
        CopyDimensionsSalesDocument(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDimensionsSalesDocumentNoRecalculateLines()
    begin
        CopyDimensionsSalesDocument(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDimensionsPurchaseDocumentRecalculateLines()
    begin
        CopyDimensionsPurchaseDocument(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDimensionsPurchaseDocumentNoRecalculateLines()
    begin
        CopyDimensionsPurchaseDocument(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDimensionsSalesLineRecalculateLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocNo: Code[20];
        DefaultDimSetID: Integer;
    begin
        // [SCENARIO 371951] Default Dimensions used for Sales Document when running Copy Sales Document with "Recalculate Lines" = Yes
        // [FEATURE] [Sales] [Dimension] [Recalculate Lines]

        Initialize();
        CopyDocumentMgt.SetProperties(true, true, false, false, true, false, false);
        // [GIVEN] Posted Sales Order with Dimension Set ID in Sales Line = "X" (different from Default Dimension Set ID = "Y")
        DefaultDimSetID := PostSalesOrderWithUpdatedDimensions(SalesLine, PostedDocNo);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, SalesLine."Bill-to Customer No.");

        // [WHEN] Copy Sales Document with "Recalculate Lines" = Yes
        CopyToDestinationSalesDocument("Sales Document Type From"::"Posted Invoice", PostedDocNo, SalesHeader);

        // [THEN] Dimension Set ID of copied Sales Line = "X"
        FindSalesLine(SalesHeader, SalesLine);
        SalesLine.TestField("Dimension Set ID", DefaultDimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDimensionsSalesLineNoRecalculateLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocNo: Code[20];
        ExpectedDimSetID: Integer;
    begin
        // [SCENARIO 371951] Dimensions from Posted Sales Order used for Sales Document when running Copy Sales Document with "Recalculate Lines" = No
        // [FEATURE] [Sales] [Dimension]

        Initialize();
        // [GIVEN] Posted Sales Order with Dimension Set ID in Sales Line = "X" (different from Default Dimension Set ID = "Y")
        PostSalesOrderWithUpdatedDimensions(SalesLine, PostedDocNo);
        ExpectedDimSetID := SalesLine."Dimension Set ID";
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, SalesLine."Bill-to Customer No.");

        // [WHEN] Copy Sales Document with "Recalculate Lines" = No
        CopyToDestinationSalesDocument("Sales Document Type From"::"Posted Invoice", PostedDocNo, SalesHeader);

        // [THEN] Dimension Set ID of copied Sales Line = "Y"
        FindSalesLine(SalesHeader, SalesLine);
        SalesLine.TestField("Dimension Set ID", ExpectedDimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDimensionsPurchLineRecalculateLines()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PostedDocNo: Code[20];
        DefaultDimSetID: Integer;
    begin
        // [SCENARIO 371951] Default Dimensions used for Purchase Document when running Copy Purch. Document with "Recalculate Lines" = Yes
        // [FEATURE] [Purchase] [Dimension] [Recalculate Lines]

        Initialize();
        CopyDocumentMgt.SetProperties(true, true, false, false, true, false, false);
        // [GIVEN] Posted Purch. Order with Dimension Set ID in Purch. Line = "X" (different from Default Dimension Set ID = "Y")
        DefaultDimSetID := PostPurchOrderWithUpdatedDimensions(PurchLine, PostedDocNo);
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, PurchLine."Pay-to Vendor No.");

        // [WHEN] Copy Purch. Document with "Recalculate Lines" = Yes
        CopyToDestinationPurchaseDocument("Sales Document Type From"::"Posted Invoice", PostedDocNo, PurchHeader);

        // [THEN] Dimension Set ID of copied Purch. Line = "X"
        FindPurchLine(PurchHeader, PurchLine);
        PurchLine.TestField("Dimension Set ID", DefaultDimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDimensionsPurchLineNoRecalculateLines()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PostedDocNo: Code[20];
        ExpectedDimSetID: Integer;
    begin
        // [SCENARIO 371951] Dimensions from Posted Purchase Order used for Purchase Document when running Copy Purch. Document with "Recalculate Lines" = No
        // [FEATURE] [Purchase] [Dimension]

        Initialize();
        // [GIVEN] Posted Purch. Order with Dimension Set ID in Purch. Line = "X" (different from Default Dimension Set ID = "Y")
        PostPurchOrderWithUpdatedDimensions(PurchLine, PostedDocNo);
        ExpectedDimSetID := PurchLine."Dimension Set ID";
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, PurchLine."Pay-to Vendor No.");

        // [WHEN] Copy Purch. Document with "Recalculate Lines" = No
        CopyToDestinationPurchaseDocument("Sales Document Type From"::"Posted Invoice", PostedDocNo, PurchHeader);

        // [THEN] Dimension Set ID of copied Purch. Line = "Y"
        FindPurchLine(PurchHeader, PurchLine);
        PurchLine.TestField("Dimension Set ID", ExpectedDimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyTwoItemChargesAssignedToOneReceipt()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemRcptNo: Code[20];
        ChargeRcptNo: Code[20];
        Quantity: Integer;
        I: Integer;
    begin
        // [FEATURE] [Item Charge] [Get Receipt Lines]
        // [SCENARIO 377987] "Get Receipt Lines" function copies all item charges assigned to a single purchase receipt line
        Initialize();

        // [GIVEN] Create a purchase order with one line of type "Item"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Order, '');
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader[1], PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Post receipt
        ItemRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        Quantity := LibraryRandom.RandInt(10);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader[1]);

        // [GIVEN] Create two item charge lines and assign to the posted receipt
        for I := 1 to 2 do
            CreateItemChargePurchaseLine(
              PurchaseLine, PurchaseHeader[1], ItemRcptNo, FindPurchRcptLineNo(ItemRcptNo, 1), Item."No.", Quantity, Quantity);

        // [GIVEN] Post item charges receipt
        ChargeRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        // [WHEN] Create a purchase invoice and copy lines from posted receipts
        CreatePurchaseInvoiceCopyFromReceipt(
          PurchaseHeader[2], PurchaseHeader[1]."Pay-to Vendor No.", StrSubstNo('%1|%2', ItemRcptNo, ChargeRcptNo));

        // [THEN] All item charge assignments are copied into the new invoice
        VerifyItemChargeAssignmentPurchCopied(
          PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No.",
          PurchaseHeader[2]."Document Type", PurchaseHeader[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyOneItemChargeAssignedToTwoReceipts()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ItemRcptNo: Code[20];
        ChargeRcptNo: Code[20];
        Quantity: Integer;
        I: Integer;
    begin
        // [FEATURE] [Item Charge] [Get Receipt Lines]
        // [SCENARIO 377987] "Get Receipt Lines" function copies item charge assignments when a single item charge line is assigned to several purchase receipt lines

        Initialize();

        // [GIVEN] Create a purchase order with two lines of type "Item"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Order, '');
        LibraryInventory.CreateItem(Item);

        for I := 1 to 2 do
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader[1], PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Post receipt
        ItemRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        // [GIVEN] Create one item charge line and split item charge amount among posted receipt lines
        Quantity := LibraryRandom.RandInt(10);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader[1]);
        CreateItemChargePurchaseLine(
          PurchaseLine, PurchaseHeader[1], ItemRcptNo, FindPurchRcptLineNo(ItemRcptNo, 1), Item."No.", Quantity * 2, Quantity);

        CreateItemChargeAssignmentPurch(PurchaseLine, ItemRcptNo, FindPurchRcptLineNo(ItemRcptNo, 2), Item."No.", Quantity);
        ChargeRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        // [WHEN] Create a purchase invoice and copy lines from posted receipts
        CreatePurchaseInvoiceCopyFromReceipt(
          PurchaseHeader[2], PurchaseHeader[1]."Pay-to Vendor No.", StrSubstNo('%1|%2', ItemRcptNo, ChargeRcptNo));

        // [THEN] All item charge assignments are copied into the new invoice
        VerifyItemChargeAssignmentPurchCopied(
          PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No.",
          PurchaseHeader[2]."Document Type", PurchaseHeader[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyTwoItemChargesAssignedToOneShipment()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemShptNo: Code[20];
        ChargeShptNo: Code[20];
        Quantity: Integer;
        I: Integer;
    begin
        // [FEATURE] [Item Charge] [Get Shipment Lines]
        // [SCENARIO 377987] "Get Shipment Lines" function copies all item charges assigned to a single sales shipment line

        Initialize();

        // [GIVEN] Create a sales order with one line of type "Item"
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::Order, '');
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader[1], SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Post shipment
        ItemShptNo := LibrarySales.PostSalesDocument(SalesHeader[1], true, false);

        // [GIVEN] Create two item charge lines and assign to the posted shipment
        Quantity := LibraryRandom.RandInt(10);
        LibrarySales.ReopenSalesDocument(SalesHeader[1]);

        for I := 1 to 2 do
            CreateItemChargeSalesLine(
              SalesLine, SalesHeader[1], ItemShptNo, FindSalesShptLineNo(ItemShptNo, 1), Item."No.", Quantity, Quantity);

        // [GIVEN] Post item charges shipment
        ChargeShptNo := LibrarySales.PostSalesDocument(SalesHeader[1], true, false);

        // [WHEN] Create a sales invoice and copy lines from posted shipments
        CreateSalesInvoiceCopyFromShipment(
          SalesHeader[2], SalesHeader[1]."Bill-to Customer No.", StrSubstNo('%1|%2', ItemShptNo, ChargeShptNo));

        // [THEN] All item charge assignments are copied into the new invoice
        VerifyItemChargeAssignmentSalesCopied(
          SalesHeader[1]."Document Type", SalesHeader[1]."No.",
          SalesHeader[2]."Document Type", SalesHeader[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyOneItemChargeAssignedToTwoShipments()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemShptNo: Code[20];
        ChargeShptNo: Code[20];
        Quantity: Integer;
        I: Integer;
    begin
        // [FEATURE] [Item Charge] [Get Shipment Lines]
        // [SCENARIO 377987] "Get Shipment Lines" function copies item charge assignments when a single item charge line is assigned to several sales shipment lines

        Initialize();

        // [GIVEN] Create a sales order with two lines of type "Item"
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::Order, '');
        LibraryInventory.CreateItem(Item);

        for I := 1 to 2 do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader[1], SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Post shipment
        ItemShptNo := LibrarySales.PostSalesDocument(SalesHeader[1], true, false);

        // [GIVEN] Create one item charge line and split item charge amount among posted shipment lines
        Quantity := LibraryRandom.RandInt(10);
        LibrarySales.ReopenSalesDocument(SalesHeader[1]);
        CreateItemChargeSalesLine(
          SalesLine, SalesHeader[1], ItemShptNo, FindSalesShptLineNo(ItemShptNo, 1), Item."No.", Quantity * 2, Quantity);

        CreateItemChargeAssignmentSales(SalesLine, ItemShptNo, FindSalesShptLineNo(ItemShptNo, 2), Item."No.", Quantity);

        // [GIVEN] Post item charges shipment
        ChargeShptNo := LibrarySales.PostSalesDocument(SalesHeader[1], true, false);

        // [WHEN] Create a sales invoice and copy lines from posted shipments
        CreateSalesInvoiceCopyFromShipment(
          SalesHeader[2], SalesHeader[1]."Bill-to Customer No.", StrSubstNo('%1|%2', ItemShptNo, ChargeShptNo));

        // [THEN] All item charge assignments are copied into the new invoice
        VerifyItemChargeAssignmentSalesCopied(
          SalesHeader[1]."Document Type", SalesHeader[1]."No.",
          SalesHeader[2]."Document Type", SalesHeader[2]."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyPurchOrderWithTrackingAndNoRemainingQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        PurchInvoiceNo: Code[20];
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Item Tracking]
        // [SCENARIO 381103] No Item Tracking should be created for the Purchase Line copied from Purchase with fully sold Lot.
        Initialize();

        // [GIVEN] Lot-tracked Item "I".
        ItemNo := CreateLotTrackedItem();
        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Received and invoiced Purchase "P" of Item "I" with Lot "L".
        PurchInvoiceNo := CreateAndPostPurchOrderWithTracking(ItemNo, Quantity);

        // [GIVEN] Lot "L" is sold in full.
        CreateAndPostSalesOrderWithTracking(ItemNo, Quantity);

        // [WHEN] Create new Purchase Order by copying the posted invoice of the Purchase "P".
        CopyPurchDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", PurchInvoiceNo);

        // [THEN] No Item Tracking for "I" is created.
        ReservationEntry.Init();
        ReservationEntry.SetRange("Item No.", ItemNo);
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    [Test]
    procedure CopyPostedInvoiceToPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Copy Document]
        // [GIVEN] Posted Purchase Order with Vendor Order No. and Vendor Invoice No. and Vendor Cr. Memo No. and Vendor Shipment No.
        CreatePurchaseOrder(PurchaseHeader);
        if PurchaseHeader."Vendor Order No." = '' then
            PurchaseHeader.Validate("Vendor Order No.", LibraryUtility.GenerateGUID());
        if PurchaseHeader."Vendor Invoice No." = '' then
            PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        if PurchaseHeader."Vendor Cr. Memo No." = '' then
            PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        if PurchaseHeader."Vendor Shipment No." = '' then
            PurchaseHeader.Validate("Vendor Shipment No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Create new Purchase Order by copying the posted invoice of the Purchase "P".
        CopyPurchDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", PurchInvoiceNo);

        // [THEN] Vendor Invoice No. and Vendor Order No. and Vendor Cr. Memo No. and Vendor Shipment No. are empty in the new Purchase Order.
        PurchaseHeader.TestField("Vendor Order No.", '');
        PurchaseHeader.TestField("Vendor Invoice No.", '');
        PurchaseHeader.TestField("Vendor Cr. Memo No.", '');
        PurchaseHeader.TestField("Vendor Shipment No.", '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQuantityToCreateModalPageHandler,PostedSalesDocumentLinesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderCanBePopulatedFromPostedInvoiceWithATOAndItemTracking()
    var
        Item: Record Item;
        CompItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReturnSalesHeader: Record "Sales Header";
        ReturnSalesLine: Record "Sales Line";
        PostedInvoiceNo: Code[20];
        CustomerNo: Code[20];
        SalesQty: Decimal;
    begin
        // [FEATURE] [Sales] [Return Order] [Order] [Item Tracking] [Assembly] [Assemble-to-Order]
        // [SCENARIO 218977] Sales return order can be populated using "Get Posted Document Lines to Reverse" function from posted sales invoice with linked assembly order and serial no. tracking.
        Initialize();

        // [GIVEN] Serial no.-tracked assembled item "I" with "Assemble-to-Order" assembly policy.
        CreateSNTrackedItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);

        // [GIVEN] Component "C" of the parent item "I" is in inventory.
        LibraryAssembly.CreateAssemblyList(Item."Costing Method", Item."No.", true, 1, 0, 0, LibraryRandom.RandInt(5), '', '');
        CompItem.Get(FindComponentItem(Item."No."));
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, CompItem."No.", '', '', LibraryRandom.RandIntInRange(100, 200));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order for "Q" pcs of item "I".
        // [GIVEN] Serial nos. "S1..SQ" are assigned to the linked Assembly Order.
        // [GIVEN] The sales order is posted with "Ship & Invoice" option.
        SalesQty := LibraryRandom.RandInt(10);
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostedInvoiceNo :=
          CreateAndPostSalesOrderWithAsmToOrderAndTracking(CustomerNo, Item."No.", SalesQty, ItemTrackingMode::"Assign Serial Nos.");

        // [GIVEN] Sales Return Order.
        LibrarySales.CreateSalesHeader(
          ReturnSalesHeader, ReturnSalesHeader."Document Type"::"Return Order", CustomerNo);

        // [WHEN] Run "Get Posted Document Lines to Reverse" and select the posted invoice.
        LibraryVariableStorage.Enqueue(PostedInvoiceNo);
        ReturnSalesHeader.GetPstdDocLinesToReverse();

        // [THEN] Document line for "Q" pcs of "I" is created in the sales return order.
        FindSalesLine(ReturnSalesHeader, ReturnSalesLine);
        ReturnSalesLine.TestField("No.", Item."No.");
        ReturnSalesLine.TestField(Quantity, SalesQty);

        // [THEN] The sales return line is tracked with "Q" serial nos.
        VerifySNItemTrackingOnSalesLine(ReturnSalesLine, SalesQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundQtyToAssignOnDistributingItemChargeViaGetReceiptLines()
    var
        Item: Record Item;
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        PurchReceiptNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Get Receipt Lines] [Item Charge] [Rounding]
        // [SCENARIO 272850] "Qty. to Assign" is rounded on purchase invoice line for item charge generated using "Get Receipt Lines".
        Initialize();

        // [GIVEN] Purchase order with item line and item charge line. Quantity = 3.
        // [GIVEN] Set item charge assignment.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeaderOrder, PurchaseLine[1], PurchaseHeaderOrder."Document Type"::Order,
          LibraryPurchase.CreateVendorNo(), Item."No.", 3, '', WorkDate());
        CreateItemChargePurchaseLine(
          PurchaseLine[2], PurchaseHeaderOrder, PurchaseLine[1]."Document No.", PurchaseLine[1]."Line No.", Item."No.", 3, 3);

        // [GIVEN] Set "Qty. to Receipt" on both lines to 2 and post the order with "Receive" option. Posted receipt no. = "R1".
        UpdateQtyToReceiveOnPurchaseLines(PurchaseHeaderOrder, 2);
        PurchReceiptNo[1] := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Set "Qty. to Receipt" on both lines to 1 and post the order with "Receive" option. Posted receipt no. = "R2".
        UpdateQtyToReceiveOnPurchaseLines(PurchaseHeaderOrder, 1);
        PurchReceiptNo[2] := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [WHEN] Create a purchase invoice, run "Get Receipt Lines", select both receipts.
        CreatePurchaseInvoiceCopyFromReceipt(
          PurchaseHeaderInvoice, PurchaseHeaderOrder."Pay-to Vendor No.", StrSubstNo('%1|%2', PurchReceiptNo[1], PurchReceiptNo[2]));

        // [THEN] "Qty. to Assign" on the purchase invoice line representing receipt "R1" = 2. (instead of 3 * (2 / 3) = 3 * 0.6666666667 = 2.0000000001)
        // [THEN] "Qty. to Assign" on the purchase invoice line representing receipt "R2" = 1. (instead of 3 * (1 / 3) = 3 * 0.3333333333 = 0.9999999999)
        VerifyQtyToAssignOnPurchInvoiceLine(PurchaseHeaderInvoice, PurchReceiptNo[1], 2);
        VerifyQtyToAssignOnPurchInvoiceLine(PurchaseHeaderInvoice, PurchReceiptNo[2], 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundQtyToAssignOnDistributingItemChargeViaGetShipmentLines()
    var
        Item: Record Item;
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SalesShipmentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Get Shipment Lines] [Item Charge] [Rounding]
        // [SCENARIO 272850] "Qty. to Assign" is rounded on sales invoice line for item charge generated using "Get Shipment Lines".
        Initialize();

        // [GIVEN] Sales order with item line and item charge line. Quantity = 3.
        // [GIVEN] Set item charge assignment.
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeaderOrder, SalesLine[1], SalesHeaderOrder."Document Type"::Order,
          LibrarySales.CreateCustomerNo(), Item."No.", 3, '', WorkDate());
        CreateItemChargeSalesLine(
          SalesLine[2], SalesHeaderOrder, SalesLine[1]."Document No.", SalesLine[1]."Line No.", Item."No.", 3, 3);

        // [GIVEN] Set "Qty. to Ship" on both lines to 2 and post the order with "Ship" option. Posted shipment no. = "S1".
        UpdateQtyToShipOnSalesLines(SalesHeaderOrder, 2);
        SalesShipmentNo[1] := LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Set "Qty. to Ship" on both lines to 1 and post the order with "Ship" option. Posted shipment no. = "S2".
        UpdateQtyToShipOnSalesLines(SalesHeaderOrder, 1);
        SalesShipmentNo[2] := LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [WHEN] Create a sales invoice, run "Get Shipment Lines", select both shipments.
        CreateSalesInvoiceCopyFromShipment(
          SalesHeaderInvoice, SalesHeaderOrder."Bill-to Customer No.", StrSubstNo('%1|%2', SalesShipmentNo[1], SalesShipmentNo[2]));

        // [THEN] "Qty. to Assign" on the sales invoice line representing shipment "S1" = 2. (instead of 3 * (2 / 3) = 3 * 0.6666666667 = 2.0000000001)
        // [THEN] "Qty. to Assign" on the sales invoice line representing shipment "S2" = 1. (instead of 3 * (1 / 3) = 3 * 0.3333333333 = 0.9999999999)
        VerifyQtyToAssignOnSalesInvoiceLine(SalesHeaderInvoice, SalesShipmentNo[1], 2);
        VerifyQtyToAssignOnSalesInvoiceLine(SalesHeaderInvoice, SalesShipmentNo[2], 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundQtyToAssignOnDistributingItemChargeViaGetReturnShipmentLines()
    var
        Item: Record Item;
        PurchaseHeaderReturnOrder: Record "Purchase Header";
        PurchaseHeaderCrMemo: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        ReturnShipmentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Get Return Shipment Lines] [Item Charge] [Rounding]
        // [SCENARIO 272850] "Qty. to Assign" is rounded on purchase credit memo line for item charge generated using "Get Return Shipment Lines".
        Initialize();

        // [GIVEN] Purchase return order with item line and item charge line. Quantity = 3.
        // [GIVEN] Set item charge assignment.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeaderReturnOrder, PurchaseLine[1], PurchaseHeaderReturnOrder."Document Type"::"Return Order",
          LibraryPurchase.CreateVendorNo(), Item."No.", 3, '', WorkDate());
        CreateItemChargePurchaseLine(
          PurchaseLine[2], PurchaseHeaderReturnOrder, PurchaseLine[1]."Document No.", PurchaseLine[1]."Line No.", Item."No.", 3, 3);

        // [GIVEN] Set "Return Qty. to Ship" on both lines to 2 and post the return order with "Ship" option. Posted shipment no. = "S1".
        UpdateReturnQtyToShipOnPurchaseLines(PurchaseHeaderReturnOrder, 2);
        ReturnShipmentNo[1] := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderReturnOrder, true, false);

        // [GIVEN] Set "Return Qty. to Ship" on both lines to 1 and post the return order with "Ship" option. Posted shipment no. = "S2".
        UpdateReturnQtyToShipOnPurchaseLines(PurchaseHeaderReturnOrder, 1);
        ReturnShipmentNo[2] := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderReturnOrder, true, false);

        // [WHEN] Create a purchase credit memo, run "Get Return Shipment Lines", select both shipments.
        CreatePurchaseCrMemoCopyFromReturnShipment(
          PurchaseHeaderCrMemo, PurchaseHeaderReturnOrder."Pay-to Vendor No.", StrSubstNo('%1|%2', ReturnShipmentNo[1], ReturnShipmentNo[2]));

        // [THEN] "Qty. to Assign" on the purchase credit memo line representing shipment "S1" = 2. (instead of 3 * (2 / 3) = 3 * 0.6666666667 = 2.0000000001)
        // [THEN] "Qty. to Assign" on the purchase credit memo line representing shipment "S2" = 1. (instead of 3 * (1 / 3) = 3 * 0.3333333333 = 0.9999999999)
        VerifyQtyToAssignOnPurchCrMemoLine(PurchaseHeaderCrMemo, ReturnShipmentNo[1], 2);
        VerifyQtyToAssignOnPurchCrMemoLine(PurchaseHeaderCrMemo, ReturnShipmentNo[2], 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundQtyToAssignOnDistributingItemChargeViaGetReturnReceiptLines()
    var
        Item: Record Item;
        SalesHeaderReturnOrder: Record "Sales Header";
        SalesHeaderCrMemo: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReturnReceiptNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Get Return Receipt Lines] [Item Charge] [Rounding]
        // [SCENARIO 272850] "Qty. to Assign" is rounded on sales credit memo line for item charge generated using "Get Return Receipt Lines".
        Initialize();

        // [GIVEN] Sales return order with item line and item charge line. Quantity = 3.
        // [GIVEN] Set item charge assignment.
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeaderReturnOrder, SalesLine[1], SalesHeaderReturnOrder."Document Type"::"Return Order",
          LibrarySales.CreateCustomerNo(), Item."No.", 3, '', WorkDate());
        CreateItemChargeSalesLine(
          SalesLine[2], SalesHeaderReturnOrder, SalesLine[1]."Document No.", SalesLine[1]."Line No.", Item."No.", 3, 3);

        // [GIVEN] Set "Return Qty. to Receive" on both lines to 2 and post the return order with "Receive" option. Posted receipt no. = "R1".
        UpdateReturnQtyToReceiveOnSalesLines(SalesHeaderReturnOrder, 2);
        ReturnReceiptNo[1] := LibrarySales.PostSalesDocument(SalesHeaderReturnOrder, true, false);

        // [GIVEN] Set "Return Qty. to Receive" on both lines to 1 and post the return order with "Receive" option. Posted receipt no. = "R2".
        UpdateReturnQtyToReceiveOnSalesLines(SalesHeaderReturnOrder, 1);
        ReturnReceiptNo[2] := LibrarySales.PostSalesDocument(SalesHeaderReturnOrder, true, false);

        // [WHEN] Create a sales credit memo, run "Get Return Receipt Lines", select both receipts.
        CreateSalesCrMemoCopyFromReturnReceipt(
          SalesHeaderCrMemo, SalesHeaderReturnOrder."Bill-to Customer No.", StrSubstNo('%1|%2', ReturnReceiptNo[1], ReturnReceiptNo[2]));

        // [THEN] "Qty. to Assign" on the sales credit memo line representing receipt "R1" = 2. (instead of 3 * (2 / 3) = 3 * 0.6666666667 = 2.0000000001)
        // [THEN] "Qty. to Assign" on the sales credit memo line representing receipt "R2" = 1. (instead of 3 * (1 / 3) = 3 * 0.3333333333 = 0.9999999999)
        VerifyQtyToAssignOnSalesCrMemoLine(SalesHeaderCrMemo, ReturnReceiptNo[1], 2);
        VerifyQtyToAssignOnSalesCrMemoLine(SalesHeaderCrMemo, ReturnReceiptNo[2], 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressValidatedFromCustomerOnCopySalesReturnOrderWithBlankShipToCode()
    var
        Customer: Record Customer;
        SalesHeaderReturn: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Return Order] [Order]
        // [SCENARIO 228033] Ship-to Address is validated from customer card when sales order is copied from sales return order with blank ship-to code.
        Initialize();

        // [GIVEN] Customer "C" with Address = "A" and "Address 2" = "A2".
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [GIVEN] Sales Return Order "SR" to customer "C".
        // [GIVEN] "SR"."Ship-to Code" is blank; "SR"."Ship-to Address" = "B"; "SR"."Ship-to Address 2" = "B2".
        LibrarySales.CreateSalesHeader(SalesHeaderReturn, SalesHeaderReturn."Document Type"::"Return Order", Customer."No.");
        SalesHeaderReturn.Validate("Ship-to Code", '');
        SalesHeaderReturn.Validate(
          "Ship-to Address", LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeaderReturn."Ship-to Address")));
        SalesHeaderReturn.Validate(
          "Ship-to Address 2", LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeaderReturn."Ship-to Address 2")));
        SalesHeaderReturn.Modify(true);

        // [GIVEN] Sales Order "SO" for customer "C".
        LibrarySales.CreateSalesHeader(SalesHeaderOrder, SalesHeaderOrder."Document Type"::Order, Customer."No.");

        // [WHEN] Copy sales return order "SR" to sales order "SO".
        CopyDocumentMgt.CopySalesDoc(
          "Sales Document Type From"::"Return Order", SalesHeaderReturn."No.", SalesHeaderOrder);

        // [THEN] "SO"."Ship-to Address" = "A".
        // [THEN] "SO"."Ship-to Address 2" = "A2".
        SalesHeaderOrder.TestField("Ship-to Address", Customer.Address);
        SalesHeaderOrder.TestField("Ship-to Address 2", Customer."Address 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPstdSalesLinesSameLineNoDifferentInvoices()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ShipmentNo: Code[20];
        CustomerNo: Code[20];
        I: Integer;
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        // [FEATURE] [Sales] [Get Posted Document Lines to Reverse] [Invoice]
        // [SCENARIO 279030] Sales Lines with same "Line No." in different invoice documents and same Shipment "Document No." can be copied

        Initialize();

        // [GIVEN] Created Customer
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Sales Order for Customer with two Sales Lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, '', 1);
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, '', 1);

        // [GIVEN] Sales Order posted with shipment
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Sales Invoice created and posted for each posted Sales Shipment Line for Customer
        for I := 1 to ArrayLen(SalesLine) do begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
            GetSalesShipmentLineWithOrderNo(SalesHeader, ShipmentNo, I);
            LibrarySales.PostSalesDocument(SalesHeader, false, false);
        end;

        // [GIVEN] Sales Credit Memo created for Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);

        // [WHEN] Copy both Posted Sales Invoice Lines to Sales Credit Memo
        LinesNotCopied := 0;
        MissingExCostRevLink := false;
        SalesInvoiceLine.SetRange("Sell-to Customer No.", CustomerNo);
        CopyDocumentMgt.SetProperties(false, false, false, false, true, true, false);
        CopyDocumentMgt.CopySalesInvLinesToDoc(SalesHeader, SalesInvoiceLine, LinesNotCopied, MissingExCostRevLink);

        // [THEN] Sales Lines created for Sales Credit Memo
        VerifyCopySalesLinesNos(
          SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.",
          SalesLine[1].Type::Item, SalesLine[1]."No.", SalesLine[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPstdPurchLinesSameLineNoDifferentInvoices()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        ReceiptNo: Code[20];
        VendorNo: Code[20];
        I: Integer;
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        // [FEATURE] [Purchase] [Get Posted Document Lines to Reverse] [Invoice]
        // [SCENARIO 279030] Purchase Lines with same "Line No." in different invoice documents and same Receipt "Document No." can be copied

        Initialize();

        // [GIVEN] Created Vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Purchase Order for Vendor with two Purchase Lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::Item, '', 1);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::Item, '', 1);

        // [GIVEN] Purchase Order posted with Receipt
        ReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Purchase Invoice created and posted for each posted Purchase Receipt Line for Vendor
        for I := 1 to ArrayLen(PurchaseLine) do begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
            GetPurchaseReceiptLineWithOrderNo(PurchaseHeader, ReceiptNo, I);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);
        end;

        // [GIVEN] Purchase Credit Memo created for Vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);

        // [WHEN] Copy both Posted Purchase Invoice Lines to Purchase Credit Memo
        LinesNotCopied := 0;
        MissingExCostRevLink := false;
        PurchInvLine.SetRange("Buy-from Vendor No.", VendorNo);
        CopyDocumentMgt.SetProperties(false, false, false, false, true, true, false);
        CopyDocumentMgt.CopyPurchInvLinesToDoc(PurchaseHeader, PurchInvLine, LinesNotCopied, MissingExCostRevLink);

        // [THEN] Purchase Lines created for Purchase Credit Memo
        VerifyCopyPurchLinesNos(
          PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."No.",
          PurchaseLine[1].Type::Item, PurchaseLine[1]."No.", PurchaseLine[2]."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CorrectPostedSalesOrderLinkedWithTwoShipmentsAndAssemblyOrder()
    var
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        Item: Record Item;
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];

    begin
        // [SCENARIO 342934] Correct posted sales order that is linked to two shiments and assembly to order
        Initialize();

        LibraryAssembly.SetStockoutWarning(false);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Assemble-to-order item "I".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);

        // [GIVEN] Create component "C" with "Standard" costing method and add it to the assembly BOM of item "I".
        LibraryAssembly.CreateAssemblyList(AssemblyItem."Costing Method"::Standard, Item."No.", true, 1, 0, 0, LibraryRandom.RandInt(5), '', '');
        AssemblyItem.Get(FindComponentItem(Item."No."));

        // [GIVEN] Set the standard cost of item.
        AssemblyItem.Validate("Standard Cost", LibraryRandom.RandDec(100, 2));
        AssemblyItem.Modify(true);

        // [Give] Make sure we have enough inventory
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Order, Vendor."No.", Item."No.", 1000, '', 0D);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Order, Vendor."No.", AssemblyItem."No.", 1000, '', 0D);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create sales order with linked assembly order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", 2, '', WorkDate());

        SalesLine.Validate("Qty. to Assemble to Order", 2);
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Modify(true);

        // [Then] Post sales document in 2 seperate shipments.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);


        // [Then] Correct the posted sales invoice.
        SalesInvoiceHeader.Get(DocumentNo);
        Clear(SalesHeader);

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeader);

        // [THEN] System succesfully created new invoice with the lines copied from posted invoice with 2 seperate shipments.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.RecordCount(SalesLine, 1);

    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmAllHandler')]
    [Scope('OnPrem')]
    procedure CopyPostedSalesOrderLinkedWithTwoShipmentsAndAssemblyOrder()
    var
        Item: Record Item;
        AssemblyItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];

    begin
        // [SCENARIO 342934] copy posted sales order that is linked to two shiments and assembly to order
        Initialize();

        LibraryAssembly.SetStockoutWarning(false);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Assemble-to-order item "I".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);

        // [GIVEN] Create component "C" with "Standard" costing method and add it to the assembly BOM of item "I".
        LibraryAssembly.CreateAssemblyList(AssemblyItem."Costing Method"::Standard, Item."No.", true, 1, 0, 0, LibraryRandom.RandInt(5), '', '');
        AssemblyItem.Get(FindComponentItem(Item."No."));

        // [GIVEN] Set the standard cost of item.
        AssemblyItem.Validate("Standard Cost", LibraryRandom.RandDec(100, 2));
        AssemblyItem.Modify(true);

        // [Give] Make sure we have enough inventory
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Order, Vendor."No.", Item."No.", 1000, '', 0D);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Order, Vendor."No.", AssemblyItem."No.", 1000, '', 0D);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create sales order with linked assembly order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", 2, '', WorkDate());

        SalesLine.Validate("Qty. to Assemble to Order", 2);
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Modify(true);

        // [Then] Post sales document in 2 seperate shipments.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [Then] Copy Document from the posted sales invoice throw error
        // The posted sales invoice XXXX covers more than one shipment of linked assembly orders that potentially have different assembly components. Select Posted Shipment as document type, and then select a specific shipment of assembled items.
        SalesInvoiceHeader.Get(DocumentNo);
        Clear(SalesHeader);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        asserterror LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);

        if not GetLastErrorText().Contains('covers more than one shipment of linked assembly orders that potentially have different assembly components. Select Posted Shipment as document type, and then select a specific shipment of assembled items.') then
            Error('Unexpected error: %1', GetLastErrorText());
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyingSalesOrderWithATOAndRecalculateLinesFalseCopiesStandardCostFromSourceAsm()
    var
        Item: Record Item;
        CompItem: Record Item;
        SourceSalesHeader: Record "Sales Header";
        SourceSalesLine: Record "Sales Line";
        TargetSalesHeader: Record "Sales Header";
        AssemblyLine: Record "Assembly Line";
        UnitCost: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Assemble-to-Order] [Costing Method]
        // [SCENARIO 312542] Copying of sales order with linked assembly-to-order and turned OFF "Recalculate Lines" option copies unit cost of assembly component from the source assembly line, despite the changed standard cost.
        Initialize();

        LibraryAssembly.SetStockoutWarning(false);

        // [GIVEN] Assemble-to-order item "I".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);

        // [GIVEN] Create component "C" with "Standard" costing method and add it to the assembly BOM of item "I".
        LibraryAssembly.CreateAssemblyList(CompItem."Costing Method"::Standard, Item."No.", true, 1, 0, 0, LibraryRandom.RandInt(5), '', '');
        CompItem.Get(FindComponentItem(Item."No."));

        // [GIVEN] Set the standard cost of item "C" to "X" LCY.
        UnitCost := LibraryRandom.RandDec(100, 2);
        CompItem.Validate("Standard Cost", UnitCost);
        CompItem.Modify(true);

        // [GIVEN] Create sales order "SO-SOURCE" with linked assembly order.
        LibrarySales.CreateSalesDocumentWithItem(
          SourceSalesHeader, SourceSalesLine, SourceSalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", LibraryRandom.RandInt(10), '', WorkDate());

        // [GIVEN] Increase the standard cost of "C" to "2X" LCY.
        CompItem.Validate("Standard Cost", UnitCost * 2);
        CompItem.Modify(true);

        // [WHEN] Copy "SO-SOURCE" to new sales order "SO-TARGET".
        LibrarySales.CreateSalesHeader(
          TargetSalesHeader, TargetSalesHeader."Document Type"::Order, SourceSalesHeader."Sell-to Customer No.");
        LibrarySales.CopySalesDocument(TargetSalesHeader, "Sales Document Type From"::Order, SourceSalesHeader."No.", true, false);

        // [THEN] Copy is successful. No error message is thrown.
        // [THEN] "Unit Cost" of assembly component "C" in the assembly order linked to "SO-TARGET" is equal to "X".
        FindATOLine(AssemblyLine, TargetSalesHeader, CompItem."No.");
        AssemblyLine.TestField("Unit Cost", UnitCost);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyingSalesOrderWithATOAndRecalculateLinesTrueRetrievesStandardCostFromItemCard()
    var
        Item: Record Item;
        CompItem: Record Item;
        SourceSalesHeader: Record "Sales Header";
        SourceSalesLine: Record "Sales Line";
        TargetSalesHeader: Record "Sales Header";
        AssemblyLine: Record "Assembly Line";
        UnitCost: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Assemble-to-Order] [Costing Method]
        // [SCENARIO 312542] Copying of sales order with linked assembly-to-order and turned ON "Recalculate Lines" option retrieves unit cost of assembly component from the item card.
        Initialize();

        LibraryAssembly.SetStockoutWarning(false);

        // [GIVEN] Assemble-to-order item "I".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);

        // [GIVEN] Create component "C" with "Standard" costing method and add it to the assembly BOM of item "I".
        LibraryAssembly.CreateAssemblyList(CompItem."Costing Method"::Standard, Item."No.", true, 1, 0, 0, LibraryRandom.RandInt(5), '', '');
        CompItem.Get(FindComponentItem(Item."No."));

        // [GIVEN] Set the standard cost of item "C" to "X" LCY.
        UnitCost := LibraryRandom.RandDec(100, 2);
        CompItem.Validate("Standard Cost", UnitCost);
        CompItem.Modify(true);

        // [GIVEN] Create sales order "SO-SOURCE" with linked assembly order.
        LibrarySales.CreateSalesDocumentWithItem(
          SourceSalesHeader, SourceSalesLine, SourceSalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", LibraryRandom.RandInt(10), '', WorkDate());

        // [GIVEN] Increase the standard cost of "C" to "2X" LCY.
        CompItem.Validate("Standard Cost", UnitCost * 2);
        CompItem.Modify(true);

        // [WHEN] Copy "SO-SOURCE" to new sales order "SO-TARGET".
        LibrarySales.CreateSalesHeader(
          TargetSalesHeader, TargetSalesHeader."Document Type"::Order, SourceSalesHeader."Sell-to Customer No.");
        LibrarySales.CopySalesDocument(TargetSalesHeader, "Sales Document Type From"::Order, SourceSalesHeader."No.", true, true);

        // [THEN] Copy is successful. No error message is thrown.
        // [THEN] "Unit Cost" of assembly component "C" in the assembly order linked to "SO-TARGET" is equal to "2X".
        FindATOLine(AssemblyLine, TargetSalesHeader, CompItem."No.");
        AssemblyLine.TestField("Unit Cost", UnitCost * 2);
    end;

    [Test]
    procedure CopyItemChargeAssignmentFromPurchCreditMemo()
    var
        Vendor: Record Vendor;
        Item: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: array[2] of Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        CreditMemoNo: Code[20];
    begin
        // [FEATURE] [Item Charge] [Purchase] [Credit Memo] [Invoice]
        // [SCENARIO 387263] Correct distribution of item charge assignment when copying document from posted purchase credit memo.
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Create purchase order with two lines - item nos. "I1", "I2".
        // [GIVEN] Receive the purchase order.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Vendor."No.", Item[1]."No.",
          LibraryRandom.RandInt(10), '', WorkDate());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item[2]."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        FindPurchRcptLine(PurchRcptLine[1], PurchaseHeader."No.", Item[1]."No.");
        FindPurchRcptLine(PurchRcptLine[2], PurchaseHeader."No.", Item[2]."No.");

        // [GIVEN] Create purchase credit memo with item charge. Quantity = 1.
        // [GIVEN] Assign 0.25 to the receipt of item "I1".
        // [GIVEN] Assign 0.75 to the receipt of item "I2".
        // [GIVEN] Post the credit memo.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 4 * LibraryRandom.RandDecInRange(50, 100, 2));
        PurchaseLine.Modify(true);
        CreateItemChargeAssignmentPurch(PurchaseLine, PurchRcptLine[1]."Document No.", PurchRcptLine[1]."Line No.", Item[1]."No.", 0.25);
        CreateItemChargeAssignmentPurch(PurchaseLine, PurchRcptLine[2]."Document No.", PurchRcptLine[2]."Line No.", Item[2]."No.", 0.75);
        CreditMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Copy posted credit memo to a new purchase invoice.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CopyDocumentMgt.CopyPurchDoc("Purchase Document Type From"::"Posted Credit Memo", CreditMemoNo, PurchaseHeader);

        // [THEN] Open item charge assignment for the invoice.
        // [THEN] 0.25 of item charge is assigned to item "I1"
        ItemChargeAssignmentPurch.SetRange("Document Type", PurchaseHeader."Document Type");
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseHeader."No.");
        ItemChargeAssignmentPurch.SetRange("Item No.", Item[1]."No.");
        ItemChargeAssignmentPurch.FindFirst();
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", 0.25);

        // [THEN] 0.75 of item charge is assigned to item "I2"
        ItemChargeAssignmentPurch.SetRange("Item No.", Item[2]."No.");
        ItemChargeAssignmentPurch.FindFirst();
        ItemChargeAssignmentPurch.TestField("Qty. to Assign", 0.75);
    end;

    [Test]
    procedure CopyItemChargeAssignmentFromSalesCreditMemo()
    var
        Customer: Record Customer;
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: array[2] of Record "Sales Shipment Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        CreditMemoNo: Code[20];
    begin
        // [FEATURE] [Item Charge] [Sales] [Credit Memo] [Invoice]
        // [SCENARIO 387263] Correct distribution of item charge assignment when copying document from posted sales credit memo.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Create sales order with two lines - item nos. "I1", "I2".
        // [GIVEN] Ship the sales order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", Item[1]."No.",
          LibraryRandom.RandInt(10), '', WorkDate());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[2]."No.", LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        FindSalesShipmentLine(SalesShipmentLine[1], SalesHeader."No.", Item[1]."No.");
        FindSalesShipmentLine(SalesShipmentLine[2], SalesHeader."No.", Item[2]."No.");

        // [GIVEN] Create sales credit memo with item charge. Quantity = 1.
        // [GIVEN] Assign 0.25 to the shipment of item "I1".
        // [GIVEN] Assign 0.75 to the shipment of item "I2".
        // [GIVEN] Post the credit memo.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        SalesLine.Validate("Unit Price", 4 * LibraryRandom.RandDecInRange(50, 100, 2));
        SalesLine.Modify(true);
        CreateItemChargeAssignmentSales(
          SalesLine, SalesShipmentLine[1]."Document No.", SalesShipmentLine[1]."Line No.", Item[1]."No.", 0.25);
        CreateItemChargeAssignmentSales(
          SalesLine, SalesShipmentLine[2]."Document No.", SalesShipmentLine[2]."Line No.", Item[2]."No.", 0.75);
        CreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Copy posted credit memo to a new sales invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Credit Memo", CreditMemoNo, SalesHeader);

        // [THEN] Open item charge assignment for the invoice.
        // [THEN] 0.25 of item charge is assigned to item "I1"
        ItemChargeAssignmentSales.SetRange("Document Type", SalesHeader."Document Type");
        ItemChargeAssignmentSales.SetRange("Document No.", SalesHeader."No.");
        ItemChargeAssignmentSales.SetRange("Item No.", Item[1]."No.");
        ItemChargeAssignmentSales.FindFirst();
        ItemChargeAssignmentSales.TestField("Qty. to Assign", 0.25);

        // [THEN] 0.75 of item charge is assigned to item "I2"
        ItemChargeAssignmentSales.SetRange("Item No.", Item[2]."No.");
        ItemChargeAssignmentSales.FindFirst();
        ItemChargeAssignmentSales.TestField("Qty. to Assign", 0.75);
    end;

    [Test]
    procedure QtyToAssembleToOrderZeroOnSalesOrderCopiedFromDropShipment()
    var
        Purchasing: Record Purchasing;
        AsmItem: Record Item;
        CompItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewSalesHeader: Record "Sales Header";
        NewSalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Drop Shipment] [Assemble-to-Order]
        // [SCENARIO 439592] No error and "Qty. to Assemble to Order" = 0 on a sales order line copied from the existing one for drop shipment.
        Initialize();

        // [GIVEN] Purchasing code "P" for drop shipment.
        LibraryPurchase.CreateDropShipmentPurchasingCode(Purchasing);

        // [GIVEN] New assembly item set up for assemble-to-order.
        // [GIVEN] Set "Purchasing Code" = "P" on the item.
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Validate("Purchasing Code", Purchasing.Code);
        AsmItem.Modify(true);

        // [GIVEN] Create component item and post it to inventory.
        LibraryAssembly.CreateAssemblyList(AsmItem."Costing Method", AsmItem."No.", true, 1, 0, 0, 1, '', '');
        CompItem.Get(FindComponentItem(AsmItem."No."));
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, CompItem."No.", '', '', LibraryRandom.RandIntInRange(100, 200));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order. Ensure that "Purchasing Code" = "P" and "Qty. to Assemble to Order" = 0.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          AsmItem."No.", LibraryRandom.RandInt(10), '', WorkDate());
        SalesLine.TestField("Purchasing Code", Purchasing.Code);
        SalesLine.TestField("Qty. to Assemble to Order", 0);

        // [WHEN] Create a new sales order and copy it from the previous one.
        LibrarySales.CreateSalesHeader(
          NewSalesHeader, NewSalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Order, SalesHeader."No.", NewSalesHeader);

        // [THEN] The new sales line has "Purchasing Code" = "P" and "Qty. to Assemble to Order" = 0.
        NewSalesLine.SetRange(Type, NewSalesLine.Type::Item);
        FindSalesLine(NewSalesHeader, NewSalesLine);
        NewSalesLine.TestField("Purchasing Code", Purchasing.Code);
        NewSalesLine.TestField(Quantity, SalesLine.Quantity);
        NewSalesLine.TestField("Qty. to Assemble to Order", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopySalesDocumentHandler')]
    procedure CheckLineCaptionWhenSalesDocumentCopied()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 556718] Check Sales Document Caption after copy document.
        Initialize();

        // [GIVEN] Create Sales Invoice and Post.
        DocumentNo := CreateAndPostSalesInvoice(Customer);

        // [GIVEN] Modify Customer.
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify(true);

        // [GIVEN] Enqueue Multiple Values.
        EnqueueCopyDocumentReqpageParameters("Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);

        // [GIVEN] Create a new Sales Invoice.
        CreateEmptySalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Modify(true);

        // [GIVEN] Open Sales Invoice Page.
        SalesInvoice.OpenNew();
        SalesInvoice.GoToRecord(SalesHeader);
        Commit();

        // [WHEN] Copy the Posted Document.
        SalesInvoice.CopyDocument.Invoke();

        // [THEN] Verify Sales Line Field Caption.
        VerifySalesDocumentCaption(SalesInvoice);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopyPurchaseDocumentHandler')]
    procedure CheckLineCaptionWhenPurchaseDocumentCopied()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseInvoice: TestPage "Purchase Invoice";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 556718] Check Purchase Document Caption after copy document.
        Initialize();

        // [GIVEN] Create Purchase Invoice and Post.
        DocumentNo := CreateAndPostPurchaseInvoice(Vendor);

        // [GIVEN] Modify Vendor.
        Vendor.Validate("Prices Including VAT", true);
        Vendor.Modify(true);

        // [GIVEN] Enqueue Multiple Values.
        EnqueueCopyDocumentReqpageParameters("Sales Document Type From"::"Posted Invoice", DocumentNo, true, true);

        // [GIVEN] Create a new Purchase Invoice.
        CreateEmptyPurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Validate("Prices Including VAT", false);
        PurchaseHeader.Modify(true);

        // [GIVEN] Open Purchase Invoice Page.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeader);
        Commit();

        // [WHEN] Copy the Posted Document.
        PurchaseInvoice.CopyDocument.Invoke();

        // [THEN] Verify Purchase Line Field Caption.
        VerifyPurchaseDocumentCaption(PurchaseInvoice);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopySalesDocumentHandler')]
    [Scope('OnPrem')]
    procedure CheckGlobalDimensionsOnSalesDocumentWhenCopyDocument()
    var
        Customer: Record Customer;
        SalesHeader: array[2] of Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
        DocumentNo: Code[20];
    begin
        Initialize();
        // [SCENARIO 557528] Verify Global Dimension and Shortcut Dimension on Sales Document.

        // [GIVEN] Create Customer with Shortcut Dimension.
        CreateCustomerWithMultipleDimension(Customer);

        // [GIVEN] Create a Sales Invoice with Global Dimensions.
        CreateSalesDocumentWithGlobalDimension(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader[1], false, true);

        // [GIVEN] Create Empty Sales Invoice.
        CreateEmptySalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice);

        // [GIVEN] Open Sales Invoice Page.
        SalesInvoice.OpenEdit();
        SalesInvoice.GoToRecord(SalesHeader[2]);

        // [GIVEN] Enqueue the Request Page Parmeters.
        EnqueueCopyDocumentReqpageParameters("Sales Document Type From"::"Posted Invoice", DocumentNo, true, true);
        Commit();

        // [WHEN] Copy Sales Invoice From Posted Invoice.
        SalesInvoice.CopyDocument.Invoke();

        // [THEN] Verify Sales Document Dimensions.
        VerifySalesDocumentDimensions(SalesInvoice, SalesHeader[2], DocumentNo);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyPurchaseDocumentHandler')]
    [Scope('OnPrem')]
    procedure CheckGlobalDimensionsOnPurchaseDocumentWhenCopyDocument()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        Vendor: Record Vendor;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PurchaseInvoice: TestPage "Purchase Invoice";
        DocumentNo: Code[20];
    begin
        Initialize();
        // [SCENARIO 557528] Verify Global Dimension and Shortcut Dimension on Purchase Document.

        // [GIVEN] Create Vendor with Shortcut Dimension
        CreateVendorWithMultipleDimension(Vendor);

        // [GIVEN] Create a Purchase Invoice with Global Dimensions.
        CreatePurchaseDocumentWithGlobalDimension(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Post Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], false, true);

        // [GIVEN] Create Empty Purchase Invoice.
        CreateEmptyPurchHeader(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice);

        // [GIVEN] Open Purchase Invoice Page.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeader[2]);

        // [GIVEN] Enqueue the Request Page Parmeters.
        EnqueueCopyDocumentReqpageParameters("Purchase Document Type From"::"Posted Invoice", DocumentNo, true, true);
        Commit();

        // [WHEN] Copy Purchase Invoice From Posted Invoice.
        PurchaseInvoice.CopyDocument.Invoke();

        // [THEN] Verify Purchase Document Dimensions.
        VerifyPurchaseDocumentDimensions(PurchaseInvoice, PurchaseHeader[2], DocumentNo);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure OverReceivingPurchaseLineWithChargeItem()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: array[2] of Decimal;
    begin
        // [SCENARIO 562447] Check error while Over-Receive with "Charge Item".
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Generate Quanity.
        Quantity[1] := LibraryRandom.RandInt(10);
        Quantity[2] := Quantity[1] + LibraryRandom.RandInt(10);

        // [GIVEN] Create Purchase Order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create Purchase Line with "Charge Item".
        CreateItemChargePurchaseLineWithoutAssignment(PurchaseLine, PurchaseHeader, Quantity[1]);

        // [WHEN] Over-Receive "Charge Item".
        asserterror UpdateQtyToReceiveOnPurchaseLines(PurchaseHeader, Quantity[2]);

        // [THEN] Verify Error message.
        Assert.ExpectedError(StrSubstNo(OverReceiveError, PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.", PurchaseLine.Type));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Copy Document Mgt.");

        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        CopyDocumentMgt.SetProperties(true, false, false, false, true, false, false);
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Copy Document Mgt.");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySales.SetCreditWarningsToNoWarnings();

        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Copy Document Mgt.");
    end;

    local procedure CreateSourceDocument(Type: Enum "Sales Document Type From"; TypeBeforePosting: Enum "Sales Document Type") DocNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        DocNo := CreateSalesOrder(SalesHeader, TypeBeforePosting, CreateCustomer());

        case Type of
            "Sales Document Type From"::"Posted Shipment",
            "Sales Document Type From"::"Posted Invoice",
            "Sales Document Type From"::"Posted Return Receipt",
            "Sales Document Type From"::"Posted Credit Memo":
                begin
                    CreateItemChargeAssignment(SalesHeader);
                    LibrarySales.PostSalesDocument(SalesHeader, true, true);
                end;
        end;

        case Type of
            "Sales Document Type From"::"Posted Credit Memo":
                begin
                    SalesCrMemoHeader.SetRange("Return Order No.", SalesHeader."No.");
                    SalesCrMemoHeader.FindFirst();
                    DocNo := SalesCrMemoHeader."No.";
                end;
            "Sales Document Type From"::"Posted Shipment":
                begin
                    SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
                    SalesShipmentHeader.FindFirst();
                    DocNo := SalesShipmentHeader."No.";
                end;
            "Sales Document Type From"::"Posted Invoice":
                begin
                    SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
                    SalesInvoiceHeader.FindFirst();
                    DocNo := SalesInvoiceHeader."No.";
                end;
            "Sales Document Type From"::"Posted Return Receipt":
                begin
                    ReturnReceiptHeader.SetRange("Return Order No.", SalesHeader."No.");
                    ReturnReceiptHeader.FindFirst();
                    DocNo := ReturnReceiptHeader."No.";
                end;
        end;

        exit(DocNo);
    end;

    local procedure CopyToDestinationSalesDocument(SourceType: Enum "Sales Document Type From"; SourceNo: Code[20]; var SalesHeader: Record "Sales Header"): Code[20]
    begin
        CopyDocumentMgt.CopySalesDoc(SourceType, SourceNo, SalesHeader);
        exit(SalesHeader."No.");
    end;

    local procedure CopyToDestinationPurchaseDocument(SourceType: Enum "Purchase Document Type From"; SourceNo: Code[20]; var PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        CopyDocumentMgt.CopyPurchDoc(SourceType, SourceNo, PurchaseHeader);
        exit(PurchaseHeader."No.");
    end;

    local procedure CopyPurchDocument(var PurchaseHeader: Record "Purchase Header"; SourceType: Enum "Purchase Document Type From"; SourceNo: Code[20])
    begin
        CreateEmptyPurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        CopyDocumentMgt.SetProperties(true, false, false, false, true, false, false);
        CopyDocumentMgt.CopyPurchDoc(SourceType, SourceNo, PurchaseHeader, true);
    end;

    local procedure CopyDimensionsSalesDocument(RecalculateLines: Boolean)
    var
        SalesHeader: Record "Sales Header";
        DocNo: Code[20];
        DimensionSetID: Integer;
    begin
        Initialize();
        CopyDocumentMgt.SetProperties(true, RecalculateLines, false, false, true, false, false);

        CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        CreateItemChargeAssignment(SalesHeader);
        DimensionSetID := SalesHeader."Dimension Set ID";
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CreateEmptySalesHeader(SalesHeader, SalesHeader."Document Type"::Order);
        CopyToDestinationSalesDocument("Sales Document Type From"::"Posted Invoice", DocNo, SalesHeader);

        VerifySalesDocumentDimension(SalesHeader, DimensionSetID);
    end;

    local procedure CopyDimensionsPurchaseDocument(RecalculateLines: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        DocNo: Code[20];
        DimensionSetID: Integer;
    begin
        Initialize();
        CopyDocumentMgt.SetProperties(true, RecalculateLines, false, false, true, false, false);

        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        PurchaseHeader."Dimension Set ID" := UpdateDimensionSet(PurchaseHeader."Dimension Set ID");
        DimensionSetID := PurchaseHeader."Dimension Set ID";
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        CreateEmptyPurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        CopyToDestinationPurchaseDocument("Purchase Document Type From"::"Posted Invoice", DocNo, PurchaseHeader);

        VerifyPurchaseDocumentDimension(PurchaseHeader, DimensionSetID);
    end;

    local procedure CreateItemChargePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; AppliesToDocNo: Code[20]; AppliesToDocLineNo: Integer; ItemNo: Code[20]; Quantity: Decimal; QtyToAssign: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", '', Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        CreateItemChargeAssignmentPurch(PurchaseLine, AppliesToDocNo, AppliesToDocLineNo, ItemNo, QtyToAssign);
    end;

    local procedure CreateItemChargeSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; AppliesToDocNo: Code[20]; AppliesToDocLineNo: Integer; ItemNo: Code[20]; Quantity: Decimal; QtyToAssign: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", '', Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        CreateItemChargeAssignmentSales(SalesLine, AppliesToDocNo, AppliesToDocLineNo, ItemNo, QtyToAssign);
    end;

    local procedure CreatePurchaseInvoiceCopyFromReceipt(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; CopyFromDocNoFilter: Text)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        GetPurchaseReceiptLines(PurchaseHeader, CopyFromDocNoFilter);
    end;

    local procedure CreateSalesInvoiceCopyFromShipment(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CopyFromDocNoFilter: Text)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        GetSalesShipmentLines(SalesHeader, CopyFromDocNoFilter);
    end;

    local procedure CreatePurchaseCrMemoCopyFromReturnShipment(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; CopyFromDocNoFilter: Text)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        GetReturnShipmentLines(PurchaseHeader, CopyFromDocNoFilter);
    end;

    local procedure CreateSalesCrMemoCopyFromReturnReceipt(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CopyFromDocNoFilter: Text)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        GetReturnReceiptLines(SalesHeader, CopyFromDocNoFilter);
    end;

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateEmptySalesHeader(SalesHeader, SalesHeader."Document Type"::Quote);
        SalesHeader."Document Date" := WorkDate();
        SalesHeader.Modify();
        CreateBlankSalesLine(SalesHeader, SalesLine, SalesHeader."Document Type");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount(), 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, LibraryResource.CreateResourceNo(), 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", CreateItemCharge(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10000) / 100);
        SalesLine.Modify(true);

        exit(SalesHeader."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), 1);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateEmptySalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"): Code[20]
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);
        exit(SalesHeader."No.");
    end;

    local procedure CreateEmptyPurchHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"): Code[20]
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader.Insert(true);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateItemCharge(): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Next(LibraryRandom.RandInt(ItemCharge.Count));
        exit(ItemCharge."No.");
    end;

    local procedure CreateItemChargeAssignment(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindFirst();

        SalesLine2.SetRange("Document No.", SalesHeader."No.");
        SalesLine2.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine2.SetRange(Type, SalesLine2.Type::Item);
        SalesLine2.FindFirst();

        LibraryInventory.CreateItemChargeAssignment(ItemChargeAssignmentSales,
          SalesLine, SalesLine2."Document Type", SalesLine2."Document No.",
          SalesLine2."Line No.", SalesLine2."No.");
    end;

    local procedure CreateItemChargeAssignmentPurch(PurchaseLine: Record "Purchase Line"; AppliesToDocNo: Code[20]; AppliesToDocLineNo: Integer; ItemNo: Code[20]; QtyToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          AppliesToDocNo, AppliesToDocLineNo, ItemNo);
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", QtyToAssign);
        ItemChargeAssignmentPurch.Modify(true);
    end;

    local procedure CreateItemChargeAssignmentSales(SalesLine: Record "Sales Line"; AppliesToDocNo: Code[20]; AppliesToDocLineNo: Integer; ItemNo: Code[20]; QtyToAssign: Decimal)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
          AppliesToDocNo, AppliesToDocLineNo, ItemNo);
        ItemChargeAssignmentSales.Validate("Qty. to Assign", QtyToAssign);
        ItemChargeAssignmentSales.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        GenProdPostingGroup.SetFilter("Def. VAT Prod. Posting Group", '<>%1', '');
        GenProdPostingGroup.Next(LibraryRandom.RandInt(GenProdPostingGroup.Count));
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
        GenBusPostingGroup.Next(LibraryRandom.RandInt(GenBusPostingGroup.Count));
        GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryInventory.CreateItem(Item);
        GenerateDimensions(Dimension, DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", Dimension.Code, DimensionValue.Code);
        exit(Item."No.");
    end;

    local procedure CreateLotTrackedItem(): Code[20]
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
        exit(Item."No.");
    end;

    local procedure CreateSNTrackedItem(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("SN Specific Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateCustomer(Customer);
        GenerateDimensions(Dimension, DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code);
        exit(Customer."No.");
    end;

    local procedure CreateBlankSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        RecRef: RecordRef;
    begin
        Clear(SalesLine);
        SalesLine.Init();
        SalesLine.Validate("Document Type", DocumentType);
        SalesLine.Validate("Document No.", SalesHeader."No.");
        RecRef.GetTable(SalesLine);
        SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
        SalesLine.Validate(Description, Format(CreateGuid()));
        SalesLine.Insert(true);
    end;

    local procedure CreateAndPostPurchOrderWithTracking(ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
        PurchaseLine.OpenItemTrackingLines();
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesOrderWithTracking(ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndPostSalesOrderWithAsmToOrderAndTracking(CustomerNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; ItemTracking: Option): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, ItemNo, Qty, '', WorkDate());
        LibraryAssembly.FindLinkedAssemblyOrder(AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        LibraryVariableStorage.Enqueue(ItemTracking);
        AssemblyHeader.OpenItemTrackingLines();
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        GenerateDimensions(Dimension, DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", Dimension.Code, DimensionValue.Code);
        exit(Vendor."No.");
    end;

    local procedure GetPurchaseReceiptLines(PurchaseHeader: Record "Purchase Header"; ReceiptNoFilter: Text)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptLine.SetFilter("Document No.", ReceiptNoFilter);
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure GetPurchaseReceiptLineWithOrderNo(PurchaseHeader: Record "Purchase Header"; ReceiptNo: Code[20]; LineOrderNo: Integer)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptLine.SetRange("Document No.", ReceiptNo);
        PurchRcptLine.SetRange("Line No.", FindPurchRcptLineNo(ReceiptNo, LineOrderNo));
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure GetSalesShipmentLines(SalesHeader: Record "Sales Header"; ShipmentNoFilter: Text)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentLine.SetFilter("Document No.", ShipmentNoFilter);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
    end;

    local procedure GetSalesShipmentLineWithOrderNo(SalesHeader: Record "Sales Header"; ShipmentNo: Code[20]; LineOrderNo: Integer)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentLine.SetRange("Document No.", ShipmentNo);
        SalesShipmentLine.SetRange("Line No.", FindSalesShptLineNo(ShipmentNo, LineOrderNo));
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
    end;

    local procedure GetReturnShipmentLines(PurchaseHeader: Record "Purchase Header"; ReturnShipmentNoFilter: Text)
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        ReturnShipmentLine.SetFilter("Document No.", ReturnShipmentNoFilter);
        PurchGetReturnShipments.SetPurchHeader(PurchaseHeader);
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);
    end;

    local procedure GetReturnReceiptLines(SalesHeader: Record "Sales Header"; ReturnReceiptNoFilter: Text)
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        ReturnReceiptLine.SetFilter("Document No.", ReturnReceiptNoFilter);
        SalesGetReturnReceipts.SetSalesHeader(SalesHeader);
        SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);
    end;

    local procedure PostSalesOrderWithUpdatedDimensions(var SalesLine: Record "Sales Line"; var PostedDocNo: Code[20]) DefaultDimSetID: Integer
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        DefaultDimSetID := SalesLine."Dimension Set ID";
        SalesLine."Dimension Set ID" := UpdateDimensionSet(SalesLine."Dimension Set ID");
        SalesLine.Modify();
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(DefaultDimSetID);
    end;

    local procedure PostPurchOrderWithUpdatedDimensions(var PurchLine: Record "Purchase Line"; var PostedDocNo: Code[20]) DefaultDimSetID: Integer
    var
        PurchHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        DefaultDimSetID := PurchLine."Dimension Set ID";
        PurchLine."Dimension Set ID" := UpdateDimensionSet(PurchLine."Dimension Set ID");
        PurchLine.Modify();
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        exit(DefaultDimSetID);
    end;

    local procedure FindComponentItem(ParentItemNo: Code[20]): Code[20]
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.FindFirst();
        exit(BOMComponent."No.");
    end;

    local procedure FindDimension(var Dimension: Record Dimension; var DimensionValueCode: Code[20]; DimensionSetId: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetId);
        DimensionSetEntry.FindFirst();
        DimensionValueCode := DimensionSetEntry."Dimension Value Code";
        Dimension.Get(DimensionSetEntry."Dimension Code");
    end;

    local procedure FindDimensionValue(var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20]; OldDimensionValueCode: Code[20])
    begin
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetFilter(Code, '<>%1', OldDimensionValueCode);
        DimensionValue.FindFirst();
    end;

    local procedure FindSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; OrderNo: Code[20]; ItemNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.FindFirst();
    end;

    local procedure FindSalesShptLineNo(SalesShptNo: Code[20]; LineOrderNo: Integer): Integer
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", SalesShptNo);
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.FindSet();
        SalesShipmentLine.Next(LineOrderNo - 1);

        exit(SalesShipmentLine."Line No.");
    end;

    local procedure FindPurchLine(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindLast();
    end;

    local procedure FindPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20]; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindPurchRcptLineNo(PurchRcptNo: Code[20]; LineOrderNo: Integer): Integer
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", PurchRcptNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.FindSet();
        PurchRcptLine.Next(LineOrderNo - 1);

        exit(PurchRcptLine."Line No.");
    end;

    local procedure FindATOLine(var AssemblyLine: Record "Assembly Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        AssembleToOrderLink.SetRange("Document Type", SalesHeader."Document Type");
        AssembleToOrderLink.SetRange("Document No.", SalesHeader."No.");
        AssembleToOrderLink.FindFirst();
        AssemblyLine.SetRange("Document Type", AssembleToOrderLink."Assembly Document Type");
        AssemblyLine.SetRange("Document No.", AssembleToOrderLink."Assembly Document No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.SetRange("No.", ItemNo);
        AssemblyLine.FindFirst();
    end;

    local procedure GenerateDimensions(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value")
    var
        "Count": Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);
        Count := LibraryRandom.RandIntInRange(5, 10);
        while Count > 0 do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
            Count -= 1;
        end;
    end;

    local procedure UpdateDimensionSet(DimensionSetID: Integer): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        OldDimensionValueCode: Code[20];
    begin
        FindDimension(Dimension, OldDimensionValueCode, DimensionSetID);
        FindDimensionValue(DimensionValue, Dimension.Code, OldDimensionValueCode);
        exit(LibraryDimension.EditDimSet(DimensionSetID, Dimension.Code, DimensionValue.Code));
    end;

    local procedure UpdateQtyToReceiveOnPurchaseLines(PurchaseHeader: Record "Purchase Header"; QtyToReceive: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure UpdateReturnQtyToShipOnPurchaseLines(PurchaseHeader: Record "Purchase Header"; ReturnQtyToShip: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Return Qty. to Ship", ReturnQtyToShip);
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure UpdateQtyToShipOnSalesLines(SalesHeader: Record "Sales Header"; QtyToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Qty. to Ship", QtyToShip);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure UpdateReturnQtyToReceiveOnSalesLines(SalesHeader: Record "Sales Header"; ReturnQtyToReceive: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Return Qty. to Receive", ReturnQtyToReceive);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyCopy(SourceType: Enum "Sales Document Type From"; SourceNo: Code[20]; DestType: Enum "Sales Document Type"; DestNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Get(DestType, DestNo);
        SalesLine.SetRange("Document No.", DestNo);
        SalesLine.SetRange("Document Type", DestType);
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.FindSet();

        case SourceType of
            "Sales Document Type From"::Order,
            "Sales Document Type From"::"Return Order",
            "Sales Document Type From"::"Credit Memo",
            "Sales Document Type From"::Quote,
            "Sales Document Type From"::Invoice,
            "Sales Document Type From"::"Blanket Order":
                ValidateCopiedSalesHeader(SalesHeader, SalesLine, SourceType, SourceNo);
            "Sales Document Type From"::"Posted Credit Memo":
                ValidateCopiedCrMemoHeader(SalesHeader, SalesLine, SourceNo);
            "Sales Document Type From"::"Posted Shipment":
                ValidateCopiedShipmentHeader(SalesHeader, SalesLine, SourceNo);
            "Sales Document Type From"::"Posted Invoice":
                ValidateCopiedInvoiceHeader(SalesHeader, SalesLine, SourceNo);
            "Sales Document Type From"::"Posted Return Receipt":
                ValidateCopiedReceiptHeader(SalesHeader, SalesLine, SourceNo);
        end;

        Assert.IsTrue(SalesLine.Next() = 0,
          'Unexpected remaining data in destination document');
    end;

    local procedure VerifyItemChargeAssignmentPurchCopied(FromDocType: Enum "Purchase Document Type"; FromDocNo: Code[20]; ToDocType: Enum "Purchase Document Type"; ToDocNo: Code[20])
    var
        FromItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        FromItemChargeAssignmentPurch.SetRange("Document Type", FromDocType);
        FromItemChargeAssignmentPurch.SetRange("Document No.", FromDocNo);
        ToItemChargeAssignmentPurch.SetRange("Document Type", ToDocType);
        ToItemChargeAssignmentPurch.SetRange("Document No.", ToDocNo);
        FromItemChargeAssignmentPurch.FindSet();
        repeat
            ToItemChargeAssignmentPurch.SetRange("Item Charge No.", FromItemChargeAssignmentPurch."Item Charge No.");
            ToItemChargeAssignmentPurch.FindFirst();
            ToItemChargeAssignmentPurch.TestField("Qty. to Assign", FromItemChargeAssignmentPurch."Qty. to Assign");
        until FromItemChargeAssignmentPurch.Next() = 0;
    end;

    local procedure VerifyItemChargeAssignmentSalesCopied(FromDocType: Enum "Sales Document Type"; FromDocNo: Code[20]; ToDocType: Enum "Sales Document Type"; ToDocNo: Code[20])
    var
        FromItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        FromItemChargeAssignmentSales.SetRange("Document Type", FromDocType);
        FromItemChargeAssignmentSales.SetRange("Document No.", FromDocNo);
        ToItemChargeAssignmentSales.SetRange("Document Type", ToDocType);
        ToItemChargeAssignmentSales.SetRange("Document No.", ToDocNo);
        FromItemChargeAssignmentSales.FindSet();
        repeat
            ToItemChargeAssignmentSales.SetRange("Item Charge No.", FromItemChargeAssignmentSales."Item Charge No.");
            ToItemChargeAssignmentSales.FindFirst();
            ToItemChargeAssignmentSales.TestField("Qty. to Assign", FromItemChargeAssignmentSales."Qty. to Assign");
        until FromItemChargeAssignmentSales.Next() = 0;
    end;

    local procedure VerifyShipmntItemChargeAssngmt(SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssignmentSales.SetRange("Document No.", SalesHeader."No.");
        ItemChargeAssignmentSales.SetRange("Document Type", SalesHeader."Document Type");
        ItemChargeAssignmentSales.FindSet();

        Assert.AreEqual(
          ItemChargeAssignmentSales."Applies-to Doc. Type",
          ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
          StrSubstNo('Item Charge Assignment should apply to Posted Shipment. Type was %1.',
            ItemChargeAssignmentSales."Applies-to Doc. Type"));
        Assert.AreEqual(ItemChargeAssignmentSales."Item No.", ItemNo,
          StrSubstNo('Wrong Item No. when validating Item Charge Assignment on Shipment. Was %1, expected %2.',
            ItemChargeAssignmentSales."Item No.", ItemNo));

        Assert.IsTrue(
          ItemChargeAssignmentSales.Next() = 0,
          'Unexpected data in item charge assignment');
    end;

    local procedure ValidateCopiedSalesHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SourceType: Enum "Sales Document Type From"; SourceNo: Code[20])
    var
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
    begin
        SalesHeader2.Get(CopyDocumentMgt.GetSalesDocumentType(SourceType), SourceNo);
        SalesHeader.TestField("Sell-to Customer No.", SalesHeader2."Sell-to Customer No.");
        SalesLine2.SetRange("Document No.", SourceNo);
        SalesLine2.SetRange("Document Type", CopyDocumentMgt.GetSalesDocumentType(SourceType));
        SalesLine2.SetFilter(Type, '<>%1', SalesLine2.Type::" ");
        SalesLine2.FindSet();
        repeat
            SalesLine.TestField(Type, SalesLine2.Type);
            SalesLine.TestField("No.", SalesLine2."No.");
            SalesLine.TestField(Quantity, SalesLine2.Quantity);
            SalesLine.TestField("Unit of Measure", SalesLine2."Unit of Measure");
            SalesLine.TestField("Unit Price", SalesLine2."Unit Price");
            SalesLine.TestField("Location Code", SalesLine2."Location Code");
        until (SalesLine2.Next() = 0) and (SalesLine.Next() = 0);
        Assert.IsTrue(SalesLine2.Next() = 0,
          'Unexpected remaining data in source document');
    end;

    local procedure ValidateCopiedCrMemoHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SourceNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader.Get(SourceNo);
        SalesHeader.TestField("Sell-to Customer No.", SalesCrMemoHeader."Sell-to Customer No.");
        SalesCrMemoLine.SetRange("Document No.", SourceNo);
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        SalesCrMemoLine.FindSet();
        repeat
            SalesLine.TestField(Type, SalesCrMemoLine.Type);
            SalesLine.TestField("No.", SalesCrMemoLine."No.");
            SalesLine.TestField(Quantity, SalesCrMemoLine.Quantity);
            SalesLine.TestField("Unit of Measure", SalesCrMemoLine."Unit of Measure");
            SalesLine.TestField("Unit Price", SalesCrMemoLine."Unit Price");
            SalesLine.TestField("Location Code", SalesCrMemoLine."Location Code");
        until (SalesCrMemoLine.Next() = 0) and (SalesLine.Next() = 0);
        Assert.IsTrue(SalesCrMemoLine.Next() = 0,
          'Unexpected remaining data in source document');
    end;

    local procedure ValidateCopiedShipmentHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SourceNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentHeader.Get(SourceNo);
        SalesHeader.TestField("Sell-to Customer No.", SalesShipmentHeader."Sell-to Customer No.");
        SalesShipmentLine.SetRange("Document No.", SourceNo);
        SalesShipmentLine.SetFilter(Type, '<>%1', SalesShipmentLine.Type::" ");
        SalesShipmentLine.FindSet();
        repeat
            SalesLine.TestField(Type, SalesShipmentLine.Type);
            SalesLine.TestField("No.", SalesShipmentLine."No.");
            SalesLine.TestField(Quantity, SalesShipmentLine.Quantity);
            SalesLine.TestField("Unit of Measure", SalesShipmentLine."Unit of Measure");
            SalesLine.TestField("Unit Price", SalesShipmentLine."Unit Price");
            SalesLine.TestField("Location Code", SalesShipmentLine."Location Code");
        until (SalesShipmentLine.Next() = 0) and (SalesLine.Next() = 0);
        Assert.IsTrue(SalesShipmentLine.Next() = 0,
          'Unexpected remaining data in source document');
    end;

    local procedure ValidateCopiedInvoiceHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SourceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.Get(SourceNo);
        SalesHeader.TestField("Sell-to Customer No.", SalesInvoiceHeader."Sell-to Customer No.");
        SalesInvoiceLine.SetRange("Document No.", SourceNo);
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        SalesInvoiceLine.FindSet();
        repeat
            SalesLine.TestField(Type, SalesInvoiceLine.Type);
            SalesLine.TestField("No.", SalesInvoiceLine."No.");
            SalesLine.TestField(Quantity, SalesInvoiceLine.Quantity);
            SalesLine.TestField("Unit of Measure", SalesInvoiceLine."Unit of Measure");
            SalesLine.TestField("Unit Price", SalesInvoiceLine."Unit Price");
            SalesLine.TestField("Location Code", SalesInvoiceLine."Location Code");
        until (SalesInvoiceLine.Next() = 0) and (SalesLine.Next() = 0);
        Assert.IsTrue(SalesInvoiceLine.Next() = 0,
          'Unexpected remaining data in source document');
    end;

    local procedure ValidateCopiedReceiptHeader(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SourceNo: Code[20])
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptHeader.Get(SourceNo);
        SalesHeader.TestField("Sell-to Customer No.", ReturnReceiptHeader."Sell-to Customer No.");
        ReturnReceiptLine.SetRange("Document No.", SourceNo);
        ReturnReceiptLine.SetFilter(Type, '<>%1', ReturnReceiptLine.Type::" ");
        ReturnReceiptLine.FindSet();
        repeat
            SalesLine.TestField(Type, ReturnReceiptLine.Type);
            SalesLine.TestField("No.", ReturnReceiptLine."No.");
            SalesLine.TestField(Quantity, ReturnReceiptLine.Quantity);
            SalesLine.TestField("Unit of Measure", ReturnReceiptLine."Unit of Measure");
            SalesLine.TestField("Unit Price", ReturnReceiptLine."Unit Price");
            SalesLine.TestField("Location Code", ReturnReceiptLine."Location Code");
        until (ReturnReceiptLine.Next() = 0) and (SalesLine.Next() = 0);
        Assert.IsTrue(ReturnReceiptLine.Next() = 0,
          'Unexpected remaining data in source document');
    end;

    local procedure ValidateCopiedSalesHeaderAndSalesLines(var SalesHeader: Record "Sales Header"; FromType: Enum "Sales Document Type"; FromDocNo: Code[20])
    var
        FromSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        FromSalesHeader.Get(FromType, FromDocNo);
        FindSalesLine(FromSalesHeader, SalesLine);
        FindSalesLine(SalesHeader, SalesLine2);
        repeat
            SalesLine2.TestField(Type, SalesLine.Type);
            SalesLine2.TestField("No.", SalesLine."No.");
        until (SalesLine2.Next() = 0) and (SalesLine.Next() = 0);
    end;

    local procedure VerifySNItemTrackingOnSalesLine(SalesLine: Record "Sales Line"; Qty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        SalesLine.SetReservationFilters(ReservationEntry);
        ReservationEntry.SetRange("Item Tracking", ReservationEntry."Item Tracking"::"Serial No.");
        Assert.RecordCount(ReservationEntry, Qty);
    end;

    local procedure VerifySalesDocumentDimension(var SalesHeader: Record "Sales Header"; ExpectedDimensionSetID: Integer)
    begin
        Assert.AreEqual(ExpectedDimensionSetID, SalesHeader."Dimension Set ID", WrongDimensionsCopiedErr);
    end;

    local procedure VerifyPurchaseDocumentDimension(var PurchaseHeader: Record "Purchase Header"; ExpectedDimensionSetID: Integer)
    begin
        Assert.AreEqual(ExpectedDimensionSetID, PurchaseHeader."Dimension Set ID", WrongDimensionsCopiedErr);
    end;

    local procedure VerifyCopySalesLinesNos(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; LineType: Enum "Sales Line Type"; ItemNo1: Code[20]; ItemNo2: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, LineType);
        SalesLine.FindSet();
        Assert.AreEqual(ItemNo1, SalesLine."No.", '');
        SalesLine.Next();
        Assert.AreEqual(ItemNo2, SalesLine."No.", '');
        Assert.AreEqual(0, SalesLine.Next(), 'Unexpected remaining data in source document');
    end;

    local procedure VerifyCopyPurchLinesNos(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; LineType: Enum "Purchase Line Type"; ItemNo1: Code[20]; ItemNo2: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, LineType);
        PurchaseLine.FindSet();
        Assert.AreEqual(ItemNo1, PurchaseLine."No.", '');
        PurchaseLine.Next();
        Assert.AreEqual(ItemNo2, PurchaseLine."No.", '');
        Assert.AreEqual(0, PurchaseLine.Next(), 'Unexpected remaining data in source document');
    end;

    local procedure VerifyQtyToAssignOnPurchInvoiceLine(PurchaseHeader: Record "Purchase Header"; PurchReceiptNo: Code[20]; QtyToAssign: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Receipt No.", PurchReceiptNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        FindPurchLine(PurchaseHeader, PurchaseLine);
        PurchaseLine.CalcFields("Qty. to Assign");
        PurchaseLine.TestField("Qty. to Assign", QtyToAssign);
    end;

    local procedure VerifyQtyToAssignOnSalesInvoiceLine(SalesHeader: Record "Sales Header"; SalesShipmentNo: Code[20]; QtyToAssign: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Shipment No.", SalesShipmentNo);
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        FindSalesLine(SalesHeader, SalesLine);
        SalesLine.CalcFields("Qty. to Assign");
        SalesLine.TestField("Qty. to Assign", QtyToAssign);
    end;

    local procedure VerifyQtyToAssignOnPurchCrMemoLine(PurchaseHeader: Record "Purchase Header"; ReturnShipmentNo: Code[20]; QtyToAssign: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Return Shipment No.", ReturnShipmentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        FindPurchLine(PurchaseHeader, PurchaseLine);
        PurchaseLine.CalcFields("Qty. to Assign");
        PurchaseLine.TestField("Qty. to Assign", QtyToAssign);
    end;

    local procedure VerifyQtyToAssignOnSalesCrMemoLine(SalesHeader: Record "Sales Header"; ReturnReceiptNo: Code[20]; QtyToAssign: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Return Receipt No.", ReturnReceiptNo);
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        FindSalesLine(SalesHeader, SalesLine);
        SalesLine.CalcFields("Qty. to Assign");
        SalesLine.TestField("Qty. to Assign", QtyToAssign);
    end;

    local procedure EnqueueCopyDocumentReqpageParameters(DocType: Variant; DocNo: Variant; IncludeHeader: Variant; RecalcLines: Variant)
    begin
        LibraryVariableStorage.Enqueue(DocType);
        LibraryVariableStorage.Enqueue(DocNo);
        LibraryVariableStorage.Enqueue(IncludeHeader);
        LibraryVariableStorage.Enqueue(RecalcLines);
    end;

    local procedure CreateAndPostSalesInvoice(var Customer: Record Customer): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);

        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::Invoice,
            Customer."No.");
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
            Item,
            LibraryRandom.RandDecInRange(1, 100, 2),
            LibraryRandom.RandDecInRange(1, 100, 2));
        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(100));

        SalesLine.Validate("VAT %", 0);
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        exit(DocumentNo);
    end;

    local procedure VerifySalesDocumentCaption(var SalesInvoice: TestPage "Sales Invoice")
    begin
        Assert.AreEqual(
            'Unit Price Excl. VAT',
            SalesInvoice.SalesLines."Unit Price".Caption(),
            CaptionNotMatchErr);
        Assert.AreEqual(
            'Line Amount Excl. VAT',
            SalesInvoice.SalesLines."Line Amount".Caption(),
            CaptionNotMatchErr);
    end;

    local procedure CreateAndPostPurchaseInvoice(var Vendor: Record Vendor): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader,
            PurchaseHeader."Document Type"::Invoice,
            Vendor."No.");
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
            Item,
            LibraryRandom.RandDecInRange(1, 100, 2),
            LibraryRandom.RandDecInRange(1, 100, 2));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(100));

        PurchaseLine.Validate("VAT %", 0);
        PurchaseLine.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        exit(DocumentNo);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
    end;

    local procedure VerifyPurchaseDocumentCaption(var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        Assert.AreEqual(
            'Direct Unit Cost Excl. VAT',
            PurchaseInvoice.PurchLines."Direct Unit Cost".Caption(),
            CaptionNotMatchErr);
        Assert.AreEqual(
            'Line Amount Excl. VAT',
            PurchaseInvoice.PurchLines."Line Amount".Caption(),
            CaptionNotMatchErr);
    end;

    local procedure CreateCustomerWithMultipleDimension(var Customer: Record Customer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: array[4] of Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);

        for i := 1 to 4 do begin
            GenerateDimensions(Dimension[i], DimensionValue);
            LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension[i].Code, DimensionValue.Code);
        end;

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension[1].Code);
        GeneralLedgerSetup.Validate("Shortcut Dimension 4 Code", Dimension[2].Code);
        GeneralLedgerSetup.Validate("Shortcut Dimension 5 Code", Dimension[3].Code);
        GeneralLedgerSetup.Validate("Shortcut Dimension 6 Code", Dimension[4].Code);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreateSalesDocumentWithGlobalDimension(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        DimensionValue: array[2] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);

        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue[1], GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[2], GeneralLedgerSetup."Global Dimension 2 Code");

        SalesHeader.Validate("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        SalesHeader.Validate("Shortcut Dimension 2 Code", DimensionValue[2].Code);
        SalesHeader.Modify(true);

        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
            Item,
            LibraryRandom.RandIntInRange(1000, 2000),
            LibraryRandom.RandIntInRange(3000, 4000));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount(), LibraryRandom.RandInt(10));
    end;

    local procedure VerifySalesDocumentDimensions(var SalesInvoice: TestPage "Sales Invoice"; SalesHeader: Record "Sales Header"; DocumentNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoice."Shortcut Dimension 1 Code".AssertEquals(SalesInvoiceHeader."Shortcut Dimension 1 Code");
        SalesInvoice."Shortcut Dimension 2 Code".AssertEquals(SalesInvoiceHeader."Shortcut Dimension 2 Code");
        SalesInvoice.Close();

        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual(SalesHeader."Dimension Set ID", SalesInvoiceHeader."Dimension Set ID", WrongDimensionsCopiedErr);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.FindSet();
        repeat
            Assert.AreEqual(SalesLine."Dimension Set ID", SalesHeader."Dimension Set ID", WrongDimensionsCopiedErr);
            Assert.AreEqual(SalesLine."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 1 Code", WrongDimensionsCopiedErr);
            Assert.AreEqual(SalesLine."Shortcut Dimension 2 Code", SalesHeader."Shortcut Dimension 2 Code", WrongDimensionsCopiedErr);
        until SalesLine.Next() = 0;
    end;

    local procedure CreateVendorWithMultipleDimension(var Vendor: Record Vendor)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: array[4] of Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);

        for i := 1 to 4 do begin
            GenerateDimensions(Dimension[i], DimensionValue);
            LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", Dimension[i].Code, DimensionValue.Code);
        end;

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension[1].Code);
        GeneralLedgerSetup.Validate("Shortcut Dimension 4 Code", Dimension[2].Code);
        GeneralLedgerSetup.Validate("Shortcut Dimension 5 Code", Dimension[3].Code);
        GeneralLedgerSetup.Validate("Shortcut Dimension 6 Code", Dimension[4].Code);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithGlobalDimension(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    var
        DimensionValue: array[2] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);

        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue[1], GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[2], GeneralLedgerSetup."Global Dimension 2 Code");

        PurchaseHeader.Validate("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        PurchaseHeader.Validate("Shortcut Dimension 2 Code", DimensionValue[2].Code);
        PurchaseHeader.Modify(true);

        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
            Item,
            LibraryRandom.RandIntInRange(1000, 2000),
            LibraryRandom.RandIntInRange(3000, 4000));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(), LibraryRandom.RandInt(10));
    end;

    local procedure VerifyPurchaseDocumentDimensions(var PurchaseInvoice: TestPage "Purchase Invoice"; PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchaseInvoice."Shortcut Dimension 1 Code".AssertEquals(PurchInvHeader."Shortcut Dimension 1 Code");
        PurchaseInvoice."Shortcut Dimension 2 Code".AssertEquals(PurchInvHeader."Shortcut Dimension 2 Code");
        PurchaseInvoice.Close();

        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(PurchaseHeader."Dimension Set ID", PurchInvHeader."Dimension Set ID", WrongDimensionsCopiedErr);

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetFilter("No.", '<>%1', '');
        PurchaseLine.FindSet();
        repeat
            Assert.AreEqual(PurchaseLine."Dimension Set ID", PurchaseHeader."Dimension Set ID", WrongDimensionsCopiedErr);
            Assert.AreEqual(PurchaseLine."Shortcut Dimension 1 Code", PurchaseHeader."Shortcut Dimension 1 Code", WrongDimensionsCopiedErr);
            Assert.AreEqual(PurchaseLine."Shortcut Dimension 2 Code", PurchaseHeader."Shortcut Dimension 2 Code", WrongDimensionsCopiedErr);
        until PurchaseLine.Next() = 0;
    end;

    local procedure CreateItemChargePurchaseLineWithoutAssignment(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", '', Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingMode::"Assign Lot No.":
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingMode::"Assign Serial Nos.":
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateModalPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesModalPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        DocType: Option "Posted Shipments","Posted Invoices","Posted Return Receipts","Posted Cr. Memos";
    begin
        PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(DocType::"Posted Invoices");
        PostedSalesDocumentLines.PostedInvoices.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MsgCorrectedInvoiceNo) > 0, Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmAllHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure ExecuteConfirmHandler()
    begin
        if Confirm(MsgCorrectedInvoiceNo) then;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopySalesDocumentHandler(var CopySalesDocument: TestRequestPage "Copy Sales Document")
    var
        DocType: Option;
        DocumentType: Variant;
        No: Variant;
        IncludeHeader: Variant;
        RecalculateLines: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(No);
        DocType := DocumentType;
        LibraryVariableStorage.Dequeue(IncludeHeader);
        LibraryVariableStorage.Dequeue(RecalculateLines);
        CopySalesDocument.DocumentType.SetValue(DocType);
        CopySalesDocument.DocumentNo.SetValue(No);
        CopySalesDocument.IncludeHeader_Options.SetValue(IncludeHeader);
        CopySalesDocument.RecalculateLines.SetValue(RecalculateLines);
        CopySalesDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPurchaseDocumentHandler(var CopyPurchaseDocument: TestRequestPage "Copy Purchase Document")
    var
        DocType: Option;
        DocumentType: Variant;
        No: Variant;
        IncludeHeader: Variant;
        RecalculateLines: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(No);
        DocType := DocumentType;
        LibraryVariableStorage.Dequeue(IncludeHeader);
        LibraryVariableStorage.Dequeue(RecalculateLines);
        CopyPurchaseDocument.DocumentType.SetValue(DocType);
        CopyPurchaseDocument.DocumentNo.SetValue(No);
        CopyPurchaseDocument.IncludeHeader_Options.SetValue(IncludeHeader);
        CopyPurchaseDocument.RecalculateLines.SetValue(RecalculateLines);
        CopyPurchaseDocument.OK().Invoke();
    end;
}

