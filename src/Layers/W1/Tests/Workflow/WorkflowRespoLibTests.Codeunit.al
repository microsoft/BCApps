codeunit 134310 "Workflow Respo. Lib. Tests"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = im,
                  TableData "Workflow - Record Change" = i;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Response]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowMgt: Codeunit "Workflow Management";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CreateAppReqrespDescForApproverChainTxt: Label 'Create an approval request for the record using approver type Approver and approver limit type Approver Chain.';
        CreateAppReqrespDescForUserGrpTxt: Label 'Create an approval request for the record using approver type Workflow User Group and workflow user group code %1.', Comment = '%1 is a code. Example: GU00001';
        CreateNotificationForUserTxt: Label 'Create a notification for %1.', Comment = '%1 = User Id';
        ShowMessageTestMsg: Label 'This is just a test message.';
        RecordRestrictedErr: Label 'You cannot use %1 for this action.', Comment = '%1 = Record ID. You cannot use Customer 10000 for this action.';
        RecHasBeenApprovedMsg: Label 'has been approved.';
        PendingApprovalMsg: Label 'An approval request has been sent.';
        SenderTok: Label '<Sender>';
        ApplyNewValuesTestMsg: Label 'The current value of the field is different from the value before the change.';
        NoRecordChangesFoundMsg: Label 'No record changes exist to apply the saved values to using the current options.';
        IsInitialized: Boolean;
        UserIdNotInSetupErr: Label 'User ID %1 does not exist in the Approval User Setup window.', Comment = '%1 = UserID. User ID NAVUser does not exist in the Approval User Setup window.';
        UnsupportedRecordTypeErr: Label 'Record type %1 is not supported by this workflow response.', Comment = '%1 = Table Caption. Record type Item is not supported by this workflow response.';
        CannotReleaseErr: Label 'This document can only be released when the approval process is complete.';

    [Test]
    procedure SendNotificationEntryWithoutApprovalStep()
    var
        Item: Record Item;
        NotificationEntry: Record "Notification Entry";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        ItemCard: TestPage "Item Card";
    begin
        // A notification entry can be created even when no approval step is present.
        Initialize();
        NotificationEntry.DeleteAll();
        LibraryWorkflow.DisableAllWorkflows();

        // [GIVEN] a user setup for the current user
        CreateOrFindCurrentUserSetup();


        // [Given] An Item
        LibraryInventory.CreateItem(Item); // inserts an item and modifies it twice so the WF runs twice

        // [GIVEN] An enabled workflow that sends a notification when an item is edited.
        CreateNotifyOnItemChangeWorkflow();

        // [WHEN] The item is modified
        ItemCard.OpenEdit();
        ItemCard.GoToRecord(Item);
        ItemCard.Description.SetValue('Test');
        ItemCard.OK().Invoke();

        // [THEN] A notification entry is created (no error is thrown)
        Assert.RecordIsNotEmpty(WorkflowStepInstanceArchive);
#pragma warning disable AA0233, AA0181
        NotificationEntry.FindLast();
        Assert.AreEqual(Item.RecordId, NotificationEntry."Triggered By Record", 'Notification entry not created');
#pragma warning restore AA0233, AA0181
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePmtLineAsyncRespTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreatePmtLineAsyncRespWorkflowStepInstance: Record "Workflow Step Instance";
        JobQueueEntry: Record "Job Queue Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Create Pmt Line Async response creates a job queue entry.
        // [GIVEN] An active workflow step instance for CreatePmtLineAsync.
        // [WHEN] CreatePmtLineAsync response is executed on the given workflow step instance.
        // [THEN] A job Queue Entry is created.

        // Setup
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader);
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreatePmtLineAsyncRespWorkflowStepInstance,
          WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocAsyncCode());
        AddCreatePmtLineArgumentToStep(CreatePmtLineAsyncRespWorkflowStepInstance);
        WorkflowStepArgument.Get(CreatePmtLineAsyncRespWorkflowStepInstance.Argument);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchInvHeader, PurchInvHeader, FirstWorkflowStepInstance);

        JobQueueEntry.SetRange("Record ID to Process", WorkflowStepArgument.RecordId);
        Assert.IsTrue(JobQueueEntry.FindFirst(), 'There should be a job queue entry created');

        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);

        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // Verify.
        GenJournalLine.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
        Assert.IsTrue(GenJournalLine.FindFirst(), 'There should be a general journal line created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePmtLineRespTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreatePmtLineRespWorkflowStepInstance: Record "Workflow Step Instance";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Create Pmt Line response creates general journal line.
        // [GIVEN] An active workflow step instance for CreatePmtLine.
        // [WHEN] CreatePmtLine response is executed on the given workflow step instance.
        // [THEN] A general journal line is created.

        // Setup
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader);
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreatePmtLineRespWorkflowStepInstance,
          WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocCode());
        AddCreatePmtLineArgumentToStep(CreatePmtLineRespWorkflowStepInstance);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchInvHeader, PurchInvHeader, FirstWorkflowStepInstance);

        // Verify
        GenJournalLine.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
        Assert.IsTrue(GenJournalLine.FindFirst(), 'There should be a general journal line created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDocumentAsyncRespOnPurchaseDocTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        PostDocumentAsyncRespWorkflowStepInstance: Record "Workflow Step Instance";
        JobQueueEntry: Record "Job Queue Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Post document async response on purchase invoice posts the document.
        // [GIVEN] An active workflow step instance for PostDocumentAsync.
        // [GIVEN] A released purchase invoice.
        // [WHEN] PostDocumentAsync response is executed on the given workflow step instance.
        // [THEN] A job Queue Entry is created.

        // Setup
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader);
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, PostDocumentAsyncRespWorkflowStepInstance,
          WorkflowResponseHandling.PostDocumentAsyncCode());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify
        JobQueueEntry.SetRange("Record ID to Process", PurchaseHeader.RecordId);
        Assert.IsTrue(JobQueueEntry.FindFirst(), 'There should be a job queue entry created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDocumentAsyncRespOnSalesDocTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        PostDocumentAsyncRespWorkflowStepInstance: Record "Workflow Step Instance";
        JobQueueEntry: Record "Job Queue Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Post document async response on sales invoice posts the document.
        // [GIVEN] An active workflow step instance for PostDocumentAsync.
        // [GIVEN] A released sales invoice.
        // [WHEN] PostDocumentAsync response is executed on the given workflow step instance.
        // [THEN] A job Queue Entry is created.

        // Setup
        Initialize();
        CreateSalesInvoice(SalesHeader);
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, PostDocumentAsyncRespWorkflowStepInstance,
          WorkflowResponseHandling.PostDocumentAsyncCode());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify
        JobQueueEntry.SetRange("Record ID to Process", SalesHeader.RecordId);
        Assert.IsTrue(JobQueueEntry.FindFirst(), 'There should be a job queue entry created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDocumentAsyncRespOnUnsupportedRecordTypeTest()
    var
        Item: Record Item;
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        PostDocumentAsyncRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Post document async response on an unsuported record type throws an error.
        // [GIVEN] An active workflow step instance for PostDocumentAsync.
        // [GIVEN] An item(unsupported record type).
        // [WHEN] PostDocumentAsync response is executed on the given workflow step instance.
        // [THEN] Unsupported record type error is thrown .

        // Setup
        Initialize();
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, PostDocumentAsyncRespWorkflowStepInstance,
          WorkflowResponseHandling.PostDocumentAsyncCode());

        LibraryInventory.CreateItem(Item);

        // Excercise & verify
        asserterror WorkflowMgt.ExecuteResponses(Item, Item, FirstWorkflowStepInstance);
        Assert.ExpectedError(StrSubstNo(UnsupportedRecordTypeErr, Item.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDocumentRespOnPurchaseDocTest()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        PostDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        VendorNo: Code[20];
        PurchInvNo: Code[20];
    begin
        // [SCENARIO] Post document response on purchase invoice posts the document.
        // [GIVEN] An active workflow step instance for PostDocument.
        // [GIVEN] A released purchase invoice.
        // [WHEN] PostDocument response is executed on the given workflow step instance.
        // [THEN] The purchase document is posted.

        // Setup - Initialize
        Initialize();

        // Setup - Create a Purchase Invoce and Release it.
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Setup - Create the workflow
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, PostDocRespWorkflowStepInstance,
          WorkflowResponseHandling.PostDocumentCode());

        // Exercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);
        Commit();

        // Verify
        PurchInvNo := PurchaseHeader."No.";
        asserterror PurchaseHeader.Find();

        Assert.ExpectedErrorCannotFind(Database::"Purchase Header");

        PurchInvHeader.Init();
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchInvNo);
        Assert.RecordIsNotEmpty(PurchInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDocumentRespOnSalesDocTest()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        PostDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        CustomerNo: Code[20];
        SalesInvNo: Code[20];
    begin
        // [SCENARIO] Post document response on sales invoice posts the document.
        // [GIVEN] An active workflow step instance for PostDocument.
        // [GIVEN] A released sales invoice.
        // [WHEN] PostDocument response is executed on the given workflow step instance.
        // [THEN] The sales document is posted.

        // Setup - Initialize
        Initialize();

        // Setup - Create a Purchase Invoce and Release it.
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Setup - Create the workflow
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, PostDocRespWorkflowStepInstance,
          WorkflowResponseHandling.PostDocumentCode());

        // Exercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);
        Commit();

        // Verify
        SalesInvNo := SalesHeader."No.";
        asserterror SalesHeader.Find();

        Assert.ExpectedErrorCannotFind(Database::"Sales Header");

        SalesInvoiceHeader.Init();
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesInvNo);
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDocumentRespOnUnsupportedRecordTypeTest()
    var
        Item: Record Item;
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        PostDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Post document response on an unsuported record type throws an error.
        // [GIVEN] An active workflow step instance for PostDocument.
        // [GIVEN] An item(unsupported record type).
        // [WHEN] PostDocument response is executed on the given workflow step instance.
        // [THEN] Unsupported record type error is thrown .

        // Setup
        Initialize();
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, PostDocRespWorkflowStepInstance,
          WorkflowResponseHandling.PostDocumentCode());

        LibraryInventory.CreateItem(Item);

        // Excercise & verify
        asserterror WorkflowMgt.ExecuteResponses(Item, Item, FirstWorkflowStepInstance);
        Assert.ExpectedError(StrSubstNo(UnsupportedRecordTypeErr, Item.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseDocumentRespOnPurchaseDocTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ReleaseDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Release document response releases the purchase document.
        // [GIVEN] An active workflow step instance for ReleaseDocument.
        // [GIVEN] A purchase invoice that can be released.
        // [WHEN] ReleaseDocument response is executed on the given workflow step instance.
        // [THEN] The purchase document is released.

        // Setup
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader);
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ReleaseDocRespWorkflowStepInstance,
          WorkflowResponseHandling.ReleaseDocumentCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify
        VerifyPurchaseInvIsReleased(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseDocumentRespOnUnApprovedPurchaseDocThrowsErrorTest()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ReleaseDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        UserSetup: Record "User Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Release document response on a document that still has unhandled approval entries
        // throws an error.
        // [GIVEN] A mock purchase approval workflow, so that the check for approval workflow
        // to be present and enabled returns true.
        // [GIVEN] An active workflow step instance for ReleaseDocument.
        // [GIVEN] A purchase invoice that can be released.
        // [GIVEN] A approval entry related to the purchase invoice that needs to be released.
        // [WHEN] ReleaseDocument response is executed on the given workflow step instance.
        // [THEN] The execution throws an error.

        // Setup
        Initialize();
        CreateOrFindUserSetup(UserSetup, UserId);
        SetUnlimitedPurchaseApprovalLimit(UserSetup);
        CreateMockPurchaseApprovalWorkflow();
        CreatePurchaseInvoice(PurchaseHeader);
        CreateApprovalEntryForPurchaseDoc(ApprovalEntry, PurchaseHeader);
        ApprovalEntry.Status := ApprovalEntry.Status::Created;
        ApprovalEntry.Modify();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ReleaseDocRespWorkflowStepInstance,
          WorkflowResponseHandling.ReleaseDocumentCode());

        // Excercise
        asserterror WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify
        Assert.ExpectedError(CannotReleaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseDocumentRespOnSalesDocTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ReleaseDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Release document response releases the sales document.
        // [GIVEN] An active workflow step instance for ReleaseDocument.
        // [GIVEN] A sales invoice that can be released.
        // [WHEN] ReleaseDocument response is executed on the given workflow step instance.
        // [THEN] The sales document is released.

        // Setup
        Initialize();
        CreateSalesInvoice(SalesHeader);
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ReleaseDocRespWorkflowStepInstance,
          WorkflowResponseHandling.ReleaseDocumentCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify
        VerifySalesInvIsReleased(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseDocumentRespOnUnApprovedSalesDocThrowsErrorTest()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ReleaseDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Release document response on a document that still has unhandled approval entries
        // throws an error.
        // [GIVEN] A mock purchase approval workflow, so that the check for approval workflow
        // to be present and enabled returns true.
        // [GIVEN] An active workflow step instance for ReleaseDocument.
        // [GIVEN] A sales invoice that can be released.
        // [GIVEN] A approval entry related to the sales invoice that needs to be released.
        // [WHEN] ReleaseDocument response is executed on the given workflow step instance.
        // [THEN] The execution throws an error.

        // Setup
        Initialize();
        CreateOrFindUserSetup(UserSetup, UserId);
        SetUnlimitedSalesApprovalLimit(UserSetup);
        CreateMockSalesApprovalWorkflow();
        CreateSalesInvoice(SalesHeader);
        CreateApprovalEntryForSalesDoc(ApprovalEntry, SalesHeader);
        ApprovalEntry.Status := ApprovalEntry.Status::Created;
        ApprovalEntry.Modify();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ReleaseDocRespWorkflowStepInstance,
          WorkflowResponseHandling.ReleaseDocumentCode());

        // Excercise
        asserterror WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify
        Assert.ExpectedError(CannotReleaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseDocumentRespOnApprovalEntryToPurchDocTest()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ReleaseDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Release document response on approval entry, picks the document
        // related to the approval entry and releases it.
        // [GIVEN] An active workflow step instance for ReleaseDocument.
        // [GIVEN] A approval entry that points to a purchase invoice that can be released.
        // [WHEN] ReleaseDocument response is executed on the given workflow step instance.
        // [THEN] The purchase document is released.

        // Setup
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader);
        CreateApprovalEntryForPurchaseDoc(ApprovalEntry, PurchaseHeader);
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ReleaseDocRespWorkflowStepInstance,
          WorkflowResponseHandling.ReleaseDocumentCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);

        // Verify
        VerifyPurchaseInvIsReleased(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseDocumentRespOnApprovalEntryToSalesDocTest()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ReleaseDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Release document response on approval entry, picks the document
        // related to the approval entry and releases it.
        // [GIVEN] An active workflow step instance for ReleaseDocument.
        // [GIVEN] A approval entry that points to a sales invoice that can be released.
        // [WHEN] ReleaseDocument response is executed on the given workflow step instance.
        // [THEN] The sales document is released.

        // Setup
        Initialize();
        CreateSalesInvoice(SalesHeader);
        CreateApprovalEntryForSalesDoc(ApprovalEntry, SalesHeader);
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ReleaseDocRespWorkflowStepInstance,
          WorkflowResponseHandling.ReleaseDocumentCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);

        // Verify
        VerifySalesInvIsReleased(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseDocumentRespOnUnsupportedRecordTypeTest()
    var
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ReleaseDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        Item: Record Item;
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Release document response on an unsuported record type throws an error.
        // [GIVEN] An active workflow step instance for ReleaseDocument.
        // [GIVEN] An item(unsupported record type).
        // [WHEN] ReleaseDocument response is executed on the given workflow step instance.
        // [THEN] Unsupported record type error is thrown .

        // Setup
        Initialize();
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ReleaseDocRespWorkflowStepInstance,
          WorkflowResponseHandling.ReleaseDocumentCode());

        LibraryInventory.CreateItem(Item);

        // Excercise & verify
        asserterror WorkflowMgt.ExecuteResponses(Item, Item, FirstWorkflowStepInstance);
        Assert.ExpectedError(StrSubstNo(UnsupportedRecordTypeErr, Item.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenDocumentRespOnPurchaseDocTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        OpenDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Open document respons opens the released purchase document.
        // [GIVEN] An active workflow step instance for OpenDocument.
        // [GIVEN] A purchase invoice that is released.
        // [WHEN] OpenDocument response is executed on the given workflow step instance.
        // [THEN] The purchase document is reopened.

        // Setup
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Status := PurchaseHeader.Status::Released;
        PurchaseHeader.Modify();

        // Excercise
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, OpenDocRespWorkflowStepInstance,
          WorkflowResponseHandling.OpenDocumentCode());

        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify
        VerifyPurchaseInvIsOpen(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenDocumentRespOnSalesDocTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        OpenDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Open document response opens the released sales document.
        // [GIVEN] An active workflow step instance for OpenDocument.
        // [GIVEN] A sales invoice that is released.
        // [WHEN] OpenDocument response is executed on the given workflow step instance.
        // [THEN] The sales document is reopened.

        // Setup
        Initialize();
        CreateSalesInvoice(SalesHeader);
        SalesHeader.Status := SalesHeader.Status::Released;
        SalesHeader.Modify();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, OpenDocRespWorkflowStepInstance,
          WorkflowResponseHandling.OpenDocumentCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify
        VerifySalesInvIsOpen(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenDocumentRespOnApprovalEntryToPurchDocTest()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        OpenDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Open document response on approval entry, picks the document
        // related to the approval entry and reopens it.
        // [GIVEN] An active workflow step instance for OpenDocument.
        // [GIVEN] A approval entry that points to a purchase invoice that is released.
        // [WHEN] OpenDocument response is executed on the given workflow step instance.
        // [THEN] The purchase document is reopened.

        // Setup
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Status := PurchaseHeader.Status::Released;
        PurchaseHeader.Modify();

        CreateApprovalEntryForPurchaseDoc(ApprovalEntry, PurchaseHeader);
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, OpenDocRespWorkflowStepInstance,
          WorkflowResponseHandling.OpenDocumentCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);

        // Verify
        VerifyPurchaseInvIsOpen(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenDocumentRespOnApprovalEntryToSalesDocTest()
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        OpenDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Open document response on approval entry, picks the document
        // related to the approval entry and reopens it.
        // [GIVEN] An active workflow step instance for OpenDocument.
        // [GIVEN] A approval entry that points to a sales invoice that is released.
        // [WHEN] OpenDocument response is executed on the given workflow step instance.
        // [THEN] The sales document is reopened.

        // Setup
        Initialize();
        CreateSalesInvoice(SalesHeader);
        SalesHeader.Status := SalesHeader.Status::Released;
        SalesHeader.Modify();
        CreateApprovalEntryForSalesDoc(ApprovalEntry, SalesHeader);

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, OpenDocRespWorkflowStepInstance,
          WorkflowResponseHandling.OpenDocumentCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);

        // Verify
        VerifySalesInvIsOpen(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenDocumentRespOnUnsupportedRecordTypeTest()
    var
        Item: Record Item;
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        OpenDocRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Open document response on an unsupported record type throws an error.
        // [GIVEN] An active workflow step instance for OpenDocument.
        // [GIVEN] A item(unsupported record type).
        // [WHEN] OpenDocument response is executed on the given workflow step instance.
        // [THEN] Unsupported record type error is thrown .

        // Setup
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, OpenDocRespWorkflowStepInstance,
          WorkflowResponseHandling.OpenDocumentCode());

        LibraryInventory.CreateItem(Item);

        // Excercise & verify
        asserterror WorkflowMgt.ExecuteResponses(Item, Item, FirstWorkflowStepInstance);
        Assert.ExpectedError(StrSubstNo(UnsupportedRecordTypeErr, Item.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetApprovalCommentRespOnPurchaseDocTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        GetCommentRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        LibraryUtility: Codeunit "Library - Utility";
        ApprovalComments: TestPage "Approval Comments";
        CommentTxt: Text[80];
    begin
        // [SCENARIO] Get approval comment response opens the Get Comment page and collects the
        // comments for related document.
        // [GIVEN] An active workflow step instance for GetApprovlComment.
        // [GIVEN] A purchase document.
        // [WHEN] GetApprovalComment response is executed on the given workflow step instance.
        // [THEN] The Get Comment page opens up and stores the comments for related document.

        // Setup
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader);

        CommentTxt := CopyStr(LibraryUtility.GenerateRandomText(20), 1, 20);

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, GetCommentRespWorkflowStepInstance,
          WorkflowResponseHandling.GetApprovalCommentCode());

        // Excercise
        ApprovalComments.Trap();
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);
        ApprovalComments.Comment.Value(CommentTxt);
        ApprovalComments.OK().Invoke();

        // Verify
        VerifyApprovalCommentLineForPurchInv(PurchaseHeader, CommentTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetApprovalCommentRespOnSalesDocTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        GetCommentRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        LibraryUtility: Codeunit "Library - Utility";
        ApprovalComments: TestPage "Approval Comments";
        CommentTxt: Text[80];
    begin
        // [SCENARIO] Get approval comment response opens the Get Comment page and collects the
        // comments for related document.
        // [GIVEN] An active workflow step instance for GetApprovlComment.
        // [GIVEN] A purchase document.
        // [WHEN] GetApprovalComment response is executed on the given workflow step instance.
        // [THEN] The Get Comment page opens up and stores the comments for related document.

        // Setup
        Initialize();
        CreateSalesInvoice(SalesHeader);
        CommentTxt := CopyStr(LibraryUtility.GenerateRandomText(20), 1, 20);

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, GetCommentRespWorkflowStepInstance,
          WorkflowResponseHandling.GetApprovalCommentCode());

        // Excercise
        ApprovalComments.Trap();
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);
        ApprovalComments.Comment.Value(CommentTxt);
        ApprovalComments.OK().Invoke();

        // Verify
        VerifyApprovalCommentLineForSalesInv(SalesHeader, CommentTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetApprovalCommentRespOnApprovalEntryTest()
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        GetCommentRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        LibraryUtility: Codeunit "Library - Utility";
        ApprovalComments: TestPage "Approval Comments";
        CommentTxt: Text[80];
    begin
        // [SCENARIO] Get approval comment response opens the Get Comment page and collects the
        // comments for related document.
        // [GIVEN] An active workflow step instance for GetApprovalComment.
        // [GIVEN] A purchase document.
        // [WHEN] GetApprovalComment response is executed on the given workflow step instance.
        // [THEN] The Get Comment page opens up and stores the comments for related document.

        // Setup
        Initialize();
        CommentTxt := CopyStr(LibraryUtility.GenerateRandomText(20), 1, 20);
        CreatePurchaseInvoice(PurchaseHeader);
        CreateApprovalEntryForPurchaseDoc(ApprovalEntry, PurchaseHeader);

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, GetCommentRespWorkflowStepInstance,
          WorkflowResponseHandling.GetApprovalCommentCode());

        // Excercise
        ApprovalComments.Trap();
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);
        ApprovalComments.Comment.Value(CommentTxt);
        ApprovalComments.OK().Invoke();

        // Verify
        VerifyApprovalCommentLineForPurchInv(PurchaseHeader, CommentTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetApprovalCommentRespOnOtherRecordTypeTest()
    var
        Item: Record Item;
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        GetCommentRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        ApprovalComments: TestPage "Approval Comments";
        CommentTxt: Text[80];
    begin
        // [SCENARIO] Get Approval Comment can be executed on a record type other than sales and purch. docs
        // [GIVEN] An active workflow step instance for GetApprovalComment.
        // [GIVEN] An item
        // [WHEN] OpenDocument response is executed on the given workflow step instance.
        // [THEN] Comment page is opened.

        // Setup
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, GetCommentRespWorkflowStepInstance,
          WorkflowResponseHandling.GetApprovalCommentCode());
        CommentTxt := CopyStr(LibraryUtility.GenerateRandomText(20), 1, 20);
        LibraryInventory.CreateItem(Item);

        // Exercise.
        ApprovalComments.Trap();
        WorkflowMgt.ExecuteResponses(Item, Item, FirstWorkflowStepInstance);
        ApprovalComments.Comment.Value(CommentTxt);
        ApprovalComments.OK().Invoke();

        // Verify.
        VerifyApprovalCommentLineForItem(Item, CommentTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesDocStatusToPendingApprovalTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SetDocStatusRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Set document status to Pending approval response
        // [GIVEN] An active workflow step instance for SetDocumentStatusToPendingApproval.
        // [GIVEN] A Sales Document
        // [WHEN] SetDocumentStatusToPendingApprova response is executed on the given workflow step instance.
        // [THEN] Document status is changed to Pending Approval.

        // Setup
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, SetDocStatusRespWorkflowStepInstance,
          WorkflowResponseHandling.SetStatusToPendingApprovalCode());

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // Exercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify
        SalesHeader.Find();
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Approval");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePurchDocStatusToPendingApprovalTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SetDocStatusRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Set document status to Pending approval response
        // [GIVEN] An active workflow step instance for SetDocumentStatusToPendingApproval.
        // [GIVEN] A Purchase Document
        // [WHEN] SetDocumentStatusToPendingApproval response is executed on the given workflow step instance.
        // [THEN] Document status is changed to Pending Approval.

        // Setup
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, SetDocStatusRespWorkflowStepInstance,
          WorkflowResponseHandling.SetStatusToPendingApprovalCode());

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        // Exercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::"Pending Approval");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespWithApproverTypeAndAllApprovalLimitTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is approver and
        // Limit type is approval creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.
        // [GIVEN] A purchase invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The three approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice where amount is 5000.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"Approver Chain", DueDateFormula, '', false);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - 3 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        Assert.RecordCount(ApprovalEntry, 3);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver1UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 2);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver2UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 3);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespWithApproverTypeAndNoLimitTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is approver and
        // Limit type is no limit creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.
        // [GIVEN] A purchase invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The three approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice where amount is 5000.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", DueDateFormula, '', false);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - 3 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        Assert.RecordCount(ApprovalEntry, 1);

        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver1UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespWithApproverTypeAndLastApprovalLimitTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is approver and
        // Limit type is Approval Limit - Last Approver creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.
        // [GIVEN] A purchase invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] Two approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice where amount is 5000.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        LibrarySales.CreateSalesperson(SalespersonPurchaser); // TFS 381808
        UpdatePurchaseDocPurchaserCode(PurchaseHeader, SalespersonPurchaser.Code);

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", DueDateFormula, '', false);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - 2 approval request are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        Assert.RecordCount(ApprovalEntry, 2);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver2UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 2);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespWithApproverTypeAndSpeificApproverTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument1: Record "Workflow Step Argument";
        ApproverUserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is approver and
        // Limit type is Specific Approver Approver creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with a user.
        // [GIVEN] A purchase invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] One approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);

        // Setup - Create purchase invoice where amount is 5000.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument1."Approver Type"::Approver,
          WorkflowStepArgument1."Approver Limit Type"::"Specific Approver", DueDateFormula, '', false);
        WorkflowStepArgument1.Get(CreateApprReqRespWorkflowStepInstance.Argument);
        WorkflowStepArgument1.Validate("Approver User ID", ApproverUserSetup."User ID");
        WorkflowStepArgument1.Modify(true);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - 1 approval request is created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        Assert.AreEqual(1, ApprovalEntry.Count, 'Unexpected number of approval entries found');

        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, ApproverUserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespWithPurchaserTypeAndAllApprovalLimitTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is purchaser and
        // Limit type is approval creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.
        // [GIVEN] A purchase invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] Two approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice where amount is 5000.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdatePurchaseDocPurchaserCode(PurchaseHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
          WorkflowStepArgument."Approver Limit Type"::"Approver Chain", DueDateFormula, '', false);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - 2 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        Assert.RecordCount(ApprovalEntry, 2);

        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver1UserSetup."User ID",
          ApprovalEntry."Approval Type"::"Sales Pers./Purchaser", ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver2UserSetup."User ID",
          ApprovalEntry."Approval Type"::"Sales Pers./Purchaser", ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 2);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespWithPurchaserTypeAndNoLimitTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is approver and
        // Limit type is approval creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.
        // [GIVEN] A purchase invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The three approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice where amount is 5000.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdatePurchaseDocPurchaserCode(PurchaseHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", DueDateFormula, '', false);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - 3 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        Assert.RecordCount(ApprovalEntry, 1);

        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver1UserSetup."User ID",
          ApprovalEntry."Approval Type"::"Sales Pers./Purchaser", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespWithPurchaserTypeAndLastApprovalLimitTest()
    var
        UserSetup: Record "User Setup";
        ApproversUserSetup: array[2] of Record "User Setup";
        PurchaseHeader: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
        Limit: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 377860] Create approval requests response when "Approver type" is "Salesperson/Purchaser" and
        // [SCENARIO] "Approver Limit Type" is "First Qualified Approver" the right amount of approval requests.

        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.

        Initialize();

        // [GIVEN] "User A" with approval limit 100 and "Approver ID" = "User B" and "Purchaser Code" = "X"
        // [GIVEN] "User B" with approval limit 1000
        // [GIVEN] "User C" - sender approval request
        Limit := LibraryRandom.RandIntInRange(100, 200);
        CreateThreeUserSetupWithApproverChainFirstQualified(UserSetup, ApproversUserSetup, Limit);

        // [GIVEN] Purchase Invoice is created by "User C" with "Purchaser Code" = "X" and Amount= 200
        CreatePurchInvWithLine(PurchaseHeader, Limit * 2);
        UpdatePurchaseDocPurchaserCode(PurchaseHeader, ApproversUserSetup[1]."Salespers./Purch. Code");

        // [WHEN] Send Approval Request
        CreateWorkflowStepInstanceWithTwoResponses(
          FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance, WorkflowResponseHandling.CreateApprovalRequestsCode());
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(
          CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
          WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", DueDateFormula, '', false);
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // [THEN] One approval request is created. (TFS 377860)
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        ApprovalEntry.SetRange("Approver ID", ApproversUserSetup[2]."User ID");
        Assert.RecordCount(ApprovalEntry, 1);

        // [THEN] Approval entry is created for "User B" with status "Created"
        ApprovalEntry.FindFirst();
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Created);

        // [THEN] Approval entry is not created for "User C" and "User A"
        ApprovalEntry.SetRange("Approver ID", UserSetup."User ID");
        Assert.RecordIsEmpty(ApprovalEntry);
        ApprovalEntry.SetRange("Approver ID", ApproversUserSetup[1]."User ID");
        Assert.RecordIsEmpty(ApprovalEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesApprReqRespWithApproverTypeAndAllApprovalLimitTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is approver and
        // Limit type is approval creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.
        // [GIVEN] A sales invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The three approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create sales invoice.
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"Approver Chain", DueDateFormula, '', false);

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify - 3 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."No.");
        Assert.RecordCount(ApprovalEntry, 3);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver1UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 2);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver2UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 3);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesApprReqRespWithApproverTypeAndNoLimitTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is approver and
        // Limit type is no limit creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.
        // [GIVEN] A sales invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The three approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice where amount is 5000.
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", DueDateFormula, '', false);

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify - 3 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."No.");
        Assert.RecordCount(ApprovalEntry, 1);

        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver1UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesApprReqRespWithApproverTypeAndLastApprovalLimitTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is approver and
        // Limit type is approval creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.
        // [GIVEN] A sales invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] Two approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create sales invoice.
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        LibrarySales.CreateSalesperson(SalespersonPurchaser); // TFS 381808
        UpdateSalesDocSalespersonCode(SalesHeader, SalespersonPurchaser.Code);

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", DueDateFormula, '', false);

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify - 2 approval request are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."No.");
        Assert.RecordCount(ApprovalEntry, 2);

        VerifyApprovalEntryIsApproved(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver2UserSetup."User ID",
          ApprovalEntry."Approval Type"::Approver, ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 2);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesApprReqRespWithSalespersonTypeAndAllApprovalLimitTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is purchaser and
        // Limit type is approval creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.
        // [GIVEN] A sales invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] Two approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice where amount is 5000.
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdateSalesDocSalespersonCode(SalesHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
          WorkflowStepArgument."Approver Limit Type"::"Approver Chain", DueDateFormula, '', false);

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify - 2 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."No.");
        Assert.RecordCount(ApprovalEntry, 2);

        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver1UserSetup."User ID",
          ApprovalEntry."Approval Type"::"Sales Pers./Purchaser", ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver2UserSetup."User ID",
          ApprovalEntry."Approval Type"::"Sales Pers./Purchaser", ApprovalEntry."Limit Type"::"Approval Limits", DueDateFormula, 2);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesApprReqRespWithSalespersonTypeAndNoLimitTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is approver and
        // Limit type is approval creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.
        // [GIVEN] A sales invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The three approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice where amount is 5000.
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdateSalesDocSalespersonCode(SalesHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", DueDateFormula, '', false);

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify - 3 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."No.");
        Assert.RecordCount(ApprovalEntry, 1);

        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserSetup."User ID", Approver1UserSetup."User ID",
          ApprovalEntry."Approval Type"::"Sales Pers./Purchaser", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesApprReqRespWithSalespersonTypeAndLastApprovalLimitTest()
    var
        UserSetup: Record "User Setup";
        ApproversUserSetup: array[2] of Record "User Setup";
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
        Limit: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 377860] Create approval requests response when "Approver type" is "Salesperson/Purchaser" and
        // [SCENARIO] "Approver Limit Type" is "First Qualified Approver" the right amount of approval requests.

        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with 3 users and in approval chain.

        Initialize();

        // [GIVEN] "User A" with approval limit 100 and "Approver ID" = "User B" and "Salesperson Code" = "X"
        // [GIVEN] "User B" with approval limit 1000
        // [GIVEN] "User C" - sender approval request
        Limit := LibraryRandom.RandIntInRange(100, 200);
        CreateThreeUserSetupWithApproverChainFirstQualified(UserSetup, ApproversUserSetup, Limit);

        // [GIVEN] Sales Invoice is created by "User C" with "Salesperson Code" = "X" and Amount= 200
        CreateSalesInvWithLine(SalesHeader, Limit * 2);
        UpdateSalesDocSalespersonCode(SalesHeader, ApproversUserSetup[1]."Salespers./Purch. Code");

        // [WHEN] Send Approval Request
        CreateWorkflowStepInstanceWithTwoResponses(
          FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance, WorkflowResponseHandling.CreateApprovalRequestsCode());
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(
          CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
          WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", DueDateFormula, '', false);
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // [THEN] One approval request is created. (TFS 377860)
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."No.");
        ApprovalEntry.SetRange("Approver ID", ApproversUserSetup[2]."User ID");
        Assert.RecordCount(ApprovalEntry, 1);

        // [THEN] Approval entry is created for "User B" with status "Open"
        ApprovalEntry.FindFirst();
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Created);

        // [THEN] Approval entry is not created for "User A" and "User C"
        ApprovalEntry.SetRange("Approver ID", ApproversUserSetup[1]."User ID");
        Assert.RecordIsEmpty(ApprovalEntry);
        ApprovalEntry.SetRange("Approver ID", UserSetup."User ID");
        Assert.RecordIsEmpty(ApprovalEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesApprReqRespWithSalespersonTypeAndSpecificApproverTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is purchaser and
        // Limit type is specific approver creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] 2 user setups.
        // [GIVEN] A sales invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] Two approval requests are created.

        // Setup - Cleanup
        Initialize();

        // Setup - Create approvers
        LibraryDocumentApprovals.CreateMockupUserSetup(Approver1UserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(Approver2UserSetup);

        // Setup - Create purchase invoice where amount is 5000.
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdateSalesDocSalespersonCode(SalesHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
          WorkflowStepArgument."Approver Limit Type"::"Specific Approver", DueDateFormula, '', false);
        WorkflowStepArgument.Get(CreateApprReqRespWorkflowStepInstance.Argument);
        WorkflowStepArgument.Validate("Approver User ID", Approver2UserSetup."User ID");
        WorkflowStepArgument.Modify(true);

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify - 2 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."No.");
        Assert.AreEqual(2, ApprovalEntry.Count, 'Unexpected number of approval entries found');

        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, Approver1UserSetup."User ID",
          ApprovalEntry."Approval Type"::"Sales Pers./Purchaser", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 1);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, Approver2UserSetup."User ID",
          ApprovalEntry."Approval Type"::"Sales Pers./Purchaser", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 2);
        ApprovalEntry.TestField("Approval Code", FirstWorkflowStepInstance."Workflow Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesApprReqRespWithSalespersonTypeAndNoSalesPersonCodeThrowsErrorTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is purchaser and
        // Limit type is specific approver creates the right amount of approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] 2 user setups.
        // [GIVEN] A sales invoice without a Sales Person Code defined.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] An error is thrown.

        // Setup - Cleanup
        Initialize();

        // Setup - Create approvers
        LibraryDocumentApprovals.CreateMockupUserSetup(Approver1UserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(Approver2UserSetup);

        // Setup - Create purchase invoice where amount is 5000.
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser",
          WorkflowStepArgument."Approver Limit Type"::"Specific Approver", DueDateFormula, '', false);
        WorkflowStepArgument.Get(CreateApprReqRespWorkflowStepInstance.Argument);
        WorkflowStepArgument.Validate("Approver User ID", Approver2UserSetup."User ID");
        WorkflowStepArgument.Modify(true);

        // Excercise
        asserterror WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify
        Assert.ExpectedError('Salespers./Purch. Code must have a value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespDescForApproverTypeAndApproverChainLimitTest()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        Description: Text;
    begin
        // [SCENARIO] Description for 'Create approval requests' response when approver type is approver and
        // Limit type is approval chain lists out approver type and limit type argument values.
        // [GIVEN] Create Approval Requests response.
        // [GIVEN] Step Argument setup to approver and approver chain.
        // [WHEN] GetDescription is called on the CreateApprovalRequests response.
        // [THEN] It returns a description where the approver type and approver limit type is listed out.

        // Setup - Cleanup
        Initialize();

        LibraryWorkflow.CreateWorkflowStepArgument(WorkflowStepArgument, WorkflowStepArgument.Type::Response,
          '', '', '', WorkflowStepArgument."Approver Type"::Approver, true);
        WorkflowStepArgument.Validate("Approver Limit Type", WorkflowStepArgument."Approver Limit Type"::"Approver Chain");
        WorkflowStepArgument.Validate("Response Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        WorkflowStepArgument.Modify(true);

        // Excercise
        Description := WorkflowResponseHandling.GetDescription(WorkflowStepArgument);

        // Verify - Description
        Assert.AreEqual(Format(CreateAppReqrespDescForApproverChainTxt), Description, 'Description text is not built as expected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespDescForUserGroupApproverTypeTest()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        Description: Text;
    begin
        // [SCENARIO] Description for 'Create approval requests' response when approver type is workflow user group
        // lists out approver type and limit type argument values.
        // [GIVEN] Create Approval Requests response.
        // [GIVEN] Step Argument setup to workflow user group type with a valid user group code.
        // [WHEN] GetDescription is called on the CreateApprovalRequests response.
        // [THEN] It returns a description where the approver type and approver limit type is listed out.

        // Setup - Cleanup
        Initialize();

        CreateWorkflowUserGroup(WorkflowUserGroup);

        LibraryWorkflow.CreateWorkflowStepArgument(WorkflowStepArgument, WorkflowStepArgument.Type::Response,
          '', '', '', WorkflowStepArgument."Approver Type"::"Workflow User Group", true);
        WorkflowStepArgument.Validate("Workflow User Group Code", WorkflowUserGroup.Code);
        WorkflowStepArgument.Validate("Response Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        WorkflowStepArgument.Modify(true);

        // Excercise
        Description := WorkflowResponseHandling.GetDescription(WorkflowStepArgument);

        // Verify - Description
        Assert.AreEqual(StrSubstNo(CreateAppReqrespDescForUserGrpTxt, WorkflowUserGroup.Code),
          Description, 'Description text is not built as expected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespDescForNotifySenderTest()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        Description: Text;
    begin
        // [SCENARIO] Description for 'Create notification entry' response when "Notify Sender" is 'Yes'.

        // Setup - Cleanup
        Initialize();

        // [GIVEN] Create CreateNotificationEntry response.
        LibraryWorkflow.CreateWorkflowStepArgument(WorkflowStepArgument, WorkflowStepArgument.Type::Response,
          '', '', '', WorkflowStepArgument."Approver Type"::Approver, true);
        WorkflowStepArgument.Validate("Response Function Name", WorkflowResponseHandling.CreateNotificationEntryCode());
        WorkflowStepArgument.Validate("Notify Sender", true);
        WorkflowStepArgument.Modify(true);

        // [WHEN] GetDescription is called on the CreateNotificationEntry response.
        Description := WorkflowResponseHandling.GetDescription(WorkflowStepArgument);

        // [THEN] It returns 'Create a notification for <Sender>.' 
        Assert.AreEqual(StrSubstNo(CreateNotificationForUserTxt, SenderTok), Description, 'Description text is not built as expected.');
    end;

    [Test]
    [HandlerFunctions('RecordApprovedMessageHandler')]
    [Scope('OnPrem')]
    procedure ApprovalMessageOnCreateApprReqRespWithNoPendingRequestTest()
    var
        Customer: Record Customer;
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response with approval status message enabled and
        // there are no pending approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A user setup with unlimited approval limit.
        // [GIVEN] A customer.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The message informing that the record has been approved is shown.

        // Setup - Cleanup
        Initialize();

        // Setup - Create UserSetup with unlimited approval limit
        CreateOrFindUserSetup(UserSetup, UserId);
        SetUnlimitedPurchaseApprovalLimit(UserSetup);

        // Setup - Create a customer.
        LibrarySales.CreateCustomer(Customer);

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"Approver Chain", DueDateFormula, '', true);

        // Excercise
        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);

        // Verification is done in the message handler
    end;

    [Test]
    [HandlerFunctions('PendingApprovalMessageHandler')]
    [Scope('OnPrem')]
    procedure ApprovalMessageCreateApprReqRespWithPendingRequestTest()
    var
        Customer: Record Customer;
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response with approval status message enabled and
        // there are pending approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A approval chain setup.
        // [GIVEN] A customer.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The message informing that an approval request has been sent for approval is shown.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create a customer.
        LibrarySales.CreateCustomer(Customer);

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", DueDateFormula, '', true);

        // Excercise
        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);

        // Verification is done in the message handæer
    end;

    [Test]
    [HandlerFunctions('PendingApprovalMessageHandler')]
    [Scope('OnPrem')]
    procedure ApprovalMessageCreateApprReqRespRecordChangeTest()
    var
        Customer: Record Customer;
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response for record change with approval status message enabled and
        // there are pending approval requests.
        // [GIVEN] An active workflow step instance for CreateApprovalRequsts.
        // [GIVEN] A approval chain setup.
        // [GIVEN] A customer.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The message informing that an approval request has been sent for approval is shown.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create a customer.
        LibrarySales.CreateCustomer(Customer);

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create Change Record
        CreateWorkflowCustomerRecordChange(Customer, Customer.FieldNo("Credit Limit (LCY)"),
          Format(Customer."Credit Limit (LCY)"), Format(Customer."Credit Limit (LCY)" + 10.0), FirstWorkflowStepInstance.ID);

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", DueDateFormula, '', true);

        // Excercise
        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);

        // Verification is done in the message handæer
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendForApprovalTestWithNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
    begin
        // [SCENARIO] Send for approval response with notification template defined.
        // [GIVEN] An active workflow step instance for SendForApproval.
        // [GIVEN] A user setup with 3 users and approval chain.
        // [GIVEN] A purchase invoice.
        // [WHEN] SendForApprova response is executed on the given workflow step instance.
        // [THEN] The approval entries change status.
        // [THEN] A notification gets created for the approver.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdatePurchaseDocPurchaserCode(PurchaseHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithSendForApprovalResponse(FirstWorkflowStepInstance, SendForApprovalWorkflowStepInstance);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - approval requests.
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.IsTrue(ApprovalEntry.FindFirst(), 'There should be at least one open approval entry.');
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, Approver1UserSetup."User ID");

        // Verify - Notification.
        VerifyNotificationEntry(ApprovalEntry."Approver ID", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendForApprovalToSequentialWorkflowUserGroupTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance";
        ApprovalEntry: Record "Approval Entry";
        UserSetup1: Record "User Setup";
        UserSetup2: Record "User Setup";
        UserSetup3: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
    begin
        // [SCENARIO] Send for approval response with sequential user group.
        // [GIVEN] An active workflow step instance for SendForApproval.
        // [GIVEN] A user group setup with 3 users and with different sequence numbers.
        // [GIVEN] A purchase invoice.
        // [WHEN] SendForApprova response is executed on the given workflow step instance.
        // [THEN] The approval entries change status.

        // Setup - Cleanup
        Initialize();

        CreateOrFindCurrentUserSetup();

        // Setup - WorkflowUserGroups and usersetups
        CreateThreeUserSetupWithSequentialWorkflowUserGroup(WorkflowUserGroup, UserSetup1,
          UserSetup2, UserSetup3);

        // Setup - Create purchase invoice.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // Setup - Create workflow response for testing
        CreateWorkflowStepInstanceWithSendForApprovalToUserGroupResponse(
          FirstWorkflowStepInstance, SendForApprovalWorkflowStepInstance, WorkflowUserGroup.Code);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - approval requests.
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        Assert.RecordCount(ApprovalEntry, 3);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.RecordCount(ApprovalEntry, 1);
        Assert.IsTrue(ApprovalEntry.FindFirst(), 'There should be at least one open approval entry.');
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, UserSetup1."User ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendForApprovalToFlatWorkflowUserGroupTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance";
        ApprovalEntry: Record "Approval Entry";
        UserSetup1: Record "User Setup";
        UserSetup2: Record "User Setup";
        UserSetup3: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
    begin
        // [SCENARIO] Send for approval response with flat user group.
        // [GIVEN] An active workflow step instance for SendForApproval.
        // [GIVEN] A user group setup with 3 users with the same sequence number.
        // [GIVEN] A purchase invoice.
        // [WHEN] SendForApprova response is executed on the given workflow step instance.
        // [THEN] The approval entries change status.

        // Setup - Cleanup
        Initialize();

        CreateOrFindCurrentUserSetup();

        // Setup - WorkflowUserGroups and usersetups
        CreateThreeUserSetupWithFlatWorkflowUserGroup(WorkflowUserGroup, UserSetup1,
          UserSetup2, UserSetup3);

        // Setup - Create purchase invoice.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // Setup - Create workflow response for testing
        CreateWorkflowStepInstanceWithSendForApprovalToUserGroupResponse(
          FirstWorkflowStepInstance, SendForApprovalWorkflowStepInstance, WorkflowUserGroup.Code);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - approval requests.
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        Assert.RecordCount(ApprovalEntry, 3);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.RecordCount(ApprovalEntry, 3);
        Assert.IsTrue(ApprovalEntry.FindFirst(), 'There should be at least one open approval entry.');
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserId);
        VerifyApprovalEntryApproverID(ApprovalEntry, UserSetup1."User ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelAllApprovalRequestsTestWithNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance";
        CancelAllWorkflowStepInstance: Record "Workflow Step Instance";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Cancel approval requests with notification template defined.
        // [GIVEN] An active workflow step instance for CancelAllApprovalRequests.
        // [GIVEN] A user setup with 3 users and approval chain.
        // [GIVEN] A purchase invoice.
        // [WHEN] CancelAllApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The approval entries change status.
        // [THEN] A notification gets created for the first canceled approval entry.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdatePurchaseDocPurchaserCode(PurchaseHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithSendForApprovalResponse(FirstWorkflowStepInstance, SendForApprovalWorkflowStepInstance);
        CreateResponseStepAfterGivenStepWithNotification(SendForApprovalWorkflowStepInstance, CancelAllWorkflowStepInstance,
          WorkflowResponseHandling.CancelAllApprovalRequestsCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - approval requests.
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Canceled);
        Assert.RecordCount(ApprovalEntry, 3);

        // Verify - Notification.
        VerifyNotificationsForApprovers(ApprovalEntry, Approver1UserSetup, Approver2UserSetup, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RejectAllApprovalRequestsTestWithNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance";
        RejectAllWorkflowStepInstance: Record "Workflow Step Instance";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Reject approval requests with notification template defined.
        // [GIVEN] An active workflow step instance for RejectAllApprovalRequests.
        // [GIVEN] A user setup with 3 users and approval chain.
        // [GIVEN] A purchase invoice.
        // [WHEN] RejectAllApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The approval entries change status.
        // [THEN] A notification gets created for the first rejected approval entry.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdatePurchaseDocPurchaserCode(PurchaseHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithSendForApprovalResponse(FirstWorkflowStepInstance, SendForApprovalWorkflowStepInstance);
        CreateResponseStepAfterGivenStepWithNotification(SendForApprovalWorkflowStepInstance, RejectAllWorkflowStepInstance,
          WorkflowResponseHandling.RejectAllApprovalRequestsCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - approval requests.
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Rejected);
        Assert.RecordCount(ApprovalEntry, 3);

        // Verify - Notification.
        VerifyNotificationsForApprovers(ApprovalEntry, Approver1UserSetup, Approver2UserSetup, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendSalesForApprovalTestWithNotification()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
    begin
        // [SCENARIO] Send for approval response with notification template defined.
        // [GIVEN] An active workflow step instance for SendForApproval.
        // [GIVEN] A user setup with 3 users and approval chain.
        // [GIVEN] A sales invoice.
        // [WHEN] SendForApproval response is executed on the given workflow step instance.
        // [THEN] The approval entries change status.
        // [THEN] A notification gets created for the approver.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create sales invoice.
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdateSalesDocSalespersonCode(SalesHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithSendForApprovalResponse(FirstWorkflowStepInstance, SendForApprovalWorkflowStepInstance);

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify - approval requests.
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."No.");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.IsTrue(ApprovalEntry.FindFirst(), 'There should be at least one open approval entry.');
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, Approver1UserSetup."User ID");

        // Verify - Notification.
        VerifyNotificationEntry(ApprovalEntry."Approver ID", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelAllSalesApprovalRequestsTestWithNotification()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance";
        CancelAllWorkflowStepInstance: Record "Workflow Step Instance";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Cancel approval requests with notification template defined.
        // [GIVEN] An active workflow step instance for CancelAllApprovalRequests.
        // [GIVEN] A user setup with 3 users and approval chain.
        // [GIVEN] A sales invoice.
        // [WHEN] CancelAllApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The approval entries change status.
        // [THEN] A notification gets created for the first canceled approval entry.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create sales invoice.
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdateSalesDocSalespersonCode(SalesHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithSendForApprovalResponse(FirstWorkflowStepInstance, SendForApprovalWorkflowStepInstance);
        CreateResponseStepAfterGivenStepWithNotification(SendForApprovalWorkflowStepInstance, CancelAllWorkflowStepInstance,
          WorkflowResponseHandling.CancelAllApprovalRequestsCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify - approval requests.
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."No.");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Canceled);
        Assert.RecordCount(ApprovalEntry, 3);

        // Verify - Notification.
        VerifyNotificationsForApprovers(ApprovalEntry, Approver1UserSetup, Approver2UserSetup, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RejectAllSalesApprovalRequestsTestWithNotification()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance";
        RejectAllWorkflowStepInstance: Record "Workflow Step Instance";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Reject approval requests with notification template defined.
        // [GIVEN] An active workflow step instance for RejectAllApprovalRequests.
        // [GIVEN] A user setup with 3 users and approval chain.
        // [GIVEN] A sales invoice.
        // [WHEN] RejectAllApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The approval entries change status.
        // [THEN] A notification gets created for the first rejected approval entry.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create sales invoice.
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdateSalesDocSalespersonCode(SalesHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithSendForApprovalResponse(FirstWorkflowStepInstance, SendForApprovalWorkflowStepInstance);
        CreateResponseStepAfterGivenStepWithNotification(SendForApprovalWorkflowStepInstance, RejectAllWorkflowStepInstance,
          WorkflowResponseHandling.RejectAllApprovalRequestsCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify - approval requests.
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."No.");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Rejected);
        Assert.RecordCount(ApprovalEntry, 3);

        // Verify - Notification.
        VerifyNotificationsForApprovers(ApprovalEntry, Approver1UserSetup, Approver2UserSetup, 1, 0);
    end;

    [Test]
    [HandlerFunctions('OverdueMessageHandler')]
    [Scope('OnPrem')]
    procedure SendOverdueNotificationsTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance";
        SendOverdueWorkflowStepInstance: Record "Workflow Step Instance";
        UserSetup: Record "User Setup";
        Approver1UserSetup: Record "User Setup";
        Approver2UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Send overdue notifications.
        // [GIVEN] An active workflow step instance for SendForApproval.
        // [GIVEN] A user setup with 3 users and approval chain.
        // [GIVEN] A purchase invoice.
        // [WHEN] CreateOverdueNotifications response is executed on the given workflow step instance.
        // [THEN] The approval entries change status.
        // [THEN] Notifications get created for all approvers.

        // Setup - Cleanup
        Initialize();

        // Setup - Create chain of approvers
        CreateThreeUserSetupWithApproverChain(UserSetup, Approver1UserSetup, Approver2UserSetup);

        // Setup - Create purchase invoice.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdatePurchaseDocPurchaserCode(PurchaseHeader, Approver1UserSetup."Salespers./Purch. Code");

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithSendForApprovalResponse(FirstWorkflowStepInstance, SendForApprovalWorkflowStepInstance);
        CreateResponseStepAfterGivenStepWithNotification(SendForApprovalWorkflowStepInstance, SendOverdueWorkflowStepInstance,
          WorkflowResponseHandling.CreateOverdueNotificationCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - approval requests.
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        Assert.IsTrue(ApprovalEntry.FindFirst(), 'Unexpected number of open approval entries found');
        VerifyApprovalEntryIsOpen(ApprovalEntry);
        VerifyApprovalEntrySenderID(ApprovalEntry, UserSetup."User ID");
        VerifyApprovalEntryApproverID(ApprovalEntry, Approver1UserSetup."User ID");

        // Verify - Notification.
        VerifyNotificationEntry(ApprovalEntry."Approver ID", 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespWithTypeSequentialWorkflowUserGroupTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup1: Record "User Setup";
        UserSetup2: Record "User Setup";
        UserSetup3: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is workflow user group.
        // [GIVEN] An active workflow step instance for CreateApprovalRequests.
        // [GIVEN] A workflow user group and workflow user group membership setup with 3 sequential users.
        // [GIVEN] A purchase invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The three approval requests are created.

        // Setup - Cleanup
        Initialize();

        CreateOrFindCurrentUserSetup();

        // Setup - WorkflowUserGroups and usersetups
        CreateThreeUserSetupWithSequentialWorkflowUserGroup(WorkflowUserGroup, UserSetup1,
          UserSetup2, UserSetup3);

        // Setup - Create purchase invoice where amount is 5000.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::"Workflow User Group",
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", DueDateFormula, WorkflowUserGroup.Code, false);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - 3 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        Assert.RecordCount(ApprovalEntry, 3);

        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, UserSetup1."User ID",
          ApprovalEntry."Approval Type"::"Workflow User Group", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 1);

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, UserSetup2."User ID",
          ApprovalEntry."Approval Type"::"Workflow User Group", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 2);

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, UserSetup3."User ID",
          ApprovalEntry."Approval Type"::"Workflow User Group", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateApprReqRespWithTypeFlatWorkflowUserGroupTest()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup1: Record "User Setup";
        UserSetup2: Record "User Setup";
        UserSetup3: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is workflow user group.
        // [GIVEN] An active workflow step instance for CreateApprovalRequests.
        // [GIVEN] A workflow user group and workflow user group membership setup with 3 users where their
        // sequence number is the same.
        // [GIVEN] A purchase invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The three approval requests are created.

        // Setup - Cleanup
        Initialize();

        CreateOrFindCurrentUserSetup();

        // Setup - WorkflowUserGroups and usersetups
        CreateThreeUserSetupWithFlatWorkflowUserGroup(WorkflowUserGroup, UserSetup1,
          UserSetup2, UserSetup3);

        // Setup - Create purchase invoice where amount is 5000.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::"Workflow User Group",
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", DueDateFormula, WorkflowUserGroup.Code, false);

        // Excercise
        WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // Verify - 3 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Purchase Header", PurchaseHeader."No.");
        Assert.RecordCount(ApprovalEntry, 3);

        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, UserSetup1."User ID",
          ApprovalEntry."Approval Type"::"Workflow User Group", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 1);

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, UserSetup2."User ID",
          ApprovalEntry."Approval Type"::"Workflow User Group", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 1);

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, UserSetup3."User ID",
          ApprovalEntry."Approval Type"::"Workflow User Group", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesApprReqRespWithTypeWorkflowUserGroupTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CreateApprReqRespWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup1: Record "User Setup";
        UserSetup2: Record "User Setup";
        UserSetup3: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowUserGroup: Record "Workflow User Group";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        // [SCENARIO] Create approval requests response when approver type is workflow user group.
        // [GIVEN] An active workflow step instance for CreateApprovalRequests.
        // [GIVEN] A workflow user group and workflow user group membership setup with 3 users.
        // [GIVEN] A sales invoice.
        // [WHEN] CreateApprovalRequests response is executed on the given workflow step instance.
        // [THEN] The three approval requests are created.

        // Setup - Cleanup
        Initialize();

        CreateOrFindCurrentUserSetup();

        // Setup - WorkflowUserGroups and usersetups
        CreateThreeUserSetupWithSequentialWorkflowUserGroup(WorkflowUserGroup, UserSetup1,
          UserSetup2, UserSetup3);

        // Setup - Create purchase invoice where amount is 5000.
        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // Setup - Create workflow response chain for testing
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprReqRespWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());

        // Setup - Create step argument, select the approver type and update the step instance
        Evaluate(DueDateFormula, '<+1M>');
        CreateApprovalArgument(CreateApprReqRespWorkflowStepInstance, WorkflowStepArgument."Approver Type"::"Workflow User Group",
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", DueDateFormula, WorkflowUserGroup.Code, false);

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify - 3 approval requests are created
        GetApprovalEntriesForInv(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."No.");
        Assert.RecordCount(ApprovalEntry, 3);

        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, UserSetup1."User ID",
          ApprovalEntry."Approval Type"::"Workflow User Group", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 1);

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, UserSetup2."User ID",
          ApprovalEntry."Approval Type"::"Workflow User Group", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 2);

        ApprovalEntry.Next();
        VerifyApprovalEntryIsCreated(ApprovalEntry);
        VerifyApprovalEntry(ApprovalEntry, UserId, UserSetup3."User ID",
          ApprovalEntry."Approval Type"::"Workflow User Group", ApprovalEntry."Limit Type"::"No Limits", DueDateFormula, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCreditLimitTest()
    var
        SalesHeader: Record "Sales Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        CheckCreditLimitWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Check credit limit response.
        // [GIVEN] An active workflow step instance for CheckCreditLimit.
        // [GIVEN] A sales invoice.
        // [WHEN] CheckCreditLimit response is executed on the given workflow step instance.

        // Setup
        Initialize();
        CreateSalesInvoice(SalesHeader);
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CheckCreditLimitWorkflowStepInstance,
          WorkflowResponseHandling.CheckCustomerCreditLimitCode());

        // Excercise
        WorkflowMgt.ExecuteResponses(SalesHeader, SalesHeader, FirstWorkflowStepInstance);

        // Verify
        WorkflowStepInstanceArchive.SetRange(ID, CheckCreditLimitWorkflowStepInstance.ID);
        WorkflowStepInstanceArchive.SetRange("Workflow Code", CheckCreditLimitWorkflowStepInstance."Workflow Code");
        WorkflowStepInstanceArchive.SetRange("Workflow Step ID", CheckCreditLimitWorkflowStepInstance."Workflow Step ID");
        Assert.IsTrue(WorkflowStepInstanceArchive.FindFirst(), 'The response was not executed and the workflow was not compledted.');
    end;

    [Test]
    [HandlerFunctions('ShowMessageHandler')]
    [Scope('OnPrem')]
    procedure ShowMessageTest()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ShowMessageWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Check show message response.
        // [GIVEN] An active workflow step instance for ShowMessage.
        // [WHEN] ShowMessage response is executed on the given workflow step instance.

        // Setup
        Initialize();
        GenJnlBatch.Init();
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ShowMessageWorkflowStepInstance,
          WorkflowResponseHandling.ShowMessageCode());

        WorkflowStepArgument.Init();
        WorkflowStepArgument.Type := WorkflowStepArgument.Type::Response;
        WorkflowStepArgument.Validate(Message, ShowMessageTestMsg);
        WorkflowStepArgument.Insert(true);

        ShowMessageWorkflowStepInstance.Argument := WorkflowStepArgument.ID;
        ShowMessageWorkflowStepInstance.Modify(true);

        // Excercise
        WorkflowMgt.ExecuteResponses(GenJnlBatch, GenJnlBatch, FirstWorkflowStepInstance);

        // Verify
        WorkflowStepInstanceArchive.SetRange(ID, ShowMessageWorkflowStepInstance.ID);
        WorkflowStepInstanceArchive.SetRange("Workflow Code", ShowMessageWorkflowStepInstance."Workflow Code");
        WorkflowStepInstanceArchive.SetRange("Workflow Step ID", ShowMessageWorkflowStepInstance."Workflow Step ID");
        Assert.IsTrue(WorkflowStepInstanceArchive.FindFirst(), 'The response was not executed and the workflow was not compledted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestrictCustomerUsageForDocsRespTest()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictEntityUsageWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictedRecord: Record "Restricted Record";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Restrict entity usage response.
        // [GIVEN] An active workflow step instance for Restrict Entity Usage.
        // [GIVEN] A customer.
        // [WHEN] Restrict Entity Usage response is executed on the given workflow step instance.
        // [THEN] The customer cannot be used for posting documents.

        // Setup.
        Initialize();
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RestrictEntityUsageWorkflowStepInstance,
          WorkflowResponseHandling.RestrictRecordUsageCode());
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          Customer."No.", LibraryInventory.CreateItemNo(), 10, '', WorkDate());

        // Exercise.
        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);

        // Verify.
        RestrictedRecord.Init();
        RestrictedRecord.SetRange("Record ID", Customer.RecordId);
        Assert.RecordCount(RestrictedRecord, 1);
        Commit();
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(Customer.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowCustomerUsageForDocsRespTest()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictEntityUsageWorkflowStepInstance: Record "Workflow Step Instance";
        RemoveRestrictionWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictedRecord: Record "Restricted Record";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Remove entity usage restriction response.
        // [GIVEN] An active workflow step instance for Remove Entity Usage Restriction.
        // [GIVEN] A customer.
        // [WHEN] Restrict Entity Usage response is executed on the given workflow step instance.
        // [WHEN] Remove Entity Usage Restriction is executed.
        // [THEN] The customer can be used again for posting documents.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RestrictEntityUsageWorkflowStepInstance,
          WorkflowResponseHandling.RestrictRecordUsageCode());

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          Customer."No.", LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(1000, 2), '', WorkDate());
        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);
        Commit();
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(Customer.RecordId, 0, 1)));

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RemoveRestrictionWorkflowStepInstance,
          WorkflowResponseHandling.AllowRecordUsageCode());

        // Exercise.
        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);

        // Verify.
        RestrictedRecord.Init();
        RestrictedRecord.SetRange("Record ID", Customer.RecordId);
        Assert.RecordIsEmpty(RestrictedRecord);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestrictCustomerUsageForJournalsRespTest()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictEntityUsageWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictedRecord: Record "Restricted Record";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Restrict entity usage response.
        // [GIVEN] An active workflow step instance for Restrict Entity Usage.
        // [GIVEN] A customer.
        // [WHEN] Restrict Entity Usage response is executed on the given workflow step instance.
        // [THEN] The customer cannot be used for posting journal lines.

        // Setup.
        Initialize();
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RestrictEntityUsageWorkflowStepInstance,
          WorkflowResponseHandling.RestrictRecordUsageCode());
        LibrarySales.CreateCustomer(Customer);
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.", -LibraryRandom.RandDec(1000, 2));

        // Exercise.
        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);

        // Verify.
        RestrictedRecord.Init();
        RestrictedRecord.SetRange("Record ID", Customer.RecordId);
        Assert.RecordCount(RestrictedRecord, 1);
        Commit();
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(Customer.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowCustomerUsageForJournalsRespTest()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictEntityUsageWorkflowStepInstance: Record "Workflow Step Instance";
        RemoveRestrictionWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictedRecord: Record "Restricted Record";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Remove entity usage restriction response.
        // [GIVEN] An active workflow step instance for Remove Entity Usage Restriction.
        // [GIVEN] A customer.
        // [WHEN] Restrict Entity Usage response is executed on the given workflow step instance.
        // [WHEN] Remove Entity Usage Restriction is executed.
        // [THEN] The customer can be used again for posting journal lines.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RestrictEntityUsageWorkflowStepInstance,
          WorkflowResponseHandling.RestrictRecordUsageCode());

        LibrarySales.CreateCustomer(Customer);
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.", -LibraryRandom.RandDec(1000, 2));

        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);
        Commit();
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(Customer.RecordId, 0, 1)));

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RemoveRestrictionWorkflowStepInstance,
          WorkflowResponseHandling.AllowRecordUsageCode());

        // Exercise.
        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);

        // Verify.
        RestrictedRecord.Init();
        RestrictedRecord.SetRange("Record ID", Customer.RecordId);
        Assert.RecordIsEmpty(RestrictedRecord);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RestrictGenJnlLineUsageRespTest()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictEntityUsageWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictedRecord: Record "Restricted Record";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Restrict entity usage response.
        // [GIVEN] An active workflow step instance for Restrict Entity Usage.
        // [GIVEN] A general journal line.
        // [WHEN] Restrict Entity Usage response is executed on the given workflow step instance.
        // [THEN] The general journal line cannot be used for posting.

        // Setup.
        Initialize();
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RestrictEntityUsageWorkflowStepInstance,
          WorkflowResponseHandling.RestrictRecordUsageCode());
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate());
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          -LibraryRandom.RandDec(1000, 2));

        // Exercise.
        WorkflowMgt.ExecuteResponses(GenJournalLine, GenJournalLine, FirstWorkflowStepInstance);

        // Verify.
        RestrictedRecord.Init();
        RestrictedRecord.SetRange("Record ID", GenJournalLine.RecordId);
        Assert.RecordCount(RestrictedRecord, 1);
        Commit();
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalLine.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowGenJnlLineUsageRespTest()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictEntityUsageWorkflowStepInstance: Record "Workflow Step Instance";
        RemoveRestrictionWorkflowStepInstance: Record "Workflow Step Instance";
        RestrictedRecord: Record "Restricted Record";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Remove entity usage restriction response.
        // [GIVEN] An active workflow step instance for Remove Entity Usage Restriction.
        // [GIVEN] A general journal line.
        // [WHEN] Restrict Entity Usage response is executed on the given workflow step instance.
        // [WHEN] Remove Entity Usage Restriction is executed.
        // [THEN] The general journal line can be posted.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RestrictEntityUsageWorkflowStepInstance,
          WorkflowResponseHandling.RestrictRecordUsageCode());

        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryPurchase.SelectPmtJnlTemplate());
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          -LibraryRandom.RandDec(1000, 2));

        WorkflowMgt.ExecuteResponses(GenJournalLine, GenJournalLine, FirstWorkflowStepInstance);
        Commit();
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Assert.ExpectedError(StrSubstNo(RecordRestrictedErr, Format(GenJournalLine.RecordId, 0, 1)));

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RemoveRestrictionWorkflowStepInstance,
          WorkflowResponseHandling.AllowRecordUsageCode());

        // Exercise.
        WorkflowMgt.ExecuteResponses(GenJournalLine, GenJournalLine, FirstWorkflowStepInstance);

        // Verify.
        RestrictedRecord.Init();
        RestrictedRecord.SetRange("Record ID", GenJournalLine.RecordId);
        Assert.RecordIsEmpty(RestrictedRecord);
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Assert.ExpectedError('out of balance');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevertFieldValueCreatesChangeRecordTest()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        WorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowRecordChangeArchive: Record "Workflow Record Change Archive";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        RevertFieldValueWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Revert field values and create change record.
        // [GIVEN] An active workflow step instance for Revert field value.
        // [GIVEN] A customer record that is changed.
        // [WHEN] Revert field value is executed.
        // [THEN] The customer record holds the initial values and there is a change record.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RevertFieldValueWorkflowStepInstance,
          WorkflowResponseHandling.RevertValueForFieldCode());

        AddFieldNoArgumentToStep(RevertFieldValueWorkflowStepInstance, DATABASE::Customer, 20);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(Customer2);

        Customer."Credit Limit (LCY)" := 200;
        Customer.Modify();

        Customer2."Credit Limit (LCY)" := 100;
        Customer2.Modify();

        // Exercise.
        WorkflowMgt.ExecuteResponses(Customer, Customer2, FirstWorkflowStepInstance);

        Customer.Get(Customer."No.");
        Customer2.Get(Customer2."No.");

        // Verify.
        WorkflowRecordChange.Init();
        WorkflowRecordChange.SetRange("Record ID", Customer.RecordId);
        Assert.RecordIsEmpty(WorkflowRecordChange);
        WorkflowRecordChangeArchive.Init();
        Assert.RecordIsNotEmpty(WorkflowRecordChangeArchive);
        Assert.AreEqual(Customer."Credit Limit (LCY)", Customer2."Credit Limit (LCY)", 'The value was not reverted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevertFieldValueDoesNothingForIdenticalRecordsTest()
    var
        Customer: Record Customer;
        WorkflowRecordChange: Record "Workflow - Record Change";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        RevertFieldValueWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Revert field values does nothing for identical fields.
        // [GIVEN] An active workflow step instance for Revert field value.
        // [GIVEN] A customer record.
        // [WHEN] Revert field value is executed.
        // [THEN] The response does nothing because the records are identical.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RevertFieldValueWorkflowStepInstance,
          WorkflowResponseHandling.RevertValueForFieldCode());

        AddFieldNoArgumentToStep(RevertFieldValueWorkflowStepInstance, DATABASE::Customer, 20);

        LibrarySales.CreateCustomer(Customer);

        // Exercise.
        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);

        // Verify.
        WorkflowRecordChange.Init();
        WorkflowRecordChange.SetRange("Record ID", Customer.RecordId);
        Assert.RecordIsEmpty(WorkflowRecordChange);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevertFieldValueFailsForWrongFieldNoTest()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        RevertFieldValueWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Revert field values fails for a wrong field number.
        // [GIVEN] An active workflow step instance for Revert field value.
        // [GIVEN] A wrong field number in the workflow step argument.
        // [WHEN] Revert field value is executed.
        // [THEN] The engine fails because of the wrong field number.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RevertFieldValueWorkflowStepInstance,
          WorkflowResponseHandling.RevertValueForFieldCode());

        AddFieldNoArgumentToStep(RevertFieldValueWorkflowStepInstance, DATABASE::Customer, -1);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(Customer2);

        Customer."Credit Limit (LCY)" := 200;
        Customer.Modify();

        Customer2."Credit Limit (LCY)" := 100;
        Customer2.Modify();

        // Exercise.
        asserterror WorkflowMgt.ExecuteResponses(Customer, Customer2, FirstWorkflowStepInstance);

        // Verify.
        Assert.ExpectedError('The supplied field number ''-1'' cannot be found in the ''Customer'' table.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyNewValuesTest()
    var
        Customer: Record Customer;
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ApplyNewValuesWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        OldValue: Decimal;
        NewValue: Decimal;
    begin
        // [SCENARIO] Apply new values for a record.
        // [GIVEN] An active workflow step instance for Apply new values.
        // [GIVEN] An approval entry holding the customer record id.
        // [GIVEN] A record change holding the customer record changes.
        // [WHEN] Apply new values is executed.
        // [THEN] The customer record is changed.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ApplyNewValuesWorkflowStepInstance,
          WorkflowResponseHandling.ApplyNewValuesCode());

        LibrarySales.CreateCustomer(Customer);
        OldValue := LibraryRandom.RandDec(100, 2);
        NewValue := LibraryRandom.RandDec(100, 2);

        Customer."Credit Limit (LCY)" := OldValue;
        Customer.Modify();

        ApprovalEntry.Init();
        ApprovalEntry."Record ID to Approve" := Customer.RecordId;
        ApprovalEntry.Insert(true);

        CreateWorkflowCustomerRecordChange(Customer, Customer.FieldNo("Credit Limit (LCY)"),
          Format(OldValue, 0, 9), Format(NewValue, 0, 9), ApplyNewValuesWorkflowStepInstance.ID);

        // Exercise.
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);

        Customer.Get(Customer."No.");

        // Verify.
        Assert.AreEqual(Customer."Credit Limit (LCY)", NewValue, 'The value was not applied');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyNewValuesCustomerTest()
    var
        Customer: Record Customer;
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ApplyNewValuesWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        OldValue: Decimal;
        NewValue: Decimal;
    begin
        // [SCENARIO] Trying to apply new values for a customer record type will work.
        // [GIVEN] An active workflow step instance for Apply new values.
        // [GIVEN] A customer record.
        // [GIVEN] A record change holding the customer record changes.
        // [WHEN] Apply new values is executed.
        // [THEN] The changes are applied.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ApplyNewValuesWorkflowStepInstance,
          WorkflowResponseHandling.ApplyNewValuesCode());

        LibrarySales.CreateCustomer(Customer);
        OldValue := LibraryRandom.RandDec(100, 2);
        NewValue := LibraryRandom.RandDec(100, 2);

        Customer."Credit Limit (LCY)" := OldValue;
        Customer.Modify();

        CreateWorkflowCustomerRecordChange(Customer, Customer.FieldNo("Credit Limit (LCY)"),
          Format(OldValue, 0, 9), Format(NewValue, 0, 9), ApplyNewValuesWorkflowStepInstance.ID);

        // Exercise.
        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);

        Customer.Get(Customer."No.");

        // Verify.
        Assert.AreEqual(Customer."Credit Limit (LCY)", NewValue, 'The value was not applied');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyNewValuesChangeRecordTest()
    var
        Vendor: Record Vendor;
        WorkflowRecordChange: Record "Workflow - Record Change";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ApplyNewValuesWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        OldValue: Decimal;
        NewValue: Decimal;
    begin
        // [SCENARIO] Trying to apply new values for a change record type will apply the values.
        // [GIVEN] An active workflow step instance for Apply new values.
        // [GIVEN] A change record.
        // [GIVEN] A record change holding the vendor record changes.
        // [WHEN] Apply new values is executed.
        // [THEN] The workflow engine applies the new values.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ApplyNewValuesWorkflowStepInstance,
          WorkflowResponseHandling.ApplyNewValuesCode());

        LibraryPurchase.CreateVendor(Vendor);
        OldValue := LibraryRandom.RandDec(100, 2);
        NewValue := LibraryRandom.RandDec(100, 2);

        Vendor."Budgeted Amount" := OldValue;
        Vendor.Modify();

        WorkflowRecordChange.Init();
        WorkflowRecordChange."Old Value" := Format(OldValue, 0, 9);
        WorkflowRecordChange."New Value" := Format(NewValue, 0, 9);
        WorkflowRecordChange."Table No." := 23;
        WorkflowRecordChange."Field No." := 19;
        WorkflowRecordChange."Record ID" := Vendor.RecordId;
        WorkflowRecordChange."Workflow Step Instance ID" := ApplyNewValuesWorkflowStepInstance.ID;
        WorkflowRecordChange.Insert(true);

        // Exercise.
        WorkflowMgt.ExecuteResponses(WorkflowRecordChange, WorkflowRecordChange, FirstWorkflowStepInstance);

        // Verify.
        Vendor.Find();
        Assert.AreEqual(NewValue, Vendor."Budgeted Amount", 'The new value was not applied');
    end;

    [Test]
    [HandlerFunctions('ApplyNewValuesMessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyNewValuesFailsIfTheValueIsChangedTest()
    var
        Customer: Record Customer;
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ApplyNewValuesWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        OldValue: Decimal;
        NewValue: Decimal;
        ChangedValue: Decimal;
    begin
        // [SCENARIO] Trying to apply new values for an already modified record will inform the user about this.
        // [GIVEN] An active workflow step instance for Apply new values.
        // [GIVEN] An record that is changed between the creation of the record change and when the response is executed.
        // [GIVEN] A record change holding the customer record changes.
        // [WHEN] Apply new values is executed.
        // [THEN] The workflow engine will not apply the change and will inform the user.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ApplyNewValuesWorkflowStepInstance,
          WorkflowResponseHandling.ApplyNewValuesCode());

        LibrarySales.CreateCustomer(Customer);
        OldValue := LibraryRandom.RandDec(100, 2);
        NewValue := LibraryRandom.RandDec(100, 2);
        ChangedValue := LibraryRandom.RandDec(100, 2);
        Customer."Credit Limit (LCY)" := OldValue;
        Customer.Modify();

        ApprovalEntry.Init();
        ApprovalEntry."Record ID to Approve" := Customer.RecordId;
        ApprovalEntry.Insert(true);

        CreateWorkflowCustomerRecordChange(Customer, Customer.FieldNo("Credit Limit (LCY)"),
          Format(OldValue, 0, 9), Format(NewValue, 0, 9), ApplyNewValuesWorkflowStepInstance.ID);

        Customer."Credit Limit (LCY)" := ChangedValue;
        Customer.Modify();

        // Exercise.
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);

        // Verify.
        Assert.AreEqual(Customer."Credit Limit (LCY)", ChangedValue, 'The value should not be applied');
    end;

    [Test]
    [HandlerFunctions('ApplyNewValuesNoRecChangesMessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyNewValuesShowMessageIfThereIsNothignToApplyTest()
    var
        Customer: Record Customer;
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ApplyNewValuesWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        OldValue: Decimal;
        NewValue: Decimal;
    begin
        // [SCENARIO] Trying to apply new values for fields that have no record change will show a message.
        // [GIVEN] An active workflow step instance for Apply new values.
        // [GIVEN] An record change that is not on the same field as the apply new values response expects.
        // [WHEN] Apply new values is executed.
        // [THEN] The workflow engine will not apply the change and will inform the user.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ApplyNewValuesWorkflowStepInstance,
          WorkflowResponseHandling.ApplyNewValuesCode());

        AddFieldNoArgumentToStep(ApplyNewValuesWorkflowStepInstance, 18, 20);

        LibrarySales.CreateCustomer(Customer);
        OldValue := LibraryRandom.RandDec(100, 2);
        NewValue := LibraryRandom.RandDec(100, 2);
        Customer."Credit Limit (LCY)" := OldValue;
        Customer.Modify();

        ApprovalEntry.Init();
        ApprovalEntry."Record ID to Approve" := Customer.RecordId;
        ApprovalEntry.Insert(true);

        CreateWorkflowCustomerRecordChange(Customer, Customer.FieldNo("Customer Posting Group"),
          Format(OldValue, 0, 9), Format(NewValue, 0, 9), ApplyNewValuesWorkflowStepInstance.ID);

        // Exercise.
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);

        // Verify.
        Assert.AreEqual(Customer."Credit Limit (LCY)", OldValue, 'The value should not be applied');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyNewValuesBooleanTest()
    var
        Customer: Record Customer;
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ApplyNewValuesWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        OldValue: Boolean;
        NewValue: Boolean;
    begin
        // [SCENARIO] Apply new values for a record.
        // [GIVEN] An active workflow step instance for Apply new values.
        // [GIVEN] An approval entry holding the customer record id.
        // [GIVEN] A record change holding the customer record changes where a boolean field is changed.
        // [WHEN] Apply new values is executed.
        // [THEN] The customer record is changed.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ApplyNewValuesWorkflowStepInstance,
          WorkflowResponseHandling.ApplyNewValuesCode());

        LibrarySales.CreateCustomer(Customer);
        OldValue := false;
        NewValue := true;

        Customer."Combine Shipments" := OldValue;
        Customer.Modify();

        ApprovalEntry.Init();
        ApprovalEntry."Record ID to Approve" := Customer.RecordId;
        ApprovalEntry.Insert(true);

        CreateWorkflowCustomerRecordChange(Customer, Customer.FieldNo("Combine Shipments"),
          Format(OldValue, 0, 9), Format(NewValue, 0, 9), ApplyNewValuesWorkflowStepInstance.ID);

        // Exercise.
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);

        Customer.Get(Customer."No.");

        // Verify.
        Assert.AreEqual(Customer."Combine Shipments", NewValue, 'The value was not applied');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyNewValuesOptionTest()
    var
        Customer: Record Customer;
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ApplyNewValuesWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        OldValue: Enum "Customer Blocked";
        NewValue: Enum "Customer Blocked";
    begin
        // [SCENARIO] Apply new values for a record.
        // [GIVEN] An active workflow step instance for Apply new values.
        // [GIVEN] An approval entry holding the customer record id.
        // [GIVEN] A record change holding the customer record changes where a boolean field is changed.
        // [WHEN] Apply new values is executed.
        // [THEN] The customer record is changed.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ApplyNewValuesWorkflowStepInstance,
          WorkflowResponseHandling.ApplyNewValuesCode());

        LibrarySales.CreateCustomer(Customer);
        OldValue := Customer.Blocked::Invoice;
        NewValue := Customer.Blocked::Ship;

        Customer.Blocked := OldValue;
        Customer.Modify();

        ApprovalEntry.Init();
        ApprovalEntry."Record ID to Approve" := Customer.RecordId;
        ApprovalEntry.Insert(true);

        CreateWorkflowCustomerRecordChange(Customer, Customer.FieldNo(Blocked),
          Format(OldValue, 0, 9), Format(NewValue, 0, 9), ApplyNewValuesWorkflowStepInstance.ID);

        // Exercise.
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);

        Customer.Get(Customer."No.");

        // Verify.
        Assert.AreEqual(Customer.Blocked, NewValue, 'The value was not applied');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyNewValuesDateTest()
    var
        Customer: Record Customer;
        ApprovalEntry: Record "Approval Entry";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        ApplyNewValuesWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        OldValue: Date;
        NewValue: Date;
    begin
        // [SCENARIO] Apply new values for a record.
        // [GIVEN] An active workflow step instance for Apply new values.
        // [GIVEN] An approval entry holding the customer record id.
        // [GIVEN] A record change holding the customer record changes where a boolean field is changed.
        // [WHEN] Apply new values is executed.
        // [THEN] The customer record is changed.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, ApplyNewValuesWorkflowStepInstance,
          WorkflowResponseHandling.ApplyNewValuesCode());

        LibrarySales.CreateCustomer(Customer);
        OldValue := CalcDate('<-1D>', WorkDate());
        NewValue := Today;

        Customer."Last Date Modified" := OldValue;
        Customer.Modify();

        ApprovalEntry.Init();
        ApprovalEntry."Record ID to Approve" := Customer.RecordId;
        ApprovalEntry.Insert(true);

        CreateWorkflowCustomerRecordChange(Customer, Customer.FieldNo("Last Date Modified"),
          Format(OldValue, 0, 9), Format(NewValue, 0, 9), ApplyNewValuesWorkflowStepInstance.ID);

        // Exercise.
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);

        Customer.Get(Customer."No.");

        // Verify.
        Assert.AreEqual(Customer."Last Date Modified", NewValue, 'The value was not applied');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevertValuesBooleanTest()
    var
        Customer: Record Customer;
        xRecCustomer: Record Customer;
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        RevertFieldValueWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowRecordChangeArchive: Record "Workflow Record Change Archive";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        OldValue: Boolean;
        NewValue: Boolean;
    begin
        // [SCENARIO] Apply new values for a record.
        // [GIVEN] An active workflow step instance for Apply new values.
        // [GIVEN] An approval entry holding the customer record id.
        // [GIVEN] A record change holding the customer record changes where a boolean field is changed.
        // [WHEN] Apply new values is executed.
        // [THEN] The customer record is changed.

        // Setup.
        Initialize();

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, RevertFieldValueWorkflowStepInstance,
          WorkflowResponseHandling.RevertValueForFieldCode());
        AddFieldNoArgumentToStep(RevertFieldValueWorkflowStepInstance, DATABASE::Customer, Customer.FieldNo("Combine Shipments"));

        OldValue := false;
        NewValue := true;

        LibrarySales.CreateCustomer(xRecCustomer);
        Customer := xRecCustomer;
        Customer."Combine Shipments" := NewValue;
        Customer.Modify();

        // Exercise.
        WorkflowMgt.ExecuteResponses(Customer, xRecCustomer, FirstWorkflowStepInstance);

        // Verify.
        Customer.Get(Customer."No.");
        Assert.AreEqual(Customer."Combine Shipments", OldValue, 'The value was not reverted');

        WorkflowRecordChangeArchive.SetRange("Table No.", DATABASE::Customer);
        WorkflowRecordChangeArchive.SetRange("Field No.", Customer.FieldNo("Combine Shipments"));
        WorkflowRecordChangeArchive.SetRange("Workflow Step Instance ID", FirstWorkflowStepInstance.ID);
        Assert.RecordCount(WorkflowRecordChangeArchive, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiscardNewValuesTest()
    var
        Customer: Record Customer;
        WorkflowRecordChange: Record "Workflow - Record Change";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        // [SCENARIO] Calling Discard New Values response will delete all the record changes recorded.
        // [GIVEN] An active workflow step instance for Discard New Values.
        // [GIVEN] One or more record changes for a single record.
        // [WHEN] Discard New Values is executed.
        // [THEN] The record changes are deleted.

        // Setup
        Initialize();

        WorkflowRecordChange.DeleteAll(true);

        CreateWFStepInstanceWithCustomerAndRecordChange(FirstWorkflowStepInstance, Customer);

        // Exercise.
        WorkflowMgt.ExecuteResponses(Customer, Customer, FirstWorkflowStepInstance);

        // Verify.
        Assert.RecordIsEmpty(WorkflowRecordChange);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiscardNewValuesRecordChangeTest()
    var
        WorkflowRecordChange: Record "Workflow - Record Change";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        Customer: Record Customer;
    begin
        // [SCENARIO] Calling Discard New Values response will delete all the record changes recorded.
        // [GIVEN] An active workflow step instance for Discard New Values.
        // [GIVEN] One or more record changes for a single record.
        // [WHEN] Discard New Values is executed.
        // [THEN] The record changes are deleted.

        // Setup
        Initialize();

        WorkflowRecordChange.DeleteAll(true);

        CreateWFStepInstanceWithCustomerAndRecordChange(FirstWorkflowStepInstance, Customer);

        // Exercise.
        WorkflowRecordChange.FindFirst();
        WorkflowMgt.ExecuteResponses(WorkflowRecordChange, WorkflowRecordChange, FirstWorkflowStepInstance);

        // Verify.
        Assert.RecordIsEmpty(WorkflowRecordChange);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiscardNewValuesApprovalEntryTest()
    var
        Customer: Record Customer;
        ApprovalEntry: Record "Approval Entry";
        WorkflowRecordChange: Record "Workflow - Record Change";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        DiscardNewValuesWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        // [SCENARIO] Calling Discard New Values response will delete all the record changes recorded.
        // [GIVEN] An active workflow step instance for Discard New Values.
        // [GIVEN] One or more record changes for a single record.
        // [WHEN] Discard New Values is executed.
        // [THEN] The record changes are deleted.

        // Setup
        Initialize();

        WorkflowRecordChange.DeleteAll(true);

        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, DiscardNewValuesWorkflowStepInstance,
          WorkflowResponseHandling.DiscardNewValuesCode());

        LibrarySales.CreateCustomer(Customer);

        ApprovalEntry.Init();
        ApprovalEntry."Record ID to Approve" := Customer.RecordId;
        ApprovalEntry."Workflow Step Instance ID" := DiscardNewValuesWorkflowStepInstance.ID;
        ApprovalEntry.Insert();

        CreateWorkflowCustomerRecordChange(Customer, Customer.FieldNo("Credit Limit (LCY)"),
          Format(LibraryRandom.RandDec(100, 2)), Format(LibraryRandom.RandDec(100, 2)), DiscardNewValuesWorkflowStepInstance.ID);

        // Exercise.
        WorkflowMgt.ExecuteResponses(ApprovalEntry, ApprovalEntry, FirstWorkflowStepInstance);

        // Verify.
        WorkflowRecordChange.Init();
        WorkflowRecordChange.SetRange(Inactive, false);
        Assert.RecordIsEmpty(WorkflowRecordChange);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendForApprovalToWorkflowUserGroupWithoutUserSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        FirstWorkflowStepInstance: Record "Workflow Step Instance";
        SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance";
        UserSetup1: Record "User Setup";
        UserSetup2: Record "User Setup";
        UserSetup3: Record "User Setup";
        WorkflowUserGroup: Record "Workflow User Group";
    begin
        // [SCENARIO 284222] User is not able to send approval request if he/she is not defined in user setup
        Initialize();

        // [GIVEN] No user setup for current user
        if UserSetup1.Get(UserId) then
            UserSetup1.Delete();
        // [GIVEN] An active workflow step instance for SendForApproval.
        // [GIVEN] A user group setup with 3 users with the same sequence number.
        CreateThreeUserSetupWithFlatWorkflowUserGroup(WorkflowUserGroup, UserSetup1,
          UserSetup2, UserSetup3);

        // [GIVEN] A purchase invoice.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));

        // [WHEN] User tries to send approval request
        CreateWorkflowStepInstanceWithSendForApprovalToUserGroupResponse(
          FirstWorkflowStepInstance, SendForApprovalWorkflowStepInstance, WorkflowUserGroup.Code);
        asserterror WorkflowMgt.ExecuteResponses(PurchaseHeader, PurchaseHeader, FirstWorkflowStepInstance);

        // [THEN] Error "User ID does not exist..."
        Assert.ExpectedError(StrSubstNo(UserIdNotInSetupErr, UserId));
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Workflow Respo. Lib. Tests");
        LibraryWorkflow.DeleteAllExistingWorkflows();
        UserSetup.DeleteAll();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        WorkflowResponseHandling.CreateResponsesLibrary();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Workflow Respo. Lib. Tests");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Workflow Respo. Lib. Tests");
    end;

    local procedure CreateMockPurchaseApprovalWorkflow()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);
        LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
        Workflow.Enabled := true;
        Workflow.Modify();
    end;

    local procedure CreateMockSalesApprovalWorkflow()
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);
        LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
        Workflow.Enabled := true;
        Workflow.Modify();
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header") DocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        DocumentNo := PurchaseHeader."No.";
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, '', LibraryInventory.CreateItemNo(), 3, '', 0D);
    end;

    local procedure CreateApprovalEntryForPurchaseDoc(var ApprovalEntry: Record "Approval Entry"; PurchaseHeader: Record "Purchase Header")
    var
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Table ID" := DATABASE::"Purchase Header";
        ApprovalEntry."Document Type" := EnumAssignmentMgt.GetPurchApprovalDocumentType(PurchaseHeader."Document Type");
        ApprovalEntry."Document No." := PurchaseHeader."No.";
        ApprovalEntry."Record ID to Approve" := PurchaseHeader.RecordId;
        ApprovalEntry.Insert();
    end;

    local procedure CreateApprovalEntryForSalesDoc(var ApprovalEntry: Record "Approval Entry"; SalesHeader: Record "Sales Header")
    var
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Table ID" := DATABASE::"Sales Header";
        ApprovalEntry."Document Type" := EnumAssignmentMgt.GetSalesApprovalDocumentType(SalesHeader."Document Type");
        ApprovalEntry."Document No." := SalesHeader."No.";
        ApprovalEntry."Record ID to Approve" := SalesHeader.RecordId;
        ApprovalEntry.Insert();
    end;

    local procedure CreateWorkflowStepInstanceWithTwoResponses(var FirstWorkflowStepInstance: Record "Workflow Step Instance"; var SecondWorkflowStepInstance: Record "Workflow Step Instance"; SecondResponseCode: Code[128])
    var
        Workflow: Record Workflow;
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        Workflow.Enabled := true;
        Workflow.Modify();

        CreateResponseWorkflowStepInstance(FirstWorkflowStepInstance, Workflow.Code,
          CreateGuid(), WorkflowResponseHandling.DoNothingCode(), 1, 0, FirstWorkflowStepInstance.Status::Completed);

        CreateResponseWorkflowStepInstance(SecondWorkflowStepInstance, Workflow.Code,
          FirstWorkflowStepInstance.ID, SecondResponseCode, 2, 1, SecondWorkflowStepInstance.Status::Active);
    end;

    local procedure CreateWorkflowStepInstanceWithSendForApprovalResponse(var FirstWorkflowStepInstance: Record "Workflow Step Instance"; var SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance")
    var
        CreateApprovalReqWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprovalReqWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());
        AddNotificationArgumentToStep(CreateApprovalReqWorkflowStepInstance, '');

        CreateResponseStepAfterGivenStepWithNotification(CreateApprovalReqWorkflowStepInstance, SendForApprovalWorkflowStepInstance,
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode());
    end;

    local procedure CreateWorkflowStepInstanceWithSendForApprovalToUserGroupResponse(var FirstWorkflowStepInstance: Record "Workflow Step Instance"; var SendForApprovalWorkflowStepInstance: Record "Workflow Step Instance"; WorkflowUserGroupCode: Code[20])
    var
        CreateApprovalReqWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        CreateWorkflowStepInstanceWithTwoResponses(FirstWorkflowStepInstance, CreateApprovalReqWorkflowStepInstance,
          WorkflowResponseHandling.CreateApprovalRequestsCode());
        AddWorkflowUserGroupArgumentToStep(CreateApprovalReqWorkflowStepInstance, WorkflowUserGroupCode);

        CreateResponseStepAfterGivenStepWithNotification(CreateApprovalReqWorkflowStepInstance, SendForApprovalWorkflowStepInstance,
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode());
    end;

    local procedure CreateResponseWorkflowStepInstance(var WorkflowStepInstance: Record "Workflow Step Instance"; WorkflowCode: Code[20]; WorkflowInstanceId: Guid; FunctionCode: Code[128]; StepId: Integer; PreviousStepId: Integer; Status: Option)
    begin
        WorkflowStepInstance.ID := WorkflowInstanceId;
        WorkflowStepInstance."Workflow Code" := WorkflowCode;
        WorkflowStepInstance."Workflow Step ID" := StepId;
        WorkflowStepInstance.Type := WorkflowStepInstance.Type::Response;
        WorkflowStepInstance."Function Name" := FunctionCode;
        WorkflowStepInstance.Status := Status;
        WorkflowStepInstance."Previous Workflow Step ID" := PreviousStepId;
        WorkflowStepInstance.Insert();
    end;

    local procedure CreateWorkflowCustomerRecordChange(Customer: Record Customer; FieldNo: Integer; OldValue: Text; NewValue: Text; InstanceId: Guid)
    var
        WorkflowRecordChange: Record "Workflow - Record Change";
    begin
        WorkflowRecordChange.Init();
        WorkflowRecordChange."Old Value" := CopyStr(OldValue, 1, MaxStrLen(WorkflowRecordChange."Old Value"));
        WorkflowRecordChange."New Value" := CopyStr(NewValue, 1, MaxStrLen(WorkflowRecordChange."New Value"));
        WorkflowRecordChange."Table No." := DATABASE::Customer;
        WorkflowRecordChange."Field No." := FieldNo;
        WorkflowRecordChange."Record ID" := Customer.RecordId;
        WorkflowRecordChange."Workflow Step Instance ID" := InstanceId;
        WorkflowRecordChange.Insert(true)
    end;

    local procedure CreateNotifyOnItemChangeWorkflow();
    var
        Workflow: Record Workflow;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        CurrStep: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);
        CurrStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnItemChangedCode());
        CurrStep := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), CurrStep);
#pragma warning disable AA0139
        LibraryWorkflow.InsertNotificationArgument(CurrStep, UserId(), 0, '');
#pragma warning restore AA0139
        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure RegetPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.FindFirst();
    end;

    local procedure RegetSalesDocument(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
    end;

    local procedure CreateOrFindUserSetup(var UserSetup: Record "User Setup"; UserName: Text[208])
    begin
        if not LibraryDocumentApprovals.GetUserSetup(UserSetup, CopyStr(UserName, 1, 50)) then
            LibraryDocumentApprovals.CreateUserSetup(UserSetup, CopyStr(UserName, 1, 50), '');
    end;

    local procedure CreateOrFindCurrentUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        if not LibraryDocumentApprovals.GetUserSetup(UserSetup, UserId) then
            LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId, '');
    end;

    local procedure CreateThreeUserSetupWithSequentialWorkflowUserGroup(var WorkflowUserGroup: Record "Workflow User Group"; var UserSetup1: Record "User Setup"; var UserSetup2: Record "User Setup"; var UserSetup3: Record "User Setup")
    var
        WorkflowUserGroupMember: Record "Workflow User Group Member";
    begin
        CreateWorkflowUserGroup(WorkflowUserGroup);

        // Crete 3 usersetups
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup1);
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup2);
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup3);

        CreateWorkflowUserGroupMember(WorkflowUserGroupMember, WorkflowUserGroup.Code, UserSetup1."User ID", false);
        CreateWorkflowUserGroupMember(WorkflowUserGroupMember, WorkflowUserGroup.Code, UserSetup2."User ID", false);
        CreateWorkflowUserGroupMember(WorkflowUserGroupMember, WorkflowUserGroup.Code, UserSetup3."User ID", false);
    end;

    local procedure CreateThreeUserSetupWithFlatWorkflowUserGroup(var WorkflowUserGroup: Record "Workflow User Group"; var UserSetup1: Record "User Setup"; var UserSetup2: Record "User Setup"; var UserSetup3: Record "User Setup")
    var
        WorkflowUserGroupMember: Record "Workflow User Group Member";
    begin
        CreateWorkflowUserGroup(WorkflowUserGroup);

        // Crete 3 usersetups
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup1);
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup2);
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup3);

        CreateWorkflowUserGroupMember(WorkflowUserGroupMember, WorkflowUserGroup.Code, UserSetup1."User ID", true);
        CreateWorkflowUserGroupMember(WorkflowUserGroupMember, WorkflowUserGroup.Code, UserSetup2."User ID", true);
        CreateWorkflowUserGroupMember(WorkflowUserGroupMember, WorkflowUserGroup.Code, UserSetup3."User ID", true);
    end;

    local procedure CreateThreeUserSetupWithApproverChain(var UserSetup: Record "User Setup"; var Approver1UserSetup: Record "User Setup"; var Approver2UserSetup: Record "User Setup")
    begin
        // Crete 3 users
        CreateOrFindUserSetup(UserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(Approver1UserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(Approver2UserSetup);

        SetApprover(UserSetup, Approver1UserSetup);
        SetApprover(Approver1UserSetup, Approver2UserSetup);

        SetPurchaseApprovalLimit(UserSetup, 100);
        SetPurchaseApprovalLimit(Approver1UserSetup, 1000);
        SetUnlimitedPurchaseApprovalLimit(Approver2UserSetup);

        SetSalesApprovalLimit(UserSetup, 100);
        SetSalesApprovalLimit(Approver1UserSetup, 1000);
        SetUnlimitedSalesApprovalLimit(Approver2UserSetup);
    end;

    local procedure CreateThreeUserSetupWithApproverChainFirstQualified(var UserSetup: Record "User Setup"; var ApproversUserSetup: array[2] of Record "User Setup"; Limit: Integer)
    begin
        // Create 3 users

        // 1st - with Limit = 100, Salesperson/Purchaser Code = "X" and "Approver ID" = "User B"
        // 2nd - with Limit = 1000,
        // 3rd - approval request sender
        CreateOrFindUserSetup(UserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproversUserSetup[1]);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproversUserSetup[2]);

        SetApprover(ApproversUserSetup[1], ApproversUserSetup[2]);

        SetPurchaseApprovalLimit(ApproversUserSetup[1], Limit);
        SetSalesApprovalLimit(ApproversUserSetup[1], Limit);
        SetPurchaseApprovalLimit(ApproversUserSetup[2], Limit * 10);
        SetSalesApprovalLimit(ApproversUserSetup[2], Limit * 10);
    end;

    local procedure CreateResponseStepAfterGivenStepWithNotification(FirstWorkflowStepInstance: Record "Workflow Step Instance"; var SecondWorkflowStepInstance: Record "Workflow Step Instance"; FunctionName: Code[128])
    begin
        CreateResponseWorkflowStepInstance(SecondWorkflowStepInstance, FirstWorkflowStepInstance."Workflow Code",
          FirstWorkflowStepInstance.ID, FunctionName, FirstWorkflowStepInstance."Workflow Step ID" + 1,
          FirstWorkflowStepInstance."Workflow Step ID", FirstWorkflowStepInstance.Status::Inactive);
        AddNotificationArgumentToStep(SecondWorkflowStepInstance, '');
    end;

    local procedure SetApprover(var UserSetup: Record "User Setup"; var ApproverUserSetup: Record "User Setup")
    begin
        UserSetup."Approver ID" := ApproverUserSetup."User ID";
        UserSetup.Modify(true);
    end;

    local procedure SetPurchaseApprovalLimit(var UserSetup: Record "User Setup"; PurchaseApprovalLimit: Integer)
    begin
        UserSetup."Purchase Amount Approval Limit" := PurchaseApprovalLimit;
        UserSetup."Unlimited Purchase Approval" := false;
        UserSetup.Modify(true);
    end;

    local procedure SetUnlimitedPurchaseApprovalLimit(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Purchase Approval" := true;
        UserSetup.Modify(true);
    end;

    local procedure SetSalesApprovalLimit(var UserSetup: Record "User Setup"; SalesApprovalLimit: Integer)
    begin
        UserSetup."Sales Amount Approval Limit" := SalesApprovalLimit;
        UserSetup."Unlimited Sales Approval" := false;
        UserSetup.Modify(true);
    end;

    local procedure SetUnlimitedSalesApprovalLimit(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Sales Approval" := true;
        UserSetup.Modify(true);
    end;

    local procedure CreatePurchInvWithLine(var PurchHeader: Record "Purchase Header"; Amount: Decimal)
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
        PurchLine.Validate("Direct Unit Cost", Amount);
        PurchLine.Modify(true);
    end;

    local procedure CreateSalesInvWithLine(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure UpdatePurchaseDocPurchaserCode(var PurchaseHeader: Record "Purchase Header"; PurchaserCode: Code[20])
    begin
        PurchaseHeader."Purchaser Code" := PurchaserCode;
        PurchaseHeader.Modify();
    end;

    local procedure UpdateSalesDocSalespersonCode(var SalesHeader: Record "Sales Header"; SalespersonCode: Code[20])
    begin
        SalesHeader."Salesperson Code" := SalespersonCode;
        SalesHeader.Modify();
    end;

    local procedure AddNotificationArgumentToStep(var WorkflowStepInstance: Record "Workflow Step Instance"; NotifUserID: Code[50])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        LibraryWorkflow.CreateWorkflowStepArgument(WorkflowStepArgument, WorkflowStepArgument.Type::Response,
          NotifUserID, '', '', WorkflowStepArgument."Approver Type"::Approver, true);
        WorkflowStepArgument.Validate("Approver Limit Type",
          WorkflowStepArgument."Approver Limit Type"::"Approver Chain");
        WorkflowStepArgument.Modify(true);

        WorkflowStepInstance.Validate(Argument, WorkflowStepArgument.ID);
        WorkflowStepInstance.Modify(true);
    end;

    local procedure AddCreatePmtLineArgumentToStep(var WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryWorkflow.CreateWorkflowStepArgument(WorkflowStepArgument, WorkflowStepArgument.Type::Response,
          '', GenJournalBatch."Journal Template Name", GenJournalBatch.Name, WorkflowStepArgument."Approver Type"::Approver, true);
        WorkflowStepArgument.Modify(true);

        WorkflowStepInstance.Validate(Argument, WorkflowStepArgument.ID);
        WorkflowStepInstance.Modify(true);
    end;

    local procedure AddWorkflowUserGroupArgumentToStep(var WorkflowStepInstance: Record "Workflow Step Instance"; WorkflowUserGroupCode: Code[20])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        LibraryWorkflow.CreateWorkflowStepArgument(WorkflowStepArgument, WorkflowStepArgument.Type::Response,
          '', '', '', WorkflowStepArgument."Approver Type"::"Workflow User Group", true);
        WorkflowStepArgument.Validate("Workflow User Group Code", WorkflowUserGroupCode);
        WorkflowStepArgument.Modify(true);

        WorkflowStepInstance.Validate(Argument, WorkflowStepArgument.ID);
        WorkflowStepInstance.Modify(true);
    end;

    local procedure AddFieldNoArgumentToStep(var WorkflowStepInstance: Record "Workflow Step Instance"; TableNo: Integer; FieldNo: Integer)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        LibraryWorkflow.CreateWorkflowStepArgument(WorkflowStepArgument, WorkflowStepArgument.Type::Response,
          '', '', '', WorkflowStepArgument."Approver Type"::"Workflow User Group", true);
        WorkflowStepArgument.Validate("Table No.", TableNo);
        WorkflowStepArgument.Validate("Field No.", FieldNo);
        WorkflowStepArgument.Modify(true);

        WorkflowStepInstance.Validate(Argument, WorkflowStepArgument.ID);
        WorkflowStepInstance.Modify(true);
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

    local procedure VerifySalesInvIsReleased(var SalesHeader: Record "Sales Header")
    begin
        RegetSalesDocument(SalesHeader);
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
    end;

    local procedure VerifySalesInvIsOpen(var SalesHeader: Record "Sales Header")
    begin
        RegetSalesDocument(SalesHeader);
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
    end;

    local procedure VerifyApprovalCommentLineForPurchInv(PurchaseHeader: Record "Purchase Header"; ExpectedCommentTxt: Text[80])
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", DATABASE::"Purchase Header");
        ApprovalCommentLine.SetRange("Record ID to Approve", PurchaseHeader.RecordId);
        ApprovalCommentLine.FindFirst();
        ApprovalCommentLine.TestField(Comment, ExpectedCommentTxt);
    end;

    local procedure VerifyApprovalCommentLineForSalesInv(SalesHeader: Record "Sales Header"; ExpectedCommentTxt: Text[80])
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", DATABASE::"Sales Header");
        ApprovalCommentLine.SetRange("Record ID to Approve", SalesHeader.RecordId);
        ApprovalCommentLine.FindFirst();
        ApprovalCommentLine.TestField(Comment, ExpectedCommentTxt);
    end;

    local procedure VerifyApprovalCommentLineForItem(Item: Record Item; ExpectedCommentTxt: Text[80])
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", DATABASE::Item);
        ApprovalCommentLine.SetRange("Record ID to Approve", Item.RecordId);
        ApprovalCommentLine.FindFirst();
        ApprovalCommentLine.TestField(Comment, ExpectedCommentTxt);
    end;

    local procedure VerifyApprovalEntry(ApprovalEntry: Record "Approval Entry"; SenderID: Code[50]; ApproverID: Code[50]; ApprovalType: Enum "Workflow Approval Type"; LimitType: Enum "Workflow Approval Limit Type"; DueDateFormula: DateFormula; SequenceNo: Integer)
    begin
        VerifyApprovalEntrySenderID(ApprovalEntry, SenderID);
        VerifyApprovalEntryApproverID(ApprovalEntry, ApproverID);
        VerifyApprovalEntrySequenceNo(ApprovalEntry, SequenceNo);
        VerifyApprovalEntryAdditionalFields(ApprovalEntry, ApprovalType, LimitType, DueDateFormula);
    end;

    local procedure VerifyApprovalEntryIsApproved(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Approved);
    end;

    local procedure VerifyApprovalEntryIsOpen(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Open);
    end;

    local procedure VerifyApprovalEntryIsCreated(ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Created);
    end;

    local procedure VerifyApprovalEntrySenderID(ApprovalEntry: Record "Approval Entry"; SenderId: Code[50])
    begin
        ApprovalEntry.TestField("Sender ID", SenderId);
    end;

    local procedure VerifyApprovalEntryApproverID(ApprovalEntry: Record "Approval Entry"; ApproverId: Code[50])
    begin
        ApprovalEntry.TestField("Approver ID", ApproverId);
    end;

    local procedure VerifyApprovalEntrySequenceNo(ApprovalEntry: Record "Approval Entry"; SequenceNo: Integer)
    begin
        ApprovalEntry.TestField("Sequence No.", SequenceNo);
    end;

    local procedure VerifyApprovalEntryAdditionalFields(ApprovalEntry: Record "Approval Entry"; ApproverType: Enum "Workflow Approval Type"; ApproverLimitType: Enum "Workflow Approval Limit Type"; DueDateFormula: DateFormula)
    begin
        ApprovalEntry.TestField("Approval Type", ApproverType);
        ApprovalEntry.TestField("Limit Type", ApproverLimitType);
        ApprovalEntry.TestField("Due Date", CalcDate(DueDateFormula, Today));
    end;

    local procedure VerifyNotificationEntry(RecipientUserID: Code[50]; NoOfEntries: Integer)
    var
        NotificationEntry: Record "Notification Entry";
    begin
        NotificationEntry.SetRange("Recipient User ID", RecipientUserID);
        Assert.RecordIsNotEmpty(NotificationEntry);
        Assert.RecordCount(NotificationEntry, NoOfEntries);
    end;

    local procedure VerifyNotificationEntryIsEmptyForRecipient(RecipientUserID: Code[50])
    var
        NotificationEntry: Record "Notification Entry";
    begin
        NotificationEntry.SetRange("Recipient User ID", RecipientUserID);
        Assert.RecordIsEmpty(NotificationEntry);
    end;

    local procedure VerifyNotificationsForApprovers(var ApprovalEntry: Record "Approval Entry"; Approver1UserSetup: Record "User Setup"; Approver2UserSetup: Record "User Setup"; ExpectedNotifQtyApprover1: Integer; ExpectedNotifQtyApprover2: Integer)
    begin
        ApprovalEntry.SetRange("Approver ID", Approver1UserSetup."User ID");
        ApprovalEntry.FindFirst();
        VerifyNotificationEntry(ApprovalEntry."Approver ID", ExpectedNotifQtyApprover1);

        ApprovalEntry.SetRange("Approver ID", Approver2UserSetup."User ID");
        ApprovalEntry.FindFirst();
        case ExpectedNotifQtyApprover2 of
            0:
                VerifyNotificationEntryIsEmptyForRecipient(ApprovalEntry."Approver ID");
            else
                VerifyNotificationEntry(ApprovalEntry."Approver ID", ExpectedNotifQtyApprover2);
        end;
    end;

    local procedure GetApprovalEntriesForInv(var ApprovalEntry: Record "Approval Entry"; TableID: Integer; DocumentNo: Code[20])
    begin
        ApprovalEntry.SetRange("Table ID", TableID);
        ApprovalEntry.SetRange("Document Type", ApprovalEntry."Document Type"::Invoice);
        ApprovalEntry.SetRange("Document No.", DocumentNo);
        ApprovalEntry.FindSet();
    end;

    local procedure CreateWorkflowUserGroup(var WorkflowUserGroup: Record "Workflow User Group")
    begin
        WorkflowUserGroup.Init();
        WorkflowUserGroup.Code :=
          LibraryUtility.GenerateRandomCode(WorkflowUserGroup.FieldNo(Code),
            DATABASE::"Workflow User Group");
        WorkflowUserGroup.Insert();
    end;

    local procedure CreateWorkflowUserGroupMember(var WorkflowUserGroupMember: Record "Workflow User Group Member"; WorkflowUserGroupCode: Code[20]; UserID: Code[50]; FlatGroup: Boolean)
    begin
        WorkflowUserGroupMember.Init();
        WorkflowUserGroupMember.Validate("Workflow User Group Code", WorkflowUserGroupCode);
        WorkflowUserGroupMember.Validate("User Name", UserID);
        if FlatGroup then
            WorkflowUserGroupMember."Sequence No." := 1;
        WorkflowUserGroupMember.Insert(true);
        Clear(WorkflowUserGroupMember);
    end;

    local procedure CreateApprovalArgument(var WorkflowStepInstance: Record "Workflow Step Instance"; ApproverType: Enum "Workflow Approver Type"; LimitType: Enum "Workflow Approver Limit Type"; DueDateFormula: DateFormula; WFUserGroup: Code[20]; ShowMessage: Boolean)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        LibraryWorkflow.CreateWorkflowStepArgument(WorkflowStepArgument, WorkflowStepArgument.Type::Response,
          '', '', '', ApproverType, true);
        WorkflowStepArgument.Validate("Due Date Formula", DueDateFormula);
        WorkflowStepArgument.Validate("Approver Limit Type", LimitType);
        WorkflowStepArgument.Validate("Workflow User Group Code", WFUserGroup);
        WorkflowStepArgument.Validate("Show Confirmation Message", ShowMessage);
        WorkflowStepArgument.Modify(true);
        WorkflowStepInstance.Argument := WorkflowStepArgument.ID;
        WorkflowStepInstance.Modify();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure OverdueMessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ShowMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ShowMessageTestMsg, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ApplyNewValuesMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ApplyNewValuesTestMsg, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ApplyNewValuesNoRecChangesMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(NoRecordChangesFoundMsg, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PendingApprovalMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(PendingApprovalMsg, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure RecordApprovedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(RecHasBeenApprovedMsg, Message);
    end;

    local procedure CreateWFStepInstanceWithCustomerAndRecordChange(var WorkflowStepInstance: Record "Workflow Step Instance"; var Customer: Record Customer)
    var
        DiscardNewValuesWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        CreateWorkflowStepInstanceWithTwoResponses(WorkflowStepInstance, DiscardNewValuesWorkflowStepInstance,
          WorkflowResponseHandling.DiscardNewValuesCode());

        LibrarySales.CreateCustomer(Customer);

        CreateWorkflowCustomerRecordChange(Customer, Customer.FieldNo("Credit Limit (LCY)"),
          Format(LibraryRandom.RandDec(100, 2)), Format(LibraryRandom.RandDec(100, 2)), DiscardNewValuesWorkflowStepInstance.ID);
    end;
}

