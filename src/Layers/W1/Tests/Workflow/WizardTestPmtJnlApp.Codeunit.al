codeunit 134570 "Wizard Test - Pmt. Jnl App."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Wizard] [UI]
    end;

    var
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWorkflow: Codeunit "Library - Workflow";
        Assert: Codeunit Assert;
        ExitWithoutSavingConfirmMsg: Label 'Payment Journal Approval has not been set up.';

    [Test]
    [HandlerFunctions('WizardOpenHandler,ExitWithoutSavingConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreateApprovalWorklfowOpensTheWizardTest()
    var
        ApprovalWorkflowWizard: Record "Approval Workflow Wizard";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Setup
        Initialize();
        Commit();
        PaymentJournal.OpenEdit();

        ApprovalWorkflowWizard."For All Batches" := false;
        ApprovalWorkflowWizard."Journal Batch Name" := CopyStr(PaymentJournal.FILTER.GetFilter("Journal Batch Name"),
            1, MaxStrLen(ApprovalWorkflowWizard."Journal Batch Name"));
        ApprovalWorkflowWizard."Journal Template Name" := CopyStr(PaymentJournal.FILTER.GetFilter("Journal Template Name"),
            1, MaxStrLen(ApprovalWorkflowWizard."Journal Template Name"));
        LibraryVariableStorage.Enqueue(ApprovalWorkflowWizard);

        // Execute
        PaymentJournal.CreateApprovalWorkflow.Invoke();

        // Verification is done in the handler
    end;

    [Test]
    [HandlerFunctions('ExitWithoutSavingConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure InvalidApproverIdThrowsErrorTest()
    var
        PmtAppWorkflowSetupWzrd: TestPage "Pmt. App. Workflow Setup Wzrd.";
    begin
        // Setup
        Initialize();

        PmtAppWorkflowSetupWzrd.OpenEdit();
        PmtAppWorkflowSetupWzrd.NextPage.Invoke();

        // Execute & Verify
        asserterror PmtAppWorkflowSetupWzrd.NextPage.Invoke();
        Assert.ExpectedError('You must select an approver before continuing.');
    end;

    [Test]
    [HandlerFunctions('WizardOpenAndFinishHandler,ApprovelUserLookupHandler')]
    [Scope('OnPrem')]
    procedure FinishWizardWithAllBatchesSelectionTest()
    begin
        FinishWizardAndVerify(true);
    end;

    [Test]
    [HandlerFunctions('WizardOpenAndFinishHandler,ApprovelUserLookupHandler')]
    [Scope('OnPrem')]
    procedure FinishWizardWithCurrentBatchSelectionTest()
    begin
        FinishWizardAndVerify(false);
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        LibraryVariableStorage.Clear();
        LibraryWorkflow.DisableAllWorkflows();
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.FindFirst();
        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.ModifyAll("No. Series", '');
        AssistedSetupTestLibrary.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WizardOpenHandler(var PmtAppWorkflowSetupWzrd: TestPage "Pmt. App. Workflow Setup Wzrd.")
    var
        ApprovalWorkflowWizard: Record "Approval Workflow Wizard";
        ApprovalWorkflowWizardVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(ApprovalWorkflowWizardVar);
        ApprovalWorkflowWizard := ApprovalWorkflowWizardVar;

        // Ship the first instructional page
        PmtAppWorkflowSetupWzrd.NextPage.Invoke();

        Assert.ExpectedMessage(ApprovalWorkflowWizard."Journal Batch Name", PmtAppWorkflowSetupWzrd.CurrentBatchIsLabel.Value);
        if ApprovalWorkflowWizard."For All Batches" then
            Assert.AreEqual('All Batches', PmtAppWorkflowSetupWzrd.BatchSelection.Value, 'Current batch selection is not ''All Batches''')
        else
            Assert.AreEqual('Current Batch Only', PmtAppWorkflowSetupWzrd.BatchSelection.Value,
              'Current batch selection is not ''Current Batch Only''');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WizardOpenAndFinishHandler(var PmtAppWorkflowSetupWzrd: TestPage "Pmt. App. Workflow Setup Wzrd.")
    var
        ApprovalWorkflowWizard: Record "Approval Workflow Wizard";
        ApprovalWorkflowWizardVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(ApprovalWorkflowWizardVar);
        ApprovalWorkflowWizard := ApprovalWorkflowWizardVar;

        // Skip the first instructional page
        PmtAppWorkflowSetupWzrd.NextPage.Invoke();

        LibraryVariableStorage.Enqueue := ApprovalWorkflowWizard."Approver ID";
        PmtAppWorkflowSetupWzrd."Approver ID".Lookup();
        // PmtAppWorkflowSetupWzrd."Approver ID".VALUE := ApprovalWorkflowWizard."Approver ID";
        // PmtAppWorkflowSetupWzrd."Approver ID".VALUE :

        if ApprovalWorkflowWizard."For All Batches" then
            PmtAppWorkflowSetupWzrd.BatchSelection.Value := PmtAppWorkflowSetupWzrd.BatchSelection.GetOption(2)
        else
            PmtAppWorkflowSetupWzrd.BatchSelection.Value := PmtAppWorkflowSetupWzrd.BatchSelection.GetOption(1);

        PmtAppWorkflowSetupWzrd.NextPage.Invoke();
        PmtAppWorkflowSetupWzrd.Finish.Invoke();
        Commit();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ExitWithoutSavingConfirmHandlerYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(ExitWithoutSavingConfirmMsg, Message);
        Reply := true;
    end;

    [Scope('OnPrem')]
    procedure FindWorkflowEnabledEntryPoints(TableNo: Integer; EventFilter: Text; var WorkflowDefinition: Query "Workflow Definition"): Boolean
    begin
        WorkflowDefinition.SetRange(Table_ID, TableNo);
        WorkflowDefinition.SetRange(Entry_Point, true);
        WorkflowDefinition.SetRange(Enabled, true);
        WorkflowDefinition.SetRange(Type, WorkflowDefinition.Type::"Event");
        WorkflowDefinition.SetFilter(Function_Name, EventFilter);
        WorkflowDefinition.Open();
        exit(WorkflowDefinition.Read());
    end;

    [Scope('OnPrem')]
    procedure FinishWizardAndVerify(ForAllBatches: Boolean)
    var
        UserSetup: Record "User Setup";
        ApprovalWorkflowWizard: Record "Approval Workflow Wizard";
        WorkflowStepArgument: Record "Workflow Step Argument";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowStep: Record "Workflow Step";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        PaymentJournal: TestPage "Payment Journal";
        WorkflowDefinition: Query "Workflow Definition";
    begin
        // Setup
        Initialize();
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        Assert.IsFalse(FindWorkflowEnabledEntryPoints(DATABASE::"Gen. Journal Line",
            WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode(),
            WorkflowDefinition), 'Workflow already exists');
        Commit();

        // Execute
        PaymentJournal.OpenEdit();

        if ForAllBatches then
            ApprovalWorkflowWizard."For All Batches" := true
        else
            ApprovalWorkflowWizard."For All Batches" := false;

        ApprovalWorkflowWizard."Journal Batch Name" := CopyStr(PaymentJournal.FILTER.GetFilter("Journal Batch Name"),
            1, MaxStrLen(ApprovalWorkflowWizard."Journal Batch Name"));
        ApprovalWorkflowWizard."Journal Template Name" := CopyStr(PaymentJournal.FILTER.GetFilter("Journal Template Name"),
            1, MaxStrLen(ApprovalWorkflowWizard."Journal Template Name"));
        ApprovalWorkflowWizard."Approver ID" := UserSetup."User ID";
        LibraryVariableStorage.Enqueue(ApprovalWorkflowWizard);

        PaymentJournal.CreateApprovalWorkflow.Invoke();

        // Verify that the workflow is created
        Assert.IsTrue(FindWorkflowEnabledEntryPoints(DATABASE::"Gen. Journal Line",
            WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode(),
            WorkflowDefinition), 'Workflow is not created');

        // Verify that the evnet conditions are set correctly
        GenJournalLine.SetRange("Journal Template Name", ApprovalWorkflowWizard."Journal Template Name");
        if not ForAllBatches then
            GenJournalLine.SetRange("Journal Batch Name", ApprovalWorkflowWizard."Journal Batch Name");
        WorkflowStepArgument.Get(WorkflowDefinition.Argument);
        Assert.ExpectedMessage(GenJournalLine.GetView(false), WorkflowStepArgument.GetEventFilters());

        // Verify that the response options are set correctly
        WorkflowStep.SetRange(Type, WorkflowStep.Type::Response);
        WorkflowStep.SetRange("Workflow Code", WorkflowDefinition.Code);
        WorkflowStep.SetRange("Entry Point", false);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());

        Assert.AreEqual(1, WorkflowStep.Count, 'More than 1 expected response found.');

        WorkflowStep.FindFirst();

        WorkflowStepArgument.Get(WorkflowStep.Argument);
        Assert.AreEqual(WorkflowStepArgument."Approver User ID", ApprovalWorkflowWizard."Approver ID",
          'Approver id is not set correctly.');
        Assert.AreEqual(WorkflowStepArgument."Approver Limit Type", WorkflowStepArgument."Approver Limit Type"::"Specific Approver",
          'Limit type is not set correctly.');
        Assert.AreEqual(WorkflowStepArgument."Approver Type", WorkflowStepArgument."Approver Type"::Approver,
          'Type not set correctly.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApprovelUserLookupHandler(var ApprovalUserSetup: TestPage "Approval User Setup")
    var
        ApprovalUserId: Variant;
    begin
        LibraryVariableStorage.Dequeue(ApprovalUserId);
        ApprovalUserSetup.GotoKey(ApprovalUserId);
        ApprovalUserSetup.OK().Invoke();
    end;
}

