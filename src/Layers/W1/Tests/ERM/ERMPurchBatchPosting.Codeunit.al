codeunit 134337 "ERM Purch. Batch Posting"
{
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Batch Post] [Purchase]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryVariableStorageCounter: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        BatchCompletedMsg: Label 'All of your selections were processed.';
        NotificationMsg: Label 'An error or warning occured during operation Batch processing of Purchase Header records.';
        DefaultCategoryCodeLbl: Label 'PURCHBCKGR';

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Invoice Exists.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoiceDiffPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", CalcDate('<1D>', WorkDate()), false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Invoice Exists.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", CalcDate('<1D>', WorkDate()), false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoiceCalcInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, true);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", 0D, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Invoice Exists.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PurchaseHeader."Posting Date", true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoiceCalcInvDiscAndReplacePostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 204056] Batch Posting of Purchase Invoice with Replace Posting Date and Calc. Inv. Discount options for special Purchase Setup
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Purchase Setup has "Posted Invoice Nos." = "Invoice Nos." and "Receipt on Invoice" = No
        UpdateReceiptOnInvoiceOnPurchasePayablesSetup();

        // [GIVEN] Released Purchase Invoice with posting nos are already assigned
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Run Batch Post Purchase Invoice with Replace Posting Date, Replace Document Date, Calc. Inv. Discount options
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseHeader."Posting Date" + 1, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] InvoiceDiscount is calculated and Posting Date is updated
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PurchaseHeader."Posting Date" + 1, true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler,PurchaseInvoiceStatisticsUpdateVATAmountModalPageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoiceVATDifferenceAndReplacePostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        MaxAllowedVATDifference: Decimal;
        TotalAmount: Decimal;
        TotalAmountWithVATDifference: Decimal;
    begin
        // [SCENARIO 204056] Batch Posting of Purchase Invoice with Replace Posting Date and VAT Difference
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Allow VAT Difference
        MaxAllowedVATDifference := 1;
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);
        LibraryPurchase.SetAllowVATDifference(true);

        // [GIVEN] Released Purchase Invoice with posting nos are already assigned
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);
        TotalAmount := PurchaseHeader."Amount Including VAT";

        // [GIVEN] VAT Amount Increased on Statistics page
        LibraryVariableStorage.Enqueue(MaxAllowedVATDifference / 3);
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoicePage.Statistics.Invoke();
        PurchaseInvoicePage.Close();
        Commit();

        PurchaseHeader.CalcFields("Amount Including VAT");
        TotalAmountWithVATDifference := PurchaseHeader."Amount Including VAT";
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Run Batch Post Purchase Invoice with Replace Document Date := true
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseHeader."Posting Date" + 1, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Verify Document Date is equal to Posting Date
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("Document Date", PurchaseHeader."Posting Date" + 1);

        // [THEN] Verify Amount Including VAT still include VAT Difference after posting
        PurchInvHeader.CalcFields("Amount Including VAT");
        Assert.AreEqual(TotalAmountWithVATDifference, PurchInvHeader."Amount Including VAT", 'Total amount is not correct.');
    end;
#endif

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler,PurchaseInvoiceStatisticsUpdateVATAmountPageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchInvoiceVATDifferenceAndReplacePostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        MaxAllowedVATDifference: Decimal;
        TotalAmount: Decimal;
        TotalAmountWithVATDifference: Decimal;
    begin
        // [SCENARIO 204056] Batch Posting of Purchase Invoice with Replace Posting Date and VAT Difference
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Allow VAT Difference
        MaxAllowedVATDifference := 1;
        LibraryERM.SetMaxVATDifferenceAllowed(MaxAllowedVATDifference);
        LibraryPurchase.SetAllowVATDifference(true);

        // [GIVEN] Released Purchase Invoice with posting nos are already assigned
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);
        TotalAmount := PurchaseHeader."Amount Including VAT";

        // [GIVEN] VAT Amount Increased on Statistics page
        LibraryVariableStorage.Enqueue(MaxAllowedVATDifference / 3);
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoicePage.PurchaseStatistics.Invoke();
        PurchaseInvoicePage.Close();
        Commit();

        PurchaseHeader.CalcFields("Amount Including VAT");
        TotalAmountWithVATDifference := PurchaseHeader."Amount Including VAT";
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Run Batch Post Purchase Invoice with Replace Document Date := true
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseHeader."Posting Date" + 1, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Verify Document Date is equal to Posting Date
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("Document Date", PurchaseHeader."Posting Date" + 1);

        // [THEN] Verify Amount Including VAT still include VAT Difference after posting
        PurchInvHeader.CalcFields("Amount Including VAT");
        Assert.AreEqual(TotalAmountWithVATDifference, PurchInvHeader."Amount Including VAT", 'Total amount is not correct.');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoices()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::Invoice, false);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader2.RecordId);

        // Verify that Posted Purchase Invoice Exists.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        VerifyPostedPurchaseInvoice(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Credit Memo.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", false);

        // Batch Post Purchase Credit Memo.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Credit Memo Exists.
        VerifyPostedPurchaseCrMemo(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseCrMemoDiffPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", false);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", CalcDate('<1D>', WorkDate()), false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Credit Memo Exists.
        VerifyPostedPurchaseCrMemo(PurchaseHeader."No.", CalcDate('<1D>', WorkDate()), false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseCrMemoCalcInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", true);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", 0D, true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // Verify that Posted Purchase Credit Memo Exists.
        VerifyPostedPurchaseCrMemo(PurchaseHeader."No.", PurchaseHeader."Posting Date", true);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseCrMemos,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseCrMemos()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create Purchase Credit Memo.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", false);
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::"Credit Memo", false);

        // Batch Post Purchase Credit Memo.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader2.RecordId);

        // Verify that Posted Purchase Credit Memo Exists.
        VerifyPostedPurchaseCrMemo(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        VerifyPostedPurchaseCrMemo(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoicesWithApprovals()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::Invoice, false);

        // Batch Post Purchase Invoice.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        VerifyPurchHeaderNotification();

        // Verify that Posted Purchase Invoice Exists.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        asserterror VerifyPostedPurchaseInvoice(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter();

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseCrMemos,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseCrMemosWithApprovals()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release cr. memo.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());

        // Create Purchase Cr. Memo.
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::"Credit Memo", false);

        // Batch Post Purchase Cr. Memo.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        VerifyPurchHeaderNotification();

        // Verify that Posted Purchase Cr. Memo Exists.
        VerifyPostedPurchaseCrMemo(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        asserterror VerifyPostedPurchaseCrMemo(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter();

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseOrders,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseOrdersWithApprovals()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release order.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // Create Purchase Order.
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::Order, false);

        // Batch Post Purchase Order.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        VerifyPurchHeaderNotification();

        // Verify that Posted Purchase Order Exists.
        VerifyPostedPurchaseOrder(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        asserterror VerifyPostedPurchaseOrder(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter();

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseReturnOrders,SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseReturnOrdersWithApprovals()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // Create and release return order.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode());

        // Create Purchase return order.
        CreatePurchaseDocument(PurchaseHeader2, PurchaseHeader."Document Type"::"Return Order", false);

        // Batch Post Purchase return order.
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No." + '|' + PurchaseHeader2."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        VerifyPurchHeaderNotification();

        // Verify that Posted Purchase return order Exists.
        VerifyPostedPurchaseReturnOrder(PurchaseHeader."No.", PurchaseHeader."Posting Date", false);
        asserterror VerifyPostedPurchaseReturnOrder(PurchaseHeader2."No.", PurchaseHeader."Posting Date", false);
        Assert.AssertNothingInsideFilter();

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseOrders,CountingMessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseOrderWithInvoiceDiscountAndJobQueue()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        Index: Integer;
    begin
        // [FEATURE] [Order] [Job  Queue] [Invoice Discount]
        // [SCENARIO 268223] Stan can post multiple orders in a batch when "Calc. Invoice Discount" and "Post with Job Queue" are enabled in setup
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Purchase setup with enabled "Calc. Invoice Discount" and "Post with Job Queue"
        LibraryVariableStorageCounter.Clear();
        LibraryWorkflow.DisableAllWorkflows();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Two purchase orders
        for Index := 1 to ArrayLen(PurchaseHeader) do
            CreatePurchaseDocument(PurchaseHeader[Index], PurchaseHeader[Index]."Document Type"::Order, true);

        // [WHEN] Post them via "Batch Post Purchase Orders" report
        RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, true);

        // [THEN] Two Job Queue Entries created and their ID stored in orders
        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            PurchaseHeader[Index].Get(PurchaseHeader[Index]."Document Type", PurchaseHeader[Index]."No.");
            PurchaseHeader[Index].TestField("Job Queue Entry ID");
        end;

        // [THEN] Messages of Job Queue Entry creation have been omitted
        Assert.ExpectedMessage(Format(BatchCompletedMsg), LibraryVariableStorageCounter.DequeueText());
        LibraryVariableStorageCounter.AssertEmpty();

        // [THEN] Invoices has been posted after queues execution
        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            RunJobQueueFromPurchaseHeader(PurchaseHeader[Index]);
            VerifyPostedPurchaseInvoiceByOrderNo(PurchaseHeader[Index]."No.", PurchaseHeader[Index]."Posting Date", true);
        end;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseOrders,ShowErrorsNotificationHandler')]
    [Scope('OnPrem')]
    procedure BatchPostRetryPurchaseOrderWithJobQueueAndZeroQuantity()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        ErrorMessages: TestPage "Error Messages";
        Index: Integer;
        NullGUID: Guid;
    begin
        // [FEATURE] [Order] [Job  Queue]
        // [SCENARIO 275869] Stan can try post with job queue multiple time bad orders without error 'Batch Processing Parameter Map already exists.'
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Purchase setup with enabled "Calc. Invoice Discount" and "Post with Job Queue"
        LibraryVariableStorageCounter.Clear();
        LibraryWorkflow.DisableAllWorkflows();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Two purchase orders
        for Index := 1 to ArrayLen(PurchaseHeader) do
            CreatePurchaseDocumentWithQuantity(
              PurchaseHeader[Index], PurchaseHeader[Index]."Document Type"::Order, false, 0);

        // [WHEN] Post two times them via "Batch Post Sales Orders" report

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        // [THEN] Click on 'Details' action: opened "Error Messages" page with list of bad documents each time
        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            ErrorMessages.Trap();
            RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, true);

            VerifyPurchHeaderNotification();
            LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseHeader[1].RecordId);
            // Bug: 306600
            ErrorMessages.Source.AssertEquals(Format(PurchaseHeader[1].RecordId));
            ErrorMessages.Next();
            ErrorMessages.Source.AssertEquals(Format(PurchaseHeader[2].RecordId));
            ErrorMessages.Close();
        end;

        // [THEN] Job Queue Entries are not created.
        for Index := 1 to ArrayLen(PurchaseHeader) do begin
            PurchaseHeader[Index].Get(PurchaseHeader[Index]."Document Type", PurchaseHeader[Index]."No.");
            PurchaseHeader[Index].TestField("Job Queue Entry ID", NullGUID);
        end;

        Assert.TableIsEmpty(DATABASE::"Batch Processing Parameter");
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoiceWithConcurrentBatch()
    var
        PurchaseHeader: Record "Purchase Header";
        BatchProcessingParameter: Record "Batch Processing Parameter";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        BatchID: array[2] of Guid;
        BatchSessionID: array[2] of Integer;
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 306600] Stan can run "Batch Post Purchase Invoices" report when concurrent batch is active having the same document
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        BatchSessionID[1] := SessionId();
        BatchSessionID[2] := SessionId() - 1;

        PostingDate[1] := WorkDate() - 1;
        PostingDate[2] := WorkDate();

        BatchID[1] := CreateGuid();
        BatchID[2] := CreateGuid();

        // [GIVEN] Purchase invoice "I" to be posted via batch
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);

        // [GIVEN] Batch "B[1]" processing "I". Batch is lost in current session. Parameter "Posting Date" = March 1st, 2019.
        AddBatchProcessParameters(
          PurchaseHeader, "Batch Posting Parameter Type"::"Posting Date", PostingDate[1], BatchSessionID[1], BatchID[1]);

        // [GIVEN] Batch "B[2]" processing "I". Batch is live in other session. Parameter "Posting Date" = March 1st, 2019.
        AddBatchProcessParameters(
          PurchaseHeader, "Batch Posting Parameter Type"::"Posting Date", PostingDate[1], BatchSessionID[2], BatchID[2]);

        // [WHEN] Stan run "Batch Post Purchase Invoices" report with "Replace Posting Date" = TRUE and "Posting Date" = March 2nd, 2019 and "I" in filter
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", PostingDate[2], true);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] "I" is posted with "Posting Date" = March 2nd, 2019.
        VerifyPostedPurchaseInvoice(PurchaseHeader."No.", PostingDate[2], false);

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
    procedure SetPostAndPrintWithJobQueuePurchaseSetupUT()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] "Post with Job Queue" is TRUE when "Post & Print with Job Queue" enabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = FALSE, "Post & Print with Job Queue" = FALSE
        LibraryPurchase.SetPostWithJobQueue(false);
        LibraryPurchase.SetPostAndPrintWithJobQueue(false);
        PurchasesPayablesSetup.Get();
        // [WHEN] Set "Post & Print with Job Queue" = TRUE
        PurchasesPayablesSetup.Validate("Post & Print with Job Queue", true);
        // [THEN] "Post with Job Queue" = TRUE
        Assert.IsTrue(PurchasesPayablesSetup."Post with Job Queue", 'Setup is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResetPostWithJobQueuePurchaseSetupUT()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] "Post & Print with Job Queue" is FALSE when "Post with Job Queue" is disabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = TRUE, "Post & Print with Job Queue" = TRUE
        LibraryPurchase.SetPostWithJobQueue(true);
        LibraryPurchase.SetPostAndPrintWithJobQueue(true);
        PurchasesPayablesSetup.Get();
        // [WHEN] Set "Post with Job Queue" = FALSE
        PurchasesPayablesSetup.Validate("Post with Job Queue", false);
        // [THEN] "Post & Print with Job Queue" = FALSE
        Assert.IsFalse(PurchasesPayablesSetup."Post & Print with Job Queue", 'Setup is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPrintReportOutputTypeInSaaSPurchaseSetupUT()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO 267099] Set "Report Output Type" = Print in SaaS
        Initialize();

        // [GIVEN] SaaS, Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PurchasesPayablesSetup.Get();
        // [WHEN] Set "Report Output Type" = Print
        asserterror PurchasesPayablesSetup.Validate("Report Output Type", PurchasesPayablesSetup."Report Output Type"::Print);
        // [THEN] Error, "Report Output Type" must be PDF
        Assert.ExpectedTestFieldError(PurchasesPayablesSetup.FieldCaption("Report Output Type"), Format(PurchasesPayablesSetup."Report Output Type"::PDF));
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchaseInvoicesPrintRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintBatchPostPurchaseInvoices()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
    begin
        // [FEATURE] [Print]
        // [SCENARIO 267099] Print "Purchase - Invoice" when batch post purchase invoices
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);
        CreateInvoiceReportSelection();

        // [GIVEN] Two invoices
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Invoice, false);
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Batch post two invoices (set Print = TRUE in BatchPostSalesInvoicesPrintRequestPageHandler)
        RunBatchPostPurchase(
          PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, false);

        // [THEN] 'Print' checkbox is not visible, so number "Purchase - Invoice" report runs = 0 (calculated in PurchaseInvoiceReportHandler)
        Assert.AreEqual(0, LibraryVariableStorage.DequeueInteger(), 'Number of printed invoice is not correct');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Print checkbox should not be invisible');
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchaseInvoicesPrintRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintBatchPostPurchaseInvoicesBackground()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [FEATURE] [Print]
        // [SCENARIO 267099] Print "Purchase - Invoice" when batch post purchase invoices in background
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        LibraryPurchase.SetPostAndPrintWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        CreateInvoiceReportSelection();

        // [GIVEN] Two invoices
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Invoice, false);
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Batch post two invoices (set Print = TRUE in BatchPostSalesInvoicesPrintRequestPageHandler)
        RunBatchPostPurchase(
          PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[1].RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader[2].RecordId);

        // [THEN] There are two records in the "Job Queue Entry" with "PDF" output type
        VerifyPrintJobQueueEntries(PurchaseHeader);
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Print checkbox should be visible');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoiceCalcInvDiscAndReplacePostingDateJobQueue()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        JobQueueEntry: Record "Job Queue Entry";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Job Queue]
        // [SCENARIO 316670] Batch Posting of Purchase Invoice with "Replace Posting Date", "Calc. Inv. Discount" and "backgroud posting" in Purchase Setup
        Initialize();

        // [GIVEN] Purchase Setup has "Posted Invoice Nos." = "Invoice Nos." and "Receipt on Invoice" = No
        UpdateReceiptOnInvoiceOnPurchasePayablesSetup();

        // [GIVEN] "Post & Print with Job Queue" and "Post with Job Queue" enabled in Purchase setup
        LibraryPurchase.SetPostAndPrintWithJobQueue(true);
        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Released Purchase Invoice with posting nos are already assigned
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Invoice, true);
        PostingDate[1] := PurchaseHeader[1]."Posting Date";
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader[1]);

        // [GIVEN] "Batch Post Purchase Invoice" ran with Replace Posting Date, Replace Document Date, Calc. Inv. Discount options
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);
        RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No.", PostingDate[1] + 1, true);

        // [GIVEN] "Post & Print with Job Queue" and "Post with Job Queue" disabled in Purchase setup
        LibraryPurchase.SetPostAndPrintWithJobQueue(false);
        LibraryPurchase.SetPostWithJobQueue(false);

        // [GIVEN] Released Purchase Invoice "B" and post via Batch Postig without background job
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, true);
        PostingDate[2] := PurchaseHeader[2]."Posting Date";
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader[2]);
        PurchaseHeader[2].SetRecFilter();
        RunBatchPostPurchase(PurchaseHeader[2]."Document Type", PurchaseHeader[2]."No.", PostingDate[2] + 2, true);

        // [GIVEN] Job Queue Entries created for Invoice 'A'. 
        PurchaseHeader[1].Find();
        JobQueueEntry.Get(PurchaseHeader[1]."Job Queue Entry ID");

        // [WHEN] Run Job Queue Entries for Invoice "A"
        CODEUNIT.Run(JobQueueEntry."Object ID to Run", JobQueueEntry);

        // [THEN] Invoice 'B' is posted directly. 
        Assert.IsFalse(PurchaseHeader[2].Find(), 'Second Invoice should be posted');

        // [THEN] InvoiceDiscount is calculated and Posting Date is updated in Invoices "A"
        VerifyPostedPurchaseInvoice(PurchaseHeader[1]."No.", PostingDate[1] + 1, true);
        // [THEN] InvoiceDiscount is calculated and Posting Date is updated in Invoice "B"
        VerifyPostedPurchaseInvoice(PurchaseHeader[2]."No.", PostingDate[2] + 2, true);

        // [THEN] Batch Processing Session Map table cleaned after job queue execution
        BatchProcessingSessionMap.SetRange("Record ID", PurchaseHeader[1].RecordId);
        Assert.RecordIsEmpty(BatchProcessingSessionMap);

        BatchProcessingSessionMap.SetRange("Record ID", PurchaseHeader[2].RecordId);
        Assert.RecordIsEmpty(BatchProcessingSessionMap);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    procedure BatchPostInvoices_OneJobQueue()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 355799] Batch posting invoices via one job queue
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled
        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Two invoices
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Invoice, false);
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Post batch
        RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(PurchaseHeader[1]);

        // [THEN] All invoices are posted
        VerifyPostedPurchaseInvoice(PurchaseHeader[1]."No.", PurchaseHeader[1]."Posting Date", false);
        VerifyPostedPurchaseInvoice(PurchaseHeader[2]."No.", PurchaseHeader[2]."Posting Date", false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseOrders,MessageHandler')]
    procedure BatchPostOrders_OneJobQueue()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 355799] Batch posting orders via one job queue
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled
        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Two orders
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Order, false);
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Order, false);

        // [WHEN] Post batch
        RunBatchPostPurchase(PurchaseHeader[2]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(PurchaseHeader[1]);

        // [THEN] All orders are posted
        VerifyPostedPurchaseOrder(PurchaseHeader[1]."No.", PurchaseHeader[1]."Posting Date", false);
        VerifyPostedPurchaseOrder(PurchaseHeader[2]."No.", PurchaseHeader[2]."Posting Date", false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseCrMemos,MessageHandler')]
    procedure BatchPostCreditMemos_OneJobQueue()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 355799] Batch posting credit memos via one job queue
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled
        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Two credit memos
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::"Credit Memo", false);
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::"Credit Memo", false);

        // [WHEN] Post batch
        RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(PurchaseHeader[1]);

        // [THEN] All credit memos are posted
        VerifyPostedPurchaseCrMemo(PurchaseHeader[1]."No.", PurchaseHeader[1]."Posting Date", false);
        VerifyPostedPurchaseCrMemo(PurchaseHeader[2]."No.", PurchaseHeader[2]."Posting Date", false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseReturnOrders,MessageHandler')]
    procedure BatchPostReturnOrders_OneJobQueue()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 355799] Batch posting return orders via one job queue
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled
        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Two return orders
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::"Return Order", false);
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::"Return Order", false);

        // [WHEN] Post batch
        RunBatchPostPurchase(PurchaseHeader[2]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(PurchaseHeader[1]);

        // [THEN] All return orders are posted
        VerifyPostedPurchaseReturnOrder(PurchaseHeader[1]."No.", PurchaseHeader[1]."Posting Date", false);
        VerifyPostedPurchaseReturnOrder(PurchaseHeader[2]."No.", PurchaseHeader[2]."Posting Date", false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    procedure BatchPostInvoicesWithEmptyJobQueueCategoryCode_OneJobQueue()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: array[2] of Record "Purchase Header";
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
        LibraryPurchase.SetPostWithJobQueue(true);
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Job Queue Category Code" := '';
        PurchasesPayablesSetup.Modify();

        // [GIVEN] Two invoices
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Invoice, false);
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Post batch
        RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(PurchaseHeader[1]);
        JobQueueEntryId := PurchaseHeader[1]."Job Queue Entry ID";

        // [THEN] Job queue log entry contains default "Job Queue Category Code"
        JobQueueLogEntry.SetRange(ID, JobQueueEntryId);
        JobQueueLogEntry.FindFirst();
        Assert.IsTrue(JobQueueLogEntry."Job Queue Category Code" = DefaultCategoryCodeLbl, 'Job queue log entry has wrong Job Queue Category Code');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,SentNotificationHandler')]
    procedure BatchPostInvoicesOneWithErrorBeforePosting_OneJobQueue()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 355799] Batch posting invoices via one job queue, one invoice has "Job Queue Status" = "Scheduled for Posting"
        Initialize();
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryJobQueue.SetDoNotSkipProcessBatchInBackground(true);

        // [GIVEN] Post with job queue is enabled
        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Two invoices: I1 and I2, I2 has "Job Queue Status" = "Scheduled for Posting"
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Invoice, false);
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, false);
        PurchaseHeader[2]."Job Queue Status" := PurchaseHeader[2]."Job Queue Status"::"Scheduled for Posting";
        PurchaseHeader[2].Modify();

        // [WHEN] Post batch
        RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(PurchaseHeader[1]);

        // [THEN] I1 is posted
        VerifyPostedPurchaseInvoice(PurchaseHeader[1]."No.", PurchaseHeader[1]."Posting Date", false);

        // [THEN] I2 is not posted
        PurchaseHeader[2].Get(PurchaseHeader[2]."Document Type", PurchaseHeader[2]."No.");

        // [THEN] Notification: 'An error occured during operation: batch processing of Purchase Header records.'
        VerifyPurchHeaderNotification();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseInvoices,MessageHandler')]
    procedure BatchPostInvoicesOneWithErrorWhilePosting_OneJobQueue()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
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
        LibraryPurchase.SetPostWithJobQueue(true);

        // [GIVEN] Two invoices: I1 and I2, I2 has empty "Posting Date"
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Invoice, false);
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, false);
        Codeunit.Run(Codeunit::"Release Purchase Document", PurchaseHeader[2]);
        PurchaseHeader[2]."Posting Date" := 0D;
        PurchaseHeader[2].Modify();

        // [WHEN] Post batch
        RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(PurchaseHeader[1]);
        JobQueueEntryId := PurchaseHeader[1]."Job Queue Entry ID";

        // [THEN] I1 is posted
        VerifyPostedPurchaseInvoice(PurchaseHeader[1]."No.", PurchaseHeader[1]."Posting Date", false);

        // [THEN] I2 is not posted, "Job Queue Status" = "Error"
        PurchaseHeader[2].Get(PurchaseHeader[2]."Document Type", PurchaseHeader[2]."No.");
        Assert.IsTrue(PurchaseHeader[2]."Job Queue Status" = PurchaseHeader[2]."Job Queue Status"::Error, 'Purchase header has wrong Job Queue Status');

        // [THEN] Job queue log entry "Status" = "Error", "Error Message" contains error message about I2 "Posting Date"
        JobQueueLogEntry.SetRange(ID, JobQueueEntryId);
        JobQueueLogEntry.FindFirst();
        Assert.IsTrue(JobQueueLogEntry.Status = JobQueueLogEntry.Status::Error, 'Job queue log entry has wrong status');
        Assert.AreEqual(JobQueueLogEntry."Error Message", '1 purchase documents out of 2 have errors during posting.', 'Job queue log entry has wrong error message');

        // [THEN] Error message register contains two records, one for error during posting and one for final message
        ErrorMessage.SetRange("Register ID", JobQueueLogEntry."Error Message Register Id");
        Assert.RecordCount(ErrorMessage, 1);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchaseInvoicesPrintRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostAndPrintInvoices_OneJobQueue()
    var
        PurchaseHeader: array[2] of Record "Purchase Header";
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
        LibraryPurchase.SetPostAndPrintWithJobQueue(true);

        // [GIVEN] Two invoices
        CreatePurchaseDocument(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Invoice, false);
        CreatePurchaseDocument(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, false);

        // [WHEN] Post batch
        RunBatchPostPurchase(PurchaseHeader[1]."Document Type", PurchaseHeader[1]."No." + '|' + PurchaseHeader[2]."No.", 0D, false);
        FindAndRunJobQueueEntryByRecord(PurchaseHeader[1]);
        JobQueueEntryId := PurchaseHeader[1]."Job Queue Entry ID";

        // [THEN] All invoices are posted
        VerifyPostedPurchaseInvoice(PurchaseHeader[1]."No.", PurchaseHeader[1]."Posting Date", false);
        VerifyPostedPurchaseInvoice(PurchaseHeader[2]."No.", PurchaseHeader[2]."Posting Date", false);

        // [THEN] All invoices are printed as PDF to Report Inbox
        ReportInbox.SetRange("Job Queue Log Entry ID", JobQueueEntryId);
        Assert.RecordCount(ReportInbox, 2);
        ReportInbox.FindFirst();
        Assert.IsTrue(StrPos(ReportInbox.Description, StrSubstNo('Print Purchase Invoice No. %1', PurchaseHeader[1]."No.")) > 0, 'Report Inbox contains wrong printed document');
        ReportInbox.Next();
        Assert.IsTrue(StrPos(ReportInbox.Description, StrSubstNo('Print Purchase Invoice No. %1', PurchaseHeader[2]."No.")) > 0, 'Report Inbox contains wrong printed document');
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler1,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoicesRequestValuesNotOverriddenWhenRunInBackground()
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
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purchase Invoices", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purchase Invoices", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler1).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purchase Invoices", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [Test]
    [HandlerFunctions('PostBatchRequestValuesHandler2,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchPostPurchCreditMemosRequestValuesNotOverriddenWhenRunInBackground()
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
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purch. Credit Memos", RequestPageXML);

        // [WHEN] Running the request page in the background.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);
        RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purch. Credit Memos", RequestPageXML);

        // [THEN] The saved request page values are not overriden (see PostBatchRequestValuesHandler2).

        // [WHEN] Running the request page as desktop.
        LibraryVariableStorage.Enqueue(false);
        TestClientTypeSubscriber.SetClientType(ClientType::Desktop);
        asserterror RequestPageXML := Report.RunRequestPage(Report::"Batch Post Purch. Credit Memos", RequestPageXML);

        // [THEN] The saved request page values are overridden.
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerBatchPostPurchaseOrders,MessageHandler')]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseOrderReplacePostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [SCENARIO 495353] Batch Posting of Purchase Order with Replace Posting Date for special Purchase Setup
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Create and Release the Purchase Order 
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Run Batch Post Purchase Order with Replace Posting Date, Replace Document Date options
        RunBatchPostPurchase(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseHeader."Posting Date" + 1, false);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader.RecordId);

        // [THEN] Posting Date is replaced with new Posting Date in the Purchase Order
        VerifyPostedPurchaseOrder(PurchaseHeader."No.", PurchaseHeader."Posting Date" + 1, false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purch. Batch Posting");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purch. Batch Posting");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();
        isInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purch. Batch Posting");
    end;

    local procedure CreateVendor(InvDisc: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        if InvDisc then
            CreateVendorDiscount(Vendor."No.");
        exit(Vendor."No.");
    end;

    local procedure CreateVendorDiscount(VendorNo: Code[20])
    var
        VendInvDisc: Record "Vendor Invoice Disc.";
    begin
        VendInvDisc.Init();
        VendInvDisc.Validate(Code, VendorNo);
        VendInvDisc.Validate("Discount %", LibraryRandom.RandInt(10));
        VendInvDisc.Insert(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; InvDisc: Boolean)
    begin
        CreatePurchaseDocumentWithQuantity(PurchaseHeader, DocumentType, InvDisc, LibraryRandom.RandIntInRange(5, 10));
    end;

    local procedure CreatePurchaseDocumentWithQuantity(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; InvDisc: Boolean; DocQuantity: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(InvDisc));
        if DocumentType = PurchaseHeader."Document Type"::"Credit Memo" then begin
            PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
            PurchaseHeader.Modify(true);
        end;
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), DocQuantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
    end;

    local procedure AddBatchProcessParameters(PurchaseHeader: Record "Purchase Header"; ParameterId: Enum "Batch Posting Parameter Type"; ParameterValue: Variant; BachSessionID: Integer; var BatchID: Guid)
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingParameter.Init();
        BatchProcessingParameter."Batch ID" := BatchID;
        BatchProcessingParameter."Parameter Id" := ParameterId.AsInteger();
        BatchProcessingParameter."Parameter Value" := Format(ParameterValue);
        BatchProcessingParameter.Insert();

        BatchProcessingSessionMap."Record ID" := PurchaseHeader.RecordId;
        BatchProcessingSessionMap."Batch ID" := BatchProcessingParameter."Batch ID";
        BatchProcessingSessionMap."User ID" := UserSecurityId();
        BatchProcessingSessionMap."Session ID" := BachSessionID;
        BatchProcessingSessionMap.Insert();
    end;

    local procedure RunBatchPostPurchase(DocumentType: Enum "Purchase Document Type"; DocumentNoFilter: Text; PostingDate: Date; CalcInvDisc: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        UpdateCalcInvDiscPurchasePayablesSetup(CalcInvDisc);
        LibraryVariableStorage.Enqueue(DocumentNoFilter);
        LibraryVariableStorage.Enqueue(PostingDate);

        Commit();
        case DocumentType of
            PurchaseHeader."Document Type"::Invoice:
                REPORT.RunModal(REPORT::"Batch Post Purchase Invoices", true, true, PurchaseHeader);
            PurchaseHeader."Document Type"::"Credit Memo":
                REPORT.RunModal(REPORT::"Batch Post Purch. Credit Memos", true, true, PurchaseHeader);
            PurchaseHeader."Document Type"::Order:
                REPORT.RunModal(REPORT::"Batch Post Purchase Orders", true, true, PurchaseHeader);
            PurchaseHeader."Document Type"::"Return Order":
                REPORT.RunModal(REPORT::"Batch Post Purch. Ret. Orders", true, true, PurchaseHeader);
        end;
    end;

    local procedure RunJobQueueFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Get(PurchaseHeader."Job Queue Entry ID");
        CODEUNIT.Run(JobQueueEntry."Object ID to Run", JobQueueEntry);
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Finished);
    end;

    local procedure UpdateCalcInvDiscPurchasePayablesSetup(CalcInvDisc: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", CalcInvDisc);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateReceiptOnInvoiceOnPurchasePayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", PurchasesPayablesSetup."Invoice Nos.");
        PurchasesPayablesSetup."Receipt on Invoice" := false;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure CreateInvoiceReportSelection()
    var
        CustomReportSelection: Record "Custom Report Selection";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.DeleteAll();
        CustomReportSelection.DeleteAll();

        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"P.Invoice";
        ReportSelections."Report ID" := REPORT::"Purchase - Invoice";
        if ReportSelections.Insert() then;
    end;

    local procedure FindAndRunJobQueueEntryByRecord(var PurchaseHeader: Record "Purchase Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        JobQueueEntry.Get(PurchaseHeader."Job Queue Entry ID");
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Modify();
        Commit();
        if not Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry) then
            LibraryJobQueue.RunJobQueueErrorHandler(JobQueueEntry);
    end;

    local procedure VerifyPostedPurchaseInvoice(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("Posting Date", PostingDate);
        PurchInvHeader.TestField("Document Date", PostingDate); // TFS ID 203294
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        Assert.AreEqual(InvDisc, PurchInvLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedPurchaseInvoiceByOrderNo(OrderNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("Posting Date", PostingDate);
        PurchInvHeader.TestField("Document Date", PostingDate);
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        Assert.AreEqual(InvDisc, PurchInvLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedPurchaseCrMemo(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoHdr.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchCrMemoHdr.FindFirst();
        PurchCrMemoHdr.TestField("Posting Date", PostingDate);
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        PurchCrMemoLine.FindFirst();
        Assert.AreEqual(InvDisc, PurchCrMemoLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedPurchaseOrder(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvHeader.SetRange("Order No.", PreAssignedNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("Posting Date", PostingDate);
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        Assert.AreEqual(InvDisc, PurchInvLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
    end;

    local procedure VerifyPostedPurchaseReturnOrder(PreAssignedNo: Code[20]; PostingDate: Date; InvDisc: Boolean)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoHdr.SetRange("Return Order No.", PreAssignedNo);
        PurchCrMemoHdr.FindFirst();
        PurchCrMemoHdr.TestField("Posting Date", PostingDate);
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        PurchCrMemoLine.FindFirst();
        Assert.AreEqual(InvDisc, PurchCrMemoLine."Inv. Discount Amount" <> 0, 'Calculate Inv. Discount value not processed correctly.');
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

    local procedure VerifyPurchHeaderNotification()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Assert.ExpectedMessage(NotificationMsg, LibraryVariableStorage.DequeueText()); // from SentNotificationHandler
        LibraryVariableStorage.AssertEmpty();
        Clear(PurchaseHeader);
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader);
    end;

    local procedure VerifyPrintJobQueueEntries(var PurchaseHeader: array[2] of Record "Purchase Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Purchase - Invoice");
        JobQueueEntry.SetRange("Report Output Type", JobQueueEntry."Report Output Type"::PDF);

        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader[1]."No.");
        PurchInvHeader.FindFirst();
        JobQueueEntry.SetRange("Record ID to Process", PurchInvHeader.RecordId);
        Assert.RecordCount(JobQueueEntry, 1);

        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader[2]."No.");
        PurchInvHeader.FindFirst();
        JobQueueEntry.SetRange("Record ID to Process", PurchInvHeader.RecordId);
        Assert.RecordCount(JobQueueEntry, 1);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostPurchaseInvoices(var BatchPostPurchaseInvoices: TestRequestPage "Batch Post Purchase Invoices")
    var
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
        RunReplacePostingDate: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostPurchaseInvoices."Purchase Header".SetFilter("No.", DocumentNoFilter);
        BatchPostPurchaseInvoices."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Invoice));

        BatchPostPurchaseInvoices.PostingDate.SetValue(PostingDate);
        RunReplacePostingDate := Format(PostingDate) <> '';
        BatchPostPurchaseInvoices.ReplacePostingDate.SetValue(RunReplacePostingDate);
        BatchPostPurchaseInvoices.ReplaceDocumentDate.SetValue(RunReplacePostingDate);
        // CalcInvDiscount is set from Purchase Setup
        BatchPostPurchaseInvoices.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostPurchaseCrMemos(var BatchPostPurchaseCrMemos: TestRequestPage "Batch Post Purch. Credit Memos")
    var
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostPurchaseCrMemos."Purchase Header".SetFilter("No.", DocumentNoFilter);
        BatchPostPurchaseCrMemos."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::"Credit Memo"));

        BatchPostPurchaseCrMemos.PostingDate.SetValue(PostingDate);
        if Format(PostingDate) <> '' then
            BatchPostPurchaseCrMemos.ReplacePostingDate.SetValue(true)
        else
            BatchPostPurchaseCrMemos.ReplacePostingDate.SetValue(false);
        // CalcInvDiscount is set from Purchase Setup
        BatchPostPurchaseCrMemos.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostPurchaseOrders(var BatchPostPurchaseOrders: TestRequestPage "Batch Post Purchase Orders")
    var
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostPurchaseOrders."Purchase Header".SetFilter("No.", DocumentNoFilter);
        BatchPostPurchaseOrders."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Order));

        BatchPostPurchaseOrders.PostingDate.SetValue(PostingDate);
        if Format(PostingDate) <> '' then
            BatchPostPurchaseOrders.ReplacePostingDate.SetValue(true)
        else
            BatchPostPurchaseOrders.ReplacePostingDate.SetValue(false);
        BatchPostPurchaseOrders.Receive.SetValue(true);
        BatchPostPurchaseOrders.Invoice.SetValue(true);
        BatchPostPurchaseOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerBatchPostPurchaseReturnOrders(var BatchPostPurchRetOrders: TestRequestPage "Batch Post Purch. Ret. Orders")
    var
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostPurchRetOrders."Purchase Header".SetFilter("No.", DocumentNoFilter);
        BatchPostPurchRetOrders."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::"Return Order"));

        BatchPostPurchRetOrders.PostingDate.SetValue(PostingDate);
        if Format(PostingDate) <> '' then
            BatchPostPurchRetOrders.ReplacePostingDate.SetValue(true)
        else
            BatchPostPurchRetOrders.ReplacePostingDate.SetValue(false);
        BatchPostPurchRetOrders.Ship.SetValue(true);
        BatchPostPurchRetOrders.Invoice.SetValue(true);
        BatchPostPurchRetOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseInvoicesPrintRequestPageHandler(var BatchPostPurchaseInvoices: TestRequestPage "Batch Post Purchase Invoices");
    var
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Variant;
        DocumentNoFilter: Variant;
        PrintVisible: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DocumentNoFilter);
        LibraryVariableStorage.Dequeue(PostingDate);

        BatchPostPurchaseInvoices."Purchase Header".SETFILTER("No.", DocumentNoFilter);
        BatchPostPurchaseInvoices."Purchase Header".SETFILTER("Document Type", FORMAT(PurchaseHeader."Document Type"::Invoice));

        PrintVisible := BatchPostPurchaseInvoices.PrintDoc.Visible();
        if PrintVisible then
            BatchPostPurchaseInvoices.PrintDoc.SetValue(true);
        BatchPostPurchaseInvoices.OK().Invoke();

        LibraryVariableStorage.Enqueue(PrintVisible);
        LibraryVariableStorage.Enqueue(0); // initialize report run counter
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReportHandler(var PurchaseInvoice: Report "Purchase - Invoice");
    begin
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger() + 1);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
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
    procedure PostBatchRequestValuesHandler1(var PostBatchForm: TestRequestPage "Batch Post Purchase Invoices")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();

        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.PostingDate.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate.SetValue(true);
            PostBatchForm.ReplaceDocumentDate.SetValue(true);
            PostBatchForm.CalcInvDisc.SetValue(not PurchasesPayablesSetup."Calc. Inv. Discount");
            PostBatchForm.PrintDoc.SetValue(true);
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.PostingDate.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplaceDocumentDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(
                PostBatchForm.CalcInvDisc.AsBoolean(),
                not PurchasesPayablesSetup."Calc. Inv. Discount",
                'Expected value to be restored.'
            );
            Assert.AreEqual(PostBatchForm.PrintDoc.AsBoolean(), true, 'Expected value to be restored.');
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBatchRequestValuesHandler2(var PostBatchForm: TestRequestPage "Batch Post Purch. Credit Memos")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();

        if LibraryVariableStorage.DequeueBoolean() then begin
            PostBatchForm.PostingDate.SetValue(20200101D);
            PostBatchForm.ReplacePostingDate.SetValue(true);
            PostBatchForm.ReplaceDocumentDate.SetValue(true);
            PostBatchForm.CalcInvDiscount.SetValue(not PurchasesPayablesSetup."Calc. Inv. Discount");
            PostBatchForm.PrintDoc.SetValue(true);
            PostBatchForm.OK().Invoke();
        end else begin
            Assert.AreEqual(PostBatchForm.PostingDate.AsDate(), 20200101D, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplacePostingDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(PostBatchForm.ReplaceDocumentDate.AsBoolean(), true, 'Expected value to be restored.');
            Assert.AreEqual(
                PostBatchForm.CalcInvDiscount.AsBoolean(),
                not PurchasesPayablesSetup."Calc. Inv. Discount",
                'Expected value to be restored.'
            );
            Assert.AreEqual(PostBatchForm.PrintDoc.AsBoolean(), true, 'Expected value to be restored.');
        end;
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatisticsUpdateVATAmountModalPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        PurchaseStatistics.SubForm.Last();
        PurchaseStatistics.SubForm."VAT Amount".SetValue(
          PurchaseStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal()); // increase VAT amount with the given value.
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatisticsUpdateVATAmountPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        PurchaseStatistics.SubForm.Last();
        PurchaseStatistics.SubForm."VAT Amount".SetValue(
          PurchaseStatistics.SubForm."VAT Amount".AsDecimal() + LibraryVariableStorage.DequeueDecimal()); // increase VAT amount with the given value.
    end;
}

