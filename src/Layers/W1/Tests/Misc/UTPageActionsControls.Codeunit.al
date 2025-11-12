codeunit 134341 "UT Page Actions & Controls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJob: Codeunit "Library - Job";
        AmountRoundingValidationErr: Label 'Validation error for Field: %1,  Message = ''You cannot change the contents of the %2 field because there are posted ledger entries.';
        LibraryMarketing: Codeunit "Library - Marketing";
        TaskNoErr: Label 'Wrong number of Tasks was created.';
        CountOrdersNotInvoicedErr: Label 'Wrong result of PurchaseCue.CountOrders("Not Invoiced") ';
        CountOrdersPartiallyInvoicedErr: Label 'Wrong result of PurchaseCue.CountOrders("Partially Invoiced") ';
        PageFieldVisibleErr: Label '%1 must be visible.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryTemplates: Codeunit "Library - Templates";
        PageFieldNotVisibleErr: Label '%1 must not be visible.';
        FieldLengthErr: Label 'must not have the length more than 20 symbols';
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedSalesInvoiceLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentOpenPostedSalesInvoiceLines()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        Initialize();
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open tracking Invoice Lines from Posted Sales Shipment
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::Order);

        OpenPostedSalesShipment(PostedSalesShipment, SalesHeader);

        PostedSalesShipment.SalesShipmLines.ItemInvoiceLines.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedItemTrackingLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentOpenItemTrackingLines()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Item Tracking Lines from Posted Sales Shipment
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::Order);

        OpenPostedSalesShipment(PostedSalesShipment, SalesHeader);

        PostedSalesShipment.SalesShipmLines.ItemTrackingEntries.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,SalesCommentSheetMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentOpenComments()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Comments from Posted Sales Shipment
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::Order);

        OpenPostedSalesShipment(PostedSalesShipment, SalesHeader);

        PostedSalesShipment.SalesShipmLines.Comments.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,DimensionSetEntriesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentOpenDimensions()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Dimensions from Posted Sales Shipment
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::Order);

        OpenPostedSalesShipment(PostedSalesShipment, SalesHeader);

        PostedSalesShipment.SalesShipmLines.Dimensions.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedSalesShipmentLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceOpenPostedSalesShipmentLines()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open tracking Shipment Lines from Posted Sales Invoice
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::Order);

        OpenPostedSalesInvoice(PostedSalesInvoice, SalesHeader);

        PostedSalesInvoice.SalesInvLines.ItemShipmentLines.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedItemTrackingLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceOpenItemTrackingLines()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Item Tracking Lines from Posted Sales Invoice
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::Order);

        OpenPostedSalesInvoice(PostedSalesInvoice, SalesHeader);

        PostedSalesInvoice.SalesInvLines.ItemTrackingEntries.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,SalesCommentSheetMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceOpenComments()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Comments from Posted Sales Invoice
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::Order);

        OpenPostedSalesInvoice(PostedSalesInvoice, SalesHeader);

        PostedSalesInvoice.SalesInvLines.Comments.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,DimensionSetEntriesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceOpenDimensions()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Dimensions from Posted Sales Invoice
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::Order);

        OpenPostedSalesInvoice(PostedSalesInvoice, SalesHeader);

        PostedSalesInvoice.SalesInvLines.Dimensions.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedSalesRetReceiptLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoOpenPostedReturnReceiptLines()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open tracking Return Receipt Lines from Posted Sales Credit Memo
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        OpenPostedSalesCrMemo(PostedSalesCreditMemo, SalesHeader);

        PostedSalesCreditMemo.SalesCrMemoLines.ItemReturnReceiptLines.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedItemTrackingLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoOpenItemTrackingLines()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Item Tracking Lines from Posted Sales Credit Memo
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        OpenPostedSalesCrMemo(PostedSalesCreditMemo, SalesHeader);

        PostedSalesCreditMemo.SalesCrMemoLines.ItemTrackingEntries.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,SalesCommentSheetMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoOpenComments()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Comments from Posted Sales Credit Memo
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        OpenPostedSalesCrMemo(PostedSalesCreditMemo, SalesHeader);

        PostedSalesCreditMemo.SalesCrMemoLines.Comments.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,DimensionSetEntriesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoOpenDimensions()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Dimensions from Posted Sales Credit Memo
        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        OpenPostedSalesCrMemo(PostedSalesCreditMemo, SalesHeader);

        PostedSalesCreditMemo.SalesCrMemoLines.Dimensions.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedSalesCrMemoLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesRetReceiptOpenPostedCreditMemoLines()
    var
        SalesHeader: Record "Sales Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open tracking Credit Memo Lines from Posted Return Receipt
        UpdateNoSeriesOnSalesSetup();

        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::"Return Order");

        OpenPostedReturnReceipt(PostedReturnReceipt, SalesHeader);

        PostedReturnReceipt.ReturnRcptLines.ItemCreditMemoLines.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedItemTrackingLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesRetReceiptOpenItemTrackingLines()
    var
        SalesHeader: Record "Sales Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Item Tracking Lines from Posted Return Receipt
        UpdateNoSeriesOnSalesSetup();

        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::"Return Order");

        OpenPostedReturnReceipt(PostedReturnReceipt, SalesHeader);

        PostedReturnReceipt.ReturnRcptLines.ItemTrackingEntries.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,SalesCommentSheetMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesRetReceiptOpenComments()
    var
        SalesHeader: Record "Sales Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Comments from Posted Return Receipt
        UpdateNoSeriesOnSalesSetup();

        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::"Return Order");

        OpenPostedReturnReceipt(PostedReturnReceipt, SalesHeader);

        PostedReturnReceipt.ReturnRcptLines.Comments.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,DimensionSetEntriesMPH')]
    [Scope('OnPrem')]
    procedure PostedSalesRetReceiptOpenDimensions()
    var
        SalesHeader: Record "Sales Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376891] Open Dimensions from Posted Return Receipt
        UpdateNoSeriesOnSalesSetup();

        PostSalesDocumentWithLotTracking(SalesHeader, SalesHeader."Document Type"::"Return Order");

        OpenPostedReturnReceipt(PostedReturnReceipt, SalesHeader);

        PostedReturnReceipt.ReturnRcptLines.Dimensions.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedPurchaseInvoiceLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptOpenPostedPurchaseInvoiceLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open tracking Invoice Lines from Posted Purchase Receipt
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        OpenPostedPurchaseReceipt(PostedPurchaseReceipt, PurchaseHeader);

        PostedPurchaseReceipt.PurchReceiptLines.ItemInvoiceLines.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedItemTrackingLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptOpenItemTrackingLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Item Tracking Lines from Posted Purchase Receipt
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        OpenPostedPurchaseReceipt(PostedPurchaseReceipt, PurchaseHeader);

        PostedPurchaseReceipt.PurchReceiptLines.ItemTrackingEntries.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PurchCommentSheetMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptOpenComments()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Comments from Posted Purchase Receipt
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        OpenPostedPurchaseReceipt(PostedPurchaseReceipt, PurchaseHeader);

        PostedPurchaseReceipt.PurchReceiptLines.Comments.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,DimensionSetEntriesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptOpenDimensions()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Dimensions from Posted Purchase Receipt
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        OpenPostedPurchaseReceipt(PostedPurchaseReceipt, PurchaseHeader);

        PostedPurchaseReceipt.PurchReceiptLines.Dimensions.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedPurchaseReceiptLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceOpenPostedPurchaseReceiptLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open tracking Receipt Lines from Posted Purchase Invoice
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        OpenPostedPurchaseInvoice(PostedPurchaseInvoice, PurchaseHeader);

        PostedPurchaseInvoice.PurchInvLines.ItemReceiptLines.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedItemTrackingLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceOpenItemTrackingLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Item Tracking Lines from Posted Purchase Invoice
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        OpenPostedPurchaseInvoice(PostedPurchaseInvoice, PurchaseHeader);

        PostedPurchaseInvoice.PurchInvLines.ItemTrackingEntries.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PurchCommentSheetMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceOpenComments()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Comments from Posted Purchase Invoice
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        OpenPostedPurchaseInvoice(PostedPurchaseInvoice, PurchaseHeader);

        PostedPurchaseInvoice.PurchInvLines.Comments.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,DimensionSetEntriesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceOpenDimensions()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Dimensions from Posted Purchase Invoice
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        OpenPostedPurchaseInvoice(PostedPurchaseInvoice, PurchaseHeader);

        PostedPurchaseInvoice.PurchInvLines.Dimensions.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedPurchRetShipmenttLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCrMemoOpenPostedReturnShipmentLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open tracking Return Shipment Lines from Posted Purchase Credit Memo
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        OpenPostedPurchaseCrMemo(PostedPurchaseCreditMemo, PurchaseHeader);

        PostedPurchaseCreditMemo.PurchCrMemoLines.ItemReturnShipmentLines.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedItemTrackingLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCrMemoOpenItemTrackingLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Item Tracking Lines from Posted Purchase Credit Memo
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        OpenPostedPurchaseCrMemo(PostedPurchaseCreditMemo, PurchaseHeader);

        PostedPurchaseCreditMemo.PurchCrMemoLines.ItemTrackingEntries.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PurchCommentSheetMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCrMemoOpenComments()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Comments from Posted Purchase Credit Memo
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        OpenPostedPurchaseCrMemo(PostedPurchaseCreditMemo, PurchaseHeader);

        PostedPurchaseCreditMemo.PurchCrMemoLines.Comments.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,DimensionSetEntriesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCrMemoOpenDimensions()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Dimensions from Posted Purchase Credit Memo
        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        OpenPostedPurchaseCrMemo(PostedPurchaseCreditMemo, PurchaseHeader);

        PostedPurchaseCreditMemo.PurchCrMemoLines.Dimensions.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedPurchaseCrMemoLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseRetShipmentOpenPostedCreditMemoLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open tracking Credit Memo Lines from Posted Return Shipment
        UpdateNoSeriesOnPurchaseSetup();

        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        OpenPostedReturnShipment(PostedReturnShipment, PurchaseHeader);

        PostedReturnShipment.ReturnShptLines.ItemCreditMemoLines.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PostedItemTrackingLinesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseRetShipmentOpenItemTrackingLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Item Tracking Lines from Posted Return Shipment
        UpdateNoSeriesOnPurchaseSetup();

        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        OpenPostedReturnShipment(PostedReturnShipment, PurchaseHeader);

        PostedReturnShipment.ReturnShptLines.ItemTrackingEntries.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,PurchCommentSheetMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseRetShipmentOpenComments()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Comments from Posted Return Shipment
        UpdateNoSeriesOnPurchaseSetup();

        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        OpenPostedReturnShipment(PostedReturnShipment, PurchaseHeader);

        PostedReturnShipment.ReturnShptLines.Comments.Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingMPH,DimensionSetEntriesMPH')]
    [Scope('OnPrem')]
    procedure PostedPurchaseRetShipmentOpenDimensions()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376891] Open Dimensions from Posted Return Shipment
        UpdateNoSeriesOnPurchaseSetup();

        PostPurchaseDocumentWithLotTracking(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");

        OpenPostedReturnShipment(PostedReturnShipment, PurchaseHeader);

        PostedReturnShipment.ReturnShptLines.Dimensions.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POCardJobQueueStatusInvisible()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseOrder."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnPurchaseSetup(false, false);

        PurchaseOrder.OpenNew();
        Assert.IsFalse(PurchaseOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POCardJobQueueStatusVisiblePostWithQueue()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseOrder."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(true, false);

        PurchaseOrder.OpenNew();
        Assert.IsTrue(PurchaseOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POCardJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseOrder."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(false, true);

        PurchaseOrder.OpenNew();
        Assert.IsTrue(PurchaseOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PICardJobQueueStatusInvisible()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseInvoice."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnPurchaseSetup(false, false);

        PurchaseInvoice.OpenNew();
        Assert.IsFalse(PurchaseInvoice."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PICardJobQueueStatusVisiblePostWithQueue()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseInvoice."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(true, false);

        PurchaseInvoice.OpenNew();
        Assert.IsTrue(PurchaseInvoice."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PICardJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseInvoice."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(false, true);

        PurchaseInvoice.OpenNew();
        Assert.IsTrue(PurchaseInvoice."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PCMCardJobQueueStatusInvisible()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseCreditMemo."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnPurchaseSetup(false, false);

        PurchaseCreditMemo.OpenNew();
        Assert.IsFalse(PurchaseCreditMemo."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PCMCardJobQueueStatusVisiblePostWithQueue()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseCreditMemo."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(true, false);

        PurchaseCreditMemo.OpenNew();
        Assert.IsTrue(PurchaseCreditMemo."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PCMCardJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseCreditMemo."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(false, true);

        PurchaseCreditMemo.OpenNew();
        Assert.IsTrue(PurchaseCreditMemo."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PROCardJobQueueStatusInvisible()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseReturnOrder."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnPurchaseSetup(false, false);

        PurchaseReturnOrder.OpenNew();
        Assert.IsFalse(PurchaseReturnOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PROCardJobQueueStatusVisiblePostWithQueue()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseReturnOrder."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(true, false);

        PurchaseReturnOrder.OpenNew();
        Assert.IsTrue(PurchaseReturnOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PROCardJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseReturnOrder."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(false, true);

        PurchaseReturnOrder.OpenNew();
        Assert.IsTrue(PurchaseReturnOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POListJobQueueStatusInvisible()
    var
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseOrderList."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnPurchaseSetup(false, false);

        PurchaseOrderList.OpenNew();
        Assert.IsFalse(PurchaseOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POListJobQueueStatusVisiblePostWithQueue()
    var
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseOrderList."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(true, false);

        PurchaseOrderList.OpenNew();
        Assert.IsTrue(PurchaseOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure POListJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseOrderList."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(false, true);

        PurchaseOrderList.OpenNew();
        Assert.IsTrue(PurchaseOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PIListJobQueueStatusInvisible()
    var
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseInvoices."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnPurchaseSetup(false, false);

        PurchaseInvoices.OpenNew();
        Assert.IsFalse(PurchaseInvoices."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PIListJobQueueStatusVisiblePostWithQueue()
    var
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseInvoices."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(true, false);

        PurchaseInvoices.OpenNew();
        Assert.IsTrue(PurchaseInvoices."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PIListJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseInvoices."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(false, true);

        PurchaseInvoices.OpenNew();
        Assert.IsTrue(PurchaseInvoices."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PCMListJobQueueStatusInvisible()
    var
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseCreditMemos."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnPurchaseSetup(false, false);

        PurchaseCreditMemos.OpenNew();
        Assert.IsFalse(PurchaseCreditMemos."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PCMListJobQueueStatusVisiblePostWithQueue()
    var
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseCreditMemos."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(true, false);

        PurchaseCreditMemos.OpenNew();
        Assert.IsTrue(PurchaseCreditMemos."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PCMListJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseCreditMemos."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(false, true);

        PurchaseCreditMemos.OpenNew();
        Assert.IsTrue(PurchaseCreditMemos."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PROListJobQueueStatusInvisible()
    var
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseReturnOrderList."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnPurchaseSetup(false, false);

        PurchaseReturnOrderList.OpenNew();
        Assert.IsFalse(PurchaseReturnOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PROListJobQueueStatusVisiblePostWithQueue()
    var
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseReturnOrderList."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(true, false);

        PurchaseReturnOrderList.OpenNew();
        Assert.IsTrue(PurchaseReturnOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PROListJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 211732] PurchaseReturnOrderList."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnPurchaseSetup(false, true);

        PurchaseReturnOrderList.OpenNew();
        Assert.IsTrue(PurchaseReturnOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PROListFieldsVisible()
    var
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 252621] PurchaseReturnOrderList has visible fields: "Status".

        PurchaseReturnOrderList.OpenNew();
        Assert.IsTrue(PurchaseReturnOrderList.Status.Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOCardJobQueueStatusInvisible()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesOrder."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnSalesSetup(false, false);

        SalesOrder.OpenNew();
        Assert.IsFalse(SalesOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOCardJobQueueStatusVisiblePostWithQueue()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesOrder."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(true, false);

        SalesOrder.OpenNew();
        Assert.IsTrue(SalesOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOCardJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesOrder."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(false, true);

        SalesOrder.OpenNew();
        Assert.IsTrue(SalesOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SICardJobQueueStatusInvisible()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesInvoice."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnSalesSetup(false, false);

        SalesInvoice.OpenNew();
        Assert.IsFalse(SalesInvoice."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SICardJobQueueStatusVisiblePostWithQueue()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesInvoice."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(true, false);

        SalesInvoice.OpenNew();
        Assert.IsTrue(SalesInvoice."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SICardJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesInvoice."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(false, true);

        SalesInvoice.OpenNew();
        Assert.IsTrue(SalesInvoice."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SCMCardJobQueueStatusInvisible()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesCreditMemo."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnSalesSetup(false, false);

        SalesCreditMemo.OpenNew();
        Assert.IsFalse(SalesCreditMemo."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SCMCardJobQueueStatusVisiblePostWithQueue()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesCreditMemo."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(true, false);

        SalesCreditMemo.OpenNew();
        Assert.IsTrue(SalesCreditMemo."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SCMCardJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesCreditMemo."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(false, true);

        SalesCreditMemo.OpenNew();
        Assert.IsTrue(SalesCreditMemo."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SROCardJobQueueStatusInvisible()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesReturnOrder."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnSalesSetup(false, false);

        SalesReturnOrder.OpenNew();
        Assert.IsFalse(SalesReturnOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SROCardJobQueueStatusVisiblePostWithQueue()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesReturnOrder."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(true, false);

        SalesReturnOrder.OpenNew();
        Assert.IsTrue(SalesReturnOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SROCardJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesReturnOrder."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(false, true);

        SalesReturnOrder.OpenNew();
        Assert.IsTrue(SalesReturnOrder."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOListJobQueueStatusInvisible()
    var
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesOrderList."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnSalesSetup(false, false);

        SalesOrderList.OpenNew();
        Assert.IsFalse(SalesOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOListJobQueueStatusVisiblePostWithQueue()
    var
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesOrderList."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(true, false);

        SalesOrderList.OpenNew();
        Assert.IsTrue(SalesOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SOListJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesOrderList."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(false, true);

        SalesOrderList.OpenNew();
        Assert.IsTrue(SalesOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIListJobQueueStatusInvisible()
    var
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesInvoiceList."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnSalesSetup(false, false);

        SalesInvoiceList.OpenNew();
        Assert.IsFalse(SalesInvoiceList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIListJobQueueStatusVisiblePostWithQueue()
    var
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesInvoiceList."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(true, false);

        SalesInvoiceList.OpenNew();
        Assert.IsTrue(SalesInvoiceList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIListJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesInvoiceList."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(false, true);

        SalesInvoiceList.OpenNew();
        Assert.IsTrue(SalesInvoiceList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SCMListJobQueueStatusInvisible()
    var
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesCreditMemos."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnSalesSetup(false, false);

        SalesCreditMemos.OpenNew();
        Assert.IsFalse(SalesCreditMemos."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SCMListJobQueueStatusVisiblePostWithQueue()
    var
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesCreditMemos."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(true, false);

        SalesCreditMemos.OpenNew();
        Assert.IsTrue(SalesCreditMemos."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SCMListJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesCreditMemos."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(false, true);

        SalesCreditMemos.OpenNew();
        Assert.IsTrue(SalesCreditMemos."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SROListJobQueueStatusInvisible()
    var
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesReturnOrderList."Job Queue Status".VISIBLE = FALSE when posting with job queue is disabled
        UpdateJobQueueActiveOnSalesSetup(false, false);

        SalesReturnOrderList.OpenNew();
        Assert.IsFalse(SalesReturnOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SROListJobQueueStatusVisiblePostWithQueue()
    var
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesReturnOrderList."Job Queue Status".VISIBLE = TRUE when post with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(true, false);

        SalesReturnOrderList.OpenNew();
        Assert.IsTrue(SalesReturnOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SROListJobQueueStatusVisiblePostAndPrintWithQueue()
    var
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 211732] SalesReturnOrderList."Job Queue Status".VISIBLE = TRUE when post and print with job queue is enabled
        UpdateJobQueueActiveOnSalesSetup(false, true);

        SalesReturnOrderList.OpenNew();
        Assert.IsTrue(SalesReturnOrderList."Job Queue Status".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SROListFieldsVisible()
    var
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 252621] SalesReturnOrderList has visible fields: "Status", "Amount", "Amount Including VAT".

        SalesReturnOrderList.OpenNew();
        Assert.IsTrue(SalesReturnOrderList.Status.Visible(), '');
        Assert.IsTrue(SalesReturnOrderList.Amount.Visible(), '');
        Assert.IsTrue(SalesReturnOrderList."Amount Including VAT".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardICPartnerCodeVisible()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Vendor] [IC]
        // [SCENARIO 223571] "IC Partner Code" is visible on Vendor Card

        // [GIVEN] No Application Area is set
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Vendor "V" with "IC Partner Code" = "ICP"
        CreateVendorWithICPartnerCode(Vendor);

        // [WHEN] Open Vendor card page for "V"
        OpenVendorCard(VendorCard, Vendor."No.");

        // [THEN] Card page shows "ICP" in "IC Partner Code" field
        Assert.IsTrue(VendorCard."IC Partner Code".Visible(), 'Field "IC Partner Code" must be visible');
        VendorCard."IC Partner Code".AssertEquals(Vendor."IC Partner Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardICPartnerCodeNotVisibleInBasicApplicationArea()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Vendor] [IC] [Basic]
        // [SCENARIO 223571] "IC Partner Code" is not visible on Vendor Card if Application Area is set to Basic

        // [GIVEN] Application Area = BASIC
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] Vendor "V" with "IC Partner Code" = "ICP"
        CreateVendorWithICPartnerCode(Vendor);

        // [WHEN] Open Vendor card page for "V"
        OpenVendorCard(VendorCard, Vendor."No.");

        // [THEN] Card page does not show "IC Partner Code" field
        Assert.IsFalse(VendorCard.FindFirstField("IC Partner Code", Vendor."IC Partner Code"), 'Field "IC Partner Code" must be hidden');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardICPartnerCodeNotVisibleInSuiteApplicationArea()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Vendor] [IC] [Suite]
        // [SCENARIO 223571] "IC Partner Code" is not visible on Vendor Card if Application Area is set to Suite

        // [GIVEN] Application Area = Suite
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Vendor "V" with "IC Partner Code" = "ICP"
        CreateVendorWithICPartnerCode(Vendor);

        // [WHEN] Open Vendor card page for "V"
        OpenVendorCard(VendorCard, Vendor."No.");

        // [THEN] Card page does not show "IC Partner Code" field
        Assert.IsFalse(VendorCard.FindFirstField("IC Partner Code", Vendor."IC Partner Code"), 'Field "IC Partner Code" must be hidden');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardICPartnerCodeVisible()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer] [IC]
        // [SCENARIO 223571] "IC Partner Code" is visible on Customer Card

        // [GIVEN] No Application Area is set
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Customer "C" with "IC Partner Code" = "ICP"
        CreateCustomerWithICPartnerCode(Customer);

        // [WHEN] Open Customer card page for "C"
        OpenCustomerCard(CustomerCard, Customer."No.");

        // [THEN] Card page shows "ICP" in "IC Partner Code" field
        Assert.IsTrue(CustomerCard."IC Partner Code".Visible(), 'Field "IC Partner Code" must be visible');
        CustomerCard."IC Partner Code".AssertEquals(Customer."IC Partner Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardICPartnerCodeNotVisibleInBasicApplicationArea()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer] [IC] [Basic]
        // [SCENARIO 223571] "IC Partner Code" is not visible on Customer Card if Application Area is set to Basic

        // [GIVEN] Application Area = BASIC
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] Customer "C" with "IC Partner Code" = "ICP"
        CreateCustomerWithICPartnerCode(Customer);

        // [WHEN] Open Customer card page for "C"
        OpenCustomerCard(CustomerCard, Customer."No.");

        // [THEN] Card page does not show "IC Partner Code" field
        Assert.IsFalse(
          CustomerCard.FindFirstField("IC Partner Code", Customer."IC Partner Code"), 'Field "IC Partner Code" must be hidden');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardICPartnerCodeNotVisibleInSuiteApplicationArea()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer] [IC] [Suite]
        // [SCENARIO 223571] "IC Partner Code" is not visible on Customer Card if Application Area is set to Suite

        // [GIVEN] Application Area = Suite
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Customer "C" with "IC Partner Code" = "ICP"
        CreateCustomerWithICPartnerCode(Customer);

        // [WHEN] Open Customer card page for "V"
        OpenCustomerCard(CustomerCard, Customer."No.");

        // [THEN] Card page does not show "IC Partner Code" field
        Assert.IsFalse(
          CustomerCard.FindFirstField("IC Partner Code", Customer."IC Partner Code"), 'Field "IC Partner Code" must be hidden');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentCardCanBeOpenedFromListInEditMode()
    var
        PostedSalesShipments: TestPage "Posted Sales Shipments";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 235003] Posted Sales Shipment card can be opened from the Posted Sales Shipments page in Edit-mode

        // [GIVEN] Posted Sales Shipments page is opened
        PostedSalesShipments.OpenEdit();

        // [WHEN] Push Edit button
        PostedSalesShipment.Trap();
        PostedSalesShipments.Edit().Invoke();

        // [THEN] Posted Sales Shipment card is opened in Edit-mode
        Assert.IsTrue(PostedSalesShipment.Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceCardCanBeOpenedFromListInEditMode()
    var
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 235003] Posted Sales Invoice card can be opened from the Posted Sales Invoices page in Edit-mode

        // [GIVEN] Posted Sales Invoices page is opened
        PostedSalesInvoices.OpenEdit();

        // [WHEN] Push Edit button
        PostedSalesInvoice.Trap();
        PostedSalesInvoices.Edit().Invoke();

        // [THEN] Posted Sales Invoice card is opened in Edit-mode
        Assert.IsTrue(PostedSalesInvoice.Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesMemoCardCanBeOpenedFromListInEditMode()
    var
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 235003] Posted Credit Memo card can be opened from the Posted Credit Memos page in Edit-mode

        // [GIVEN] Posted Credit Memos page is opened
        PostedSalesCreditMemos.OpenEdit();

        // [WHEN] Push Edit button
        PostedSalesCreditMemo.Trap();
        PostedSalesCreditMemos.Edit().Invoke();

        // [THEN] Posted Credit Memo card is opened in Edit-mode
        Assert.IsTrue(PostedSalesCreditMemo.Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptCardCanBeOpenedFromListInEditMode()
    var
        PostedPurchaseReceipts: TestPage "Posted Purchase Receipts";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        // [FEATURE] [Purchase] [Receipt]
        // [SCENARIO 235003] Posted Purchase Receipt card can be opened from the Posted Purchase Receipts page in Edit-mode

        // [GIVEN] Posted Purchase Receipts page is opened
        PostedPurchaseReceipts.OpenEdit();

        // [WHEN] Push Edit button
        PostedPurchaseReceipt.Trap();
        PostedPurchaseReceipts.Edit().Invoke();

        // [THEN] Posted Purchase Receipt card is opened in Edit-mode
        Assert.IsTrue(PostedPurchaseReceipt.Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceCardCanBeOpenedFromListInEditMode()
    var
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 235003] Posted Purchase Invoice card can be opened from the Posted Purchase Invoices page in Edit-mode

        // [GIVEN] Posted Purchase Invoices page is opened
        PostedPurchaseInvoices.OpenEdit();

        // [WHEN] Push Edit button
        PostedPurchaseInvoice.Trap();
        PostedPurchaseInvoices.Edit().Invoke();

        // [THEN] Posted Purchase Invoice card is opened in Edit-mode
        Assert.IsTrue(PostedPurchaseInvoice.Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseMemoCardCanBeOpenedFromListInEditMode()
    var
        PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 235003] Posted Purchase Credit Memo card can be opened from the Posted Purchase Credit Memos page in Edit-mode

        // [GIVEN] Posted Purchase Credit Memos page is opened
        PostedPurchaseCreditMemos.OpenEdit();

        // [WHEN] Push Edit button
        PostedPurchaseCreditMemo.Trap();
        PostedPurchaseCreditMemos.Edit().Invoke();

        // [THEN] Posted Purchase Credit Memo card is opened in Edit-mode
        Assert.IsTrue(PostedPurchaseCreditMemo.Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PageGeneralLedgerSetupFields()
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupPage: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [General Ledger Setup]
        // [SCENARIO 258864] There is a "#Basic,#Suite" application area for "Amount Rounding Precision (LCY)", "Amount Decimal Places (LCY)",
        // [SCENARIO 258864] "Unit-Amount Rounding Precision (LCY)" and "Unit-Amount Decimal Places (LCY)" fields in general ledger setup page
        Initialize();
        MockRecordWithKeyValue(GLEntry);
        Commit();

        LibraryApplicationArea.EnableFoundationSetup();
        SetBasicUserExperience();

        GeneralLedgerSetupPage.OpenEdit();
        Assert.IsTrue(GeneralLedgerSetupPage.AmountRoundingPrecision.Enabled(), '');
        Assert.IsTrue(GeneralLedgerSetupPage.AmountRoundingPrecision.Visible(), '');
        Assert.IsTrue(GeneralLedgerSetupPage.AmountRoundingPrecision.Editable(), '');
        Assert.IsTrue(GeneralLedgerSetupPage.AmountDecimalPlaces.Enabled(), '');
        Assert.IsTrue(GeneralLedgerSetupPage.AmountDecimalPlaces.Visible(), '');
        Assert.IsTrue(GeneralLedgerSetupPage.AmountDecimalPlaces.Editable(), '');
        Assert.IsTrue(GeneralLedgerSetupPage.UnitAmountRoundingPrecision.Enabled(), '');
        Assert.IsTrue(GeneralLedgerSetupPage.UnitAmountRoundingPrecision.Visible(), '');
        Assert.IsTrue(GeneralLedgerSetupPage.UnitAmountRoundingPrecision.Editable(), '');
        Assert.IsTrue(GeneralLedgerSetupPage.UnitAmountDecimalPlaces.Enabled(), '');
        Assert.IsTrue(GeneralLedgerSetupPage.UnitAmountDecimalPlaces.Visible(), '');
        Assert.IsTrue(GeneralLedgerSetupPage.UnitAmountDecimalPlaces.Editable(), '');

        asserterror GeneralLedgerSetupPage.AmountRoundingPrecision.SetValue(1 / (LibraryRandom.RandInt(3) * 10));
        Assert.ExpectedError(
          StrSubstNo(
            AmountRoundingValidationErr,
            'AmountRoundingPrecision',
            GeneralLedgerSetup.FieldCaption("Amount Rounding Precision")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PageGeneralLedgerEntriesFields()
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [General Ledger Entries]
        // [SCENARIO 256677] The field "External Document No." must be visible on the page "General Ledger Entries"

        // [GIVEN] Application Area = Suite
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] "G/L Entry"
        MockRecordWithKeyValue(GLEntry);

        // [WHEN] Open the page "General Ledger Entries"
        GeneralLedgerEntries.OpenView();

        // [THEN] The field "External Document No." is visible on the page "General Ledger Entries"
        Assert.IsTrue(GeneralLedgerEntries."External Document No.".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardPrepaymentPercent()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Sales] [Card]
        // [SCENARIO 257000] "Prepayment %" is enabled, visible and editable on "Customer Card" page
        CustomerCard.OpenEdit();
        Assert.IsTrue(CustomerCard."Prepayment %".Enabled(), '');
        Assert.IsTrue(CustomerCard."Prepayment %".Visible(), '');
        Assert.IsTrue(CustomerCard."Prepayment %".Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardPrepaymentPercent()
    var
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Purchase] [Card]
        // [SCENARIO 257000] "Prepayment %" is enabled, visible and editable on "Vendor Card" page
        VendorCard.OpenEdit();
        Assert.IsTrue(VendorCard."Prepayment %".Enabled(), '');
        Assert.IsTrue(VendorCard."Prepayment %".Visible(), '');
        Assert.IsTrue(VendorCard."Prepayment %".Editable(), '');
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentsPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedSalesShipmentsPageIsOpenedOnTopMostRecord()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [SCENARIO 256948] Filtered Posted Sales Shipments page is opened on top most record everytime.

        SalesShipmentHeader.SetCurrentKey("Posting Date");
        SalesShipmentHeader.Ascending(false);
        MockThreeRecordsAndOpenFilteredPage(SalesShipmentHeader, PAGE::"Posted Sales Shipments");
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoicesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedSalesInvoicesPageIsOpenedOnTopMostRecord()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO 256948] Filtered Posted Sales Invoices page is opened on top most record everytime.

        SalesInvoiceHeader.SetCurrentKey("Posting Date");
        SalesInvoiceHeader.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(SalesInvoiceHeader, PAGE::"Posted Sales Invoices");
    end;

    [Test]
    [HandlerFunctions('PostedSalesCreditMemosPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedSalesCreditMemosPageIsOpenedOnTopMostRecord()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [SCENARIO 256948] Filtered Posted Sales Credit Memos page is opened on top most record everytime.

        SalesCrMemoHeader.SetCurrentKey("Posting Date");
        SalesCrMemoHeader.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(SalesCrMemoHeader, PAGE::"Posted Sales Credit Memos");
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptsPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedReturnReceiptsPageIsOpenedOnTopMostRecord()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        // [SCENARIO 256948] Filtered Posted Return Receipts page is opened on top most record everytime.

        ReturnReceiptHeader.SetCurrentKey("Posting Date");
        ReturnReceiptHeader.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(ReturnReceiptHeader, PAGE::"Posted Return Receipts");
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseReceiptsPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedPurchaseReceiptsPageIsOpenedOnTopMostRecord()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        // [SCENARIO 256948] Filtered Posted Purchase Receipts page is opened on top most record everytime.

        PurchRcptHeader.SetCurrentKey("Posting Date");
        PurchRcptHeader.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(PurchRcptHeader, PAGE::"Posted Purchase Receipts");
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseInvoicesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedPurchaseInvoicesPageIsOpenedOnTopMostRecord()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [SCENARIO 256948] Filtered Posted Purchase Invoices page is opened on top most record everytime.

        PurchInvHeader.SetCurrentKey("Posting Date");
        PurchInvHeader.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(PurchInvHeader, PAGE::"Posted Purchase Invoices");
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseCreditMemosPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedPurchaseCreditMemosPageIsOpenedOnTopMostRecord()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [SCENARIO 256948] Filtered Posted Purchase Credit Memos page is opened on top most record everytime.

        PurchCrMemoHdr.SetCurrentKey("Posting Date");
        PurchCrMemoHdr.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(PurchCrMemoHdr, PAGE::"Posted Purchase Credit Memos");
    end;

    [Test]
    [HandlerFunctions('GeneralLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredGeneralLedgerEntriesPageIsOpenedOnTopMostRecord()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO 256948] Filtered General Ledger Entries page is opened on top most record everytime.

        GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        GLEntry.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(GLEntry, PAGE::"General Ledger Entries");
    end;

    [Test]
    [HandlerFunctions('ResourceLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredResourceLedgerEntriesPageIsOpenedOnTopMostRecord()
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        // [SCENARIO 256948] Filtered Resource Ledger Entries page is opened on top most record everytime.

        ResLedgerEntry.SetCurrentKey("Resource No.", "Posting Date");
        ResLedgerEntry.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(ResLedgerEntry, PAGE::"Resource Ledger Entries");
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredCustomerLedgerEntriesPageIsOpenedOnTopMostRecord()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO 256948] Filtered Customer Ledger Entries page is opened on top most record everytime.

        CustLedgerEntry.SetCurrentKey("Entry No.");
        CustLedgerEntry.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(CustLedgerEntry, PAGE::"Customer Ledger Entries");
    end;

    [Test]
    [HandlerFunctions('VendorLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredVendorLedgerEntriesPageIsOpenedOnTopMostRecord()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 256948] Filtered Vendor Ledger Entries page is opened on top most record everytime.

        VendorLedgerEntry.SetCurrentKey("Entry No.");
        VendorLedgerEntry.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(VendorLedgerEntry, PAGE::"Vendor Ledger Entries");
    end;

    [Test]
    [HandlerFunctions('CheckLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredCheckLedgerEntriesPageIsOpenedOnToMostRecord()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // [SCENARIO 256948] Filtered Check Ledger Entries page is opened on top most record everytime.

        CheckLedgerEntry.SetCurrentKey("Entry No.");
        CheckLedgerEntry.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(CheckLedgerEntry, PAGE::"Check Ledger Entries");
    end;

    [Test]
    [HandlerFunctions('ItemLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredItemLedgerEntriesPageIsOpenedOnTopMostRecord()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO 256948] Filtered Item Ledger Entries page is opened on top most record everytime.

        ItemLedgerEntry.SetCurrentKey("Entry No.");
        ItemLedgerEntry.Ascending(false);

        MockThreeRecordsAndOpenFilteredPage(ItemLedgerEntry, PAGE::"Item Ledger Entries");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderListFieldStatusVisible()
    var
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 260487] Purchase Order List has visible fields: "Status" if Application Area is set to Suite
        LibraryApplicationArea.EnableFoundationSetup();
        PurchaseOrderList.OpenNew();
        Assert.IsTrue(PurchaseOrderList.Status.Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTaskOnPrem()
    var
        ToDo: Record "To-do";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CreateTask: TestPage "Create Task";
    begin
        // [FEATURE] [Marketing] [To-do]
        // [SCEANRIO 258975] Cassies can set "Meeting" in field "Type" at Create Task page. "Location" field is visible
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        MockTodo(ToDo);

        CreateTask.OpenEdit();
        CreateTask.FILTER.SetFilter("No.", ToDo."No.");
        Assert.IsFalse(CreateTask.TypeSaaS.Visible(), '');
        Assert.IsTrue(CreateTask.TypeOnPrem.Visible(), '');
        Assert.IsTrue(CreateTask.Location.Visible(), '');
        Assert.AreEqual('Type', CreateTask.TypeOnPrem.Caption, '');

        CreateTask.TypeOnPrem.SetValue(ToDo.Type::Meeting);
        ToDo.Find();
        ToDo.TestField(Type, ToDo.Type::Meeting);

        ToDo.Delete(false)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderListPartialReceivedYes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCue: Record "Purchase Cue";
        PurchaseOrderListTestPage: TestPage "Purchase Order List";
        CountOfOrders: Integer;
    begin
        // [FEATURE] [Purchase] [Order] [Cue]
        // [SCENARIO 259717] "Purchase Order List" shows partially received purchase orders when passing view filter "Receive" = TRUE, "Completely Received" = FALSE

        // [GIVEN] Partially received purchase order "X"
        CountOfOrders := PurchaseCue.CountOrders(PurchaseCue.FieldNo("Not Invoiced"));

        CreatePurchaseOrderPartialReceive(PurchaseHeader);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Open "Purchase Order List" page with filter "Partially received orders"
        OpenPurchaseOrderListWithPartialReceiveFilter(PurchaseOrderListTestPage, true);

        // [THEN] "Purchase Order List" shows "X"
        Assert.AreEqual(CountOfOrders, PurchaseCue.CountOrders(PurchaseCue.FieldNo("Not Invoiced")), CountOrdersNotInvoicedErr);
        PurchaseOrderListTestPage.GotoRecord(PurchaseHeader);
        PurchaseOrderListTestPage."No.".AssertEquals(PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderListPartialReceivedNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCue: Record "Purchase Cue";
        PurchaseOrderListTestPage: TestPage "Purchase Order List";
        CountOfOrders: Integer;
    begin
        // [FEATURE] [Purchase] [Order] [Cue]
        // [SCENARIO 259717] "Purchase Order List" does not show partially received purchase orders when passing view filter "Receive" = FALSE, "Completely Received" = FALSE

        // [GIVEN] Partially received purchase order "X"
        CountOfOrders := PurchaseCue.CountOrders(PurchaseCue.FieldNo("Not Invoiced"));

        CreatePurchaseOrderPartialReceive(PurchaseHeader);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Open "Purchase Order List" page with filter "not received orders"
        OpenPurchaseOrderListWithPartialReceiveFilter(PurchaseOrderListTestPage, false);

        // [THEN] "Purchase Order List" does not show "X"
        Assert.AreEqual(CountOfOrders, PurchaseCue.CountOrders(PurchaseCue.FieldNo("Not Invoiced")), CountOrdersNotInvoicedErr);
        asserterror PurchaseOrderListTestPage.GotoRecord(PurchaseHeader);
        Assert.ExpectedError('The row does not exist on the TestPage.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderListPartialInvoicedYes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCue: Record "Purchase Cue";
        PurchaseOrderListTestPage: TestPage "Purchase Order List";
        CountOfOrders: Integer;
    begin
        // [FEATURE] [Purchase] [Order]
        // [SCENARIO 266060] "Purchase Order List" shows partially invoiced purchase orders when passing view filter "Invoice" = TRUE, "Completely Received" = TRUE

        // [GIVEN] Partially invoiced purchase order "X"
        CountOfOrders := PurchaseCue.CountOrders(PurchaseCue.FieldNo("Partially Invoiced"));

        CreatePurchaseOrderPartialInvoice(PurchaseHeader);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] When open "Purchase Order List" with filters "Partially invoiced"
        OpenPurchaseOrderListWithPartialInvoiceFilter(PurchaseOrderListTestPage, true);

        // [THEN] "Purchase Order List" shows "X"
        Assert.AreEqual(
          CountOfOrders + 1, PurchaseCue.CountOrders(PurchaseCue.FieldNo("Partially Invoiced")), CountOrdersPartiallyInvoicedErr);
        PurchaseOrderListTestPage.GotoRecord(PurchaseHeader);
        PurchaseOrderListTestPage."No.".AssertEquals(PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderListPartialInvoicedNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCue: Record "Purchase Cue";
        PurchaseOrderListTestPage: TestPage "Purchase Order List";
        CountOfOrders: Integer;
    begin
        // [FEATURE] [Purchase] [Order] [Cue]
        // [SCENARIO 266060] "Purchase Order List" does not show partially invoiced purchase orders when passing view filter "Invoice" = FALSE, "Completely Received" = TRUE

        // [GIVEN] Partially invoiced purchase order "X"
        CountOfOrders := PurchaseCue.CountOrders(PurchaseCue.FieldNo("Partially Invoiced"));

        CreatePurchaseOrderPartialInvoice(PurchaseHeader);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] When open "Purchase Order List" with filters "Received, not invoiced"
        OpenPurchaseOrderListWithPartialInvoiceFilter(PurchaseOrderListTestPage, false);

        // [THEN] "Purchase Order List" does not show "X"
        Assert.AreEqual(
          CountOfOrders + 1, PurchaseCue.CountOrders(PurchaseCue.FieldNo("Partially Invoiced")), CountOrdersPartiallyInvoicedErr);
        asserterror PurchaseOrderListTestPage.GotoRecord(PurchaseHeader);
        Assert.ExpectedError('The row does not exist on the TestPage.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderListStandAlonePartialInvoicedYes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCue: Record "Purchase Cue";
        PurchaseOrderListTestPage: TestPage "Purchase Order List";
        CountOfOrders: Integer;
    begin
        // [FEATURE] [Purchase] [Order] [Cue]
        // [SCENARIO 266060] "Purchase Order List" shows partially invoiced purchase orders when passing view filter "Invoice" = TRUE, "Completely Received" = TRUE

        // [GIVEN] Partially invoiced purchase order "X" within separate invoice
        CountOfOrders := PurchaseCue.CountOrders(PurchaseCue.FieldNo("Partially Invoiced"));

        CreatePurchaseOrderPartialInvoice(PurchaseHeader);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseHeader.Invoice := false;
        PurchaseHeader.Modify();

        // [WHEN] When open "Purchase Order List" with filters "Partially invoiced"
        OpenPurchaseOrderListWithPartialInvoiceFilter(PurchaseOrderListTestPage, true);

        // [THEN] "Purchase Order List" shows "X"
        Assert.AreEqual(
          CountOfOrders + 1, PurchaseCue.CountOrders(PurchaseCue.FieldNo("Partially Invoiced")), CountOrdersPartiallyInvoicedErr);
        PurchaseOrderListTestPage.GotoRecord(PurchaseHeader);
        PurchaseOrderListTestPage."No.".AssertEquals(PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderListStandAlonePartialInvoicedNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCue: Record "Purchase Cue";
        PurchaseOrderListTestPage: TestPage "Purchase Order List";
        CountOfOrders: Integer;
    begin
        // [FEATURE] [Purchase] [Order] [Cue]
        // [SCENARIO 266060] "Purchase Order List" does not show partially invoiced purchase orders when passing view filter "Invoice" = FALSE, "Completely Received" = TRUE

        // [GIVEN] Partially invoiced purchase order "X" within separate invoice
        CountOfOrders := PurchaseCue.CountOrders(PurchaseCue.FieldNo("Partially Invoiced"));

        CreatePurchaseOrderPartialInvoice(PurchaseHeader);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseHeader.Invoice := false;
        PurchaseHeader.Modify();

        // [WHEN] When open "Purchase Order List" with filters "Delivered, not invoiced"
        OpenPurchaseOrderListWithPartialInvoiceFilter(PurchaseOrderListTestPage, false);

        // [THEN] "Purchase Order List" does not show "X"
        Assert.AreEqual(
          CountOfOrders + 1, PurchaseCue.CountOrders(PurchaseCue.FieldNo("Partially Invoiced")), CountOrdersPartiallyInvoicedErr);
        asserterror PurchaseOrderListTestPage.GotoRecord(PurchaseHeader);
        Assert.ExpectedError('The row does not exist on the TestPage.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderListRecievedNotInvoiced()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseCue: Record "Purchase Cue";
        PurchaseOrderListTestPage: TestPage "Purchase Order List";
        CountOfOrders: Integer;
    begin
        // [FEATURE] [Purchase] [Order] [Cue]
        // [SCENARIO 266060] "Purchase Order List" shows fully received and not invoiced purchase orders when passing view filter "Invoice" = FALSE, "Completely Received" = TRUE

        // [GIVEN] Completely delivered, not invoiced purchase order "X"
        CountOfOrders := PurchaseCue.CountOrders(PurchaseCue.FieldNo("Not Invoiced"));

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          '', LibraryRandom.RandDecInRange(10, 20, 2), '', LibraryRandom.RandDate(10));

        PurchaseLine.Validate("Qty. to Invoice", 0);
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] When open "Purchase Order List" with filters "Delivered, not invoiced"
        OpenPurchaseOrderListWithPartialInvoiceFilter(PurchaseOrderListTestPage, false);

        // [THEN] "Purchase Order List" shows "X"
        Assert.AreEqual(CountOfOrders + 1, PurchaseCue.CountOrders(PurchaseCue.FieldNo("Not Invoiced")), CountOrdersNotInvoicedErr);
        PurchaseOrderListTestPage.GotoRecord(PurchaseHeader);
        PurchaseOrderListTestPage."No.".AssertEquals(PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VerifyMinimumQuantityInSalesPriceAndLineDiscountsPageHandler')]
    procedure OpenSalesPrLineDiscPartFromCustomerCard()
    var
        Customer: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [UI] [Sales] [Sales Prices]
        // [SCENARIO 264545] Customer page shows Sales Prices & Discounts
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Item with Sales Line Discount with Minimum Quantity = 15
        CreateItemWithSalesLineDiscount(SalesLineDiscount);

        // [WHEN] Open customer card
        OpenCustomerCard(CustomerCard, Customer."No.");

        // [THEN] Sales Pr. & Discounts overview shows the Sales Line Discount with Code = Item."No." and "Minimum Quantity" = 15
        LibraryVariableStorage.Enqueue(SalesLineDiscount.Code);
        LibraryVariableStorage.Enqueue(SalesLineDiscount."Minimum Quantity");
        CustomerCard."Prices and Discounts Overview".Invoke();

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenDefaultAnalysisViewEntriesPage()
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewEntries: TestPage "Analysis View Entries";
    begin
        // [FEATURE] [Analysis View]
        // [SCENARIO 264348] Analisys View Entry has default page
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisViewEntry.Init();
        AnalysisViewEntry."Analysis View Code" := AnalysisView.Code;
        AnalysisViewEntry."Account No." := LibraryUtility.GenerateGUID();
        AnalysisViewEntry.Insert();
        AnalysisViewEntry.SetRecFilter();
        AnalysisViewEntries.Trap();
        PAGE.Run(0, AnalysisViewEntry);
        AnalysisViewEntries."Account No.".AssertEquals(AnalysisViewEntry."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenDefaultAnalysisViewBudgetEntriesPage()
    var
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        AnalysisViewBudgetEntries: TestPage "Analysis View Budget Entries";
    begin
        // [FEATURE] [Analysis View] [Budget]
        // [SCENARIO 264348] Analisys View Budget Entry has default page
        AnalysisViewBudgetEntry.Init();
        AnalysisViewBudgetEntry."Budget Name" := LibraryUtility.GenerateGUID();
        AnalysisViewBudgetEntry."G/L Account No." := LibraryUtility.GenerateGUID();
        AnalysisViewBudgetEntry.Insert();
        AnalysisViewBudgetEntry.SetRecFilter();
        AnalysisViewBudgetEntries.Trap();
        PAGE.Run(0, AnalysisViewBudgetEntry);
        AnalysisViewBudgetEntries."G/L Account No.".AssertEquals(AnalysisViewBudgetEntry."G/L Account No.");
    end;

    [Test]
    [HandlerFunctions('CreateTaskMultipleReassigningTypeModalPageHandler')]
    [Scope('OnPrem')]
    procedure OneTaskCreatedAfterMultipleTypeValidationOnCreateTask()
    var
        TempTask: Record "To-do" temporary;
        Task: Record "To-do";
        Contact: Record Contact;
        Customer: Record Customer;
    begin
        // [FEATURE] [To-do]
        // [SCENARIO 268931] If Type is changed multiple times on the "Create Task" Page then still one Task is created.

        // [GIVEN] Create Contact.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [WHEN] Create Task for Contact and change Type multiple times (CreateTaskMultipleReassigningTypeModalPageHandler).
        Task.SetFilter("Contact No.", Contact."No.");
        TempTask.CreateTaskFromTask(Task);

        // [THEN] One Task was created for Contact.
        Task.Reset();
        Task.SetRange("Contact No.", Contact."No.");
        Assert.AreEqual(1, Task.Count, TaskNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalFieldsVisibility()
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenView();
        Assert.IsTrue(PaymentJournal."Posting Date".Visible(), PaymentJournal."Posting Date".Caption);
        Assert.IsTrue(PaymentJournal."Document Type".Visible(), PaymentJournal."Document Type".Caption);
        Assert.IsTrue(PaymentJournal."Document No.".Visible(), PaymentJournal."Document No.".Caption);
        PaymentJournal.Close();
    end;

    [Scope('OnPrem')]
    procedure SalesOrderFieldDirectDebitMandateVisible()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 269728] Sales Order has visible fields: "Direct Debit Mandate ID" if Application Area is set to Suite
        LibraryApplicationArea.EnableFoundationSetup();
        SalesOrder.OpenNew();
        Assert.IsTrue(SalesOrder."Direct Debit Mandate ID".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceFieldDirectDebitMandateVisible()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 269728] Sales Invoice has visible fields: "Direct Debit Mandate ID" if Application Area is set to Suite
        LibraryApplicationArea.EnableFoundationSetup();
        SalesInvoice.OpenNew();
        Assert.IsTrue(SalesInvoice."Direct Debit Mandate ID".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceFieldDirectDebitMandateVisible()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 269728] Posted Sales Order has visible fields: "Direct Debit Mandate ID" if Application Area is set to Suite
        LibraryApplicationArea.EnableFoundationSetup();
        PostedSalesInvoice.OpenView();
        Assert.IsTrue(PostedSalesInvoice."Direct Debit Mandate ID".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigWizardConfigPackageAssidtEditRtc()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ConfigWizard: TestPage "Config. Wizard";
    begin
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Windows);
        BindSubscription(TestClientTypeSubscriber);

        ConfigWizard.OpenEdit();
        Assert.IsTrue(ConfigWizard.PackageFileNameRtc.Visible(), StrSubstNo(PageFieldVisibleErr, 'PackageFileNameRtc'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfigWizardConfigPackageAssidtEditWeb()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        ConfigWizard: TestPage "Config. Wizard";
    begin
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(TestClientTypeSubscriber);

        ConfigWizard.OpenEdit();
        Assert.IsTrue(ConfigWizard.PackageFileNameRtc.Visible(), StrSubstNo(PageFieldVisibleErr, 'PackageFileNameRtc'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasingCodesVisibleForSuite()
    var
        PurchasingCodes: TestPage "Purchasing Codes";
    begin
        // [FEATURE] [Purchase] [Purchasing Codes]
        // [SCENARIO 271183] Columns of the Purchasing Codes page are visible for #Suite plan.

        LibraryApplicationArea.EnableFoundationSetup();
        PurchasingCodes.OpenView();

        Assert.IsTrue(
          PurchasingCodes.Code.Visible(),
          StrSubstNo(PageFieldVisibleErr, PurchasingCodes.Code.Caption));
        Assert.IsTrue(
          PurchasingCodes.Description.Visible(),
          StrSubstNo(PageFieldVisibleErr, PurchasingCodes.Description.Caption));
        Assert.IsTrue(
          PurchasingCodes."Drop Shipment".Visible(),
          StrSubstNo(PageFieldVisibleErr, PurchasingCodes."Drop Shipment".Caption));
        Assert.IsTrue(
          PurchasingCodes."Special Order".Visible(),
          StrSubstNo(PageFieldVisibleErr, PurchasingCodes."Special Order".Caption));

        PurchasingCodes.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasingCodesListVisibleForSuite()
    var
        PurchasingCodeList: TestPage "Purchasing Code List";
    begin
        // [FEATURE] [Purchase] [Purchasing Codes]
        // [SCENARIO 271183] Columns of the Purchasing Codes page are visible for #Suite plan.

        LibraryApplicationArea.EnableFoundationSetup();
        PurchasingCodeList.OpenView();

        Assert.IsTrue(
          PurchasingCodeList.Code.Visible(),
          StrSubstNo(PageFieldVisibleErr, PurchasingCodeList.Code.Caption));
        Assert.IsTrue(
          PurchasingCodeList.Description.Visible(),
          StrSubstNo(PageFieldVisibleErr, PurchasingCodeList.Description.Caption));
        Assert.IsTrue(
          PurchasingCodeList."Drop Shipment".Visible(),
          StrSubstNo(PageFieldVisibleErr, PurchasingCodeList."Drop Shipment".Caption));
        Assert.IsTrue(
          PurchasingCodeList."Special Order".Visible(),
          StrSubstNo(PageFieldVisibleErr, PurchasingCodeList."Special Order".Caption));

        PurchasingCodeList.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowAvialabilityLinesManualRevenuesCaption()
    var
        CashFlowAvailabilityLines: TestPage "Cash Flow Availability Lines";
    begin
        // [FEATURE] [Cash Flow]
        // [SCENARIO 272786] The column ManualRevenues of page "Cash Flow Avialability Lines" has a caption 'Cash Flow Manual Revenues'
        CashFlowAvailabilityLines.OpenView();
        Assert.AreEqual('Cash Flow Manual Revenues', CashFlowAvailabilityLines.ManualRevenues.Caption, 'Wrong caption');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrder_ProformaInvoiceAction()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales] [Order] [Pro Forma]
        // [SCENARIO 271413] Pro Forma Invoice action must be available on Sales Order card page
        LibraryApplicationArea.EnableBasicSetup();

        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        Assert.IsTrue(SalesOrder.ProformaInvoice.Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_ProformaInvoiceAction()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [Pro Forma]
        // [SCENARIO 271413] Pro Forma Invoice action must be available on Sales Invoice card page
        LibraryApplicationArea.EnableBasicSetup();

        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        Assert.IsTrue(SalesInvoice.ProformaInvoice.Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemCardQtyJobOrder()
    var
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Item] [Card] [UI]
        // [SCENARIO 280027] "Qty. on Job Order" is enabled and visible on "Item Card" page
        LibraryApplicationArea.EnableJobsSetup();

        ItemCard.OpenEdit();
        Assert.IsTrue(ItemCard."Qty. on Job Order".Enabled(), '');
        Assert.IsTrue(ItemCard."Qty. on Job Order".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ItemListMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchOrderSelectMultipleItems()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchOrderPage: TestPage "Purchase Order";
        ExpectedItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Order] [Select Multiple Items]
        // [SCENARIO] Action "Select items" on Order subpage adds selected items, if no lines exist
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Open Purchase Order '1000' with no lines
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchOrderPage.OpenEdit();
        PurchOrderPage.GotoRecord(PurchHeader);
        // [GIVEN] run action "Select items" on the subpage
        PurchOrderPage.PurchLines.SelectMultiItems.Invoke();

        // [WHEN] Select the Item 'X' and push "OK"
        ExpectedItemNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20); // from ItemListMPH

        // [THEN] One purchase line added, where "Document No." = '1000', "Type" = 'Item', "No." = 'X'
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        Assert.RecordCount(PurchLine, 1);
        PurchLine.FindFirst();
        PurchLine.TestField(Type, PurchLine.Type::Item);
        PurchLine.TestField("No.", ExpectedItemNo);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ItemListCancelMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchInvoiceSelectMultipleItems()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvoicePage: TestPage "Purchase Invoice";
        ExpectedItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Select Multiple Items]
        // [SCENARIO] Action "Select items" on Invoice subpage adds selected items, if the current line is the last one
        LibraryApplicationArea.EnableBasicSetup();
        // [GIVEN] Open Purchase Invoice '1000' with one line
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);
        PurchInvoicePage.OpenEdit();
        PurchInvoicePage.GotoRecord(PurchHeader);
        // [GIVEN] run action "Select items" on the subpage
        PurchInvoicePage.PurchLines.SelectMultiItems.Invoke();

        // [WHEN] Select the Item 'X' and push "Cancel"
        ExpectedItemNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20); // from ItemListCancelMPH

        // [THEN] Second purchase line is not added
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        Assert.RecordCount(PurchLine, 1);
        PurchLine.FindLast();
        PurchLine.TestField(Type, PurchLine.Type::Item);
        Assert.AreNotEqual(ExpectedItemNo, PurchLine."No.", 'selected item should not be inserted');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ItemListMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchQuoteSelectMultipleItems()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchQuotePage: TestPage "Purchase Quote";
        ExpectedItemNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Quote] [Select Multiple Items]
        // [SCENARIO] Action "Select items" on Quote subpage adds selected items, if the current line is the first of many
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Created Purchase Quote '1000' with two lines
        LibraryPurchase.CreatePurchaseQuote(PurchHeader);
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindLast();
        PurchLine."Line No." += 10000;
        PurchLine.Insert(true);
        Assert.RecordCount(PurchLine, 2);

        // [GIVEN] Open Purchase Quote on the first line
        PurchQuotePage.OpenEdit();
        PurchQuotePage.GotoRecord(PurchHeader);
        // [GIVEN] run action "Select items" on the subpage
        PurchQuotePage.PurchLines.SelectMultiItems.Invoke();

        // [WHEN] Select the Item 'X' and push "OK"
        ExpectedItemNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20); // from ItemListMPH

        // [THEN] Third purchase line added as the last one, where "Document No." = '1000', "Type" = 'Item', "No." = 'X'
        Assert.RecordCount(PurchLine, 3);
        PurchLine.FindLast();
        PurchLine.TestField(Type, PurchLine.Type::Item);
        PurchLine.TestField("No.", ExpectedItemNo);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ItemListMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesOrderSelectMultipleItems()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderPage: TestPage "Sales Order";
        ExpectedItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Order] [Select Multiple Items]
        // [SCENARIO] Action "Select items" on Order subpage adds selected items, if no lines exist
        LibraryApplicationArea.EnableBasicSetup();
        // [GIVEN] Open Sales Order '1000' with no lines
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesOrderPage.OpenEdit();
        SalesOrderPage.GotoRecord(SalesHeader);
        // [GIVEN] run action "Select items" on the subpage
        SalesOrderPage.SalesLines.SelectMultiItems.Invoke();

        // [WHEN] Select the Item 'X' and push "OK"
        ExpectedItemNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20); // from ItemListMPH

        // [THEN] One sales line added, where "Document No." = '1000', "Type" = 'Item', "No." = 'X'
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.RecordCount(SalesLine, 1);
        SalesLine.FindFirst();
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", ExpectedItemNo);
    end;

    [Test]
    [HandlerFunctions('ItemListCancelMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesInvoiceSelectMultipleItems()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoicePage: TestPage "Sales Invoice";
        ExpectedItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Select Multiple Items]
        // [SCENARIO] Action "Select items" on Invoice subpage adds selected items, if the current line is the last one
        LibraryApplicationArea.EnableBasicSetup();
        // [GIVEN] Open Sales Invoice '1000' with one line
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.GotoRecord(SalesHeader);
        // [GIVEN] run action "Select items" on the subpage
        SalesInvoicePage.SalesLines.SelectMultiItems.Invoke();

        // [WHEN] Select the Item 'X' and push "Cancel"
        ExpectedItemNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20); // from ItemListCancelMPH

        // [THEN] Second sales line is not added
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.RecordCount(SalesLine, 1);
        SalesLine.FindLast();
        SalesLine.TestField(Type, SalesLine.Type::Item);
        Assert.AreNotEqual(ExpectedItemNo, SalesLine."No.", 'selected item should not be inserted');
    end;

    [Test]
    [HandlerFunctions('ItemListMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesQuoteSelectMultipleItems()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuotePage: TestPage "Sales Quote";
        ExpectedItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Quote] [Select Multiple Items]
        // [SCENARIO] Action "Select items" on Quote subpage adds selected items, if the current line is the first of many
        LibraryApplicationArea.EnableBasicSetup();
        // [GIVEN] Created Sales Quote '1000' with two lines
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();
        SalesLine."Line No." += 10000;
        SalesLine.Insert(true);
        Assert.RecordCount(SalesLine, 2);

        // [GIVEN] Open Sales Quote on the first line
        SalesQuotePage.OpenEdit();
        SalesQuotePage.GotoRecord(SalesHeader);
        // [GIVEN] run action "Select items" on the subpage
        SalesQuotePage.SalesLines.SelectMultiItems.Invoke();

        // [WHEN] Select the Item 'X' and push "OK"
        ExpectedItemNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20); // from ItemListMPH

        // [THEN] Third sales line added as the last one, where "Document No." = '1000', "Type" = 'Item', "No." = 'X'
        Assert.RecordCount(SalesLine, 3);
        SalesLine.FindLast();
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", ExpectedItemNo);
    end;

    [Test]
    [HandlerFunctions('ItemListLookForItemMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SelectItemsSkipsBlockedItems()
    var
        BlockedItem: Record Item;
        ItemList: Page "Item List";
    begin
        // [FEATURE] [Select Multiple Items] [Blocked]
        // [GIVEN] Item 'X' is blocked
        LibraryInventory.CreateItem(BlockedItem);
        BlockedItem.Validate(Blocked, true);
        BlockedItem.Modify(true);

        // [WHEN] run SelectActiveItems on "Item List" page
        LibraryVariableStorage.Enqueue(BlockedItem."No."); // for ItemListLookForItemMPH
        ItemList.SelectActiveItems();

        // [THEN] Item 'X' is not in the list
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Blocked Item should not be visible');
    end;

    [Test]
    [HandlerFunctions('ItemListLookForItemMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SelectItemsSkipsBlockedItemsForSalesInvoice()
    var
        BlockedItem: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Select Multiple Items] [Sales] [Blocked] [Invoice]
        // [GIVEN] Item 'X' is blocked for sales
        LibraryInventory.CreateItem(BlockedItem);
        BlockedItem.Validate("Sales Blocked", true);
        BlockedItem.Modify(true);

        // [WHEN] run SelectMultipleItems on for Invoice line
        LibraryVariableStorage.Enqueue(BlockedItem."No."); // for ItemListLookForItemMPH
        SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
        SalesLine.SelectMultipleItems();

        // [THEN] Item 'X' is not in the list
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Blocked Item should not be visible');
    end;

    [Test]
    [HandlerFunctions('ItemListLookForItemMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SelectItemsSkipsBlockedItemsForSalesCrMemo()
    var
        BlockedItem: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Select Multiple Items] [Sales] [Blocked] [Credit Memo]
        // [GIVEN] Item 'X' is blocked for sales
        LibraryInventory.CreateItem(BlockedItem);
        BlockedItem.Validate("Sales Blocked", true);
        BlockedItem.Modify(true);

        // [WHEN] run SelectMultipleItems on for Credit Memo line
        LibraryVariableStorage.Enqueue(BlockedItem."No."); // for ItemListLookForItemMPH
        SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
        SalesLine.SelectMultipleItems();

        // [THEN] Item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Blocked Item should be visible');
    end;

    [Test]
    [HandlerFunctions('ItemListLookForItemMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SelectItemsSkipsBlockedItemsForSalesRetOrder()
    var
        BlockedItem: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Select Multiple Items] [Sales] [Blocked] [Return Order]
        // [GIVEN] Item 'X' is blocked for sales
        LibraryInventory.CreateItem(BlockedItem);
        BlockedItem.Validate("Sales Blocked", true);
        BlockedItem.Modify(true);

        // [WHEN] run SelectMultipleItems on for Return Order line
        LibraryVariableStorage.Enqueue(BlockedItem."No."); // for ItemListLookForItemMPH
        SalesLine."Document Type" := SalesLine."Document Type"::"Return Order";
        SalesLine.SelectMultipleItems();

        // [THEN] Item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Blocked Item should be visible');
    end;

    [Test]
    [HandlerFunctions('ItemListLookForItemMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SelectItemsSkipsBlockedItemsForPurchInvoice()
    var
        BlockedItem: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Select Multiple Items] [Purchase] [Blocked] [Invoice]
        // [GIVEN] Item 'X' is blocked for purchase
        LibraryInventory.CreateItem(BlockedItem);
        BlockedItem.Validate("Purchasing Blocked", true);
        BlockedItem.Modify(true);

        // [WHEN] run SelectMultipleItems on for Invoice line
        LibraryVariableStorage.Enqueue(BlockedItem."No."); // for ItemListLookForItemMPH
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Invoice;
        PurchaseLine.SelectMultipleItems();

        // [THEN] Item 'X' is not in the list
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Blocked Item should not be visible');
    end;

    [Test]
    [HandlerFunctions('ItemListLookForItemMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SelectItemsSkipsBlockedItemsForPurchCrMemo()
    var
        BlockedItem: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Select Multiple Items] [Purchase] [Blocked] [Credit Memo]
        // [GIVEN] Item 'X' is blocked for purchase
        LibraryInventory.CreateItem(BlockedItem);
        BlockedItem.Validate("Purchasing Blocked", true);
        BlockedItem.Modify(true);

        // [WHEN] run SelectMultipleItems on for Credit Memo line
        LibraryVariableStorage.Enqueue(BlockedItem."No."); // for ItemListLookForItemMPH
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::"Credit Memo";
        PurchaseLine.SelectMultipleItems();

        // [THEN] Item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Blocked Item should be visible');
    end;

    [Test]
    [HandlerFunctions('ItemListLookForItemMPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SelectItemsSkipsBlockedItemsForPurchRetOrder()
    var
        BlockedItem: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Select Multiple Items] [Purchase] [Blocked] [Return Order]
        // [GIVEN] Item 'X' is blocked for purchase
        LibraryInventory.CreateItem(BlockedItem);
        BlockedItem.Validate("Purchasing Blocked", true);
        BlockedItem.Modify(true);

        // [WHEN] run SelectMultipleItems on for Return Order line
        LibraryVariableStorage.Enqueue(BlockedItem."No."); // for ItemListLookForItemMPH
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::"Return Order";
        PurchaseLine.SelectMultipleItems();

        // [THEN] Item 'X' is in the list
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Blocked Item should be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteExternalDocumentNo()
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 283922] "External Document No" is enabled and visible on "Sales Quote" page
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN]
        // [WHEN] "Sales Quote" test page is opened
        SalesQuote.OpenEdit();

        // [THEN] "External Document No." field is enabled and visible
        Assert.IsTrue(SalesQuote."External Document No.".Enabled(), '');
        Assert.IsTrue(SalesQuote."External Document No.".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuote_ActionSendIsVisible()
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UT] [Purchase] [Quote]
        // [SCENARIO 274511] "Send" action is visible on the "Purchase Quote" page.

        PurchaseQuote.OpenNew();
        Assert.IsTrue(PurchaseQuote.Send.Visible(), 'Button "Send" must be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuotes_ActionSendIsVisible()
    var
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        // [FEATURE] [UT] [Purchase] [Quote]
        // [SCENARIO 274511] "Send" action is visible on the "Purchase Quotes" page.

        PurchaseQuotes.OpenNew();
        Assert.IsTrue(PurchaseQuotes.Send.Visible(), 'Button "Send" must be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPostingInventoryAccountInterimOnValidate()
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        GLAccount: Record "G/L Account";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        InventoryPostingSetupPage: TestPage "Inventory Posting Setup";
    begin
        // [FEATURE] [Inventory]
        // [SCENARIO 286866] OnValidate trigger for "Inventory Account (Interim)" sets value for "Inventory Account (Interim)".

        // [GIVEN] Inventory Posting Setup
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        InventoryPostingSetup.Init();
        InventoryPostingSetup.Validate("Invt. Posting Group Code", InventoryPostingGroup.Code);
        InventoryPostingSetup.Insert(true);

        // [WHEN] "Inventory Account (Interim)" Validated
        CreateGLAccountInventoryPostingSetup(GLAccount);
        InventoryPostingSetupPage.OpenEdit();
        InventoryPostingSetupPage.FILTER.SetFilter("Invt. Posting Group Code", InventoryPostingGroup.Code);
        InventoryPostingSetupPage."Inventory Account (Interim)".SetValue(GLAccount."No.");
        InventoryPostingSetupPage.Close();

        // [THEN] Correct field is filled out in the record
        VerifyInventoryPostingSetupInserted(GLAccount."No.");
    end;

    [Test]
    [HandlerFunctions('GLAccountListLookupPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPostingInventoryAccountInterimOnLookup()
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        GLAccount: Record "G/L Account";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        InventoryPostingSetupPage: TestPage "Inventory Posting Setup";
    begin
        // [FEATURE] [Inventory]
        // [SCENARIO 286866] OnLookup trigger for "Inventory Account (Interim)" sets value for "Inventory Account (Interim)".

        // [GIVEN] Inventory Posting Setup
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        InventoryPostingSetup.Init();
        InventoryPostingSetup.Validate("Invt. Posting Group Code", InventoryPostingGroup.Code);
        InventoryPostingSetup.Insert(true);

        // [WHEN] "Inventory Account (Interim)" Validated
        CreateGLAccountInventoryPostingSetup(GLAccount);
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        InventoryPostingSetupPage.OpenEdit();
        InventoryPostingSetupPage.FILTER.SetFilter("Invt. Posting Group Code", InventoryPostingGroup.Code);
        InventoryPostingSetupPage."Inventory Account (Interim)".Lookup();
        InventoryPostingSetupPage.Close();

        // [THEN] Correct field is filled out in the record
        VerifyInventoryPostingSetupInserted(GLAccount."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostCodeFilterPageHandler')]
    [Scope('OnPrem')]
    procedure LookupPostCodeEmptyCountryRegion()
    var
        PostCode: Record "Post Code";
    begin
        // [FEATURE] [Address]
        // [SCENARIO 289060] Lookup for Post Code table opens records without filters in case of empty CountryCode parameter

        // [GIVEN] Create Post Code record with Post Code = "P", City = "CITY", County = "COUNTY", Country/Region = "COUNTRY"
        CreatePostCode(PostCode);

        // [WHEN] Function PostCode.LookupPostCode is being run with CountryCode parameter = ""
        PostCode."Country/Region Code" := '';
        PostCode.LookupPostCode(PostCode.City, PostCode.Code, PostCode.County, PostCode."Country/Region Code");

        // [THEN] Page Post Codes has filter for Country/Region Code = "COUNTRY"
        Assert.AreEqual('', LibraryVariableStorage.DequeueText(), 'Invalid Country/Region Code filter');
    end;

    [Test]
    [HandlerFunctions('PostCodeFilterPageHandler')]
    [Scope('OnPrem')]
    procedure LookupPostCodeWithCountryRegion()
    var
        PostCode: Record "Post Code";
    begin
        // [FEATURE] [Address]
        // [SCENARIO 289060] Lookup for Post Code table opens records with filter by Country/Region Code = CountryCode parameter

        // [GIVEN] Create Post Code record with Post Code = "P", City = "CITY", County = "COUNTY", Country/Region = "COUNTRY"
        CreatePostCode(PostCode);

        // [WHEN] Function PostCode.LookupPostCode is being run with CountryCode parameter = "COUNTRY"
        PostCode.LookupPostCode(PostCode.City, PostCode.Code, PostCode.County, PostCode."Country/Region Code");

        // [THEN] Page Post Codes has filter for Country/Region Code = "COUNTRY"
        Assert.AreEqual(PostCode."Country/Region Code", LibraryVariableStorage.DequeueText(), 'Invalid Country/Region Code filter');
    end;

    [Test]
    [HandlerFunctions('PostCodeLookupOkPageHandler')]
    [Scope('OnPrem')]
    procedure LookupPostCodeOk()
    var
        PostCode: array[2] of Record "Post Code";
    begin
        // [FEATURE] [Address]
        // [SCENARIO 289060] Function PostCode.LookupPostCode set parameters by values selected in lookup page

        // [GIVEN] Create Post Code record with Post Code = "P", City = "CITY", County = "COUNTY", Country/Region = "COUNTRY"
        CreatePostCode(PostCode[1]);

        // [WHEN] Function PostCode.LookupPostCode is being run and selected record was Post Code = "P", City = "CITY"
        LibraryVariableStorage.Enqueue(PostCode[1].City);
        LibraryVariableStorage.Enqueue(PostCode[1].Code);
        PostCode[1].LookupPostCode(PostCode[2].City, PostCode[2].Code, PostCode[2].County, PostCode[2]."Country/Region Code");

        // [THEN] Function parameters equal to Post Code = "P2", City = "CITY2", County = "COUNTY2", Country/Region = "COUNTRY2"
        PostCode[2].TestField(Code, PostCode[1].Code);
        PostCode[2].TestField(City, PostCode[1].City);
        PostCode[2].TestField("Country/Region Code", PostCode[1]."Country/Region Code");
        PostCode[2].TestField(County, PostCode[1].County);
    end;

    [Test]
    [HandlerFunctions('PostCodeLookupCancelPageHandler')]
    [Scope('OnPrem')]
    procedure LookupPostCodeCancel()
    var
        PostCode: Record "Post Code";
        City: Text[30];
        "Code": Code[20];
        County: Text[30];
        CountryCode: Code[10];
        SavedCity: Text[30];
        SavedCode: Code[20];
        SavedCounty: Text[30];
        SavedCountryCode: Code[10];
    begin
        // [FEATURE] [Address]
        // [SCENARIO 289060] Function PostCode.LookupPostCode does not change parameters if lookup was canceled

        // [GIVEN] PostCode = "P", City = "CITY", County = "COUNTY", CountryCode = "COUNTRY"
        CreatePostCodeFields(City, Code, County, CountryCode);
        SavedCity := City;
        SavedCode := Code;
        SavedCountryCode := CountryCode;
        SavedCounty := County;

        // [WHEN] Function PostCode.LookupPostCode is being run and selection canceled
        PostCode.LookupPostCode(City, Code, County, CountryCode);

        // [THEN] Function parameters are not changed
        Assert.AreEqual(SavedCode, Code, 'Invalid PostCode parameter value');
        Assert.AreEqual(SavedCity, City, 'Invalid City parameter value');
        Assert.AreEqual(SavedCounty, County, 'Invalid County parameter value');
        Assert.AreEqual(SavedCountryCode, CountryCode, 'Invalid CountryCode parameter value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckClearPostCodeCityCounty()
    var
        PostCode: Record "Post Code";
        City: Text[30];
        "Code": Code[20];
        County: Text[30];
        CountryCode: Code[10];
        xCountryCode: Code[10];
    begin
        // [FEATURE] [Address]
        // [SCENARIO 289060] Function PostCode.CheckClearPostCodeCityCounty clears Post Code, City and County when country code changed

        // [GIVEN] PostCode = "P", City = "CITY", County = "COUNTY", CountryCode = "COUNTRY"
        CreatePostCodeFields(City, Code, County, CountryCode);

        // [GIVEN] xCountyCode = "COUNTRY2"
        xCountryCode := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(xCountryCode));

        // [WHEN] Funcion PostCode.CheckClearPostCodeCityCounty is being run with xCountryCode <> CountryCode
        PostCode.CheckClearPostCodeCityCounty(City, Code, County, CountryCode, xCountryCode);

        // [THEN] City, Post Code, County parameters cleared
        Assert.AreEqual('', Code, 'Invalid PostCode parameter value');
        Assert.AreEqual('', City, 'Invalid City parameter value');
        Assert.AreEqual('', County, 'Invalid County parameter value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckClearPostCodeCityCountyEmptyXCountryCode()
    var
        PostCode: Record "Post Code";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Address]
        // [SCENARIO 302399] Function PostCode.CheckClearPostCodeCityCounty does not clear Post Code, City and County when country code changed if xCountryCode = ''

        // [GIVEN] PostCode = "P", City = "CITY", County = "COUNTY", CountryCode = "COUNTRY"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Customer with PostCode = "P", City = "CITY", County = "COUNTY", CountryCode = ""
        LibrarySales.CreateCustomer(Customer);
        Customer."Post Code" := PostCode.Code;
        Customer.City := PostCode.City;
        Customer.County := PostCode.County;
        Customer.Modify();

        // [GIVEN] Customer card page with created customer
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");

        // [WHEN] Funcion PostCode.CheckClearPostCodeCityCounty is being run with xCountryCode = ''
        CustomerCard."Country/Region Code".SetValue(PostCode."Country/Region Code");

        // [THEN] City, Post Code, County parameters have not been changed
        CustomerCard."Post Code".AssertEquals(Customer."Post Code");
        CustomerCard.City.AssertEquals(Customer.City);
        CustomerCard.County.AssertEquals(Customer.County);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequireCountryRegionCodeInAddress()
    var
        PostCode: Record "Post Code";
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        GLSetup: Record "General Ledger Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Address]
        // [SCENARIO 316984] Function PostCode.CheckClearPostCodeCityCounty does not clear Post Code, City and County when GLSetup."Require Country/Region Code in Address" = true
        Initialize();

        // [GIVEN] PostCode = "P", City = "CITY", County = "COUNTY", CountryCode = "COUNTRY"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Customer with PostCode = "P", City = "CITY", County = "COUNTY", CountryCode = "CC1"
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySales.CreateCustomer(Customer);
        Customer."Post Code" := PostCode.Code;
        Customer.City := PostCode.City;
        Customer.County := PostCode.County;
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer.Modify();

        // [GIVEN] GLSetup."Require Country/Region Code in Address" = true
        GLSetup.Get();
        GLSetup."Req.Country/Reg. Code in Addr." := true;
        GLSetup.Modify();

        // [GIVEN] Customer card page with created customer
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");

        // [WHEN] "Country/Region Code" is being changed to "CC2"
        CustomerCard."Country/Region Code".SetValue(PostCode."Country/Region Code");

        // [THEN] City, Post Code, County parameters have not been changed
        CustomerCard."Post Code".AssertEquals(Customer."Post Code");
        CustomerCard.City.AssertEquals(Customer.City);
        CustomerCard.County.AssertEquals(Customer.County);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnSalesQuote()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Sales Quote" page

        SalesQuote.OpenEdit();
        Assert.IsTrue(SalesQuote."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", SalesQuote."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnPurchaseQuote()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [Sales Purchase]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Sales Purchase" page

        PurchaseQuote.OpenEdit();
        Assert.IsTrue(PurchaseQuote."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", PurchaseQuote."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnSalesInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Sales Invoice" page

        SalesInvoice.OpenEdit();
        Assert.IsTrue(SalesInvoice."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", SalesInvoice."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnPurchaseInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase Invoice]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Purchase Invoice" page

        PurchaseInvoice.OpenEdit();
        Assert.IsTrue(PurchaseInvoice."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", PurchaseInvoice."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnSalesOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales Order]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Sales Order" page

        SalesOrder.OpenEdit();
        Assert.IsTrue(SalesOrder."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", SalesOrder."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnPurchaseOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase Order]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Purchase Order" page

        PurchaseOrder.OpenEdit();
        Assert.IsTrue(PurchaseOrder."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", PurchaseOrder."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnSalesCreditMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Sales Credit Memo" page

        SalesCreditMemo.OpenEdit();
        Assert.IsTrue(SalesCreditMemo."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", SalesCreditMemo."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnPurchCreditMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase Credit Memo]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Purchase Credit Memo" page

        PurchaseCreditMemo.OpenEdit();
        Assert.IsTrue(PurchaseCreditMemo."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", PurchaseCreditMemo."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnSalesReturnOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Sales Return Order" page

        SalesReturnOrder.OpenEdit();
        Assert.IsTrue(SalesReturnOrder."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", SalesReturnOrder."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnPurchReturnOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Purchase Return Order]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Purchase Return Order" page

        PurchaseReturnOrder.OpenEdit();
        Assert.IsTrue(PurchaseReturnOrder."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", PurchaseReturnOrder."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnBlanketSalesOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [Blanket Sales Order]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Blanket Sales Order" page

        BlanketSalesOrder.OpenEdit();
        Assert.IsTrue(BlanketSalesOrder."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", BlanketSalesOrder."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnBlanketPurchaseOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [Blanket Purchase Order]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Blanket Purchase Order" page

        BlanketPurchaseOrder.OpenEdit();
        Assert.IsTrue(BlanketPurchaseOrder."Payment Method Code".Enabled(), '');
        Assert.AreEqual(not GeneralLedgerSetup."Hide Payment Method Code", BlanketPurchaseOrder."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeOnServiceCreditMemo()
    var
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [FEATURE] [Service Credit Memo]
        // [SCENARIO 288448] "Payment Method Code" is enabled and visible on "Service Credit Memo" page

        ServiceCreditMemo.OpenEdit();
        Assert.IsTrue(ServiceCreditMemo."Payment Method Code".Enabled(), '');
        Assert.IsTrue(ServiceCreditMemo."Payment Method Code".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserListLicenseTypeSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Users: TestPage Users;
    begin
        // [FEATURE] [Users]
        // [SCENARIO 294901] License Type field is not be visible in SaaS

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        Users.OpenEdit();
        Assert.IsFalse(Users."License Type".Visible(), '');

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManufacturersPageIsAvilableWithBasicSetup()
    var
        Manufacturers: TestPage Manufacturers;
    begin
        // [FEATURE] [Manufacturers]
        // [SCENARIO 298939] Page 'Manufacturers' is visible with Basic setup
        LibraryApplicationArea.EnableBasicSetup();
        Manufacturers.OpenEdit();
        Assert.IsTrue(Manufacturers.Code.Visible(), '');
        Assert.IsTrue(Manufacturers.Name.Visible(), '');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManufacturersPageIsAvilableWithSuiteSetup()
    var
        Manufacturers: TestPage Manufacturers;
    begin
        // [FEATURE] [Manufacturers]
        // [SCENARIO 298939] Page 'Manufacturers' is visible with Suite setup
        LibraryApplicationArea.EnableFoundationSetup();
        Manufacturers.OpenEdit();
        Assert.IsTrue(Manufacturers.Code.Visible(), '');
        Assert.IsTrue(Manufacturers.Name.Visible(), '');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIListCustomerAction()
    var
        SalesHeaderWithCustomer: Record "Sales Header";
        SalesHeaderWithoutCustomer: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] SalesInvoiceList.Customer.ENABLED = FALSE when Customer is not set
        // [SCENARIO] SalesInvoiceList.Customer.ENABLED = TRUE when Customer is set

        LibraryApplicationArea.EnableBasicSetup();
        // [GIVEN] One Sales Invoice with Customer and one without
        LibrarySales.CreateSalesHeader(
          SalesHeaderWithCustomer, SalesHeaderWithCustomer."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        Clear(SalesHeaderWithoutCustomer);
        SalesHeaderWithoutCustomer.Validate("Document Type", SalesHeaderWithoutCustomer."Document Type"::Invoice);
        SalesHeaderWithoutCustomer.Insert(true);

        SalesInvoiceList.OpenEdit();
        // [WHEN] Sales Invoice with Customer is selected
        SalesInvoiceList.GotoRecord(SalesHeaderWithCustomer);

        // [THEN] Verify that the Customer action is enabled
        Assert.IsTrue(SalesInvoiceList.CustomerAction.Enabled(), 'Customer action is not enabled');

        // [WHEN] Sales Invoice with Customer is selected
        SalesInvoiceList.GotoRecord(SalesHeaderWithoutCustomer);

        // [THEN] Verify that the Customer action is enabled
        Assert.IsFalse(SalesInvoiceList.CustomerAction.Enabled(), 'Customer action is enabled');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomAddressBillToOptionOnSalesQuotePage()
    var
        SalesQuoteHeader: Record "Sales Header";
        SalesQuotePage: TestPage "Sales Quote";
        BillToOptions: Option "Default (Customer)","Another Customer","Custom Address";
    begin
        // [FEATURE] [Sales] [Quote]
        // [SCENARIO 301084] Bill-to/Pay-to address fields cannot be edited

        // [GIVEN] Created document, opened it's page
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesQuoteHeader, LibrarySales.CreateCustomerNo());
        SalesQuotePage.OpenEdit();
        SalesQuotePage.FILTER.SetFilter("No.", SalesQuoteHeader."No.");

        // [WHEN] Choose "Custom Address" Bill-to option
        SalesQuotePage.BillToOptions.SetValue(BillToOptions::"Custom Address");

        // [THEN] Bill-to address fields are editable, and "Bill-to Name" field is not
        Assert.IsFalse(SalesQuotePage."Bill-to Name".Editable(), '');
        Assert.IsTrue(SalesQuotePage."Bill-to Address".Editable() and
          SalesQuotePage."Bill-to Address 2".Editable() and
          SalesQuotePage."Bill-to City".Editable() and
          SalesQuotePage."Bill-to County".Editable() and
          SalesQuotePage."Bill-to Post Code".Editable() and
          SalesQuotePage."Bill-to Contact No.".Editable() and
          SalesQuotePage."Bill-to Contact".Editable() and
          SalesQuotePage."Bill-to Contact".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomAddressBillToOptionOnSalesOrderPage()
    var
        SalesOrderHeader: Record "Sales Header";
        SalesOrderPage: TestPage "Sales Order";
        BillToOptions: Option "Default (Customer)","Another Customer","Custom Address";
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 301084] Bill-to/Pay-to address fields cannot be edited

        // [GIVEN] Created document, opened it's page
        LibrarySales.CreateSalesOrder(SalesOrderHeader);
        SalesOrderPage.OpenEdit();
        SalesOrderPage.FILTER.SetFilter("No.", SalesOrderHeader."No.");

        // [WHEN] Choose "Custom Address" Bill-to option
        SalesOrderPage.BillToOptions.SetValue(BillToOptions::"Custom Address");

        // [THEN] Bill-to address fields are editable, and "Bill-to Name" field is not
        Assert.IsFalse(SalesOrderPage."Bill-to Name".Editable(), '');
        Assert.IsTrue(SalesOrderPage."Bill-to Address".Editable() and
          SalesOrderPage."Bill-to Address 2".Editable() and
          SalesOrderPage."Bill-to City".Editable() and
          SalesOrderPage."Bill-to County".Editable() and
          SalesOrderPage."Bill-to Post Code".Editable() and
          SalesOrderPage."Bill-to Contact No.".Editable() and
          SalesOrderPage."Bill-to Contact".Editable() and
          SalesOrderPage."Bill-to Contact".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomAddressBillToOptionOnSalesInvoicePage()
    var
        SalesInvoiceHeader: Record "Sales Header";
        SalesInvoicePage: TestPage "Sales Invoice";
        BillToOptions: Option "Default (Customer)","Another Customer","Custom Address";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 301084] Bill-to/Pay-to address fields cannot be edited

        // [GIVEN] Created document, opened it's page
        LibrarySales.CreateSalesInvoice(SalesInvoiceHeader);
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");

        // [WHEN] Choose "Custom Address" Bill-to option
        SalesInvoicePage.BillToOptions.SetValue(BillToOptions::"Custom Address");

        // [THEN] Bill-to address fields are editable, and "Bill-to Name" field is not
        Assert.IsFalse(SalesInvoicePage."Bill-to Name".Editable(), '');
        Assert.IsTrue(SalesInvoicePage."Bill-to Address".Editable() and
          SalesInvoicePage."Bill-to Address 2".Editable() and
          SalesInvoicePage."Bill-to City".Editable() and
          SalesInvoicePage."Bill-to County".Editable() and
          SalesInvoicePage."Bill-to Post Code".Editable() and
          SalesInvoicePage."Bill-to Contact No.".Editable() and
          SalesInvoicePage."Bill-to Contact".Editable() and
          SalesInvoicePage."Bill-to Contact".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomAddressBillToOptionOnSalesBlanketOrderPage()
    var
        BlanketSalesOrderHeader: Record "Sales Header";
        BlanketSalesOrderPage: TestPage "Blanket Sales Order";
        BillToOptions: Option "Default (Customer)","Another Customer","Custom Address";
    begin
        // [FEATURE] [Sales] [Blanket Order]
        // [SCENARIO 301084] Bill-to/Pay-to address fields cannot be edited

        // [GIVEN] Created document, opened it's page
        LibrarySales.CreateSalesHeader(
          BlanketSalesOrderHeader, BlanketSalesOrderHeader."Document Type"::"Blanket Order", LibrarySales.CreateCustomerNo());
        BlanketSalesOrderPage.OpenEdit();
        BlanketSalesOrderPage.FILTER.SetFilter("No.", BlanketSalesOrderHeader."No.");

        // [WHEN] Choose "Custom Address" Bill-to option
        BlanketSalesOrderPage.BillToOptions.SetValue(BillToOptions::"Custom Address");

        // [THEN] Bill-to address fields are editable, and "Bill-to Name" field is not
        Assert.IsFalse(BlanketSalesOrderPage."Bill-to Name".Editable(), '');
        Assert.IsTrue(BlanketSalesOrderPage."Bill-to Address".Editable() and
          BlanketSalesOrderPage."Bill-to Address 2".Editable() and
          BlanketSalesOrderPage."Bill-to City".Editable() and
          BlanketSalesOrderPage."Bill-to Post Code".Editable() and
          BlanketSalesOrderPage."Bill-to Contact No.".Editable() and
          BlanketSalesOrderPage."Bill-to Contact".Editable() and
          BlanketSalesOrderPage."Bill-to Contact".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomAddressPayToOptionOnPurchaseQuotePage()
    var
        PurchaseQuoteHeader: Record "Purchase Header";
        PurchaseQuotePage: TestPage "Purchase Quote";
        PayToOptions: Option "Default (Vendor)","Another Vendor","Custom Address";
    begin
        // [FEATURE] [Purchase] [Quote]
        // [SCENARIO 301084] Bill-to/Pay-to address fields cannot be edited

        // [GIVEN] Created document, opened it's page
        LibraryPurchase.CreatePurchaseQuote(PurchaseQuoteHeader);
        PurchaseQuotePage.OpenEdit();
        PurchaseQuotePage.FILTER.SetFilter("No.", PurchaseQuoteHeader."No.");

        // [WHEN] Choose "Custom Address" Pay-to option
        PurchaseQuotePage.PayToOptions.SetValue(PayToOptions::"Custom Address");

        // [THEN] Pay-to address fields are editable, and "Pay-to Name" field is not
        Assert.IsFalse(PurchaseQuotePage."Pay-to Name".Editable(), '');
        Assert.IsTrue(PurchaseQuotePage."Pay-to Address".Editable() and
          PurchaseQuotePage."Pay-to Address 2".Editable() and
          PurchaseQuotePage."Pay-to City".Editable() and
          PurchaseQuotePage."Pay-to County".Editable() and
          PurchaseQuotePage."Pay-to Post Code".Editable() and
          PurchaseQuotePage."Pay-to Contact No.".Editable() and
          PurchaseQuotePage."Pay-to Contact".Editable() and
          PurchaseQuotePage."Pay-to Contact".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomAddressPayToOptionOnPurchaseOrderPage()
    var
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseOrderPage: TestPage "Purchase Order";
        PayToOptions: Option "Default (Vendor)","Another Vendor","Custom Address";
    begin
        // [FEATURE] [Purchase] [Order]
        // [SCENARIO 301084] Bill-to/Pay-to address fields cannot be edited

        // [GIVEN] Created document, opened it's page
        LibraryPurchase.CreatePurchaseOrder(PurchaseOrderHeader);
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.FILTER.SetFilter("No.", PurchaseOrderHeader."No.");

        // [WHEN] Choose "Custom Address" Pay-to option
        PurchaseOrderPage.PayToOptions.SetValue(PayToOptions::"Custom Address");

        // [THEN] Pay-to address fields are editable, and "Pay-to Name" field is not
        Assert.IsFalse(PurchaseOrderPage."Pay-to Name".Editable(), '');
        Assert.IsTrue(PurchaseOrderPage."Pay-to Address".Editable() and
          PurchaseOrderPage."Pay-to Address 2".Editable() and
          PurchaseOrderPage."Pay-to City".Editable() and
          PurchaseOrderPage."Pay-to County".Editable() and
          PurchaseOrderPage."Pay-to Post Code".Editable() and
          PurchaseOrderPage."Pay-to Contact No.".Editable() and
          PurchaseOrderPage."Pay-to Contact".Editable() and
          PurchaseOrderPage."Pay-to Contact".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomAddressPayToOptionOnPurchaseInvoicePage()
    var
        PurchaseInvoiceHeader: Record "Purchase Header";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        PayToOptions: Option "Default (Vendor)","Another Vendor","Custom Address";
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 301084] Bill-to/Pay-to address fields cannot be edited

        // [GIVEN] Created document, opened it's page
        LibraryPurchase.CreatePurchaseInvoice(PurchaseInvoiceHeader);
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.FILTER.SetFilter("No.", PurchaseInvoiceHeader."No.");

        // [WHEN] Choose "Custom Address" Pay-to option
        PurchaseInvoicePage.PayToOptions.SetValue(PayToOptions::"Custom Address");

        // [THEN] Pay-to address fields are editable, and "Pay-to Name" field is not
        Assert.IsFalse(PurchaseInvoicePage."Pay-to Name".Editable(), '');
        Assert.IsTrue(PurchaseInvoicePage."Pay-to Address".Editable() and
          PurchaseInvoicePage."Pay-to Address 2".Editable() and
          PurchaseInvoicePage."Pay-to City".Editable() and
          PurchaseInvoicePage."Pay-to County".Editable() and
          PurchaseInvoicePage."Pay-to Post Code".Editable() and
          PurchaseInvoicePage."Pay-to Contact No.".Editable() and
          PurchaseInvoicePage."Pay-to Contact".Editable() and
          PurchaseInvoicePage."Pay-to Contact".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BillToAddressEqualsSellToAddress()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 301084] Bill-to/Pay-to address fields cannot be edited

        // [GIVEN] Created Customer with address
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [WHEN] Create document for the Customer with default Bill-to address fields
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesInvoiceHeader, Customer."No.");

        // [THEN] Bill-to address equals Sell-to address
        Assert.IsTrue(SalesInvoiceHeader.BillToAddressEqualsSellToAddress(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BillToAddressNotEqualsSellToAddress()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 301084] Bill-to/Pay-to address fields cannot be edited

        // [GIVEN] Created Customer with address
        LibrarySales.CreateCustomerWithAddress(Customer);

        // [WHEN] Create document for the Customer with custom Bill-to address fields
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesInvoiceHeader, Customer."No.");
        SalesInvoiceHeader.Validate("Bill-to Address 2", CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Customer."Address 2")));
        SalesInvoiceHeader.Modify();

        // [THEN] Bill-to address doesn't equal Sell-to address
        Assert.IsFalse(SalesInvoiceHeader.BillToAddressEqualsSellToAddress(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayToAddressEqualsBuyFromAddress()
    var
        Vendor: Record Vendor;
        PurchaseInvoiceHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 301084] Bill-to/Pay-to address fields cannot be edited

        // [GIVEN] Created Vendor with address
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // [WHEN] Create document for the Vendor with default Pay-to address fields
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseInvoiceHeader, Vendor."No.");

        // [THEN] Pay-to address equals Buy-from address
        Assert.IsTrue(PurchaseInvoiceHeader.BuyFromAddressEqualsPayToAddress(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayToAddressNotEqualsBuyFromAddress()
    var
        Vendor: Record Vendor;
        PurchaseInvoiceHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 301084] Bill-to/Pay-to address fields cannot be edited

        // [GIVEN] Created Vendor with address
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // [WHEN] Create document for the Vendor with custom Pay-to address fields
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseInvoiceHeader, Vendor."No.");
        PurchaseInvoiceHeader.Validate("Pay-to Address 2", CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Vendor."Address 2")));
        PurchaseInvoiceHeader.Modify();

        // [THEN] Pay-to address doesn't equal Buy-from address
        Assert.IsFalse(PurchaseInvoiceHeader.BuyFromAddressEqualsPayToAddress(), '');
    end;

    [HandlerFunctions('ItemListLookForItemOkMPH')]
    [Scope('OnPrem')]
    procedure SalesSelectMultipleItemsAddsExtendedText()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExtendedText: Text;
    begin
        // [SCENARIO 302778] SelectMultipleItems on Sales page adds Extended text of Item
        // [GIVEN] Item with "Extended Text" equal "X" and "Automatic Ext. Texts" set to TRUE
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify();
        ExtendedText := LibraryInventory.CreateExtendedTextForItem(Item."No.");

        // [GIVEN] Sales Document "Y"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] SelectMultipleItems is called
        LibraryVariableStorage.Enqueue(Item."No.");
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine.SelectMultipleItems();

        // [THEN] Sales Line with Description equal to "X" added to Sales Document "Y"
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        SalesLine.FindFirst();
        Assert.AreEqual(ExtendedText, SalesLine.Description, '');
    end;

    [Test]
    [HandlerFunctions('ItemListLookForItemOkMPH')]
    [Scope('OnPrem')]
    procedure PurchaseSelectMultipleItemsAddsExtendedText()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ExtendedText: Text;
    begin
        // [SCENARIO 302778] SelectMultipleItems on Purchase page adds Extended text of Item
        // [GIVEN] Item with "Extended Text" equal "X" and "Automatic Ext. Texts" set to TRUE
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify();
        ExtendedText := LibraryInventory.CreateExtendedTextForItem(Item."No.");

        // [GIVEN] Purchase Document "Y"
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // [WHEN] SelectMultipleItems is called
        LibraryVariableStorage.Enqueue(Item."No.");
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine.SelectMultipleItems();

        // [THEN] Purchase Line with Description equal to "X" added to Purchase Document "Y"
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::" ");
        PurchaseLine.FindFirst();
        Assert.AreEqual(ExtendedText, PurchaseLine.Description, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroupsToleranceVisible()
    var
        CustPstGrps: TestPage "Customer Posting Groups";
    begin
        // [FEATURE] [Sales] [Quote]
        // [SCENARIO 304263] When "Max. Pmt. Tolerance Amount" is not 0, fields "Payment Tolerance Credit Acc." and "Payment Tolerance Debit Acc." are Visible on page Customer Posting Groups
        Initialize();
        LibraryPmtDiscSetup.SetPmtTolerance(0);
        CustPstGrps.OpenEdit();
        Assert.IsTrue(
          CustPstGrps."Payment Tolerance Credit Acc.".Visible(),
          StrSubstNo(PageFieldVisibleErr, CustPstGrps."Payment Tolerance Credit Acc.".Caption));
        Assert.IsTrue(
          CustPstGrps."Payment Tolerance Debit Acc.".Visible(),
          StrSubstNo(PageFieldVisibleErr, CustPstGrps."Payment Tolerance Debit Acc.".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroupsToleranceNotVisible()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustPstGrps: TestPage "Customer Posting Groups";
    begin
        // [FEATURE] [Sales] [Quote]
        // [SCENARIO 304263] When "Max. Pmt. Tolerance Amount" and "Payment Tolerance %" are 0, fields "Payment Tolerance Credit Acc." and "Payment Tolerance Debit Acc." are not Visible on page Customer Posting Groups
        Initialize();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", 0);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", 0);
        GeneralLedgerSetup.Modify(true);
        CustPstGrps.OpenEdit();
        Assert.IsFalse(
          CustPstGrps."Payment Tolerance Credit Acc.".Visible(),
          StrSubstNo(PageFieldNotVisibleErr, CustPstGrps."Payment Tolerance Credit Acc.".Caption));
        Assert.IsFalse(
          CustPstGrps."Payment Tolerance Debit Acc.".Visible(),
          StrSubstNo(PageFieldNotVisibleErr, CustPstGrps."Payment Tolerance Debit Acc.".Caption));
        LibrarySetupStorage.Restore();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroupsToleranceVisible()
    var
        VndrPstGrps: TestPage "Vendor Posting Groups";
    begin
        // [FEATURE] [Sales] [Quote]
        // [SCENARIO 304263] When "Max. Pmt. Tolerance Amount" is not 0, fields "Payment Tolerance Credit Acc." and "Payment Tolerance Debit Acc." are Visible on page Vendor Posting Groups
        LibraryPmtDiscSetup.SetPmtTolerance(0);
        VndrPstGrps.OpenEdit();
        Assert.IsTrue(
          VndrPstGrps."Payment Tolerance Credit Acc.".Visible(),
          StrSubstNo(PageFieldVisibleErr, VndrPstGrps."Payment Tolerance Credit Acc.".Caption));
        Assert.IsTrue(
          VndrPstGrps."Payment Tolerance Debit Acc.".Visible(),
          StrSubstNo(PageFieldVisibleErr, VndrPstGrps."Payment Tolerance Debit Acc.".Caption));
        LibrarySetupStorage.Restore();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroupsToleranceNotVisible()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VndrPstGrps: TestPage "Vendor Posting Groups";
    begin
        // [FEATURE] [Sales] [Quote]
        // [SCENARIO 304263] When "Max. Pmt. Tolerance Amount" and "Payment Tolerance %"are 0, fields "Payment Tolerance Credit Acc." and "Payment Tolerance Debit Acc." are not Visible on page Vendor Posting Groups
        Initialize();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", 0);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", 0);
        GeneralLedgerSetup.Modify(true);
        VndrPstGrps.OpenEdit();
        Assert.IsFalse(
          VndrPstGrps."Payment Tolerance Credit Acc.".Visible(),
          StrSubstNo(PageFieldNotVisibleErr, VndrPstGrps."Payment Tolerance Credit Acc.".Caption));
        Assert.IsFalse(
          VndrPstGrps."Payment Tolerance Debit Acc.".Visible(),
          StrSubstNo(PageFieldNotVisibleErr, VndrPstGrps."Payment Tolerance Debit Acc.".Caption));
    end;

    [Test]
    [HandlerFunctions('ItemCardPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInfoPaneManagementCorrectDropShipmentFilter()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInfoPaneManagement: Codeunit "Sales Info-Pane Management";
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Item] [Drop Shipment] [Sales]
        // [SCENARIO 312348] Item Card page opened with LookupItem shows correct flowfield values

        // [GIVEN] Created Sales Line with Item
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", 8, '', 0D);

        // [GIVEN] Set Drop Shipment = TRUE for that Sales Line
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);

        // [WHEN] Invoke procedure from Sales Info-Pane Management that includes SetItemFilter local function
        SalesInfoPaneManagement.CalcAvailability(SalesLine);

        // [THEN] Item Card page opened with LookupItem shows correct flowfield value
        ItemCard.Trap();
        SalesInfoPaneManagement.LookupItem(SalesLine);
        Assert.AreEqual(8, LibraryVariableStorage.DequeueDecimal(), '');
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure CustomerCardGetTotalSalesDoesntCallSetFilterForUnpostedLines()
    var
        CodeCoverage: Record "Code Coverage";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        CustomerCard: TestPage "Customer Card";
        NoOfHits: Integer;
    begin
        // [SCENARIO 314486] GetTotalSales is not leading to calls for SetFilterForUnpostedLines when No. = '' on opening new Customer Card page.
        if CodeCoverageMgt.Running() then
            CodeCoverageMgt.StopApplicationCoverage();

        CustomerCard.Trap();
        CodeCoverageMgt.StartApplicationCoverage();
        CustomerCard.OpenNew();
        CodeCoverageMgt.StopApplicationCoverage();

        NoOfHits := CodeCoverageMgt.GetNoOfHitsCoverageForObject(
            CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Customer Mgt.", 'SetFilterForUnpostedLines');
        Assert.AreEqual(0, NoOfHits, '');
    end;

    [Test]
    [HandlerFunctions('GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalPageHasClosingCurrentPostingDate()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlManagement: Codeunit GenJnlManagement;
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [Closing Date] [Posting Date]
        // [SCENARIO 318394] Current Posting Date on General Journal page can show Closing Dates.
        // [GIVEN] Created a Gen. Journal Line with according type of a Posting Date
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(100, 2));
        GenJnlLine.Validate("Posting Date", ClosingDate(WorkDate()));
        GenJnlLine.Modify(true);

        // [WHEN] Open General Journal for created record in Simple Mode
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"General Journal");
        LibraryVariableStorage.Enqueue(GenJnlLine."Journal Template Name");
        GeneralJournal.OpenEdit();

        // [THEN] Current Posting Date as Closing Date is shown correctly
        Assert.AreEqual(GenJnlLine."Posting Date", GeneralJournal."<CurrentPostingDate>".AsDate(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GenJnlTemplateHandler')]
    [Scope('OnPrem')]
    procedure GeneralJournalPageHasOpeningCurrentPostingDate()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlManagement: Codeunit GenJnlManagement;
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [Posting Date]
        // [SCENARIO 318394] Current Posting Date on General Journal page can show Opening Dates.
        // [GIVEN] Created a Gen. Journal Line with according type of a Posting Date
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(100, 2));
        GenJnlLine.Validate("Posting Date", WorkDate());
        GenJnlLine.Modify(true);

        // [WHEN] Open General Journal for created record in Simple Mode
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"General Journal");
        LibraryVariableStorage.Enqueue(GenJnlLine."Journal Template Name");
        GeneralJournal.OpenEdit();

        // [THEN] Current Posting Date as Opening Date is shown correctly
        Assert.AreEqual(GenJnlLine."Posting Date", GeneralJournal."<CurrentPostingDate>".AsDate(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('LookupTableID_Handler')]
    [Scope('OnPrem')]
    procedure ConfigLine_LookupTableID()
    var
        ConfigLine: Record "Config. Line";
        ConfigLinePage: TestPage "Config. Worksheet";
        TableID: Integer;
    begin
        // - Lookup Table ID on Config. Lines.
        // [FEATURE] [Rapid Start]

        ConfigLine.DeleteAll(true);
        TableID := DATABASE::Customer;
        LibraryVariableStorage.Enqueue(TableID);

        ConfigLinePage.OpenEdit();
        ConfigLinePage.New();
        ConfigLinePage."Line Type".SetValue(ConfigLine."Line Type"::Table);
        ConfigLinePage."Table ID".Lookup();
        ConfigLinePage.OK().Invoke();

        ConfigLine.FindFirst();
        Assert.AreEqual(TableID, ConfigLine."Table ID", 'Incorrect Table ID.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerStatisticsFactbox()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CustomerStatisticsFactBox: TestPage "Customer Statistics FactBox";
    begin
        // [SCENARIO 323686] "Refund (LCY)" is visible on Customer Statistics Factbox.
        // [FEATURE] [Customer] [Sales] [Refund]
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        CustomerStatisticsFactBox.OpenView();
        Assert.IsTrue(CustomerStatisticsFactBox."Balance (LCY)".Visible(), 'Balance (LCY) is not visible in SaaS');

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorStatisticsFactbox()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        VendorStatisticsFactBox: TestPage "Vendor Statistics FactBox";
    begin
        // [SCENARIO 323686] "Refund (LCY)" is visible on Vendor Statistics Factbox.
        // [FEATURE] [Vendor] [Purchases] [Refund]
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        VendorStatisticsFactBox.OpenView();
        Assert.IsTrue(VendorStatisticsFactBox."Balance (LCY)".Visible(), 'Balance (LCY) is not visible in SaaS');

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('TimeZoneLookup')]
    [Scope('OnPrem')]
    procedure PostCodesLookUpTimeZone()
    var
        PostCode: Record "Post Code";
        TimeZone: Record "Time Zone";
        PostCodes: TestPage "Post Codes";
    begin
        // [SCENARIO 323341] Lookup TimeZone in Post Codes
        CreatePostCode(PostCode);
        PostCodes.OpenEdit();
        PostCodes.FILTER.SetFilter(City, PostCode.City);
        TimeZone.FindSet();
        TimeZone.Next(TimeZone.Count);
        LibraryVariableStorage.Enqueue(TimeZone.ID);
        PostCodes.TimeZone.Lookup();
        PostCodes.Close();
        PostCode.Find();
        PostCode.TestField("Time Zone", TimeZone.ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToOptionsOnPurchaseQuotePage()
    var
        PurchaseQuoteHeader: Record "Purchase Header";
        PurchaseQuotePage: TestPage "Purchase Quote";
        ShipToOptions: Option "Default (Company Address)",Location,"Custom Address";
    begin
        // [FEATURE] [Purchase] [Quote] [Ship-to-Address]
        // [SCENARIO 343963] Ship-to options on Purchase Quote page consist of: Default (Company Address), Location, Custom Address

        // [GIVEN] Created Purchase Quote
        LibraryPurchase.CreatePurchaseQuote(PurchaseQuoteHeader);

        // [WHEN] Opened th page
        PurchaseQuotePage.OpenEdit();
        PurchaseQuotePage.FILTER.SetFilter("No.", PurchaseQuoteHeader."No.");

        // [THEN] Ship-to options consist of: Default (Company Address), Location, Custom Address
        PurchaseQuotePage.ShippingOptionWithLocation.SetValue(ShipToOptions::"Default (Company Address)");
        PurchaseQuotePage.ShippingOptionWithLocation.SetValue(ShipToOptions::Location);
        PurchaseQuotePage.ShippingOptionWithLocation.SetValue(ShipToOptions::"Custom Address");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,LogSegmentHandler')]
    [Scope('OnPrem')]
    procedure CheckNewSegmentLoggedSuccessfully()
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        LoggedSegment: Record "Logged Segment";

        Segment: TestPage Segment;
        Description: Code[20];
        SegmentNo: Code[20];
    begin
        // [FEATURE] [Segment]
        // [SCENARIO 346492] Create New Segment with Segment Line
        // [GIVEN] Created Interaction Template
        CreateInteractionTemplate(InteractionTemplate);

        // [GIVEN] Created Contact with SalesPerson
        CreateContactWithSalesperson(Contact);

        // [GIVEN] Created new segment with page
        Segment.OpenNew();
        Description := LibraryUtility.GenerateGUID();
        Segment.Description.SetValue(Description);
        Segment.SegLines."Contact No.".SETVALUE(Contact."No.");
        Segment."Interaction Template Code".SETVALUE(InteractionTemplate.Code);

        SegmentNo := Segment."No.".Value();
        Segment.Close();
        Segment.OpenEdit();
        Segment.Filter.SetFilter("No.", SegmentNo);
        Segment.First();
        Commit();

        // [WHEN] Log Segment
        Segment.LogSegment.Invoke();

        // [THEN] The page Segment Closed successfully 
        // [THEN] The Segment logged successfully 
        LoggedSegment.SetRange(Description, Description);
        LoggedSegment.FindFirst();
    end;

    [Test]
    [HandlerFunctions('VATStatementTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure DateFilterCopyToVATEntriesFromVATStatementPreview()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreview: TestPage "VAT Statement Preview";
        VATStatement: TestPage "VAT Statement";
        VATEntries: TestPage "VAT Entries";
    begin
        // [FEATURE] [UI] [VAT Statement]
        // [SCENARIO 353780] 'VAT Entries' opened from VAT Statement Preview respect the Date Filter in VAT Statement
        // [GIVEN] "VAT Statement Name" and "VAT Statement Line" with Type = "VAT Entry Totaling"
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Amount);
        VATStatementLine.Modify(true);
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");

        // [GIVEN] Open page "VAT Statement Preview" for created line
        VATStatement.OpenEdit();
        VATStatement.Filter.SetFilter("Statement Template Name", VATStatementLine."Statement Template Name");
        VATStatement.Filter.SetFilter("Statement Name", VATStatementLine."Statement Name");
        VATStatement.First();
        VATStatementPreview.Trap();
        VATStatement."P&review".Invoke();

        // [GIVEN] Set date filter to "Date" and Period Selection = "Within Period"
        VATStatementPreview.PeriodSelection.SetValue('Within Period');
        VATStatementPreview.DateFilter.SetValue(WorkDate());
        VATEntries.Trap();

        // [WHEN] DrillDown to ColumnValue
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.Drilldown();

        // [THEN] Page "VAT Entries" was opened with filter to "VAT Reporting Date" = Date
        Assert.AreEqual(VATEntries.FILTER.GetFilter("VAT Reporting Date"), Format(WorkDate()), '');
        VATEntries.Close();
        VATStatement.Close();
        VATStatementPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProfileCustomizationListHaveFiltersAfterRunningFrimProfileList()
    var
        ProfileList: TestPage "Profile List";
        ProfileCustomizationList: TestPage "Profile Customization List";
    begin
        // [FEATURE] [UI] [Profile]
        // [SCENARIO 382290] Open "Profile Customization List" and check filters
        // [GIVEN] Opened "Profile List" page
        ProfileCustomizationList.Trap();
        ProfileList.OpenEdit();
        ProfileList.First();

        // [WHEN] Open "Profile Customization List" page from "Profile List"
        ProfileList.ManageCustomizedPages.Invoke();

        // [GIVEN] Filters are set to "App ID" and "Profile ID"
        Assert.AreNotEqual(ProfileCustomizationList.Filter.GetFilter("App ID"), '', 'Filter "App ID" should not be empty');
        Assert.AreNotEqual(ProfileCustomizationList.Filter.GetFilter("Profile ID"), '', 'Filter "Profile ID" should not be empty');
        ProfileList.Close();
        ProfileCustomizationList.Close();
    end;

    [Test]
    [HandlerFunctions('PostedSalesShipmentsPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedSalesShipmentsPageOpensPassedRecord()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [SCENARIO 386212] Filtered Posted Sales Shipments page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(SalesShipmentHeader, PAGE::"Posted Sales Shipments");
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoicesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedSalesInvoicesPageOpensPassedRecord()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO 386212] Filtered Posted Sales Invoices page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(SalesInvoiceHeader, PAGE::"Posted Sales Invoices");
    end;

    [Test]
    [HandlerFunctions('PostedSalesCreditMemosPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedSalesCreditMemosPageOpensPassedRecord()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [SCENARIO 386212] Filtered Posted Sales Credit Memos page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(SalesCrMemoHeader, PAGE::"Posted Sales Credit Memos");
    end;

    [Test]
    [HandlerFunctions('PostedReturnReceiptsPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedReturnReceiptsPageOpensPassedRecord()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        // [SCENARIO 386212] Filtered Posted Return Receipts page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(ReturnReceiptHeader, PAGE::"Posted Return Receipts");
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseReceiptsPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedPurchaseReceiptsPageOpensPassedRecord()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        // [SCENARIO 386212] Filtered Posted Purchase Receipts page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(PurchRcptHeader, PAGE::"Posted Purchase Receipts");
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseInvoicesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedPurchaseInvoicesPageOpensPassedRecord()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [SCENARIO 386212] Filtered Posted Purchase Invoices page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(PurchInvHeader, PAGE::"Posted Purchase Invoices");
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseCreditMemosPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredPostedPurchaseCreditMemosPageOpensPassedRecord()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [SCENARIO 386212] Filtered Posted Purchase Credit Memos page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(PurchCrMemoHdr, PAGE::"Posted Purchase Credit Memos");
    end;

    [Test]
    [HandlerFunctions('GeneralLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredGeneralLedgerEntriesPageOpensPassedRecord()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO 386212] Filtered General Ledger Entries page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(GLEntry, PAGE::"General Ledger Entries");
    end;

    [Test]
    [HandlerFunctions('ResourceLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredResourceLedgerEntriesPageOpensPassedRecord()
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        // [SCENARIO 386212] Filtered Resource Ledger Entries page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(ResLedgerEntry, PAGE::"Resource Ledger Entries");
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredCustomerLedgerEntriesPageOpensPassedRecord()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO 386212] Filtered Customer Ledger Entries page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(CustLedgerEntry, PAGE::"Customer Ledger Entries");
    end;

    [Test]
    [HandlerFunctions('VendorLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredVendorLedgerEntriesPageOpensPassedRecord()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 386212] Filtered Vendor Ledger Entries page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(VendorLedgerEntry, PAGE::"Vendor Ledger Entries");
    end;

    [Test]
    [HandlerFunctions('CheckLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredCheckLedgerEntriesPageOpensPassedRecord()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // [SCENARIO 386212] Filtered Check Ledger Entries page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(CheckLedgerEntry, PAGE::"Check Ledger Entries");
    end;

    [Test]
    [HandlerFunctions('ItemLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure FilteredItemLedgerEntriesPageOpensPassedRecord()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO 386212] Filtered Item Ledger Entries page opens passed record.

        MockThreeRecordsAndOpenSecondOnFilteredPage(ItemLedgerEntry, PAGE::"Item Ledger Entries");
    end;

    [Test]
    [HandlerFunctions('SetSpecialPricesEnabledSalesPriceAndLineDiscountsModalPageHandler')]
    procedure SetSpecialPricesIsEnabledWhenSalesLineDiscountLineIsSelected()
    var
        SalesLineDiscount: Record "Sales Line Discount";
        ItemCard: TestPage "Item Card";
        SetSpecialPricesEnabled: Boolean;
    begin
        // [SCENARIO 392447] "Set Special Prices" enabled state when Line with Type "Sales Line Discount" is selected on page "Sales Price and Line Discount".

        // [GIVEN] Item with Sales Line Discount for Customer.
        CreateSalesLineDiscount(SalesLineDiscount, LibraryInventory.CreateItemNo(), LibrarySales.CreateCustomerNo());

        // [GIVEN] Item card is opened and drill down action for field "Sales Prices & Discounts" is performed.
        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", SalesLineDiscount.Code);
        ItemCard.SpecialPricesAndDiscountsTxt.Drilldown();

        // [WHEN] Page "Sales Price and Line Discount" is opened and Line with Type "Sales Line Discount" is selected.
        // [THEN] "Set Special Prices" action is enabled on page "Sales Price and Line Discount".
        SetSpecialPricesEnabled := LibraryVariableStorage.DequeueBoolean();
        Assert.IsTrue(SetSpecialPricesEnabled, 'Set Special Prices action is not enabled');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SetSpecialPricesEnabledSalesPriceAndLineDiscountsModalPageHandler')]
    procedure SetSpecialPricesIsEnabledWhenSalesPriceLineIsSelected()
    var
        SalesPrice: Record "Sales Price";
        ItemCard: TestPage "Item Card";
        SetSpecialPricesEnabled: Boolean;
    begin
        // [SCENARIO 392447] "Set Special Prices" enabled state when Line with Type "Sales Price" is selected on page "Sales Price and Line Discount".

        // [GIVEN] Item with Sales Price for Customer.
        CreateSalesPrice(SalesPrice, LibraryInventory.CreateItemNo(), LibrarySales.CreateCustomerNo());

        // [GIVEN] Item card is opened and drill down action for field "Sales Prices & Discounts" is performed.
        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", SalesPrice."Item No.");
        ItemCard.SpecialPricesAndDiscountsTxt.Drilldown();

        // [WHEN] Page "Sales Price and Line Discount" is opened and Line with Type "Sales Price" is selected.
        // [THEN] "Set Special Prices" action is enabled on page "Sales Price and Line Discount".
        SetSpecialPricesEnabled := LibraryVariableStorage.DequeueBoolean();
        Assert.IsTrue(SetSpecialPricesEnabled, 'Set Special Prices action is not enabled');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTaskSalespersonCodeEnabledTeamTask()
    var
        ToDo: Record "To-do";
        SalesPerson: Record "Salesperson/Purchaser";
        CreateTask: TestPage "Create Task";
    begin
        // [FEATURE] [Marketing] [To-do] 
        // [SCEANRIO 406510] Salesperson Code should be editable with every 'Team Task' value

        // [WHEN] Create Task page is opened
        MockTodo(ToDo);
        ToDo.SetFilter("Salesperson Code", SalesPerson.Code);
        LibrarySales.CreateSalesperson(SalesPerson);

        CreateTask.OpenEdit();
        CreateTask.FILTER.SetFilter("No.", ToDo."No.");
        CreateTask.Description.SetValue(LibraryUtility.GenerateRandomXMLText(10));
        CreateTask."Salesperson Code".SetValue(SalesPerson.Code);

        // [THEN] Field 'Salesperson Code' is enabled
        Assert.AreEqual(true, CreateTask."Salesperson Code".Enabled(), 'Salesperson Code should be enabled');

        // [WHEN] 'Team Task' = True
        CreateTask.TeamTask.SetValue(true);

        // [THEN] Field 'Salesperson Code' is enabled
        Assert.AreEqual(false, CreateTask."Salesperson Code".Enabled(), 'Salesperson Code should be disable');
        Assert.AreEqual('', CreateTask."Salesperson Code".Value, 'Salesperson Code should be empty');

        // [WHEN] 'Team Task' = True
        CreateTask.TeamTask.SetValue(false);

        // [THEN] Field 'Salesperson Code' is enabled
        Assert.AreEqual(true, CreateTask."Salesperson Code".Enabled(), 'Salesperson Code should be enabled');

        CreateTask."Salesperson Code".SetValue(SalesPerson.Code); // needed to close page without error message
        CreateTask.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ContactListPageHandler')]
    [Scope('OnPrem')]
    procedure BilltoContactLookupOnJobCardPage()
    var
        Job: Record Job;
        Contact: Record Contact;
        Customer: Record Customer;
        JobCard: TestPage "Job Card";
    begin
        // [SCENARIO 407536] "Bill-to Contact No." lookup in "Job Card" must update "Bill-to Contact No."
        Initialize();
        LibraryApplicationArea.EnableJobsSetup();

        // [GIVEN] Job and Contact "C1"
        LibraryJob.CreateJob(Job, '');

        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        JobCard.Trap();

        // [WNEN] Open Job Card and invoke "Bill-to Contact No." lookup and choose "C1"
        Page.Run(Page::"Job Card", Job);
        LibraryVariableStorage.Enqueue(Contact."No.");
        JobCard."Bill-to Contact No.".Lookup();

        // [THEN] "Job Card"."Bill-to Contact No." = "C1"
        JobCard."Bill-to Contact No.".AssertEquals(Contact."No.");

        LibraryVariableStorage.AssertEmpty();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardRegistrationNumberIsEditable()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        RegistrationNumber: Text[50];
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 359959] Registration Number field is editable on the Vendor Card page
        LibraryPurchase.CreateVendor(Vendor);
        RegistrationNumber := LibraryUtility.GenerateGUID();

        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", Vendor."No.");
        VendorCard."Registration Number".SetValue(RegistrationNumber);
        VendorCard.Close();

        Vendor.Find();
        Vendor.TestField("Registration Number", RegistrationNumber);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure VendorCardRegistrationNumberErrorLength()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        RegistrationNumber: Text[50];
    begin
        // [FEATURE] [Vendor]        
        // [SCENARIO 359959] Registration Number field error for legth more than 20 on the Vendor Card page
        LibraryPurchase.CreateVendor(Vendor);
        RegistrationNumber := LibraryUtility.GenerateRandomText(21);

        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", Vendor."No.");
        asserterror VendorCard."Registration Number".SetValue(RegistrationNumber);

        Assert.ExpectedErrorCode('TestValidation');
        Assert.ExpectedError(FieldLengthErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardRegistrationNumberIsEditable()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        RegistrationNumber: Text[50];
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 359959] Registration Number field is editable on the Customer Card page
        LibrarySales.CreateCustomer(Customer);
        RegistrationNumber := LibraryUtility.GenerateGUID();

        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer."No.");
        CustomerCard."Registration Number".SetValue(RegistrationNumber);
        CustomerCard.Close();

        Customer.Find();
        Customer.TestField("Registration Number", RegistrationNumber);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardRegistrationNumberErrorLength()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        RegistrationNumber: Text[50];
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 359959] Registration Number field error for legth more than 20 on the Customer Card page
        LibrarySales.CreateCustomer(Customer);
        RegistrationNumber := LibraryUtility.GenerateRandomText(21);

        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer."No.");
        asserterror CustomerCard."Registration Number".SetValue(RegistrationNumber);

        Assert.ExpectedErrorCode('TestValidation');
        Assert.ExpectedError(FieldLengthErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCompanyCardRegistrationNumberIsEditable()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        RegistrationNumber: Text[50];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 466353] Registration Number field is editable on the company Contact Card page
        LibraryMarketing.CreateCompanyContact(Contact);
        RegistrationNumber := LibraryUtility.GenerateGUID();

        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");
        ContactCard."Registration Number".SetValue(RegistrationNumber);
        ContactCard.Close();

        Contact.Find();
        Contact.TestField("Registration Number", RegistrationNumber);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactPersonCardRegistrationNumberIsNotEnabled()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 466353] Registration Number field is not enablesdon the person Contact Card page
        LibraryMarketing.CreatePersonContact(Contact);

        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");
        Assert.IsFalse(ContactCard."Registration Number".Enabled(), '');
        ContactCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCompanyCardRegistrationNumberErrorLength()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        RegistrationNumber: Text[50];
    begin
        // [FEATURE] [Contact]        
        // [SCENARIO 466353] Registration Number field error for legth more than 20 on the Contact Card page
        LibraryMarketing.CreateCompanyContact(Contact);
        RegistrationNumber := LibraryUtility.GenerateRandomText(21);

        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");
        asserterror ContactCard."Registration Number".SetValue(RegistrationNumber);

        Assert.ExpectedErrorCode('TestValidation');
        Assert.ExpectedError(FieldLengthErr);
    end;

    [Test]
    [HandlerFunctions('VATStatementTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure VATStatementPreviewWithCountryRegionFilterSunshine()
    var
        VATEntry: array[2] of Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementPreview: TestPage "VAT Statement Preview";
        VATStatement: TestPage "VAT Statement";
    begin
        // [FEATURE] [UI] [VAT Statement]
        // [SCENARIO 556928] VAT Entries opened from VAT Statement Preview respect the Country/Region Filter in VAT Statement

        // [GIVEN] "VAT Statement Name" and "VAT Statement Line" with Type = "VAT Entry Totaling"
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Amount);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATStatementLine.Validate("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Purchase);
        VATStatementLine.Modify(true);
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");

        MockPurchVATEntryWithCountryCode(VATEntry[1], VATPostingSetup);
        MockPurchVATEntryWithCountryCode(VATEntry[2], VATPostingSetup);

        // [GIVEN] Open page "VAT Statement Preview" for created line
        VATStatement.OpenEdit();
        VATStatement.Filter.SetFilter("Statement Template Name", VATStatementLine."Statement Template Name");
        VATStatement.Filter.SetFilter("Statement Name", VATStatementLine."Statement Name");
        VATStatement.First();
        VATStatementPreview.Trap();
        VATStatement."P&review".Invoke();

        VATStatementPreview.PeriodSelection.SetValue('Within Period');
        VATStatementPreview.DateFilter.SetValue(WorkDate());
        // [WHEN] Set country/region filter to "DE"
        VATStatementPreview."Country/Region Filter".SetValue(VATEntry[2]."Country/Region Code");

        // [THEN]
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.AssertEquals(VATEntry[2].Amount);

        // tear down
        VATStatement.Close();
        VATStatementPreview.Close();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTemplates.EnableTemplatesFeature();

        IsInitialized := true;
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        Commit();
    end;

    local procedure CreatePostCodeFields(var City: Text[30]; var "Code": Code[20]; var County: Text[30]; var CountryCode: Code[10])
    var
        PostCode: Record "Post Code";
    begin
        CreatePostCode(PostCode);
        City := PostCode.City;
        Code := PostCode.Code;
        County := PostCode.County;
        CountryCode := PostCode."Country/Region Code";
    end;

    local procedure CreateVendorWithICPartnerCode(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("IC Partner Code", LibraryERM.CreateICPartnerNo());
        Vendor.Modify(true);
    end;

    local procedure OpenVendorCard(var VendorCard: TestPage "Vendor Card"; VendorNo: Code[20])
    begin
        VendorCard.Trap();
        VendorCard.OpenView();
        VendorCard.FILTER.SetFilter("No.", VendorNo);
    end;

    local procedure CreateCustomerWithICPartnerCode(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("IC Partner Code", LibraryERM.CreateICPartnerNo());
        Customer.Modify(true);
    end;

    local procedure OpenCustomerCard(var CustomerCard: TestPage "Customer Card"; CustomerNo: Code[20])
    begin
        CustomerCard.Trap();
        CustomerCard.OpenView();
        CustomerCard.FILTER.SetFilter("No.", CustomerNo);
    end;

    local procedure CreateItemWithTracking(): Code[20]
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", true);
        ItemTrackingCode.Validate("Lot Purchase Inbound Tracking", true);
        ItemTrackingCode.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);

        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrderPartialReceive(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          '', LibraryRandom.RandDecInRange(10, 20, 2), '', LibraryRandom.RandDate(10));

        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);
        PurchaseLine.Validate("Qty. to Invoice", 0);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderPartialInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          '', LibraryRandom.RandDecInRange(10, 20, 2), '', LibraryRandom.RandDate(10));

        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePostCode(var PostCode: Record "Post Code")
    begin
        LibraryERM.CreatePostCode(PostCode);
        PostCode.Validate(
          County,
          CopyStr(
            LibraryUtility.GenerateRandomCode(PostCode.FieldNo(County), DATABASE::"Post Code"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Post Code", PostCode.FieldNo(County))));
        PostCode.Modify();
    end;

    local procedure MockThreeRecordsAndOpenFilteredPage(RecVar: Variant; PageNo: Integer)
    var
        KeyValueMiddle: Variant;
        KeyValueFirst: Variant;
        ActionOption: Option Set,Verify;
        Index: Integer;
    begin
        for Index := 1 to 3 do
            MockRecordWithKeyValue(RecVar);

        GetFirstMiddleKeyFieldValuesAndSetFilter(KeyValueMiddle, KeyValueFirst, RecVar);

        EnqueueValuesAndRunFilteredPage(KeyValueMiddle, ActionOption::Set, PageNo, RecVar);
        EnqueueValuesAndRunFilteredPage(KeyValueFirst, ActionOption::Verify, PageNo, RecVar);
    end;

    local procedure MockThreeRecordsAndOpenSecondOnFilteredPage(RecVar: Variant; PageNo: Integer)
    var
        KeyValueMiddle: Variant;
        ActionOption: Option Set,Verify;
        Index: Integer;
    begin
        for Index := 1 to 3 do
            MockRecordWithKeyValue(RecVar);

        GetMiddleKeyFieldValueAndSetFilter(KeyValueMiddle, RecVar);

        EnqueueValuesAndRunFilteredPage(KeyValueMiddle, ActionOption::Verify, PageNo, RecVar);
    end;

    local procedure MockRecordWithKeyValue(RecVar: Variant): Code[10]
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(RecVar);
        KeyRef := RecRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        case FieldRef.Type of
            FieldType::Code:
                FieldRef.Value := LibraryUtility.GenerateGUID();
            FieldType::Integer:
                FieldRef.Value := LibraryUtility.GetNewRecNo(RecRef, FieldRef.Number);
        end;
        RecRef.Insert();
        exit(Format(FieldRef.Value));
    end;

    local procedure MockTodo(var ToDo: Record "To-do")
    begin
        ToDo.Init();
        ToDo."No." := '';
        ToDo.Date := LibraryRandom.RandDate(10);
        ToDo.Duration := LibraryRandom.RandIntInRange(2, 10) * 1000 * 60 * 60 * 24;
        ToDo.Type := ToDo.Type::" ";
        ToDo.Insert();
    end;

    local procedure MockPurchVATEntryWithCountryCode(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup")
    var
        CountryRegion: Record "Country/Region";
    begin
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry."Posting Date" := WorkDate();
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry.Type := VATEntry.Type::Purchase;
        LibraryERM.CreateCountryRegion(CountryRegion);
        VATEntry."Country/Region Code" := CountryRegion.Code;
        VATEntry.Amount := LibraryRandom.RandDec(100, 2);
        VATEntry.Insert();
    end;

    local procedure CreateItemWithSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount")
    begin
        SalesLineDiscount.Init();
        SalesLineDiscount.Code := LibraryInventory.CreateItemNo();
        SalesLineDiscount.Type := SalesLineDiscount.Type::Item;
        SalesLineDiscount."Sales Type" := SalesLineDiscount."Sales Type"::"All Customers";
        SalesLineDiscount."Minimum Quantity" := LibraryRandom.RandIntInRange(10, 100);
        SalesLineDiscount.Insert(true);
    end;

    local procedure CreateSalesPrice(var SalesPrice: Record "Sales Price"; ItemNo: Code[20]; CustomerNo: Code[20])
    var
        SalesType: Enum "Sales Price Type";
    begin
        LibrarySales.CreateSalesPrice(
            SalesPrice, ItemNo, SalesType::Customer, CustomerNo, WorkDate(), '', '', '', 1, LibraryRandom.RandDecInRange(100, 200, 2));
    end;

    local procedure CreateSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; ItemNo: Code[20]; CustomerNo: Code[20])
    var
        SalesLineDiscountType: Enum "Sales Line Discount Type";
    begin
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, SalesLineDiscountType::Item, ItemNo, SalesLineDiscount."Sales Type"::Customer, CustomerNo,
            WorkDate(), '', '', '', 1);
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDecInRange(2, 7, 2));
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateGLAccountInventoryPostingSetup(var GLAccount: Record "G/L Account")
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount."Account Category" := GLAccount."Account Category"::Assets;
        GLAccount."Account Subcategory Entry No." :=
          GLAccountCategoryMgt.GetSubcategoryEntryNo(GLAccount."Account Category".AsInteger(), GLAccountCategoryMgt.GetInventory());
        GLAccount.Modify(true);
    end;

    local procedure EnqueueValuesAndRunFilteredPage(KeyValue: Variant; ActionValue: Integer; PageNo: Integer; RecVar: Variant)
    begin
        LibraryVariableStorage.Enqueue(ActionValue);
        LibraryVariableStorage.Enqueue(KeyValue);

        PAGE.Run(PageNo, RecVar);
    end;

    local procedure GetFirstMiddleKeyFieldValuesAndSetFilter(var KeyValueMiddle: Variant; var KeyValueFirst: Variant; var RecVar: Variant)
    var
        RecRefToFilter: RecordRef;
        RecRef: RecordRef;
        KeyRef: KeyRef;
        FieldRef: FieldRef;
        KeyValueLast: Variant;
    begin
        RecRef.GetTable(RecVar);

        RecRefToFilter.Open(RecRef.Number);
        KeyRef := RecRefToFilter.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);

        RecRefToFilter.FindFirst();
        KeyValueFirst := FieldRef.Value();
        RecRefToFilter.Next(RecRef.Count div 2);
        KeyValueMiddle := FieldRef.Value();
        RecRefToFilter.FindLast();
        KeyValueLast := FieldRef.Value();

        FieldRef := RecRef.Field(FieldRef.Number);
        FieldRef.SetRange(KeyValueFirst, KeyValueLast);

        RecRef.FindFirst();
        RecRef.SetTable(RecVar);

        KeyValueFirst := FieldRef.Value();
    end;

    local procedure GetMiddleKeyFieldValueAndSetFilter(var KeyValueMiddle: Variant; var RecVar: Variant)
    var
        RecRefToFilter: RecordRef;
        RecRef: RecordRef;
        KeyRef: KeyRef;
        FieldRef: FieldRef;
        KeyValueFirst: Variant;
        KeyValueLast: Variant;
    begin
        RecRef.GetTable(RecVar);

        RecRefToFilter.Open(RecRef.Number);
        KeyRef := RecRefToFilter.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);

        RecRefToFilter.FindFirst();
        KeyValueFirst := FieldRef.Value();
        RecRefToFilter.Next(RecRef.Count div 2);
        KeyValueMiddle := FieldRef.Value();
        RecRefToFilter.FindLast();
        KeyValueLast := FieldRef.Value();

        FieldRef := RecRef.Field(FieldRef.Number);
        FieldRef.SetRange(KeyValueMiddle, KeyValueMiddle);
        RecRef.FindFirst();
        FieldRef.SetRange(KeyValueFirst, KeyValueLast);

        RecRef.SetTable(RecVar);

        KeyValueFirst := FieldRef.Value();
    end;

    local procedure OpenPostedSalesShipment(var PostedSalesShipment: TestPage "Posted Sales Shipment"; SalesHeader: Record "Sales Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();

        PostedSalesShipment.OpenEdit();
        PostedSalesShipment.FILTER.SetFilter("No.", SalesShipmentHeader."No.");
        Assert.IsTrue(PostedSalesShipment.Editable(), 'Posted Sales Shipment page must be editable'); // BUG: 196378
    end;

    local procedure OpenPostedSalesInvoice(var PostedSalesInvoice: TestPage "Posted Sales Invoice"; SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();

        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");
        Assert.IsTrue(PostedSalesInvoice.Editable(), 'Posted Sales Invoice page must be editable'); // BUG: 196378
    end;

    local procedure OpenPostedSalesCrMemo(var PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo"; SalesHeader: Record "Sales Header")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();

        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");
        Assert.IsTrue(PostedSalesCreditMemo.Editable(), 'Posted Sales Credit Memo page must be editable'); // BUG: 196378
    end;

    local procedure OpenPostedReturnReceipt(var PostedReturnReceipt: TestPage "Posted Return Receipt"; SalesHeader: Record "Sales Header")
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        ReturnReceiptHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        ReturnReceiptHeader.FindFirst();

        PostedReturnReceipt.OpenEdit();
        PostedReturnReceipt.FILTER.SetFilter("No.", ReturnReceiptHeader."No.");
        Assert.IsTrue(PostedReturnReceipt.Editable(), 'Posted Return Receipt page must be editable'); // BUG: 196378
    end;

    local procedure OpenPostedPurchaseReceipt(var PostedPurchaseReceipt: TestPage "Posted Purchase Receipt"; PurchaseHeader: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptHeader.FindFirst();

        PostedPurchaseReceipt.OpenEdit();
        PostedPurchaseReceipt.FILTER.SetFilter("No.", PurchRcptHeader."No.");
        Assert.IsTrue(PostedPurchaseReceipt.Editable(), 'Posted Purchase Receipt page must be editable'); // BUG: 196378
    end;

    local procedure OpenPostedPurchaseInvoice(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice"; PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchInvHeader.FindFirst();

        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PurchInvHeader."No.");
        Assert.IsTrue(PostedPurchaseInvoice.Editable(), 'Posted Purchase Invoice page must be editable'); // BUG: 196378
    end;

    local procedure OpenPostedPurchaseCrMemo(var PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo"; PurchaseHeader: Record "Purchase Header")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchCrMemoHdr.FindFirst();

        PostedPurchaseCreditMemo.OpenEdit();
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", PurchCrMemoHdr."No.");
        Assert.IsTrue(PostedPurchaseCreditMemo.Editable(), 'Posted Purchase Credit Memo page must be editable'); // BUG: 196378
    end;

    local procedure OpenPostedReturnShipment(var PostedReturnShipment: TestPage "Posted Return Shipment"; PurchaseHeader: Record "Purchase Header")
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        ReturnShipmentHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        ReturnShipmentHeader.FindFirst();

        PostedReturnShipment.OpenEdit();
        PostedReturnShipment.FILTER.SetFilter("No.", ReturnShipmentHeader."No.");
        Assert.IsTrue(PostedReturnShipment.Editable(), 'Posted Return Shipment page must be editable'); // BUG: 196378
    end;

    local procedure OpenPurchaseOrderListWithPartialReceiveFilter(var PurchaseOrderListTestPage: TestPage "Purchase Order List"; Receive: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Completely Received", false);
        PurchaseHeader.SetRange(Receive, Receive);

        PurchaseOrderListTestPage.Trap();
        PAGE.Run(PAGE::"Purchase Order List", PurchaseHeader);
    end;

    local procedure OpenPurchaseOrderListWithPartialInvoiceFilter(var PurchaseOrderListTestPage: TestPage "Purchase Order List"; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Completely Received", true);
        PurchaseHeader.SetRange(Invoice, Invoice);

        PurchaseOrderListTestPage.Trap();
        PAGE.Run(PAGE::"Purchase Order List", PurchaseHeader);
    end;

    local procedure PostPurchaseDocumentWithLotTracking(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithTracking(), LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostSalesDocumentWithLotTracking(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithTracking(), LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure SetBasicUserExperience()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Basic));
    end;

    local procedure UpdateJobQueueActiveOnSalesSetup(PostWithQueue: Boolean; PostAndPrintWithQueue: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Post with Job Queue" := PostWithQueue;
        SalesReceivablesSetup."Post & Print with Job Queue" := PostAndPrintWithQueue;
        SalesReceivablesSetup.Modify();

        UpdateNoSeriesOnSalesSetup();
    end;

    local procedure UpdateJobQueueActiveOnPurchaseSetup(PostWithQueue: Boolean; PostAndPrintWithQueue: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Post with Job Queue" := PostWithQueue;
        PurchasesPayablesSetup."Post & Print with Job Queue" := PostAndPrintWithQueue;
        PurchasesPayablesSetup.Modify();

        UpdateNoSeriesOnPurchaseSetup();
    end;

    local procedure UpdateNoSeriesOnSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Return Order Nos." := LibraryERM.CreateNoSeriesCode();
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdateNoSeriesOnPurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Return Order Nos." := LibraryERM.CreateNoSeriesCode();
        PurchasesPayablesSetup.Modify();
    end;

    local procedure VerifyInventoryPostingSetupInserted(GLAccountNo: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.SetRange("Inventory Account (Interim)", GLAccountNo);
        Assert.RecordIsNotEmpty(InventoryPostingSetup);
    end;

    local procedure CreateContactWithSalesperson(var Contact: Record Contact)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Contact.Init();
        Contact."No." := LibraryUtility.GenerateGUID();
        Contact."Salesperson Code" := SalespersonPurchaser.Code;
        Contact.Insert();
    end;

    local procedure CreateInteractionTemplate(var InteractionTemplate: Record "Interaction Template")
    begin
        InteractionTemplate.Init();
        InteractionTemplate."Correspondence Type (Default)" := "Correspondence Type"::" ";
        InteractionTemplate.Code := LibraryUtility.GenerateGUID();
        InteractionTemplate.Insert(false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListMPH(var ItemList: TestPage "Item List")
    begin
        ItemList.Next();
        LibraryVariableStorage.Enqueue(ItemList."No.".Value);
        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListLookForItemMPH(var ItemList: TestPage "Item List")
    begin
        ItemList.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(ItemList.First());
        ItemList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListLookForItemOkMPH(var ItemList: TestPage "Item List")
    begin
        ItemList.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ItemList.First();
        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListCancelMPH(var ItemList: TestPage "Item List")
    begin
        ItemList.Next();
        LibraryVariableStorage.Enqueue(ItemList."No.".Value);
        ItemList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingMPH(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
        ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines."Quantity (Base)".AsDecimal() / 2);  // Partial Quantity.
        ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No for the new Line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesMPH(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
        PostedItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetEntriesMPH(var DimensionSetEntries: TestPage "Dimension Set Entries")
    begin
        DimensionSetEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceLinesMPH(var PostedSalesInvoiceLines: TestPage "Posted Sales Invoice Lines")
    begin
        PostedSalesInvoiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentLinesMPH(var PostedSalesShipmentLines: TestPage "Posted Sales Shipment Lines")
    begin
        PostedSalesShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesRetReceiptLinesMPH(var PostedReturnReceiptLines: TestPage "Posted Return Receipt Lines")
    begin
        PostedReturnReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoLinesMPH(var PostedSalesCreditMemoLines: TestPage "Posted Sales Credit Memo Lines")
    begin
        PostedSalesCreditMemoLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceLinesMPH(var PostedPurchaseInvoiceLines: TestPage "Posted Purchase Invoice Lines")
    begin
        PostedPurchaseInvoiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptLinesMPH(var PostedPurchaseReceiptLines: TestPage "Posted Purchase Receipt Lines")
    begin
        PostedPurchaseReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchRetShipmenttLinesMPH(var PostedReturnShipmentLines: TestPage "Posted Return Shipment Lines")
    begin
        PostedReturnShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseCrMemoLinesMPH(var PostedPurchaseCrMemoLines: TestPage "Posted Purchase Cr. Memo Lines")
    begin
        PostedPurchaseCrMemoLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesCommentSheetMPH(var SalesCommentSheet: TestPage "Sales Comment Sheet")
    begin
        SalesCommentSheet.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchCommentSheetMPH(var PurchCommentSheet: TestPage "Purch. Comment Sheet")
    begin
        PurchCommentSheet.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentsPageHandler(var PostedSalesShipments: TestPage "Posted Sales Shipments")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                PostedSalesShipments."No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                PostedSalesShipments."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        PostedSalesShipments.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicesPageHandler(var PostedSalesInvoices: TestPage "Posted Sales Invoices")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                PostedSalesInvoices."No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                PostedSalesInvoices."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        PostedSalesInvoices.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemosPageHandler(var PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                PostedSalesCreditMemos."No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                PostedSalesCreditMemos."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        PostedSalesCreditMemos.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedReturnReceiptsPageHandler(var PostedReturnReceipts: TestPage "Posted Return Receipts")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                PostedReturnReceipts."No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                PostedReturnReceipts."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        PostedReturnReceipts.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptsPageHandler(var PostedPurchaseReceipts: TestPage "Posted Purchase Receipts")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                PostedPurchaseReceipts."No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                PostedPurchaseReceipts."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        PostedPurchaseReceipts.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicesPageHandler(var PostedPurchaseInvoices: TestPage "Posted Purchase Invoices")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                PostedPurchaseInvoices."No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                PostedPurchaseInvoices."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        PostedPurchaseInvoices.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseCreditMemosPageHandler(var PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                PostedPurchaseCreditMemos."No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                PostedPurchaseCreditMemos."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        PostedPurchaseCreditMemos.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GeneralLedgerEntriesPageHandler(var GeneralLedgerEntries: TestPage "General Ledger Entries")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                GeneralLedgerEntries."Entry No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                GeneralLedgerEntries."Entry No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        GeneralLedgerEntries.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ResourceLedgerEntriesPageHandler(var ResourceLedgerEntries: TestPage "Resource Ledger Entries")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                ResourceLedgerEntries."Entry No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                ResourceLedgerEntries."Entry No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        ResourceLedgerEntries.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                CustomerLedgerEntries."Entry No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                CustomerLedgerEntries."Entry No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        CustomerLedgerEntries.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesPageHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                VendorLedgerEntries."Entry No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                VendorLedgerEntries."Entry No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        VendorLedgerEntries.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CheckLedgerEntriesPageHandler(var CheckLedgerEntries: TestPage "Check Ledger Entries")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                CheckLedgerEntries."Entry No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                CheckLedgerEntries."Entry No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        CheckLedgerEntries.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesPageHandler(var ItemLedgerEntries: TestPage "Item Ledger Entries")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            0:
                ItemLedgerEntries."Entry No.".SetValue(LibraryVariableStorage.DequeueText());
            1:
                ItemLedgerEntries."Entry No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        ItemLedgerEntries.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplListModalPageHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateTaskMultipleReassigningTypeModalPageHandler(var CreateTask: TestPage "Create Task")
    var
        Task: Record "To-do";
    begin
        // Assign Type = Meeting (attendees are set)
        CreateTask.TypeOnPrem.SetValue(Task.Type::Meeting);
        // Assign Type = Phone Call (attendees are refreshed)
        CreateTask.TypeOnPrem.SetValue(Task.Type::"Phone Call");
        // Assign Type = Meeting (attendees are set once more and should be cleared before resetting)
        CreateTask.TypeOnPrem.SetValue(Task.Type::Meeting);
        CreateTask.Description.SetValue(LibraryUtility.GenerateRandomXMLText(10));
        CreateTask."Start Time".SetValue(Time);
        CreateTask.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountListLookupPageHandler(var GLAccountList: TestPage "G/L Account List")
    begin
        GLAccountList.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        GLAccountList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostCodeFilterPageHandler(var PostCodes: TestPage "Post Codes")
    begin
        LibraryVariableStorage.Enqueue(PostCodes.FILTER.GetFilter("Country/Region Code"));
        PostCodes.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostCodeLookupOkPageHandler(var PostCodes: TestPage "Post Codes")
    begin
        PostCodes.FILTER.SetFilter(City, LibraryVariableStorage.DequeueText());
        PostCodes.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        PostCodes.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostCodeLookupCancelPageHandler(var PostCodes: TestPage "Post Codes")
    begin
        PostCodes.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemCardPageHandler(var ItemCard: TestPage "Item Card")
    begin
        LibraryVariableStorage.Enqueue(ItemCard."Qty. on Sales Order".Value);
        ItemCard.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJnlTemplateHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LookupTableID_Handler(var ObjectsPage: TestPage Objects)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TableID: Variant;
    begin
        LibraryVariableStorage.Dequeue(TableID);
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", TableID);
        AllObjWithCaption.FindFirst();
        ObjectsPage.GotoRecord(AllObjWithCaption);
        ObjectsPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeZoneLookup(var TimeZones: TestPage "Time Zones Lookup")
    begin
        TimeZones.FILTER.SetFilter(ID, LibraryVariableStorage.DequeueText());
        TimeZones.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyMinimumQuantityInSalesPriceAndLineDiscountsPageHandler(var SalesPrLineDisc: TestPage "Sales Price and Line Discounts")
    var
        DiscountCode: Code[20];
        MinimumQuantity: Decimal;
    begin
        DiscountCode := LibraryVariableStorage.DequeueText();
        MinimumQuantity := LibraryVariableStorage.DequeueDecimal();

        SalesPrLineDisc.Filter.SetFilter(Code, DiscountCode);
        SalesPrLineDisc."Minimum Quantity".AssertEquals(MinimumQuantity);
        SalesPrLineDisc.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SetSpecialPricesEnabledSalesPriceAndLineDiscountsModalPageHandler(var SalesPrLineDisc: TestPage "Sales Price and Line Discounts")
    begin
        LibraryVariableStorage.Enqueue(SalesPrLineDisc."Set Special Prices".Enabled());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        //MessageHandler
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LogSegmentHandler(var LogSegment: TestRequestPage "Log Segment")
    begin
        LogSegment.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementTemplateListModalPageHandler(var VATStatementTemplateList: TestPage "VAT Statement Template List")
    begin
        VATStatementTemplateList.Filter.SetFilter(Name, LibraryVariableStorage.DequeueText());
        VATStatementTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListPageHandler(var ContactList: TestPage "Contact List")
    begin
        ContactList.GoToKey(LibraryVariableStorage.DequeueText());
        ContactList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Message: Text[1024]; var Response: Boolean)
    begin
        Response := false;
    end;
}

