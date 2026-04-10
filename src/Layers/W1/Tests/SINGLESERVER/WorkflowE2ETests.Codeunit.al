codeunit 134302 "Workflow E2E Tests"
{
    Permissions = TableData "Approval Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        NotificationEntryFoundErr: Label 'Notification Entry should not be created for a Purchase Invoice not based on Incoming Document.';
        UserEmailAddressTxt: Label 'test@contoso.com', Locked = true;
        CustomURLTxt: Label '//customurl';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestWorkflowInstaceIsNotDeletedWhenNotAllStepsAreExecuted()
    var
        IncomingDocument: Record "Incoming Document";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        ResponseStep: Integer;
        EventStep: Integer;
    begin
        // [SCENARIO] When only one step of the workflow is executed, it will not be deleted.
        // [GIVEN] There is a workflow starting from Incoming Document.
        // [WHEN] An Incoming Document record is created.
        // [THEN] One workflow step is executed and the instance is not deleted.

        // Setup
        Initialize();
        LibraryIncomingDocuments.InitIncomingDocuments();

        CreateWorkflow(Workflow);

        EntryPointEventStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        ResponseStep := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            EntryPointEventStep);
        LibraryWorkflow.InsertNotificationArgument(ResponseStep, UserId, 0, '');

        EventStep :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(), ResponseStep);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), EventStep);

        EnableWorkflow(Workflow.Code);

        // Execute
        BindSubscription(LibraryJobQueue);
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        UnbindSubscription(LibraryJobQueue);

        // Validate
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsFalse(WorkflowStepInstance.IsEmpty, 'The workflow instance should exist after it is executed.');
        ValidateArchivedSteps(Workflow.Code, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowInstaceIsDeletedWhenMultipleStepsAreExecuted()
    var
        PurchaseHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        ResponseStep: Integer;
        ResponseStep2: Integer;
        EventStep: Integer;
    begin
        // [SCENARIO] When the step of the workflow is executed, it will be deleted.
        // [GIVEN] There is a workflow starting from Incoming Document.
        // [WHEN] An Incoming Document record is created.
        // [THEN] The workflow step is executed and the instance is deleted.

        // Setup
        Initialize();
        LibraryIncomingDocuments.InitIncomingDocuments();

        CreateWorkflow(Workflow);

        EntryPointEventStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterReleasePurchaseDocCode());
        ResponseStep := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            EntryPointEventStep);
        LibraryWorkflow.InsertNotificationArgument(ResponseStep, UserId, 0, '');

        EventStep :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(), ResponseStep);
        ResponseStep2 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), EventStep);
        LibraryWorkflow.InsertNotificationArgument(ResponseStep2, UserId, 0, '');

        EnableWorkflow(Workflow.Code);
        CreatePurchaseInvBasedOnIncomingDoc(PurchaseHeader);

        // Execute
        BindSubscription(LibraryJobQueue);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);
        UnbindSubscription(LibraryJobQueue);

        // Validate
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, 'The workflow instance should not exist after it is executed.');
        ValidateArchivedSteps(Workflow.Code, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestSendingApprovalRequestForPurchInvGeneratesNotification()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        NotificationEntry: Record "Notification Entry";
        PurchaseHeader: Record "Purchase Header";
        RequestorUserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        TriggeredByRecordRef: RecordRef;
        TableIDFieldRef: FieldRef;
    begin
        // [SCENARIO] Approver is notified when a Purhcase Invoice is sent for approval
        // [GIVEN] Workflow is set up to notify Stan.
        // [GIVEN] Purchase Invoice created.
        // [WHEN] Cassie Sends the purchase invoice for Approval.
        // [THEN] Status of the Purchase Invoice is Pending Approval.
        // [THEN] Notificaiton Entry is created for Stan.

        // Pre-Setup
        Initialize();
        SetupUsersForApproval(RequestorUserSetup, ApproverUserSetup);
        CreatePurchInvLoopbackWorkflow(Workflow);
        EnableWorkflow(Workflow.Code);

        // Setup
        CreatePurchaseInvoice(PurchaseHeader);

        // Pre-Exercise
        PurchaseHeader.Validate("Purchaser Code", RequestorUserSetup."Salespers./Purch. Code");
        PurchaseHeader.Modify(true);

        // Exercise
        BindSubscription(LibraryJobQueue);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);
        UnbindSubscription(LibraryJobQueue);

        // Verify
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::"Pending Approval");
        FindNotificationEntry(NotificationEntry,
          ApproverUserSetup."User ID", NotificationEntry.Type::Approval, RequestorUserSetup."User ID");
        TriggeredByRecordRef.Get(NotificationEntry."Triggered By Record");
        TableIDFieldRef := TriggeredByRecordRef.Field(ApprovalEntry.FieldNo("Table ID"));

        TableIDFieldRef.TestField(DATABASE::"Purchase Header");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestAutoApprovalOfPurchInvDoesNotGenerateNotification()
    var
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        PurchaseHeader: Record "Purchase Header";
        RequestorUserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] Approver is not notified when a Purhcase Invoice is auto-approved
        // [GIVEN] Workflow is set up to notify Stan.
        // [GIVEN] Purchase Invoice created.
        // [WHEN] Cassie Sends the approval invoice for Approval.
        // [THEN] Document is auto-approved.
        // [THEN] Notification Entry is not created for Stan.

        // Pre-Setup
        Initialize();
        SetupUsersForApproval(RequestorUserSetup, ApproverUserSetup);
        RequestorUserSetup."Approver ID" := RequestorUserSetup."User ID";
        RequestorUserSetup.Modify();

        CreatePurchInvLoopbackWorkflow(Workflow);
        EnableWorkflow(Workflow.Code);

        // Setup
        CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Purchaser Code", RequestorUserSetup."Salespers./Purch. Code");
        PurchaseHeader.Modify(true);

        // Exercise
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // Verify
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);
        Assert.IsFalse(
          IsEmailNotificationEntryCreated(ApproverUserSetup."User ID", DATABASE::"Approval Entry", RequestorUserSetup."User ID"),
          NotificationEntryFoundErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRejectingApprovalRequestForPurchInvGeneratesNotification()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalNotificationEntry: Record "Notification Entry";
        ApproverUserSetup: Record "User Setup";
        PurchaseHeader: Record "Purchase Header";
        RequestorUserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApproverTriggeredByRecRef: RecordRef;
        ApproverTableIDFieldRef: FieldRef;
    begin
        // [SCENARIO 210514] Approver is notified when a Purchase Invoice is sent for approval
        // [GIVEN] Workflow is set up to notify Stan.
        // [GIVEN] Purchase Invoice created.
        // [GIVEN] Cassie sent approval request for the Purchase Invoice to Stan
        // [WHEN] Stan rejects approval request.
        // [THEN] Status of the Purchase Invoice is set to Open.
        // [THEN] Notification Entries are created for Stan only.

        // Pre-Setup
        Initialize();
        SetupUsersForApproval(RequestorUserSetup, ApproverUserSetup);
        CreatePurchInvLoopbackWorkflow(Workflow);
        EnableWorkflow(Workflow.Code);

        // Setup
        CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Purchaser Code", RequestorUserSetup."Salespers./Purch. Code");
        PurchaseHeader.Modify(true);
        BindSubscription(LibraryJobQueue);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);
        UnbindSubscription(LibraryJobQueue);

        // Pre-Exercise
        FindApprovalEntry(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."Document Type", PurchaseHeader."No.");
        ApprovalEntry.ModifyAll("Sender ID", RequestorUserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", RequestorUserSetup."User ID", true);

        // Exercise
        BindSubscription(LibraryJobQueue);
        ApprovalsMgmt.RejectRecordApprovalRequest(PurchaseHeader.RecordId);
        UnbindSubscription(LibraryJobQueue);

        // Post-Exercise
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchaseHeader."No.");
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);

        // Pre-Verify
        FindNotificationEntry(ApprovalNotificationEntry,
          ApproverUserSetup."User ID", ApprovalNotificationEntry.Type::Approval, RequestorUserSetup."User ID");

        ApproverTriggeredByRecRef.Get(ApprovalNotificationEntry."Triggered By Record");
        ApproverTableIDFieldRef := ApproverTriggeredByRecRef.Field(ApprovalEntry.FieldNo("Table ID"));

        // Verify
        ApproverTableIDFieldRef.TestField(DATABASE::"Purchase Header");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRejectingApprovalRequestForPurchInvWithLoopbackToEvent()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApproveWorkflowStep: Record "Workflow Step";
        ApproverUserSetup: Record "User Setup";
        PurchaseHeader: Record "Purchase Header";
        RejectWorkflowStep: Record "Workflow Step";
        RequestorUserSetup: Record "User Setup";
        SendForApprovalWorkflowStep: Record "Workflow Step";
        WorkflowStepInstance: Record "Workflow Step Instance";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] Branch out to a previous step using a loop
        // [GIVEN] Workflow Steps for Rejecting an approval request of a Purchase Invoice that loops back to an event.
        // [WHEN] Workflow Step Instance followed by a loopback step is executed.
        // [THEN] Status of the current step is Completed, siblings are Ignored, and children are blank.
        // [THEN] Status of the loopback step remains Completed and siblings are Ignored.
        // [THEN] Status of the children of the loopback step are Active.

        // ===================================
        // #   [Send for Approval] <----|
        // #             |              |
        // #            / \             |
        // #   [Approve]   [Reject] ----|
        // #       |
        // #  [Auto-Post]
        // ===================================

        Initialize();

        // Pre-Setup
        SetupUsersForApproval(RequestorUserSetup, ApproverUserSetup);
        CreatePurchInvLoopbackWorkflow(Workflow);

        EnableWorkflow(Workflow.Code);

        // Setup
        CreatePurchaseInvBasedOnIncomingDoc(PurchaseHeader);
        BindSubscription(LibraryJobQueue);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);
        UnbindSubscription(LibraryJobQueue);

        // Pre-Exercise
        FindApprovalEntry(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."Document Type", PurchaseHeader."No.");
        ApprovalEntry.ModifyAll("Sender ID", RequestorUserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", RequestorUserSetup."User ID", true);

        // Exercise
        BindSubscription(LibraryJobQueue);
        ApprovalsMgmt.RejectRecordApprovalRequest(PurchaseHeader.RecordId);
        UnbindSubscription(LibraryJobQueue);

        // Verify.
        FindWorkflowStep(SendForApprovalWorkflowStep,
          Workflow.Code, SendForApprovalWorkflowStep.Type::"Event", WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
        VerifyWorkflowStepInstance(SendForApprovalWorkflowStep, WorkflowStepInstance.Status::Active);

        FindWorkflowStep(ApproveWorkflowStep,
          Workflow.Code, SendForApprovalWorkflowStep.Type::"Event", WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
        VerifyWorkflowStepInstance(ApproveWorkflowStep, WorkflowStepInstance.Status::Ignored);

        FindWorkflowStep(RejectWorkflowStep,
          Workflow.Code, SendForApprovalWorkflowStep.Type::"Event", WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode());
        VerifyWorkflowStepInstance(RejectWorkflowStep, WorkflowStepInstance.Status::Completed);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRejectingApprovalRequestForPurchInvWithLoopbackToResponse()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        OnApprovedEventWorkflowStep: Record "Workflow Step";
        ApproverUserSetup: Record "User Setup";
        PurchaseHeader: Record "Purchase Header";
        OnRejectedEventWorkflowStep: Record "Workflow Step";
        OnRejectedRespWorkflowStep: Record "Workflow Step";
        RequestorUserSetup: Record "User Setup";
        OnSentForApprovalRespWorkflowStep: Record "Workflow Step";
        WorkflowStepInstance: Record "Workflow Step Instance";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] Branch out to a previous step using a loop
        // [GIVEN] Workflow Steps for Rejecting an approval request of a Purchase Invoice that loops back to a response.
        // [WHEN] Workflow Step Instance followed by a loopback step is executed.
        // [THEN] Status of the current step is Completed, siblings are Ignored, and children are blank.
        // [THEN] Status of the loopback step remains Completed and siblings are Ignored.
        // [THEN] Status of the children of the loopback step are Active.

        // ===================================
        // #   [Send for Approval] <----|
        // #             |              |
        // #            / \             |
        // #   [Approve]   [Reject] ----|
        // #       |
        // #  [Auto-Post]
        // ===================================

        Initialize();

        // Pre-Setup
        SetupUsersForApproval(RequestorUserSetup, ApproverUserSetup);
        CreatePurchInvLoopbackWorkflow(Workflow);

        FindWorkflowStep(OnRejectedRespWorkflowStep,
          Workflow.Code, OnRejectedRespWorkflowStep.Type::Response, WorkflowResponseHandling.OpenDocumentCode());
        FindWorkflowStep(OnSentForApprovalRespWorkflowStep,
          Workflow.Code, OnSentForApprovalRespWorkflowStep.Type::Response, WorkflowResponseHandling.SendApprovalRequestForApprovalCode());
        EnableWorkflow(Workflow.Code);

        // Setup
        CreatePurchaseInvBasedOnIncomingDoc(PurchaseHeader);
        BindSubscription(LibraryJobQueue);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);
        UnbindSubscription(LibraryJobQueue);

        // Pre-Exercise
        FindApprovalEntry(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."Document Type", PurchaseHeader."No.");
        ApprovalEntry.ModifyAll("Sender ID", RequestorUserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", RequestorUserSetup."User ID", true);

        // Exercise
        BindSubscription(LibraryJobQueue);
        ApprovalsMgmt.RejectRecordApprovalRequest(PurchaseHeader.RecordId);
        UnbindSubscription(LibraryJobQueue);

        // Verify.
        VerifyWorkflowStepInstance(OnSentForApprovalRespWorkflowStep, WorkflowStepInstance.Status::Completed);
        VerifyWorkflowStepInstance(OnRejectedRespWorkflowStep, WorkflowStepInstance.Status::Completed);

        FindWorkflowStep(OnApprovedEventWorkflowStep,
          Workflow.Code, OnApprovedEventWorkflowStep.Type::"Event", WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
        VerifyWorkflowStepInstance(OnApprovedEventWorkflowStep, WorkflowStepInstance.Status::Ignored);

        FindWorkflowStep(OnRejectedEventWorkflowStep,
          Workflow.Code, OnRejectedEventWorkflowStep.Type::"Event", WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode());
        VerifyWorkflowStepInstance(OnRejectedEventWorkflowStep, WorkflowStepInstance.Status::Completed);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestRejectingApprovalRequestForPurchInvWithoutLoopback()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApproveWorkflowStep: Record "Workflow Step";
        ApproverUserSetup: Record "User Setup";
        PurchaseHeader: Record "Purchase Header";
        RejectResponseWorkflowStep: Record "Workflow Step";
        RequestorUserSetup: Record "User Setup";
        SendForApprovalWorkflowStep: Record "Workflow Step";
        WorkflowStepInstance: Record "Workflow Step Instance";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] Don't branch out to a previous step.
        // [GIVEN] Workflow Steps for Rejecting an approval request of a Purchase Invoice.
        // [WHEN] Workflow Step Instance not followed by a loopback step is executed.
        // [THEN] Status of the current step is Completed, siblings are Ignored, and children are Active.

        // ===================================
        // #    [Send for approval]
        // #             |
        // #            / \
        // #   [Approve]   [Reject]
        // #       |
        // #  [Auto-Post]
        // ===================================

        Initialize();

        // Pre-Setup
        SetupUsersForApproval(RequestorUserSetup, ApproverUserSetup);
        CreatePurchInvLoopbackWorkflow(Workflow);

        FindWorkflowStep(RejectResponseWorkflowStep,
          Workflow.Code, SendForApprovalWorkflowStep.Type::Response, WorkflowResponseHandling.OpenDocumentCode());
        LibraryWorkflow.SetNextStep(Workflow, RejectResponseWorkflowStep.ID, 0);
        EnableWorkflow(Workflow.Code);

        // Setup
        CreatePurchaseInvBasedOnIncomingDoc(PurchaseHeader);
        BindSubscription(LibraryJobQueue);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);
        UnbindSubscription(LibraryJobQueue);

        // Pre-Exercise
        FindApprovalEntry(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."Document Type", PurchaseHeader."No.");
        ApprovalEntry.ModifyAll("Sender ID", RequestorUserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", RequestorUserSetup."User ID", true);

        // Exercise
        BindSubscription(LibraryJobQueue);
        ApprovalsMgmt.RejectRecordApprovalRequest(PurchaseHeader.RecordId);
        UnbindSubscription(LibraryJobQueue);

        // Verify.
        FindWorkflowStep(SendForApprovalWorkflowStep,
          Workflow.Code, SendForApprovalWorkflowStep.Type::"Event", WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
        VerifyArchivedWorkflowStepInstance(SendForApprovalWorkflowStep, WorkflowStepInstance.Status::Completed);

        FindWorkflowStep(ApproveWorkflowStep,
          Workflow.Code, SendForApprovalWorkflowStep.Type::"Event", WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
        VerifyArchivedWorkflowStepInstance(ApproveWorkflowStep, WorkflowStepInstance.Status::Ignored);

        VerifyArchivedWorkflowStepInstance(RejectResponseWorkflowStep, WorkflowStepInstance.Status::Completed);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestApprovingRejectedApprovalRequestForPurchInvWithLoopback()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApproveWorkflowStep: Record "Workflow Step";
        ApproverUserSetup: Record "User Setup";
        PurchaseHeader: Record "Purchase Header";
        RejectWorkflowStep: Record "Workflow Step";
        RequestorUserSetup: Record "User Setup";
        SendForApprovalWorkflowStep: Record "Workflow Step";
        WorkflowStepInstance: Record "Workflow Step Instance";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Branch out to a previous step
        // [GIVEN] Workflow Steps for Rejecting an approval request of a Purchase Invoice.
        // [WHEN] Workflow Step Instance not followed by a loopback step is executed.
        // [WHEN] User proceeds with the steps from the loopback step onwards.
        // [THEN] All done steps are Completed, and all skipped steps are Ignored.

        // ===================================
        // #      [Send for approval] <-|
        // #             |              |
        // #            / \             |
        // #   [Approve]   [Reject] ----|
        // #       |
        // #  [Auto-Post]
        // ===================================

        Initialize();

        // Pre-Setup
        SetupUsersForApproval(RequestorUserSetup, ApproverUserSetup);
        CreatePurchInvLoopbackWorkflow(Workflow);
        EnableWorkflow(Workflow.Code);
        DocumentNo := CreatePurchaseInvBasedOnIncomingDoc(PurchaseHeader);
        SetCurrentUserApprovalAdiministrator(true);
        // Setup
        BindSubscription(LibraryJobQueue);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);
        UnbindSubscription(LibraryJobQueue);
        AdjustRequestorAndApprover(ApprovalEntry, DocumentNo, RequestorUserSetup."Approver ID", RequestorUserSetup."User ID");

        BindSubscription(LibraryJobQueue);
        ApprovalsMgmt.RejectRecordApprovalRequest(PurchaseHeader.RecordId);
        UnbindSubscription(LibraryJobQueue);
        AdjustRequestorAndApprover(ApprovalEntry, DocumentNo, RequestorUserSetup."User ID", RequestorUserSetup."Approver ID");

        // Pre-Exercise
        CheckPurchInvStatus(DocumentNo, PurchaseHeader.Status::Open);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, DocumentNo);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);
        CheckPurchInvStatus(DocumentNo, PurchaseHeader.Status::"Pending Approval");

        // Exercise
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        FindApprovalEntry(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."Document Type"::Invoice, DocumentNo);
        ApprovalEntry.SetRecFilter();
        ApprovalsMgmt.ApproveApprovalRequests(ApprovalEntry);

        // Post-Exercise
        CheckPurchInvStatus(DocumentNo, PurchaseHeader.Status::Released);

        // Verify.
        FindWorkflowStep(SendForApprovalWorkflowStep,
          Workflow.Code, SendForApprovalWorkflowStep.Type::"Event", WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
        VerifyArchivedWorkflowStepInstance(SendForApprovalWorkflowStep, WorkflowStepInstance.Status::Completed);

        FindWorkflowStep(ApproveWorkflowStep,
          Workflow.Code, SendForApprovalWorkflowStep.Type::"Event", WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
        VerifyArchivedWorkflowStepInstance(ApproveWorkflowStep, WorkflowStepInstance.Status::Completed);

        FindWorkflowStep(RejectWorkflowStep,
          Workflow.Code, SendForApprovalWorkflowStep.Type::"Event", WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode());
        VerifyArchivedWorkflowStepInstance(RejectWorkflowStep, WorkflowStepInstance.Status::Ignored);
    end;

    local procedure Initialize()
    var
        JobQueueEntry: Record "Job Queue Entry";
        NotificationEntry: Record "Notification Entry";
        NotificationSetup: Record "Notification Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        LibraryWorkflow.DeleteAllExistingWorkflows();
        NotificationEntry.DeleteAll();
        NotificationSetup.DeleteAll();
        JobQueueEntry.DeleteAll();
        ApprovalEntry.DeleteAll();

        ConfigureEmail();
        WorkflowEventHandling.CreateEventsLibrary();
        WorkflowResponseHandling.CreateResponsesLibrary();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
    end;

    local procedure ConfigureEmail()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then begin
            UserSetup."User ID" := UserId;
            UserSetup."E-Mail" := UserEmailAddressTxt;
            UserSetup.Insert();
        end else
            if UserSetup."E-Mail" = '' then begin
                UserSetup."E-Mail" := UserEmailAddressTxt;
                UserSetup.Modify();
            end;
    end;

    local procedure SetupUsersForApproval(var RequestorUserSetup: Record "User Setup"; var ApproverUserSetup: Record "User Setup")
    var
        RequestorUser: Record User;
        StubUser: Record User;
    begin
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);

        // CL 10941868 introduced new User Card Page behavior. It inserts current user as Super User when user table is empty. So we try to insert current user twice.
        // Stub user helps to avoid unwanted default user insertion.
        StubUser.Init();
        StubUser."User Security ID" := CreateGuid();
        StubUser.Insert();

        if not LibraryDocumentApprovals.UserExists(UserId) then
            LibraryDocumentApprovals.CreateUser(Format(CreateGuid()), UserId);

        LibraryDocumentApprovals.GetUser(RequestorUser, UserId);

        if LibraryDocumentApprovals.GetUserSetup(RequestorUserSetup, UserId) then
            LibraryDocumentApprovals.DeleteUserSetup(RequestorUserSetup, UserId);

        LibraryDocumentApprovals.CreateUserSetup(RequestorUserSetup, RequestorUser."User Name", ApproverUserSetup."User ID");
        LibraryDocumentApprovals.UpdateApprovalLimits(RequestorUserSetup, false, false, false, 0, 0, 0);

        ApproverUserSetup."Approval Administrator" := true;
        ApproverUserSetup.Modify();

        StubUser.Delete();
    end;

    local procedure CreatePurchaseInvBasedOnIncomingDoc(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        IncomingDocument: Record "Incoming Document";
    begin
        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Incoming Document Entry No.", IncomingDocument."Entry No.");
        PurchaseHeader.Modify(true);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header") DocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        DocumentNo := PurchaseHeader."No.";

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure FindNotificationEntry(var NotificationEntry: Record "Notification Entry"; UserID: Code[50]; Type: Enum "Notification Entry Type"; CreatedByUserID: Code[50])
    begin
        NotificationEntry.SetRange(Type, Type);
        NotificationEntry.SetRange("Recipient User ID", UserID);
        NotificationEntry.SetRange("Created By", CreatedByUserID);
        NotificationEntry.FindLast();
    end;

    local procedure IsEmailNotificationEntryCreated(UserID: Code[50]; Type: Integer; CreatedByUserID: Code[50]): Boolean
    var
        NotificationEntry: Record "Notification Entry";
    begin
        NotificationEntry.SetRange("Recipient User ID", UserID);
        NotificationEntry.SetRange(Type, Type);
        NotificationEntry.SetRange("Created By", CreatedByUserID);
        exit(not NotificationEntry.IsEmpty);
    end;

    local procedure FindApprovalEntry(var ApprovalEntry: Record "Approval Entry"; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    begin
        ApprovalEntry.SetRange("Table ID", TableID);
        ApprovalEntry.SetRange("Document Type", DocumentType);
        ApprovalEntry.SetRange("Document No.", DocumentNo);
        ApprovalEntry.FindSet();
    end;

    local procedure CreatePurchInvLoopbackWorkflow(var Workflow: Record Workflow)
    begin
        CreateWorkflow(Workflow);
        CreatePurchInvLoopbackWorkflowSteps(Workflow);
    end;

    local procedure CreatePurchInvLoopbackWorkflowSteps(Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        SendForApprovalResponseID: Integer;
        CreateApprovalRequestsResponseID: Integer;
        OnSendForApprovalEventID: Integer;
        OnApprovalRequestApprovedEventID: Integer;
        OnApprovalRequestRejectedEventID: Integer;
        OpenDocumentResponseID: Integer;
        RejectAllResponseID: Integer;
        SetStatusToPendingApprovalResponseID: Integer;
    begin
        // 1. Purchase Invoice sent for approval.
        OnSendForApprovalEventID :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());

        SetStatusToPendingApprovalResponseID := LibraryWorkflow.InsertResponseStep(Workflow,
            WorkflowResponseHandling.SetStatusToPendingApprovalCode(), OnSendForApprovalEventID);
        CreateApprovalRequestsResponseID :=
          LibraryWorkflow.InsertResponseStep(Workflow,
            WorkflowResponseHandling.CreateApprovalRequestsCode(), SetStatusToPendingApprovalResponseID);
        LibraryWorkflow.InsertApprovalArgument(CreateApprovalRequestsResponseID, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"Approver Chain", '', true);

        SendForApprovalResponseID := LibraryWorkflow.InsertResponseStep(Workflow,
            WorkflowResponseHandling.SendApprovalRequestForApprovalCode(), CreateApprovalRequestsResponseID);
        LibraryWorkflow.InsertNotificationArgument(SendForApprovalResponseID, '', 0, CustomURLTxt);

        // 2.a. Purchase Invoice approved.
        OnApprovalRequestApprovedEventID :=
          LibraryWorkflow.InsertEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(), SendForApprovalResponseID);

        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ReleaseDocumentCode(), OnApprovalRequestApprovedEventID);

        // 3.b. Purchase Invoice rejected.
        OnApprovalRequestRejectedEventID :=
          LibraryWorkflow.InsertEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(), SendForApprovalResponseID);

        RejectAllResponseID := LibraryWorkflow.InsertResponseStep(Workflow,
            WorkflowResponseHandling.RejectAllApprovalRequestsCode(), OnApprovalRequestRejectedEventID);
        LibraryWorkflow.InsertNotificationArgument(RejectAllResponseID, '', 0, CustomURLTxt);

        OpenDocumentResponseID :=
          LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.OpenDocumentCode(), RejectAllResponseID);
        LibraryWorkflow.SetNextStep(Workflow, OpenDocumentResponseID, OnSendForApprovalEventID);
    end;

    local procedure AdjustRequestorAndApprover(var ApprovalEntry: Record "Approval Entry"; DocumentNo: Code[20]; SenderID: Code[50]; ApproverID: Code[50])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        FindApprovalEntry(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."Document Type"::Invoice, DocumentNo);
        repeat
            if ApprovalEntry."Sender ID" = ApprovalEntry."Approver ID" then
                ApprovalEntry."Approver ID" := SenderID
            else
                ApprovalEntry."Approver ID" := ApproverID;
            ApprovalEntry."Sender ID" := SenderID;
            ApprovalEntry.Modify();
        until ApprovalEntry.Next() = 0;
    end;

    local procedure SetCurrentUserApprovalAdiministrator(ApprovalAdministrator: Boolean)
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Get(UserId);
        UserSetup."Approval Administrator" := ApprovalAdministrator;
        UserSetup.Modify();
    end;

    local procedure CheckPurchInvStatus(DocumentNo: Code[20]; Status: Enum "Purchase Document Status")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, DocumentNo);
        PurchaseHeader.TestField(Status, Status);
    end;

    local procedure FindWorkflowStep(var WorkflowStep: Record "Workflow Step"; WorkflowCode: Code[20]; Type: Option; FunctionName: Code[128])
    begin
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        WorkflowStep.SetRange(Type, Type);
        WorkflowStep.SetRange("Function Name", FunctionName);
        WorkflowStep.FindFirst();
    end;

    local procedure VerifyWorkflowStepInstance(WorkflowStep: Record "Workflow Step"; Status: Option)
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        WorkflowStepInstance.SetRange("Original Workflow Code", WorkflowStep."Workflow Code");
        WorkflowStepInstance.SetRange("Original Workflow Step ID", WorkflowStep.ID);
        WorkflowStepInstance.SetRange(Type, WorkflowStep.Type);
        WorkflowStepInstance.SetRange("Function Name", WorkflowStep."Function Name");
        WorkflowStepInstance.FindFirst();
        Assert.AreEqual(1, WorkflowStepInstance.Count, WorkflowStepInstance.GetFilters);
        WorkflowStepInstance.TestField(Status, Status);
    end;

    local procedure VerifyArchivedWorkflowStepInstance(WorkflowStep: Record "Workflow Step"; Status: Option)
    var
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        WorkflowStepInstanceArchive.SetRange("Original Workflow Code", WorkflowStep."Workflow Code");
        WorkflowStepInstanceArchive.SetRange("Original Workflow Step ID", WorkflowStep.ID);
        WorkflowStepInstanceArchive.SetRange(Type, WorkflowStep.Type);
        WorkflowStepInstanceArchive.SetRange("Function Name", WorkflowStep."Function Name");
        WorkflowStepInstanceArchive.FindFirst();
        Assert.AreEqual(1, WorkflowStepInstanceArchive.Count, WorkflowStepInstanceArchive.GetFilters);
        WorkflowStepInstanceArchive.TestField(Status, Status);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler!
    end;

    local procedure ValidateArchivedSteps(WorkflowCode: Code[20]; ShouldStepsBeArchived: Boolean)
    var
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        WorkflowStepInstanceArchive.SetRange("Workflow Code", WorkflowCode);
        Assert.AreEqual(WorkflowStepInstanceArchive.IsEmpty, not ShouldStepsBeArchived, 'There is an issue with the archived steps.');
    end;

    local procedure EnableWorkflow(WorkflowCode: Code[20])
    var
        Workflow: Record Workflow;
    begin
        Workflow.Get(WorkflowCode);
        Workflow.Enabled := true;
        Workflow.Modify(true);
    end;

    local procedure CreateWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Init();
        Workflow.Code := LibraryUtility.GenerateRandomCode(Workflow.FieldNo(Code), DATABASE::Workflow);
        Workflow.Enabled := false;
        Workflow.Insert(true);
    end;
}

