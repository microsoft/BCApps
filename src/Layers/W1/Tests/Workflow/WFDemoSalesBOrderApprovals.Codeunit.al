codeunit 134174 "WF Demo Sales BOrder Approvals"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Sales] [Blanket Order]
    end;

    var
        DocCannotBeReleasedErr: Label 'This document can only be released when the approval process is complete.';
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo Sales BOrder Approvals");
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        UserSetup.DeleteAll();
        LibraryWorkflow.DisableAllWorkflows();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo Sales BOrder Approvals");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo Sales BOrder Approvals");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesBlanketOrder()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        BlanketSalesOrders: TestPage "Blanket Sales Order";
    begin
        // [SCENARIO] The user cannot release a Sales blanket order when the approval workflow is enabled and the Sales banket order is not approved.
        // [GIVEN] There is a Sales blanket order that is not approved.
        // [GIVEN] The approval workflow for puchase blanket order is enabled.
        // [WHEN] The user wants to Release the Sales blanket order.
        // [THEN] The user will get an error that he cannot release a Sales blanket order that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesBlanketOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        CreateSalesBlanketOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        BlanketSalesOrders.OpenView();
        BlanketSalesOrders.GotoRecord(SalesHeader);
        asserterror BlanketSalesOrders.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesBlanketOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [SCENARIO] The user cannot release a sales blanket order  when the approval workflow is enabled and the sales blanket order is pending approval.
        // [GIVEN] There is a sales blanket order that is sent for approval.
        // [GIVEN] The approval workflow for sales blanket orders is enabled.
        // [WHEN] The user wants to Release the sales blanket order.
        // [THEN] The user will get an error that he cannot release the sales blanket order that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesBlanketOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Setup - Create Blanket Sales order
        CreateSalesBlanketOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Excercise - Open Blanket Sales order card and sent it for approval
        SendBlanketSalesOrderForApproval(SalesHeader);

        // Verify - Blanket Sales Order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Exercise
        Commit();
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        asserterror BlanketSalesOrder.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(SalesHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenSalesBlanketOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [SCENARIO] The user cannot release a sales blanket order when the approval workflow is enabled and the sales blanket order is pending approval.
        // [GIVEN] There is a sales blanket order that is sent for approval.
        // [GIVEN] The approval workflow for sales blanket orders is enabled.
        // [WHEN] The user wants to Reopen the sales blanket order.
        // [THEN] The user will get an error that he cannot reopen the sales blanket order.

        // Setup
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesBlanketOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Setup - Create Blanket Sales order
        CreateSalesBlanketOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Excercise - Open Blanket Sales order card and sent it for approval
        SendBlanketSalesOrderForApproval(SalesHeader);

        // Verify - Blanket Sales Order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Exercise
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        asserterror BlanketSalesOrder.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketSalesOrderApprovalWorkflow()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 1] Test that the Blanket Sales Order Approval Workflow approval path works with a group of 3 users.
        // [GIVEN] The Blanket Sales Order Approval Workflow is enabled.
        // [WHEN] A user sends the Sales order for approval and all users in the group of approvals approve the document.
        // [THEN] The blanket Sales order is approved and released.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);

        // Verify - blanket Sales order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open blanket Sales order card and approve the approval request
        ApproveBlanketSalesOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Set the approverid to USERID so that it can be approved
        ApproveBlanketSalesOrder(SalesHeader);

        // Verify - blanket Sales order is approved and released
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Released);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketSalesOrderApprovalWorkflowRejectionPathLastApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 2] Test that the Blanket Sales Order Approval Workflow rejection path works with a group of 3 users.
        // [GIVEN] The Blanket Sales Order Approval Workflow is enabled.
        // [WHEN] A user sends the blanket Sales order for approval, the first approver approves it and last approver rejects it.
        // [THEN] The blanket Sales order is rejected and open.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);

        // Verify - Blanket Sales order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Blanket Sales order card and approve the approval request
        ApproveBlanketSalesOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Set the approverid to USERID so that it can be rejected
        RejectBlanketSalesOrder(SalesHeader);

        // Verify - Blanket Sales Order is rejected and open
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Open);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketSalesOrderApprovalWorkflowRejectionPathFirstApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 3] Test that the Blanket Sales Order Approval Workflow rejection path works with a group of 3 users.
        // [GIVEN] The Blanket Sales Order Approval Workflow is enabled.
        // [WHEN] A user sends the Blanket Sales order for approval and the first approver rejects it.
        // [THEN] The Blanket Sales order is rejected and open.

        Initialize();
        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);

        // Verify - Blanket Sales Order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - reject the Blanket Sales Order
        RejectBlanketSalesOrder(SalesHeader);

        // Verify - Blanket Sales Order is rejected and open
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Open);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketSalesOrderApprovalWorkflowCancelationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 5] Test that the Blanket Sales Order Approval Workflow rejection path works with a group of 3 users.
        // [GIVEN] The Blanket Sales Order Approval Workflow is enabled.
        // [WHEN] A user sends the Blanket Sales order for approval and then the user cancels it.
        // [THEN] The Blanket Sales order is canceled and open.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Cancel the Blanket Sales order
        CancelBlanketSalesOrder(SalesHeader);

        // Verify - Blanket Purcahse Order is canceled and open
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Open);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Canceled,
          ApprovalEntry.Status::Canceled, ApprovalEntry.Status::Canceled);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketSalesOrderApprovalWorkflowDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 6] Test that the Blanket Sales Order Approval Workflow delegation path works with a group of 3 users and one delegate.
        // [GIVEN] The Blanket Sales Order Approval Workflow is enabled.
        // [WHEN] A user sends the Sales order for approval and the second user delegates the approval to the 3rd user and the last user approves it.
        // [THEN] The Blanket Sales order is approved and released.

        Initialize();

        SendDocForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Verify - Blanket Sales Order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Blanket Salesae order card and approve the approval request
        ApproveBlanketSalesOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Delegate the Blanket Sales order
        DelegateBlanketSalesOrder(SalesHeader);

        // Exercise - Set the approver id
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Exercise - Approve the Blanket Sales order
        ApproveBlanketSalesOrder(SalesHeader);

        // Verify - Blanket Sales Order is approved and released
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Released);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderApprovalActionsVisibilityOnCardTest()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        CreateSalesBlanketOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(BlanketSalesOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(BlanketSalesOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror BlanketSalesOrder.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        BlanketSalesOrder.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesBlanketOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [WHEN] SalesHeader card is opened.
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(BlanketSalesOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(BlanketSalesOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(BlanketSalesOrder.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(BlanketSalesOrder.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(BlanketSalesOrder.Delegate.Visible(), 'Delegate should NOT be visible');
        BlanketSalesOrder.Close();

        // [GIVEN] Approval exist on SalesHeader.
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        BlanketSalesOrder.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(BlanketSalesOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(BlanketSalesOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        BlanketSalesOrder.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // [WHEN] SalesHeader card is opened.
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(BlanketSalesOrder.Approve.Visible(), 'Approva should be visible');
        Assert.IsTrue(BlanketSalesOrder.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(BlanketSalesOrder.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderApprovalActionsVisibilityOnListTest()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        BlanketSalesOrders: TestPage "Blanket Sales Orders";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        CreateSalesBlanketOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();
        BlanketSalesOrders.OpenEdit();
        BlanketSalesOrders.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(BlanketSalesOrders.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(BlanketSalesOrders.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror BlanketSalesOrders.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        BlanketSalesOrders.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesBlanketOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [WHEN] SalesHeader card is opened.
        BlanketSalesOrders.OpenEdit();
        BlanketSalesOrders.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(BlanketSalesOrders.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(BlanketSalesOrders.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        BlanketSalesOrders.Close();

        // [GIVEN] Approval exist on SalesHeader.
        BlanketSalesOrders.OpenEdit();
        BlanketSalesOrders.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        BlanketSalesOrders.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(BlanketSalesOrders.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(BlanketSalesOrders.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales Blanket Order approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Sales Blanket Order Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Blanket Order is sent for approval.
        // [THEN] Approval Request is created and the user can add a comment.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales Blanket Order is released.

        Initialize();

        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesBlanketOrderApprovalWorkflowCode());

        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Create Sales Blanket Order
        CreateSalesBlanketOrder(SalesHeader, LibraryRandom.RandInt(5000));

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Excercise - Open Sales Blanket Order card and sent it for approval
        SendBlanketSalesOrderForApproval(SalesHeader);

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Verify - Sales Blanket Order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, UserId, IntermediateApproverUserSetup."User ID", ApprovalEntry.Status::Open);

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, true);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Excercise - Open Sales Blanket Order card and approve the approval request
        ApproveBlanketSalesOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntry(ApprovalEntry, '', CurrentUserSetup."User ID", ApprovalEntry.Status::Approved);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderApprovalWorkflowTestUserCanCancel()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales Blanket Order approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Sales Blanket Order Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Blanket Order is sent for approval.
        // [THEN] Approval Request is created and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesBlanketOrderApprovalWorkflowCode());

        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Create Sales Blanket Order
        CreateSalesBlanketOrder(SalesHeader, LibraryRandom.RandInt(5000));

        // Excercise - Open Sales Blanket Order card and sent it for approval
        SendBlanketSalesOrderForApproval(SalesHeader);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, true);

        // Verify - Sales invoice status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(3, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, UserId, IntermediateApproverUserSetup."User ID", ApprovalEntry.Status::Open);

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Verify - User Cannot cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, false);

        // Setup
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.SetAdministrator(CurrentUserSetup);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, true);

        // Excercise - Open Sales Blanket Order card and cancel the approval request
        CancelBlanketSalesOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Open);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntry(ApprovalEntry, '', CurrentUserSetup."User ID", ApprovalEntry.Status::Canceled);
    end;

    local procedure SendDocForApproval(var Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup"; var SalesHeader: Record "Sales Header")
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesBlanketOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Setup - Create blanket Sales order
        CreateSalesBlanketOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Excercise - Open blanket Sales order card and sent it for approval
        SendBlanketSalesOrderForApproval(SalesHeader);
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

    local procedure CreateSalesBlanketOrder(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure SendBlanketSalesOrderForApproval(var SalesHeader: Record "Sales Header")
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        BlanketSalesOrder.SendApprovalRequest.Invoke();
        BlanketSalesOrder.Close();
    end;

    local procedure ApproveBlanketSalesOrder(var SalesHeader: Record "Sales Header")
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        BlanketSalesOrder.Approve.Invoke();
        BlanketSalesOrder.Close();
    end;

    local procedure RejectBlanketSalesOrder(var SalesHeader: Record "Sales Header")
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        BlanketSalesOrder.Reject.Invoke();
        BlanketSalesOrder.Close();
    end;

    local procedure CancelBlanketSalesOrder(var SalesHeader: Record "Sales Header")
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        BlanketSalesOrder.CancelApprovalRequest.Invoke();
        BlanketSalesOrder.Close();
    end;

    local procedure DelegateBlanketSalesOrder(var SalesHeader: Record "Sales Header")
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        BlanketSalesOrder.Delegate.Invoke();
        BlanketSalesOrder.Close();
    end;

    local procedure VerifySalesDocumentStatus(SalesHeader: Record "Sales Header"; Status: Enum "Sales Document Status")
    begin
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
        SalesHeader.TestField(Status, Status);
    end;

    local procedure VerifyApprovalEntry(ApprovalEntry: Record "Approval Entry"; SenderId: Code[50]; ApproverId: Code[50]; Status: Enum "Approval Status")
    begin
        ApprovalEntry.TestField("Sender ID", SenderId);
        ApprovalEntry.TestField("Approver ID", ApproverId);
        ApprovalEntry.TestField(Status, Status);
    end;

    local procedure VerifyApprovalRequests(SalesHeader: Record "Sales Header"; ExpectedNumberOfApprovalEntries: Integer; SenderUserID: Code[50]; ApproverUserID1: Code[50]; ApproverUserID2: Code[50]; ApproverUserID3: Code[50]; Status1: Enum "Approval Status"; Status2: Enum "Approval Status"; Status3: Enum "Approval Status")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(ExpectedNumberOfApprovalEntries, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID1, Status1);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID2, Status2);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID3, Status3);
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(SalesHeader: Record "Sales Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        NumberOfComments: Integer;
    begin
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.GotoRecord(SalesHeader);

        ApprovalComments.Trap();

        Assert.AreEqual(CommentActionIsVisible, BlanketSalesOrder.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            BlanketSalesOrder.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        BlanketSalesOrder.Close();
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

    local procedure CheckUserCanCancelTheApprovalRequest(SalesHeader: Record "Sales Header"; CancelActionExpectedEnabled: Boolean)
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        BlanketSalesOrders: TestPage "Blanket Sales Orders";
    begin
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, BlanketSalesOrder.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        BlanketSalesOrder.Close();

        BlanketSalesOrders.OpenView();
        BlanketSalesOrders.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, BlanketSalesOrders.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        BlanketSalesOrders.Close();
    end;
}

