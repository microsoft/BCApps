codeunit 134178 "WF Demo Incoming Doc"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Workflow Step Instance Archive" = d;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Incoming Document]
    end;

    var
        LibraryWorkflow: Codeunit "Library - Workflow";
        Assert: Codeunit Assert;
        RecordNotFoundErr: Label '%1 was not found.', Comment = '%1=TableCaption';
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowInsert()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponse: Record "Workflow Response";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowSetup: Codeunit "Workflow Setup";
        Guid: Guid;
    begin
        // [SCENARIO] Recreate the workflow demo data
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowEvent.DeleteAll();
        WorkflowResponse.DeleteAll();

        // Exercise.
        WorkflowSetup.InitWorkflow();

        // Verify
        Assert.AreEqual(32, Workflow.Count, StrSubstNo(RecordNotFoundErr, Workflow.TableCaption()));
        Assert.AreEqual(488, WorkflowStep.Count, StrSubstNo(RecordNotFoundErr, WorkflowStep.TableCaption()));

        WorkflowStep.SetFilter(Argument, '<>%1', Guid);
        Assert.AreEqual(WorkflowStep.Count, WorkflowStepArgument.Count, 'There should not be more arguments than steps.');

        WorkflowStepArgument.SetRange("Notify Sender", true);
        Assert.isfalse(WorkflowStepArgument.IsEmpty, 'There must be arguments with Notify Sender');
        if WorkflowStepArgument.FindSet() then
            repeat
                WorkflowStep.SetRange(Argument, WorkflowStepArgument.ID);
                WorkflowStep.FindSet();
                repeat
                    Assert.AreEqual(
                        1, StrPos(WorkflowStep."Function Name", 'REJECT'),
                        StrSubstNo('Step functions name %1 should start with REJECT', WorkflowStep."Function Name"));
                until WorkflowStep.Next() = 0;
            until WorkflowStepArgument.next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncomingDocumentGeneratesNotification()
    var
        Workflow: Record Workflow;
        IncomingDocument: Record "Incoming Document";
        NotificationEntry: Record "Notification Entry";
    begin
        // [SCENARIO] When an Incoming Document is created, a Notification record is also created for the specified user.
        // [GIVEN] Workflow is setup to notify a specific user.
        // [WHEN] An Incoming Document record is created.
        // [THEN] A Notification record is created for that user.

        // Setup
        Initialize();
        SetNotificationSetup(Workflow);

        // Exercise
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Verify
        VerifyNotificationEntry(NotificationEntry, UserId, IncomingDocument.RecordId);

        // Tear-down
        LibraryWorkflow.DisableAllWorkflows();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncomingDocumentCreatesNewWorkflow()
    var
        Workflow: Record Workflow;
        IncomingDocument: Record "Incoming Document";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        // [SCENARIO] When an Incoming Document is created, a copy of all the workflow steps is created.
        // [GIVEN] A workflow template that starts from Incoming Documents exits.
        // [WHEN] An Incoming Document record is created.
        // [THEN] A copy of all the workflow steps is created.

        // Setup
        Initialize();
        SetNotificationSetup(Workflow);

        // Exercise
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Validate
        WorkflowStepInstanceArchive.SetRange("Workflow Code", Workflow.Code);
        Assert.AreEqual(2, WorkflowStepInstanceArchive.Count, 'Unexpected number of step instances.');
        WorkflowStepInstanceArchive.SetFilter(Status, '<>%1', WorkflowStepInstanceArchive.Status::Completed);
        Assert.IsTrue(WorkflowStepInstanceArchive.IsEmpty, 'All step instances should be completed.');

        // Tear-down
        LibraryWorkflow.DisableAllWorkflows();
    end;

    local procedure Initialize()
    var
        NotificationEntry: Record "Notification Entry";
        NotificationSetup: Record "Notification Setup";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        UserSetup: Record "User Setup";
    begin
        WorkflowStepInstanceArchive.DeleteAll();
        NotificationEntry.DeleteAll();
        NotificationSetup.DeleteAll();
        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowSetup.InitWorkflow();
        if IsInitialized then
            exit;

        if not UserSetup.get(UserId) then begin
            UserSetup."User ID" := UserId;
            UserSetup.Insert(true);
        end;

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    local procedure FindNotificationEntry(var NotificationEntry: Record "Notification Entry"; UserID: Code[50]; RecordID: RecordID)
    begin
        NotificationEntry.SetRange("Recipient User ID", UserID);
        NotificationEntry.SetRange("Triggered By Record", RecordID);
        NotificationEntry.FindFirst();
    end;

    local procedure VerifyNotificationEntry(var NotificationEntry: Record "Notification Entry"; UserID: Code[50]; RecordID: RecordID)
    begin
        FindNotificationEntry(NotificationEntry, UserID, RecordID);

        NotificationEntry.TestField(Type, NotificationEntry.Type::"New Record");
        NotificationEntry.TestField("Recipient User ID", UserID);
        NotificationEntry.TestField("Triggered By Record", RecordID);
    end;

    local procedure SetNotificationSetup(var Workflow: Record Workflow)
    var
        NotificationSetup: Record "Notification Setup";
        WorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        LibraryWorkflow.CreateNotificationSetup(NotificationSetup, UserId, NotificationSetup."Notification Type"::"New Record",
          NotificationSetup."Notification Method"::Note);

        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.IncomingDocumentWorkflowCode());

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateNotificationEntryCode());
        WorkflowStep.FindFirst();
        LibraryWorkflow.InsertNotificationArgument(WorkflowStep.ID, UserId, 0, '');

        LibraryWorkflow.EnableWorkflow(Workflow);
    end;
}

