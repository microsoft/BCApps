codeunit 134213 "WF Demo Item Unit Pri Approval"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = m;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Approval] [Item] [Unit Price]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();

        UserSetup.DeleteAll();
        if IsInitialized then
            exit;

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestItemUnitPriceChangeApprovalWorkflow()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Item: Record Item;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowSetup: Codeunit "Workflow Setup";
        NewUnitPrice: Decimal;
    begin
        // [SCENARIO 1] Test that the Item unit price Change Approval Workflow approval path works with a group of 3 users.
        // [GIVEN] The Item unit price Change Approval Workflow is enabled.
        // [WHEN] A user sends the Item unit price change for approval and all users in the group of approvals approve the document.
        // [THEN] The Item unit price change is approved and applied.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Excercise - Open Item card and sent the unit price change for approval
        NewUnitPrice := LibraryRandom.RandDec(1000, 2);
        CreateItemAndChangeUnitPriceAndSendForApproval(Item, NewUnitPrice);

        // Verify - Record change for the Item record was created
        VerifyChangeRecordExists(Item);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Item, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Item);

        // Excercise - Open Item card and approve the unit price change
        ApproveItemUnitPriceChange(Item);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Item, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Open Item card and approve the unit price change
        ApproveItemUnitPriceChange(Item);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Item, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);

        // Verify - Record change for the Item was deleted
        VerifyChangeRecordDoesNotExist(Item);

        // Verify - The new unit price was applied for the record
        VerifyUnitPriceForItem(Item, NewUnitPrice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestItemUnitPriceChangeApprovalWorkflowRejectionPathFirstApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Item: Record Item;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowSetup: Codeunit "Workflow Setup";
        NewUnitPrice: Decimal;
        OldUnitPrice: Decimal;
    begin
        // [SCENARIO 3] Test that the Item unit price Change Approval Workflow rejection path works with a group of 3 users.
        // [GIVEN] The Item unit price Change Approval Workflow is enabled.
        // [WHEN] A user sends the Item unit price change for approval and the first approver rejects it.
        // [THEN] The Item unit price change is rejected and deleted.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Excercise - Open Item card and sent the unit price change for approval
        NewUnitPrice := LibraryRandom.RandDec(1000, 2);
        OldUnitPrice := CreateItemAndChangeUnitPriceAndSendForApproval(Item, NewUnitPrice);

        // Verify - Record change for the Item record was created
        VerifyChangeRecordExists(Item);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Item, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Item);

        // Excercise - Open Item card and reject the unit price change
        RejectItemUnitPriceChange(Item);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Item, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);

        // Verify - Record change for the Item was deleted
        VerifyChangeRecordDoesNotExist(Item);

        // Verify - The new unit price was not applied for the record
        VerifyUnitPriceForItem(Item, OldUnitPrice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestItemUnitPriceChangeApprovalWorkflowDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Item: Record Item;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowSetup: Codeunit "Workflow Setup";
        NewUnitPrice: Decimal;
    begin
        // [SCENARIO 4] Test that the Item unit price Change Approval Workflow delegation path works with a group of 3 users and one delegate.
        // [GIVEN] The Item unit price Change Approval Workflow is enabled.
        // [WHEN] A user sends the Item unit price change for approval and the second user delegates the approval to the 3rd user and the last user approves it.
        // [THEN] The Item unit price change is approved and applied.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Excercise - Open Item card and sent the unit price change for approval
        NewUnitPrice := LibraryRandom.RandDec(1000, 2);
        CreateItemAndChangeUnitPriceAndSendForApproval(Item, NewUnitPrice);

        // Verify - Record change for the Item record was created
        VerifyChangeRecordExists(Item);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Item, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Item);

        // Excercise - Open Item card and approve the unit price change
        ApproveItemUnitPriceChange(Item);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Item, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Open Item card and delegate the unit price change
        DelegateItemUnitPriceChange(Item);

        // Exercise - Set the approver id
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Item);

        // Excercise - Open Item card and approve the unit price change
        ApproveItemUnitPriceChange(Item);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Item, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);

        // Verify - Record change for the Item was deleted
        VerifyChangeRecordDoesNotExist(Item);

        // Verify - The new unit price was applied for the record
        VerifyUnitPriceForItem(Item, NewUnitPrice);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestItemUnitPriceChangeApprovalActionsVisibilityOnCardTest()
    var
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        Item: Record Item;
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowChange: Record Workflow;
        WorkflowApproval: Record Workflow;
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowSetup: Codeunit "Workflow Setup";
        ItemCard: TestPage "Item Card";
        OldValue: Decimal;
    begin
        // [SCENARIO 5] Approval action availability.
        // [GIVEN] Item approval workflow and Item unit price change approval workflow are disabled.
        Initialize();

        // [WHEN] Item card is opened.
        LibraryInventory.CreateItem(Item);
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [THEN] Send and Cancel are disabled.
        Assert.IsFalse(ItemCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsFalse(ItemCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // Cleanup
        ItemCard.Close();

        // [GIVEN] Item unit price change approval workflow and Item approval workflow are enabled.
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowChange, WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowApproval, WorkflowSetup.ItemWorkflowCode());
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowChange.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowApproval.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(WorkflowChange);
        LibraryWorkflow.EnableWorkflow(WorkflowApproval);

        // [WHEN] Item card is opened.
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(ItemCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(ItemCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(ItemCard.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(ItemCard.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(ItemCard.Delegate.Visible(), 'Delegate should NOT be visible');
        ItemCard.Close();

        // [WHEN] Item card is opened.
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [WHEN] Item unit price (LCY) is changed.
        LibraryVariableStorage.Enqueue('The item unit price change was sent for approval.');
        Evaluate(OldValue, ItemCard."Unit Price".Value);
        ItemCard."Unit Price".Value := Format(OldValue + 100);
        ItemCard.OK().Invoke();

        // [THEN] The record change was created.
        WorkflowRecordChange.SetRange("Record ID", Item.RecordId);
        Assert.IsFalse(WorkflowRecordChange.IsEmpty, 'WorkflowRecordChange should not be empty');

        // [WHEN] Item card is opened.
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(ItemCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(ItemCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [THEN] Approval action are not shown.
        Assert.IsFalse(ItemCard.Approve.Visible(), 'Approve should be visible');
        Assert.IsFalse(ItemCard.Reject.Visible(), 'Reject should be visible');
        Assert.IsFalse(ItemCard.Delegate.Visible(), 'Delegate should be visible');

        // Clenup
        ItemCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure TestItemUnitPriceChangeApprovalActionsVisibilityOnListTest()
    var
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        Item: Record Item;
        WorkflowChange: Record Workflow;
        WorkflowApproval: Record Workflow;
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowRecordChange: Record "Workflow - Record Change";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        WorkflowSetup: Codeunit "Workflow Setup";
        ItemList: TestPage "Item List";
        ItemCard: TestPage "Item Card";
        OldValue: Decimal;
    begin
        // [SCENARIO 6] Approval action availability.
        // [GIVEN] Item approval workflow and Item unit price change approval workflow are disabled.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [WHEN] Item card is opened.
        LibraryInventory.CreateItem(Item);
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);

        // [THEN] Only Send is enabled.
        Assert.IsFalse(ItemList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsFalse(ItemList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // Cleanup
        ItemList.Close();

        // [GIVEN] Item unit price change approval workflow and Item approval workflow are enabled.
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowChange, WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowApproval, WorkflowSetup.ItemWorkflowCode());
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowChange.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowApproval.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(WorkflowChange);
        LibraryWorkflow.EnableWorkflow(WorkflowApproval);

        // [WHEN] Item list is opened.
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(ItemList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(ItemList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        ItemList.Close();

        // [WHEN] Item unit price (LCY) is changed.
        LibraryVariableStorage.Enqueue('The item unit price change was sent for approval.');
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        Evaluate(OldValue, ItemCard."Unit Price".Value);
        ItemCard."Unit Price".Value := Format(OldValue + 100);
        ItemCard.OK().Invoke();

        // [THEN] The record change was created.
        WorkflowRecordChange.SetRange("Record ID", Item.RecordId);
        Assert.IsFalse(WorkflowRecordChange.IsEmpty, 'WorkflowRecordChange should not be empty');

        // [GIVEN] Approval exist on Item.
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(ItemList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(ItemList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        ItemList.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestMultipleItemUnitPriceChangeApprovalWorkflow()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Item: Record Item;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowSetup: Codeunit "Workflow Setup";
        RequeststoApprovePage: TestPage "Requests to Approve";
        NewUnitPrice: Decimal;
    begin
        // [SCENARIO 7] Test that the Item unit price Change Approval Workflow approval path works when multiple requests are made for the same Item.
        // [GIVEN] The Item unit price Change Approval Workflow is enabled.
        // [WHEN] A user sends 3 Item unit price changes for approval and all users in the group of approvals approve the 2nd request.
        // [THEN] The 2nd Item unit price change is approved and applied.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Excercise - Open Item card and send the unit price change for approval
        CreateItemAndChangeUnitPriceAndSendForApproval(Item, LibraryRandom.RandDecInRange(1, 1000, 2));
        NewUnitPrice := LibraryRandom.RandDecInRange(1000, 2000, 2);
        ChangeUnitPriceAndSendForApproval(Item, NewUnitPrice);
        ChangeUnitPriceAndSendForApproval(Item, LibraryRandom.RandDecInRange(2000, 3000, 2));

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Item);

        // Approve the middle approval entry
        // find the workflow instance from the change record
        WorkflowRecordChange.SetFilter("Record ID", '%1', Item.RecordId);
        WorkflowRecordChange.SetRange("Table No.", DATABASE::Item);
        WorkflowRecordChange.SetRange("Field No.", Item.FieldNo("Unit Price"));
        WorkflowRecordChange.SetRange("New Value", Format(NewUnitPrice, 0, 9));
        WorkflowRecordChange.FindFirst();
        // find the approval entry from the workflow instance
        ApprovalEntry.SetFilter("Record ID to Approve", '%1', Item.RecordId);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowRecordChange."Workflow Step Instance ID");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.FindFirst();
        // goto the approval entry and approve
        RequeststoApprovePage.OpenView();
        RequeststoApprovePage.GotoRecord(ApprovalEntry);
        RequeststoApprovePage.Approve.Invoke();
        // find the next approval entry (there were 3, 1 auto-approved, 1 approved just above and this last one)
        ApprovalEntry.FindFirst();
        RequeststoApprovePage.GotoRecord(ApprovalEntry);
        RequeststoApprovePage.Approve.Invoke();
        // close the page
        RequeststoApprovePage.OK().Invoke();

        // verify that the Item now has the correct unit price set.
        Item.Get(Item."No.");
        Assert.AreEqual(NewUnitPrice, Item."Unit Price", 'Correct unit price (LCY) was not set');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestItemUnitPriceChangeAndItemApprovalWorkflowRejection()
    var
        WorkflowUnitPrice: Record Workflow;
        WorkflowItemApproval: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Item: Record Item;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowRecordChangeArchive: Record "Workflow Record Change Archive";
        WorkflowSetup: Codeunit "Workflow Setup";
        NewUnitPrice: Decimal;
    begin
        // [SCENARIO 8] Test that rejecting a unit price change approval does not cancel a Item approval.
        // [GIVEN] A Item unit price Change Approval Workflow and a Item Approval Workflow are enabled.
        // [WHEN] A user sends the Item unit price change for approval, sends the Item for approval and then rejects the Item unit price change approval.
        // [THEN] The Item unit price change is rejected, but the Item approval is not impacted.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowUnitPrice, WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowItemApproval, WorkflowSetup.ItemWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsWithApproversAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowUnitPrice.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(WorkflowUnitPrice);
        LibraryWorkflow.EnableWorkflow(WorkflowItemApproval);

        // Excercise - Open Item card and sent the unit price change for approval
        NewUnitPrice := LibraryRandom.RandDec(1000, 2);
        CreateItemAndChangeUnitPriceAndSendForApproval(Item, NewUnitPrice);

        // Exercise - Send Item For Approval
        SendItemForApproval(Item);

        // Verify - Record change for the Item record was created
        VerifyChangeRecordExists(Item);

        // Verify - Approval requests number
        ApprovalEntry.SetRange("Record ID to Approve", Item.RecordId);
        Assert.AreEqual(4, ApprovalEntry.Count, 'Unexpected number of approval entries was created.');

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Item);

        // Excercise - Open Item card and reject the unit price change
        RejectItemUnitPriceChange(Item);

        // Verify - Not all Approval requests were rejected
        WorkflowRecordChangeArchive.SetRange("Record ID", Item.RecordId);
        WorkflowRecordChangeArchive.FindFirst();
        ApprovalEntry.SetRange("Record ID to Approve", Item.RecordId);
        ApprovalEntry.SetFilter("Workflow Step Instance ID", '<>%1', WorkflowRecordChangeArchive."Workflow Step Instance ID");
        ApprovalEntry.SetFilter(Status, '<>%1', ApprovalEntry.Status::Rejected);
        Assert.IsFalse(ApprovalEntry.IsEmpty, 'Not all approvals should be rejected.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestItemUnitPriceChangeAndItemApprovalWorkflowCancelation()
    var
        WorkflowUnitPrice: Record Workflow;
        WorkflowItemApproval: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Item: Record Item;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        NewUnitPrice: Decimal;
    begin
        // [SCENARIO 9] Test that canceling a Item approval workflow does not cancel a unit price change approval.
        // [GIVEN] A Item unit price Change Approval Workflow and a Item Approval Workflow are enabled.
        // [WHEN] A user sends the Item unit price change for approval, sends the Item for approval and then cancels the Item approval.
        // [THEN] The Item approval is canceled, but the unit price change approval is not impacted.

        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowItemApproval, WorkflowSetup.ItemWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowUnitPrice, WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsWithApproversAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowUnitPrice.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(WorkflowItemApproval);
        LibraryWorkflow.EnableWorkflow(WorkflowUnitPrice);

        // Excercise - Open Item card and sent the unit price change for approval
        NewUnitPrice := LibraryRandom.RandDec(1000, 2);
        CreateItemAndChangeUnitPriceAndSendForApproval(Item, NewUnitPrice);

        CheckUserCanCancelTheApprovalRequest(Item, false);

        // Exercise - Send Item For Approval
        SendItemForApproval(Item);

        CheckUserCanCancelTheApprovalRequest(Item, true);

        // Verify - Record change for the Item record was created
        VerifyChangeRecordExists(Item);

        // Verify - Approval requests number
        ApprovalEntry.SetRange("Record ID to Approve", Item.RecordId);
        Assert.AreEqual(4, ApprovalEntry.Count, 'Unexpected number of approval entries was created.');

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Item);

        // Excercise - Open Item card and cancel the unit price change
        CancelItemApproval(Item);

        // Verify - Not correct Approval requests were rejected
        WorkflowRecordChange.SetRange("Record ID", Item.RecordId);
        WorkflowRecordChange.FindFirst();
        ApprovalEntry.SetRange("Record ID to Approve", Item.RecordId);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowRecordChange."Workflow Step Instance ID");
        ApprovalEntry.SetFilter(Status, '<>%1', ApprovalEntry.Status::Canceled);
        Assert.IsFalse(ApprovalEntry.IsEmpty, 'Not all approvals should be canceled.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestItemUnitPriceChangeAndItemApprovalWorkflowCancelationApprovalAdmin()
    var
        WorkflowUnitPrice: Record Workflow;
        WorkflowItemApproval: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Item: Record Item;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        NewUnitPrice: Decimal;
    begin
        // [SCENARIO 9] Test that canceling a Item approval workflow does not cancel a unit price change approval.
        // [GIVEN] A Item unit price Change Approval Workflow and a Item Approval Workflow are enabled.
        // [WHEN] A user sends the Item unit price change for approval, sends the Item for approval and then cancels the Item approval.
        // [THEN] The Item approval is canceled, but the unit price change approval is not impacted.

        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowUnitPrice, WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(WorkflowItemApproval, WorkflowSetup.ItemWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsWithApproversAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(WorkflowUnitPrice.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(WorkflowUnitPrice);
        LibraryWorkflow.EnableWorkflow(WorkflowItemApproval);

        // Excercise - Open Item card and sent the unit price change for approval
        NewUnitPrice := LibraryRandom.RandDec(1000, 2);
        CreateItemAndChangeUnitPriceAndSendForApproval(Item, NewUnitPrice);

        CheckUserCanCancelTheApprovalRequest(Item, false);

        // Exercise - Send Item For Approval
        SendItemForApproval(Item);

        // Verify - Record change for the Item record was created
        VerifyChangeRecordExists(Item);

        CheckUserCanCancelTheApprovalRequest(Item, true);

        // Verify - Approval requests number
        ApprovalEntry.SetRange("Record ID to Approve", Item.RecordId);
        Assert.AreEqual(4, ApprovalEntry.Count, 'Unexpected number of approval entries was created.');

        // Excercise - Set the user to be an approval admin
        LibraryDocumentApprovals.SetAdministrator(CurrentUserSetup);
        CheckUserCanCancelTheApprovalRequest(Item, true);

        // Excercise - Open Item card and cancel the unit price change
        CancelItemApproval(Item);

        // Verify - Not correct Approval requests were rejected
        WorkflowRecordChange.SetRange("Record ID", Item.RecordId);
        WorkflowRecordChange.FindFirst();
        ApprovalEntry.SetRange("Record ID to Approve", Item.RecordId);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowRecordChange."Workflow Step Instance ID");
        ApprovalEntry.SetFilter(Status, '<>%1', ApprovalEntry.Status::Canceled);
        Assert.IsFalse(ApprovalEntry.IsEmpty, 'Not all approvals should be canceled.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestItemUnitPriceChangeApprovalWorkflowWithComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        Item: Record Item;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowSetup: Codeunit "Workflow Setup";
        NewUnitPrice: Decimal;
    begin
        // [SCENARIO 1] Test that the Item unit price Change Approval Workflow approval path works with a group of 3 users.
        // [GIVEN] The Item unit price Change Approval Workflow is enabled.
        // [WHEN] A user sends the Item unit price change for approval and all users in the group of approvals approve the document.
        // [THEN] The Item unit price change is approved and applied.

        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode());

        // Setup - Create 3 user setups, create workflow user group and set the group for the workflow
        CreateUserSetupsAndGroupOfApproversForWorkflow(WorkflowUserGroup, CurrentUserSetup,
          IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.SetWorkflowGroupApprover(Workflow.Code, WorkflowUserGroup.Code);
        LibraryWorkflow.EnableWorkflow(Workflow);

        // Excercise - Open Item card and sent the unit price change for approval
        NewUnitPrice := LibraryRandom.RandDec(1000, 2);
        CreateItemAndChangeUnitPriceAndSendForApproval(Item, NewUnitPrice);

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        ApprovalEntry.Next();
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 0);

        // Verify - Record change for the Item record was created
        VerifyChangeRecordExists(Item);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Item, 3, CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID", FinalApproverUserSetup."User ID", ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, Item);

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        ApprovalEntry.Next();
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 0);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 0);

        // Excercise - Open Item card and approve the unit price change
        ApproveItemUnitPriceChange(Item);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Item, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Excercise - Open Item card and approve the unit price change
        ApproveItemUnitPriceChange(Item);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(Item, 3, CurrentUserSetup."Approver ID", CurrentUserSetup."User ID", CurrentUserSetup."User ID",
          CurrentUserSetup."User ID", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);

        // Verify - Record change for the Item was deleted
        VerifyChangeRecordDoesNotExist(Item);

        // Verify - The new unit price was applied for the record
        VerifyUnitPriceForItem(Item, NewUnitPrice);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerValidateMessage(Message: Text[1024])
    var
        Variant: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        Assert.ExpectedMessage(Variant, Message)
    end;

    local procedure CreateUserSetupsAndGroupOfApproversForWorkflow(var WorkflowUserGroup: Record "Workflow User Group"; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        WorkflowUserGroup.Code := LibraryUtility.GenerateRandomCode(WorkflowUserGroup.FieldNo(Code), DATABASE::"Workflow User Group");
        WorkflowUserGroup.Description := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        WorkflowUserGroup.Insert(true);

        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, CurrentUserSetup."User ID", 1);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, IntermediateApproverUserSetup."User ID", 2);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, FinalApproverUserSetup."User ID", 3);
    end;

    local procedure CreateUserSetupsWithApproversAndGroupOfApproversForWorkflow(var WorkflowUserGroup: Record "Workflow User Group"; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, IntermediateApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        WorkflowUserGroup.Code := LibraryUtility.GenerateRandomCode(WorkflowUserGroup.FieldNo(Code), DATABASE::"Workflow User Group");
        WorkflowUserGroup.Description := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        WorkflowUserGroup.Insert(true);

        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, CurrentUserSetup."User ID", 1);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, IntermediateApproverUserSetup."User ID", 2);
        LibraryDocumentApprovals.CreateWorkflowUserGroupMember(WorkflowUserGroup.Code, FinalApproverUserSetup."User ID", 3);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure CreateItemAndChangeUnitPriceAndSendForApproval(var Item: Record Item; NewUnitPrice: Decimal) OldValue: Decimal
    begin
        LibraryInventory.CreateItem(Item);
        OldValue := ChangeUnitPriceAndSendForApproval(Item, NewUnitPrice);
    end;

    local procedure SendItemForApproval(Item: Record Item)
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard.SendApprovalRequest.Invoke();
    end;

    local procedure ChangeUnitPriceAndSendForApproval(var Item: Record Item; NewUnitPrice: Decimal) OldValue: Decimal
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);

        Evaluate(OldValue, ItemCard."Unit Price".Value);

        ItemCard."Unit Price".Value(Format(NewUnitPrice));
        ItemCard.OK().Invoke();
    end;

    local procedure ApproveItemUnitPriceChange(var Item: Record Item)
    var
        ApprovalEntry: Record "Approval Entry";
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        ApprovalEntry.SetRange("Table ID", DATABASE::Item);
        ApprovalEntry.SetRange("Record ID to Approve", Item.RecordId);
        ApprovalEntry.SetRange("Related to Change", true);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.FindFirst();

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Approve.Invoke();
        RequeststoApprove.Close();
    end;

    local procedure RejectItemUnitPriceChange(var Item: Record Item)
    var
        ApprovalEntry: Record "Approval Entry";
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        ApprovalEntry.SetRange("Table ID", DATABASE::Item);
        ApprovalEntry.SetRange("Record ID to Approve", Item.RecordId);
        ApprovalEntry.SetRange("Related to Change", true);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.FindFirst();

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Reject.Invoke();
        RequeststoApprove.Close();
    end;

    local procedure CancelItemApproval(var Item: Record Item)
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);
        ItemCard.CancelApprovalRequest.Invoke();
        ItemCard.Close();
    end;

    local procedure DelegateItemUnitPriceChange(var Item: Record Item)
    var
        ApprovalEntry: Record "Approval Entry";
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        ApprovalEntry.SetRange("Table ID", DATABASE::Item);
        ApprovalEntry.SetRange("Record ID to Approve", Item.RecordId);
        ApprovalEntry.SetRange("Related to Change", true);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.FindFirst();

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);
        RequeststoApprove.Delegate.Invoke();
        RequeststoApprove.Close();
    end;

    local procedure UpdateApprovalEntryWithTempUser(UserSetup: Record "User Setup"; Item: Record Item)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;

    local procedure VerifyApprovalEntry(ApprovalEntry: Record "Approval Entry"; SenderId: Code[50]; ApproverId: Code[50]; Status: Enum "Approval Status")
    begin
        ApprovalEntry.TestField("Sender ID", SenderId);
        ApprovalEntry.TestField("Approver ID", ApproverId);
        ApprovalEntry.TestField(Status, Status);
    end;

    local procedure VerifyApprovalRequests(Item: Record Item; ExpectedNumberOfApprovalEntries: Integer; SenderUserID: Code[50]; ApproverUserID1: Code[50]; ApproverUserID2: Code[50]; ApproverUserID3: Code[50]; Status1: Enum "Approval Status"; Status2: Enum "Approval Status"; Status3: Enum "Approval Status")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        Assert.AreEqual(ExpectedNumberOfApprovalEntries, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID1, Status1);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID2, Status2);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID3, Status3);
    end;

    local procedure VerifyChangeRecordExists(Item: Record Item)
    var
        WorkflowRecordChange: Record "Workflow - Record Change";
    begin
        WorkflowRecordChange.SetRange("Record ID", Item.RecordId);
        Assert.IsFalse(WorkflowRecordChange.IsEmpty, 'The record change was not created');
    end;

    local procedure VerifyChangeRecordDoesNotExist(Item: Record Item)
    var
        WorkflowRecordChange: Record "Workflow - Record Change";
    begin
        WorkflowRecordChange.SetRange("Record ID", Item.RecordId);
        Assert.IsTrue(WorkflowRecordChange.IsEmpty, 'The record change was not deleted');
    end;

    local procedure VerifyUnitPriceForItem(Item: Record Item; UnitPrice: Decimal)
    begin
        Item.Find();
        Assert.AreEqual(UnitPrice, Item."Unit Price", 'The unit price was not applied');
    end;

    local procedure CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry: Record "Approval Entry"; NumberOfExpectedComments: Integer)
    var
        ApprovalComments: TestPage "Approval Comments";
        ApprovalEntries: TestPage "Approval Entries";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        ApprovalEntries.OpenView();
        ApprovalEntries.GotoRecord(ApprovalEntry);

        ApprovalEntries.Comments.Invoke();
        if ApprovalComments.First() then
            repeat
                NumberOfComments += 1;
            until ApprovalComments.Next();
        Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

        ApprovalComments.Close();

        ApprovalEntries.Close();
    end;

    local procedure CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry: Record "Approval Entry"; NumberOfExpectedComments: Integer)
    var
        ApprovalComments: TestPage "Approval Comments";
        RequeststoApprove: TestPage "Requests to Approve";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        RequeststoApprove.OpenView();
        RequeststoApprove.GotoRecord(ApprovalEntry);

        RequeststoApprove.Comments.Invoke();
        if ApprovalComments.First() then
            repeat
                NumberOfComments += 1;
            until ApprovalComments.Next();
        Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

        ApprovalComments.Close();

        RequeststoApprove.Close();
    end;

    local procedure CheckUserCanCancelTheApprovalRequest(Item: Record Item; CancelActionExpectedEnabled: Boolean)
    var
        ItemCard: TestPage "Item Card";
        ItemList: TestPage "Item List";
    begin
        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);
        Assert.AreEqual(CancelActionExpectedEnabled, ItemCard.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        ItemCard.Close();

        ItemList.OpenView();
        ItemList.GotoRecord(Item);
        Assert.AreEqual(CancelActionExpectedEnabled, ItemList.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        ItemList.Close();
    end;
}

