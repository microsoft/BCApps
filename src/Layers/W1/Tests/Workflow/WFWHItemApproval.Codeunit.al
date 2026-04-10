codeunit 134214 "WFWH Item Approval"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Workflow Webhook Entry" = imd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Approval] [Item]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        BogusUserIdTxt: Label 'Contoso';
        DynamicRequestPageParametersItemTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Item">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>', Locked = true;
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure MakeCurrentUserAnApprover()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(BogusUserIdTxt) then begin
            UserSetup.Init();
            UserSetup."User ID" := BogusUserIdTxt;
            UserSetup."Approver ID" := UserId;
            UserSetup.Insert(true);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveBogusUser()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(BogusUserIdTxt) then
            UserSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNecessaryTableRelationsAreSetup()
    var
        DummyItem: Record Item;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowTableRelation: Record "Workflow - Table Relation";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] Ensure that the necessary webhook item approval workflow table relations are setup.
        // [WHEN] Workflow setup is initialized.
        // [THEN] Workflow table relations for item and workflow webhook entry exist.

        // Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();

        // Excercise
        WorkflowSetup.InitWorkflow();

        // Verify
        WorkflowTableRelation.Get(
          DATABASE::Item, DummyItem.FieldNo(SystemId),
          DATABASE::"Workflow Webhook Entry", DummyWorkflowWebhookEntry.FieldNo("Data ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNewItemCanBeSentForApproval()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        Item: Record Item;
    begin
        // [SCENARIO] A user can send a newly created item for approval.
        // [GIVEN] A new  Item.
        // [WHEN] The user send an approval request from the item.
        // [THEN] The Approval flow gets started.

        // Setup
        Initialize();
        CreateAndEnableItemWorkflowDefinition(UserId);

        // Exercise - New Item
        LibraryInventory.CreateItem(Item);

        // Exercise - Send for approval
        SendItemForApproval(Item);

        // Verify
        VerifyWorkflowWebhookEntryResponse(Item.SystemId, DummyWorkflowWebhookEntry.Response::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureItemApprovalWorkflowFunctionsCorrectlyWhenContinued()
    var
        Item: Record Item;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook item approval workflow 'approval' path works correctly.
        // [GIVEN] A webhook item approval workflow for a item is enabled.
        // [GIVEN] A item request is pending approval.
        // [WHEN] The webhook item approval workflow receives an 'approval' response for the item request.
        // [THEN] The item request is approved.

        // Setup
        Initialize();
        CreateAndEnableItemWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();
        LibraryInventory.CreateItem(Item);

        // Setup - A approval
        SendItemForApproval(Item);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Item.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Item.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(Item.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureItemApprovalWorkflowFunctionsCorrectlyWhenCancelled()
    var
        Item: Record Item;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook item approval workflow 'cancellation' path works correctly.
        // [GIVEN] A webhook item approval workflow for a item is enabled.
        // [GIVEN] A item request is pending approval.
        // [WHEN] The webhook item approval workflow receives a 'cancellation' response for the item request.
        // [THEN] The item request is cancelled.

        // Setup
        Initialize();
        CreateAndEnableItemWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();
        LibraryInventory.CreateItem(Item);

        // Setup - A approval
        SendItemForApproval(Item);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Item.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.CancelByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Item.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(Item.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureItemApprovalWorkflowFunctionsCorrectlyWhenRejected()
    var
        Item: Record Item;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] Ensure that a webhook item approval workflow 'rejection' path works correctly.
        // [GIVEN] A webhook item approval workflow for a item is enabled.
        // [GIVEN] A item request is pending approval.
        // [WHEN] The webhook item approval workflow receives a 'rejection' response for the item request.
        // [THEN] The item request is rejected.

        // Setup
        Initialize();
        CreateAndEnableItemWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();
        LibraryInventory.CreateItem(Item);

        // Setup - A approval
        SendItemForApproval(Item);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Item.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        WorkflowWebhookManagement.RejectByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Item.SystemId));

        // Verify
        VerifyWorkflowWebhookEntryResponse(Item.SystemId, DummyWorkflowWebhookEntry.Response::Reject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureItemApprovalWorkflowFunctionsCorrectlyWhenItemIsRenamed()
    var
        Item: Record Item;
        NewItem: Record Item;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        // [SCENARIO] A user can rename a item after they send it for approval and the approval requests
        // still points to the same record.
        // [GIVEN] Existing approval.
        // [WHEN] The user renames a item.
        // [THEN] The approval entries are renamed to point to the same record.

        // Setup
        Initialize();
        CreateAndEnableItemWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();

        // Setup - an existing approval
        LibraryInventory.CreateItem(Item);
        SendItemForApproval(Item);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Item.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise - Create a new item and delete it to reuse the item No.
        LibraryInventory.CreateItem(NewItem);
        NewItem.Delete(true);
        Item.Rename(NewItem."No.");

        // Verify - Request is approved since approval entry renamed to point to same record
        WorkflowWebhookManagement.ContinueByStepInstanceId(GetPendingWorkflowStepInstanceIdFromDataId(Item.SystemId));
        VerifyWorkflowWebhookEntryResponse(Item.SystemId, DummyWorkflowWebhookEntry.Response::Continue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureItemApprovalWorkflowFunctionsCorrectlyWhenItemIsDeleted()
    var
        Item: Record Item;
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowCode: Code[20];
    begin
        // [SCENARIO] A user can delete a item and the existing approval requests will be canceled.
        // [GIVEN] Existing approval.
        // [WHEN] The user deletes the item.
        // [THEN] The item approval requests are canceled and then the item is deleted.

        // Setup
        Initialize();
        WorkflowCode := CreateAndEnableItemWorkflowDefinition(UserId);
        MakeCurrentUserAnApprover();

        // Setup - an existing approval
        LibraryInventory.CreateItem(Item);
        SendItemForApproval(Item);

        Commit();

        // Verify
        VerifyWorkflowWebhookEntryResponse(Item.SystemId, DummyWorkflowWebhookEntry.Response::Pending);

        // Exercise
        Item.Delete(true);

        // Verify
        VerifyWorkflowWebhookEntryResponse(Item.SystemId, DummyWorkflowWebhookEntry.Response::Cancel);
        WorkflowStepInstance.SetRange("Workflow Code", WorkflowCode);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingApprovalOnItemCard()
    var
        Item: Record Item;
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        WebhookHelper: Codeunit "Webhook Helper";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Item Card page while Flow approval is pending.
        Initialize();

        // [GIVEN] Item record exists, with enabled workflow and a Flow approval request already open.
        LibraryInventory.CreateItem(Item);
        Commit();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemWorkflowCode());
        WebhookHelper.CreatePendingFlowApproval(Item.RecordId);

        // [WHEN] Item card is opened.
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(ItemCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(ItemCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ButtonStatusForPendingApprovalOnItemList()
    var
        Item: Record Item;
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        WebhookHelper: Codeunit "Webhook Helper";
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO] Approval actions are correctly enabled/disabled on Item List page while Flow approval is pending.
        Initialize();

        // [GIVEN] v record exists, with enabled workflow and a Flow approval request already open.
        LibraryInventory.CreateItem(Item);
        Commit();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemWorkflowCode());
        WebhookHelper.CreatePendingFlowApproval(Item.RecordId);

        // [WHEN] Item list is opened.
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);

        // [THEN] Cancel is enabled and Send is disabled.
        Assert.IsFalse(ItemList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(ItemList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        ItemList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnItemCard()
    var
        Item: Record Item;
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Item Card page
        Initialize();

        // [GIVEN] Item record exists, with a Flow approval request already open.
        LibraryInventory.CreateItem(Item);
        Commit();
        WebhookHelper.CreatePendingFlowApproval(Item.RecordId);

        // [WHEN] Item card is opened and Cancel button is clicked.
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelButtonWorksOnItemList()
    var
        Item: Record Item;
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WebhookHelper: Codeunit "Webhook Helper";
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO] Clicking cancel action to cancel pending Flow approval on Item List page
        Initialize();

        // [GIVEN] Item record exists, with a Flow approval request already open.
        LibraryInventory.CreateItem(Item);
        Commit();
        WebhookHelper.CreatePendingFlowApproval(Item.RecordId);

        // [WHEN] Item list is opened and Cancel button is clicked.
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);
        ItemList.CancelApprovalRequest.Invoke();

        // [THEN] Workflow Webhook Entry record is cancelled
        WorkflowWebhookEntry.FindFirst();
        Assert.AreEqual(WorkflowWebhookEntry.Response::Cancel, WorkflowWebhookEntry.Response, 'Approval request should be cancelled.');

        // Cleanup
        ItemList.Close();
    end;

    local procedure SendItemForApproval(var Item: Record Item)
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard.SendApprovalRequest.Invoke();
        ItemCard.Close();
    end;

    local procedure Initialize()
    var
        ClearWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        UserSetup: Record "User Setup";
    begin
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        ClearWorkflowWebhookEntry.DeleteAll();
        RemoveBogusUser();
        if IsInitialized then
            exit;
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        BindSubscription(MockOnFindTaskSchedulerAllowed);
    end;

    local procedure CreateAndEnableItemWorkflowDefinition(ResponseUserID: Code[50]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        WorkflowCode: Code[20];
    begin
        WorkflowCode :=
          WorkflowWebhookSetup.CreateWorkflowDefinition(WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode(),
            '', DynamicRequestPageParametersItemTxt, ResponseUserID);
        Workflow.Get(WorkflowCode);
        LibraryWorkflow.EnableWorkflow(Workflow);
        exit(WorkflowCode);
    end;

    local procedure GetPendingWorkflowStepInstanceIdFromDataId(Id: Guid): Guid
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry.SetFilter("Data ID", Id);
        WorkflowWebhookEntry.SetFilter(Response, '=%1', WorkflowWebhookEntry.Response::Pending);
        WorkflowWebhookEntry.FindFirst();

        exit(WorkflowWebhookEntry."Workflow Step Instance ID");
    end;

    local procedure VerifyWorkflowWebhookEntryResponse(Id: Guid; ResponseArgument: Option)
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry.SetCurrentKey("Data ID");
        WorkflowWebhookEntry.SetRange("Data ID", Id);
        WorkflowWebhookEntry.FindFirst();

        WorkflowWebhookEntry.TestField(Response, ResponseArgument);
    end;
}

