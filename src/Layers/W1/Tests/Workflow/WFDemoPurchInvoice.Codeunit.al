codeunit 134185 "WF Demo Purch. Invoice"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Purchase] [Invoice]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWorkflow: Codeunit "Library - Workflow";
        MissingRespnseOptionsErr: Label 'Response options are missing in one or more workflow steps.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        UserIDIsNotRequiredErr: Label 'There is no step making Notification User ID mandatory.';

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceWorkflow()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        // [SCENARIO 1] When a user releases a purchase invoice the purchase invoice workflow is executed.
        // [GIVEN] The Purchase Invoice Workflow is enabled.
        // [WHEN] The user releases a purchase invoice.
        // [THEN] The Purchase Invoice Workflow is executed.

        // Setup
        Initialize();
        ChangeDemoData(Workflow);
        CreatePurchInvoice(PurchaseHeader);

        // Execute
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJournalsPost();
        LibraryLowerPermissions.AddJobs();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryLowerPermissions.SetO365Full();

        // Verify
        WorkflowStepInstanceArchive.SetRange("Workflow Code", Workflow.Code);
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        Assert.IsFalse(WorkflowStepInstanceArchive.IsEmpty, 'The workflow was not completed.');

        // Tear-down
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceWorkflowIsNotRunWithPreviewPosting()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO 1] When a user previews a purchase invoice posting the purchase invoice workflow is NOT executed.
        // [GIVEN] The Purchase Invoice Workflow is enabled.
        // [WHEN] The user uses Preview Posting on purchase invoice.
        // [THEN] The Purchase Invoice Workflow is NOT executed.

        // Setup
        Initialize();
        ChangeDemoData(Workflow);
        CreatePurchInvoice(PurchaseHeader);
        Commit(); // need to commit to run posting preview later

        // Execute
        LibraryLowerPermissions.SetPurchDocsPost();
        LibraryLowerPermissions.AddJobs();
        GLPostingPreview.Trap();
        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchaseHeader);
        GLPostingPreview.Close();
        LibraryLowerPermissions.SetO365Full();

        // Verify
        Assert.AreEqual('', GetLastErrorText, 'Non blank error was thrown');
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        Assert.IsTrue(PurchInvHeader.IsEmpty, 'The PurchaseHeader was posted.');
        WorkflowStepInstanceArchive.SetRange("Workflow Code", Workflow.Code);
        Assert.IsTrue(WorkflowStepInstanceArchive.IsEmpty, 'The workflow was completed.');

        // Tear-down
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnablePurchInvWhenUserIDIsMandatoryWithoutUserID()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserIDRequired: Boolean;
    begin
        // [SCENARIO 376597] Enabling Workflow should not be allowed when "User ID" is mandatory ("Create a notification for <User>." step exists) and "User ID" is not specified.

        Initialize();

        // [GIVEN] Workflow for Purchase invoice is set up from the template, has "User ID" field mandatory, has no "User ID" and is not enabled.
        ChangeDemoData(Workflow);
        Workflow.Enabled := false;
        Workflow.Modify();
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        if WorkflowStep.FindSet() then
            repeat
                if WorkflowStepArgument.Get(WorkflowStep.Argument) then begin
                    WorkflowStepArgument.CalcFields("Response Option Group");
                    if WorkflowStepArgument."Response Option Group" = 'GROUP 3' then begin
                        WorkflowStepArgument."Notification User ID" := '';
                        WorkflowStepArgument.Modify();
                        UserIDRequired := true;
                    end;
                end;
            until WorkflowStep.Next() = 0;
        Assert.IsTrue(UserIDRequired, UserIDIsNotRequiredErr);

        // [WHEN] Enabling Workflow
        LibraryLowerPermissions.SetO365Setup();
        asserterror Workflow.Validate(Enabled, true);

        // [THEN] "User ID" should not be empty error appears.
        Assert.ExpectedError(MissingRespnseOptionsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnablePurchInvWhenUserIDIsMandatoryWithNotifySender()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserIDRequired: Boolean;
    begin
        // [SCENARIO 279875] Enabling Workflow should be allowed when "User ID" is mandatory ("Create a notification for <User>." step exists) and "Notify Sender" is 'Yes'.
        Initialize();

        // [GIVEN] Workflow for Purchase invoice is set up from the template, has "User ID" field mandatory,
        // [GIVEN] "Notification User ID" is blank because "Notify Sender" is 'Yes'
        ChangeDemoData(Workflow);
        Workflow.Enabled := false;
        Workflow.Modify();
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        if WorkflowStep.FindSet() then
            repeat
                if WorkflowStepArgument.Get(WorkflowStep.Argument) then begin
                    WorkflowStepArgument.CalcFields("Response Option Group");
                    if WorkflowStepArgument."Response Option Group" = 'GROUP 3' then begin
                        WorkflowStepArgument.Validate("Notify Sender", true);
                        WorkflowStepArgument.Modify();
                        UserIDRequired := true;
                    end;
                end;
            until WorkflowStep.Next() = 0;
        Assert.IsTrue(UserIDRequired, UserIDIsNotRequiredErr);

        // [WHEN] Enabling Workflow
        LibraryLowerPermissions.SetO365Setup();
        Workflow.Validate(Enabled, true);

        // [THEN] Workflow enabled.
        Workflow.TestField(Enabled, true);

        // Tear-down
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnablePurchInvWhenUserIDIsMandatoryWithUserID()
    var
        Workflow: Record Workflow;
    begin
        // [SCENARIO 376597] Enabling Workflow should be allowed when "User ID" is mandatory ("Create a notification for <User>." step exists) and filled.

        Initialize();

        // [GIVEN] Workflow for Purchase invoice is set up from the template, has "User ID" field mandatory and filled and is not enabled.
        ChangeDemoData(Workflow);
        Workflow.Enabled := false;
        Workflow.Modify();

        // [WHEN] Enabling Workflow.
        LibraryLowerPermissions.SetO365Setup();
        Workflow.Validate(Enabled, true);

        // [THEN] Workflow enabled.
        Workflow.TestField(Enabled, true);

        // Tear-down
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo Purch. Invoice");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo Purch. Invoice");
        LibraryERMCountryData.InitializeCountry();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        Commit();

        BindSubscription(LibraryJobQueue);
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo Purch. Invoice");
    end;

    local procedure ChangeDemoData(var Workflow: Record Workflow)
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        GenJournalBatch: Record "Gen. Journal Batch";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseInvoiceWorkflowCode());

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.PostDocumentAsyncCode());
        WorkflowStep.FindFirst();
        WorkflowStep.Validate("Function Name", WorkflowResponseHandling.PostDocumentCode());
        WorkflowStep.Modify(true);

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocAsyncCode());
        WorkflowStep.FindFirst();
        WorkflowStep."Function Name" := WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocCode();
        WorkflowStep.Modify(true);
        WorkflowStepArgument.Get(WorkflowStep.Argument);

        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);

        WorkflowStepArgument."General Journal Template Name" := GenJournalBatch."Journal Template Name";
        WorkflowStepArgument."General Journal Batch Name" := GenJournalBatch.Name;
        WorkflowStepArgument.Modify(true);

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateNotificationEntryCode());
        WorkflowStep.FindFirst();
        WorkflowStepArgument.Get(WorkflowStep.Argument);

        WorkflowStepArgument."Notification User ID" := UserId;
        WorkflowStepArgument.Modify(true);

        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure CreatePurchInvoice(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, '', LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchLine.Modify(true);
    end;
}

