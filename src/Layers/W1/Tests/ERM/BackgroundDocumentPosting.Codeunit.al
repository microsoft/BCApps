codeunit 134893 "Background Document Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue] [Background Posting]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322727] Post Sales Invoice via Job Queue.
        Initialize();

        // [GIVEN] Sales Invoice.
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [WHEN] Post Sales Invoice via Job Queue.
        PostSalesDocumentViaJobQueue(SalesHeader);

        // [THEN] Posted Sales Invoice was created.
        VerifyPostedSalesInvoice(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322727] Post Sales Order via Job Queue.
        Initialize();

        // [GIVEN] Sales Order.
        CreateSalesOrder(SalesHeader);

        // [WHEN] Post Sales Order via Job Queue.
        PostSalesDocumentViaJobQueue(SalesHeader);

        // [THEN] Posted Sales Invoice was created.
        // [THEN] Posted Sales Shipment was created.
        VerifyPostedSalesOrder(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322727] Post Sales Credit Memo via Job Queue.
        Initialize();

        // [GIVEN] Sales Credit Memo.
        LibrarySales.CreateSalesCreditMemo(SalesHeader);

        // [WHEN] Post Sales Credit Memo via Job Queue.
        PostSalesDocumentViaJobQueue(SalesHeader);

        // [THEN] Posted Sales Credit Memo was created.
        VerifyPostedSalesCreditMemo(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322727] Post Sales Return Order via Job Queue.
        Initialize();

        // [GIVEN] Sales Return Order.
        CreateSalesReturnOrder(SalesHeader);

        // [WHEN] Post Sales Return Order via Job Queue.
        PostSalesDocumentViaJobQueue(SalesHeader);

        // [THEN] Posted Sales Credit Memo was created.
        // [THEN] Posted Retun Receipt was created.
        VerifyPostedSalesReturnOrder(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithError()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCopy: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322727] Post Sales Order via Job Queue in case an error is occured during posting.
        Initialize();

        // [GIVEN] Sales Order with blank "External Document No.".
        CreateSalesOrder(SalesHeader);
        SalesHeader."External Document No." := '';
        SalesHeader.Modify();
        SalesHeaderCopy := SalesHeader;

        // [WHEN] Post Sales Order via Job Queue.
        asserterror PostSalesDocumentViaJobQueue(SalesHeader);

        // [THEN] Sales Order was not posted.
        Assert.ExpectedError(StrSubstNo('%1 must have a value', SalesHeader.FieldCaption("External Document No.")));
        VerifySalesOrderNotPosted(SalesHeaderCopy);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderCancel()
    var
        SalesHeader: Record "Sales Header";
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322727] Cancel the Job Queue after scheduling Sales Order posting.
        Initialize();

        // [GIVEN] Sales Order, that is scheduled for posting via Job Queue "J".
        CreateSalesOrder(SalesHeader);
        CreateJobQueueEntryForPostingSalesDocument(SalesHeader, TempJobQueueEntry);

        // [WHEN] Remove Job Queue Entry "J".
        SalesPostViaJobQueue.CancelQueueEntry(SalesHeader);

        // [THEN] Job Queue Entry "J" was removed.
        // [THEN] Sales Order has "Job Queue Status" = ''.
        VerifyJobQueueForPostingSalesDocCancelled(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderShipOnly()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322727] Post Sales Order via Job Queue in case Ship = TRUE, Invoice = FALSE.
        Initialize();

        // [GIVEN] Sales Order with Ship = TRUE, Invoice = FALSE.
        CreateSalesOrder(SalesHeader);
        UpdateInvoiceShipReceiveOnSalesDocument(SalesHeader, false, true, false);

        // [WHEN] Post Sales Order via Job Queue.
        PostSalesDocumentViaJobQueue(SalesHeader);

        // [THEN] Sales Order was Shipped, but not Invoiced.
        VerifySalesOrderShippedNotInvoiced(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Post2StepsSalesOrderShipAndInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322727] Post Sales Order in two steps via Job Queue, first Ship, then Invoice.
        Initialize();

        // [GIVEN] Sales Order, that is Shipped, but not Invoiced.
        CreateSalesOrder(SalesHeader);
        UpdateInvoiceShipReceiveOnSalesDocument(SalesHeader, false, true, false);
        PostSalesDocumentViaJobQueue(SalesHeader);

        // [GIVEN] Invoice is set to TRUE for Sales Order.
        UpdateInvoiceShipReceiveOnSalesDocument(SalesHeader, true, false, false);

        // [WHEN] Post Sales Order via Job Queue.
        PostSalesDocumentViaJobQueue(SalesHeader);

        // [THEN] Posted Sales Invoice was created.
        VerifyPostedSalesOrder(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderReceiveOnly()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322727] Post Sales Return Order via Job Queue in case Receive = TRUE, Invoice = FALSE.
        Initialize();

        // [GIVEN] Sales Return Order with Receive = TRUE, Invoice = FALSE.
        CreateSalesReturnOrder(SalesHeader);
        UpdateInvoiceShipReceiveOnSalesDocument(SalesHeader, false, false, true);

        // [WHEN] Post Sales Order via Job Queue.
        PostSalesDocumentViaJobQueue(SalesHeader);

        // [THEN] Sales Return Order was Received, but not Invoiced.
        VerifySalesReturnOrderReceivedNotInvoiced(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Post2StepsSalesReturnOrderReceiveAndInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322727] Post Sales Return Order in two steps via Job Queue, first Receive, then Invoice.
        Initialize();

        // [GIVEN] Sales Return Order, that is Received, but not Invoiced.
        CreateSalesReturnOrder(SalesHeader);
        UpdateInvoiceShipReceiveOnSalesDocument(SalesHeader, false, false, true);
        PostSalesDocumentViaJobQueue(SalesHeader);

        // [GIVEN] Invoice is set to TRUE for Sales Return Order.
        UpdateInvoiceShipReceiveOnSalesDocument(SalesHeader, true, false, false);

        // [WHEN] Post Sales Retun Order via Job Queue.
        PostSalesDocumentViaJobQueue(SalesHeader);

        // [THEN] Posted Sales Invoice was created.
        VerifyPostedSalesReturnOrder(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 322727] Post Purchase Invoice via Job Queue.
        Initialize();

        // [GIVEN] Purchase Invoice.
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // [WHEN] Post Purchase Invoice via Job Queue.
        PostPurchaseDocumentViaJobQueue(PurchaseHeader);

        // [THEN] Posted Purchase Invoice was created.
        VerifyPostedPurchaseInvoice(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 322727] Post Purchase Order via Job Queue.
        Initialize();

        // [GIVEN] Purchase Order.
        CreatePurchaseOrder(PurchaseHeader);

        // [WHEN] Post Purchase Order via Job Queue.
        PostPurchaseDocumentViaJobQueue(PurchaseHeader);

        // [THEN] Posted Purchase Invoice was created.
        // [THEN] Posted Purchase Receipt was created.
        VerifyPostedPurchaseOrder(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 322727] Post Purchase Credit Memo via Job Queue.
        Initialize();

        // [GIVEN] Purchase Credit Memo.
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        // [WHEN] Post Purchase Credit Memo via Job Queue.
        PostPurchaseDocumentViaJobQueue(PurchaseHeader);

        // [THEN] Posted Purchase Credit Memo was created.
        VerifyPostedPurchaseCreditMemo(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 322727] Post Purchase Return Order via Job Queue.
        Initialize();

        // [GIVEN] Purchase Return Order.
        CreatePurchaseReturnOrder(PurchaseHeader);

        // [WHEN] Post Purchase Return Order via Job Queue.
        PostPurchaseDocumentViaJobQueue(PurchaseHeader);

        // [THEN] Posted Purchase Credit Memo was created.
        // [THEN] Posted Return Shipment was created.
        VerifyPostedPurchaseReturnOrder(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderCopy: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 322727] Post Purchase Order via Job Queue in case an error is occured during posting.
        Initialize();

        // [GIVEN] Purchase Order with blank "Vendor Invoice No.".
        CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader."Vendor Invoice No." := '';
        PurchaseHeader.Modify();
        PurchaseHeaderCopy := PurchaseHeader;

        // [WHEN] Post Purchase Order via Job Queue.
        asserterror PostPurchaseDocumentViaJobQueue(PurchaseHeader);

        // [THEN] Purchase Order was not posted.
        Assert.ExpectedError('You need to enter the document number');
        VerifyPurchaseOrderNotPosted(PurchaseHeaderCopy);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderCancel()
    var
        PurchaseHeader: Record "Purchase Header";
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        PurchasePostViaJobQueue: Codeunit "Purchase Post via Job Queue";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 322727] Cancel the Job Queue after scheduling Purchase Order posting.
        Initialize();

        // [GIVEN] Purchase Order, that is scheduled for posting via Job Queue "J".
        CreatePurchaseOrder(PurchaseHeader);
        CreateJobQueueEntryForPostingPurchaseDocument(PurchaseHeader, TempJobQueueEntry);

        // [WHEN] Remove Job Queue Entry "J".
        PurchasePostViaJobQueue.CancelQueueEntry(PurchaseHeader);

        // [THEN] Job Queue Entry "J" was removed.
        // [THEN] Purchase Order has "Job Queue Status" = ''.
        VerifyJobQueueForPostingPurchaseDocCancelled(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderReceiveOnly()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 322727] Post Purchase Order via Job Queue in case Receive = TRUE, Invoice = FALSE.
        Initialize();

        // [GIVEN] Purchase Order with Receive = TRUE, Invoice = FALSE.
        CreatePurchaseOrder(PurchaseHeader);
        UpdateInvoiceShipReceiveOnPurchaseDocument(PurchaseHeader, false, false, true);

        // [WHEN] Post Purchase Order via Job Queue.
        PostPurchaseDocumentViaJobQueue(PurchaseHeader);

        // [THEN] Purchase Order was Received, but not Invoiced.
        VerifyPurchaseOrderReceivedNotInvoiced(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Post2StepsPurchaseOrderReceiveAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 322727] Post Purchase Order in two steps via Job Queue, first Receive, then Invoice.
        Initialize();

        // [GIVEN] Purchase Order, that is Received, but not Invoiced.
        CreatePurchaseOrder(PurchaseHeader);
        UpdateInvoiceShipReceiveOnPurchaseDocument(PurchaseHeader, false, false, true);
        PostPurchaseDocumentViaJobQueue(PurchaseHeader);

        // [GIVEN] Invoice is set to TRUE for Purchase Order.
        UpdateInvoiceShipReceiveOnPurchaseDocument(PurchaseHeader, true, false, false);

        // [WHEN] Post Purchase Order via Job Queue.
        PostPurchaseDocumentViaJobQueue(PurchaseHeader);

        // [THEN] Posted Purchase Invoice was created.
        VerifyPostedPurchaseOrder(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderShipOnly()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 322727] Post Purchase Return Order via Job Queue in case Ship = TRUE, Invoice = FALSE.
        Initialize();

        // [GIVEN] Purchase Return Order with Ship = TRUE, Invoice = FALSE.
        CreatePurchaseReturnOrder(PurchaseHeader);
        UpdateInvoiceShipReceiveOnPurchaseDocument(PurchaseHeader, false, true, false);

        // [WHEN] Post Purchase Return Order via Job Queue.
        PostPurchaseDocumentViaJobQueue(PurchaseHeader);

        // [THEN] Purchase Return Order was Shipped, but not Invoiced.
        VerifyPurchaseReturnOrderShippedNotInvoiced(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Post2StepsPurchaseReturnOrderShipAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 322727] Post Purchase Return Order in two steps via Job Queue, first Ship, then Invoice.
        Initialize();

        // [GIVEN] Purchase Return Order, that is Shipped, but not Invoiced.
        CreatePurchaseReturnOrder(PurchaseHeader);
        UpdateInvoiceShipReceiveOnPurchaseDocument(PurchaseHeader, false, true, false);
        PostPurchaseDocumentViaJobQueue(PurchaseHeader);

        // [GIVEN] Invoice is set to TRUE for Purchase Return Order.
        UpdateInvoiceShipReceiveOnPurchaseDocument(PurchaseHeader, true, false, false);

        // [WHEN] Post Purchase Return Order via Job Queue.
        PostPurchaseDocumentViaJobQueue(PurchaseHeader);

        // [THEN] Posted Purchase Credit Memo was created.
        VerifyPostedPurchaseReturnOrder(PurchaseHeader);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Background Document Posting");
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Background Document Posting");
        UpdateSalesAndPurchaseSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        isInitialized := true;

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Background Document Posting");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.Invoice := true;
        SalesHeader.Ship := true;
        SalesHeader.Modify();
    end;

    local procedure CreateSalesReturnOrder(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', '', LibraryRandom.RandDecInRange(10, 20, 2), '', WorkDate());
        SalesHeader.Invoice := true;
        SalesHeader.Receive := true;
        SalesHeader.Modify();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.Invoice := true;
        PurchaseHeader.Receive := true;
        PurchaseHeader.Modify();
    end;

    local procedure CreatePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);
        PurchaseHeader.Invoice := true;
        PurchaseHeader.Ship := true;
        PurchaseHeader.Modify();
    end;

    local procedure CreateJobQueueEntryForPostingSalesDocument(var SalesHeader: Record "Sales Header"; var TempJobQueueEntry: Record "Job Queue Entry" temporary)
    var
        LibraryJobQueue: Codeunit "Library - Job Queue";
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
    begin
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        SalesPostViaJobQueue.EnqueueSalesDocWithUI(SalesHeader, false);

        SalesHeader.TestField("Job Queue Status", SalesHeader."Job Queue Status"::"Scheduled for Posting");

        LibraryJobQueue.GetCollectedJobQueueEntries(TempJobQueueEntry);
        Assert.RecordCount(TempJobQueueEntry, 1);
        TempJobQueueEntry.TestField("Object Type to Run", TempJobQueueEntry."Object Type to Run"::Codeunit);
        TempJobQueueEntry.TestField("Object ID to Run", CODEUNIT::"Sales Post via Job Queue");
    end;

    local procedure CreateJobQueueEntryForPostingPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var TempJobQueueEntry: Record "Job Queue Entry" temporary)
    var
        LibraryJobQueue: Codeunit "Library - Job Queue";
        PurchasePostViaJobQueue: Codeunit "Purchase Post via Job Queue";
    begin
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        PurchasePostViaJobQueue.EnqueuePurchDocWithUI(PurchaseHeader, false);

        PurchaseHeader.TestField("Job Queue Status", PurchaseHeader."Job Queue Status"::"Scheduled for Posting");

        LibraryJobQueue.GetCollectedJobQueueEntries(TempJobQueueEntry);
        Assert.RecordCount(TempJobQueueEntry, 1);
        TempJobQueueEntry.TestField("Object Type to Run", TempJobQueueEntry."Object Type to Run"::Codeunit);
        TempJobQueueEntry.TestField("Object ID to Run", CODEUNIT::"Purchase Post via Job Queue");
    end;

    local procedure PostSalesDocumentViaJobQueue(var SalesHeader: Record "Sales Header")
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        CreateJobQueueEntryForPostingSalesDocument(SalesHeader, TempJobQueueEntry);

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Background);
        BindSubscription(TestClientTypeSubscriber);
        CODEUNIT.Run(TempJobQueueEntry."Object ID to Run", TempJobQueueEntry);
    end;

    local procedure PostPurchaseDocumentViaJobQueue(var PurchaseHeader: Record "Purchase Header")
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        CreateJobQueueEntryForPostingPurchaseDocument(PurchaseHeader, TempJobQueueEntry);

        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Background);
        BindSubscription(TestClientTypeSubscriber);
        CODEUNIT.Run(TempJobQueueEntry."Object ID to Run", TempJobQueueEntry);
    end;

    local procedure UpdateSalesAndPurchaseSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchasesSetup: Record "Purchases & Payables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Post with Job Queue" := true;
        SalesSetup."Ext. Doc. No. Mandatory" := true;
        SalesSetup.Modify();

        PurchasesSetup.Get();
        PurchasesSetup."Post with Job Queue" := true;
        PurchasesSetup."Ext. Doc. No. Mandatory" := true;
        PurchasesSetup.Modify();
    end;

    local procedure UpdateInvoiceShipReceiveOnSalesDocument(var SalesHeader: Record "Sales Header"; Invoice: Boolean; Ship: Boolean; Receive: Boolean)
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.Invoice := Invoice;
        SalesHeader.Ship := Ship;
        SalesHeader.Receive := Receive;
        SalesHeader.Modify();
    end;

    local procedure UpdateInvoiceShipReceiveOnPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; Invoice: Boolean; Ship: Boolean; Receive: Boolean)
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Invoice := Invoice;
        PurchaseHeader.Ship := Ship;
        PurchaseHeader.Receive := Receive;
        PurchaseHeader.Modify();
    end;

    local procedure VerifyPostedSalesInvoice(SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);
    end;

    local procedure VerifyPostedSalesOrder(SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);

        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(SalesShipmentHeader);
    end;

    local procedure VerifyPostedSalesCreditMemo(SalesHeader: Record "Sales Header")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(SalesCrMemoHeader);
    end;

    local procedure VerifyPostedSalesReturnOrder(SalesHeader: Record "Sales Header")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        SalesCrMemoHeader.SetRange("Return Order No.", SalesHeader."No.");
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(SalesCrMemoHeader);

        ReturnReceiptHeader.SetRange("Return Order No.", SalesHeader."No.");
        ReturnReceiptHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(ReturnReceiptHeader);
    end;

    local procedure VerifySalesOrderNotPosted(SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsEmpty(SalesInvoiceHeader);

        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsEmpty(SalesShipmentHeader);
    end;

    local procedure VerifySalesOrderShippedNotInvoiced(SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsEmpty(SalesInvoiceHeader);

        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(SalesShipmentHeader);
    end;

    local procedure VerifySalesReturnOrderReceivedNotInvoiced(SalesHeader: Record "Sales Header")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");

        SalesCrMemoHeader.SetRange("Return Order No.", SalesHeader."No.");
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsEmpty(SalesCrMemoHeader);

        ReturnReceiptHeader.SetRange("Return Order No.", SalesHeader."No.");
        ReturnReceiptHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(ReturnReceiptHeader);
    end;

    local procedure VerifyPostedPurchaseInvoice(PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsNotEmpty(PurchInvHeader);
    end;

    local procedure VerifyPostedPurchaseOrder(PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsNotEmpty(PurchInvHeader);

        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsNotEmpty(PurchRcptHeader);
    end;

    local procedure VerifyPostedPurchaseCreditMemo(PurchaseHeader: Record "Purchase Header")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsNotEmpty(PurchCrMemoHdr);
    end;

    local procedure VerifyPostedPurchaseReturnOrder(PurchaseHeader: Record "Purchase Header")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        PurchCrMemoHdr.SetRange("Return Order No.", PurchaseHeader."No.");
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsNotEmpty(PurchCrMemoHdr);

        ReturnShipmentHeader.SetRange("Return Order No.", PurchaseHeader."No.");
        ReturnShipmentHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsNotEmpty(ReturnShipmentHeader);
    end;

    local procedure VerifyPurchaseOrderNotPosted(PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsEmpty(PurchInvHeader);

        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsEmpty(PurchRcptHeader);
    end;

    local procedure VerifyPurchaseOrderReceivedNotInvoiced(PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsEmpty(PurchInvHeader);

        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsNotEmpty(PurchRcptHeader);
    end;

    local procedure VerifyPurchaseReturnOrderShippedNotInvoiced(PurchaseHeader: Record "Purchase Header")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        PurchCrMemoHdr.SetRange("Return Order No.", PurchaseHeader."No.");
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsEmpty(PurchCrMemoHdr);

        ReturnShipmentHeader.SetRange("Return Order No.", PurchaseHeader."No.");
        ReturnShipmentHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordIsNotEmpty(ReturnShipmentHeader);
    end;

    local procedure VerifyJobQueueForPostingSalesDocCancelled(SalesHeader: Record "Sales Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange(ID, SalesHeader."Job Queue Entry ID");
        Assert.RecordIsEmpty(JobQueueEntry);

        SalesHeader.TestField("Job Queue Status", SalesHeader."Job Queue Status"::" ");
    end;

    local procedure VerifyJobQueueForPostingPurchaseDocCancelled(PurchaseHeader: Record "Purchase Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange(ID, PurchaseHeader."Job Queue Entry ID");
        Assert.RecordIsEmpty(JobQueueEntry);

        PurchaseHeader.TestField("Job Queue Status", PurchaseHeader."Job Queue Status"::" ");
    end;
}

