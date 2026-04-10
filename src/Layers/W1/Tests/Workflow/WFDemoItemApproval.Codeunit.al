codeunit 134212 "WF Demo Item Approval"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Approval] [Item]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';
        NoApprovalCommentExistsErr: Label 'There is no approval comment for this approval entry.';
        ApprovalCommentWasNotDeletedErr: Label 'The approval comment for this approval entry was not deleted.';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SendItemForApprovalTest()
    var
        Item: Record Item;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 1] A user can send a newly created Item for approval.
        // [GIVEN] A new  Item.
        // [WHEN] The user send an approval request from the Item.
        // [THEN] The Approval flow gets started.

        // Setup
        Initialize();

        SendItemForApproval(Workflow, Item, ItemCard);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Item);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelItemApprovalRequestTest()
    var
        Item: Record Item;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 2] A user can cancel a approval request.
        // [GIVEN] Existing approval.
        // [WHEN] The user cancel a approval request.
        // [THEN] The Approval flow is canceled.

        // Setup
        Initialize();

        SendItemForApproval(Workflow, Item, ItemCard);

        // Exercise
        ItemCard.CancelApprovalRequest.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Canceled, Item);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RenameItemAfterApprovalRequestTest()
    var
        Item: Record Item;
        NewItem: Record Item;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ItemCard: TestPage "Item Card";
        NewItemNo: Text;
    begin
        // [SCENARIO 9] A user can rename a Item after they send it for approval and the approval requests
        // still point to the same record.
        // [GIVEN] Existing approval.
        // [WHEN] The user renames a Item.
        // [THEN] The approval entries are renamed to point to the same record.

        // Setup
        Initialize();

        SendItemForApproval(Workflow, Item, ItemCard);

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Item);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise - Create a new Item and delete it to reuse the Item No.
        LibraryInventory.CreateItem(NewItem);
        NewItemNo := NewItem."No.";
        NewItem.Delete(true);
        Item.Rename(NewItemNo);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Item);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteItemAfterApprovalRequestTest()
    var
        Item: Record Item;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepInstance: Record "Workflow Step Instance";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 8] A user can delete a Item and the existing approval requests will be canceled and then deleted.
        // [GIVEN] Existing approval.
        // [WHEN] The user deletes the Item.
        // [THEN] The Item approval requests are canceled and then the Item is deleted.

        // Setup
        Initialize();

        SendItemForApproval(Workflow, Item, ItemCard);
        ItemCard.OK().Invoke();

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Item);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise
        Item.Delete(true);

        // Verify
        Assert.IsTrue(ApprovalEntry.IsEmpty, 'There are still approval entries for the record');
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
        Assert.IsFalse(ApprovalCommentExists(ApprovalEntry), ApprovalCommentWasNotDeletedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure ItemApprovalActionsVisibilityOnCardTest()
    var
        Item: Record Item;
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] Item approval disabled.
        Initialize();

        // [WHEN] Item card is opened.
        LibraryInventory.CreateItem(Item);
        Commit();
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [THEN] Send and Cancel are disabled.
        Assert.IsFalse(ItemCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsFalse(ItemCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // Cleanup
        ItemCard.Close();

        // [GIVEN] Item approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemWorkflowCode());

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

        // [GIVEN] Approval exist on Item.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [WHEN] Item send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        ItemCard.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(ItemCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(ItemCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        ItemCard.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Item.RecordId);

        // [WHEN] Item card is opened.
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [THEN] Approval action are shown.
        Assert.IsTrue(ItemCard.Approve.Visible(), 'Approve should be visible');
        Assert.IsTrue(ItemCard.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(ItemCard.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure ItemApprovalActionsVisibilityOnListTest()
    var
        Item: Record Item;
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        ItemList: TestPage "Item List";
    begin
        // [SCENARIO 4] Approval action availability.
        // [GIVEN] Item approval disabled.
        Initialize();

        // [WHEN] Item card is opened.
        LibraryInventory.CreateItem(Item);
        Commit();
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);

        // [THEN] Only Send is enabled.
        Assert.IsFalse(ItemList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsFalse(ItemList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // Cleanup
        ItemList.Close();

        // [GIVEN] Item approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemWorkflowCode());

        // [WHEN] Item card is opened.
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(ItemList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(ItemList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        ItemList.Close();

        // [GIVEN] Approval exist on Item.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);

        // [WHEN] Item send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        ItemList.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(ItemList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(ItemList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
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

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApproveItemTest()
    var
        Item: Record Item;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 5] A user can approve a Item approval.
        // [GIVEN] A Item Approval.
        // [WHEN] The user approves a request for Item approval.
        // [THEN] The Item gets approved.
        Initialize();

        SendItemForApproval(Workflow, Item, ItemCard);
        ItemCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Item.RecordId);

        // Exercise
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard.Approve.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Approved, Item);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RejectItemTest()
    var
        Item: Record Item;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 6] A user can reject a Item approval.
        // [GIVEN] A Item Approval.
        // [WHEN] The user rejects a request for Item approval.
        // [THEN] The Item gets rejected.
        Initialize();

        SendItemForApproval(Workflow, Item, ItemCard);
        ItemCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Item.RecordId);

        // Exercise
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard.Reject.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Rejected, Item);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DelegateItemTest()
    var
        Item: Record Item;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        CurrentUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 7] A user can delegate a Item approval.
        // [GIVEN] A Item Approval.
        // [WHEN] The user delegates a request for Item approval.
        // [THEN] The Item gets assigned to the substitute.
        Initialize();

        // Setup
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, ApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, ApproverUserSetup);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemWorkflowCode());
        LibraryInventory.CreateItem(Item);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard.SendApprovalRequest.Invoke();
        ItemCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Item.RecordId);

        // Exercise
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard.Delegate.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Item.RecordId);
        ApprovalEntry.TestField("Approver ID", ApproverUserSetup."User ID");
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Item);
    end;

    local procedure SendItemForApproval(var Workflow: Record Workflow; var Item: Record Item; var ItemCard: TestPage "Item Card")
    var
        ApprovalUserSetup: Record "User Setup";
    begin
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.ItemWorkflowCode());

        LibraryInventory.CreateItem(Item);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard.SendApprovalRequest.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure VerifyApprovalEntry(ApprovalEntry: Record "Approval Entry"; Status: Enum "Approval Status"; Item: Record Item)
    begin
        ApprovalEntry.TestField("Document Type", ApprovalEntry."Document Type"::" ");
        ApprovalEntry.TestField("Document No.", '');
        ApprovalEntry.TestField("Record ID to Approve", Item.RecordId);
        ApprovalEntry.TestField(Status, Status);
    end;

    local procedure AddApprovalComment(ApprovalEntry: Record "Approval Entry")
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.Init();
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        ApprovalCommentLine.SetRange("Workflow Step Instance ID", ApprovalEntry."Workflow Step Instance ID");
        ApprovalCommentLine.Comment := 'Test';
        ApprovalCommentLine.Insert(true);
    end;

    local procedure ApprovalCommentExists(ApprovalEntry: Record "Approval Entry"): Boolean
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", ApprovalEntry."Table ID");
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        exit(ApprovalCommentLine.FindFirst())
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
    begin
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        if IsInitialized then
            exit;
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;
}

