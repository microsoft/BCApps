codeunit 134315 "Workflow Queuing Tests"
{
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
}

