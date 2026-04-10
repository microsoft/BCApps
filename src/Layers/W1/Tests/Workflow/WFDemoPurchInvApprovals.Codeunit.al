codeunit 134179 "WF Demo Purch. Inv. Approvals"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = rimd,
                  TableData "Posted Approval Entry" = md;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Purchase] [Invoice]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        DocCannotBeReleasedErr: Label 'This document can only be released when the approval process is complete.';
        DocCannotBePostedErr: Label '%1 %2 must be approved and released before you can perform this action.', Comment = '%1 = PurchHeader."Document Type", %2 = PurchHeader."No."';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostPurchaseInvoice()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [SCENARIO] The user cannot post a purchase invoice when the approval workflow is enabled and the purchase invoice is not approved and released.
        // [GIVEN] There is a purchase invoice that is not approved and released.
        // [GIVEN] The approval workflow for puchase invoices is enabled.
        // [WHEN] The user wants to Post the purchase invoice.
        // [THEN] The user will get an error that he cannot post a purchase invoice that is not approved and released.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        PurchaseInvoices.OpenView();
        PurchaseInvoices.GotoRecord(PurchaseHeader);
        asserterror PurchaseInvoices.PostSelected.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocCannotBePostedErr, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseInvoice()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [SCENARIO] The user cannot release a purchase invoice when the approval workflow is enabled and the purchase invoice is not approved.
        // [GIVEN] There is a purchase invoice that is not approved.
        // [GIVEN] The approval workflow for puchase invoices is enabled.
        // [WHEN] The user wants to Release the purchase invoice.
        // [THEN] The user will get an error that he cannot release a purchase invoice that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        CreatePurchaseInvoice(PurchaseHeader);

        // Exercise
        PurchaseInvoices.OpenView();
        PurchaseInvoices.GotoRecord(PurchaseHeader);
        asserterror PurchaseInvoices.Release.Invoke();

        // Verify
        Assert.ExpectedError(DocCannotBeReleasedErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReleasePurchaseInvoiceApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [SCENARIO] The user cannot release a purchase invoice when the approval workflow is enabled and the purchase invoice is pending approval.
        // [GIVEN] There is a purchase invoice that is sent for approval.
        // [GIVEN] The approval workflow for puchase invoices is enabled.
        // [WHEN] The user wants to Release the purchase invoice.
        // [THEN] The user will get an error that he cannot release the purchase invoice that is not approved.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase invoice
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase invoice card and sent it for approval
        SendPurchaseInvoiceForApproval(PurchaseHeader);

        // Verify - Purchase invoice status is set to Pending Approval
        VerifyPurchaseInvIsPendingApproval(PurchaseHeader);

        // Exercise
        Commit();
        PurchaseInvoices.OpenView();
        PurchaseInvoices.GotoRecord(PurchaseHeader);
        asserterror PurchaseInvoices.Release.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(PurchaseHeader.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenPurchaseInvoiceApprovalIsPending()
    var
        Workflow: Record Workflow;
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [SCENARIO] The user cannot release a purchase invoice when the approval workflow is enabled and the purchase invoice is pending approval.
        // [GIVEN] There is a purchase invoice that is sent for approval.
        // [GIVEN] The approval workflow for puchase invoices is enabled.
        // [WHEN] The user wants to Reopen the purchase invoice.
        // [THEN] The user will get an error that he cannot reopen the purchase invoice.

        // Setup
        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase invoice
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase invoice card and sent it for approval
        SendPurchaseInvoiceForApproval(PurchaseHeader);

        // Verify - Purchase invoice status is set to Pending Approval
        VerifyPurchaseInvIsPendingApproval(PurchaseHeader);

        // Exercise
        PurchaseInvoices.OpenView();
        PurchaseInvoices.GotoRecord(PurchaseHeader);
        asserterror PurchaseInvoices.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceApprovalWorkflowOnApprovePath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase invoice approval workflow on approval path.
        // [GIVEN] Purchase Invoice Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Invoice is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Purchaser approves the approval request.
        // [THEN] Purchase Invoice is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase invoice
        CreatePurchInvWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase invoice card and sent it for approval
        SendPurchaseInvoiceForApproval(PurchHeader);

        // Verify - Purchase invoice status is set to Pending Approval
        VerifyPurchaseInvIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, 'Unexpected number of approval entries found');

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchae invoice card and approve the approval request
        ApprovePurchaseInvoice(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseInvIsReleased(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceApprovalWorkflowOnRejectionPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase invoice approval workflow on rejection path.
        // [GIVEN] Purchase Invoice Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Invoice is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Purchaser rejects the approval request.
        // [THEN] Purchase Invoice is reopened and approval entries are marked as rejected.

        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase invoice
        CreatePurchInvWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase invoice card and sent it for approval
        SendPurchaseInvoiceForApproval(PurchHeader);

        // Verify - Purchase invoice status is set to Pending Approval
        VerifyPurchaseInvIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, 'Unexpected number of approval entries found');

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchase invoice card and reject the approval request
        RejectPurchaseInvoice(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseInvIsOpen(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsRejected(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceApprovalWorkflowOnDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase invoice approval workflow on delegation path.
        // [GIVEN] Purchase Invoice Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Invoice is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Purchaser delegates the approval request.
        // [THEN] Approval request is assigned to the substitute.
        // [WHEN] Approval Request is approved.
        // [THEN] Purchase Invoice is released.

        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(IntermediateApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        // Setup - Chain of approvers
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, IntermediateApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Create purchase invoice
        CreatePurchInvWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase invoice card and sent it for approval
        SendPurchaseInvoiceForApproval(PurchHeader);

        // Verify - Purchase invoice status is set to Pending Approval
        VerifyPurchaseInvIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, 'Unexpected number of approval entries found');

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, CurrentUserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchae invoice card and delgate the approval request
        DelegatePurchaseInvoice(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseInvIsPendingApproval(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntryApproverID(ApprovalEntry, FinalApproverUserSetup."User ID");

        // Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // Excercise - Open Purchae invoice card and approve the approval request
        ApprovePurchaseInvoice(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseInvIsReleased(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceApprovalWorkflowOnCancellationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase invoice approval workflow on cancellation path.
        // [GIVEN] Purchase Invoice Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Invoice is sent for approval.
        // [THEN] Approval Request is created for the purchaser.
        // [WHEN] Sender cancels the approval request.
        // [THEN] Purchase Invoice is opend and approval requests are marked as cancelled.

        Initialize();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // Setup - Create 3 usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create purchase invoice
        CreatePurchInvWithLine(PurchHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase invoice card and sent it for approval
        SendPurchaseInvoiceForApproval(PurchHeader);

        // Verify - Purchase invoice status is set to Pending Approval
        VerifyPurchaseInvIsPendingApproval(PurchHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, 'Unexpected number of approval entries found');

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Excercise - Open Purchae invoice card and cancel the approval request
        CancelPurchaseInvoice(PurchHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseInvIsOpen(PurchHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceFullBusinessProcess()
    var
        Workflow: Record Workflow;
        IncomingDocument: Record "Incoming Document";
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        CurrentUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO] This test verifies E2E scenario for the purchase invoice approval and basic purchase invoice posting workflow.
        Initialize();
        // [GIVEN] Create sender's usersetup
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, UserId);

        // [GIVEN] Enable workflows: 'Incoming Document' and 'Purchase Invoice Approval'
        EnableIncDocWorkflow();
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        EnablePurchInvWorkflow();

        // [GIVEN] Create Incoming Document.
        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // [GIVEN] Genereated the Notification Entry for Incoming Document
        VerifyNotificationEntry(IncomingDocument.RecordId);

        // [GIVEN] Create Approver's usersetup and chain of approvers
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.SetApprover(CurrentUserSetup, ApproverUserSetup);

        // [GIVEN] Purchase Invoice created from the Incoming Document.
        CreatePurchInvWithLine(PurchHeader, LibraryRandom.RandInt(5000));
        PurchHeader.Validate("Incoming Document Entry No.", IncomingDocument."Entry No.");
        PurchHeader.Modify(true);

        // [GIVEN] Purchase Invoice Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        SetPurchDocPurchaserCode(PurchHeader, ApproverUserSetup."Salespers./Purch. Code");

        // [WHEN] Purchase Invoice is sent for approval.
        SendPurchaseInvoiceForApproval(PurchHeader);

        // [THEN] Approval Request is created for the purchaser.
        VerifyPurchaseInvIsPendingApproval(PurchHeader);

        // [WHEN] Purchaser approves the approval request.
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchHeader.RecordId);
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(PurchHeader.RecordId);

        // [THEN] A payment line is created.
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchHeader."No.");
        PurchInvHeader.FindFirst();

        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
        Assert.AreEqual(1, GenJournalLine.Count, 'Unexpected payment line.');
        GenJournalLine.FindFirst();

        // [THEN] Notification entry for the payment line.
        VerifyNotificationEntry(GenJournalLine.RecordId);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure PurchInvoiceApprovalActionsVisibilityOnCardTest()
    var
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] Purchase Header approval disabled.
        Initialize();

        // [WHEN] Purchase Header card is opened.
        CreatePurchaseInvoice(PurchHeader);
        Commit();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseInvoice.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseInvoice.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror PurchaseInvoice.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        PurchaseInvoice.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // [WHEN] PurchHeader card is opened.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseInvoice.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseInvoice.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(PurchaseInvoice.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(PurchaseInvoice.Reject.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(PurchaseInvoice.Delegate.Visible(), 'Delegate should NOT be visible');
        PurchaseInvoice.Close();

        // [GIVEN] Approval exist on PurchHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetPurchDocPurchaserCode(PurchHeader, ApproverUserSetup."Salespers./Purch. Code");
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        PurchaseInvoice.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(PurchaseInvoice.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseInvoice.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        PurchaseInvoice.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchHeader.RecordId);

        // [WHEN] PurchHeader card is opened.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchHeader);

        // [THEN] Approval action are shown.
        Assert.IsTrue(PurchaseInvoice.Approve.Visible(), 'Approva should be visible');
        Assert.IsTrue(PurchaseInvoice.Reject.Visible(), 'Reject should be visible');
        Assert.IsTrue(PurchaseInvoice.Delegate.Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure PurchInvoiceApprovalActionsVisibilityOnListTest()
    var
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] PurchHeader approval disabled.
        Initialize();

        // [WHEN] PurchHeader card is opened.
        CreatePurchaseInvoice(PurchHeader);
        Commit();
        PurchaseInvoices.OpenEdit();
        PurchaseInvoices.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseInvoices.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseInvoices.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror PurchaseInvoices.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        PurchaseInvoices.Close();

        // [GIVEN] PurchHeader approval enabled.
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // [WHEN] PurchHeader card is opened.
        PurchaseInvoices.OpenEdit();
        PurchaseInvoices.GotoRecord(PurchHeader);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(PurchaseInvoices.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(PurchaseInvoices.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        PurchaseInvoices.Close();

        // [GIVEN] Approval exist on PurchHeader.
        LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        SetPurchDocPurchaserCode(PurchHeader, ApproverUserSetup."Salespers./Purch. Code");
        PurchaseInvoices.OpenEdit();
        PurchaseInvoices.GotoRecord(PurchHeader);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        PurchaseInvoices.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(PurchaseInvoices.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(PurchaseInvoices.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithoutLinesCannotBeSentForApproval()
    var
        PurchHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Approval action for invoice without lines.
        // [GIVEN] Purchase Header with no lines.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '');
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        Commit();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchHeader);

        // [WHEN] Send Approval Request is pushed.
        asserterror PurchaseInvoice.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase invoice approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Purchase Invoice Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Invoice is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and the user can add a comment.
        // [WHEN] Purchaser approves the approval request.
        // [THEN] Purchase Invoice is released.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Purchase invoice
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, false);

        // Excercise - Open Purchase invoice card and sent it for approval
        SendPurchaseInvoiceForApproval(PurchaseHeader);

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, false);

        // Verify - Purchase invoice status is set to Pending Approval
        VerifyPurchaseInvIsPendingApproval(PurchaseHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);

        CheckCommentsForDocumentOnDocumentCard(PurchaseHeader, 0, true);
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Excercise - Open Purchase invoice card and approve the approval request
        ApprovePurchaseInvoice(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseInvIsReleased(PurchaseHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        VerifyApprovalEntryIsApproved(ApprovalEntry);
        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceApprovalWorkflowTestUserCanCancel()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        IntermediateApproverUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Purchase invoice approval workflow on cancellation path and whether a user can cancel the workflow or not.
        // [GIVEN] Purchase Invoice Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Purchase Invoice is sent for approval.
        // [THEN] Approval Request is created for the Purchaser and user can cancel the request.
        // [WHEN] Next approver opens the document.
        // [THEN] The user can only cancel the request if he is an approval administrator.

        Initialize();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // Setup - Create 3 approval usersetups
        LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create Purchase invoice
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandInt(5000));

        // Setup - Update Purchaser Code
        SetPurchDocPurchaserCode(PurchaseHeader, IntermediateApproverUserSetup."Salespers./Purch. Code");

        // Excercise - Open Purchase invoice card and sent it for approval
        SendPurchaseInvoiceForApproval(PurchaseHeader);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, true);

        // Verify - Purchase invoice status is set to Pending Approval
        VerifyPurchaseInvIsPendingApproval(PurchaseHeader);

        // Verify - Approval requests and their data
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        Assert.AreEqual(1, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, IntermediateApproverUserSetup."User ID");

        // Setup - Assign the approval entry to current user so that it can be approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);

        // Verify - User Cannot cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, false);

        // Setup
        LibraryDocumentApprovals.CreateOrFindUserSetup(UserSetup, UserId);
        LibraryDocumentApprovals.SetAdministrator(UserSetup);

        // Verify - User can cancel the approval request
        CheckUserCanCancelTheApprovalRequest(PurchaseHeader, true);

        // Excercise - Open Purchase invoice card and cancel the approval request
        CancelPurchaseInvoice(PurchaseHeader);

        // Verify - Approval requests and their data
        VerifyPurchaseInvIsOpen(PurchaseHeader);
        ApprovalEntry.Reset();
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, PurchaseHeader.RecordId);
        VerifyApprovalEntryIsCancelled(ApprovalEntry);
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
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OverdueEntriesFilteringOnApprovalEntries()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntries: TestPage "Approval Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255337] Overdue enties must be filtered on clicking "Overdue Entries" on Approval Entries page

        Initialize();

        ApprovalEntry.DeleteAll();

        // [GIVEN] Non-overdue Approval Entry
        ApprovalEntry.Init();
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Due Date" := Today;
        ApprovalEntry."Sender ID" := UserId;
        ApprovalEntry.Insert();

        // [GIVEN] Approval Entry is shown on Approval Entries page
        ApprovalEntries.OpenEdit();
        ApprovalEntries.GotoRecord(ApprovalEntry);
        Assert.AreEqual(ApprovalEntries.Status.Value, Format(ApprovalEntry.Status), '');

        // [WHEN] Click "verdue Entries" on Approval Entries page
        ApprovalEntries."O&verdue Entries".Invoke();

        // [THEN] Approval Entry is not shown on page
        Assert.AreEqual(ApprovalEntries.Status.Value, '', '');
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        PostedApprovalEntry: Record "Posted Approval Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"WF Demo Purch. Inv. Approvals");

        LibraryVariableStorage.Clear();
        UserSetup.DeleteAll();
        LibraryERMCountryData.InitializeCountry();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryWorkflow.DisableAllWorkflows();
        PostedApprovalEntry.DeleteAll();
        if IsInitialized then
            exit;
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(100));
    end;

    local procedure CreatePurchInvWithLine(var PurchHeader: Record "Purchase Header"; Amount: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, '', 1);
        PurchLine.Validate("Direct Unit Cost", Amount);
        PurchLine.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure SendPurchaseInvoiceForApproval(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.SendApprovalRequest.Invoke();
        PurchaseInvoice.Close();
    end;

    local procedure RegetPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.FindFirst();
    end;

    local procedure VerifyPurchaseInvIsReleased(var PurchaseHeader: Record "Purchase Header")
    begin
        RegetPurchaseDocument(PurchaseHeader);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);
    end;

    local procedure VerifyPurchaseInvIsOpen(var PurchaseHeader: Record "Purchase Header")
    begin
        RegetPurchaseDocument(PurchaseHeader);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
    end;

    local procedure VerifyPurchaseInvIsPendingApproval(var PurchaseHeader: Record "Purchase Header")
    begin
        RegetPurchaseDocument(PurchaseHeader);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::"Pending Approval");
    end;

    local procedure VerifyApprovalEntryIsApproved(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Approved);
    end;

    local procedure VerifyApprovalEntryIsOpen(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Open);
    end;

    local procedure VerifyApprovalEntryIsRejected(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);
    end;

    local procedure VerifyApprovalEntryIsCancelled(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Canceled);
    end;

    local procedure VerifyApprovalEntrySenderID(ApprovalEntry: Record "Approval Entry"; SenderId: Code[50])
    begin
        ApprovalEntry.TestField("Sender ID", SenderId);
    end;

    local procedure VerifyApprovalEntryApproverID(ApprovalEntry: Record "Approval Entry"; ApproverId: Code[50])
    begin
        ApprovalEntry.TestField("Approver ID", ApproverId);
    end;

    local procedure ApprovePurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Approve.Invoke();
        PurchaseInvoice.Close();
    end;

    local procedure RejectPurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Reject.Invoke();
        PurchaseInvoice.Close();
    end;

    local procedure DelegatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Delegate.Invoke();
        PurchaseInvoice.Close();
    end;

    local procedure CancelPurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.CancelApprovalRequest.Invoke();
        PurchaseInvoice.Close();
    end;

    local procedure SetPurchDocPurchaserCode(PurchaseHeader: Record "Purchase Header"; PurchaserCode: Code[20])
    begin
        PurchaseHeader.Validate("Purchaser Code", PurchaserCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure EnablePurchInvWorkflow()
    var
        Workflow: Record Workflow;
        GenJournalBatch: Record "Gen. Journal Batch";
        WorkflowStep: Record "Workflow Step";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseInvoiceWorkflowCode());

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::Response);

        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.PostDocumentAsyncCode());
        WorkflowStep.FindFirst();

        WorkflowStep.Validate("Function Name", WorkflowResponseHandling.PostDocumentCode());
        WorkflowStep.Modify(true);

        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocAsyncCode());
        WorkflowStep.FindFirst();
        WorkflowStep.Validate("Function Name", WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocCode());
        WorkflowStep.Modify(true);

        LibraryPurchase.SelectPmtJnlBatch(GenJournalBatch);
        LibraryWorkflow.InsertPmtLineCreationArgument(WorkflowStep.ID, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);

        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateNotificationEntryCode());
        WorkflowStep.FindFirst();

        LibraryWorkflow.InsertNotificationArgument(WorkflowStep.ID, UserId, 0, '');

        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure EnableIncDocWorkflow()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.IncomingDocumentWorkflowCode());

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::Response);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateNotificationEntryCode());
        WorkflowStep.FindFirst();

        LibraryWorkflow.InsertNotificationArgument(WorkflowStep.ID, UserId, 0, '');

        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure VerifyNotificationEntry(RecID: RecordID)
    var
        NotificationEntry: Record "Notification Entry";
    begin
        NotificationEntry.SetRange("Triggered By Record", RecID);

        NotificationEntry.SetRange("Recipient User ID", UserId);
        Assert.AreEqual(1, NotificationEntry.Count, 'Unexpected notification line.');
        NotificationEntry.FindFirst();
        NotificationEntry.TestField(Type, NotificationEntry.Type::"New Record");
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(PurchaseHeader: Record "Purchase Header"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        PurchaseInvoice: TestPage "Purchase Invoice";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        Assert.AreEqual(CommentActionIsVisible, PurchaseInvoice.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            PurchaseInvoice.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        PurchaseInvoice.Close();
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

    local procedure CheckUserCanCancelTheApprovalRequest(PurchaseHeader: Record "Purchase Header"; CancelActionExpectedEnabled: Boolean)
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        PurchaseInvoice.OpenView();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, PurchaseInvoice.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        PurchaseInvoice.Close();

        PurchaseInvoices.OpenView();
        PurchaseInvoices.GotoRecord(PurchaseHeader);
        Assert.AreEqual(CancelActionExpectedEnabled, PurchaseInvoices.CancelApprovalRequest.Enabled(), 'Wrong state for the Cancel action');
        PurchaseInvoices.Close();
    end;
}

