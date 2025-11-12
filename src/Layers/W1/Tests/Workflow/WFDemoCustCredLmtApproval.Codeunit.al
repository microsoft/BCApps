codeunit 134190 "WF Demo Cust Cred Lmt Approval"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = m;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Credit Limit]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        if IsInitialized then
            exit;

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerCreditLimitChangeApprovalWorkflow()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Customer: Record Customer;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowSetup: Codeunit "Workflow Setup";
        NewCreditLimit: Decimal;
    begin
        // [SCENARIO 1] Test that the Customer Credit Limit Change Approval Workflow approval path works with a group of 3 users.
        // [GIVEN] The Customer Credit Limit Change Approval Workflow is enabled.
        // [WHEN] A user sends the customer credit limit change for approval and all users in the group of approvals approve the document.
        // [THEN] The customer credit limit change is approved and applied.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Excercise - Open Customer card and sent the credit limit change for approval
        NewCreditLimit := LibraryRandom.RandDec(1000, 2);
        CreateCustomerAndChangeCreditLimitAndSendForApproval(Customer, NewCreditLimit);

        // Verify - Record change for the Customer record was created
        VerifyChangeRecordExists(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Customer);

        // Excercise - Open Customer card and approve the credit limit change
        ApproveCustomerCreditLimitChange(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Open Customer card and approve the credit limit change
        ApproveCustomerCreditLimitChange(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);

        // Verify - Record change for the Customer was deleted
        VerifyChangeRecordDoesNotExist(Customer);

        // Verify - The new credit limit was applied for the record
        VerifyCreditLimitForCustomer(Customer, NewCreditLimit);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerCreditLimitChangeApprovalWorkflowRejectionPathLastApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Customer: Record Customer;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowSetup: Codeunit "Workflow Setup";
        NewCreditLimit: Decimal;
        OldCreditLimit: Decimal;
    begin
        // [SCENARIO 2] Test that the Customer Credit Limit Change Approval Workflow rejection path works with a group of 3 users.
        // [GIVEN] The Customer Credit Limit Change Approval Workflow is enabled.
        // [WHEN] A user sends the customer credit limit change for approval, the first approver approves it and last approver rejects it.
        // [THEN] The customer credit limit change is rejected and the change deleted.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Excercise - Open Customer card and sent the credit limit change for approval
        NewCreditLimit := LibraryRandom.RandDec(1000, 2);
        OldCreditLimit := CreateCustomerAndChangeCreditLimitAndSendForApproval(Customer, NewCreditLimit);

        // Verify - Record change for the Customer record was created
        VerifyChangeRecordExists(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Customer);

        // Excercise - Open Customer card and approve the credit limit change
        ApproveCustomerCreditLimitChange(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Open Customer card and reject the credit limit change
        RejectCustomerCreditLimitChange(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);

        // Verify - Record change for the Customer was deleted
        VerifyChangeRecordDoesNotExist(Customer);

        // Verify - The new credit limit was not applied for the record
        VerifyCreditLimitForCustomer(Customer, OldCreditLimit);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerCreditLimitChangeApprovalWorkflowRejectionPathFirstApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Customer: Record Customer;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowSetup: Codeunit "Workflow Setup";
        NewCreditLimit: Decimal;
        OldCreditLimit: Decimal;
    begin
        // [SCENARIO 3] Test that the Customer Credit Limit Change Approval Workflow rejection path works with a group of 3 users.
        // [GIVEN] The Customer Credit Limit Change Approval Workflow is enabled.
        // [WHEN] A user sends the customer credit limit change for approval and the first approver rejects it.
        // [THEN] The customer credit limit change is rejected and deleted.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Excercise - Open Customer card and sent the credit limit change for approval
        NewCreditLimit := LibraryRandom.RandDec(1000, 2);
        OldCreditLimit := CreateCustomerAndChangeCreditLimitAndSendForApproval(Customer, NewCreditLimit);

        // Verify - Record change for the Customer record was created
        VerifyChangeRecordExists(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Customer);

        // Excercise - Open Customer card and reject the credit limit change
        RejectCustomerCreditLimitChange(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);

        // Verify - Record change for the Customer was deleted
        VerifyChangeRecordDoesNotExist(Customer);

        // Verify - The new credit limit was not applied for the record
        VerifyCreditLimitForCustomer(Customer, OldCreditLimit);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerCreditLimitChangeApprovalWorkflowDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Customer: Record Customer;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowSetup: Codeunit "Workflow Setup";
        NewCreditLimit: Decimal;
    begin
        // [SCENARIO 4] Test that the Customer Credit Limit Change Approval Workflow delegation path works with a group of 3 users and one delegate.
        // [GIVEN] The Customer Credit Limit Change Approval Workflow is enabled.
        // [WHEN] A user sends the customer credit limit change for approval and the second user delegates the approval to the 3rd user and the last user approves it.
        // [THEN] The customer credit limit change is approved and applied.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Excercise - Open Customer card and sent the credit limit change for approval
        NewCreditLimit := LibraryRandom.RandDec(1000, 2);
        CreateCustomerAndChangeCreditLimitAndSendForApproval(Customer, NewCreditLimit);

        // Verify - Record change for the Customer record was created
        VerifyChangeRecordExists(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Customer);

        // Excercise - Open Customer card and approve the credit limit change
        ApproveCustomerCreditLimitChange(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Open Customer card and delegate the credit limit change
        DelegateCustomerCreditLimitChange(Customer);

        // Exercise - Set the approver id
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Customer);

        // Excercise - Open Customer card and approve the credit limit change
        ApproveCustomerCreditLimitChange(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);

        // Verify - Record change for the Customer was deleted
        VerifyChangeRecordDoesNotExist(Customer);

        // Verify - The new credit limit was applied for the record
        VerifyCreditLimitForCustomer(Customer, NewCreditLimit);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestCustomerCreditLimitChangeApprovalActionsVisibilityOnCardTest()
    var
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        Customer: Record Customer;
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowChange: Record Workflow;
        WorkflowApproval: Record Workflow;
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowSetup: Codeunit "Workflow Setup";
        CustomerCard: TestPage "Customer Card";
        OldValue: Decimal;
    begin
        // [SCENARIO 5] Approval action availability.
        // [GIVEN] Customer approval workflow and customer credit limit change approval workflow are disabled.
        Initialize();

        // [WHEN] Customer card is opened.
        LibrarySales.CreateCustomer(Customer);
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [THEN] Send and Cancel are disabled.
        Assert.IsFalse(CustomerCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should NOT be enabled');
        Assert.IsFalse(CustomerCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // Cleanup
        CustomerCard.Close();

        // [GIVEN] Customer credit limit change approval workflow and customer approval workflow are enabled.
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowChange, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowApproval, WorkflowSetup.CustomerWorkflowCode());
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowChange.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowApproval.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(WorkflowChange);
        LibraryWorkflow.EnableWorkflow(WorkflowApproval);

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

        // [WHEN] Customer card is opened.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Customer Credit Limit (LCY) is changed.
        LibraryVariableStorage.Enqueue('The customer credit limit change was sent for approval.');
        Evaluate(OldValue, CustomerCard."Credit Limit (LCY)".Value);
        CustomerCard."Credit Limit (LCY)".Value := Format(OldValue + 100);
        CustomerCard.OK().Invoke();

        // [THEN] The record change was created.
        WorkflowRecordChange.SetRange("Record ID", Customer.RecordId);
        Assert.IsFalse(WorkflowRecordChange.IsEmpty, 'WorkflowRecordChange should not be empty');

        // [WHEN] Customer card is opened.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(CustomerCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(CustomerCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [THEN] Approval action are not shown.
        Assert.IsFalse(CustomerCard.Approve.Visible(), 'Approve should be visible');
        Assert.IsFalse(CustomerCard.Reject.Visible(), 'Reject should be visible');
        Assert.IsFalse(CustomerCard.Delegate.Visible(), 'Delegate should be visible');

        // Clenup
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestCustomerCreditLimitChangeApprovalActionsVisibilityOnListTest()
    var
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        Customer: Record Customer;
        WorkflowChange: Record Workflow;
        WorkflowApproval: Record Workflow;
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowRecordChange: Record "Workflow - Record Change";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        WorkflowSetup: Codeunit "Workflow Setup";
        CustomerList: TestPage "Customer List";
        CustomerCard: TestPage "Customer Card";
        OldValue: Decimal;
    begin
        // [SCENARIO 6] Approval action availability.
        // [GIVEN] Customer approval workflow and customer credit limit change approval workflow are disabled.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Customer card is opened.
        LibrarySales.CreateCustomer(Customer);
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [THEN] Only Send is enabled.
        Assert.IsFalse(CustomerList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsFalse(CustomerList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // Cleanup
        CustomerList.Close();

        // [GIVEN] Customer credit limit change approval workflow and customer approval workflow are enabled.
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowChange, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowApproval, WorkflowSetup.CustomerWorkflowCode());
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowChange.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowApproval.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(WorkflowChange);
        LibraryWorkflow.EnableWorkflow(WorkflowApproval);

        // [WHEN] Customer list is opened.
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(CustomerList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(CustomerList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        CustomerList.Close();

        // [WHEN] Customer Credit Limit (LCY) is changed.
        LibraryVariableStorage.Enqueue('The customer credit limit change was sent for approval.');
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        Evaluate(OldValue, CustomerCard."Credit Limit (LCY)".Value);
        CustomerCard."Credit Limit (LCY)".Value := Format(OldValue + 100);
        CustomerCard.OK().Invoke();

        // [THEN] The record change was created.
        WorkflowRecordChange.SetRange("Record ID", Customer.RecordId);
        Assert.IsFalse(WorkflowRecordChange.IsEmpty, 'WorkflowRecordChange should not be empty');

        // [GIVEN] Approval exist on Customer.
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(CustomerList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(CustomerList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        CustomerList.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestMultipleCustomerCreditLimitChangeApprovalWorkflow()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Customer: Record Customer;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowSetup: Codeunit "Workflow Setup";
        RequeststoApprove: TestPage "Requests to Approve";
        NewCreditLimit: Decimal;
    begin
        // [SCENARIO 7] Test that the Customer Credit Limit Change Approval Workflow approval path works when multiple requests are made for the same customer.
        // [GIVEN] The Customer Credit Limit Change Approval Workflow is enabled.
        // [WHEN] A user sends 3 customer credit limit changes for approval and all users in the group of approvals approve the 2nd request.
        // [THEN] The 2nd customer credit limit change is approved and applied.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Excercise - Open Customer card and send the credit limit change for approval
        CreateCustomerAndChangeCreditLimitAndSendForApproval(Customer, LibraryRandom.RandDecInRange(1, 1000, 2));
        NewCreditLimit := LibraryRandom.RandDecInRange(1000, 2000, 2);
        ChangeCreditLimitAndSendForApproval(Customer, NewCreditLimit);
        ChangeCreditLimitAndSendForApproval(Customer, LibraryRandom.RandDecInRange(2000, 3000, 2));

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Customer);

        // Approve the middle approval entry
        // find the workflow instance from the change record
        WorkflowRecordChange.SetFilter("Record ID", '%1', Customer.RecordId);
        WorkflowRecordChange.SetRange("Table No.", DATABASE::Customer);
        WorkflowRecordChange.SetRange("Field No.", Customer.FieldNo("Credit Limit (LCY)"));
        WorkflowRecordChange.SetRange("New Value", Format(NewCreditLimit, 0, 9));
        WorkflowRecordChange.FindFirst();
        // find the approval entry from the workflow instance
        ApprovalEntry.SetFilter("Record ID to Approve", '%1', Customer.RecordId);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowRecordChange."Workflow Step Instance ID");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.FindFirst();
        // goto the approval entry and approve
        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Approve.Invoke();
        // find the next approval entry (there were 3, 1 auto-approved, 1 approved just above and this last one)
        ApprovalEntry.FindFirst();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Approve.Invoke();
        // close the page
        RequeststoApprove.OK().Invoke();

        // verify that the customer now has the correct Credit Limit set.
        Customer.Get(Customer."No.");
        Assert.AreEqual(NewCreditLimit, Customer."Credit Limit (LCY)", 'Correct Credit Limit (LCY) was not set');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerCreditLimitChangeAndCustomerApprovalWorkflowRejection()
    var
        WorkflowCreditLimit: Record Workflow;
        WorkflowCustomerApproval: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Customer: Record Customer;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowRecordChangeArchive: Record "Workflow Record Change Archive";
        WorkflowSetup: Codeunit "Workflow Setup";
        NewCreditLimit: Decimal;
    begin
        // [SCENARIO 8] Test that rejecting a credit limit change approval does not cancel a customer approval.
        // [GIVEN] A Customer Credit Limit Change Approval Workflow and a Customer Approval Workflow are enabled.
        // [WHEN] A user sends the customer credit limit change for approval, sends the customer for approval and then rejects the customer credit limit change approval.
        // [THEN] The customer credit limit change is rejected, but the customer approval is not impacted.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowCreditLimit, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowCustomerApproval, WorkflowSetup.CustomerWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsWithApproversAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowCreditLimit.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(WorkflowCreditLimit);
        LibraryWorkflow.EnableWorkflow(WorkflowCustomerApproval);

        // Excercise - Open Customer card and sent the credit limit change for approval
        NewCreditLimit := LibraryRandom.RandDec(1000, 2);
        CreateCustomerAndChangeCreditLimitAndSendForApproval(Customer, NewCreditLimit);

        // Exercise - Send Customer For Approval
        SendCustomerForApproval(Customer);

        // Verify - Record change for the Customer record was created
        VerifyChangeRecordExists(Customer);

        // Verify - Approval requests number
        ApprovalEntry.SetRange("Record ID to Approve", Customer.RecordId);
        Assert.AreEqual(4, ApprovalEntry.Count, 'Unexpected number of approval entries was created.');

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Customer);

        // Excercise - Open Customer card and reject the credit limit change
        RejectCustomerCreditLimitChange(Customer);

        // Verify - Not all Approval requests were rejected
        WorkflowRecordChangeArchive.SetRange("Record ID", Customer.RecordId);
        WorkflowRecordChangeArchive.FindFirst();
        ApprovalEntry.SetRange("Record ID to Approve", Customer.RecordId);
        ApprovalEntry.SetFilter("Workflow Step Instance ID", '<>%1', WorkflowRecordChangeArchive."Workflow Step Instance ID");
        ApprovalEntry.SetFilter(Status, '<>%1', ApprovalEntry.Status::Rejected);
        Assert.IsFalse(ApprovalEntry.IsEmpty, 'Not all approvals should be rejected.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerCreditLimitChangeAndCustomerApprovalWorkflowCancelation()
    var
        WorkflowCreditLimit: Record Workflow;
        WorkflowCustomerApproval: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Customer: Record Customer;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        NewCreditLimit: Decimal;
    begin
        // [SCENARIO 9] Test that canceling a customer approval workflow does not cancel a credit limit change approval.
        // [GIVEN] A Customer Credit Limit Change Approval Workflow and a Customer Approval Workflow are enabled.
        // [WHEN] A user sends the customer credit limit change for approval, sends the customer for approval and then cancels the customer approval.
        // [THEN] The customer approval is canceled, but the credit limit change approval is not impacted.

        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowCustomerApproval, WorkflowSetup.CustomerWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowCreditLimit, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsWithApproversAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowCreditLimit.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(WorkflowCustomerApproval);
        LibraryWorkflow.EnableWorkflow(WorkflowCreditLimit);

        // Excercise - Open Customer card and sent the credit limit change for approval
        NewCreditLimit := LibraryRandom.RandDec(1000, 2);
        CreateCustomerAndChangeCreditLimitAndSendForApproval(Customer, NewCreditLimit);

        CheckUserCanCancelTheApprovalRequest(Customer, false);

        // Exercise - Send Customer For Approval
        SendCustomerForApproval(Customer);

        CheckUserCanCancelTheApprovalRequest(Customer, true);

        // Verify - Record change for the Customer record was created
        VerifyChangeRecordExists(Customer);

        // Verify - Approval requests number
        ApprovalEntry.SetRange("Record ID to Approve", Customer.RecordId);
        Assert.AreEqual(4, ApprovalEntry.Count, 'Unexpected number of approval entries was created.');

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Customer);

        // Excercise - Open Customer card and cancel the credit limit change
        CancelCustomerApproval(Customer);

        // Verify - Not correct Approval requests were rejected
        WorkflowRecordChange.SetRange("Record ID", Customer.RecordId);
        WorkflowRecordChange.FindFirst();
        ApprovalEntry.SetRange("Record ID to Approve", Customer.RecordId);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowRecordChange."Workflow Step Instance ID");
        ApprovalEntry.SetFilter(Status, '<>%1', ApprovalEntry.Status::Canceled);
        Assert.IsFalse(ApprovalEntry.IsEmpty, 'Not all approvals should be canceled.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerCreditLimitChangeAndCustomerApprovalWorkflowCancelationApprovalAdmin()
    var
        WorkflowCreditLimit: Record Workflow;
        WorkflowCustomerApproval: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Customer: Record Customer;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        NewCreditLimit: Decimal;
    begin
        // [SCENARIO 9] Test that canceling a customer approval workflow does not cancel a credit limit change approval.
        // [GIVEN] A Customer Credit Limit Change Approval Workflow and a Customer Approval Workflow are enabled.
        // [WHEN] A user sends the customer credit limit change for approval, sends the customer for approval and then cancels the customer approval.
        // [THEN] The customer approval is canceled, but the credit limit change approval is not impacted.

        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowCreditLimit, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowCustomerApproval, WorkflowSetup.CustomerWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsWithApproversAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowCreditLimit.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(WorkflowCreditLimit);
        LibraryWorkflow.EnableWorkflow(WorkflowCustomerApproval);

        // Excercise - Open Customer card and sent the credit limit change for approval
        NewCreditLimit := LibraryRandom.RandDec(1000, 2);
        CreateCustomerAndChangeCreditLimitAndSendForApproval(Customer, NewCreditLimit);

        CheckUserCanCancelTheApprovalRequest(Customer, false);

        // Exercise - Send Customer For Approval
        SendCustomerForApproval(Customer);

        // Verify - Record change for the Customer record was created
        VerifyChangeRecordExists(Customer);

        CheckUserCanCancelTheApprovalRequest(Customer, true);

        // Verify - Approval requests number
        ApprovalEntry.SetRange("Record ID to Approve", Customer.RecordId);
        Assert.AreEqual(4, ApprovalEntry.Count, 'Unexpected number of approval entries was created.');

        // Excercise - Set the user to be an approval admin
        LibraryDocumentApprovals.SetAdministrator(CurrentUserSetup);
        CheckUserCanCancelTheApprovalRequest(Customer, true);

        // Excercise - Open Customer card and cancel the credit limit change
        CancelCustomerApproval(Customer);

        // Verify - Not correct Approval requests were rejected
        WorkflowRecordChange.SetRange("Record ID", Customer.RecordId);
        WorkflowRecordChange.FindFirst();
        ApprovalEntry.SetRange("Record ID to Approve", Customer.RecordId);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowRecordChange."Workflow Step Instance ID");
        ApprovalEntry.SetFilter(Status, '<>%1', ApprovalEntry.Status::Canceled);
        Assert.IsFalse(ApprovalEntry.IsEmpty, 'Not all approvals should be canceled.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerCreditLimitChangeApprovalWorkflowWithComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Customer: Record Customer;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowSetup: Codeunit "Workflow Setup";
        NewCreditLimit: Decimal;
    begin
        // [SCENARIO 1] Test that the Customer Credit Limit Change Approval Workflow approval path works with a group of 3 users.
        // [GIVEN] The Customer Credit Limit Change Approval Workflow is enabled.
        // [WHEN] A user sends the customer credit limit change for approval and all users in the group of approvals approve the document.
        // [THEN] The customer credit limit change is approved and applied.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Excercise - Open Customer card and sent the credit limit change for approval
        NewCreditLimit := LibraryRandom.RandDec(1000, 2);
        CreateCustomerAndChangeCreditLimitAndSendForApproval(Customer, NewCreditLimit);

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Customer.RecordId);
        ApprovalEntry.Next();
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 0);

        // Verify - Record change for the Customer record was created
        VerifyChangeRecordExists(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Customer);

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Customer.RecordId);
        ApprovalEntry.Next();
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 0);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 0);

        // Excercise - Open Customer card and approve the credit limit change
        ApproveCustomerCreditLimitChange(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Open Customer card and approve the credit limit change
        ApproveCustomerCreditLimitChange(Customer);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Customer, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);

        // Verify - Record change for the Customer was deleted
        VerifyChangeRecordDoesNotExist(Customer);

        // Verify - The new credit limit was applied for the record
        VerifyCreditLimitForCustomer(Customer, NewCreditLimit);
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

    local procedure CreateUserSetupsAndGroupOfApproversForWorkflow(var WorkflowUserGroup: Record "Workflow User Group"; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        WorkflowUserGroup.Code := LibraryUtility.GenerateRandomCode(WorkflowUserGroup.FieldNo(Code), DATABASE::"Workflow User Group");
        WorkflowUserGroup.Description := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        WorkflowUserGroup.Insert(true);

        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, CurrentUserSetup."User ID", 1);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, IntermediateApproverUserSetup."User ID", 2);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, FinalApproverUserSetup."User ID", 3);
    end;

    local procedure CreateUserSetupsWithApproversAndGroupOfApproversForWorkflow(var WorkflowUserGroup: Record "Workflow User Group"; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, IntermediateApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        WorkflowUserGroup.Code := LibraryUtility.GenerateRandomCode(WorkflowUserGroup.FieldNo(Code), DATABASE::"Workflow User Group");
        WorkflowUserGroup.Description := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        WorkflowUserGroup.Insert(true);

        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, CurrentUserSetup."User ID", 1);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, IntermediateApproverUserSetup."User ID", 2);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, FinalApproverUserSetup."User ID", 3);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure CreateCustomerAndChangeCreditLimitAndSendForApproval(var Customer: Record Customer; NewCreditLimit: Decimal) OldValue: Decimal
    begin
        LibrarySales.CreateCustomer(Customer);
        OldValue := ChangeCreditLimitAndSendForApproval(Customer, NewCreditLimit);
    end;

    local procedure SendCustomerForApproval(Customer: Record Customer)
    var
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();
    end;

    local procedure ChangeCreditLimitAndSendForApproval(var Customer: Record Customer; NewCreditLimit: Decimal) OldValue: Decimal
    var
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenView();
        CustomerCard.GotoRecord(Customer);

        Evaluate(OldValue, CustomerCard."Credit Limit (LCY)".Value);

        CustomerCard."Credit Limit (LCY)".Value(Format(NewCreditLimit));
        CustomerCard.OK().Invoke();
    end;

    local procedure ApproveCustomerCreditLimitChange(var Customer: Record Customer)
    var
        ApprovalEntry: Record "Approval Entry";
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        ApprovalEntry.SetRange("Table ID", DATABASE::Customer);
        ApprovalEntry.SetRange("Record ID to Approve", Customer.RecordId);
        ApprovalEntry.SetRange("Related to Change", true);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.FindFirst();

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Approve.Invoke();
        RequeststoApprove.Close();
    end;

    local procedure RejectCustomerCreditLimitChange(var Customer: Record Customer)
    var
        ApprovalEntry: Record "Approval Entry";
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        ApprovalEntry.SetRange("Table ID", DATABASE::Customer);
        ApprovalEntry.SetRange("Record ID to Approve", Customer.RecordId);
        ApprovalEntry.SetRange("Related to Change", true);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.FindFirst();

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Reject.Invoke();
        RequeststoApprove.Close();
    end;

    local procedure CancelCustomerApproval(var Customer: Record Customer)
    var
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenView();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.CancelApprovalRequest.Invoke();
        CustomerCard.Close();
    end;

    local procedure DelegateCustomerCreditLimitChange(var Customer: Record Customer)
    var
        ApprovalEntry: Record "Approval Entry";
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        ApprovalEntry.SetRange("Table ID", DATABASE::Customer);
        ApprovalEntry.SetRange("Record ID to Approve", Customer.RecordId);
        ApprovalEntry.SetRange("Related to Change", true);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.FindFirst();

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Delegate.Invoke();
        RequeststoApprove.Close();
    end;

    local procedure UpdateApprovalEntryWithTempUser(UserSetup: Record "User Setup"; Customer: Record Customer)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Customer.RecordId);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;

    local procedure VerifyApprovalEntry(ApprovalEntry: Record "Approval Entry"; SenderId: Code[50]; ApproverId: Code[50]; Status: Enum "Approval Status")
    begin
        ApprovalEntry.TestField("Sender ID", SenderId);
        ApprovalEntry.TestField("Approver ID", ApproverId);
        ApprovalEntry.TestField(Status, Status);
    end;

    local procedure VerifyApprovalRequests(Customer: Record Customer; ExpectedNumberOfApprovalEntries: Integer; SenderUserID: Code[50]; ApproverUserID1: Code[50]; ApproverUserID2: Code[50]; ApproverUserID3: Code[50]; Status1: Enum "Approval Status"; Status2: Enum "Approval Status"; Status3: Enum "Approval Status")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Customer.RecordId);
        Assert.AreEqual(ExpectedNumberOfApprovalEntries, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID1, Status1);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID2, Status2);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID3, Status3);
    end;

    local procedure VerifyChangeRecordExists(Customer: Record Customer)
    var
        WorkflowRecordChange: Record "Workflow - Record Change";
    begin
        WorkflowRecordChange.SetRange("Record ID", Customer.RecordId);
        Assert.IsFalse(WorkflowRecordChange.IsEmpty, 'The record change was not created');
    end;

    local procedure VerifyChangeRecordDoesNotExist(Customer: Record Customer)
    var
        WorkflowRecordChange: Record "Workflow - Record Change";
    begin
        WorkflowRecordChange.SetRange("Record ID", Customer.RecordId);
        Assert.IsTrue(WorkflowRecordChange.IsEmpty, 'The record change was not deleted');
    end;

    local procedure VerifyCreditLimitForCustomer(Customer: Record Customer; CreditLimit: Decimal)
    begin
        Customer.Find();
        Assert.AreEqual(CreditLimit, Customer."Credit Limit (LCY)", 'The credit limit was not applied');
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

    local procedure CheckUserCanCancelTheApprovalRequest(Customer: Record Customer; CancelActionExpectedEnabled: Boolean)
    var
        CustomerCard: TestPage "Customer Card";
        CustomerList: TestPage "Customer List";
    begin
        CustomerCard.OpenView();
        CustomerCard.GotoRecord(Customer);
        Assert.AreEqual(CancelActionExpectedEnabled, CustomerCard.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        CustomerCard.Close();

        CustomerList.OpenView();
        CustomerList.GotoRecord(Customer);
        Assert.AreEqual(CancelActionExpectedEnabled, CustomerList.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        CustomerList.Close();
    end;
}

