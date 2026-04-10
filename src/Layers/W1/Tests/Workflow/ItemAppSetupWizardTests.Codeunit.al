codeunit 139308 "Item App. Setup Wizard Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Approval] [Workflow] [Item] [Wizard] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        ApproverNotSelectedErr: Label 'You must select an approver before continuing.';
        CloseWizardConfirmMsg: Label 'Item Approval has not been set up.\\Are you sure that you want to exit?';
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
        ItemCard: TestPage "Item Card";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryVariableStorage.Enqueue(UserSetup);
        LibraryVariableStorage.Enqueue(1);

        ItemCard.OpenView();
        ItemCard.First();

        Assert.IsTrue(ItemCard.CreateApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);
        Assert.IsFalse(ItemCard.ManageApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);

        asserterror ItemCard.CreateApprovalWorkflow.Invoke();

        Assert.ExpectedError(ApproverNotSelectedErr);
    end;

    [Test]
    [HandlerFunctions('CloseWizardYesConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCloseWizardBeforeFinishTriggersMessage()
    var
        ItemApprovalWFSetupWizard: TestPage "Item Approval WF Setup Wizard";
    begin
        Initialize();
        ItemApprovalWFSetupWizard.Trap();

        PAGE.Run(PAGE::"Item Approval WF Setup Wizard");

        ItemApprovalWFSetupWizard.Close();
    end;

    [Test]
    [HandlerFunctions('CloseWizardYesConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCanNavigateBackInWizard()
    var
        ItemApprovalWFSetupWizard: TestPage "Item Approval WF Setup Wizard";
    begin
        Initialize();
        ItemApprovalWFSetupWizard.Trap();

        PAGE.Run(PAGE::"Item Approval WF Setup Wizard");

        // Go to second page
        ItemApprovalWFSetupWizard.NextPage.Invoke();

        // Go back to Intro page
        ItemApprovalWFSetupWizard.PreviousPage.Invoke();

        // Verify - Cannot check field visibility, we consider to be on the first page if we cannot go back
        Assert.IsFalse(ItemApprovalWFSetupWizard.PreviousPage.Enabled(), 'Control should not be enabled');
    end;

    [Test]
    [HandlerFunctions('RunWizardWithOptions,WorkflowPageHandler')]
    [Scope('OnPrem')]
    procedure TestNormalApprovalWizardRunFromCard()
    var
        UserSetup: Record "User Setup";
        ItemCard: TestPage "Item Card";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryWorkflow.DisableAllWorkflows();

        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        LibraryVariableStorage.Enqueue(UserSetup);
        LibraryVariableStorage.Enqueue(1);

        ItemCard.OpenView();
        ItemCard.First();

        Assert.IsTrue(ItemCard.CreateApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);
        Assert.IsFalse(ItemCard.ManageApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);

        ItemCard.CreateApprovalWorkflow.Invoke();

        VerifyStandardWorkflow(UserSetup);

        Assert.IsFalse(ItemCard.CreateApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);
        Assert.IsTrue(ItemCard.ManageApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);

        ItemCard.ManageApprovalWorkflow.Invoke();
    end;

    [Test]
    [HandlerFunctions('RunWizardWithOptions,WorkflowPageHandler')]
    [Scope('OnPrem')]
    procedure TestRecordChangeApprovalWizardRunFromCard()
    var
        Item: Record Item;
        UserSetup: Record "User Setup";
        ItemCard: TestPage "Item Card";
        FieldOperator: Integer;
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryWorkflow.DisableAllWorkflows();

        FieldOperator := LibraryRandom.RandInt(3);

        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        LibraryVariableStorage.Enqueue(UserSetup);
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(Item.FieldCaption(Blocked));
        LibraryVariableStorage.Enqueue('Custom test message');
        LibraryVariableStorage.Enqueue(FieldOperator);

        ItemCard.OpenView();
        ItemCard.First();

        Assert.IsTrue(ItemCard.CreateApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);
        Assert.IsFalse(ItemCard.ManageApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);

        ItemCard.CreateApprovalWorkflow.Invoke();

        VerifyChangeRecWorkflow(UserSetup, Item.FieldNo(Blocked), FieldOperator);

        Assert.IsFalse(ItemCard.CreateApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);
        Assert.IsTrue(ItemCard.ManageApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);

        ItemCard.ManageApprovalWorkflow.Invoke();
    end;

    [Test]
    [HandlerFunctions('RunWizardWithOptions,WorkflowPageHandler')]
    [Scope('OnPrem')]
    procedure TestNormalApprovalWizardRunFromList()
    var
        UserSetup: Record "User Setup";
        ItemList: TestPage "Item List";
    begin
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryWorkflow.DisableAllWorkflows();

        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        LibraryVariableStorage.Enqueue(UserSetup);
        LibraryVariableStorage.Enqueue(1);

        ItemList.OpenView();
        ItemList.First();

        Assert.IsTrue(ItemList.CreateApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);
        Assert.IsFalse(ItemList.ManageApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);

        ItemList.CreateApprovalWorkflow.Invoke();

        VerifyStandardWorkflow(UserSetup);

        Assert.IsFalse(ItemList.CreateApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);
        Assert.IsTrue(ItemList.ManageApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);

        ItemList.ManageApprovalWorkflow.Invoke();
    end;

    [Test]
    [HandlerFunctions('RunWizardWithOptions,WorkflowPageHandler')]
    [Scope('OnPrem')]
    procedure TestRecordChangeApprovalWizardRunFromList()
    var
        Item: Record Item;
        UserSetup: Record "User Setup";
        ItemList: TestPage "Item List";
        FieldOperator: Integer;
    begin
        Initialize();
        LibraryWorkflow.DisableAllWorkflows();

        FieldOperator := LibraryRandom.RandInt(3);

        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        LibraryVariableStorage.Enqueue(UserSetup);
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(Item.FieldCaption(Blocked));
        LibraryVariableStorage.Enqueue('Custom test message');
        LibraryVariableStorage.Enqueue(FieldOperator);

        ItemList.OpenView();
        ItemList.First();

        Assert.IsTrue(ItemList.CreateApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);
        Assert.IsFalse(ItemList.ManageApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);

        ItemList.CreateApprovalWorkflow.Invoke();

        VerifyChangeRecWorkflow(UserSetup, Item.FieldNo(Blocked), FieldOperator);

        Assert.IsFalse(ItemList.CreateApprovalWorkflow.Enabled(), ActionShouldNotBeEnabledErr);
        Assert.IsTrue(ItemList.ManageApprovalWorkflow.Enabled(), ActionShouldBeEnabledErr);

        ItemList.ManageApprovalWorkflow.Invoke();
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RunWizardWithOptions(var ItemApprovalWFSetupWizard: TestPage "Item Approval WF Setup Wizard")
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
            CustomMessage := LibraryVariableStorage.DequeueText();
            FieldOperator := LibraryVariableStorage.DequeueInteger();
        end;

        // Navigate away from the Intro page.
        ItemApprovalWFSetupWizard.NextPage.Invoke();

        ItemApprovalWFSetupWizard."Approver ID".SetValue(UserSetup."User ID");
        ItemApprovalWFSetupWizard."App. Trigger".SetValue(ItemApprovalWFSetupWizard."App. Trigger".GetOption(TriggerOption));

        ItemApprovalWFSetupWizard.NextPage.Invoke();

        if TriggerOption = 1 then
            ItemApprovalWFSetupWizard.Finish.Invoke()
        else begin
            ItemApprovalWFSetupWizard.ItemFieldCap.SetValue(FieldCaption);
            ItemApprovalWFSetupWizard."Field Operator".SetValue(FieldOperator);
            ItemApprovalWFSetupWizard."Custom Message".SetValue(CustomMessage);
            ItemApprovalWFSetupWizard.NextPage.Invoke();
            ItemApprovalWFSetupWizard.Finish.Invoke();
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
            WorkflowStepArgument.TestField("Approver Limit Type", WorkflowStepArgument."Approver Limit Type"::"Specific Approver");
            WorkflowStepArgument.TestField("Approver Type", WorkflowStepArgument."Approver Type"::Approver);
            WorkflowStepArgument.TestField("Approver User ID", UserSetup."User ID");
        end;
    end;
}

