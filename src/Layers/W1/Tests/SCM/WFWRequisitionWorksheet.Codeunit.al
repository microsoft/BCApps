codeunit 139506 "WFW Requisition Worksheet"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "User Setup" = imd,
                  TableData "Workflow Webhook Entry" = imd,
                  TableData "Approval Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Requisition Worksheet]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        IsInitialized: Boolean;
        BogusUserIdTxt: Label 'CONTOSO';
        DynamicRequestPageParametersRequisitionWkshNameTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Requisition Line">VERSION(1) SORTING(Field1,Field51,Field2)</DataItem></DataItems></ReportParameters>', Locked = true;
        RecordRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1 = Record ID, for example Customer 10000';
        NoApprovalCommentExistsErr: Label 'There is no approval comment for this approval entry.';
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        ApprovalCommentWasNotDeletedErr: Label 'The approval comment for this approval entry was not deleted.';
        PreventModifyRecordWithOpenApprovalEntryMsg: Label 'You can''t modify a record pending approval. Add a comment or reject the approval to modify the record.';
        ImposedRestrictionLbl: Label 'Imposed restriction';
        SendApprovalRequestRequisitionWorksheetBatchActionMustBeDisabledLbl: Label 'Send Approval Request Requisition Worksheet Batch action must be disabled';
        CancelApprovalRequestRequisitionWkshBatchActionMustBeDisabledLbl: Label 'Cancel Approval Request Requisition Worksheet Batch action must be disabled';
        CancelApprovalRequestRequisitionWkshBatchActionMustBeEnabledLbl: Label 'Cancel Approval Request Requisition Worksheet Batch action must be enabled';
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
        CannotRenameRecordErr: Label 'You cannot rename a %1.', Comment = '%1 = Table Caption';

    [Test]
    procedure TestEnsureNecessaryTableRelatiosnsAreSetup()
    var
        DummyRequisitionWkshName: Record "Requisition Wksh. Name";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowTableRelation: Record "Workflow - Table Relation";
    begin
        // [SCENARIO 307883] Verify that required workflow table relations for "Requisition Wksh. Name" approval are established.
        Initialize();

        // [GIVEN] Remove all existing workflows to ensure a clean state.
        LibraryWorkflow.DeleteAllExistingWorkflows();

        // [WHEN] Initialize workflow setup.
        WorkflowSetup.InitWorkflow();

        // [THEN] Verify that table relation for "Requisition Wksh. Name" approval workflow exists.
        WorkflowTableRelation.Get(
            Database::"Requisition Wksh. Name", DummyRequisitionWkshName.FieldNo(SystemId),
            Database::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
    end;

    [Test]
    procedure TestRequisitionWorksheetNameApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        ApproverUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 307883] Verify Approver approve the request for the "Requisition Wksh. Name".
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableRequisitionWkshNameWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] Create an Requisition Line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);
        Commit();

        // [WHEN] Send an Approval Request for Requisition Worksheet.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify Open Approval Entry.
        VerifyWorkflowWebhookEntryResponse(RequisitionWkshName.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Approve the Approval Entry via workflow webhook.
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(RequisitionWkshName.SystemId));

        // [THEN] Verify Approval Entry is Approved.
        VerifyWorkflowWebhookEntryResponse(RequisitionWkshName.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    procedure TestRequisitionWorksheetNameApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        ApproverUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 307883] Verify that a webhook "Requisition Wksh. Name" approval workflow rejection path works correctly.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableRequisitionWkshNameWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] Create an Requisition Line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [WHEN] Send an Approval Request for Requisition Worksheet.
        Commit();
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify workflow webhook entry response is pending.
        VerifyWorkflowWebhookEntryResponse(RequisitionWkshName.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Webhook "Requisition Wksh. Name" approval workflow receives a rejection response.
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(RequisitionWkshName.SystemId));

        // [THEN] Verify that "Requisition Wksh. Name" is rejected.
        VerifyWorkflowWebhookEntryResponse(RequisitionWkshName.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    procedure TestRequisitionWkshNameApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        ApproverUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 307883] Verify that a Webhook "Requisition Wksh. Name" approval workflow cancellation path works correctly.
        Initialize();

        // [GIVEN] A webhook "Requisition Wksh. Name" approval workflow is enabled.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableRequisitionWkshNameWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] Create an Requisition Line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [WHEN] Send an Approval Request for Requisition Worksheet.
        Commit();
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify workflow webhook entry response is pending.
        VerifyWorkflowWebhookEntryResponse(RequisitionWkshName.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Webhook "Requisition Wksh. Name" approval workflow receives a cancellation response.
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(RequisitionWkshName.SystemId));

        // [THEN] Verify that the "Requisition Wksh. Name" is cancelled.
        VerifyWorkflowWebhookEntryResponse(RequisitionWkshName.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;


    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestDirectApproverApprovesRequestForRequisitionWkshName()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 307883] Verify that Approver approves the request for the "Requisition Wksh. Name".
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create an Requisition Line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Create an Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for Requisition Worksheet.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify Open Approval Entry.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId());
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Assign an Approval Entry.
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [WHEN] Approve an Approval Entry.
        ApproveRequisitionWkshName(RequisitionWkshName.Name);

        // [THEN] Verify Approval Entry is Approved.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId());
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestDirectApproverRejectsRequestForRequisitionWkshName()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 307883] Verify that Approver Rejects the request for the "Requisition Wksh. Name".
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create a Requisition Line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Create an Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for Requisition Worksheet.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify Open Approval Entry.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId());
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Assign an Approval Entry.
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [WHEN] Reject an Approval Entry.
        RejectRequisitionWkshName(RequisitionWkshName.Name);

        // [THEN] Verify that Approval Entry is Rejected.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId());
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('ApprovalEntriesPageHandler')]
    procedure TestShowApprovalEntriesPage()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 307883] Verify that the related approval entries for the "Requisition Wksh. Name" are displayed when an approval entry exists.
        Initialize();

        // [GIVEN] Create a Direct approval workflow and enabled.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create a "Requisition Wksh. Name" with one requisition Line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Create a open approval entry for the current user.
        CreateOpenApprovalEntryForCurrentUser(RequisitionWkshName.RecordId);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Enqueue the record ID of the "Requisition Wksh. Name".
        LibraryVariableStorage.Enqueue(RequisitionWkshName.RecordId);

        // [WHEN] Show approval entries for the "Requisition Wksh. Name".
        ShowApprovalEntries(RequisitionWkshName.Name);

        // [THEN] Verify that the Approval Entries page is shown through Handler.
        LibraryVariableStorage.AssertEmpty();
    end;


    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCannotSendApprovalRequestToChainOfApprovers()
    var
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 307883] Verify that an approval request to a chain of approvers is self-approved if no valid approver is found for the "Requisition Wksh. Name".
        Initialize();

        // [GIVEN] Create a Direct Approval and Enable Workflow with Approver Chain.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateApprovalChainEnabledWorkflow(Workflow);

        // [GIVEN] Create an Requisition Line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for Requisition Worksheet.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify that approval request is self-approved due to absence of a valid approver chain.
        VerifySelfApprovalEntryAfterSendingForApproval(RequisitionWkshName.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCannotSendApprovalRequestToFirstQualifiedApprover()
    var
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 307883] Verify that an approval request to the first qualified approver is self-approved if no qualified approver is found for the "Requisition Wksh. Name".
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow with First Qualified Approver.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateFirstQualifiedApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create an Requisition Line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for requisition worksheet.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify that approval request is self-approved due to absence of a qualified approver.
        VerifySelfApprovalEntryAfterSendingForApproval(RequisitionWkshName.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure TestDeleteLinesAfterApprovalRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        Workflow: Record Workflow;
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO 307883] Verify that deleting all Requisition Lines after an approval request cancels the approval request and deletes approval entries.
        Initialize();

        // [GIVEN] Create a Direct approval workflow and enabled.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create an "Requisition Wksh. Name" with one requisition Line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Create an Approval Setup.
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, CopyStr(UserId, 1, 50));
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Send an Approval Request for Requisition Worksheet.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [GIVEN] Get the approval entry for the batch.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);

        // [WHEN] Add an approval comment to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [THEN] Verify that approval entry is open and approval comment exists.
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.RecordCount(ApprovalEntry, 1);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // [WHEN] All Requisition Lines in the batch are deleted.
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.DeleteAll(true);

        // [THEN] Verify that deleting all Requisition Lines after an approval request cancels the approval request and deletes approval entries.
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TestHasPendingWorkflowWebhookEntryByRecordId()
    var
        RequisitionLine: Record "Requisition Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 307883] Verify that CanRequestApproval returns false when there is a pending Workflow Webhook Entry for an Requisition Line.
        Initialize();

        // [GIVEN] Insert a Requisition Line.
        RequisitionLine.Insert();

        // [GIVEN] Create a Workflow Webhook Entry for the Requisition Line with status Pending.
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry."Record ID" := RequisitionLine.RecordId();
        WorkflowWebhookEntry.Response := WorkflowWebhookEntry.Response::Pending;
        WorkflowWebhookEntry.Insert();

        // [WHEN] CanRequestApproval is checked for the Requisition Line.
        Assert.IsFalse(WorkflowWebhookManagement.CanRequestApproval(RequisitionLine.RecordId()), CanRequestApprovalLbl);

        // [THEN] Verify that FindWorkflowWebhookEntryByRecordIdAndResponse returns true for the pending entry.
        Assert.IsTrue(
            WorkflowWebhookManagement.FindWorkflowWebhookEntryByRecordIdAndResponse(
                WorkflowWebhookEntry, RequisitionLine.RecordId(), WorkflowWebhookEntry.Response::Pending),
                FindWorkflowWebhookEntryByRecordIdAndResponseLbl);
    end;

    [Test]
    procedure TestRequisitionLineApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 307883] Ensure that a webhook "Requisition Wksh. Name" approval workflow approval path works correctly.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableRequisitionWkshNameWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] Create an "Requisition Wksh. Name" with one or more requisition lines.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] An approval request is sent for the Requisition Wksh. Name.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify that the workflow webhook entry response is pending.
        VerifyWorkflowWebhookEntryResponse(RequisitionWkshName.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Approval entry is continued via workflow webhook.
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(RequisitionWkshName.SystemId));

        // [THEN] Verify that the workflow webhook entry response is continue.
        VerifyWorkflowWebhookEntryResponse(RequisitionWkshName.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure TestDeleteAfterApprovalRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        Workflow: Record Workflow;
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO 307883] Verify that deleting the record after an approval request is sent cancels the approval request and deletes the approval entries.
        Initialize();

        // [GIVEN] A direct approval workflow is created and enabled for "Requisition Wksh. Name".
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An "Requisition Wksh. Name" with one or more requisition lines is created.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Requestor and approver user setups are configured for the approval process.
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, CopyStr(UserId, 1, 208));
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Approval request is sent for the Requisition Wksh. Name.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [GIVEN] Approval entry for the batch is retrieved.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);

        // [WHEN] An approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [THEN] Verify that the approval entry exists and is open and the approval comment exists.
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // [WHEN] "Requisition Wksh. Name" is deleted.
        RequisitionWkshName.Delete(true);

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
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 307883] Verify that renaming the record after an approval request is sent changes the approval request to point to the new record.
        Initialize();

        // [GIVEN] Direct approval workflow is created and enabled for "Requisition Wksh. Name".
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An "Requisition Wksh. Name" with one requisition line is created.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Requestor and approver user setups are configured for the approval process.
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, CopyStr(UserId, 1, 50));
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Approval request is sent for the "Requisition Wksh. Name".
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [GIVEN] Approval entry for the batch is retrieved.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);

        // [WHEN] Approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [THEN] Verify that approval entry is open and approval comment exists.
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // [WHEN] "Requisition Wksh. Name" is renamed.
        asserterror RequisitionWkshName.Rename(RequisitionWkshName."Worksheet Template Name", LibraryRandom.RandText(10));

        // [THEN] Verify that the requisition line cannot be renamed.
        Assert.ExpectedError(StrSubstNo(CannotRenameRecordErr, RequisitionLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ApprovalEntriesPageHandler')]
    procedure TestShowApprovalEntriesEmptyPage()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 307883] Verify that the approval entries page displays no approval entries for the batch.
        Initialize();

        // [GIVEN] Direct approval workflow is created and enabled for "Requisition Wksh. Name".
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An "Requisition Wksh. Name" with one requisition line is created.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Enqueue the record ID of the "Requisition Wksh. Name".
        LibraryVariableStorage.Enqueue(RequisitionWkshName.RecordId);

        // [WHEN] Show approval entries for the "Requisition Wksh. Name".
        ShowApprovalEntries(RequisitionWkshName.Name);

        // [THEN] Verify that the page handler verifies that no approval entries exist for the batch.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCancelRequisitionWkshNameForApprovalNotAllowsUsage()
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO 307883] Verify that a newly created "Requisition Wksh. Name" that has a canceled approval cannot be posted.
        Initialize();

        // [GIVEN] Approval user setup is configured.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        // [GIVEN] An enabled approval workflow for "Requisition Wksh. Name" is created.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.RequisitionWkshBatchApprovalWorkflowCode());

        // [GIVEN] An "Requisition Wksh. Name" and line are created.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] User sends an approval request from the "Requisition Wksh. Name".
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [GIVEN] User cancels the approval.
        CancelApprovalRequestForRequisitionWorksheet(RequisitionLine."Journal Batch Name");

        // [GIVEN] Find Requisition Line.
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.FindFirst();

        // [WHEN] Carry out action on the Requisition Line. 
        asserterror LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] Verify that an error is raised indicating that the record is restricted.
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(RequisitionWkshName.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestApproveRequisitionWkshNameForApprovalAllowsUsage()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO 307883] Verify that a newly created "Requisition Wksh. Name" that is approved can be posted.
        Initialize();

        // [GIVEN] Approval user setup is configured.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        // [GIVEN] Enabled approval workflow for "Requisition Wksh. Name" is created.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.RequisitionWkshBatchApprovalWorkflowCode());

        // [GIVEN] An "Requisition Wksh. Name" and line are created.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Send an approval request from the "Requisition Wksh. Name".
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [GIVEN] Approval entry for the batch is retrieved and assigned to the requestor.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);
        ApprovalUserSetup.Get(UserId);
        AssignApprovalEntry(ApprovalEntry, ApprovalUserSetup);

        // [WHEN] Approves the batch.
        ApproveRequisitionWkshName(RequisitionWkshName.Name);

        // [THEN] Verify that "Requisition Wksh. Name" can be posted.
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    [Test]
    procedure TestRestrictRequisitionWkshNameExportingWithApprovalRemovedWhenWorkflowInstancesRemoved()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO 307883] Verify that restrict exporting of an "Requisition Wksh. Name" when approval is needed, but all restrictions are removed when workflow is disabled and step instances are deleted.
        Initialize();

        // [GIVEN] Direct approval workflow is created and enabled for Requisition Wksh. Name.
        CreateDirectApprovalEnabledWorkflow(Workflow);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] An "Requisition Wksh. Name" with one requisition line is created.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [THEN] Verify that restriction record exists for the Requisition Line.
        VerifyRestrictionRecordExists(RequisitionLine.RecordId);

        // [GIVEN] Workflow step instance is created for the Requisition Line.
        CreateWorkflowStepInstance(Workflow.Code, RequisitionLine.RecordId);

        // [WHEN] Workflow is disabled and Workflow Step Instances are deleted.
        Workflow.Enabled := false;
        Workflow.Modify();
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        WorkflowStepInstance.DeleteAll(true);

        // [THEN] Verify that no restriction record exists for the Requisition Line.
        VerifyNoRestrictionRecordExists(RequisitionLine.RecordId);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('MessageHandler')]
    procedure TestBatchWorkflowIsVisibleOnRequisitionWorksheetPage()
    var
        ApprovalUserSetup: Record "User Setup";
        RequisitionWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        Workflow: Record Workflow;
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [SCENARIO 307883] Verify that batch workflow status factbox becomes visible when the batch is sent for approval on requisition worksheet Page.
        Initialize();

        // [GIVEN] requisition worksheet Templates are deleted.
        RequisitionWkshTemplate.DeleteAll();

        // [GIVEN] Approval users and direct approval workflow are set up.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An "Requisition Wksh. Name" with one requisition line is created.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [WHEN] The requisition worksheet page is opened for the batch.
        ReqWorksheet.OpenView();
        ReqWorksheet.CurrentJnlBatchName.SetValue(RequisitionWkshName.Name);

        // [THEN] Verify that batch workflow status factboxes are not visible before approval request.
        Assert.IsFalse(ReqWorksheet.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowStatusFactboxMustNotBeVisibleLbl);

        // [WHEN] Send Approval Request from requisition worksheet Page.
        ReqWorksheet.SendApprovalRequestWkshBatch.Invoke();

        // [THEN] Verify that the batch workflow status factbox becomes visible.
        Assert.IsTrue(ReqWorksheet.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowStatusFactboxMustBeVisibleLbl);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('MessageHandler')]
    procedure TestBatchWorkflowIsNotVisibleOnRequisitionWkshPageAfterCancelApproval()
    var
        ApprovalUserSetup: Record "User Setup";
        RequisitionWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        Workflow: Record Workflow;
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [SCENARIO 307883] Verify that batch workflow status factbox becomes not visible when the batch is cancelled for approval on requisition worksheet Page.
        Initialize();

        // [GIVEN] Requisition worksheet Templates are deleted.
        RequisitionWkshTemplate.DeleteAll();

        // [GIVEN] Approval users and direct approval workflow are set up.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] The requisition worksheet page is opened and an approval request is sent.
        ReqWorksheet.OpenView();
        ReqWorksheet.CurrentJnlBatchName.SetValue(RequisitionWkshName.Name);
        ReqWorksheet.SendApprovalRequestWkshBatch.Invoke();

        // [WHEN] Cancel Approval Request from requisition worksheet Page.
        ReqWorksheet.CancelApprovalRequestWkshBatch.Invoke();

        // [THEN] Verify that batch workflow status factboxes are not visible.
        Assert.IsFalse(ReqWorksheet.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowStatusFactboxMustNotBeVisibleLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestApproveRequisitionWkshNameForApprovalAdministrator()
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ApprovalEntry: Record "Approval Entry";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 307883] Verify that "Requisition Wksh. Name" is auto approved for Approval Administrator.
        Initialize();

        // [GIVEN] User is set up as Approval Administrator.
        SetupApprovalAdministrator();

        // [GIVEN] Enabled approval workflow for "Requisition Wksh. Name" is created.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] "Requisition Wksh. Name" is created with one requisition line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [WHEN] Approval request is sent for the Requisition Wksh. Name.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify that approval entry for the batch is approved automatically.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    procedure TestModifyRequisitionLineIsNotAllowedForCreatedApprovalEntry()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 307883] Verify that modifying an Requisition Line is not allowed when an approval entry has status created.
        Initialize();

        // [GIVEN] An Requisition Line is created.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] An Approval Entry for the "Requisition Wksh. Name" is created with status created.
        CreateApprovalEntryForCurrentUser(RequisitionWkshName.RecordId, ApprovalStatus::Created);

        // [WHEN] Modify the Requisition Line.
        asserterror RequisitionLine.Modify(true);

        // [THEN] Verify that the expected error message is shown.
        Assert.ExpectedError(PreventModifyRecordWithOpenApprovalEntryMsg);
    end;

    [Test]
    procedure TestShowImposedRestrictionBatchStatusIfUserModifyRequisitionLineForApprovedApprovalRequest()
    var
        Workflow: Record Workflow;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ApprovalUserSetup: Record "User Setup";
        ReqWorksheet: TestPage "Req. Worksheet";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 307883] Verify that imposed restriction batch status is shown if user modifies Requisition Line for approved approval request.
        Initialize();

        // [GIVEN] Approval users and direct approval workflow are set up.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An Requisition Line is created.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] An Approval Entry for the "Requisition Wksh. Name" is created with status Approved.
        CreateApprovalEntryForCurrentUser(RequisitionWkshName.RecordId, ApprovalStatus::Approved);

        // [WHEN] Requisition Line is modified.
        RequisitionLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        RequisitionLine.Modify(true);

        // [THEN] Verify that imposed restriction batch status is shown on the requisition worksheet page.
        Commit();
        ReqWorksheet.OpenView();
        ReqWorksheet.CurrentJnlBatchName.SetValue(RequisitionWkshName.Name);
        Assert.AreEqual(ImposedRestrictionLbl, ReqWorksheet.RequisitionWkshBatchApprovalStatus.Value(), ImposedRestrictionMustBeShownLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestShowImposedRestrictionBatchStatusForWorkflowUserGroupIfFirstApprovalEntryIsApproved_requisitionWksh()
    var
        Workflow: Record Workflow;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [SCENARIO 307883] Verify that imposed restriction batch status is shown for Workflow User Group if first approval entry is auto approved.
        Initialize();

        // [GIVEN] Workflow template is copied.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.RequisitionWkshBatchApprovalWorkflowCode());

        // [GIVEN] Three user setups and a workflow user group are created and set for the workflow.
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] "Requisition Wksh. Name" is created with one requisition line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [WHEN] Approval request is sent for the Requisition Wksh. Name.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify that imposed restriction batch status is shown on the requisition worksheet page.
        ReqWorksheet.OpenView();
        ReqWorksheet.CurrentJnlBatchName.SetValue(RequisitionWkshName.Name);
        Assert.AreEqual(ImposedRestrictionLbl, ReqWorksheet.RequisitionWkshBatchApprovalStatus.Value(), ImposedRestrictionMustBeShownLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestApprovalActionsVisibilityOnRequisitionWkshName()
    var
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [SCENARIO 307883] Verify approval actions visibility on the "Requisition Wksh. Name".
        Initialize();

        // [GIVEN] Create an Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Create an Requisition Line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Create Direct Approval Workflow.
        CreateDirectApprovalWorkflow(Workflow);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open requisition worksheet.
        ReqWorksheet.OpenEdit();
        ReqWorksheet.CurrentJnlBatchName.SetValue(RequisitionWkshName.Name);

        // [THEN] Verify Action must not be visible and enabled.
        Assert.IsFalse(ReqWorksheet.SendApprovalRequestWkshBatch.Enabled(), SendApprovalRequestRequisitionWorksheetBatchActionMustBeDisabledLbl);
        Assert.IsFalse(ReqWorksheet.CancelApprovalRequestWkshBatch.Enabled(), CancelApprovalRequestRequisitionWkshBatchActionMustBeDisabledLbl);
        Assert.IsFalse(ReqWorksheet.Approve.Visible(), ApproveActionMustNotBeVisibleLbl);
        Assert.IsFalse(ReqWorksheet.Reject.Visible(), RejectActionMustNotBeVisibleLbl);
        Assert.IsFalse(ReqWorksheet.Delegate.Visible(), DelegateActionMustNotBeVisibleLbl);
        ReqWorksheet.Close();

        // [GIVEN] Enable Workflow.
        EnableWorkflow(Workflow);

        // [GIVEN] Send an approval request to properly set up the workflow state.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [GIVEN] Create Open Approval Entry For Current User.
        CreateOpenApprovalEntryForCurrentUser(RequisitionWkshName.RecordId());

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open requisition worksheet.
        ReqWorksheet.OpenEdit();
        ReqWorksheet.CurrentJnlBatchName.SetValue(RequisitionWkshName.Name);

        // [THEN] Verify Action must be visible and enabled.
        Assert.IsFalse(ReqWorksheet.SendApprovalRequestWkshBatch.Enabled(), SendApprovalRequestRequisitionWorksheetBatchActionMustBeDisabledLbl);
        Assert.IsTrue(ReqWorksheet.CancelApprovalRequestWkshBatch.Enabled(), CancelApprovalRequestRequisitionWkshBatchActionMustBeEnabledLbl);
        Assert.IsTrue(ReqWorksheet.Approve.Visible(), ApproveActionMustBeVisibleLbl);
        Assert.IsTrue(ReqWorksheet.Reject.Visible(), RejectActionMustBeVisibleLbl);
        Assert.IsTrue(ReqWorksheet.Delegate.Visible(), DelegateActionMustBeVisibleLbl);
        ReqWorksheet.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestWorkflowUserGroupSequentialApprovalWorksForRequisitionWkshName()
    var
        Workflow: Record Workflow;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ApprovalEntry: Record "Approval Entry";
    begin
        // [SCENARIO 307883] Verify that Workflow User Group with sequential approval works correctly for "Requisition Wksh. Name".
        Initialize();

        // [GIVEN] Copy Workflow Template.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.RequisitionWkshBatchApprovalWorkflowCode());

        // [GIVEN] Create Workflow.
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // [GIVEN] Enable Workflow.
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Create a Requisition Wksh. Name with one line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify that there is open approval entry.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.RecordIsNotEmpty(ApprovalEntry);

        // [WHEN] Approve all pending entries sequentially.
        CurrentUserSetup.Get(UserId);
        ApproveAllOpenApprovalEntriesForBatch(RequisitionWkshName.Name, RequisitionWkshName.RecordId, CurrentUserSetup);

        // [THEN] Verify that there is no open approval entry.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.IsTrue(ApprovalEntry.IsEmpty, UnexpectedNoOfApprovalEntriesErr);

        // [THEN] Verify that "Requisition Wksh. Name" can be posted.
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestRequisitionWorksheetCanBePostedWhenAllApprovalsAreCompleted()
    var
        Workflow: Record Workflow;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ApprovalEntry: Record "Approval Entry";
    begin
        // [SCENARIO 307883] Verify that posting is allowed when all workflow user group approvals are finished.
        Initialize();

        // [GIVEN] Copy workflow template.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.RequisitionWkshBatchApprovalWorkflowCode());

        // [GIVEN] Create user group with three approvers is created and enabled.
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Create Requisition Wksh. Name with one Line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify that there is open approval entry.
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, IntermediateApproverUserSetup, CurrentUserSetup);

        // [GIVEN] Assign Approval Entry to the current approver in the workflow group.
        AssignApprovalEntry(ApprovalEntry, CurrentUserSetup);

        // [WHEN] Approve "Requisition Wksh. Name".
        ApproveRequisitionWkshName(RequisitionWkshName.Name);

        // [THEN] Verify that there should still be remaining open approval entries.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.RecordIsNotEmpty(ApprovalEntry);

        // [WHEN] Carry Out Action on Requisition Line.
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        asserterror LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] Verify that an error is raised indicating that the record is restricted.
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(RequisitionWkshName.RecordId, 0, 1)));

        // [WHEN] Complete remaining approvals sequentially.
        CurrentUserSetup.Get(UserId);
        ApproveAllOpenApprovalEntriesForBatch(RequisitionWkshName.Name, RequisitionWkshName.RecordId, CurrentUserSetup);

        // [THEN] Verify that there are no remaining open approval entries.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.IsTrue(ApprovalEntry.IsEmpty, UnexpectedNoOfApprovalEntriesErr);

        // [THEN] Verify that "Requisition Wksh. Name" can be posted.
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestRequisitionWkshNameIsRejectedWhenUserGroupIsConfiguredInWorkflow()
    var
        Workflow: Record Workflow;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ApprovalEntry: Record "Approval Entry";
    begin
        // [SCENARIO 307883] Verify that Requisition Wksh. Name is rejected when user group is configured in workflow.
        Initialize();

        // [GIVEN] Copy Workflow Template.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.RequisitionWkshBatchApprovalWorkflowCode());

        // [GIVEN] Create Workflow.
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Create a Requisition Wksh. Name with one line.
        CreateRequisitionWkshNameWithOneRequisitionLine(RequisitionWkshName, RequisitionLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send approval request.
        SendApprovalRequestForRequisitionWorksheet(RequisitionWkshName.Name);

        // [THEN] Verify that an approval entry is open.
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);
        VerifyOpenApprovalEntry(ApprovalEntry, IntermediateApproverUserSetup, CurrentUserSetup);

        // [GIVEN] Assign Approval Entry to the current approver in the workflow group.
        AssignApprovalEntry(ApprovalEntry, CurrentUserSetup);

        // [WHEN] Reject the first pending entry.
        RejectRequisitionWkshName(RequisitionWkshName.Name);

        // [THEN] Verify that there is a rejected approval entry.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Rejected);
        Assert.RecordIsNotEmpty(ApprovalEntry);

        // [THEN] Verify that there are no open approval entries.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RequisitionWkshName.RecordId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.IsTrue(ApprovalEntry.IsEmpty, UnexpectedNoOfApprovalEntriesErr);
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        RequisitionWkshTemplate: Record "Req. Wksh. Template";
        ClearWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryVariableStorage.Clear();
        Workflow.ModifyAll(Enabled, false, true);
        UserSetup.DeleteAll();
        RequisitionWkshTemplate.DeleteAll();
        ClearWorkflowWebhookEntry.DeleteAll();
        LibraryERMCountryData.CreateVATData();
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

    local procedure ApproveRequisitionWkshName(RequisitionWkshNameName: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshNameName);
        RequisitionLine.FindFirst();
        ApprovalsMgmt.ApproveRequisitionWkshLineRequest(RequisitionLine);
    end;

    local procedure ApproveAllOpenApprovalEntriesForBatch(BatchName: Code[10]; RecIdToApprove: RecordId; ApproverUserSetup: Record "User Setup")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RecIdToApprove);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        if ApprovalEntry.FindFirst() then
            repeat
                AssignApprovalEntry(ApprovalEntry, ApproverUserSetup);
                ApproveRequisitionWkshName(BatchName);
            until ApprovalEntry.Next() = 0;
    end;

    local procedure CancelApprovalRequestForRequisitionWorksheet(RequisitionWkshNameName: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshNameName);
        if RequisitionLine.FindFirst() then
            ApprovalsMgmt.TryCancelWorksheetBatchApprovalRequest(RequisitionLine);
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

    local procedure SendApprovalRequestForRequisitionWorksheet(RequisitionWkshNameName: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshNameName);
        RequisitionLine.FindFirst();

        ApprovalsMgmt.TrySendWorksheetBatchApprovalRequest(RequisitionLine);
    end;

    local procedure CreateFirstQualifiedApprovalEnabledWorkflow(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        CreateCustomApproverTypeWorkflow(Workflow, WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", WorkflowSetup.RequisitionWkshBatchApprovalWorkflowCode());
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
        CreateCustomApproverTypeWorkflow(Workflow, WorkflowStepArgument."Approver Limit Type"::"Approver Chain", WorkflowSetup.RequisitionWkshBatchApprovalWorkflowCode());
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

    local procedure ShowApprovalEntries(RequisitionWkshNameName: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshNameName);
        RequisitionLine.FindFirst();
        ApprovalsMgmt.ShowWorksheetApprovalEntries(RequisitionLine);
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

    local procedure CreateAndEnableRequisitionWkshNameWorkflowDefinition(ResponseUserID: Code[50]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        WorkflowCode: Code[20];
    begin
        WorkflowCode :=
          WorkflowWebhookSetup.CreateWorkflowDefinition(WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode(),
            '', DynamicRequestPageParametersRequisitionWkshNameTxt, ResponseUserID);
        Workflow.Get(WorkflowCode);
        LibraryWorkflow.EnableWorkflow(Workflow);
        exit(WorkflowCode);
    end;

    local procedure CreateRequisitionWkshNameWithOneRequisitionLine(var RequisitionWkshName: Record "Requisition Wksh. Name"; var RequisitionLine: Record "Requisition Line")
    var
        Item: Record Item;
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, SelectRequisitionTemplateName());

        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        CreateRequisitionLine(RequisitionLine, RequisitionWkshName, Item."No.");
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name"; ItemNo: Code[20])
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate(Quantity, LibraryRandom.RandInt(10));
        RequisitionLine.Validate("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    procedure SelectRequisitionTemplateName(): Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.SetRange(Recurring, false);
        if not ReqWkshTemplate.FindFirst() then begin
            ReqWkshTemplate.Init();
            ReqWkshTemplate.Validate(Name, LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"));
            ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::"Req.");
            ReqWkshTemplate.Insert(true);
        end;

        exit(ReqWkshTemplate.Name);
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

    local procedure RejectRequisitionWkshName(RequisitionWkshNameName: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshNameName);
        RequisitionLine.FindFirst();
        ApprovalsMgmt.RejectRequisitionWkshLineRequest(RequisitionLine);
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

    local procedure CreateDirectApprovalEnabledWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.RequisitionWkshBatchApprovalWorkflowCode());
    end;

    local procedure CreateDirectApprovalWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.RequisitionWkshBatchApprovalWorkflowCode());
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