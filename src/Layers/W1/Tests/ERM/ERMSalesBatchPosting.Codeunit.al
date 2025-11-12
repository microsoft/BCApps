codeunit 134391 "ERM Sales Batch Posting"
{
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Batch Post] [Sales]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryVariableStorageCounter: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        BatchCompletedMsg: Label 'All of your selections were processed.';
        InterCompanyZipFileNamePatternTok: Label 'Sales IC Batch - %1.zip';
        GLInterCompanyZipFileNamePatternTok: Label 'General Journal IC Batch - %1.zip', Comment = '%1 - today date, Sample: Sales IC Batch - 23-01-2024.zip';
        NotificationMsg: Label 'An error or warning occured during operation Batch processing of Sales Header records.';
        DefaultCategoryCodeLbl: Label 'SALESBCKGR';
        NothingToPostErr: Label 'There is nothing to post because the document does not contain a quantity or amount.';
        SalesOrderStatusMsg: Label 'Sales Order Status must be released.';

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, false);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Invoice Exists.
        VerifyPostedSalesInvoice(SalesHeader."No.", SalesHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoiceDiffPostingDate()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, false);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", CalcDate('<1D>', WorkDate()), false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Invoice Exists.
        VerifyPostedSalesInvoice(SalesHeader."No.", CalcDate('<1D>', WorkDate()), false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoiceCalcInvDisc()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, true);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Invoice Exists.
        VerifyPostedSalesInvoice(SalesHeader."No.", SalesHeader."Posting Date", true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoiceCalcInvDiscAndReplacePostingDate()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 204056] Batch Posting of Sales Invoice with Replace Posting Date and Calc. Inv. Discount options for special Sales Setup
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Sales Setup has "Posted Invoice Nos." = "Invoice Nos." and "Shipment on Invoice" = No
        UpdateShipmentOnInvoiceOnSalesReceivablesSetup();

        // [GIVEN] Released Sales Invoice with posting nos are already assigned
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Run Batch Post Sales Invoice with Replace Posting Date, Replace Document Date, Calc. Inv. Discount options
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Posting Date" + 1, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] InvoiceDiscount is calculated and Posting Date is updated
        VerifyPostedSalesInvoice(SalesHeader."No.", SalesHeader."Posting Date" + 1, true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoices()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::Invoice, false);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader2.RecordId);

        // Verify that Posted Sales Invoice Exists.
        VerifyPostedSalesInvoice(SalesHeader."No.", SalesHeader."Posting Date", false);
        VerifyPostedSalesInvoice(SalesHeader2."No.", SalesHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Credit Memo.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);

        // Batch Post Sales Credit Memo.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Credit Memo Exists.
        VerifyPostedSalesCrMemo(SalesHeader."No.", SalesHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCrMemoDiffPostingDate()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", CalcDate('<1D>', WorkDate()), false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Credit Memo Exists.
        VerifyPostedSalesCrMemo(SalesHeader."No.", CalcDate('<1D>', WorkDate()), false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCrMemoCalcInvDisc()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", true);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // Verify that Posted Sales Credit Memo Exists.
        VerifyPostedSalesCrMemo(SalesHeader."No.", SalesHeader."Posting Date", true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCrMemos()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Sales Credit Memo.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::"Credit Memo", false);

        // Batch Post Sales Credit Memo.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader2.RecordId);

        // Verify that Posted Sales Credit Memo Exists.
        VerifyPostedSalesCrMemo(SalesHeader."No.", SalesHeader."Posting Date", false);
        VerifyPostedSalesCrMemo(SalesHeader2."No.", SalesHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoicesWithApprovals()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release Sales Invoice.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        // Create a sales invoice.
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::Invoice, false);

        // Batch Post Sales Invoice.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        VerifySalesHeaderNotification();

        // Verify that Posted Sales Invoice Exists.
        VerifyPostedSalesInvoice(SalesHeader."No.", SalesHeader."Posting Date", false);
        asserterror VerifyPostedSalesInvoice(SalesHeader2."No.", SalesHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter();

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesCrMemos,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesCrMemosWithApprovals()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release Sales cr. memo.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesCreditMemoApprovalWorkflowCode());

        // Create a sales cr. memo.
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::"Credit Memo", false);

        // Batch Post Sales cr. memo.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        VerifySalesHeaderNotification();

        // Verify that Posted Sales cr. memo Exists.
        VerifyPostedSalesCrMemo(SalesHeader."No.", SalesHeader."Posting Date", false);
        asserterror VerifyPostedSalesCrMemo(SalesHeader2."No.", SalesHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter();

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrders,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrdersWithApprovals()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release Sales order.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // Create a sales order.
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::Order, false);

        // Batch Post Sales Order.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        VerifySalesHeaderNotification();

        // Verify that Posted Sales Order Exists.
        VerifyPostedSalesOrder(SalesHeader."No.", SalesHeader."Posting Date", false);
        asserterror VerifyPostedSalesOrder(SalesHeader2."No.", SalesHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter();

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesReturnOrders,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesReturnOrdersWithApprovals()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        // Create and release Sales return order.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesReturnOrderApprovalWorkflowCode());

        // Create a sales return order.
        CreateSalesDocument(SalesHeader2, SalesHeader."Document Type"::"Return Order", false);

        // Batch Post Sales return order.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No." + '|' + SalesHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        VerifySalesHeaderNotification();

        // Verify that Posted Sales return order Exists.
        VerifyPostedSalesReturnOrder(SalesHeader."No.", SalesHeader."Posting Date", false);
        asserterror VerifyPostedSalesReturnOrder(SalesHeader2."No.", SalesHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter();

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrders,CountingMessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrderWithInvoiceDiscountAndJobQueue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        Index: Integer;
    begin
        // [FEATURE] [Order] [Job  Queue] [Invoice Discount]
        // [SCENARIO 268223] Stan can post with job queue multiple orders in a batch when "Calc. Invoice Discount" is turned on
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Sales setup with enabled "Calc. Invoice Discount" and "Post with Job Queue"
        LibraryVariableStorageCounter.Clear();
        LibraryWorkflow.DisableAllWorkflows();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Two purchase orders
        for Index := 1 to ArrayLen(SalesHeader) do
            CreateSalesDocument(SalesHeader[Index], SalesHeader[Index]."Document Type"::Order, true);

        // [WHEN] Post them via "Batch Post Sales Orders" report
        RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, true);

        // [THEN] Two Job Queue Entries created and their ID stored in orders
        for Index := 1 to ArrayLen(SalesHeader) do begin
            SalesHeader[Index].Find();
            SalesHeader[Index].TestField("Job Queue Entry ID");
        end;

        // [THEN] Messages of Job Queue Entry creation have been omitted
        Assert.ExpectedMessage(Format(BatchCompletedMsg), LibraryVariableStorageCounter.DequeueText());
        LibraryVariableStorageCounter.AssertEmpty();

        // [THEN] Invoices has been posted after queues execution
        for Index := 1 to ArrayLen(SalesHeader) do begin
            RunJobQueueFromSalesHeader(SalesHeader[Index]);
            VerifyPostedSalesInvoiceByOrderNo(SalesHeader[Index]."No.", SalesHeader[Index]."Posting Date", true);
        end;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrders,ShowErrorsNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostRetrySalesOrderWithJobQueueAndZeroQuantity()
    var
        SalesHeader: array[2] of Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        ErrorMessages: TestPage "Error Messages";
        Index: Integer;
        NullGUID: Guid;
    begin
        // [FEATURE] [Order] [Job  Queue]
        // [SCENARIO 275869] Stan can try post with job queue multiple time bad orders without error 'Batch Processing Parameter Map already exists.'
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Sales setup with enabled "Calc. Invoice Discount" and "Post with Job Queue"
        LibraryVariableStorageCounter.Clear();
        LibraryWorkflow.DisableAllWorkflows();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Two purchase orders
        for Index := 1 to ArrayLen(SalesHeader) do
            CreateSalesDocumentWithQuantity(SalesHeader[Index], SalesHeader[Index]."Document Type"::Order, false, 0);

        // [WHEN] Post two times them via "Batch Post Sales Orders" report

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        // [THEN] Click on 'Details' action: opened "Error Messages" page with list of bad documents each time
        for Index := 1 to ArrayLen(SalesHeader) do begin
            ErrorMessages.Trap();
            RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, true);
            VerifySalesHeaderNotification();
            LibraryNotificationMgt.RecallNotificationsForRecordID(SalesHeader[1].RecordId);

            // Bug: 306600
            ErrorMessages.Source.AssertEquals(Format(SalesHeader[1].RecordId));
            ErrorMessages.Next();
            ErrorMessages.Source.AssertEquals(Format(SalesHeader[2].RecordId));
            ErrorMessages.Close();
        end;

        // [THEN] Job Queue Entries are not created.
        for Index := 1 to ArrayLen(SalesHeader) do begin
            SalesHeader[Index].Find();
            SalesHeader[Index].TestField("Job Queue Entry ID", NullGUID);
        end;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoiceWithConcurrentBatch()
    var
        SalesHeader: Record "Sales Header";
        BatchProcessingParameter: Record "Batch Processing Parameter";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        BatchID: array[2] of Guid;
        BatchSessionID: array[2] of Integer;
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 306600] Stan can run "Batch Post Sales Invoices" report when concurrent batch is active having the same document
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        BatchSessionID[1] := SessionId();
        BatchSessionID[2] := SessionId() - 1;

        PostingDate[1] := WorkDate() - 1;
        PostingDate[2] := WorkDate();

        BatchID[1] := CreateGuid();
        BatchID[2] := CreateGuid();

        // [GIVEN] Sales invoice "I" to be posted via batch
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, false);

        // [GIVEN] Batch "B[1]" processing "I". Batch is lost in current session. Parameter "Posting Date" = March 1st, 2019.
        AddBatchProcessParameters(
          SalesHeader, "Batch Posting Parameter Type"::"Posting Date", PostingDate[1], BatchSessionID[1], BatchID[1]);

        // [GIVEN] Batch "B[2]" processing "I". Batch is live in other session. Parameter "Posting Date" = March 1st, 2019.
        AddBatchProcessParameters(
          SalesHeader, "Batch Posting Parameter Type"::"Posting Date", PostingDate[1], BatchSessionID[2], BatchID[2]);

        // [WHEN] Stan run "Batch Post Sales Invoices" report with "Replace Posting Date" = TRUE and "Posting Date" = March 2nd, 2019 and "I" in filter
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", PostingDate[2], true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] "I" is posted with "Posting Date" = March 2nd, 2019.
        VerifyPostedSalesInvoice(SalesHeader."No.", PostingDate[2], false);

        // [THEN] "B[1]" removed
        VerifyBatchParametersDoNoExist(BatchID[1]);

        // [THEN] "B[2]" remains unchanged
        VerifyBatchParametersExist(BatchID[2]);

        // [THEN] "Batch Processing Parameter" table empty after cleaning B[2]
        BatchProcessingParameter.SetRange("Batch ID", BatchID[2]);
        BatchProcessingParameter.DeleteAll();

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPostAndPrintWithJobQueueSalesSetupUT()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] "Post with Job Queue" is TRUE when "Post & Print with Job Queue" enabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = FALSE, "Post & Print with Job Queue" = FALSE
        LibrarySales.SetPostWithJobQueue(false);
        LibrarySales.SetPostAndPrintWithJobQueue(false);
        SalesReceivablesSetup.Get();
        // [WHEN] Set "Post & Print with Job Queue" = TRUE
        SalesReceivablesSetup.Validate("Post & Print with Job Queue", true);
        // [THEN] "Post with Job Queue" = TRUE
        Assert.IsTrue(SalesReceivablesSetup."Post with Job Queue", 'Setup is not correct.');

    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResetPostWithJobQueueSalesSetupUT()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] "Post & Print with Job Queue" is FALSE when "Post with Job Queue" is disabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = TRUE, "Post & Print with Job Queue" = TRUE
        LibrarySales.SetPostWithJobQueue(true);
        LibrarySales.SetPostAndPrintWithJobQueue(true);
        SalesReceivablesSetup.Get();
        // [WHEN] Set "Post with Job Queue" = FALSE
        SalesReceivablesSetup.Validate("Post with Job Queue", false);
        // [THEN] "Post & Print with Job Queue" = FALSE
        Assert.IsFalse(SalesReceivablesSetup."Post & Print with Job Queue", 'Setup is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPrintReportOutputTypeInSaaSSalesSetupUT()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] Set "Report Output Type" = Print in SaaS
        Initialize();

        // [GIVEN] SaaS, Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SalesReceivablesSetup.Get();
        // [WHEN] Set "Report Output Type" = Print
        asserterror SalesReceivablesSetup.Validate("Report Output Type", SalesReceivablesSetup."Report Output Type"::Print);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        // [THEN] Error, "Report Output Type" must be PDF
        Assert.ExpectedTestFieldError(SalesReceivablesSetup.FieldCaption("Report Output Type"), Format(SalesReceivablesSetup."Report Output Type"::PDF));
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesInvoicesPrintRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintBatchPostSalesInvoices()
    var
        SalesHeader: array[2] of Record "Sales Header";
    begin
        // [FEATURE] [Print]
        // [SCENARIO 267099] Print "Standard Sales - Invoice" when batch post sales invoices
        Initialize();
        LibrarySales.SetPostWithJobQueue(false);
        CreateInvoiceReportSelection();

        // [GIVEN] Two sales invoices
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Batch post two sales invoices (set Print = TRUE in BatchPostSalesInvoicesPrintRequestPageHandler)
        RunBatchPostSales(
          SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);

        // [THEN] 'Print' checkbox is not visible, so number "Sales - Invoice" report runs = 0 (calculated in StandardSalesInvoiceReportHandler)
        Assert.AreEqual(0, LibraryVariableStorage.DequeueInteger(), 'Number of printed invoice is not correct');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Print checkbox should not be invisible');
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesInvoicesPrintRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintBatchPostSalesInvoicesBackground()
    var
        SalesHeader: array[2] of Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [FEATURE] [Print]
        // [SCENARIO 267099] Print "Standard Sales - Invoice" when batch post sales invoices in background
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        LibrarySales.SetPostAndPrintWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        CreateInvoiceReportSelection();

        // [GIVEN] Two sales invoices
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Batch post two sales invoices (set Print = TRUE in BatchPostSalesInvoicesPrintRequestPageHandler)
        RunBatchPostSales(
          SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[1].RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[2].RecordId);

        // [THEN] There are two records in the "Job Queue Entry" with "PDF" output type
        VerifyPrintJobQueueEntries(SalesHeader);
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Print checkbox should be visible');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoiceCalcInvDiscAndReplacePostingDateJobQueue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Job Queue]
        // [SCENARIO 316670] Batch Posting of Sales Invoice with "Replace Posting Date", "Calc. Inv. Discount" and "backgroud posting" in Purchase Setup
        Initialize();

        // [GIVEN] Sales Setup with "Calc. Inv. Discount" = TRUE;
        UpdateCalcInvDiscSalesReceivablesSetup(true);

        // [GIVEN] "Post & Print with Job Queue" and "Post with Job Queue" enabled in Sales setup
        LibrarySales.SetPostAndPrintWithJobQueue(true);
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Released Sales Invoice "A"
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, true);
        PostingDate[1] := SalesHeader[1]."Posting Date";
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);

        // [GIVEN] "Batch Post Sales Invoice" report ran with Replace Posting Date, Replace Document Date, Calc. Inv. Discount options
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);
        RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No.", PostingDate[1] + 1, true);

        // [GIVEN] "Post & Print with Job Queue" and "Post with Job Queue" disabled in Sales setup
        LibrarySales.SetPostAndPrintWithJobQueue(false);
        LibrarySales.SetPostWithJobQueue(false);

        // [GIVEN] Released Sales Invoice "B" and post via Batch Postig without background job
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, true);
        PostingDate[2] := SalesHeader[2]."Posting Date";
        LibrarySales.ReleaseSalesDocument(SalesHeader[2]);
        SalesHeader[2].SetRecFilter();
        RunBatchPostSales(SalesHeader[2]."Document Type", SalesHeader[2]."No.", PostingDate[2] + 2, true);

        // [GIVEN] Job Queue Entries created for Invoice 'A'. 
        SalesHeader[1].Find();
        JobQueueEntry.Get(SalesHeader[1]."Job Queue Entry ID");

        // [WHEN] Run Job Queue Entries for Invoice "A"
        CODEUNIT.Run(JobQueueEntry."Object ID to Run", JobQueueEntry);

        // [THEN] Invoice 'B' is posted directly. 
        Assert.IsFalse(SalesHeader[2].Find(), 'Second Invoice should be posted');

        // [THEN] InvoiceDiscount is calculated and Posting Date is updated in Invoices "A"
        VerifyPostedSalesInvoice(SalesHeader[1]."No.", PostingDate[1] + 1, true);
        // [THEN] InvoiceDiscount is calculated and Posting Date is updated in Invoice "B"
        VerifyPostedSalesInvoice(SalesHeader[2]."No.", PostingDate[2] + 2, true);

        // [THEN] Batch Processing Map Table cleaned after job queue execution
        BatchProcessingSessionMap.SetRange("Record ID", SalesHeader[1].RecordId);
        Assert.RecordIsEmpty(BatchProcessingSessionMap);

        BatchProcessingSessionMap.SetRange("Record ID", SalesHeader[2].RecordId);
        Assert.RecordIsEmpty(BatchProcessingSessionMap);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    procedure BatchPostInvoices_OneJobQueue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 355799] Batch posting invoices via one job queue
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Two invoices
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Post batch
        RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(SalesHeader[1]);

        // [THEN] All invoices are posted
        VerifyPostedSalesInvoice(SalesHeader[1]."No.", SalesHeader[1]."Posting Date", false);
        VerifyPostedSalesInvoice(SalesHeader[2]."No.", SalesHeader[2]."Posting Date", false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrders,MessageHandler')]
    procedure BatchPostOrders_OneJobQueue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 355799] Batch posting orders via one job queue
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Two orders
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Order, false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Order, false);

        // [WHEN] Post batch
        RunBatchPostSales(SalesHeader[2]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(SalesHeader[1]);

        // [THEN] All orders are posted
        VerifyPostedSalesOrder(SalesHeader[1]."No.", SalesHeader[1]."Posting Date", false);
        VerifyPostedSalesOrder(SalesHeader[2]."No.", SalesHeader[2]."Posting Date", false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesCrMemos,MessageHandler')]
    procedure BatchPostCreditMemos_OneJobQueue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 355799] Batch posting credit memos via one job queue
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Two credit memos
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::"Credit Memo", false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::"Credit Memo", false);

        // [WHEN] Post batch
        RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(SalesHeader[1]);

        // [THEN] All credit memos are posted
        VerifyPostedSalesCrMemo(SalesHeader[1]."No.", SalesHeader[1]."Posting Date", false);
        VerifyPostedSalesCrMemo(SalesHeader[2]."No.", SalesHeader[2]."Posting Date", false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesReturnOrders,MessageHandler')]
    procedure BatchPostReturnOrders_OneJobQueue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 355799] Batch posting return orders via one job queue
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Two return orders
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::"Return Order", false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::"Return Order", false);

        // [WHEN] Post batch
        RunBatchPostSales(SalesHeader[2]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(SalesHeader[1]);

        // [THEN] All return orders are posted
        VerifyPostedSalesReturnOrder(SalesHeader[1]."No.", SalesHeader[1]."Posting Date", false);
        VerifyPostedSalesReturnOrder(SalesHeader[2]."No.", SalesHeader[2]."Posting Date", false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    procedure BatchPostInvoicesWithEmptyJobQueueCategoryCode_OneJobQueue()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: array[2] of Record "Sales Header";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        JobQueueEntryId: Guid;
    begin
        // [SCENARIO 355799] Batch posting invoices via one job queue with empty "Job Queue Category Code" in the setup
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled, "Job Queue Category Code" is empty
        LibrarySales.SetPostWithJobQueue(true);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Job Queue Category Code" := '';
        SalesReceivablesSetup.Modify();

        // [GIVEN] Two invoices
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Post batch
        RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(SalesHeader[1]);
        JobQueueEntryId := SalesHeader[1]."Job Queue Entry ID";

        // [THEN] Job queue log entry contains default "Job Queue Category Code"
        JobQueueLogEntry.SetRange(ID, JobQueueEntryId);
        JobQueueLogEntry.FindFirst();
        Assert.IsTrue(JobQueueLogEntry."Job Queue Category Code" = DefaultCategoryCodeLbl, 'Job queue log entry has wrong Job Queue Category Code');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,SentNotificationHandler')]
    procedure BatchPostInvoicesOneWithErrorBeforePosting_OneJobQueue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 355799] Batch posting invoices via one job queue, one invoice has "Job Queue Status" = "Scheduled for Posting"
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Two invoices: I1 and I2, I2 has "Job Queue Status" = "Scheduled for Posting"
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, false);
        SalesHeader[2]."Job Queue Status" := SalesHeader[2]."Job Queue Status"::"Scheduled for Posting";
        SalesHeader[2].Modify();

        // [WHEN] Post batch
        RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(SalesHeader[1]);

        // [THEN] I1 is posted
        VerifyPostedSalesInvoice(SalesHeader[1]."No.", SalesHeader[1]."Posting Date", false);

        // [THEN] I2 is not posted
        SalesHeader[2].Get(SalesHeader[2]."Document Type", SalesHeader[2]."No.");

        // [THEN] Notification: 'An error occured during operation: batch processing of Sales Header records.'
        VerifySalesHeaderNotification();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    procedure BatchPostInvoicesOneWithErrorWhilePosting_OneJobQueue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ErrorMessage: Record "Error Message";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        JobQueueEntryId: Guid;
    begin
        // [SCENARIO 355799] Batch posting invoices via one job queue, one invoice has error while posting
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Two invoices: I1 and I2, I2 has empty "Posting Date"
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, false);
        Codeunit.Run(Codeunit::"Release Sales Document", SalesHeader[2]);
        SalesHeader[2]."Posting Date" := 0D;
        SalesHeader[2].Modify();

        // [WHEN] Post batch
        RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(SalesHeader[1]);
        JobQueueEntryId := SalesHeader[1]."Job Queue Entry ID";

        // [THEN] I1 is posted
        VerifyPostedSalesInvoice(SalesHeader[1]."No.", SalesHeader[1]."Posting Date", false);

        // [THEN] I2 is not posted, "Job Queue Status" = "Error"
        SalesHeader[2].Get(SalesHeader[2]."Document Type", SalesHeader[2]."No.");
        Assert.IsTrue(SalesHeader[2]."Job Queue Status" = SalesHeader[2]."Job Queue Status"::Error, 'Sales header has wrong Job Queue Status');

        // [THEN] Job queue log entry "Status" = "Error", "Error Message" contains error message about I2 "Posting Date"
        JobQueueLogEntry.SetRange(ID, JobQueueEntryId);
        JobQueueLogEntry.FindFirst();
        Assert.IsTrue(JobQueueLogEntry.Status = JobQueueLogEntry.Status::Error, 'Job queue log entry has wrong status');
        Assert.AreEqual('1 sales documents out of 2 have errors during posting.', JobQueueLogEntry."Error Message", 'Job queue log entry has wrong error message');

        // [THEN] Error message register contains one record
        ErrorMessage.SetRange("Register ID", JobQueueLogEntry."Error Message Register Id");
        Assert.RecordCount(ErrorMessage, 1);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesInvoicesPrintRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostAndPrintInvoices_OneJobQueue()
    var
        SalesHeader: array[2] of Record "Sales Header";
        ReportInbox: Record "Report Inbox";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        JobQueueEntryId: Guid;
    begin
        // [SCENARIO 355799] Batch posting and printing invoices via one job queue
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);
        CreateInvoiceReportSelection();

        // [GIVEN] Post and print with job queue is enabled
        LibrarySales.SetPostAndPrintWithJobQueue(true);

        // [GIVEN] Two invoices
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Post batch
        RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(SalesHeader[1]);
        JobQueueEntryId := SalesHeader[1]."Job Queue Entry ID";

        // [THEN] All invoices are posted
        VerifyPostedSalesInvoice(SalesHeader[1]."No.", SalesHeader[1]."Posting Date", false);
        VerifyPostedSalesInvoice(SalesHeader[2]."No.", SalesHeader[2]."Posting Date", false);

        // [THEN] All invoices are printed as PDF to Report Inbox
        ReportInbox.SetRange("Job Queue Log Entry ID", JobQueueEntryId);
        Assert.RecordCount(ReportInbox, 2);
        ReportInbox.FindFirst();
        Assert.IsTrue(StrPos(ReportInbox.Description, StrSubstNo('Print Sales Invoice No. %1', SalesHeader[1]."No.")) > 0, 'Report Inbox contains wrong printed document');
        ReportInbox.Next();
        Assert.IsTrue(StrPos(ReportInbox.Description, StrSubstNo('Print Sales Invoice No. %1', SalesHeader[2]."No.")) > 0, 'Report Inbox contains wrong printed document');
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesInvoicesPrintRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostInvoicesWithAnalysisView()
    var
        SalesHeader: array[2] of Record "Sales Header";
        AnalysisView: Record "Analysis View";
        ERMAnalysisView: Codeunit "ERM Analysis View";
        AnalysisAccountSource: Enum "Analysis Account Source";
        LastEntryNo: Integer;
        i: Integer;
    begin
        // [SCENARIO] Batch posting updates Analysis Views
        Initialize();
        ERMAnalysisView.CreateAnalysisViewWithDimensions(AnalysisView, AnalysisAccountSource::"G/L Account");
        AnalysisView."Update on Posting" := true;
        AnalysisView.Modify();
        Commit();
        LastEntryNo := AnalysisView."Last Entry No.";

        // [GIVEN] Two invoices
        CreateSalesDocument(SalesHeader[1], SalesHeader[1]."Document Type"::Invoice, false);
        CreateSalesDocument(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Post batch
        RunBatchPostSales(SalesHeader[1]."Document Type", SalesHeader[1]."No." + '|' + SalesHeader[2]."No.", 0D, false);
        AnalysisView.Get(AnalysisView.Code);
        while (i < 10) and (LastEntryNo = AnalysisView."Last Entry No.") do begin  // may be executed in background
            i += 1;
            AnalysisView.Get(AnalysisView.Code);
            Sleep(1000 * i);
        end;
        if i >= 10 then
            Error('Analysis View is not updated after 10 waits.');
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStaticsUpdateVATAmountModalPageHandler,RequestPageHandlerBatchPostSalesInvoices')]
    procedure BatchPostSalesInvoiceWithVATDifference()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoicePage: TestPage "Sales Invoice";
        MaxAllowedVATDifference: Decimal;
        VATModifier: Decimal;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 385771] Stan can preview and run batch posting with invoice having VAT Difference
        Initialize();

        MaxAllowedVATDifference := LibraryRandom.RandIntInRange(2, 10);
        VATModifier := Round(-MaxAllowedVATDifference / 2);

        LibrarySales.SetAllowVATDifference(true);
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Modify(true);

        LibraryVariableStorage.Enqueue(VATModifier);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoicePage.Statistics.Invoke();

        SalesInvoicePage.Next();
        SalesInvoicePage.SalesLines."Total Amount Incl. VAT".AssertEquals(
          SalesLine."Amount Including VAT" + VATModifier);

        SalesInvoicePage.Close();

        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, false);

        SalesHeader.SetRecFilter();

        Assert.RecordIsEmpty(SalesHeader);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStaticsUpdateVATAmountModalPageHandler,RequestPageHandlerBatchPostSalesInvoices')]
    procedure BatchPostSalesInvoiceWithVATDifferenceAndPriceInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoicePage: TestPage "Sales Invoice";
        MaxAllowedVATDifference: Decimal;
        VATModifier: Decimal;
    begin
        // [FEATURE] [Invoice] [Price Including VAT]
        // [SCENARIO 385771] Stan can preview and run batch posting with invoice having VAT Difference and "Price Including VAT" = TRUE
        Initialize();

        MaxAllowedVATDifference := LibraryRandom.RandIntInRange(2, 10);
        VATModifier := Round(-MaxAllowedVATDifference / 2);

        LibrarySales.SetAllowVATDifference(true);
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Modify(true);

        LibraryVariableStorage.Enqueue(VATModifier);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoicePage.Statistics.Invoke();
        SalesInvoicePage.Close();

        SalesLine.Find();
        SalesLine.TestField(Amount, Round(SalesLine."Unit Price" / (1 + SalesLine."VAT %" / 100)) - VATModifier);


        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, false);

        SalesHeader.SetRecFilter();

        Assert.RecordIsEmpty(SalesHeader);
    end;
#endif

    [Test]
    [HandlerFunctions('SalesStaticsUpdateVATAmountPageHandler,RequestPageHandlerBatchPostSalesInvoices')]
    procedure BatchPostSalesInvoiceWithVATDifferenceNonModal()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoicePage: TestPage "Sales Invoice";
        MaxAllowedVATDifference: Decimal;
        VATModifier: Decimal;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 385771] Stan can preview and run batch posting with invoice having VAT Difference
        Initialize();

        MaxAllowedVATDifference := LibraryRandom.RandIntInRange(2, 10);
        VATModifier := Round(-MaxAllowedVATDifference / 2);

        LibrarySales.SetAllowVATDifference(true);
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Modify(true);

        LibraryVariableStorage.Enqueue(VATModifier);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.GoToRecord(SalesHeader);
        SalesInvoicePage.SalesStatistics.Invoke();
        SalesInvoicePage.Close();

        SalesInvoicePage.OpenView();
        SalesInvoicePage.GoToRecord(SalesHeader);
        SalesInvoicePage.SalesLines."Total Amount Incl. VAT".AssertEquals(SalesLine."Amount Including VAT" + VATModifier);

        SalesInvoicePage.Close();

        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, false);

        SalesHeader.SetRecFilter();

        Assert.RecordIsEmpty(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('SalesStaticsUpdateVATAmountPageHandler,RequestPageHandlerBatchPostSalesInvoices')]
    procedure BatchPostSalesInvoiceWithVATDifferenceAndPriceInclVATNonModal()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoicePage: TestPage "Sales Invoice";
        MaxAllowedVATDifference: Decimal;
        VATModifier: Decimal;
    begin
        // [FEATURE] [Invoice] [Price Including VAT]
        // [SCENARIO 385771] Stan can preview and run batch posting with invoice having VAT Difference and "Price Including VAT" = TRUE
        Initialize();

        MaxAllowedVATDifference := LibraryRandom.RandIntInRange(2, 10);
        VATModifier := Round(-MaxAllowedVATDifference / 2);

        LibrarySales.SetAllowVATDifference(true);
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Modify(true);

        LibraryVariableStorage.Enqueue(VATModifier);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoicePage.SalesStatistics.Invoke();
        SalesInvoicePage.Close();

        SalesLine.Find();
        SalesLine.TestField(Amount, Round(SalesLine."Unit Price" / (1 + SalesLine."VAT %" / 100)) - VATModifier);

        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", 0D, false);

        SalesHeader.SetRecFilter();

        Assert.RecordIsEmpty(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler1,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostSalesCreditMemosRequestValuesNotOverriddenWhenRunInBackground()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Saved Request page values are not overridden when running the batch job in background.

        // [GIVEN] Saved request page values.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Credit Memos", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Credit Memos", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler1).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Credit Memos", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler2,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoicesRequestValuesNotOverriddenWhenRunInBackground()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Saved Request page values are not overridden when running the batch job in background.

        // [GIVEN] Saved request page values.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Invoices", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Invoices", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler2).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Invoices", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler3,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrdersRequestValuesNotOverriddenWhenRunInBackground()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Saved Request page values are not overridden when running the batch job in background.

        // [GIVEN] Saved request page values.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Orders", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Orders", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler3).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Orders", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler4,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostSalesReturnOrdersRequestValuesNotOverriddenWhenRunInBackground()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        RequestPageXML: Text;
    begin
        // [SCENARIO] Saved Request page values are not overridden when running the batch job in background.

        // [GIVEN] Saved request page values.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Return Orders", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Return Orders", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler4).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Sales Return Orders", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrders,MessageHandler')]
    procedure BatchPostSalesOrderForICPartner()
    var
        Customer: Record Customer;
        ICSetup: Record "IC Setup";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        TempBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        ZipEntryList: List of [Text];
        InStreamVar: InStream;
        ICPartnerCode: Code[20];
        ICPartnerInboxType: enum "IC Partner Inbox Type";
        ZipEntryName: Text;
        Index: Integer;
        SalesDocFilter: Text;
    begin
        // [FEATURE] [InterCompany] [File]
        // [SCENARIO 415486] Stan can post a few sales orders in a batch with auto sending IC documents when IC Partner's Inbox is a File Location. Stan gets all IC documents in a single zip file.
        Initialize();

        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);

        ICPartnerCode := CreateICPartnerWithInbox(ICPartnerInboxType::"File Location");
        UpdateICSetup(ICPartnerCode, ICSetup."IC Inbox Type"::"File Location", true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Modify(true);

        for Index := 1 to ArrayLen(SalesHeader) do begin
            LibrarySales.CreateSalesHeader(SalesHeader[Index], SalesHeader[Index]."Document Type"::Order, Customer."No.");
            LibrarySales.CreateSalesLine(SalesLine[Index], SalesHeader[Index], SalesLine[Index].Type::Item, LibraryInventory.CreateItemNo(), 1);
            SalesLine[Index].Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
            SalesLine[Index].Modify(true);
        end;

        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        SalesDocFilter := StrSubstNo('%1|%2', SalesHeader[1]."No.", SalesHeader[2]."No.");
        RunBatchPostSales(SalesHeader[1]."Document Type"::Order, SalesDocFilter, WorkDate(), false);

        ZipEntryName := CopyStr(StrSubstNo(InterCompanyZipFileNamePatternTok, Format(WorkDate(), 10, '<Year4>-<Month,2>-<Day,2>')), 1, 1024);
        Assert.AreEqual(ZipEntryName, LibraryFileMgtHandler.GetDownloadFromSreamToFileName(), 'Invalid zip file name to save');

        LibraryFileMgtHandler.GetTempBlob(TempBlob);
        TempBlob.CreateInStream(InStreamVar);
        DataCompression.OpenZipArchive(InStreamVar, false);
        DataCompression.GetEntryList(ZipEntryList);
        DataCompression.CloseZipArchive();

        Assert.AreEqual(4, ZipEntryList.Count(), 'Incorrect number of files in zip');

        for Index := 1 to ZipEntryList.Count() do begin
            ZipEntryList.Get(Index, ZipEntryName);
            Assert.AreEqual(StrSubstNo('%1_%2.xml', ICPartnerCode, Index), ZipEntryName, 'Incorrect name of file in zip at position: ' + Format(Index));
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    procedure BatchPostGenJournalForICPartner()
    var
        Customer: Record Customer;
        ICSetup: Record "IC Setup";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalLineToPost: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        TempBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        ZipEntryList: List of [Text];
        InStreamVar: InStream;
        ICPartnerCode: Code[20];
        ICPartnerInboxType: enum "IC Partner Inbox Type";
        ZipEntryName: Text;
        Index: Integer;
    begin
        // [FEATURE] [InterCompany] [File]
        // [SCENARIO 415486] Stan can post a few sales orders in a batch with auto sending IC documents when IC Partner's Inbox is a File Location. Stan gets all IC documents in a single zip file.
        Initialize();

        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);

        ICPartnerCode := CreateICPartnerWithInbox(ICPartnerInboxType::"File Location");
        UpdateICSetup(ICPartnerCode, ICSetup."IC Inbox Type"::"File Location", true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Modify(true);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Intercompany);
        GenJournalTemplate.Modify(true);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalBatch.Modify(true);

        for Index := 1 to ArrayLen(GenJournalLine) do begin
            LibraryERM.CreateGeneralJnlLine(
                GenJournalLine[Index], GenJournalTemplate.Name, GenJournalBatch.Name,
                GenJournalLine[Index]."Document Type"::Invoice, GenJournalLine[Index]."Account Type"::Customer, Customer."No.",
                LibraryRandom.RandIntInRange(100, 200));
            GenJournalLine[Index].Validate("IC Account Type", "IC Journal Account Type"::"G/L Account");
            GenJournalLine[Index].Validate("IC Account No.", CreateICGLAccountCode());
            GenJournalLine[Index].Modify(true);
        end;

        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        GenJournalLineToPost.SetRange("Account Type", GenJournalLineToPost."Account Type"::Customer);
        GenJournalLineToPost.SetRange("Account No.", Customer."No.");
        GenJournalLineToPost.FindFirst();

        GenJournalLineToPost.SendToPosting(Codeunit::"Gen. Jnl.-Post");

        ZipEntryName := CopyStr(StrSubstNo(GLInterCompanyZipFileNamePatternTok, Format(WorkDate(), 10, '<Year4>-<Month,2>-<Day,2>')), 1, 1024);
        Assert.AreEqual(ZipEntryName, LibraryFileMgtHandler.GetDownloadFromSreamToFileName(), 'Invalid zip file name to save');

        LibraryFileMgtHandler.GetTempBlob(TempBlob);
        TempBlob.CreateInStream(InStreamVar);
        DataCompression.OpenZipArchive(InStreamVar, false);
        DataCompression.GetEntryList(ZipEntryList);
        DataCompression.CloseZipArchive();

        Assert.AreEqual(2, ZipEntryList.Count(), 'Incorrect number of files in zip');

        for Index := 1 to ZipEntryList.Count() do begin
            ZipEntryList.Get(Index, ZipEntryName);
            Assert.AreEqual(StrSubstNo('%1_%2.xml', ICPartnerCode, Index), ZipEntryName, 'Incorrect name of file in zip at position: ' + Format(Index));
        end;
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrders,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrderReplacePostingDate()
    var
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 543504] There is an issue with the “Post with Job Queue” function in the Sales & Receivables Setup. When selecting “Replace Posting Date” the posting date does not update as expected
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Create and Release the Sales Order 
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Run Batch Post Sales Order with Replace Posting Date, Replace Document Date options
        RunBatchPostsales(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Posting Date" + 1, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Posting Date is replaced with new Posting Date in the Sales Order
        VerifyPostedSalesOrder(SalesHeader."No.", SalesHeader."Posting Date" + 1, false);
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoicesWithReplaceAllDates,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSaleInvoiceWithReplacePostingDateAndCurrencyCode()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        Amount: Decimal;
    begin
        // [SCENARIO 562713] Post sales invoice with currency code via Post Batch, but the posted data has not been changed.
        Initialize();

        // [GIVEN] Set Post with Job queue on Sales & Receivables Setup
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Bind subscription and do not handle Job queue event as true
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Create Sales Invoice with Currency Code.
        Amount := CreateSalesDocumentWithCurrency(SalesHeader, Currency, SalesHeader."Document Type"::Invoice, false);

        // [WHEN] Run Post Batch with Replace Posting Date, Replace Document Date & Replace VAT Date options.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Posting Date" + 10, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] The amount was not changed in the posted sales invoice line
        VerifyPostedSalesInvoiceAmount(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Posting Date" + 10, Amount);
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrderShipmentCompleted,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostSaleOrderCompleteShipmentWithReplacePostingDateAndCurrencyCode()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        Amount: Decimal;
    begin
        // [SCENARIO 563344] Batch posting when changing posting date and when different currency is used and Item has completely shipped document status is "Released"
        Initialize();

        // [GIVEN] Set Post with Job queue on Sales & Receivables Setup
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Bind subscription and do not handle Job queue event as true
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Create Sales Order with Currency Code.
        Amount := CreateSalesDocumentWithCurrency(SalesHeader, Currency, SalesHeader."Document Type"::Order, false);

        // [WHEN] Post the shipment
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Run Post Batch with Replace Posting Date, Replace Document Date & Replace VAT Date options.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Posting Date" + 10, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] The amount was not changed in the posted sales invoice line
        VerifyPostedSalesInvoiceAmount(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Posting Date" + 10, Amount);
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrderShipmentCompleted,MessageHandler')]
    procedure VerifySalesOrderStatusBatchPostSaleOrderWithReplacePostingDateAndCurrencyCode()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 578963] Verify Sales Order Status When Batch posting with Replace Posting Date and different currency.
        Initialize();

        // [GIVEN] Set Post with Job queue on Sales & Receivables Setup
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Bind subscription and do not handle Job queue event as true
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Create Release Sales Order with Currency Code.
        CreateSalesDocumentWithCurrency(SalesHeader, Currency, SalesHeader."Document Type"::Order, false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Run Post Batch with Replace Posting Date, Replace Document Date & Replace VAT Date options.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Posting Date" + 10, false);
        asserterror LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] An Error Message appear and verify Sales Header Status as Released.
        Assert.ExpectedError(NothingToPostErr);
        VerifySalesOrderStatus(SalesHeader."Document Type", SalesHeader."No.")
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesInvoices,MessageHandler')]
    procedure BatchPostSalesInvoiceWithPaymentDiscount()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        BatchID: array[2] of Guid;
        BatchSessionID: array[2] of Integer;
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 582400] Payment discounts are not being calculated on sales invoices when batch posting with the 'Replace Posting date' and 'Replace document date' options selected
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        BatchSessionID[1] := SessionId();
        BatchSessionID[2] := SessionId() - 1;

        PostingDate[1] := WorkDate() - 1;
        PostingDate[2] := WorkDate();

        BatchID[1] := CreateGuid();
        BatchID[2] := CreateGuid();

        // [GIVEN] Create Customer with Payment Terms and Payment Discount
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);

        // [GIVEN] Sales invoice to be posted via batch
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", 1);

        // [GIVEN] Adding Batch Parameter "Posting Date" 
        AddBatchProcessParameters(
          SalesHeader, "Batch Posting Parameter Type"::"Posting Date", PostingDate[1], BatchSessionID[1], BatchID[1]);
        AddBatchProcessParameters(
          SalesHeader, "Batch Posting Parameter Type"::"Posting Date", PostingDate[1], BatchSessionID[2], BatchID[2]);

        // [WHEN] Run "Batch Post Sales Invoices" report with "Replace Posting Date" = TRUE 
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", PostingDate[2], true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] Verify Payment discount setup on the Sales invoice should be calculated after posting via batch posting process
        VerifyPostedSalesInvoicePaymentDiscount(SalesHeader."No.", PostingDate[2], PaymentTerms."Discount %");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostSalesOrderShipmentCompleted,MessageHandler')]
    procedure VerifySalesOrderStatusBatchPostSaleOrderWithReplacePostingDateAndCurrencyCodeandWithoutShipment()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 595901] Unshipped 'Open' Sales Orders Incorrectly Changing to 'Released' Status During Batch Post with Foreign Currency
        Initialize();

        // [GIVEN] Set Post with Job queue on Sales & Receivables Setup
        LibrarySales.SetPostWithJobQueue(true);

        // [GIVEN] Bind subscription and do not handle Job queue event as true
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Create Release Sales Order with Currency Code.
        CreateSalesDocumentWithCurrency(SalesHeader, Currency, SalesHeader."Document Type"::Order, false);

        // [WHEN] Run Post Batch with Replace Posting Date, Replace Document Date & Replace VAT Date options.
        RunBatchPostSales(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Posting Date" + 10, false);
        asserterror LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId);

        // [THEN] An Error Message appear and verify Sales Header Status as Open.
        Assert.ExpectedError(NothingToPostErr);
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Batch Posting");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Batch Posting");

        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.Save(Database::"IC Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Batch Posting");
    end;

    local procedure CreateCustomer(InvDisc: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        if InvDisc then
            CreateCustomerDiscount(Customer."No.");
        exit(Customer."No.");
    end;

    local procedure CreateCustomerDiscount(CustomerNo: Code[20])
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.Init();
        CustInvDisc.Validate(Code, CustomerNo);
        CustInvDisc.Validate("Discount %", LibraryRandom.RandIntInRange(10, 20));
        CustInvDisc.Insert(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; InvDisc: Boolean)
    begin
        CreateSalesDocumentWithQuantity(SalesHeader, DocumentType, InvDisc, LibraryRandom.RandIntInRange(10, 20));
    end;

    local procedure CreateSalesDocumentWithQuantity(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; InvDisc: Boolean; DocQuantity: Decimal)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(InvDisc));
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", DocQuantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; DocQuantity: Decimal)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", DocQuantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
    end;

    local procedure AddBatchProcessParameters(SalesHeader: Record "Sales Header"; ParameterId: Enum "Batch Posting Parameter Type"; ParameterValue: Variant; BachSessionID: Integer; BatchID: Guid)
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingParameter.Init();
        BatchProcessingParameter."Batch ID" := BatchID;
        BatchProcessingParameter."Parameter Id" := ParameterId.AsInteger();
        BatchProcessingParameter."Parameter Value" := Format(ParameterValue);
        BatchProcessingParameter.Insert();

        BatchProcessingSessionMap."Record ID" := SalesHeader.RecordId;
        BatchProcessingSessionMap."Batch ID" := BatchProcessingParameter."Batch ID";
        BatchProcessingSessionMap."User ID" := UserSecurityId();
        BatchProcessingSessionMap."Session ID" := BachSessionID;
        BatchProcessingSessionMap.Insert();
    end;

    local procedure CreateICGLAccountCode(): Code[20]
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        LibraryERM.CreateICGLAccount(ICGLAccount);
        exit(ICGLAccount."No.");
    end;

    local procedure UpdateICSetup(ICPartnerCode: Code[20]; ICInboxType: Option; AutoSendTransaction: Boolean)
    var
        ICSetup: Record "IC Setup";
    begin
        ICSetup.Get();
        ICSetup.Validate("IC Partner Code", ICPartnerCode);
        ICSetup.Validate("IC Inbox Type", ICInboxType);
        ICSetup.Validate("Auto. Send Transactions", AutoSendTransaction);
        ICSetup.Modify(true);
    end;

    local procedure RunBatchPostSales(DocumentType: Enum "Sales Document Type"; DocumentNoFilter: Text; PostingDate: Date; CalcInvDisc: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        UpdateCalcInvDiscSalesReceivablesSetup(CalcInvDisc);
        LibraryVariableStorage.Enqueue(DocumentNoFilter);
        LibraryVariableStorage.Enqueue(PostingDate);

        Commit();
        case DocumentType of
            SalesHeader."Document Type"::Invoice:
                REPORT.RunModal(REPORT::"Batch Post Sales Invoices", true, true, SalesHeader);
            SalesHeader."Document Type"::"Credit Memo":
                REPORT.RunModal(REPORT::"Batch Post Sales Credit Memos", true, true, SalesHeader);
            SalesHeader."Document Type"::Order:
                REPORT.RunModal(REPORT::"Batch Post Sales Orders", true, true, SalesHeader);
            SalesHeader."Document Type"::"Return Order":
                REPORT.RunModal(REPORT::"Batch Post Sales Return Orders", true, true, SalesHeader);
        end;
    end;

    local procedure RunJobQueueFromSalesHeader(var SalesHeader: Record "Sales Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Get(SalesHeader."Job Queue Entry ID");
        CODEUNIT.Run(JobQueueEntry."Object ID to Run", JobQueueEntry);
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Finished);
    end;

    local procedure UpdateCalcInvDiscSalesReceivablesSetup(CalcInvDisc: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", CalcInvDisc);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateShipmentOnInvoiceOnSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", SalesReceivablesSetup."Invoice Nos.");
        SalesReceivablesSetup."Shipment on Invoice" := false;
        SalesReceivablesSetup.Modify();
    end;

    local procedure CreateInvoiceReportSelection()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.DeleteAll();
        CustomReportSelection.DeleteAll();

        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"S.Invoice";
        ReportSelections."Report ID" := REPORT::"Standard Sales - Invoice";
        if ReportSelections.Insert() then;
    end;

    local procedure CreateICPartnerBase(var ICPartner: Record "IC Partner")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateICPartner(ICPartner);
        ICPartner.Validate("Receivables Account", GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        ICPartner.Validate("Payables Account", GLAccount."No.");
    end;

    local procedure CreateICPartnerWithInbox(ICPartnerInboxType: enum "IC Partner Inbox Type"): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        CreateICPartnerBase(ICPartner);
        ICPartner.Validate(Name, LibraryUtility.GenerateGUID());
        ICPartner.Validate("Inbox Type", ICPartnerInboxType);
        ICPartner.Validate("Inbox Details", '');
        ICPartner.Modify(true);
        exit(ICPartner.Code);
    end;

    local procedure FindAndRunJobQueueEntryByRecord(var SalesHeader: Record "Sales Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        JobQueueEntry.Get(SalesHeader."Job Queue Entry ID");
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Modify();
        Commit();
        if not Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry) then
            LibraryJobQueue.RunJobQueueErrorHandler(JobQueueEntry);
    end;

    local procedure VerifyPostedSalesInvoice(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.SetFilter("Pre-Assigned No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Posting Date", PostingDate);
        SalesInvoiceHeader.TestField("Document Date", PostingDate); // TFS ID 203294
        SalesInvoiceLine.SetFilter("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(InvDisc, SalesInvoiceLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedSalesInvoicePaymentDiscount(PreAssignedNo: Code[20]; PostingDate: Date; PaymentDiscount: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetFilter("Pre-Assigned No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Posting Date", PostingDate);
        SalesInvoiceHeader.TestField("Document Date", PostingDate);
        SalesInvoiceHeader.TestField("Payment Discount %", PaymentDiscount);
    end;

    local procedure VerifyPostedSalesInvoiceByOrderNo(OrderNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.SetFilter("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Posting Date", PostingDate);
        SalesInvoiceHeader.TestField("Document Date", PostingDate); // TFS ID 203294
        SalesInvoiceLine.SetFilter("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(InvDisc, SalesInvoiceLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedSalesCrMemo(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader.SetFilter("Pre-Assigned No.", PreAssignedNo);
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.TestField("Posting Date", PostingDate);
        SalesCrMemoLine.SetFilter("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();
        Assert.AreEqual(InvDisc, SalesCrMemoLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedSalesOrder(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.SetFilter("Order No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Posting Date", PostingDate);
        SalesInvoiceHeader.TestField("Document Date", PostingDate);
        SalesInvoiceLine.SetFilter("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(InvDisc, SalesInvoiceLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedSalesReturnOrder(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader.SetFilter("Return Order No.", PreAssignedNo);
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.TestField("Posting Date", PostingDate);
        SalesCrMemoLine.SetFilter("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();
        Assert.AreEqual(InvDisc, SalesCrMemoLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyBatchParametersExist(BatchId: Guid)
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingParameter.SetRange("Batch ID", BatchId);
        Assert.RecordIsNotEmpty(BatchProcessingParameter);

        BatchProcessingSessionMap.SetRange("Batch ID", BatchId);
        Assert.RecordIsNotEmpty(BatchProcessingSessionMap);
    end;

    local procedure VerifyBatchParametersDoNoExist(BatchId: Guid)
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingParameter.SetRange("Batch ID", BatchId);
        Assert.RecordIsEmpty(BatchProcessingParameter);

        BatchProcessingSessionMap.SetRange("Batch ID", BatchId);
        Assert.RecordIsEmpty(BatchProcessingSessionMap);
    end;

    local procedure VerifySalesHeaderNotification()
    var
        SalesHeader: Record "Sales Header";
    begin
        Assert.ExpectedMessage(NotificationMsg, LibraryVariableStorage.DequeueText()); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty();
        Clear(SalesHeader);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    local procedure VerifyPrintJobQueueEntries(var SalesHeader: array[2] of Record "Sales Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Standard Sales - Invoice");
        JobQueueEntry.SetRange("Report Output Type", JobQueueEntry."Report Output Type"::PDF);

        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader[1]."No.");
        SalesInvoiceHeader.FindFirst();
        JobQueueEntry.SetRange("Record ID to Process", SalesInvoiceHeader.RecordId);
        Assert.RecordCount(JobQueueEntry, 1);

        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader[2]."No.");
        SalesInvoiceHeader.FindFirst();
        JobQueueEntry.SetRange("Record ID to Process", SalesInvoiceHeader.RecordId);
        Assert.RecordCount(JobQueueEntry, 1);
    end;

    local procedure CreateSalesDocumentWithCurrency(var SalesHeader: Record "Sales Header"; var Currency: Record Currency; DocumentType: Enum "Sales Document Type"; InvDisc: Boolean): Decimal
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(InvDisc));
        CreateCurrencyWithExchangeRate(Currency);
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandInt(20));
        SalesLine.Modify(true);

        exit(SalesLine."Amount Including VAT");
    end;

    local procedure CreateCurrencyWithExchangeRate(var Currency: Record Currency)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());

        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandInt(0));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", LibraryRandom.RandInt(0));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDecInDecimalRange(0.6458, 0.6458, 4));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", LibraryRandom.RandDecInDecimalRange(0.6458, 0.6458, 4));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure VerifyPostedSalesInvoiceAmount(SalesDocumentType: Enum "Sales Document Type"; PreAssignedNo: Code[20]; PostingDate: Date; Amount: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        if SalesDocumentType = SalesDocumentType::Order then
            SalesInvoiceHeader.SetRange("Order No.", PreAssignedNo)
        else
            SalesInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);

        SalesInvoiceHeader.FindFirst();
        Assert.Equal(SalesInvoiceHeader."Posting Date", PostingDate);
        SalesInvoiceLine.SetFilter("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        Assert.Equal(Amount, SalesInvoiceLine."Amount Including VAT");
    end;

    local procedure VerifySalesOrderStatus(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        Assert.AreEqual(SalesHeader.Status::Released, SalesHeader.Status, SalesOrderStatusMsg);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostSalesInvoices(var BatchPostSalesInvoices: TestRequestPage "Batch Post Sales Invoices")
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
        RunReplacePostingDate: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesInvoices."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesInvoices."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::Invoice));

        BatchPostSalesInvoices.PostingDate.SetValue(PostingDate);
        RunReplacePostingDate := Format(PostingDate) <> '';
        BatchPostSalesInvoices.ReplaceDocumentDate.SetValue(RunReplacePostingDate);
        BatchPostSalesInvoices.ReplacePostingDate.SetValue(RunReplacePostingDate);
        // CalcInvDiscount is set from Sales Setup
        BatchPostSalesInvoices.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostSalesCrMemos(var BatchPostSalesCrMemos: TestRequestPage "Batch Post Sales Credit Memos")
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesCrMemos."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesCrMemos."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::"Credit Memo"));

        BatchPostSalesCrMemos.PostingDate.SetValue(PostingDate);
        if Format(PostingDate) <> '' then
            BatchPostSalesCrMemos.ReplacePostingDate.SetValue(true)
        else
            BatchPostSalesCrMemos.ReplacePostingDate.SetValue(false);
        // CalcInvDiscount is set from Sales Setup
        BatchPostSalesCrMemos.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostSalesOrders(var BatchPostSalesOrders: TestRequestPage "Batch Post Sales Orders")
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesOrders."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesOrders."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::Order));

        BatchPostSalesOrders.PostingDate.SetValue(PostingDate);
        if Format(PostingDate) <> '' then begin
            BatchPostSalesOrders.ReplacePostingDate.SetValue(true);
            BatchPostSalesOrders.ReplaceDocumentDate.SetValue(true);
        end else
            BatchPostSalesOrders.ReplacePostingDate.SetValue(false);
        BatchPostSalesOrders.Ship.SetValue(true);
        BatchPostSalesOrders.Invoice.SetValue(true);
        BatchPostSalesOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostSalesReturnOrders(var BatchPostSalesReturnOrders: TestRequestPage "Batch Post Sales Return Orders")
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesReturnOrders."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesReturnOrders."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::"Return Order"));

        BatchPostSalesReturnOrders.PostingDateReq.SetValue(PostingDate);
        if Format(PostingDate) <> '' then
            BatchPostSalesReturnOrders.ReplacePostingDate.SetValue(true)
        else
            BatchPostSalesReturnOrders.ReplacePostingDate.SetValue(false);
        BatchPostSalesReturnOrders.ReceiveReq.SetValue(true);
        BatchPostSalesReturnOrders.InvReq.SetValue(true);
        BatchPostSalesReturnOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoicesPrintRequestPageHandler(var BatchPostSalesInvoices: TestRequestPage "Batch Post Sales Invoices")
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
        PrintVisible: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesInvoices."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesInvoices."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::Invoice));

        PrintVisible := BatchPostSalesInvoices.PrintDoc.Visible();
        if PrintVisible then
            BatchPostSalesInvoices.PrintDoc.SetValue(true);
        BatchPostSalesInvoices.OK().Invoke();

        LibraryVariableStorage.Enqueue(PrintVisible);
        LibraryVariableStorage.Enqueue(0); // initialize report run counter
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostSalesOrderShipmentCompleted(var BatchPostSalesOrders: TestRequestPage "Batch Post Sales Orders")
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesOrders."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesOrders."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::Order));

        BatchPostSalesOrders.PostingDate.SetValue(PostingDate);
        if Format(PostingDate) <> '' then begin
            BatchPostSalesOrders.ReplacePostingDate.SetValue(true);
            BatchPostSalesOrders.ReplaceDocumentDate.SetValue(false);
        end else
            BatchPostSalesOrders.ReplacePostingDate.SetValue(false);
        BatchPostSalesOrders.Ship.SetValue(false);
        BatchPostSalesOrders.Invoice.SetValue(true);
        BatchPostSalesOrders.OK().Invoke();
    end;

    [ReportHandler]
    procedure StandardSalesInvoiceReportHandler(var StandardSalesInvoice: Report "Standard Sales - Invoice")
    begin
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger() + 1);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    procedure SalesStaticsUpdateVATAmountModalPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesStatistics.SubForm."VAT Amount".SetValue(
          SalesStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal());
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, LibraryVariableStorage.DequeueText());
        SalesStatistics.GotoRecord(SalesHeader);
    end;
#endif
    [PageHandler]
    procedure SalesStaticsUpdateVATAmountPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesStatistics.SubForm."VAT Amount".SetValue(
          SalesStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal());
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, LibraryVariableStorage.DequeueText());
        SalesStatistics.GotoRecord(SalesHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CountingMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorageCounter.Enqueue(Message);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SentNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ShowErrorsNotificationHandler(var Notification: Notification): Boolean
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        ErrorMessageMgt.ShowErrors(Notification); // simulate a click on notification's action
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchRequestValuesHandler1(var PostBatchForm: TestRequestPage "Batch Post Sales Credit Memos")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();

        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.PostingDate.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate.SetValue(true);
            PostBatchForm.ReplaceDocumentDate.SetValue(true);
            PostBatchForm.CalcInvDisc.SetValue(not SalesReceivablesSetup."Calc. Inv. Discount");
            PostBatchForm.PrintDoc.SetValue(true);
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.PostingDate.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplaceDocumentDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(
                PostBatchForm.CalcInvDisc.AsBoolean(),
                not SalesReceivablesSetup."Calc. Inv. Discount",
                'Expected value to be restored.'
            );
            Assert.AreEqual(PostBatchForm.PrintDoc.AsBoolean(), true, 'Expected value to be restored.');
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchRequestValuesHandler2(var PostBatchForm: TestRequestPage "Batch Post Sales Invoices")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();

        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.PostingDate.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate.SetValue(true);
            PostBatchForm.ReplaceDocumentDate.SetValue(true);
            PostBatchForm.CalcInvDisc.SetValue(not SalesReceivablesSetup."Calc. Inv. Discount");
            PostBatchForm.PrintDoc.SetValue(true);
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.PostingDate.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplaceDocumentDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(
                PostBatchForm.CalcInvDisc.AsBoolean(),
                not SalesReceivablesSetup."Calc. Inv. Discount",
                'Expected value to be restored.'
            );
            Assert.AreEqual(PostBatchForm.PrintDoc.AsBoolean(), true, 'Expected value to be restored.');
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchRequestValuesHandler3(var PostBatchForm: TestRequestPage "Batch Post Sales Orders")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();

        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.Ship.SetValue(true);
            PostBatchForm.Invoice.SetValue(true);
            PostBatchForm.PostingDate.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate.SetValue(true);
            PostBatchForm.ReplaceDocumentDate.SetValue(true);
            PostBatchForm.CalcInvDisc.SetValue(not SalesReceivablesSetup."Calc. Inv. Discount");
            PostBatchForm.PrintDoc.SetValue(true);
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.Ship.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.Invoice.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.PostingDate.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplaceDocumentDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(
                PostBatchForm.CalcInvDisc.AsBoolean(),
                not SalesReceivablesSetup."Calc. Inv. Discount",
                'Expected value to be restored.'
            );
            Assert.AreEqual(PostBatchForm.PrintDoc.AsBoolean(), true, 'Expected value to be restored.');
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchRequestValuesHandler4(var PostBatchForm: TestRequestPage "Batch Post Sales Return Orders")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();

        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.ReceiveReq.SetValue(true);
            PostBatchForm.InvReq.SetValue(true);
            PostBatchForm.PostingDateReq.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate.SetValue(true);
            PostBatchForm.ReplaceDocumentDate.SetValue(true);
            PostBatchForm.CalcInvDisc.SetValue(not SalesReceivablesSetup."Calc. Inv. Discount");
            PostBatchForm.PrintDoc.SetValue(true);
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.ReceiveReq.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.InvReq.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.PostingDateReq.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplaceDocumentDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(
                PostBatchForm.CalcInvDisc.AsBoolean(),
                not SalesReceivablesSetup."Calc. Inv. Discount",
                'Expected value to be restored.'
            );
            Assert.AreEqual(PostBatchForm.PrintDoc.AsBoolean(), true, 'Expected value to be restored.');
        end;
    end;

    [RequestPageHandler]
    procedure RequestPageHandlerBatchPostSalesInvoicesWithReplaceAllDates(var BatchPostSalesInvoices: TestRequestPage "Batch Post Sales Invoices")
    var
        SalesHeader: Record "Sales Header";
        DocumentNoFilter: Variant;
        PostingDate: Variant;
        RunReplacePostingDate: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostSalesInvoices."Sales Header".SetFilter("No.", DocumentNoFilter);
        BatchPostSalesInvoices."Sales Header".SetFilter("Document Type", Format(SalesHeader."Document Type"::Invoice));

        BatchPostSalesInvoices.PostingDate.SetValue(PostingDate);
        RunReplacePostingDate := Format(PostingDate) <> '';
        BatchPostSalesInvoices.ReplacePostingDate.SetValue(RunReplacePostingDate);
        BatchPostSalesInvoices.ReplaceVATDate.SetValue(RunReplacePostingDate);
        BatchPostSalesInvoices.OK().Invoke();
    end;
}

