codeunit 134220 "WFWH General Journal Line"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "User Setup" = imd,
                  TableData "Workflow Webhook Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [General Journal]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryJournals: Codeunit "Library - Journals";
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        IsInitialized: Boolean;
        BogusUserIdTxt: Label 'CONTOSO';
        DynamicRequestPageParametersGeneralJournalLineTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Gen. Journal Line">VERSION(1) SORTING(Field1,Field51,Field2)</DataItem></DataItems></ReportParameters>', Locked = true;
        UserCannotCancelErr: Label 'User %1 does not have the permission necessary to cancel the item.', Comment = '%1 = NAV USERID';
        UserCannotActErr: Label 'User %1 cannot act on this step. Make sure the user who created the webhook (%2) is the same who is trying to act.', Comment = '%1, %2 = two distinct NAV user IDs, for example "MEGANB" and "WILLIAMC"';
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.', Locked = true;
        PreventDeleteRecordWithOpenApprovalEntryForSenderMsg: Label 'You can''t delete a record that has open approval entries. To delete a record, you need to Cancel approval request first.';

    [Test]
    [Scope('OnPrem')]
    procedure HasPendingWorkflowWebhookEntryByRecordId()
    var
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 418743] CanRequestApproval is refactored to show if there are no pending entries.
        // [GIVEN] Gen. Jnl line 'GJL' has a pending WorkflowWebhookEntry
        GenJournalLine.Insert();
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry."Record ID" := GenJournalLine.RecordId();
        WorkflowWebhookEntry.Response := WorkflowWebhookEntry.Response::Pending;
        WorkflowWebhookEntry.Insert();

        // [THEN] CanRequestApproval() is reverted FindWorkflowWebhookEntryByRecordIdAndResponse() for 'Pending'
        Assert.IsFalse(WorkflowWebhookManagement.CanRequestApproval(GenJournalLine.RecordId()), 'CanRequestApproval');
        Assert.IsTrue(
        WorkflowWebhookManagement.FindWorkflowWebhookEntryByRecordIdAndResponse(
            WorkflowWebhookEntry, GenJournalLine.RecordId(), WorkflowWebhookEntry.Response::Pending),
            'FindWorkflowWebhookEntryByRecordIdAndResponse');
    end;

    [Normal]
    local procedure ChangeWorkflowWebhookEntryInitiatedBy(Id: Guid; InitiatedByUserID: Code[50])
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry.SetCurrentKey("Data ID");
        WorkflowWebhookEntry.SetRange("Data ID", Id);
        WorkflowWebhookEntry.FindFirst();

        WorkflowWebhookEntry."Initiated By User ID" := InitiatedByUserID;
        WorkflowWebhookEntry.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeCurrentUserAnApprover()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(BogusUserIdTxt) then begin
            UserSetup.Init();
            UserSetup."User ID" := BogusUserIdTxt;
            UserSetup."Approver ID" := UserId;
            UserSetup.Insert(true);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveBogusUser()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(BogusUserIdTxt) then
            UserSetup.Delete(true);
    end;

    local procedure GetPendingWorkflowStepInstanceIdFromDataId(Id: Guid): Guid
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry.SetFilter("Data ID", Id);
        WorkflowWebhookEntry.SetFilter(Response, '=%1', WorkflowWebhookEntry.Response::Pending);
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

    local procedure CreateAndEnableGeneralJournalLineWorkflowDefinition(ResponseUserID: Code[50]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        WorkflowCode: Code[20];
    begin
        WorkflowCode :=
          WorkflowWebhookSetup.CreateWorkflowDefinition(WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode(),
            '', DynamicRequestPageParametersGeneralJournalLineTxt, ResponseUserID);
        Workflow.Get(WorkflowCode);
        LibraryWorkflow.EnableWorkflow(Workflow);
        exit(WorkflowCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNecessaryTableRelationsAreSetup()
    var
        DummyGenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowTableRelation: Record "Workflow - Table Relation";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] Ensure that the necessary webhook general journal line approval workflow table relations are setup.
        // [WHEN] Workflow setup is initialized.
        // [THEN] Workflow table relations for general journal line and workflow webhook entry exist.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();

        // Excercise
        WorkflowSetup.InitWorkflow();

        // Verify
        WorkflowTableRelation.Get(
          DATABASE::"Gen. Journal Line", DummyGenJournalLine.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Ensure2IndependantGeneralJournalLinesCanBeSentForApproval()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        // [SCENARIO] Send 2 lines for approval indepently
        // [GIVEN] A webhook general journal line approval workflow for a general journal line is enabled.
        // [GIVEN] Journal batch with Two line
        // [WHEN] Journal Line 1 sent for approval
        // [WHEN] Journal Line 2 sent for approval
        // [THEN] Two lines are sent for approval

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateJournalBatchWithMultipleJournalLines(GenJournalLine);
        Commit();

        // Exercise
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        GenJournalLine.Next(-1);
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalLineApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general line approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook general journal line approval workflow for a general journal line is enabled.
        // [GIVEN] Journal batch with one line
        // [GIVEN] A general journal line is pending approval.
        // [WHEN] The webhook general journal line workflow receives an 'approval' response for the general journal line.
        // [THEN] The general journal line is approved.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalLineApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general line approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook general journal line approval workflow for a general journal line is enabled.
        // [GIVEN] Journal batch with one line
        // [GIVEN] A general journal line is pending approval.
        // [WHEN] The webhook general journal line workflow receives a 'rejected' response for the general journal line.
        // [THEN] The general journal line is rejected.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalLineApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general journal line approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook general journal line approval workflow for a general journal line is enabled.
        // [GIVEN] Journal batch with one line
        // [GIVEN] A general journal line is pending approval.
        // [WHEN] The webhook general journal line workflow receives a 'cancellation' response for the general journal line.
        // [THEN] The general journal line is cancelled.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsurerCashReceiptJournaLineApprovalWorkflowFunctionsCorrectlylWhenContinued()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook cash receipt journal line approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook general journal line approval workflow for a cash receipt journal line is enabled.
        // [GIVEN] Cash receipt Journal batch with one line
        // [GIVEN] A cash receipt journal line is pending approval.
        // [WHEN] The webhook cash receipt journal line workflow receives an 'approval' response for the cash receipt journal line.
        // [THEN] The cash receipt journal line is approved.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForCashReceipt(GenJournalBatch.Name);
        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsurerCashReceiptJournaLineApprovalWorkflowFunctionsCorrectlylWhenRejected()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook  journal line approval workflow 'rejection' path works correctly for cash receipt.
        // [GIVEN] A webhook general journal line approval workflow for a cash receipt journal line is enabled.
        // [GIVEN] Cash receipt journal batch with one line
        // [GIVEN] A cash receipt journal line is pending approval.
        // [WHEN] The webhook cash receipt journal line workflow receives a 'rejection' response for the cash receipt journal line.
        // [THEN] The cash receipt journal line is rejected.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForCashReceipt(GenJournalBatch.Name);
        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsurerCashReceiptJournaLineApprovalWorkflowFunctionsCorrectlylWhenCancelled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook  journal line approval workflow 'cancellation' path works correctly for cash receipt.
        // [GIVEN] A webhook general journal line approval workflow for a cash receipt journal line is enabled.
        // [GIVEN] Cash receipt journal batch with one line
        // [GIVEN] A cash receipt journal line is pending approval.
        // [WHEN] The webhook cash receipt journal line workflow receives a 'cancellation' response for the cash receipt journal line.
        // [THEN] The cash receipt journal line is cancelled.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForCashReceipt(GenJournalBatch.Name);
        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsurePaymentJournalLineApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook  journal line approval workflow 'approval' path works correctly for payment journal.
        // [GIVEN] A webhook general journal line approval workflow for a payment journal line is enabled.
        // [GIVEN] Payment journal batch with one line
        // [GIVEN] A payment journal line is pending approval.
        // [WHEN] The webhook payment journal line workflow receives an 'approval' response for the payment journal line.
        // [THEN] The payment journal line is approved.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForPaymentJournal(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsurePaymentJournalLineApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook  journal line approval workflow 'rejection' path works correctly for payment journal.
        // [GIVEN] A webhook general journal line approval workflow for a payment journal line is enabled.
        // [GIVEN] Payment journal batch with one line
        // [GIVEN] A payment journal line is pending approval.
        // [WHEN] The webhook payment journal line workflow receives a 'rejection' response for the payment journal line.
        // [THEN] The payment journal line is rejected.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForPaymentJournal(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsurePaymentJournalLineApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook  journal line approval workflow 'cancellation' path works correctly for payment journal.
        // [GIVEN] A webhook general journal line approval workflow for a payment journal line is enabled.
        // [GIVEN] Payment journal batch with one line
        // [GIVEN] A payment journal line is pending approval.
        // [WHEN] The webhook payment journal line workflow receives a 'cancellation' response for the payment journal line.
        // [THEN] The payment journal line is cancelled.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForPaymentJournal(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    procedure EnsurePurchaseJournalLineApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook  journal line approval workflow 'approval' path works correctly for purchase journal.
        // [GIVEN] A webhook general journal line approval workflow for a purchase journal line is enabled.
        // [GIVEN] Purchase journal batch with one line
        // [GIVEN] A purchase journal line is pending approval.
        // [WHEN] The webhook purchase journal line workflow receives an 'approval' response for the purchase journal line.
        // [THEN] The purchase journal line is approved.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForPurchaseJournal(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    procedure EnsurePurchaseJournalLineApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook  journal line approval workflow 'rejection' path works correctly for purchase journal.
        // [GIVEN] A webhook general journal line approval workflow for a purchase journal line is enabled.
        // [GIVEN] Purchase journal batch with one line
        // [GIVEN] A purchase journal line is pending approval.
        // [WHEN] The webhook purchase journal line workflow receives a 'rejection' response for the purchase journal line.
        // [THEN] The purchase journal line is rejected.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForPurchaseJournal(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    procedure EnsurePurchaseJournalLineApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook  journal line approval workflow 'cancellation' path works correctly for purchase journal.
        // [GIVEN] A webhook general journal line approval workflow for a purchase journal line is enabled.
        // [GIVEN] Purchase journal batch with one line
        // [GIVEN] A purchase journal line is pending approval.
        // [WHEN] The webhook purchase journal line workflow receives a 'cancellation' response for the purchase journal line.
        // [THEN] The purchase journal line is cancelled.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForPurchaseJournal(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    procedure EnsureSalesJournalLineApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook  journal line approval workflow 'approval' path works correctly for sales journal.
        // [GIVEN] A webhook general journal line approval workflow for a sales journal line is enabled.
        // [GIVEN] Sales journal batch with one line
        // [GIVEN] A sales journal line is pending approval.
        // [WHEN] The webhook sales journal line workflow receives an 'approval' response for the sales journal line.
        // [THEN] The sales journal line is approved.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForSalesJournal(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    procedure EnsureSalesJournalLineApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook  journal line approval workflow 'rejection' path works correctly for sales journal.
        // [GIVEN] A webhook general journal line approval workflow for a sales journal line is enabled.
        // [GIVEN] Sales journal batch with one line
        // [GIVEN] A sales journal line is pending approval.
        // [WHEN] The webhook sales journal line workflow receives a 'rejection' response for the sales journal line.
        // [THEN] The sales journal line is rejected.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForSalesJournal(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    procedure EnsureSalesJournalLineApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook  journal line approval workflow 'cancellation' path works correctly for sales journal.
        // [GIVEN] A webhook general journal line approval workflow for a sales journal line is enabled.
        // [GIVEN] Sales journal batch with one line
        // [GIVEN] A sales journal line is pending approval.
        // [WHEN] The webhook sales journal line workflow receives a 'cancellation' response for the sales journal line.
        // [THEN] The sales journal line is cancelled.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForSalesJournal(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureFilteredGeneralJournalLineApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general line approval workflow 'approval' path works correctly for Filtered Gen Journ Line.
        // [GIVEN] A webhook general journal line approval workflow for a general journal line is enabled.
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] A general journal line is pending approval.
        // [WHEN] The webhook general journal line workflow receives an 'approval' response for the general journal line.
        // [THEN] The general journal line is approved

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateJournalBatchWithMultipleJournalLines(GenJournalLine);
        MakeCurrentUserAnApprover();
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        Commit();

        // Verify
        VerifySingleApprovalRequestPendingForFilteredGeneralJournalLine(DummyWorkflowWebhookEntry, GenJournalLine.SystemId);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureFilteredGeneralJournalLineApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general line approval workflow 'approval' path works correctly for Filtered Gen Journ Line.
        // [GIVEN] A webhook general journal line approval workflow for a general journal line is enabled.
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] A general journal line is pending approval.
        // [WHEN] The webhook general journal line workflow receives a 'rejection' response for the general journal line.
        // [THEN] The general journal line is rejected

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateJournalBatchWithMultipleJournalLines(GenJournalLine);
        MakeCurrentUserAnApprover();
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        Commit();

        // Verify
        VerifySingleApprovalRequestPendingForFilteredGeneralJournalLine(DummyWorkflowWebhookEntry, GenJournalLine.SystemId);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureFilteredGeneralJournalLineApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general line approval workflow 'approval' path works correctly for Filtered Gen Journ Line.
        // [GIVEN] A webhook general journal line approval workflow for a general journal line is enabled.
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] A general journal line is pending approval.
        // [WHEN] The webhook general journal line workflow receives a 'cancellation' response for the general journal line.
        // [THEN] The general journal line is cancelled

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateJournalBatchWithMultipleJournalLines(GenJournalLine);
        MakeCurrentUserAnApprover();
        SendFilteredApprovalRequest(GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        Commit();

        // Verify
        VerifySingleApprovalRequestPendingForFilteredGeneralJournalLine(DummyWorkflowWebhookEntry, GenJournalLine.SystemId);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalLineApprovalWorkflowFunctionsCorrectlyWithUnauthorizedContinuation()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general line approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook general journal line approval workflow for a general journal line is enabled.
        // [GIVEN] Journal batch with one line
        // [GIVEN] A general journal line is pending approval.
        // [WHEN] The webhook general journal line workflow receives an 'approval' response from an
        // 'invalid user' for the general journal line.
        // [THEN] The general journal line is not continued

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(BogusUserIdTxt);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");
        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        asserterror WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotActErr, UserId, BogusUserIdTxt));
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalLineApprovalWorkflowFunctionsCorrectlyWithUnauthorizedCancellation()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general line approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook general journal line approval workflow for a general journal line is enabled.
        // [GIVEN] Journal batch with one line
        // [GIVEN] A general journal line is pending approval.
        // [WHEN] The webhook general journal line workflow receives a 'cancellation' response from an
        // 'invalid user' for the general journal line.
        // [THEN] The general journal line is not cancelled

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");
        ChangeWorkflowWebhookEntryInitiatedBy(GenJournalLine.SystemId, BogusUserIdTxt);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        asserterror WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotCancelErr, UserId));
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalLineApprovalWorkflowFunctionsCorrectlyWithUnauthorizedRejection()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general line approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook general journal line approval workflow for a general journal line is enabled.
        // [GIVEN] Journal batch with one line
        // [GIVEN] A general journal line is pending approval.
        // [WHEN] The webhook general journal line workflow receives a 'rejection' response from an
        // 'invalid user' for the general journal line.
        // [THEN] The general journal line is not rejected

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(BogusUserIdTxt);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");
        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        asserterror WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotActErr, UserId, BogusUserIdTxt));
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalLineApprovalWorkflowFunctionsCorrectlyWhenGeneralJournalLineIsRenamed()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NewGenJournalBatch: Record "Gen. Journal Batch";
        NewGenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] A user can rename a general journal line after they send it for approval and the approval requests
        // still points to the same record.
        // [GIVEN] Existing approval.
        // [WHEN] The user renames a general journal line.
        // [THEN] The approval entries are renamed to point to the same record.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise - Create a new general journal line and delete it to reuse the new general journal line keys
        CreateGeneralJournalBatchWithOneJournalLine(NewGenJournalBatch, NewGenJournalLine);
        NewGenJournalLine.Delete(true);
        GenJournalLine.Rename(
          NewGenJournalLine."Journal Template Name", NewGenJournalLine."Journal Batch Name", NewGenJournalLine."Line No.");

        // Verify
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalLine.SystemId));
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalLineApprovalWorkflowFunctionsCorrectlyWhenGeneralJournalLineIsDeleted()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        // [SCENARIO] A user can delete a general journal line after they send it for approval and the approval requests
        // will be cancelled.
        // [GIVEN] Existing approval.
        // [WHEN] The user deltes a general journal line.
        // [THEN] The approval entries are cancelled the general journal line is deleted.

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalLineWorkflowDefinition(UserId);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        MakeCurrentUserAnApprover();
        SendApprovalRequestForGeneralJournal(GenJournalLine."Journal Batch Name");

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalLine.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        GenJournalLine.Find();
        asserterror GenJournalLine.Delete(true);
        Assert.ExpectedError(PreventDeleteRecordWithOpenApprovalEntryForSenderMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingGeneralJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on General Journal page while approval is pending for journal line
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for line
        WebhookHelper.CreatePendingFlowApproval(GenJournalLine.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch should be disabled');
        Assert.IsFalse(GeneralJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch should be disabled');
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line should be disabled');
        Assert.IsTrue(GeneralJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line should be enabled');

        // [THEN] Close the journal
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingPaymentJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Payment Journal page while approval is pending for journal line
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for line
        WebhookHelper.CreatePendingFlowApproval(GenJournalLine.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(PaymentJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch should be disabled');
        Assert.IsFalse(PaymentJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch should be disabled');
        Assert.IsFalse(PaymentJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line should be disabled');
        Assert.IsTrue(PaymentJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line should be enabled');

        // [THEN] Close the journal
        PaymentJournal.Close();
    end;

    [Test]
    procedure ButtonStatusForPendingPurchaseJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Purchase Journal page while approval is pending for journal line
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for line
        WebhookHelper.CreatePendingFlowApproval(GenJournalLine.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        PurchaseJournal.OpenEdit();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(PurchaseJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch should be disabled');
        Assert.IsFalse(PurchaseJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch should be disabled');
        Assert.IsFalse(PurchaseJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line should be disabled');
        Assert.IsTrue(PurchaseJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line should be enabled');

        // [THEN] Close the journal
        PurchaseJournal.Close();
    end;

    [Test]
    procedure ButtonStatusForPendingSalesJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Sales Journal page while approval is pending for journal line
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for line
        WebhookHelper.CreatePendingFlowApproval(GenJournalLine.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        SalesJournal.OpenEdit();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(SalesJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch should be disabled');
        Assert.IsFalse(SalesJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch should be disabled');
        Assert.IsFalse(SalesJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line should be disabled');
        Assert.IsTrue(SalesJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line should be enabled');

        // [THEN] Close the journal
        SalesJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingCashReceiptJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Cash Receipt Journal page while approval is pending for journal line
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for line
        WebhookHelper.CreatePendingFlowApproval(GenJournalLine.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(CashReceiptJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch should be disabled');
        Assert.IsFalse(CashReceiptJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch should be disabled');
        Assert.IsFalse(CashReceiptJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line should be disabled');
        Assert.IsTrue(CashReceiptJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line should be enabled');

        // [THEN] Close the journal
        CashReceiptJournal.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnGeneralJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending journal line approval on General Journal page
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalLine.RecordId);

        // [WHEN] User opens the journal batch and clicks Cancel
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal.CancelApprovalRequestJournalLine.Invoke();

        // [THEN] Flow approval is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // [THEN] Close the journal
        GeneralJournal.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnPaymentJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending journal line approval on Payment Journal page
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalLine.RecordId);

        // [WHEN] User opens the journal batch and clicks Cancel
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.CancelApprovalRequestJournalLine.Invoke();

        // [THEN] Flow approval is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // [THEN] Close the journal
        PaymentJournal.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CancelButtonWorksOnPurchaseJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending journal line approval on Purchase Journal page
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalLine.RecordId);

        // [WHEN] User opens the journal batch and clicks Cancel
        Commit();
        PurchaseJournal.OpenEdit();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PurchaseJournal.CancelApprovalRequestJournalLine.Invoke();

        // [THEN] Flow approval is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // [THEN] Close the journal
        PurchaseJournal.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CancelButtonWorksOnSalesJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending journal line approval on Sales Journal page
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalLine.RecordId);

        // [WHEN] User opens the journal batch and clicks Cancel
        Commit();
        SalesJournal.OpenEdit();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        SalesJournal.CancelApprovalRequestJournalLine.Invoke();

        // [THEN] Flow approval is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // [THEN] Close the journal
        SalesJournal.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnCashReceiptJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending journal line approval on Cash Receipt Journal page
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalLine.RecordId);

        // [WHEN] User opens the journal batch and clicks Cancel
        Commit();
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        CashReceiptJournal.CancelApprovalRequestJournalLine.Invoke();

        // [THEN] Flow approval is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // [THEN] Close the journal
        CashReceiptJournal.Close();
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        UserSetup: Record "User Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        ClearWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        Workflow.ModifyAll(Enabled, false, true);
        UserSetup.DeleteAll();
        GenJournalTemplate.DeleteAll();
        ClearWorkflowWebhookEntry.DeleteAll();
        RemoveBogusUser();
        if IsInitialized then
            exit;

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        BindSubscription(MockOnFindTaskSchedulerAllowed);
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
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreatePaymentJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreateCashReceiptJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibrarySales.SelectCashReceiptJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreatePurchaseJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibraryJournals.SelectGenJournalTemplate(GenJournalTemplate.Type::Purchases, Page::"Purchase Journal"));

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreateSalesJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibraryJournals.SelectGenJournalTemplate(GenJournalTemplate.Type::Sales, Page::"Sales Journal"));

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure CreateJournalBatchWithMultipleJournalLines(var GenJournalLine2: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalLine3: Record "Gen. Journal Line";
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine1, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine1."Document Type"::Invoice, GenJournalLine1."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
        LibraryERM.CreateGeneralJnlLine(GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
        LibraryERM.CreateGeneralJnlLine(GenJournalLine3, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine3."Document Type"::Invoice, GenJournalLine3."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDecInRange(10000, 50000, 2));
    end;

    local procedure SendApprovalRequestForGeneralJournal(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure SendApprovalRequestForCashReceipt(GenJournalBatchName: Code[20])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        CashReceiptJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure SendApprovalRequestForPaymentJournal(GenJournalBatchName: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        PaymentJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure SendApprovalRequestForPurchaseJournal(GenJournalBatchName: Code[20])
    var
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        PurchaseJournal.OpenView();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        PurchaseJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure SendApprovalRequestForSalesJournal(GenJournalBatchName: Code[20])
    var
        SalesJournal: TestPage "Sales Journal";
    begin
        SalesJournal.OpenView();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        SalesJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    local procedure SendFilteredApprovalRequest(GenJournalBatchName: Code[20]; LineNo: Integer)
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.FILTER.SetFilter("Line No.", Format(LineNo));
        GeneralJournal.SendApprovalRequestJournalLine.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure VerifySingleApprovalRequestPendingForFilteredGeneralJournalLine(DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry"; GenJournalId: Guid)
    begin
        Assert.AreEqual(1, DummyWorkflowWebhookEntry.Count, UnexpectedNoOfApprovalEntriesErr);
        VerifyWorkflowWebhookEntryResponse(GenJournalId, DummyWorkflowWebhookEntry.Response::Pending);
    end;
}
