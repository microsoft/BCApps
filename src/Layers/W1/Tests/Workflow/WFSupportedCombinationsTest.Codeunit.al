codeunit 134207 "WF Supported Combinations Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Event/Response Combination]
    end;

    var
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure ShowEventEventCombination()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowEvent3: Record "Workflow Event";
        WorkflowEventHierarchies: TestPage "Workflow Event Hierarchies";
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        CreateAnyEvent(WorkflowEvent3);

        LibraryWorkflow.CreateEventPredecessor(WorkflowEvent2."Function Name", WorkflowEvent1."Function Name");
        LibraryWorkflow.CreateEventPredecessor(WorkflowEvent3."Function Name", WorkflowEvent2."Function Name");

        // Exercise
        WorkflowEventHierarchies.Trap();
        PAGE.Run(PAGE::"Workflow Event Hierarchies");

        // Verify
        WorkflowEventHierarchies.MatrixEventSubpage.First();
        VerifyEventMatrixRow(WorkflowEventHierarchies, WorkflowEvent1.Description, true, true, false);

        WorkflowEventHierarchies.MatrixEventSubpage.Next();
        VerifyEventMatrixRow(WorkflowEventHierarchies, WorkflowEvent2.Description, true, false, true);

        WorkflowEventHierarchies.MatrixEventSubpage.Next();
        VerifyEventMatrixRow(WorkflowEventHierarchies, WorkflowEvent3.Description, true, false, false);

        Assert.IsFalse(WorkflowEventHierarchies.MatrixEventSubpage.Next(), 'There should only be 3 events.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddEventEventCombination()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowEvent3: Record "Workflow Event";
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowEventHierarchies: TestPage "Workflow Event Hierarchies";
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        CreateAnyEvent(WorkflowEvent3);
        LibraryWorkflow.CreateEventPredecessor(WorkflowEvent2."Function Name", WorkflowEvent1."Function Name");
        LibraryWorkflow.CreateEventPredecessor(WorkflowEvent3."Function Name", WorkflowEvent2."Function Name");

        WorkflowEventHierarchies.Trap();
        PAGE.Run(PAGE::"Workflow Event Hierarchies");
        WorkflowEventHierarchies.MatrixEventSubpage.First();
        VerifyEventMatrixRow(WorkflowEventHierarchies, WorkflowEvent1.Description, true, true, false);

        // Exercise.
        WorkflowEventHierarchies.MatrixEventSubpage.Cell3.SetValue(true);

        // Verify
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::"Event", WorkflowEvent3."Function Name",
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent1."Function Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteEventEventCombination()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowEventHierarchies: TestPage "Workflow Event Hierarchies";
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        LibraryWorkflow.CreateEventPredecessor(WorkflowEvent2."Function Name", WorkflowEvent1."Function Name");

        WorkflowEventHierarchies.Trap();
        PAGE.Run(PAGE::"Workflow Event Hierarchies");
        WorkflowEventHierarchies.MatrixEventSubpage.First();
        VerifyEventMatrixRow(WorkflowEventHierarchies, WorkflowEvent1.Description, true, true, false);

        // Exercise.
        WorkflowEventHierarchies.MatrixEventSubpage.Cell2.SetValue(false);

        // Verify
        asserterror WFEventResponseCombination.Get(WFEventResponseCombination.Type::"Event", WorkflowEvent2."Function Name",
            WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent1."Function Name");
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateEventSet()
    var
        WorkflowEvent: array[24] of Record "Workflow Event";
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowEventHierarchies: TestPage "Workflow Event Hierarchies";
        i: Integer;
    begin
        Initialize();

        // Setup
        for i := 1 to 24 do begin
            CreateAnyEvent(WorkflowEvent[i]);
            LibraryWorkflow.CreateEventPredecessor(WorkflowEvent[i]."Function Name", WorkflowEvent[1]."Function Name");
        end;

        WorkflowEventHierarchies.Trap();
        PAGE.Run(PAGE::"Workflow Event Hierarchies");

        // Exercise
        WorkflowEventHierarchies.NextSet.Invoke();
        WorkflowEventHierarchies.MatrixEventSubpage.First();
        WorkflowEventHierarchies.MatrixEventSubpage.Next();
        UpdateAllEventCells(WorkflowEventHierarchies);

        // Verify
        Assert.AreEqual(WorkflowEvent[13].Description, WorkflowEventHierarchies.MatrixEventSubpage.Cell1.Caption, 'Wrong caption');
        Assert.AreEqual(WorkflowEvent[24].Description, WorkflowEventHierarchies.MatrixEventSubpage.Cell12.Caption, 'Wrong caption');
        for i := 13 to 24 do
            WFEventResponseCombination.Get(WFEventResponseCombination.Type::"Event", WorkflowEvent[i]."Function Name",
              WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent[2]."Function Name");

        // Exercise
        WorkflowEventHierarchies.PreviousSet.Invoke();
        WorkflowEventHierarchies.MatrixEventSubpage.First();

        // Verify
        Assert.AreEqual(WorkflowEvent[1].Description, WorkflowEventHierarchies.MatrixEventSubpage.Cell1.Caption, 'Wrong caption');
        Assert.AreEqual(WorkflowEvent[12].Description, WorkflowEventHierarchies.MatrixEventSubpage.Cell12.Caption, 'Wrong caption');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeIndependentEventIntoDependent()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowEvent3: Record "Workflow Event";
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowEventHierarchies: TestPage "Workflow Event Hierarchies";
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        CreateAnyEvent(WorkflowEvent3);

        WorkflowEventHierarchies.Trap();
        PAGE.Run(PAGE::"Workflow Event Hierarchies");

        // Exercise
        WorkflowEventHierarchies.MatrixEventSubpage.First();
        WorkflowEventHierarchies.MatrixEventSubpage.Cell3.SetValue(false);

        // Verify
        WorkflowEventHierarchies.MatrixEventSubpage.First();
        VerifyEventMatrixRow(WorkflowEventHierarchies, WorkflowEvent1.Description, true, true, false);

        WorkflowEventHierarchies.MatrixEventSubpage.Next();
        VerifyEventMatrixRow(WorkflowEventHierarchies, WorkflowEvent2.Description, true, true, true);

        WorkflowEventHierarchies.MatrixEventSubpage.Next();
        VerifyEventMatrixRow(WorkflowEventHierarchies, WorkflowEvent3.Description, true, true, true);

        Assert.IsFalse(WorkflowEventHierarchies.MatrixEventSubpage.Next(), 'There should only be 3 events.');

        WFEventResponseCombination.Get(WFEventResponseCombination.Type::"Event", WorkflowEvent3."Function Name",
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent2."Function Name");
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::"Event", WorkflowEvent3."Function Name",
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent3."Function Name");
        asserterror WFEventResponseCombination.Get(WFEventResponseCombination.Type::"Event", WorkflowEvent3."Function Name",
            WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent1."Function Name");
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeDependentEventIntoIndependent()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowEventHierarchies: TestPage "Workflow Event Hierarchies";
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        LibraryWorkflow.CreateEventPredecessor(WorkflowEvent2."Function Name", WorkflowEvent1."Function Name");

        WorkflowEventHierarchies.Trap();
        PAGE.Run(PAGE::"Workflow Event Hierarchies");

        // Exercise
        WorkflowEventHierarchies.MatrixEventSubpage.Last();
        WorkflowEventHierarchies.MatrixEventSubpage.Cell2.SetValue(true);

        // Verify
        WorkflowEventHierarchies.MatrixEventSubpage.First();
        VerifyEventMatrixRow(WorkflowEventHierarchies, WorkflowEvent1.Description, true, true, false);

        WorkflowEventHierarchies.MatrixEventSubpage.Next();
        VerifyEventMatrixRow(WorkflowEventHierarchies, WorkflowEvent2.Description, true, true, false);

        Assert.IsFalse(WorkflowEventHierarchies.MatrixEventSubpage.Next(), 'There should only be 2 events.');

        Assert.IsFalse(WorkflowEvent2.HasPredecessors(), 'Event 2 should be independent.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowEventResponseCombination()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowResponse1: Record "Workflow Response";
        WorkflowResponse2: Record "Workflow Response";
        WFEventResponseCombinations: TestPage "WF Event/Response Combinations";
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        CreateAnyResponse(WorkflowResponse1);
        CreateAnyResponse(WorkflowResponse2);

        LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse2."Function Name", WorkflowEvent1."Function Name");
        LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse1."Function Name", WorkflowEvent2."Function Name");

        // Exercise
        WFEventResponseCombinations.Trap();
        PAGE.Run(PAGE::"WF Event/Response Combinations");

        // Verify
        WFEventResponseCombinations.MatrixResponseSubpage.First();
        VerifyResponseMatrixRow(WFEventResponseCombinations, WorkflowEvent1.Description, false, true);

        WFEventResponseCombinations.MatrixResponseSubpage.Next();
        VerifyResponseMatrixRow(WFEventResponseCombinations, WorkflowEvent2.Description, true, false);

        Assert.IsFalse(WFEventResponseCombinations.MatrixResponseSubpage.Next(), 'There should only be 2 events.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddEventResponseCombination()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowEvent3: Record "Workflow Event";
        WorkflowResponse1: Record "Workflow Response";
        WorkflowResponse2: Record "Workflow Response";
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WFEventResponseCombinations: TestPage "WF Event/Response Combinations";
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        CreateAnyEvent(WorkflowEvent3);
        CreateAnyResponse(WorkflowResponse1);
        CreateAnyResponse(WorkflowResponse2);
        LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse2."Function Name", WorkflowEvent1."Function Name");

        WFEventResponseCombinations.Trap();
        PAGE.Run(PAGE::"WF Event/Response Combinations");
        WFEventResponseCombinations.MatrixResponseSubpage.First();
        VerifyResponseMatrixRow(WFEventResponseCombinations, WorkflowEvent1.Description, true, true);

        // Exercise.
        WFEventResponseCombinations.MatrixResponseSubpage.Next();
        WFEventResponseCombinations.MatrixResponseSubpage.Cell2.SetValue(true);

        // Verify
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponse2."Function Name",
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent2."Function Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteEventResponseCombination()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowResponse1: Record "Workflow Response";
        WorkflowResponse2: Record "Workflow Response";
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WFEventResponseCombinations: TestPage "WF Event/Response Combinations";
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        CreateAnyResponse(WorkflowResponse1);
        CreateAnyResponse(WorkflowResponse2);
        LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse2."Function Name", WorkflowEvent1."Function Name");

        WFEventResponseCombinations.Trap();
        PAGE.Run(PAGE::"WF Event/Response Combinations");
        WFEventResponseCombinations.MatrixResponseSubpage.First();
        VerifyResponseMatrixRow(WFEventResponseCombinations, WorkflowEvent1.Description, true, true);

        // Exercise.
        WFEventResponseCombinations.MatrixResponseSubpage.Cell2.SetValue(false);

        // Verify
        asserterror WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponse2."Function Name",
            WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent1."Function Name");
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigateResponseSet()
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowEvent3: Record "Workflow Event";
        WorkflowResponse: array[24] of Record "Workflow Response";
        WFEventResponseCombinations: TestPage "WF Event/Response Combinations";
        i: Integer;
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        CreateAnyEvent(WorkflowEvent3);
        for i := 1 to 24 do begin
            CreateAnyResponse(WorkflowResponse[i]);
            LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse[i]."Function Name", WorkflowEvent2."Function Name");
        end;

        WFEventResponseCombinations.Trap();
        PAGE.Run(PAGE::"WF Event/Response Combinations");

        // Exercise
        WFEventResponseCombinations.NextSet.Invoke();
        WFEventResponseCombinations.MatrixResponseSubpage.First();
        UpdateAllResponseCells(WFEventResponseCombinations);

        // Verify
        Assert.AreEqual(
          WorkflowResponse[13].Description, WFEventResponseCombinations.MatrixResponseSubpage.Cell1.Caption, 'Wrong caption');
        Assert.AreEqual(
          WorkflowResponse[24].Description, WFEventResponseCombinations.MatrixResponseSubpage.Cell12.Caption, 'Wrong caption');
        for i := 13 to 24 do
            WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponse[i]."Function Name",
              WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent1."Function Name");

        // Exercise
        WFEventResponseCombinations.PreviousSet.Invoke();
        WFEventResponseCombinations.MatrixResponseSubpage.First();

        // Verify
        Assert.AreEqual(WorkflowResponse[1].Description, WFEventResponseCombinations.MatrixResponseSubpage.Cell1.Caption, 'Wrong caption');
        Assert.AreEqual(
          WorkflowResponse[12].Description, WFEventResponseCombinations.MatrixResponseSubpage.Cell12.Caption, 'Wrong caption');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeIndependentResponseIntoDependent()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowResponse1: Record "Workflow Response";
        WorkflowResponse2: Record "Workflow Response";
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WFEventResponseCombinations: TestPage "WF Event/Response Combinations";
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        CreateAnyResponse(WorkflowResponse1);
        CreateAnyResponse(WorkflowResponse2);

        WFEventResponseCombinations.Trap();
        PAGE.Run(PAGE::"WF Event/Response Combinations");

        // Exercise
        WFEventResponseCombinations.MatrixResponseSubpage.First();
        WFEventResponseCombinations.MatrixResponseSubpage.Cell2.SetValue(false);

        // Verify
        WFEventResponseCombinations.MatrixResponseSubpage.First();
        VerifyResponseMatrixRow(WFEventResponseCombinations, WorkflowEvent1.Description, true, false);

        WFEventResponseCombinations.MatrixResponseSubpage.Next();
        VerifyResponseMatrixRow(WFEventResponseCombinations, WorkflowEvent2.Description, true, true);

        Assert.IsFalse(WFEventResponseCombinations.MatrixResponseSubpage.Next(), 'There should only be 2 events.');

        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponse2."Function Name",
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent2."Function Name");
        asserterror WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponse2."Function Name",
            WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent1."Function Name");
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeDependentResponseIntoIndependent()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowResponse1: Record "Workflow Response";
        WorkflowResponse2: Record "Workflow Response";
        WFEventResponseCombinations: TestPage "WF Event/Response Combinations";
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        CreateAnyResponse(WorkflowResponse1);
        CreateAnyResponse(WorkflowResponse2);
        LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse2."Function Name", WorkflowEvent1."Function Name");

        WFEventResponseCombinations.Trap();
        PAGE.Run(PAGE::"WF Event/Response Combinations");

        // Exercise
        WFEventResponseCombinations.MatrixResponseSubpage.Last();
        WFEventResponseCombinations.MatrixResponseSubpage.Cell2.SetValue(true);

        // Verify
        WFEventResponseCombinations.MatrixResponseSubpage.First();
        VerifyResponseMatrixRow(WFEventResponseCombinations, WorkflowEvent1.Description, true, true);

        WFEventResponseCombinations.MatrixResponseSubpage.Next();
        VerifyResponseMatrixRow(WFEventResponseCombinations, WorkflowEvent2.Description, true, true);

        Assert.IsFalse(WFEventResponseCombinations.MatrixResponseSubpage.Next(), 'There should only be 2 events.');

        Assert.IsFalse(WorkflowResponse2.HasPredecessors(), 'Response 2 should not have predecessors.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearEventResponseCombinations()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowResponse1: Record "Workflow Response";
        WorkflowResponse2: Record "Workflow Response";
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        Initialize();

        // Setup
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        CreateAnyResponse(WorkflowResponse1);
        CreateAnyResponse(WorkflowResponse2);

        LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse2."Function Name", WorkflowEvent1."Function Name");
        LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse1."Function Name", WorkflowEvent2."Function Name");
        LibraryWorkflow.CreateEventPredecessor(WorkflowEvent2."Function Name", WorkflowEvent1."Function Name");

        // Exercise
        WorkflowEvent1.Delete(true);

        // Verify
        Commit();
        asserterror WFEventResponseCombination.Get(WFEventResponseCombination.Type::"Event", WorkflowEvent2."Function Name",
            WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent1."Function Name");
        Assert.AssertRecordNotFound();
        asserterror WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponse2."Function Name",
            WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent1."Function Name");
        Assert.AssertRecordNotFound();

        // Exercise
        WorkflowResponse1.Delete(true);

        // Verify
        asserterror WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponse1."Function Name",
            WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent2."Function Name");
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidSalesOrderExceededCreditLimitEventResponseCombinations()
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        // [SCENARIO 414690] CustomerCreditLimit(Not)Exceeded events should allow combinations with certain responces.
        Initialize();
        WorkflowEventHandling.CreateEventsLibrary();
        WorkflowResponseHandling.CreateResponsesLibrary();
        // [THEN] SetStatusToPendingApproval is allowed
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponseHandling.SetStatusToPendingApprovalCode(),
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceededCode());
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponseHandling.SetStatusToPendingApprovalCode(),
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode());
        // [THEN] CreateApprovalRequestsCode is allowed
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceededCode());
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode());
        // [THEN] SendApprovalRequestForApprovalCode is allowed
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceededCode());
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidOCREventResponseCombinations()
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        Initialize();
        WorkflowEventHandling.CreateEventsLibrary();
        WorkflowResponseHandling.CreateResponsesLibrary();
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponseHandling.GetReceiveFromOCRCode(),
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEventHandling.RunWorkflowOnAfterSendToOCRIncomingDocCode());
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponseHandling.GetReceiveFromOCRAsyncCode(),
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEventHandling.RunWorkflowOnAfterSendToOCRIncomingDocCode());
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponseHandling.GetSendToOCRCode(),
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEventHandling.RunWorkflowOnAfterReadyForOCRIncomingDocCode());
        WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponseHandling.GetSendToOCRAsyncCode(),
          WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEventHandling.RunWorkflowOnAfterReadyForOCRIncomingDocCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInValidOCREventResponseCombinations()
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        Initialize();
        WorkflowEventHandling.CreateEventsLibrary();
        WorkflowResponseHandling.CreateResponsesLibrary();
        WorkflowEvent.FindSet();
        repeat
            if WorkflowEvent."Function Name" <> WorkflowEventHandling.RunWorkflowOnAfterSendToOCRIncomingDocCode() then begin
                asserterror WFEventResponseCombination.Get(
                    WFEventResponseCombination.Type::Response, WorkflowResponseHandling.GetReceiveFromOCRCode(),
                    WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent."Function Name");
                Assert.AssertRecordNotFound();
                asserterror WFEventResponseCombination.Get(
                    WFEventResponseCombination.Type::Response, WorkflowResponseHandling.GetReceiveFromOCRAsyncCode(),
                    WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent."Function Name");
                Assert.AssertRecordNotFound();
            end;
            if WorkflowEvent."Function Name" <> WorkflowEventHandling.RunWorkflowOnAfterReadyForOCRIncomingDocCode() then begin
                asserterror WFEventResponseCombination.Get(
                    WFEventResponseCombination.Type::Response, WorkflowResponseHandling.GetSendToOCRCode(),
                    WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent."Function Name");
                Assert.AssertRecordNotFound();
                asserterror WFEventResponseCombination.Get(
                    WFEventResponseCombination.Type::Response, WorkflowResponseHandling.GetSendToOCRAsyncCode(),
                    WFEventResponseCombination."Predecessor Type"::"Event", WorkflowEvent."Function Name");
                Assert.AssertRecordNotFound();
            end;
        until WorkflowEvent.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowEventResponseCombinationExtended()
    var
        WorkflowEvent1: Record "Workflow Event";
        WorkflowEvent2: Record "Workflow Event";
        WorkflowResponse1: Record "Workflow Response";
        WorkflowResponse2: Record "Workflow Response";
        WFEventResponseCombinations: TestPage "WF Event/Response Combinations";
    begin
        // [FEATURE] [Field Length]
        // [SCENARIO 334262] WF Event/Response Combinations page shows Captions of MAXIMUM(WorkflowResponse.Description) length.
        Initialize();

        // [GIVEN] Created two WorkflowEvents and WorkflowResponses, cross-connected
        CreateAnyEvent(WorkflowEvent1);
        CreateAnyEvent(WorkflowEvent2);
        CreateLongResponse(WorkflowResponse1);
        CreateLongResponse(WorkflowResponse2);

        LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse2."Function Name", WorkflowEvent1."Function Name");
        LibraryWorkflow.CreateResponsePredecessor(WorkflowResponse1."Function Name", WorkflowEvent2."Function Name");

        // [WHEN] WF Event/Response Combinations page
        WFEventResponseCombinations.Trap();
        PAGE.Run(PAGE::"WF Event/Response Combinations");

        // [THEN] WF Event/Response Combinations shows full captions
        WFEventResponseCombinations.MatrixResponseSubpage.First();
        Assert.AreEqual(WorkflowResponse1.Description, WFEventResponseCombinations.MatrixResponseSubpage.Cell1.Caption, '');
        Assert.AreEqual(WorkflowResponse2.Description, WFEventResponseCombinations.MatrixResponseSubpage.Cell2.Caption, '');
    end;

    local procedure Initialize()
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponse: Record "Workflow Response";
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        LibraryVariableStorage.Clear();
        WorkflowEvent.DeleteAll();
        WorkflowResponse.DeleteAll();
        WFEventResponseCombination.DeleteAll();
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

    local procedure CreateLongResponse(var WorkflowResponse: Record "Workflow Response")
    begin
        WorkflowResponse.Init();
        WorkflowResponse."Function Name" := LibraryUtility.GenerateGUID();
        WorkflowResponse.Description := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(WorkflowResponse.Description)), 1);
        WorkflowResponse."Table ID" := DATABASE::"Purchase Header";
        WorkflowResponse.Insert(true);
    end;

    local procedure UpdateAllEventCells(var WorkflowEventHierarchies: TestPage "Workflow Event Hierarchies")
    begin
        WorkflowEventHierarchies.MatrixEventSubpage.Cell1.SetValue(true);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell2.SetValue(true);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell3.SetValue(true);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell4.SetValue(true);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell5.SetValue(true);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell6.SetValue(true);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell7.SetValue(true);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell8.SetValue(true);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell9.SetValue(true);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell10.SetValue(true);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell11.SetValue(true);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell12.SetValue(true);
    end;

    local procedure UpdateAllResponseCells(var WFEventResponseCombinations: TestPage "WF Event/Response Combinations")
    begin
        WFEventResponseCombinations.MatrixResponseSubpage.Cell1.SetValue(true);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell2.SetValue(true);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell3.SetValue(true);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell4.SetValue(true);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell5.SetValue(true);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell6.SetValue(true);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell7.SetValue(true);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell8.SetValue(true);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell9.SetValue(true);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell10.SetValue(true);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell11.SetValue(true);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell12.SetValue(true);
    end;

    local procedure VerifyEventMatrixRow(WorkflowEventHierarchies: TestPage "Workflow Event Hierarchies"; EventDescription: Text; Cell1Value: Boolean; Cell2Value: Boolean; Cell3Value: Boolean)
    begin
        WorkflowEventHierarchies.MatrixEventSubpage.Description.AssertEquals(EventDescription);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell1.AssertEquals(Cell1Value);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell2.AssertEquals(Cell2Value);
        WorkflowEventHierarchies.MatrixEventSubpage.Cell3.AssertEquals(Cell3Value);
    end;

    local procedure VerifyResponseMatrixRow(WFEventResponseCombinations: TestPage "WF Event/Response Combinations"; EventDescription: Text; Cell1Value: Boolean; Cell2Value: Boolean)
    begin
        WFEventResponseCombinations.MatrixResponseSubpage.Description.AssertEquals(EventDescription);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell1.AssertEquals(Cell1Value);
        WFEventResponseCombinations.MatrixResponseSubpage.Cell2.AssertEquals(Cell2Value);
    end;
}

