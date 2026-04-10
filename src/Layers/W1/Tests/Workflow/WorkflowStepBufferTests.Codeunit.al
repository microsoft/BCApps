codeunit 134312 "Workflow Step Buffer Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Step]
    end;

    var
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryUtility: Codeunit "Library - Utility";
        AmountConditionTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Purch. Inv. Event Conditions" id="1502"><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.) WHERE(Amount=FILTER(100))</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.)</DataItem></DataItems></ReportParameters>', Locked = true;
        TemplateTok: Label '<Template>';
        GenJnlBatchTok: Label '<Batch>';
        WhenNextStepDescTxt: Label 'Next when "%1"';
        CancelledErr: Label 'Cancelled.';

    [Test]
    [Scope('OnPrem')]
    procedure TestOneRootStepIsInserted()
    var
        Workflow: Record Workflow;
        AnyEventWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowEvent: Record "Workflow Event";
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(AnyEventWorkflowStep, Workflow);

        // Exercise
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Validate
        Assert.AreEqual(1, TempWorkflowStepBuffer.Count, 'Wrong number of lines');

        TempWorkflowStepBuffer.TestField(Order, 10000);
        TempWorkflowStepBuffer.TestField(Indent, 0);
        WorkflowEvent.Get(AnyEventWorkflowStep."Function Name");
        TempWorkflowStepBuffer.TestField("Event Description", WorkflowEvent.Description);
        TempWorkflowStepBuffer.TestField(Condition, '<Always>');
        TempWorkflowStepBuffer.TestField("Response Description", '<Select Response>');
        TempWorkflowStepBuffer.TestField("Event Step ID", AnyEventWorkflowStep.ID);
        TempWorkflowStepBuffer.TestField("Response Step ID", 0);
        TempWorkflowStepBuffer.TestField("Workflow Code", Workflow.Code);
        TempWorkflowStepBuffer.TestField("Parent Event Step ID", 0);
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", 0);
        TempWorkflowStepBuffer.TestField("Response Description Style", 'Standard');
        TempWorkflowStepBuffer.TestField("Entry Point", true);
        TempWorkflowStepBuffer.TestField("Sequence No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTwoRootStepAreInserted()
    var
        Workflow: Record Workflow;
        RootWorkflowStep1: Record "Workflow Step";
        RootWorkflowStep2: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(RootWorkflowStep1, Workflow);
        CreateAnyEventWorkflowStep(RootWorkflowStep2, Workflow, 0);

        // Exercise
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Validate
        Assert.AreEqual(2, TempWorkflowStepBuffer.Count, 'Wrong number of lines');

        TempWorkflowStepBuffer.TestField(Order, 10000);
        TempWorkflowStepBuffer.TestField(Indent, 0);
        TempWorkflowStepBuffer.TestField("Event Step ID", RootWorkflowStep1.ID);

        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField(Order, 20000);
        TempWorkflowStepBuffer.TestField(Indent, 0);
        TempWorkflowStepBuffer.TestField("Event Step ID", RootWorkflowStep2.ID);
        TempWorkflowStepBuffer.TestField("Entry Point", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChildStepAreInserted()
    var
        Workflow: Record Workflow;
        RootWorkflowStep: Record "Workflow Step";
        MiddleWorkflowStep: Record "Workflow Step";
        LeafWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(RootWorkflowStep, Workflow);
        CreateAnyEventWorkflowStep(MiddleWorkflowStep, Workflow, RootWorkflowStep.ID);
        CreateAnyEventWorkflowStep(LeafWorkflowStep, Workflow, MiddleWorkflowStep.ID);

        // Exercise
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Validate
        Assert.AreEqual(3, TempWorkflowStepBuffer.Count, 'Wrong number of lines');

        TempWorkflowStepBuffer.TestField(Order, 10000);
        TempWorkflowStepBuffer.TestField(Indent, 0);
        TempWorkflowStepBuffer.TestField("Event Step ID", RootWorkflowStep.ID);

        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField(Order, 20000);
        TempWorkflowStepBuffer.TestField(Indent, 1);
        TempWorkflowStepBuffer.TestField("Event Step ID", MiddleWorkflowStep.ID);

        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField(Order, 30000);
        TempWorkflowStepBuffer.TestField(Indent, 2);
        TempWorkflowStepBuffer.TestField("Event Step ID", LeafWorkflowStep.ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultipleEventStepWithSamePrevAreInserted()
    var
        Workflow: Record Workflow;
        RootWorkflowStep: Record "Workflow Step";
        WorkflowStep1: Record "Workflow Step";
        WorkflowStep2: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(RootWorkflowStep, Workflow);
        CreateAnyEventWorkflowStep(WorkflowStep1, Workflow, RootWorkflowStep.ID);
        CreateAnyEventWorkflowStep(WorkflowStep2, Workflow, RootWorkflowStep.ID);

        // Exercise
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Validate
        Assert.AreEqual(3, TempWorkflowStepBuffer.Count, 'Wrong number of lines');

        TempWorkflowStepBuffer.TestField(Indent, 0);
        TempWorkflowStepBuffer.TestField("Event Step ID", RootWorkflowStep.ID);

        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField(Indent, 1);
        TempWorkflowStepBuffer.TestField("Event Step ID", WorkflowStep1.ID);

        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField(Indent, 1);
        TempWorkflowStepBuffer.TestField("Event Step ID", WorkflowStep2.ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOneResponceStepIsInserted()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowEvent: Record "Workflow Event";
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EventWorkflowStep, Workflow);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep, Workflow, EventWorkflowStep.ID);

        // Exercise
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Validate
        Assert.AreEqual(1, TempWorkflowStepBuffer.Count, 'Wrong number of lines');

        TempWorkflowStepBuffer.TestField(Order, 10000);
        TempWorkflowStepBuffer.TestField(Indent, 0);
        WorkflowEvent.Get(EventWorkflowStep."Function Name");
        TempWorkflowStepBuffer.TestField("Event Description", WorkflowEvent.Description);
        TempWorkflowStepBuffer.TestField(Condition, '<Always>');
        TempWorkflowStepBuffer.TestField("Response Description", ResponseWorkflowStep.GetDescription());
        TempWorkflowStepBuffer.TestField("Event Step ID", EventWorkflowStep.ID);
        TempWorkflowStepBuffer.TestField("Response Step ID", ResponseWorkflowStep.ID);
        TempWorkflowStepBuffer.TestField("Workflow Code", Workflow.Code);
        TempWorkflowStepBuffer.TestField("Parent Event Step ID", 0);
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", 0);
        TempWorkflowStepBuffer.TestField("Response Description Style", 'Standard');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultipleResponseStepsAreInserted()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep1: Record "Workflow Step";
        ResponseWorkflowStep2: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EventWorkflowStep, Workflow);
        CreateResponseCreatePmtLineWorkflowStep(ResponseWorkflowStep1, Workflow, EventWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep2, Workflow, ResponseWorkflowStep1.ID);

        // Exercise
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Validate
        Assert.AreEqual(1, TempWorkflowStepBuffer.Count, 'Wrong number of lines');

        TempWorkflowStepBuffer.TestField("Response Description", '(+) ' + ResponseWorkflowStep1.GetDescription());
        TempWorkflowStepBuffer.TestField("Response Step ID", -1);
        TempWorkflowStepBuffer.TestField("Response Description Style", 'StandardAccent');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestConditionForEventStepsIsInserted()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EventWorkflowStep, Workflow);
        SetEventFilters(EventWorkflowStep, AmountConditionTxt);

        // Exercise
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Validate
        Assert.AreEqual(1, TempWorkflowStepBuffer.Count, 'Wrong number of lines');

        TempWorkflowStepBuffer.TestField(Condition, 'Amount: 100');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResponseArgsAreInserted()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        ResponseDescription: Text;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EventWorkflowStep, Workflow);
        CreateResponseCreatePmtLineWorkflowStep(ResponseWorkflowStep, Workflow, EventWorkflowStep.ID);

        // Exercise
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Validate
        Assert.AreEqual(1, TempWorkflowStepBuffer.Count, 'Wrong number of lines');

        ResponseDescription := GetResponseDescription(WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocAsyncCode());
        TempWorkflowStepBuffer.TestField("Response Description", StrSubstNo(ResponseDescription, TemplateTok, GenJnlBatchTok));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSingleResponseForEventIsInserted()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        ResponseDescription: Text;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EventWorkflowStep, Workflow);
        CreateResponseCreatePmtLineWorkflowStep(ResponseWorkflowStep, Workflow, EventWorkflowStep.ID);

        // Exercise
        TempWorkflowStepBuffer.PopulateTableFromEvent(Workflow.Code, EventWorkflowStep.ID);

        // Validate
        Assert.AreEqual(1, TempWorkflowStepBuffer.Count, 'Wrong number of lines');

        TempWorkflowStepBuffer.TestField(Order, 10000);
        TempWorkflowStepBuffer.TestField(Indent, 0);
        TempWorkflowStepBuffer.TestField("Event Description", '');
        TempWorkflowStepBuffer.TestField(Condition, '');
        ResponseDescription := GetResponseDescription(WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocAsyncCode());
        TempWorkflowStepBuffer.TestField("Response Description", StrSubstNo(ResponseDescription, TemplateTok, GenJnlBatchTok));
        TempWorkflowStepBuffer.TestField("Event Step ID", 0);
        TempWorkflowStepBuffer.TestField("Response Step ID", ResponseWorkflowStep.ID);
        TempWorkflowStepBuffer.TestField("Workflow Code", Workflow.Code);
        TempWorkflowStepBuffer.TestField("Parent Event Step ID", EventWorkflowStep.ID);
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", EventWorkflowStep.ID);
        TempWorkflowStepBuffer.TestField("Response Description Style", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultipleResponsesForEventAreInserted()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep1: Record "Workflow Step";
        ResponseWorkflowStep2: Record "Workflow Step";
        ResponseWorkflowStep3: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EventWorkflowStep, Workflow);
        CreateResponseCreatePmtLineWorkflowStep(ResponseWorkflowStep1, Workflow, EventWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep2, Workflow, ResponseWorkflowStep1.ID);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep3, Workflow, ResponseWorkflowStep2.ID);

        // Exercise
        TempWorkflowStepBuffer.PopulateTableFromEvent(Workflow.Code, EventWorkflowStep.ID);

        // Validate
        Assert.AreEqual(3, TempWorkflowStepBuffer.Count, 'Wrong number of lines');

        TempWorkflowStepBuffer.TestField(Order, 10000);
        TempWorkflowStepBuffer.TestField("Response Step ID", ResponseWorkflowStep1.ID);
        TempWorkflowStepBuffer.TestField("Parent Event Step ID", EventWorkflowStep.ID);
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", EventWorkflowStep.ID);

        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField(Order, 20000);
        TempWorkflowStepBuffer.TestField("Response Step ID", ResponseWorkflowStep2.ID);
        TempWorkflowStepBuffer.TestField("Parent Event Step ID", EventWorkflowStep.ID);
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", ResponseWorkflowStep1.ID);

        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField(Order, 30000);
        TempWorkflowStepBuffer.TestField("Response Step ID", ResponseWorkflowStep3.ID);
        TempWorkflowStepBuffer.TestField("Parent Event Step ID", EventWorkflowStep.ID);
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", ResponseWorkflowStep2.ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestClearBuffer()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EventWorkflowStep, Workflow);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep, Workflow, EventWorkflowStep.ID);

        // Setup - Buffer with data
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Exercise
        TempWorkflowStepBuffer.ClearBuffer();

        // Validate
        Assert.IsTrue(TempWorkflowStepBuffer.IsEmpty, 'Buffer should be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertBlankWorkflow()
    var
        Workflow: Record Workflow;
        InsertedEventWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        LastStepID: Integer;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        LastStepID := FindLastStepID();

        // Exercise
        TempWorkflowStepBuffer."Workflow Code" := Workflow.Code;
        TempWorkflowStepBuffer.Order := 10000;
        TempWorkflowStepBuffer.Insert(true);

        // Validate
        TempWorkflowStepBuffer.TestField("Event Step ID", LastStepID + 1);

        InsertedEventWorkflowStep.Get(Workflow.Code, LastStepID + 1);
        InsertedEventWorkflowStep.TestField("Previous Workflow Step ID", 0);
        InsertedEventWorkflowStep.TestField(Type, InsertedEventWorkflowStep.Type::"Event");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertAddEventToExistingWorkflow()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        InsertedEventWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EventWorkflowStep, Workflow);
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Exercise
        TempWorkflowStepBuffer.Init();
        TempWorkflowStepBuffer."Workflow Code" := Workflow.Code;
        TempWorkflowStepBuffer.Order := 20000;
        TempWorkflowStepBuffer.Insert(true);

        // Validate
        TempWorkflowStepBuffer.TestField("Event Step ID", EventWorkflowStep.ID + 1);

        InsertedEventWorkflowStep.Get(Workflow.Code, EventWorkflowStep.ID + 1);
        InsertedEventWorkflowStep.TestField("Previous Workflow Step ID", 0);
        InsertedEventWorkflowStep.TestField(Type, InsertedEventWorkflowStep.Type::"Event");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertAddResponseToExistingWorkflow()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        InsertedEventWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EventWorkflowStep, Workflow);
        TempWorkflowStepBuffer.PopulateTableFromEvent(Workflow.Code, EventWorkflowStep.ID);

        // Exercise
        TempWorkflowStepBuffer.Init();
        TempWorkflowStepBuffer."Workflow Code" := Workflow.Code;
        TempWorkflowStepBuffer.Order := 10000;
        TempWorkflowStepBuffer."Parent Event Step ID" := EventWorkflowStep.ID;
        TempWorkflowStepBuffer.Insert(true);

        // Validate
        TempWorkflowStepBuffer.TestField("Response Step ID", EventWorkflowStep.ID + 1);

        InsertedEventWorkflowStep.Get(Workflow.Code, EventWorkflowStep.ID + 1);
        InsertedEventWorkflowStep.TestField("Previous Workflow Step ID", EventWorkflowStep.ID);
        InsertedEventWorkflowStep.TestField(Type, InsertedEventWorkflowStep.Type::Response);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateNewWhenThenLine()
    var
        Workflow: Record Workflow;
        RootEventWorkflowStep: Record "Workflow Step";
        LeafEventWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(RootEventWorkflowStep, Workflow);
        CreateAnyEventWorkflowStep(LeafEventWorkflowStep, Workflow, RootEventWorkflowStep.ID);
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Setup - Move to last row
        TempWorkflowStepBuffer.FindLast();
        TempWorkflowStepBuffer.SetxRec(TempWorkflowStepBuffer);

        // Exercise
        TempWorkflowStepBuffer.Init();
        TempWorkflowStepBuffer.CreateNewWhenThenLine(Workflow.Code, true);

        // Validation
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", RootEventWorkflowStep.ID);
        TempWorkflowStepBuffer.TestField(Indent, 1);
        TempWorkflowStepBuffer.TestField(Order, 30000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEntryPointOnOff()
    var
        Workflow: Record Workflow;
        RootEventWorkflowStep: Record "Workflow Step";
        LeafEventWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(RootEventWorkflowStep, Workflow);
        CreateAnyEventWorkflowStep(LeafEventWorkflowStep, Workflow, RootEventWorkflowStep.ID);
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);
        TempWorkflowStepBuffer.Get(20000);

        // Exercise - Set Entry Point
        TempWorkflowStepBuffer.Validate("Entry Point", true);

        // Verify - Set Entry Point
        LeafEventWorkflowStep.Find();
        LeafEventWorkflowStep.TestField("Entry Point", true);

        // Exercise - Clear Entry Point
        TempWorkflowStepBuffer.Validate("Entry Point", false);

        // Verify - Clear Entry Point
        LeafEventWorkflowStep.Find();
        LeafEventWorkflowStep.TestField("Entry Point", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSequenceNoGetSetWhenInsertingRow()
    var
        Workflow: Record Workflow;
        RootEventWorkflowStep: Record "Workflow Step";
        LeafEventWorkflowStep1: Record "Workflow Step";
        LeafEventWorkflowStep2: Record "Workflow Step";
        NewWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(RootEventWorkflowStep, Workflow);
        CreateAnyEventWorkflowStep(LeafEventWorkflowStep1, Workflow, RootEventWorkflowStep.ID);
        CreateAnyEventWorkflowStep(LeafEventWorkflowStep2, Workflow, RootEventWorkflowStep.ID);
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        TempWorkflowStepBuffer.FindLast();
        TempWorkflowStepBuffer.SetxRec(TempWorkflowStepBuffer);

        // Exercise
        TempWorkflowStepBuffer.Init();
        TempWorkflowStepBuffer.CreateNewWhenThenLine(Workflow.Code, false);
        TempWorkflowStepBuffer.Insert(true);

        // Verify
        NewWorkflowStep.Get(Workflow.Code, TempWorkflowStepBuffer."Event Step ID");
        NewWorkflowStep.TestField("Sequence No.", 2);
        LeafEventWorkflowStep2.Find();
        LeafEventWorkflowStep2.TestField("Sequence No.", 3)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBufferLoadedInSequence()
    var
        Workflow: Record Workflow;
        RootEventWorkflowStep: Record "Workflow Step";
        LeafEventWorkflowStep1: Record "Workflow Step";
        LeafEventWorkflowStep2: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(RootEventWorkflowStep, Workflow);
        CreateAnyEventWorkflowStep(LeafEventWorkflowStep1, Workflow, RootEventWorkflowStep.ID);
        LibraryWorkflow.SetSequenceNo(Workflow, LeafEventWorkflowStep1.ID, 2);
        CreateAnyEventWorkflowStep(LeafEventWorkflowStep2, Workflow, RootEventWorkflowStep.ID);
        LibraryWorkflow.SetSequenceNo(Workflow, LeafEventWorkflowStep2.ID, 1);

        // Exercise
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        // Verify
        TempWorkflowStepBuffer.FindSet();
        TempWorkflowStepBuffer.TestField("Event Step ID", RootEventWorkflowStep.ID);
        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField("Event Step ID", LeafEventWorkflowStep2.ID);
        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField("Event Step ID", LeafEventWorkflowStep1.ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecreaseIndentChangesPreviousWorkflowStepId()
    var
        Workflow: Record Workflow;
        EntryEventWorkflowStep: Record "Workflow Step";
        EventWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // [FEATURE] [Workflow Designer] [Event Indentation]
        // [SCENARIO 1] User moves left a leaf event.
        // [GIVEN] A workflow with a zero-indent event, and a subsequent event.
        // [WHEN] User invokes Decrease Indent action for the second event.
        // [THEN] Second event gets promoted to the zero indent.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EntryEventWorkflowStep, Workflow);
        CreateAnyEventWorkflowStep(EventWorkflowStep, Workflow, EntryEventWorkflowStep.ID);

        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        TempWorkflowStepBuffer.SetRange("Event Step ID", EventWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();

        // Exercise
        TempWorkflowStepBuffer.MoveLeft();

        // Verify
        TempWorkflowStepBuffer.Find();
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", EntryEventWorkflowStep."Previous Workflow Step ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncreaseIndentChangesPreviousWorkflowStepId()
    var
        Workflow: Record Workflow;
        EntryEventWorkflowStep: Record "Workflow Step";
        EntryEventWorkflowStep2: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // [FEATURE] [Workflow Designer] [Event Indentation]
        // [SCENARIO 2] User moves right a leaf event.
        // [GIVEN] A workflow with two zero-indent events.
        // [WHEN] User invokes Increase Indent action for the second event.
        // [THEN] Second event gets demoted to follow the zero-indent event.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EntryEventWorkflowStep, Workflow);
        CreateAnyEntryEventWorkflowStep(EntryEventWorkflowStep2, Workflow);

        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        TempWorkflowStepBuffer.SetRange("Event Step ID", EntryEventWorkflowStep2.ID);
        TempWorkflowStepBuffer.FindFirst();

        // Exercise
        TempWorkflowStepBuffer.MoveRight();

        // Verify
        TempWorkflowStepBuffer.Find();
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", EntryEventWorkflowStep.ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecreaseIndentChangesPreviousWorkflowStepIdWithResponses()
    var
        Workflow: Record Workflow;
        EntryEventWorkflowStep: Record "Workflow Step";
        EventWorkflowStep: Record "Workflow Step";
        FirstResponseWorkflowStep: Record "Workflow Step";
        SecondResponseWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // [FEATURE] [Workflow Designer] [Event Indentation]
        // [SCENARIO 3] User moves left a leaf event with responses.
        // [GIVEN] A workflow with a zero-indent event with response, and a subsequent event with response.
        // [WHEN] User invokes Decrease Indent action for the second event.
        // [THEN] Second event gets promoted to zero indent.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EntryEventWorkflowStep, Workflow);
        CreateAnyResponseWorkflowStep(FirstResponseWorkflowStep, Workflow, EntryEventWorkflowStep.ID);
        CreateAnyEventWorkflowStep(EventWorkflowStep, Workflow, FirstResponseWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(SecondResponseWorkflowStep, Workflow, EventWorkflowStep.ID);

        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        TempWorkflowStepBuffer.SetRange("Event Step ID", EventWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();

        // Exercise
        TempWorkflowStepBuffer.MoveLeft();

        // Verify
        TempWorkflowStepBuffer.Find();
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", EntryEventWorkflowStep."Previous Workflow Step ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncreaseIndentChangesPreviousWorkflowStepIdWithResponses()
    var
        Workflow: Record Workflow;
        EntryEventWorkflowStep: Record "Workflow Step";
        EntryEventWorkflowStep2: Record "Workflow Step";
        FirstResponseWorkflowStep: Record "Workflow Step";
        SecondResponseWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // [FEATURE] [Workflow Designer] [Event Indentation]
        // [SCENARIO 4] User moves right a leaf event with responses.
        // [GIVEN] A workflow with an zero-indent event with response, and a subsequent event with response.
        // [WHEN] User invokes Increase Indent action for the second event.
        // [THEN] Second event gets promoted to zero-indent.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EntryEventWorkflowStep, Workflow);
        CreateAnyResponseWorkflowStep(FirstResponseWorkflowStep, Workflow, EntryEventWorkflowStep.ID);
        CreateAnyEventWorkflowStep(EntryEventWorkflowStep2, Workflow, FirstResponseWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(SecondResponseWorkflowStep, Workflow, EntryEventWorkflowStep2.ID);

        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        TempWorkflowStepBuffer.SetRange("Event Step ID", EntryEventWorkflowStep2.ID);
        TempWorkflowStepBuffer.FindFirst();

        // Exercise
        TempWorkflowStepBuffer.MoveRight();

        // Verify
        TempWorkflowStepBuffer.Find();
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", FirstResponseWorkflowStep.ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncreaseDecreaseIndentBelowPreviousEvent()
    var
        Workflow: Record Workflow;
        EntryEventWorkflowStep: Record "Workflow Step";
        SecondWorkflowStep: Record "Workflow Step";
        ThirdWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        FirstResponseWorkflowStep: Record "Workflow Step";
        SecondResponseWorkflowStep: Record "Workflow Step";
        ThirdResponseWorkflowStep: Record "Workflow Step";
    begin
        // [FEATURE] [Workflow Designer] [Event Indentation]
        // [SCENARIO 5] User moves right a leaf event with responses, when there is an event above.
        // [GIVEN] A workflow with two zero-indent events with responses, one of which has a subsequent event.
        // [WHEN] User invokes Increase Indent action for the second zero-indent event.
        // [THEN] Second zero-indent event gets moved under the first zero-indent event's descendant.
        // [WHEN] User invokes Decrease Indent action for the second zero-indent event.
        // [THEN] Second zero-indent event gets moved under the first zero-indent event again.

        // E
        // |_
        // # R
        // # |_
        // #   E
        // #   |_
        // #     R
        // E <->
        // |_
        // # R

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EntryEventWorkflowStep, Workflow);
        CreateAnyResponseWorkflowStep(FirstResponseWorkflowStep, Workflow, EntryEventWorkflowStep.ID);
        CreateAnyEventWorkflowStep(SecondWorkflowStep, Workflow, FirstResponseWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(SecondResponseWorkflowStep, Workflow, SecondWorkflowStep.ID);
        CreateAnyEntryEventWorkflowStep(ThirdWorkflowStep, Workflow);
        CreateAnyResponseWorkflowStep(ThirdResponseWorkflowStep, Workflow, ThirdWorkflowStep.ID);

        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        TempWorkflowStepBuffer.SetRange("Event Step ID", ThirdWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();

        // Exercise
        TempWorkflowStepBuffer.MoveRight();

        // Verify
        TempWorkflowStepBuffer.Find();
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", FirstResponseWorkflowStep.ID);

        // Exercise
        TempWorkflowStepBuffer.SetRange("Event Step ID", ThirdWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();

        TempWorkflowStepBuffer.MoveLeft();

        // Verify
        TempWorkflowStepBuffer.Find();
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecreaseIncreaseIndentForEventsWithSameIndent()
    var
        Workflow: Record Workflow;
        EntryEventWorkflowStep: Record "Workflow Step";
        SecondWorkflowStep: Record "Workflow Step";
        ThirdWorkflowStep: Record "Workflow Step";
        FourthWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        FirstResponseWorkflowStep: Record "Workflow Step";
        SecondResponseWorkflowStep: Record "Workflow Step";
        ThirdResponseWorkflowStep: Record "Workflow Step";
        FourthResponseWorkflowStep: Record "Workflow Step";
    begin
        // [FEATURE] [Workflow Designer] [Event Indentation]
        // [SCENARIO 6] User moves left a leaf event with response, when there are siblign events with same indent.
        // [GIVEN] A workflow with one zero-indent event with response, and 3 subsequent sibling events.
        // [WHEN] User invokes Decrease Indent action for the second sibling event.
        // [THEN] Second sibling event becomes a zero-indent event and the last sibling event becomes its descendant.
        // [WHEN] User invokes Increase Indent action for the second sibling event.
        // [THEN] Second sibling event gets moved under the first zero-indent event event again.

        // E
        // |_
        // # R
        // # |_
        // # | E
        // # | |_
        // # |   R
        // # |_
        // <-> E
        // # | |_
        // # |   R
        // # |_
        // #   E
        // #   |_
        // #     R

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EntryEventWorkflowStep, Workflow);
        CreateAnyResponseWorkflowStep(FirstResponseWorkflowStep, Workflow, EntryEventWorkflowStep.ID);
        CreateAnyEventWorkflowStep(SecondWorkflowStep, Workflow, FirstResponseWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(SecondResponseWorkflowStep, Workflow, SecondWorkflowStep.ID);
        CreateAnyEventWorkflowStep(ThirdWorkflowStep, Workflow, FirstResponseWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(ThirdResponseWorkflowStep, Workflow, ThirdWorkflowStep.ID);
        CreateAnyEventWorkflowStep(FourthWorkflowStep, Workflow, FirstResponseWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(FourthResponseWorkflowStep, Workflow, FourthWorkflowStep.ID);

        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        TempWorkflowStepBuffer.SetRange("Event Step ID", ThirdWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();

        // Exercise
        TempWorkflowStepBuffer.MoveLeft();

        // Verify
        TempWorkflowStepBuffer.Find();
        Assert.AreEqual(0, TempWorkflowStepBuffer."Previous Workflow Step ID",
          'The third step should be an entry point.');

        TempWorkflowStepBuffer.SetRange("Event Step ID", FourthWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();
        Assert.AreEqual(ThirdResponseWorkflowStep.ID, TempWorkflowStepBuffer."Previous Workflow Step ID",
          'The last step should point to the third events response');

        TempWorkflowStepBuffer.MoveLeft();

        // Exercise
        TempWorkflowStepBuffer.SetRange("Event Step ID", ThirdWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();

        TempWorkflowStepBuffer.MoveRight();

        // Verify
        TempWorkflowStepBuffer.Find();
        Assert.AreEqual(FirstResponseWorkflowStep.ID, TempWorkflowStepBuffer."Previous Workflow Step ID",
          'The thirs step should point to the first events response');

        TempWorkflowStepBuffer.SetRange("Event Step ID", FourthWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotChangeIndentIfEventIsEntryPointAndHasSubsequentEvents()
    var
        Workflow: Record Workflow;
        EntryEventWorkflowStep: Record "Workflow Step";
        EventWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // [FEATURE] [Workflow Designer] [Event Indentation]
        // [SCENARIO 7] User cannot move an entry point event that is not a leaf.
        // [GIVEN] A workflow with a zero-indent event, and a subsequent event.
        // [WHEN] User invokes Increase Indent action for the zero-indent event.
        // [THEN] Nothing happens.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EntryEventWorkflowStep, Workflow);
        CreateAnyEventWorkflowStep(EventWorkflowStep, Workflow, EntryEventWorkflowStep.ID);

        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        TempWorkflowStepBuffer.SetRange("Event Step ID", EntryEventWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();

        // Exercise
        TempWorkflowStepBuffer.MoveRight();

        // Verify
        TempWorkflowStepBuffer.Find();
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncreaseIndentIfEventHasSubtree()
    var
        Workflow: Record Workflow;
        EntryEventWorkflowStep: Record "Workflow Step";
        EventWorkflowStep: Record "Workflow Step";
        EventWorkflowStep2: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // [FEATURE] [Workflow Designer] [Event Indentation]
        // [SCENARIO 8] User can move an event that is not a leaf.
        // [GIVEN] A workflow with a zero-indent event, and a subsequent event.
        // [WHEN] User invokes Increase Indent action for the zero-indent event.
        // [THEN] The subtree is linked to the parent.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EntryEventWorkflowStep, Workflow);
        CreateAnyEventWorkflowStep(EventWorkflowStep, Workflow, EntryEventWorkflowStep.ID);
        CreateAnyEventWorkflowStep(EventWorkflowStep2, Workflow, EventWorkflowStep.ID);

        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        TempWorkflowStepBuffer.SetRange("Event Step ID", EventWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();

        // Exercise
        TempWorkflowStepBuffer.MoveRight();

        // Verify
        TempWorkflowStepBuffer.SetRange("Event Step ID", EventWorkflowStep2.ID);
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", EntryEventWorkflowStep.ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecreaseIncreaseIndentIfEventHasSubtree()
    var
        Workflow: Record Workflow;
        EntryEventWorkflowStep: Record "Workflow Step";
        EventWorkflowStep: Record "Workflow Step";
        EventWorkflowStep2: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // [FEATURE] [Workflow Designer] [Event Indentation]
        // [SCENARIO 9] User can move an event that is not a leaf left and then right.
        // [GIVEN] A workflow with a zero-indent event, and a subsequent event.
        // [WHEN] User invokes Decrease Indent action for the zero-indent event and then Increase.
        // [THEN] The subtree is linked to the moved event parent.

        // E
        // |____
        // <-> E
        // |_
        // E

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EntryEventWorkflowStep, Workflow);
        CreateAnyEventWorkflowStep(EventWorkflowStep, Workflow, EntryEventWorkflowStep.ID);
        CreateAnyEventWorkflowStep(EventWorkflowStep2, Workflow, EntryEventWorkflowStep.ID);

        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);

        TempWorkflowStepBuffer.SetRange("Event Step ID", EventWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();

        // Exercise.
        TempWorkflowStepBuffer.MoveLeft();

        // Verify.
        TempWorkflowStepBuffer.Find();
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", 0);

        TempWorkflowStepBuffer.SetRange("Event Step ID", EventWorkflowStep2.ID);
        TempWorkflowStepBuffer.FindFirst();
        TempWorkflowStepBuffer.TestField("Previous Workflow Step ID", EventWorkflowStep.ID);

        // Exercise
        TempWorkflowStepBuffer.SetRange("Event Step ID", EventWorkflowStep.ID);
        TempWorkflowStepBuffer.FindFirst();
        TempWorkflowStepBuffer.MoveRight();

        // Verify
        EventWorkflowStep.Find();
        EventWorkflowStep.TestField("Previous Workflow Step ID", EntryEventWorkflowStep.ID);

        EventWorkflowStep2.Find();
        EventWorkflowStep2.TestField("Previous Workflow Step ID", EntryEventWorkflowStep.ID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNextStep()
    var
        Workflow: Record Workflow;
        RootEventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep1: Record "Workflow Step";
        ResponseWorkflowStep2: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        WorkflowEvent: Record "Workflow Event";
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(RootEventWorkflowStep, Workflow);
        WorkflowEvent.Get(RootEventWorkflowStep."Function Name");
        WorkflowEvent.Description := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        WorkflowEvent.Modify(true);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep1, Workflow, RootEventWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep2, Workflow, ResponseWorkflowStep1.ID);
        LibraryWorkflow.SetNextStep(Workflow, ResponseWorkflowStep2.ID, RootEventWorkflowStep.ID);

        // Exercise
        TempWorkflowStepBuffer.PopulateTableFromEvent(Workflow.Code, RootEventWorkflowStep.ID);

        // Verify
        TempWorkflowStepBuffer.FindSet();
        TempWorkflowStepBuffer.TestField("Next Step Description", '');
        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField("Next Step Description", StrSubstNo(WhenNextStepDescTxt, RootEventWorkflowStep.GetDescription()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNextStepLookup()
    var
        Workflow: Record Workflow;
        RootEventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep1: Record "Workflow Step";
        ResponseWorkflowStep2: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(RootEventWorkflowStep, Workflow);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep1, Workflow, RootEventWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep2, Workflow, ResponseWorkflowStep1.ID);

        // Exercise
        TempWorkflowStepBuffer.PopulateLookupTable(Workflow.Code);

        // Verify
        TempWorkflowStepBuffer.FindSet();
        TempWorkflowStepBuffer.TestField("Event Description", RootEventWorkflowStep.GetDescription());
        TempWorkflowStepBuffer.TestField("Response Description", '');
        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField("Event Description", '');
        TempWorkflowStepBuffer.TestField("Response Description", ResponseWorkflowStep1.GetDescription());
        TempWorkflowStepBuffer.Next();
        TempWorkflowStepBuffer.TestField("Event Description", '');
        TempWorkflowStepBuffer.TestField("Response Description", ResponseWorkflowStep2.GetDescription());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestConfirmOnDeleteResponseWithLinkReference()
    var
        DummyWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        StepID: Integer;
    begin
        // [SCENARIO 382391] WF Step which is referred by the other WF Steps is confirmed when deleted.

        // [GIVEN] Workflow "WF" with two events and two responses, where the second response has reference to the first response.
        CreateTwoEventsWithLinkedResponses(TempWorkflowStepBuffer, StepID);

        // [WHEN] Remove the First response for "WF" and answer YES to confirmation dialog.
        DeleteTempWorkflowStepBufferEntry(TempWorkflowStepBuffer, StepID);

        // [THEN] The reference link between the Second and the First response is cleared.
        DummyWorkflowStep.SetRange("Workflow Code", TempWorkflowStepBuffer."Workflow Code");
        DummyWorkflowStep.SetFilter("Next Workflow Step ID", '<>%1', 0);
        Assert.RecordIsEmpty(DummyWorkflowStep);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestNotConfirmOnDeleteResponseWithLinkReference()
    var
        DummyWorkflowStep: Record "Workflow Step";
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
        StepID: Integer;
    begin
        // [SCENARIO 382391] WF Step which is referred by other WF Steps was is not confirmed on delete and has not been deleted.

        // [GIVEN] Workflow "WF" with two events and two responses, where the second response has reference to the first response.
        CreateTwoEventsWithLinkedResponses(TempWorkflowStepBuffer, StepID);

        // [WHEN] Remove the First response for "WF" and answer NO to confirmation dialog.
        DummyWorkflowStep.SetRange("Workflow Code", TempWorkflowStepBuffer."Workflow Code");
        DummyWorkflowStep.SetFilter("Next Workflow Step ID", '<>%1', 0);
        Assert.RecordIsNotEmpty(DummyWorkflowStep);
        Commit();
        asserterror DeleteTempWorkflowStepBufferEntry(TempWorkflowStepBuffer, StepID);

        // [THEN] Transaction is rolled back with an expected message.
        Assert.ExpectedError(CancelledErr);
        Assert.RecordIsNotEmpty(DummyWorkflowStep);
    end;

    local procedure CreateAnyEvent(var WorkflowEvent: Record "Workflow Event")
    begin
        WorkflowEvent.Init();
        WorkflowEvent."Function Name" := LibraryUtility.GenerateGUID();
        WorkflowEvent.Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(WorkflowEvent.Description)), 1,
            MaxStrLen(WorkflowEvent.Description));
        WorkflowEvent."Table ID" := DATABASE::"Purchase Header";
        WorkflowEvent.Insert(true);
    end;

    local procedure CreateAnyResponse(var WorkflowResponse: Record "Workflow Response")
    begin
        WorkflowResponse.Init();
        WorkflowResponse."Function Name" := LibraryUtility.GenerateGUID();
        WorkflowResponse.Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(WorkflowResponse.Description)), 1,
            MaxStrLen(WorkflowResponse.Description));
        WorkflowResponse."Table ID" := DATABASE::"Purchase Header";
        WorkflowResponse.Insert(true);
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

    local procedure CreateAnyEntryEventWorkflowStep(var WorkflowStep: Record "Workflow Step"; Workflow: Record Workflow)
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        CreateAnyEvent(WorkflowEvent);
        WorkflowStep.Get(Workflow.Code, LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent."Function Name"));
    end;

    local procedure CreateResponseCreatePmtLineWorkflowStep(var WorkflowStep: Record "Workflow Step"; Workflow: Record Workflow; PreviousStepID: Integer)
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        ResponseStep: Integer;
    begin
        ResponseStep := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocAsyncCode(),
            PreviousStepID);

        WorkflowStep.Get(Workflow.Code, ResponseStep);
    end;

    local procedure SetEventFilters(var WorkflowStep: Record "Workflow Step"; Filters: Text)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        LibraryWorkflow.CreateWorkflowStepArgument(WorkflowStepArgument, WorkflowStepArgument.Type::"Event", UserId, '', '',
          WorkflowStepArgument."Approver Type"::Approver, false);
        WorkflowStepArgument.SetEventFilters(Filters);
        WorkflowStep.Argument := WorkflowStepArgument.ID;
        WorkflowStep.Modify();
    end;

    local procedure FindLastStepID(): Integer
    var
        WorkflowStep: Record "Workflow Step";
        ID: Integer;
    begin
        WorkflowStep.Init();
        WorkflowStep.Insert();
        ID := WorkflowStep.ID;
        WorkflowStep.Delete();
        exit(ID);
    end;

    local procedure GetResponseDescription(ResponseCode: Code[128]): Text
    var
        WorkflowResponse: Record "Workflow Response";
    begin
        WorkflowResponse.Get(ResponseCode);
        exit(WorkflowResponse.Description);
    end;

    local procedure CreateTwoEventsWithLinkedResponses(var TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary; var EntryEventWorkflowStepID: Integer)
    var
        Workflow: Record Workflow;
        EntryEventWorkflowStep: Record "Workflow Step";
        SecondWorkflowStep: Record "Workflow Step";
        FirstResponseWorkflowStep: Record "Workflow Step";
        SecondResponseWorkflowStep: Record "Workflow Step";
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EntryEventWorkflowStep, Workflow);
        CreateAnyResponseWorkflowStep(FirstResponseWorkflowStep, Workflow, EntryEventWorkflowStep.ID);
        CreateAnyEventWorkflowStep(SecondWorkflowStep, Workflow, FirstResponseWorkflowStep.ID);
        CreateAnyResponseWorkflowStep(SecondResponseWorkflowStep, Workflow, SecondWorkflowStep.ID);
        TempWorkflowStepBuffer.PopulateTable(Workflow.Code);
        LibraryWorkflow.SetNextStep(Workflow, SecondResponseWorkflowStep.ID, FirstResponseWorkflowStep.ID);
        EntryEventWorkflowStepID := EntryEventWorkflowStep.ID;
    end;

    local procedure DeleteTempWorkflowStepBufferEntry(var TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary; StepID: Integer)
    begin
        TempWorkflowStepBuffer.SetRange("Event Step ID", StepID);
        TempWorkflowStepBuffer.FindFirst();
        TempWorkflowStepBuffer.Delete(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

