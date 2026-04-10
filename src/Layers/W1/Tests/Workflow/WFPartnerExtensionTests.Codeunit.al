codeunit 134319 "WF Partner Extension Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Event]
    end;

    var
        Assert: Codeunit Assert;
        NotSupportedResponseErr: Label 'Response %1 is not supported in the workflow.', Comment = '%1=a function name, an internal code that identifies the function.';
        CustomResponseExecutedErr: Label 'New custom response was executed.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AddToEventLibraryTest()
    var
        WorkflowEvent: Record "Workflow Event";
        WFPartnerExtensionTests: Codeunit "WF Partner Extension Tests";
        Workflows: TestPage Workflows;
    begin
        // [SCENARIO 1] A partner should be able to extend the Workflows with their own event by subscribing to the events published by the WF engine.
        // [GIVEN] A partner has added a new subscriber for the OnAddWorkflowEventsToLibrary and has added the appropriate code.
        // [WHEN] The workflows page is opened.
        // [THEN] the new event is added to the library.

        // Setup
        asserterror WorkflowEvent.Get(OnNewCustomEventCode());
        BindSubscription(WFPartnerExtensionTests);

        // Exercise
        Workflows.OpenView();

        // Verify
        WorkflowEvent.Get(OnNewCustomEventCode());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AddToResponseLibraryTest()
    var
        WorkflowResponse: Record "Workflow Response";
        WFPartnerExtensionTests: Codeunit "WF Partner Extension Tests";
        Workflows: TestPage Workflows;
    begin
        // [SCENARIO 2] A partner should be able to extend the Workflows with their own responses by subscribing to the events published by the WF engine.
        // [GIVEN] A partner has added a new subscriber for the OnAddWorkflowResponsesToLibrary and has added the appropriate code.
        // [WHEN] The workflows page is opened.
        // [THEN] the new response is added to the library.

        // Setup
        asserterror WorkflowResponse.Get(NewCustomResponseCode());
        BindSubscription(WFPartnerExtensionTests);

        // Exercise
        Workflows.OpenView();

        // Verify
        WorkflowResponse.Get(NewCustomResponseCode());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExecuteResponseTest()
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        "Integer": Record "Integer";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WFPartnerExtensionTests: Codeunit "WF Partner Extension Tests";
        Workflows: TestPage Workflows;
        Variant: Variant;
    begin
        // [SCENARIO 3] A partner should be able to extend the Workflows with their own responses by subscribing to the events published by the WF engine.
        // [GIVEN] A partner has added a new subscriber for the OnExecuteWorkflowResponse and has added the appropriate code.
        // [WHEN] A workflow is triggered that has the new response (simulated)
        // [THEN] the new response is executed.

        // Setup
        BindSubscription(WFPartnerExtensionTests);

        // Exercise
        Workflows.OpenView();
        WorkflowStepInstance.Init(); // silly, useless preCAL rule
        Integer.Init(); // silly, useless preCAL rule
        Variant := Integer;
        WorkflowStepInstance."Function Name" := NewCustomResponseCode();
        asserterror WorkflowResponseHandling.ExecuteResponse(Variant, WorkflowStepInstance, Variant);

        // Verify
        Assert.ExpectedError(CustomResponseExecutedErr)
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExecuteResponseFailTest()
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        "Integer": Record "Integer";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WFPartnerExtensionTests: Codeunit "WF Partner Extension Tests";
        Workflows: TestPage Workflows;
        Variant: Variant;
    begin
        // [SCENARIO 3] A partner should be able to extend the Workflows with their own responses by subscribing to the events published by the WF engine.
        // [GIVEN] A partner has added a new subscriber for the OnExecuteWorkflowResponse and has NOT added the appropriate code.
        // [WHEN] A workflow is triggered that has the new response (simulated)
        // [THEN] an error is triggered that new response was not executed

        // Setup
        BindSubscription(WFPartnerExtensionTests);

        // Exercise
        Workflows.OpenView();
        WorkflowStepInstance.Init(); // silly, useless preCAL rule
        Integer.Init(); // silly, useless preCAL rule
        WorkflowStepInstance."Function Name" := NewCustomResponse2Code();
        Variant := Integer;
        asserterror WorkflowResponseHandling.ExecuteResponse(Variant, WorkflowStepInstance, Variant);

        // Verify
        Assert.ExpectedError(StrSubstNo(NotSupportedResponseErr, WorkflowStepInstance."Function Name"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    local procedure CustomAddToEventLibrarySubscriber()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowEventHandling.AddEventToLibrary(OnNewCustomEventCode(), DATABASE::Integer, OnNewCustomEventCode(), 0, false)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsesToLibrary', '', false, false)]
    local procedure CustomAddToResponseLibrarySubscriber()
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowResponseHandling.AddResponseToLibrary(NewCustomResponseCode(), DATABASE::Integer, NewCustomResponseCode(), 'GROUP 0');
        WorkflowResponseHandling.AddResponseToLibrary(NewCustomResponse2Code(), DATABASE::Integer, NewCustomResponse2Code(), 'GROUP 0')
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', false, false)]
    local procedure CustomExecuteResponseSubscriber(var ResponseExecuted: Boolean; Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance")
    begin
        ResponseExecuted := false;

        case ResponseWorkflowStepInstance."Function Name" of
            NewCustomResponseCode():
                begin
                    ResponseExecuted := true;
                    NewCustomResponse(Variant);
                end;
            NewCustomResponse2Code():
                ;
        end;
    end;

    local procedure OnNewCustomEventCode(): Code[128]
    begin
        exit(UpperCase('OnNewCustomEventCode'))
    end;

    local procedure NewCustomResponseCode(): Code[128]
    begin
        exit(UpperCase('NewCustomResponseCode'))
    end;

    local procedure NewCustomResponse2Code(): Code[128]
    begin
        exit(UpperCase('NewCustomResponse2Code'))
    end;

    local procedure NewCustomResponse(var "Integer": Record "Integer")
    begin
        Integer.Init(); // dummy line to avoid the error that a variable must be used. If you remove it here, you'll get the error on the EventSubscriber. If you remove it there it will work, but it won't be nice...
        Error(CustomResponseExecutedErr);
    end;
}

