codeunit 134205 "WF Demo Customer Approval"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = m;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Approval] [Customer]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';
        NoApprovalCommentExistsErr: Label 'There is no approval comment for this approval entry.';
        ApprovalCommentWasNotDeletedErr: Label 'The approval comment for this approval entry was not deleted.';
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        RecordRestrictedErr: Label 'You cannot use %1 for this action.', Comment = 'You cannot use Customer 10000 for this action.';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SendCustomerForApprovalTest()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 1] A user can send a newly created customer for approval.
        // [GIVEN] A new  Customer.
        // [WHEN] The user send an approval request from the customer.
        // [THEN] The Approval flow gets started.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());

        // Exercise - New Customer
        LibrarySales.CreateCustomer(Customer);

        // Exercise - Send for approval
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Customer.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Customer);

        // Rollback
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelCustomerApprovalRequestTest()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 2] A user can cancel a approval request.
        // [GIVEN] Existing approval.
        // [WHEN] The user cancel a approval request.
        // [THEN] The Approval flow is canceled.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());

        // Setup - an existing approval
        LibrarySales.CreateCustomer(Customer);
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();

        // Exercise
        CustomerCard.CancelApprovalRequest.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Customer.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Canceled, Customer);

        // Rollback
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RenameCustomerAfterApprovalRequestTest()
    var
        Customer: Record Customer;
        NewCustomer: Record Customer;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
        NewCustomerNo: Text;
    begin
        // [SCENARIO 9] A user can rename a customer after they send it for approval and the approval requests
        // still point to the same record.
        // [GIVEN] Existing approval.
        // [WHEN] The user renames a customer.
        // [THEN] The approval entries are renamed to point to the same record.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());

        // Setup - an existing approval
        LibrarySales.CreateCustomer(Customer);
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Customer.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Customer);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise - Create a new customer and delete it to reuse the customer No.
        LibrarySales.CreateCustomer(NewCustomer);
        NewCustomerNo := NewCustomer."No.";
        NewCustomer.Delete(true);
        Customer.Rename(NewCustomerNo);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, NewCustomer.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Customer);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Rollback
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteCustomerAfterApprovalRequestTest()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalUserSetup: Record "User Setup";
        WorkflowStepInstance: Record "Workflow Step Instance";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 8] A user can delete a customer and the existing approval requests will be canceled and then deleted.
        // [GIVEN] Existing approval.
        // [WHEN] The user deletes the customer.
        // [THEN] The customer approval requests are canceled and then the customer is deleted.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());

        // Setup - an existing approval
        LibrarySales.CreateCustomer(Customer);
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();
        CustomerCard.OK().Invoke();

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Customer.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Customer);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise
        Customer.Delete(true);

        // Verify
        Assert.IsTrue(ApprovalEntry.IsEmpty, 'There are still approval entries for the record');
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
        Assert.IsFalse(ApprovalCommentExists(ApprovalEntry), ApprovalCommentWasNotDeletedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure CustomerApprovalActionsVisibilityOnCardTest()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] Customer approval disabled.
        Initialize();

        // [WHEN] Customer card is opened.
        LibrarySales.CreateCustomer(Customer);
        Commit();
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [THEN] Send and Cancel are disabled.
        Assert.IsFalse(CustomerCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsFalse(CustomerCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // Cleanup
        CustomerCard.Close();

        // [GIVEN] Customer approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());

        // [WHEN] Customer card is opened.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(CustomerCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(CustomerCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(CustomerCard.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(CustomerCard.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(CustomerCard.Delegate.Visible(), 'Delegate should NOT be visible');
        CustomerCard.Close();

        // [GIVEN] Approval exist on Customer.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Customer send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        CustomerCard.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(CustomerCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(CustomerCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        CustomerCard.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Customer.RecordId);

        // [WHEN] Customer card is opened.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [THEN] Approval action are shown.
        Assert.IsTrue(CustomerCard.Approve.Visible(), 'Approve should be visible');
        Assert.IsTrue(CustomerCard.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(CustomerCard.Delegate.Visible(), 'Delegate should be visible');

        // Rollback
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure CustomerApprovalActionsVisibilityOnListTest()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        CustomerList: TestPage "Customer List";
    begin
        // [SCENARIO 4] Approval action availability.
        // [GIVEN] Customer approval disabled.
        Initialize();

        // [WHEN] Customer card is opened.
        LibrarySales.CreateCustomer(Customer);
        Commit();
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [THEN] Only Send is enabled.
        Assert.IsFalse(CustomerList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsFalse(CustomerList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // Cleanup
        CustomerList.Close();

        // [GIVEN] Customer approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());

        // [WHEN] Customer card is opened.
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(CustomerList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(CustomerList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        CustomerList.Close();

        // [GIVEN] Approval exist on Customer.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [WHEN] Customer send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        CustomerList.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(CustomerList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(CustomerList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Rollback
        CustomerList.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApproveCustomerTest()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 5] A user can approve a customer approval.
        // [GIVEN] A Customer Approval.
        // [WHEN] The user approves a request for customer approval.
        // [THEN] The Customer gets approved.
        Initialize();

        // Setup
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());
        LibrarySales.CreateCustomer(Customer);

        // Setup - A approval
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();
        CustomerCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Customer.RecordId);

        // Exercise
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.Approve.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Customer.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Approved, Customer);

        // Rollback
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RejectCustomerTest()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ApprovalUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 6] A user can reject a customer approval.
        // [GIVEN] A Customer Approval.
        // [WHEN] The user rejects a request for customer approval.
        // [THEN] The Customer gets rejected.
        Initialize();

        // Setup
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());
        LibrarySales.CreateCustomer(Customer);

        // Setup - A approval
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();
        CustomerCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Customer.RecordId);

        // Exercise
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.Reject.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Customer.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Rejected, Customer);

        // Rollback
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DelegateCustomerTest()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        CurrentUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 7] A user can delegate a customer approval.
        // [GIVEN] A Customer Approval.
        // [WHEN] The user delegates a request for customer approval.
        // [THEN] The Customer gets assigned to the substitute.
        Initialize();

        // Setup
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, ApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, ApproverUserSetup);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());
        LibrarySales.CreateCustomer(Customer);

        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();
        CustomerCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Customer.RecordId);

        // Exercise
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.Delegate.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Customer.RecordId);
        ApprovalEntry.TestField("Approver ID", ApproverUserSetup."User ID");
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Customer);

        // Rollback
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SendCustomerForApprovalRestrictsUsageTest()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 8] A newly created customer that is sent for approval cannot be used.
        // [GIVEN] A new  Customer.
        // [WHEN] The user sends an approval request from the customer.
        // [THEN] Any sales document using the customer cannot be posted.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', WorkDate());

        // Exercise.
        Commit();
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();

        // Verify.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(Customer.RecordId, 0, 1)));

        // Rollback
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelCustomerApprovalAllowsUsageTest()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 9] A newly created customer whose approval is canceled can be used.
        // [GIVEN] A new  Customer.
        // [WHEN] The user sends an approval request from the customer.
        // [WHEN] The user then cancels the request.
        // [THEN] Any sales document using the customer can be posted.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', WorkDate());

        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();

        // Exercise.
        CustomerCard.CancelApprovalRequest.Invoke();

        // Verify. No errors.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Rollback
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApproveCustomerApprovalAllowsUsageTest()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 10] A newly created customer that is approved can be used.
        // [GIVEN] A new  Customer.
        // [WHEN] The user sends an approval request from the customer.
        // [WHEN] The request is approved.
        // [THEN] Any sales document using the customer can be posted.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', WorkDate());

        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Customer.RecordId);

        // Exercise.
        CustomerCard.Approve.Invoke();

        // Verify. No errors.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Rollback
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RunCustomerApprovalWorkflowForWorkflowUserGroupWithIncrementalSequence()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        CurrentUserSetup: Record "User Setup";
        ApprovalUserSetup2: Record "User Setup";
        ApprovalUserSetup3: Record "User Setup";
        RestrictedRecord: Record "Restricted Record";
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [FEATURE] [Workflow] [Workflow User Group]
        // [SCENARIO 264151] Run standard Customer Approval Workflow for ApproverType = Workflow User Group with incremental Sequence.
        Initialize();

        // [GIVEN] Customer "CUS".
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Customer Approval Workflow "WF" where Approver Type set as Workflow User Group
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());
        LibraryWorkflow.DisableAllWorkflows();
        LibraryDocumentApprovals.SetWorkflowApproverType(Workflow, WorkflowStepArgument."Approver Type"::"Workflow User Group");

        // [GIVEN] Three approvers for "WF" User1 User2 and User3 added into the Workflow User Group "WG" with the Sequences of 1, 2 and 3, respectively.
        // [GIVEN] "WG" is set into "WF" as Workflow User Group.
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, ApprovalUserSetup2, ApprovalUserSetup3);

        // [GIVEN] "WF" is enabled.
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [WHEN] Customer is sent for approval
        ApprovalsMgmt.OnSendCustomerForApproval(Customer);

        // [THEN] Approval Entry for User1 has Status::Approved.
        FindApprovalEntry(ApprovalEntry, Workflow.Code, CurrentUserSetup."User ID", ApprovalEntry.Status::Approved);

        // [THEN] Approval Entry for User3 has Status::Created.
        FindApprovalEntry(ApprovalEntry, Workflow.Code, ApprovalUserSetup3."User ID", ApprovalEntry.Status::Created);

        // [THEN] Approval Entry for User2 has Status::Open.
        FindApprovalEntry(ApprovalEntry, Workflow.Code, ApprovalUserSetup2."User ID", ApprovalEntry.Status::Open);

        // [WHEN] Approval Entry for User2 is approved.
        UpdateApprovalEntryWithCurrUser(ApprovalEntry);
        ApprovalsMgmt.ApproveRecordApprovalRequest(Customer.RecordId);

        // [THEN] Approval Entry for User3 has Status::Open.
        FindApprovalEntry(ApprovalEntry, Workflow.Code, ApprovalUserSetup3."User ID", ApprovalEntry.Status::Open);

        // [WHEN] Approval Entry for User3 is approved.
        UpdateApprovalEntryWithCurrUser(ApprovalEntry);
        ApprovalsMgmt.ApproveRecordApprovalRequest(Customer.RecordId);

        // [THEN] "WF" completed, i.e. no active Workflow Step Instances exists.
        VerifyWorkflowCompleted(Workflow.Code);

        // [THEN] No Restricted Records exists for "CUS".
        RestrictedRecord.SetRange("Record ID", Customer.RecordId);
        Assert.RecordIsEmpty(RestrictedRecord);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RunCustomerApprovalWorkflowOpenNextWhenOneApproved()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        CurrentUserSetup: Record "User Setup";
        ApprovalUserSetup2: Record "User Setup";
        ApprovalUserSetup3: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [FEATURE] [Workflow] [Workflow User Group]
        // [SCENARIO 318374] Approval Entry has Status::Open when there is approval entry with lower sequence no. approved.
        Initialize();

        // [GIVEN] Customer
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Customer Approval Workflow "WF" where Approver Type set as Workflow User Group
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());
        LibraryWorkflow.DisableAllWorkflows();
        LibraryDocumentApprovals.SetWorkflowApproverType(Workflow, WorkflowStepArgument."Approver Type"::"Workflow User Group");

        // [GIVEN] Three approvers for "WF" User1 User2 and User3 added into the Workflow User Group "WG" with the Sequences of 1, 1 and 2, respectively.
        // [GIVEN] "WG" is set into "WF" as Workflow User Group.
        CreateUserSetupsAndGroupOfApproversForWorkflowTwo(
          Workflow, CurrentUserSetup, ApprovalUserSetup2, ApprovalUserSetup3);

        // [GIVEN] "WF" is enabled.
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [WHEN] Customer is sent for approval
        ApprovalsMgmt.OnSendCustomerForApproval(Customer);

        // [THEN] Approval Entry for User1 has Status::Approved. Approval Entry for User2 has Status::Open.
        FindApprovalEntry(ApprovalEntry, Workflow.Code, CurrentUserSetup."User ID", ApprovalEntry.Status::Approved);
        FindApprovalEntry(ApprovalEntry, Workflow.Code, ApprovalUserSetup2."User ID", ApprovalEntry.Status::Open);
        // [THEN] Approval Entry for User3 has Status::Open.
        FindApprovalEntry(ApprovalEntry, Workflow.Code, ApprovalUserSetup3."User ID", ApprovalEntry.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TriggerOnApproveApprovalRequestWhenApprovalEntryAutoApproved_FlatGroup()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        WorkflowUserGroupMember: Record "Workflow User Group Member";
        CurrentUserSetup: Record "User Setup";
        ApprovalUserSetup2: Record "User Setup";
        ApprovalUserSetup3: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [Workflow] [Workflow User Group]
        // [SCENARIO 264151] When the Customer Approval Workflow has 'On Approve Approval request' event, then it must be triggered when Approval Entry is created and approved by the same user for ApproverType = Workflow Group.
        Initialize();

        // [GIVEN] Customer "CUS"
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRecFilter();

        // [GIVEN] Workflow "WF" with the response 'Approve all approval request' to an event 'An approval request is approved'.
        CustomerApprovalWorkflowWithAutoApproveForEntireGroup(Workflow);

        // [GIVEN] Three approvers for "WF" added into the Workflow User Group "WG".
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, ApprovalUserSetup2, ApprovalUserSetup3);

        // [GIVEN] "WG" group is flat, i.e. have equal Sequence No.
        WorkflowUserGroupMember.ModifyAll("Sequence No.", 1, true);

        // [GIVEN] "WF" is enabled.
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [WHEN] Customer is sent for approval
        ApprovalsMgmt.OnSendCustomerForApproval(Customer);

        // [THEN] Customer is auto-approved as the request sender is inside of "WG"
        // [THEN] All approval entries have Status::Approved.
        VerifyApprovalEntriesApprovedForAllGroupMembers(Workflow);

        // [THEN] "WF" completed, i.e. no active Workflow Step Instances.
        VerifyWorkflowCompleted(Workflow.Code);
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowUserGroupMember: Record "Workflow User Group Member";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo Customer Approval");
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        WorkflowUserGroup.DeleteAll();
        WorkflowUserGroupMember.DeleteAll();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo Customer Approval");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo Customer Approval");
    end;

    [Scope('OnPrem')]
    procedure CreateUserSetupsAndGroupOfApproversForWorkflowTwo(Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    var
        WorkflowUserGroup: Record "Workflow User Group";
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);
        LibraryDocumentApprovals.CreateWorkflowUserGroup(WorkflowUserGroup);

        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, CurrentUserSetup."User ID", 1);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, IntermediateApproverUserSetup."User ID", 1);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, FinalApproverUserSetup."User ID", 2);

        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
    end;

    local procedure CustomerApprovalWorkflowWithAutoApproveForEntireGroup(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        FirstEntryPointEvent: Integer;
        FirstResponse: Integer;
        SecondResponse: Integer;
        SecondEvent: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);
        FirstEntryPointEvent :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode());
        FirstResponse :=
          LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateApprovalRequestsCode(), FirstEntryPointEvent);
        SecondResponse :=
          LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(), FirstResponse);
        SecondEvent :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(), SecondResponse);
        FirstResponse :=
          LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ApproveAllApprovalRequestsCode(), SecondEvent);

        LibraryDocumentApprovals.SetWorkflowApproverType(Workflow, WorkflowStepArgument."Approver Type"::"Workflow User Group");
    end;

    local procedure FindApprovalEntry(var ApprovalEntry: Record "Approval Entry"; WorkflowCode: Code[20]; ApproverID: Code[50]; Status: Enum "Approval Status")
    begin
        ApprovalEntry.SetRange("Approval Code", WorkflowCode);
        ApprovalEntry.SetRange("Approver ID", ApproverID);
        ApprovalEntry.SetRange(Status, Status);
        ApprovalEntry.FindFirst();
    end;

    local procedure AddApprovalComment(ApprovalEntry: Record "Approval Entry")
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.Init();
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        ApprovalCommentLine.SetRange("Workflow Step Instance ID", ApprovalEntry."Workflow Step Instance ID");
        ApprovalCommentLine.Comment := 'Test';
        ApprovalCommentLine.Insert(true);
    end;

    local procedure ApprovalCommentExists(ApprovalEntry: Record "Approval Entry"): Boolean
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        exit(ApprovalCommentLine.FindFirst())
    end;

    local procedure VerifyApprovalEntry(ApprovalEntry: Record "Approval Entry"; Status: Enum "Approval Status"; Customer: Record Customer)
    begin
        ApprovalEntry.TestField("Document Type", ApprovalEntry."Document Type"::" ");
        ApprovalEntry.TestField("Document No.", '');
        ApprovalEntry.TestField("Record ID to Approve", Customer.RecordId);
        ApprovalEntry.TestField("Salespers./Purch. Code", Customer."Salesperson Code");
        ApprovalEntry.TestField(Status, Status);
        ApprovalEntry.TestField("Currency Code", Customer."Currency Code");
        ApprovalEntry.TestField("Available Credit Limit (LCY)", Customer.CalcAvailableCredit());
    end;

    local procedure VerifyApprovalEntriesApprovedForAllGroupMembers(Workflow: Record Workflow)
    var
        WorkflowUserGroupMember: Record "Workflow User Group Member";
        ApprovalEntry: Record "Approval Entry";
    begin
        WorkflowUserGroupMember.FindSet();
        repeat
            ApprovalEntry.Reset();
            ApprovalEntry.SetRange("Approval Code", Workflow.Code);
            ApprovalEntry.SetRange("Approver ID", WorkflowUserGroupMember."User Name");
            ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Approved);
            Assert.RecordIsNotEmpty(ApprovalEntry);
        until WorkflowUserGroupMember.Next() = 0;
    end;

    local procedure VerifyWorkflowCompleted(WorkflowCode: Code[20])
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        WorkflowStepInstance.SetRange("Workflow Code", WorkflowCode);
        Assert.RecordIsEmpty(WorkflowStepInstance);
    end;

    local procedure UpdateApprovalEntryWithCurrUser(var ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry.Modify();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
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
}

