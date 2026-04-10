codeunit 134313 "Workflow Designer Page Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Workflow Designer]
    end;

    var
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SelectResponseTxt: Label '<Select Response>';
        NextStepTxt: Label '<(Optional) Select Next Step>';
        DueDateFormulaErr: Label 'Due Date Formula must be a positive value.';
        LibraryRandom: Codeunit "Library - Random";
        ResponseDeletedLbl: Label 'Response are Deleted.';

    [Test]
    [HandlerFunctions('WhenModalPageHandler,UIConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInsertOfEventInNewWorkflow()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowPage: TestPage Workflow;
    begin
        // [SCENARIO 1] User addes event to empty workflow.
        // [GIVEN] An empty workflow.
        // [WHEN] User Lookup the "when" column and selects the first event.
        // [THEN] Event gets create in the event in the workflow step table and display the description to the user.
        // [WHEN] User Lookup the "when" column again and selects the first event.
        // [THEN] The same workflow step gets changed to use the new event and display the description to the user.

        Initialize();
        SetApplicationArea();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoKey(Workflow.Code);

        // Exercise - Create event
        CreateAnyEvent(WorkflowEvent);
        LibraryVariableStorage.Enqueue(WorkflowEvent.Description);

        WorkflowPage.WorkflowSubpage."Event Description".Lookup();
        // Lookup handlerselects WorkflowEvent.Description

        // Verify - Event created
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindFirst();

        WorkflowStep.TestField("Function Name", WorkflowEvent."Function Name");
        WorkflowStep.TestField("Previous Workflow Step ID", 0);
        WorkflowStep.TestField("Entry Point", false);
        WorkflowPage.WorkflowSubpage."Event Description".AssertEquals(WorkflowEvent.Description);

        // Exercise - Change event
        CreateAnyEvent(WorkflowEvent);
        LibraryVariableStorage.Enqueue(WorkflowEvent.Description);

        WorkflowPage.WorkflowSubpage.First();
        WorkflowPage.WorkflowSubpage."Event Description".Lookup();

        // Verify - Event changed
        WorkflowStep.Get(WorkflowStep."Workflow Code", WorkflowStep.ID);
        WorkflowStep.TestField("Function Name", WorkflowEvent."Function Name");
        WorkflowPage.WorkflowSubpage."Event Description".AssertEquals(WorkflowEvent.Description);
    end;

    [Test]
    [HandlerFunctions('WhenModalPageHandler,UIConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInsertOfEventInExistingWorkflowAtTheEnd()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        FirstWorkflowStep: Record "Workflow Step";
        LastWorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowPage: TestPage Workflow;
    begin
        // [SCENARIO 2] User addes event to existing workflow.
        // [GIVEN] Existing workflow.
        // [WHEN] User moves to the en of the events steps and Lookup the "when" column and selects the first event.
        // [THEN] Event gets create in the event in the workflow step table and display the description to the user.
        // "Previous Workflow Step ID" get set to the same as the last event in the list.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(FirstWorkflowStep, Workflow, 0);
        CreateAnyEventWorkflowStep(LastWorkflowStep, Workflow, FirstWorkflowStep.ID);

        WorkflowPage.OpenEdit();
        WorkflowPage.GotoKey(Workflow.Code);

        // Exercise
        WorkflowEvent.FindFirst();
        LibraryVariableStorage.Enqueue(WorkflowEvent.Description);

        WorkflowPage.WorkflowSubpage.Last();
        WorkflowPage.WorkflowSubpage."Event Description".Lookup();
        // Lookup handlerselects WorkflowEvent.Description
        WorkflowPage.Close();

        // Verify
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindLast();

        WorkflowStep.TestField("Function Name", WorkflowEvent."Function Name");
        WorkflowStep.TestField("Previous Workflow Step ID", FirstWorkflowStep.ID);
        WorkflowStep.TestField("Entry Point", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertOfEventByTypingExactValue()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowPage: TestPage Workflow;
    begin
        // [SCENARIO 3] User creates event by typing full event name.
        // [GIVEN] Existing workflow.
        // [WHEN] User types the full event value the "when" column and leaves the field.
        // [THEN] Event gets create in the workflow step table.

        Initialize();
        SetApplicationArea();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        WorkflowPage.OpenEdit();
        WorkflowPage.GotoKey(Workflow.Code);

        // Exercise
        CreateAnyEvent(WorkflowEvent);
        WorkflowPage.WorkflowSubpage."Event Description".SetValue(WorkflowEvent.Description);
        WorkflowPage.Close();

        // Verify
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindLast();
        WorkflowStep.TestField("Function Name", WorkflowEvent."Function Name");
    end;

    [Test]
    [HandlerFunctions('WhenModalPageHandlerLookupValidation,UIConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInsertOfEventByTypingPartOfValue()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowPage: TestPage Workflow;
    begin
        // [SCENARIO 4] User creates event by typing part of event name.
        // [GIVEN] Existing workflow.
        // [WHEN] User types part of the event description in the "when" column and leaves the field.
        // [THEN] User gets presented with a lookup filtered to the pretyped value there he selects the event
        // and Event gets create in the event in the workflow step table and display the description to the user.

        Initialize();
        SetApplicationArea();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        WorkflowPage.OpenEdit();
        WorkflowPage.GotoKey(Workflow.Code);

        // Exercise
        CreateAnyEvent(WorkflowEvent);
        WorkflowPage.WorkflowSubpage."Event Description".SetValue(CopyStr(WorkflowEvent.Description, 8, 8));
        // Lookup handler validates the filter and return to event

        // Verify
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindLast();
        WorkflowStep.TestField("Function Name", WorkflowEvent."Function Name");
        WorkflowPage.WorkflowSubpage."Event Description".AssertEquals(WorkflowEvent.Description);
        WorkflowPage.Close();
    end;

    [Test]
    [HandlerFunctions('WhenModalPageHandlerCombinationValidation')]
    [Scope('OnPrem')]
    procedure TestEventEventSupportedCombinationOnLookup()
    var
        Workflow: Record Workflow;
        RootWorkflowStep: Record "Workflow Step";
        RootWorkflowEvent: Record "Workflow Event";
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowPage: TestPage Workflow;
    begin
        // [SCENARIO] User creates event step by looking up the event name.
        // [GIVEN] Existing workflow.
        // [GIVEN] An existing supported combination between the root event and the desired event.
        // [WHEN] User invokes lookup on the next step.
        // [THEN] User gets presented with a lookup showing the "independent" events plus the successor of the root event.
        // [THEN] The successor's succesor event should not be shown.

        // Root Event -> Event 1 -> Event 2

        // Setup
        SetApplicationArea();
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(RootWorkflowStep, Workflow, 0);
        RootWorkflowEvent.Get(RootWorkflowStep."Function Name");
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        LibraryWorkflow.CreateEventPredecessor(WorkflowEvent1."Function Name", RootWorkflowStep."Function Name");
        LibraryWorkflow.CreateEventPredecessor(WorkflowEvent2."Function Name", WorkflowEvent1."Function Name");

        // Exercise
        LibraryVariableStorage.Enqueue(RootWorkflowEvent.Description);
        LibraryVariableStorage.Enqueue(WorkflowEvent1.Description);
        LibraryVariableStorage.Enqueue(WorkflowEvent2.Description);
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoRecord(Workflow);
        WorkflowPage.WorkflowSubpage.New();
        WorkflowPage.WorkflowSubpage."Event Description".Lookup();

        // Validate: in page handler.
    end;

    [Test]
    [HandlerFunctions('WhenModalPageHandlerCombinationValidationPartialValue,UIConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestEventEventSupportedCombinationOnTypingPartOfValue()
    var
        Workflow: Record Workflow;
        RootWorkflowStep: Record "Workflow Step";
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        RootWorkflowEvent: Record "Workflow Event";
        WorkflowPage: TestPage Workflow;
    begin
        // [SCENARIO] User creates event step by looking up the event name.
        // [GIVEN] Existing workflow.
        // [GIVEN] An existing supported combination between the root event and the desired event.
        // [WHEN] User types part of root event name, event 1 and event 2 on the next step.
        // [THEN] User gets presented with a lookup showing the "independent" events or the successor of the root event.
        // [THEN] The successor's succesor event should not be shown.

        // Root Event -> Event 1 -> Event 2

        // Setup
        SetApplicationArea();
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(RootWorkflowStep, Workflow, 0);
        RootWorkflowEvent.Get(RootWorkflowStep."Function Name");
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        LibraryWorkflow.CreateEventPredecessor(WorkflowEvent1."Function Name", RootWorkflowStep."Function Name");
        LibraryWorkflow.CreateEventPredecessor(WorkflowEvent2."Function Name", WorkflowEvent1."Function Name");

        // Exercise
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoRecord(Workflow);
        WorkflowPage.WorkflowSubpage.New();

        LibraryVariableStorage.Enqueue(RootWorkflowEvent.Description);
        WorkflowPage.WorkflowSubpage."Event Description".SetValue(CopyStr(RootWorkflowEvent.Description, 8, 8));

        LibraryVariableStorage.Enqueue(WorkflowEvent1.Description);
        WorkflowPage.WorkflowSubpage.Next();
        WorkflowPage.WorkflowSubpage."Event Description".SetValue(CopyStr(WorkflowEvent1.Description, 8, 8));

        LibraryVariableStorage.Enqueue(WorkflowEvent2.Description);
        asserterror WorkflowPage.WorkflowSubpage."Event Description".SetValue(CopyStr(WorkflowEvent2.Description, 8, 8));

        // Validate: In handler.
    end;

    [Test]
    [HandlerFunctions('ThenModalPageHandlerOK')]
    [Scope('OnPrem')]
    procedure TestAssistEditOnThenOnNewEvent()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowPage: TestPage Workflow;
    begin
        // [SCENARIO 5] Open workflow responses
        // [GIVEN] An empty workflow.
        // [WHEN] User selsets a "when".
        // [THEN] Event gets create in the event in the workflow step table and Select response gets shown in Then.
        // [WHEN] User Lookup the "Then" column again he get the response dialog.
        // [THEN] REsponse dialog opens.

        Initialize();
        SetApplicationArea();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoKey(Workflow.Code);

        // Exercise
        CreateAnyEvent(WorkflowEvent);
        WorkflowPage.WorkflowSubpage."Event Description".SetValue(WorkflowEvent.Description);

        // Verity
        WorkflowPage.WorkflowSubpage."Response Description".AssertEquals(SelectResponseTxt);

        // Exercise
        WorkflowPage.WorkflowSubpage."Response Description".AssistEdit();

        // Verity
        // Handler is closing the assist
    end;

    [Test]
    [HandlerFunctions('ConditionModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestConditionLookup()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowPage: TestPage Workflow;
    begin
        // [SCENARIO 5.1] User adds conditions to an existing event.
        // [GIVEN] Existing workflow.
        // [WHEN] User lookup the Condition and adds a filter to Amount.
        // [THEN] The Conditions gets saved and shown on in the condition column.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(WorkflowStep, Workflow, 0);

        WorkflowPage.OpenEdit();
        WorkflowPage.GotoKey(Workflow.Code);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1000, 2));
        Commit();

        // Exercise
        WorkflowPage.WorkflowSubpage.Condition.AssistEdit();
        // Event Handler will set values

        // Verify
        WorkflowStep.Find();
        WorkflowPage.WorkflowSubpage.Condition.AssertEquals(WorkflowStep.GetConditionAsDisplayText());
    end;

    [Test]
    [HandlerFunctions('ThenModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestInsertOfResponseByLookup()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowResponse: Record "Workflow Response";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowStepResponses: TestPage "Workflow Step Responses";
    begin
        // [SCENARIO 5.5] User creates response by typing full event name.
        // [GIVEN] Existing workflow.
        // [WHEN] User types the full response value the "Select response" field.
        // [THEN] Response gets created in the workflow step table.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(WorkflowStep, Workflow, 0);

        // Setup - Page
        TempWorkflowStepBuffer.PopulateTableFromEvent(WorkflowStep."Workflow Code", WorkflowStep.ID);
        WorkflowStepResponses.Trap();
        PAGE.Run(PAGE::"Workflow Step Responses", TempWorkflowStepBuffer);

        // Exercise
        CreateAnyResponse(WorkflowResponse);
        LibraryVariableStorage.Enqueue(WorkflowResponse.Description);
        WorkflowStepResponses.ResponseDescriptionCardControl.Lookup();
        // Handler will select value and close the lookup

        // Verify
        WorkflowStepResponses.ResponseDescriptionCardControl.AssertEquals(WorkflowResponse.Description);
        WorkflowStepResponses.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestClearOfResponseByTypingBlankValueSingleResponsePage()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowStepResponses: TestPage "Workflow Step Responses";
    begin
        // [SCENARIO 5.6] User clears response by deleting value in response.
        // [GIVEN] Existing workflow.
        // [WHEN] User deletes the existing response value.
        // [THEN] Response gets deleted in the workflow step table.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(EventWorkflowStep, Workflow, 0);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep, Workflow, EventWorkflowStep.ID);

        // Setup - Page
        TempWorkflowStepBuffer.PopulateTableFromEvent(EventWorkflowStep."Workflow Code", EventWorkflowStep.ID);
        WorkflowStepResponses.Trap();
        PAGE.Run(PAGE::"Workflow Step Responses", TempWorkflowStepBuffer);

        // Exercise
        WorkflowStepResponses.ResponseDescriptionCardControl.SetValue('');
        WorkflowStepResponses.Close();

        // Verify
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindLast();
        Assert.AreEqual(1, WorkflowStep.Count, 'Only the event should exist');
        WorkflowStep.TestField("Function Name", EventWorkflowStep."Function Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertOfResponseByTypingExactValueSingleResponsePage()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowResponse: Record "Workflow Response";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowStepResponses: TestPage "Workflow Step Responses";
    begin
        // [SCENARIO 6] User creates response by typing full event name.
        // [GIVEN] Existing workflow.
        // [WHEN] User types the full response value the "Select response" field.
        // [THEN] Response gets create in the workflow step table.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(WorkflowStep, Workflow, 0);

        // Setup - Page
        TempWorkflowStepBuffer.PopulateTableFromEvent(WorkflowStep."Workflow Code", WorkflowStep.ID);
        WorkflowStepResponses.Trap();
        PAGE.Run(PAGE::"Workflow Step Responses", TempWorkflowStepBuffer);

        // Exercise
        CreateAnyResponse(WorkflowResponse);
        WorkflowStepResponses.ResponseDescriptionCardControl.SetValue(WorkflowResponse.Description);
        WorkflowStepResponses.Close();

        // Verify
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindLast();
        WorkflowStep.TestField("Function Name", WorkflowResponse."Function Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertOfResponseByTypingExactTwiseValueSingleResponsePageBug()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowResponse: Record "Workflow Response";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowStepResponses: TestPage "Workflow Step Responses";
    begin
        // [SCENARIO 6b] User creates response by typing full event name.
        // [GIVEN] Existing workflow.
        // [WHEN] User types the full response value the "Select response" field.
        // [THEN] Response gets create in the workflow step table.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(WorkflowStep, Workflow, 0);

        // Setup - Page
        TempWorkflowStepBuffer.PopulateTableFromEvent(WorkflowStep."Workflow Code", WorkflowStep.ID);
        WorkflowStepResponses.Trap();
        PAGE.Run(PAGE::"Workflow Step Responses", TempWorkflowStepBuffer);

        // Exercise
        CreateAnyResponse(WorkflowResponse);
        WorkflowStepResponses.ResponseDescriptionCardControl.SetValue(WorkflowResponse.Description);
        WorkflowStepResponses.ResponseDescriptionCardControl.SetValue(WorkflowResponse.Description);
        WorkflowStepResponses.Close();

        // Verify
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindLast();
        Assert.AreEqual(2, WorkflowStep.Count, 'Only the event and one response should exist');
        WorkflowStep.TestField("Function Name", WorkflowResponse."Function Name");
    end;

    [Test]
    [HandlerFunctions('ThenModalPageHandlerLookupValidation')]
    [Scope('OnPrem')]
    procedure TestInsertOfResponseByTypingPartOfValueSingleResponsePage()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowResponse: Record "Workflow Response";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowStepResponses: TestPage "Workflow Step Responses";
    begin
        // [SCENARIO 7] User creates event by typing part of response name.
        // [GIVEN] Existing workflow.
        // [WHEN] User types part of the response description in the "Select response" column and leaves the field.
        // [THEN] User gets presented with a lookup filtered to the pretyped value there he selects the response
        // and Response gets create in the workflow step table and display the description to the user.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(WorkflowStep, Workflow, 0);

        // Setup - Page
        TempWorkflowStepBuffer.PopulateTableFromEvent(WorkflowStep."Workflow Code", WorkflowStep.ID);
        WorkflowStepResponses.Trap();
        PAGE.Run(PAGE::"Workflow Step Responses", TempWorkflowStepBuffer);

        // Exercise
        CreateAnyResponse(WorkflowResponse);
        WorkflowStepResponses.ResponseDescriptionCardControl.SetValue(CopyStr(WorkflowResponse.Description, 8, 8));
        // Lookup handler validates the filter and return to event

        // Verify
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindLast();
        WorkflowStep.TestField("Function Name", WorkflowResponse."Function Name");
        WorkflowStepResponses.ResponseDescriptionCardControl.AssertEquals(WorkflowResponse.Description);
        WorkflowStepResponses.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertOfResponseByTypingExactValueMultiResponsePage()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowResponse: Record "Workflow Response";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowStepResponses: TestPage "Workflow Step Responses";
    begin
        // [SCENARIO 8] User creates response by typing full event name.
        // [GIVEN] Existing workflow.
        // [WHEN] User types the full response value the "Then" column and leaves the field.
        // [THEN] Response gets create in the workflow step table.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(WorkflowStep, Workflow, 0);

        // Setup - Page
        TempWorkflowStepBuffer.PopulateTableFromEvent(WorkflowStep."Workflow Code", WorkflowStep.ID);
        WorkflowStepResponses.Trap();
        PAGE.Run(PAGE::"Workflow Step Responses", TempWorkflowStepBuffer);

        // Exercise
        CreateAnyResponse(WorkflowResponse);
        WorkflowStepResponses.ResponseDescriptionTableControl.SetValue(WorkflowResponse.Description);
        WorkflowStepResponses.Close();

        // Verify
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindLast();
        WorkflowStep.TestField("Function Name", WorkflowResponse."Function Name");
    end;

    [Test]
    [HandlerFunctions('ThenModalPageHandlerLookupValidation')]
    [Scope('OnPrem')]
    procedure TestInsertOfResponseByTypingPartOfValueMultiResponsePage()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowResponse: Record "Workflow Response";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowStepResponses: TestPage "Workflow Step Responses";
    begin
        // [SCENARIO 9] User creates event by typing part of response name.
        // [GIVEN] Existing workflow.
        // [WHEN] User types part of the response description in the "Select response" column and leaves the field.
        // [THEN] User gets presented with a lookup filtered to the pretyped value there he selects the response
        // and Response gets create in the workflow step table and display the description to the user.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(WorkflowStep, Workflow, 0);

        // Setup - Page
        TempWorkflowStepBuffer.PopulateTableFromEvent(WorkflowStep."Workflow Code", WorkflowStep.ID);
        WorkflowStepResponses.Trap();
        PAGE.Run(PAGE::"Workflow Step Responses", TempWorkflowStepBuffer);

        // Exercise
        CreateAnyResponse(WorkflowResponse);
        WorkflowStepResponses.ResponseDescriptionTableControl.SetValue(CopyStr(WorkflowResponse.Description, 8, 8));
        // Lookup handler validates the filter and return to event

        // Verify
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindLast();
        WorkflowStep.TestField("Function Name", WorkflowResponse."Function Name");
        WorkflowStepResponses.ResponseDescriptionTableControl.AssertEquals(WorkflowResponse.Description);
        WorkflowStepResponses.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNextStepOnlyShowsOnLastResponse()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep1: Record "Workflow Step";
        ResponseWorkflowStep2: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowStepResponses: TestPage "Workflow Step Responses";
    begin
        // [SCENARIO 10] User creates event by typing part of response name.
        // [GIVEN] Existing workflow.
        // [WHEN] User types part of the response description in the "Select response" column and leaves the field.
        // [THEN] User gets presented with a lookup filtered to the pretyped value there he selects the response
        // and Response gets create in the workflow step table and display the description to the user.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(EventWorkflowStep, Workflow, 0);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep1, Workflow, EventWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep2, Workflow, ResponseWorkflowStep1.ID);

        // Setup - Page
        TempWorkflowStepBuffer.PopulateTableFromEvent(EventWorkflowStep."Workflow Code", EventWorkflowStep.ID);
        WorkflowStepResponses.Trap();

        // Exercise
        PAGE.Run(PAGE::"Workflow Step Responses", TempWorkflowStepBuffer);

        // Verify
        WorkflowStepResponses.First();
        WorkflowStepResponses.NextStepDescription.AssertEquals('');
        WorkflowStepResponses.Next();
        WorkflowStepResponses.NextStepDescription.AssertEquals(NextStepTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResponseOptionsDueDateFormula()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowResponseOptions: TestPage "Workflow Response Options";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO 13] User types in a negative due date formula.
        // [GIVEN] Demo data approvals workflow
        // [WHEN] User types in a wrong due date formula.
        // [THEN] an error is shown.

        Initialize();

        // Setup.
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        WorkflowStep.FindFirst();

        WorkflowStepArgument.Get(WorkflowStep.Argument);

        WorkflowResponseOptions.Trap();
        PAGE.Run(PAGE::"Workflow Response Options", WorkflowStepArgument);

        // Exercise.
        Evaluate(DueDateFormula, '<-1M>');
        asserterror WorkflowResponseOptions."Due Date Formula".SetValue(DueDateFormula);

        // Verify
        Assert.ExpectedError(DueDateFormulaErr);
    end;

    [Test]
    [HandlerFunctions('ThenModalPageHandlerCombinationValidation')]
    [Scope('OnPrem')]
    procedure TestEventResponseCombinationOnLookup()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponse1: Record "Workflow Response";
        WorkflowResponse2: Record "Workflow Response";
        WorkflowResponse3: Record "Workflow Response";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowStepResponses: TestPage "Workflow Step Responses";
    begin
        // [SCENARIO] User can only select "independent" responses or responses preceded by the given event.
        // [GIVEN] Existing workflow event step.
        // [WHEN] User looks up the response.
        // [THEN] Only responses preceded by the event, or independent responses, are shown.

        // Event 1 -> Response 1
        // Event 2 -> Response 2
        // Response 3 - no preceding event

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(WorkflowStep, Workflow, 0);

        CreateAnyResponse(WorkflowResponse1);
        LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse1."Function Name", WorkflowStep."Function Name");

        CreateAnyEvent(WorkflowEvent);
        CreateAnyResponse(WorkflowResponse2);
        LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse2."Function Name", WorkflowEvent."Function Name");

        CreateAnyResponse(WorkflowResponse3);

        TempWorkflowStepBuffer.PopulateTableFromEvent(WorkflowStep."Workflow Code", WorkflowStep.ID);
        WorkflowStepResponses.Trap();
        PAGE.Run(PAGE::"Workflow Step Responses", TempWorkflowStepBuffer);

        // Exercise
        LibraryVariableStorage.Enqueue(WorkflowResponse1.Description);
        LibraryVariableStorage.Enqueue(WorkflowResponse2.Description);
        LibraryVariableStorage.Enqueue(WorkflowResponse3.Description);
        WorkflowStepResponses.ResponseDescriptionCardControl.Lookup();

        // Verify: in handler.
    end;

    [Test]
    [HandlerFunctions('WhenModalPageHandler,UIConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestResponseIsDeletedWhenDescriptionChanged()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowPage: TestPage Workflow;
    begin
        // [SCENARIO 431848] When Event is changed and response of old When event has been deleted

        Initialize();
        SetApplicationArea();

        // [GIVEN] Create Workflow
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoKey(Workflow.Code);

        // [THEN] Create event
        CreateAnyEvent(WorkflowEvent);
        LibraryVariableStorage.Enqueue(WorkflowEvent.Description);
        WorkflowPage.WorkflowSubpage."Event Description".Lookup();


        // [VERIFY] Event created
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindFirst();

        WorkflowStep.TestField("Function Name", WorkflowEvent."Function Name");
        WorkflowStep.TestField("Previous Workflow Step ID", 0);
        WorkflowStep.TestField("Entry Point", false);
        WorkflowPage.WorkflowSubpage."Event Description".AssertEquals(WorkflowEvent.Description);

        // [THEN] Change event
        CreateAnyEvent(WorkflowEvent);
        LibraryVariableStorage.Enqueue(WorkflowEvent.Description);

        WorkflowPage.WorkflowSubpage.First();
        WorkflowPage.WorkflowSubpage."Event Description".Lookup();

        // [VERIFY] Event changed, Response Deleted
        WorkflowStep.Get(WorkflowStep."Workflow Code", WorkflowStep.ID);
        WorkflowStep.TestField("Function Name", WorkflowEvent."Function Name");
        WorkflowPage.WorkflowSubpage."Event Description".AssertEquals(WorkflowEvent.Description);
        WorkflowPage.WorkflowSubpage."Response Description".AssertEquals(SelectResponseTxt);
    end;

    [Test]
    [HandlerFunctions('WhenModalPageHandler,UIConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestResponseIsNotDeletedWhenDescriptionNotChanged()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowPage: TestPage Workflow;
        ResponseTxtBefore: Text;
        ResponseTxtAfter: Text;
    begin
        // [SCENARIO 431818] When Event is not change and Response will not be deleted
        Initialize();
        SetApplicationArea();

        // [GIEVN] Create Workflow
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowPage.OpenEdit();
        WorkflowPage.GotoKey(Workflow.Code);

        // [THEN] Create event
        CreateAnyEvent(WorkflowEvent);
        LibraryVariableStorage.Enqueue(WorkflowEvent.Description);
        WorkflowPage.WorkflowSubpage."Event Description".Lookup();

        // [VERIFY] Event created
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.FindFirst();

        WorkflowStep.TestField("Function Name", WorkflowEvent."Function Name");
        WorkflowStep.TestField("Previous Workflow Step ID", 0);
        WorkflowStep.TestField("Entry Point", false);
        WorkflowPage.WorkflowSubpage."Event Description".AssertEquals(WorkflowEvent.Description);
        ResponseTxtBefore := WorkflowPage.WorkflowSubpage."Response Description".Value();

        // [THEN ] Try to Change event
        CreateAnyEvent(WorkflowEvent);
        LibraryVariableStorage.Enqueue(WorkflowEvent.Description);
        WorkflowPage.WorkflowSubpage.First();
        WorkflowPage.WorkflowSubpage."Event Description".Lookup();

        // [VERIFY] Verify Event Not changed
        WorkflowStep.Get(WorkflowStep."Workflow Code", WorkflowStep.ID);
        ResponseTxtAfter := WorkflowPage.WorkflowSubpage."Response Description".Value();
        Assert.AreEqual(ResponseTxtBefore, ResponseTxtAfter, ResponseDeletedLbl);
    end;

    local procedure Initialize()
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponse: Record "Workflow Response";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        LibraryVariableStorage.Clear();
        WorkflowEvent.DeleteAll();
        WorkflowEventHandling.CreateEventsLibrary();

        WorkflowResponse.DeleteAll();
        WorkflowResponseHandling.CreateResponsesLibrary();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhenModalPageHandler(var WhenLookup: TestPage "Workflow Events")
    var
        WhenDescription: Variant;
    begin
        LibraryVariableStorage.Dequeue(WhenDescription);
        WhenLookup.FILTER.SetFilter(Description, WhenDescription);
        WhenLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhenModalPageHandlerLookupValidation(var WhenLookup: TestPage "Workflow Events")
    begin
        Assert.IsFalse(WhenLookup.Next(), 'Only one line should be shown');
        WhenLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhenModalPageHandlerCombinationValidation(var WhenLookup: TestPage "Workflow Events")
    var
        WhenDescription1: Variant;
        WhenDescription2: Variant;
        RootWhenDescription: Variant;
    begin
        LibraryVariableStorage.Dequeue(RootWhenDescription);
        LibraryVariableStorage.Dequeue(WhenDescription1);
        LibraryVariableStorage.Dequeue(WhenDescription2);

        WhenLookup.FILTER.SetFilter(Description, RootWhenDescription);
        Assert.IsTrue(WhenLookup.First(), 'Only one line should be shown');
        Assert.IsFalse(WhenLookup.Next(), 'Only one line should be shown');

        WhenLookup.FILTER.SetFilter(Description, WhenDescription1);
        Assert.IsTrue(WhenLookup.First(), 'Only one line should be shown');
        Assert.IsFalse(WhenLookup.Next(), 'Only one line should be shown');

        WhenLookup.FILTER.SetFilter(Description, WhenDescription2);
        Assert.IsFalse(WhenLookup.First(), 'No line should be shown');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhenModalPageHandlerCombinationValidationPartialValue(var WhenLookup: TestPage "Workflow Events")
    var
        WhenDescription: Variant;
    begin
        LibraryVariableStorage.Dequeue(WhenDescription);
        WhenLookup.FILTER.SetFilter(Description, WhenDescription);
        Assert.IsTrue(WhenLookup.First(), 'Only one line should be shown');
        Assert.IsFalse(WhenLookup.Next(), 'Only one line should be shown');
        WhenLookup.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConditionModalPageHandler(var WorkflowEventSimpleArgs: TestRequestPage "Workflow Event Simple Args")
    var
        Amount: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        WorkflowEventSimpleArgs."Purchase Header".SetFilter(Amount, StrSubstNo('>%1', Amount));
        WorkflowEventSimpleArgs.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ThenModalPageHandlerLookupValidation(var WorkflowResponses: TestPage "Workflow Responses")
    begin
        Assert.IsFalse(WorkflowResponses.Next(), 'Only one line should be shown');
        WorkflowResponses.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ThenModalPageHandler(var WorkflowStepResponses: TestPage "Workflow Responses")
    var
        ThenDescription: Variant;
    begin
        LibraryVariableStorage.Dequeue(ThenDescription);
        WorkflowStepResponses.FILTER.SetFilter(Description, ThenDescription);
        WorkflowStepResponses.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ThenModalPageHandlerCombinationValidation(var WorkflowStepResponses: TestPage "Workflow Responses")
    var
        ThenDescription1: Variant;
        ThenDescription2: Variant;
        ThenDescription3: Variant;
    begin
        LibraryVariableStorage.Dequeue(ThenDescription1);
        LibraryVariableStorage.Dequeue(ThenDescription2);
        LibraryVariableStorage.Dequeue(ThenDescription3);

        WorkflowStepResponses.FILTER.SetFilter(Description, ThenDescription1);
        Assert.IsTrue(WorkflowStepResponses.First(), 'Only one line should be shown');
        Assert.IsFalse(WorkflowStepResponses.Next(), 'Only one line should be shown');

        WorkflowStepResponses.FILTER.SetFilter(Description, ThenDescription2);
        Assert.IsFalse(WorkflowStepResponses.First(), 'Only one line should be shown');

        WorkflowStepResponses.FILTER.SetFilter(Description, ThenDescription3);
        Assert.IsTrue(WorkflowStepResponses.First(), 'Only one line should be shown');
        Assert.IsFalse(WorkflowStepResponses.Next(), 'Only one line should be shown');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ThenModalPageHandlerOK(var WorkflowStepResponses: TestPage "Workflow Step Responses")
    begin
        WorkflowStepResponses.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UIConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UIConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure CreateAnyEventWorkflowStep(var WorkflowStep: Record "Workflow Step"; Workflow: Record Workflow; PreviousStepID: Integer)
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        CreateAnyEvent(WorkflowEvent);
        WorkflowStep.Get(Workflow.Code, LibraryWorkflow.InsertEventStep(Workflow, WorkflowEvent."Function Name", PreviousStepID));
    end;

    local procedure CreateAnyResponseWorkflowStep(var WorkflowStep: Record "Workflow Step"; Workflow: Record Workflow; PreviousStepID: Integer)
    var
        WorkflowResponse: Record "Workflow Response";
    begin
        CreateAnyResponse(WorkflowResponse);
        WorkflowStep.Get(Workflow.Code, LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponse."Function Name", PreviousStepID));
    end;

    local procedure CreateAnyEvent(var WorkflowEvent: Record "Workflow Event")
    begin
        WorkflowEvent.Init();
        WorkflowEvent."Function Name" := LibraryUtility.GenerateGUID();
        WorkflowEvent.Description := LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID();
        WorkflowEvent."Table ID" := DATABASE::"Purchase Header";
        WorkflowEvent."Request Page ID" := REPORT::"Workflow Event Simple Args";
        WorkflowEvent.Insert(true);
    end;

    local procedure CreateAnyResponse(var WorkflowResponse: Record "Workflow Response")
    begin
        WorkflowResponse.Init();
        WorkflowResponse."Function Name" := LibraryUtility.GenerateGUID();
        WorkflowResponse.Description := LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID();
        WorkflowResponse."Table ID" := DATABASE::"Purchase Header";
        WorkflowResponse.Insert(true);
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

