namespace Microsoft.Tests_Fixed_Asset;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.Foundation.NoSeries;
using System.Automation;
using System.Security.User;
using System.TestLibraries.Utilities;

codeunit 134080 "WFW FA Journal Batch"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "User Setup" = imd,
                  TableData "Workflow Webhook Entry" = imd,
                  TableData "Approval Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Fixed Asset Journal]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        BogusUserIdTxt: Label 'CONTOSO';
        DynamicRequestPageParametersFAJournalBatchTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="FA Journal Line">VERSION(1) SORTING(Field1,Field51,Field2)</DataItem></DataItems></ReportParameters>', Locked = true;
        RecordRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1 = Record ID, for example Customer 10000';
        NoApprovalCommentExistsErr: Label 'There is no approval comment for this approval entry.';
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        ApprovalCommentWasNotDeletedErr: Label 'The approval comment for this approval entry was not deleted.';
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

    [Test]
    procedure TestEnsureNecessaryTableRelationsAreSetup()
    var
        DummyFAJournalBatch: Record "FA Journal Batch";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowTableRelation: Record "Workflow - Table Relation";
    begin
        // [SCENARIO 440258] Verify that required workflow table relations for FA Journal Batch approval are established.
        Initialize();

        // [GIVEN] Remove all existing workflows to ensure a clean state.
        LibraryWorkflow.DeleteAllExistingWorkflows();

        // [WHEN] Initialize workflow setup.
        WorkflowSetup.InitWorkflow();

        // [THEN] Verify that table relation for FA Journal Batch approval workflow exists.
        WorkflowTableRelation.Get(
            Database::"FA Journal Batch", DummyFAJournalBatch.FieldNo(SystemId),
            Database::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
    end;

    [Test]
    procedure TestFAJournalBatchApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        ApproverUserSetup: Record "User Setup";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 440258] Verify Approver approves the request for the FA Journal Batch.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableFAJournalBatchWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] Create FA Journal Line.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);
        Commit();

        // [WHEN] Send an Approval Request for Fixed Asset Journal.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [THEN] Verify Open Approval Entry.
        VerifyWorkflowWebhookEntryResponse(FAJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Approve the Approval Entry via workflow webhook.
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(FAJournalBatch.SystemId));

        // [THEN] Verify Approval Entry is Approved.
        VerifyWorkflowWebhookEntryResponse(FAJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    procedure TestFAJournalBatchApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        ApproverUserSetup: Record "User Setup";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 440258] Verify that a webhook FA Journal Batch approval workflow rejection path works correctly.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableFAJournalBatchWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] Create an FA Journal Line.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [WHEN] Send an Approval Request for Fixed Asset Journal.
        Commit();
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [THEN] Verify workflow webhook entry response is pending.
        VerifyWorkflowWebhookEntryResponse(FAJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Webhook FA Journal Batch approval workflow receives a rejection response for the FA Journal Batch.
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(FAJournalBatch.SystemId));

        // [THEN] Verify that FA Journal Batch is rejected.
        VerifyWorkflowWebhookEntryResponse(FAJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    procedure TestFAJournalBatchApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        ApproverUserSetup: Record "User Setup";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 440258] Verify that a Webhook FA Journal Batch approval workflow cancellation path works correctly.
        Initialize();

        // [GIVEN] A webhook FA Journal Batch approval workflow for an FA Journal Batch is enabled.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableFAJournalBatchWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] Create an FA Journal Line.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [WHEN] Send an Approval Request for Fixed Asset Journal.
        Commit();
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [THEN] Verify workflow webhook entry response is pending.
        VerifyWorkflowWebhookEntryResponse(FAJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Webhook FA Journal Batch approval workflow receives a cancellation response for the FA Journal Batch.
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(FAJournalBatch.SystemId));

        // [THEN] Verify that the FA Journal Batch is cancelled.
        VerifyWorkflowWebhookEntryResponse(FAJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;


    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestDirectApproverApprovesRequestForFAJournalBatch()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
    begin
        // [SCENARIO 440258] Verify that Approver approves the request for the FA Journal Batch.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create an FA Journal Line.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Create an Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for FA Journal.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [THEN] Verify Open Approval Entry.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, FAJournalBatch.RecordId());
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Assign an Approval Entry.
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [WHEN] Approve an Approval Entry.
        ApproveFAJournalBatch(FAJournalBatch.Name);

        // [THEN] Verify Approval Entry is Approved.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, FAJournalBatch.RecordId());
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestDirectApproverRejectsRequestForFAJournalBatch()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
    begin
        // [SCENARIO 440258] Verify that Approver Rejects the request for the FA Journal Batch.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create an FA Journal Line.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Create an Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for FA Journal.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [THEN] Verify Open Approval Entry.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, FAJournalBatch.RecordId());
        VerifyOpenApprovalEntry(ApprovalEntry, ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Assign an Approval Entry.
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [WHEN] Reject an Approval Entry.
        RejectFAJournalBatch(FAJournalBatch.Name);

        // [THEN] Verify that Approval Entry is Rejected.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, FAJournalBatch.RecordId());
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('ApprovalEntriesPageHandler')]
    procedure TestShowApprovalEntriesPage()
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 440258] Verify that the related approval entries for the FA Journal Batch are displayed when an approval entry exists.
        Initialize();

        // [GIVEN] A Direct approval workflow is created and enabled for FA Journal Batches
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An FA Journal Batch with one Journal Line is created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] An open approval entry exists for the FA Journal Batch.
        CreateOpenApprovalEntryForCurrentUser(FAJournalBatch.RecordId);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] The batch record ID is enqueued for the approval entries page handler.
        LibraryVariableStorage.Enqueue(FAJournalBatch.RecordId);

        // [WHEN] The approval entries page is shown for the batch.
        ShowApprovalEntries(FAJournalBatch.Name);

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
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
    begin
        // [SCENARIO 440258] Verify that an approval request to a chain of approvers is self-approved if no valid approver is found for the FA Journal Batch.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow with Approver Chain.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateApprovalChainEnabledWorkflow(Workflow);

        // [GIVEN] Create a FA Journal Line.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for FA Journal.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name); // Assuming the function name remains the same

        // [THEN] Verify that approval request is self-approved due to absence of a valid approver chain.
        VerifySelfApprovalEntryAfterSendingForApproval(FAJournalBatch.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCannotSendApprovalRequestToFirstQualifiedApprover()
    var
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
    begin
        // [SCENARIO 440258] Verify that an approval request to the first qualified approver is self-approved if no qualified approver is found for the FA Journal Batch.
        Initialize();

        // [GIVEN] Create Direct Approval and Enable Workflow with First Qualified Approver.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateFirstQualifiedApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create a FA Journal Line.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Send an Approval Request for FA Journal.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [THEN] Verify that approval request is self-approved due to absence of a qualified approver.
        VerifySelfApprovalEntryAfterSendingForApproval(FAJournalBatch.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure TestDeleteLinesAfterApprovalRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        Workflow: Record Workflow;
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO 440258] Verify that deleting all FA Journal Lines after an approval request cancels the approval request and deletes approval entries.
        Initialize();

        // [GIVEN] A Direct approval workflow is created and enabled for FA Journal Batch.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An FA Journal Batch with one journal line is created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Requestor and approver user setups are configured for the approval process.
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, CopyStr(UserId, 1, 50));
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Approval request is sent for the FA Journal Batch.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [GIVEN] Approval entry for the batch is retrieved.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, FAJournalBatch.RecordId);

        // [WHEN] An approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [THEN] Verify that approval entry is open and approval comment exists.
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.RecordCount(ApprovalEntry, 1);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // [WHEN] All FA Journal Lines in the batch are deleted.
        FAJournalLine.SetRange("Journal Template Name", FAJournalBatch."Journal Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatch.Name);
        FAJournalLine.DeleteAll(true);

        // [THEN] Workflow Step Instances are removed and variable storage is empty.
        Assert.RecordIsEmpty(ApprovalEntry);
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);

        // [THEN] Verify that deleting all FA Journal Lines after an approval request cancels the approval request and deletes approval entries.
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TestHasPendingWorkflowWebhookEntryByRecordId()
    var
        FAJournalLine: Record "FA Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 440258] Verify that CanRequestApproval returns false when there is a pending Workflow Webhook Entry for an FA Journal Line.
        Initialize();

        // [GIVEN] An FA Journal Line is inserted.
        FAJournalLine.Insert();

        // [GIVEN] Create a Workflow Webhook Entry is created for the FA Journal Line with status Pending.
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry."Record ID" := FAJournalLine.RecordId();
        WorkflowWebhookEntry.Response := WorkflowWebhookEntry.Response::Pending;
        WorkflowWebhookEntry.Insert();

        // [WHEN] CanRequestApproval is checked for the FA Journal Line.
        Assert.IsFalse(WorkflowWebhookManagement.CanRequestApproval(FAJournalLine.RecordId()), CanRequestApprovalLbl);

        // [THEN] Verify that FindWorkflowWebhookEntryByRecordIdAndResponse returns true for the pending entry.
        Assert.IsTrue(
            WorkflowWebhookManagement.FindWorkflowWebhookEntryByRecordIdAndResponse(
                WorkflowWebhookEntry, FAJournalLine.RecordId(), WorkflowWebhookEntry.Response::Pending),
                FindWorkflowWebhookEntryByRecordIdAndResponseLbl);
    end;

    [Test]
    procedure TestFAJournalLineApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO 440258] Ensure that a webhook FA journal batch approval workflow approval path works correctly.
        Initialize();

        // [GIVEN] An FA Journal Batch approval workflow is created and enabled for the current user.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableFAJournalBatchWorkflowDefinition(RequestorUserSetup."User ID");

        // [GIVEN] An FA Journal Batch with one journal line is created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] An approval request is sent for the FA Journal Batch.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [THEN] Verify that the workflow webhook entry response is pending.
        VerifyWorkflowWebhookEntryResponse(FAJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] Approval entry is continued via workflow webhook.
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(FAJournalBatch.SystemId));

        // [THEN] Verify that the workflow webhook entry response is continue.
        VerifyWorkflowWebhookEntryResponse(FAJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure TestDeleteAfterApprovalRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        Workflow: Record Workflow;
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO 440258] Verify that deleting the record after an approval request is sent cancels the approval request and deletes the approval entries.
        Initialize();

        // [GIVEN] A direct approval workflow is created and enabled for FA Journal Batch.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An FA Journal Batch with one or more journal lines is created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Requestor and approver user setups are configured for the approval process.
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, CopyStr(UserId, 1, 208));
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Approval request is sent for the FA Journal Batch.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [GIVEN] Approval entry for the batch is retrieved.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, FAJournalBatch.RecordId);

        // [WHEN] An approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [THEN] Verify that the approval entry exists and is open and the approval comment exists.
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // [WHEN] FA Journal Batch is deleted.
        FAJournalBatch.Delete(true);

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
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 440258] Verify that renaming the record after an approval request is sent changes the approval request to point to the new record.
        Initialize();

        // [GIVEN] Direct approval workflow is created and enabled for FA Journal Batch.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An FA Journal Batch with one journal line is created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Requestor and approver user setups are configured for the approval process.
        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, CopyStr(UserId, 1, 50));
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Approval request is sent for the FA Journal Batch.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [GIVEN] Approval entry for the batch is retrieved.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, FAJournalBatch.RecordId);

        // [WHEN] Approval comment is added to the approval entry.
        AddApprovalComment(ApprovalEntry);

        // [THEN] Verify that approval entry is open and approval comment exists.
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // [WHEN] FA Journal Batch is renamed.
        FAJournalBatch.Rename(FAJournalBatch."Journal Template Name", LibraryRandom.RandText(10));

        // [THEN] Verify that approval entry still exists, is open, and approval comment still exists for the renamed batch.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, FAJournalBatch.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);
    end;

    [Test]
    [HandlerFunctions('ApprovalEntriesPageHandler')]
    procedure TestShowApprovalEntriesEmptyPage()
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 440258] Verify that the approval entries page displays no approval entries for the batch.
        Initialize();

        // [GIVEN] Direct approval workflow is created and enabled for FA Journal Batch.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An FA Journal Batch with one journal line is created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] The batch record ID is enqueued for the approval entries page.
        LibraryVariableStorage.Enqueue(FAJournalBatch.RecordId);

        // [WHEN] Approval entries page is shown for the batch.
        ShowApprovalEntries(FAJournalBatch.Name);

        // [THEN] Verify that the page handler verifies that no approval entries exist for the batch.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestCancelFAJournalBatchForApprovalNotAllowsUsage()
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO 440258] Verify that a newly created FA Journal Batch that has a canceled approval cannot be posted.
        Initialize();

        // [GIVEN] Approval user setup is configured.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        // [GIVEN] An enabled approval workflow for FA Journal Batch is created.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.FAJournalBatchApprovalWorkflowCode());

        // [GIVEN] An FA Journal Batch and line are created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] User sends an approval request from the FA Journal Batch.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [GIVEN] User cancels the approval.
        CancelApprovalRequestForFAJournal(FAJournalLine."Journal Batch Name");

        // [GIVEN] Find FA Journal Line.
        FAJournalLine.Reset();
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatch.Name);
        FAJournalLine.FindFirst();

        // [WHEN] Post FA Journal Line.
        asserterror LibraryFixedAsset.PostFAJournalLine(FAJournalLine);

        // [THEN] Verify that an error is raised indicating that the record is restricted.
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(FAJournalBatch.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestApproveFAJournalBatchForApprovalAllowsUsage()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        ApprovalUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
    begin
        // [SCENARIO 440258] Verify that a newly created FA Journal Batch that is approved can be posted.
        Initialize();

        // [GIVEN] Approval user setup is configured.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);

        // [GIVEN] Enabled approval workflow for FA Journal Batch is created.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.FAJournalBatchApprovalWorkflowCode());

        // [GIVEN] An FA Journal Batch and line are created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Send an approval request from the FA Journal Batch.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [GIVEN] Approval entry for the batch is retrieved and assigned to the requestor.
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, FAJournalBatch.RecordId);
        RequestorUserSetup.Get(UserId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // [WHEN] Approves the batch.
        ApproveFAJournalBatch(FAJournalBatch.Name);

        // [THEN] Verify that FA Journal Batch can be posted.
        FAJournalLine.Reset();
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatch.Name);
        FAJournalLine.FindFirst();
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    [Test]
    procedure TestRestrictFAJournalBatchExportingWithApprovalRemovedWhenWorkflowInstancesRemoved()
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO 440258] Verify that restrict exporting of an FA Journal Batch when approval is needed, but all restrictions are removed when workflow is disabled and step instances are deleted.
        Initialize();

        // [GIVEN] Direct approval workflow is created and enabled for FA Journal Batch.
        CreateDirectApprovalEnabledWorkflow(Workflow);
        Workflow.Enabled := true;
        Workflow.Modify();

        // [WHEN] An FA Journal Batch with one journal line is created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [THEN] Verify that restriction record exists for the FA Journal Batch.
        VerifyRestrictionRecordExists(FAJournalBatch.RecordId);

        // [GIVEN] Workflow step instance is created for the FA Journal Batch.
        CreateWorkflowStepInstance(Workflow.Code, FAJournalBatch.RecordId);

        // [WHEN] Workflow is disabled and Workflow Step Instances are deleted.
        Workflow.Enabled := false;
        Workflow.Modify();
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        WorkflowStepInstance.DeleteAll(true);

        // [THEN] Verify that no restriction record exists for the FA Journal Batch.
        VerifyNoRestrictionRecordExists(FAJournalBatch.RecordId);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('MessageHandler')]
    procedure TestBatchWorkflowIsVisibleOnFAJnlPage()
    var
        ApprovalUserSetup: Record "User Setup";
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        Workflow: Record Workflow;
        FixedAssetJournal: TestPage "Fixed Asset Journal";
    begin
        // [SCENARIO 440258] Verify that batch workflow status factbox becomes visible when the batch is sent for approval on FA Journal Page.
        Initialize();

        // [GIVEN] FA Journal Templates are deleted.
        FAJournalTemplate.DeleteAll();

        // [GIVEN] Approval users and direct approval workflow are set up.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An FA Journal Batch with one journal line is created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [WHEN] The FA Journal page is opened for the batch.
        FixedAssetJournal.OpenView();
        FixedAssetJournal.CurrentJnlBatchName.SetValue(FAJournalBatch.Name);

        // [THEN] Verify that batch workflow status factboxes are not visible before approval request.
        Assert.IsFalse(FixedAssetJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowStatusFactboxMustNotBeVisibleLbl);

        // [WHEN] Send Approval Request from FA Journal Page.
        FixedAssetJournal.SendApprovalRequestJournalBatch.Invoke();

        // [THEN] Verify that the batch workflow status factbox becomes visible.
        Assert.IsTrue(FixedAssetJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowStatusFactboxMustBeVisibleLbl);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('MessageHandler')]
    procedure TestBatchWorkflowIsNotVisibleOnFAJnlPageAfterCancelApproval()
    var
        ApprovalUserSetup: Record "User Setup";
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        Workflow: Record Workflow;
        FixedAssetJournal: TestPage "Fixed Asset Journal";
    begin
        // [SCENARIO 440258] Verify that batch workflow status factbox becomes not visible when the batch is cancelled for approval on FA Journal Page.
        Initialize();

        // [GIVEN] FA Journal Templates are deleted.
        FAJournalTemplate.DeleteAll();

        // [GIVEN] Approval users and direct approval workflow are set up.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] The Fixed Asset Journal page is opened and an approval request is sent.
        FixedAssetJournal.OpenView();
        FixedAssetJournal.CurrentJnlBatchName.SetValue(FAJournalBatch.Name);
        FixedAssetJournal.SendApprovalRequestJournalBatch.Invoke();

        // [WHEN] Cancel Approval Request from FA Journal Page.
        FixedAssetJournal.CancelApprovalRequestJournalBatch.Invoke();

        // [THEN] Verify that batch workflow status factboxes are not visible.
        Assert.IsFalse(FixedAssetJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), BatchWorkflowStatusFactboxMustNotBeVisibleLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestApproveFAJournalBatchForApprovalAdministrator()
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        ApprovalEntry: Record "Approval Entry";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 440258] Verify that FA Journal Batch is auto approved for Approval Administrator.
        Initialize();

        // [GIVEN] User is set up as Approval Administrator.
        SetupApprovalAdministrator();

        // [GIVEN] Enabled approval workflow for FA Journal Batch is created.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] FA Journal Batch is created with one journal line.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [WHEN] Approval request is sent for the FA Journal Batch.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [THEN] Verify that approval entry for the batch is approved automatically.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, FAJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    procedure TestModifyFAJournalLineIsNotAllowedForCreatedApprovalEntry()
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 440258] Verify that modifying an FA Journal Line is not allowed when an approval entry has status created.
        Initialize();

        // [GIVEN] A FA Journal Line is created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] An Approval Entry for the FA Journal Batch is created with status created.
        CreateApprovalEntryForCurrentUser(FAJournalBatch.RecordId, ApprovalStatus::Created);

        // [WHEN] Modify the FA Journal Line.
        asserterror FAJournalLine.Modify(true);

        // [THEN] Verify that the expected error message is shown.
        Assert.ExpectedError(PreventModifyRecordWithOpenApprovalEntryMsg);
    end;

    [Test]
    procedure TestDeleteFAJournalLineIsNotAllowedForCreatedApprovalEntry()
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 440258] Verify that deleting an FA Journal Line is not allowed when an approval entry has status created.
        Initialize();

        // [GIVEN] A FA Journal Line is created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] An Approval Entry for the FA Journal Batch is created with status created.
        CreateApprovalEntryForCurrentUser(FAJournalBatch.RecordId, ApprovalStatus::Created);

        // [WHEN] Delete the FA Journal Line.
        asserterror FAJournalLine.Delete(true);

        // [THEN] Verify that the expected error message is shown.
        Assert.ExpectedError(PreventDeleteRecordWithOpenApprovalEntryForCurrUserMsg);
    end;

    [Test]
    procedure TestShowImposedRestrictionBatchStatusIfUserModifyFAJournalLineForApprovedApprovalRequest()
    var
        Workflow: Record Workflow;
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        ApprovalUserSetup: Record "User Setup";
        FixedAssetJournal: TestPage "Fixed Asset Journal";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 440258] Verify that imposed restriction batch status is shown if user modifies FA Journal Line for approved approval request.
        Initialize();

        // [GIVEN] Delete all FA Journal Template.
        FAJournalTemplate.DeleteAll();

        // [GIVEN] Approval users and direct approval workflow are set up.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] An FA Journal Line is created.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] An Approval Entry for the FA Journal Batch is created with status Approved.
        CreateApprovalEntryForCurrentUser(FAJournalBatch.RecordId, ApprovalStatus::Approved);

        // [WHEN] FA Journal Line is modified.
        FAJournalLine.Validate(Amount, LibraryRandom.RandDec(100, 2));
        FAJournalLine.Modify(true);

        // [THEN] Verify that imposed restriction batch status is shown on the FA Journal page.
        FixedAssetJournal.OpenView();
        FixedAssetJournal.CurrentJnlBatchName.SetValue(FAJournalBatch.Name);
        Assert.AreEqual(ImposedRestrictionLbl, FixedAssetJournal.FAJnlBatchApprovalStatus.Value(), ImposedRestrictionMustBeShownLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestShowImposedRestrictionBatchStatusForWorkflowUserGroupIfFirstApprovalEntryIsApproved_FAJournal()
    var
        Workflow: Record Workflow;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        FAJournalLine: Record "FA Journal Line";
        FAJournalBatch: Record "FA Journal Batch";
        FixedAssetJournal: TestPage "Fixed Asset Journal";
    begin
        // [SCENARIO 440258] Verify that imposed restriction batch status is shown for Workflow User Group if first approval entry is auto approved.
        Initialize();

        // [GIVEN] Workflow template is copied.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.FAJournalBatchApprovalWorkflowCode());

        // [GIVEN] Three user setups and a workflow user group are created and set for the workflow.
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] FA Journal Batch is created with one journal line.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [WHEN] Approval request is sent for the FA Journal Batch.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [THEN] Verify that imposed restriction batch status is shown on the FA Journal page.
        FixedAssetJournal.OpenView();
        FixedAssetJournal.CurrentJnlBatchName.SetValue(FAJournalBatch.Name);
        Assert.AreEqual(ImposedRestrictionLbl, FixedAssetJournal.FAJnlBatchApprovalStatus.Value(), ImposedRestrictionMustBeShownLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestApprovalActionsVisibilityOnFAJournalBatch()
    var
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        FixedAssetJournal: TestPage "Fixed Asset Journal";
    begin
        // [SCENARIO 440258] Verify approval actions visibility on the FA Journal Batch.
        Initialize();

        // [GIVEN] Create an Approval Setup.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);

        // [GIVEN] Create an FA Journal Line.
        CreateFAJournalBatchWithOneJournalLine(FAJournalBatch, FAJournalLine);

        // [GIVEN] Create Direct Approval Workflow.
        CreateDirectApprovalWorkflow(Workflow);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open FA Journal.
        FixedAssetJournal.OpenEdit();
        FixedAssetJournal.CurrentJnlBatchName.SetValue(FAJournalBatch.Name);

        // [THEN] Verify Action must not be visible and enabled.
        Assert.IsFalse(FixedAssetJournal.SendApprovalRequestJournalBatch.Enabled(), SendApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsFalse(FixedAssetJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsFalse(FixedAssetJournal.Approve.Visible(), ApproveActionMustNotBeVisibleLbl);
        Assert.IsFalse(FixedAssetJournal.Reject.Visible(), RejectActionMustNotBeVisibleLbl);
        Assert.IsFalse(FixedAssetJournal.Delegate.Visible(), DelegateActionMustNotBeVisibleLbl);
        FixedAssetJournal.Close();

        // [GIVEN] Enable Workflow.
        EnableWorkflow(Workflow);

        // [GIVEN] Send an approval request to properly set up the workflow state.
        SendApprovalRequestForFAJournal(FAJournalBatch.Name);

        // [GIVEN] Create Open Approval Entry For Current User.
        CreateOpenApprovalEntryForCurrentUser(FAJournalBatch.RecordId());

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Open FA Journal.
        FixedAssetJournal.OpenEdit();
        FixedAssetJournal.CurrentJnlBatchName.SetValue(FAJournalBatch.Name);

        // [THEN] Verify Action must be visible and enabled.
        Assert.IsFalse(FixedAssetJournal.SendApprovalRequestJournalBatch.Enabled(), SendApprovalRequestJournalBatchActionMustBeDisabledLbl);
        Assert.IsTrue(FixedAssetJournal.CancelApprovalRequestJournalBatch.Enabled(), CancelApprovalRequestJournalBatchActionMustBeEnabledLbl);
        Assert.IsTrue(FixedAssetJournal.Approve.Visible(), ApproveActionMustBeVisibleLbl);
        Assert.IsTrue(FixedAssetJournal.Reject.Visible(), RejectActionMustBeVisibleLbl);
        Assert.IsTrue(FixedAssetJournal.Delegate.Visible(), DelegateActionMustBeVisibleLbl);
        FixedAssetJournal.Close();
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        FAJournalTemplate: Record "FA Journal Template";
        ClearWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        Workflow.ModifyAll(Enabled, false, true);
        UserSetup.DeleteAll();
        FAJournalTemplate.DeleteAll();
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

    local procedure ApproveFAJournalBatch(FAJournalBatchName: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatchName);
        FAJournalLine.FindFirst();
        ApprovalsMgmt.ApproveFAJournalRequest(FAJournalLine);
    end;

    local procedure CancelApprovalRequestForFAJournal(FAJournalBatchName: Code[20])
    var
        FAJournalLine: Record "FA Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatchName);
        if FAJournalLine.FindFirst() then
            ApprovalsMgmt.tryCancelJournalBatchApprovalRequest(FAJournalLine);
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

    local procedure SendApprovalRequestForFAJournal(FAJournalBatchName: Code[20])
    var
        FAJournalLine: Record "FA Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatchName);
        FAJournalLine.FindFirst();

        ApprovalsMgmt.TrySendJournalBatchApprovalRequest(FAJournalLine);
    end;

    local procedure CreateFirstQualifiedApprovalEnabledWorkflow(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        CreateCustomApproverTypeWorkflow(Workflow, WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", WorkflowSetup.FAJournalBatchApprovalWorkflowCode());
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
        CreateCustomApproverTypeWorkflow(Workflow, WorkflowStepArgument."Approver Limit Type"::"Approver Chain", WorkflowSetup.FAJournalBatchApprovalWorkflowCode());
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
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.FAJournalBatchApprovalWorkflowCode());
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

    local procedure ShowApprovalEntries(FAJournalBatchName: Code[20])
    var
        FAJournalLine: Record "FA Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatchName);
        FAJournalLine.FindFirst();
        ApprovalsMgmt.ShowJournalApprovalEntries(FAJournalLine);
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

    local procedure CreateAndEnableFAJournalBatchWorkflowDefinition(ResponseUserID: Code[50]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        WorkflowCode: Code[20];
    begin
        WorkflowCode :=
          WorkflowWebhookSetup.CreateWorkflowDefinition(WorkflowEventHandling.RunWorkflowOnSendFAJournalBatchForApprovalCode(),
            '', DynamicRequestPageParametersFAJournalBatchTxt, ResponseUserID);
        Workflow.Get(WorkflowCode);
        LibraryWorkflow.EnableWorkflow(Workflow);
        exit(WorkflowCode);
    end;

    local procedure CreateFAJournalBatchWithOneJournalLine(var FAJournalBatch: Record "FA Journal Batch"; var FAJournalLine: Record "FA Journal Line")
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        CreateFAJournalLine(
          FAJournalBatch, FAJournalLine, FixedAsset."No.", FADepreciationBook."Depreciation Book Code",
          FAJournalLine."Document Type", FAJournalLine."FA Posting Type");

    end;

    local procedure CreateJournalSetupDepreciation(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
    begin
        FAJournalSetup2.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook());
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroupCode: Code[20]; DepreciationBookCode: Code[10])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroupCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Depreciation Ending Date greater than Depreciation Starting Date, Using the Random Number for the Year.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAJournalLine(var FAJournalBatch: Record "FA Journal Batch"; var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; DocumentType: Enum "FA Journal Line Document Type"; FAPostingType: Enum "FA Journal Line FA Posting Type")
    begin
        CreateFAJournalBatch(FAJournalBatch);
        CreateFAJnlLine(FAJournalLine, FAJournalBatch, FANo, DepreciationBookCode, DocumentType, FAPostingType);
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        FAJournalBatch.Modify(true);
    end;

    local procedure CreateFAJnlLine(var FAJournalLine: Record "FA Journal Line"; FAJournalBatch: Record "FA Journal Batch"; FANo: Code[20]; DepreciationBookCode: Code[10]; DocumentType: Enum "FA Journal Line Document Type"; FAPostingType: Enum "FA Journal Line FA Posting Type")
    begin
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document Type", DocumentType);
        FAJournalLine.Validate("Document No.", GetDocumentNo(FAJournalBatch));
        FAJournalLine.Validate("Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, LibraryRandom.RandIntInRange(1000, 2000));
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure GetDocumentNo(FAJournalBatch: Record "FA Journal Batch"): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        NoSeries.Get(FAJournalBatch."No. Series");
        exit(NoSeriesCodeunit.PeekNextNo(FAJournalBatch."No. Series"));
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

    local procedure RejectFAJournalBatch(FAJournalBatchName: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatchName);
        FAJournalLine.FindFirst();
        ApprovalsMgmt.RejectFAJournalRequest(FAJournalLine);
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
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.FAJournalBatchApprovalWorkflowCode());
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