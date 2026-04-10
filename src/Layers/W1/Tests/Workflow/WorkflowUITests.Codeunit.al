codeunit 134316 "Workflow UI Tests"
{
    Permissions = TableData "Approval Entry" = i,
                  TableData "Workflow - Record Change" = i;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [UI]
    end;

    var
        InputWorkflowRule: Record "Workflow Rule";
        InputField: Record "Field";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        SelectedEventDesc: Text;
        UIElementDoesNotHaveCorrectStateErr: Label 'The UI Element does not have the correct stat according to the type of the workflow';
        WorkflowExistsAsTemplateErr: Label 'The record already exists, as a workflow template.';
        ShowMessageTestMsg: Label 'Test Message';
        FieldShouldBeVisibleErr: Label 'The field should be visible';
        ValuesAreNotTheSameErr: Label 'The values are not the same';
        ApprovalDetailsOneValTxt: Label '%1; %2 changed from %3 to %4', Comment = '%1 = Record Id, %2 = Field Caption, %3 = Old Value, %4 = New Value';
        ApprovalDetailsTwoValTxt: Label '%1; %2 changed from %3 to %4; %5 changed from %6 to %7', Comment = '%1 = Record Id, %2 = Field Caption 1, %3 = Old Value 1, %4 = New Value 1, %5 = Field Caption 2, %6 = Old Value 2, %7 = New Value 2';

    [Test]
    [Scope('OnPrem')]
    procedure TestUIForWorkflows()
    var
        Workflow: Record Workflow;
        WorkflowTemplate: Record Workflow;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] The UI changes visibility and enabled state based on the template flag in a Workflow.
        // [GIVEN] A normal workflow and a workflow template.
        // [WHEN] The Workflow page is opened to show a record.
        // [THEN] The actions are visible and the fields are editable only for the normal workflow.
        // [THEN] The actions are not visible and the fields are not editable for the workflow template.

        // Setup
        SetApplicationArea();
        SelectedEventDesc := '';
        LibraryWorkflow.CreateWorkflow(Workflow);
        LibraryWorkflow.InsertEntryPointEventStep(Workflow, '');

        LibraryWorkflow.CreateWorkflow(WorkflowTemplate);
        LibraryWorkflow.InsertEntryPointEventStep(WorkflowTemplate, '');
        WorkflowTemplate.Validate(Template, true);
        WorkflowTemplate.Modify();

        // Verify
        ValidateUIForWorkflowPage(Workflow);
        ValidateUIForWorkflowPage(WorkflowTemplate)
    end;

    [Test]
    [HandlerFunctions('ModalLookupHandler')]
    [Scope('OnPrem')]
    procedure TestForNewWorkflow()
    var
        WorkflowPage: TestPage Workflow;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] The user can enter data in the "When" event column when creating a new workflow.
        // [GIVEN] No Workflow records exist
        // [WHEN] The user openes the Workflow card to create a new Workflow.
        // [THEN] The "When" event column is editable and the user can add a new event in the workflow.

        // Setup
        SelectedEventDesc := '';
        // Exercise
        WorkflowPage.OpenNew();
        WorkflowPage.Code.SetValue('Test');
        WorkflowPage.Description.SetValue('Description');
        WorkflowPage.WorkflowSubpage."Event Description".Lookup();

        // Validate
        WorkflowPage.WorkflowSubpage."Event Description".AssertEquals(SelectedEventDesc);
        Assert.IsTrue(WorkflowPage.WorkflowSubpage."Event Description".Enabled(), 'The When event column is not editable.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertWorkflowWithSameCodeAsTemplate()
    var
        Workflow: Record Workflow;
        WorkflowTemplate: Record Workflow;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] When an user wants to create a new workflow using the same code as the code of an template workflow, they will get an error.
        // [GIVEN] There is an workflow template.
        // [WHEN] The user creates a new workflow using the same code as the workflow template.
        // [THEN] They will see an error.

        // Setup
        LibraryWorkflow.CreateTemplateWorkflow(WorkflowTemplate);

        // Execute
        Workflow.Init();
        asserterror Workflow.Validate(Code, WorkflowTemplate.Code);

        // Verify
        Assert.ExpectedError(WorkflowExistsAsTemplateErr);
    end;

    [Test]
    [HandlerFunctions('EmptyEventConditionsPageHandler')]
    [Scope('OnPrem')]
    procedure TestAssistEditConditionOnEventWithIncludeXRecOpensEventConditionsPage()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowPage: TestPage Workflow;
        EventFunctionName: Code[50];
    begin
        // [SCENARIO] When an user clicks on the assist edit for setting conditions on an event where include xrec is set to true, it opens up the Event Conditons page.
        // [GIVEN] There is an workflow.
        // [GIVEN] There is an event where the "Include XRec" is set to TRUE
        // [WHEN] The user creates clicks on the assist edit to set condtions.
        // [THEN] User gets the Event Conditions page shown.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EventFunctionName := LibraryUtility.GenerateRandomCode(WorkflowEvent.FieldNo("Function Name"), DATABASE::"Workflow Event");
        WorkflowEventHandling.AddEventToLibrary(EventFunctionName, DATABASE::Customer, LibraryUtility.GenerateGUID(), 0, true);

        LibraryWorkflow.InsertEntryPointEventStep(Workflow, EventFunctionName);
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoRecord(Workflow);

        // Execute
        WorkflowPage.WorkflowSubpage.Condition.AssistEdit();

        // Verify - Page handler setting ensure Event Conditions page is opened
    end;

    [Test]
    [HandlerFunctions('EventConditionsOKWithSetRulesPageHandler')]
    [Scope('OnPrem')]
    procedure TestOKOnEventConditionsPageSavesTheRule()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowRule: Record "Workflow Rule";
        Customer: Record Customer;
        WorkflowPage: TestPage Workflow;
        EventFunctionName: Code[50];
        StepId: Integer;
    begin
        // [SCENARIO] User is able to set event rules through the 'Event Conditions' page.
        // [GIVEN] There is an workflow.
        // [GIVEN] There is an event where the "Include XRec" is set to TRUE
        // [WHEN] The user creates clicks on the assist edit to set condtions.
        // [THEN] User gets the Event Conditions page shown.
        // [WHEN] The user sets an event rules.
        // [THEN] The rules are saved for the event with workflow and step information.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EventFunctionName := LibraryUtility.GenerateRandomCode(WorkflowEvent.FieldNo("Function Name"), DATABASE::"Workflow Event");
        WorkflowEventHandling.AddEventToLibrary(EventFunctionName, DATABASE::Customer, LibraryUtility.GenerateGUID(), 0, true);

        StepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EventFunctionName);

        // Setup - Prepare the input workflowrule for the page handler to work with
        Clear(InputWorkflowRule);
        InputWorkflowRule."Table ID" := DATABASE::Customer;
        InputWorkflowRule."Field No." := Customer.FieldNo("Credit Limit (LCY)");
        InputWorkflowRule.CalcFields("Field Caption");
        InputWorkflowRule.Operator := InputWorkflowRule.Operator::Increased;

        // Execute - Page handler will create the rules
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoRecord(Workflow);
        WorkflowPage.WorkflowSubpage.First();
        WorkflowPage.WorkflowSubpage.Condition.AssistEdit();

        // Verify
        WorkflowRule.SetRange("Workflow Code", Workflow.Code);
        WorkflowRule.SetRange("Workflow Step ID", StepId);

        Assert.IsFalse(WorkflowRule.IsEmpty, 'Rule is not created');
        Assert.IsTrue(WorkflowRule.Count = 1, 'More than one rule is created');
        WorkflowRule.FindFirst();
        WorkflowRule.TestField("Table ID", DATABASE::Customer);
        WorkflowRule.TestField("Field No.", Customer.FieldNo("Credit Limit (LCY)"));
        WorkflowRule.TestField(Operator, WorkflowRule.Operator::Increased);
    end;

    [Test]
    [HandlerFunctions('EventConditionsCancelWithSetRulesPageHandler')]
    [Scope('OnPrem')]
    procedure TestCancelOnEventConditionsPageDoesNotSaveTheRule()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowRule: Record "Workflow Rule";
        Customer: Record Customer;
        WorkflowPage: TestPage Workflow;
        EventFunctionName: Code[50];
        StepId: Integer;
    begin
        // [SCENARIO] The event rules set by the user is not saved if the user cancels the page.
        // [GIVEN] There is an workflow.
        // [GIVEN] There is an event where the "Include XRec" is set to TRUE
        // [WHEN] The user creates clicks on the assist edit to set condtions.
        // [THEN] User gets the Event Conditions page shown.
        // [WHEN] The user sets an event rules.
        // [THEN] The rule is not saved when the page is cancelled.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EventFunctionName := LibraryUtility.GenerateRandomCode(WorkflowEvent.FieldNo("Function Name"), DATABASE::"Workflow Event");
        WorkflowEventHandling.AddEventToLibrary(EventFunctionName, DATABASE::Customer, LibraryUtility.GenerateGUID(), 0, true);

        StepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EventFunctionName);

        // Setup - Prepare the input workflowrule for the page handler to work with
        Clear(InputWorkflowRule);
        InputWorkflowRule."Table ID" := DATABASE::Customer;
        InputWorkflowRule."Field No." := Customer.FieldNo("Credit Limit (LCY)");
        InputWorkflowRule.CalcFields("Field Caption");
        InputWorkflowRule.Operator := InputWorkflowRule.Operator::Changed;

        // Execute - Page handler will create the rules
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoRecord(Workflow);
        WorkflowPage.WorkflowSubpage.First();
        WorkflowPage.WorkflowSubpage.Condition.AssistEdit();

        // Verify
        WorkflowRule.SetRange("Workflow Code", Workflow.Code);
        WorkflowRule.SetRange("Workflow Step ID", StepId);

        Assert.IsTrue(WorkflowRule.IsEmpty, 'Rule is created');
    end;

    [Test]
    [HandlerFunctions('EventConditionsOKWithSetRulesPageHandler')]
    [Scope('OnPrem')]
    procedure TestOKOnEventConditionsPageWithEmptyFieldDoesNotSaveTheRule()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowRule: Record "Workflow Rule";
        WorkflowPage: TestPage Workflow;
        EventFunctionName: Code[50];
        StepId: Integer;
    begin
        // [SCENARIO] No rule is saved when a user selects OK on the Event Conditions page where the field is empty.
        // [GIVEN] There is an workflow.
        // [GIVEN] There is an event where the "Include XRec" is set to TRUE
        // [WHEN] The user clicks on OK in the Event Conditions page where the field caption is empty.
        // [THEN] No rule is saved.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EventFunctionName := LibraryUtility.GenerateRandomCode(WorkflowEvent.FieldNo("Function Name"), DATABASE::"Workflow Event");
        WorkflowEventHandling.AddEventToLibrary(EventFunctionName, DATABASE::Customer, LibraryUtility.GenerateGUID(), 0, true);

        StepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EventFunctionName);

        // Setup - Prepare the input workflowrule for the page handler to work with
        Clear(InputWorkflowRule);
        InputWorkflowRule."Table ID" := DATABASE::Customer;
        InputWorkflowRule."Field No." := 0;
        InputWorkflowRule.CalcFields("Field Caption");
        InputWorkflowRule.Operator := InputWorkflowRule.Operator::Increased;

        // Execute - Page handler will create the rules
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoRecord(Workflow);
        WorkflowPage.WorkflowSubpage.First();
        WorkflowPage.WorkflowSubpage.Condition.AssistEdit();

        // Verify
        WorkflowRule.SetRange("Workflow Code", Workflow.Code);
        WorkflowRule.SetRange("Workflow Step ID", StepId);

        Assert.IsTrue(WorkflowRule.IsEmpty, 'Rule is created');
    end;

    [Test]
    [HandlerFunctions('EventConditionsOKWithSetRulesPageHandler')]
    [Scope('OnPrem')]
    procedure TestOKOnEventConditionsPageWithEmptyFieldClearsTheRule()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowStep: Record "Workflow Step";
        WorkflowRule: Record "Workflow Rule";
        Customer: Record Customer;
        WorkflowPage: TestPage Workflow;
        EventFunctionName: Code[50];
        StepId: Integer;
    begin
        // [SCENARIO] Rule is cleared when the user selects OK on the Event Conditions page that already has a rule set.
        // [GIVEN] There is an workflow.
        // [GIVEN] There is an event where the "Include XRec" is set to TRUE
        // [WHEN] The user clicks on OK in the Event Conditions page where the field caption is empty.
        // [THEN] Existing rule is cleared.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EventFunctionName := LibraryUtility.GenerateRandomCode(WorkflowEvent.FieldNo("Function Name"), DATABASE::"Workflow Event");
        WorkflowEventHandling.AddEventToLibrary(EventFunctionName, DATABASE::Customer, LibraryUtility.GenerateGUID(), 0, true);

        StepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EventFunctionName);

        // Setup - Prepare the input workflowrule for the page handler to work with
        LibraryWorkflow.InsertEventRule(StepId, Customer.FieldNo("Credit Limit (LCY)"), WorkflowRule.Operator::Increased);

        WorkflowStep.Get(Workflow.Code, StepId);
        Assert.IsTrue(WorkflowStep.FindWorkflowRules(WorkflowRule), 'Rule was not found');

        Clear(InputWorkflowRule);
        InputWorkflowRule."Table ID" := DATABASE::Customer;
        InputWorkflowRule."Field No." := 0;
        InputWorkflowRule.CalcFields("Field Caption");
        InputWorkflowRule.Operator := InputWorkflowRule.Operator::Increased;

        // Execute - Page handler will create the rules
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoRecord(Workflow);
        WorkflowPage.WorkflowSubpage.First();
        WorkflowPage.WorkflowSubpage.Condition.AssistEdit();

        // Verify
        Assert.IsFalse(WorkflowStep.FindWorkflowRules(WorkflowRule), 'Rule is not deleted');
    end;

    [Test]
    [HandlerFunctions('EventConditionsTriggeringFieldLookupPageHandler,FieldListWithSelectionCheckPageHandler')]
    [Scope('OnPrem')]
    procedure TestFieldCaptionLookupOnEventConditionsOpensFieldListPageWithSelection()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowRule: Record "Workflow Rule";
        WorkflowStep: Record "Workflow Step";
        Customer: Record Customer;
        WorkflowPage: TestPage Workflow;
        EventFunctionName: Code[50];
        StepId: Integer;
    begin
        // [SCENARIO] Lookup on field caption on a existing rule, opens up the Field List where the field caption from the current rule is selected.
        // [GIVEN] There is an workflow.
        // [GIVEN] There is an event where the "Include XRec" is set to TRUE.
        // [GIVEN] A step exists in the workflow and a rule exists.
        // [WHEN] The user clicks on the lookup.
        // [THEN] Field List page opens up with an selection on the current field from the rule.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EventFunctionName := LibraryUtility.GenerateRandomCode(WorkflowEvent.FieldNo("Function Name"), DATABASE::"Workflow Event");
        WorkflowEventHandling.AddEventToLibrary(EventFunctionName, DATABASE::Customer, LibraryUtility.GenerateGUID(), 0, true);

        StepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EventFunctionName);
        WorkflowStep.Get(Workflow.Code, StepId);

        // Setup - Prepare the input workflowrule for the page handler to work with
        LibraryWorkflow.InsertEventRule(StepId, Customer.FieldNo(Amount), WorkflowRule.Operator::Increased);
        Assert.IsTrue(WorkflowStep.FindWorkflowRules(WorkflowRule), 'Rule was not found');

        Clear(InputField);
        InputField.SetRange(TableNo, DATABASE::Customer);
        InputField.SetRange("No.", Customer.FieldNo(Amount));
        InputField.FindFirst();

        // Execute - Page handler will lookup the field caption
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoRecord(Workflow);
        WorkflowPage.WorkflowSubpage.First();
        WorkflowPage.WorkflowSubpage.Condition.AssistEdit();

        // Verify - FieldListWithSelectionCheckPageHandler does the verification
    end;

    [Test]
    [HandlerFunctions('EventConditionsTriggeringFieldAssistEditPageHandler,FieldListWithFieldNameCheckPageHandler')]
    [Scope('OnPrem')]
    procedure TestFieldCaptionValidationOnEventConditionsOpensFieldListPageWithFilteredOnCaption()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowRule: Record "Workflow Rule";
        WorkflowStep: Record "Workflow Step";
        Customer: Record Customer;
        WorkflowPage: TestPage Workflow;
        EventFunctionName: Code[50];
        StepId: Integer;
    begin
        // [SCENARIO] Validation of the partially filled FieldCaption on the Event Conditions page opens up a Field list where the entries are filtered by entered value.
        // [GIVEN] There is an workflow.
        // [GIVEN] There is an event where the "Include XRec" is set to TRUE
        // [WHEN] The user types in the field caption partially and tabs out.
        // [THEN] Field List page is opened where the entries are filtered by the entered partial field caption.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EventFunctionName := LibraryUtility.GenerateRandomCode(WorkflowEvent.FieldNo("Function Name"), DATABASE::"Workflow Event");
        WorkflowEventHandling.AddEventToLibrary(EventFunctionName, DATABASE::Customer, LibraryUtility.GenerateGUID(), 0, true);

        StepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EventFunctionName);

        // Setup - Prepare the input workflowrule for the page handler to work with
        LibraryWorkflow.InsertEventRule(StepId, Customer.FieldNo(Amount), WorkflowRule.Operator::Increased);
        WorkflowStep.Get(Workflow.Code, StepId);
        Assert.IsTrue(WorkflowStep.FindWorkflowRules(WorkflowRule), 'Rule was not found');

        Clear(InputField);
        InputField.SetRange(TableNo, DATABASE::Customer);
        InputField.SetRange("No.", Customer.FieldNo("Shipment Method Code"));
        InputField.FindFirst();
        InputField."Field Caption" := CopyStr(InputField."Field Caption", 1, 2);

        // Execute - Page handler will enter partial field caption
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoRecord(Workflow);
        WorkflowPage.WorkflowSubpage.First();
        WorkflowPage.WorkflowSubpage.Condition.AssistEdit();

        // Verify - FieldListWithFieldNameCheckPageHandler does the verification
    end;

    [Test]
    [HandlerFunctions('FieldPageModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestRevertFieldChangesResponseOptions()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        WorkflowStepResponse: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowRule: Record "Workflow Rule";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowResponseOptions: TestPage "Workflow Response Options";
        EntryPointEventStepId: Integer;
        ResponseStepId: Integer;
    begin
        // [SCENARIO] Validation of field selection works for RevertValueForField response.
        // [GIVEN] A workflow with the RevertValueForField response.
        // [WHEN] The user navigates to the response options.
        // [THEN] The user can choose one of the fields from the event table.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        LibraryWorkflow.InsertEventRule(EntryPointEventStepId, Customer.FieldNo("Credit Limit (LCY)"), WorkflowRule.Operator::Changed);
        ResponseStepId := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.RevertValueForFieldCode(),
            EntryPointEventStepId);
        LibraryWorkflow.InsertRecChangeValueArgument(ResponseStepId, 0, 0);

        WorkflowStepResponse.Get(Workflow.Code, ResponseStepId);
        WorkflowStepArgument.Get(WorkflowStepResponse.Argument);

        // Exercise
        WorkflowResponseOptions.OpenView();
        WorkflowResponseOptions.GotoRecord(WorkflowStepArgument);

        LibraryVariableStorage.Enqueue(Customer.FieldCaption("Credit Limit (LCY)"));

        Assert.IsTrue(WorkflowResponseOptions.TableFieldRevert.Visible(), 'The field should be visible');

        WorkflowResponseOptions.TableFieldRevert.Lookup();
        WorkflowResponseOptions.OK().Invoke();

        // Verify
        WorkflowStepArgument.Find();
        Assert.AreEqual(18, WorkflowStepArgument."Table No.", 'The wrong field was selected');
        Assert.AreEqual(20, WorkflowStepArgument."Field No.", 'The wrong field was selected');
    end;

    [Test]
    [HandlerFunctions('FieldPageModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestApplyNewValuesResponseOptions()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        WorkflowStepResponse: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowRule: Record "Workflow Rule";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowResponseOptions: TestPage "Workflow Response Options";
        EntryPointEventStepId: Integer;
        ResponseStepId: Integer;
        ApplyNewValuesResponseId: Integer;
    begin
        // [SCENARIO] Validation of field selection works for ApplyNewValues response - one field.
        // [GIVEN] A workflow with the RevertValueForField response and ApplyNewValuesResponse.
        // [WHEN] The user navigates to the response options.
        // [THEN] The user can choose one of the fields from the event table.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        LibraryWorkflow.InsertEventRule(EntryPointEventStepId, Customer.FieldNo("Credit Limit (LCY)"), WorkflowRule.Operator::Changed);
        ResponseStepId := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.RevertValueForFieldCode(),
            EntryPointEventStepId);
        LibraryWorkflow.InsertRecChangeValueArgument(ResponseStepId, DATABASE::Customer, Customer.FieldNo("Credit Limit (LCY)"));
        ApplyNewValuesResponseId := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ApplyNewValuesCode(),
            ResponseStepId);

        WorkflowStepResponse.Get(Workflow.Code, ApplyNewValuesResponseId);
        WorkflowStepArgument.Get(WorkflowStepResponse.Argument);

        // Exercise
        WorkflowResponseOptions.OpenView();
        WorkflowResponseOptions.GotoRecord(WorkflowStepArgument);

        LibraryVariableStorage.Enqueue(Customer.FieldCaption("Credit Limit (LCY)"));

        Assert.IsFalse(WorkflowResponseOptions.TableFieldApply.Visible(), 'The field should not be visible');

        WorkflowResponseOptions.ApplyAllValues.SetValue(false);

        Assert.IsTrue(WorkflowResponseOptions.TableFieldApply.Visible(), 'The field should be visible');

        WorkflowResponseOptions.TableFieldApply.Lookup();
        WorkflowResponseOptions.OK().Invoke();

        // Verify
        WorkflowStepArgument.Find();
        WorkflowStepArgument.TestField("Table No.", DATABASE::Customer);
        WorkflowStepArgument.TestField("Field No.", Customer.FieldNo("Credit Limit (LCY)"));

        // Exercise
        WorkflowResponseOptions.OpenView();
        WorkflowResponseOptions.GotoRecord(WorkflowStepArgument);

        Assert.IsTrue(WorkflowResponseOptions.TableFieldApply.Visible(), 'The field should be visible');

        WorkflowResponseOptions.ApplyAllValues.SetValue(true);

        Assert.IsFalse(WorkflowResponseOptions.TableFieldApply.Visible(), 'The field should not be visible');

        WorkflowResponseOptions.OK().Invoke();

        // Verify
        WorkflowStepArgument.Find();
        WorkflowStepArgument.TestField("Table No.", 0);
        WorkflowStepArgument.TestField("Field No.", 0);
    end;

    [Test]
    [HandlerFunctions('MultiFieldPageModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestApplyNewValuesLookupResponseOptions()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        WorkflowStepResponse: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowRule: Record "Workflow Rule";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowResponseOptions: TestPage "Workflow Response Options";
        EntryPointEventStepId: Integer;
        ResponseStepId1: Integer;
        ResponseStepId2: Integer;
        ApplyNewValuesResponseId: Integer;
    begin
        // [SCENARIO] Validation of field selection works for ApplyNewValues response - two fields.
        // [GIVEN] A workflow with two RevertValueForField responses and ApplyNewValuesResponse.
        // [WHEN] The user navigates to the response options.
        // [THEN] The user can choose one of the fields from the event table.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        LibraryWorkflow.InsertEventRule(EntryPointEventStepId, Customer.FieldNo("Credit Limit (LCY)"), WorkflowRule.Operator::Changed);
        ResponseStepId1 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.RevertValueForFieldCode(),
            EntryPointEventStepId);
        LibraryWorkflow.InsertRecChangeValueArgument(ResponseStepId1, DATABASE::Customer, Customer.FieldNo("Credit Limit (LCY)"));
        ResponseStepId2 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.RevertValueForFieldCode(),
            ResponseStepId1);
        LibraryWorkflow.InsertRecChangeValueArgument(ResponseStepId2, DATABASE::Customer, Customer.FieldNo("Customer Posting Group"));
        ApplyNewValuesResponseId := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ApplyNewValuesCode(),
            ResponseStepId2);

        WorkflowStepResponse.Get(Workflow.Code, ApplyNewValuesResponseId);
        WorkflowStepArgument.Get(WorkflowStepResponse.Argument);

        // Exercise
        WorkflowResponseOptions.OpenView();
        WorkflowResponseOptions.GotoRecord(WorkflowStepArgument);

        LibraryVariableStorage.Enqueue(Customer.FieldCaption("Credit Limit (LCY)"));
        LibraryVariableStorage.Enqueue(Customer.FieldCaption("Customer Posting Group"));

        Assert.IsFalse(WorkflowResponseOptions.TableFieldApply.Visible(), 'The field should not be visible');

        WorkflowResponseOptions.ApplyAllValues.SetValue(false);

        Assert.IsTrue(WorkflowResponseOptions.TableFieldApply.Visible(), 'The field should be visible');

        WorkflowResponseOptions.TableFieldApply.Lookup();
        WorkflowResponseOptions.OK().Invoke();

        // Verify
        WorkflowStepArgument.Find();
        Assert.AreEqual(DATABASE::Customer, WorkflowStepArgument."Table No.", 'The wrong field was selected');
        Assert.AreEqual(Customer.FieldNo("Customer Posting Group"), WorkflowStepArgument."Field No.", 'The wrong field was selected');

        // Exercise
        WorkflowResponseOptions.OpenView();
        WorkflowResponseOptions.GotoRecord(WorkflowStepArgument);

        Assert.IsTrue(WorkflowResponseOptions.TableFieldApply.Visible(), 'The field should be visible');

        WorkflowResponseOptions.ApplyAllValues.SetValue(true);

        Assert.IsFalse(WorkflowResponseOptions.TableFieldApply.Visible(), 'The field should not be visible');

        WorkflowResponseOptions.OK().Invoke();

        // Verify
        WorkflowStepArgument.Find();
        Assert.AreEqual(0, WorkflowStepArgument."Table No.", 'The wrong field was selected');
        Assert.AreEqual(0, WorkflowStepArgument."Field No.", 'The wrong field was selected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeFactboxOnRequestsToApprovePageWithOneChange()
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowRecordChange: Record "Workflow - Record Change";
        Customer: Record Customer;
        RequeststoApprove: TestPage "Requests to Approve";
        WorkflowInstanceId: Guid;
        OldValue: Decimal;
        NewValue: Decimal;
        ApprovalDetails: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] The Change factbox on the Requests to approve shows the change information when the number of changes is one.
        // [GIVEN] A workflow instance.
        // [GIVEN] A customer record.
        // [GIVEN] An approval entry and a change record related to the customer record and the workflow instance.
        // [WHEN] The Requests to Approve page is opened.
        // [THEN] The Change factbox shows the information about the change associated.
        WorkflowInstanceId := CreateGuid();
        OldValue := LibraryRandom.RandDec(1000, 2);

        LibrarySales.CreateCustomer(Customer);

        CreateApprovalEntry(ApprovalEntry, Customer.RecordId, CopyStr(UserId(), 1, 50), WorkflowInstanceId);
        CreateRecordChange(WorkflowRecordChange, Customer.RecordId, Customer.FieldNo("Credit Limit (LCY)"), Format(OldValue, 0, 9), WorkflowInstanceId);

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        NewValue := Customer."Credit Limit (LCY)";

        ApprovalDetails := StrSubstNo(ApprovalDetailsOneValTxt, Customer.RecordId, Customer.FieldCaption("Credit Limit (LCY)"), Format(OldValue, 0, 9), Format(NewValue, 0, 9));
        Assert.AreEqual(ApprovalDetails, RequeststoApprove.Details.Value, 'Record details seem to be wrong');

        Assert.AreEqual(Customer.FieldCaption("Credit Limit (LCY)"), RequeststoApprove.Change.Field.Value, 'Field caption is not displayed correctly');
        Assert.AreEqual(Format(OldValue, 0, 9), Format(RequeststoApprove.Change.OldValue.Value, 0, 9), 'Old value is not displayed correctly');
        Assert.AreEqual(Format(NewValue, 0, 9), Format(RequeststoApprove.Change.NewValue.Value, 0, 9), 'New value is not displayed correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeFactboxOnRequestsToApprovePageWithMultipleChange()
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowRecordChange: Record "Workflow - Record Change";
        Customer: Record Customer;
        RequeststoApprove: TestPage "Requests to Approve";
        WorkflowInstanceId: Guid;
        OldValue1: Decimal;
        OldValue2: Decimal;
        NewValue1: Decimal;
        NewValue2: Decimal;
        ApprovalDetails: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] The Change factbox on the Requests to approve shows the change information when the number of changes is more than one.
        // [GIVEN] A workflow instance.
        // [GIVEN] A customer record.
        // [GIVEN] An approval entry and a couple of change records related to the customer record and the workflow instance.
        // [WHEN] The Requests to Approve page is opened.
        // [THEN] The Change factbox shows the information about both the changes associated.
        WorkflowInstanceId := CreateGuid();
        OldValue1 := LibraryRandom.RandDec(1000, 2);
        OldValue2 := LibraryRandom.RandDec(1000, 2);

        Customer.FindFirst();
        CreateApprovalEntry(ApprovalEntry, Customer.RecordId, UserId, WorkflowInstanceId);
        CreateRecordChange(WorkflowRecordChange, Customer.RecordId, Customer.FieldNo("Credit Limit (LCY)"), Format(OldValue1, 0, 9), WorkflowInstanceId);
        CreateRecordChange(WorkflowRecordChange, Customer.RecordId, Customer.FieldNo("Credit Amount (LCY)"), Format(OldValue2, 0, 9), WorkflowInstanceId);

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);

        NewValue1 := Customer."Credit Limit (LCY)";
        NewValue2 := Customer."Credit Amount (LCY)";

        ApprovalDetails := StrSubstNo(ApprovalDetailsTwoValTxt, Customer.RecordId, Customer.FieldCaption("Credit Limit (LCY)"), Format(OldValue1, 0, 9), Format(NewValue1, 0, 9), Customer.FieldCaption("Credit Amount (LCY)"), Format(OldValue2, 0, 9), Format(NewValue2, 0, 9));
        Assert.AreEqual(ApprovalDetails, RequeststoApprove.Details.Value, 'Record details seem to be wrong');

        Assert.AreEqual(Customer.FieldCaption("Credit Limit (LCY)"), Format(RequeststoApprove.Change.Field.Value, 0, 1), 'Field caption is not displayed correctly');
        Assert.AreEqual(Format(OldValue1, 0, 9), Format(RequeststoApprove.Change.OldValue.Value, 0, 9), 'Old value is not displayed correctly');
        Assert.AreEqual(Format(NewValue1, 0, 9), Format(RequeststoApprove.Change.NewValue.Value, 0, 9), 'New value is not displayed correctly');

        RequeststoApprove.Change.Next();

        Assert.AreEqual(Customer.FieldCaption("Credit Amount (LCY)"), RequeststoApprove.Change.Field.Value, 'Field caption is not displayed correctly');
        Assert.AreEqual(Format(OldValue2, 0, 9), Format(RequeststoApprove.Change.OldValue.Value, 0, 9), 'Old value is not displayed correctly');
        Assert.AreEqual(Format(NewValue2, 0, 9), Format(RequeststoApprove.Change.NewValue.Value, 0, 9), 'New value is not displayed correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeFactboxOnRequestsToApprovePageWithNoChange()
    var
        ApprovalEntry: Record "Approval Entry";
        Customer: Record Customer;
        RequeststoApprove: TestPage "Requests to Approve";
        WorkflowInstanceId: Guid;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] The Change factbox on the Requests to approve shows the change information when there are no change records.
        // [GIVEN] A workflow instance.
        // [GIVEN] A customer record.
        // [GIVEN] An approval entry associated to the customer record and the workflow instance.
        // [WHEN] The Requests to Approve page is opened.
        // [THEN] The Change factbox is empty.
        WorkflowInstanceId := CreateGuid();

        Customer.FindFirst();
        CreateApprovalEntry(ApprovalEntry, Customer.RecordId, UserId, WorkflowInstanceId);

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Comment.AssertEquals(true);
        Assert.AreEqual(Format(Customer.RecordId, 0, 1), RequeststoApprove.Details.Value, 'Record details seem to be wrong');

        Assert.AreEqual('', RequeststoApprove.Change.Field.Value, 'Field caption is not displayed correctly');
        Assert.AreEqual('', RequeststoApprove.Change.OldValue.Value, 'Old value is not displayed correctly');
        Assert.AreEqual('', RequeststoApprove.Change.NewValue.Value, 'New value is not displayed correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCommentFactboxOnRequestsToApprovePageWithOneChange()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalCommentLine: Record "Approval Comment Line";
        WorkflowRecordChange: Record "Workflow - Record Change";
        Customer: Record Customer;
        RequeststoApprove: TestPage "Requests to Approve";
        WorkflowInstanceId: Guid;
        OldValue: Decimal;
        Comment: Text[80];
    begin
        // [UNITTEST] The Comment factbox on the Requests to approve shows the comment..
        // [GIVEN] A workflow instance.
        // [GIVEN] A customer record.
        // [GIVEN] An approval entry and a comment record related to the workflow instance.
        // [WHEN] The Requests to Approve page is opened.
        // [THEN] The Comment factbox shows the information about the comments.
        WorkflowInstanceId := CreateGuid();
        OldValue := LibraryRandom.RandDec(1000, 2);

        LibrarySales.CreateCustomer(Customer);

        Comment := CreateGuid();
        CreateApprovalEntry(ApprovalEntry, Customer.RecordId, UserId, WorkflowInstanceId);
        CreateApprovalComment(ApprovalCommentLine, ApprovalEntry, Comment);
        CreateRecordChange(WorkflowRecordChange, Customer.RecordId,
          Customer.FieldNo("Credit Limit (LCY)"), Format(OldValue, 0, 9), WorkflowInstanceId);

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Comment.AssertEquals(true);
        RequeststoApprove.CommentsFactBox.First();

        RequeststoApprove.CommentsFactBox.Comment.AssertEquals(Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCommentFactboxOnRequestsToApprovePageWithMultipleChange()
    var
        ApprovalEntry1: Record "Approval Entry";
        ApprovalCommentLine1: Record "Approval Comment Line";
        ApprovalEntry2: Record "Approval Entry";
        ApprovalCommentLine2: Record "Approval Comment Line";
        WorkflowRecordChange: Record "Workflow - Record Change";
        Customer: Record Customer;
        RequeststoApprove: TestPage "Requests to Approve";
        WorkflowInstanceId: Guid;
        OldValue: Decimal;
        Comment1: Text[80];
        Comment2: Text[80];
    begin
        // [UNITTEST] The Comment factbox on the Requests to approve shows the comment for each approval entry.
        // [GIVEN] A workflow instance.
        // [GIVEN] A customer record.
        // [GIVEN] Two approval entry and a comment record related to the workflow instance.
        // [WHEN] The Requests to Approve page is opened.
        // [THEN] The Comment factbox shows the information about the comments.
        WorkflowInstanceId := CreateGuid();
        OldValue := LibraryRandom.RandDec(1000, 2);

        Comment1 := CreateGuid();
        LibrarySales.CreateCustomer(Customer);
        CreateApprovalEntry(ApprovalEntry1, Customer.RecordId, UserId, WorkflowInstanceId);
        CreateApprovalComment(ApprovalCommentLine1, ApprovalEntry1, Comment1);
        CreateRecordChange(WorkflowRecordChange, Customer.RecordId, Customer.FieldNo("Credit Limit (LCY)"), Format(OldValue, 0, 9), WorkflowInstanceId);

        Comment2 := CreateGuid();
        WorkflowInstanceId := CreateGuid();
        LibrarySales.CreateCustomer(Customer);
        CreateApprovalEntry(ApprovalEntry2, Customer.RecordId, UserId, WorkflowInstanceId);
        CreateApprovalComment(ApprovalCommentLine2, ApprovalEntry2, Comment2);
        CreateRecordChange(WorkflowRecordChange, Customer.RecordId, Customer.FieldNo("Credit Limit (LCY)"), Format(OldValue, 0, 9), WorkflowInstanceId);

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry1);
        RequeststoApprove.Comment.AssertEquals(true);
        RequeststoApprove.CommentsFactBox.First();

        RequeststoApprove.CommentsFactBox.Comment.AssertEquals(Comment1);
        Assert.IsFalse(RequeststoApprove.CommentsFactBox.Next(), 'Too many elements');

        RequeststoApprove.GotoRecord(ApprovalEntry2);
        RequeststoApprove.Comment.AssertEquals(true);
        RequeststoApprove.CommentsFactBox.First();

        RequeststoApprove.CommentsFactBox.Comment.AssertEquals(Comment2);
        Assert.IsFalse(RequeststoApprove.CommentsFactBox.Next(), 'Too many elements');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCommentFactboxOnRequestsToApprovePageWithMultipleChangesForSameRecord()
    var
        ApprovalEntry1: Record "Approval Entry";
        ApprovalCommentLine1: Record "Approval Comment Line";
        ApprovalEntry2: Record "Approval Entry";
        ApprovalCommentLine2: Record "Approval Comment Line";
        WorkflowRecordChange: Record "Workflow - Record Change";
        Customer: Record Customer;
        RequeststoApprove: TestPage "Requests to Approve";
        WorkflowInstanceId: Guid;
        OldValue: Decimal;
        Comment1: Text[80];
        Comment2: Text[80];
    begin
        // [UNITTEST] The Comment factbox on the Requests to approve shows the comment for each approval entry.
        // [GIVEN] A workflow instance.
        // [GIVEN] A customer record.
        // [GIVEN] Two approval entry and a comment record related to the workflow instance.
        // [WHEN] The Requests to Approve page is opened.
        // [THEN] The Comment factbox shows the information about the comments.
        WorkflowInstanceId := CreateGuid();
        OldValue := LibraryRandom.RandDec(1000, 2);

        Comment1 := CreateGuid();
        LibrarySales.CreateCustomer(Customer);
        CreateApprovalEntry(ApprovalEntry1, Customer.RecordId, UserId, WorkflowInstanceId);
        CreateApprovalComment(ApprovalCommentLine1, ApprovalEntry1, Comment1);
        CreateRecordChange(WorkflowRecordChange, Customer.RecordId, Customer.FieldNo("Credit Limit (LCY)"), Format(OldValue, 0, 9), WorkflowInstanceId);

        Comment2 := CreateGuid();
        WorkflowInstanceId := CreateGuid();
        CreateApprovalEntry(ApprovalEntry2, Customer.RecordId, UserId, WorkflowInstanceId);
        CreateApprovalComment(ApprovalCommentLine2, ApprovalEntry2, Comment2);
        CreateRecordChange(WorkflowRecordChange, Customer.RecordId, Customer.FieldNo("Credit Limit (LCY)"), Format(OldValue, 0, 9), WorkflowInstanceId);

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry1);
        RequeststoApprove.Comment.AssertEquals(true);
        RequeststoApprove.CommentsFactBox.First();

        RequeststoApprove.CommentsFactBox.Comment.AssertEquals(Comment1);
        Assert.IsFalse(RequeststoApprove.CommentsFactBox.Next(), 'Too many elements');

        RequeststoApprove.GotoRecord(ApprovalEntry2);
        RequeststoApprove.Comment.AssertEquals(true);
        RequeststoApprove.CommentsFactBox.First();

        RequeststoApprove.CommentsFactBox.Comment.AssertEquals(Comment2);
        Assert.IsFalse(RequeststoApprove.CommentsFactBox.Next(), 'Too many elements');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRequestsToApproveCommentFlag()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalCommentLine: Record "Approval Comment Line";
        WorkflowRecordChange: Record "Workflow - Record Change";
        Customer: Record Customer;
        RequeststoApprove: TestPage "Requests to Approve";
        WorkflowInstanceId: Guid;
        OldValue: Decimal;
        Comment: Text[80];
    begin
        // [UNITTEST] The Comment flag on the Requests to approve shows whether there are comments or not.
        // [GIVEN] A workflow instance.
        // [GIVEN] A customer record.
        // [GIVEN] An approval entry and a comment.
        // [WHEN] The Requests to Approve page is opened.
        // [THEN] The Comment flag shows that there are comments.

        WorkflowInstanceId := CreateGuid();
        OldValue := LibraryRandom.RandDec(1000, 2);

        Comment := CreateGuid();
        LibrarySales.CreateCustomer(Customer);
        CreateApprovalEntry(ApprovalEntry, Customer.RecordId, UserId, WorkflowInstanceId);

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Comment.AssertEquals(false);
        RequeststoApprove.Close();

        CreateApprovalComment(ApprovalCommentLine, ApprovalEntry, Comment);
        CreateRecordChange(WorkflowRecordChange, Customer.RecordId, Customer.FieldNo("Credit Limit (LCY)"), Format(OldValue, 0, 9), WorkflowInstanceId);

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Comment.AssertEquals(true);
        RequeststoApprove.CommentsFactBox.First();

        RequeststoApprove.CommentsFactBox.Comment.AssertEquals(Comment);
        Assert.IsFalse(RequeststoApprove.CommentsFactBox.Next(), 'Too many elements');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateNotificationEntryResponseOptions()
    var
        Workflow: Record Workflow;
        WorkflowStepResponse: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        User: Record User;
        UserSetup: Record "User Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowResponseOptions: TestPage "Workflow Response Options";
        EntryPointEventStepId: Integer;
        ResponseStepId: Integer;
        UserName: Code[50];
    begin
        // [SCENARIO] Entering a "Notification User ID" option works for CreateNotificationEntry response.
        // [GIVEN] The non-windows user: 'NAV Test User' set as the approval user
        UserName := LibraryUtility.GenerateGUID();
        LibraryPermissions.CreateUser(User, UserName, false);
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserName, '');
        // [GIVEN] A workflow with the CreateNotificationEntry response.
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        ResponseStepId := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), EntryPointEventStepId);
        LibraryWorkflow.InsertNotificationArgument(ResponseStepId, '', 0, '');

        WorkflowStepResponse.Get(Workflow.Code, ResponseStepId);
        WorkflowStepArgument.Get(WorkflowStepResponse.Argument);

        // [WHEN] The user navigates to the response options.
        WorkflowResponseOptions.OpenEdit();
        WorkflowResponseOptions.GotoRecord(WorkflowStepArgument);

        // [THEN] "Link Target Page", "Custom Link", "Notification User ID", and "Notify Sender" are visible and editable
        Assert.IsTrue(WorkflowResponseOptions."Link Target Page".Visible(), 'Link Target Page.Visible');
        Assert.IsTrue(WorkflowResponseOptions."Custom Link".Visible(), 'Custom Link.Visible');
        Assert.IsTrue(WorkflowResponseOptions."Link Target Page".Editable(), 'Link Target Page.Editable');
        Assert.IsTrue(WorkflowResponseOptions."Custom Link".Editable(), 'Custom Link.Editable');
        Assert.IsTrue(WorkflowResponseOptions."Notification User ID".Visible(), 'Notification User ID.Visible');
        Assert.IsTrue(WorkflowResponseOptions."Notification User ID".Editable(), 'Notification User ID.Editable');
        Assert.IsTrue(WorkflowResponseOptions.NotifySender3.Visible(), 'Notify Sender.Visible');
        Assert.IsTrue(WorkflowResponseOptions.NotifySender3.Editable(), 'Notify Sender.Editable');

        // [THEN] The user can enter a "Notification User ID", as it is visible and editable.
        WorkflowResponseOptions."Notification User ID".Value := UserName;

        WorkflowResponseOptions.OK().Invoke();

        // Verify
        WorkflowStepArgument.Find();
        WorkflowStepArgument.TestField("Notification User ID", UserName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateNotificationEntryForSenderResponseOptions()
    var
        Workflow: Record Workflow;
        WorkflowStepResponse: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        User: Record User;
        UserSetup: Record "User Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowResponseOptions: TestPage "Workflow Response Options";
        EntryPointEventStepId: Integer;
        ResponseStepId: Integer;
        UserName: Code[50];
    begin
        // [SCENARIO] Entering a "Notify Sender" option works for CreateNotificationEntry response.
        // [GIVEN] The non-windows user: 'NAV Test User' set as the approval user
        UserName := LibraryUtility.GenerateGUID();
        LibraryPermissions.CreateUser(User, UserName, false);
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserName, '');
        // [GIVEN] A workflow with the CreateNotificationEntry response.
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId :=
            LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        ResponseStepId :=
            LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), EntryPointEventStepId);
        LibraryWorkflow.InsertNotificationArgument(ResponseStepId, UserName, 0, '');

        WorkflowStepResponse.Get(Workflow.Code, ResponseStepId);
        WorkflowStepArgument.Get(WorkflowStepResponse.Argument);

        // [GIVEN] The user navigates to the response options.
        WorkflowResponseOptions.OpenEdit();
        WorkflowResponseOptions.GotoRecord(WorkflowStepArgument);

        // [GIVEN] "Notification User ID", and "Notify Sender" are visible and editable
        Assert.IsTrue(WorkflowResponseOptions."Notification User ID".Visible(), 'Notification User ID.Visible');
        Assert.IsTrue(WorkflowResponseOptions."Notification User ID".Editable(), 'Notification User ID.Editable');
        Assert.IsTrue(WorkflowResponseOptions.NotifySender3.Visible(), 'Notify Sender.Visible');
        Assert.IsTrue(WorkflowResponseOptions.NotifySender3.Editable(), 'Notify Sender.Editable');

        // [WHEN] The user set "Notify Sender" as 'Yes'.
        WorkflowResponseOptions.NotifySender3.Value := format(true);

        // [THEN] "Notification User ID" is visible, but not editable
        Assert.IsTrue(WorkflowResponseOptions."Notification User ID".Visible(), 'Notification User ID.Visible');
        Assert.IsFalse(WorkflowResponseOptions."Notification User ID".Editable(), 'Notification User ID.Editable');

        WorkflowResponseOptions.OK().Invoke();

        // [THEN] WorkflowStepArgument, where "Notify Sender" is 'Yes', "Notification User ID" is blank
        WorkflowStepArgument.Find();
        WorkflowStepArgument.Testfield("Notify Sender");
        WorkflowStepArgument.TestField("Notification User ID", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestShowMessageResponseOptions()
    var
        Workflow: Record Workflow;
        WorkflowStepResponse: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowResponseOptions: TestPage "Workflow Response Options";
        EntryPointEventStepId: Integer;
        ResponseStepId: Integer;
    begin
        // [SCENARIO] Entering a message option works for ShowMessage response.
        // [GIVEN] A workflow with the ShowMessage response.
        // [WHEN] The user navigates to the response options.
        // [THEN] The user can enter a custom message.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        ResponseStepId := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ShowMessageCode(), EntryPointEventStepId);
        LibraryWorkflow.InsertMessageArgument(ResponseStepId, '');

        WorkflowStepResponse.Get(Workflow.Code, ResponseStepId);
        WorkflowStepArgument.Get(WorkflowStepResponse.Argument);

        // Exercise
        WorkflowResponseOptions.OpenView();
        WorkflowResponseOptions.GotoRecord(WorkflowStepArgument);

        Assert.IsTrue(WorkflowResponseOptions.MessageField.Visible(), FieldShouldBeVisibleErr);

        WorkflowResponseOptions.MessageField.Value := ShowMessageTestMsg;

        WorkflowResponseOptions.OK().Invoke();

        // Verify
        WorkflowStepArgument.Find();
        WorkflowStepArgument.TestField(Message, ShowMessageTestMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTreesBuildByWorkflowStepBufferAndWorkflowStepInstanceAreSame()
    var
        Workflow: Record Workflow;
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        TempResponseWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowStepInstance: Record "Workflow Step Instance";
        TempWorkflowStepInstance: Record "Workflow Step Instance" temporary;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] Trees generate by the Workflow Step Buffer and Workflow Step Instance tables are same.
        // [GIVEN] A workflow and an instance of the workflow.
        // [WHEN] "Workflow Step Buffer".PopulateTable and "Workflow Step Instance".BuildTempWorkflowTree is run.
        // [THEN] The trees generated are same.

        // Setup
        LibraryWorkflow.CopyWorkflow(Workflow, 'MS-' + WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
        Workflow.CreateInstance(WorkflowStepInstance);
        WorkflowStepInstance.FindFirst();

        // Excercise
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);
        TempWorkflowStepInstance.BuildTempWorkflowTree(WorkflowStepInstance.ID);

        // Verify
        repeat
            Assert.AreEqual(TempWorkflowStepBuffer."Event Step ID", TempWorkflowStepInstance."Original Workflow Step ID", '');
            TempResponseWorkflowStepBuffer.PopulateTableFromEvent(Workflow.Code, TempWorkflowStepBuffer."Event Step ID");
            TempWorkflowStepInstance.Next();
            repeat
                Assert.AreEqual(TempResponseWorkflowStepBuffer."Response Step ID", TempWorkflowStepInstance."Original Workflow Step ID", '');
            until (TempResponseWorkflowStepBuffer.Next() = 0) or (TempWorkflowStepInstance.Next() = 0);
            TempResponseWorkflowStepBuffer.ClearBuffer();
        until TempWorkflowStepBuffer.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ModalLookupHandler')]
    [Scope('OnPrem')]
    procedure TestCannotAddWorkflowStepToWorkflowWithNoCode()
    var
        WorkFlowStep: Record "Workflow Step";
        Workflows: TestPage Workflows;
        Workflow: TestPage Workflow;
    begin
        // [SCENARIO] The user cannot add a workflow step to a workflow without a code.
        // [GIVEN] There are no workflows defined.
        // [WHEN] The user opens the workflow card and tries to add a workflow event.
        // [THEN] The user will get an error saying they need to a add a workflow code.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();

        // Exercise
        Workflows.OpenView();
        Workflow.Trap();
        Workflows.NewAction.Invoke();

        asserterror Workflow.WorkflowSubpage."Event Description".Lookup();

        // Verify
        Assert.ExpectedTestFieldError(WorkFlowStep.FieldCaption("Workflow Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePaymentLineResponseOptions()
    var
        Workflow: Record Workflow;
        WorkflowStepResponse: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        GenJournalBatch: Record "Gen. Journal Batch";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowResponseOptions: TestPage "Workflow Response Options";
        EntryPointEventStepId: Integer;
        ResponseStepId: Integer;
    begin
        // [SCENARIO] Entering the general journal template and batch for a response.
        // [GIVEN] A workflow with the CreatePaymentJournalLine response.
        // [WHEN] The user navigates to the response options.
        // [THEN] The user can enter the template and the batch.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        ResponseStepId := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocCode(), EntryPointEventStepId);
        LibraryWorkflow.InsertPmtLineCreationArgument(ResponseStepId, '', '');

        LibraryPurchase.SelectPmtJnlBatch(GenJournalBatch);

        WorkflowStepResponse.Get(Workflow.Code, ResponseStepId);
        WorkflowStepArgument.Get(WorkflowStepResponse.Argument);

        // Exercise
        WorkflowResponseOptions.OpenView();
        WorkflowResponseOptions.GotoRecord(WorkflowStepArgument);

        Assert.IsTrue(WorkflowResponseOptions."General Journal Batch Name".Visible(), FieldShouldBeVisibleErr);
        Assert.IsTrue(WorkflowResponseOptions."General Journal Template Name".Visible(), FieldShouldBeVisibleErr);

        WorkflowResponseOptions."General Journal Template Name".SetValue(GenJournalBatch."Journal Template Name");
        WorkflowResponseOptions."General Journal Batch Name".SetValue(GenJournalBatch.Name);

        WorkflowResponseOptions.OK().Invoke();

        // Verify
        WorkflowStepArgument.Find();
        WorkflowStepArgument.TestField("General Journal Template Name", GenJournalBatch."Journal Template Name");
        WorkflowStepArgument.TestField("General Journal Batch Name", GenJournalBatch.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApprovalResponseOptions()
    var
        Workflow: Record Workflow;
        WorkflowStepResponse: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowResponseOptions: TestPage "Workflow Response Options";
        EntryPointEventStepId: Integer;
        ResponseStepId: Integer;
    begin
        // [SCENARIO] Entering the approval options for a create approval request response.
        // [GIVEN] A workflow with the CreateApprovalRequests response.
        // [WHEN] The user navigates to the response options.
        // [THEN] The user can enter the options for the approval requests creation.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        ResponseStepId := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateApprovalRequestsCode(), EntryPointEventStepId);
        LibraryWorkflow.InsertApprovalArgument(ResponseStepId, WorkflowStepArgument."Approver Type"::Approver, WorkflowStepArgument."Approver Limit Type"::"Approver Chain", '', true);

        WorkflowStepResponse.Get(Workflow.Code, ResponseStepId);
        WorkflowStepArgument.Get(WorkflowStepResponse.Argument);

        // Exercise
        WorkflowResponseOptions.OpenView();
        WorkflowResponseOptions.GotoRecord(WorkflowStepArgument);

        Assert.IsTrue(WorkflowResponseOptions."Show Confirmation Message".Visible(), FieldShouldBeVisibleErr);
        Assert.IsTrue(WorkflowResponseOptions."Due Date Formula".Visible(), FieldShouldBeVisibleErr);
        Assert.IsTrue(WorkflowResponseOptions."Delegate After".Visible(), FieldShouldBeVisibleErr);
        Assert.IsTrue(WorkflowResponseOptions."Approver Type".Visible(), FieldShouldBeVisibleErr);
        Assert.IsTrue(WorkflowResponseOptions."Approver Limit Type".Visible(), FieldShouldBeVisibleErr);

        WorkflowResponseOptions."Show Confirmation Message".SetValue(false);
        WorkflowResponseOptions."Due Date Formula".SetValue('<2D>');
        WorkflowResponseOptions."Delegate After".SetValue(WorkflowStepArgument."Delegate After"::"1 day");
        WorkflowResponseOptions."Approver Type".SetValue(WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser");
        WorkflowResponseOptions."Approver Limit Type".SetValue(WorkflowStepArgument."Approver Limit Type"::"Direct Approver");
        WorkflowResponseOptions.OK().Invoke();

        // Verify
        WorkflowStepArgument.Find();
        WorkflowStepArgument.TestField("Show Confirmation Message", false);
        Assert.AreEqual('2D', Format(WorkflowStepArgument."Due Date Formula"), ValuesAreNotTheSameErr);
        WorkflowStepArgument.TestField("Delegate After", WorkflowStepArgument."Delegate After"::"1 day");
        WorkflowStepArgument.TestField("Approver Type", WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser");
        WorkflowStepArgument.TestField("Approver Limit Type", WorkflowStepArgument."Approver Limit Type"::"Direct Approver");
    end;

    [Test]
    [HandlerFunctions('ArchivedWorkflowStepInstancedModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestWorkflowArchivePage()
    var
        Workflow: Record Workflow;
        IncomingDocument: Record "Incoming Document";
        WorkflowEventHandling2: Codeunit "Workflow Event Handling";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        WorkflowPage: TestPage Workflow;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] The user can navigate to the Archived Workflow Step Instances page.
        // [GIVEN] An enabled workflow with archived workflow steps.
        // [WHEN] The user navigates to the Archived Workflow Step Instances page.
        // [THEN] The user can see the archived steps.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling2.RunWorkflowOnAfterInsertIncomingDocumentCode());
        LibraryWorkflow.EnableWorkflow(Workflow);
        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Exercise
        WorkflowPage.OpenView();
        WorkflowPage.GotoRecord(Workflow);
        WorkflowPage.ArchivedWorkflowStepInstances.Invoke();

        // Verify
        // Verification is done in the modal page handler
    end;

    [Test]
    [HandlerFunctions('WorkflowsPageWithCountModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToEmptyWorkflowsPage()
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Calling the workflow management codeunit function NavigateToWorkflows when no workflows.
        // [GIVEN] No workflows exist.
        // [WHEN] When the NavigateToWorkflows function is called.
        // [THEN] The workflows page is opened without a record.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();
        LibraryVariableStorage.Enqueue(0);

        // Exercise
        Assert.IsFalse(WorkflowManagement.EnabledWorkflowExist(DATABASE::"Sales Header", ''), 'No workflow should exist');
        WorkflowManagement.NavigateToWorkflows(DATABASE::"Sales Header", '');

        // Verify - It is done in the page handler
    end;

    [Test]
    [HandlerFunctions('WorkflowPageWithCheckModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToWorkflowPage()
    var
        Workflow: Record Workflow;
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowEventHandling2: Codeunit "Workflow Event Handling";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Calling the workflow management codeunit function NavigateToWorkflows will open the correct page with one workflow.
        // [GIVEN] A workflow exists.
        // [WHEN] When the NavigateToWorkflows function is called.
        // [THEN] The workflow page is opened, showing the correct workflow.

        // Setup
        LibraryWorkflow.DisableAllWorkflows();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());
        LibraryVariableStorage.Enqueue(Workflow.Code);

        // Exercise
        Assert.IsTrue(WorkflowManagement.EnabledWorkflowExist(DATABASE::Customer, WorkflowEventHandling2.RunWorkflowOnSendCustomerForApprovalCode()), 'Workflows should exist');
        WorkflowManagement.NavigateToWorkflows(DATABASE::Customer, WorkflowEventHandling2.RunWorkflowOnSendCustomerForApprovalCode());

        // Verify - Verification is done in the modal page handler
    end;

    [Test]
    [HandlerFunctions('WorkflowsPageWithCountModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToWorkflowsPage()
    var
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Calling the workflow management codeunit function NavigateToWorkflows will open the correct page with some workflows.
        // [GIVEN] Some workflows exists.
        // [WHEN] When the NavigateToWorkflows function is called.
        // [THEN] The workflows page is opened, showing the correct workflows.

        // Setup
        LibraryWorkflow.DisableAllWorkflows();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode());
        LibraryVariableStorage.Enqueue(2);

        // Exercise
        Assert.IsFalse(WorkflowManagement.EnabledWorkflowExist(DATABASE::Customer, WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode()), 'Workflows should exist');
        WorkflowManagement.NavigateToWorkflows(DATABASE::"Purchase Header", WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());

        // Verify - Verification is done in the page handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFirstCreatedWorkflowShowsUp()
    var
        Workflows: TestPage Workflows;
        Workflow: TestPage Workflow;
        WorkflowCategory: Code[20];
        NoOfWorkflows: Integer;
    begin
        // [SCENARIO] Creating a new non-template based workflow, and returning to workflow list.
        // [GIVEN] The user is on the Workflows page and no workflows exist.
        // [WHEN] The user clicks New, specifies code, category and description and clicks Ok.
        // [THEN] The user returns to the list of Workflows which now contains the new workflow.

        // Setup:
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowCategory := LibraryWorkflow.CreateWorkflowCategory();

        // Exercise:
        Workflows.OpenView();
        Workflow.Trap();
        Workflows.NewAction.Invoke();
        Workflow.Code.SetValue('WFID');
        Workflow.Description.SetValue('WF Desc');
        Workflow.Category.SetValue(WorkflowCategory);
        Workflow.OK().Invoke();
        // Trigger refresh buffer logic by changing filter
        Workflows.FILTER.Ascending(false);

        while Workflows.Next() do
            NoOfWorkflows += 1;

        // Verify
        Assert.AreEqual(1, NoOfWorkflows, 'Number of workflows is wrong');
    end;

    [Test]
    [HandlerFunctions('WorkflowEventsPageHandler')]
    [Scope('OnPrem')]
    procedure TestWhenEventLookupWithIndent()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowPage: TestPage Workflow;
        PredecessorFunctionName: Code[128];
        EventFunctionName1: Code[128];
        EventFunctionName2: Code[128];
    begin
        // [SCENARIO 217100] Workflow event should be accessible to select as event step when it is added after identical event with indentation.
        SetApplicationArea();

        // [GIVEN] Events "E1" and "E2" with predecessor event "P"
        PredecessorFunctionName := CreateWorkflowEvent();
        EventFunctionName1 := CreateWorkflowEvent();
        EventFunctionName2 := CreateWorkflowEvent();
        CreateWFEventCombination(EventFunctionName1, PredecessorFunctionName);
        CreateWFEventCombination(EventFunctionName2, PredecessorFunctionName);

        // [GIVEN] Workflow page with first line of event "P" and second line event "E1" with Indent = 1
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoRecord(Workflow);
        LibraryVariableStorage.Enqueue(PredecessorFunctionName);
        WorkflowPage.WorkflowSubpage."Event Description".Lookup();

        LibraryVariableStorage.Enqueue(EventFunctionName1);
        WorkflowPage.WorkflowSubpage.Next();
        WorkflowPage.WorkflowSubpage."Event Description".Lookup();
        WorkflowPage.WorkflowSubpage.IncreaseIndent.Invoke();

        // [WHEN] Select event "E2" on lookup 'When Event' field below event "E1"
        LibraryVariableStorage.Enqueue(EventFunctionName2);
        WorkflowPage.WorkflowSubpage.Next();
        WorkflowPage.WorkflowSubpage."Event Description".Lookup();

        // [THEN] Workflow step is added with 'When Event' = "E2"
        WorkflowEvent.Get(EventFunctionName2);
        WorkflowPage.WorkflowSubpage."Event Description".AssertEquals(WorkflowEvent.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountsAndCurrencyCodeVisibleOnRequestsToApprovePage()
    var
        ApprovalEntry: Record "Approval Entry";
        Currency: Record Currency;
        RequeststoApprove: TestPage "Requests to Approve";
        Amount: Decimal;
        AmountLCY: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 287176] Fields "Amount", "Amount (LCY)" and "Currency Code" are shown on Page "Requests To Approve"

        // [GIVEN] Created Currency "CUR"
        // [GIVEN] Created Approval Entry "AE01" with "Amount" = 100, "Amount (LCY)" = 150, "Currency Code" = "CUR"
        LibraryERM.CreateCurrency(Currency);
        Amount := LibraryRandom.RandDec(1000, 2);
        AmountLCY := LibraryRandom.RandDec(1000, 2);
        CreateApprovalEntryWithAmountsAndCurrencyCode(ApprovalEntry, Currency.RecordId, UserId, CreateGuid(), Amount, AmountLCY, Currency.Code);

        // [WHEN] Open Page "Requests to Approve"
        RequeststoApprove.OpenView();

        // [THEN] On line "AE01" fields "Amount" = 100, "Amount (LCY)" = 150, "Currency Code" = "CUR" are shown
        RequeststoApprove.FILTER.SetFilter("Entry No.", Format(ApprovalEntry."Entry No."));
        RequeststoApprove.Amount.AssertEquals(Amount);
        RequeststoApprove."Amount (LCY)".AssertEquals(AmountLCY);
        RequeststoApprove."Currency Code".AssertEquals(Currency.Code);
        RequeststoApprove.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountsAndCurrencyCodeApplicationAreaSuiteRequestsToApprovePage()
    var
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        // [FEATURE] [UT] [Application Area] [Suite]
        // [SCENARIO 287176] Fields "Amount", "Amount (LCY)" and "Currency Code" are visible on Page "Requests To Approve" in Foundation setup

        // [GIVEN] Foundation Application Area Setup Enabled
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Open Page "Requests to Approve"
        RequeststoApprove.OpenView();

        // [THEN] Fields "Amount", "Amount (LCY)" and "Currency Code" are visible
        Assert.IsTrue(RequeststoApprove.Amount.Visible(), FieldShouldBeVisibleErr);
        Assert.IsTrue(RequeststoApprove."Amount (LCY)".Visible(), FieldShouldBeVisibleErr);
        Assert.IsTrue(RequeststoApprove."Currency Code".Visible(), FieldShouldBeVisibleErr);
        RequeststoApprove.Close();

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountsAndCurrencyCodeVisibleOnApprovalRequestEntriesPage()
    var
        ApprovalEntry: Record "Approval Entry";
        Currency: Record Currency;
        ApprovalRequestEntries: TestPage "Approval Request Entries";
        Amount: Decimal;
        AmountLCY: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 287176] Fields "Amount", "Amount (LCY)" and "Currency Code" are shown on Page "Approval Request Entries"

        // [GIVEN] Created Currency "CUR"
        // [GIVEN] Created Approval Entry "AE01" with "Amount" = 100, "Amount (LCY)" = 150, "Currency Code" = "CUR"
        LibraryERM.CreateCurrency(Currency);
        Amount := LibraryRandom.RandDec(1000, 2);
        AmountLCY := LibraryRandom.RandDec(1000, 2);
        CreateApprovalEntryWithAmountsAndCurrencyCode(ApprovalEntry, Currency.RecordId, UserId, CreateGuid(), Amount, AmountLCY, Currency.Code);

        // [WHEN] Open Page "Approval Request Entries"
        ApprovalRequestEntries.OpenView();

        // [THEN] On line "AE01" fields "Amount" = 100, "Amount (LCY)" = 150, "Currency Code" = "CUR" are shown
        ApprovalRequestEntries.FILTER.SetFilter("Entry No.", Format(ApprovalEntry."Entry No."));
        ApprovalRequestEntries.Amount.AssertEquals(Amount);
        ApprovalRequestEntries."Amount (LCY)".AssertEquals(AmountLCY);
        ApprovalRequestEntries."Currency Code".AssertEquals(Currency.Code);
        ApprovalRequestEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountsAndCurrencyCodeApplicationAreaSuiteApprovalRequestEntriesPage()
    var
        ApprovalRequestEntries: TestPage "Approval Request Entries";
    begin
        // [FEATURE] [UT] [Application Area] [Suite]
        // [SCENARIO 287176] Fields "Amount", "Amount (LCY)" and "Currency Code" are not found on Page "Approval Request Entries" in Foundation setup

        // [GIVEN] Foundation Application Area Setup Enabled
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Open Page "Approval Request Entries"
        ApprovalRequestEntries.OpenView();

        // [THEN] Fields "Amount", "Amount (LCY)" and "Currency Code" are visible
        Assert.IsTrue(ApprovalRequestEntries.Amount.Visible(), FieldShouldBeVisibleErr);
        Assert.IsTrue(ApprovalRequestEntries."Amount (LCY)".Visible(), FieldShouldBeVisibleErr);
        Assert.IsTrue(ApprovalRequestEntries."Currency Code".Visible(), FieldShouldBeVisibleErr);
        ApprovalRequestEntries.Close();

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkflowCardDoesNotMixRecsWithTemplates_NonTemplateIsOpened()
    var
        Workflow: array[2] of Record "Workflow";
        TemplateWorkflow: array[2] of Record "Workflow";
        TestPageWorkflow: TestPage "Workflow";
        Index: Integer;
    begin
        // [FEATURE] [Workflow Card]
        // [SCENARIO 324094] Workflow Card opened from non-template Workflow show only non-template records when switching records with "back" and "previous" buttons
        Workflow[1].DeleteAll();

        // [GIVEN] Workflows "WF1" and "WF2" and Workflow Templates "WT1" and "WT2"
        for Index := 1 to ArrayLen(Workflow) do begin
            LibraryWorkflow.CreateWorkflow(Workflow[Index]);
            LibraryWorkflow.CreateTemplateWorkflow(TemplateWorkflow[Index]);
        end;

        // [GIVEN] Workflow Card page opened for "WF1"
        TestPageWorkflow.Trap();
        Page.Run(Page::Workflow, Workflow[1]);

        // [WHEN] Go to previous record
        // [THEN] "WF1" selected
        // [WHEN] Go to next record
        // [THEN] "WF2" selected
        // [WHEN] Go to next record
        // [THEN] "WF2" selected
        VerifyPreviousAndNextWorkflowRecords(TestPageWorkflow, Workflow[1].Code, Workflow[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkflowCardDoesNotMixRecsWithTemplates_TemplateIsOpened()
    var
        Workflow: array[2] of Record "Workflow";
        TemplateWorkflow: array[2] of Record "Workflow";
        TestPageWorkflow: TestPage "Workflow";
        Index: Integer;
    begin
        // [FEATURE] [Workflow Card]
        // [SCENARIO 324094] Workflow Card opened from template Workflow show only template records when switching records with "back" and "previous" buttons
        Workflow[1].DeleteAll();

        // [GIVEN] Workflows "WF1" and "WF2" and Workflow Templates "WT1" and "WT2"
        for Index := 1 to ArrayLen(Workflow) do begin
            LibraryWorkflow.CreateWorkflow(Workflow[Index]);
            LibraryWorkflow.CreateTemplateWorkflow(TemplateWorkflow[Index]);
        end;

        // [GIVEN] Workflow Card page opened for "WT1"
        TestPageWorkflow.Trap();
        Page.Run(Page::Workflow, TemplateWorkflow[1]);

        // [WHEN] Go to previous record
        // [THEN] "WT1" selected
        // [WHEN] Go to next record
        // [THEN] "WT2" selected
        // [WHEN] Go to next record
        // [THEN] "WT2" selected
        VerifyPreviousAndNextWorkflowRecords(TestPageWorkflow, TemplateWorkflow[1].Code, TemplateWorkflow[2].Code);
    end;

    local procedure CreateWorkflowEvent() EventFunctionName: Text[128]
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        EventFunctionName := LibraryUtility.GenerateRandomCode(WorkflowEvent.FieldNo("Function Name"), DATABASE::"Workflow Event");
        WorkflowEventHandling.AddEventToLibrary(EventFunctionName, DATABASE::Customer, LibraryUtility.GenerateGUID(), 0, false);
    end;

    local procedure CreateWFEventCombination(WorkflowEventName: Code[128]; PredesessorFunctionName: Code[128])
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        WFEventResponseCombination.Init();
        WFEventResponseCombination."Function Name" := WorkflowEventName;
        WFEventResponseCombination.Type := WFEventResponseCombination.Type::"Event";
        WFEventResponseCombination."Predecessor Type" := WFEventResponseCombination."Predecessor Type"::"Event";
        WFEventResponseCombination."Predecessor Function Name" := PredesessorFunctionName;
        WFEventResponseCombination.Insert();
    end;

    local procedure ValidateUIForWorkflowPage(Workflow: Record Workflow)
    var
        WorkflowPage: TestPage Workflow;
        IsActionable: Boolean;
    begin
        IsActionable := not Workflow.Template;

        WorkflowPage.Trap();
        Page.Run(Page::Workflow, Workflow);

        Assert.AreEqual(IsActionable, WorkflowPage.WorkflowStepInstances.Visible(), UIElementDoesNotHaveCorrectStateErr);
        Assert.AreEqual(IsActionable, WorkflowPage.ArchivedWorkflowStepInstances.Visible(), UIElementDoesNotHaveCorrectStateErr);

        Assert.AreEqual(IsActionable, WorkflowPage.Code.Editable(), UIElementDoesNotHaveCorrectStateErr);
        Assert.AreEqual(IsActionable, WorkflowPage.Description.Editable(), UIElementDoesNotHaveCorrectStateErr);
        Assert.AreEqual(IsActionable, WorkflowPage.Description.Editable(), UIElementDoesNotHaveCorrectStateErr);

        Assert.AreEqual(IsActionable, WorkflowPage.WorkflowSubpage.DecreaseIndent.Visible(), UIElementDoesNotHaveCorrectStateErr);
        Assert.AreEqual(IsActionable, WorkflowPage.WorkflowSubpage.IncreaseIndent.Visible(), UIElementDoesNotHaveCorrectStateErr);
        Assert.AreEqual(IsActionable, WorkflowPage.WorkflowSubpage.DeleteEventConditions.Visible(), UIElementDoesNotHaveCorrectStateErr);

        Assert.AreEqual(IsActionable, WorkflowPage.WorkflowSubpage."Event Description".Editable(), UIElementDoesNotHaveCorrectStateErr);
    end;

    local procedure VerifyPreviousAndNextWorkflowRecords(var TestPageWorkflow: TestPage "Workflow"; WorkflowCode1: Code[20]; WorkflowCode2: Code[20])
    begin
        TestPageWorkflow.Previous();
        TestPageWorkflow.Code.AssertEquals(WorkflowCode1);
        TestPageWorkflow.Next();
        TestPageWorkflow.Code.AssertEquals(WorkflowCode2);
        TestPageWorkflow.Next();
        TestPageWorkflow.Code.AssertEquals(WorkflowCode2);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalLookupHandler(var WorkflowEvents: TestPage "Workflow Events")
    begin
        WorkflowEvents.First();
        SelectedEventDesc := WorkflowEvents.Description.Value();
        WorkflowEvents.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmptyEventConditionsPageHandler(var WorkflowEventConditions: TestPage "Workflow Event Conditions")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EventConditionsOKWithSetRulesPageHandler(var WorkflowEventConditions: TestPage "Workflow Event Conditions")
    begin
        if not WorkflowEventConditions.FieldCaption2.Visible() then
            WorkflowEventConditions.AddChangeValueConditionLbl.DrillDown();
        WorkflowEventConditions.AddChangeValueConditionLbl.DrillDown();
        WorkflowEventConditions.FieldCaption2.SetValue(InputWorkflowRule."Field Caption");
        WorkflowEventConditions.Operator.SetValue(InputWorkflowRule.Operator);
        WorkflowEventConditions.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EventConditionsCancelWithSetRulesPageHandler(var WorkflowEventConditions: TestPage "Workflow Event Conditions")
    begin
        if not WorkflowEventConditions.FieldCaption2.Visible() then
            WorkflowEventConditions.AddChangeValueConditionLbl.DrillDown();
        WorkflowEventConditions.AddChangeValueConditionLbl.DrillDown();
        WorkflowEventConditions.FieldCaption2.SetValue(InputWorkflowRule."Field Caption");
        WorkflowEventConditions.Operator.SetValue(InputWorkflowRule.Operator);
        WorkflowEventConditions.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [HandlerFunctions('FieldListWithSelectionCheckPageHandler')]
    [Scope('OnPrem')]
    procedure EventConditionsTriggeringFieldLookupPageHandler(var WorkflowEventConditions: TestPage "Workflow Event Conditions")
    begin
        if not WorkflowEventConditions.FieldCaption2.Visible() then
            WorkflowEventConditions.AddChangeValueConditionLbl.DrillDown();

        WorkflowEventConditions.FieldCaption2.Lookup();
        WorkflowEventConditions.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FieldListWithSelectionCheckPageHandler(var FieldsLookup: TestPage "Fields Lookup")
    begin
    end;

    [ModalPageHandler]
    [HandlerFunctions('FieldListWithFieldNameCheckPageHandler')]
    [Scope('OnPrem')]
    procedure EventConditionsTriggeringFieldAssistEditPageHandler(var WorkflowEventConditions: TestPage "Workflow Event Conditions")
    begin
        if not WorkflowEventConditions.FieldCaption2.Visible() then
            WorkflowEventConditions.AddChangeValueConditionLbl.DrillDown();

        WorkflowEventConditions.FieldCaption2.Value := InputField."Field Caption";
        WorkflowEventConditions.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FieldListWithFieldNameCheckPageHandler(var FieldsLookup: TestPage "Fields Lookup")
    var
        FieldCaption: Text;
    begin
        if FieldsLookup.First() then
            repeat
                FieldCaption := UpperCase(FieldsLookup.FieldName.Value);
                Assert.AreEqual(UpperCase(InputField."Field Caption"), CopyStr(FieldCaption, 1, 2), 'failed');
            until FieldsLookup.Next() = false;
        FieldsLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FieldPageModalPageHandler(var FieldsLookup: TestPage "Fields Lookup")
    var
        FieldCaption: Text;
    begin
        FieldCaption := LibraryVariableStorage.DequeueText();
        FieldsLookup.First();

        repeat
            if FieldsLookup.FieldName.Value = FieldCaption then
                break;
        until not FieldsLookup.Next();

        FieldsLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MultiFieldPageModalPageHandler(var FieldsLookup: TestPage "Fields Lookup")
    var
        FieldCaption: Text;
        Found: Boolean;
        "Count": Integer;
        OriginalQueueLength: Integer;
    begin
        OriginalQueueLength := LibraryVariableStorage.Length();

        while LibraryVariableStorage.Length() > 0 do begin
            FieldsLookup.First();
            FieldCaption := LibraryVariableStorage.DequeueText();
            Found := false;
            Count := 0;
            repeat
                if FieldsLookup.FieldName.Value = FieldCaption then
                    Found := true;
                Count += 1;
            until not FieldsLookup.Next();
            Assert.IsTrue(Found, 'The field was not found');
            Assert.AreEqual(OriginalQueueLength, Count, 'The number of fields shown is not correct');
        end;

        FieldsLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkflowsPageWithCountModalPageHandler(var Workflows: TestPage Workflows)
    var
        NoOfExpectedWorkflwos: Integer;
        NoOfActualWorkflows: Integer;
    begin
        NoOfExpectedWorkflwos := LibraryVariableStorage.DequeueInteger();

        Workflows.First();
        while Workflows.Next() do
            NoOfActualWorkflows += 1;

        Assert.AreEqual(NoOfExpectedWorkflwos, NoOfActualWorkflows, 'Wrong number of workflows shown');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkflowPageWithCheckModalPageHandler(var Workflow: TestPage Workflow)
    var
        ExpectedWorkflowCode: Text;
    begin
        ExpectedWorkflowCode := LibraryVariableStorage.DequeueText();

        Assert.AreEqual(ExpectedWorkflowCode, Format(Workflow.Code), 'Wrong workflow shown');
    end;

    local procedure CreateApprovalEntry(var ApprovalEntry: Record "Approval Entry"; RecId: RecordID; ApproverId: Code[50]; WorkflowInstanceId: Guid)
    begin
        CreateApprovalEntryWithAmountsAndCurrencyCode(ApprovalEntry, RecId, ApproverId, WorkflowInstanceId, 0, 0, '');
    end;

    local procedure CreateApprovalEntryWithAmountsAndCurrencyCode(var ApprovalEntry: Record "Approval Entry"; RecId: RecordID; ApproverId: Code[50]; WorkflowInstanceId: Guid; Amount: Decimal; AmountLCY: Decimal; CurrencyCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        RecRef.Get(RecId);

        ApprovalEntry.Init();
        ApprovalEntry."Table ID" := RecRef.Number;
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Approver ID" := ApproverId;
        ApprovalEntry."Sender ID" := CopyStr(UserId(), 1, MaxStrLen(ApprovalEntry."Sender ID"));
        ApprovalEntry."Record ID to Approve" := RecId;
        ApprovalEntry."Workflow Step Instance ID" := WorkflowInstanceId;
        ApprovalEntry.Amount := Amount;
        ApprovalEntry."Amount (LCY)" := AmountLCY;
        ApprovalEntry."Currency Code" := CurrencyCode;
        ApprovalEntry.Insert();
    end;

    local procedure CreateRecordChange(var WorkflowRecordChange: Record "Workflow - Record Change"; RecId: RecordID; FieldNo: Integer; OldValue: Text[250]; WorkflowInstanceId: Guid)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Get(RecId);
        Clear(WorkflowRecordChange);
        WorkflowRecordChange.Init();
        WorkflowRecordChange."Field No." := FieldNo;
        WorkflowRecordChange."Table No." := RecRef.Number;
        WorkflowRecordChange.CalcFields("Field Caption");
        WorkflowRecordChange."Old Value" := OldValue;
        FieldRef := RecRef.Field(FieldNo);
        WorkflowRecordChange."New Value" := Format(FieldRef.Value, 0, 9);
        WorkflowRecordChange."Record ID" := RecId;
        WorkflowRecordChange."Workflow Step Instance ID" := WorkflowInstanceId;
        WorkflowRecordChange.Insert();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ArchivedWorkflowStepInstancedModalPageHandler(var ArchivedWFStepInstances: TestPage "Archived WF Step Instances")
    begin
        ArchivedWFStepInstances.First();
    end;

    local procedure CreateApprovalComment(var ApprovalCommentLine: Record "Approval Comment Line"; ApprovalEntry: Record "Approval Entry"; Comment: Text[80])
    begin
        ApprovalCommentLine.Init();
        ApprovalCommentLine."Table ID" := ApprovalEntry."Table ID";
        ApprovalCommentLine."Workflow Step Instance ID" := ApprovalEntry."Workflow Step Instance ID";
        ApprovalCommentLine.Comment := Comment;
        ApprovalCommentLine."Record ID to Approve" := ApprovalEntry."Record ID to Approve";
        ApprovalCommentLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(ApprovalCommentLine."User ID"));
        ApprovalCommentLine."Entry No." := ApprovalEntry."Entry No.";
        ApprovalCommentLine.Insert();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkflowEventsPageHandler(var WorkflowEvents: TestPage "Workflow Events")
    begin
        WorkflowEvents.GotoKey(LibraryVariableStorage.DequeueText());
        WorkflowEvents.OK().Invoke();
    end;

    local procedure SetApplicationArea()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        // Set ApplicationArea to Essential since Workflow page is read-only in Basic.
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
    end;
}
