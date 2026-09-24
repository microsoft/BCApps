codeunit 134315 "Workflow Queuing Tests"
{
    EventSubscriberInstance = Manual;
    Permissions = tabledata "Workflow Step Instance Archive" = rd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Event]
    end;

    var
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
        WorkflowRecordManagement: Codeunit "Workflow Record Management";
        ReplayedResponseCount: Integer;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Workflow Queuing Tests");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEventQueuingWithIncDocWorkflow()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        // [SCENARIO] Thw Workflow is compledted even if there is a response that triggers an event, and that response is followed by a different response.
        // [GIVEN] A workflow with a response that triggers an event in it.
        // [GIVEN] A response that follows the first response that triggers the event.
        // [GIVEN] The second response is followed by the event that is triggered in the first response.
        // [WHEN] The entry point event is executed.
        // [THEN] The workflow is completed and archived, and is not getting stuck in the process.

        Initialize();
        // Setup
        LibraryERMCountryData.CreateVATData();
        WorkflowStepInstanceArchive.DeleteAll();

        CreateIncomingDocumentWorkflow();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);

        // Exercise
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Verify
        WorkflowStepInstanceArchive.SetFilter(Status, StrSubstNo('<>%1', WorkflowStepInstanceArchive.Status::Completed));
        Assert.IsTrue(WorkflowStepInstanceArchive.IsEmpty, 'The workflow was not executed.');
    end;

    local procedure CreateIncomingDocumentWorkflow()
    var
        Workflow: Record Workflow;
        GenJournalBatch: Record "Gen. Journal Batch";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        SecondEvent: Integer;
        SecondResponse: Integer;
        ThirdResponse: Integer;
        ThirdEvent: Integer;
        FourthResponse: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        SecondEvent :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterReleasePurchaseDocCode());
        SecondResponse := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentCode(), SecondEvent);
        ThirdResponse := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), SecondResponse);

        ThirdEvent :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(), ThirdResponse);
        FourthResponse := LibraryWorkflow.InsertResponseStep(Workflow,
            WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocCode(), ThirdEvent);

        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryWorkflow.InsertPmtLineCreationArgument(FourthResponse, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);

        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoErrorWhenQueuedEventHasConsumedVariantData()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Workflow: Record Workflow;
        WorkflowEventQueue: Record "Workflow Event Queue";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        Variant: Variant;
        EntryPointEvent: Integer;
        InstanceGuid: Guid;
    begin
        // [SCENARIO] Workflow completes normally when a queued event has consumed VarArray data (NavVariant not initialized).
        // [GIVEN] A WorkflowStepInstance with Status = Processing.
        // [GIVEN] A WorkflowEventQueue entry pointing to it with VarArray indices that have no data.
        // [GIVEN] A working workflow with an entry point event.
        // [WHEN] The workflow event is triggered.
        // [THEN] No error occurs and the workflow completes normally.

        Initialize();
        // Setup
        LibraryERMCountryData.CreateVATData();
        EnsurePurchSetupNoSeries();
        WorkflowStepInstanceArchive.DeleteAll();
        WorkflowEventQueue.SetRange("Session ID", SessionId());
        WorkflowEventQueue.DeleteAll();

        // Ensure VarArray indices 98, 99 are empty by restoring them
        WorkflowRecordManagement.RestoreRecord(98, Variant);
        WorkflowRecordManagement.RestoreRecord(99, Variant);

        // Create a real workflow for the release event
        LibraryWorkflow.DisableAllWorkflows();
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEvent := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterReleasePurchaseDocCode());
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), EntryPointEvent);
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);

        // Create a step instance with Processing status to be found by ExecuteQueuedEvents
        InstanceGuid := CreateGuid();
        WorkflowStepInstance.Init();
        WorkflowStepInstance.ID := InstanceGuid;
        WorkflowStepInstance."Workflow Code" := Workflow.Code;
        WorkflowStepInstance."Workflow Step ID" := 50000;
        WorkflowStepInstance.Status := WorkflowStepInstance.Status::Processing;
        WorkflowStepInstance.Type := WorkflowStepInstance.Type::"Event";
        WorkflowStepInstance."Function Name" := 'STALE_EVENT';
        WorkflowStepInstance.Insert();

        // Insert a queue entry pointing to the Processing step instance with empty VarArray indices
        WorkflowEventQueue.Init();
        WorkflowEventQueue."Session ID" := SessionId();
        WorkflowEventQueue."Step Record ID" := WorkflowStepInstance.RecordId;
        WorkflowEventQueue."Record Index" := 98;
        WorkflowEventQueue."xRecord Index" := 99;
        WorkflowEventQueue.Insert(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);

        // Exercise - this triggers workflow → ExecuteResponses → ExecuteQueuedEvents
        // Before fix: crashes with NavVariant variable not initialized
        // After fix: skips the stale entry, workflow completes normally
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Verify - no error, workflow completed
        WorkflowStepInstanceArchive.SetFilter(Status, StrSubstNo('<>%1', WorkflowStepInstanceArchive.Status::Completed));
        Assert.IsTrue(WorkflowStepInstanceArchive.IsEmpty(), 'The workflow should have completed without error.');

        // Clean up
        WorkflowStepInstance.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedQueuedEventRetainsRecordsUntilUnblocked()
    var
        Customer: Record Customer;
        xCustomer: Record Customer;
        QueuedEvent: Record "Workflow Step Instance";
        BlockingResponse: Record "Workflow Step Instance";
        WorkflowEventQueue: Record "Workflow Event Queue";
        SavedWorkflowEventQueue: Record "Workflow Event Queue";
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowQueuingTests: Codeunit "Workflow Queuing Tests";
    begin
        // [SCENARIO] Another workflow in the session must not consume a blocked event's saved records.
        InitializeQueueReplayTest(Customer, xCustomer);
        BindSubscription(WorkflowQueuingTests);

        // [GIVEN] An event is queued while a response in its workflow instance is still processing.
        CreateBlockedWorkflowEvent(QueuedEvent, BlockingResponse);
        WorkflowManagement.ExecuteResponses(Customer, xCustomer, QueuedEvent);
        FindQueuedEvent(WorkflowEventQueue, QueuedEvent);
        SavedWorkflowEventQueue := WorkflowEventQueue;

        // [WHEN] Other workflow instances attempt to process the session's queue.
        ProcessSessionQueue(Customer);
        ProcessSessionQueue(Customer);

        // [THEN] The original queue entry and both saved record indices are retained without executing the response.
        FindQueuedEvent(WorkflowEventQueue, QueuedEvent);
        Assert.AreEqual(1, WorkflowEventQueue.Count(), 'The blocked event must not be queued again.');
        Assert.AreEqual(SavedWorkflowEventQueue.ID, WorkflowEventQueue.ID, 'The original queue entry must be retained.');
        Assert.AreEqual(SavedWorkflowEventQueue."Record Index", WorkflowEventQueue."Record Index", 'The saved record index must not change.');
        Assert.AreEqual(SavedWorkflowEventQueue."xRecord Index", WorkflowEventQueue."xRecord Index", 'The saved previous record index must not change.');
        Assert.AreEqual(0, WorkflowQueuingTests.GetReplayedResponseCount(), 'The blocked event must not execute.');

        // [WHEN] The blocking response completes and the queue is processed again.
        CompleteBlockingResponse(BlockingResponse);
        ProcessSessionQueue(Customer);

        // [THEN] The event executes exactly once with the original current and previous records and is archived.
        VerifyQueuedEventCompleted(QueuedEvent);
        Assert.AreEqual(1, WorkflowQueuingTests.GetReplayedResponseCount(), 'The deferred response must execute once.');
        ProcessSessionQueue(Customer);
        Assert.AreEqual(1, WorkflowQueuingTests.GetReplayedResponseCount(), 'The completed response must not execute again.');
        UnbindSubscription(WorkflowQueuingTests);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadyQueuedEventRunsWhileAnotherInstanceIsBlocked()
    var
        Customer: Record Customer;
        xCustomer: Record Customer;
        BlockedEvent: Record "Workflow Step Instance";
        BlockingResponse: Record "Workflow Step Instance";
        ReadyEvent: Record "Workflow Step Instance";
        CompletedResponse: Record "Workflow Step Instance";
        WorkflowEventQueue: Record "Workflow Event Queue";
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowQueuingTests: Codeunit "Workflow Queuing Tests";
    begin
        // [SCENARIO] A blocked workflow instance must not prevent another instance's queued event from completing.
        InitializeQueueReplayTest(Customer, xCustomer);
        BindSubscription(WorkflowQueuingTests);

        // [GIVEN] Two workflow instances have queued events, and only the second instance is ready.
        CreateBlockedWorkflowEvent(BlockedEvent, BlockingResponse);
        WorkflowManagement.ExecuteResponses(Customer, xCustomer, BlockedEvent);
        CreateBlockedWorkflowEvent(ReadyEvent, CompletedResponse);
        WorkflowManagement.ExecuteResponses(Customer, xCustomer, ReadyEvent);
        CompleteBlockingResponse(CompletedResponse);

        // [WHEN] Another workflow processes the session's queue.
        ProcessSessionQueue(Customer);

        // [THEN] The ready event completes while the first event remains queued.
        VerifyQueuedEventCompleted(ReadyEvent);
        FindQueuedEvent(WorkflowEventQueue, BlockedEvent);
        Assert.AreEqual(1, WorkflowEventQueue.Count(), 'The blocked event must remain queued.');
        Assert.AreEqual(1, WorkflowQueuingTests.GetReplayedResponseCount(), 'Only the ready response must execute.');

        // [WHEN] The remaining blocking response completes.
        CompleteBlockingResponse(BlockingResponse);
        ProcessSessionQueue(Customer);

        // [THEN] Both events have completed exactly once.
        VerifyQueuedEventCompleted(BlockedEvent);
        Assert.AreEqual(2, WorkflowQueuingTests.GetReplayedResponseCount(), 'Both deferred responses must execute once.');
        UnbindSubscription(WorkflowQueuingTests);
    end;

    local procedure InitializeQueueReplayTest(var Customer: Record Customer; var xCustomer: Record Customer)
    var
        WorkflowEventQueue: Record "Workflow Event Queue";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        Initialize();
        LibraryWorkflow.DisableAllWorkflows();
        WorkflowEventQueue.SetRange("Session ID", SessionId());
        WorkflowEventQueue.DeleteAll();
        WorkflowResponseHandling.AddResponseToLibrary(VerifyQueuedRecordsCode(), Database::Customer, VerifyQueuedRecordsCode(), 'GROUP 0');

        Customer.Init();
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), Database::Customer);
        Customer.Name := 'Current name';
        Customer.Insert();
        xCustomer := Customer;
        xCustomer.Name := 'Previous name';
    end;

    local procedure CreateEventInstance(var WorkflowStepInstance: Record "Workflow Step Instance")
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowStepInstance.Init();
        WorkflowStepInstance.ID := CreateGuid();
        WorkflowStepInstance."Workflow Code" := Workflow.Code;
        WorkflowStepInstance."Workflow Step ID" := 1;
        WorkflowStepInstance.Type := WorkflowStepInstance.Type::"Event";
        WorkflowStepInstance.Status := WorkflowStepInstance.Status::Active;
        WorkflowStepInstance."Function Name" := WorkflowEventHandling.RunWorkflowOnCustomerChangedCode();
        WorkflowStepInstance.Insert(true);
    end;

    local procedure CreateBlockedWorkflowEvent(var QueuedEvent: Record "Workflow Step Instance"; var BlockingResponse: Record "Workflow Step Instance")
    var
        QueuedResponse: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        CreateEventInstance(QueuedEvent);

        BlockingResponse := QueuedEvent;
        BlockingResponse."Workflow Step ID" := 2;
        BlockingResponse.Type := BlockingResponse.Type::Response;
        BlockingResponse.Status := BlockingResponse.Status::Processing;
        BlockingResponse."Function Name" := WorkflowResponseHandling.DoNothingCode();
        BlockingResponse.Insert(true);

        QueuedEvent."Previous Workflow Step ID" := BlockingResponse."Workflow Step ID";
        QueuedEvent.Modify(true);

        QueuedResponse := QueuedEvent;
        QueuedResponse."Workflow Step ID" := 3;
        QueuedResponse."Previous Workflow Step ID" := QueuedEvent."Workflow Step ID";
        QueuedResponse.Type := QueuedResponse.Type::Response;
        QueuedResponse.Status := QueuedResponse.Status::Inactive;
        QueuedResponse."Function Name" := VerifyQueuedRecordsCode();
        QueuedResponse.Insert(true);
    end;

    local procedure ProcessSessionQueue(Customer: Record Customer)
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        CreateEventInstance(WorkflowStepInstance);
        WorkflowManagement.ExecuteResponses(Customer, Customer, WorkflowStepInstance);
    end;

    local procedure FindQueuedEvent(var WorkflowEventQueue: Record "Workflow Event Queue"; WorkflowStepInstance: Record "Workflow Step Instance")
    begin
        WorkflowEventQueue.Reset();
        WorkflowEventQueue.SetRange("Session ID", SessionId());
        WorkflowEventQueue.SetRange("Step Record ID", WorkflowStepInstance.RecordId());
        WorkflowEventQueue.FindFirst();
    end;

    local procedure CompleteBlockingResponse(var WorkflowStepInstance: Record "Workflow Step Instance")
    begin
        WorkflowStepInstance.Status := WorkflowStepInstance.Status::Completed;
        WorkflowStepInstance.Modify(true);
    end;

    local procedure VerifyQueuedEventCompleted(WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowEventQueue: Record "Workflow Event Queue";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        WorkflowEventQueue.SetRange("Session ID", SessionId());
        WorkflowEventQueue.SetRange("Step Record ID", WorkflowStepInstance.RecordId());
        Assert.IsTrue(WorkflowEventQueue.IsEmpty(), 'The completed event must be removed from the queue.');
        WorkflowStepInstanceArchive.Get(WorkflowStepInstance.ID, WorkflowStepInstance."Workflow Code", WorkflowStepInstance."Workflow Step ID");
        Assert.AreEqual(WorkflowStepInstanceArchive.Status::Completed, WorkflowStepInstanceArchive.Status, 'The queued event must complete.');
    end;

    procedure GetReplayedResponseCount(): Integer
    begin
        exit(ReplayedResponseCount);
    end;

    local procedure VerifyQueuedRecordsCode(): Code[128]
    begin
        exit('VERIFYQUEUEDRECORDS');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', false, false)]
    local procedure VerifyQueuedRecords(var ResponseExecuted: Boolean; var Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance")
    var
        Customer: Record Customer;
        xCustomer: Record Customer;
    begin
        if ResponseWorkflowStepInstance."Function Name" <> VerifyQueuedRecordsCode() then
            exit;

        Assert.IsTrue(Variant.IsRecord, 'A replayed response must receive a Record-backed Variant.');
        Assert.IsTrue(xVariant.IsRecord, 'A replayed response must receive a Record-backed xVariant.');
        Customer := Variant;
        xCustomer := xVariant;
        Assert.AreEqual(Customer."No.", xCustomer."No.", 'Both saved records must belong to the same customer.');
        Assert.AreEqual('Current name', Customer.Name, 'The current record must be preserved while the event is blocked.');
        Assert.AreEqual('Previous name', xCustomer.Name, 'The previous record must be preserved while the event is blocked.');
        ReplayedResponseCount += 1;
        ResponseExecuted := true;
    end;

    local procedure EnsurePurchSetupNoSeries()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeriesCode: Code[20];
        IsModified: Boolean;
    begin
        PurchasesPayablesSetup.Get();
        NoSeriesCode := LibraryUtility.GetGlobalNoSeriesCode();
        if PurchasesPayablesSetup."Invoice Nos." = '' then begin
            PurchasesPayablesSetup.Validate("Invoice Nos.", NoSeriesCode);
            IsModified := true;
        end;
        if PurchasesPayablesSetup."Posted Invoice Nos." = '' then begin
            PurchasesPayablesSetup.Validate("Posted Invoice Nos.", NoSeriesCode);
            IsModified := true;
        end;
        if IsModified then
            PurchasesPayablesSetup.Modify(true);
    end;
}

