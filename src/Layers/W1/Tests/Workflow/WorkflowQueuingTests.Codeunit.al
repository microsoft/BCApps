codeunit 134315 "Workflow Queuing Tests"
{
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

