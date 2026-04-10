codeunit 134191 "WF Demo Inc. Doc. Approvals"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = m;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Incoming Document]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        DocWhenApprovalIsCompleteErr: Label 'The document can only be created when the approval process is complete.';
        OCRWhenApprovalIsCompleteErr: Label 'The document can only be sent to the OCR service when the approval process is complete.';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalRequestSendMsg: Label 'An approval request has been sent.';
        RecordIsRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1=Record Id';
        ApprovalShouldBeHandledErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        LibraryUtility: Codeunit "Library - Utility";
        UnexpectedNoOfApprovalEntriesErr: Label 'Unexpected number of approval entries found.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetReadyForOCRFromIncomingDoc()
    var
        Workflow: Record Workflow;
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        IncomingDocuments: TestPage "Incoming Documents";
    begin
        // [SCENARIO] The user cannot mark a incoming document send for OCR when the approval workflow is enabled and the incoming documemnt is not approved and released.
        // [GIVEN] There is a incoming document that is not approved and released.
        // [GIVEN] The approval workflow for puchase invoices is enabled.
        // [WHEN] The user wants to Post the incoming document.
        // [THEN] The user will get an error that he cannot post a incoming document that is not approved and released.

        // Setup
        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Exercise
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        asserterror IncomingDocuments.SetReadyForOCR.Invoke();

        // Verify
        Assert.ExpectedError(OCRWhenApprovalIsCompleteErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCreatePurchaseInvoiceFromIncomingDoc()
    var
        Workflow: Record Workflow;
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        IncomingDocuments: TestPage "Incoming Documents";
    begin
        // [SCENARIO] The user cannot release a incoming document when the approval workflow is enabled and the incoming document is not approved.
        // [GIVEN] There is a incoming document that is not approved.
        // [GIVEN] The approval workflow for puchase invoices is enabled.
        // [WHEN] The user wants to Release the incoming document.
        // [THEN] The user will get an error that he cannot release a incoming document that is not approved.

        // Setup
        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'xml');

        // Exercise
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        asserterror IncomingDocuments.CreateDocument.Invoke();

        // Verify
        Assert.ExpectedError(DocWhenApprovalIsCompleteErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotSetReadyForOCRIncomingDocmumentApprovalIsPending()
    var
        Workflow: Record Workflow;
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        IncomingDocuments: TestPage "Incoming Documents";
    begin
        // [SCENARIO] The user cannot release a incoming document when the approval workflow is enabled and the incoming document is pending approval.
        // [GIVEN] There is a incoming document that is sent for approval.
        // [GIVEN] The approval workflow for puchase invoices is enabled.
        // [WHEN] The user wants to Release the incoming document.
        // [THEN] The user will get an error that he cannot release the incoming document that is not approved.

        // Setup
        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create 3 approval usersetups
        // LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create incoming document
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Excercise - Open incoming document card and sent it for approval
        SendIncomingDocumentForApproval(IncomingDocument);

        // Verify - incoming document status is set to Pending Approval
        VerifyIncomingDocumentIsPendingApproval(IncomingDocument);

        // Exercise
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        asserterror IncomingDocuments.SetReadyForOCR.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(IncomingDocument.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotCreateIncomingDocmumentApprovalIsPending()
    var
        Workflow: Record Workflow;
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        IncomingDocuments: TestPage "Incoming Documents";
    begin
        // [SCENARIO] The user cannot release a incoming document when the approval workflow is enabled and the incoming document is pending approval.
        // [GIVEN] There is a incoming document that is sent for approval.
        // [GIVEN] The approval workflow for puchase invoices is enabled.
        // [WHEN] The user wants to Release the incoming document.
        // [THEN] The user will get an error that he cannot release the incoming document that is not approved.

        // Setup
        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create 3 approval usersetups
        // LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create incoming document
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Excercise - Open incoming document card and sent it for approval
        SendIncomingDocumentForApproval(IncomingDocument);

        // Verify - incoming document status is set to Pending Approval
        VerifyIncomingDocumentIsPendingApproval(IncomingDocument);

        // Exercise
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        asserterror IncomingDocuments.CreateDocument.Invoke();

        // Verify
        Assert.ExpectedError(StrSubstNo(RecordIsRestrictedErr, Format(IncomingDocument.RecordId, 0, 1)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReopenIncomingDocmumentApprovalIsPending()
    var
        Workflow: Record Workflow;
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        IncomingDocuments: TestPage "Incoming Documents";
    begin
        // [SCENARIO] The user cannot release a incoming document when the approval workflow is enabled and the incoming document is pending approval.
        // [GIVEN] There is a incoming document that is sent for approval.
        // [GIVEN] The approval workflow for puchase invoices is enabled.
        // [WHEN] The user wants to Reopen the incoming document.
        // [THEN] The user will get an error that he cannot reopen the incoming document.

        // Setup
        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create 3 approval usersetups
        // LibraryDocumentApprovals.SetupUsersForApprovals(IntermediateApproverUserSetup);

        // Setup - Create incoming document
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Excercise - Open incoming document card and sent it for approval
        SendIncomingDocumentForApproval(IncomingDocument);

        // Verify - incoming document status is set to Pending Approval
        VerifyIncomingDocumentIsPendingApproval(IncomingDocument);

        // Exercise
        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        asserterror IncomingDocuments.Reopen.Invoke();

        // Verify
        Assert.ExpectedError(ApprovalShouldBeHandledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestIncomingDocmumentApprovalWorkflow()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 1] Test that the Incoming Document Approval Workflow approval path works with a group of 3 users.
        // [GIVEN] The Incoming Document Approval Workflow is enabled.
        // [WHEN] A user sends the incoming document for approval and all users in the group of approvals approve the document.
        // [THEN] The incoming document is approved and released.

        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create incoming document
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Excercise - Open incoming document card and sent it for approval
        SendIncomingDocumentForApproval(IncomingDocument);

        // Verify - incoming document status is set to Pending Approval
        VerifyIncomingDocumentIsPendingApproval(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open,
          ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, IncomingDocument);

        // Excercise - Open incoming document card and approve the approval request
        ApproveIncomingDocument(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."Approver ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open);

        // Excercise - Set the approverid to USERID so that it can be approved
        ApproveIncomingDocument(IncomingDocument);

        // Verify - incoming document is approved and released
        VerifyIncomingDocumentIsReleased(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."Approver ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestIncomingDocmumentApprovalWorkflowRejectionPathLastApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 2] Test that the incoming document Approval Workflow rejection path works with a group of 3 users.
        // [GIVEN] The incoming document Approval Workflow is enabled.
        // [WHEN] A user sends the incoming document for approval, the first approver approves it and last approver rejects it.
        // [THEN] The incoming document is rejected and open.

        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create incoming document
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Excercise - Open incoming document card and sent it for approval
        SendIncomingDocumentForApproval(IncomingDocument);

        // Verify - incoming document status is set to Pending Approval
        VerifyIncomingDocumentIsPendingApproval(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open,
          ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, IncomingDocument);

        // Excercise - Open incoming document card and approve the approval request
        ApproveIncomingDocument(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."Approver ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open);

        // Excercise - Set the approverid to USERID so that it can be rejected
        RejectIncomingDocument(IncomingDocument);

        // Verify - incoming document is rejected and open
        VerifyIncomingDocumentIsOpen(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."Approver ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          ApprovalEntry.Status::Rejected,
          ApprovalEntry.Status::Rejected,
          ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestIncomingDocmumentApprovalWorkflowRejectionPathFirstApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 3] Test that the incoming document Approval Workflow rejection path works with a group of 3 users.
        // [GIVEN] The incoming document Approval Workflow is enabled.
        // [WHEN] A user sends the incoming document for approval and the first approver rejects it.
        // [THEN] The incoming document is rejected and open.

        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create incoming document
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Excercise - Open incoming document card and sent it for approval
        SendIncomingDocumentForApproval(IncomingDocument);

        // Verify - incoming document status is set to Pending Approval
        VerifyIncomingDocumentIsPendingApproval(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open,
          ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, IncomingDocument);

        // Excercise - reject the incoming document
        RejectIncomingDocument(IncomingDocument);

        // Verify - incoming document is rejected and open
        VerifyIncomingDocumentIsOpen(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."Approver ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          ApprovalEntry.Status::Rejected,
          ApprovalEntry.Status::Rejected,
          ApprovalEntry.Status::Rejected);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestIncomingDocmumentApprovalWorkflowCancelationPathFirstApprover()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 5] Test that the incoming document Approval Workflow rejection path works with a group of 3 users.
        // [GIVEN] The incoming document Approval Workflow is enabled.
        // [WHEN] A user sends the incoming document for approval and then the user cancels it.
        // [THEN] The incoming document is canceled and open.

        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create incoming document
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Excercise - Open incoming document card and sent it for approval
        SendIncomingDocumentForApproval(IncomingDocument);

        // Verify - incoming document status is set to Pending Approval
        VerifyIncomingDocumentIsPendingApproval(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open,
          ApprovalEntry.Status::Created);

        // Excercise - Cancel the incoming document
        CancelIncomingDocument(IncomingDocument);

        // Verify - Incoming document is canceled and open
        VerifyIncomingDocumentIsOpen(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID",
          ApprovalEntry.Status::Canceled,
          ApprovalEntry.Status::Canceled,
          ApprovalEntry.Status::Canceled);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure IncomingDocmumentApprovalWorkflowOnDelegationPath()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 6] Test that the incoming document Approval Workflow delegation path works with a group of 3 users and one delegate.
        // [GIVEN] The incoming document Approval Workflow is enabled.
        // [WHEN] A user sends the incoming document for approval and the second user delegates the approval to the 3rd user and the last user approves it.
        // [THEN] The incoming document is approved and released.

        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryDocumentApprovals.SetSubstitute(CurrentUserSetup, FinalApproverUserSetup);

        // Setup - Create incoming document
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Excercise - Open incoming document card and sent it for approval
        SendIncomingDocumentForApproval(IncomingDocument);

        // Verify - incoming document status is set to Pending Approval
        VerifyIncomingDocumentIsPendingApproval(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open,
          ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be approved
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, IncomingDocument);

        // Excercise - Open incoming document card and approve the approval request
        ApproveIncomingDocument(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."Approver ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open);

        // Excercise - Delegate the incoming document
        DelegateIncomingDocument(IncomingDocument);

        // Exercise - Set the approver id
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, IncomingDocument);

        // Exercise - Approve the incoming document
        ApproveIncomingDocument(IncomingDocument);

        // Verify - incoming document is approved and released
        VerifyIncomingDocumentIsReleased(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."Approver ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Approved);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure IncomingDocmumentApprovalActionsVisibilityOnCardTest()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        Workflow: Record Workflow;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] Purchase Header approval disabled.
        Initialize();
        // EnableIncDocWorkflow();

        // [WHEN] Purchase Header card is opened.
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'xml');

        Commit();
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(IncomingDocumentCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(IncomingDocumentCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should NOT be enabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror IncomingDocumentCard.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        IncomingDocumentCard.Close();

        // [GIVEN] PurchHeader approval enabled.
        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        // LibraryWorkflow.CreateEnabledWorkflow(Workflow,WorkflowSetup.IncomingDocumentApprovalWorkflowCode);

        // [WHEN] PurchHeader card is opened.
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(IncomingDocumentCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(IncomingDocumentCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        Assert.IsFalse(IncomingDocumentCard.Approve.Visible(), 'Approve should NOT be visible');
        Assert.IsFalse(IncomingDocumentCard.RejectApproval.Visible(), 'Reject should NOT be visible');
        Assert.IsFalse(IncomingDocumentCard.Delegate.Visible(), 'Delegate should NOT be visible');
        IncomingDocumentCard.Close();

        // [GIVEN] Approval exist on PurchHeader.
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        IncomingDocumentCard.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(IncomingDocumentCard.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(IncomingDocumentCard.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');

        // Clenup
        IncomingDocumentCard.Close();

        // Setup the approval so it can be approve by current user
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(IncomingDocument.RecordId);

        // [WHEN] PurchHeader card is opened.
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);

        // [THEN] Approval action are shown.
        Assert.IsTrue(IncomingDocumentCard.OCRResultFileName.Visible(), 'Approva should be visible');
        Assert.IsTrue(IncomingDocumentCard.Delegate.Visible(), 'Reject should be visible');
        Assert.IsTrue(IncomingDocumentCard."VAT Amount".Visible(), 'Delegate should be visible');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure IncomingDocmumentApprovalActionsVisibilityOnListTest()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        Workflow: Record Workflow;
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        IncomingDocuments: TestPage "Incoming Documents";
    begin
        // [SCENARIO 3] Approval action availability.
        // [GIVEN] PurchHeader approval disabled.
        Initialize();
        EnableIncDocWorkflow();

        // [WHEN] PurchHeader card is opened.
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'xml');

        // CreatePurchaseInvoice(PurchHeader);
        Commit();
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(IncomingDocuments.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(IncomingDocuments.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');

        // [WHEN] Send Approval Request is pushed.
        asserterror IncomingDocuments.SendApprovalRequest.Invoke();

        // [THEN] Error is displayed.
        Assert.ExpectedError(NoWorkflowEnabledErr);

        // Cleanup
        IncomingDocuments.Close();

        // [GIVEN] PurchHeader approval enabled.
        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        // LibraryWorkflow.CreateEnabledWorkflow(Workflow,WorkflowSetup.IncomingDocumentApprovalWorkflowCode);

        // [WHEN] PurchHeader card is opened.
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);

        // [THEN] Only Send is enabled.
        Assert.IsTrue(IncomingDocuments.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be enabled');
        Assert.IsFalse(IncomingDocuments.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be disabled');
        IncomingDocuments.Close();

        // [GIVEN] Approval exist on PurchHeader.
        // LibraryDocumentApprovals.SetupUsersForApprovals(ApproverUserSetup);
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);

        // [WHEN] PurchHeader send for approval.
        LibraryVariableStorage.Enqueue(ApprovalRequestSendMsg);
        IncomingDocuments.SendApprovalRequest.Invoke();

        // [THEN] Only Send is enabled.
        Assert.IsFalse(IncomingDocuments.SendApprovalRequest.Enabled(), 'SendApprovalRequest should be disabled');
        Assert.IsTrue(IncomingDocuments.CancelApprovalRequest.Enabled(), 'CancelApprovalRequest should be enabled');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestIncomingDocumentApprovalWorkflowApprovePathAddComments()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO] This test verifies E2E scenario for the Incoming Document approval workflow on approval path and adds a comment for each step.
        // [GIVEN] Incoming Document Approval Workflow that has Purchaser as the approver and No Limit as the limit type.
        // [WHEN] Incoming Document is sent for approval.
        // [THEN] Approval Request is created and the user can add a comment.
        // [WHEN] Approver approves the approval request.
        // [THEN] Incoming Document is released.

        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create incoming document
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        CheckCommentsForDocumentOnDocumentCard(IncomingDocument, 0, false);

        // Excercise - Open incoming document card and sent it for approval
        SendIncomingDocumentForApproval(IncomingDocument);

        // Verify - incoming document status is set to Pending Approval
        VerifyIncomingDocumentIsPendingApproval(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open,
          ApprovalEntry.Status::Created);

        CheckCommentsForDocumentOnDocumentCard(IncomingDocument, 0, false);

        // Exercise - Set the approver id
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, IncomingDocument);

        CheckCommentsForDocumentOnDocumentCard(IncomingDocument, 0, true);
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, IncomingDocument.RecordId);
        ApprovalEntry.Next();
        CheckCommentsForDocumentOnRequestsToApprovePage(ApprovalEntry, 1);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."Approver ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open,
          ApprovalEntry.Status::Created);

        CheckCommentsForDocumentOnApprovalEntriesPage(ApprovalEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestIncomingDocmumentApprovalWorkflowUserCanCancelApproval()
    var
        Workflow: Record Workflow;
        ApprovalEntry: Record "Approval Entry";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        CurrentUserSetup: Record "User Setup";
        IntermediateApproverUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
    begin
        // [SCENARIO 5] Test that the incoming document Approval Workflow cancelation path works.
        // [GIVEN] The incoming document Approval Workflow is enabled.
        // [WHEN] A user sends the incoming document for approval and then the user cancels it.
        // [THEN] The incoming document is canceled and open.

        Initialize();

        CreateIncomingDocApprovalWorkflow(Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);

        // Setup - Create incoming document
        CreateIncomingDocument(IncomingDocument);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        CheckUserCanCancelTheApprovalRequest(IncomingDocument, false);

        // Excercise - Open incoming document card and sent it for approval
        SendIncomingDocumentForApproval(IncomingDocument);

        CheckUserCanCancelTheApprovalRequest(IncomingDocument, true);

        // Verify - incoming document status is set to Pending Approval
        VerifyIncomingDocumentIsPendingApproval(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          IntermediateApproverUserSetup."User ID",
          FinalApproverUserSetup."User ID",
          ApprovalEntry.Status::Approved,
          ApprovalEntry.Status::Open,
          ApprovalEntry.Status::Created);

        // Excercise - Set the approverid to USERID so that it can be canceled
        UpdateApprovalEntryWithTempUser(CurrentUserSetup, IncomingDocument);

        CheckUserCanCancelTheApprovalRequest(IncomingDocument, false);

        LibraryDocumentApprovals.SetAdministrator(CurrentUserSetup);
        CheckUserCanCancelTheApprovalRequest(IncomingDocument, true);

        // Excercise - Cancel the incoming document
        CancelIncomingDocument(IncomingDocument);

        // Verify - Incoming document is canceled and open
        VerifyIncomingDocumentIsOpen(IncomingDocument);

        // Verify - Approval requests and their data
        VerifyApprovalRequests(
          IncomingDocument,
          3,
          CurrentUserSetup."Approver ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          CurrentUserSetup."User ID",
          ApprovalEntry.Status::Canceled,
          ApprovalEntry.Status::Canceled,
          ApprovalEntry.Status::Canceled);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestEmptyIncomingDocument()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        // [SCENARIO] The user cannot insert a file with 0 bytes
        // [GIVEN] Create the Incoming Document and Create an Empty Doc Attachment
        // [WHEN] The user trys to attach the empty document
        // [THEN] The user will get an error saying they cannot attache a document with no content

        // Setup
        Initialize();

        CreateIncomingDocument(IncomingDocument);
        CreateIncomingEmptyDocAttachment(IncomingDocument, IncomingDocumentAttachment);

        // Verify
        Assert.IsFalse(IncomingDocumentAttachment.Content.HasValue, 'Incoming Document Should be empty');
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

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        PostedApprovalEntry: Record "Posted Approval Entry";
    begin
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

    local procedure CreateIncomingDocApprovalWorkflow(var Workflow: Record Workflow; var CurrentUserSetup: Record "User Setup"; var IntermediateApproverUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup")
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.IncomingDocumentApprovalWorkflowCode());
        LibraryDocumentApprovals.CreateUserSetupsAndGroupOfApproversForWorkflow(
          Workflow, CurrentUserSetup, IntermediateApproverUserSetup, FinalApproverUserSetup);
        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure CreateIncomingDocument(var IncomingDocument: Record "Incoming Document")
    begin
        if IncomingDocument.FindLast() then;
        IncomingDocument.Init();
        IncomingDocument."Entry No." += 1;
        IncomingDocument."OCR Service Doc. Template Code" := 'TEST';
        IncomingDocument."Data Exchange Type" := LibraryUtility.GenerateGUID();
        IncomingDocument.Insert(true);
    end;

    local procedure CreateIncomingDocAttachment(IncomingDocument: Record "Incoming Document"; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; AttachmentType: Text[10])
    var
        FileMgt: Codeunit "File Management";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        SystemIOFile: DotNet File;
        FileName: Text;
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");

        FileName := FileMgt.ServerTempFileName(AttachmentType);

        SystemIOFile.WriteAllText(FileName, AttachmentType);
        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FileName);
    end;

    local procedure CreateIncomingEmptyDocAttachment(IncomingDocument: Record "Incoming Document"; var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");

        ImportAttachmentIncDoc.SetTestMode();
        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment,
          MakeEmptyFile(LibraryUtility.GenerateGUID() + '.txt'));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure SendIncomingDocumentForApproval(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        IncomingDocumentCard.OpenView();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.SendApprovalRequest.Invoke();
        IncomingDocumentCard.Close();
    end;

    [Scope('OnPrem')]
    procedure MakeEmptyFile(FileNameIn: Text) FileNameOut: Text
    var
        File: File;
    begin
        if not File.Create(FileNameIn) then
            Assert.Fail('Unable to create file.');

        FileNameOut := FileNameIn;
    end;

    local procedure RegetIncomingDocument(var IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.SetRecFilter();
        IncomingDocument.FindFirst();
    end;

    local procedure VerifyIncomingDocumentIsReleased(var IncomingDocument: Record "Incoming Document")
    begin
        RegetIncomingDocument(IncomingDocument);
        // IncomingDocument.TESTFIELD(Status,IncomingDocument.Status::created);
    end;

    local procedure VerifyIncomingDocumentIsOpen(var IncomingDocument: Record "Incoming Document")
    begin
        RegetIncomingDocument(IncomingDocument);
        IncomingDocument.TestField(Status, IncomingDocument.Status::New);
    end;

    local procedure VerifyIncomingDocumentIsPendingApproval(var IncomingDocument: Record "Incoming Document")
    begin
        RegetIncomingDocument(IncomingDocument);
        IncomingDocument.TestField(Status, IncomingDocument.Status::"Pending Approval");
    end;

    local procedure ApproveIncomingDocument(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        IncomingDocumentCard.OpenView();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.Approve.Invoke();
        IncomingDocumentCard.Close();
    end;

    local procedure RejectIncomingDocument(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        IncomingDocumentCard.OpenView();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.RejectApproval.Invoke();
        IncomingDocumentCard.Close();
    end;

    local procedure DelegateIncomingDocument(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        IncomingDocumentCard.OpenView();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.Delegate.Invoke();
        IncomingDocumentCard.Close();
    end;

    local procedure CancelIncomingDocument(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        IncomingDocumentCard.OpenView();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        IncomingDocumentCard.CancelApprovalRequest.Invoke();
        IncomingDocumentCard.Close();
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

    local procedure VerifyApprovalRequests(IncomingDocument: Record "Incoming Document"; ExpectedNumberOfApprovalEntries: Integer; SenderUserID: Code[50]; ApproverUserID1: Code[50]; ApproverUserID2: Code[50]; ApproverUserID3: Code[50]; Status1: Enum "Approval Status"; Status2: Enum "Approval Status"; Status3: Enum "Approval Status")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, IncomingDocument.RecordId);
        Assert.AreEqual(ExpectedNumberOfApprovalEntries, ApprovalEntry.Count, UnexpectedNoOfApprovalEntriesErr);

        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID1, Status1);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID2, Status2);
        ApprovalEntry.Next();
        VerifyApprovalEntry(ApprovalEntry, SenderUserID, ApproverUserID3, Status3);
    end;

    local procedure UpdateApprovalEntryWithTempUser(UserSetup: Record "User Setup"; IncomingDocument: Record "Incoming Document")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        LibraryDocumentApprovals.GetApprovalEntries(ApprovalEntry, IncomingDocument.RecordId);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;

    local procedure VerifyApprovalEntry(ApprovalEntry: Record "Approval Entry"; SenderId: Code[50]; ApproverId: Code[50]; Status: Enum "Approval Status")
    begin
        ApprovalEntry.TestField("Sender ID", SenderId);
        ApprovalEntry.TestField("Approver ID", ApproverId);
        ApprovalEntry.TestField(Status, Status);
    end;

    local procedure CheckCommentsForDocumentOnDocumentCard(IncomingDocument: Record "Incoming Document"; NumberOfExpectedComments: Integer; CommentActionIsVisible: Boolean)
    var
        ApprovalComments: TestPage "Approval Comments";
        IncomingDocumentPage: TestPage "Incoming Document";
        NumberOfComments: Integer;
    begin
        ApprovalComments.Trap();

        IncomingDocumentPage.OpenView();
        IncomingDocumentPage.GotoRecord(IncomingDocument);

        Assert.AreEqual(CommentActionIsVisible, IncomingDocumentPage.Comment.Visible(), 'The Comments action has the wrong visibility');

        if CommentActionIsVisible then begin
            IncomingDocumentPage.Comment.Invoke();
            if ApprovalComments.First() then
                repeat
                    NumberOfComments += 1;
                until ApprovalComments.Next();
            Assert.AreEqual(NumberOfExpectedComments, NumberOfComments, 'The page contains the wrong number of comments');

            ApprovalComments.Comment.SetValue('Test Comment' + Format(NumberOfExpectedComments));
            ApprovalComments.Next();
            ApprovalComments.Close();
        end;

        IncomingDocumentPage.Close();
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

    local procedure CheckUserCanCancelTheApprovalRequest(IncomingDocument: Record "Incoming Document"; CancelActionExpectedEnabled: Boolean)
    var
        IncomingDocumentPage: TestPage "Incoming Document";
        IncomingDocuments: TestPage "Incoming Documents";
    begin
        IncomingDocumentPage.OpenView();
        IncomingDocumentPage.GotoRecord(IncomingDocument);
        Assert.AreEqual(CancelActionExpectedEnabled, IncomingDocumentPage.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        IncomingDocumentPage.Close();

        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocument);
        Assert.AreEqual(CancelActionExpectedEnabled, IncomingDocuments.CancelApprovalRequest.Enabled(),
          'Wrong state for the Cancel action');
        IncomingDocuments.Close();
    end;
}

