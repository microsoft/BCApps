codeunit 134222 "WFWH Vendor Approval"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Workflow Webhook Entry" = imd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Approval] [Vendor]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        BogusUserIdTxt: Label 'CONTOSO';
        DynamicRequestPageParametersVendorTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Vendor">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>', Locked = true;
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNecessaryTableRelationsAreSetup()
    var
        DummyVendor: Record Vendor;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowTableRelation: Record "Workflow - Table Relation";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] Ensure that the necessary webhook vendor approval workflow table relations are setup.
        // [WHEN] Workflow setup is initialized.
        // [THEN] Workflow table relations for vendor and workflow webhook entry exist.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();

        // Excercise
        WorkflowSetup.InitWorkflow();

        // Verify
        WorkflowTableRelation.Get(
          DATABASE::Vendor, DummyVendor.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNewVendorCanBeSentForApproval()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] A user can send a newly created vendor for approval.
        // [GIVEN] A new  Vendor.
        // [WHEN] The user send an approval request from the vendor.
        // [THEN] The Approval flow gets started.

        // Setup
        Initialize();
        CreateAndEnableVendorWorkflowDefinition(UserId);

        // Exercise - New Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise - Send for approval
        SendVendorForApproval(Vendor);

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureVendorApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        Vendor: Record Vendor;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook vendor approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook vendor approval workflow for a vendor is enabled.
        // [GIVEN] A vendor request is pending approval.
        // [WHEN] The webhook vendor approval workflow receives an 'approval' response for the vendor request.
        // [THEN] The vendor request is approved.

        // Setup
        Initialize();
        CreateAndEnableVendorWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();
        LibraryPurchase.CreateVendor(Vendor);

        // Setup - A approval
        SendVendorForApproval(Vendor);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Vendor.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureVendorApprovalWorkflowFailsIfAlreadyApproved()
    var
        Vendor: Record Vendor;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
        PendingWorkflowId: Guid;
    begin
        // [SCENARIO] Ensure that a webhook vendor approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook vendor approval workflow for a vendor is enabled.
        // [GIVEN] A vendor request is pending approval.
        // [WHEN] The webhook vendor approval workflow receives an 'approval' response for the vendor request.
        // [THEN] The vendor request is approved.
        // [WHEN] The webhook vendor approval workflow receives another 'approval' response.
        // [THEN] The second approval fails.

        // Setup
        Initialize();
        CreateAndEnableVendorWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();
        LibraryPurchase.CreateVendor(Vendor);

        // Setup - A approval
        SendVendorForApproval(Vendor);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        PendingWorkflowId := GetPendingWorkflowStepInstanceIdFromDataId(Vendor.SystemId);
        WorkflowWebhookManagement.ContinueByStepInstanceId(PendingWorkflowId);

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Continue);

        // Exercise
        asserterror WorkflowWebhookManagement.ContinueByStepInstanceId(PendingWorkflowId);
        Assert.ExpectedError('A response has already been received.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureVendorApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        Vendor: Record Vendor;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook vendor approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook vendor approval workflow for a vendor is enabled.
        // [GIVEN] A vendor request is pending approval.
        // [WHEN] The webhook vendor approval workflow receives a 'cancellation' response for the vendor request.
        // [THEN] The vendor request is cancelled.

        // Setup
        Initialize();
        CreateAndEnableVendorWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();
        LibraryPurchase.CreateVendor(Vendor);

        // Setup - A approval
        SendVendorForApproval(Vendor);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Vendor.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureVendorApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        Vendor: Record Vendor;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook vendor approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook vendor approval workflow for a vendor is enabled.
        // [GIVEN] A vendor request is pending approval.
        // [WHEN] The webhook vendor approval workflow receives a 'rejection' response for the vendor request.
        // [THEN] The vendor request is rejected.

        // Setup
        Initialize();
        CreateAndEnableVendorWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();
        LibraryPurchase.CreateVendor(Vendor);

        // Setup - A approval
        SendVendorForApproval(Vendor);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Vendor.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureVendorApprovalWorkflowFunctionsCorrectlyWhenVendorIsRenamed()
    var
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] A user can rename a vendor after they send it for approval and the approval requests
        // still points to the same record.
        // [GIVEN] Existing approval.
        // [WHEN] The user renames a vendor.
        // [THEN] The approval entries are renamed to point to the same record.

        // Setup
        Initialize();
        CreateAndEnableVendorWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();

        // Setup - an existing approval
        LibraryPurchase.CreateVendor(Vendor);
        SendVendorForApproval(Vendor);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise - Create a new vendor and delete it to reuse the vendor No.
        LibraryPurchase.CreateVendor(NewVendor);
        NewVendor.Delete(true);
        Vendor.Rename(NewVendor."No.");

        // Verify - Request is approved since approval entry renamed to point to same record
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Vendor.SystemId));
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureVendorApprovalWorkflowFunctionsCorrectlyWhenVendorIsDeleted()
    var
        Vendor: Record Vendor;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowCode: Code[20];
    begin
        // [SCENARIO] A user can delete a vendor and the existing approval requests will be canceled.
        // [GIVEN] Existing approval.
        // [WHEN] The user deletes the vendor.
        // [THEN] The vendor approval requests are canceled and then the vendor is deleted.

        // Setup
        Initialize();
        WorkflowCode := CreateAndEnableVendorWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();

        // Setup - an existing approval
        LibraryPurchase.CreateVendor(Vendor);
        SendVendorForApproval(Vendor);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        Vendor.Delete(true);

        // Verify
        VerifyWorkflowWebhookEntryResponse(Vendor.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
        WorkflowStepInstance.SetRange("Workflow Code", WorkflowCode);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingApprovalVendorCard()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        WebhookHelper: Codeunit "Webhook Helper";
        WorkflowSetup: Codeunit "Workflow Setup";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Vendor Card page while Flow approval is pending.
        Initialize();

        // [GIVEN] Vendor record exists, with enabled workflow and a Flow approval request already open.
        LibraryPurchase.CreateVendor(Vendor);
        Commit();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorWorkflowCode());
        WebhookHelper.CreatePendingFlowApproval(Vendor.RecordId);

        // [WHEN] Vendor card is opened.
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(VendorCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(VendorCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingFlowApprovalVendorList()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        WebhookHelper: Codeunit "Webhook Helper";
        WorkflowSetup: Codeunit "Workflow Setup";
        VendorList: TestPage "Vendor List";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Vendor List page while Flow approval is pending.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Vendor record exists, with enabled workflow and a Flow approval request already open.
        LibraryPurchase.CreateVendor(Vendor);
        Commit();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorWorkflowCode());
        WebhookHelper.CreatePendingFlowApproval(Vendor.RecordId);

        // [WHEN] Vendor list is opened.
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(VendorList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(VendorList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        VendorList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalVendorCard()
    var
        Vendor: Record Vendor;
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Vendor Card page
        Initialize();

        // [GIVEN] Vendor record exists, with a Flow approval request already open.
        LibraryPurchase.CreateVendor(Vendor);
        Commit();
        WebhookHelper.CreatePendingFlowApproval(Vendor.RecordId);

        // [WHEN] Vendor card is opened and Cancel button is clicked.
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnFlowApprovalVendorList()
    var
        Vendor: Record Vendor;
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        WebhookHelper: Codeunit "Webhook Helper";
        VendorList: TestPage "Vendor List";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Vendor List page
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Vendor record exists, with a Flow approval request already open.
        LibraryPurchase.CreateVendor(Vendor);
        Commit();
        WebhookHelper.CreatePendingFlowApproval(Vendor.RecordId);

        // [WHEN] Vendor list is opened and Cancel button is clicked.
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);
        VendorList.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        VendorList.Close();
    end;

    local procedure SendVendorForApproval(var Vendor: Record Vendor)
    var
        VendorCard: TestPage "Vendor Card";
    begin
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.SendApprovalRequest.Invoke();
        VendorCard.Close();
    end;

    local procedure Initialize()
    var
        ClearWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        UserSetup: Record "User Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        ClearWorkflowWebhookEntry.DeleteAll();
        RemoveBogusUser();
        if IsInitialized then
            exit;
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        BindSubscription(MockOnFindTaskSchedulerAllowed);
    end;

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

    [Scope('OnPrem')]
    procedure RemoveBogusUser()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(BogusUserIdTxt) then
            UserSetup.Delete(true);
    end;

    local procedure CreateAndEnableVendorWorkflowDefinition(ResponseUserID: Code[50]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        WorkflowCode: Code[20];
    begin
        WorkflowCode :=
          WorkflowWebhookSetup.CreateWorkflowDefinition(WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode(),
            '', DynamicRequestPageParametersVendorTxt, ResponseUserID);
        Workflow.Get(WorkflowCode);
        LibraryWorkflow.EnableWorkflow(Workflow);
        exit(WorkflowCode);
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
}
