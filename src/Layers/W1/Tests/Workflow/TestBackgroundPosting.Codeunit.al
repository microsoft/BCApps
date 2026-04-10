codeunit 139027 "Test Background Posting"
{
    // 
    // NOTE: Test Execution
    //   In NAV7, TestIsolation does not support Background Sessions. These tests therefore
    //   fail fast when TestIsolation is enabled. Note that TestIsolation is enabled in SNAP so these
    //   tests cannot be run in SNAP.
    //   How to run these tests in the lab: use the Gate tool.
    //   How to run these tests in your development box:
    //     1. Set the TestIsolation property to Disabled for the Test Runner COD130020, recompile it and use it
    //     through the Test Tool PAG130021.
    //     2. Alternatively, run codeunit directly from CSIDE or run command ALTest runtests /runner:130202 133503.
    // NOTE: Database Rollback
    //   Our Database rollback mechanisms do not support transactions coming from Background Sessions. Running these
    //   tests therefore leaves the database in an unknown state where some tables will be out of sync with others.
    //   This easily impacts other tests and creates failures which are difficult to debug. The C# wrappers which
    //   are used to run these tests have therefore been placed in a separate C# project in file "BackgroundSessionTests.cs"
    //   so that they are isolated and run with a clean database without impacting other tests.
    // NOTE: Checking in changes to this codeunit
    //   This codeunit has been tagged with the "UNSAFE" keyword in the VersionList: the command ALTest CSWRAP
    //   ignores test codeunits with this keyword and does not generate C# wrappers in GeneratedTests.cs. When you
    //   add\remove\update test functions in this codeunit, you need to manually created\update the C# wrappers
    //   in BackgroundSessionTests.cs.
    // NOTE: Execution Parallelization
    //   The assumption is that Tests in this Codeunit are NOT run in parallel on the same Service Instance
    //   and are NOT distributed across multiple Service Instances. This may have unpredictable results due to the
    //   nature of the Job Queue.
    // NOTE: Background Session Cleanup
    //   Tests are intentionally structured in such a way that they attempt to clean up Background Sessions
    //   before performing validation. This is important to ensure reliability and repeatability of tests.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue] [Background Posting]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        PostTimeoutErr: Label 'Document exceeded timeout when posting: Header %1 still present and JobQueueStatus is %2.';
        JobQueueLogEntriesCntErr: Label 'The count of job queue log entries is not the expected one.';
        HeaderNotFoundErr: Label '%1 was not found in %2.';
        TextNotFoundErr: Label 'Document No.: %1 was not found in %2.';
        FinishedSuccessfullyTxt: Label 'finished successfully';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Background Posting");
        // These steps are executed once per test.
        DeleteAllJobQueueEntries();

        // These steps are executed only once per codeunit.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Background Posting");
        SalesAndPurchSetup();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Background Posting");
    end;

    local procedure SalesAndPurchSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Post with Job Queue" := true;
        SalesSetup."Ext. Doc. No. Mandatory" := true;
        SalesSetup.Modify();
        PurchSetup.Get();
        PurchSetup."Post with Job Queue" := true;
        PurchSetup."Ext. Doc. No. Mandatory" := true;
        PurchSetup.Modify();
    end;

    local procedure DeleteAllJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        Commit();
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        Commit();
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := DocumentType;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", '10000');
        SalesHeader."External Document No." := SalesHeader."No.";
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        SalesHeader.Modify(true);

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", '70000');
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchDocument(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchLine: Record "Purchase Line";
        LibraryPurch: Codeunit "Library - Purchase";
    begin
        LibraryPurch.CreatePurchHeader(PurchHeader, DocumentType, '10000');

        if PurchHeader."Document Type" = PurchHeader."Document Type"::"Return Order" then
            PurchHeader.Validate("Vendor Cr. Memo No.", PurchHeader."No.");
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchHeader.Modify(true);

        LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, '70000', 1);
        if PurchHeader."Document Type" = PurchHeader."Document Type"::"Return Order" then begin
            PurchLine.Validate("Direct Unit Cost", 1);
            PurchLine.Validate("Qty. to Receive", 0);
        end;
        PurchLine.Modify(true);
    end;

    local procedure WaitForSalesHeaderRemoved(var SalesHeader: Record "Sales Header"): Boolean
    var
        i: Integer;
    begin
        while (i < 1000) and SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.") do begin
            Commit();
            Sleep(200);
            i := i + 1;
        end;
        exit(i < 1000);
    end;

    local procedure WaitForPurchaseHeaderRemoved(var PurchaseHeader: Record "Purchase Header"): Boolean
    var
        i: Integer;
    begin
        while (i < 1000) and PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.") do begin
            Commit();
            Sleep(200);
            i := i + 1;
        end;
        exit(i < 1000);
    end;

    local procedure WaitForNumberOfJobQueueLogEntries(ExpectedCount: Integer; JobQueueLogEntryStatus: Option): Integer
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        Iterations: Integer;
        NoOfEntries: Integer;
    begin
        // Job Queue Log Entry is inserted at the end of the background process, and may not yet be inserted.
        JobQueueLogEntry.SetRange(Status, JobQueueLogEntryStatus);

        if ExpectedCount = 0 then begin
            // We expect no log entries, so wait for one, but don't wait that long
            ExpectedCount := 1;
            Iterations := 50;
        end else
            Iterations := 1000;

        while (NoOfEntries <> ExpectedCount) and (Iterations > 0) do begin
            Sleep(200);
            NoOfEntries := JobQueueLogEntry.Count();
            Iterations -= 1;
        end;

        exit(NoOfEntries);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
        Assert.IsTrue(
          StrPos(Msg, 'scheduled') <> 0,
          'Expected UI message containing "scheduled", but got "' + Msg + '"');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderDifferentCategoryTest()
    var
        SalesHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        BackgroundSessionsTestLib: Codeunit "Background Sessions Test Lib";
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
        WasJobPosted: Boolean;
    begin
        Initialize();

        // Set up documents to be posted with a category different than the category
        // filter on the job queue, so that the job queue will not pick up the job.
        SalesSetup.Get();
        SalesSetup."Job Queue Category Code" := 'SALESPOST';
        SalesSetup.Modify();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesPostViaJobQueue.EnqueueSalesDoc(SalesHeader);
        Commit();

        BackgroundSessionsTestLib.CleanupAll();

        // Ensure that job was not posted because of the job queue category filter
        WasJobPosted := not SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.Delete();
        JobQueueEntry.DeleteAll();
        Assert.IsFalse(
          WasJobPosted,
          'Expected document to not have been posted, since the job queue is filtered to a different category');

        Assert.AreEqual(
          0,
          WaitForNumberOfJobQueueLogEntries(0, JobQueueLogEntry.Status::Success),
          JobQueueLogEntriesCntErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderSameCategoryTest()
    var
        SalesHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        BackgroundSessionsTestLib: Codeunit "Background Sessions Test Lib";
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
    begin
        Initialize();

        // Set up documents to be posted with the same category different as the filter
        // on the job queue, so that the job queue will pick up the job.
        SalesSetup.Get();
        SalesSetup."Job Queue Category Code" := 'SALESPOST';
        SalesSetup.Modify();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesPostViaJobQueue.EnqueueSalesDoc(SalesHeader);
        Commit();

        WaitForSalesHeaderRemoved(SalesHeader);

        BackgroundSessionsTestLib.CleanupAll();

        Assert.IsFalse(
          SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."),
          StrSubstNo(PostTimeoutErr, SalesHeader."No.", SalesHeader."Job Queue Status"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderDifferentCategoryTest()
    var
        PurchHeader: Record "Purchase Header";
        PurchSetup: Record "Purchases & Payables Setup";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        BackgroundSessionsTestLib: Codeunit "Background Sessions Test Lib";
        PurchPostViaJobQueue: Codeunit "Purchase Post via Job Queue";
        WasJobPosted: Boolean;
    begin
        Initialize();

        // Set up documents to be posted with a category different than the category
        // filter on the job queue, so that the job queue will not pick up the job.
        PurchSetup.Get();
        PurchSetup."Job Queue Category Code" := 'PURCHPOST';
        PurchSetup.Modify();

        CreatePurchDocument(PurchHeader, PurchHeader."Document Type"::Order);
        PurchPostViaJobQueue.EnqueuePurchDoc(PurchHeader);
        Commit();

        BackgroundSessionsTestLib.CleanupAll();

        // Ensure that job was not posted because of the job queue category filter
        WasJobPosted := not PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        PurchHeader.Delete();
        JobQueueEntry.DeleteAll();
        Assert.IsFalse(
          WasJobPosted,
          'Expected document to not have been posted, since the job queue is filtered to a different category');

        Assert.AreEqual(
          0,
          WaitForNumberOfJobQueueLogEntries(0, JobQueueLogEntry.Status::Success),
          JobQueueLogEntriesCntErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderSameCategoryTest()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        Initialize();

        // Set up documents to be posted with the same category different as the filter
        // on the job queue, so that the job queue will pick up the job.
        PurchSetup.Get();
        PurchSetup."Job Queue Category Code" := 'PURCHPOST';
        PurchSetup.Modify();

        ValidatePostSales("Sales Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderNotificationTest()
    var
        SalesHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
    begin
        Initialize();

        SalesSetup.Get();
        SalesSetup."Notify On Success" := true;
        SalesSetup.Modify();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesPostViaJobQueue.EnqueueSalesDoc(SalesHeader); // background session created
        Commit();

        CleanBackgroundSessionsForSalesHeader(SalesHeader);

        Assert.IsFalse(
          SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."),
          StrSubstNo(PostTimeoutErr, SalesHeader."No.", SalesHeader."Job Queue Status"));

        VerifyJobQueueEntryPostedSuccessfully(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderNotificationNegativeTest()
    var
        SalesHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        RecordLink: Record "Record Link";
        BackgroundSessionsTestLib: Codeunit "Background Sessions Test Lib";
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
    begin
        Initialize();

        SalesSetup.Get();
        SalesSetup."Notify On Success" := false;
        SalesSetup.Modify();

        RecordLink.DeleteAll();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesPostViaJobQueue.EnqueueSalesDoc(SalesHeader); // background session created
        Commit();

        WaitForSalesHeaderRemoved(SalesHeader);

        BackgroundSessionsTestLib.CleanupAll();

        RecordLink.SetView('SORTING(Link ID) order(descending)');
        RecordLink.SetRange(Type, RecordLink.Type::Note);
        RecordLink.SetRange(Notify, true);
        asserterror RecordLink.FindFirst();
        Assert.AreEqual(0, RecordLink.Count, 'Did not expect any notifications, as "Notify On Success" is set to FALSE');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderNotificationTest()
    var
        PurchHeader: Record "Purchase Header";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchPostViaJobQueue: Codeunit "Purchase Post via Job Queue";
    begin
        Initialize();

        PurchSetup.Get();
        PurchSetup."Notify On Success" := true;
        PurchSetup.Modify();

        CreatePurchDocument(PurchHeader, PurchHeader."Document Type"::Order);
        PurchPostViaJobQueue.EnqueuePurchDoc(PurchHeader); // background session created

        CleanBackgroundSessionsForPurchaseHeader(PurchHeader);

        Assert.IsFalse(
          PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No."),
          StrSubstNo(PostTimeoutErr, PurchHeader."No.", PurchHeader."Job Queue Status"));

        VerifyJobQueueEntryPostedSuccessfully(PurchHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderNotificationNegativeTest()
    var
        PurchHeader: Record "Purchase Header";
        PurchSetup: Record "Purchases & Payables Setup";
        RecordLink: Record "Record Link";
        BackgroundSessionsTestLib: Codeunit "Background Sessions Test Lib";
        PurchPostViaJobQueue: Codeunit "Purchase Post via Job Queue";
    begin
        Initialize();

        PurchSetup.Get();
        PurchSetup."Notify On Success" := false;
        PurchSetup.Modify();

        RecordLink.DeleteAll();

        CreatePurchDocument(PurchHeader, PurchHeader."Document Type"::Order);
        PurchPostViaJobQueue.EnqueuePurchDoc(PurchHeader); // background session created
        Commit();

        WaitForPurchaseHeaderRemoved(PurchHeader);

        BackgroundSessionsTestLib.CleanupAll();

        RecordLink.SetView('SORTING(Link ID) order(descending)');
        RecordLink.SetRange(Type, RecordLink.Type::Note);
        RecordLink.SetRange(Notify, true);
        asserterror RecordLink.FindFirst();
        Assert.AreEqual(0, RecordLink.Count, 'Did not expect any notifications, as "Notify On Success" is set to FALSE');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ReceiveAndInvoiceStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderNotificationWithCalcInvDiscount()
    var
        PurchHeader: Record "Purchase Header";
    begin
        Initialize();
        UpdatePurchasePayableSetup(true, true);
        CreatePurchaseOrderAndPostUsingPage(PurchHeader);

        CleanBackgroundSessionsForPurchaseHeader(PurchHeader);

        VerifyJobQueueEntryPostedSuccessfully(PurchHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ReceiveAndInvoiceStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderNotificationWithCalcInvDiscount()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();
        UpdateSalesReceivableSetup(true, true);
        CreateSalesOrderAndPostUsingPage(SalesHeader);

        CleanBackgroundSessionsForSalesHeader(SalesHeader);

        VerifyJobQueueEntryPostedSuccessfully(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailManagementSubscriptionInTwoSessions()
    var
        ScheduledTask: Record "Scheduled Task";
        NameValueBuffer: Record "Name/Value Buffer";
        MailManagement: Codeunit "Mail Management";
        MailManagementConcurrency: Codeunit "Mail Management Concurrency";
        DummyRecordID: RecordID;
        TaskId: Guid;
        Counter: Integer;
        InsertCounter: Integer;
        TimeOut: Boolean;
    begin
        NameValueBuffer.DeleteAll();
        Commit();

        TaskId := TASKSCHEDULER.CreateTask(CODEUNIT::"Mail Management Concurrency", 0, true, CompanyName, CurrentDateTime, DummyRecordID);
        ScheduledTask.SetRange(ID, TaskId);

        while not ScheduledTask.IsEmpty() and not TimeOut do begin
            if not MailManagement.IsHandlingGetEmailBodyCustomer() then begin
                MailManagementConcurrency.InsertNameValueBuffer(NameValueBuffer);
                InsertCounter += 1;
            end;
            TimeOut := (Counter - 1) > Round(MailManagementConcurrency.GetSleepDuration() / 1000, 1);
            Counter += 1;
            Sleep(1000);
        end;

        Assert.IsFalse(TimeOut, 'Time out');
        Assert.IsTrue(Counter > 0, 'We did not wait for background job');
        Assert.IsTrue(InsertCounter < NameValueBuffer.Count, 'Background insert missing');
        Assert.RecordCount(NameValueBuffer, Counter + 1);

        NameValueBuffer.DeleteAll();
        Commit();
    end;

    [Test]
    [HandlerFunctions('DataSubjectModalPageHandler')]
    [Scope('OnPrem')]
    procedure DataPrivacyWizardExportExcelActivityLogSuccess()
    var
        Customer: Record Customer;
        ActivityLog: Record "Activity Log";
        DataSensitivity: Record "Data Sensitivity";
        DataPrivacyWizard: TestPage "Data Privacy Wizard";
        ActionType: Option "Export data subject data","Create configuration package";
    begin
        // [FEATURE] [Activity Log] [Data Privacy Utility] [UI]
        // [SCENARIO 273346] Write log to Activity Log table after successful export of an Excel file.

        // [GIVEN] Customer with "Partner Type" = Person.
        CreateCustomerWithPersonPartnerType(Customer);
        Commit();

        // [WHEN] Export privacy data for Customer to Excel.
        PrepareForExportDataPrivacyWizard(
          DataPrivacyWizard, ActionType::"Export data subject data", 'Customer',
          Customer."No.", DataSensitivity."Data Sensitivity"::Normal);
        InvokeExportDataPrivacyWizard(DataPrivacyWizard, false);

        // [THEN] Log with Status "Success" is inserted to Activity Log table.
        VerifyActivityLogExists(
          ActivityLog.Status::Success, StrSubstNo('*%1*%2*', Customer.TableCaption(), Customer."No."), 'Exporting data subject data');
    end;

    local procedure CleanBackgroundSessionsForSalesHeader(SalesHeader: Record "Sales Header")
    var
        BackgroundSessionsTestLib: Codeunit "Background Sessions Test Lib";
    begin
        Commit();
        WaitForSalesHeaderRemoved(SalesHeader);

        BackgroundSessionsTestLib.CleanupAll();
    end;

    local procedure CleanBackgroundSessionsForPurchaseHeader(PurchaseHeader: Record "Purchase Header")
    var
        BackgroundSessionsTestLib: Codeunit "Background Sessions Test Lib";
    begin
        Commit();
        WaitForPurchaseHeaderRemoved(PurchaseHeader);

        BackgroundSessionsTestLib.CleanupAll();
    end;

    local procedure CreatePurchaseOrderAndPostUsingPage(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.Post.Invoke();
    end;

    local procedure CreateSalesOrderAndPostUsingPage(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LibrarySales: Codeunit "Library - Sales";
        SalesOrder: TestPage "Sales Order";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.Post.Invoke();
    end;

    local procedure CreateCustomerWithPersonPartnerType(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Partner Type" := Customer."Partner Type"::Person;
        Customer.Modify();
    end;

    local procedure InvokeExportDataPrivacyWizard(var DataPrivacyWizard: TestPage "Data Privacy Wizard"; EditConfigPackage: Boolean)
    begin
        DataPrivacyWizard.NextAction.Invoke(); // Exports data
        DataPrivacyWizard.EditConfigPackage.SetValue(EditConfigPackage);
        DataPrivacyWizard.FinishAction.Invoke();
    end;

    local procedure PrepareForExportDataPrivacyWizard(var DataPrivacyWizard: TestPage "Data Privacy Wizard"; ActionType: Option; DataSubject: Text; DataSubjectIdentifier: Code[80]; DataSensitivity: Option)
    begin
        DataPrivacyWizard.Trap();
        PAGE.Run(PAGE::"Data Privacy Wizard");
        DataPrivacyWizard.NextAction.Invoke(); // Welcome Screen
        DataPrivacyWizard.ActionType.SetValue(ActionType);
        DataPrivacyWizard.NextAction.Invoke();
        LibraryVariableStorage.Enqueue(DataSubject);
        DataPrivacyWizard.EntityType.Lookup();
        DataPrivacyWizard.EntityNo.SetValue(DataSubjectIdentifier);
        DataPrivacyWizard.DataSensitivity.SetValue(DataSensitivity);
    end;

    local procedure UpdatePurchasePayableSetup(CalcInvDiscount: Boolean; NotifyOnSuccess: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Calc. Inv. Discount" := CalcInvDiscount;
        PurchasesPayablesSetup."Notify On Success" := NotifyOnSuccess;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure UpdateSalesReceivableSetup(CalcInvDiscount: Boolean; NotifyOnSuccess: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Calc. Inv. Discount" := CalcInvDiscount;
        SalesReceivablesSetup."Notify On Success" := NotifyOnSuccess;
        SalesReceivablesSetup.Modify();
    end;

    local procedure VerifyJobQueueEntryPostedSuccessfully(HeaderNo: Code[20])
    var
        RecordLink: Record "Record Link";
        NoteInStream: InStream;
        NoteTxt: Text;
    begin
        RecordLink.SetView('SORTING(Link ID) order(descending)');
        RecordLink.SetRange(Type, RecordLink.Type::Note);
        RecordLink.SetRange(Notify, true);
        RecordLink.FindFirst();
        RecordLink.CalcFields(Note);
        RecordLink.Note.CreateInStream(NoteInStream);
        NoteInStream.ReadText(NoteTxt);
        Assert.IsTrue(StrPos(NoteTxt, HeaderNo) <> 0, StrSubstNo(HeaderNotFoundErr, HeaderNo, NoteTxt));
        Assert.IsTrue(StrPos(NoteTxt, FinishedSuccessfullyTxt) <> 0, StrSubstNo(TextNotFoundErr, HeaderNo, NoteTxt));
    end;

    local procedure VerifyActivityLogExists(Status: Option; ActivityMessageFilter: Text[250]; DescriptionFilter: Text[250])
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.Init();
        ActivityLog.SetFilter("Activity Message", ActivityMessageFilter);
        ActivityLog.SetFilter(Description, DescriptionFilter);
        ActivityLog.SetFilter(Context, 'Privacy Activity');
        ActivityLog.SetRange(Status, Status);
        ActivityLog.SetRange("Table No Filter", DATABASE::Company);
        Assert.RecordIsNotEmpty(ActivityLog);
    end;

    [Normal]
    local procedure ValidatePostSales(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        BackgroundSessionsTestLib: Codeunit "Background Sessions Test Lib";
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
        NoOfJQLogEntries: Integer;
    begin
        Initialize();

        CreateSalesDocument(SalesHeader, DocumentType);
        SalesPostViaJobQueue.EnqueueSalesDoc(SalesHeader); // background session created
        Commit();

        WaitForSalesHeaderRemoved(SalesHeader);
        NoOfJQLogEntries := WaitForNumberOfJobQueueLogEntries(1, JobQueueLogEntry.Status::Success);

        BackgroundSessionsTestLib.CleanupAll();

        Assert.IsFalse(
          SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."),
          StrSubstNo(PostTimeoutErr, SalesHeader."No.", SalesHeader."Job Queue Status"));

        Assert.AreEqual(1, NoOfJQLogEntries, JobQueueLogEntriesCntErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DataSubjectModalPageHandler(var DataSubject: TestPage "Data Subject")
    var
        DataPrivacyEntities: Record "Data Privacy Entities";
        Value: Variant;
        TableCaption: Text;
    begin
        LibraryVariableStorage.Dequeue(Value);
        TableCaption := Value;
        DataPrivacyEntities.SetRange("Table Caption", TableCaption);
        DataPrivacyEntities.FindFirst();
        DataSubject.GotoRecord(DataPrivacyEntities);
        DataSubject.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ReceiveAndInvoiceStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 3;
    end;
}

