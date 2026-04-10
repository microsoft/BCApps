codeunit 134305 "Workflow Delete Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    Permissions = TableData "Workflow - Record Change" = rimd,
                  TableData "Workflow Record Change Archive" = rimd;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Deletion]
    end;

    var
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        CannotDeleteEnabledWorkflowErr: Label 'Enabled workflows cannot be deleted.';
        NoWorkflowStepArgumentsShouldExistErr: Label 'There should be no records in the workflow step argument table.';
        NoWorkflowShouldExistErr: Label 'There should be no records in the workflow table.';
        NoWorkflowStepShouldExistErr: Label 'There should be no records in the workflow step table.';
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        SetupFailedErr: Label 'Setup failed.';
        WorkflowHasActiveInstancesErr: Label 'You cannot delete the workflow because active workflow step instances exist.';
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotDeleteEnabledWorkflow()
    var
        Workflow: Record Workflow;
    begin
        // [SCENARIO 1] When the user wants to delete an enabled workflow, the system will throw an error.
        // [GIVEN] There is an enabled workflow.
        // [WHEN] The user wants to delete the enabled workflow.
        // [THEN] The system will show the user an error.

        // Setup
        CreateWorkflow(Workflow);

        // Execute
        asserterror Workflow.Delete(true);

        // Validate
        Assert.ExpectedError(CannotDeleteEnabledWorkflowErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteWorkflowAndWorkflowSteps()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowCode: Code[20];
    begin
        // [SCENARIO 2] When the user wants to delete an disabled workflow, the workflow and all workflow steps will be deleted.
        // [GIVEN] There is an enabled workflow.
        // [WHEN] The user disables the workflow and then deletes it.
        // [WHEN] The user selects the option to delete only the template.
        // [THEN] The workflow and all workflow steps will be deleted.

        // Setup
        WorkflowStepArgument.DeleteAll();
        CreateWorkflow(Workflow);

        DisableWorkflow(Workflow);

        WorkflowCode := Workflow.Code;

        // Execute
        Workflow.Delete(true);

        // Validate
        Clear(Workflow);
        Workflow.SetRange(Code, WorkflowCode);
        Clear(WorkflowStep);
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        Clear(WorkflowStepArgument);

        Assert.IsTrue(Workflow.IsEmpty, NoWorkflowShouldExistErr);
        Assert.IsTrue(WorkflowStep.IsEmpty, NoWorkflowStepShouldExistErr);
        Assert.IsTrue(WorkflowStepArgument.IsEmpty, NoWorkflowStepArgumentsShouldExistErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestArchiveWorkflowActiveInstance()
    var
        Workflow: Record Workflow;
        IncomingDocument: Record "Incoming Document";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        InstanceGuid: Guid;
    begin
        // [SCENARIO 3] When the user wants to archive all instances of a worfklow, all the steps of those instances will be archived.
        // [GIVEN] There is a workflow instance.
        // [WHEN] The user archives the active instance.
        // [THEN] All the steps of that instance will be archived.

        Initialize();

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();
        CreateWorkflow(Workflow);

        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsTrue(WorkflowStepInstance.FindFirst(), SetupFailedErr);
        InstanceGuid := WorkflowStepInstance.ID;

        // Execute
        WorkflowStepInstance.ArchiveActiveInstances(Workflow);

        // Validate
        Clear(WorkflowStepInstance);
        WorkflowStepInstance.SetRange(ID, InstanceGuid);
        Assert.RecordIsEmpty(WorkflowStepInstance);
        WorkflowStepInstanceArchive.SetRange(ID, InstanceGuid);
        Assert.RecordIsNotEmpty(WorkflowStepInstanceArchive);
    end;

    [Test]
    [HandlerFunctions('PageHandlerWorkflow')]
    [Scope('OnPrem')]
    procedure TestUserCanViewActiveInstancesOfWorkflow()
    var
        Workflow: Record Workflow;
        IncomingDocument: Record "Incoming Document";
        WorkflowPage: TestPage Workflow;
    begin
        // [SCENARIO 4] The user can view all the active instances of a workflow definition, from the workflow card, and the
        // Workflow Step Instances action changes the enabled state based on existing records in the DB.
        // [GIVEN] There is an workflow definition and one active instance of the workflow.
        // [WHEN] The user navigates to the active workflow instances page.
        // [THEN] The Workflow Step Instances action is disabled.
        // [WHEN] The user creates one or more Incoming Documents.
        // [WHEN] The user navigates to the active workflow instances page.
        // [THEN] The Workflow Step Instances action is enabled.
        // [THEN] The user can see all the active instances.
        Initialize();

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();
        CreateWorkflow(Workflow);

        WorkflowPage.OpenView();
        WorkflowPage.GotoRecord(Workflow);

        // Validate
        Assert.IsFalse(WorkflowPage.WorkflowStepInstances.Enabled(), 'The action should be disabled.');
        WorkflowPage.Close();

        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Validate
        WorkflowPage.OpenView();
        WorkflowPage.GotoRecord(Workflow);
        Assert.IsTrue(WorkflowPage.WorkflowStepInstances.Enabled(), 'The action should be enabled.');

        // Execute
        WorkflowPage.WorkflowStepInstances.Invoke();

        // Validate
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowCannotBeDeletedWhenActiveInstancesExist()
    var
        IncomingDocument: Record "Incoming Document";
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        ResponseStep: Integer;
    begin
        // [SCENARIO] When there are active workflow instances, the workflow template cannot be deleted.
        // [GIVEN] There is a workflow starting from Incoming Document, and there is an instance of a workflow.
        // [WHEN] The user wants to delete the workflow template.
        // [THEN] The workflow cannot be deleted because there are existing workflow instances.
        Initialize();

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();

        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        ResponseStep := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            EntryPointEventStep);

        LibraryWorkflow.InsertNotificationArgument(ResponseStep, UserId, 0, '');

        LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(), ResponseStep);

        EnableWorkflow(Workflow);

        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        DisableWorkflow(Workflow);

        // Execute;
        asserterror Workflow.Delete(true);

        // Validate
        Assert.ExpectedError(WorkflowHasActiveInstancesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestDeleteArchivedSteps()
    var
        IncomingDocument: Record "Incoming Document";
        Workflow: Record Workflow;
        WorkflowStepArgumentArchive: Record "Workflow Step Argument Archive";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ArchivedWFStepInstances: TestPage "Archived WF Step Instances";
        EntryPointEventStep: Integer;
    begin
        // [SCENARIO] After a workflow was completed, the user wants delete all the archived steps of a workflow.
        // [GIVEN] There is a workflow starting from Incoming Document and a completed workflow instance.
        // [WHEN] The user wants to delete all the workflow archived steps and chooses 'Yes' on the confirm dialog.
        // [THEN] The achived workflow steps will be deleted.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();

        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        LibraryWorkflow.InsertEventArgument(EntryPointEventStep, 'Dummy conditions');

        EnableWorkflow(Workflow);

        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        Assert.RecordIsNotEmpty(WorkflowStepInstanceArchive);

        DisableWorkflow(Workflow);

        Workflow.Delete(true);
        Assert.RecordIsNotEmpty(WorkflowStepArgumentArchive);

        // Execute
        ArchivedWFStepInstances.OpenView();
        ArchivedWFStepInstances.DeleteArchive.Invoke();

        // Validate
        Assert.RecordIsEmpty(WorkflowStepInstanceArchive);
        Assert.RecordIsEmpty(WorkflowStepArgumentArchive);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestDoNotDeleteArchivedSteps()
    var
        IncomingDocument: Record "Incoming Document";
        Workflow: Record Workflow;
        WorkflowStepArgumentArchive: Record "Workflow Step Argument Archive";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ArchivedWFStepInstances: TestPage "Archived WF Step Instances";
        WorkflowPage: TestPage Workflow;
        EntryPointEventStep: Integer;
    begin
        // [SCENARIO] After a workflow was completed, the user wants to delete all the archived steps of a workflow.
        // [GIVEN] There is a workflow starting from Incoming Document and a completed workflow instance.
        // [WHEN] The user wants to delete all the workflow archived steps, but chooses 'No' on the confirm dialog.
        // [THEN] The achived workflow steps will not be deleted.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();

        LibraryWorkflow.CreateWorkflow(Workflow);

        // Validate
        WorkflowPage.OpenView();
        WorkflowPage.GotoRecord(Workflow);
        Assert.IsFalse(WorkflowPage.ArchivedWorkflowStepInstances.Enabled(), 'The action should be disabled.');
        WorkflowPage.Close();

        EntryPointEventStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        LibraryWorkflow.InsertEventArgument(EntryPointEventStep, 'Dummy conditions');

        EnableWorkflow(Workflow);

        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        Assert.RecordIsNotEmpty(WorkflowStepInstanceArchive);

        // Validate
        WorkflowPage.OpenView();
        WorkflowPage.GotoRecord(Workflow);
        Assert.IsTrue(WorkflowPage.ArchivedWorkflowStepInstances.Enabled(), 'The action should be enabled.');
        WorkflowPage.Close();

        DisableWorkflow(Workflow);

        Workflow.Delete(true);
        Clear(WorkflowStepArgumentArchive);
        Assert.RecordIsNotEmpty(WorkflowStepArgumentArchive);

        // Execute;
        ArchivedWFStepInstances.OpenView();
        ArchivedWFStepInstances.DeleteArchive.Invoke();

        // Validate
        Assert.RecordIsNotEmpty(WorkflowStepInstanceArchive);
        Assert.RecordIsNotEmpty(WorkflowStepArgumentArchive);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestArchiveWorkflowArchivesRecordChanges()
    var
        Customer: array[3] of Record Customer;
        Workflow: Record Workflow;
        WorkflowRule: Record "Workflow Rule";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowRecordChangeArchive: Record "Workflow Record Change Archive";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepArgumentArchive: Record "Workflow Step Argument Archive";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EntryPointEventStep: Integer;
        ResponseStep: Integer;
    begin
        // [SCENARIO] After a workflow was completed, record changes are also archived.
        // [GIVEN] There is a workflow starting from Customer Changed and existing record changes.
        // [WHEN] The workflow is completed.
        // [THEN] The workflow steps will be archived and so will be the record changes.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();
        LibraryRandom.Init();
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        LibraryWorkflow.InsertEventRule(EntryPointEventStep, 20, WorkflowRule.Operator::Changed);
        ResponseStep := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.RevertValueForFieldCode(),
            EntryPointEventStep);
        LibraryWorkflow.InsertRecChangeValueArgument(ResponseStep, DATABASE::Customer, 20);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ApplyNewValuesCode(), ResponseStep);
        EnableWorkflow(Workflow);

        // Bug: 437824
        MockWorkflowRecordChangeArchive();

        LibrarySales.CreateCustomer(Customer[1]);
        Customer[2].TransferFields(Customer[1]);
        Customer[2]."Credit Limit (LCY)" := LibraryRandom.RandDec(100, 2);
        Customer[2].Modify();

        LibrarySales.CreateCustomer(Customer[1]);
        Customer[3].TransferFields(Customer[1]);
        Customer[3]."Credit Limit (LCY)" := LibraryRandom.RandDec(100, 2);
        Customer[3].Modify();

        // Exercise
        Assert.RecordCount(WorkflowStepArgument, 2);

        WorkflowEventHandling.RunWorkflowOnCustomerChanged(Customer[1], Customer[2], false);
        WorkflowEventHandling.RunWorkflowOnCustomerChanged(Customer[1], Customer[3], false);

        // Verify
        WorkflowStepInstance.Reset();
        Assert.RecordIsEmpty(WorkflowStepInstance);
        Assert.RecordIsEmpty(WorkflowRecordChange);
        Assert.RecordCount(WorkflowStepArgument, 2);
        Assert.RecordCount(WorkflowStep, 3);

        Assert.RecordCount(WorkflowStepInstanceArchive, 6);
        Assert.RecordCount(WorkflowRecordChangeArchive, 2);
        Assert.RecordCount(WorkflowStepArgumentArchive, 4);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    local procedure CreateWorkflow(var Workflow: Record Workflow)
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        OnCreateIncDocEventID: Integer;
        CreateNotifResponseID: Integer;
        PmtLineCreatedEventID: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        OnCreateIncDocEventID :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        CreateNotifResponseID := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            OnCreateIncDocEventID);

        PmtLineCreatedEventID :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertGeneralJournalLineCode(),
            CreateNotifResponseID);
        LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), PmtLineCreatedEventID);

        LibraryWorkflow.InsertNotificationArgument(CreateNotifResponseID, UserId, 0, '');

        EnableWorkflow(Workflow);
    end;

    local procedure EnableWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Enabled := true;
        Workflow.Modify(true);
    end;

    local procedure DisableWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Enabled := false;
        Workflow.Modify(true);
    end;

    local procedure MockWorkflowRecordChangeArchive()
    var
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowRecordChangeArchive: Record "Workflow Record Change Archive";
    begin
        WorkflowRecordChange."Field Caption" := WorkflowRecordChange.FieldCaption("Entry No.");
        WorkflowRecordChange."Field No." := WorkflowRecordChange.FieldNo("Entry No.");
        WorkflowRecordChange."Old Value" := '0';
        WorkflowRecordChange."New Value" := '1';
        WorkflowRecordChange.Insert(true);
        WorkflowRecordChange.FindLast();

        WorkflowRecordChangeArchive.Init();
        WorkflowRecordChangeArchive.TransferFields(WorkflowRecordChange);
        WorkflowRecordChangeArchive."Entry No." += 1;
        WorkflowRecordChangeArchive.Insert();

        WorkflowRecordChange.Delete();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PageHandlerWorkflow(var WorkflowStepInstances: TestPage "Workflow Step Instances")
    begin
        WorkflowStepInstances.First();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

