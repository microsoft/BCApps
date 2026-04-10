codeunit 139307 "Cust. App. Setup Wizard Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Customer] [Wizard] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        ApproverNotSelectedErr: Label 'You must select an approver before continuing.';
        CloseWizardConfirmMsg: Label 'Customer Approval has not been set up.\\Are you sure that you want to exit?';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryRandom: Codeunit "Library - Random";
        ActionShouldBeEnabledErr: Label 'Action should be enabled.';
        ActionShouldNotBeEnabledErr: Label 'Action should not be enabled.';
        LibraryApplicationArea: Codeunit "Library - Application Area";

    [Test]
    [HandlerFunctions('YesConfirmHandler,RunWizardWithOptions')]
    [Scope('OnPrem')]
    procedure TestErrorIfApproverIsNotSelected()
    var
        UserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryVariableStorage.Enqueue(UserSetup);
        LibraryVariableStorage.Enqueue(1);

        CustomerCard.OpenView();
        CustomerCard.First();

        Assert.IsTrue(CustomerCard.CreateApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);
        Assert.IsFalse(CustomerCard.ManageApprovalWorkflows.Enabled(), ActionShouldNotBeEnabledErr);

        asserterror CustomerCard.CreateApprovalWorkflow.Invoke();

        Assert.ExpectedError(ApproverNotSelectedErr);
    end;

    [Test]
    [HandlerFunctions('CloseWizardYesConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCloseWizardBeforeFinishTriggersMessage()
    var
        CustApprovalWFSetupWizard: TestPage "Cust. Approval WF Setup Wizard";
    begin
        Initialize();
        CustApprovalWFSetupWizard.Trap();

        PAGE.Run(PAGE::"Cust. Approval WF Setup Wizard");

        CustApprovalWFSetupWizard.Close();
    end;

    [Test]
    [HandlerFunctions('CloseWizardYesConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCanNavigateBackInWizard()
    var
        CustApprovalWFSetupWizard: TestPage "Cust. Approval WF Setup Wizard";
    begin
        Initialize();
        CustApprovalWFSetupWizard.Trap();

        PAGE.Run(PAGE::"Cust. Approval WF Setup Wizard");

        // Go to second page
        CustApprovalWFSetupWizard.NextPage.Invoke();

        // Go back to Intro page
        CustApprovalWFSetupWizard.PreviousPage.Invoke();

        // Verify - Cannot check field visibility, we consider to be on the first page if we cannot go back
        Assert.IsFalse(CustApprovalWFSetupWizard.PreviousPage.Enabled(), 'Control should not be enabled');
    end;

    [Test]
    [HandlerFunctions('RunWizardWithOptions,WorkflowPageHandler')]
    [Scope('OnPrem')]
    procedure TestNormalApprovalWizardRunFromCard()
    var
        UserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryWorkflow.DisableAllWorkflows();

        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        LibraryVariableStorage.Enqueue(UserSetup);
        LibraryVariableStorage.Enqueue(1);

        CustomerCard.OpenView();
        CustomerCard.First();

        Assert.IsTrue(CustomerCard.CreateApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);
        Assert.IsFalse(CustomerCard.ManageApprovalWorkflows.Enabled(), ActionShouldNotBeEnabledErr);

        CustomerCard.CreateApprovalWorkflow.Invoke();

        VerifyStandardWorkflow(UserSetup);

        Assert.IsFalse(CustomerCard.CreateApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);
        Assert.IsTrue(CustomerCard.ManageApprovalWorkflows.Enabled(), ActionShouldBeEnabledErr);

        CustomerCard.ManageApprovalWorkflows.Invoke();
    end;

    [Test]
    [HandlerFunctions('RunWizardWithOptions,WorkflowPageHandler')]
    [Scope('OnPrem')]
    procedure TestRecordChangeApprovalWizardRunFromCard()
    var
        Customer: Record Customer;
        UserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
        FieldOperator: Integer;
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryWorkflow.DisableAllWorkflows();

        FieldOperator := LibraryRandom.RandInt(3);

        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        LibraryVariableStorage.Enqueue(UserSetup);
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(Customer.FieldCaption("Name 2"));
        LibraryVariableStorage.Enqueue(FieldOperator);
        LibraryVariableStorage.Enqueue('Custom test message');

        CustomerCard.OpenView();
        CustomerCard.First();

        Assert.IsTrue(CustomerCard.CreateApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);
        Assert.IsFalse(CustomerCard.ManageApprovalWorkflows.Enabled(), ActionShouldNotBeEnabledErr);

        CustomerCard.CreateApprovalWorkflow.Invoke();

        VerifyChangeRecWorkflow(UserSetup, Customer.FieldNo("Name 2"), FieldOperator);

        Assert.IsFalse(CustomerCard.CreateApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);
        Assert.IsTrue(CustomerCard.ManageApprovalWorkflows.Enabled(), ActionShouldBeEnabledErr);

        CustomerCard.ManageApprovalWorkflows.Invoke();
    end;

    [Test]
    [HandlerFunctions('RunWizardWithOptions,WorkflowPageHandler')]
    [Scope('OnPrem')]
    procedure TestNormalApprovalWizardRunFromList()
    var
        UserSetup: Record "User Setup";
        CustomerList: TestPage "Customer List";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryWorkflow.DisableAllWorkflows();

        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        LibraryVariableStorage.Enqueue(UserSetup);
        LibraryVariableStorage.Enqueue(1);

        CustomerList.OpenView();
        CustomerList.First();

        Assert.IsTrue(CustomerList.CreateApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);
        Assert.IsFalse(CustomerList.ManageApprovalWorkflows.Enabled(), ActionShouldNotBeEnabledErr);

        CustomerList.CreateApprovalWorkflow.Invoke();

        VerifyStandardWorkflow(UserSetup);

        Assert.IsFalse(CustomerList.CreateApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);
        Assert.IsTrue(CustomerList.ManageApprovalWorkflows.Enabled(), ActionShouldBeEnabledErr);

        CustomerList.ManageApprovalWorkflows.Invoke();
    end;

    [Test]
    [HandlerFunctions('RunWizardWithOptions,WorkflowPageHandler')]
    [Scope('OnPrem')]
    procedure TestRecordChangeApprovalWizardRunFromList()
    var
        Customer: Record Customer;
        UserSetup: Record "User Setup";
        CustomerList: TestPage "Customer List";
        FieldOperator: Integer;
    begin
        Initialize();
        LibraryWorkflow.DisableAllWorkflows();

        FieldOperator := LibraryRandom.RandInt(3);

        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        LibraryVariableStorage.Enqueue(UserSetup);
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(Customer.FieldCaption("Name 2"));
        LibraryVariableStorage.Enqueue(FieldOperator);
        LibraryVariableStorage.Enqueue('Custom test message');

        CustomerList.OpenView();
        CustomerList.First();

        Assert.IsTrue(CustomerList.CreateApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);
        Assert.IsFalse(CustomerList.ManageApprovalWorkflows.Enabled(), ActionShouldNotBeEnabledErr);

        CustomerList.CreateApprovalWorkflow.Invoke();

        VerifyChangeRecWorkflow(UserSetup, Customer.FieldNo("Name 2"), FieldOperator);

        Assert.IsFalse(CustomerList.CreateApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);
        Assert.IsTrue(CustomerList.ManageApprovalWorkflows.Enabled(), ActionShouldBeEnabledErr);

        CustomerList.ManageApprovalWorkflows.Invoke();
    end;

    local procedure Initialize()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RunWizardWithOptions(var CustApprovalWFSetupWizard: TestPage "Cust. Approval WF Setup Wizard")
    var
        UserSetup: Record "User Setup";
        UserSetupVar: Variant;
        TriggerOption: Integer;
        FieldCaption: Text;
        FieldOperator: Integer;
        CustomMessage: Text;
    begin
        LibraryVariableStorage.Dequeue(UserSetupVar);
        UserSetup := UserSetupVar;
        TriggerOption := LibraryVariableStorage.DequeueInteger();
        if TriggerOption > 1 then begin
            FieldCaption := LibraryVariableStorage.DequeueText();
            FieldOperator := LibraryVariableStorage.DequeueInteger();
            CustomMessage := LibraryVariableStorage.DequeueText();
        end;

        // Navigate away from the Intro page.
        CustApprovalWFSetupWizard.NextPage.Invoke();

        CustApprovalWFSetupWizard."Approver ID".SetValue(UserSetup."User ID");
        CustApprovalWFSetupWizard."App. Trigger".SetValue(CustApprovalWFSetupWizard."App. Trigger".GetOption(TriggerOption));

        CustApprovalWFSetupWizard.NextPage.Invoke();

        if TriggerOption = 1 then
            CustApprovalWFSetupWizard.Finish.Invoke()
        else begin
            CustApprovalWFSetupWizard.CustomerFieldCap.SetValue(FieldCaption);
            CustApprovalWFSetupWizard."Field Operator".SetValue(FieldOperator);
            CustApprovalWFSetupWizard."Custom Message".SetValue(CustomMessage);
            CustApprovalWFSetupWizard.NextPage.Invoke();
            CustApprovalWFSetupWizard.Finish.Invoke();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkflowPageHandler(var Workflow: TestPage Workflow)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CloseWizardYesConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.AreEqual(CloseWizardConfirmMsg, Question, 'Wrong confirm message');
        Reply := true;
    end;

    local procedure VerifyStandardWorkflow(UserSetup: Record "User Setup")
    var
        Workflow: Record Workflow;
    begin
        GetWorkflow(Workflow);

        VerifyCreateApprovalRequestResponse(Workflow, UserSetup);
    end;

    local procedure VerifyChangeRecWorkflow(UserSetup: Record "User Setup"; FieldNo: Integer; FieldOperator: Integer)
    var
        Workflow: Record Workflow;
        WorkflowRule: Record "Workflow Rule";
        RecOperator: Integer;
    begin
        GetWorkflow(Workflow);

        VerifyCreateApprovalRequestResponse(Workflow, UserSetup);

        WorkflowRule.SetRange("Workflow Code", Workflow.Code);
        if WorkflowRule.FindFirst() then begin
            Assert.AreEqual(FieldNo, WorkflowRule."Field No.", 'Wrong Field');
            RecOperator := WorkflowRule.Operator;
            Assert.AreEqual(FieldOperator, RecOperator, 'Wrong Field');
        end;
    end;

    local procedure GetWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.SetRange(Enabled, true);
        Assert.RecordCount(Workflow, 1);
        Workflow.FindFirst();
    end;

    local procedure VerifyCreateApprovalRequestResponse(Workflow: Record Workflow; UserSetup: Record "User Setup")
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::Response);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        if WorkflowStep.FindFirst() then begin
            WorkflowStepArgument.Get(WorkflowStep.Argument);
            WorkflowStepArgument.TestField("Approver Type", WorkflowStepArgument."Approver Type"::Approver);
            WorkflowStepArgument.TestField("Approver Limit Type", WorkflowStepArgument."Approver Limit Type"::"Specific Approver");
            WorkflowStepArgument.TestField("Approver User ID", UserSetup."User ID");
        end;
    end;
}

