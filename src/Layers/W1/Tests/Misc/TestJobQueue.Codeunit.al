codeunit 139026 "Test Job Queue"
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
    //     2. Alternatively, run codeunit directly from CSIDE or run command ALTest runtests /runner:130202 139026.
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

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue]
    end;

    var
        TimeoutErr: Label 'Timeout exceeded. %1.', Comment = '%1 is the reason why the timeout was exceeded, or any additional data needed to debug a timeout issue.';
        InteractionLogCreatedErr: Label 'Interaction log created';
        JobQueueEntryDidNotExecutedErr: Label 'Job Queue Entry did not executed!';
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        libraryInventory: Codeunit "Library - Inventory";
        LibraryMarketing: Codeunit "Library - Marketing";
        librarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryService: Codeunit "Library - Service";
        LibraryPurchase: Codeunit "Library - Purchase";

    [Test]
    [Scope('OnPrem')]
    procedure EnqueueUserSessionTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueEntryID: Guid;
    begin
        Initialize();

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Job Queue CAL Error Sample";
        JobQueueEntry."Job Queue Category Code" := 'TEST';

        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);  // 1 Background Session created.
        JobQueueEntryID := JobQueueEntry.ID;

        WaitForJobEntryStatus(JobQueueEntryID);

        JobQueueLogEntry.SetRange(ID, JobQueueEntryID);
        Assert.IsTrue(JobQueueLogEntry.FindFirst(), 'Cannot find log entry for job ' + Format(JobQueueEntryID));
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntry.Status, 'Unexpected status in the log');
        Assert.AreEqual('TEST', JobQueueLogEntry."Job Queue Category Code", 'Unexpected category in the log');
        Assert.AreEqual(UserId, JobQueueLogEntry."User ID", 'Unexpected userid in the log');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnqueueSameCategory()
    var
        JobQueueEntry: Record "Job Queue Entry";
        i: Integer;
        NoOfRemainingJobs: Integer;
    begin
        Initialize();

        for i := 1 to 3 do begin
            JobQueueEntry.Init();
            Clear(JobQueueEntry.ID);
            Clear(JobQueueEntry."System Task ID");
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Object ID to Run" := CODEUNIT::"Job Queue Sleeping Sample"; // sleeps 10s
            JobQueueEntry."Job Queue Category Code" := 'TEST';
            CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);  // 1 Background Session created.
            Commit();
            Sleep(1000); // allow a small interval between jobs
        end;
        Commit();
        i := 0;
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Job Queue Sleeping Sample");
        repeat
            Sleep(2000);
            NoOfRemainingJobs := JobQueueEntry.Count();
            JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
            Assert.IsTrue(JobQueueEntry.Count <= 1, 'More than one task runs at the same time');
            JobQueueEntry.SetRange(Status);
            i += 1;
        until (NoOfRemainingJobs = 0) or (i > 100);
        Assert.AreEqual(0, NoOfRemainingJobs, 'Not all jobs finished');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryShowRelatedTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Customer: Record Customer;
        CustomerLookup: TestPage "Customer Lookup";
        RecRef: RecordRef;
    begin
        Initialize();

        JobQueueEntry.LookupRecordToProcess(); // Does nothing, just returns.
        JobQueueEntry.ID := CreateGuid();
        asserterror JobQueueEntry.LookupRecordToProcess();
        Customer.Init();
        Customer.Insert(true);
        RecRef.GetTable(Customer);
        JobQueueEntry."Record ID to Process" := RecRef.RecordId;
        CustomerLookup.Trap();
        JobQueueEntry.LookupRecordToProcess();
        CustomerLookup.Close();
        Customer.Delete();
        asserterror JobQueueEntry.LookupRecordToProcess();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCreateEmptyJobQueueCategoryTest()
    var
        JobQueueCategoryList: TestPage "Job Queue Category List";
    begin
        JobQueueCategoryList.OpenNew();
        asserterror JobQueueCategoryList.Code.Value := '';
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GracefullDotNetErrorHandlingTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueEntryID: Guid;
        ErrorMsg: Text;
    begin
        Initialize();

        CreateJobQueueEntry(
          JobQueueEntry,
          JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Job Queue Exception Sample",
          JobQueueEntry.Status::Ready);
        JobQueueEntryID := JobQueueEntry.ID;
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        WaitForJobEntryStatus(JobQueueEntryID);

        JobQueueLogEntry.SetRange(ID, JobQueueEntryID);

        Assert.IsTrue(JobQueueLogEntry.FindFirst(), 'Cannot find log entry for job ' + Format(JobQueueEntryID));
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntry.Status, 'Unexpected status in the log');
        ErrorMsg := JobQueueLogEntry."Error Message";
        Assert.IsTrue(StrPos(ErrorMsg, 'System.Xml.XmlTextReader.Create') > 0, CopyStr('Unexpected error message:' + ErrorMsg, 1, 1024));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryOutdatedStart()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryLogFound: Boolean;
        Baseline: DateTime;
        StartingTime: Time;
        EndingTime: Time;
        Duration: Integer;
        EarliestStartingDateTime: DateTime;
        NextDay: Boolean;
    begin
        Initialize();

        Duration := 1;
        Baseline := RoundDateTime(CurrentDateTime, 1000, '>'); // Rounds to nearest second avoiding milisecond comparison failures.
        EarliestStartingDateTime := Baseline;
        StartingTime := DT2Time(Baseline) + 3 * 60 * 60 * 1000; // Sets to 3h from now.
        EndingTime := StartingTime + 1 * 60 * 60 * 1000;
        // We can meet case when StartingTime set to next day's (Baseline between 21-00 and 24-00). In this case next start date must be next day.
        NextDay := (DT2Time(Baseline) >= 210000T);

        // Test that when the Job Queue Entry is marked as Ready, the Earliest Start DateTime is automatically
        // adjusted to the next possible DateTime based on the Start\End Time boundaries.
        CreateTimeBasedRecurringJobQueueEntry(
          JobQueueEntry,
          StartingTime,
          EndingTime,
          Duration,
          EarliestStartingDateTime,
          JobQueueEntry.Status::Ready);
        Assert.AreEqual(
          StartingTime,
          DT2Time(JobQueueEntry."Earliest Start Date/Time"),
          StrSubstNo(
            'Earliest Start time should be set to that of StartingTime for baseline: %1',
            Baseline));
        if NextDay then
            Assert.AreEqual(DT2Date(Baseline) + 1, DT2Date(JobQueueEntry."Earliest Start Date/Time"),
              StrSubstNo(
                'Earliest Start date should be tomorrow for baseline: %1',
                Baseline))
        else
            Assert.AreEqual(DT2Date(Baseline), DT2Date(JobQueueEntry."Earliest Start Date/Time"),
              StrSubstNo(
                'Earliest Start date should be today for baseline: %1',
                Baseline));

        Assert.AreEqual(false, JobQueueEntryLogFound, 'Job Queue Entry should not be run');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForSalesDaily()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [Sales] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue with Prepmt. Auto Update Frequency = Daily in Sales Setup
        Initialize();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate(
          "Prepmt. Auto Update Frequency", SalesReceivablesSetup."Prepmt. Auto Update Frequency"::Daily);
        SalesReceivablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Sales", true, 24 * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForSalesWeekly()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [Sales] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue with Prepmt. Auto Update Frequency = Weekly in Sales Setup
        Initialize();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate(
          "Prepmt. Auto Update Frequency", SalesReceivablesSetup."Prepmt. Auto Update Frequency"::Weekly);
        SalesReceivablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Sales", true, 7 * 24 * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForSalesNever()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [Sales] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue when reset Prepmt. Auto Update Frequency to Never in Sales Setup
        Initialize();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate(
          "Prepmt. Auto Update Frequency", SalesReceivablesSetup."Prepmt. Auto Update Frequency"::Daily);
        SalesReceivablesSetup.Modify(true);
        SalesReceivablesSetup.Validate(
          "Prepmt. Auto Update Frequency", SalesReceivablesSetup."Prepmt. Auto Update Frequency"::Never);
        SalesReceivablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Sales", false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForPurchasesDaily()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [UT] [Purchase] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue with Prepmt. Auto Update Frequency = Daily in Purchase Setup
        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate(
          "Prepmt. Auto Update Frequency", PurchasesPayablesSetup."Prepmt. Auto Update Frequency"::Daily);
        PurchasesPayablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Purchase", true, 24 * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForPurchasesWeekly()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [UT] [Purchase] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue with Prepmt. Auto Update Frequency = Weekly in Purchase Setup
        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate(
          "Prepmt. Auto Update Frequency", PurchasesPayablesSetup."Prepmt. Auto Update Frequency"::Weekly);
        PurchasesPayablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Purchase", true, 7 * 24 * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScheduleJobQueueForPurchasesNever()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [UT] [Purchase] [Prepmt. Auto Update]
        // [SCENARIO 273807] Schedule job queue when reset Prepmt. Auto Update Frequency to Never in Purchase Setup
        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate(
          "Prepmt. Auto Update Frequency", PurchasesPayablesSetup."Prepmt. Auto Update Frequency"::Daily);
        PurchasesPayablesSetup.Modify(true);
        PurchasesPayablesSetup.Validate(
          "Prepmt. Auto Update Frequency", PurchasesPayablesSetup."Prepmt. Auto Update Frequency"::Never);
        PurchasesPayablesSetup.Modify(true);

        VerifyJobQueueEntryWithTearDown(CODEUNIT::"Upd. Pending Prepmt. Purchase", false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryRunConfirm()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UT] [Confirm Dialog] [GUIALLOWED]
        // [SCENARIO 273067] Schedule Job Queue running codeunit with CONFIRM dialog which is not wrapped with GUIALLOWED
        Initialize();

        // [GIVEN] Job Queue Entry running codeunit with CONFIRM dialog
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Job Queue Confirm";
        JobQueueEntry."Job Queue Category Code" := 'TEST';
        // [WHEN] Job Queue Entry run
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);  // 1 Background Session created.
        JobQueueEntryID := JobQueueEntry.ID;
        WaitForJobEntryStatus(JobQueueEntryID);
        // [THEN] Job Queue failed, Status = Error
        JobQueueLogEntry.SetRange(ID, JobQueueEntryID);
        Assert.IsTrue(JobQueueLogEntry.FindFirst(), 'Cannot find log entry for job ' + Format(JobQueueEntryID));
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntry.Status, 'Unexpected status in the log');
        Assert.AreEqual('TEST', JobQueueLogEntry."Job Queue Category Code", 'Unexpected category in the log');
        Assert.AreEqual(UserId, JobQueueLogEntry."User ID", 'Unexpected userid in the log');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryRunConfirmWithGuiallowed()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UT] [Confirm Dialog] [GUIALLOWED]
        // [SCENARIO 273067] Schedule Job Queue running codeunit with CONFIRM dialog which is wrapped with GUIALLOWED
        Initialize();

        // [GIVEN] Job Queue Entry running codeunit with CONFIRM dialog wrapped with GUIALLOWED
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Job Queue Confirm Guiallowed";
        JobQueueEntry."Job Queue Category Code" := 'TEST';
        // [WHEN] Job Queue Entry run
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);  // 1 Background Session created.
        JobQueueEntryID := JobQueueEntry.ID;
        WaitForJobEntryStatus(JobQueueEntryID);
        // [THEN] Job Queue successful, Status = Success
        JobQueueLogEntry.SetRange(ID, JobQueueEntryID);
        Assert.IsTrue(JobQueueLogEntry.FindFirst(), 'Cannot find log entry for job ' + Format(JobQueueEntryID));
        Assert.AreEqual(JobQueueLogEntry.Status::Success, JobQueueLogEntry.Status, 'Unexpected status in the log');
        Assert.AreEqual('TEST', JobQueueLogEntry."Job Queue Category Code", 'Unexpected category in the log');
        Assert.AreEqual(UserId, JobQueueLogEntry."User ID", 'Unexpected userid in the log');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoOfMinutesValidationResetsRecurringProperly()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 400333] When user validates "No. of Minutes between Runs" after setting "Next Run Date Formula" the Recurring Job is False
        Initialize();

        // [GIVEN] A Job Queue Entry
        CreateJobQueueEntry(JobQueueEntry, JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"Job Queue Exception Sample", JobQueueEntry.Status::"On Hold");

        // [GIVEN] Next Run Date Formula was set
        Evaluate(JobQueueEntry."Next Run Date Formula", '1D');
        JobQueueEntry.Validate("Next Run Date Formula");

        // [WHEN] Set "No. of Minutes between Runs" to 60
        JobQueueEntry.Validate("No. of Minutes between Runs", LibraryRandom.RandIntInRange(50, 200));

        // [THEN] "Recurring Job" is false
        JobQueueEntry.TestField("Recurring Job", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntriesPageStaleJob()
    var
        JobQueueEntries: TestPage "Job Queue Entries";
        JobQueueEntry: Record "Job Queue Entry";
        FirstJQId: Guid;
        SecondJQId: Guid;
    begin
        // [Scenario] Given stale (in process) jobs, when the page opens, it should update the stale jobs to error state

        // [Given] Stale job queues
        CreateJobQueueEntry(JobQueueEntry, 0, 0, JobQueueEntry.Status::"In Process");
        FirstJQId := JobQueueEntry.ID;

        CreateJobQueueEntry(JobQueueEntry, 0, 0, JobQueueEntry.Status::"In Process");
        SecondJQId := JobQueueEntry.ID;

        // [When] Open JQE list page
        JobQueueEntries.OpenView();

        // [Then] Job queues should be in error state
        JobQueueEntries.GoToKey(FirstJQId);
        Assert.AreEqual(JobQueueEntry.Status::Error, JobQueueEntries.Status, 'The first job queue is not in error state.');
        JobQueueEntries.GoToKey(SecondJQId);
        Assert.AreEqual(JobQueueEntry.Status::Error, JobQueueEntries.Status, 'The second job queue is not in error state.');
        JobQueueEntries.Close();

        JobQueueEntry.Get(FirstJQId);
        Assert.AreEqual(JobQueueEntry.Status::Error, JobQueueEntry.Status, 'The first job queue is not in error state.');
        JobQueueEntry.Get(SecondJQId);
        Assert.AreEqual(JobQueueEntry.Status::Error, JobQueueEntry.Status, 'The second job queue is not in error state.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueLogEntriesPageStaleJob()
    var
        JobQueueLogEntries: TestPage "Job Queue Log Entries";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        FirstJQId: Integer;
        SecondJQId: Integer;
    begin
        // [Scenario] Given stale (in process) jobs, when the page opens, it should update the stale jobs to error state

        // [Given] Stale job queues log entries
        CreateJobQueueLogEntry(JobQueueLogEntry, 0, 0, JobQueueLogEntry.Status::"In Process");
        FirstJQId := JobQueueLogEntry."Entry No.";

        CreateJobQueueLogEntry(JobQueueLogEntry, 0, 0, JobQueueLogEntry.Status::"In Process");
        SecondJQId := JobQueueLogEntry."Entry No.";

        // [When] Open JQLE list page
        JobQueueLogEntries.OpenView();

        // [Then] Job queue log entries should be in error state
        JobQueueLogEntries.GoToKey(FirstJQId);
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntries.Status, 'The first job queue log entry is not in error state.');
        JobQueueLogEntries.GoToKey(SecondJQId);
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntries.Status, 'The second job queue log entry is not in error state.');
        JobQueueLogEntries.Close();

        JobQueueLogEntry.Get(FirstJQId);
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntry.Status, 'The first job queue log entry is not in error state.');
        JobQueueLogEntry.Get(SecondJQId);
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntry.Status, 'The second job queue log entry is not in error state.');
    end;

    [Test]
    procedure JobQueueErrorMessageDeleteByJQE()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ErrorMessage: Record "Error Message";
        ErrorMessageRegister: Record "Error Message Register";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [Scenario] When a JQ runs and fails, once both JQE and JLE are deleted, the error message should be deleted as well.
        // Delete JQE first, then JQLE

        // [Given] A JQE that will fail and run it
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleSendNotificationEvent(false);
        Initialize();
        ErrorMessage.DeleteAll();
        ErrorMessageRegister.DeleteAll();
        CreateJobQueueEntry(JobQueueEntry, JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"Sales Post via Job Queue", JobQueueEntry.Status::Ready);

        // [When] Run the JQE and delete it
        asserterror Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
        CODEUNIT.Run(CODEUNIT::"Job Queue Error Handler", JobQueueEntry);
        Assert.AreEqual(JobQueueEntry.Status::Error, JobQueueEntry.Status, 'Job should be in error state');
        JobQueueEntry.Delete();

        // [Then] The JQE should be deleted, an error message should be created and the error message register should be created
        Assert.IsFalse(ErrorMessage.IsEmpty(), 'Error message should have been created.');
        Assert.IsFalse(ErrorMessageRegister.IsEmpty(), 'Error message register should have been created.');

        // [When] Delete the JQLE
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        JobQueueLogEntry.FindLast();
        Assert.AreEqual(JobQueueLogEntry.Status::Error, JobQueueLogEntry.Status, 'Job log entry should be in error state');
        JobQueueLogEntry.DeleteAll();

        // [Then] The error message and register should be deleted
        Assert.IsTrue(ErrorMessage.IsEmpty(), 'Error message should have been deleted.');
        Assert.IsTrue(ErrorMessageRegister.IsEmpty(), 'Error message register should have been deleted.');

        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    procedure JobQueueErrorMessageDeleteByJQLE()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ErrorMessage: Record "Error Message";
        ErrorMessageRegister: Record "Error Message Register";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [Scenario] When a JQ runs and fails, once both JQE and JLE are deleted, the error message should be deleted as well.
        // Delete JQLE first and then JQE

        // [Given] A JQE that will fail and run it
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleSendNotificationEvent(false);
        Initialize();
        ErrorMessage.DeleteAll();
        ErrorMessageRegister.DeleteAll();
        CreateJobQueueEntry(JobQueueEntry, JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"Sales Post via Job Queue", JobQueueEntry.Status::Ready);

        // [When] Run the JQE and delete the JQLE
        asserterror Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
        CODEUNIT.Run(CODEUNIT::"Job Queue Error Handler", JobQueueEntry);
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        JobQueueLogEntry.DeleteAll();

        // [Then] The JQE should be deleted, an error message should be created and the error message register should be created
        Assert.IsFalse(ErrorMessage.IsEmpty(), 'Error message should have been created.');
        Assert.IsFalse(ErrorMessageRegister.IsEmpty(), 'Error message register should have been created.');

        // [When] Delete the JQE
        JobQueueEntry.Delete();

        // [Then] The error message and register should be deleted
        Assert.IsTrue(ErrorMessage.IsEmpty(), 'Error message should have been deleted.');
        Assert.IsTrue(ErrorMessageRegister.IsEmpty(), 'Error message register should have been deleted.');

        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('StandardStatementReqPageHandler,StatementReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_CustomerReports()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: array[2] of Record "Job Queue Entry";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Job Queue Entry with interaction log disabled
        // for the Standard Statement and Statement report.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create and post Sales Invoice to entry customer balance.
        librarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        librarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Standard Statement report.
        LibraryVariableStorage.Enqueue(Customer."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry[1], Report::"Standard Statement");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry[1], Customer."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Statement report.
        LibraryVariableStorage.Enqueue(Customer."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry[2], Report::Statement);

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry[2], Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('BlanketSalesOrderReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_BlanketSalesOrder()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Blanket Sales Order reports from Job Queue Entries with Interaction Log disabled
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create a Blanket Sales Order.
        librarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order",
            Customer."No.", libraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), Customer."Location Code", WorkDate());
        librarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the "Blanket Sales Order" report.
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Blanket Sales Order");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('StandardSalesOrderConfirmationReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_StandardSalesOrderConfirmation()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Standard Sales Order Confirmation
        //reports from Job Queue Entries with Interaction Log disabled
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create a Sales Order.
        librarySales.CreateSalesOrderForCustomerNo(SalesHeader, Customer."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Standard Sales Order Conf.
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Standard Sales - Order Conf.");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesShipmentReqPageHandler,StandardSalesShipmentReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_SalesShipmentReports()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: array[2] of Record "Job Queue Entry";
        SalesHeader: Record "Sales Header";
        SaleShipmentNo: Code[20];
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Job Queue Entry with interaction log disabled
        // for the Sales Shipment and Standard Sales Shipment report.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create and post a Sales Order.
        librarySales.CreateSalesOrderForCustomerNo(SalesHeader, Customer."No.");
        SaleShipmentNo := librarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Sales Shipment report.
        LibraryVariableStorage.Enqueue(SaleShipmentNo);
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry[1], Report::"Sales - Shipment");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry[1], Customer."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Standard Sales Shipment report.
        LibraryVariableStorage.Enqueue(SaleShipmentNo);
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry[2], Report::"Standard Sales - Shipment");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry[2], Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('StandardSalesDraftInvoiceReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_StandardSalesDraftInvoice()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Standard Sales Draft Invoice reports
        // from Job Queue Entries with Interaction Log disabled
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create a Sales Invoice.
        librarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Standard Sales Draft Invoice report.
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Standard Sales - Draft Invoice");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('StandardSalesQuoteReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_StandardSalesQuote()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Standard Sales Quote report
        // from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create a Sales Quote.
        librarySales.CreateSalesQuoteForCustomerNo(SalesHeader, Customer."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Standard Sales Quote report.
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Standard Sales - Quote");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ReturnOrderConfirmationReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_ReturnOrderConfirmation()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Return Order Confirmation report
        // from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create a Sales Return Order.
        librarySales.CreateSalesReturnOrderForCustomerNo(SalesHeader, Customer."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Return Order Confirmation report.
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Return Order Confirmation");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesReturnReceiptReqPageHandler,StandardSalesReturnReceiptReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_SalesReturnRcptReports()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: array[2] of Record "Job Queue Entry";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Job Queue Entry with interaction log disabled
        // for the Sales Return Receipt and Standard Sales Return Receipt report.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create and post Sales Return Order.
        librarySales.CreateSalesReturnOrderForCustomerNo(SalesHeader, Customer."No.");
        UpdateReturnQtyInSalesReturnOrder(SalesHeader);
        librarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Sales Return Receipt report.
        LibraryVariableStorage.Enqueue(Customer."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry[1], Report::"Sales - Return Receipt");

        // [THEN] Verify that Interaction Log does not created for the customer.
        VerifyLogInteractionDoesNotCreated(JobQueueEntry[1], Customer."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Standard Return Receipt report.
        LibraryVariableStorage.Enqueue(Customer."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry[2], Report::"Standard Sales - Return Rcpt.");

        // [THEN] Verify that Interaction Log does not created for the customer.
        VerifyLogInteractionDoesNotCreated(JobQueueEntry[2], Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('StandardSalesCreditMemoReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_StandardSalesCreditMemo()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        SalesHeader: Record "Sales Header";
        PostedSalesCrMemoNo: Code[20];
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Standard Sales Credit Memo
        //report from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create and post a Sales Credit Memo.
        librarySales.CreateSalesCreditMemoForCustomerNo(SalesHeader, Customer."No.");
        PostedSalesCrMemoNo := librarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Standard Sales Credit Memo report.
        LibraryVariableStorage.Enqueue(PostedSalesCrMemoNo);
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Standard Sales - Credit Memo");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('FinanceChargeMemoReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_FinanceChargeMemo()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        IssuedFinanceChargeMemoHdr: Record "Issued Fin. Charge Memo Header";
        JobQueueEntry: Record "Job Queue Entry";
        FinanceChargeMemoNo: Code[20];
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Finance Charge Memo from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create and issue a Finance Charge Memo.
        CreateFinanceChargeDocument(FinanceChargeMemoNo, Customer."No.");
        IssueFinanceChargeMemo(FinanceChargeMemoNo);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Finance Charge Memo report.
        IssuedFinanceChargeMemoHdr.SetRange("Customer No.", Customer."No.");
        IssuedFinanceChargeMemoHdr.FindFirst();
        LibraryVariableStorage.Enqueue(IssuedFinanceChargeMemoHdr."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Finance Charge Memo");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ReminderReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_Reminder()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderHeader: Record "Reminder Header";
        ReminderTerms: Record "Reminder Terms";
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the reports from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create and post a Sales Order.
        librarySales.CreateSalesOrderForCustomerNo(SalesHeader, Customer."No.");
        librarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create reminder term with levels.
        CreateReminderTermsWithLevels(ReminderTerms, 7, LibraryRandom.RandInt(10));

        // [GIVEN] Create overdue entries for Customer.
        CreateCustomerWithOverdueEntries(Customer, ReminderTerms, LibraryRandom.RandInt(10));

        // [GIVEN] Create and issue reminder for customer.
        CreateAndIssueReminder(ReminderHeader, Customer."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Reminder report.
        IssuedReminderHeader.SetRange("Customer No.", Customer."No.");
        IssuedReminderHeader.FindFirst();
        LibraryVariableStorage.Enqueue(IssuedReminderHeader."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::Reminder);

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceQuoteReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_ServiceQuote()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Service Quote
        // report from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create and post a Service Quote.
        CreateServiceOrderWithCustomer(ServiceHeader, ServiceHeader."Document Type"::Quote, Customer."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Service Quote.
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Service Quote");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceContractReqPageHandler,ServiceConfirmHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_ServiceContract()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Service Contract
        // report from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create a Service Contract.
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Service Contract report.
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Service Contract");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceContractQuoteReqPageHandler,ServiceConfirmHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_ServiceContractQuote()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Service Contract Quote
        // report from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create a Service Contract Quote.
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, Customer."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Service Contract Quote report.
        LibraryVariableStorage.Enqueue(ServiceContractHeader."Contract No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Service Contract Quote");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ContactCoverSheetReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_ContactCoverSheet()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the reports from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Contact Cover Sheet report
        LibraryVariableStorage.Enqueue(Contact."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Contact - Cover Sheet");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SegmentCoverSheetReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_SegmentCoverSheet()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Segment Cover Sheet
        // from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Customer.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Create a Segment for the Contact.
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Modify(true);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Segment Cover Sheet report
        LibraryVariableStorage.Enqueue(SegmentHeader."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Segment - Cover Sheet");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ReturnOrderReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_ReturnOrder()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Return Order from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Vendor.
        LibraryMarketing.CreateContactWithVendor(Contact, Vendor);

        // [GIVEN] Create a Purchase Order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Return Order report
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Return Order");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PurchaseReturnShipmentReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_PurchaseReturnShipment()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Purchase Return Shipment
        // from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Vendor.
        LibraryMarketing.CreateContactWithVendor(Contact, Vendor);

        // [GIVEN] Create a Purchase Order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);

        // [GIVEN] Post the Purchase Return Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Return Order report
        LibraryVariableStorage.Enqueue(Vendor."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Purchase - Return Shipment");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('StandardPurchaseOrderReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_StandardPurchaseOrder()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Standard Purchase Order
        // from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Vendor.
        LibraryMarketing.CreateContactWithVendor(Contact, Vendor);

        // [GIVEN] Create a Purchase Order.
        LibraryPurchase.CreatePurchaseOrderForVendorNo(PurchaseHeader, Vendor."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Standard Purchase order report
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Standard Purchase - Order");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor)..
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PurchaseReceiptReqPageHandler,PurchaseInvoiceReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_PurchReceiptAndInvoice()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Job Queue Entry with interaction log disabled
        // for the Purchase Receipt and Purchase Invoice report.
        Initialize();

        // [GIVEN] Create Contact and Vendor.
        LibraryMarketing.CreateContactWithVendor(Contact, Vendor);

        // [GIVEN] Create a post Purchase Order.
        LibraryPurchase.CreatePurchaseOrderForVendorNo(PurchaseHeader, Vendor."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Purchase Invoice report
        LibraryVariableStorage.Enqueue(Vendor."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Purchase - Invoice");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Vendor."No.");

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Purchase Receipt report
        LibraryVariableStorage.Enqueue(Vendor."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Purchase - Receipt");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PurchaseCreditMemoReqPageHandler')]
    procedure InteractionLogEntryNotCreatedWhenRunJobQueueWithIntLogDisabled_PurchaseCrMemo()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO 547254] Interaction Log Entry should not be created while running the Purchase Credit Memo
        // from Job Queue Entries with Interaction Log disabled.
        Initialize();

        // [GIVEN] Create Contact and Vendor.
        LibraryMarketing.CreateContactWithVendor(Contact, Vendor);

        // [GIVEN] Create and post Purchase Credit Memo.
        LibraryPurchase.CreatePurchaseCreditMemoForVendorNo(PurchaseHeader, Vendor."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Create and execute Job Queue Entry with "Interaction Log" disabled for the Purchase Credit Memo report
        LibraryVariableStorage.Enqueue(Vendor."No.");
        CreateAndRunJobQueueEntryWithReport(JobQueueEntry, Report::"Purchase - Credit Memo");

        // [THEN] Verify that Interaction Log entry does not created for the Contact (Personal and Company contact of Customer or Vendor).
        VerifyLogInteractionDoesNotCreated(JobQueueEntry, Vendor."No.");
    end;

    local procedure Initialize()
    begin
        OnBeforeInitialize();
        LibraryVariableStorage.Clear();
        DeleteAllJobQueueEntries();
        OnAfterInitialize();
    end;

    local procedure CreateJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; ObjectType: Integer; ObjectID: Integer; JQEntryStatus: Option)
    begin
        JobQueueEntry.Init();
        Clear(JobQueueEntry."ID");
        JobQueueEntry.Validate("Object Type to Run", ObjectType);
        JobQueueEntry.Validate("Object ID to Run", ObjectID);
        JobQueueEntry.Status := JQEntryStatus;
        JobQueueEntry.Insert(true);
    end;

    local procedure CreateJobQueueLogEntry(var JobQueueLogEntry: Record "Job Queue Log Entry"; ObjectType: Integer; ObjectID: Integer; JQLogEntryStatus: Option)
    begin
        JobQueueLogEntry.Init();
        Clear(JobQueueLogEntry."Entry No.");
        JobQueueLogEntry.Validate("Object Type to Run", ObjectType);
        JobQueueLogEntry.Validate("Object ID to Run", ObjectID);
        JobQueueLogEntry.Status := JQLogEntryStatus;
        JobQueueLogEntry.Insert(true);
    end;

    local procedure CreateRecurringJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; Duration: Integer; JQEntryStatus: Option)
    begin
        CreateJobQueueEntry(
          JobQueueEntry,
          JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Job Queue Sleeping Sample",
          JobQueueEntry.Status::"On Hold");

        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry."No. of Minutes between Runs" := Duration;
        JobQueueEntry.Modify(true);
        JobQueueEntry.SetStatus(JQEntryStatus);
    end;

    local procedure CreateTimeBasedRecurringJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; StartingTime: Time; EndingTime: Time; Duration: Integer; EarliestStartingDatetTime: DateTime; JQEntryStatus: Option)
    begin
        CreateRecurringJobQueueEntry(JobQueueEntry, Duration, JobQueueEntry.Status::"On Hold");

        JobQueueEntry."Starting Time" := StartingTime;
        JobQueueEntry."Ending Time" := EndingTime;
        JobQueueEntry."Earliest Start Date/Time" := EarliestStartingDatetTime;
        JobQueueEntry.Modify(true);
        JobQueueEntry.SetStatus(JQEntryStatus);
    end;

    local procedure WaitForJobEntryStatus(JobEntryId: Guid)
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        i: Integer;
    begin
        Commit();
        repeat
            i += 1;
            Sleep(1000);

            JobQueueLogEntry.SetRange(ID, JobEntryId);
            if JobQueueLogEntry.FindLast() then;
        until (i > 300) or ((JobQueueLogEntry."Entry No." <> 0) and (JobQueueLogEntry.Status <> JobQueueLogEntry.Status::"In Process"));

        if i > 300 then
            Error(TimeoutErr, 'JobQueueEntry status remained In Progress');
    end;

    local procedure DeleteAllJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        // We won't be able to delete entries with Status = In Process.
        Commit();
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
        if JobQueueEntry.FindSet() then
            repeat
                JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
            until JobQueueEntry.Next() = 0;
        JobQueueEntry.SetRange(Status);

        JobQueueEntry.DeleteAll(true);
        JobQueueLogEntry.DeleteAll(true);
        Commit();
    end;

    local procedure VerifyJobQueueEntryWithTearDown(CodeunitID: Integer; Recurring: Boolean; NoOfMinutes: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CodeunitID);
        JobQueueEntry.FindFirst();

        JobQueueEntry.TestField("Recurring Job", Recurring);
        JobQueueEntry.TestField("No. of Minutes between Runs", NoOfMinutes);

        JobQueueEntry.Delete();
    end;

    local procedure CreateAndRunJobQueueEntryWithReport(var JobQueueEntry: Record "Job Queue Entry"; ReportID: Integer)
    var
    begin
        CreateJobQueueEntry(JobQueueEntry, JobQueueEntry."Object Type to Run"::Report, ReportID, JobQueueEntry.Status::"On Hold");
        Commit();

        JobQueueEntry.Validate("Report Request Page Options", true);
        JobQueueEntry.Validate(Status, JobQueueEntry.Status::Ready);
        JobQueueEntry.Modify();

        Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
    end;

    local procedure VerifyLogInteractionDoesNotCreated(JobQueueEntry: Record "Job Queue Entry"; ContactBusRelationNo: Code[20])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        JobQueueLogEntry: Record "Job Queue Log Entry";
        Vendor: Record Vendor;
    begin
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        Assert.IsFalse(JobQueueLogEntry.IsEmpty(), JobQueueEntryDidNotExecutedErr);

        if Customer.Get(ContactBusRelationNo) then
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer)
        else
            if Vendor.get(ContactBusRelationNo) then
                ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("No.", ContactBusRelationNo);
        if ContactBusinessRelation.FindSet() then
            repeat
                Assert.IsFalse(IsInteractionLogEntryExist(ContactBusinessRelation."Contact No."), InteractionLogCreatedErr);
            until ContactBusinessRelation.Next() = 0;
    end;

    local procedure IsInteractionLogEntryExist(ContactNo: Code[20]): Boolean
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Contact No.", ContactNo);
        exit(not InteractionLogEntry.IsEmpty());
    end;

    local procedure CreateServiceOrderWithCustomer(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader."Due Date" := WorkDate();
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
    end;

    local procedure UpdateReturnQtyInSalesReturnOrder(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity);
                SalesLine.Modify(true);
            until SalesLine.Next() = 0
    end;

    local procedure CreateFinanceChargeDocument(var FinanceChargeMemoNo: Code[20]; CustomerNo: Code[20])
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, CustomerNo);
        FinanceChargeMemoHeader.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        FinanceChargeMemoHeader.Modify(true);
        LibraryERM.CreateFinanceChargeMemoLine(
          FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeMemoLine.Type::"G/L Account");
        FinanceChargeMemoLine.Validate("No.", CreateGLAccount());
        FinanceChargeMemoLine.Validate(Amount, LibraryRandom.RandInt(100));
        FinanceChargeMemoLine.Modify(true);
        FinanceChargeMemoNo := FinanceChargeMemoHeader."No.";
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.SetFilter("Def. VAT Prod. Posting Group", '<>%1', '');
        GenProductPostingGroup.FindFirst();
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure IssueFinanceChargeMemo(No: Code[20])
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        FinanceChargeMemoHeader.Get(No);
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);
    end;

    local procedure CreateAndIssueReminder(var ReminderHeader: Record "Reminder Header"; CustomerNo: Code[20])
    var
        SuggestReminderLines: Report "Suggest Reminder Lines";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Modify(true);

        ReminderHeader.SetRange("No.", ReminderHeader."No.");
        SuggestReminderLines.SetTableView(ReminderHeader);
        SuggestReminderLines.UseRequestPage(false);
        SuggestReminderLines.Run();

        ReminderHeader.SetRecFilter();
        Report.RunModal(Report::"Issue Reminders", false, true, ReminderHeader);
    end;

    local procedure CreateCustomerWithOverdueEntries(var Customer: Record Customer; var ReminderTerms: Record "Reminder Terms"; NumberOfEntries: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReminderLevel: Record "Reminder Level";
        Item: Record Item;
        PostingDate: Date;
        I: Integer;
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTerms.Code);
        ReminderLevel.FindFirst();

        Customer.Validate("Reminder Terms Code", ReminderTerms.Code);
        Customer.Modify(true);

        PostingDate := WorkDate() + (WorkDate() - CalcDate(ReminderLevel."Due Date Calculation", WorkDate()));
        PostingDate := CalcDate('<-5M>', PostingDate);

        for I := 1 to NumberOfEntries do begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
            SalesHeader.Validate("Posting Date", PostingDate);
            SalesHeader.Validate("Due Date", PostingDate);
            SalesHeader.Validate("Document Date", PostingDate);
            SalesHeader.Modify(true);
            LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
              Item, LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;
    end;

    local procedure CreateReminderTermsWithLevels(var ReminderTerms: Record "Reminder Terms"; DueDateCalculationDays: Integer; NumberOfLevels: Integer)
    var
        ReminderLevel: Record "Reminder Level";
        I: Integer;
    begin
        LibraryErm.CreateReminderTerms(ReminderTerms);
        for I := 1 to NumberOfLevels do begin
            Clear(ReminderLevel);
            LibraryErm.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
            Evaluate(ReminderLevel."Due Date Calculation", '<' + Format(DueDateCalculationDays, 0, 9) + 'D>');
            ReminderLevel.Modify(true);
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerVerifyRequest(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, LibraryVariableStorage.DequeueText()) > 0, 'Unexpected confirmation request');
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [RequestPageHandler]
    procedure StandardStatementReqPageHandler(var StandardStatementReqPage: TestRequestPage "Standard Statement")
    begin
        StandardStatementReqPage.LogInteraction.SetValue(false);
        StandardStatementReqPage."Start Date".SetValue(CalcDate('<-5Y>', WorkDate()));
        StandardStatementReqPage."End Date".SetValue(WorkDate());
        StandardStatementReqPage.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardStatementReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StatementReqPageHandler(var StatementReqPage: TestRequestPage Statement)
    begin
        StatementReqPage.LogInteraction.SetValue(false);
        StatementReqPage."Start Date".SetValue(CalcDate('<-5Y>', WorkDate()));
        StatementReqPage."End Date".SetValue(WorkDate());
        StatementReqPage.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StatementReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure BlanketSalesOrderReqPageHandler(var BlankedSalesOrderReportRequestpage: TestRequestPage "Blanket Sales Order")
    begin
        BlankedSalesOrderReportRequestpage.LogInteraction.SetValue(false);
        BlankedSalesOrderReportRequestpage."Sales Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        BlankedSalesOrderReportRequestpage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StandardSalesOrderConfirmationReqPageHandler(var StdSalesOrderConfirmationReqPage: TestRequestPage "Standard Sales - Order Conf.")
    begin
        StdSalesOrderConfirmationReqPage.LogInteraction.SetValue(false);
        StdSalesOrderConfirmationReqPage.Header.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StdSalesOrderConfirmationReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure SalesShipmentReqPageHandler(var SalesShipmentReqPage: TestRequestPage "Sales - Shipment")
    begin
        SalesShipmentReqPage.LogInteraction.SetValue(false);
        SalesShipmentReqPage."Sales Shipment Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        SalesShipmentReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StandardSalesShipmentReqPageHandler(var StandardSalesShipmentReqPage: TestRequestPage "Standard Sales - Shipment")
    begin
        StandardSalesShipmentReqPage.LogInteractionControl.SetValue(false);
        StandardSalesShipmentReqPage.Header.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardSalesShipmentReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StandardSalesDraftInvoiceReqPageHandler(var StandardSalesDraftInvoiceReqPage: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        StandardSalesDraftInvoiceReqPage.LogInteractionField.SetValue(false);
        StandardSalesDraftInvoiceReqPage.Header.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardSalesDraftInvoiceReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StandardSalesQuoteReqPageHandler(var StandardSalesQuoteReqPage: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuoteReqPage.LogInteraction.SetValue(false);
        StandardSalesQuoteReqPage.Header.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardSalesQuoteReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ReturnOrderConfirmationReqPageHandler(var ReturnOrderConfirmationReqPage: TestRequestPage "Return Order Confirmation")
    begin
        ReturnOrderConfirmationReqPage.LogInteraction.SetValue(false);
        ReturnOrderConfirmationReqPage."Sales Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        ReturnOrderConfirmationReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure SalesReturnReceiptReqPageHandler(var SalesReturnReceiptReqPage: TestRequestPage "Sales - Return Receipt")
    begin
        SalesReturnReceiptReqPage.LogInteraction.SetValue(false);
        SalesReturnReceiptReqPage."Return Receipt Header".SetFilter("Sell-to Customer No.", LibraryVariableStorage.DequeueText());
        SalesReturnReceiptReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StandardSalesReturnReceiptReqPageHandler(var StandardSalesReturnReceiptReqPage: TestRequestPage "Standard Sales - Return Rcpt.")
    begin
        StandardSalesReturnReceiptReqPage.LogInteractionControl.SetValue(false);
        StandardSalesReturnReceiptReqPage.Header.SetFilter("Sell-to Customer No.", LibraryVariableStorage.DequeueText());
        StandardSalesReturnReceiptReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StandardSalesCreditMemoReqPageHandler(var StandardSalesCreditMemoReqPage: TestRequestPage "Standard Sales - Credit Memo")
    begin
        StandardSalesCreditMemoReqPage.LogInteraction.SetValue(false);
        StandardSalesCreditMemoReqPage.Header.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardSalesCreditMemoReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure FinanceChargeMemoReqPageHandler(var FinanceChargeMemoReqPage: TestRequestPage "Finance Charge Memo")
    begin
        FinanceChargeMemoReqPage.LogInteraction.SetValue(false);
        FinanceChargeMemoReqPage."Issued Fin. Charge Memo Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        FinanceChargeMemoReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ReminderReqPageHandler(var ReminderReqPage: TestRequestPage Reminder)
    begin
        ReminderReqPage.LogInteraction.SetValue(false);
        ReminderReqPage."Issued Reminder Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        ReminderReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ServiceQuoteReqPageHandler(var ServiceQuoteReqPage: TestRequestPage "Service Quote")
    begin
        ServiceQuoteReqPage.LogInteraction.SetValue(false);
        ServiceQuoteReqPage."Service Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        ServiceQuoteReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ServiceContractReqPageHandler(var ServiceContractReqPage: TestRequestPage "Service Contract")
    begin
        ServiceContractReqPage.LogInteraction.SetValue(false);
        ServiceContractReqPage."Service Contract Header".SetFilter("Contract No.", LibraryVariableStorage.DequeueText());
        ServiceContractReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ServiceContractQuoteReqPageHandler(var ServiceContractQuoteReqPage: TestRequestPage "Service Contract Quote")
    begin
        ServiceContractQuoteReqPage.LogInteraction.SetValue(false);
        ServiceContractQuoteReqPage."Service Contract Header".SetFilter("Contract No.", LibraryVariableStorage.DequeueText());
        ServiceContractQuoteReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ContactCoverSheetReqPageHandler(var ContactCoverSheetReqPage: TestRequestPage "Contact - Cover Sheet")
    begin
        ContactCoverSheetReqPage.LogInteraction.SetValue(false);
        ContactCoverSheetReqPage.Contact.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ContactCoverSheetReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure SegmentCoverSheetReqPageHandler(var SegmentCoverSheetReqPage: TestRequestPage "Segment - Cover Sheet")
    begin
        SegmentCoverSheetReqPage.LogInteraction.SetValue(false);
        SegmentCoverSheetReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ReturnOrderReqPageHandler(var ReturnOrderReqPage: TestRequestPage "Return Order")
    begin
        ReturnOrderReqPage.LogInteraction.SetValue(false);
        ReturnOrderReqPage."Purchase Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        ReturnOrderReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure PurchaseReturnShipmentReqPageHandler(var PurchaseReturnShipmentReqPage: TestRequestPage "Purchase - Return Shipment")
    begin
        PurchaseReturnShipmentReqPage.LogInteraction.SetValue(false);
        PurchaseReturnShipmentReqPage."Return Shipment Header".SetFilter("Buy-from Vendor No.", LibraryVariableStorage.DequeueText());
        PurchaseReturnShipmentReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StandardPurchaseOrderReqPageHandler(var StandardPurchaseOrderReqPage: TestRequestPage "Standard Purchase - Order")
    begin
        StandardPurchaseOrderReqPage.LogInteraction.SetValue(false);
        StandardPurchaseOrderReqPage."Purchase Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardPurchaseOrderReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure PurchaseInvoiceReqPageHandler(var PurchaseInvoiceReqPage: TestRequestPage "Purchase - Invoice")
    begin
        PurchaseInvoiceReqPage.LogInteraction.SetValue(false);
        PurchaseInvoiceReqPage."Purch. Inv. Header".SetFilter("Buy-from Vendor No.", LibraryVariableStorage.DequeueText());
        PurchaseInvoiceReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure PurchaseReceiptReqPageHandler(var PurchaseReceiptReqPage: TestRequestPage "Purchase - Receipt")
    begin
        PurchaseReceiptReqPage.LogInteraction.SetValue(false);
        PurchaseReceiptReqPage."Purch. Rcpt. Header".SetFilter("Buy-from Vendor No.", LibraryVariableStorage.DequeueText());
        PurchaseReceiptReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure PurchaseCreditMemoReqPageHandler(var PurchaseCreditMemoReqPage: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCreditMemoReqPage.LogInteraction.SetValue(false);
        PurchaseCreditMemoReqPage."Purch. Cr. Memo Hdr.".SetFilter("Buy-from Vendor No.", LibraryVariableStorage.DequeueText());
        PurchaseCreditMemoReqPage.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ServiceConfirmHandler(ConfirmMessage: Text[1024]; var Result: Boolean)
    begin
        Result := false;
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInitialize()
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterInitialize()
    begin
    end;
}
