codeunit 134180 "WF Demo Purch. Order Approvals"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Purchase] [Order]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        DocCannotBeReleasedErr: Label 'This document can only be released when the approval process is complete.';
        DocCannotBePostedErr: Label '%1 %2 must be approved and released before you can perform this action.', Comment = '%1 = PurchHeader."Document Type", %2 = PurchHeader."No."';
        LibraryWorkflow: Codeunit "Library - Workflow";
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;
        DynamicRequestPageParametersTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Purchase Header">SORTING(Field1,Field3) WHERE(Field1=1(1),Field120=1(0))</DataItem><DataItem name="Purchase Line">SORTING(Field1,Field3,Field4) WHERE(Field5=1(%1))</DataItem></DataItems></ReportParameters>', Locked = true;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"WF Demo Purch. Order Approvals");
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"WF Demo Purch. Order Approvals");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"WF Demo Purch. Order Approvals");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostPurchaseOrder()
    var
        Workflow: Record Workflow;
        PurchHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO] The user cannot post a purchase order when the approval workflow is enabled and the purchase order is not approved and released.
        // [GIVEN] There is a purchase order that is not approved and released.
        // [GIVEN] The approval workflow for puchase order is enabled.
        // [WHEN] The user wants to Post the purchase order.
        // [THEN] The user will get an error that he cannot post a purchase order that is not approved and released.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        CreatePurchDocument(PurchHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchHeader);
        asserterror PurchaseOrderList.Post.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBePostedErr, PurchHeader."Document Type", PurchHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseOrder()
    var
        Workflow: Record Workflow;
        PurchHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO] The user cannot release a purchase order when the approval workflow is enabled and the purchase order is not approved.
        // [GIVEN] There is a purchase order that is not approved.
        // [GIVEN] The approval workflow for puchase order is enabled.
        // [WHEN] The user wants to Release the purchase order.
        // [THEN] The user will get an error that he cannot release a purchase order that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        CreatePurchDocument(PurchHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchHeader);
        asserterror PurchaseOrderList.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] The user cannot release a purchase order when the approval workflow is enabled and the purchase order is pending approval.
        // [GIVEN] There is a purchase order that is sent for approval.
        // [GIVEN] The approval workflow for puchase orders is enabled.
        // [WHEN] The user wants to Release the purchase order.
        // [THEN] The user will get an error that he cannot release the purchase order that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, chain the users for approval, set purchase amount limits
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create purchase order where amount will lead to 3 approval requests
        CreatePurchDocument(PurchHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Excercise - Open Purchase order card and sent it for approval
        SendPurchaseOrderForApproval(PurchHeader);

        // Verify - Purchase order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Exercise
        Commit();
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchHeader);
        asserterror PurchaseOrder.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(PurchHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenPurchaseOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] The user cannot release a purchase order when the approval workflow is enabled and the purchase order is pending approval.
        // [GIVEN] There is a purchase order that is sent for approval.
        // [GIVEN] The approval workflow for puchase orders is enabled.
        // [WHEN] The user wants to Reopen the purchase order.
        // [THEN] The user will get an error that he cannot reopen the purchase order.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, chain the users for approval, set purchase amount limits
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create purchase order where amount will lead to 3 approval requests
        CreatePurchDocument(PurchHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Excercise - Open Purchase order card and sent it for approval
        SendPurchaseOrderForApproval(PurchHeader);

        // Verify - Purchase order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Exercise
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchHeader);
        asserterror PurchaseOrder.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderApprovalWorkflow()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 1] Test that the Purchase Order Approval Workflow approval path works with a chain of approvers of 3 users.
        // [GIVEN] The Purchase Order Approval Workflow is enabled.
        // [WHEN] A user sends the purchase order for approval and all users in the chain of approvals approve the document.
        // [THEN] The purchase order is approved and released.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Purchase order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);

        // Excercise - Open Purchae order card and approve the approval request
        ApprovePurchaseOrder(PurchHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Set the approverid to USERID so that it can be approved
        ApprovePurchaseOrder(PurchHeader);

        // Verify - Purchase order is approved and released
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::Released);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderApprovalWorkflowRejectionPathLastApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 2] Test that the Purchase Order Approval Workflow rejection path works with a chain of approvers of 3 users.
        // [GIVEN] The Purchase Order Approval Workflow is enabled.
        // [WHEN] A user sends the purchase order for approval, the first approver approves it and last approver rejects it.
        // [THEN] The purchase order is rejected and open.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Purchase order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);

        // Excercise - Open Purchae order card and approve the approval request
        ApprovePurchaseOrder(PurchHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Set the approverid to USERID so that it can be rejected
        RejectPurchaseOrder(PurchHeader);

        // Verify - Purchase order is rejected and open
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::Open);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderApprovalWorkflowRejectionPathFirstApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 3] Test that the Purchase Order Approval Workflow rejection path works with a chain of approvers of 3 users.
        // [GIVEN] The Purchase Order Approval Workflow is enabled.
        // [WHEN] A user sends the purchase order for approval and the first approver rejects it.
        // [THEN] The purchase order is rejected and open.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Purchase order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be rejected
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);

        // Excercise - Open Purchase order card and reject it
        RejectPurchaseOrder(PurchHeader);

        // Verify - Purchase order is rejected and open
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::Open);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderApprovalWorkflowCancelation()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 5] Test that the Purchase Order Approval Workflow rejection path works with a chain of approvers of 3 users.
        // [GIVEN] The Purchase Order Approval Workflow is enabled.
        // [WHEN] A user sends the purchase order for approval and then the user cancels it.
        // [THEN] The purchase order is canceled and open.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);

        // Verify - Purchase order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Cancel the approval request
        CancelPurchaseOrder(PurchHeader);

        // Verify - Purchase order is canceled and open
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::Open);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderApprovalWorkflowDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 6] Test that the Purchase Order Approval Workflow delegation path works with a chain of approvers of 3 users and one delegate.
        // [GIVEN] The Purchase Order Approval Workflow is enabled.
        // [WHEN] A user sends the purchase order for approval and the second user delegates the approval to the 3rd user and the last user approves it.
        // [THEN] The purchase order is approved and released.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, PurchHeader);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Verify - Purchase order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);

        // Excercise - Open Purchae order card and approve the approval request
        ApprovePurchaseOrder(PurchHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Delegate the purchase order
        DelegatePurchaseOrder(PurchHeader);

        // Exercise - Set the approver id
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);

        // Exercise - Approve the purchase order
        ApprovePurchaseOrder(PurchHeader);

        // Verify - Purchase order is approved and released
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::Released);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(PurchHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderApprovalActionsVisibilityOnCardTest()
    var
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] Purchase Header approval disabled.
        Initialize();

        // [WHEN] Purchase Header card is opened.
        CreatePurchDocument(PurchHeader, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror PurchaseOrder.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        PurchaseOrder.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // [WHEN] PurchHeader card is opened.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(PurchaseOrder.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(PurchaseOrder.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(PurchaseOrder.Delegate.Visible(), 'Delegate should NOT be visible');
        PurchaseOrder.Close();

        // [GIVEN] Approval exist on PurchHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        PurchaseOrder.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(PurchaseOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        PurchaseOrder.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // [WHEN] PurchHeader card is opened.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(PurchaseOrder.Approve.Visible(), 'Approve should be visible');
        Assert.IsTrue(PurchaseOrder.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(PurchaseOrder.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderApprovalActionsVisibilityOnListTest()
    var
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] PurchHeader approval disabled.
        Initialize();

        // [WHEN] PurchHeader card is opened.
        CreatePurchDocument(PurchHeader, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();
        PurchaseOrderList.OpenEdit();
        PurchaseOrderList.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror PurchaseOrderList.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        PurchaseOrderList.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // [WHEN] PurchHeader card is opened.
        PurchaseOrderList.OpenEdit();
        PurchaseOrderList.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        PurchaseOrderList.Close();

        // [GIVEN] Approval exist on PurchHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        PurchaseOrderList.OpenEdit();
        PurchaseOrderList.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        PurchaseOrderList.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(PurchaseOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderWorkflowTableRelationSetup()
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO 379202] Test Workflow Table Relations for Purchase Order
        // [WHEN] Init Workflow Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowSetup.InitWorkflow();

        // [THEN] Workflow Table Relations for Purhase Order exist
        WorkflowTableRelation.Get(
          DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"),
          DATABASE::"Purchase Line", PurchaseLine.FieldNo("Document Type"));
        WorkflowTableRelation.Get(
          DATABASE::"Purchase Header", PurchaseHeader.FieldNo("No."),
          DATABASE::"Purchase Line", PurchaseLine.FieldNo("Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasePurchaseOrderForItemFilteringForApprovalsOnFixedAsset()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkflowStepArgument: Record "Workflow Step Argument";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO 379202] Release Purchase Order of Item when POAP workflow filtering on Fixed Asset
        Initialize();

        // [GIVEN] Workflow on Purchase Order Approval Template
        ReinitializeWorkflowsAndCreateWorkflowForPurchaseOrder(Workflow, WorkflowStep);

        // [GIVEN] Filtering Workflow purchase lines on Type = Fixed Asset
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.SetEventFilters(StrSubstNo(DynamicRequestPageParametersTxt, PurchaseLine.Type::"Fixed Asset"));

        // [GIVEN] Workflow enabled
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Purchase Order on Item
        CreatePurchDocument(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // [WHEN] Release Purchase Order
        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        PurchaseOrderList.Release.Invoke();

        // [THEN] Purchase Order Status = Released
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseOrderForFixedAssetFilteringForApprovalsOnFixedAsset()
    var
        WorkflowStep: Record "Workflow Step";
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkflowStepArgument: Record "Workflow Step Argument";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [SCENARIO 379202] Release Purchase Order of Fixed Asset errors when POAP workflow filtering on Fixed Asset
        Initialize();

        // [GIVEN] Workflow on Purchase Order Approval Template
        ReinitializeWorkflowsAndCreateWorkflowForPurchaseOrder(Workflow, WorkflowStep);

        // [GIVEN] Filtering Workflow purchase lines on Type = Fixed Asset
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.SetEventFilters(StrSubstNo(DynamicRequestPageParametersTxt, PurchaseLine.Type::"Fixed Asset"));

        // [GIVEN] Workflow enabled
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Purchase Order on Fixed Asset
        CreatePurchDocumentForFixedAsset(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryRandom.RandIntInRange(5000, 10000));

        // [WHEN] Release Purchase Order
        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        asserterror PurchaseOrderList.Release.Invoke();

        // [THEN] Error "This document can only be released when the approval process is complete."
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalUserSetup: Record "User Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Order approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Purchase Order Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Order is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and the user can add a comment.
        // [WHEN] Purchaser approves the approval request.
        // [THEN] Purchase Order is released.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalUserSetup, PurchaseHeader);

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, false);

        // Verify - Purchase Order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, UserId, IntermediateApproverUserSetup."User ID", ApprovalEntry.Status::Open);

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, true);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Excercise - Open Purchase Order card and approve the approval request
        ApprovePurchaseOrder(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        VerifyApprovalEntry(ApprovalEntry, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", ApprovalEntry.Status::Approved);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderApprovalWorkflowTestUserCanCancel()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalUserSetup: Record "User Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase Order approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Purchase Order Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Order is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalUserSetup, PurchaseHeader);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, true);

        // Verify - Purchase Order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, UserId, IntermediateApproverUserSetup."User ID", ApprovalEntry.Status::Open);

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);

        // Verify - User Cannot cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, false);

        LibraryDocumentApprovals.SetAdministrator(CurrentUserSetup);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, true);

        // Excercise - Open Purchase Order card and cancel the approval request
        CancelPurchaseOrder(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::Open);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        VerifyApprovalEntry(ApprovalEntry, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", ApprovalEntry.Status::Canceled);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderApprovalWithOverReceiptWorkflowStep()
    var
        Workflow: Record Workflow;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowStep: Record "Workflow Step";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO 395546] Purchase Order approval workflow with Over-Receipt workflow step
        Initialize();

        // [GIVEN] The Purchase Order Approval Workflow with additional Over-Receipt workflow step is enabled
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
        InsertNewWorkflowStepAfter(
            Workflow.Code, WorkflowResponseHandling.AllowRecordUsageCode(),
            WorkflowStep.Type::Response, WorkflowResponseHandling.GetApproveOverReceiptCode());
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Approval Setup
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // [GIVEN] Purchase Order created with Purchase Line containing Over-Receipt Code
        CreatePurchDocument(PurchHeader, LibraryRandom.RandIntInRange(10, 50));
        LibraryPurchase.FindFirstPurchLine(PurchLine, PurchHeader);
        PurchLine.Validate("Over-Receipt Code", CreateOverReceiptCode());
        PurchLine.Validate("Over-Receipt Approval Status", PurchLine."Over-Receipt Approval Status"::Pending);
        PurchLine.Modify(true);

        // [GIVEN] Purchase Order sent for approval
        SendPurchaseOrderForApproval(PurchHeader);
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::"Pending Approval");
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, PurchHeader);

        // [WHEN] Purchase Order is approved
        ApprovePurchaseOrder(PurchHeader);

        // [THEN] Purchase Order status = Released and Purchase Line "Over-Receipt Approval Status" = Approved
        VerifyPurchaseDocumentStatus(PurchHeader, PurchHeader.Status::Released);
        LibraryPurchase.FindFirstPurchLine(PurchLine, PurchHeader);
        PurchLine.TestField("Over-Receipt Approval Status", PurchLine."Over-Receipt Approval Status"::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ApprovalEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDetailtextonApprovalEntryPageFromPurchOrder()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalUserSetup: Record "User Setup";
    begin
        // [SCENARIO 453092] The amount of the initial Details on the approval entries is updating with new approval amount. 
        Initialize();

        // [GIVEN] Purchase Order Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        //  and Purchase Order is sent for approval.
        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalUserSetup, PurchaseHeader);

        // [VERIFY] Verify Purchase Order status is set to Pending Approval
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");

        // [VERIFY] Verify Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        // [VERIFY] Approval Entry created correctly
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, UserId, IntermediateApproverUserSetup."User ID", ApprovalEntry.Status::Open);

        // [THEN] Cancel the approval request
        CancelPurchaseOrder(PurchaseHeader);

        // [THEN] Update purchase amount on line.
        UpdatePurchaseAmountOnLine(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // [THEN] Send For approval after changing the purchase order value.
        SendPurchaseOrderForApproval(PurchaseHeader);

        // [THEN] Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);

        // [VERIFY] Verify the Detail text on Approval entries page. 
        CheckDetailTextForDocumentOnApprovalEntriesPage(ApprovalEntry, PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyStatusMustBeOpenOfOnlyOneApprovalEntriesForWorkflowUserGroup()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        UserSetup: array[10] of Record "User Setup";
        NoOfUser: Integer;
    begin
        // [SCENARIO 492509] Verify that the status must be open for only one approval entry for the Workflow User Group.
        Initialize();

        // [GIVEN] A generated number of users should be added to the workflow user group.
        NoOfUser := LibraryRandom.RandIntInRange(7, 10);

        // [GIVEN] Created a workflow for the purchase order with an approval-type workflow user group.
        CreatePurchaseOrderDocApprovalWorkflow(Workflow, CurrentUserSetup, UserSetup, NoOfUser);

        // [GIVEN] Create a purchase document.
        CreatePurchDocument(PurchaseHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // [WHEN] Send a purchase order for approval.
        SendPurchaseOrderForApproval(PurchaseHeader);

        // [GIVEN] Verify that the status of the purchase order is pending approval.
        VerifyPurchaseDocumentStatus(PurchaseHeader, PurchaseHeader.Status::"Pending Approval");

        // [VERIFY] Verify that the status must be open for only one approval entry for the Workflow User Group.
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.SetRange("Record ID to Approve", PurchaseHeader.RecordId());
        Assert.RecordCount(ApprovalEntry, 1);
    end;

    local procedure SendDocumentForApproval(var Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup"; var PurchHeader: Record "Purchase Header")
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, chain the users for approval, set purchase amount limits
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create purchase order where amount will lead to 3 approval requests
        CreatePurchDocument(PurchHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Excercise - Open Purchase order card and sent it for approval
        SendPurchaseOrderForApproval(PurchHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerValidateMessage(Message: Text[1024])
    var
        Variant: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        Assert.ExpectedMessage(Variant, Message)
    end;

    local procedure CreateUserSetupsAndChainOfApprovers(var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    begin
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        CurrentUserSetup.Get(UserId);
        SetPurchaseAmountApprovalLimits(CurrentUserSetup, LibraryRandom.RandIntInRange(1, 100));
        SetLimitedPurchaseApprovalLimits(CurrentUserSetup);

        SetPurchaseAmountApprovalLimits(IntermediateApproverUserSetup, LibraryRandom.RandIntInRange(101, 1000));
        SetLimitedPurchaseApprovalLimits(IntermediateApproverUserSetup);

        FinalApproverUserSetup.Get(IntermediateApproverUserSetup."Approver ID");
        SetPurchaseAmountApprovalLimits(FinalApproverUserSetup, 0);
        SetUnlimitedPurchaseApprovalLimits(FinalApproverUserSetup);
    end;

    local procedure SetPurchaseAmountApprovalLimits(var UserSetup: Record "User Setup"; PurchaseApprovalLimit: Integer)
    begin
        UserSetup."Purchase Amount Approval Limit" := PurchaseApprovalLimit;
        UserSetup.Modify(true);
    end;

    local procedure SetUnlimitedPurchaseApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Purchase Approval" := true;
        UserSetup.Modify(true);
    end;

    local procedure SetLimitedPurchaseApprovalLimits(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Purchase Approval" := false;
        UserSetup.Modify(true);
    end;

    local procedure CreatePurchDocument(var PurchHeader: Record "Purchase Header"; Amount: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, '', 1);
        PurchLine.Validate("Direct Unit Cost", Amount);
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchDocumentForFixedAsset(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; Amount: Decimal)
    var
        PurchLine: Record "Purchase Line";
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"Fixed Asset", FixedAsset."No.", 1);
        PurchLine.Validate("Direct Unit Cost", Amount);
        PurchLine.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure SendPurchaseOrderForApproval(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.SendApprovalRequest.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure ApprovePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.Approve.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure RejectPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.Reject.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure CancelPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.CancelApprovalRequest.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure DelegatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.Delegate.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure UpdateApprovalEntryWithTempUser(UserSetup: Record "User Setup"; PurchaseHeader: Record "Purchase Header")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;

    local procedure VerifyPurchaseDocumentStatus(var PurchaseHeader: Record "Purchase Header"; Status: Enum "Purchase Document Status")
    begin
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField(Status, Status);
    end;

    local procedure VerifyApprovalEntry(ApprovalEntry: Record "Approval Entry"; SenderId: Code[50]; ApproverId: Code[50]; Status: Enum "Approval Status")
    begin
        ApprovalEntry.TestField("Sender ID", SenderId);
        ApprovalEntry.TestField("Approver ID", ApproverId);
        ApprovalEntry.TestField(Status, Status);
    end;

    local procedure VerifyApprovalRequests(PurchaseHeader: Record "Purchase Header"; ExpectedNumberOfApprovalEntries: Integer; SenderUserID: Code[50]; ApproverUserID1: Code[50]; ApproverUserID2: Code[50]; ApproverUserID3: Code[50]; Status1: Enum "Approval Status"; Status2: Enum "Approval Status"; Status3: Enum "Approval Status")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(ExpectedNumberOfApprovalEntries, ApprovalEntry.Count, 'Unexpected number of approval entries found');

        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID1, Status1);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID2, Status2);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID3, Status3);
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(PurchaseHeader: Record "Purchase Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        PurchaseOrder: TestPage "Purchase Order";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        Assert.AreEqual(CommentActionIsVisible, PurchaseOrder.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            PurchaseOrder.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        PurchaseOrder.Close();
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
        Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

        ApprovalComments.Close();

        ApprovalEntries.Close();
    end;

    local procedure CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry: Record "Approval Entry"; NumberOfExpectedComments: Integer)
    var
        ApprovalComments: TestPage "Approval Comments";
        RequeststoApprove: TestPage "Requests to Approve";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);

        RequeststoApprove.Comments.Invoke();
        if ApprovalComments.First() then
            repeat
                NumberOfComments += 1;
            until ApprovalComments.Next();
        Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

        ApprovalComments.Close();

        RequeststoApprove.Close();
    end;

    local procedure CheckUserCanCancelTheApprovalRequest(PurchaseHeader: Record "Purchase Header"; CancelActionExpectedEnabled: Boolean)
    var
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, PurchaseOrder.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        PurchaseOrder.Close();

        PurchaseOrderList.OpenView();
        PurchaseOrderList.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, PurchaseOrderList.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        PurchaseOrderList.Close();
    end;

    local procedure ReinitializeWorkflowsAndCreateWorkflowForPurchaseOrder(var Workflow: Record Workflow; var WorkflowStep: Record "Workflow Step")
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowSetup.InitWorkflow();

        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        WorkflowEvent.Get(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowEvent."Function Name");
        WorkflowStep.FindFirst();
    end;

    local procedure CreateOverReceiptCode(): Code[20]
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        OverReceiptCode.Init();
        OverReceiptCode.Code := LibraryUtility.GenerateRandomCode20(OverReceiptCode.FieldNo(Code), Database::"Over-Receipt Code");
        OverReceiptCode.Description := OverReceiptCode.Code;
        OverReceiptCode."Over-Receipt Tolerance %" := 100;
        OverReceiptCode.Insert();

        exit(OverReceiptCode.Code);
    end;

    local procedure InsertNewWorkflowStepAfter(WorkflowCode: Code[20]; AfterStepFunctioName: Code[128]; StepType: Option; NewStepFunctionName: Code[128])
    var
        WorkflowStep: Record "Workflow Step";
        NewWorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        WorkflowStep.SetRange("Function Name", AfterStepFunctioName);
        WorkflowStep.FindFirst();
        NewWorkflowStep.Init();
        NewWorkflowStep."Workflow Code" := WorkflowCode;
        NewWorkflowStep.Type := StepType;
        NewWorkflowStep.Validate("Function Name", NewStepFunctionName);
        NewWorkflowStep.Insert(true);
        WorkflowStep.InsertAfterStep(NewWorkflowStep);
    end;

    local procedure CheckDetailTextForDocumentOnApprovalEntriesPage(ApprovalEntry: Record "Approval Entry"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Canceled);
        ApprovalEntry.SetRange("Document No.", PurchaseHeader."No.");
        ApprovalEntry.FindFirst();
        LibraryVariableStorage.Enqueue(ApprovalEntry.RecordDetails());

        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.Approvals.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure UpdatePurchaseAmountOnLine(PurchaseHeader: Record "Purchase Header"; Amount: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderDocApprovalWorkflow(
        var Workflow: Record Workflow;
        var CurrentUserSetup: Record "User Setup";
        var UserSetup: array[10] of Record "User Setup";
        NoOfUsers: Integer)
    var
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowSetup: Codeunit "Workflow Setup";
        i: Integer;
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, Format(UserId()));
        LibraryDocumentApprovals.CreateWorkflowUserGroup(WorkflowUserGroup);
        for i := 1 to NoOfUsers - 1 do
            LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup[i]);

        for i := 1 to NoOfUsers do
            if i = 3 then
                LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, CurrentUserSetup."User ID", i)
            else
                if i > 3 then
                    LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, UserSetup[i - 1]."User ID", i)
                else
                    LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, UserSetup[i]."User ID", i);

        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ApprovalEntriesPageHandler(var ApprovalEntries: TestPage "Approval Entries")
    var
        ApprovalEntry: Record "Approval Entry";
        DeatilsText: Variant;
        AEDeatilsText: Text;
    begin
        LibraryVariableStorage.Dequeue(DeatilsText);
        ApprovalEntries.Filter.SetFilter(Status, Format(ApprovalEntry.Status::Canceled));
        if ApprovalEntries.First() then
            repeat
                AEDeatilsText := ApprovalEntries.Details.Value();
                Assert.AreEqual(DeatilsText, AEDeatilsText, '')
            until ApprovalEntries.Next();
        ApprovalEntries.Close();
    end;
}

