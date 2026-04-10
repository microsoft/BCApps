codeunit 134306 "Copy Workflow Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Copy Workflow] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        AmountCondXmlTemplateTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Purch. Inv. Event Conditions" id="1502"><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.) WHERE(Amount=FILTER(%1))</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.)</DataItem></DataItems></ReportParameters>', Locked = true;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyTemplateToFirstWorkflow()
    var
        FromWorkflow: Record Workflow;
        ToWorkflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowTemplatesPage: TestPage "Workflow Templates";
        WorkflowPage: TestPage Workflow;
        EventConditions: Text;
    begin
        // [SCENARIO] Copy Workflow Template to a new workflow.
        // [GIVEN] An existing workflow template with one or more steps.
        // [WHEN] The user invokes the New Workflow from Template Action.
        // [THEN] All the data in the Workflow Template and Workflow Steps is copied to a new workflow and the new Workflow is opened.

        // Setup
        Initialize();

        EventConditions :=
          CreateTwoStepsWorkflow(
            FromWorkflow, WorkflowEvent,
            WorkflowResponseHandling.CreateNotificationEntryCode());
        FromWorkflow.Validate(Template, true);
        FromWorkflow.Modify();

        WorkflowTemplatesPage.OpenView();
        WorkflowTemplatesPage.FILTER.SetFilter(Description, FromWorkflow.Description);
        WorkflowTemplatesPage.First();

        // Exercise.
        WorkflowPage.Trap();
        WorkflowTemplatesPage."New Workflow from Template".Invoke();

        // Verify.
        ToWorkflow.Get(WorkflowPage.Code.Value);
        ToWorkflow.TestField(Description, FromWorkflow.Description);
        VerifyWorkflowSteps(ToWorkflow, WorkflowStep.Type::"Event", WorkflowEvent."Function Name", EventConditions);
        VerifyWorkflowSteps(ToWorkflow, WorkflowStep.Type::Response, WorkflowResponseHandling.CreateNotificationEntryCode(), '');
        VerifyWorkflowRules(ToWorkflow, FromWorkflow);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyFirstWorkflowToWorkflow()
    var
        FromWorkflow: Record Workflow;
        ToWorkflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowsPage: TestPage Workflows;
        WorkflowPage: TestPage Workflow;
        EventConditions: Text;
    begin
        // [SCENARIO] Copy Workflow to a new workflow (duplicate).
        // [GIVEN] An existing workflow with one or more steps.
        // [WHEN] The user invokes the Copy Workflow Action.
        // [THEN] All the data in the Workflow and Workflow Steps is copied to a new workflow and the new Workflow is opened.

        // Setup
        Initialize();

        EventConditions :=
          CreateTwoStepsWorkflow(
            FromWorkflow, WorkflowEvent,
            WorkflowResponseHandling.CreateNotificationEntryCode());
        FromWorkflow.Validate(Template, false);
        FromWorkflow.Modify();

        WorkflowsPage.OpenView();
        WorkflowsPage.FILTER.SetFilter(Description, FromWorkflow.Description);
        WorkflowsPage.First();

        // Exercise.
        WorkflowPage.Trap();
        WorkflowsPage.CopyWorkflow.Invoke();

        // Verify.
        ToWorkflow.Get(WorkflowPage.Code.Value);
        ToWorkflow.TestField(Description, FromWorkflow.Description);
        VerifyWorkflowSteps(ToWorkflow, WorkflowStep.Type::"Event", WorkflowEvent."Function Name", EventConditions);
        VerifyWorkflowSteps(ToWorkflow, WorkflowStep.Type::Response, WorkflowResponseHandling.CreateNotificationEntryCode(), '');
        VerifyWorkflowRules(ToWorkflow, FromWorkflow);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyEnabledWorkflowToWorkflow()
    var
        FromWorkflow: Record Workflow;
        ToWorkflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowsPage: TestPage Workflows;
        WorkflowPage: TestPage Workflow;
        EventConditions: Text;
    begin
        // [SCENARIO] Copy an Enabled Workflow to a new workflow (duplicate).
        // [GIVEN] An existing enabled workflow with one or more steps.
        // [WHEN] The user invokes the Copy Workflow Action.
        // [THEN] All the data in the Workflow and Workflow Steps is copied to a new workflow and the new Workflow is opened.
        // [THEN] The new Workflow is not enabled.

        // Setup
        Initialize();

        EventConditions :=
          CreateTwoStepsWorkflow(
            FromWorkflow, WorkflowEvent,
            WorkflowResponseHandling.CreateNotificationEntryCode());
        FromWorkflow.Validate(Template, false);
        FromWorkflow.Modify();
        FromWorkflow.Enabled := true;
        FromWorkflow.Modify();

        WorkflowsPage.OpenView();
        WorkflowsPage.FILTER.SetFilter(Description, FromWorkflow.Description);
        WorkflowsPage.First();

        // Exercise.
        WorkflowPage.Trap();
        WorkflowsPage.CopyWorkflow.Invoke();

        // Verify.
        ToWorkflow.Get(WorkflowPage.Code.Value);
        ToWorkflow.TestField(Enabled, false);
        ToWorkflow.TestField(Description, FromWorkflow.Description);
        VerifyWorkflowSteps(ToWorkflow, WorkflowStep.Type::"Event", WorkflowEvent."Function Name", EventConditions);
        VerifyWorkflowSteps(ToWorkflow, WorkflowStep.Type::Response, WorkflowResponseHandling.CreateNotificationEntryCode(), '');
        VerifyWorkflowRules(ToWorkflow, FromWorkflow);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyTemplateToWorkflowMultipleExist()
    var
        FromWorkflow: Record Workflow;
        ToWorkflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowTemplatesPage: TestPage "Workflow Templates";
        WorkflowPage: TestPage Workflow;
        EventConditions: Text;
    begin
        // [SCENARIO] Copy Workflow Template to a new workflow.
        // [GIVEN] An existing workflow template with one or more steps.
        // [GIVEN] Multiple workflows already exist.
        // [WHEN] The user invokes the New Workflow from Template Action.
        // [THEN] All the data in the Workflow Template and Workflow Steps is copied to a new workflow and the new Workflow is opened.

        // Setup
        Initialize();

        // create two existing workflows
        EventConditions :=
          CreateTwoStepsWorkflow(
            FromWorkflow, WorkflowEvent,
            WorkflowResponseHandling.CreateNotificationEntryCode());
        FromWorkflow.Validate(Template, false);
        FromWorkflow.Modify();

        EventConditions :=
          CreateTwoStepsWorkflow(
            FromWorkflow, WorkflowEvent,
            WorkflowResponseHandling.CreateNotificationEntryCode());
        FromWorkflow.Validate(Template, false);
        FromWorkflow.Modify();

        // create workflow template to be copied.
        EventConditions :=
          CreateTwoStepsWorkflow(
            FromWorkflow, WorkflowEvent,
            WorkflowResponseHandling.CreateNotificationEntryCode());
        FromWorkflow.Validate(Template, true);
        FromWorkflow.Modify();

        WorkflowTemplatesPage.OpenView();
        WorkflowTemplatesPage.FILTER.SetFilter(Description, FromWorkflow.Description);
        WorkflowTemplatesPage.First();

        // Exercise.
        WorkflowPage.Trap();
        WorkflowTemplatesPage."New Workflow from Template".Invoke();

        // Verify.
        ToWorkflow.Get(WorkflowPage.Code.Value);
        ToWorkflow.TestField(Description, FromWorkflow.Description);
        VerifyWorkflowSteps(ToWorkflow, WorkflowStep.Type::"Event", WorkflowEvent."Function Name", EventConditions);
        VerifyWorkflowSteps(ToWorkflow, WorkflowStep.Type::Response, WorkflowResponseHandling.CreateNotificationEntryCode(), '');
        VerifyWorkflowRules(ToWorkflow, FromWorkflow);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyWorkflowToWorkflowMultipleExist()
    var
        FromWorkflow: Record Workflow;
        ToWorkflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowsPage: TestPage Workflows;
        WorkflowPage: TestPage Workflow;
        EventConditions: Text;
    begin
        // [SCENARIO] Copy Workflow to a new workflow (duplicate).
        // [GIVEN] An existing workflow with one or more steps.
        // [GIVEN] Multiple workflows already exist.
        // [WHEN] The user invokes the Copy Workflow Action.
        // [THEN] All the data in the Workflow and Workflow Steps is copied to a new workflow and the new Workflow is opened.

        // Setup
        Initialize();
        // create two existing workflows
        EventConditions :=
          CreateTwoStepsWorkflow(
            FromWorkflow, WorkflowEvent,
            WorkflowResponseHandling.CreateNotificationEntryCode());
        FromWorkflow.Validate(Template, false);
        FromWorkflow.Modify();

        EventConditions :=
          CreateTwoStepsWorkflow(
            FromWorkflow, WorkflowEvent,
            WorkflowResponseHandling.CreateNotificationEntryCode());
        FromWorkflow.Validate(Template, false);
        FromWorkflow.Modify();

        // create workflow to be copied.
        EventConditions :=
          CreateTwoStepsWorkflow(
            FromWorkflow, WorkflowEvent,
            WorkflowResponseHandling.CreateNotificationEntryCode());
        FromWorkflow.Validate(Template, false);
        FromWorkflow.Modify();

        WorkflowsPage.OpenView();
        WorkflowsPage.FILTER.SetFilter(Description, FromWorkflow.Description);
        WorkflowsPage.First();

        // Exercise.
        WorkflowPage.Trap();
        WorkflowsPage.CopyWorkflow.Invoke();

        // Verify.
        ToWorkflow.Get(WorkflowPage.Code.Value);
        ToWorkflow.TestField(Description, FromWorkflow.Description);
        VerifyWorkflowSteps(ToWorkflow, WorkflowStep.Type::"Event", WorkflowEvent."Function Name", EventConditions);
        VerifyWorkflowSteps(ToWorkflow, WorkflowStep.Type::Response, WorkflowResponseHandling.CreateNotificationEntryCode(), '');
        VerifyWorkflowRules(ToWorkflow, FromWorkflow);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyWorkflowNotSelectedErr()
    var
        FromWorkflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowsPage: TestPage Workflows;
    begin
        // [SCENARIO] Error when trying to Invoke Copy on a Category line.
        // [GIVEN] An existing workflow with one or more steps.
        // [GIVEN] The current selected line is a Category header line
        // [WHEN] The user invokes the Copy Workflow Action.
        // [THEN] Nothing happens.

        // Setup
        Initialize();

        CreateTwoStepsWorkflow(
          FromWorkflow, WorkflowEvent,
          WorkflowResponseHandling.CreateNotificationEntryCode());
        FromWorkflow.Validate(Template, false);
        FromWorkflow.Modify();

        WorkflowsPage.OpenView();
        WorkflowsPage.FILTER.SetFilter("Workflow Code", '');
        WorkflowsPage.First();

        // Exercise.
        ClearLastError();
        WorkflowsPage.CopyWorkflow.Invoke();

        // Verify.
        Assert.AreEqual('', GetLastErrorText, 'An unexpected error was thrown');
        FromWorkflow.Reset();
        FromWorkflow.SetRange(Template, false);
        Assert.AreEqual(1, FromWorkflow.Count, 'A new workflow was created.')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyTemplateNotSelectedErr()
    var
        FromWorkflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowTemplatesPage: TestPage "Workflow Templates";
    begin
        // [SCENARIO] Error when trying to Invoke Copy on a Category line.
        // [GIVEN] An existing workflow with one or more steps.
        // [GIVEN] The current selected line is a Category header line
        // [WHEN] The user invokes the Copy Workflow Action.
        // [THEN] Nothing happens.

        // Setup
        Initialize();

        CreateTwoStepsWorkflow(
          FromWorkflow, WorkflowEvent,
          WorkflowResponseHandling.CreateNotificationEntryCode());
        FromWorkflow.Validate(Template, true);
        FromWorkflow.Modify();

        WorkflowTemplatesPage.OpenView();
        WorkflowTemplatesPage.FILTER.SetFilter("Workflow Code", '');
        WorkflowTemplatesPage.First();

        // Exercise.
        ClearLastError();
        WorkflowTemplatesPage."New Workflow from Template".Invoke();

        // Verify.
        Assert.AreEqual('', GetLastErrorText, 'An unexpected error was thrown.');
        FromWorkflow.Reset();
        FromWorkflow.SetRange(Template, false);
        Assert.AreEqual(0, FromWorkflow.Count, 'A new workflow was created.')
    end;

    local procedure Initialize()
    begin
        LibraryWorkflow.DeleteAllExistingWorkflows();
    end;

    local procedure CreateTwoStepsWorkflow(var Workflow: Record Workflow; var WorkflowEvent: Record "Workflow Event"; ResponseFunctionName: Code[128]) EventConditions: Text
    var
        WorkflowRule: Record "Workflow Rule";
        EntryPointEventID: Integer;
        ResponseID: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyPurchaseHeaderEvent(WorkflowEvent);

        EntryPointEventID := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent."Function Name");
        ResponseID := LibraryWorkflow.InsertResponseStep(Workflow, ResponseFunctionName, EntryPointEventID);

        EventConditions := StrSubstNo(AmountCondXmlTemplateTxt, Format(LibraryRandom.RandDec(1000, 2)));
        LibraryWorkflow.InsertEventArgument(EntryPointEventID, EventConditions);

        LibraryWorkflow.InsertEventRule(EntryPointEventID, 0, WorkflowRule.Operator::Changed);
        LibraryWorkflow.InsertEventRule(EntryPointEventID, 0, WorkflowRule.Operator::Increased);
        LibraryWorkflow.InsertNotificationArgument(ResponseID, UserId, 0, '');

        Workflow.Enabled := true;
        Workflow.Modify(true);
    end;

    local procedure CreateAnyPurchaseHeaderEvent(var WorkflowEvent: Record "Workflow Event")
    begin
        WorkflowEvent.Init();
        WorkflowEvent."Function Name" := LibraryUtility.GenerateGUID();
        WorkflowEvent.Description := LibraryUtility.GenerateGUID();
        WorkflowEvent."Table ID" := DATABASE::"Purchase Header";
        WorkflowEvent."Request Page ID" := REPORT::"Workflow Event Simple Args";
        WorkflowEvent.Insert(true);
    end;

    local procedure VerifyWorkflowSteps(ToWorkflow: Record Workflow; ActivityType: Option; ActivityName: Code[128]; EventConditions: Text)
    var
        ToWorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        InStream: InStream;
        ActualConditionText: Text;
    begin
        ToWorkflowStep.SetRange("Workflow Code", ToWorkflow.Code);
        ToWorkflowStep.SetRange(Type, ActivityType);
        Assert.AreEqual(1, ToWorkflowStep.Count, 'Unexpected number of steps.');
        ToWorkflowStep.FindFirst();
        ToWorkflowStep.TestField("Function Name", ActivityName);

        if WorkflowStepArgument.Get(ToWorkflowStep.Argument) then begin
            WorkflowStepArgument.CalcFields("Event Conditions");
            WorkflowStepArgument."Event Conditions".CreateInStream(InStream, TextEncoding::UTF8);
            InStream.ReadText(ActualConditionText);
            Assert.AreEqual(EventConditions, ActualConditionText, 'The event condition was not copied correctly');
        end;
    end;

    local procedure VerifyWorkflowRules(ToWorkflow: Record Workflow; FromWorkflow: Record Workflow)
    var
        ToWorkflowStep: Record "Workflow Step";
        ToWorkflowRule: Record "Workflow Rule";
        FromWorkflowStep: Record "Workflow Step";
        FromWorkflowRule: Record "Workflow Rule";
    begin
        ToWorkflowStep.SetRange("Workflow Code", ToWorkflow.Code);
        ToWorkflowStep.SetRange(Type, ToWorkflowStep.Type::"Event");
        if not ToWorkflowStep.FindSet() then
            exit;

        repeat
            FromWorkflowStep.SetRange("Workflow Code", FromWorkflow.Code);
            FromWorkflowStep.SetRange("Function Name", ToWorkflowStep."Function Name");
            FromWorkflowStep.FindFirst();
            FromWorkflowRule.SetRange("Workflow Code", FromWorkflowStep."Workflow Code");
            FromWorkflowRule.SetRange("Workflow Step ID", FromWorkflowStep.ID);
            if FromWorkflowRule.FindSet() then
                repeat
                    ToWorkflowRule.SetRange("Workflow Code", ToWorkflowStep."Workflow Code");
                    ToWorkflowRule.SetRange("Workflow Step ID", ToWorkflowStep.ID);
                    ToWorkflowRule.SetRange(Operator, FromWorkflowRule.Operator);
                    Assert.AreEqual(1, ToWorkflowRule.Count, 'Wrong no. of rules.');
                    ToWorkflowRule.FindFirst();
                    ToWorkflowRule.TestField("Table ID", FromWorkflowRule."Table ID");
                    ToWorkflowRule.TestField("Field No.", FromWorkflowRule."Field No.");
                until FromWorkflowRule.Next() = 0;
        until ToWorkflowStep.Next() = 0;
    end;
}

