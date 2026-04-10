codeunit 134303 "Workflow Event Response Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        VendorNo: Code[20];
        UserEmailAddressTxt: Label 'test@contoso.com';
        GeneralJnlTemplateCode: Code[10];
        GeneralJnlBatchCode: Code[10];
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutomaticPostingOfPurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        JobQueueEntry: Record "Job Queue Entry";
        ItemNo: Code[20];
    begin
        // [SCENARIO 1] When a Purchase Invoice is released,
        // the Purchase Invoice will be automatically posted by running a Job Queue Entry.
        // [GIVEN] There is a Purchase Invoice sent for approval.
        // [WHEN] The Purchase Invoice is approved and released.
        // [THEN] A Job Queue Entry will be created and the Purchase Invoice will be automatically posted.

        // Setup
        Initialize();

        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo,
          LibraryRandom.RandInt(100));

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.CreatePurchaseHeaderPostingJobQueueEntry(JobQueueEntry, PurchaseHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Purchase Post via Job Queue", JobQueueEntry);

        // Validate
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        Assert.IsFalse(PurchInvHeader.IsEmpty, 'No posted Purchase Invoice was found. The posting has failed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePaymentLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        JobQueueEntry: Record "Job Queue Entry";
        ItemNo: Code[20];
    begin
        // [SCENARIO 2] When a Purchase Invoice is posted, a General Journal Line will be automatically created
        // [GIVEN] There is an approved Purchase Invoice .
        // [WHEN] The Purchase Invoice is posted.
        // [THEN] A General Journal Line will be created.

        // Setup
        Initialize();

        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        ItemNo := LibraryInventory.CreateItemNo();
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo,
          LibraryRandom.RandInt(100));

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.CreatePurchaseHeaderPostingJobQueueEntry(JobQueueEntry, PurchaseHeader);

        CODEUNIT.Run(CODEUNIT::"Purchase Post via Job Queue", JobQueueEntry);

        PurchInvHeader.Init();
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();

        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Workflow Create Payment Line");
        JobQueueEntry.FindFirst();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Workflow Create Payment Line", JobQueueEntry);

        // Validate
        VendorLedgerEntry.Get(PurchInvHeader."Vendor Ledger Entry No.");
        GenJournalLine.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
        GenJournalLine.SetRange("Source Line No.", VendorLedgerEntry."Entry No.");
        Assert.IsFalse(GenJournalLine.IsEmpty, 'No General Journal Line was found based on the Vendor Ledger Entry No.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNotificationCreatedForPaymentLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJournalLine: Record "Gen. Journal Line";
        JobQueueEntry: Record "Job Queue Entry";
        RecRef: RecordRef;
        ItemNo: Code[20];
    begin
        // [SCENARIO 3] When a Purchase Invoice is posted, a General Journal Line will be automatically created and
        // a notification will be created and the email will be sent.
        // [GIVEN] There is an approved Purchase Invoice .
        // [WHEN] The Purchase Invoice is posted.
        // [THEN] A General Journal Line will be created.
        // [THEN] A notification entry will be created and the email will be sent.

        // Setup
        Initialize();
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        ItemNo := LibraryInventory.CreateItemNo();
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo,
          LibraryRandom.RandInt(100));

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.CreatePurchaseHeaderPostingJobQueueEntry(JobQueueEntry, PurchaseHeader);

        CODEUNIT.Run(CODEUNIT::"Purchase Post via Job Queue", JobQueueEntry);

        PurchInvHeader.Init();
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();

        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Workflow Create Payment Line");
        JobQueueEntry.FindFirst();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Workflow Create Payment Line", JobQueueEntry);

        // Validate
        GenJournalLine.SetRange("Journal Template Name", GeneralJnlTemplateCode);
        GenJournalLine.SetRange("Journal Batch Name", GeneralJnlBatchCode);
        GenJournalLine.FindFirst();

        RecRef.GetTable(GenJournalLine);
        RecRef.Reset();
        VerifyNotificationEntry(RecRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowThatDoesNothingUsingDoNothing()
    begin
        TestWorkflowThatDoesNothing(WorkflowResponseHandling.DoNothingCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowThatDoesNothingUsingNonExistingResponse()
    begin
        asserterror TestWorkflowThatDoesNothing('Nonexisting');
        Assert.ExpectedError('The field Function Name of table Workflow Step contains a value (NONEXISTING) that cannot be' +
          ' found in the related table (Workflow Response).');
    end;

    local procedure TestWorkflowThatDoesNothing(ResponseFunctionName: Code[128])
    var
        IncomingDocument: Record "Incoming Document";
        NotificationEntry: Record "Notification Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobQueueEntry: Record "Job Queue Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO] Add workflow steps that do not trigger any action (either using DoNothing or a non-existing response).
        // [GIVEN] A new Incoming Document, a posted purchase invoice or a payment journal line.
        // [WHEN] The trigger is executed.
        // [THEN] No effect.

        // Setup.
        Initialize();
        LibraryWorkflow.DeleteAllExistingWorkflows();
        CreateWorkflowThatDoesNothing(ResponseFunctionName);
        LibraryIncomingDocuments.InitIncomingDocuments();

        // Exercise.
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Verify.
        Assert.IsTrue(NotificationEntry.IsEmpty, 'No notification should be created.');

        // Setup.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(100));

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.CreatePurchaseHeaderPostingJobQueueEntry(JobQueueEntry, PurchaseHeader);

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Purchase Post via Job Queue", JobQueueEntry);

        // Verify.
        PurchInvHeader.Init();
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();

        GenJournalLine.SetRange("Applies-to Doc. No.", PurchInvHeader."No.");
        Assert.IsTrue(GenJournalLine.IsEmpty, 'No General Journal Line should be created');

        // Exercise
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Insert();

        // Verify.
        Assert.IsTrue(NotificationEntry.IsEmpty, 'No notification should be created.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowPostingFailsOnSendForApproval()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO 6] Workflow fails when calling the OnPurchaseInvoiceSendForApproval for a non-released invoice
        // [GIVEN] There is an open Purchase Invoice.
        // [WHEN] The Workflow posting step is called.
        // [THEN] An error occurs.

        // Setup.
        Initialize();
        LibraryWorkflow.DeleteAllExistingWorkflows();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        CreateTwoStepsWorkflow(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(),
          WorkflowResponseHandling.PostDocumentAsyncCode());

        // Exercise.
        asserterror ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // Verify.
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Released));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowPostingCreatesNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Workflow that creates a notification when posting a purchase invoice
        // [GIVEN] There is an open Purchase Invoice.
        // [WHEN] The Workflow posting step is called.
        // [THEN] A notification is created.

        // Setup.
        Initialize();
        LibraryWorkflow.DeleteAllExistingWorkflows();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(100));

        CreateTwoStepsWorkflow(WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(),
          WorkflowResponseHandling.CreateNotificationEntryCode());

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        RecRef.GetTable(PurchInvHeader);
        VerifyNotificationEntry(RecRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWorkflowWithMultipleResponses()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Workflow Runs All Responses for an Event
        // [GIVEN] Workflow with one event and multiple responses
        // [GIVEN] A released purchase invoice
        // [WHEN] OnPurchaseDocReleased is run
        // [THEN] Notification entry is created

        Initialize();

        // Pre-Setup
        LibraryWorkflow.DeleteAllExistingWorkflows();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(100));

        // Setup
        CreateWorkflowWithMultipleResponse(WorkflowEventHandling.RunWorkflowOnAfterReleasePurchaseDocCode());

        // Exercise
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Verify
        RecRef.GetTable(PurchaseHeader);
        VerifyNotificationEntry(RecRef);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAllEventsPostPurchaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        Workflow.ModifyAll(Enabled, false);
        WorkflowEvent.DeleteAll();

        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', 0D);

        // Exercise
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify
        PurchInvHeader.Get(DocumentNo);
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Workflow Event Response Tests");
        PurchaseHeader.DeleteAll();
        PurchInvHeader.DeleteAll();
        JobQueueEntry.DeleteAll();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowEventHandling.CreateEventsLibrary();
        WorkflowResponseHandling.CreateResponsesLibrary();

        LibraryWorkflow.DeleteNotifications();
        CreateWorkflowToGenerateGeneralJournalLines();
        ConfigureEmail();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Workflow Event Response Tests");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Workflow Event Response Tests");
    end;

    local procedure CreateWorkflowToGenerateGeneralJournalLines()
    var
        Workflow: Record Workflow;
        WorkflowTableRelation: Record "Workflow - Table Relation";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowEntryPointStep: Integer;
        WorkflowEventStep1: Integer;
        WorkflowResponseStep1: Integer;
        WorkflowResponseStep2: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation, DATABASE::"Purch. Inv. Header", PurchaseHeader.FieldNo("No."),
          DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Applies-to Doc. No."));

        LibraryWorkflow.GetGeneralJournalTemplateAndBatch(GeneralJnlTemplateCode, GeneralJnlBatchCode);

        // 1. Create payment line
        WorkflowEntryPointStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode());
        WorkflowResponseStep1 := LibraryWorkflow.InsertResponseStep(Workflow,
            WorkflowResponseHandling.CreatePmtLineForPostedPurchaseDocAsyncCode(), WorkflowEntryPointStep);

        LibraryWorkflow.InsertPmtLineCreationArgument(WorkflowResponseStep1, GeneralJnlTemplateCode, GeneralJnlBatchCode);

        // 2. Notify user about new payment line
        WorkflowEventStep1 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertGeneralJournalLineCode(),
            WorkflowResponseStep1);
        WorkflowResponseStep2 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(),
            WorkflowEventStep1);

        LibraryWorkflow.InsertNotificationArgument(WorkflowResponseStep2, UserId, 0, '');

        EnableWorkflow(Workflow.Code);
    end;

    local procedure CreateWorkflowThatDoesNothing(ResponseFunctionName: Code[128])
    var
        Workflow: Record Workflow;
        WorkflowEntryPointStep: Integer;
        WorkflowEventStep1: Integer;
        WorkflowEventStep2: Integer;
        WorkflowResponseStep1: Integer;
        WorkflowResponseStep2: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        // 1. Incoming document created.
        WorkflowEntryPointStep :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertIncomingDocumentCode());
        WorkflowResponseStep1 := LibraryWorkflow.InsertResponseStep(Workflow, ResponseFunctionName, WorkflowEntryPointStep);

        // 2. Purchase invoice posted.
        WorkflowEventStep1 := LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterPostPurchaseDocCode(),
            WorkflowResponseStep1);
        WorkflowResponseStep2 := LibraryWorkflow.InsertResponseStep(Workflow, ResponseFunctionName, WorkflowEventStep1);

        // 3. Payment journal line created.
        WorkflowEventStep2 :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnAfterInsertGeneralJournalLineCode(),
            WorkflowResponseStep2);
        LibraryWorkflow.InsertResponseStep(Workflow, ResponseFunctionName, WorkflowEventStep2);

        EnableWorkflow(Workflow.Code);
    end;

    local procedure CreateWorkflowWithMultipleResponse(EventFunctionName: Code[128])
    var
        Workflow: Record Workflow;
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        EventID: Integer;
        ResponseID1: Integer;
        ResponseID2: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        EventID := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EventFunctionName);
        ResponseID1 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.PostDocumentCode(), EventID);
        ResponseID2 := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateNotificationEntryCode(), ResponseID1);

        LibraryWorkflow.InsertNotificationArgument(ResponseID2, UserId, 0, '');

        EnableWorkflow(Workflow.Code);
    end;

    local procedure CreateTwoStepsWorkflow(EventFunctionName: Code[128]; ResponseFunctionName: Code[128])
    var
        Workflow: Record Workflow;
        EventID: Integer;
        ResponseID: Integer;
    begin
        LibraryWorkflow.CreateWorkflow(Workflow);

        EventID := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EventFunctionName);
        ResponseID := LibraryWorkflow.InsertResponseStep(Workflow, ResponseFunctionName, EventID);

        LibraryWorkflow.InsertNotificationArgument(ResponseID, UserId, 0, '');

        EnableWorkflow(Workflow.Code);
    end;

    local procedure ConfigureEmail()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then begin
            UserSetup."User ID" := UserId;
            UserSetup."E-Mail" := UserEmailAddressTxt;
            UserSetup.Insert();
        end else
            if UserSetup."E-Mail" = '' then begin
                UserSetup."E-Mail" := UserEmailAddressTxt;
                UserSetup.Modify();
            end;
    end;

    local procedure VerifyNotificationEntry(RecRef: RecordRef)
    var
        NotificationEntry: Record "Notification Entry";
    begin
        NotificationEntry.SetRange("Triggered By Record", RecRef.RecordId);
        NotificationEntry.SetRange("Recipient User ID", UserId);
        NotificationEntry.FindFirst();

        Assert.AreEqual(1, NotificationEntry.Count, 'Unexpected notification entry.');
    end;

    local procedure EnableWorkflow(WorkflowCode: Code[20])
    var
        Workflow: Record Workflow;
    begin
        Workflow.Get(WorkflowCode);
        Workflow.Enabled := true;
        Workflow.Modify(true);
    end;
}

