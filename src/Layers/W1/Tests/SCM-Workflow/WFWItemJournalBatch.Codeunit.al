codeunit 139491 "WFW Item Journal Batch"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "User Setup" = imd,
                  TableData "Workflow Webhook Entry" = imd,
                  TableData "Approval Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Item Journal]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;
        BogusUserIdTxt: Label 'CONTOSO';
        DynamicRequestPageParametersItemJournalBatchTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Item Journal Line">VERSION(1) SORTING(Field1,Field51,Field2)</DataItem></DataItems></ReportParameters>', Locked = true;
        RecordRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1 = Record ID, for example Customer 10000';
        NoApprovalCommentExistsErr: Label 'There is no approval comment for this approval entry.';
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        ApprovalCommentWasNotDeletedErr: Label 'The approval comment for this approval entry was not deleted.';
        PreventInsertRecordWithOpenApprovalEntryForCurrUserMsg: Label 'You can''t insert a record for active batch approval request. To insert a record, you can Reject approval and document requested changes in approval comment lines.';
        PreventDeleteRecordWithOpenApprovalEntryForCurrUserMsg: Label 'You can''t delete a record that has open approval entries. To delete a record, you can Reject approval and document requested changes in approval comment lines.';
        PreventModifyRecordWithOpenApprovalEntryMsg: Label 'You can''t modify a record pending approval. Add a comment or reject the approval to modify the record.';
        ImposedRestrictionLbl: Label 'Imposed restriction';
        SendApprovalRequestJournalBatchActionMustBeDisabledLbl: Label 'Send Approval Request Journal Batch action must be disabled';
        CancelApprovalRequestJournalBatchActionMustBeDisabledLbl: Label 'Cancel Approval Request Journal Batch action must be disabled';
        CancelApprovalRequestJournalBatchActionMustBeEnabledLbl: Label 'Cancel Approval Request Journal Batch action must be enabled';
        ApproveActionMustNotBeVisibleLbl: Label 'Approve action must not be visible';
        RejectActionMustNotBeVisibleLbl: Label 'Reject action must not be visible';
        DelegateActionMustNotBeVisibleLbl: Label 'Delegate action must not be visible';
        ApproveActionMustBeVisibleLbl: Label 'Approve action must be visible';
        RejectActionMustBeVisibleLbl: Label 'Reject action must be visible';
        DelegateActionMustBeVisibleLbl: Label 'Delegate action must be visible';
        CanRequestApprovalLbl: Label 'CanRequestApproval';
        FindWorkflowWebhookEntryByRecordIdAndResponseLbl: Label 'FindWorkflowWebhookEntryByRecordIdAndResponse';
        BatchWorkflowStatusFactboxMustNotBeVisibleLbl: Label 'Batch workflow Status factbox must not be visible';
        BatchWorkflowStatusFactboxMustBeVisibleLbl: Label 'Batch workflow Status factbox must be visible';
        ImposedRestrictionMustBeShownLbl: Label 'Imposed restriction must be shown.';
        ApprovalCommentActionMustBeVisibleLbl: Label 'Approval Comment action must be visible.';
        ApprovalCommentActionMustNotBeVisibleLbl: Label 'Approval Comment action must not be visible.';
        PageContainsWrongNumberOfCommentsLbl: Label 'The %1 page contains the wrong number of comments. Comments must be equal to %2', Comment = '%1 = Page Name, %2 = No. of Comments';
        TestCommentLbl: Label 'Test Comment';

    [Test]
    procedure TestEnsureNecessaryTableRelationsAreSetup()
    var
        DummyItemJournalBatch: Record "Item Journal Batch";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowTableRelation: Record "Workflow - Table Relation";
    begin
        // [SCENARIO 336178] Verify that required workflow table relations for Item Journal Batch approval are established.
        Initialize();

        // [GIVEN] Remove all existing workflows to ensure a clean state.
        LibraryWorkflow.DeleteAllExistingWorkflows();

        // [WHEN] Initialize workflow setup.
        WorkflowSetup.InitWorkflow();

        // [THEN] Verify that table relation for Item Journal Batch approval workflow exists.
        WorkflowTableRelation.Get(
            Database::"Item Journal Batch", DummyItemJournalBatch.FieldNo(SystemId),
            Database::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
    end;

    [Test]
    procedure TestItemJournalBatchApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        ApproverUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 336178] Verify Approver approves the request for the Item Journal Batch.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableItemJournalBatchWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] Create an Item Journal Line.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);
        Commit();

        // [WHEN] Send an Approval Request for Item Journal.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [THEN] Verify Open Approval Entry.
        VerifyWorkflowWebhookEntryResponse(ItemJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Approve the Approval Entry via workflow webhook.
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(ItemJournalBatch.SystemId));

        // [THEN] Verify Approval Entry is Approved.
        VerifyWorkflowWebhookEntryResponse(ItemJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    procedure TestItemJournalBatchApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        ApproverUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 336178] Verify that a webhook Item Journal Batch approval workflow rejection path works correctly.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableItemJournalBatchWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] Create an Item Journal Line.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [WHEN] Send an Approval Request for Item Journal.
        Commit();
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [THEN] Verify workflow webhook entry response is pending.
        VerifyWorkflowWebhookEntryResponse(ItemJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Webhook Item Journal Batch approval workflow receives a rejection response for the Item Journal Batch.
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(ItemJournalBatch.SystemId));

        // [THEN] Verify that Item Journal Batch is rejected.
        VerifyWorkflowWebhookEntryResponse(ItemJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    procedure TestItemJournalBatchApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        ApproverUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 336178] Verify that a Webhook Item Journal Batch approval workflow cancellation path works correctly.
        Initialize();

        // [GIVEN] A webhook Item Journal Batch approval workflow for an Item Journal Batch is enabled.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableItemJournalBatchWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] Create an Item Journal Line.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [WHEN] Send an Approval Request for Item Journal.
        Commit();
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [THEN] Verify workflow webhook entry response is pending.
        VerifyWorkflowWebhookEntryResponse(ItemJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Webhook Item Journal Batch approval workflow receives a cancellation response for the Item Journal Batch.
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(ItemJournalBatch.SystemId));

        // [THEN] Verify that the Item Journal Batch is cancelled.
        VerifyWorkflowWebhookEntryResponse(ItemJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestDirectApproverApprovesRequestForItemJournalBatch()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 336178] Verify that Approver approves the request for the Item Journal Batch.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create an Item Journal Line.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Create an Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for Item Journal.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [THEN] Verify Open Approval Entry.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId());
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Assign an Approval Entry.
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [WHEN] Approve an Approval Entry.
        ApproveItemJournalBatch(ItemJournalBatch.Name);

        // [THEN] Verify Approval Entry is Approved.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId());
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestDirectApproverRejectsRequestForItemJournalBatch()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 336178] Verify that Approver Rejects the request for the Item Journal Batch.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create an Item Journal Line.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Create an Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for Item Journal.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [THEN] Verify Open Approval Entry.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId());
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Assign an Approval Entry.
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [WHEN] Reject an Approval Entry.
        RejectItemJournalBatch(ItemJournalBatch.Name);

        // [THEN] Verify that Approval Entry is Rejected.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId());
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('ApprovalEntriesPageHandler')]
    procedure TestShowApprovalEntriesPage()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 336178] Verify that the related approval entries for the Item Journal Batch are displayed when an approval entry exists.
        Initialize();

        // [GIVEN] A Direct approval workflow is created and enabled for Item Journal Batches
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An Item Journal Batch with one Journal Line is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] An open approval entry exists for the Item Journal Batch.
        CreateOpenApprovalEntryForCurrentUser(ItemJournalBatch.RecordId);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] The batch record ID is enqueued for the approval entries page handler.
        LibraryVariableStorage.Enqueue(ItemJournalBatch.RecordId);

        // [WHEN] The approval entries page is shown for the batch.
        ShowApprovalEntries(ItemJournalBatch.Name);

        // [THEN] The page handler consumes the enqueued record ID and closes the approval entries page.
        // [THEN] The variable storage is empty after the page handler processes the expected record ID.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCannotSendApprovalRequestToChainOfApprovers()
    var
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 336178] Verify that an approval request to a chain of approvers is self-approved if no valid approver is found for the Item Journal Batch.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow with Approver Chain.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateApprovalChainEnabledWorkflow(Workflow);

        // [GIVEN] Create an Item Journal Line.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for Item Journal.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [THEN] Verify that approval request is self-approved due to absence of a valid approver chain.
        VerifySelfApprovalEntryAfterSendingForApproval(ItemJournalBatch.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCannotSendApprovalRequestToFirstQualifiedApprover()
    var
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO 336178] Verify that an approval request to the first qualified approver is self-approved if no qualified approver is found for the Item Journal Batch.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow with First Qualified Approver.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateFirstQualifiedApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create an Item Journal Line.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for Item Journal.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [THEN] Verify that approval request is self-approved due to absence of a qualified approver.
        VerifySelfApprovalEntryAfterSendingForApproval(ItemJournalBatch.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure TestDeleteLinesAfterApprovalRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Workflow: Record Workflow;
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO 336178] Verify that deleting all Item Journal Lines after an approval request cancels the approval request and deletes approval entries.
        Initialize();

        // [GIVEN] A Direct approval workflow is created and enabled for Item Journal Batch.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An Item Journal Batch with one journal line is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Requestor and approver user setups are configured for the approval process.
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, CopyStr(UserId, 1, 50));
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Approval request is sent for the Item Journal Batch.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [GIVEN] Approval entry for the batch is retrieved.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);

        // [WHEN] An approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [THEN] Verify that approval entry is open and approval comment exists.
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.RecordCount(ApprovalEntry, 1);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // [WHEN] All Item Journal Lines in the batch are deleted.
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll(true);

        // [THEN] Workflow Step Instances are removed and variable storage is empty.
        Assert.RecordIsEmpty(ApprovalEntry);
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);

        // [THEN] Verify that deleting all Item Journal Lines after an approval request cancels the approval request and deletes approval entries.
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TestHasPendingWorkflowWebhookEntryByRecordId()
    var
        ItemJournalLine: Record "Item Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 336178] Verify that CanRequestApproval returns false when there is a pending Workflow Webhook Entry for an Item Journal Line.
        Initialize();

        // [GIVEN] An Item Journal Line is inserted.
        ItemJournalLine.Insert();

        // [GIVEN] Create a Workflow Webhook Entry is created for the Item Journal Line with status Pending.
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry."Record ID" := ItemJournalLine.RecordId();
        WorkflowWebhookEntry.Response := WorkflowWebhookEntry.Response::Pending;
        WorkflowWebhookEntry.Insert();

        // [WHEN] CanRequestApproval is checked for the Item Journal Line.
        Assert.IsFalse(WorkflowWebhookManagement.CanRequestApproval(ItemJournalLine.RecordId()), CanRequestApprovalLbl);

        // [THEN] Verify that FindWorkflowWebhookEntryByRecordIdAndResponse returns true for the pending entry.
        Assert.IsTrue(
            WorkflowWebhookManagement.FindWorkflowWebhookEntryByRecordIdAndResponse(
                WorkflowWebhookEntry, ItemJournalLine.RecordId(), WorkflowWebhookEntry.Response::Pending),
                FindWorkflowWebhookEntryByRecordIdAndResponseLbl);
    end;

    [Test]
    procedure TestItemJournalLineApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 336178] Ensure that a webhook item journal batch approval workflow approval path works correctly.
        Initialize();

        // [GIVEN] An Item Journal Batch approval workflow is created and enabled for the current user.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableItemJournalBatchWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] An Item Journal Batch with one journal line is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] An approval request is sent for the Item Journal Batch.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [THEN] Verify that the workflow webhook entry response is pending.
        VerifyWorkflowWebhookEntryResponse(ItemJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Approval entry is continued via workflow webhook.
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(ItemJournalBatch.SystemId));

        // [THEN] Verify that the workflow webhook entry response is continue.
        VerifyWorkflowWebhookEntryResponse(ItemJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure TestDeleteAfterApprovalRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Workflow: Record Workflow;
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO 336178] Verify that deleting the record after an approval request is sent cancels the approval request and deletes the approval entries.
        Initialize();

        // [GIVEN] A direct approval workflow is created and enabled for Item Journal Batch.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An Item Journal Batch with one or more journal lines is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Requestor and approver user setups are configured for the approval process.
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, CopyStr(UserId, 1, 208));
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Approval request is sent for the Item Journal Batch.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [GIVEN] Approval entry for the batch is retrieved.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);

        // [WHEN] An approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [THEN] Verify that the approval entry exists and is open and the approval comment exists.
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // [WHEN] Item Journal Batch is deleted.
        ItemJournalBatch.Delete(true);

        // [THEN] Verify that the approval entry is deleted, workflow step instances are removed, the approval comment is deleted, and variable storage is empty.
        Assert.IsTrue(ApprovalEntry.IsEmpty, UnexpectedNoOfApprovalEntriesErr);
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
        Assert.IsFalse(ApprovalCommentExists(ApprovalEntry), ApprovalCommentWasNotDeletedErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestRenameAfterApprovalRequest()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 336178] Verify that renaming the record after an approval request is sent changes the approval request to point to the new record.
        Initialize();

        // [GIVEN] Direct approval workflow is created and enabled for Item Journal Batch.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An Item Journal Batch with one journal line is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Requestor and approver user setups are configured for the approval process.
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, CopyStr(UserId, 1, 50));
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Approval request is sent for the Item Journal Batch.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [GIVEN] Approval entry for the batch is retrieved.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);

        // [WHEN] Approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [THEN] Verify that approval entry is open and approval comment exists.
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // [WHEN] Item Journal Batch is renamed.
        ItemJournalBatch.Rename(ItemJournalBatch."Journal Template Name", LibraryRandom.RandText(10));

        // [THEN] Verify that approval entry still exists, is open, and approval comment still exists for the renamed batch.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);
    end;

    [Test]
    [HandlerFunctions('ApprovalEntriesPageHandler')]
    procedure TestShowApprovalEntriesEmptyPage()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 336178] Verify that the approval entries page displays no approval entries for the batch.
        Initialize();

        // [GIVEN] Direct approval workflow is created and enabled for Item Journal Batch.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An Item Journal Batch with one journal line is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] The batch record ID is enqueued for the approval entries page.
        LibraryVariableStorage.Enqueue(ItemJournalBatch.RecordId);

        // [WHEN] Approval entries page is shown for the batch.
        ShowApprovalEntries(ItemJournalBatch.Name);

        // [THEN] Verify that the page handler verifies that no approval entries exist for the batch.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCancelItemJournalBatchForApprovalNotAllowsUsage()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO 336178] Verify that a newly created Item Journal Batch that has a canceled approval cannot be posted.
        Initialize();

        // [GIVEN] Approval user setup is configured.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        // [GIVEN] An enabled approval workflow for Item Journal Batch is created.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemJournalBatchApprovalWorkflowCode());

        // [GIVEN] An Item Journal Batch and line are created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] User sends an approval request from the Item Journal Batch.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [GIVEN] User cancels the approval.
        CancelApprovalRequestForItemJournal(ItemJournalLine."Journal Batch Name");

        // [GIVEN] Find Item Journal Line.
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();

        // [WHEN] Post Item Journal Line.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Verify that an error is raised indicating that the record is restricted.
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(ItemJournalBatch.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestApproveItemJournalBatchForApprovalAllowsUsage()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ApprovalUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
    begin
        // [SCENARIO 336178] Verify that a newly created Item Journal Batch that is approved can be posted.
        Initialize();

        // [GIVEN] Approval user setup is configured.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        // [GIVEN] Enabled approval workflow for Item Journal Batch is created.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemJournalBatchApprovalWorkflowCode());

        // [GIVEN] An Item Journal Batch and line are created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Send an approval request from the Item Journal Batch.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [GIVEN] Approval entry for the batch is retrieved and assigned to the requestor.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        RequestorUserSetup.Get(UserId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [WHEN] Approves the batch.
        ApproveItemJournalBatch(ItemJournalBatch.Name);

        // [THEN] Verify that Item Journal Batch can be posted.
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    [Test]
    procedure TestRestrictItemJournalBatchExportingWithApprovalRemovedWhenWorkflowInstancesRemoved()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO 336178] Verify that restrict exporting of an Item Journal Batch when approval is needed, but all restrictions are removed when workflow is disabled and step instances are deleted.
        Initialize();

        // [GIVEN] Direct approval workflow is created and enabled for Item Journal Batch.
        CreateDirectApprovalEnabledWorkflow(Workflow);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] An Item Journal Batch with one journal line is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [THEN] Verify that restriction record exists for the Item Journal Batch.
        VerifyRestrictionRecordExists(ItemJournalBatch.RecordId);

        // [GIVEN] Workflow step instance is created for the Item Journal Batch.
        CreateWorkflowStepInstance(Workflow.Code, ItemJournalBatch.RecordId);

        // [WHEN] Workflow is disabled and Workflow Step Instances are deleted.
        Workflow.Enabled := false;
        Workflow.Modify();
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        WorkflowStepInstance.DeleteAll(true);

        // [THEN] Verify that no restriction record exists for the Item Journal Batch.
        VerifyNoRestrictionRecordExists(ItemJournalBatch.RecordId);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('MessageHandler')]
    procedure TestBatchWorkflowIsVisibleOnItemJnlPage()
    var
        ApprovalUserSetup: Record "User Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Workflow: Record Workflow;
        ItemJournal: TestPage "Item Journal";
    begin
        // [SCENARIO 336178] Verify that batch workflow status factbox becomes visible when the batch is sent for approval on Item Journal Page.
        Initialize();

        // [GIVEN] Item Journal Templates are deleted.
        ItemJournalTemplate.DeleteAll();

        // [GIVEN] Approval users and direct approval workflow are set up.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An Item Journal Batch with one journal line is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [WHEN] The Item Journal page is opened for the batch.
        ItemJournal.OpenView();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        // [THEN] Verify that batch workflow status factboxes are not visible before approval request.
        Assert.IsFalse(ItemJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowStatusFactboxMustNotBeVisibleLbl);

        // [WHEN] Send Approval Request from Item Journal Page.
        ItemJournal.SendApprovalRequestJournalBatch.Invoke();

        // [THEN] Verify that the batch workflow status factbox becomes visible.
        Assert.IsTrue(ItemJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowStatusFactboxMustBeVisibleLbl);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('MessageHandler')]
    procedure TestBatchWorkflowIsNotVisibleOnItemJnlPageAfterCancelApproval()
    var
        ApprovalUserSetup: Record "User Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Workflow: Record Workflow;
        ItemJournal: TestPage "Item Journal";
    begin
        // [SCENARIO 336178] Verify that batch workflow status factbox becomes not visible when the batch is cancelled for approval on Item Journal Page.
        Initialize();

        // [GIVEN] Item Journal Templates are deleted.
        ItemJournalTemplate.DeleteAll();

        // [GIVEN] Approval users and direct approval workflow are set up.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] The Item Journal page is opened and an approval request is sent.
        ItemJournal.OpenView();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);
        ItemJournal.SendApprovalRequestJournalBatch.Invoke();

        // [WHEN] Cancel Approval Request from Item Journal Page.
        ItemJournal.CancelApprovalRequestJournalBatch.Invoke();

        // [THEN] Verify that batch workflow status factboxes are not visible.
        Assert.IsFalse(ItemJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowStatusFactboxMustNotBeVisibleLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestApproveItemJournalBatchForApprovalAdministrator()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ApprovalEntry: Record "Approval Entry";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 336178] Verify that Item Journal Batch is auto approved for Approval Administrator.
        Initialize();

        // [GIVEN] User is set up as Approval Administrator.
        SetupApprovalAdministrator();

        // [GIVEN] Enabled approval workflow for Item Journal Batch is created.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Item Journal Batch is created with one journal line.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [WHEN] Approval request is sent for the Item Journal Batch.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [THEN] Verify that approval entry for the batch is approved automatically.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    procedure TestModifyItemJournalLineIsNotAllowedForCreatedApprovalEntry()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 336178] Verify that modifying an Item Journal Line is not allowed when an approval entry has status created.
        Initialize();

        // [GIVEN] An Item Journal Line is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] An Approval Entry for the Item Journal Batch is created with status created.
        CreateApprovalEntryForCurrentUser(ItemJournalBatch.RecordId, ApprovalStatus::Created);

        // [WHEN] Modify the Item Journal Line.
        asserterror ItemJournalLine.Modify(true);

        // [THEN] Verify that the expected error message is shown.
        Assert.ExpectedError(PreventModifyRecordWithOpenApprovalEntryMsg);
    end;

    [Test]
    procedure TestDeleteItemJournalLineIsNotAllowedForCreatedApprovalEntry()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 336178] Verify that deleting an Item Journal Line is not allowed when an approval entry has status created.
        Initialize();

        // [GIVEN] An Item Journal Line is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] An Approval Entry for the Item Journal Batch is created with status created.
        CreateApprovalEntryForCurrentUser(ItemJournalBatch.RecordId, ApprovalStatus::Created);

        // [WHEN] Delete the Item Journal Line.
        asserterror ItemJournalLine.Delete(true);

        // [THEN] Verify that the expected error message is shown.
        Assert.ExpectedError(PreventDeleteRecordWithOpenApprovalEntryForCurrUserMsg);
    end;

    [Test]
    procedure TestInsertItemJournalLineIsNotAllowedForCreatedApprovalEntry()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine1: Record "Item Journal Line";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 336178] Verify that insert an Item Journal Line is not allowed when an approval entry has status created.
        Initialize();

        // [GIVEN] An Item Journal Line is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] An Approval Entry for the Item Journal Batch is created with status created.
        CreateApprovalEntryForCurrentUser(ItemJournalBatch.RecordId, ApprovalStatus::Created);

        // [WHEN] Insert the Item Journal Line.
        asserterror LibraryInventory.CreateItemJournalLine(ItemJournalLine1, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemJournalLine."Item No.", LibraryRandom.RandIntInRange(1, 10));

        // [THEN] Verify that the expected error message is shown.
        Assert.ExpectedError(PreventInsertRecordWithOpenApprovalEntryForCurrUserMsg);
    end;

    [Test]
    procedure TestShowImposedRestrictionBatchStatusIfUserModifyItemJournalLineForApprovedApprovalRequest()
    var
        Workflow: Record Workflow;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ApprovalUserSetup: Record "User Setup";
        ItemJournal: TestPage "Item Journal";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 336178] Verify that imposed restriction batch status is shown if user modifies Item Journal Line for approved approval request.
        Initialize();

        // [GIVEN] Delete all Item Journal Template.
        ItemJournalTemplate.DeleteAll();

        // [GIVEN] Approval users and direct approval workflow are set up.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An Item Journal Line is created.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] An Approval Entry for the Item Journal Batch is created with status Approved.
        CreateApprovalEntryForCurrentUser(ItemJournalBatch.RecordId, ApprovalStatus::Approved);

        // [WHEN] Item Journal Line is modified.
        ItemJournalLine.Validate(Amount, LibraryRandom.RandDec(100, 2));
        ItemJournalLine.Modify(true);

        // [THEN] Verify that imposed restriction batch status is shown on the Item Journal page.
        ItemJournal.OpenView();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);
        Assert.AreEqual(ImposedRestrictionLbl, ItemJournal.ItemJnlBatchApprovalStatus.Value(), ImposedRestrictionMustBeShownLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestShowImposedRestrictionBatchStatusForWorkflowUserGroupIfFirstApprovalEntryIsApproved_ItemJournal()
    var
        Workflow: Record Workflow;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournal: TestPage "Item Journal";
    begin
        // [SCENARIO 336178] Verify that imposed restriction batch status is shown for Workflow User Group if first approval entry is auto approved.
        Initialize();

        // [GIVEN] Workflow template is copied.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.ItemJournalBatchApprovalWorkflowCode());

        // [GIVEN] Three user setups and a workflow user group are created and set for the workflow.
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Item Journal Batch is created with one journal line.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [WHEN] Approval request is sent for the Item Journal Batch.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [THEN] Verify that imposed restriction batch status is shown on the Item Journal page.
        ItemJournal.OpenView();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);
        Assert.AreEqual(ImposedRestrictionLbl, ItemJournal.ItemJnlBatchApprovalStatus.Value(), ImposedRestrictionMustBeShownLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestApprovalActionsVisibilityOnItemJournalBatch()
    var
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournal: TestPage "Item Journal";
    begin
        // [SCENARIO 336178] Verify approval actions visibility on the Item Journal Batch.
        Initialize();

        // [GIVEN] Create an Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Create an Item Journal Line.
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Create Direct Approval Workflow.
        CreateDirectApprovalWorkflow(Workflow);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open Item Journal.
        ItemJournal.OpenEdit();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        // [THEN] Verify Action must not be visible and enabled.
        Assert.IsFalse(ItemJournal.SendApprovalRequestJournalBatch.Enabled(), SendApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsFalse(ItemJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsFalse(ItemJournal.Approve.Visible(), ApproveActionMustNotBeVisibleLbl);
        Assert.IsFalse(ItemJournal.Reject.Visible(), RejectActionMustNotBeVisibleLbl);
        Assert.IsFalse(ItemJournal.Delegate.Visible(), DelegateActionMustNotBeVisibleLbl);
        ItemJournal.Close();

        // [GIVEN] Enable Workflow.
        EnableWorkflow(Workflow);

        // [GIVEN] Send an approval request to properly set up the workflow state.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [GIVEN] Create Open Approval Entry For Current User.
        CreateOpenApprovalEntryForCurrentUser(ItemJournalBatch.RecordId());

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open Item Journal.
        ItemJournal.OpenEdit();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        // [THEN] Verify Action must be visible and enabled.
        Assert.IsFalse(ItemJournal.SendApprovalRequestJournalBatch.Enabled(), SendApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsTrue(ItemJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeEnabledLbl);
        Assert.IsTrue(ItemJournal.Approve.Visible(), ApproveActionMustBeVisibleLbl);
        Assert.IsTrue(ItemJournal.Reject.Visible(), RejectActionMustBeVisibleLbl);
        Assert.IsTrue(ItemJournal.Delegate.Visible(), DelegateActionMustBeVisibleLbl);
        ItemJournal.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestDirectApproverApprovesConsumptionJournalRequestWithComment()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 336178] Verify that the Stan can approve Consumption Journal Batch with comments.
        Initialize();

        // [GIVEN] Clear existing approval entries.
        ApprovalEntry.DeleteAll();

        // [GIVEN] Create a direct approval and enable workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create Consumption Journal Batch with one line.
        CreateConsumptionJournalBatchWithOneJournalLine(ItemJournalBatch);

        // [GIVEN] Create Requestor and Approver User Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Check comments to the Consumption Journal Batch.
        CheckCommentsForDocumentOnConsumptionJournalPage(ItemJournalBatch, 0, false);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request for the Consumption Journal Batch.
        SendApprovalRequestForConsumptionJnlBatch(ItemJournalBatch.Name);

        // [THEN] Check comments for the Consumption Journal Batch.
        CheckCommentsForDocumentOnConsumptionJournalPage(ItemJournalBatch, 0, true);

        // [THEN] Verify that the approval entry is created for the Consumption Journal Batch.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Check comments for the Consumption Journal Batch.
        CheckCommentsForDocumentOnConsumptionJournalPage(ItemJournalBatch, 1, true);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // [WHEN] Approve the Consumption Journal Batch.
        Approve(ApprovalEntry);

        // [THEN] Verify that the approval entry is approved.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestDirectApproverApprovesPhysicalInventoryRequestWithComment()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 336178] Verify that the Stan can approve Physical Inventory Journal Batch with comments.
        Initialize();

        // [GIVEN] Create a direct approval and enable workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create Physical Inventory Journal Batch with one line.
        CreatePhysicalInventoryJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Create Requestor and Approver User Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Check comments to the Physical Inventory Journal Batch.
        CheckCommentsForDocumentOnPhysicalInventoryJournalPage(ItemJournalBatch, 0, false);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request for the Physical Inventory Journal Batch.
        SendApprovalRequestForPhysicalInventoryJnlBatch(ItemJournalBatch.Name);

        // [THEN] Check comments for the Physical Inventory Journal Batch.
        CheckCommentsForDocumentOnPhysicalInventoryJournalPage(ItemJournalBatch, 0, true);

        // [THEN] Verify that the approval entry is created for the Physical Inventory Journal Batch.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Check comments for the Physical Inventory Journal Batch.
        CheckCommentsForDocumentOnPhysicalInventoryJournalPage(ItemJournalBatch, 1, true);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // [WHEN] Approve the Physical Inventory Journal Batch.
        Approve(ApprovalEntry);

        // [THEN] Verify that the approval entry is approved.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestDirectApproverApprovesOutputJournalRequestWithComment()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 336178] Verify that the Stan can approve Output Journal Batch with comments.
        Initialize();

        // [GIVEN] Create a direct approval and enable workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create Output Journal Batch with one line.
        CreateOutputJournalBatchWithOneJournalLine(ItemJournalBatch);

        // [GIVEN] Create Requestor and Approver User Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Check comments to the Output Journal Batch.
        CheckCommentsForDocumentOnOutputJournalPage(ItemJournalBatch, 0, false);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request for the Output Journal Batch.
        SendApprovalRequestForOutputJnlBatch(ItemJournalBatch.Name);

        // [THEN] Check comments for the Output Journal Batch.
        CheckCommentsForDocumentOnOutputJournalPage(ItemJournalBatch, 0, true);

        // [THEN] Verify that the approval entry is created for the Output Journal Batch.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Check comments for the Output Journal Batch.
        CheckCommentsForDocumentOnOutputJournalPage(ItemJournalBatch, 1, true);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // [WHEN] Approve the Output Journal Batch.
        Approve(ApprovalEntry);

        // [THEN] Verify that the approval entry is approved.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestRequestorCancelsPhysicalInventoryRequestToDirectApprover()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 336178] Verify that the Stan can Cancel a pending request to approve Physical Inventory Journal Batch.
        Initialize();

        // [GIVEN] Create a direct approval and enable workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create Physical Inventory Journal Batch with one line.
        CreatePhysicalInventoryJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Create Requestor and Approver User Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Check if the user can cancel the approval request for the journal batch.
        CheckUserCanCancelTheApprovalRequestForAPhysicalInventoryJnlBatch(ItemJournalBatch, false);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request for the Physical Inventory Journal Batch.
        SendApprovalRequestForPhysicalInventoryJnlBatch(ItemJournalBatch.Name);

        // [THEN] Verify approval entry is created.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);

        // [GIVEN] Check if the user can cancel the approval request for the journal batch.
        CheckUserCanCancelTheApprovalRequestForAPhysicalInventoryJnlBatch(ItemJournalBatch, true);

        // [WHEN] Cancel the approval request for the Physical Inventory Journal Batch.
        CancelApprovalRequestForPhysicalInventoryJnlBatch(ItemJournalBatch.Name);

        // [THEN] Verify approval entry is cancelled.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    procedure TestApprovalActionsVisibilityOnPhysicalInventoryJournal()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        PhysicalInventoryJournal: TestPage "Phys. Inventory Journal";
    begin
        // [SCENARIO 336178] Verify the Visibility of approval actions on a Physical Inventory Journal Batch.
        Initialize();

        // [GIVEN] Create Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Create Physical Inventory Journal Batch with one line.
        CreatePhysicalInventoryJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Create Direct Approval Workflow.
        CreateDirectApprovalWorkflow(Workflow);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open the Physical Inventory Journal Batch.
        PhysicalInventoryJournal.OpenEdit();
        PhysicalInventoryJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        // [THEN] Verify Action must not be visible and enabled.
        Assert.IsFalse(PhysicalInventoryJournal.SendApprovalRequestJournalBatch.Enabled(), SendApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsFalse(PhysicalInventoryJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsFalse(PhysicalInventoryJournal.Approve.Visible(), ApproveActionMustNotBeVisibleLbl);
        Assert.IsFalse(PhysicalInventoryJournal.Reject.Visible(), RejectActionMustNotBeVisibleLbl);
        Assert.IsFalse(PhysicalInventoryJournal.Delegate.Visible(), DelegateActionMustNotBeVisibleLbl);
        PhysicalInventoryJournal.Close();

        // [GIVEN] Enable Workflow.
        EnableWorkflow(Workflow);

        // [GIVEN] Create an open approval entry for the Physical Inventory Journal Batch.
        CreateJournalBatchOpenApprovalEntryForCurrentUser(ItemJournalBatch);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open the Physical Inventory Journal Batch.
        PhysicalInventoryJournal.OpenEdit();
        PhysicalInventoryJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        // [THEN] Verify visibility and enabled status of actions.
        Assert.IsFalse(PhysicalInventoryJournal.SendApprovalRequestJournalBatch.Enabled(), SendApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsTrue(PhysicalInventoryJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeEnabledLbl);
        Assert.IsTrue(PhysicalInventoryJournal.Approve.Visible(), ApproveActionMustBeVisibleLbl);
        Assert.IsTrue(PhysicalInventoryJournal.Reject.Visible(), RejectActionMustBeVisibleLbl);
        Assert.IsTrue(PhysicalInventoryJournal.Delegate.Visible(), DelegateActionMustBeVisibleLbl);
        PhysicalInventoryJournal.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCancelPhysicalInventoryJournalBatchForApprovalNotAllowsUsage()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO 336178] Verify that a newly created Physical Inventory Batch that has a canceled approval cannot be posted.
        Initialize();

        // [GIVEN] Approval user setup is configured.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        // [GIVEN] An enabled approval workflow for Item Journal Batch is created.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemJournalBatchApprovalWorkflowCode());

        // [GIVEN] Create Physical Inventory Journal Batch with one line.
        CreatePhysicalInventoryJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] User sends an approval request from the Physical Inventory Journal Batch.
        SendApprovalRequestForPhysicalInventoryJnlBatch(ItemJournalBatch.Name);

        // [GIVEN] User cancels the approval.
        CancelApprovalRequestForPhysicalInventoryJnlBatch(ItemJournalBatch.Name);

        // [GIVEN] Find Item Journal Line.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);

        // [WHEN] Post Item Journal Line.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Verify that an error is raised indicating that the record is restricted.
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(ItemJournalBatch.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestRequestorCancelsOutputJournalRequestToDirectApprover()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 336178] Verify that the Stan can Cancel a pending request to approve Output Journal Batch.
        Initialize();

        // [GIVEN] Create a direct approval and enable workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create Output Journal Batch with one line.
        CreateOutputJournalBatchWithOneJournalLine(ItemJournalBatch);

        // [GIVEN] Create Requestor and Approver User Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Check if the user can cancel the approval request for the journal batch.
        CheckUserCanCancelTheApprovalRequestForAOutputJnlBatch(ItemJournalBatch, false);

        // [WHEN] Send approval request for the Output Journal Batch.
        SendApprovalRequestForOutputJnlBatch(ItemJournalBatch.Name);

        // [THEN] Verify approval entry is created.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);

        // [GIVEN] Check if the user can cancel the approval request for the journal Batch.
        CheckUserCanCancelTheApprovalRequestForAOutputJnlBatch(ItemJournalBatch, true);

        // [WHEN] Cancel the approval request for the Output Journal Batch.
        CancelApprovalRequestForOutputJnlBatch(ItemJournalBatch.Name);

        // [THEN] Verify approval entry is cancelled.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    procedure TestApprovalActionsVisibilityOnOutputJournal()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        OutputJournal: TestPage "Output Journal";
    begin
        // [SCENARIO 336178] Verify the Visibility of approval actions on an Output Journal Batch.
        Initialize();

        // [GIVEN] Create Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Create Output Journal Batch with one line.
        CreateOutputJournalBatchWithOneJournalLine(ItemJournalBatch);

        // [GIVEN] Create Direct Approval Workflow.
        CreateDirectApprovalWorkflow(Workflow);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open the Output Journal Batch.
        OutputJournal.OpenEdit();
        OutputJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        // [THEN] Verify Action must not be visible and enabled.
        Assert.IsFalse(OutputJournal.SendApprovalRequestJournalBatch.Enabled(), SendApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsFalse(OutputJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsFalse(OutputJournal.Approve.Visible(), ApproveActionMustNotBeVisibleLbl);
        Assert.IsFalse(OutputJournal.Reject.Visible(), RejectActionMustNotBeVisibleLbl);
        Assert.IsFalse(OutputJournal.Delegate.Visible(), DelegateActionMustNotBeVisibleLbl);
        OutputJournal.Close();

        // [GIVEN] Enable Workflow.
        EnableWorkflow(Workflow);

        // [GIVEN] Create an open approval entry for the Output Journal Batch.
        CreateJournalBatchOpenApprovalEntryForCurrentUser(ItemJournalBatch);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open the Output Journal Batch.
        OutputJournal.OpenEdit();
        OutputJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        // [THEN] Verify visibility and enabled status of actions.
        Assert.IsFalse(OutputJournal.SendApprovalRequestJournalBatch.Enabled(), SendApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsTrue(OutputJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeEnabledLbl);
        Assert.IsTrue(OutputJournal.Approve.Visible(), ApproveActionMustBeVisibleLbl);
        Assert.IsTrue(OutputJournal.Reject.Visible(), RejectActionMustBeVisibleLbl);
        Assert.IsTrue(OutputJournal.Delegate.Visible(), DelegateActionMustBeVisibleLbl);
        OutputJournal.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCancelOutputJournalBatchForApprovalNotAllowsUsage()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO 336178] Verify that a newly created Output Journal Batch that has a canceled approval cannot be posted.
        Initialize();

        // [GIVEN] Approval user setup is configured.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        // [GIVEN] An enabled approval workflow for Item Journal Batch is created.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemJournalBatchApprovalWorkflowCode());

        // [GIVEN] Create Output Journal Batch with one line.
        CreateOutputJournalBatchWithOneJournalLine(ItemJournalBatch);

        // [GIVEN] Find the Item Journal Line.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] User sends an approval request from the Output Journal Batch.
        SendApprovalRequestForOutputJnlBatch(ItemJournalBatch.Name);

        // [GIVEN] User cancels the approval.
        CancelApprovalRequestForOutputJnlBatch(ItemJournalBatch.Name);

        // [GIVEN] Find Item Journal Line.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);

        // [WHEN] Post Item Journal Line.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Verify that an error is raised indicating that the record is restricted.
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(ItemJournalBatch.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestRequestorCancelsConsumptionJournalRequestToDirectApprover()
    var
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 336178] Verify that the Stan can Cancel a pending request to approve Consumption Journal Batch.
        Initialize();

        // [GIVEN] Create a direct approval and enable workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create Consumption Journal Batch with one line.
        CreateConsumptionJournalBatchWithOneJournalLine(ItemJournalBatch);

        // [GIVEN] Find the Item Journal Line.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);

        // [GIVEN] Create Requestor and Approver User Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Check if the user can cancel the approval request for the journal batch.
        CheckUserCanCancelTheApprovalRequestForAConsumptionJnlBatch(ItemJournalBatch, false);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request for the Consumption Journal Batch.
        SendApprovalRequestForConsumptionJnlBatch(ItemJournalBatch.Name);

        // [THEN] Verify approval entry is created.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);

        // [GIVEN] Check if the user can cancel the approval request for the journal batch.
        CheckUserCanCancelTheApprovalRequestForAConsumptionJnlBatch(ItemJournalBatch, true);

        // [WHEN] Cancel the approval request for the Consumption Journal Batch.
        CancelApprovalRequestForConsumptionJnlBatch(ItemJournalBatch.Name);

        // [THEN] Verify approval entry is cancelled.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    procedure TestApprovalActionsVisibilityOnConsumptionJournal()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        ConsumptionJournal: TestPage "Consumption Journal";
    begin
        // [SCENARIO 336178] Verify the Visibility of approval actions on an Consumption Journal Batch.
        Initialize();

        // [GIVEN] Create Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Create Consumption Journal Batch with one line.
        CreateConsumptionJournalBatchWithOneJournalLine(ItemJournalBatch);

        // [GIVEN] Create Direct Approval Workflow.
        CreateDirectApprovalWorkflow(Workflow);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open the Consumption Journal Batch.
        ConsumptionJournal.OpenEdit();
        ConsumptionJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        // [THEN] Verify Action must not be visible and enabled.
        Assert.IsFalse(ConsumptionJournal.SendApprovalRequestJournalBatch.Enabled(), SendApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsFalse(ConsumptionJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsFalse(ConsumptionJournal.Approve.Visible(), ApproveActionMustNotBeVisibleLbl);
        Assert.IsFalse(ConsumptionJournal.Reject.Visible(), RejectActionMustNotBeVisibleLbl);
        Assert.IsFalse(ConsumptionJournal.Delegate.Visible(), DelegateActionMustNotBeVisibleLbl);
        ConsumptionJournal.Close();

        // [GIVEN] Enable Workflow.
        EnableWorkflow(Workflow);

        // [GIVEN] Create an open approval entry for the Consumption Journal Batch.
        CreateJournalBatchOpenApprovalEntryForCurrentUser(ItemJournalBatch);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open the Consumption Journal Batch.
        ConsumptionJournal.OpenEdit();
        ConsumptionJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        // [THEN] Verify visibility and enabled status of actions.
        Assert.IsFalse(ConsumptionJournal.SendApprovalRequestJournalBatch.Enabled(), SendApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsTrue(ConsumptionJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeEnabledLbl);
        Assert.IsTrue(ConsumptionJournal.Approve.Visible(), ApproveActionMustBeVisibleLbl);
        Assert.IsTrue(ConsumptionJournal.Reject.Visible(), RejectActionMustBeVisibleLbl);
        Assert.IsTrue(ConsumptionJournal.Delegate.Visible(), DelegateActionMustBeVisibleLbl);
        ConsumptionJournal.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCancelConsumptionJournalBatchForApprovalNotAllowsUsage()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO 336178] Verify that a newly created Consumption Journal Batch that has a canceled approval cannot be posted.
        Initialize();

        // [GIVEN] Approval user setup is configured.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        // [GIVEN] An enabled approval workflow for Item Journal Batch is created.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemJournalBatchApprovalWorkflowCode());

        // [GIVEN] Create Consumption Journal Batch with one line.
        CreateConsumptionJournalBatchWithOneJournalLine(ItemJournalBatch);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] User sends an approval request from the Consumption Journal Batch.
        SendApprovalRequestForConsumptionJnlBatch(ItemJournalBatch.Name);

        // [GIVEN] User cancels the approval.
        CancelApprovalRequestForConsumptionJnlBatch(ItemJournalBatch.Name);

        // [GIVEN] Find Item Journal Line.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);

        // [WHEN] Post Item Journal Line.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Verify that an error is raised indicating that the record is restricted.
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(ItemJournalBatch.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalEntryMustBeMovedToPostedApprovalEntryForItemJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        RequestorUserSetup: Record "User Setup";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ItemRegister: Record "Item Register";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624702] Verify that the approval entry is moved from approval entry to posted approval entry when the Item Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Item Journal Batch with setup.
        SendApprovalRequestForItemJournalWithSetup(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Approval entry for the batch is retrieved and assigned to the requestor.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        RequestorUserSetup.Get(UserId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approves the batch.
        ApproveItemJournalBatch(ItemJournalBatch.Name);

        // [WHEN] Post the Item Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval entry is moved to posted approval entry.
        ItemRegister.Get(ItemJournalPostBatch.GetItemRegNo());
        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, ItemRegister.RecordId());
        Assert.RecordCount(PostedApprovalEntry, 1);

        // [THEN] Verify that the comment on approval entry is moved to posted approval entry.
        PostedApprovalEntry.CalcFields(Comment);
        PostedApprovalEntry.TestField(Comment, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalEntryMustBeMovedToPostedApprovalEntryWithCommentForItemJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        RequestorUserSetup: Record "User Setup";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ItemRegister: Record "Item Register";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624702] Verify that the approval entry is moved from approval entry to posted approval entry with comment when the Item Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Item Journal Batch with setup.
        SendApprovalRequestForItemJournalWithSetup(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Approval entry for the batch is retrieved and assigned to the requestor.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        RequestorUserSetup.Get(UserId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] An approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [GIVEN] Approves the batch.
        ApproveItemJournalBatch(ItemJournalBatch.Name);

        // [WHEN] Post the Item Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval entry is moved to posted approval entry.
        ItemRegister.Get(ItemJournalPostBatch.GetItemRegNo());
        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, ItemRegister.RecordId());
        Assert.RecordCount(PostedApprovalEntry, 1);

        // [THEN] Verify that the comment on approval entry is moved to posted approval entry.
        PostedApprovalEntry.CalcFields(Comment);
        PostedApprovalEntry.TestField(Comment, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalStatusMustBeBlankWhenItemJournalIsPosted()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        RequestorUserSetup: Record "User Setup";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
        ItemJournalPage: TestPage "Item Journal";
    begin
        // [SCENARIO 624702] Verify that the approval status on the journal batch is blank when the Item Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Item Journal Batch with setup.
        SendApprovalRequestForItemJournalWithSetup(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Approval entry for the batch is retrieved and assigned to the requestor.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        RequestorUserSetup.Get(UserId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approves the batch.
        ApproveItemJournalBatch(ItemJournalBatch.Name);

        // [WHEN] Post the Item Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval status on the journal batch is blank.
        ItemJournalPage.OpenView();
        ItemJournalPage.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);
        ItemJournalPage.ItemJnlBatchApprovalStatus.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalRequestCanBeSendForNewLineWithoutAnyConfirmationForItemJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        RequestorUserSetup: Record "User Setup";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624702] Verify that the approval request can be sent for a new line for Item Journal Batch without any confirmation.
        Initialize();

        // [GIVEN] Send an approval request for the Item Journal Batch with setup.
        SendApprovalRequestForItemJournalWithSetup(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Approval entry for the batch is retrieved and assigned to the requestor.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        RequestorUserSetup.Get(UserId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approves the batch.
        ApproveItemJournalBatch(ItemJournalBatch.Name);

        // [GIVEN] Post the Item Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [GIVEN] Add a new line to the approved batch.  
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request for the Item Journal Batch without any confirmation.
        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);

        // [THEN] Verify approval entry is created.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalEntryMustBeMovedToPostedApprovalEntryForPhysicalInventoryJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemRegister: Record "Item Register";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624842] Verify that the approval entry is moved from approval entry to posted approval entry when the Physical Inventory Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Physical Inventory Journal Batch with setup.
        SendApprovalRequestForPhysicalInventoryJournalWithSetup(ItemJournalBatch, ItemJournalLine, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approve the Physical Inventory Journal Batch.
        Approve(ApprovalEntry);

        // [WHEN] Post the Item Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval entry is moved to posted approval entry.
        ItemRegister.Get(ItemJournalPostBatch.GetItemRegNo());
        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, ItemRegister.RecordId());
        Assert.RecordCount(PostedApprovalEntry, 1);

        // [THEN] Verify that the comment on approval entry is moved to posted approval entry.
        PostedApprovalEntry.CalcFields(Comment);
        PostedApprovalEntry.TestField(Comment, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalEntryMustBeMovedToPostedApprovalEntryWithCommentForPhysicalInventoryJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemRegister: Record "Item Register";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624842] Verify that the approval entry is moved from approval entry to posted approval entry with comment when the Physical Inventory Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Physical Inventory Journal Batch with setup.
        SendApprovalRequestForPhysicalInventoryJournalWithSetup(ItemJournalBatch, ItemJournalLine, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] An approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [GIVEN] Approve the Physical Inventory Journal Batch.
        Approve(ApprovalEntry);

        // [WHEN] Post the Item Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval entry is moved to posted approval entry.
        ItemRegister.Get(ItemJournalPostBatch.GetItemRegNo());
        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, ItemRegister.RecordId());
        Assert.RecordCount(PostedApprovalEntry, 1);

        // [THEN] Verify that the comment on approval entry is moved to posted approval entry.
        PostedApprovalEntry.CalcFields(Comment);
        PostedApprovalEntry.TestField(Comment, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalStatusMustBeBlankWhenPhysicalInventoryJournalIsPosted()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
        PhysInventoryJournalPage: TestPage "Phys. Inventory Journal";
    begin
        // [SCENARIO 624842] Verify that the approval status on the journal batch is blank when the Physical Inventory Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Physical Inventory Journal Batch with setup.
        SendApprovalRequestForPhysicalInventoryJournalWithSetup(ItemJournalBatch, ItemJournalLine, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approve the Physical Inventory Journal Batch.
        Approve(ApprovalEntry);

        // [WHEN] Post the Item Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval status on the journal batch is blank.
        PhysInventoryJournalPage.OpenView();
        PhysInventoryJournalPage.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);
        PhysInventoryJournalPage.ItemJnlBatchApprovalStatus.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalRequestCanBeSendForNewLineWithoutAnyConfirmationForPhysicalInventoryJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624842] Verify that the approval request can be sent for a new line for Physical Inventory Journal Batch without any confirmation.
        Initialize();

        // [GIVEN] Send an approval request for the Physical Inventory Journal Batch with setup.
        SendApprovalRequestForPhysicalInventoryJournalWithSetup(ItemJournalBatch, ItemJournalLine, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approve the Physical Inventory Journal Batch.
        Approve(ApprovalEntry);

        // [GIVEN] Post the Item Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [GIVEN] Add a new line to the approved batch.  
        CreatePhysicalInventoryJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request for the Physical Inventory Journal Batch without any confirmation.
        SendApprovalRequestForPhysicalInventoryJnlBatch(ItemJournalBatch.Name);

        // [THEN] Verify approval entry is created.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalEntryMustBeMovedToPostedApprovalEntryForOutputJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemRegister: Record "Item Register";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624843] Verify that the approval entry is moved from approval entry to posted approval entry when the Output Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Output Journal Batch with setup.
        SendApprovalRequestForOutputJournalWithSetup(ItemJournalBatch, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approve the Output Journal Batch.
        Approve(ApprovalEntry);

        // [WHEN] Post the Output Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval entry is moved to posted approval entry.
        ItemRegister.Get(ItemJournalPostBatch.GetItemRegNo());
        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, ItemRegister.RecordId());
        Assert.RecordCount(PostedApprovalEntry, 1);

        // [THEN] Verify that the comment on approval entry is moved to posted approval entry.
        PostedApprovalEntry.CalcFields(Comment);
        PostedApprovalEntry.TestField(Comment, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalEntryMustBeMovedToPostedApprovalEntryWithCommentForOutputJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemRegister: Record "Item Register";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624843] Verify that the approval entry is moved from approval entry to posted approval entry with comment when the Output Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Output Journal Batch with setup.
        SendApprovalRequestForOutputJournalWithSetup(ItemJournalBatch, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] An approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [GIVEN] Approve the Output Journal Batch.
        Approve(ApprovalEntry);

        // [WHEN] Post the Output Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval entry is moved to posted approval entry.
        ItemRegister.Get(ItemJournalPostBatch.GetItemRegNo());
        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, ItemRegister.RecordId());
        Assert.RecordCount(PostedApprovalEntry, 1);

        // [THEN] Verify that the comment on approval entry is moved to posted approval entry.
        PostedApprovalEntry.CalcFields(Comment);
        PostedApprovalEntry.TestField(Comment, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalStatusMustBeBlankWhenOutputJournalIsPosted()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
        OutputJournalPage: TestPage "Output Journal";
    begin
        // [SCENARIO 624843] Verify that the approval status on the journal batch is blank when the Output Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Output Journal Batch with setup.
        SendApprovalRequestForOutputJournalWithSetup(ItemJournalBatch, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approve the Output Journal Batch.
        Approve(ApprovalEntry);

        // [WHEN] Post the Output Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval status on the journal batch is blank.
        OutputJournalPage.OpenView();
        OutputJournalPage.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);
        OutputJournalPage.ItemJnlBatchApprovalStatus.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalRequestCanBeSendForNewLineWithoutAnyConfirmationForOutputJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624843] Verify that the approval request can be sent for a new line for Output Journal Batch without any confirmation.
        Initialize();

        // [GIVEN] Send an approval request for the Output Journal Batch with setup.
        SendApprovalRequestForOutputJournalWithSetup(ItemJournalBatch, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approve the Output Journal Batch.
        Approve(ApprovalEntry);

        // [GIVEN] Post the Item Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [GIVEN] Add a new line to the approved batch.  
        CreateOutputJournalBatchWithOneJournalLine(ItemJournalBatch);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request for the Output Journal Batch without any confirmation.
        SendApprovalRequestForOutputJnlBatch(ItemJournalBatch.Name);

        // [THEN] Verify approval entry is created.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalEntryMustBeMovedToPostedApprovalEntryForConsumptionJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemRegister: Record "Item Register";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624844] Verify that the approval entry is moved from approval entry to posted approval entry when the Consumption Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Consumption Journal Batch with setup.
        SendApprovalRequestForConsumptionJournalWithSetup(ItemJournalBatch, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approve the Consumption Journal Batch.
        Approve(ApprovalEntry);

        // [WHEN] Post the Consumption Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval entry is moved to posted approval entry.
        ItemRegister.Get(ItemJournalPostBatch.GetItemRegNo());
        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, ItemRegister.RecordId());
        Assert.RecordCount(PostedApprovalEntry, 1);

        // [THEN] Verify that the comment on approval entry is moved to posted approval entry.
        PostedApprovalEntry.CalcFields(Comment);
        PostedApprovalEntry.TestField(Comment, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalEntryMustBeMovedToPostedApprovalEntryWithCommentForConsumptionJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemRegister: Record "Item Register";
        PostedApprovalEntry: Record "Posted Approval Entry";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624844] Verify that the approval entry is moved from approval entry to posted approval entry with comments when the Consumption Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Consumption Journal Batch with setup.
        SendApprovalRequestForConsumptionJournalWithSetup(ItemJournalBatch, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] An approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [GIVEN] Approve the Consumption Journal Batch.
        Approve(ApprovalEntry);

        // [WHEN] Post the Consumption Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval entry is moved to posted approval entry.
        ItemRegister.Get(ItemJournalPostBatch.GetItemRegNo());
        LibraryDocumentApprovals.GetPostedApprovalEntries(PostedApprovalEntry, ItemRegister.RecordId());
        Assert.RecordCount(PostedApprovalEntry, 1);

        // [THEN] Verify that the comment on approval entry is moved to posted approval entry.
        PostedApprovalEntry.CalcFields(Comment);
        PostedApprovalEntry.TestField(Comment, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalStatusMustBeBlankWhenConsumptionJournalIsPosted()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
        ConsumptionJournalPage: TestPage "Consumption Journal";
    begin
        // [SCENARIO 624844] Verify that the approval status on the journal batch is blank when the Consumption Journal Batch is approved and posted.
        Initialize();

        // [GIVEN] Send an approval request for the Consumption Journal Batch with setup.
        SendApprovalRequestForConsumptionJournalWithSetup(ItemJournalBatch, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approve the Consumption Journal Batch.
        Approve(ApprovalEntry);

        // [WHEN] Post the Consumption Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [THEN] Verify that the approval status on the journal batch is blank.
        ConsumptionJournalPage.OpenView();
        ConsumptionJournalPage.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);
        ConsumptionJournalPage.ItemJnlBatchApprovalStatus.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ApprovalRequestCanBeSendForNewLineWithoutAnyConfirmationForConsumptionJournal()
    var
        ApprovalEntry: Record "Approval Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        RequestorUserSetup: Record "User Setup";
        ItemJournalPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        // [SCENARIO 624844] Verify that the approval request can be sent for a new line for Consumption Journal Batch without any confirmation.
        Initialize();

        // [GIVEN] Send an approval request for the Consumption Journal Batch with setup.
        SendApprovalRequestForConsumptionJournalWithSetup(ItemJournalBatch, RequestorUserSetup);

        // [GIVEN] Assign the approval entry to the requestor user setup.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [GIVEN] Approve the Consumption Journal Batch.
        Approve(ApprovalEntry);

        // [GIVEN] Post the Item Journal Batch.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalPostBatch.Run(ItemJournalLine);

        // [GIVEN] Add a new line to the approved batch.  
        CreateConsumptionJournalBatchWithOneJournalLine(ItemJournalBatch);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request for the Consumption Journal Batch without any confirmation.
        SendApprovalRequestForConsumptionJnlBatch(ItemJournalBatch.Name);

        // [THEN] Verify approval entry is created.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, ItemJournalBatch.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ClearWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        Workflow.ModifyAll(Enabled, false, true);
        UserSetup.DeleteAll();
        ItemJournalTemplate.DeleteAll();
        ItemJournalLine.DeleteAll();
        ClearWorkflowWebhookEntry.DeleteAll();
        ApprovalEntry.DeleteAll();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        RemoveBogusUser();
        if IsInitialized then
            exit;

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        BindSubscription(MockOnFindTaskSchedulerAllowed);
    end;

    local procedure RemoveBogusUser()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(BogusUserIdTxt) then
            UserSetup.Delete(true);
    end;

    local procedure CreateApprovalEntryForCurrentUser(RecordID: RecordID; Status: Enum "Approval Status")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Document Type" := ApprovalEntry."Document Type"::" ";
        ApprovalEntry."Document No." := '';
        ApprovalEntry."Table ID" := RecordID.TableNo;
        ApprovalEntry."Record ID to Approve" := RecordID;
        ApprovalEntry."Approver ID" := CopyStr(UserId, 1, 50);
        ApprovalEntry.Status := Status;
        ApprovalEntry."Sequence No." := 1;
        ApprovalEntry.Insert();
    end;

    local procedure SetupApprovalAdministrator()
    var
        UserSetup: Record "User Setup";
    begin
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, CopyStr(UserId, 1, 50), '');
        UserSetup."Approval Administrator" := true;
        UserSetup.Modify();
    end;

    local procedure VerifyRestrictionRecordExists(RecID: RecordID)
    var
        RestrictedRecord: Record "Restricted Record";
    begin
        RestrictedRecord.SetRange("Record ID", RecID);
        Assert.RecordIsNotEmpty(RestrictedRecord);
    end;

    local procedure VerifyNoRestrictionRecordExists(RecID: RecordID)
    var
        RestrictedRecord: Record "Restricted Record";
    begin
        RestrictedRecord.SetRange("Record ID", RecID);
        Assert.RecordIsEmpty(RestrictedRecord);
    end;

    local procedure ApproveItemJournalBatch(ItemJournalBatchName: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatchName);
        ItemJournalLine.FindFirst();
        ApprovalsMgmt.ApproveItemJournalRequest(ItemJournalLine);
    end;

    local procedure CancelApprovalRequestForItemJournal(ItemJournalBatchName: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatchName);
        if ItemJournalLine.FindFirst() then
            ApprovalsMgmt.tryCancelJournalBatchApprovalRequest(ItemJournalLine);
    end;

    local procedure SelectItemJnlTemplate(): Code[10]
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);

        exit(ItemJournalTemplate.Name);
    end;

    local procedure AddApprovalComment(ApprovalEntry: Record "Approval Entry")
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.Init();
        ApprovalCommentLine."Table ID" := ApprovalEntry."Table ID";
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine."Document Type" := ApprovalEntry."Document Type";
        ApprovalCommentLine."Document No." := ApprovalEntry."Document No.";
        ApprovalCommentLine."Record ID to Approve" := ApprovalEntry."Record ID to Approve";
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        ApprovalCommentLine.Comment := 'Test';
        ApprovalCommentLine.Insert(true);
    end;

    local procedure ApprovalCommentExists(ApprovalEntry: Record "Approval Entry"): Boolean
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Document Type", ApprovalEntry."Document Type");
        ApprovalCommentLine.SetRange("Document No.", ApprovalEntry."Document No.");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");

        exit(not ApprovalCommentLine.IsEmpty());
    end;

    local procedure SendApprovalRequestForItemJournal(ItemJournalBatchName: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatchName);
        ItemJournalLine.FindFirst();

        ApprovalsMgmt.TrySendJournalBatchApprovalRequest(ItemJournalLine);
    end;

    local procedure CreateFirstQualifiedApprovalEnabledWorkflow(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        CreateCustomApproverTypeWorkflow(Workflow, WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", WorkflowSetup.ItemJournalBatchApprovalWorkflowCode());
        EnableWorkflow(Workflow);
    end;

    local procedure VerifyApprovalEntryIsApproved(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Approved);
    end;

    local procedure VerifyApprovalEntryIsOpen(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Open);
    end;

    local procedure VerifyApprovalEntrySenderID(ApprovalEntry: Record "Approval Entry"; SenderId: Code[50])
    begin
        ApprovalEntry.TestField("Sender ID", SenderId);
    end;

    local procedure VerifyApprovalEntryApproverID(ApprovalEntry: Record "Approval Entry"; ApproverId: Code[50])
    begin
        ApprovalEntry.TestField("Approver ID", ApproverId);
    end;

    local procedure VerifySelfApprovalEntryAfterSendingForApproval(RecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RecordID);
        Assert.RecordCount(ApprovalEntry, 1);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CopyStr(UserId, 1, 50));
        VerifyApprovalEntryApproverID(ApprovalEntry, CopyStr(UserId, 1, 50));
    end;

    local procedure CreateApprovalChainEnabledWorkflow(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        CreateCustomApproverTypeWorkflow(Workflow, WorkflowStepArgument."Approver Limit Type"::"Approver Chain", WorkflowSetup.ItemJournalBatchApprovalWorkflowCode());
        EnableWorkflow(Workflow);
    end;

    local procedure EnableWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure CreateCustomApproverTypeWorkflow(var Workflow: Record Workflow; ApproverLimitType: Enum "Workflow Approver Limit Type"; WorkflowCode: Code[17])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowCode);

        FindWorkflowStepArgument(Workflow, WorkflowStepArgument);

        WorkflowStepArgument.Validate("Approver Limit Type", ApproverLimitType);
        WorkflowStepArgument.Modify(true);
    end;

    local procedure FindWorkflowStepArgument(Workflow: Record Workflow; var WorkflowStepArgument: Record "Workflow Step Argument")
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::Response);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        WorkflowStep.FindFirst();

        WorkflowStepArgument.Get(WorkflowStep.Argument);
    end;

    local procedure CreateDirectApprovalEnabledWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemJournalBatchApprovalWorkflowCode());
    end;

    local procedure CreateApprovalSetup(var ApproverUserSetup: Record "User Setup"; var RequestorUserSetup: Record "User Setup")
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, CopyStr(UserId, 1, 50));
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);

        RequestorUserSetup."Unlimited Purchase Approval" := false;
        RequestorUserSetup."Purchase Amount Approval Limit" := 100;
        RequestorUserSetup.Modify();

        // Ensure the approver has higher approval limits to be qualified.
        ApproverUserSetup."Unlimited Purchase Approval" := true;
        ApproverUserSetup.Modify();

        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);
    end;

    local procedure ShowApprovalEntries(ItemJournalBatchName: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatchName);
        ItemJournalLine.FindFirst();
        ApprovalsMgmt.ShowJournalApprovalEntries(ItemJournalLine);
    end;

    local procedure CreateOpenApprovalEntryForCurrentUser(RecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Document Type" := ApprovalEntry."Document Type"::" ";
        ApprovalEntry."Document No." := '';
        ApprovalEntry."Table ID" := RecordID.TableNo;
        ApprovalEntry."Record ID to Approve" := RecordID;
        ApprovalEntry."Approver ID" := CopyStr(UserId, 1, 50);
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Sequence No." := 1;
        ApprovalEntry.Insert();
    end;

    local procedure CreateAndEnableItemJournalBatchWorkflowDefinition(ResponseUserID: Code[50]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        WorkflowCode: Code[20];
    begin
        WorkflowCode :=
          WorkflowWebhookSetup.CreateWorkflowDefinition(WorkflowEventHandling.RunWorkflowOnSendItemJournalBatchForApprovalCode(),
            '', DynamicRequestPageParametersItemJournalBatchTxt, ResponseUserID);
        Workflow.Get(WorkflowCode);
        LibraryWorkflow.EnableWorkflow(Workflow);
        exit(WorkflowCode);
    end;

    local procedure CreateJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; JournalTemplateName: Code[10])
    begin
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, JournalTemplateName);
    end;

    local procedure CreateItemJournalBatchWithOneJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
    begin
        CreateJournalBatch(ItemJournalBatch, SelectItemJnlTemplate());

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        ItemJournalLine."Unit Amount" := LibraryRandom.RandDec(100, 2);
        ItemJournalLine."Posting Date" := Today;
        ItemJournalLine.Modify(true);
    end;

    local procedure GetPendingWorkflowStepInstanceIdFromDataId(Id: Guid): Guid
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry.SetFilter("Data ID", Id);
        WorkflowWebhookEntry.SetRange(Response, WorkflowWebhookEntry.Response::Pending);
        WorkflowWebhookEntry.FindFirst();

        exit(WorkflowWebhookEntry."Workflow Step Instance ID");
    end;

    local procedure VerifyWorkflowWebhookEntryResponse(Id: Guid; ResponseArgument: Option)
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry.SetCurrentKey("Data ID");
        WorkflowWebhookEntry.SetRange("Data ID", Id);
        WorkflowWebhookEntry.FindFirst();

        WorkflowWebhookEntry.TestField(Response, ResponseArgument);
    end;

    local procedure AssignApprovalEntry(var ApprovalEntry: Record "Approval Entry"; RequestorUserSetup: Record "User Setup")
    begin
        ApprovalEntry."Approver ID" := RequestorUserSetup."User ID";
        ApprovalEntry.Modify(true);
    end;

    local procedure CreateWorkflowStepInstance(WorkflowCode: Code[20]; RecordId: RecordId)
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        WorkflowStepInstance.Init();
        WorkflowStepInstance."Workflow Code" := WorkflowCode;
        WorkflowStepInstance."Record ID" := RecordId;
        WorkflowStepInstance.Insert(true);
    end;

    local procedure RejectItemJournalBatch(ItemJournalBatchName: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatchName);
        ItemJournalLine.FindFirst();
        ApprovalsMgmt.RejectItemJournalRequest(ItemJournalLine);
    end;

    local procedure VerifyOpenApprovalEntry(ApprovalEntry: Record "Approval Entry"; ApproverUserSetup: Record "User Setup"; RequestorUserSetup: Record "User Setup")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.TestField("Sender ID", RequestorUserSetup."User ID");
        ApprovalEntry.TestField("Approver ID", ApproverUserSetup."User ID");
    end;

    local procedure VerifyApprovalEntryIsRejected(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    local procedure CreateDirectApprovalWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.ItemJournalBatchApprovalWorkflowCode());
    end;

    local procedure CreatePhysicalInventoryJournalBatchWithOneJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        RunCalculateInventoryReport(ItemJournalBatch, ItemJournalLine, PurchaseLine."No.");
    end;

    local procedure CreateOutputJournalBatchWithOneJournalLine(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        LibraryInventory.CreateItemSimple(ParentItem, "Costing Method"::FIFO, 0);
        LibraryInventory.CreateItemSimple(ChildItem, "Costing Method"::FIFO, 0);
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ParentItem, ChildItem, LibraryRandom.RandInt(1), '');

        LibraryPurchase.PostPurchaseOrder(PurchaseHeader, ChildItem, '', '', LibraryRandom.RandIntInRange(1000, 2000), WorkDate(), LibraryRandom.RandDec(100, 2), true, true);

        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ParentItem, '', '', LibraryRandom.RandInt(2), WorkDate());
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, WorkDate(), LibraryRandom.RandInt(1), 0);
    end;

    local procedure CreateConsumptionJournalBatchWithOneJournalLine(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        LibraryInventory.CreateItemSimple(ParentItem, "Costing Method"::FIFO, 0);
        LibraryInventory.CreateItemSimple(ChildItem, "Costing Method"::FIFO, 0);
        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ParentItem, ChildItem, LibraryRandom.RandInt(1), '');

        LibraryPurchase.PostPurchaseOrder(PurchaseHeader, ChildItem, '', '', LibraryRandom.RandIntInRange(1000, 2000), WorkDate(), LibraryRandom.RandDec(100, 2), true, true);

        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ParentItem, '', '', LibraryRandom.RandInt(2), WorkDate());
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        LibraryManufacturing.CreateConsumptionJournalLine(ItemJournalBatch, ProdOrderLine, ChildItem, WorkDate(), '', '', LibraryRandom.RandInt(1), 0);
    end;

    local procedure RunCalculateInventoryReport(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::"Phys. Inventory");

        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine."Document No." := LibraryUtility.GenerateGUID();
        LibraryInventory.CalculateInventoryForSingleItem(ItemJournalLine, ItemNo, WorkDate(), true, false);
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure CheckUserCanCancelTheApprovalRequestForAPhysicalInventoryJnlBatch(ItemJournalBatch: Record "Item Journal Batch"; CancelActionExpectedEnabled: Boolean)
    var
        PhysInventoryJournal: TestPage "Phys. Inventory Journal";
    begin
        PhysInventoryJournal.OpenView();
        PhysInventoryJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        if CancelActionExpectedEnabled then
            Assert.AreEqual(CancelActionExpectedEnabled, PhysInventoryJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeEnabledLbl)
        else
            Assert.AreEqual(CancelActionExpectedEnabled, PhysInventoryJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeDisabledLbl);

        PhysInventoryJournal.Close();
    end;

    local procedure SendApprovalRequestForPhysicalInventoryJnlBatch(ItemJournalBatchName: Code[20])
    var
        PhysInventoryJournal: TestPage "Phys. Inventory Journal";
    begin
        PhysInventoryJournal.OpenView();
        PhysInventoryJournal.CurrentJnlBatchName.SetValue(ItemJournalBatchName);
        PhysInventoryJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure CancelApprovalRequestForPhysicalInventoryJnlBatch(ItemJournalBatchName: Code[20])
    var
        PhysInventoryJournal: TestPage "Phys. Inventory Journal";
    begin
        PhysInventoryJournal.OpenView();
        PhysInventoryJournal.CurrentJnlBatchName.SetValue(ItemJournalBatchName);
        PhysInventoryJournal.CancelApprovalRequestJournalBatch.Invoke();
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindSet();
    end;

    local procedure CheckCommentsForDocumentOnPhysicalInventoryJournalPage(ItemJournalBatch: Record "Item Journal Batch"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        PhysInventoryPage: TestPage "Phys. Inventory Journal";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        PhysInventoryPage.OpenView();
        PhysInventoryPage.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        if CommentActionIsVisible then
            Assert.AreEqual(CommentActionIsVisible, PhysInventoryPage.Comments.Visible(), ApprovalCommentActionMustBeVisibleLbl)
        else
            Assert.AreEqual(CommentActionIsVisible, PhysInventoryPage.Comments.Visible(), ApprovalCommentActionMustNotBeVisibleLbl);

        if CommentActionIsVisible then begin
            PhysInventoryPage.Comments.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();

            Assert.AreEqual(
                NumberOfExpectedComments,
                NumberOfComments,
                StrSubstNo(PageContainsWrongNumberOfCommentsLbl, ApprovalComments.Caption(), NumberOfExpectedComments));

            ApprovalComments.Comment.SetValue(TestCommentLbl + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        PhysInventoryPage.Close();
    end;

    local procedure CheckUserCanCancelTheApprovalRequestForAOutputJnlBatch(ItemJournalBatch: Record "Item Journal Batch"; CancelActionExpectedEnabled: Boolean)
    var
        OutputJournal: TestPage "Output Journal";
    begin
        OutputJournal.OpenView();
        OutputJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        if CancelActionExpectedEnabled then
            Assert.AreEqual(CancelActionExpectedEnabled, OutputJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeEnabledLbl)
        else
            Assert.AreEqual(CancelActionExpectedEnabled, OutputJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeDisabledLbl);

        OutputJournal.Close();
    end;

    local procedure SendApprovalRequestForOutputJnlBatch(ItemJournalBatchName: Code[20])
    var
        OutputJournal: TestPage "Output Journal";
    begin
        OutputJournal.OpenView();
        OutputJournal.CurrentJnlBatchName.SetValue(ItemJournalBatchName);
        OutputJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure CancelApprovalRequestForOutputJnlBatch(ItemJournalBatchName: Code[20])
    var
        OutputJournal: TestPage "Output Journal";
    begin
        OutputJournal.OpenView();
        OutputJournal.CurrentJnlBatchName.SetValue(ItemJournalBatchName);
        OutputJournal.CancelApprovalRequestJournalBatch.Invoke();
    end;

    local procedure CheckCommentsForDocumentOnOutputJournalPage(ItemJournalBatch: Record "Item Journal Batch"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        OutputJournalPage: TestPage "Output Journal";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        OutputJournalPage.OpenView();
        OutputJournalPage.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        if CommentActionIsVisible then
            Assert.AreEqual(CommentActionIsVisible, OutputJournalPage.Comments.Visible(), ApprovalCommentActionMustBeVisibleLbl)
        else
            Assert.AreEqual(CommentActionIsVisible, OutputJournalPage.Comments.Visible(), ApprovalCommentActionMustNotBeVisibleLbl);

        if CommentActionIsVisible then begin
            OutputJournalPage.Comments.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();

            Assert.AreEqual(
                NumberOfExpectedComments,
                NumberOfComments,
                StrSubstNo(PageContainsWrongNumberOfCommentsLbl, ApprovalComments.Caption(), NumberOfExpectedComments));

            ApprovalComments.Comment.SetValue(TestCommentLbl + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        OutputJournalPage.Close();
    end;

    local procedure CheckUserCanCancelTheApprovalRequestForAConsumptionJnlBatch(ItemJournalBatch: Record "Item Journal Batch"; CancelActionExpectedEnabled: Boolean)
    var
        ConsumptionJournal: TestPage "Consumption Journal";
    begin
        ConsumptionJournal.OpenView();
        ConsumptionJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        if CancelActionExpectedEnabled then
            Assert.AreEqual(CancelActionExpectedEnabled, ConsumptionJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeEnabledLbl)
        else
            Assert.AreEqual(CancelActionExpectedEnabled, ConsumptionJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeDisabledLbl);

        ConsumptionJournal.Close();
    end;

    local procedure SendApprovalRequestForConsumptionJnlBatch(ItemJournalBatchName: Code[20])
    var
        ConsumptionJournal: TestPage "Consumption Journal";
    begin
        ConsumptionJournal.OpenView();
        ConsumptionJournal.CurrentJnlBatchName.SetValue(ItemJournalBatchName);
        ConsumptionJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure CancelApprovalRequestForConsumptionJnlBatch(ItemJournalBatchName: Code[20])
    var
        ConsumptionJournal: TestPage "Consumption Journal";
    begin
        ConsumptionJournal.OpenView();
        ConsumptionJournal.CurrentJnlBatchName.SetValue(ItemJournalBatchName);
        ConsumptionJournal.CancelApprovalRequestJournalBatch.Invoke();
    end;

    local procedure CheckCommentsForDocumentOnConsumptionJournalPage(ItemJournalBatch: Record "Item Journal Batch"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        ConsumptionJournalPage: TestPage "Consumption Journal";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        ConsumptionJournalPage.OpenView();
        ConsumptionJournalPage.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        if CommentActionIsVisible then
            Assert.AreEqual(CommentActionIsVisible, ConsumptionJournalPage.Comments.Visible(), ApprovalCommentActionMustBeVisibleLbl)
        else
            Assert.AreEqual(CommentActionIsVisible, ConsumptionJournalPage.Comments.Visible(), ApprovalCommentActionMustNotBeVisibleLbl);

        if CommentActionIsVisible then begin
            ConsumptionJournalPage.Comments.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();

            Assert.AreEqual(
                NumberOfExpectedComments,
                NumberOfComments,
                StrSubstNo(PageContainsWrongNumberOfCommentsLbl, ApprovalComments.Caption(), NumberOfExpectedComments));

            ApprovalComments.Comment.SetValue(TestCommentLbl + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        ConsumptionJournalPage.Close();
    end;

    local procedure CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry: Record "Approval Entry"; NumberOfExpectedComments: Integer)
    var
        ApprovalComments: TestPage "Approval Comments";
        ApprovalEntries: TestPage "Approval Entries";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        ApprovalEntries.OpenView();
        ApprovalEntries.GotoRecord(ApprovalEntry);

        ApprovalEntries.Comments.Invoke();
        if ApprovalComments.First() then
            repeat
                NumberOfComments += 1;
            until ApprovalComments.Next();

        Assert.AreEqual(
            NumberOfExpectedComments,
            NumberOfComments,
            StrSubstNo(PageContainsWrongNumberOfCommentsLbl, ApprovalComments.Caption(), NumberOfExpectedComments));

        ApprovalComments.Close();
        ApprovalEntries.Close();
    end;

    local procedure CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry: Record "Approval Entry"; NumberOfExpectedComments: Integer)
    var
        ApprovalComments: TestPage "Approval Comments";
        RequestsToApprove: TestPage "Requests to Approve";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        RequestsToApprove.OpenView();
        RequestsToApprove.GotoRecord(ApprovalEntry);

        RequestsToApprove.Comments.Invoke();
        if ApprovalComments.First() then
            repeat
                NumberOfComments += 1;
            until ApprovalComments.Next();

        Assert.AreEqual(
            NumberOfExpectedComments,
            NumberOfComments,
            StrSubstNo(PageContainsWrongNumberOfCommentsLbl, ApprovalComments.Caption(), NumberOfExpectedComments));

        ApprovalComments.Close();
        RequestsToApprove.Close();
    end;

    local procedure Approve(var ApprovalEntry: Record "Approval Entry")
    var
        RequestsToApprove: TestPage "Requests to Approve";
    begin
        RequestsToApprove.OpenView();
        RequestsToApprove.GotoRecord(ApprovalEntry);
        RequestsToApprove.Approve.Invoke();
    end;

    local procedure VerifyApprovalEntryIsCancelled(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Canceled);
    end;

    local procedure CreateJournalBatchOpenApprovalEntryForCurrentUser(ItemJournalBatch: Record "Item Journal Batch")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Table ID" := Database::"Item Journal Batch";
        ApprovalEntry."Record ID to Approve" := ItemJournalBatch.RecordId;
        ApprovalEntry."Sender ID" := CopyStr(UserId, 1, 50);
        ApprovalEntry."Approver ID" := CopyStr(UserId, 1, 50);
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Sequence No." := 1;
        ApprovalEntry.Insert();
    end;

    local procedure SendApprovalRequestForItemJournalWithSetup(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line")
    var
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemJournalBatchApprovalWorkflowCode());
        CreateItemJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);

        Commit();

        SendApprovalRequestForItemJournal(ItemJournalBatch.Name);
    end;

    local procedure SendApprovalRequestForPhysicalInventoryJournalWithSetup(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; var RequestorUserSetup: Record "User Setup")
    var
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
    begin
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreatePhysicalInventoryJournalBatchWithOneJournalLine(ItemJournalBatch, ItemJournalLine);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        CreateGeneralPostingSetup(ItemJournalLine."Gen. Bus. Posting Group", ItemJournalLine."Gen. Prod. Posting Group");

        Commit();

        SendApprovalRequestForPhysicalInventoryJnlBatch(ItemJournalBatch.Name);
    end;

    local procedure SendApprovalRequestForOutputJournalWithSetup(var ItemJournalBatch: Record "Item Journal Batch"; var RequestorUserSetup: Record "User Setup")
    var
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
    begin
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateOutputJournalBatchWithOneJournalLine(ItemJournalBatch);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        Commit();

        SendApprovalRequestForOutputJnlBatch(ItemJournalBatch.Name);
    end;

    local procedure SendApprovalRequestForConsumptionJournalWithSetup(var ItemJournalBatch: Record "Item Journal Batch"; var RequestorUserSetup: Record "User Setup")
    var
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
    begin
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateConsumptionJournalBatchWithOneJournalLine(ItemJournalBatch);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        Commit();

        SendApprovalRequestForConsumptionJnlBatch(ItemJournalBatch.Name);
    end;

    local procedure CreateGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup) then begin
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup, GenProdPostingGroup);
            LibraryERM.SetGeneralPostingSetupInvtAccounts(GeneralPostingSetup);
            LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
            LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        end;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    procedure ApprovalEntriesPageHandler(var ApprovalEntries: TestPage "Approval Entries")
    var
        VariableVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(VariableVariant);
        ApprovalEntries.Close();
    end;
}