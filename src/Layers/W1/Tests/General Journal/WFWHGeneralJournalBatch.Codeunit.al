codeunit 134219 "WFWH General Journal Batch"
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
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryJournals: Codeunit "Library - Journals";
        DynamicRequestPageParametersGeneralJournalBatchTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Gen. Journal Batch">VERSION(1) SORTING(Field1,Field2)</DataItem></DataItems></ReportParameters>', Locked = true;
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        IsInitialized: Boolean;
        UserCannotCancelErr: Label 'User %1 does not have the permission necessary to cancel the item.', Comment = '%1 = NAV USERID';
        UserCannotActErr: Label 'User %1 cannot act on this step. Make sure the user who created the webhook (%2) is the same who is trying to act.', Comment = '%1, %2 = two distinct NAV user IDs, for example "MEGANB" and "WILLIAMC"';
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNecessaryTableRelationsAreSetup()
    var
        DummyGenJournalBatch: Record "Gen. Journal Batch";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowTableRelation: Record "Workflow - Table Relation";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] Ensure that the necessary webhook general journal batch approval workflow table relations are setup.
        // [WHEN] Workflow setup is initialized.
        // [THEN] Workflow table relations for general journal batch and workflow webhook entry exist.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();

        // Excercise
        WorkflowSetup.InitWorkflow();

        // Verify
        WorkflowTableRelation.Get(
          DATABASE::"Gen. Journal Batch", DummyGenJournalBatch.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalBatchApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general journal batch approval workflow 'approval' path works correctly.
        Initialize();

        // [GIVEN] A webhook general journal batch approval workflow for a general journal batch is enabled.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] A general journal batch is pending approval.
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] The webhook general journal batch approval workflow receives an 'approval' response for the general journal batch.
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // [THEN] The general journal batch is approved.
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalBatchApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general journal batch approval workflow 'rejection' path works correctly.

        Initialize();

        // [GIVEN] A webhook general journal batch approval workflow for a general journal batch is enabled.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] A general journal batch is pending approval.
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] The webhook general journal batch approval workflow receives an 'rejection' response for the general journal batch.
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // [THEN] The general journal batch is rejected.
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalBatchApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general journal batch approval workflow 'cancellation' path works correctly.
        Initialize();

        // [GIVEN] A webhook general journal batch approval workflow for a general journal batch is enabled.
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] A general journal batch is pending approval.
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // [WHEN] The webhook general journal batch approval workflow receives an 'cancellation' response for the general journal batch.
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // [THEN] The general journal batch is cancelled.
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureCashReceiptJournalBatchApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook cash receipt journal batch approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook general journal batch approval workflow for a cash receipt journal batch is enabled.
        // [GIVEN] A cash receipt journal batch is pending approval.
        // [WHEN] The webhook cash receipt journal batch approval workflow receives an 'approval' response for the cash receipt journal batch.
        // [THEN] The cash receipt journal batch is approved.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForCashReceipt(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureCashReceiptJournalBatchApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook cash receipt journal batch approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook general journal batch approval workflow for a cash receipt journal batch is enabled.
        // [GIVEN] A cash receipt journal batch is pending approval.
        // [WHEN] The webhook cash receipt journal batch approval workflow receives an 'rejection' response for the cash receipt journal batch.
        // [THEN] The cash receipt journal batch is rejected.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForCashReceipt(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureCashReceiptJournalBatchApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook cash receipt journal batch approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook general journal batch approval workflow for a cash receipt journal batch is enabled.
        // [GIVEN] A cash receipt journal batch is pending approval.
        // [WHEN] The webhook cash receipt journal batch approval workflow receives an 'cancellation' response for the cash receipt journal batch.
        // [THEN] The cash receipt journal batch is cancelled.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForCashReceipt(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsurePaymentJournalBatchApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook payment journal batch approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook payment journal batch approval workflow for a payment journal batch is enabled.
        // [GIVEN] A payment journal batch is pending approval.
        // [WHEN] The webhook payment journal batch approval workflow receives an 'approval' response for the payment journal batch.
        // [THEN] The payment journal batch is approved.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForPaymentJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsurePaymentJournalBatchApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook payment journal batch approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook payment journal batch approval workflow for a payment journal batch is enabled.
        // [GIVEN] A payment journal batch is pending approval.
        // [WHEN] The webhook payment journal batch approval workflow receives an 'rejection' response for the payment journal batch.
        // [THEN] The payment journal batch is rejected.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForPaymentJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsurePaymentJournalBatchApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook payment journal batch approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook payment journal batch approval workflow for a payment journal batch is enabled.
        // [GIVEN] A payment journal batch is pending approval.
        // [WHEN] The webhook payment journal batch approval workflow receives an 'cancellation' response for the payment journal batch.
        // [THEN] The payment journal batch is cancelled.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForPaymentJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    procedure EnsurePurchaseJournalBatchApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook purchase journal batch approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook purchase journal batch approval workflow for a purchase journal batch is enabled.
        // [GIVEN] A purchase journal batch is pending approval.
        // [WHEN] The webhook purchase journal batch approval workflow receives an 'approval' response for the purchase journal batch.
        // [THEN] The purchase journal batch is approved.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForPurchaseJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    procedure EnsurePurchaseJournalBatchApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook purchase journal batch approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook purchase journal batch approval workflow for a purchase journal batch is enabled.
        // [GIVEN] A purchase journal batch is pending approval.
        // [WHEN] The webhook purchase journal batch approval workflow receives an 'rejection' response for the purchase journal batch.
        // [THEN] The purchase journal batch is rejected.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForPurchaseJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    procedure EnsurePurchaseJournalBatchApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook purchase journal batch approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook purchase journal batch approval workflow for a purchase journal batch is enabled.
        // [GIVEN] A purchase journal batch is pending approval.
        // [WHEN] The webhook purchase journal batch approval workflow receives an 'cancellation' response for the purchase journal batch.
        // [THEN] The purchase journal batch is cancelled.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForPurchaseJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    procedure EnsureSalesJournalBatchApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook sales journal batch approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook sales journal batch approval workflow for a sales journal batch is enabled.
        // [GIVEN] A sales journal batch is pending approval.
        // [WHEN] The webhook sales journal batch approval workflow receives an 'approval' response for the sales journal batch.
        // [THEN] The sales journal batch is approved.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForSalesJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    procedure EnsureSalesJournalBatchApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook sales journal batch approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook sales journal batch approval workflow for a sales journal batch is enabled.
        // [GIVEN] A sales journal batch is pending approval.
        // [WHEN] The webhook sales journal batch approval workflow receives an 'rejection' response for the sales journal batch.
        // [THEN] The sales journal batch is rejected.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForSalesJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    procedure EnsureSalesJournalBatchApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook sales journal batch approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook sales journal batch approval workflow for a sales journal batch is enabled.
        // [GIVEN] A sales journal batch is pending approval.
        // [WHEN] The webhook sales journal batch approval workflow receives an 'cancellation' response for the sales journal batch.
        // [THEN] The sales journal batch is cancelled.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForSalesJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalBatchApprovalWorkflowFunctionsCorrectlyWithUnauthorizedContinuation()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general journal batch approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook general journal batch approval workflow for a general journal batch is enabled.
        // [GIVEN] A general journal batch is pending approval.
        // [WHEN] The webhook general journal batch approval workflow receives an 'approval' response from
        // an 'invalid user' for the general journal batch.
        // [THEN] The general journal batch is not cotinued.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(RequestorUserSetup."User ID");
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        Commit();

        // Exercise
        asserterror WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotActErr, UserId, RequestorUserSetup."User ID"));
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalBatchApprovalWorkflowFunctionsCorrectlyWithUnauthorizedRejection()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general journal batch approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook general journal batch approval workflow for a general journal batch is enabled.
        // [GIVEN] A general journal batch is pending approval.
        // [WHEN] The webhook general journal batch approval workflow receives an 'rejection' response from
        // an 'invalid user' for the general journal batch.
        // [THEN] The general journal batch is not rejected.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(RequestorUserSetup."User ID");
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        Commit();

        // Exercise
        asserterror WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotActErr, UserId, RequestorUserSetup."User ID"));
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalBatchApprovalWorkflowFunctionsCorrectlyWithUnauthorizedCancellation()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general journal batch approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook general journal batch approval workflow for a general journal batch is enabled.
        // [GIVEN] A general journal batch is pending approval.
        // [WHEN] The webhook general journal batch approval workflow receives an 'cancellation' response from
        // an 'invalid user' for the general journal batch.
        // [THEN] The general journal batch is not cancelled.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);
        ChangeWorkflowWebhookEntryInitiatedBy(GenJournalBatch.SystemId, RequestorUserSetup."User ID");

        Commit();

        // Exercise
        asserterror WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        Assert.ExpectedError(StrSubstNo(UserCannotCancelErr, UserId));
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureFilteredGeneralJournalBatchApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general journal batch approval workflow 'approval' path works correctly for Filtered general journal batch.
        // [GIVEN] A webhook general journal batch approval workflow for a general journal batch is enabled.
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] A general journal batch is pending approval.
        // [WHEN] The webhook general journal batch workflow receives an 'approval' response for the general journal batch.
        // [THEN] The general journal batch is approved

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(UserId);
        CreateJournalBatchWithMultipleJournalLines(GenJournalBatch);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        SendFilteredApprovalRequest(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureFilteredGeneralJournalBatchApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general journal batch approval workflow 'rejection' path works correctly for Filtered general journal batch.
        // [GIVEN] A webhook general journal batch approval workflow for a general journal batch is enabled.
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] A general journal batch is pending approval.
        // [WHEN] The webhook general journal batch workflow receives an 'rejection' response for the general journal batch.
        // [THEN] The general journal batch is rejected

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(UserId);
        CreateJournalBatchWithMultipleJournalLines(GenJournalBatch);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        SendFilteredApprovalRequest(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureFilteredGeneralJournalBatchApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook general journal batch approval workflow 'cancellation' path works correctly for Filtered general journal batch.
        // [GIVEN] A webhook general journal batch approval workflow for a general journal batch is enabled.
        // [GIVEN] Journal batch with one or more lines
        // [GIVEN] Subset of the lines are included in the request
        // [GIVEN] A general journal batch is pending approval.
        // [WHEN] The webhook general journal batch workflow receives an 'cancelled' response for the general journal batch.
        // [THEN] The general journal batch is cancelled

        Initialize();

        // Setup
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(UserId);
        CreateJournalBatchWithMultipleJournalLines(GenJournalBatch);
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        SendFilteredApprovalRequest(GenJournalBatch.Name);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGeneralJournalBatchApprovalWorkflowFunctionsCorrectlyWhenGeneralJournalBatchIsRenamed()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NewGenJournalBatch: Record "Gen. Journal Batch";
        NewGenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] A user can rename a general journal batch after they send it for approval and the approval requests
        // still points to the same record.
        // [GIVEN] Existing approval.
        // [WHEN] The user renames a general journal batch.
        // [THEN] The approval entries are renamed to point to the same record.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise - Create a new general journal batch and delete it to reuse the new general journal batch keys
        CreateGeneralJournalBatchWithOneJournalLine(NewGenJournalBatch, NewGenJournalLine);
        NewGenJournalBatch.Delete(true);
        GenJournalBatch.Rename(NewGenJournalBatch."Journal Template Name", NewGenJournalBatch.Name);

        // Verify
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(GenJournalBatch.SystemId));
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure EnsureGeneralJournalBatchApprovalWorkflowFunctionsCorrectlyWhenGeneralJournalBatchIsDeleted()
    var
        ApproverUserSetup: Record "User Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequestorUserSetup: Record "User Setup";
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowStepInstance: Record "Workflow Step Instance";
        DummyWorkflowCode: Code[20];
    begin
        // [SCENARIO] A user can delete a general journal batch after they send it for approval and the approval requests
        // will be cancelled.
        // [GIVEN] Existing approval.
        // [WHEN] The user deltes a general journal batch.
        // [THEN] The approval entries are cancelled the general journal batch is deleted.

        Initialize();

        // Setup
        CreateApprovalSetup(ApproverUserSetup, RequestorUserSetup);
        CreateAndEnableGeneralJournalBatchWorkflowDefinition(ApproverUserSetup."User ID");
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // Exercise
        Commit();
        SendApprovalRequestForGeneralJournal(GenJournalBatch.Name);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        GenJournalBatch.Delete(true);

        // Verify
        VerifyWorkflowWebhookEntryResponse(GenJournalBatch.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
        WorkflowStepInstance.SetRange("Workflow Code", DummyWorkflowCode);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingGeneralJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on General Journal page while approval is pending for journal batch
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch should be disabled');
        Assert.IsTrue(GeneralJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch should be enabled');
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line should be disabled');
        Assert.IsFalse(GeneralJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line should be disabled');

        // [THEN] Close the journal
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingPaymentJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Payment Journal page while approval is pending for journal batch
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(PaymentJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch should be disabled');
        Assert.IsTrue(PaymentJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch should be enabled');
        Assert.IsFalse(PaymentJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line should be disabled');
        Assert.IsFalse(PaymentJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line should be disabled');

        // [THEN] Close the journal
        PaymentJournal.Close();
    end;

    [Test]
    procedure ButtonStatusForPendingPurchaseJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Purchase Journal page while approval is pending for journal batch
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        PurchaseJournal.OpenEdit();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(PurchaseJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch should be disabled');
        Assert.IsTrue(PurchaseJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch should be enabled');
        Assert.IsFalse(PurchaseJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line should be disabled');
        Assert.IsFalse(PurchaseJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line should be disabled');

        // [THEN] Close the journal
        PurchaseJournal.Close();
    end;

    [Test]
    procedure ButtonStatusForPendingSalesJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Sales Journal page while approval is pending for journal batch
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        SalesJournal.OpenEdit();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(SalesJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch should be disabled');
        Assert.IsTrue(SalesJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch should be enabled');
        Assert.IsFalse(SalesJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line should be disabled');
        Assert.IsFalse(SalesJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line should be disabled');

        // [THEN] Close the journal
        SalesJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingCashReceiptJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Cash Receipt Journal page while approval is pending for journal batch
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch
        Commit();
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(CashReceiptJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch should be disabled');
        Assert.IsTrue(CashReceiptJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch should be enabled');
        Assert.IsFalse(CashReceiptJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line should be disabled');
        Assert.IsFalse(CashReceiptJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line should be disabled');

        // [THEN] Close the journal
        CashReceiptJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnGeneralJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending journal batch approval on General Journal page
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch and clicks Cancel
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal.CancelApprovalRequestJournalBatch.Invoke();

        // [THEN] Flow approval is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // [THEN] Close the journal
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnPaymentJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending journal batch approval on Payment Journal page
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch and clicks Cancel
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.CancelApprovalRequestJournalBatch.Invoke();

        // [THEN] Flow approval is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // [THEN] Close the journal
        PaymentJournal.Close();
    end;

    [Test]
    procedure CancelButtonWorksOnPurchaseJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending journal batch approval on Purchase Journal page
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch and clicks Cancel
        Commit();
        PurchaseJournal.OpenEdit();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PurchaseJournal.CancelApprovalRequestJournalBatch.Invoke();

        // [THEN] Flow approval is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // [THEN] Close the journal
        PurchaseJournal.Close();
    end;

    [Test]
    procedure CancelButtonWorksOnSalesJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending journal batch approval on Sales Journal page
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch and clicks Cancel
        Commit();
        SalesJournal.OpenEdit();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        SalesJournal.CancelApprovalRequestJournalBatch.Invoke();

        // [THEN] Flow approval is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // [THEN] Close the journal
        SalesJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnCashReceiptJournalBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending journal batch approval on Cash Receipt Journal page
        Initialize();

        // [GIVEN] Journal batch with one or more lines
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [WHEN] User opens the journal batch and clicks Cancel
        Commit();
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        CashReceiptJournal.CancelApprovalRequestJournalBatch.Invoke();

        // [THEN] Flow approval is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // [THEN] Close the journal
        CashReceiptJournal.Close();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ButtonStatusForGeneralJournalBatchAfterLookupSwitch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        GenJnlManagement: Codeunit GenJnlManagement;
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 321997] Approval actions are correctly enabled/disabled on General Journal page after switching to different General Journal Batch through lookup
        Initialize();
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"General Journal");

        // [GIVEN] Journal batches "B1","B2" with one or more lines
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        CreateGeneralJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch "B2"
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [GIVEN] General Journal page opened on batch "B2"
        Commit();
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [WHEN] User opens the journal batch "B1" through lookup
        GeneralJournal.CurrentJnlBatchName.Lookup();

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch must be disabled');
        Assert.IsFalse(GeneralJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch must be disabled');
        Assert.IsFalse(GeneralJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line must be disnabled');
        Assert.IsFalse(GeneralJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line must be disabled');

        GeneralJournal.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ButtonStatusForPaymentJournalBatchAfterLookupSwitch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 321997] Approval actions are correctly enabled/disabled on Payment Journal page after switching to different General Journal Batch through lookup
        Initialize();

        // [GIVEN] Journal batches "B1","B2" with one or more lines
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        CreatePaymentJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch "B2"
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [GIVEN] Payment Journal page opened on batch "B2"
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [WHEN] User opens the journal batch "B1" through lookup
        PaymentJournal.CurrentJnlBatchName.Lookup();

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsTrue(PaymentJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch must be enabled');
        Assert.IsFalse(PaymentJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch must be disabled');
        Assert.IsTrue(PaymentJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line must be enabled');
        Assert.IsFalse(PaymentJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line must be disabled');

        PaymentJournal.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesModalPageHandler')]
    procedure ButtonStatusForPurchaseJournalBatchAfterLookupSwitch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO 321997] Approval actions are correctly enabled/disabled on Purchase Journal page after switching to different General Journal Batch through lookup
        Initialize();

        // [GIVEN] Journal batches "B1","B2" with one or more lines
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        CreatePurchaseJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch "B2"
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [GIVEN] Purchase Journal page opened on batch "B2"
        Commit();
        PurchaseJournal.OpenEdit();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [WHEN] User opens the journal batch "B1" through lookup
        PurchaseJournal.CurrentJnlBatchName.Lookup();

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(PurchaseJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch must be disabled');
        Assert.IsFalse(PurchaseJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch must be disabled');
        Assert.IsFalse(PurchaseJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line must be disabled');
        Assert.IsFalse(PurchaseJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line must be disabled');

        PurchaseJournal.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesModalPageHandler')]
    procedure ButtonStatusForSalesJournalBatchAfterLookupSwitch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO 321997] Approval actions are correctly enabled/disabled on Sales Journal page after switching to different General Journal Batch through lookup
        Initialize();

        // [GIVEN] Journal batches "B1","B2" with one or more lines
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        CreateSalesJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch "B2"
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [GIVEN] Sales Journal page opened on batch "B2"
        Commit();
        SalesJournal.OpenEdit();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [WHEN] User opens the journal batch "B1" through lookup
        SalesJournal.CurrentJnlBatchName.Lookup();

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsFalse(SalesJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch must be disabled');
        Assert.IsFalse(SalesJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch must be disabled');
        Assert.IsFalse(SalesJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line must be disabled');
        Assert.IsFalse(SalesJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line must be disabled');

        SalesJournal.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ButtonStatusForCashReceiptJournalBatchAfterLookupSwitch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        WebhookHelper: Codeunit "Webhook Helper";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO 321997] Approval actions are correctly enabled/disabled on Cash Receipt Journal page after switching to different General Journal Batch through lookup
        Initialize();

        // [GIVEN] Journal batches "B1","B2" with one or more lines
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        CreateCashReceiptJournalBatchWithOneJournalLine(GenJournalBatch, GenJournalLine);

        // [GIVEN] Workflow webhook entry exists for batch "B2"
        WebhookHelper.CreatePendingFlowApproval(GenJournalBatch.RecordId);

        // [GIVEN] Cash Receipt Journal page opened on batch "B2"
        Commit();
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [WHEN] User opens the journal batch "B1" through lookup
        CashReceiptJournal.CurrentJnlBatchName.Lookup();

        // [THEN] Approval actions are correctly enabled/disabled
        Assert.IsTrue(CashReceiptJournal.SendApprovalRequestJournalBatch.Enabled(), 'Send Batch must be enabled');
        Assert.IsFalse(CashReceiptJournal.CancelApprovalRequestJournalBatch.Enabled(), 'Cancel Batch must be disabled');
        Assert.IsTrue(CashReceiptJournal.SendApprovalRequestJournalLine.Enabled(), 'Send Line must be enabled');
        Assert.IsFalse(CashReceiptJournal.CancelApprovalRequestJournalLine.Enabled(), 'Cancel Line must be disabled');

        CashReceiptJournal.Close();
        LibraryVariableStorage.AssertEmpty();
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
        ClearWorkflowWebhookEntry.DeleteAll();
        GenJournalTemplate.DeleteAll();
        if IsInitialized then
            exit;

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        BindSubscription(MockOnFindTaskSchedulerAllowed);
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

    local procedure CreateAndEnableGeneralJournalBatchWorkflowDefinition(ResponseUserID: Code[50]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        WorkflowCode: Code[20];
    begin
        WorkflowCode :=
          WorkflowWebhookSetup.CreateWorkflowDefinition(WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode(),
            '', DynamicRequestPageParametersGeneralJournalBatchTxt, ResponseUserID);
        Workflow.Get(WorkflowCode);
        LibraryWorkflow.EnableWorkflow(Workflow);
        exit(WorkflowCode);
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

    local procedure CreateApprovalSetup(var ApproverUserSetup: Record "User Setup"; var RequestorUserSetup: Record "User Setup")
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(ApproverUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(RequestorUserSetup);
        LibraryDocumentApprovals.SetApprover(RequestorUserSetup, ApproverUserSetup);
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

    local procedure CreatePaymentJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateCashReceiptJournalBatchWithOneJournalLine(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        CreateJournalBatch(GenJournalBatch, LibrarySales.SelectCashReceiptJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
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

    local procedure CreateJournalBatchWithMultipleJournalLines(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalLine3: Record "Gen. Journal Line";
    begin
        CreateJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());

        LibraryERM.CreateGeneralJnlLine(GenJournalLine1, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine1."Document Type"::Invoice, GenJournalLine1."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGeneralJnlLine(GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGeneralJnlLine(GenJournalLine3, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine3."Document Type"::Invoice, GenJournalLine3."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure SendApprovalRequestForGeneralJournal(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure SendApprovalRequestForCashReceipt(GenJournalBatchName: Code[20])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        CashReceiptJournal.OpenView();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        CashReceiptJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure SendApprovalRequestForPaymentJournal(GenJournalBatchName: Code[20])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenView();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        PaymentJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure SendApprovalRequestForPurchaseJournal(GenJournalBatchName: Code[20])
    var
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        PurchaseJournal.OpenView();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        PurchaseJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure SendApprovalRequestForSalesJournal(GenJournalBatchName: Code[20])
    var
        SalesJournal: TestPage "Sales Journal";
    begin
        SalesJournal.OpenView();
        SalesJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        SalesJournal.SendApprovalRequestJournalBatch.Invoke();
    end;

    local procedure SendFilteredApprovalRequest(GenJournalBatchName: Code[20])
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        GeneralJournal.FILTER.SetFilter("Line No.", '20000'); // 2nd line
        GeneralJournal.SendApprovalRequestJournalBatch.Invoke();
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalBatchesModalPageHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalBatches.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
