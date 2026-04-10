codeunit 134347 "ERM Document Line Tracking"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Document Line Tracking]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        SalesOrderLinesTxt: Label 'Sales Order Lines';
        ArchivedSalesOrderLinesTxt: Label 'Archived Sales Order Lines';
        PostedSalesShipmentLinesTxt: Label 'Posted Sales Shipment Lines';
        PostedSalesInvoiceLinesTxt: Label 'Posted Sales Invoice Lines';
        PurchaseOrderLinesTxt: Label 'Purchase Order Lines';
        ArchivedPurchaseOrderLinesTxt: Label 'Archived Purchase Order Lines';
        PostedPurchaseReceiptLinesTxt: Label 'Posted Purchase Receipt Lines';
        PostedPurchaseInvoiceLinesTxt: Label 'Posted Purchase Invoice Lines';
        BlanketSalesOrderLinesTxt: Label 'Blanket Sales Order Lines';
        ArchivedBlanketSalesOrderLinesTxt: Label 'Archived Blanket Sales Order Lines';
        BlanketPurchaseOrderLinesTxt: Label 'Blanket Purchase Order Lines';
        ArchivedBlanketPurchaseOrderLinesTxt: Label 'Archived Blanket Purchase Order Lines';
        SalesReturnOrderLinesTxt: Label 'Sales Return Order Lines';
        ArchivedSalesReturnOrderLinesTxt: Label 'Archived Sales Return Order Lines';
        PostedReturnReceiptLinesTxt: Label 'Posted Return Receipt Lines';
        PostedSalesCreditMemoLinesTxt: Label 'Posted Sales Credit Memo Lines';
        PurchaseReturnOrderLinesTxt: Label 'Purchase Return Order Lines';
        ArchivedPurchaseReturnOrderLinesTxt: Label 'Archived Purchase Return Order Lines';
        PostedReturnShipmentLinesTxt: Label 'Posted Return Shipment Lines';
        PostedPurchaseCreditMemoLinesTxt: Label 'Posted Purchase Credit Memo Lines';
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Purchase Order] [Order]
        // [SCENARIO 315523] Document Line Tracking opened from Purchase Order
        Initialize();

        // [GIVEN] Create Blanket Purchase Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Purchase Order from Blanket Purchase Order, archive and post Purchase Order partially
        CreateArchivePostPurchaseOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" opened for "Item1" and "Item2" of Purchase Order
        FindFirstLastPurchaseLines(OrderNo, PurchaseHeader."Document Type"::Order, PurchaseLine);
        OpenDocumentLineTrackingForPurchaseLines(PurchaseLine, "Document Line Source Type"::"Purchase Order");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromBlanketPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Blanket Purchase Order] [Blanket Order]
        // [SCENARIO 315523] Document Line Tracking opened from Blanked Purchase Order
        Initialize();

        // [GIVEN] Create Blanket Purchase Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Purchase Order from Blanket Purchase Order, archive and post Purchase Order partially
        CreateArchivePostPurchaseOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Blanket Purchase Order
        FindFirstLastPurchaseLines(BlanketOrderNo, PurchaseHeader."Document Type"::"Blanket Order", PurchaseLine);
        OpenDocumentLineTrackingForPurchaseLines(PurchaseLine, "Document Line Source Type"::"Blanket Purchase Order");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedPurchaseReceipt()
    var
        PurchRcptLine: array[2] of Record "Purch. Rcpt. Line";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Posted Purchase Receipt] [Posted Receipt]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Purchase Release
        Initialize();

        // [GIVEN] Create Blanket Purchase Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Purchase Order from Blanket Purchase Order, archive and post Purchase Order partially
        CreateArchivePostPurchaseOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Posted Purchase Receipt
        FindFirstLastPurchaseReceiptLines(OrderNo, PurchRcptLine);
        OpenDocumentLineTrackingForPurchaseReceiptLines(PurchRcptLine, "Document Line Source Type"::"Purchase Receipt");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedPurchaseInvoice()
    var
        PurchInvLine: array[2] of Record "Purch. Inv. Line";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Posted Purchase Invoice] [Posted Invoice]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Purchase Invoice
        Initialize();

        // [GIVEN] Create Blanket Purchase Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Purchase Order "PO" from Blanket Purchase Order, archive and post Purchase Order partially
        CreateArchivePostPurchaseOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Posted Purchase Invoice
        FindFirstLastPurchaseInvoiceLinesFromOrderNo(OrderNo, PurchInvLine);
        OpenDocumentLineTrackingForPurchaseInvoiceLines(PurchInvLine, "Document Line Source Type"::"Purchase Invoice");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Purchase Retun Order] [Return Order]
        // [SCENARIO 315523] Document Line Tracking opened from Purchase Return Order
        Initialize();

        // [GIVEN] Create Purchase Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Purchase Return partially
        CreateArchivePostPurchaseReturnOrder(ReturnOrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Purchase Return Order
        FindFirstLastPurchaseLines(ReturnOrderNo, PurchaseHeader."Document Type"::"Return Order", PurchaseLine);
        OpenDocumentLineTrackingForPurchaseLines(PurchaseLine, "Document Line Source Type"::"Purchase Return Order");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPurchaseReturnShipmentOrder()
    var
        ReturnShipmentLine: array[2] of Record "Return Shipment Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Posted Return Shipment] [Return Shipment]
        // [SCENARIO 315523] Document Line Tracking opened from Purchase Return Shipment
        Initialize();

        // [GIVEN] Create Purchase Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Purchase Return partially
        CreateArchivePostPurchaseReturnOrder(ReturnOrderNo);

        // [WHEN] "Page" is opened for "Item1" and "Item2" from Posted Purchase Return Shipment
        FindFirstLastPurchaseReturnShipmentLines(ReturnOrderNo, ReturnShipmentLine);
        OpenDocumentLineTrackingForPurchaseReturnShipmentLines(ReturnShipmentLine, "Document Line Source Type"::"Return Shipment");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPurchaseCreditMemoOrder()
    var
        PurchCrMemoLine: array[2] of Record "Purch. Cr. Memo Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Posted Purchase Credit Memo] [Posted Credit Memo]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Purchase Credit Memo
        Initialize();

        // [GIVEN] Create Purchase Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Purchase Return partially
        CreateArchivePostPurchaseReturnOrder(ReturnOrderNo);

        // [WHEN] "Page" is opened for "Item1" and "Item2" from Posted Purchase Credit Memo
        FindFirstLastPurchaseCreditMemoLines(ReturnOrderNo, PurchCrMemoLine);
        OpenDocumentLineTrackingForPurchaseCreditMemoLines(PurchCrMemoLine, "Document Line Source Type"::"Purchase Credit Memo");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Purchase Order Lines", "Archived Blanket Purchase Order Lines",
        // [THEN] "Purchase Order Lines", "Archived Purchase Order Lines",
        // [THEN] "Posted Purchase Receipt Lines", "Posted Purchase Invoice Lines"
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('EmptyDocumentLineTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPurchaseInvoicePostedStandalone()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: array[2] of Record "Purch. Inv. Line";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Purchase Invoice] [Posted Purchase Invoice] [Invoice] [Posted Invoice]
        // [SCENARIO 315523] Open Document Line Tracking from standalone Posted Purchase Invoice showing blank page
        Initialize();

        // [GIVEN] Purchase Invoice "PI" with two lines for "Item1" and "Item2" with different quantity of 10 and 20
        CreatePurchaseHeaderWithTwoLines(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] "PI" posted
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] "Page" is opened for "Item1" and "Item2" of Posted Purchase Invoice
        FindFirstLastPurchaseInvoiceLines(PostedInvoiceNo, PurchInvLine);
        OpenDocumentLineTrackingForPurchaseInvoiceLinesWithNoEnqueue(PurchInvLine, "Document Line Source Type"::"Purchase Invoice");

        // [THEN] Verify "Page" is blank with no header and no lines
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Sales Order] [Order]
        // [SCENARIO 315523] Document Line Tracking opened from Sales Order
        Initialize();

        // [GIVEN] Create Blanket Sales Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Sales Order from Blanket Sales Order, archive and post Sales Order partially
        CreateArchivePostSalesOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Sales Order
        FindFirstLastSalesLines(OrderNo, SalesHeader."Document Type"::Order, SalesLine);
        OpenDocumentLineTrackingForSalesLines(SalesLine, "Document Line Source Type"::"Sales Order");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty();

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromBlanketSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Blanket Sales Order] [Blanket Order]
        // [SCENARIO 315523] Document Line Tracking opened from Blanket Sales Order
        Initialize();

        // [GIVEN] Create Blanket Sales Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Sales Order from Blanket Sales Order, archive and post Sales Order partially
        CreateArchivePostSalesOrder(BlanketOrderNo, OrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Blanket Sales Order
        FindFirstLastSalesLines(BlanketOrderNo, SalesHeader."Document Type"::"Blanket Order", SalesLine);
        OpenDocumentLineTrackingForSalesLines(SalesLine, "Document Line Source Type"::"Blanket Sales Order");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty();

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedSalesInvoice()
    var
        SalesInvoiceLine: array[2] of Record "Sales Invoice Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Posted Sales Invoice] [Invoice] [Posted Invoice]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Sales Invoice
        Initialize();

        // [GIVEN] Create Blanket Sales Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Sales Order from Blanket Sales Order, archive and post Sales Order partially
        CreateArchivePostSalesOrder(BlanketOrderNo, OrderNo);

        // [WHEN] "Page" is opened for "Item1" and "Item2" from Posted Sales Invoice
        FindFirstLastSalesInvoiceLinesFromOrderNo(OrderNo, SalesInvoiceLine);
        OpenDocumentLineTrackingForSalesInvoiceLines(SalesInvoiceLine, "Document Line Source Type"::"Sales Invoice");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty();

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedSalesShipment()
    var
        SalesShipmentLine: array[2] of Record "Sales Shipment Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        BlanketOrderNo: Code[20];
        OrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Posted Sales Shipment] [Posted Shipment]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Sales Shipment
        Initialize();

        // [GIVEN] Create Blanket Sales Order with two lines with two items "Itme1" and "Item2" and archive
        // [GIVEN] Create Sales Order from Blanket Sales Order, archive and post Sales Order partially
        CreateArchivePostSalesOrder(BlanketOrderNo, OrderNo);

        // [WHEN] "Page" is opened for "Item1" and "Item2" for Posted Sales Shipment
        FindFirstLastSalesShipmentLines(OrderNo, SalesShipmentLine);
        OpenDocumentLineTrackingForSalesShipmentLines(SalesShipmentLine, "Document Line Source Type"::"Sales Shipment");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty();

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Sales Retun Order] [Return Order]
        // [SCENARIO 315523] Document Line Tracking opened from Sales Return Order
        Initialize();

        // [GIVEN] Create Sales Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Sales Return partially
        CreateArchivePostSalesReturnOrder(ReturnOrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Sales Return Order
        FindFirstLastSalesLines(ReturnOrderNo, SalesHeader."Document Type"::"Return Order", SalesLine);
        OpenDocumentLineTrackingForSalesLines(SalesLine, "Document Line Source Type"::"Sales Return Order");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedReturnReceipt()
    var
        ReturnReceiptLine: array[2] of Record "Return Receipt Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Posted Return Receipt] [Return Receipt]
        // [SCENARIO 315523] Document Line Tracking opened from Posted Return Receipt
        Initialize();

        // [GIVEN] Create Sales Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Sales Return partially
        CreateArchivePostSalesReturnOrder(ReturnOrderNo);

        // [WHEN] Document Line Tracking page "Page" is opened for "Item1" and "Item2" of Posted Return Receipt
        FindFirstLastSalesReturnReceiptLines(ReturnOrderNo, ReturnReceiptLine);
        OpenDocumentLineTrackingForSalesReturnReceiptLines(ReturnReceiptLine, "Document Line Source Type"::"Return Receipt");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DocumentLineTrackingPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromPostedSalesCreditMemo()
    var
        SalesCrMemoLine: array[2] of Record "Sales Cr.Memo Line";
        ReturnOrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Posted Sales Credit Memo] [Posted Credit Memo]
        // [SCENARIO 315523] Show Document Line Tracking from partially posted Sales Return Order showing all line related information
        Initialize();

        // [GIVEN] Create Sales Return Order with two lines with two items "Item1" and "Item2" and archive
        // [GIVEN] Post Sales Return partially
        CreateArchivePostSalesReturnOrder(ReturnOrderNo);

        // [WHEN] Document Line Tracking "Page" is opened for "Item1" and "Item2" of Posted Sales Credit Memo
        FindFirstLastSalesCreditMemoLines(ReturnOrderNo, SalesCrMemoLine);
        OpenDocumentLineTrackingForSalesCreditMemoLines(SalesCrMemoLine, "Document Line Source Type"::"Sales Credit Memo");

        // [THEN] "Page" verified with DocumentLineTrackingPageHandler to contain both items information and all related tables:
        // [THEN] "Blanket Sales Order Lines", "Archived Blanket Sales Order Lines", "Sales Order Lines",
        // [THEN] "Archived Sales Order Lines", "Posted Sales Shipment Lines", "Posted Sales Invoice Lines"
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('EmptyDocumentLineTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OpenFromSalesInvoicePostedStandalone()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: array[2] of Record "Sales Invoice Line";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Sales Invoice] [Posted Sales Invoice] [Invoice] [Posted Invoice]
        // [SCENARIO 315523] Open Document Line Tracking from standalone Posted Sales Invoice showing blank page
        Initialize();

        // [GIVEN] Sales Invoice "SI" with two lines for "Item1" and "Item2"
        CreateSalesHeaderWithTwoLines(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] "SI" posted
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Document Line Tracking "Page" is opened for "Item1" and "Item2" of Posted Purchase Invoice
        FindFirstLastSalesInvoiceLines(PostedInvoiceNo, SalesInvoiceLine);
        OpenDocumentLineTrackingForSalesInvoiceLinesWithNoEnqueue(SalesInvoiceLine, "Document Line Source Type"::"Sales Invoice");

        // [THEN] Verify "Page" is blank with no header and no lines
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,DocumentLineTrackingPageHandler2')]
    procedure VerifyDocumentLineTrackingOnBlanketPurchaseOrderArchive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrderArchive: TestPage "Blanket Purchase Order Archive";
    begin
        // [SCENARIO 565974] Verify the document line tracking on the blanket purchase order archive.
        Initialize();

        // [GIVEN] Create Blanket Purchase Order.
        CreateBlanketPurchaseOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] Convert Blanket Purchase Order to Purchase Order and Archive the Blanket Purchase Order.
        BlanketPurchaseOrderMakeOrderAndArchive(PurchaseHeader);

        // [WHEN] Open Blanket Purchase Order Archive Page. 
        BlanketPurchaseOrderArchive.OpenEdit();

        // [GIVEN] Filter Set on Blanket Purchase Order Archive
        FilterSetOnBlanketPurchaseOrderArchive(BlanketPurchaseOrderArchive, PurchaseHeader);

        // [THEN] DocumentLineTracking Action was invoked & Verify Document Line Tracking for Blanket Purchase Order.
        BlanketPurchaseOrderArchive.PurchLinesArchive.DocumentLineTracking.Invoke();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Document Line Tracking");

        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateArchivePostPurchaseOrder(var BlanketOrderNo: Code[20]; var OrderNo: Code[20])
    var
        PurchaseHeaderBlanketOrder: Record "Purchase Header";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        CreatePurchaseHeaderWithTwoLines(PurchaseHeaderBlanketOrder, PurchaseHeaderBlanketOrder."Document Type"::"Blanket Order");
        ArchiveManagement.ArchivePurchDocument(PurchaseHeaderBlanketOrder);

        PurchaseHeaderOrder.Get(
          PurchaseHeaderOrder."Document Type"::Order,
          LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeaderBlanketOrder));
        ArchiveManagement.ArchivePurchDocument(PurchaseHeaderOrder);

        FindFirstLastPurchaseLines(PurchaseHeaderOrder."No.", PurchaseHeaderOrder."Document Type", PurchaseLine);
        ReducePurchaseOrderLinesForPartialPosting(PurchaseLine, "Document Line Source Type"::"Purchase Order");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, true);

        OrderNo := PurchaseHeaderOrder."No.";
        BlanketOrderNo := PurchaseHeaderBlanketOrder."No.";
    end;

    local procedure CreateArchivePostPurchaseReturnOrder(var ReturnOrderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        CreatePurchaseHeaderWithTwoLines(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        FindFirstLastPurchaseLines(PurchaseHeader."No.", PurchaseHeader."Document Type", PurchaseLine);
        ReducePurchaseOrderLinesForPartialPosting(PurchaseLine, "Document Line Source Type"::"Purchase Return Order");

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ReturnOrderNo := PurchaseHeader."No.";
    end;

    local procedure CreateArchivePostSalesOrder(var BlanketOrderNo: Code[20]; var OrderNo: Code[20])
    var
        SalesHeaderBlanketOrder: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        CreateSalesHeaderWithTwoLines(SalesHeaderBlanketOrder, SalesHeaderBlanketOrder."Document Type"::"Blanket Order");
        ArchiveManagement.ArchiveSalesDocument(SalesHeaderBlanketOrder);

        SalesHeaderOrder.Get(
          SalesHeaderOrder."Document Type"::Order, LibrarySales.BlanketSalesOrderMakeOrder(SalesHeaderBlanketOrder));
        ArchiveManagement.ArchiveSalesDocument(SalesHeaderOrder);

        FindFirstLastSalesLines(SalesHeaderOrder."No.", SalesHeaderOrder."Document Type", SalesLine);
        ReduceSalesOrderLinesForPartialPosting(SalesLine, "Document Line Source Type"::"Sales Order");

        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, true);

        OrderNo := SalesHeaderOrder."No.";
        BlanketOrderNo := SalesHeaderBlanketOrder."No.";
    end;

    local procedure CreateArchivePostSalesReturnOrder(var ReturnOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        CreateSalesHeaderWithTwoLines(SalesHeader, SalesHeader."Document Type"::"Return Order");
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        FindFirstLastSalesLines(SalesHeader."No.", SalesHeader."Document Type", SalesLine);
        ReduceSalesOrderLinesForPartialPosting(SalesLine, "Document Line Source Type"::"Sales Return Order");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ReturnOrderNo := SalesHeader."No.";
    end;

    local procedure CreatePurchaseHeaderWithTwoLines(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandIntInRange(20, 50));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandIntInRange(20, 50));
    end;

    local procedure CreateSalesHeaderWithTwoLines(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandIntInRange(20, 50));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandIntInRange(20, 50));
    end;

    local procedure FindFirstLastPurchaseLines(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; var PurchaseLine: array[2] of Record "Purchase Line")
    begin
        PurchaseLine[1].SetRange("Document No.", DocumentNo);
        PurchaseLine[1].SetRange("Document Type", DocumentType);
        PurchaseLine[1].FindFirst();

        PurchaseLine[2].SetRange("Document No.", DocumentNo);
        PurchaseLine[2].SetRange("Document Type", DocumentType);
        PurchaseLine[2].FindLast();
    end;

    local procedure FindFirstLastPurchaseReceiptLines(DocumentNo: Code[20]; var PurchRcptLine: array[2] of Record "Purch. Rcpt. Line")
    begin
        PurchRcptLine[1].SetRange("Order No.", DocumentNo);
        PurchRcptLine[1].FindFirst();

        PurchRcptLine[2].SetRange("Order No.", DocumentNo);
        PurchRcptLine[2].FindLast();
    end;

    local procedure FindFirstLastPurchaseInvoiceLines(DocumentNo: Code[20]; var PurchInvLine: array[2] of Record "Purch. Inv. Line")
    begin
        PurchInvLine[1].SetRange("Document No.", DocumentNo);
        PurchInvLine[1].FindFirst();

        PurchInvLine[2].SetRange("Document No.", DocumentNo);
        PurchInvLine[2].FindLast();
    end;

    local procedure FindFirstLastPurchaseInvoiceLinesFromOrderNo(DocumentNo: Code[20]; var PurchInvLine: array[2] of Record "Purch. Inv. Line")
    begin
        PurchInvLine[1].SetRange("Order No.", DocumentNo);
        PurchInvLine[1].FindFirst();

        PurchInvLine[2].SetRange("Order No.", DocumentNo);
        PurchInvLine[2].FindLast();
    end;

    local procedure FindFirstLastPurchaseReturnShipmentLines(DocumentNo: Code[20]; var ReturnShipmentLine: array[2] of Record "Return Shipment Line")
    begin
        ReturnShipmentLine[1].SetRange("Return Order No.", DocumentNo);
        ReturnShipmentLine[1].FindFirst();

        ReturnShipmentLine[2].SetRange("Return Order No.", DocumentNo);
        ReturnShipmentLine[2].FindLast();
    end;

    local procedure FindFirstLastPurchaseCreditMemoLines(DocumentNo: Code[20]; var PurchCrMemoLine: array[2] of Record "Purch. Cr. Memo Line")
    begin
        PurchCrMemoLine[1].SetRange("Order No.", DocumentNo);
        PurchCrMemoLine[1].FindFirst();

        PurchCrMemoLine[2].SetRange("Order No.", DocumentNo);
        PurchCrMemoLine[2].FindLast();
    end;

    local procedure FindFirstLastSalesLines(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; var SalesLine: array[2] of Record "Sales Line")
    begin
        SalesLine[1].SetRange("Document No.", DocumentNo);
        SalesLine[1].SetRange("Document Type", DocumentType);
        SalesLine[1].FindFirst();

        SalesLine[2].SetRange("Document No.", DocumentNo);
        SalesLine[2].SetRange("Document Type", DocumentType);
        SalesLine[2].FindLast();
    end;

    local procedure FindFirstLastSalesInvoiceLines(DocumentNo: Code[20]; var SalesInvoiceLine: array[2] of Record "Sales Invoice Line")
    begin
        SalesInvoiceLine[1].SetRange("Document No.", DocumentNo);
        SalesInvoiceLine[1].FindFirst();

        SalesInvoiceLine[2].SetRange("Document No.", DocumentNo);
        SalesInvoiceLine[2].FindLast();
    end;

    local procedure FindFirstLastSalesInvoiceLinesFromOrderNo(DocumentNo: Code[20]; var SalesInvoiceLine: array[2] of Record "Sales Invoice Line")
    begin
        SalesInvoiceLine[1].SetRange("Order No.", DocumentNo);
        SalesInvoiceLine[1].FindFirst();

        SalesInvoiceLine[2].SetRange("Order No.", DocumentNo);
        SalesInvoiceLine[2].FindLast();
    end;

    local procedure FindFirstLastSalesShipmentLines(DocumentNo: Code[20]; var SalesShipmentLine: array[2] of Record "Sales Shipment Line")
    begin
        SalesShipmentLine[1].SetRange("Order No.", DocumentNo);
        SalesShipmentLine[1].FindFirst();

        SalesShipmentLine[2].SetRange("Order No.", DocumentNo);
        SalesShipmentLine[2].FindLast();
    end;

    local procedure FindFirstLastSalesReturnReceiptLines(DocumentNo: Code[20]; var ReturnReceiptLine: array[2] of Record "Return Receipt Line")
    begin
        ReturnReceiptLine[1].SetRange("Return Order No.", DocumentNo);
        ReturnReceiptLine[1].FindFirst();

        ReturnReceiptLine[2].SetRange("Return Order No.", DocumentNo);
        ReturnReceiptLine[2].FindLast();
    end;

    local procedure FindFirstLastSalesCreditMemoLines(DocumentNo: Code[20]; var SalesCrMemoLine: array[2] of Record "Sales Cr.Memo Line")
    begin
        SalesCrMemoLine[1].SetRange("Order No.", DocumentNo);
        SalesCrMemoLine[1].FindFirst();

        SalesCrMemoLine[2].SetRange("Order No.", DocumentNo);
        SalesCrMemoLine[2].FindLast();
    end;

    local procedure ReducePurchaseOrderLinesForPartialPosting(var PurchaseLine: array[2] of Record "Purchase Line"; VerifyDocument: Enum "Document Line Source Type")
    begin
        case VerifyDocument of
            "Document Line Source Type"::"Purchase Order":
                begin
                    UpdatePurchaseLineQuantityToReceipt(PurchaseLine[1]);
                    UpdatePurchaseLineQuantityToReceipt(PurchaseLine[2]);
                end;
            "Document Line Source Type"::"Purchase Return Order":
                begin
                    UpdatePurchaseLineReturnQtyToShip(PurchaseLine[1]);
                    UpdatePurchaseLineReturnQtyToShip(PurchaseLine[2]);
                end;
        end;
    end;

    local procedure ReduceSalesOrderLinesForPartialPosting(var SalesLine: array[2] of Record "Sales Line"; VerifyDocument: Enum "Document Line Source Type")
    begin
        case VerifyDocument of
            "Document Line Source Type"::"Sales Order":
                begin
                    UpdateSalesLineQuantityToShip(SalesLine[1]);
                    UpdateSalesLineQuantityToShip(SalesLine[2]);
                end;
            "Document Line Source Type"::"Sales Return Order":
                begin
                    UpdateSalesLineReturnQtyToReceipt(SalesLine[1]);
                    UpdateSalesLineReturnQtyToReceipt(SalesLine[2]);
                end;
        end;
    end;

    local procedure UpdatePurchaseLineQuantityToReceipt(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity - LibraryRandom.RandIntInRange(2, 5));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchaseLineReturnQtyToShip(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine.Quantity - LibraryRandom.RandIntInRange(2, 5));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSalesLineQuantityToShip(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity - LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesLineReturnQtyToReceipt(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity - LibraryRandom.RandIntInRange(2, 5));
        SalesLine.Modify(true);
    end;

    local procedure OpenDocumentLineTrackingForPurchaseLines(PurchaseLine: array[2] of Record "Purchase Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchaseLine) do begin
            EnqueueLineValues(VerifyDocument, PurchaseLine[Index]."Line No.", PurchaseLine[Index]."No.", PurchaseLine[Index].Quantity, PurchaseLine[Index].Description, PurchaseLine[Index]."Unit of Measure Code");
            DocumentLineTracking.SetSourceDoc(
              VerifyDocument, PurchaseLine[Index]."Document No.", PurchaseLine[Index]."Line No.", PurchaseLine[Index]."Blanket Order No.", PurchaseLine[Index]."Blanket Order Line No.",
              PurchaseLine[Index]."Order No.", PurchaseLine[Index]."Order Line No.");
            DocumentLineTracking.Run();
        end;
    end;

    local procedure OpenDocumentLineTrackingForPurchaseReceiptLines(PurchRcptLine: array[2] of Record "Purch. Rcpt. Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchRcptLine) do begin
            EnqueueLineValues(VerifyDocument, PurchRcptLine[Index]."Line No.", PurchRcptLine[Index]."No.", PurchRcptLine[Index].Quantity, PurchRcptLine[Index].Description, PurchRcptLine[Index]."Unit of Measure Code");
            DocumentLineTracking.SetSourceDoc(
              VerifyDocument, PurchRcptLine[Index]."Document No.", PurchRcptLine[Index]."Line No.", PurchRcptLine[Index]."Blanket Order No.", PurchRcptLine[Index]."Blanket Order Line No.",
              PurchRcptLine[Index]."Order No.", PurchRcptLine[Index]."Order Line No.");
            DocumentLineTracking.Run();
        end;
    end;

    local procedure OpenDocumentLineTrackingForPurchaseInvoiceLines(PurchInvLine: array[2] of Record "Purch. Inv. Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchInvLine) do begin
            EnqueueLineValues(VerifyDocument, PurchInvLine[Index]."Line No.", PurchInvLine[Index]."No.", PurchInvLine[Index].Quantity, PurchInvLine[Index].Description, PurchInvLine[Index]."Unit of Measure Code");
            DocumentLineTracking.SetSourceDoc(
              VerifyDocument, PurchInvLine[Index]."Document No.", PurchInvLine[Index]."Line No.", PurchInvLine[Index]."Blanket Order No.", PurchInvLine[Index]."Blanket Order Line No.",
              PurchInvLine[Index]."Order No.", PurchInvLine[Index]."Order Line No.");
            DocumentLineTracking.Run();
        end;
    end;

    local procedure OpenDocumentLineTrackingForPurchaseInvoiceLinesWithNoEnqueue(PurchInvLine: array[2] of Record "Purch. Inv. Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchInvLine) do begin
            DocumentLineTracking.SetSourceDoc(
              VerifyDocument, PurchInvLine[Index]."Document No.", PurchInvLine[Index]."Line No.", PurchInvLine[Index]."Blanket Order No.", PurchInvLine[Index]."Blanket Order Line No.",
              PurchInvLine[Index]."Order No.", PurchInvLine[Index]."Order Line No.");
            DocumentLineTracking.Run();
        end;
    end;

    local procedure OpenDocumentLineTrackingForPurchaseReturnShipmentLines(ReturnShipmentLine: array[2] of Record "Return Shipment Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(ReturnShipmentLine) do begin
            EnqueueLineValues(VerifyDocument, ReturnShipmentLine[Index]."Line No.", ReturnShipmentLine[Index]."No.", ReturnShipmentLine[Index].Quantity, ReturnShipmentLine[Index].Description, ReturnShipmentLine[Index]."Unit of Measure Code");
            DocumentLineTracking.SetSourceDoc(VerifyDocument, ReturnShipmentLine[Index]."Document No.", ReturnShipmentLine[Index]."Line No.", ReturnShipmentLine[Index]."Return Order No.", ReturnShipmentLine[Index]."Return Order Line No.", '', 0);
            DocumentLineTracking.Run();
        end;
    end;

    local procedure OpenDocumentLineTrackingForPurchaseCreditMemoLines(PurchCrMemoLine: array[2] of Record "Purch. Cr. Memo Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(PurchCrMemoLine) do begin
            EnqueueLineValues(VerifyDocument, PurchCrMemoLine[Index]."Line No.", PurchCrMemoLine[Index]."No.", PurchCrMemoLine[Index].Quantity, PurchCrMemoLine[Index].Description, PurchCrMemoLine[Index]."Unit of Measure Code");
            DocumentLineTracking.SetSourceDoc(
              VerifyDocument, PurchCrMemoLine[Index]."Document No.", PurchCrMemoLine[Index]."Line No.", PurchCrMemoLine[Index]."Blanket Order No.", PurchCrMemoLine[Index]."Blanket Order Line No.",
              PurchCrMemoLine[Index]."Order No.", PurchCrMemoLine[Index]."Order Line No.");
            DocumentLineTracking.Run();
        end;
    end;

    local procedure OpenDocumentLineTrackingForSalesLines(SalesLine: array[2] of Record "Sales Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesLine) do begin
            EnqueueLineValues(VerifyDocument, SalesLine[Index]."Line No.", SalesLine[Index]."No.", SalesLine[Index].Quantity, SalesLine[Index].Description, SalesLine[Index]."Unit of Measure Code");
            DocumentLineTracking.SetSourceDoc(
              VerifyDocument, SalesLine[Index]."Document No.", SalesLine[Index]."Line No.", SalesLine[Index]."Blanket Order No.", SalesLine[Index]."Blanket Order Line No.", '', 0);
            DocumentLineTracking.Run();
        end;
    end;

    local procedure OpenDocumentLineTrackingForSalesShipmentLines(SalesShipmentLine: array[2] of Record "Sales Shipment Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesShipmentLine) do begin
            EnqueueLineValues(VerifyDocument, SalesShipmentLine[Index]."Line No.", SalesShipmentLine[Index]."No.", SalesShipmentLine[Index].Quantity, SalesShipmentLine[Index].Description, SalesShipmentLine[Index]."Unit of Measure Code");
            DocumentLineTracking.SetSourceDoc(
              VerifyDocument, SalesShipmentLine[Index]."Document No.", SalesShipmentLine[Index]."Line No.", SalesShipmentLine[Index]."Blanket Order No.", SalesShipmentLine[Index]."Blanket Order Line No.",
              SalesShipmentLine[Index]."Order No.", SalesShipmentLine[Index]."Order Line No.");
            DocumentLineTracking.Run();
        end;
    end;

    local procedure OpenDocumentLineTrackingForSalesInvoiceLines(SalesInvoiceLine: array[2] of Record "Sales Invoice Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesInvoiceLine) do begin
            EnqueueLineValues(VerifyDocument, SalesInvoiceLine[Index]."Line No.", SalesInvoiceLine[Index]."No.", SalesInvoiceLine[Index].Quantity, SalesInvoiceLine[Index].Description, SalesInvoiceLine[Index]."Unit of Measure Code");
            DocumentLineTracking.SetSourceDoc(
              VerifyDocument, SalesInvoiceLine[Index]."Document No.", SalesInvoiceLine[Index]."Line No.", SalesInvoiceLine[Index]."Blanket Order No.", SalesInvoiceLine[Index]."Blanket Order Line No.",
              SalesInvoiceLine[Index]."Order No.", SalesInvoiceLine[Index]."Order Line No.");
            DocumentLineTracking.Run();
        end;
    end;

    local procedure OpenDocumentLineTrackingForSalesInvoiceLinesWithNoEnqueue(SalesInvoiceLine: array[2] of Record "Sales Invoice Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesInvoiceLine) do begin
            DocumentLineTracking.SetSourceDoc(
              VerifyDocument, SalesInvoiceLine[Index]."Document No.", SalesInvoiceLine[Index]."Line No.", SalesInvoiceLine[Index]."Blanket Order No.", SalesInvoiceLine[Index]."Blanket Order Line No.",
              SalesInvoiceLine[Index]."Order No.", SalesInvoiceLine[Index]."Order Line No.");
            DocumentLineTracking.Run();
        end;
    end;

    local procedure OpenDocumentLineTrackingForSalesReturnReceiptLines(ReturnReceiptLine: array[2] of Record "Return Receipt Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(ReturnReceiptLine) do begin
            EnqueueLineValues(VerifyDocument, ReturnReceiptLine[Index]."Line No.", ReturnReceiptLine[Index]."No.", ReturnReceiptLine[Index].Quantity, ReturnReceiptLine[Index].Description, ReturnReceiptLine[Index]."Unit of Measure Code");
            DocumentLineTracking.SetSourceDoc(
              VerifyDocument, ReturnReceiptLine[Index]."Document No.", ReturnReceiptLine[Index]."Line No.", ReturnReceiptLine[Index]."Return Order No.", ReturnReceiptLine[Index]."Return Order Line No.", '', 0);
            DocumentLineTracking.Run();
        end;
    end;

    local procedure OpenDocumentLineTrackingForSalesCreditMemoLines(SalesCrMemoLine: array[2] of Record "Sales Cr.Memo Line"; VerifyDocument: Enum "Document Line Source Type")
    var
        DocumentLineTracking: Page "Document Line Tracking";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(SalesCrMemoLine) do begin
            EnqueueLineValues(VerifyDocument, SalesCrMemoLine[Index]."Line No.", SalesCrMemoLine[Index]."No.", SalesCrMemoLine[Index].Quantity, SalesCrMemoLine[Index].Description, SalesCrMemoLine[Index]."Unit of Measure Code");
            DocumentLineTracking.SetSourceDoc(
              VerifyDocument, SalesCrMemoLine[Index]."Document No.", SalesCrMemoLine[Index]."Line No.", SalesCrMemoLine[Index]."Blanket Order No.", SalesCrMemoLine[Index]."Blanket Order Line No.",
              SalesCrMemoLine[Index]."Order No.", SalesCrMemoLine[Index]."Order Line No.");
            DocumentLineTracking.Run();
        end;
    end;

    local procedure EnqueueLineValues(VerifyDocument: Enum "Document Line Source Type"; LineNo: Integer; No: Code[20]; Quantity: Decimal; Description: Text; UoMCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(VerifyDocument);
        LibraryVariableStorage.Enqueue(LineNo);
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Description);
        LibraryVariableStorage.Enqueue(UoMCode);
    end;

    local procedure VerifyDocumentLineTrackingForPurchaseOrder(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        VerifyDocumentLineTrackingLine(DocumentLineTracking, BlanketPurchaseOrderLinesTxt, 1, 1);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedBlanketPurchaseOrderLinesTxt, 1, 2);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PurchaseOrderLinesTxt, 1, 3);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedPurchaseOrderLinesTxt, 1, 4);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedPurchaseReceiptLinesTxt, 1, 5);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedPurchaseInvoiceLinesTxt, 1, 6);
    end;

    local procedure VerifyDocumentLineTrackingForPurchaseReturnOrder(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PurchaseReturnOrderLinesTxt, 1, 1);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedPurchaseReturnOrderLinesTxt, 1, 2);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedReturnShipmentLinesTxt, 1, 3);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedPurchaseCreditMemoLinesTxt, 1, 4);
    end;

    local procedure VerifyDocumentLineTrackingForSalesOrder(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        VerifyDocumentLineTrackingLine(DocumentLineTracking, BlanketSalesOrderLinesTxt, 1, 1);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedBlanketSalesOrderLinesTxt, 1, 2);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, SalesOrderLinesTxt, 1, 3);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedSalesOrderLinesTxt, 1, 4);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedSalesShipmentLinesTxt, 1, 5);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedSalesInvoiceLinesTxt, 1, 6);
    end;

    local procedure VerifyDocumentLineTrackingForSalesReturnOrder(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        VerifyDocumentLineTrackingLine(DocumentLineTracking, SalesReturnOrderLinesTxt, 1, 1);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedSalesReturnOrderLinesTxt, 1, 2);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedReturnReceiptLinesTxt, 1, 3);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PostedSalesCreditMemoLinesTxt, 1, 4);
    end;

    local procedure VerifyDocumentLineTrackingHeader(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        DocumentLineTracking.SourceDocLineNo.AssertEquals(LibraryVariableStorage.DequeueText());
        DocumentLineTracking.DocLineNo.AssertEquals(LibraryVariableStorage.DequeueText());
        DocumentLineTracking.DocLineQuantity.AssertEquals(LibraryVariableStorage.DequeueInteger());
        DocumentLineTracking.DocLineDescription.AssertEquals(LibraryVariableStorage.DequeueText());
        DocumentLineTracking.DocLineUnit.AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    local procedure VerifyDocumentLineTrackingLine(var DocumentLineTracking: TestPage "Document Line Tracking"; TableNameValue: Text; ExpectedCount: Integer; EntryNo: Integer)
    begin
        DocumentLineTracking.GotoKey(EntryNo);
        DocumentLineTracking."Table Name".AssertEquals(TableNameValue);
        DocumentLineTracking."No. of Records".AssertEquals(ExpectedCount);
    end;

    local procedure CreateBlanketPurchaseOrder(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchaseBlanketOrder(
                PurchHeader, PurchLine, Item, '', '', LibraryRandom.RandInt(10), WorkDate(),
                LibraryRandom.RandDecInRange(100, 1000, 2));
    end;

    local procedure BlanketPurchaseOrderMakeOrderAndArchive(PurchaseHeader: Record "Purchase Header")
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);
    end;

    local procedure FilterSetOnBlanketPurchaseOrderArchive(var BlanketPurchaseOrderArchive: TestPage "Blanket Purchase Order Archive"; PurchaseHeader: Record "Purchase Header")
    begin
        BlanketPurchaseOrderArchive.Filter.SetFilter("Document Type", Format(PurchaseHeader."Document Type"));
        BlanketPurchaseOrderArchive.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseHeader.CalcFields("No. of Archived Versions");
        BlanketPurchaseOrderArchive.Filter.SetFilter("Version No.", Format(PurchaseHeader."No. of Archived Versions"));
        BlanketPurchaseOrderArchive.Filter.SetFilter("Doc. No. Occurrence", Format(PurchaseHeader."Doc. No. Occurrence"));
    end;

    local procedure VerifyDocumentLineTrackingForBlanketPurchaseOrderArchive(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        VerifyDocumentLineTrackingLine(DocumentLineTracking, BlanketPurchaseOrderLinesTxt, 1, 1);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, ArchivedBlanketPurchaseOrderLinesTxt, 1, 2);
        VerifyDocumentLineTrackingLine(DocumentLineTracking, PurchaseOrderLinesTxt, 1, 3);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure DocumentLineTrackingPageHandler(var DocumentLineTracking: TestPage "Document Line Tracking")
    var
        VerifyDocument: Enum "Document Line Source Type";
    begin
        VerifyDocument := "Document Line Source Type".FromInteger(LibraryVariableStorage.DequeueInteger());
        VerifyDocumentLineTrackingHeader(DocumentLineTracking);
        case VerifyDocument of
            "Document Line Source Type"::"Purchase Order", "Document Line Source Type"::"Blanket Purchase Order",
          "Document Line Source Type"::"Purchase Invoice", "Document Line Source Type"::"Purchase Receipt":
                VerifyDocumentLineTrackingForPurchaseOrder(DocumentLineTracking);
            "Document Line Source Type"::"Purchase Return Order", "Document Line Source Type"::"Return Shipment",
          "Document Line Source Type"::"Purchase Credit Memo":
                VerifyDocumentLineTrackingForPurchaseReturnOrder(DocumentLineTracking);
            "Document Line Source Type"::"Sales Order", "Document Line Source Type"::"Blanket Sales Order",
          "Document Line Source Type"::"Sales Invoice", "Document Line Source Type"::"Sales Shipment":
                VerifyDocumentLineTrackingForSalesOrder(DocumentLineTracking);
            "Document Line Source Type"::"Sales Return Order", "Document Line Source Type"::"Return Receipt",
          "Document Line Source Type"::"Sales Credit Memo":
                VerifyDocumentLineTrackingForSalesReturnOrder(DocumentLineTracking);
        end;
        DocumentLineTracking.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EmptyDocumentLineTrackingPageHandler(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        DocumentLineTracking.SourceDocLineNo.AssertEquals('');
        DocumentLineTracking.DocLineNo.AssertEquals('');
        DocumentLineTracking.DocLineQuantity.AssertEquals('');
        DocumentLineTracking.DocLineDescription.AssertEquals('');
        DocumentLineTracking.DocLineUnit.AssertEquals('');
        Assert.IsFalse(DocumentLineTracking.First(), 'Expecting blank Document Line Tracking page');
        DocumentLineTracking.Close();
    end;

    [ModalPageHandler]
    procedure DocumentLineTrackingPageHandler2(var DocumentLineTracking: TestPage "Document Line Tracking")
    begin
        VerifyDocumentLineTrackingForBlanketPurchaseOrderArchive(DocumentLineTracking);
    end;
}

