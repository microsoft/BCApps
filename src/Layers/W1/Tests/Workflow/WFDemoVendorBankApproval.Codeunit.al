codeunit 134224 "WF Demo Vendor Bank Approval"
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
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        UnexpectedNoOfWorkflowStepInstancesErr: Label 'Unexpected number of workflow step instances found.';
        NoApprovalCommentExistsErr: Label 'There is no approval comment for this approval entry.';
        ApprovalCommentWasNotDeletedErr: Label 'The approval comment for this approval entry was not deleted.';
        IsInitialized: Boolean;
        WorkflowStepInstanceExistsErr: Label 'There are not completed Workflow Step Instances';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SendVendorBankForApprovalTest()
    var
        VendorBank: Record "Vendor Bank Account";
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        VendorBankCard: TestPage "Vendor Bank Account Card";
    begin
        // [SCENARIO 1] A user can send a newly created Vendor Bank for approval.
        // [GIVEN] A new  Vendor Bank.
        // [WHEN] The user send an approval request from the Vendor Bank.
        // [THEN] The Approval flow gets started.

        // Setup
        Initialize();

        SendVendorBankForUIApproval(Workflow, VendorBank, VendorBankCard);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, VendorBank.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, VendorBank);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelVendorBankApprovalRequestTest()
    var
        VendorBank: Record "Vendor Bank Account";
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        VendorBankCard: TestPage "Vendor Bank Account Card";
    begin
        // [SCENARIO 2] A user can cancel a approval request.
        // [GIVEN] Existing approval.
        // [WHEN] The user cancel a approval request.
        // [THEN] The Approval flow is canceled.

        // Setup
        Initialize();

        SendVendorBankForUIApproval(Workflow, VendorBank, VendorBankCard);

        // Exercise
        VendorBankCard.CancelApprovalRequest.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, VendorBank.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Canceled, VendorBank);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RenameVendorBankAfterApprovalRequestTest()
    var
        VendorBank: Record "Vendor Bank Account";
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        LibraryUtility: Codeunit "Library - Utility";
        NewVendorBankNo: Text;
    begin
        // [SCENARIO 3] A user can rename a Vendor Bank after they send it for approval and the approval requests
        // still point to the same record.
        // [GIVEN] Existing approval.
        // [WHEN] The user renames a Vendor Bank.
        // [THEN] The approval entries are renamed to point to the same record.

        // Setup
        Initialize();

        SendVendorBankForApproval(Workflow, VendorBank);

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, VendorBank.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Verify
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, VendorBank);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);

        // Exercise - Create a new Vendor Bank No.
        NewVendorBankNo :=
          CopyStr(LibraryUtility.GenerateRandomCode(VendorBank.FieldNo(Code), DATABASE::"Vendor Bank Account"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Vendor Bank Account", VendorBank.FieldNo(Code)));
        VendorBank.Rename(VendorBank."Vendor No.", NewVendorBankNo);

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, VendorBank.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, VendorBank);
        Assert.IsTrue(ApprovalCommentExists(ApprovalEntry), NoApprovalCommentExistsErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteVendorBankAfterApprovalRequestTest()
    var
        VendorBank: Record "Vendor Bank Account";
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO 4] A user can delete a Vendor Bank and the existing approval requests will be canceled and then deleted.
        // [GIVEN] Existing approval.
        // [WHEN] The user deletes the Vendor Bank.
        // [THEN] The Vendor Bank approval requests are canceled and then the Vendor Bank is deleted.

        // Setup
        Initialize();

        SendVendorBankForApproval(Workflow, VendorBank);

        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, VendorBank.RecordId);
        AddApprovalComment(ApprovalEntry);

        // Exercise
        VendorBank.Delete(true);

        // Verify
        Assert.IsTrue(ApprovalEntry.IsEmpty, 'There are still approval entries for the record');
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        Assert.IsTrue(WorkflowStepInstance.IsEmpty, UnexpectedNoOfWorkflowStepInstancesErr);
        Assert.IsFalse(ApprovalCommentExists(ApprovalEntry), ApprovalCommentWasNotDeletedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBankApprovalActionsOnCardTest()
    var
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        VendorBankCard: TestPage "Vendor Bank Account Card";
    begin
        // [SCENARIO 5] Approval action availability.
        // [GIVEN] Vendor Bank approval disabled.
        Initialize();

        // [WHEN] Vendor Bank card is opened.
        CreateVendorBankAccount(Vendor, VendorBank);
        Commit();
        VendorBankCard.OpenEdit();
        VendorBankCard.GotoRecord(VendorBank);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(VendorBankCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(VendorBankCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // Cleanup
        VendorBankCard.Close();

    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBankApprovalErrorOnNotEnabledCardTest()
    var
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        VendorBankCard: TestPage "Vendor Bank Account Card";
    begin
        // [SCENARIO 6] Approval workflow not enabled.
        // [GIVEN] Vendor Bank approval disabled.
        Initialize();

        // [WHEN] Send Approval Request is pushed.
        CreateVendorBankAccount(Vendor, VendorBank);
        Commit();
        VendorBankCard.OpenEdit();
        VendorBankCard.GotoRecord(VendorBank);
        asserterror VendorBankCard.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        VendorBankCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBankApprovalEnabledOnCardTest()
    var
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        Workflow: Record Workflow;
        VendorBankCard: TestPage "Vendor Bank Account Card";
    begin
        // [SCENARIO 7] Approval workflow enabled.
        // [GIVEN] Vendor Bank approval enabled.
        Initialize();

        // [WHEN] Vendor Bank card is opened.
        CreateVendorBankAccount(Vendor, VendorBank);
        Commit();
        VendorBankCard.OpenEdit();
        VendorBankCard.GotoRecord(VendorBank);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorBankWorkflowCode());

        // [THEN] Only Send is enabled.
        Assert.IsTrue(VendorBankCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(VendorBankCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(VendorBankCard.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(VendorBankCard.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(VendorBankCard.Delegate.Visible(), 'Delegate should NOT be visible');
        VendorBankCard.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure VendorBankApprovalExistsOnCardTest()
    var
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        VendorBankCard: TestPage "Vendor Bank Account Card";
    begin
        // [SCENARIO 8] Approval exits on Vendor Bank.
        // [GIVEN] Approval exist on Vendor Bank.
        Initialize();
        CreateVendorBankAccount(Vendor, VendorBank);
        Commit();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorBankWorkflowCode());
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        VendorBankCard.OpenEdit();
        VendorBankCard.GotoRecord(VendorBank);

        // [WHEN] Vendor Bank send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        VendorBankCard.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(VendorBankCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(VendorBankCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Cleanup
        VendorBankCard.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(VendorBank.RecordId);

        // [WHEN] Vendor Bank card is opened.
        VendorBankCard.OpenEdit();
        VendorBankCard.GotoRecord(VendorBank);

        // [THEN] Approval action are shown.
        Assert.IsTrue(VendorBankCard.Approve.Visible(), 'Approve should be visible');
        Assert.IsTrue(VendorBankCard.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(VendorBankCard.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure VendorBankApprovalActionsVisibilityOnListTest()
    var
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        VendorBankList: TestPage "Vendor Bank Account List";
    begin
        // [SCENARIO 9] Approval action availability.
        // [GIVEN] Vendor Bank approval disabled.
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        // [WHEN] Vendor Bank card is opened.
        CreateVendorBankAccount(Vendor, VendorBank);
        Commit();
        VendorBankList.OpenEdit();
        VendorBankList.GotoRecord(VendorBank);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(VendorBankList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(VendorBankList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror VendorBankList.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        VendorBankList.Close();

        // [GIVEN] Vendor Bank approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorBankWorkflowCode());

        // [WHEN] Vendor Bank card is opened.
        VendorBankList.OpenEdit();
        VendorBankList.GotoRecord(VendorBank);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(VendorBankList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(VendorBankList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        VendorBankList.Close();

        // [GIVEN] Approval exist on Vendor Bank.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        VendorBankList.OpenEdit();
        VendorBankList.GotoRecord(VendorBank);

        // [WHEN] Vendor Bank send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        VendorBankList.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(VendorBankList.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(VendorBankList.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerValidateMessage(Message: Text[1024])
    var
        Text: Text;
    begin
        Text := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(Text, Message)
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApproveVendorBankTest()
    var
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        VendorBankCard: TestPage "Vendor Bank Account Card";
    begin
        // [SCENARIO 10] A user can approve a Vendor Bank approval.
        // [GIVEN] A Vendor Bank Approval.
        // [WHEN] The user approves a request for Vendor Bank approval.
        // [THEN] The Vendor Bank gets approved.
        Initialize();

        CreateVendorBankAccount(Vendor, VendorBank);
        Commit();

        SendVendorBankForUIApproval(Workflow, VendorBank, VendorBankCard);
        VendorBankCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(VendorBank.RecordId);

        // Exercise
        VendorBankCard.OpenEdit();
        VendorBankCard.GotoRecord(VendorBank);
        VendorBankCard.Approve.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, VendorBank.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Approved, VendorBank);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RejectVendorTest()
    var
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        VendorBankCard: TestPage "Vendor Bank Account Card";
    begin
        // [SCENARIO 11] A user can reject a Vendor Bank approval.
        // [GIVEN] A Vendor Bank Approval.
        // [WHEN] The user rejects a request for Vendor Bank approval.
        // [THEN] The Vendor Bank gets rejected.
        Initialize();

        CreateVendorBankAccount(Vendor, VendorBank);
        Commit();

        SendVendorBankForUIApproval(Workflow, VendorBank, VendorBankCard);
        VendorBankCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(VendorBank.RecordId);

        // Exercise
        VendorBankCard.OpenEdit();
        VendorBankCard.GotoRecord(VendorBank);
        VendorBankCard.Reject.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, VendorBank.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Rejected, VendorBank);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DelegateVendorBankTest()
    var
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        CurrentUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        VendorBankCard: TestPage "Vendor Bank Account Card";
    begin
        // [SCENARIO 12] A user can delegate a Vendor Bank approval.
        // [GIVEN] A Vendor Bank Approval.
        // [WHEN] The user delegates a request for Vendor Bank approval.
        // [THEN] The Vendor Bank gets assigned to the substitute.
        Initialize();
        CreateVendorBankAccount(Vendor, VendorBank);
        Commit();

        // Setup
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, ApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, ApproverUserSetup);

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorBankWorkflowCode());

        VendorBankCard.OpenEdit();
        VendorBankCard.GotoRecord(VendorBank);
        VendorBankCard.SendApprovalRequest.Invoke();
        VendorBankCard.Close();

        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(VendorBank.RecordId);

        // Exercise
        VendorBankCard.OpenEdit();
        VendorBankCard.GotoRecord(VendorBank);
        VendorBankCard.Delegate.Invoke();

        // Verify
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, VendorBank.RecordId);
        ApprovalEntry.TestField("Approver ID", ApproverUserSetup."User ID");
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Open, VendorBank);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApproveVendorBankWithNotificationTest()
    var
        Vendor: Record Vendor;
        VendorBank: Record "Vendor Bank Account";
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        UserSetup: array[3] of Record "User Setup";
        WorkflowStepArgument: Record "Workflow Step Argument";
        VendorBankCard: TestPage "Vendor Bank Account Card";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        i: Integer;
    begin
        // [SCENARIO 13] A notification can be send after vendor bank approval
        Initialize();
        CreateVendorBankAccount(Vendor, VendorBank);
        Commit();

        // [GIVEN] A Vendor Bank Approval Workflow "W".
        LibraryWorkflow.CopyWorkflow(Workflow, WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.VendorBankWorkflowCode()));

        // [GIVEN] Group of 3 Approvers for "W"
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(Workflow, UserSetup[1], UserSetup[2], UserSetup[3]);
        LibraryDocumentApprovals.SetWorkflowApproverType(Workflow, WorkflowStepArgument."Approver Type"::"Workflow User Group");

        // [GIVEN] Insert Send Notification Workflow Step into "W"
        InsertCreateNotificationEntryWorkflowStepIntoVendorApprovalWorkflow(Workflow.Code, UserSetup[3]."User ID");

        LibraryWorkflow.EnableWorkflow(Workflow);

        // [GIVEN] Send Vendor Bank Approval Request
        ApprovalsMgmt.OnSendVendorBankAccountForApproval(VendorBank);


        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(VendorBank.RecordId);

        // [WHEN] All users approves a request for Vendor Bank approval.
        for i := 1 to 2 do begin
            VendorBankCard.OpenEdit();
            VendorBankCard.GotoRecord(VendorBank);
            VendorBankCard.Approve.Invoke();
            VendorBankCard.Close();
        end;

        // [THEN] "W" completes successfully, no Workflow Step Instances left
        VerifyNoWorkflowStepInstanceLeft(Workflow.Code);

        // [THEN] The Vendor Bank gets approved.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, VendorBank.RecordId);
        VerifyApprovalEntry(ApprovalEntry, ApprovalEntry.Status::Approved, VendorBank);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure CreateVendorBankAccount(var Vendor: Record Vendor; var VendorBank: Record "Vendor Bank Account")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBank, Vendor."No.");
    end;

    local procedure SendVendorBankForApproval(var Workflow: Record Workflow; var VendorBank: Record "Vendor Bank Account")
    var
        ApprovalUserSetup: Record "User Setup";
        Vendor: Record Vendor;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorBankWorkflowCode());

        // Setup - an existing approval
        CreateVendorBankAccount(Vendor, VendorBank);

        if ApprovalsMgmt.CheckVendorBankAccountApprovalsWorkflowEnabled(VendorBank) then
            ApprovalsMgmt.OnSendVendorBankAccountForApproval(VendorBank)
        else
            Error(NoWorkflowEnabledErr);
    end;

    local procedure SendVendorBankForUIApproval(var Workflow: Record Workflow; var VendorBank: Record "Vendor Bank Account"; var VendorBankCard: TestPage "Vendor Bank Account Card")
    var
        ApprovalUserSetup: Record "User Setup";
        Vendor: Record Vendor;
    begin
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorBankWorkflowCode());

        // Setup - an existing approval
        CreateVendorBankAccount(Vendor, VendorBank);
        VendorBankCard.OpenEdit();
        VendorBankCard.GotoRecord(VendorBank);
        VendorBankCard.SendApprovalRequest.Invoke();
    end;

    local procedure VerifyApprovalEntry(ApprovalEntry: Record "Approval Entry"; Status: Enum "Approval Status"; VendorBank: Record "Vendor Bank Account")
    begin
        ApprovalEntry.TestField("Document Type", ApprovalEntry."Document Type"::" ");
        ApprovalEntry.TestField("Document No.", '');
        ApprovalEntry.TestField("Record ID to Approve", VendorBank.RecordId);
        ApprovalEntry.TestField(Status, Status);
        ApprovalEntry.TestField("Currency Code", VendorBank."Currency Code");
    end;

    local procedure AddApprovalComment(ApprovalEntry: Record "Approval Entry")
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.Init();
        ApprovalCommentLine."Table ID" := ApprovalEntry."Table ID";
        ApprovalCommentLine."Record ID to Approve" := ApprovalEntry."Record ID to Approve";
        ApprovalCommentLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(ApprovalCommentLine."User ID"));
        ApprovalCommentLine."Date and Time" := CreateDateTime(Today, Time);
        ApprovalCommentLine."Entry No." := ApprovalCommentLine.GetLastEntryNo() + 1;
        ApprovalCommentLine.Comment := 'Test';
        ApprovalCommentLine.Insert(false);
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

