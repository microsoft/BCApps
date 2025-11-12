codeunit 134211 "WF Demo Vendor Approval"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Approval]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';
        NoApprovalCommentExistsErr: Label 'There is no approval comment for this approval entry.';
        ApprovalCommentWasNotDeletedErr: Label 'The approval comment for this approval entry was not deleted.';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;
        WorkflowStepInstanceExistsErr: Label 'There are not completed Workflow Step Instances';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SendVendorForApprovalTest()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 1] A user can send a newly created Vendor for approval.
        // [GIVEN] A new  Vendor.
        // [WHEN] The user send an approval request from the Vendor.
        // [THEN] The Approval flow gets started.

        // Setup
        Initialize();

        SendVendorForApproval(Workflow, Vendor, VendorCard);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Vendor.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Vendor);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelVendorApprovalRequestTest()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 2] A user can cancel a approval request.
        // [GIVEN] Existing approval.
        // [WHEN] The user cancel a approval request.
        // [THEN] The Approval flow is canceled.

        // Setup
        Initialize();

        SendVendorForApproval(Workflow, Vendor, VendorCard);

        // Exercise
        VendorCard.CancelApprovalRequest.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Vendor.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Canceled, Vendor);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RenameVendorAfterApprovalRequestTest()
    var
        Vendor: Record Vendor;
        NewVendor: Record Vendor;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        VendorCard: TestPage "Vendor Card";
        NewVendorNo: Text;
    begin
        // [SCENARIO 9] A user can rename a Vendor after they send it for approval and the approval requests
        // still point to the same record.
        // [GIVEN] Existing approval.
        // [WHEN] The user renames a Vendor.
        // [THEN] The approval entries are renamed to point to the same record.

        // Setup
        Initialize();

        SendVendorForApproval(Workflow, Vendor, VendorCard);

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Vendor.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Vendor);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise - Create a new Vendor and delete it to reuse the Vendor No.
        LibraryPurchase.CreateVendor(NewVendor);
        NewVendorNo := NewVendor."No.";
        NewVendor.Delete(true);
        Vendor.Rename(NewVendorNo);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, NewVendor.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Vendor);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteVendorAfterApprovalRequestTest()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepInstance: Record "Workflow Step Instance";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 8] A user can delete a Vendor and the existing approval requests will be canceled and then deleted.
        // [GIVEN] Existing approval.
        // [WHEN] The user deletes the Vendor.
        // [THEN] The Vendor approval requests are canceled and then the Vendor is deleted.

        // Setup
        Initialize();

        SendVendorForApproval(Workflow, Vendor, VendorCard);
        VendorCard.OK().Invoke();

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Vendor.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Vendor);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise
        Vendor.Delete(true);

        // Verify
        Assert.IsTrue(ApprovalEntry.IsEmpty, 'There are still approval entries for the record');
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
        Assert.IsFalse(ApprovalCommentExists(ApprovalEntry), ApprovalCommentWasNotDeletedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure VendorApprovalActionsVisibilityOnCardTest()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] Vendor approval disabled.
        Initialize();

        // [WHEN] Vendor card is opened.
        LibraryPurchase.CreateVendor(Vendor);
        Commit();
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(VendorCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(VendorCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror VendorCard.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        VendorCard.Close();

        // [GIVEN] Vendor approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorWorkflowCode());

        // [WHEN] Vendor card is opened.
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(VendorCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(VendorCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(VendorCard.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(VendorCard.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(VendorCard.Delegate.Visible(), 'Delegate should NOT be visible');
        VendorCard.Close();

        // [GIVEN] Approval exist on Vendor.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [WHEN] Vendor send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        VendorCard.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(VendorCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(VendorCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        VendorCard.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Vendor.RecordId);

        // [WHEN] Vendor card is opened.
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [THEN] Approval action are shown.
        Assert.IsTrue(VendorCard.Approve.Visible(), 'Approve should be visible');
        Assert.IsTrue(VendorCard.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(VendorCard.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure VendorApprovalActionsVisibilityOnListTest()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        VendorList: TestPage "Vendor List";
    begin
        // [SCENARIO 4] Approval action availability.
        // [GIVEN] Vendor approval disabled.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [WHEN] Vendor card is opened.
        LibraryPurchase.CreateVendor(Vendor);
        Commit();
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(VendorList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(VendorList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror VendorList.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        VendorList.Close();

        // [GIVEN] Vendor approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorWorkflowCode());

        // [WHEN] Vendor card is opened.
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(VendorList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(VendorList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        VendorList.Close();

        // [GIVEN] Approval exist on Vendor.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [WHEN] Vendor send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        VendorList.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(VendorList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(VendorList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
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
    procedure ApproveVendorTest()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 5] A user can approve a Vendor approval.
        // [GIVEN] A Vendor Approval.
        // [WHEN] The user approves a request for Vendor approval.
        // [THEN] The Vendor gets approved.
        Initialize();

        SendVendorForApproval(Workflow, Vendor, VendorCard);
        VendorCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Vendor.RecordId);

        // Exercise
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.Approve.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Vendor.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Approved, Vendor);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RejectVendorTest()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 6] A user can reject a Vendor approval.
        // [GIVEN] A Vendor Approval.
        // [WHEN] The user rejects a request for Vendor approval.
        // [THEN] The Vendor gets rejected.
        Initialize();

        SendVendorForApproval(Workflow, Vendor, VendorCard);
        VendorCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Vendor.RecordId);

        // Exercise
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.Reject.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Vendor.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Rejected, Vendor);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DelegateVendorTest()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        CurrentUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 7] A user can delegate a Vendor approval.
        // [GIVEN] A Vendor Approval.
        // [WHEN] The user delegates a request for Vendor approval.
        // [THEN] The Vendor gets assigned to the substitute.
        Initialize();

        // Setup
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, ApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, ApproverUserSetup);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorWorkflowCode());
        LibraryPurchase.CreateVendor(Vendor);

        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.SendApprovalRequest.Invoke();
        VendorCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Vendor.RecordId);

        // Exercise
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.Delegate.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Vendor.RecordId);
        ApprovalEntry.TestField("Approver ID", ApproverUserSetup."User ID");
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Vendor);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApproveVendorWithNotificationTest()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        UserSetup: array[3] of Record "User Setup";
        WorkflowStepArgument: Record "Workflow Step Argument";
        VendorCard: TestPage "Vendor Card";
        i: Integer;
    begin
        // [SCENARIO 230496] A notification can be send after vendor approval
        Initialize();

        // [GIVEN] A Vendor Approval Workflow "W".
        LibraryWorkflow.CopyWorkflow(Workflow, WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.VendorWorkflowCode()));

        // [GIVEN] Group of 3 Approvers for "W"
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(Workflow, UserSetup[1], UserSetup[2], UserSetup[3]);
        LibraryDocumentApprovals.SetWorkflowApproverType(Workflow, WorkflowStepArgument."Approver Type"::"Workflow User Group");

        // [GIVEN] Insert Send Notification Workflow Step into "W"
        InsertCreateNotificationEntryWorkflowStepIntoVendorApprovalWorkflow(Workflow.Code, UserSetup[3]."User ID");

        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Send Vendor Approval Request
        LibraryPurchase.CreateVendor(Vendor);
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.SendApprovalRequest.Invoke();
        VendorCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(Vendor.RecordId);

        // [WHEN] All users approves a request for Vendor approval.
        for i := 1 to 2 do begin
            VendorCard.OpenEdit();
            VendorCard.GotoRecord(Vendor);
            VendorCard.Approve.Invoke();
            VendorCard.Close();
        end;

        // [THEN] "W" completes successfully, no Workflow Step Instances left
        VerifyNoWorkflowStepInstanceLeft(Workflow.Code);

        // [THEN] The Vendor gets approved.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Vendor.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Approved, Vendor);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorApprovalWorkflowSalesPersonPurchaserApprovalType()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        ApprovalEntry: Record "Approval Entry";
        ApprovalUserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        WorkflowSetup: Codeunit "Workflow Setup";
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Workflow] [Workflow User Group]
        // [SCENARIO 428471] Vendor Approval Workflow for ApproverType = Salesperson/Purchaser shows no error.
        Initialize();

        // [GIVEN] Vendor "V1".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.SetRecFilter();

        // [GIVEN] SalesPerson "SP"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] Vendor Approval Workflow "WF" where Approver Type set as "Salesperson/Purchaser'"
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorWorkflowCode());
        LibraryWorkflow.DisableAllWorkflows();
        LibraryDocumentApprovals.SetWorkflowApproverType(Workflow, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser");
        ApprovalUserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        ApprovalUserSetup.Modify(true);

        // [GIVEN] "WF" is enabled.
        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Vendor Purchaser Code = SP
        Vendor.Validate("Purchaser Code", SalespersonPurchaser.Code);
        Vendor.Modify(true);

        // [WHEN] Vendor is sent for approval
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.SendApprovalRequest.Invoke();

        // [THEN] No error appears
        // [THEN] Approval Entry has Status::Open.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, Vendor.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, Vendor);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure SendVendorForApproval(var Workflow: Record Workflow; var Vendor: Record Vendor; var VendorCard: TestPage "Vendor Card")
    var
        ApprovalUserSetup: Record "User Setup";
    begin
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorWorkflowCode());

        // Setup - an existing approval
        LibraryPurchase.CreateVendor(Vendor);
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.SendApprovalRequest.Invoke();
    end;

    local procedure VerifyApprovalEntry(ApprovalEntry: Record "Approval Entry"; Status: Enum "Approval Status"; Vendor: Record Vendor)
    begin
        ApprovalEntry.TestField("Document Type", ApprovalEntry."Document Type"::" ");
        ApprovalEntry.TestField("Document No.", '');
        ApprovalEntry.TestField("Record ID to Approve", Vendor.RecordId);
        ApprovalEntry.TestField(Status, Status);
        ApprovalEntry.TestField("Currency Code", Vendor."Currency Code");
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
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        if IsInitialized then
            exit;

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    local procedure InsertCreateNotificationEntryWorkflowStepIntoVendorApprovalWorkflow(WorkflowCode: Code[20]; UserID: Code[50])
    var
        WorkflowStep: Record "Workflow Step";
        PreviousWorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowStepID: Integer;
    begin
        PreviousWorkflowStep.SetRange("Workflow Code", WorkflowCode);
        PreviousWorkflowStep.SetRange(Type, PreviousWorkflowStep.Type::Response);
        PreviousWorkflowStep.SetRange("Function Name", WorkflowResponseHandling.SendApprovalRequestForApprovalCode());
        PreviousWorkflowStep.FindFirst();

        WorkflowStep.Validate("Workflow Code", WorkflowCode);
        WorkflowStep.Validate(Type, WorkflowStep.Type::Response);
        WorkflowStep.Validate("Function Name", WorkflowResponseHandling.CreateNotificationEntryCode());
        WorkflowStep.Validate("Sequence No.", PreviousWorkflowStep."Sequence No.");
        WorkflowStep.Validate("Previous Workflow Step ID", PreviousWorkflowStep.ID);
        WorkflowStep.Insert(true);

        WorkflowStepID := WorkflowStep.ID;
        LibraryWorkflow.InsertNotificationArgument(WorkflowStepID, UserID, 0, '');

        WorkflowStep.Reset();
        WorkflowStep.SetFilter(ID, StrSubstNo('<>%1', WorkflowStepID));
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        WorkflowStep.SetRange("Previous Workflow Step ID", PreviousWorkflowStep.ID);
        WorkflowStep.ModifyAll("Previous Workflow Step ID", WorkflowStepID, true);
    end;

    local procedure VerifyNoWorkflowStepInstanceLeft(WorkflowCode: Code[20])
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        WorkflowStepInstance.SetRange("Workflow Code", WorkflowCode);
        Assert.AreEqual(0, WorkflowStepInstance.Count, WorkflowStepInstanceExistsErr);
    end;
}

