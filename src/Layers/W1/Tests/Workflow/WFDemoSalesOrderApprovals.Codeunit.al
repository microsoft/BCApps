codeunit 134175 "WF Demo Sales Order Approvals"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Fixed Asset" = im;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Sales] [Order]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        DocCannotBeReleasedErr: Label 'This document can only be released when the approval process is complete.';
        DocCannotBePostedErr: Label '%1 %2 must be approved and released before you can perform this action.', Comment = '%1 = SalesHeader."Document Type", %2 = SalesHeader."No."';
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;
        DynamicRequestPageParametersTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Sales Header">SORTING(Field1,Field3) WHERE(Field1=1(1),Field120=1(0))</DataItem><DataItem name="Sales Line">SORTING(Field1,Field3,Field4) WHERE(Field5=1(%1))</DataItem></DataItems></ReportParameters>', Locked = true;
        InvoiceDiscExpectedErr: Label 'Validation error for Field: Invoice Disc. Pct.,  Message = Status must be equal to Open  in Sales Header: Document Type=Order, No.=%1. Current value is Pending Approval';

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo Sales Order Approvals");
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        UserSetup.DeleteAll();
        LibraryWorkflow.DisableAllWorkflows();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo Sales Order Approvals");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo Sales Order Approvals");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostSalesOrder()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] The user cannot post a Sales order when the approval workflow is enabled and the Sales order is not approved and released.
        // [GIVEN] There is a Sales order that is not approved and released.
        // [GIVEN] The approval workflow for puchase order is enabled.
        // [WHEN] The user wants to Post the Sales order.
        // [THEN] The user will get an error that he cannot post a Sales order that is not approved and released.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        asserterror SalesOrder.Post.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBePostedErr, SalesHeader."Document Type", SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesOrder()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] The user cannot release a Sales order when the approval workflow is enabled and the Sales order is not approved.
        // [GIVEN] There is a Sales order that is not approved.
        // [GIVEN] The approval workflow for puchase order is enabled.
        // [WHEN] The user wants to Release the Sales order.
        // [THEN] The user will get an error that he cannot release a Sales order that is not approved.

        // Setup
        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Exercise
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        asserterror SalesOrder.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] The user cannot release a sales order when the approval workflow is enabled and the sales order is pending approval.
        // [GIVEN] There is a sales order that is sent for approval.
        // [GIVEN] The approval workflow for sales orders is enabled.
        // [WHEN] The user wants to Release the sales order.
        // [THEN] The user will get an error that he cannot release the sales order that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Person code for sales order
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Setup - Update  Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open sales order card and sent it for approval
        SendSalesOrderForApproval(SalesHeader);

        // Verify - Sales order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Exercise
        Commit();
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        asserterror SalesOrder.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(SalesHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenSalesOrderApprovalIsPending()
    var
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] The user cannot release a sales order when the approval workflow is enabled and the sales order is pending approval.
        // [GIVEN] There is a sales order that is sent for approval.
        // [GIVEN] The approval workflow for sales orders is enabled.
        // [WHEN] The user wants to Reopen the sales order.
        // [THEN] The user will get an error that he cannot reopen the sales order.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create sales order
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Setup - Update Sales person Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open sales order card and sent it for approval
        SendSalesOrderForApproval(SalesHeader);

        // Verify - Sales order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Exercise
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        asserterror SalesOrder.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderApprovalWorkflow()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 1] Test that the Sales Order Approval Workflow approval path works with a chain of approvers of 3 users.
        // [GIVEN] The Sales Order Approval Workflow is enabled.
        // [WHEN] A user sends the Sales order for approval and all users in the chain of approvals approve the document.
        // [THEN] The Sales order is approved and released.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);

        // Verify - Sales order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."User ID", IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID", ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales order card and approve the approval request
        ApproveSalesOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Set the approverid to USERID so that it can be approved
        ApproveSalesOrder(SalesHeader);

        // Verify - Sales order is approved and released
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Released);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderApprovalWorkflowRejectionPathLastApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 2] Test that the Sales Order Approval Workflow rejection path works with a chain of approvers of 3 users.
        // [GIVEN] The Sales Order Approval Workflow is enabled.
        // [WHEN] A user sends the Sales order for approval, the first approver approves it and last approver rejects it.
        // [THEN] The Sales order is rejected and open.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);

        // Verify - Sales order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."User ID", IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID", ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Salesae order card and approve the approval request
        ApproveSalesOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Set the approverid to USERID so that it can be rejected
        RejectSalesOrder(SalesHeader);

        // Verify - Sales order is rejected and open
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Open);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderApprovalWorkflowRejectionPathFirstApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 3] Test that the Sales Order Approval Workflow rejection path works with a chain of approvers of 3 users.
        // [GIVEN] The Sales Order Approval Workflow is enabled.
        // [WHEN] A user sends the Sales order for approval and the first approver rejects it.
        // [THEN] The Sales order is rejected and open.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);

        // Verify - Sales order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."User ID", IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID", ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be rejected
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Sales order card and reject it
        RejectSalesOrder(SalesHeader);

        // Verify - Sales order is rejected and open
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Open);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderApprovalWorkflowCancelation()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 5] Test that the Sales Order Approval Workflow rejection path works with a chain of approvers of 3 users.
        // [GIVEN] The Sales Order Approval Workflow is enabled.
        // [WHEN] A user sends the Sales order for approval and then the user cancels it.
        // [THEN] The Sales order is canceled and open.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);

        // Verify - Sales order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."User ID", IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID", ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Cancel the approval request
        CancelSalesOrder(SalesHeader);

        // Verify - Sales order is canceled and open
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Open);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderApprovalWorkflowDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 6] Test that the Sales Order Approval Workflow delegation path works with a chain of approvers of 3 users and one delegate.
        // [GIVEN] The Sales Order Approval Workflow is enabled.
        // [WHEN] A user sends the Sales order for approval and the second user delegates the approval to the 3rd user and the last user approves it.
        // [THEN] The Sales order is approved and released.

        Initialize();

        SendDocumentForApproval(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup, SalesHeader);

        // Verify - Sales order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."User ID", IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID", ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Excercise - Open Salesae order card and approve the approval request
        ApproveSalesOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Delegate the Sales order
        DelegateSalesOrder(SalesHeader);

        // Exercise - Set the approver id
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Exercise - Approve the Sales order
        ApproveSalesOrder(SalesHeader);

        // Verify - Sales order is approved and released
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Released);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(SalesHeader, 2, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestSalesOrderApprovalActionsVisibilityOnCard()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror SalesOrder.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        SalesOrder.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // [WHEN] SalesHeader card is opened.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(SalesOrder.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(SalesOrder.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(SalesOrder.Delegate.Visible(), 'Delegate should NOT be visible');
        SalesOrder.Close();

        // [GIVEN] Approval exist on SalesHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        SalesOrder.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(SalesOrder.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesOrder.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        SalesOrder.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // [WHEN] SalesHeader card is opened.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(SalesOrder.Approve.Visible(), 'Approva should be visible');
        Assert.IsTrue(SalesOrder.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(SalesOrder.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestSalesOrderApprovalActionsVisibilityOnList()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] SalesHeader approval disabled.
        Initialize();

        // [WHEN] SalesHeader card is opened.
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();
        SalesOrderList.OpenEdit();
        SalesOrderList.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror SalesOrderList.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        SalesOrderList.Close();

        // [GIVEN] SalesHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // [WHEN] SalesHeader card is opened.
        SalesOrderList.OpenEdit();
        SalesOrderList.GotoRecord(SalesHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(SalesOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(SalesOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        SalesOrderList.Close();

        // [GIVEN] Approval exist on SalesHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");
        SalesOrderList.OpenEdit();
        SalesOrderList.GotoRecord(SalesHeader);

        // [WHEN] SalesHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        SalesOrderList.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(SalesOrderList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(SalesOrderList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderWorkflowTableRelationSetup()
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO 379202] Test Workflow Table Relations for Sales Order
        // [WHEN] Init Workflow Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowSetup.InitWorkflow();

        // [THEN] Workflow Table Relations for Sales Order exist
        WorkflowTableRelation.Get(
          DATABASE::"Sales Header", SalesHeader.FieldNo("Document Type"),
          DATABASE::"Sales Line", SalesLine.FieldNo("Document Type"));
        WorkflowTableRelation.Get(
          DATABASE::"Sales Header", SalesHeader.FieldNo("No."),
          DATABASE::"Sales Line", SalesLine.FieldNo("Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseSalesOrderForItemFilteringForApprovalsOnFixedAsset()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WorkflowStepArgument: Record "Workflow Step Argument";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [SCENARIO 379202] Release Sales Order of Item when SOAP workflow filtering on Fixed Asset
        Initialize();

        // [GIVEN] Workflow on Sales Order Approval Template
        ReinitializeWorkflowsAndCreateWorkflowForSalesOrder(Workflow, WorkflowStep);

        // [GIVEN] Filtering Workflow sales lines on Type = Fixed Asset
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.SetEventFilters(StrSubstNo(DynamicRequestPageParametersTxt, SalesLine.Type::"Fixed Asset"));

        // [GIVEN] Workflow enabled
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Sales Order on Item
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // [WHEN] Release Sales Order
        SalesOrderList.OpenView();
        SalesOrderList.GotoRecord(SalesHeader);
        SalesOrderList.Release.Invoke();

        // [THEN] Sales Order Status = Released
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseSalesOrderForFixedAssetFilteringForApprovalsOnFixedAsset()
    var
        WorkflowStep: Record "Workflow Step";
        Workflow: Record Workflow;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WorkflowStepArgument: Record "Workflow Step Argument";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [SCENARIO 379202] Release Sales Order of Fixed Asset errors when SOAP workflow filtering on Fixed Asset
        Initialize();

        // [GIVEN] Workflow on Sales Order Approval Template
        ReinitializeWorkflowsAndCreateWorkflowForSalesOrder(Workflow, WorkflowStep);

        // [GIVEN] Filtering Workflow sales lines on Type = Fixed Asset
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.SetEventFilters(StrSubstNo(DynamicRequestPageParametersTxt, SalesLine.Type::"Fixed Asset"));

        // [GIVEN] Workflow enabled
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Sales Order on Fixed Asset
        CreateSalesDocumentForFixedAsset(SalesHeader, SalesHeader."Document Type"::Order, LibraryRandom.RandIntInRange(5000, 10000));

        // [WHEN] Release Sales Order
        SalesOrderList.OpenView();
        SalesOrderList.GotoRecord(SalesHeader);
        asserterror SalesOrderList.Release.Invoke();

        // [THEN] Error "This document can only be released when the approval process is complete."
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales Order approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Sales Order Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Order is sent for approval.
        // [THEN] Approval Request is created for the Salesperson and the user can add a comment.
        // [WHEN] Salesperson approves the approval request.
        // [THEN] Sales Order is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Order
        CreateSalesOrder(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Excercise - Open Sales Order card and sent it for approval
        SendSalesOrderForApproval(SalesHeader);

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, false);

        // Verify - Sales Order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntry(ApprovalEntry, UserId, IntermediateApproverUserSetup."User ID", ApprovalEntry.Status::Open);

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        CheckCommentsForDocumentOnDocumentCard(SalesHeader, 0, true);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Excercise - Open Sales Order card and approve the approval request
        ApproveSalesOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Released);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntry(ApprovalEntry, IntermediateApproverUserSetup."User ID", UserId, ApprovalEntry.Status::Approved);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderApprovalWorkflowTestUserCanCancel()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        IntermediateApproverUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Sales Order approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Sales Order Approval Workflow that has Salesperson as the approver and No Limit as the limit type.
        // [WHEN] Sales Order is sent for approval.
        // [THEN] Approval Request is created for the Salesperson and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Sales Order
        CreateSalesOrder(SalesHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales Order card and sent it for approval
        SendSalesOrderForApproval(SalesHeader);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, true);

        // Verify - Sales Order status is set to Pending Approval
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::"Pending Approval");

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntry(ApprovalEntry, UserId, IntermediateApproverUserSetup."User ID", ApprovalEntry.Status::Open);

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // Verify - User Cannot cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, false);

        // Setup
        LibraryDocumentApprovals.CreateOrFindUserSetup(UserSetup, UserId);
        LibraryDocumentApprovals.SetAdministrator(UserSetup);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(SalesHeader, true);

        // Excercise - Open Sales Order card and cancel the approval request
        CancelSalesOrder(SalesHeader);

        // Verify - Approval requests and their data
        VerifySalesDocumentStatus(SalesHeader, SalesHeader.Status::Open);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntry(ApprovalEntry, IntermediateApproverUserSetup."User ID", UserId, ApprovalEntry.Status::Canceled);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CheckSalesOrderApprovalWorkflowApproveCalcDiscount()
    var
        ApprovalEntry: Record "Approval Entry";
        IntermediateApproverUserSetup: Record "User Setup";
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO 595808] Check Sales Order Approval Workflow Approve Process When Calc Inv. Discount True.
        Initialize();

        // [GIVEN] Created And Enabled Sales Order Approval Workflow.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // [GIVEN] Setup - Create approval usersetups.
        SetupUsersForApprovals(IntermediateApproverUserSetup);

        // [GIVEN] Enable Calc. Inv. Discount in Sales & Receivables Setup.
        SalesAndReceivablesSetup.Get();
        SalesAndReceivablesSetup.Validate("Calc. Inv. Discount", true);
        SalesAndReceivablesSetup.Modify(true);

        // [GIVEN] Setup - Create Sales Order.
        CreateSalesOrder(SalesHeader, LibraryRandom.RandInt(5000));

        // [WHEN] Excercise - Open Sales Order card and sent it for approval
        SendSalesOrderForApproval(SalesHeader);

        // [THEN] Verify - Sales Order status is set to Pending Approval
        VerifySalesDocumentStatusCheck(SalesHeader, SalesHeader.Status::"Pending Approval");

        // [THEN] Verify - Approval requests and their data
        GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        // [THEN] Verify - Approval entry for Status Open.
        VerifyApprovalEntry(ApprovalEntry, UserId, IntermediateApproverUserSetup."User ID", ApprovalEntry.Status::Open);

        // [WHEN] Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);

        // [WHEN] Excercise - Open Sales Order card and approve the approval request
        ApproveSalesOrder(SalesHeader);

        // [THEN] Verify - Approval requests and their data.
        VerifySalesDocumentStatusCheck(SalesHeader, SalesHeader.Status::Released);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        VerifyApprovalEntry(ApprovalEntry, IntermediateApproverUserSetup."User ID", UserId, ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CheckSalesInvoiceDiscountFieldDisableifOrderStatusPendingApproval()
    var
        ApprovalEntry: Record "Approval Entry";
        IntermediateApproverUserSetup: Record "User Setup";
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        SalesOrderPage: TestPage "Sales Order";
        ErrorText: Text;
    begin
        // [SCENARIO 595808] Check Sales Order Invoice Discount Field must give Error while Status is Pending Approval.
        Initialize();

        // [GIVEN] Created And Enabled Sales Order Approval Workflow.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // [GIVEN] Setup - Create approval usersetups.
        SetupUsersForApprovals(IntermediateApproverUserSetup);

        // [GIVEN] Enable Calc. Inv. Discount in Sales & Receivables Setup.
        SalesAndReceivablesSetup.Get();
        SalesAndReceivablesSetup.Validate("Calc. Inv. Discount", true);
        SalesAndReceivablesSetup.Modify(true);

        // [GIVEN] Setup - Create Sales Order.
        CreateSalesOrder(SalesHeader, LibraryRandom.RandInt(5000));

        // [WHEN] Excercise - Open Sales Order card and sent it for approval
        SendSalesOrderForApproval(SalesHeader);

        // [THEN] Verify - Sales Order status is set to Pending Approval
        VerifySalesDocumentStatusCheck(SalesHeader, SalesHeader.Status::"Pending Approval");

        // [THEN] Verify - Approval requests and their data
        GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        // [THEN] Verify - Approval entry for Status Open.
        VerifyApprovalEntry(ApprovalEntry, UserId, IntermediateApproverUserSetup."User ID", ApprovalEntry.Status::Open);

        // [THEN] Verify ExpectedError.
        SalesOrderPage.OpenEdit();
        SalesOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");
        asserterror SalesOrderPage.SalesLines."Invoice Disc. Pct.".Value(Format(10));
        ErrorText := GetLastErrorText();
        assert.Equal(StrSubstNo(InvoiceDiscExpectedErr, SalesHeader."No."), ErrorText);
    end;

    local procedure SendDocumentForApproval(var Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup"; var SalesHeader: Record "Sales Header")
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        // Setup - Create 3 user setups, chain the users for approval, set Sales amount limits
        LibraryDocumentApprovals.SetupUsersForApprovalsWithLimits(CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create Sales order where amount will lead to 3 approval requests
        CreateSalesOrder(SalesHeader, LibraryRandom.RandIntInRange(5000, 10000));

        // Setup - Update Salesperson Code
        SetSalesDocSalespersonCode(SalesHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Sales order card and sent it for approval
        SendSalesOrderForApproval(SalesHeader);
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

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
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

    local procedure SendSalesOrderForApproval(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SendApprovalRequest.Invoke();
        SalesOrder.Close();
    end;

    local procedure ApproveSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.Approve.Invoke();
        SalesOrder.Close();
    end;

    local procedure RejectSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.Reject.Invoke();
        SalesOrder.Close();
    end;

    local procedure CancelSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.CancelApprovalRequest.Invoke();
        SalesOrder.Close();
    end;

    local procedure DelegateSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.Delegate.Invoke();
        SalesOrder.Close();
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

    local procedure VerifyApprovalRequests(SalesHeader: Record "Sales Header"; ExpectedNumberOfApprovalEntries: Integer; SenderUserID: Code[50]; ApproverUserID1: Code[50]; ApproverUserID2: Code[50]; Status1: Enum "Approval Status"; Status2: Enum "Approval Status")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, SalesHeader.RecordId);
        Assert.AreEqual(ExpectedNumberOfApprovalEntries, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID1, Status1);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID2, Status2);
    end;

    local procedure SetSalesDocSalespersonCode(SalesHeader: Record "Sales Header"; SalespersonCode: Code[20])
    begin
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(SalesHeader: Record "Sales Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        SalesOrderPage: TestPage "Sales Order";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        SalesOrderPage.OpenView();
        SalesOrderPage.GotoRecord(SalesHeader);

        Assert.AreEqual(CommentActionIsVisible, SalesOrderPage.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            SalesOrderPage.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        SalesOrderPage.Close();
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
        SalesOrder: TestPage "Sales Order";
        SalesOrderList: TestPage "Sales Order List";
    begin
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, SalesOrder.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        SalesOrder.Close();

        SalesOrderList.OpenView();
        SalesOrderList.GotoRecord(SalesHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, SalesOrderList.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        SalesOrderList.Close();
    end;

    local procedure CreateSalesDocumentForFixedAsset(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
        FixedAsset: Record "Fixed Asset";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FixedAsset."No.", 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure ReinitializeWorkflowsAndCreateWorkflowForSalesOrder(var Workflow: Record Workflow; var WorkflowStep: Record "Workflow Step")
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowSetup.InitWorkflow();

        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        WorkflowEvent.Get(WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowEvent."Function Name");
        WorkflowStep.FindFirst();
    end;

    local procedure GetApprovalEntries(var ApprovalEntry: Record "Approval Entry"; RecordID: RecordID)
    begin
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.FindSet();
    end;

    local procedure VerifySalesDocumentStatusCheck(var SalesHeader: Record "Sales Header"; Status: Enum "Sales Document Status")
    begin
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
        SalesHeader.TestField(Status, Status);
    end;

    Local procedure SetupUsersForApprovals(var IntermediateApproverUserSetup: Record "User Setup")
    var
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, IntermediateApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);
    end;

    Local procedure CreateOrFindUserSetup(var UserSetup: Record "User Setup"; UserName: Text[208])
    begin
        if not LibraryDocumentApprovals.GetUserSetup(UserSetup, CopyStr(UserName, 1, 50)) then
            LibraryDocumentApprovals.CreateUserSetupWithEmail(UserSetup, CopyStr(UserName, 1, 50), '', CopyStr(RandomEmail(), 1, MaxStrLen(UserSetup."E-Mail")));
    end;

    local procedure RandomEmail(): Text[250]
    begin
        exit(StrSubstNo('%1@contoso.com', CreateGuid()));
    end;
}

