codeunit 134204 "Document Approval - Requests"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        DocumentApprovalRequests: Codeunit "Document Approval - Requests";
        IsInitialized: Boolean;
        NoPermissionToDelegateErr: Label 'You do not have permission to delegate one or more of the selected approval requests.';

    [Test]
    [Scope('OnPrem')]
    procedure ApproveMultipleRequests()
    var
        ApprovalEntry: Record "Approval Entry";
        DocNo: array[4] of Code[20];
    begin
        // [SCENARIO 101] Approve from a Purchace Invoice
        // [GIVEN] Purchase Invoice and a request for approval.
        // [WHEN] Approval Request invoked from the the purchase invoice page.
        // [THEN] The Purcahse Invoice is approved.
        Initialize();

        // Setup
        CreateMultipleApprovalEntries(DocNo);

        // Exercise select 2 records and approve them
        ApprovalEntry.SetRange("Document No.", DocNo[2], DocNo[3]);
        ApprovalsMgmt.ApproveApprovalRequests(ApprovalEntry);

        // Verify
        ApprovalEntry.SetCurrentKey("Document No.");
        ApprovalEntry.SetRange("Document No.", DocNo[1], DocNo[4]);
        ApprovalEntry.FindSet();
        Assert.AreEqual(ApprovalEntry.Status::Open, ApprovalEntry.Status, '');
        ApprovalEntry.Next();
        Assert.AreEqual(ApprovalEntry.Status::Approved, ApprovalEntry.Status, '');
        ApprovalEntry.Next();
        Assert.AreEqual(ApprovalEntry.Status::Approved, ApprovalEntry.Status, '');
        ApprovalEntry.Next();
        Assert.AreEqual(ApprovalEntry.Status::Open, ApprovalEntry.Status, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RejectMultipleRequests()
    var
        ApprovalEntry: Record "Approval Entry";
        DocNo: array[4] of Code[20];
    begin
        // [SCENARIO 102] Reject from a Purchace Invoice
        // [GIVEN] Purchase Invoice and a request for approval.
        // [WHEN] Reject Request invoked from the the purchase invoice page.
        // [THEN] The Purcahse Invoice is rejected.
        Initialize();

        // Setup
        CreateMultipleApprovalEntries(DocNo);

        // Exercise select 2 records and approve them
        ApprovalEntry.SetRange("Document No.", DocNo[2], DocNo[3]);
        ApprovalsMgmt.RejectApprovalRequests(ApprovalEntry);

        // Verify
        ApprovalEntry.SetCurrentKey("Document No.");
        ApprovalEntry.SetRange("Document No.", DocNo[1], DocNo[4]);
        ApprovalEntry.FindSet();
        Assert.AreEqual(DocNo[1], ApprovalEntry."Document No.", '');
        Assert.AreEqual(ApprovalEntry.Status::Open, ApprovalEntry.Status, '');
        ApprovalEntry.Next();
        Assert.AreEqual(ApprovalEntry.Status::Rejected, ApprovalEntry.Status, '');
        ApprovalEntry.Next();
        Assert.AreEqual(ApprovalEntry.Status::Rejected, ApprovalEntry.Status, '');
        ApprovalEntry.Next();
        Assert.AreEqual(ApprovalEntry.Status::Open, ApprovalEntry.Status, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DelegateMultipleRequestsAsApprover()
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        SubstituteUserSetup: Record "User Setup";
        DocNo: array[4] of Code[20];
    begin
        // [SCENARIO 103] Delegate from a Purchace Invoice
        // [GIVEN] Purchase Invoice and a request for approval.
        // [WHEN] Delegate Request invoked from the the purchase invoice page.
        // [THEN] The Purcahse Invoice is delegated.
        Initialize();

        // Setup
        CreateUserSetup(UserSetup, UserId, LibraryUtility.GenerateRandomCode(UserSetup.FieldNo(Substitute), DATABASE::"User Setup"));
        CreateUserSetup(SubstituteUserSetup, UserSetup.Substitute, '');
        CreateMultipleApprovalEntries(DocNo);

        // Exercise select 2 records and approve them
        ApprovalEntry.SetRange("Document No.", DocNo[2], DocNo[3]);
        ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);

        // Verify
        ApprovalEntry.SetCurrentKey("Document No.");
        ApprovalEntry.SetRange("Document No.", DocNo[1], DocNo[4]);
        ApprovalEntry.FindSet();
        Assert.AreEqual(DocNo[1], ApprovalEntry."Document No.", '');
        Assert.AreEqual(UserSetup."User ID", ApprovalEntry."Approver ID", '');
        ApprovalEntry.Next();
        Assert.AreEqual(UserSetup.Substitute, ApprovalEntry."Approver ID", '');
        ApprovalEntry.Next();
        Assert.AreEqual(UserSetup.Substitute, ApprovalEntry."Approver ID", '');
        ApprovalEntry.Next();
        Assert.AreEqual(UserSetup."User ID", ApprovalEntry."Approver ID", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DelegateMultipleRequestAsSender()
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        MockUserSetup1: Record "User Setup";
        MockUserSetup2: Record "User Setup";
        DocNo: array[4] of Code[20];
    begin
        // [SCENARIO] User can delegate if he/she is the sender.
        // [GIVEN] Approval Requests where the current user is the sender.
        // [WHEN] Approval Request are delegated.
        // [THEN] The Approval Requests gets delegated.
        Initialize();

        // Setup
        LibraryDocumentApprovals.CreateMockupUserSetup(MockUserSetup1);
        LibraryDocumentApprovals.CreateMockupUserSetup(MockUserSetup2);
        LibraryDocumentApprovals.SetSubstitute(MockUserSetup1, MockUserSetup2);
        CreateUserSetup(UserSetup, UserId, LibraryUtility.GenerateRandomCode(UserSetup.FieldNo(Substitute), DATABASE::"User Setup"));
        CreateMultipleApprovalEntries(DocNo);

        // Set the approver of two of the approval requests to be a non current user
        // and set the sender to be the current user
        ApprovalEntry.SetRange("Document No.", DocNo[2], DocNo[3]);
        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntry."Approver ID" := MockUserSetup1."User ID";
                ApprovalEntry."Sender ID" := UserId;
                ApprovalEntry.Modify();
            until ApprovalEntry.Next() = 0;

        ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);

        // Verify
        ApprovalEntry.SetCurrentKey("Document No.");
        ApprovalEntry.SetRange("Document No.", DocNo[1], DocNo[4]);
        ApprovalEntry.FindSet();
        Assert.AreEqual(DocNo[1], ApprovalEntry."Document No.", '');
        Assert.AreEqual(UserSetup."User ID", ApprovalEntry."Approver ID", '');
        ApprovalEntry.Next();
        Assert.AreEqual(MockUserSetup1.Substitute, ApprovalEntry."Approver ID", '');
        ApprovalEntry.Next();
        Assert.AreEqual(MockUserSetup1.Substitute, ApprovalEntry."Approver ID", '');
        ApprovalEntry.Next();
        Assert.AreEqual(UserSetup."User ID", ApprovalEntry."Approver ID", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DelegateMultipleRequestAsAdministrator()
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        MockUserSetup1: Record "User Setup";
        MockUserSetup2: Record "User Setup";
        DocNo: array[4] of Code[20];
    begin
        // [SCENARIO] User can delegate if he/she is the approval administrator.
        // [GIVEN] Approval Requests where the current user is neither sender nor the approver.
        // [GIVEN] Current user is the approval administrator.
        // [WHEN] Approval Requests are delegated.
        // [THEN] The Approval Requests gets delegated.
        Initialize();

        // Setup
        LibraryDocumentApprovals.CreateMockupUserSetup(MockUserSetup1);
        LibraryDocumentApprovals.CreateMockupUserSetup(MockUserSetup2);
        LibraryDocumentApprovals.SetSubstitute(MockUserSetup1, MockUserSetup2);
        CreateUserSetup(UserSetup, UserId, '');
        LibraryDocumentApprovals.SetAdministrator(UserSetup);
        CreateMultipleApprovalEntries(DocNo);

        // Set the approver of two of the approval requests to be a non current user
        ApprovalEntry.SetRange("Document No.", DocNo[2], DocNo[3]);
        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntry."Approver ID" := MockUserSetup1."User ID";
                ApprovalEntry.Modify();
            until ApprovalEntry.Next() = 0;

        ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);

        // Verify
        ApprovalEntry.SetCurrentKey("Document No.");
        ApprovalEntry.SetRange("Document No.", DocNo[1], DocNo[4]);
        ApprovalEntry.FindSet();
        Assert.AreEqual(DocNo[1], ApprovalEntry."Document No.", '');
        Assert.AreEqual(UserSetup."User ID", ApprovalEntry."Approver ID", '');
        ApprovalEntry.Next();
        Assert.AreEqual(MockUserSetup1.Substitute, ApprovalEntry."Approver ID", '');
        ApprovalEntry.Next();
        Assert.AreEqual(MockUserSetup1.Substitute, ApprovalEntry."Approver ID", '');
        ApprovalEntry.Next();
        Assert.AreEqual(UserSetup."User ID", ApprovalEntry."Approver ID", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DelegateErrorWhenNoPermissionToDelegate()
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        MockUserSetup1: Record "User Setup";
        MockUserSetup2: Record "User Setup";
        DocNo: array[4] of Code[20];
    begin
        // [SCENARIO] User gets an error when user tries to delegate approval requests which are not permissible.
        // [GIVEN] Approval Requests where the current user is neither sender nor the approver or an admin.
        // [WHEN] Approval Requests are delegated.
        // [THEN] It throws an error that user is missing permission to delegate.
        Initialize();

        // Setup
        LibraryDocumentApprovals.CreateMockupUserSetup(MockUserSetup1);
        LibraryDocumentApprovals.CreateMockupUserSetup(MockUserSetup2);
        LibraryDocumentApprovals.SetSubstitute(MockUserSetup1, MockUserSetup2);
        CreateUserSetup(UserSetup, UserId, '');
        CreateMultipleApprovalEntries(DocNo);

        // Set the approver of two of the approval requests to be a non current user
        ApprovalEntry.SetRange("Document No.", DocNo[2], DocNo[3]);
        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntry."Approver ID" := MockUserSetup1."User ID";
                ApprovalEntry.Modify();
            until ApprovalEntry.Next() = 0;

        asserterror ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);

        // Verify
        Assert.ExpectedError(NoPermissionToDelegateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DelegateActionIsDisabledWhenNoPermissionToDelegate()
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        MockUserSetup1: Record "User Setup";
        MockUserSetup2: Record "User Setup";
        ApprovalEntries: TestPage "Approval Entries";
        DocNo: array[4] of Code[20];
    begin
        // [SCENARIO] Delegate action is disabled if the user does not have permission to delegate.
        // [GIVEN] Approval Requests where the current user is neither sender nor the approver or an admin.
        // [WHEN] Approval Entries page is opened.
        // [THEN] For the entries where the user does not have permission to delegate, the Delegate action is disabled.
        Initialize();

        // Setup
        LibraryDocumentApprovals.CreateMockupUserSetup(MockUserSetup1);
        LibraryDocumentApprovals.CreateMockupUserSetup(MockUserSetup2);
        LibraryDocumentApprovals.SetSubstitute(MockUserSetup1, MockUserSetup2);
        CreateUserSetup(UserSetup, UserId, '');
        CreateMultipleApprovalEntries(DocNo);

        // Set the approver of two of the approval requests to be a non current user
        ApprovalEntry.SetRange("Document No.", DocNo[1], DocNo[2]);
        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntry."Approver ID" := MockUserSetup1."User ID";
                ApprovalEntry.Modify();
            until ApprovalEntry.Next() = 0;

        // Verify
        ApprovalEntries.OpenEdit();
        if ApprovalEntry.FindSet() then
            repeat
                asserterror ApprovalEntries.GotoRecord(ApprovalEntry); // record is shown on the page.
            until ApprovalEntry.Next() = 0;

        ApprovalEntry.SetRange("Document No.", DocNo[3], DocNo[4]);
        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntries.GotoRecord(ApprovalEntry);
                Assert.AreEqual(true, ApprovalEntries."&Delegate".Enabled(), 'Delegate action is expected to be enabled');
            until ApprovalEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApprovalLineContent()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ApprovalEntry: Record "Approval Entry";
        RequeststoApprove: TestPage "Requests to Approve";
    begin
        // [SCENARIO 104] Approval line content
        // [GIVEN] Purchase Invoice and a request for approval.
        // [WHEN] User presented with a approval line.
        // [THEN] The lines contain info what document you are approving and some details about the document.
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Name := 'Name of Vendor';
        Vendor.Modify();

        LibraryPurchase.CreatePurchHeaderWithDocNo(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.", 'INVOICENO');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(100, 2));
        PurchaseLine.Amount := LibraryRandom.RandDec(1000, 2);
        PurchaseLine.Modify();

        CreateApprovalEntryPurchaseInvoice(ApprovalEntry, PurchaseHeader."No.");

        // Exercise
        RequeststoApprove.OpenView();

        // Verify
        Assert.AreEqual('Purchase Invoice INVOICENO', RequeststoApprove.ToApprove.Value, 'ToApprove has the wrong value');
        Assert.AreEqual('Name of Vendor ; Amount: ' + Format(PurchaseLine.Amount), RequeststoApprove.Details.Value, 'ToApprove has the wrong value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApproveEntryCanBeModifiedAfterOnRejectApprovalRequest()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223526] Record "Approval Entry" must be able to modify after event OnRejectApprovalRequest
        Initialize();
        BindSubscription(DocumentApprovalRequests);

        // [GIVEN] Record "Approval Entry"
        CreateApprovalEntry(ApprovalEntry, '');

        // [GIVEN] Invoke RejectApprovalRequest and modify record in handler "OnRejectApprovalRequest"
        ApprovalsMgmt.RejectApprovalRequests(ApprovalEntry);

        // [WHEN] Modify record again
        ApprovalEntry.Validate(Amount, LibraryRandom.RandIntInRange(10, 100));

        // [THEN] Record can be modifying
        Assert.IsTrue(ApprovalEntry.Modify(), 'Record is not modifying');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteWorkflowEventQueueOnApproveEntryDeletion()
    var
        ApprovalEntry: array[2] of Record "Approval Entry";
        WorkflowEventQueue: array[2] of Record "Workflow Event Queue";
    begin
        // [FEATURE] [UT] [Workflow Event Queue]
        // [SCENARIO 414141] The related "Workflow Event Queue" should be deleted on deletion of "Approval Entry".
        Initialize();

        // [GIVEN] Two "Approval Entry" records 'AE1' and 'AE2', each has a related "Workflow Event Queue" record 'WEQ1' and 'WEQ2'
        CreateApprovalEntry(ApprovalEntry[1], '');
        WorkflowEventQueue[1]."Record ID" := ApprovalEntry[1].RecordId;
        WorkflowEventQueue[1].Insert(true);

        CreateApprovalEntry(ApprovalEntry[2], '');
        WorkflowEventQueue[2]."Record ID" := ApprovalEntry[2].RecordId;
        WorkflowEventQueue[2].Insert(true);

        // [WHEN] Delete 'AE1'
        ApprovalEntry[1].Delete(true);

        // [THEN] 'WEQ1' is deleted, 'WEQ2' exists
        Assert.IsFalse(WorkflowEventQueue[1].Find(), 'WorkflowEventQueue should be deleted.');
        Assert.IsTrue(WorkflowEventQueue[2].Find(), 'WorkflowEventQueue should not be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteWorkflowEventQueueOnApproveEntryApproval()
    var
        ApprovalEntry: array[2] of Record "Approval Entry";
        WorkflowEventQueue: array[2] of Record "Workflow Event Queue";
    begin
        // [FEATURE] [UT] [Workflow Event Queue]
        // [SCENARIO 414141] The related "Workflow Event Queue" should be deleted on approval of "Approval Entry".
        Initialize();

        // [GIVEN] Two "Approval Entry" records 'AE1' and 'AE2', each has a related "Workflow Event Queue" record 'WEQ1' and 'WEQ2'
        CreateApprovalEntry(ApprovalEntry[1], '');
        WorkflowEventQueue[1]."Record ID" := ApprovalEntry[1].RecordId;
        WorkflowEventQueue[1].Insert(true);

        CreateApprovalEntry(ApprovalEntry[2], '');
        WorkflowEventQueue[2]."Record ID" := ApprovalEntry[2].RecordId;
        WorkflowEventQueue[2].Insert(true);

        // [WHEN] Change Status of 'AE1' to 'Approved'
        ApprovalEntry[1].Validate(Status, ApprovalEntry[1].Status::Approved);

        // [THEN] 'WEQ1' is deleted, 'WEQ2' exists
        Assert.IsFalse(WorkflowEventQueue[1].Find(), 'WorkflowEventQueue should be deleted.');
        Assert.IsTrue(WorkflowEventQueue[2].Find(), 'WorkflowEventQueue should not be deleted.');
    end;

    local procedure Initialize()
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Document Approval - Requests");
        ApprovalEntry.DeleteAll();
        UserSetup.DeleteAll();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Document Approval - Requests");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        Commit();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Document Approval - Requests");
    end;

    local procedure CreateApprovalEntry(var ApprovalEntry: Record "Approval Entry"; No: Code[20])
    begin
        Clear(ApprovalEntry);
        ApprovalEntry.Init();
        ApprovalEntry.Validate("Table ID", LibraryRandom.RandInt(100));
        ApprovalEntry.Validate("Document Type", LibraryRandom.RandIntInRange(0, 5));
        ApprovalEntry.Validate("Document No.", No);
        ApprovalEntry.Validate("Sequence No.", LibraryRandom.RandInt(100));
        ApprovalEntry.Validate(Status, ApprovalEntry.Status::Open);
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry.Insert(true);
    end;

    local procedure CreateApprovalEntryPurchaseInvoice(var ApprovalEntry: Record "Approval Entry"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, No);
        PurchaseHeader.CalcFields(Amount);
        Clear(ApprovalEntry);
        ApprovalEntry.Init();
        ApprovalEntry.Validate("Table ID", DATABASE::"Purchase Header");
        ApprovalEntry.Validate("Document Type", EnumAssignmentMgt.GetPurchApprovalDocumentType(PurchaseHeader."Document Type"));
        ApprovalEntry.Validate("Document No.", PurchaseHeader."No.");
        ApprovalEntry.Validate("Sequence No.", LibraryRandom.RandInt(100));
        ApprovalEntry.Validate(Amount, PurchaseHeader.Amount);
        ApprovalEntry.Validate(Status, ApprovalEntry.Status::Open);
        ApprovalEntry."Approver ID" := UserId;
        ApprovalEntry."Record ID to Approve" := PurchaseHeader.RecordId;
        ApprovalEntry.Insert(true);
    end;

    local procedure CreateUserSetup(var UserSetup: Record "User Setup"; UserID: Code[50]; SubstituteUserID: Code[50])
    begin
        UserSetup.Init();
        UserSetup."User ID" := UserID;
        UserSetup.Substitute := SubstituteUserID;
        UserSetup.Insert();
    end;

    local procedure CreateMultipleApprovalEntries(var DocNo: array[4] of Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
        i: Integer;
    begin
        for i := 1 to ArrayLen(DocNo) do begin
            DocNo[i] := LibraryUtility.GenerateGUID();
            CreateApprovalEntry(ApprovalEntry, DocNo[i]);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnRejectApprovalRequest', '', false, false)]
    local procedure ModifyApprovalEntryOnRejectApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    var
        LocalApprovalEntry: Record "Approval Entry";
    begin
        LocalApprovalEntry.Get(ApprovalEntry."Entry No.");
        LocalApprovalEntry.Validate(Amount, LibraryRandom.RandIntInRange(10, 100));
        LocalApprovalEntry.Modify(true);
        Commit();
    end;
}

