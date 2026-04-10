codeunit 134321 "General Journal Batch Approval"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = im;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [General Journal]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowSetup: Codeunit "Workflow Setup";
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';
        GenJournalBatchIsNotBalancedMsg: Label 'The selected general journal batch is not balanced and cannot be sent for approval.';
        NoApprovalCommentExistsErr: Label 'There is no approval comment for this approval entry.';
        ApprovalCommentWasNotDeletedErr: Label 'The approval comment for this approval entry was not deleted.';
        RecordRestrictedErr: Label 'You cannot use %1 for this action.', Comment = 'You cannot use Customer 10000 for this action.';
        PreventModifyRecordWithOpenApprovalEntryMsg: Label 'You can''t modify a record pending approval. Add a comment or reject the approval to modify the record.';
        ImposedRestrictionLbl: Label 'Imposed restriction';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CanPreviewPost()
    var
        GLEntry: Record "G/L Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Preview-post the batch with a pending approval request
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval entry for the journal batch
        // [WHEN] Click the Preview-Post action
        // [THEN] Message indicates all journal lines are post-ready

        Initialize();
        GLPostingPreview.OpenEdit();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        CreateOpenApprovalEntryForCurrentUser(GenJournalBatch.RecordId);

        // Exercise
        Commit();
        GLPostingPreview.Trap();
        asserterror PreviewPost(GenJournalBatch.Name);
        GLPostingPreview.Close();

        // Verify
        GLEntry.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.RecordIsEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotPost()
    var
        GLEntry: Record "G/L Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO] Fail to post the batch with a pending approval request
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval entry for the journal batch
        // [WHEN] Click the Post action
        // [THEN] Message warns user about a pending approval
        // Blocking mechanism is not implemented yet

        Initialize();

        // Setup
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        Commit();
        SendApprovalRequestBatch(GenJournalBatch.Name);

        // Exercise
        asserterror Post(GenJournalBatch.Name);

        // Verify.
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalBatch.RecordId, 0, 1)));

        // Verify
        GLEntry.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.RecordIsEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotPostAndPrint()
    var
        GLEntry: Record "G/L Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO] Fail to post the batch with a pending approval request
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Approval entry for the journal batch
        // [WHEN] Click the Post-and-Print action
        // [THEN] Message warns user about a pending approval
        // Blocking mechanism is not implemented yet

        Initialize();

        // Setup
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        Commit();
        SendApprovalRequestBatch(GenJournalBatch.Name);

        // Exercise
        asserterror PostAndPrint(GenJournalBatch.Name);

        // Verify.
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalBatch.RecordId, 0, 1)));

        // Verify
        GLEntry.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.RecordIsEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotSendApprovalRequestToChainOfApprovers()
    var
        ApprovalUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Fail to send an approval request to a chain of approvers
        // [GIVEN] Journal batch with one or more journal lines
        // [WHEN] Click the Send Approval Request action
        // [THEN] Approval request is self-approved.

        Initialize();

        // Setup
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateApprovalChainEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestBatch(GenJournalBatch.Name);

        // Verify
        VerifySelfApprovalEntryAfterSendingForApproval(GenJournalBatch.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotSendApprovalRequestToFirstQualifiedApprover()
    var
        ApprovalUserSetup: Record "User Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Fail to send an approval request to first qualified approver
        // [GIVEN] Journal batch with one or more journal lines
        // [WHEN] Click the Send Approval Request action
        // [THEN] Approval request is self-approved.

        Initialize();

        // Setup
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateFirstQualifiedApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestBatch(GenJournalBatch.Name);

        // Verify
        VerifySelfApprovalEntryAfterSendingForApproval(GenJournalBatch.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DeleteLinesAfterApprovalRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO] Deleting all the General journal lines after an approval request is sent cancels the approval request and deletes the approval entries.
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] The batch is sent for approval.
        // [WHEN] Delete the batch.
        // [THEN] The approval requests are canceled

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        Commit();
        SendApprovalRequestBatch(GenJournalBatch.Name);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.RecordCount(ApprovalEntry, 1);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll(true);

        // Verify
        Assert.RecordIsEmpty(ApprovalEntry);
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DeleteAfterApprovalRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO] Deleting the record after an approval request is sent cancels the approval request and deletes the approval entries.
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] The batch is sent for approval.
        // [WHEN] Delete the batch.
        // [THEN] The approval requests are canceled and then the approval entries are deleted.

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        Commit();
        SendApprovalRequestBatch(GenJournalBatch.Name);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise
        GenJournalBatch.Delete(true);

        // Verify
        Assert.IsTrue(ApprovalEntry.IsEmpty, UnexpectedNoOfApprovalEntriesErr);
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
        Assert.IsFalse(ApprovalCommentExists(ApprovalEntry), ApprovalCommentWasNotDeletedErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RenameAfterApprovalRequest()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO] Renaming the record after an approval request is sent changes the approval request to point to the new record.
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] The batch is sent for approval.
        // [WHEN] Rename the batch.
        // [THEN] The approval requests are changed to point to the new record.

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        LibraryDocumentApprovals.CreateOrFindUserSetup(RequestorUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);

        Commit();
        SendApprovalRequestBatch(GenJournalBatch.Name);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise
        GenJournalBatch.Rename(GenJournalBatch."Journal Template Name", 'TEST NAME');

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);
    end;

    [Test]
    [HandlerFunctions('BatchNotBalancedMessageHandler')]
    [Scope('OnPrem')]
    procedure CannotSendApprovalRequestBatchWithUnbalancedLines()
    var
        Workflow: Record Workflow;
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO] Fail to send an approval request when the batch is not balanced.
        // [GIVEN] Journal batch which is not balanced.
        // [WHEN] Click the Send Approval Request action.
        // [THEN] Message pops up that the batch is not balanced.

        Initialize();
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // Setup
        CreateGeneralJournalBatchWithOneNotBalancedJournalLine(GenJournalBatch);

        // Exercise
        Commit();
        SendApprovalRequestBatch(GenJournalBatch.Name);

        // Verify
        // MessageHandler verifies the message
    end;

    [Test]
    [HandlerFunctions('ApprovalEntriesEmptyPageHandler')]
    [Scope('OnPrem')]
    procedure ShowApprovalEntriesEmptyPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Display the approval entries page listing no approval entries
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] No approval entries exist for the journal batch
        // [GIVEN] Approval entries exist for one or more journal lines
        // [WHEN] Click the Approvals action
        // [WHEN] Select batch on the STRMENU dialog
        // [THEN] Empty page pops up

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalBatch.RecordId);
        ShowApprovalEntries(GenJournalBatch.Name);

        // Verify
        // PageHandler verifies record
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ApprovalEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ShowApprovalEntriesPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Display the related approval entries
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] An approval entry exists for the journal batch
        // [GIVEN] Approval entries exist for one or more journal lines
        // [WHEN] Click the Approvals action
        // [WHEN] Select batch on the STRMENU dialog
        // [THEN] Page displays the journal batch approval entries

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        CreateOpenApprovalEntryForCurrentUser(GenJournalBatch.RecordId);

        // Exercise
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalBatch.RecordId);
        ShowApprovalEntries(GenJournalBatch.Name);

        // Verify
        // PageHandler verifies record
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelGenJnlBatchForApprovalNotAllowsUsage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
    begin
        // [SCENARIO] A newly created gen. jnl. batch that has a canceled approval can not be posted.
        // [GIVEN] A new general journal batch and line.
        // [WHEN] The user sends an approval request from the journal batch.
        // [WHEN] The user cancels the approval.
        // [WHEN] Post general journal batch.
        // [THEN] Message warns user about approvals needed.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        Commit();
        SendApprovalRequestBatch(GenJournalBatch.Name);
        CancelApprovalRequestBatch(GenJournalLine."Journal Batch Name");

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalBatch.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApproveGenJnlBatchForApprovalAllowsUsage()
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        RequestorUserSetup: Record "User Setup";
    begin
        // [SCENARIO] A newly created gen. jnl. batch that is approved can be posted.
        // [GIVEN] A new general journal batch and line.
        // [WHEN] The user sends an approval request from the journal batch.
        // [WHEN] The user approves the batch.
        // [THEN] The general journal batch can be posted.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        Commit();
        SendApprovalRequestBatch(GenJournalBatch.Name);

        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        RequestorUserSetup.Get(UserId);
        AssignApprovalEntry(ApprovalEntry, RequestorUserSetup);

        // Exercise.
        Approve(GenJournalBatch.Name);

        // Verify.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestrictGenJournalBatchExportingWithApprovalEnabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] Restrict exporting of a journal batch when approval is needed
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Journal batch approval workflow is enabled
        // [GIVEN] Allow Payment Export is enabled
        // [WHEN] Raising the check event when exporting.
        // [THEN] An error is raised.

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        VerifyRestrictionRecordExists(GenJournalLine.RecordId);

        // Exercise
        GenJournalBatch."Allow Payment Export" := true;
        GenJournalBatch.Modify();
        Commit();
        asserterror GenJournalBatch.OnCheckGenJournalLineExportRestrictions();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalLine.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestrictGenJournalBatchExportingWithApprovalRemovedWhenWorkflowInstancesRemoved()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO] Restrict exporting of a journal batch when approval is needed
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Journal batch approval workflow is enabled
        // [WHEN] Workflow  is disabled and Workflow Step Instances are deleted
        // [THEN] All restrictions are removed

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        Workflow.Enabled := true;
        Workflow.Modify();

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        VerifyRestrictionRecordExists(GenJournalLine.RecordId);

        CreateWorkflowStepInstance(Workflow.Code, GenJournalLine.RecordId);

        // Exercise
        Workflow.Enabled := false;
        Workflow.Modify();
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        WorkflowStepInstance.DeleteAll(true);

        // Verify
        VerifyNoRestrictionRecordExists(GenJournalLine.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestrictGenJournalBatchExportingWithApprovalNotRemovedWhenWorkflowIsEnabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO] Restrict exporting of a journal batch when approval is needed
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Journal batch approval workflow is enabled
        // [GIVEN] Another work flow instance with the same record exists
        // [WHEN] The Workflow Step Instance are deleted but the Workflow is enabled
        // [THEN] Record restrictions are not removed

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);
        Workflow.Enabled := true;
        Workflow.Modify();

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        VerifyRestrictionRecordExists(GenJournalLine.RecordId);

        CreateWorkflowStepInstance(Workflow.Code, GenJournalLine.RecordId);

        // Exercise
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        WorkflowStepInstance.DeleteAll(true);

        // Verify
        VerifyRestrictionRecordExists(GenJournalLine.RecordId);
    end;

    local procedure CreateWorkflowStepInstance(WorkflowCode: Code[20]; Relatedrecord: RecordId)
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        WorkflowStepInstance.Id := CreateGuid();
        WorkflowStepInstance."Record ID" := Relatedrecord;
        WorkflowStepInstance."Workflow Code" := WorkflowCode;
        WorkflowStepInstance.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoGenJournalBatchRestrictionWithApprovalEnabledWithExportDisabled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
    begin
        // [SCENARIO] No restriction for a batch that doesn't support export
        // [GIVEN] Journal batch with one or more journal lines
        // [GIVEN] Journal batch approval workflow is enabled
        // [WHEN] Allow Payment Export is not allowed
        // [THEN] Restriction is not checked when raising the check event.

        Initialize();

        // Setup
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        VerifyRestrictionRecordExists(GenJournalLine.RecordId);

        // Exercise
        GenJournalBatch."Allow Payment Export" := false;
        GenJournalBatch.Modify();
        GenJournalBatch.OnCheckGenJournalLineExportRestrictions();

        // Verify: No error.
        Assert.AreEqual('', GetLastErrorText, 'No error expected.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchWorkflowIsVisibleOnGenJnlPage()
    var
        ApprovalUserSetup: Record "User Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Batch workflow status factbox becomes visible when the batch is sent for approval on General Journal Page
        Initialize();
        GenJournalTemplate.DeleteAll();

        // [GIVEN] Journal batch with one or more journal lines
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.IsFalse(GeneralJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), 'Batch workflow Status factbox is not hidden');
        Assert.IsFalse(GeneralJournal.WorkflowStatusLine.WorkflowDescription.Visible(), 'Line workflow Status factbox is not hidden');

        // [WHEN] Click the Send Approval Request action
        GeneralJournal.SendApprovalRequestJournalBatch.Invoke();

        // [THEN] Batch workflow status factbox becomes visible.
        Assert.IsTrue(GeneralJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), 'Batch workflow Status factbox is hidden');
        Assert.IsFalse(GeneralJournal.WorkflowStatusLine.WorkflowDescription.Visible(), 'Line workflow Status factbox is not hidden');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BatchWorkflowIsNotVisibleOnGenJnlPageAfterCancelApproval()
    var
        ApprovalUserSetup: Record "User Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 209814] Batch workflow status factbox becomes not visible when the batch is cancel for approval on General Journal Page

        Initialize();
        GenJournalTemplate.DeleteAll();

        // [GIVEN] Journal batch with one or more journal lines
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Approval request sent
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal.SendApprovalRequestJournalBatch.Invoke();

        // [WHEN] Click the Cancel Approval Request action
        GeneralJournal.CancelApprovalRequestJournalBatch.Invoke();

        // [THEN] Batch workflow status factbox becomes not visible.
        Assert.IsFalse(GeneralJournal.WorkflowStatusBatch.WorkflowDescription.Visible(), 'Batch workflow Status factbox is not hidden');
        Assert.IsFalse(GeneralJournal.WorkflowStatusLine.WorkflowDescription.Visible(), 'Line workflow Status factbox is not hidden');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveGenJnlBatchForApprovalAdministrator()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalEntry: Record "Approval Entry";
        Workflow: Record Workflow;
    begin
        // [SCENARIO 379666] General Journal Batch is auto approved for Approval Administrator

        Initialize();

        // [GIVEN] Setup user with empty "Approver ID" and "Approval Admin" is TRUE.
        SetupApprovalAdministrator();

        // [GIVEN] Create new enabled approval Workflow for Gen. Journal Batch.
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Non-empty Gen. Journal Batch "B"
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [WHEN] Approval request has been sent for Gen. Journal Batch "B".
        SendApprovalRequestBatch(GenJournalBatch.Name);

        // [THEN] Approval entry for "B" is approved automatically.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, GenJournalBatch.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalRequestSentToFirstQualifiedApproverSalesPersonGenJnlLine()
    var
        ApprovalUserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Workflow: Record Workflow;
    begin
        // [FEATURE] [Journal]
        // [SCENARIO 225990] Approval request is sent to only single First Qualified Approver from journal in case of Sales/Purchaser Person setup
        Initialize();

        // [GIVEN] Approval setup with users "A" and "B" where "B" is the First Qualified Approver for "A", and "B"."Sales/Purchaser Code" = "X"
        // [GIVEN] Approval workflow wher "Approver Type" = "Salesperson/Purchaser"
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateSalesPersonFirstQualifiedApprovalEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());

        // [GIVEN] "A" created general journal line with "Salespers./Purch. Code" = "X"
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        GenJournalLine.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        GenJournalLine.Modify(true);

        ApprovalUserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        ApprovalUserSetup.Modify(true);

        // [WHEN] "A" send approval request
        SendApprovalRequestLine(GenJournalBatch.Name);

        // [THEN] The only single approval request created and sent to "B" with the state = "Open"
        VerifyOpenFirstQualifiedApprovalEntry(GenJournalLine.RecordId, UserId, ApprovalUserSetup."User ID");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApprovalRequestSentToFirstQualifiedApproverSalesPersonSalesOrder()
    var
        ApprovalUserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Workflow: Record Workflow;
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 225990] Approval request is sent to only single First Qualified Approver from sales order in case of Sales/Purchaser Person setup
        Initialize();

        // [GIVEN] Approval setup with users "A" and "B" where "B" is the First Qualified Approver for "A", and "B"."Sales/Purchaser Code" = "X"
        // [GIVEN] Approval workflow wher "Approver Type" = "Salesperson/Purchaser"
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateSalesPersonFirstQualifiedApprovalEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // [GIVEN] "A" created sales order with customer having "Salesperson Code" = "X"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);

        ApprovalUserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        ApprovalUserSetup.Modify(true);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", '', 0, '', 0D);

        // [WHEN] "A" send approval request
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SendApprovalRequest.Invoke();

        // [THEN] The only single approval request created and sent to "B" with the state = "Open"
        VerifyOpenFirstQualifiedApprovalEntry(SalesHeader.RecordId, UserId, ApprovalUserSetup."User ID");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApprovalRequestSentToFirstQualifiedApproverSalesPersonPurchaseOrder()
    var
        ApprovalUserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Workflow: Record Workflow;
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 225990] Approval request is sent to only single First Qualified Approver from purchase order in case of Sales/Purchaser Person setup
        Initialize();

        // [GIVEN] Approval setup with users "A" and "B" where "B" is the First Qualified Approver for "A", and "B"."Sales/Purchaser Code" = "X"
        // [GIVEN] Approval workflow wher "Approver Type" = "Salesperson/Purchaser"
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateSalesPersonFirstQualifiedApprovalEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // [GIVEN] "A" created purchase order with vendor having "Purchaser Code" = "X"
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Vendor.Validate("Purchaser Code", SalespersonPurchaser.Code);
        Vendor.Modify(true);

        ApprovalUserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        ApprovalUserSetup.Modify(true);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Vendor."No.", '', 0, '', 0D);

        // [WHEN] "A" send approval request
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.SendApprovalRequest.Invoke();

        // [THEN] The only single approval request created and sent to "B" with the state = "Open"
        VerifyOpenFirstQualifiedApprovalEntry(PurchaseHeader.RecordId, UserId, ApprovalUserSetup."User ID");
    end;

    [Test]
    procedure VerifyModifyGenJournalLineIsNotAllowedForCreatedApprovalEntry()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 492705] Verify that modifying a Gen. Journal Line is not allowed when an approval entry has status created
        Initialize();

        // [GIVEN] Create Gen. Journal Line
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Document Type"::" ", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Create Approval Entry for Gen. Journal Batch
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        CreateApprovalEntryForCurrentUser(GenJournalBatch.RecordId, ApprovalStatus::Created);

        // [WHEN] Try to modify a Gen. Journal Line
        asserterror GenJournalLine.Modify(true);

        // [THEN] Verify error message
        Assert.ExpectedError(PreventModifyRecordWithOpenApprovalEntryMsg);
    end;

    [Test]
    procedure ShowImposedRestrictionBatchStatusIfUserModifyGenJournalLineForApprovedApprovalRequest()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        GeneralJournal: TestPage "General Journal";
        ApprovalStatus: Enum "Approval Status";
    begin
        // [SCENARIO 498314] Show imposed restriction batch status if user modifies Gen. Journal Line for approved approval request 
        Initialize();

        GenJournalTemplate.DeleteAll();

        // [GIVEN] Enable Gen. Journal Batch Approval Workflow
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateDirectApprovalEnabledWorkflow(Workflow);

        // [GIVEN] Create Gen. Journal Line
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Document Type"::" ", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Create Approval Entry for Gen. Journal Batch with a status Approved
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        CreateApprovalEntryForCurrentUser(GenJournalBatch.RecordId, ApprovalStatus::Approved);

        // [WHEN] Modify a Gen. Journal Line
        GenJournalLine.Validate(Amount, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Modify(true);

        // [THEN] Verify result
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.AreEqual(ImposedRestrictionLbl, GeneralJournal.GenJnlBatchApprovalStatus.Value(), 'Imposed restriction is not shown');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ShowImposedRestrictionBatchStatusForWorkflowUserGroupIfFirstApprovalEntryIsApproved()
    var
        Workflow: Record Workflow;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 526988] Show Imposed restriction batch status for Workflow User Group if first approval entry is auto approved
        Initialize();

        // [GIVEN] Copy Workflow Template
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());

        // [GIVEN] Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Non-empty Gen. Journal Batch
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [WHEN] Approval request has been sent for Gen. Journal Batch
        SendApprovalRequestBatch(GenJournalBatch.Name);

        // [THEN] Verify result
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        Assert.AreEqual(ImposedRestrictionLbl, GeneralJournal.GenJnlBatchApprovalStatus.Value(), 'Imposed restriction is not shown');
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"General Journal Batch Approval");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();

        Workflow.ModifyAll(Enabled, false, true);
        UserSetup.DeleteAll();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"General Journal Batch Approval");

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"General Journal Batch Approval");
    end;

    local procedure CreateDirectApprovalEnabledWorkflow(var Workflow: Record Workflow)
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());
    end;

    local procedure CreateApprovalChainEnabledWorkflow(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        CreateCustomApproverTypeWorkflow(
          Workflow, WorkflowStepArgument."Approver Limit Type"::"Approver Chain", WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());
        EnableWorkflow(Workflow);
    end;

    local procedure CreateFirstQualifiedApprovalEnabledWorkflow(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        CreateCustomApproverTypeWorkflow(
          Workflow, WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver",
          WorkflowSetup.GeneralJournalBatchApprovalWorkflowCode());
        EnableWorkflow(Workflow);
    end;

    local procedure CreateSalesPersonFirstQualifiedApprovalEnabledWorkflow(var Workflow: Record Workflow; WorkflowCode: Code[17])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        CreateCustomApproverTypeWorkflow(
          Workflow, WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", WorkflowCode);

        FindWorkflowStepArgument(Workflow, WorkflowStepArgument);

        WorkflowStepArgument.Validate("Approver Type", WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser");
        WorkflowStepArgument.Modify(true);

        EnableWorkflow(Workflow);
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

    local procedure EnableWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure CreateJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; JournalTemplateName: Code[10])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, JournalTemplateName);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateGeneralJournalBatchWithOneNotBalancedJournalLine(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());

        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine,
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", '', GenJournalLine."Bal. Account Type"::"G/L Account", '',
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePaymentJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
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
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Sequence No." := 1;
        ApprovalEntry.Insert();
    end;

    local procedure CreateApprovalEntryForCurrentUser(RecordID: RecordID; ApprovalStatus: Enum "Approval Status")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Document Type" := ApprovalEntry."Document Type"::" ";
        ApprovalEntry."Document No." := '';
        ApprovalEntry."Table ID" := RecordID.TableNo;
        ApprovalEntry."Record ID to Approve" := RecordID;
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry.Status := ApprovalStatus;
        ApprovalEntry."Sequence No." := 1;
        ApprovalEntry.Insert();
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

    local procedure PreviewPost(GenJournalBatchName: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.FindFirst();
        GenJnlPost.Preview(GenJournalLine);
    end;

    local procedure Post(GenJournalBatchName: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostAndPrint(GenJournalBatchName: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post+Print", GenJournalLine);
    end;

    local procedure SendApprovalRequestBatch(GenJournalBatchName: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.FindFirst();
        ApprovalsMgmt.TrySendJournalBatchApprovalRequest(GenJournalLine);
    end;

    local procedure CancelApprovalRequestBatch(GenJournalBatchName: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.FindFirst();
        ApprovalsMgmt.TryCancelJournalBatchApprovalRequest(GenJournalLine);
    end;

    local procedure SendApprovalRequestLine(GenJournalBatchName: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.FindFirst();
        ApprovalsMgmt.TrySendJournalLineApprovalRequests(GenJournalLine);
    end;

    local procedure ShowApprovalEntries(GenJournalBatchName: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.FindFirst();
        ApprovalsMgmt.ShowJournalApprovalEntries(GenJournalLine);
    end;

    local procedure AssignApprovalEntry(var ApprovalEntry: Record "Approval Entry"; UserSetup: Record "User Setup")
    begin
        ApprovalEntry."Approver ID" := UserSetup."User ID";
        ApprovalEntry.Modify();
    end;

    local procedure Approve(GenJournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.FindFirst();
        ApprovalsMgmt.ApproveGenJournalLineRequest(GenJournalLine);
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
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, UserId);
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

    local procedure VerifyOpenFirstQualifiedApprovalEntry(RecordID: RecordID; SenderID: Code[50]; ApproverID: Code[50])
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, RecordID);
        Assert.RecordCount(ApprovalEntry, 1);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, SenderID);
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverID);
    end;

    local procedure SetupApprovalAdministrator()
    var
        UserSetup: Record "User Setup";
    begin
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId, '');
        UserSetup."Approval Administrator" := true;
        UserSetup.Modify();
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ApprovalEntriesEmptyPageHandler(var ApprovalEntries: TestPage "Approval Entries")
    var
        Variant: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        Assert.IsFalse(ApprovalEntries.First(), 'The page is not empty');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ApprovalEntriesPageHandler(var ApprovalEntries: TestPage "Approval Entries")
    var
        RecordID: RecordID;
        Variant: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        RecordID := Variant;

        Assert.IsTrue(ApprovalEntries.First(), 'The page is empty');
        ApprovalEntries.RecordIDText.AssertEquals(Format(RecordID, 0, 1));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure BatchNotBalancedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(GenJournalBatchIsNotBalancedMsg, Message);
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
        exit(ApprovalCommentLine.FindFirst())
    end;
}

