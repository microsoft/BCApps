codeunit 134300 "Workflow Engine UT"
{
    Permissions = TableData "Workflow - Record Change" = i;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        CannotEditEnabledWorkflowErr: Label 'Enabled workflows cannot be edited.';
        DisableReferringWorkflowsErr: Label 'You cannot edit the %1 workflow because it is used as a sub-workflow in other workflows. You must first disable the workflows that use the %1 workflow.', Comment = '%1 = Workflow code';
        EventOnlyEntryPointsErr: Label 'Events can only be specified as entry points.';
        LibraryRandom: Codeunit "Library - Random";
        OrphanWorkflowStepsErr: Label 'There can be only one left-aligned workflow step.';
        ParametersHeaderLineTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Create Purchase Invoice Step" id="50000"><Options><Field name="&quot;Purchase Header&quot;.&quot;Due Date&quot;">2014-12-04</Field><Field name="&quot;Purchase Header&quot;.&quot;Currency Code&quot;">DKK</Field><Field name="&quot;Purchase Line&quot;.Description">Hello, World!</Field><Field name="&quot;Purchase Line&quot;.Quantity">100</Field></Options><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.) WHERE(Buy-from Vendor No.=FILTER(10000),Document Date=FILTER(%1),Amount=FILTER(&gt;%2))</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(Item),No.=FILTER(1000),Unit Cost=FILTER(&gt;500))</DataItem></DataItems></ReportParameters>', Locked = true;
        ParametersLineHeaderTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Create Purchase Invoice Step" id="50000"><Options><Field name="&quot;Purchase Header&quot;.&quot;Due Date&quot;">2014-12-04</Field><Field name="&quot;Purchase Header&quot;.&quot;Currency Code&quot;">DKK</Field><Field name="&quot;Purchase Line&quot;.Description">Hello, World!</Field><Field name="&quot;Purchase Line&quot;.Quantity">100</Field></Options><DataItems><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.) WHERE(Type=FILTER(Item),No.=FILTER(1000),Unit Cost=FILTER(&gt;500))</DataItem><DataItem name="Purchase Header">SORTING(Document Type,No.) WHERE(Buy-from Vendor No.=FILTER(10000),Document Date=FILTER(%1),Amount=FILTER(&gt;%2))</DataItem></DataItems></ReportParameters>', Locked = true;
        RecordIsFoundErr: Label '%1 was found.', Comment = '%1=TableCaption';
        RecordNotFoundErr: Label '%1 was not found.', Comment = '%1=TableCaption';
        StepIdsCannotBeTheSameErr: Label '%1 cannot be the same as %2 in %3 %4=''%5'',ID=''%6''.', Comment = 'Example: Previous Workflow Step ID cannot be the same as ID in Workflow Step Workflow Code=''GU00000016'',ID=''10000''.';
        CannotEditTemplateWorkflowsErr: Label 'Workflow templates cannot be edited.';
        SameEventConditionsErr: Label 'One or more entry-point steps exist that use the same event on table %1. You must specify unique event conditions on entry-point steps that use the same table.', Comment = '%1=Table Caption';
        ValidateTableRelationErr: Label 'You must define a table relation between all records used in events.';
        NotSupportedTypeErr: Label 'The type is not supported.';
        NotEnoughSpaceErr: Label 'There is not enough space to save the record.';
        WorkflowMustApplySavedValuesErr: Label 'The workflow does not contain a response to apply the saved values to.';
        WorkflowMustRevertValuesErr: Label 'The workflow does not contain a response to revert and save the changed field values.';
        CannotDeleteWorkflowTemplateErr: Label 'You cannot delete a workflow template.';
        MissingFunctionNamesErr: Label 'All workflow steps must have valid function names.';
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestProcessingResponsesAndEvents()
    var
        Workflow: Record Workflow;
        EventWorkflowStepInstance: Record "Workflow Step Instance";
        ResponseWorkflowStepInstance: Record "Workflow Step Instance";
        SecResponseWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowManagement: Codeunit "Workflow Management";
        Guid: Guid;
    begin
        // [SCENARIO 1] When an event is triggered, all responses for that event are marked as processing.
        // [GIVEN] There is a workflow with multiple responses.
        // [WHEN] The entry point event of the workflow is triggered.
        // [THEN] All the responses of the workflow are marked as processing.

        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);

        Guid := CreateGuid();

        EventWorkflowStepInstance.Init();
        EventWorkflowStepInstance.ID := Guid;
        EventWorkflowStepInstance."Workflow Code" := Workflow.Code;
        EventWorkflowStepInstance."Workflow Step ID" := 1;
        EventWorkflowStepInstance.Status := EventWorkflowStepInstance.Status::Completed;
        EventWorkflowStepInstance.Type := EventWorkflowStepInstance.Type::"Event";
        EventWorkflowStepInstance."Function Name" := WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode();
        EventWorkflowStepInstance.Insert(true);

        ResponseWorkflowStepInstance.Init();
        ResponseWorkflowStepInstance.ID := Guid;
        ResponseWorkflowStepInstance."Workflow Code" := Workflow.Code;
        ResponseWorkflowStepInstance."Workflow Step ID" := 2;
        ResponseWorkflowStepInstance.Status := ResponseWorkflowStepInstance.Status::Inactive;
        ResponseWorkflowStepInstance.Type := ResponseWorkflowStepInstance.Type::Response;
        ResponseWorkflowStepInstance."Function Name" := WorkflowResponseHandling.DoNothingCode();
        ResponseWorkflowStepInstance."Previous Workflow Step ID" := 1;
        ResponseWorkflowStepInstance.Insert(true);

        SecResponseWorkflowStepInstance.Init();
        SecResponseWorkflowStepInstance.ID := Guid;
        SecResponseWorkflowStepInstance."Workflow Code" := Workflow.Code;
        SecResponseWorkflowStepInstance."Workflow Step ID" := 3;
        SecResponseWorkflowStepInstance.Status := ResponseWorkflowStepInstance.Status::Inactive;
        SecResponseWorkflowStepInstance.Type := ResponseWorkflowStepInstance.Type::Response;
        SecResponseWorkflowStepInstance."Function Name" := WorkflowResponseHandling.DoNothingCode();
        SecResponseWorkflowStepInstance."Previous Workflow Step ID" := 2;
        SecResponseWorkflowStepInstance."Next Workflow Step ID" := EventWorkflowStepInstance."Workflow Step ID";
        SecResponseWorkflowStepInstance.Insert(true);

        // Execute
        WorkflowManagement.ChangeStatusForResponsesAndEvents(EventWorkflowStepInstance);

        // Verify
        EventWorkflowStepInstance.Get(Guid, Workflow.Code, 1);
        ResponseWorkflowStepInstance.Get(Guid, Workflow.Code, 2);
        SecResponseWorkflowStepInstance.Get(Guid, Workflow.Code, 3);

        Assert.AreEqual(EventWorkflowStepInstance.Status::Completed, EventWorkflowStepInstance.Status, 'The status of the event is wrong');
        Assert.AreEqual(ResponseWorkflowStepInstance.Status::Processing, ResponseWorkflowStepInstance.Status,
          'The status of the response is wrong');
        Assert.AreEqual(SecResponseWorkflowStepInstance.Status::Processing, SecResponseWorkflowStepInstance.Status,
          'The status of the response is wrong');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultipleEntryPointsDefined()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        CreateIncDocEventID1: Integer;
        DoNothingResponseID: Integer;
        CreateIncDocEventID2: Integer;
    begin
        // [SCENARIO 5] When multiple workflows have the entry point on Incoming Document, the enabled workflow will have only one entry point.
        // [GIVEN] A workflow with multiple entry points.
        // [WHEN] The user enables the workflow.
        // [THEN] The workflow has only one entry point and is enabled.

        // Setup.
        Initialize();

        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateIncDocEventID1 :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        DoNothingResponseID := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(),
            CreateIncDocEventID1);

        CreateIncDocEventID2 := LibraryWorkflow.InsertEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode(), DoNothingResponseID);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), CreateIncDocEventID2);

        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, CreateIncDocEventID2);

        // Exercise.
        Workflow.Validate(Enabled, true);

        // Verify.
        WorkflowStep.Get(Workflow.Code, CreateIncDocEventID1);
        Assert.IsTrue(WorkflowStep."Entry Point", 'This step should be an entry point');
        WorkflowStep.Get(Workflow.Code, CreateIncDocEventID2);
        Assert.IsFalse(WorkflowStep."Entry Point", 'This step should not be an entry point');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowStepInstanceQuery()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowInstance: Query "Workflow Instance";
        CreateIncDocEventID: Integer;
    begin
        // [SCENARIO 7] The Workflow Instance query returns all workflow records.
        // [GIVEN] A workflow definition and its instance.
        // [WHEN] Running the query.
        // [THEN] There are records returned.

        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateIncDocEventID :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), CreateIncDocEventID);

        EnableWorkflow(Workflow.Code);
        WorkflowInstance.SetRange(Entry_Point, true);
        WorkflowInstance.SetRange(Enabled, true);
        WorkflowInstance.Open();

        // Exercise/Verify
        Assert.IsFalse(WorkflowInstance.Read(), StrSubstNo(RecordNotFoundErr, WorkflowStep.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowIsSkipped()
    var
        PurchaseHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        CreateIncDocEventID: Integer;
    begin
        // [SCENARIO 15] When a document other than Incoming Document is created, no workflow is triggered.
        // [GIVEN] A workflow template that starts from Incoming Documents insert.
        // [WHEN] A Purchase Header record is created.
        // [THEN] The workflow is not triggered.

        // Setup
        Initialize();
        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateIncDocEventID :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), CreateIncDocEventID);

        EnableWorkflow(Workflow.Code);

        // Exercise
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        // Validate
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, StrSubstNo(RecordIsFoundErr, WorkflowStepInstance.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNonPaymentLineDoesNotGenerateNotification()
    var
        Workflow: Record Workflow;
        NotificationEntry: Record "Notification Entry";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowEntryPointStep: Integer;
        WorkflowResponseStep: Integer;
    begin
        // [SCENARIO] When a Gen. Journal Line that is not a Payment is created, a Notification record is not created.
        // [GIVEN] Workflow is setup to notify a specific user.
        // [WHEN] A Gen Jnl. Line record is created.
        // [THEN] A Notification record is not created for that user.

        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);

        WorkflowEntryPointStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnAfterInsertGeneralJournalLineCode());
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        LibraryWorkflow.InsertEventArgument(WorkflowEntryPointStep, WorkflowSetup.BuildGeneralJournalLineTypeConditions(GenJournalLine));
        WorkflowResponseStep := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            WorkflowEntryPointStep);

        LibraryWorkflow.InsertNotificationArgument(WorkflowResponseStep, UserId, 0, '');

        EnableWorkflow(Workflow.Code);

        // Exercise
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(100, 2));

        // Verify
        asserterror FindNotificationEntry(NotificationEntry, UserId, GenJournalLine.RecordId);
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowEditWhileEnabled()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        CreateIncDocEventID: Integer;
    begin
        // [SCENARIO] Editing an Enabled Workflow Results an Error Message
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] Enabled is marked
        // [WHEN] User sets another step as an entry point
        // [THEN] Error message is displayed

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateIncDocEventID :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), CreateIncDocEventID);

        EnableWorkflow(Workflow.Code);

        // Exercise
        WorkflowStep.Get(Workflow.Code, CreateIncDocEventID);
        WorkflowStep.Validate("Entry Point", false);
        asserterror WorkflowStep.Modify(true);

        // Verify
        Assert.ExpectedError(CannotEditEnabledWorkflowErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRename()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        CreateIncDocEventID: Integer;
    begin
        // [SCENARIO] Changing the code of an workflow works.
        // [GIVEN] Workflow with multiple Workflow Steps
        // [WHEN] User changes the workflow code
        // [THEN] The workflow code is changed

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateIncDocEventID :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), CreateIncDocEventID);

        // Exercise
        Workflow.Rename('TEST');

        // Verify
        Clear(Workflow);
        Workflow.Get('TEST');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowTemplateDelete()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        CreateIncDocEventID: Integer;
    begin
        // [SCENARIO] A workflow template cannot be deleted.
        // [GIVEN] A workflow template.
        // [WHEN] The user wants to delete the workflow template.
        // [THEN] An error will be shown informing the user that a workflow template cannot be deleted.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateIncDocEventID :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), CreateIncDocEventID);

        Workflow.Validate(Template, true);
        Workflow.Modify(true);

        // Exercise
        asserterror Workflow.Delete(true);

        // Verify
        Assert.ExpectedError(CannotDeleteWorkflowTemplateErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestWorkflowEditWhileUsedSubWorkflowError()
    var
        SubWorkflow: Record Workflow;
        Workflow: Record Workflow;
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowEvent5: Record "Workflow Event";
        EntryPointEvent: Integer;
        FirstResponse: Integer;
        SecondEvent: Integer;
        WorkflowEntryPointEvent: Integer;
        WorkflowFirstResponse: Integer;
    begin
        // [SCENARIO] Editing an Enabled Sub-Workflow Results an Error Message
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] Sub-Workflow with multiple workflow steps
        // [GIVEN] Enabled is marked for workflow and sub-workflow
        // [WHEN] User disables sub-workflow to edit it
        // [THEN] Confirmation message is displayed
        // [THEN] Error message is displayed

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(SubWorkflow);

        CreateAnyEvent(WorkflowEvent1, DATABASE::"Purchase Header");
        CreateAnyEvent(WorkflowEvent2, DATABASE::"Purchase Line");

        EntryPointEvent := LibraryWorkflow.InsertEntryPointEventStep(SubWorkflow, WorkflowEvent1."Function Name");
        FirstResponse := LibraryWorkflow.InsertResponseStep(SubWorkflow, '', EntryPointEvent);
        SecondEvent := LibraryWorkflow.InsertEventStep(SubWorkflow, WorkflowEvent2."Function Name", FirstResponse);
        LibraryWorkflow.InsertResponseStep(SubWorkflow, '', SecondEvent);

        EnableWorkflow(SubWorkflow.Code);

        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateAnyEvent(WorkflowEvent5, DATABASE::"Incoming Document");

        WorkflowEntryPointEvent := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent5."Function Name");
        WorkflowFirstResponse := LibraryWorkflow.InsertResponseStep(Workflow, '', WorkflowEntryPointEvent);
        LibraryWorkflow.InsertSubWorkflowStep(Workflow, SubWorkflow.Code, WorkflowFirstResponse);

        EnableWorkflow(Workflow.Code);

        // Exercise
        asserterror SubWorkflow.Validate(Enabled, false);

        // Verify
        Assert.ExpectedError(StrSubstNo(DisableReferringWorkflowsErr, SubWorkflow.Code));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestWorkflowEditWhileUsedSubWorkflow()
    var
        SubWorkflow: Record Workflow;
        Workflow: Record Workflow;
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowEvent5: Record "Workflow Event";
        EntryPointEvent: Integer;
        FirstResponse: Integer;
        SecondEvent: Integer;
        WorkflowEntryPointEvent: Integer;
        WorkflowFirstResponse: Integer;
    begin
        // [SCENARIO] Editing an Enabled Sub-Workflow Disables Referring Workflows
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] Sub-Workflow with multiple workflow steps
        // [GIVEN] Enabled is marked for workflow and sub-workflow
        // [WHEN] User disables sub-workflow to edit it
        // [THEN] Confirmation message is displayed
        // [THEN] Referring workflow is disabled

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(SubWorkflow);

        CreateAnyEvent(WorkflowEvent1, DATABASE::"Purchase Header");
        CreateAnyEvent(WorkflowEvent2, DATABASE::"Purchase Line");

        EntryPointEvent := LibraryWorkflow.InsertEntryPointEventStep(SubWorkflow, WorkflowEvent1."Function Name");
        FirstResponse := LibraryWorkflow.InsertResponseStep(SubWorkflow, '', EntryPointEvent);
        SecondEvent := LibraryWorkflow.InsertEventStep(SubWorkflow, WorkflowEvent2."Function Name", FirstResponse);
        LibraryWorkflow.InsertResponseStep(SubWorkflow, '', SecondEvent);

        EnableWorkflow(SubWorkflow.Code);

        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateAnyEvent(WorkflowEvent5, DATABASE::"Incoming Document");

        WorkflowEntryPointEvent := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent5."Function Name");
        WorkflowFirstResponse := LibraryWorkflow.InsertResponseStep(Workflow, '', WorkflowEntryPointEvent);
        LibraryWorkflow.InsertSubWorkflowStep(Workflow, SubWorkflow.Code, WorkflowFirstResponse);

        EnableWorkflow(Workflow.Code);

        // Pre-Exercise
        Workflow.Get(Workflow.Code);
        Workflow.TestField(Enabled, true);

        // Exercise
        SubWorkflow.Validate(Enabled, false);
        SubWorkflow.Modify(true);

        // Verify
        Workflow.Get(Workflow.Code);
        Workflow.TestField(Enabled, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowSetsEntryPoint()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowCard: TestPage Workflow;
    begin
        // [SCENARIO] Enabling Workflow without an Entry Point Results an Error Message
        // [GIVEN] Workflow with one Workflow Step
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] Error message is displayed

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(EventWorkflowStep, Workflow, 0);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep, Workflow, EventWorkflowStep.ID);

        // Exercise
        WorkflowCard.OpenEdit();
        WorkflowCard.GotoRecord(Workflow);
        WorkflowCard.Enabled.SetValue(true);

        // Verify
        EventWorkflowStep.Find();
        EventWorkflowStep.TestField("Entry Point", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowClearsEntryPoint()
    var
        Workflow: Record Workflow;
        EventWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep: Record "Workflow Step";
        WorkflowCard: TestPage Workflow;
    begin
        // [SCENARIO] Enabling Workflow without an Entry Point Results an Error Message
        // [GIVEN] Workflow with one Workflow Step
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] Error message is displayed

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEntryEventWorkflowStep(EventWorkflowStep, Workflow);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep, Workflow, EventWorkflowStep.ID);

        Workflow.Enabled := true;
        Workflow.Modify();

        // Exercise
        WorkflowCard.OpenEdit();
        WorkflowCard.GotoRecord(Workflow);
        WorkflowCard.Enabled.SetValue(false);

        // Verify
        EventWorkflowStep.Find();
        EventWorkflowStep.TestField("Entry Point", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowResponseEntryPoint()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowCard: TestPage Workflow;
        EntryPoint: Integer;
    begin
        // [SCENARIO] Enabling Workflow with a Response Entry Point
        // [GIVEN] Workflow with one Response Workflow Step
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] Error message is displayed

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPoint := LibraryWorkflow.InsertEntryPointEventStep(Workflow, '');
        WorkflowStep.Get(Workflow.Code, EntryPoint);
        WorkflowStep.Type := WorkflowStep.Type::Response;
        WorkflowStep.Modify();

        // Exercise
        WorkflowCard.OpenEdit();
        WorkflowCard.GotoRecord(Workflow);
        asserterror WorkflowCard.Enabled.SetValue(true);

        // Verify
        Assert.ExpectedError(EventOnlyEntryPointsErr);
        WorkflowCard.Enabled.AssertEquals(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowSubWorkflowEntryPoint()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowCard: TestPage Workflow;
        EntryPoint: Integer;
    begin
        // [SCENARIO] Enabling Workflow with a Sub-Workflow Entry Point
        // [GIVEN] Workflow with one Response Workflow Step
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] Error message is displayed

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPoint := LibraryWorkflow.InsertEntryPointEventStep(Workflow, '');
        WorkflowStep.Get(Workflow.Code, EntryPoint);
        WorkflowStep.Type := WorkflowStep.Type::"Sub-Workflow";
        WorkflowStep.Modify();

        // Exercise
        WorkflowCard.OpenEdit();
        WorkflowCard.GotoRecord(Workflow);
        asserterror WorkflowCard.Enabled.SetValue(true);

        // Verify
        Assert.ExpectedError(EventOnlyEntryPointsErr);
        WorkflowCard.Enabled.AssertEquals(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowMultipleEntryPoints()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowCard: TestPage Workflow;
        FirstEntryPointEvent: Integer;
        FirstResponse: Integer;
        SecondEntryPointEvent: Integer;
    begin
        // [SCENARIO] Enable Workflow with Multiple Entry Points
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] More than one Workflow Step are marked as entry points
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] Workflow is enabled

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        FirstEntryPointEvent :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        FirstResponse := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), FirstEntryPointEvent);

        SecondEntryPointEvent := LibraryWorkflow.InsertEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(), FirstResponse);
        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, SecondEntryPointEvent);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), SecondEntryPointEvent);

        // Exercise
        WorkflowCard.OpenEdit();
        WorkflowCard.GotoRecord(Workflow);
        WorkflowCard.Enabled.SetValue(true);

        // Verify
        WorkflowCard.Enabled.AssertEquals(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowMultipleEntryPointsMissingCurrentArgument()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowCard: TestPage Workflow;
        FirstEntryPointEvent: Integer;
        FirstResponse: Integer;
        SecondEntryPointEvent: Integer;
    begin
        // [SCENARIO] Enable Workflow with Multiple Entry Points
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] More than one Workflow Step are marked as entry points
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] Workflow is enabled

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        FirstEntryPointEvent :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        FirstResponse := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), FirstEntryPointEvent);

        SecondEntryPointEvent := LibraryWorkflow.InsertEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(), FirstResponse);
        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, SecondEntryPointEvent);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), SecondEntryPointEvent);

        // Exercise
        WorkflowCard.OpenEdit();
        WorkflowCard.GotoRecord(Workflow);
        WorkflowCard.Enabled.SetValue(true);

        // Verify
        WorkflowCard.Enabled.AssertEquals(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowMultipleEntryPointsMultipleRoots()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        FirstEntryPointEvent: Integer;
        SecondEntryPointEvent: Integer;
    begin
        // [SCENARIO] Enable Workflow with Multiple Entry Points
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] More than one Workflow Step are marked as entry points
        // [GIVEN] Entry-point Workflow Steps have Previous Workflow Step ID set to zero
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] An error occurs

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        FirstEntryPointEvent :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), FirstEntryPointEvent);

        SecondEntryPointEvent := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), SecondEntryPointEvent);

        // Exercise
        asserterror Workflow.Validate(Enabled, true);

        // Verify
        Assert.ExpectedError(OrphanWorkflowStepsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowEntryPointsSameTableSameEventMissingConditions()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        ResponseStep1: Integer;
        EntryPointEventStep2: Integer;
    begin
        // [SCENARIO] Enable a Workflow with Multiple Entry Points on Same Table Results in a workflow with only one entry point and without event
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] Same Workflow Event for each entry point, acting on the same table
        // [GIVEN] No event conditions specified on Workflow Events
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] The workflow has only one entry point and is enabled.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateAnyEvent(WorkflowEvent, DATABASE::"Purchase Header");

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent."Function Name");
        ResponseStep1 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEventStep);

        EntryPointEventStep2 := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEvent."Function Name", ResponseStep1);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEventStep2);

        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, EntryPointEventStep2);

        // Exercise
        Workflow.Validate(Enabled, true);

        // Verify
        WorkflowStep.Get(Workflow.Code, EntryPointEventStep);
        Assert.IsTrue(WorkflowStep."Entry Point", 'This step should be an entry point');
        WorkflowStep.Get(Workflow.Code, EntryPointEventStep2);
        Assert.IsFalse(WorkflowStep."Entry Point", 'This step should not be an entry point');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowEntryPointsSameTableDiffEventsMissingConditions()
    var
        Workflow: Record Workflow;
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowPage: TestPage Workflow;
        EntryPointEventStep: Integer;
        ResponseStep1: Integer;
        EntryPointEventStep2: Integer;
    begin
        // [SCENARIO] Enable a Workflow with Multiple Entry Points on Same Table Results an Error Message
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] Workflow Event for each Workflow Step, acting on the same table
        // [GIVEN] No event conditions specified on Workflow Events
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] Error message is displayed

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateAnyEvent(WorkflowEvent1, DATABASE::"Purchase Header");
        CreateAnyEvent(WorkflowEvent2, DATABASE::"Purchase Header");

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent1."Function Name");
        ResponseStep1 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEventStep);

        EntryPointEventStep2 := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEvent2."Function Name", ResponseStep1);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEventStep2);

        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, EntryPointEventStep2);

        // Exercise
        WorkflowPage.OpenEdit();
        WorkflowPage.Enabled.SetValue(true);

        // Verify
        WorkflowPage.Enabled.AssertEquals(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowEntryPointsSameTableSameConditions()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        Filters: Text;
        EntryPointEventStep: Integer;
        ResponseStep1: Integer;
        EntryPointEventStep2: Integer;
    begin
        // [SCENARIO] Enable a Workflow with Multiple Entry Points on Same Table Results in a workflow with only one entry point
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] Workflow Event for each Workflow Step, acting on the same table
        // [GIVEN] Same event conditions specified on Workflow Events
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] The workflow has only one entry point and is enabled.

        Initialize();

        // Pre-Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateAnyEvent(WorkflowEvent, DATABASE::"Purchase Header");

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent."Function Name");
        ResponseStep1 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEventStep);

        EntryPointEventStep2 := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEvent."Function Name", ResponseStep1);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEventStep2);

        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, EntryPointEventStep2);

        // Setup
        Filters := StrSubstNo(ParametersHeaderLineTxt, WorkDate(), LibraryRandom.RandInt(1000));
        LibraryWorkflow.InsertEventArgument(EntryPointEventStep, Filters);
        LibraryWorkflow.InsertEventArgument(EntryPointEventStep2, Filters);

        // Exercise
        Workflow.Validate(Enabled, true);

        // Verify
        WorkflowStep.Get(Workflow.Code, EntryPointEventStep);
        Assert.IsTrue(WorkflowStep."Entry Point", 'This step should be an entry point');
        WorkflowStep.Get(Workflow.Code, EntryPointEventStep2);
        Assert.IsFalse(WorkflowStep."Entry Point", 'This step should not be an entry point');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowEntryPointsSameTableSameConditionsDiferentInOrder()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        Amount: Integer;
        EntryPointEventStep: Integer;
        ResponseStep1: Integer;
        EntryPointEventStep2: Integer;
    begin
        // [SCENARIO] Enable a Workflow with Multiple Entry Points on Same Table results in only one event becoming an entry point
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] Workflow Event for each Workflow Step, acting on the same table
        // [GIVEN] Same event conditions specified on Workflow Events
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] The workflow has only one entry point and is enabled.

        Initialize();

        // Pre-Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateAnyEvent(WorkflowEvent, DATABASE::"Purchase Header");

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent."Function Name");
        ResponseStep1 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEventStep);

        EntryPointEventStep2 := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEvent."Function Name", ResponseStep1);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEventStep2);

        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, EntryPointEventStep2);

        // Setup
        Amount := LibraryRandom.RandInt(1000);
        LibraryWorkflow.InsertEventArgument(EntryPointEventStep, StrSubstNo(ParametersHeaderLineTxt, WorkDate(), Amount));
        LibraryWorkflow.InsertEventArgument(EntryPointEventStep2, StrSubstNo(ParametersLineHeaderTxt, WorkDate(), Amount));

        // Exercise
        Workflow.Validate(Enabled, true);

        // Verify
        WorkflowStep.Get(Workflow.Code, EntryPointEventStep);
        Assert.IsTrue(WorkflowStep."Entry Point", 'This step should be an entry point');
        WorkflowStep.Get(Workflow.Code, EntryPointEventStep2);
        Assert.IsFalse(WorkflowStep."Entry Point", 'This step should not be an entry point');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowEntryPointsSameTableDifferentConditions()
    var
        Workflow: Record Workflow;
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowCard: TestPage Workflow;
        EntryPointEventStep: Integer;
        ResponseStep1: Integer;
        EntryPointEventStep2: Integer;
    begin
        // [SCENARIO] Enable a Workflow with Multiple Entry Points on Same Table
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] Workflow Event for each Workflow Step, acting on the same table
        // [GIVEN] Different event conditions are specified on Workflow Events
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks the Enabled checkbox
        // [THEN] Workflow is enabled.

        Initialize();

        // Pre-Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        CreateAnyEvent(WorkflowEvent1, DATABASE::"Purchase Header");
        CreateAnyEvent(WorkflowEvent2, DATABASE::"Purchase Header");

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent1."Function Name");
        ResponseStep1 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEventStep);

        EntryPointEventStep2 := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEvent2."Function Name", ResponseStep1);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEventStep2);

        LibraryWorkflow.SetEventStepAsEntryPoint(Workflow, EntryPointEventStep2);

        // Setup
        LibraryWorkflow.InsertEventArgument(EntryPointEventStep, StrSubstNo(ParametersHeaderLineTxt, WorkDate() - 1,
            LibraryRandom.RandInt(1000)));
        LibraryWorkflow.InsertEventArgument(EntryPointEventStep2, StrSubstNo(ParametersHeaderLineTxt, WorkDate() + 1,
            LibraryRandom.RandInt(1000)));

        // Exercise
        WorkflowCard.OpenEdit();
        WorkflowCard.GotoRecord(Workflow);
        WorkflowCard.Enabled.SetValue(true);

        // Verify
        WorkflowCard.Enabled.AssertEquals(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowNoneEntryPointMissingPreviousWorkflowStepId()
    var
        Workflow: Record Workflow;
        EntryPointEventStep: Integer;
        EventStep: Integer;
    begin
        // [SCENARIO] Missing Previous Workflow Step ID on Non-Entry-Point Steps Results an Error Message
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] Previous Workflow Step ID and Next Workflow Step ID are set to zero
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks a step as an entry point
        // [THEN] Error message is displayed

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, '');
        LibraryWorkflow.InsertResponseStep(Workflow, '', EntryPointEventStep);

        EventStep := LibraryWorkflow.InsertEventStep(Workflow, '', 0);
        LibraryWorkflow.InsertResponseStep(Workflow, '', EventStep);

        // Exercise
        asserterror Workflow.Validate(Enabled, true);

        // Verify
        Assert.ExpectedError(OrphanWorkflowStepsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowNoneEntryPointDeletedPreviousWorkflowStepId()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        EntryPointEventStep: Integer;
        EventStep: Integer;
    begin
        // [SCENARIO] Non-Existent Previous Workflow Step ID on Non-Entry-Point Steps Results an Error Message
        // [GIVEN] Workflow with multiple Workflow Steps
        // [GIVEN] Previous Workflow Step ID refers to a non-existent step
        // [GIVEN] Next Workflow Step ID are set to zero
        // [GIVEN] Enabled is unmarked
        // [WHEN] User marks a step as an entry point
        // [THEN] Error message is displayed

        Initialize();

        // Pre-Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, '');
        LibraryWorkflow.InsertResponseStep(Workflow, '', EntryPointEventStep);

        EventStep := LibraryWorkflow.InsertEventStep(Workflow, '', 0);
        LibraryWorkflow.InsertResponseStep(Workflow, '', EventStep);

        // Setup
        WorkflowStep.Get(Workflow.Code, EventStep);
        WorkflowStep."Previous Workflow Step ID" := 1000000;
        WorkflowStep.Modify();

        // Exercise
        asserterror Workflow.Validate(Enabled, true);

        // Verify
        Assert.ExpectedError(OrphanWorkflowStepsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowMustApplySavedValues()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStepId: Integer;
    begin
        // [SCENARIO] A workflow that contains a revert value step must contain an apply new values step.
        // [GIVEN] A workflow with an revert values step and without an apply new values step.
        // [WHEN] The user wants to enable the workflow.
        // [THEN] The user will get an error.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.RevertValueForFieldCode(),
          EntryPointEventStepId);

        // Exercise
        asserterror Workflow.Validate(Enabled, true);

        // Verify
        Assert.ExpectedError(WorkflowMustApplySavedValuesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowMustApplySavedValuesNoError()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStepId: Integer;
        ResponseStepId: Integer;
    begin
        // [SCENARIO] A workflow that contains a revert value step must contain an apply new values step.
        // [GIVEN] A workflow with an revert values step and with an apply new values step.
        // [WHEN] The user wants to enable the workflow.
        // [THEN] The workflow will be enabled.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        ResponseStepId := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.RevertValueForFieldCode(),
            EntryPointEventStepId);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ApplyNewValuesCode(), ResponseStepId);

        // Exercise and Verify
        Workflow.Validate(Enabled, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowMustRevertAppliedValues()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStepId: Integer;
    begin
        // [SCENARIO] A workflow that contains an apply new value step must contain a revert values step.
        // [GIVEN] A workflow with an apply new values step and without a revert values.
        // [WHEN] The user wants to enable the workflow.
        // [THEN] The user will get an error.

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ApplyNewValuesCode(),
          EntryPointEventStepId);

        // Exercise
        asserterror Workflow.Validate(Enabled, true);

        // Verify
        Assert.ExpectedError(WorkflowMustRevertValuesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreviousWorkflowStepIdEqualsCurrentStepId()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        EntryPoint: Integer;
    begin
        // [SCENARIO] Previous Workflow Step ID == Current Step ID Results an Error Message
        // [GIVEN] Workflow with one Workflow Step
        // [GIVEN] Enabled is unmarked
        // [WHEN] User sets Previous Workflow Step ID equal to current step ID
        // [THEN] Error message is displayed

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPoint := LibraryWorkflow.InsertEntryPointEventStep(Workflow, '');
        LibraryWorkflow.InsertResponseStep(Workflow, '', EntryPoint);

        WorkflowStep.Get(Workflow.Code, EntryPoint);

        // Exercise
        asserterror WorkflowStep.Validate("Previous Workflow Step ID", EntryPoint);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(StepIdsCannotBeTheSameErr,
            WorkflowStep.FieldCaption("Previous Workflow Step ID"), WorkflowStep.FieldCaption(ID), WorkflowStep.TableCaption(),
            WorkflowStep.FieldCaption("Workflow Code"), WorkflowStep."Workflow Code", WorkflowStep.ID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNextWorkflowStepIdEqualsCurrentStepId()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        EntryPoint: Integer;
    begin
        // [SCENARIO] Next Workflow Step ID == Current Step ID Results an Error Message
        // [GIVEN] Workflow with one Workflow Step
        // [GIVEN] Enabled is unmarked
        // [WHEN] User sets Next Workflow Step ID equal to current step ID
        // [THEN] Error message is displayed

        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPoint := LibraryWorkflow.InsertEntryPointEventStep(Workflow, '');
        LibraryWorkflow.InsertResponseStep(Workflow, '', EntryPoint);

        WorkflowStep.Get(Workflow.Code, EntryPoint);

        // Exercise
        asserterror WorkflowStep.Validate("Next Workflow Step ID", EntryPoint);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(StepIdsCannotBeTheSameErr,
            WorkflowStep.FieldCaption("Next Workflow Step ID"), WorkflowStep.FieldCaption(ID), WorkflowStep.TableCaption(),
            WorkflowStep.FieldCaption("Workflow Code"), WorkflowStep."Workflow Code", WorkflowStep.ID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertNewStepInWorkflow()
    var
        Workflow: Record Workflow;
        NewResponseWorkflowStep: Record "Workflow Step";
        ParentResponseWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep1: Record "Workflow Step";
        ResponseWorkflowStep2: Record "Workflow Step";
        ResponseWorkflowStep3: Record "Workflow Step";
        EventStepID: Integer;
        ResponseStepID1: Integer;
        ResponseStepID2: Integer;
        ResponseStepID3: Integer;
        NewResponseStepID: Integer;
    begin
        // [SCENARIO] New Workflow Step can be inserted into the workflow
        // [GIVEN] Workflow with an event and two chained responses
        // [GIVEN] A Workflow Step that needs to be inserted between the two steps
        // [WHEN] InsertStepAfter is invoked on a workflow step
        // [THEN] The workflow step is inserted between two steps
        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EventStepID := LibraryWorkflow.InsertEventStep(Workflow, '', 0);
        ResponseStepID1 := LibraryWorkflow.InsertResponseStep(Workflow, '', EventStepID);
        ResponseStepID2 := LibraryWorkflow.InsertResponseStep(Workflow, '', ResponseStepID1);
        ResponseStepID3 := LibraryWorkflow.InsertResponseStep(Workflow, '', ResponseStepID1);

        NewResponseStepID := LibraryWorkflow.InsertResponseStep(Workflow, '', 0);

        // Excercise
        NewResponseWorkflowStep.Get(Workflow.Code, NewResponseStepID);
        ParentResponseWorkflowStep.Get(Workflow.Code, ResponseStepID1);
        ParentResponseWorkflowStep.InsertAfterStep(NewResponseWorkflowStep);

        // Verify
        NewResponseWorkflowStep.Find();
        ResponseWorkflowStep1.Get(Workflow.Code, ResponseStepID1);
        ResponseWorkflowStep2.Get(Workflow.Code, ResponseStepID2);
        ResponseWorkflowStep3.Get(Workflow.Code, ResponseStepID3);

        Assert.AreEqual(EventStepID, ResponseWorkflowStep1."Previous Workflow Step ID", 'Previous Step ID is not set correctly.');
        Assert.AreEqual(NewResponseStepID, ResponseWorkflowStep2."Previous Workflow Step ID", 'Previous Step ID is not set correctly.');
        Assert.AreEqual(NewResponseStepID, ResponseWorkflowStep3."Previous Workflow Step ID", 'Previous Step ID is not set correctly.');
        Assert.AreEqual(ResponseStepID1, NewResponseWorkflowStep."Previous Workflow Step ID", 'Previous Step ID is not set correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertAfterFunctionNameInWorkflow()
    var
        WorkflowResponse: Record "Workflow Response";
        Workflow: Record Workflow;
        NewResponseWorkflowStep: Record "Workflow Step";
        ResponseWorkflowStep: Record "Workflow Step";
        EventWorkflowStep: Record "Workflow Step";
    begin
        // [SCENARIO] New Workflow Step can be inserted into the workflow
        // [GIVEN] Workflow with an event and one response
        // [GIVEN] A Workflow Step that needs to be inserted after the occurence of a function name
        // [WHEN] InsertAfterFunctionName is invoked on a function name
        // [THEN] The workflow step is inserted between two steps
        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        CreateAnyEventWorkflowStep(EventWorkflowStep, Workflow, 0);
        CreateAnyResponseWorkflowStep(ResponseWorkflowStep, Workflow, EventWorkflowStep.ID);
        CreateAnyResponse(WorkflowResponse);

        // Excercise
        Workflow.InsertAfterFunctionName(EventWorkflowStep."Function Name", WorkflowResponse."Function Name",
          false, NewResponseWorkflowStep.Type::Response);

        // Verify
        ResponseWorkflowStep.Find();
        NewResponseWorkflowStep.Get(Workflow.Code, ResponseWorkflowStep."Previous Workflow Step ID");
        NewResponseWorkflowStep.TestField("Previous Workflow Step ID", EventWorkflowStep.ID);
        NewResponseWorkflowStep.TestField(Type, NewResponseWorkflowStep.Type::Response);
        NewResponseWorkflowStep.TestField("Function Name", WorkflowResponse."Function Name");
        NewResponseWorkflowStep.TestField("Entry Point", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFindEventWorkflowStepInstance()
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowManagement: Codeunit "Workflow Management";
        Variant: Variant;
        Result: Boolean;
    begin
        Initialize();

        // Setup
        WorkflowStepInstance.Init();
        Variant := WorkflowStepInstance;

        // Exercise
        Result := WorkflowManagement.FindEventWorkflowStepInstance(WorkflowStepInstance, LibraryUtility.GenerateGUID(), Variant, Variant);

        // Verify
        Assert.IsFalse(Result, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFindEventWorkflowStepInstanceWithSpecialChars()
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowManagement: Codeunit "Workflow Management";
        EntryPointStepID: Integer;
        Result: Boolean;
    begin
        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        Workflow.Rename(CopyStr(Workflow.Code, 1, 1) + '()');
        EntryPointStepID :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterReleasePurchaseDocCode());
        LibraryWorkflow.InsertEventArgument(EntryPointStepID,
          WorkflowSetup.BuildPurchHeaderTypeConditionsText(
              PurchaseHeader."Document Type"::Invoice, PurchaseHeader.Status::Open));
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Exercise
        WorkflowStepInstance.Init();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", '', 0);
        Result := WorkflowManagement.FindWorkflowStepInstance(PurchaseHeader, PurchaseHeader, WorkflowStepInstance,
            WorkflowEventHandling.RunWorkflowOnAfterReleasePurchaseDocCode());

        // Verify
        Assert.IsTrue(Result, 'Instance not found.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotRenameTemplate()
    var
        Workflow: Record Workflow;
    begin
        // [SCENARIO] When the code of a workflow template is changed there is an error triggered.
        // [GIVEN] There is a workflow template.
        // [WHEN] When there is a change to the code field of the record.
        // [THEN] There is an error triggered.

        // Setup
        LibraryWorkflow.CreateTemplateWorkflow(Workflow);

        // Exercise
        asserterror Workflow.Validate(Code, 'TEST');

        // Verify
        Assert.IsTrue(StrPos(GetLastErrorText, CannotEditTemplateWorkflowsErr) > 0, 'The template error message is wrong.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotEnableTemplate()
    var
        Workflow: Record Workflow;
    begin
        // [SCENARIO] When a workflow template is enabled there is an error.
        // [GIVEN] There is a workflow template.
        // [WHEN] When the enabled field is set to True.
        // [THEN] There is an error triggered.

        // Setup
        LibraryWorkflow.CreateTemplateWorkflow(Workflow);

        // Exercise
        asserterror Workflow.Validate(Enabled, true);

        // Verify
        Assert.IsTrue(StrPos(GetLastErrorText, CannotEditTemplateWorkflowsErr) > 0, 'The template error message is wrong.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotEditStepFromTemplate()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        StepId: Integer;
    begin
        // [SCENARIO] When a field is changed in a Workflow Step that belongs to  workflow template, an error is triggered.
        // [GIVEN] There is a workflow template with a workflow step.
        // [WHEN] When there is a change to a field of the workflow step.
        // [THEN] There is an error triggered.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        StepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, '');

        WorkflowStep.Get(Workflow.Code, StepId);

        Workflow.Validate(Template, true);
        Workflow.Modify();

        // Exercise
        WorkflowStep.Validate(Description, 'Test');
        asserterror WorkflowStep.Modify(true);

        // Verify
        Assert.IsTrue(StrPos(GetLastErrorText, CannotEditTemplateWorkflowsErr) > 0, 'The template error message is wrong.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotEditStepArgumentFromTemplate()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        StepId: Integer;
    begin
        // [SCENARIO] When a field is changed in a Workflow Step Argument that belongs to  workflow template, an error is triggered.
        // [GIVEN] There is a workflow template with a workflow step argument.
        // [WHEN] When there is a change to a field of the workflow step argument.
        // [THEN] There is an error triggered.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        StepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow, '');

        LibraryWorkflow.InsertEventArgument(StepId, 'Dummy Event cond');

        WorkflowStep.Get(Workflow.Code, StepId);
        WorkflowStepArgument.Get(WorkflowStep.Argument);

        Workflow.Validate(Template, true);
        Workflow.Modify();

        // Exercise
        WorkflowStepArgument.Validate("Link Target Page", 10);
        asserterror WorkflowStepArgument.Modify(true);

        // Verify
        Assert.IsTrue(StrPos(GetLastErrorText, CannotEditTemplateWorkflowsErr) > 0, 'The template error message is wrong.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertEventBeforeEntryPoint()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        EntryPointEventWorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        EntryPointEventStepId: Integer;
    begin
        // [SCENARIO] When adding an event before an entry point, the engine detects the entry point correctly.
        // [GIVEN] An entry point event in a workflow.
        // [WHEN] The user adds an event before the entry point and enables the workflow.
        // [THEN] The engine detects the correct entry point and the workflow is enabled.

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := Workflow.Code;
        WorkflowStep."Function Name" := WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceededCode();
        WorkflowStep."Previous Workflow Step ID" := 0;
        WorkflowStep.Type := WorkflowStep.Type::"Event";
        WorkflowStep.Insert(true);

        // Exercise
        EntryPointEventWorkflowStep.Get(Workflow.Code, EntryPointEventStepId);
        EntryPointEventWorkflowStep."Entry Point" := false;
        EntryPointEventWorkflowStep."Previous Workflow Step ID" := WorkflowStep.ID;
        EntryPointEventWorkflowStep.Modify(true);

        // Verify
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStartWorkflowWithNewlyAddedEvent()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        EntryPointEventWorkflowStep: Record "Workflow Step";
        WorkflowStepInstance: Record "Workflow Step Instance";
        SalesHeader: Record "Sales Header";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        EntryPointEventStepId: Integer;
    begin
        // [SCENARIO] When adding an event before an entry point, enabling the workflow and then triggering the event, a workflow instance should be created.
        // [GIVEN] A new entry point event in a workflow and an enabled workflow.
        // [WHEN] The user triggeres the new added event.
        // [THEN] The engine creates a new workflow instance for that workflow.

        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := Workflow.Code;
        WorkflowStep."Function Name" := WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceededCode();
        WorkflowStep."Previous Workflow Step ID" := 0;
        WorkflowStep.Type := WorkflowStep.Type::"Event";
        WorkflowStep.Insert(true);

        EntryPointEventWorkflowStep.Get(Workflow.Code, EntryPointEventStepId);
        EntryPointEventWorkflowStep."Entry Point" := false;
        EntryPointEventWorkflowStep."Previous Workflow Step ID" := WorkflowStep.ID;
        EntryPointEventWorkflowStep.Modify(true);

        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);

        // Exercise
        WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceeded(SalesHeader);

        // Verify
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsFalse(WorkflowStepInstance.IsEmpty, 'There should be a workflow instance');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOrphanStepError()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO] When creating a workflow with two steps without a previous workflow step, the user will get an error when trying to enable it.
        // [GIVEN] A workflow with two steps without a previous workflow step.
        // [WHEN] The user wants to enable the workflow.
        // [THEN] The user will get an error.

        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        LibraryWorkflow.InsertEntryPointEventStep(Workflow,
          WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode());

        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := Workflow.Code;
        WorkflowStep."Function Name" := WorkflowEventHandling.RunWorkflowOnAfterInsertGeneralJournalLineCode();
        WorkflowStep."Previous Workflow Step ID" := 0;
        WorkflowStep.Type := WorkflowStep.Type::"Event";
        WorkflowStep.Insert(true);

        // Exercise
        asserterror Workflow.Validate(Enabled, true);

        // Verify
        Assert.ExpectedError(OrphanWorkflowStepsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSameEventAsEntryPointError()
    var
        FirstWorkflow: Record Workflow;
        SecondWorkflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        RecRef: RecordRef;
    begin
        // [SCENARIO] When an user wants to enable a workflow that has the entry point matching an already enabled workflow, they will receive an error.
        // [GIVEN] An enabled workflow with an entry point event. A second, disabled, workflow with the same entry point event.
        // [WHEN] The user wants to enabled the second workflow.
        // [THEN] They will receive an error.

        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(FirstWorkflow);
        LibraryWorkflow.InsertEntryPointEventStep(FirstWorkflow,
          WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        LibraryWorkflow.EnableWorkflow(FirstWorkflow);

        LibraryWorkflow.CreateWorkflow(SecondWorkflow);
        LibraryWorkflow.InsertEntryPointEventStep(SecondWorkflow,
          WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        RecRef.Open(DATABASE::"Incoming Document");

        // Exercise
        asserterror LibraryWorkflow.EnableWorkflow(SecondWorkflow);

        // Verify
        Assert.ExpectedError(StrSubstNo(SameEventConditionsErr, RecRef.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNonRelatedTablesThrowError()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        EntryPointEventStepId: Integer;
    begin
        // [SCENARIO] When an user enables an workflow with events that work on different records and do not have relations defined between, they will get an error.
        // [GIVEN] A workflow with two events working with different records.
        // [WHEN] The user wants to enable the workflow.
        // [THEN] The user will receive an error.

        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());

        LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(),
          EntryPointEventStepId);

        // Execute
        asserterror LibraryWorkflow.EnableWorkflow(Workflow);

        // Verify
        Assert.ExpectedError(ValidateTableRelationErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRelatedTablesDoNotThrowError()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        EntryPointEventStepId: Integer;
    begin
        // [SCENARIO] When an user enables an workflow with events that work on different records and do have relations defined between, the workflow will be enabled.
        // [GIVEN] A workflow with two events working with different records and the table relation between the records.
        // [WHEN] The user wants to enable the workflow.
        // [THEN] The workflow will be enabled.

        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());

        LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterReleasePurchaseDocCode(),
          EntryPointEventStepId);

        // Execute
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Verify
        Workflow.Get(Workflow.Code);
        Workflow.TestField(Enabled, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBackupRecords()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        WorkflowRecordManagement: Codeunit "Workflow Record Management";
        SecCust: Variant;
        Index: Integer;
    begin
        // [SCENARIO] Saving a record in the Workflow Record Manager, getting the record brings back the same record.
        // [GIVEN] There is a record that is saved to the Workflow Record Manager.
        // [WHEN] Getting the record.
        // [THEN] We get the same record with the same values.

        // Setup
        Customer.FindFirst();
        Index := WorkflowRecordManagement.BackupRecord(Customer);

        // Exercise
        WorkflowRecordManagement.RestoreRecord(Index, SecCust);
        Customer2 := SecCust;

        // Verify
        Assert.AreEqual(1, Index, 'Error');
        Assert.AreEqual(Customer2."No.", Customer."No.", 'Error');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnlyRecordsCanBeStored()
    var
        Customer: Record Customer;
        WorkflowRecordManagement: Codeunit "Workflow Record Management";
        CompanyInitialize: Codeunit "Company-Initialize";
        DotNet: DotNet Convert;
        FieldRef: FieldRef;
        File: File;
        InStream: InStream;
        OutStream: OutStream;
        RecId: RecordID;
        RecRef: RecordRef;
        TxType: TransactionType;
        Actn: Action;
        BigInteger: BigInteger;
        BigText: BigText;
        Bool: Boolean;
        Byte: Byte;
        Char: Char;
        "Code": Code[10];
        Date: Date;
        DateFormula: DateFormula;
        DateTime: DateTime;
        Decimal: Decimal;
        DefLayout: DefaultLayout;
        Duration: Duration;
        ExecMode: ExecutionMode;
        Guid: Guid;
        Int: Integer;
        ObjType: ObjectType;
        Option: Option;
        TableConnType: TableConnectionType;
        Text: Text;
        TextEnc: TextEncoding;
        Time: Time;
    begin
        // [SCENARIO] The Wrokflow Engine Management can store only records.
        // [GIVEN]
        // [WHEN] The AddVariant method is called.
        // [THEN] It will throw an error if the data passed in is not a record.

        // Setup
        Customer.FindFirst();
        RecRef.Get(Customer.RecordId);

        Actn := ACTION::OK;
        BigInteger := 0;
        Bool := false;
        Byte := 0;
        Char := 0;
        Code := '';
        Date := Today;
        DateTime := CurrentDateTime;
        Decimal := 0;
        DefLayout := DEFAULTLAYOUT::None;
        Duration := 0;
        ExecMode := EXECUTIONMODE::Debug;
        Int := 0;
        ObjType := OBJECTTYPE::Table;
        RecId := Customer.RecordId;
        TableConnType := TABLECONNECTIONTYPE::CRM;
        Text := '';
        TextEnc := TEXTENCODING::Windows;
        Time := Time;
        TxType := TRANSACTIONTYPE::Update;

        // Exercise and Verify
        asserterror WorkflowRecordManagement.BackupRecord(Actn);
        asserterror WorkflowRecordManagement.BackupRecord(BigInteger);
        asserterror WorkflowRecordManagement.BackupRecord(BigText);
        asserterror WorkflowRecordManagement.BackupRecord(Bool);
        asserterror WorkflowRecordManagement.BackupRecord(Byte);
        asserterror WorkflowRecordManagement.BackupRecord(Char);
        asserterror WorkflowRecordManagement.BackupRecord(Code);
        asserterror WorkflowRecordManagement.BackupRecord(CompanyInitialize);
        asserterror WorkflowRecordManagement.BackupRecord(Date);
        asserterror WorkflowRecordManagement.BackupRecord(DateFormula);
        asserterror WorkflowRecordManagement.BackupRecord(DateTime);
        asserterror WorkflowRecordManagement.BackupRecord(Decimal);
        asserterror WorkflowRecordManagement.BackupRecord(DefLayout);
        asserterror WorkflowRecordManagement.BackupRecord(DotNet);
        asserterror WorkflowRecordManagement.BackupRecord(Duration);
        asserterror WorkflowRecordManagement.BackupRecord(ExecMode);
        asserterror WorkflowRecordManagement.BackupRecord(FieldRef);
        asserterror WorkflowRecordManagement.BackupRecord(File);
        asserterror WorkflowRecordManagement.BackupRecord(Guid);
        asserterror WorkflowRecordManagement.BackupRecord(InStream);
        asserterror WorkflowRecordManagement.BackupRecord(Int);
        asserterror WorkflowRecordManagement.BackupRecord(ObjType);
        asserterror WorkflowRecordManagement.BackupRecord(Option);
        asserterror WorkflowRecordManagement.BackupRecord(OutStream);
        asserterror WorkflowRecordManagement.BackupRecord(RecId);
        asserterror WorkflowRecordManagement.BackupRecord(RecRef);
        asserterror WorkflowRecordManagement.BackupRecord(TableConnType);
        asserterror WorkflowRecordManagement.BackupRecord(Text);
        asserterror WorkflowRecordManagement.BackupRecord(TextEnc);
        asserterror WorkflowRecordManagement.BackupRecord(Time);
        asserterror WorkflowRecordManagement.BackupRecord(TxType);
        Assert.ExpectedError(NotSupportedTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMaxNumberOfRecords()
    var
        Customer: Record Customer;
        WorkflowRecordManagement: Codeunit "Workflow Record Management";
        Variant: Variant;
        Index: Integer;
    begin
        // [SCENARIO] The workflow record manager can store only 100 records.
        // [GIVEN] A record and 100 records stored in the workflow record manager.
        // [WHEN] Another record is added.
        // [THEN] The Workflow record manager throws an error.

        // Setup
        Customer.Init();
        for Index := 1 to 100 do
            WorkflowRecordManagement.BackupRecord(Customer);

        // Exercise
        asserterror WorkflowRecordManagement.BackupRecord(Customer);

        // Verify
        Assert.ExpectedError(NotEnoughSpaceErr);

        // Tear-down
        for Index := 1 to 100 do
            WorkflowRecordManagement.RestoreRecord(Index, Variant);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForDecimal()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: Decimal;
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        Initialize();
        OldValue := LibraryRandom.RandDecInRange(1000000, 2000000, 2);

        DataTypeBuffer.Init();
        DataTypeBuffer.Decimal := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(Decimal);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(OldValue), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForInteger()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: Integer;
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        Initialize();
        OldValue := LibraryRandom.RandIntInRange(1000000, 2000000);

        DataTypeBuffer.Init();
        DataTypeBuffer.ID := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(ID);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(OldValue), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForOption()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: Option;
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        Initialize();
        OldValue := DataTypeBuffer.Option::option1;

        DataTypeBuffer.Init();
        DataTypeBuffer.Option := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(Option);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(DataTypeBuffer.Option), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForDate()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: Date;
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        Initialize();
        OldValue := Today;

        DataTypeBuffer.Init();
        DataTypeBuffer.Date := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(Date);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(OldValue), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForDateTime()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: DateTime;
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        Initialize();
        OldValue := CurrentDateTime;

        DataTypeBuffer.Init();
        DataTypeBuffer.DateTime := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(DateTime);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(OldValue), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForTime()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: Time;
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        Initialize();
        OldValue := Time;

        DataTypeBuffer.Init();
        DataTypeBuffer.Time := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(Time);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(OldValue), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForBoolean()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: Boolean;
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        Initialize();
        OldValue := true;

        DataTypeBuffer.Init();
        DataTypeBuffer.Boolean := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(Boolean);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(OldValue), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForDateFormula()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: DateFormula;
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        Initialize();
        Evaluate(OldValue, '<+2D>');

        DataTypeBuffer.Init();
        DataTypeBuffer.DateFormula := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(DateFormula);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(OldValue), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForDuration()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: Duration;
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        Initialize();
        OldValue := LibraryRandom.RandIntInRange(1000000, 2000000);

        DataTypeBuffer.Init();
        DataTypeBuffer.Duration := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(Duration);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(OldValue), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForBigInt()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: BigInteger;
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        Initialize();
        OldValue := LibraryRandom.RandIntInRange(1000000000, 2000000000);

        DataTypeBuffer.Init();
        DataTypeBuffer.BigInteger := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(BigInteger);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(OldValue), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForCode()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: Code[10];
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        Initialize();
        OldValue := 'TESTCODE';

        DataTypeBuffer.Init();
        DataTypeBuffer.Code := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(Code);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(OldValue), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowRecordChangeFormattingForText()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        WorkflowRecordChange: Record "Workflow - Record Change";
        RecRef: RecordRef;
        OldValue: Text[30];
        OldValueText: Text;
    begin
        // [SCENARIO] The formatting performed by the Workflow Record Change is correct for Old Value and New Value;
        // [GIVEN] A Workflow Record Change record with an old value and a new value.
        // [THEN] The value is correctly applied.

        // Setup
        OldValue := 'TestText';

        DataTypeBuffer.Init();
        DataTypeBuffer.Text := OldValue;
        DataTypeBuffer.Insert();

        RecRef.GetTable(DataTypeBuffer);

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Table No." := DATABASE::"Data Type Buffer";
        WorkflowRecordChange."Field No." := DataTypeBuffer.FieldNo(Text);
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."Record ID" := RecRef.RecordId;
        WorkflowRecordChange.Insert();

        OldValueText := WorkflowRecordChange.GetFormattedOldValue(true);

        // Verify
        Assert.AreEqual(Format(OldValue), OldValueText, 'The value was not formatted correctly');
        DataTypeBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMissingEventFunctionNameError()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        EntryPointEventStepId: Integer;
    begin
        // [UNITTEST] When creating a workflow, all the steps must have a function name.
        // [GIVE] A workflow with an event step without a function name.
        // [WHEN] The user wants to enable the workflow.
        // [THEN] The user will get an error.

        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode());

        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := Workflow.Code;
        WorkflowStep."Function Name" := '';
        WorkflowStep."Previous Workflow Step ID" := EntryPointEventStepId;
        WorkflowStep.Type := WorkflowStep.Type::"Event";
        WorkflowStep.Insert();

        // Exercise
        asserterror Workflow.Validate(Enabled, true);

        // Verify
        Assert.ExpectedError(MissingFunctionNamesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMissingResponseFunctionNameError()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        EntryPointEventStepId: Integer;
    begin
        // [UNITTEST] When creating a workflow, all the steps must have a function name.
        // [GIVE] A workflow with a response step without a function name.
        // [WHEN] The user wants to enable the workflow.
        // [THEN] The user will get an error.

        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode());

        WorkflowStep.Init();
        WorkflowStep."Workflow Code" := Workflow.Code;
        WorkflowStep."Function Name" := '';
        WorkflowStep."Previous Workflow Step ID" := EntryPointEventStepId;
        WorkflowStep.Type := WorkflowStep.Type::Response;
        WorkflowStep.Insert();

        // Exercise
        asserterror Workflow.Validate(Enabled, true);

        // Verify
        Assert.ExpectedError(MissingFunctionNamesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEntryPointIsSubWorkflowError()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        EntryPointEventStepId: Integer;
    begin
        // [UNITTEST] When creating a workflow, the entry point cannot be a subworkflow.
        // [GIVE] A workflow with a an entry point of type subworkflow.
        // [WHEN] The user wants to enable the workflow.
        // [THEN] The user will get an error.

        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStepId := LibraryWorkflow.InsertEntryPointEventStep(Workflow,
            WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode());

        WorkflowStep.Get(Workflow.Code, EntryPointEventStepId);
        WorkflowStep.Type := WorkflowStep.Type::"Sub-Workflow";
        WorkflowStep.Modify();

        // Exercise
        asserterror Workflow.Validate(Enabled, true);

        // Verify
        Assert.ExpectedError(EventOnlyEntryPointsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverrideTemplateToken()
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO 204071] Stan can override workflow template token
        Assert.AreEqual('MS-', WorkflowSetup.GetWorkflowTemplateToken(), '');
        WorkflowSetup.SetCustomTemplateToken('AF-');
        Assert.AreEqual('AF-', WorkflowSetup.GetWorkflowTemplateToken(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomLinkWorkflowStepArgumentCorrectUri()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        // [SCENARIO 220210] User can validate correct value to "Custom Link" of "Workflow Step Argument"
        Initialize();

        // [GIVEN] Record of "Workflow Step Argument"

        // [WHEN] Validate correct URI - 'http://bing.com'
        WorkflowStepArgument.Validate("Custom Link", 'http://bing.com');

        // [THEN] "Workflow Step Argument"."Custom Link" = 'http://bing.com'
        WorkflowStepArgument.TestField("Custom Link", 'http://bing.com');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomLinkWorkflowStepArgumentIncorrectUri()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        // [SCENARIO 220210] User can not validate incorrect value to "Custom Link" of "Workflow Step Argument"
        Initialize();

        // [GIVEN] Record of "Workflow Step Argument"

        // [WHEN] Validate incorrect URI - '*$()@'
        asserterror WorkflowStepArgument.Validate("Custom Link", '*$()@');

        // [THEN] Error message 'The URI is not valid.' appears
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('The URI is not valid.');
        WorkflowStepArgument.TestField("Custom Link", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomLinkWorkflowStepArgumentEmptyUri()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        // [SCENARIO 220210] User can validate empty value to "Custom Link" of "Workflow Step Argument"
        Initialize();

        // [GIVEN] Record of "Workflow Step Argument" with "Custom Link" = 'http://bing.com'
        WorkflowStepArgument."Custom Link" := 'http://bing.com';

        // [WHEN] Validate empty string to "Custom Link"
        WorkflowStepArgument.Validate("Custom Link", '');

        // [THEN] "Workflow Step Argument"."Custom Link" = ''
        WorkflowStepArgument.TestField("Custom Link", '');
    end;

    local procedure Initialize()
    var
        ApprovalEntry: Record "Approval Entry";
        NotificationEntry: Record "Notification Entry";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Workflow Engine UT");
        LibraryWorkflow.DeleteAllExistingWorkflows();

        JobQueueEntry.DeleteAll();

        ApprovalEntry.DeleteAll();
        NotificationEntry.DeleteAll();

        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Workflow Engine UT");
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Workflow Engine UT");
    end;

    local procedure CreateAnyEvent(var WorkflowEvent: Record "Workflow Event"; TableID: Integer)
    begin
        WorkflowEvent.Init();
        WorkflowEvent."Function Name" := LibraryUtility.GenerateGUID();
        WorkflowEvent.Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(WorkflowEvent.Description)), 1,
            MaxStrLen(WorkflowEvent.Description));
        WorkflowEvent."Table ID" := TableID;
        WorkflowEvent.Insert(true);
    end;

    local procedure CreateAnyResponse(var WorkflowResponse: Record "Workflow Response")
    begin
        WorkflowResponse.Init();
        WorkflowResponse."Function Name" := LibraryUtility.GenerateGUID();
        WorkflowResponse.Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(WorkflowResponse.Description)), 1,
            MaxStrLen(WorkflowResponse.Description));
        WorkflowResponse.Insert(true);
    end;

    local procedure CreateAnyEventWorkflowStep(var WorkflowStep: Record "Workflow Step"; Workflow: Record Workflow; PreviousStepID: Integer)
    var
        WorkflowEvent: Record "Workflow Event";
        EventID: Integer;
    begin
        CreateAnyEvent(WorkflowEvent, DATABASE::"Purchase Header");
        EventID := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEvent."Function Name", PreviousStepID);

        WorkflowStep.Get(Workflow.Code, EventID);
    end;

    local procedure CreateAnyResponseWorkflowStep(var WorkflowStep: Record "Workflow Step"; Workflow: Record Workflow; PreviousStepID: Integer)
    var
        WorkflowResponse: Record "Workflow Response";
        ResponseID: Integer;
    begin
        CreateAnyResponse(WorkflowResponse);
        ResponseID := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponse."Function Name", PreviousStepID);

        WorkflowStep.Get(Workflow.Code, ResponseID);
    end;

    local procedure CreateAnyEntryEventWorkflowStep(var WorkflowStep: Record "Workflow Step"; Workflow: Record Workflow)
    begin
        CreateAnyEventWorkflowStep(WorkflowStep, Workflow, 0);
        WorkflowStep.Validate("Entry Point", true);
        WorkflowStep.Modify(true);
    end;

    local procedure FindNotificationEntry(var NotificationEntry: Record "Notification Entry"; UserID: Code[50]; RecordID: RecordID)
    begin
        NotificationEntry.SetRange("Recipient User ID", UserID);
        NotificationEntry.SetRange("Triggered By Record", RecordID);
        NotificationEntry.FindFirst();
    end;

    local procedure EnableWorkflow(WorkflowCode: Code[20])
    var
        Workflow: Record Workflow;
    begin
        Workflow.Get(WorkflowCode);
        Workflow.Enabled := true;
        Workflow.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

