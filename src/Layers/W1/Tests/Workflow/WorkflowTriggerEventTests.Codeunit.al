codeunit 134309 "Workflow Trigger/Event Tests"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = i;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Event]
    end;

    var
        Assert: Codeunit Assert;
        NoApprovalReqToApproveErr: Label 'There is no approval request to approve.';
        NoApprovalReqToRejectErr: Label 'There is no approval request to reject.';
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        WorkflowTriggerEventTests: Codeunit "Workflow Trigger/Event Tests";
        PositiveErr: Label 'Result must be positive.';
        NegativeErr: Label 'Result must be negative.';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure NewIncDocTriggersOnCreateIncomingDocumentEvent()
    var
        IncomingDocument: Record "Incoming Document";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnCreateIncomingDocument event is triggered when a new IncomingDocument is inserted.
        // [GIVEN] Workflow with one event step, OnCreateIncomingDocument.
        // [WHEN] Incoming Document is inserted.
        // [THEN] OnCreteIncomingDocument event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode(), '', WorkflowStep);

        // Excercise
        IncomingDocument.Init();
        IncomingDocument.Insert(true);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendPurchaseInvoiceForApprovalTriggersOnPurchaseInvoiceSentForApprovalEvent()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowStep: Record "Workflow Step";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnPurchaseDocSentForApproval event is triggered when a purchase invoice is sent for
        // approval.
        // [GIVEN] Workflow with one event step, OnPurchaseDocSentForApproval.
        // [WHEN] SendPurchaseDocForApproval function in the approvals mgmt. codeunit is called.
        // [THEN] OnPurchaseDocSentForApproval event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(), '', WorkflowStep);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // Excercise
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendPurchaseInvoiceForApprovalWithNoWorkflowExitsSilently()
    var
        PurchaseHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnPurchaseDocSentForApproval event is not triggered
        // [GIVEN] Disabled Workflow with one event step, OnPurchaseDocSentForApproval.
        // [WHEN] SendPurchaseDocForApproval function in the approvals mgmt. codeunit is called.
        // [THEN] OnPurchaseDocSentForApproval event is not tiggered and the workflow is not run.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(), '', WorkflowStep);
        Workflow.Get(WorkflowStep."Workflow Code");
        DisableWorkflow(Workflow);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // Exercise
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // Verify
        asserterror VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendPurchaseInvoiceForApprovalWithReleasedStatusExitsSilently()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowStep: Record "Workflow Step";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] OnPurchaseDocSentForApproval event is not triggered when a purchase invoice whose status is not Open is sent for approval.
        // [GIVEN] Workflow with one event step, OnPurchaseDocSentForApproval.
        // [GIVEN] Purchase Invoice with Released status.
        // [WHEN] SendPurchaseDocForApproval function in the approvals mgmt. codeunit is called.
        // [THEN] OnPurchaseDocSentForApproval event is not triggered.

        // Setup
        Initialize();
        CreatePurchDocWithLine(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Status := PurchaseHeader.Status::Released;
        PurchaseHeader.Modify();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(),
          WorkflowSetup.BuildPurchHeaderTypeConditionsText(PurchaseHeader."Document Type", PurchaseHeader.Status::Open), WorkflowStep);

        // Excercise
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // Verify
        asserterror VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendSalesForApprovalTriggersOnPurchaseInvoiceSentForApprovalEvent()
    var
        SalesHeader: Record "Sales Header";
        WorkflowStep: Record "Workflow Step";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnSalesDocSentForApproval event is triggered when a sales invoice is sent for approval.
        // [GIVEN] Workflow with one event step, OnSalesDocSentForApproval.
        // [WHEN] SendSalesDocForApproval function in the approvals mgmt. codeunit is called.
        // [THEN] OnSalesDocSentForApproval event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(), '', WorkflowStep);
        CreateSalesDocWithLine(SalesHeader, SalesHeader."Document Type"::Invoice);

        // Excercise
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendSalesForApprovalWithNoWorkflowExistsSilently()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnSalesDocSentForApproval event is not triggered sales invoice is sent for approval without having an enabled approval workflow.
        // [GIVEN] Disabled Workflow with one event step, OnSalesDocSentForApproval.
        // [WHEN] SendSalesDocForApproval function in the approvals mgmt. codeunit is called.
        // [THEN] OnSalesDocSentForApproval event is not triggered.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(), '', WorkflowStep);
        Workflow.Get(WorkflowStep."Workflow Code");
        DisableWorkflow(Workflow);
        CreateSalesDocWithLine(SalesHeader, SalesHeader."Document Type"::Invoice);

        // Excercise
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Verify
        asserterror VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendSalesForApprovalWithReleasedStatusExistsSilently()
    var
        SalesHeader: Record "Sales Header";
        WorkflowStep: Record "Workflow Step";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] OnSalesDocSentForApproval event is not triggered when a sales invoice whose status is not Open is sent for approval.
        // [GIVEN] Workflow with one event step, OnSalesDocSentForApproval.
        // [GIVEN] Sales Invoice with Released status.
        // [WHEN] SendSalesDocForApproval function in the approvals mgmt. codeunit is called.
        // [THEN] OnSalesDocSentForApproval event is not triggered.

        // Setup
        Initialize();
        CreateSalesDocWithLine(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeader.Status := SalesHeader.Status::Released;
        SalesHeader.Modify();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(),
          WorkflowSetup.BuildSalesHeaderTypeConditionsText(SalesHeader."Document Type", SalesHeader.Status::Open), WorkflowStep);

        // Excercise
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Verify
        asserterror VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancellingApprovalRequestTriggersOnApprovalRequestCancelledEventPurchDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] OnApprovalRequestCancelled event is triggered when CancelApprovalRequests method in approvals mgmt. is called.
        // [GIVEN] Workflow with one event step, OnPurchaseInvoiceSentForApproval.
        // [GIVEN] Workflow with one event step, OnApprovalRequestCancelled.
        // [GIVEN] Purchase Invoice whose status is Pending Approval
        // [WHEN] CancelApprovalRequests executed.
        // [THEN] OnApprovalRequestsCancelled event is triggered.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(), '', WorkflowStep);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode(), '', WorkflowStep);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Status := PurchaseHeader.Status::"Pending Approval";
        PurchaseHeader.Modify();

        // Excercise
        ApprovalsMgmt.OnCancelPurchaseApprovalRequest(PurchaseHeader);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancellingApprovalRequestOnReleasedPurhInvExistsSilently()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] OnApprovalRequestCancelled event is not triggered when CancelApprovalRequests method is called with an released document.
        // [GIVEN] Workflow with one event step, OnPurchaseInvoiceSentForApproval.
        // [GIVEN] Purchase Invoice whose status is Released.
        // [WHEN] CancelApprovalRequests is executed.
        // [THEN] Error is thrown.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(), '', WorkflowStep);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        PurchaseHeader.Status := PurchaseHeader.Status::Released;

        // Excercise
        ApprovalsMgmt.OnCancelPurchaseApprovalRequest(PurchaseHeader);

        // Verify
        asserterror VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancellingApprovalRequestOnOpenPurchInvExistsSilently()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] OnApprovalRequestCancelled event is not triggered when CancelApprovalRequests method is called with an open document.
        // [GIVEN] Workflow with one event step, OnPurchaseInvoiceSentForApproval.
        // [GIVEN] Purchase Invoice whose status is Open.
        // [WHEN] CancelApprovalRequests is executed.
        // [THEN] Error is thrown.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(), '', WorkflowStep);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        // Excercise
        ApprovalsMgmt.OnCancelPurchaseApprovalRequest(PurchaseHeader);

        // Verify
        asserterror VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancellingApprovalRequestTriggersOnApprovalRequestCancelledEventSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] OnApprovalRequestCancelled event is triggered when CancelApprovalRequests method in approvals mgmt. is called.
        // [GIVEN] Workflow with one event step, OnSalesInvoiceSentForApproval.
        // [GIVEN] Workflow with one event step, OnApprovalRequestCancelled.
        // [GIVEN] Sales Invoice whose status is Pending Approval
        // [WHEN] CancelApprovalRequest is executed.
        // [THEN] OnApprovalRequestsCancelled event is triggered.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(), '', WorkflowStep);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode(), '', WorkflowStep);
        CreateSalesDocWithLine(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeader.Status := SalesHeader.Status::"Pending Approval";
        SalesHeader.Modify();

        // Excercise
        ApprovalsMgmt.OnCancelSalesApprovalRequest(SalesHeader);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancellingApprovalRequestOnReleasedSalesInvExistsSilently()
    var
        SalesHeader: Record "Sales Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] OnApprovalRequestCancelled event is not triggered when CancelApprovalRequests method is called with an released document.
        // [GIVEN] Workflow with one event step, OnSalesInvoiceSentForApproval.
        // [GIVEN] Sales Invoice whose status is Released.
        // [WHEN] CancelApprovalRequests is executed.
        // [THEN] Error is thrown.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(), '', WorkflowStep);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Status := SalesHeader.Status::Released;

        // Excercise
        ApprovalsMgmt.OnCancelSalesApprovalRequest(SalesHeader);

        // Verify
        asserterror VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancellingApprovalRequestOnOpenSalesInvExistsSilently()
    var
        SalesHeader: Record "Sales Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] OnApprovalRequestCancelled event is not triggered when CancelApprovalRequests method is called with an open document.
        // [GIVEN] Workflow with one event step, OnSalesInvoiceSentForApproval.
        // [GIVEN] Sales Invoice whose status is Open.
        // [WHEN] CancelApprovalRequests is executed.
        // [THEN] Error is thrown.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(), '', WorkflowStep);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        // Excercise
        ApprovalsMgmt.OnCancelSalesApprovalRequest(SalesHeader);

        // Verify
        asserterror VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnPurchaseInvoicePostedTest()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnPurchaseInvoicePostedCode event is picked up and executed for the right event trigger.
        // [GIVEN] Workflow with one event step, OnPurchaseInvoicePosted.
        // [WHEN] OnPurchaseInvoicePosted event is triggered.
        // [THEN] OnPurchaseInvoicePosted event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(), '', WorkflowStep);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // Excercise
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnPurchaseDocumentReleasedTest()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnPurchaseDocumentReleasedCode event is picked up and executed for the right event trigger.
        // [GIVEN] Workflow with one event step, OnPurchaseDocumentReleased.
        // [WHEN] OnPurchaseDocumentReleased event is triggered.
        // [THEN] OnPurchaseDocumentReleased event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnAfterReleasePurchaseDocCode(), '', WorkflowStep);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // Excercise
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnSalesDocumentReleasedTest()
    var
        SalesHeader: Record "Sales Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnSalesDocumentReleasedCode event is picked up and executed for the right event trigger.
        // [GIVEN] Workflow with one event step, OnSalesDocumentReleased.
        // [WHEN] OnSalesDocumentReleased event is triggered.
        // [THEN] OnSalesDocumentReleased event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnAfterReleaseSalesDocCode(), '', WorkflowStep);
        CreateSalesDocWithLine(SalesHeader, SalesHeader."Document Type"::Invoice);

        // Excercise
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnPaymentJournalLineCreatedTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] OnPaymentJournalLineCreated event is picked up and executed for the right event trigger.
        // [GIVEN] Workflow with one event step, OnPaymentJournalLineCreated.
        // [WHEN] OnPaymentJournalLineCreated event is triggered.
        // [THEN] OnPaymentJournalLineCreated event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnAfterInsertGeneralJournalLineCode(),
          WorkflowSetup.BuildGeneralJournalLineTypeConditions(GenJournalLine), WorkflowStep);

        // Exercise.
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine.Insert();

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovingApprovalRequestTriggersOnApprovalRequestApprovedEvent()
    var
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowInstanceID: Guid;
    begin
        // [SCENARIO] OnApprovalRequestApproved event is triggered when an approval request is approved.
        // [GIVEN] Workflow with one event step, OnApprovalRequestApproved.
        // [GIVEN] Purchase document and approval entry.
        // [WHEN] Purchase documet is approved.
        // [THEN] OnApprovalRequestApproved event step in the workflow is selected and executed.

        // Setup
        Initialize();
        WorkflowInstanceID := CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
            '', WorkflowStep);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        CreateApprovalEntryForPurchaseDoc(ApprovalEntry, PurchaseHeader, WorkflowInstanceID);

        // Excercise
        ApprovalsMgmt.ApproveRecordApprovalRequest(PurchaseHeader.RecordId);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovingWithoutApprovalRequestThrowsErr()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] OnApprovalRequestApproved event throws an error when there are not approval entries to approve.
        // [GIVEN] Workflow with one event step, OnApprovalRequestApproved.
        // [GIVEN] Purchase document and no approval entry.
        // [WHEN] Purchase documet is approved.
        // [THEN] OnApprovalRequestApproved event step in the workflow is selected, executed and an error is thrown.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(), '', WorkflowStep);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // Excercise
        asserterror ApprovalsMgmt.ApproveRecordApprovalRequest(PurchaseHeader.RecordId);

        // Verify
        Assert.ExpectedError(NoApprovalReqToApproveErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegatingApprovalRequestTriggersOnApprovalRequestDelegatedEvent()
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowStep: Record "Workflow Step";
        PurchaseHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowInstanceID: Guid;
    begin
        // [SCENARIO] OnApprovalRequestDelegated event is picked up and executed for the right event trigger.
        // [GIVEN] Workflow with one event step, OnApprovalRequestDelegated.
        // [WHEN] OnApprovalRequestDelegated event is triggered.
        // [THEN] OnApprovalRequestDelegated event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId, '');
        UserSetup.Substitute := UserId;
        UserSetup.Modify();
        WorkflowInstanceID := CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
            '', WorkflowStep);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        CreateApprovalEntryForPurchaseDoc(ApprovalEntry, PurchaseHeader, WorkflowInstanceID);

        // Excercise
        ApprovalsMgmt.DelegateRecordApprovalRequest(ApprovalEntry."Record ID to Approve");

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RejectingApprovalRequestTriggersOnApprovalRequestRejectedEvent()
    var
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowInstanceID: Guid;
    begin
        // [SCENARIO] OnApprovalRequestRejected event is picked up and executed for the right event trigger.
        // [GIVEN] Workflow with one event step, OnApprovalRequestRejected.
        // [WHEN] OnApprovalRequestRejected event is triggered.
        // [THEN] OnApprovalRequestRejected event step in the workflow is selected and executed.

        // Setup
        Initialize();
        WorkflowInstanceID := CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
            '', WorkflowStep);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        CreateApprovalEntryForPurchaseDoc(ApprovalEntry, PurchaseHeader, WorkflowInstanceID);

        // Excercise
        ApprovalsMgmt.RejectRecordApprovalRequest(PurchaseHeader.RecordId);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RejectingWithoutApprovalRequestThrowsErr()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] OnApprovalRequestRejected event is picked up and executed for the right event trigger.
        // [GIVEN] Workflow with one event step, OnApprovalRequestRejected.
        // [WHEN] OnApprovalRequestRejected event is triggered.
        // [THEN] OnApprovalRequestRejected event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(), '', WorkflowStep);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // Excercise
        asserterror ApprovalsMgmt.RejectRecordApprovalRequest(PurchaseHeader.RecordId);

        // Verify
        Assert.ExpectedError(NoApprovalReqToRejectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnSendOverdueNotificationsTest()
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnSendOverdueNotifications event is picked up and executed for the right event trigger.
        // [GIVEN] Workflow with one event step, OnSendOverdueNotifications.
        // [WHEN] OnSendOverdueNotifications event is triggered.
        // [THEN] OnSendOverdueNotifications event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendOverdueNotificationsCode(), '', WorkflowStep);

        // Excercise
        REPORT.Run(REPORT::"Send Overdue Appr. Notif.");

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnCreditLimitExceededTest()
    var
        SalesHeader: Record "Sales Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        NotificationId: Guid;
    begin
        // [SCENARIO] OnCustomerCreditLimitExceeded event is picked up and executed for the right event trigger.
        // [GIVEN] Workflow with one event step, OnCustomerCreditLimitExceeded.
        // [WHEN] OnCustomerCreditLimitExceeded event is triggered.
        // [THEN] OnCustomerCreditLimitExceeded event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateSalesDocWithLine(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceededCode(), '', WorkflowStep);

        // Excercise
        SalesHeader.OnCustomerCreditLimitExceeded(NotificationID);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnCreditLimitNotExceededTest()
    var
        SalesHeader: Record "Sales Header";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnCustomerCreditLimitNotExceeded event is picked up and executed
        // for the right event trigger.
        // [GIVEN] Workflow with one event step, OnCustomerCreditLimitNotExceeded.
        // [WHEN] OnCustomerCreditLimitNotExceeded event is triggered.
        // [THEN] OnCustomerCreditLimitNotExceeded event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateSalesDocWithLine(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode(), '', WorkflowStep);

        // Excercise
        SalesHeader.OnCustomerCreditLimitNotExceeded();

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnSendCustomerForApprovalCardTest()
    var
        WorkflowStep: Record "Workflow Step";
        Customer: Record Customer;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO] OnSendCustomerForApproval event is picked up and executed
        // for SendApprovalRequest on customer card.
        // [GIVEN] Workflow with one event step, OnSendCustomerForApproval.
        // [WHEN] OnSendCustomerForApproval event is triggered.
        // [THEN] OnSendCustomerForApproval event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode(), '', WorkflowStep);

        // Excercise
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnSendCustomerForApprovalListTest()
    var
        WorkflowStep: Record "Workflow Step";
        Customer: Record Customer;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        CustomerList: TestPage "Customer List";
    begin
        // [SCENARIO] OnSendCustomerForApproval event is picked up and executed
        // for SendApprovalRequest on customer list.
        // [GIVEN] Workflow with one event step, OnSendCustomerForApproval.
        // [WHEN] OnSendCustomerForApproval event is triggered.
        // [THEN] OnSendCustomerForApproval event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        LibrarySales.CreateCustomer(Customer);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode(), '', WorkflowStep);

        // Excercise
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);
        CustomerList.SendApprovalRequest.Invoke();

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnCancelCustomerApprovalRequestCardTest()
    var
        WorkflowStep: Record "Workflow Step";
        Customer: Record Customer;
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        CustomerCard: TestPage "Customer Card";
        WorkflowInstanceID: Guid;
    begin
        // [SCENARIO] OnCancelCustomerApprovalRequest event is picked up and executed
        // for CancelApprovalRequest on customer card.
        // [GIVEN] Workflow with one event step, OnCancelCustomerApprovalRequest.
        // [WHEN] OnCancelCustomerApprovalRequest event is triggered.
        // [THEN] OnCancelCustomerApprovalRequest event step in the workflow is selected and executed.

        // Setup
        Initialize();

        LibraryDocumentApprovals.CreateOrFindUserSetup(UserSetup, UserId);

        LibrarySales.CreateCustomer(Customer);

        // Setup - Workflow
        WorkflowInstanceID := CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnCancelCustomerApprovalRequestCode(),
            '', WorkflowStep);

        // Setup - Approval entry
        ApprovalEntry."Table ID" := DATABASE::Customer;
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Sender ID" := UserId;
        ApprovalEntry."Record ID to Approve" := Customer.RecordId;
        ApprovalEntry."Workflow Step Instance ID" := WorkflowInstanceID;
        ApprovalEntry.Insert(true);

        // Excercise
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.CancelApprovalRequest.Invoke();

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnSendVendorForApprovalCardTest()
    var
        WorkflowStep: Record "Workflow Step";
        Vendor: Record Vendor;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO] OnSendCustomerForApproval event is picked up and executed
        // for SendApprovalRequest on customer card.
        // [GIVEN] Workflow with one event step, OnSendCustomerForApproval.
        // [WHEN] OnSendCustomerForApproval event is triggered.
        // [THEN] OnSendCustomerForApproval event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode(), '', WorkflowStep);

        // Excercise
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.SendApprovalRequest.Invoke();

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnSendVendorForApprovalListTest()
    var
        WorkflowStep: Record "Workflow Step";
        Vendor: Record Vendor;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        VendorList: TestPage "Vendor List";
    begin
        // [SCENARIO] OnSendCustomerForApproval event is picked up and executed
        // for SendApprovalRequest on customer list.
        // [GIVEN] Workflow with one event step, OnSendCustomerForApproval.
        // [WHEN] OnSendCustomerForApproval event is triggered.
        // [THEN] OnSendCustomerForApproval event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode(), '', WorkflowStep);

        // Excercise
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);
        VendorList.SendApprovalRequest.Invoke();

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnCancelVendorApprovalRequestCardTest()
    var
        WorkflowStep: Record "Workflow Step";
        Vendor: Record Vendor;
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        VendorCard: TestPage "Vendor Card";
        WorkflowInstanceID: Guid;
    begin
        // [SCENARIO] OnCancelCustomerApprovalRequest event is picked up and executed
        // for CancelApprovalRequest on customer card.
        // [GIVEN] Workflow with one event step, OnCancelCustomerApprovalRequest.
        // [WHEN] OnCancelCustomerApprovalRequest event is triggered.
        // [THEN] OnCancelCustomerApprovalRequest event step in the workflow is selected and executed.

        // Setup
        Initialize();

        LibraryDocumentApprovals.CreateOrFindUserSetup(UserSetup, UserId);

        LibraryPurchase.CreateVendor(Vendor);

        // Setup - Workflow
        WorkflowInstanceID := CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnCancelVendorApprovalRequestCode(),
            '', WorkflowStep);

        // Setup - Approval entry
        ApprovalEntry."Table ID" := DATABASE::Vendor;
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Sender ID" := UserId;
        ApprovalEntry."Record ID to Approve" := Vendor.RecordId;
        ApprovalEntry."Workflow Step Instance ID" := WorkflowInstanceID;
        ApprovalEntry.Insert(true);

        // Excercise
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.CancelApprovalRequest.Invoke();

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnSendItemForApprovalCardTest()
    var
        WorkflowStep: Record "Workflow Step";
        Item: Record Item;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO] OnSendCustomerForApproval event is picked up and executed
        // for SendApprovalRequest on customer card.
        // [GIVEN] Workflow with one event step, OnSendCustomerForApproval.
        // [WHEN] OnSendCustomerForApproval event is triggered.
        // [THEN] OnSendCustomerForApproval event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode(), '', WorkflowStep);

        // Excercise
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard.SendApprovalRequest.Invoke();

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnSendItemForApprovallListTest()
    var
        WorkflowStep: Record "Workflow Step";
        Item: Record Item;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO] OnSendCustomerForApproval event is picked up and executed
        // for SendApprovalRequest on customer list.
        // [GIVEN] Workflow with one event step, OnSendCustomerForApproval.
        // [WHEN] OnSendCustomerForApproval event is triggered.
        // [THEN] OnSendCustomerForApproval event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryInventory.CreateItem(Item);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode(), '', WorkflowStep);

        // Excercise
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);
        ItemList.SendApprovalRequest.Invoke();

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnCancelItemApprovalRequestCardTest()
    var
        WorkflowStep: Record "Workflow Step";
        Item: Record Item;
        ApprovalEntry: Record "Approval Entry";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ItemCard: TestPage "Item Card";
        WorkflowInstanceID: Guid;
    begin
        // [SCENARIO] OnCancelCustomerApprovalRequest event is picked up and executed
        // for CancelApprovalRequest on customer card.
        // [GIVEN] Workflow with one event step, OnCancelCustomerApprovalRequest.
        // [WHEN] OnCancelCustomerApprovalRequest event is triggered.
        // [THEN] OnCancelCustomerApprovalRequest event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryInventory.CreateItem(Item);

        // Setup - Workflow
        WorkflowInstanceID := CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnCancelItemApprovalRequestCode(),
            '', WorkflowStep);

        // Setup - Approval entry
        ApprovalEntry."Table ID" := DATABASE::Item;
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Record ID to Approve" := Item.RecordId;
        ApprovalEntry."Workflow Step Instance ID" := WorkflowInstanceID;
        ApprovalEntry.Insert(true);

        // Excercise
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard.CancelApprovalRequest.Invoke();

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunWorkflowOnGeneralJournalBatchBalancedTest()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] RunWorkflowOnGeneralJournalBatchBalanced event is picked up and executed
        // for the right event trigger.
        // [GIVEN] Workflow with one event step, RunWorkflowOnGeneralJournalBatchBalanced.
        // [WHEN] RunWorkflowOnGeneralJournalBatchBalanced event is triggered.
        // [THEN] RunWorkflowOnGeneralJournalBatchBalanced event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnGeneralJournalBatchBalancedCode(), '', WorkflowStep);

        // Excercise
        WorkflowEventHandling.RunWorkflowOnGeneralJournalBatchBalanced(GenJournalBatch);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunWorkflowOnGeneralJournalBatchNotBalancedTest()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] RunWorkflowOnGeneralJournalBatchNotBalanced event is picked up and executed
        // for the right event trigger.
        // [GIVEN] Workflow with one event step, RunWorkflowOnGeneralJournalBatchNotBalanced.
        // [WHEN] RunWorkflowOnGeneralJournalBatchNotBalanced event is triggered.
        // [THEN] RunWorkflowOnGeneralJournalBatchNotBalanced event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnGeneralJournalBatchNotBalancedCode(), '', WorkflowStep);

        // Excercise
        WorkflowEventHandling.RunWorkflowOnGeneralJournalBatchNotBalanced(GenJournalBatch);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunWorkflowOnCustomerRecordChangedTest()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] RunWorkflowOnCustomerRecordChanged event is picked up and executed
        // for the right event trigger.
        // [GIVEN] Workflow with one event step, RunWorkflowOnCustomerRecordChanged.
        // [WHEN] RunWorkflowOnGeneralJournalBatchNotBalanced event is triggered.
        // [THEN] RunWorkflowOnGeneralJournalBatchNotBalanced event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(Customer2);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnCustomerChangedCode(), '', WorkflowStep);

        Customer2."Credit Limit (LCY)" := LibraryRandom.RandDec(100, 2);
        Customer2.Modify();

        // Excercise
        WorkflowEventHandling.RunWorkflowOnCustomerChanged(Customer, Customer2, true);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunWorkflowOnVendorRecordChangedTest()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] RunWorkflowOnCustomerRecordChanged event is picked up and executed
        // for the right event trigger.
        // [GIVEN] Workflow with one event step, RunWorkflowOnCustomerRecordChanged.
        // [WHEN] RunWorkflowOnGeneralJournalBatchNotBalanced event is triggered.
        // [THEN] RunWorkflowOnGeneralJournalBatchNotBalanced event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendor(Vendor2);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnVendorChangedCode(), '', WorkflowStep);

        Vendor2."Phone No." := Format(LibraryRandom.RandIntInRange(10000000, 9999999));
        Vendor2.Modify();

        // Excercise
        WorkflowEventHandling.RunWorkflowOnVendorChanged(Vendor, Vendor2, true);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CreateNewVendorStrMenuHandler,VendorTempModalFormHandler')]
    procedure RunWorkflowOnVendorRecordCreatedBasedOnTheDescriptionSetOnPurchaseOrder()
    var
        Vendor: Record Vendor;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // Setup
        Initialize();

        // [GIVEN] Workflow created and enabled 
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnVendorChangedCode(), '', WorkflowStep);

        // [WHEN] Vendor is created from Purchase Order
        Vendor.GetVendorNoOpenCard(LibraryRandom.RandText(20), false);

        // [THEN] Event steps in the workflow are executed and completed.
        VerifyArchivedWorkflowStepInstanceIsCompleted2(WorkflowStep, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CreateNewCustomerStrMenuHandler,CustomerTempModalFormHandler')]
    procedure RunWorkflowOnCustomerRecordCreatedBasedOnTheDescriptionSetOnSalesOrder()
    var
        Customer: Record Customer;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // Setup
        Initialize();

        // [GIVEN] Workflow created and enabled 
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnCustomerChangedCode(), '', WorkflowStep);

        // [WHEN] Customer is created from Sales Order
        Customer.GetCustNoOpenCard(LibraryRandom.RandText(20), false, true);

        // [THEN] Event steps in the workflow are executed and completed.
        VerifyArchivedWorkflowStepInstanceIsCompleted2(WorkflowStep, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunWorkflowOnItemRecordChangedTest()
    var
        Item: Record Item;
        Item2: Record Item;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] RunWorkflowOnCustomerRecordChanged event is picked up and executed
        // for the right event trigger.
        // [GIVEN] Workflow with one event step, RunWorkflowOnCustomerRecordChanged.
        // [WHEN] RunWorkflowOnGeneralJournalBatchNotBalanced event is triggered.
        // [THEN] RunWorkflowOnGeneralJournalBatchNotBalanced event step in the workflow is selected and executed.

        // Setup
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnItemChangedCode(), '', WorkflowStep);

        Item2."Unit Price" := LibraryRandom.RandDec(100, 2);
        Item2.Modify();

        // Excercise
        WorkflowEventHandling.RunWorkflowOnItemChanged(Item, Item2, true);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunWorkflowOnItemRecordChangedInPreviewTest()
    var
        WorkflowStep: Record "Workflow Step";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        // [SCENARIO] RunWorkflowOnCustomerRecordChanged event is picked up and executed
        // for the right event trigger.
        // [GIVEN] Workflow with one event step, RunWorkflowOnCustomerRecordChanged.
        // [WHEN] RunWorkflowOnGeneralJournalBatchNotBalanced event is triggered.
        // [THEN] RunWorkflowOnGeneralJournalBatchNotBalanced event step in the workflow is selected and executed.

        // Excercise
        BindSubscription(WorkflowTriggerEventTests);
        asserterror GenJnlPostPreview.Preview(WorkflowTriggerEventTests, WorkflowStep);
        UnbindSubscription(WorkflowTriggerEventTests);

        // Verify
        Assert.AreEqual('', GetLastErrorText, 'Empty error expected form Posting Preview');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    [Normal]
    local procedure OnRunPreviewTestForOnItemChangeTest(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        Item: Record Item;
        Item2: Record Item;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // Setup
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnItemChangedCode(), '', WorkflowStep);

        Item2."Unit Price" := LibraryRandom.RandDec(100, 2);
        Item2.Modify();

        // Excercise
        WorkflowEventHandling.RunWorkflowOnItemChanged(Item, Item2, true);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsNOTCompleted(WorkflowStep);

        // Return for posting
        Result := false;
        Error('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccessTest()
    var
        IncomingDocument: Record "Incoming Document";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnAfterCreateGenJnlLineFromIncomingDocSuccess event is triggered
        // when a General Journal Line is successfully created from Incoming document.
        // [GIVEN] Workflow with one event step, OnAfterCreateGenJnlLineFromIncomingDocSuccess.
        // [WHEN] General Journal Line is successfully created from Incoming Document.
        // [THEN] OnAfterCreateGenJnlLineFromIncomingDocSuccess event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(
          WorkflowEventHandling.RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocSuccessCode(), '', WorkflowStep);

        // Excercise
        IncomingDocument.Init();
        IncomingDocument.Insert(true);

        IncomingDocument.OnAfterCreateGenJnlLineFromIncomingDocSuccess(IncomingDocument);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocFailTest()
    var
        IncomingDocument: Record "Incoming Document";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] OnAfterCreateGenJnlLineFromIncomingDocSuccess event is triggered
        // when creating General Journal Line from Incoming document fails.
        // [GIVEN] Workflow with one event step, OnAfterCreateGenJnlLineFromIncomingDocFail.
        // [WHEN] Failure while creating General Journal Line from Incoming Document.
        // [THEN] OnAfterCreateGenJnlLineFromIncomingDocFail event step in the workflow is selected and executed.

        // Setup
        Initialize();
        CreateAndEnableOneEventStepWorkflow(
          WorkflowEventHandling.RunWorkflowOnAfterCreateGenJnlLineFromIncomingDocFailCode(), '', WorkflowStep);

        // Excercise
        IncomingDocument.Init();
        IncomingDocument.Insert(true);

        IncomingDocument.OnAfterCreateGenJnlLineFromIncomingDocFail(IncomingDocument);

        // Verify
        VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendChangedItemForApprovalWithItemChangeWorkflow()
    var
        Item: Record Item;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        Result: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 231847] When Item is changed and only Item Change Workflow is enabled, no errors invoked when push SendApprovalRequest actionbutton.
        Initialize();

        LibraryInventory.CreateItem(Item);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnItemChangedCode(), '', WorkflowStep);

        Result := ApprovalsMgmt.CheckItemApprovalsWorkflowEnabled(Item);
        Assert.IsFalse(Result, NegativeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendChangedItemForApprovalWithItemChangeAndItemApprovalWorkflow()
    var
        Item: Record Item;
        WorkflowStep: array[2] of Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        Result: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 231847] When Item is changed and both Item Change Workflow with Item Approval Workflow are enabled, SendApprovalRequest actionbutton causes no errors.
        Initialize();

        LibraryInventory.CreateItem(Item);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnItemChangedCode(), '', WorkflowStep[1]);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode(), '', WorkflowStep[2]);

        Result := ApprovalsMgmt.CheckItemApprovalsWorkflowEnabled(Item);
        Assert.IsTrue(Result, PositiveErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendChangedCustomerForApprovalWithCustomerChangeWorkflow()
    var
        Customer: Record Customer;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        Result: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 231847] When Customer is changed and only Customer Change Workflow is enabled, no errors invoked when push SendApprovalRequest actionbutton.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnCustomerChangedCode(), '', WorkflowStep);

        Result := ApprovalsMgmt.CheckCustomerApprovalsWorkflowEnabled(Customer);
        Assert.IsFalse(Result, NegativeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendChangedCustomerForApprovalWithCustomerChangeAndCustomerApprovalWorkflow()
    var
        Customer: Record Customer;
        WorkflowStep: array[2] of Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        Result: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 231847] When Customer is changed and both Customer Change Workflow with Customer Approval Workflow are enabled, SendApprovalRequest actionbutton causes no errors.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnCustomerChangedCode(), '', WorkflowStep[1]);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode(), '', WorkflowStep[2]);

        Result := ApprovalsMgmt.CheckCustomerApprovalsWorkflowEnabled(Customer);
        Assert.IsTrue(Result, PositiveErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendChangedVendorForApprovalWithVendorChangeWorkflow()
    var
        Vendor: Record Vendor;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        Result: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 231847] When Vendor is changed and only Vendor Change Workflow is enabled, no errors invoked when push SendApprovalRequest actionbutton.
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnVendorChangedCode(), '', WorkflowStep);

        Result := ApprovalsMgmt.CheckVendorApprovalsWorkflowEnabled(Vendor);
        Assert.IsFalse(Result, NegativeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendChangedVendorForApprovalWithVendorChangeAndVendorApprovalWorkflow()
    var
        Vendor: Record Vendor;
        WorkflowStep: array[2] of Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        Result: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 231847] When Vendor is changed and both Vendor Change Workflow with Vendor Approval Workflow are enabled, SendApprovalRequest actionbutton causes no errors.
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnVendorChangedCode(), '', WorkflowStep[1]);
        CreateAndEnableOneEventStepWorkflow(WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode(), '', WorkflowStep[2]);

        Result := ApprovalsMgmt.CheckVendorApprovalsWorkflowEnabled(Vendor);
        Assert.IsTrue(Result, PositiveErr);
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Workflow Trigger/Event Tests");
        LibraryWorkflow.DeleteAllExistingWorkflows();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryApplicationArea.EnableFoundationSetup();
        UserSetup.DeleteAll();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Workflow Trigger/Event Tests");
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Workflow Trigger/Event Tests");
    end;

    local procedure CreateAndEnableOneEventStepWorkflow(EventCode: Code[128]; EventConditions: Text; var WorkflowStep: Record "Workflow Step"): Guid
    var
        Workflow: Record Workflow;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        WorkflowStep.Get(Workflow.Code, LibraryWorkflow.InsertEntryPointEventStep(Workflow, EventCode));
        if EventConditions <> '' then
            LibraryWorkflow.InsertEventArgument(WorkflowStep.ID, EventConditions);

        EnableWorkflow(Workflow);
        exit(CreateWorkflowInstance(Workflow));
    end;

    local procedure EnableWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Enabled := true;
        Workflow.Modify(true);
    end;

    local procedure DisableWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Enabled := false;
        Workflow.Modify(true);
    end;

    local procedure CreateWorkflowInstance(Workflow: Record Workflow): Guid
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        Workflow.CreateInstance(WorkflowStepInstance);
        WorkflowStepInstance.FindFirst();
        WorkflowStepInstance.Status := WorkflowStepInstance.Status::Active;
        WorkflowStepInstance.Modify();
        exit(WorkflowStepInstance.ID);
    end;

    local procedure VerifyArchivedWorkflowStepInstanceIsCompleted(WorkflowStep: Record "Workflow Step")
    var
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        WorkflowStepInstanceArchive.SetRange("Original Workflow Code", WorkflowStep."Workflow Code");
        WorkflowStepInstanceArchive.SetRange("Original Workflow Step ID", WorkflowStep.ID);
        WorkflowStepInstanceArchive.SetRange(Type, WorkflowStep.Type);
        WorkflowStepInstanceArchive.SetRange("Function Name", WorkflowStep."Function Name");
        WorkflowStepInstanceArchive.FindFirst();
        Assert.AreEqual(1, WorkflowStepInstanceArchive.Count, WorkflowStepInstanceArchive.GetFilters);
        WorkflowStepInstanceArchive.TestField(Status, WorkflowStepInstanceArchive.Status::Completed);
    end;

    local procedure VerifyArchivedWorkflowStepInstanceIsCompleted2(WorkflowStep: Record "Workflow Step"; ExpectedStepsCount: Integer)
    var
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        WorkflowStepInstanceArchive.SetRange("Original Workflow Code", WorkflowStep."Workflow Code");
        WorkflowStepInstanceArchive.SetRange("Original Workflow Step ID", WorkflowStep.ID);
        WorkflowStepInstanceArchive.SetRange(Type, WorkflowStep.Type);
        WorkflowStepInstanceArchive.SetRange("Function Name", WorkflowStep."Function Name");
        WorkflowStepInstanceArchive.FindFirst();
        Assert.AreEqual(ExpectedStepsCount, WorkflowStepInstanceArchive.Count, WorkflowStepInstanceArchive.GetFilters);
        WorkflowStepInstanceArchive.TestField(Status, WorkflowStepInstanceArchive.Status::Completed);
    end;

    local procedure VerifyArchivedWorkflowStepInstanceIsNOTCompleted(WorkflowStep: Record "Workflow Step")
    var
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        WorkflowStepInstanceArchive.SetRange("Original Workflow Code", WorkflowStep."Workflow Code");
        Assert.AreEqual(0, WorkflowStepInstanceArchive.Count, WorkflowStepInstanceArchive.GetFilters);
    end;

    local procedure CreatePurchDocWithLine(var PurchHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type")
    var
        Item: Record Item;
        PurchLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 1));
        PurchLine.Modify(true);
    end;

    local procedure CreateSalesDocWithLine(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        SalesLine.Validate("Unit Cost", LibraryRandom.RandDec(1000, 1));
        SalesLine.Modify(true);
    end;

    local procedure CreateApprovalEntryForPurchaseDoc(var ApprovalEntry: Record "Approval Entry"; PurchaseHeader: Record "Purchase Header"; WorkflowInstanceID: Guid)
    var
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Table ID" := DATABASE::"Purchase Header";
        ApprovalEntry."Document Type" := EnumAssignmentMgt.GetPurchApprovalDocumentType(PurchaseHeader."Document Type");
        ApprovalEntry."Document No." := PurchaseHeader."No.";
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry."Record ID to Approve" := PurchaseHeader.RecordId;
        ApprovalEntry."Workflow Step Instance ID" := WorkflowInstanceID;
        ApprovalEntry.Insert();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CreateNewVendorStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorTempModalFormHandler(var VendorTemplateList: Page "Select Vendor Templ. List"; var Reply: Action)
    begin
        Reply := Action::LookupOK;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CreateNewCustomerStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTempModalFormHandler(var CustomerTemplateList: Page "Select Customer Templ. List"; var Reply: Action)
    begin
        Reply := Action::LookupOK;
    end;
}

