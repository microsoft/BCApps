codeunit 139020 "Test Job Queue SNAP"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue Entry] [UT]
    end;

    var
        Assert: Codeunit Assert;
        Text005: Label 'Job Queue Entry was not deleted after execution.';
        UnhandledBufferedTransactionErr: Label 'Codeunit.Run should fail when running target codeunit %1. Either COMMIT was removed from the end of COD449.OnRun, or the test object %1 no longer inserts a record with existing key into a table without autoincrementing primary key.', Comment = '%1 is the ID of a test codeunit supplied to the Job Queue Entry as the Object ID to Run.';
        UnhandledBufferedTransactionNoFailureTextErr: Label 'Test expected some error text to be set by the platform: this should indicate that a record cannot be inserted with primary key field values which already exist.';
        StartDateTimeDelayErr: Label 'Earliest Start Date/Time should be delayed by about 1 sec. Current delay: %1 ms.';
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        JobQueueDispatcher: Codeunit "Job Queue Dispatcher";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T001_ValidateJQEOnInsert()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Init
        JobQueueEntry.Init();

        // Execute
        JobQueueEntry.Insert(true);

        // Validate
        Assert.IsFalse(IsNullGuid(JobQueueEntry.ID), '');
        Assert.AreEqual(UserId, JobQueueEntry."User ID", '');
        Assert.AreNotEqual(0DT, JobQueueEntry."Last Ready State", '');
        Assert.AreEqual(GlobalLanguage, JobQueueEntry."User Language ID", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T002_ValidateJQEOnDelete()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Init
        JobQueueEntry.Init();

        // Execute
        JobQueueEntry.Insert(true);
        JobQueueEntry.Delete(true);
        JobQueueEntry.Status := JobQueueEntry.Status::"In Process";
        JobQueueEntry.Insert(true);
        asserterror JobQueueEntry.Delete(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T003_ValidateJQEExpirationDateTime()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Init
        JobQueueEntry.Init();

        // Execute
        JobQueueEntry.Validate("Expiration Date/Time", CurrentDateTime);

        // Validation: -> No error message
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T004_ValidateJQEExpirationDateTimeErr()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Init
        JobQueueEntry.Init();
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(99000101D, 120000T);

        // Execute
        asserterror JobQueueEntry.Validate("Expiration Date/Time", CurrentDateTime);

        // Validation
        Assert.IsTrue(StrPos(GetLastErrorText, 'must be later than') > 1, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T005_ValidateJQEStartingTime()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Init
        JobQueueEntry.Init();
        JobQueueEntry."Recurring Job" := true;

        // Execute
        JobQueueEntry.Validate("Starting Time", 120000T);

        // Validation
        Assert.AreEqual(120000T, DT2Time(JobQueueEntry."Reference Starting Time"), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T006_ValidateJQEReferenceStartingDateTime()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Init
        JobQueueEntry.Init();
        JobQueueEntry."Recurring Job" := true;

        // Execute
        JobQueueEntry.Validate("Reference Starting Time", CreateDateTime(20000101D, 120000T));

        // Validation
        Assert.AreEqual(120000T, JobQueueEntry."Starting Time", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T010_TestGetStartingDateTimeNull()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Init
        InitializeRecurringJobQueueEntry(JobQueueEntry, 30);

        // Execute
        JobQueueEntry.Validate("Starting Time", 0T);

        // Validation
        Assert.AreEqual(000000T, DT2Time(JobQueueEntry.GetStartingDateTime(CurrentDateTime)), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T011_TestGetStartingDateTime()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Init
        InitializeRecurringJobQueueEntry(JobQueueEntry, 30);

        // Execute
        JobQueueEntry.Validate("Starting Time", 120000T);

        // Validation
        Assert.AreEqual(120000T, DT2Time(JobQueueEntry.GetStartingDateTime(CurrentDateTime)), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T012_TestGetEndingDateTimeNull()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Init
        InitializeRecurringJobQueueEntry(JobQueueEntry, 30);

        // Execute
        JobQueueEntry.Validate("Starting Time", 0T);
        JobQueueEntry.Validate("Ending Time", 0T);

        // Validation
        Assert.AreEqual(000000T, DT2Time(JobQueueEntry.GetEndingDateTime(CurrentDateTime)), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T013_TestGetEndingDateTime1()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Init
        InitializeRecurringJobQueueEntry(JobQueueEntry, 30);

        // Execute
        JobQueueEntry.Validate("Starting Time", 0T);
        JobQueueEntry.Validate("Ending Time", 120000T);

        // Validation
        Assert.AreEqual(120000T, DT2Time(JobQueueEntry.GetEndingDateTime(CurrentDateTime)), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T014_TestGetEndingDateTime2()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Init
        InitializeRecurringJobQueueEntry(JobQueueEntry, 30);

        // Execute
        JobQueueEntry.Validate("Starting Time", 110000T);
        JobQueueEntry.Validate("Ending Time", 120000T);

        // Validation
        Assert.AreEqual(120000T, DT2Time(JobQueueEntry.GetEndingDateTime(CurrentDateTime)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T030_NotScheduledJobByQueueEnqueueSetsJobOnHold()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ExpectedEarliestStartDateTime: DateTime;
    begin
        // [FEATURE] [Job Queue - Enqueue]
        // [GIVEN] The recurrung Job Queue Entry, where "Earliest Start Date/Time" is more then 1 sec in future
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime + 1500;
        JobQueueEntry.Insert(true);
        ExpectedEarliestStartDateTime := JobQueueEntry."Earliest Start Date/Time";

        // [WHEN] run "Job Queue - Enqueue" at time "X", where "System Task ID" is not defined
        BindSubscription(LibraryJobQueue);
        Clear(JobQueueEntry."System Task ID"); // As if TASKSCHEDULER failed to schedule
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);

        // [THEN] Job Queue Entry, where Status is "On Hold", "User Session Started" is <blank>
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold");
        JobQueueEntry.TestField("User Session Started", 0DT);
        // [THEN] "Earliest Start Date/Time" is not changed.
        JobQueueEntry.TestField("Earliest Start Date/Time", ExpectedEarliestStartDateTime);

        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T031_ScheduledJobByQueueEnqueueSetsJobAsReady()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CurrDateTime: DateTime;
        ActualDelay: Integer;
    begin
        // [FEATURE] [Job Queue - Enqueue]
        // [GIVEN] The recurrung Job Queue Entry, where "Earliest Start Date/Time" is is less then 1 sec in future
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);
        CurrDateTime := CurrentDateTime;
        JobQueueEntry."Earliest Start Date/Time" := CurrDateTime + 999;
        JobQueueEntry.Insert(true);

        // [WHEN] run "Job Queue - Enqueue", where "System Task ID" is defined
        BindSubscription(LibraryJobQueue);
        JobQueueEntry."System Task ID" := CreateGuid(); // As if TASKSCHEDULER defined it
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);

        // [THEN] Job Queue Entry, where Status is "Ready", "User Session Started" is <blank>
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Ready);
        JobQueueEntry.TestField("User Session Started", 0DT);
        // [THEN] "Earliest Start Date/Time" is shifted to future in 1 sec.
        ActualDelay := JobQueueEntry."Earliest Start Date/Time" - CurrDateTime;
        if not (ActualDelay in [1000 .. 1500]) then
            Assert.Fail(StrSubstNo(StartDateTimeDelayErr, ActualDelay));

        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T040_CleanupAfterExecutionTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);
        JobQueueEntry."User Session ID" := 1;
        JobQueueEntry."User Session Started" := CurrentDateTime;
        JobQueueEntry."User Service Instance ID" := 1;
        JobQueueEntry.Insert(true);

        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Ready);

        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry.Status := JobQueueEntry.Status::Finished;
        JobQueueEntry.FinalizeRun();
        if JobQueueEntry.Get(JobQueueEntry.ID) then
            Error(Text005);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T041_RestartBlanksNoOAttemptsToRun()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        BindSubscription(LibraryJobQueue);
        // [GIVEN] "Maximum No. of Attempts to Run" is 2, "No. of Attempts to Run" is 2, Status is Error.
        JobQueueEntry.Init();
        JobQueueEntry."No. of Attempts to Run" := 2;
        JobQueueEntry."Maximum No. of Attempts to Run" := 2;
        JobQueueEntry.Status := JobQueueEntry.Status::Error;
        JobQueueEntry.Insert(true);
        // [WHEN] run Restart()
        JobQueueEntry.Restart();

        // [THEN] "No. of Attempts to Run" is 0, Status is Ready
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Ready);
        JobQueueEntry.TestField("No. of Attempts to Run", 0);
        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T050_HandleExecutionErrorTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        RecordLink: Record "Record Link";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        BindSubscription(LibraryJobQueue);

        // [GIVEN] "Maximum No. of Attempts to Run" is equal to "No. of Attempts to Run"
        JobQueueEntry.Init();
        JobQueueEntry.Insert(true);
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Ready);
        // [WHEN] run FinalizeRun() while Status is Error
        JobQueueEntry.Status := JobQueueEntry.Status::Error;
        JobQueueEntry.FinalizeRun();
        LibraryJobQueue.RunSendNotification(JobQueueEntry);

        // [THEN] Job Status is Error
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Error);
        // [THEN] Job has sent Notification with RecId
        RecordLink.SetRange("Record ID", JobQueueEntry.RecordId);
        Assert.RecordIsNotEmpty(RecordLink);

        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T051_HandleExecutionErrorMultipleTimes()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LastEarliestStartDateTime: DateTime;
    begin
        BindSubscription(LibraryJobQueue);
        // [GIVEN] "Maximum No. of Attempts to Run" is 2, "No. of Attempts to Run" is 0, "Rerun Delay (sec.)" is 30 sec.
        JobQueueEntry.Init();
        JobQueueEntry."Maximum No. of Attempts to Run" := 2;
        JobQueueEntry."Rerun Delay (sec.)" := 30;
        JobQueueEntry.Insert(true);
        LastEarliestStartDateTime := JobQueueEntry."Earliest Start Date/Time";

        // [WHEN] run HandleExecutionError() 1st time
        JobQueueEntry.Status := JobQueueEntry.Status::Error;
        JobQueueEntry.FinalizeRun();
        // [THEN] Job Status is "On Hold"
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold");
        // [THEN] "No. of Attempts to Run" is 1, "Earliest Start Date/Time" is set
        JobQueueEntry.TestField("No. of Attempts to Run", 1);
        Assert.AreNotEqual(
          Format(LastEarliestStartDateTime, 0, 9),
          Format(JobQueueEntry."Earliest Start Date/Time", 0, 9), 'Earliest Start Date/Time');
        LastEarliestStartDateTime := JobQueueEntry."Earliest Start Date/Time";
        Sleep(3);

        // [WHEN] run HandleExecutionError() 2nd time
        JobQueueEntry.Status := JobQueueEntry.Status::Error;
        JobQueueEntry.FinalizeRun();
        // [THEN] Job Status is "On Hold"
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold");
        // [THEN] "No. of Attempts to Run" is 2, "Earliest Start Date/Time" is set
        JobQueueEntry.TestField("No. of Attempts to Run", 2);
        Assert.AreNotEqual(
          Format(LastEarliestStartDateTime, 0, 9),
          Format(JobQueueEntry."Earliest Start Date/Time", 0, 9), 'Earliest Start Date/Time');
        LastEarliestStartDateTime := JobQueueEntry."Earliest Start Date/Time";
        Sleep(3);

        // [WHEN] run HandleExecutionError() 3rd time
        JobQueueEntry.Status := JobQueueEntry.Status::Error;
        JobQueueEntry.FinalizeRun();
        // [THEN] Job Status is "Error"
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Error);
        // [THEN] "No. of Attempts to Run" is still 2, "Earliest Start Date/Time" is not changed
        JobQueueEntry.TestField("No. of Attempts to Run", 2);
        Assert.AreEqual(
          Format(LastEarliestStartDateTime, 0, 9),
          Format(JobQueueEntry."Earliest Start Date/Time", 0, 9), 'Earliest Start Date/Time');

        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T052_HandleBufferedTransactionFailures()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Success: Boolean;
    begin
        // Tests a very specific scenario where buffered record insertion in the platform does not
        // guarantee that a record insertion error will be thrown immediately. Because of this,
        // the Job Queue must commit transactions before testing for error conditions.

        JobQueueEntry.Init();
        JobQueueEntry."User ID" := UserId;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Job Queue Failed Insert Sample";
        JobQueueEntry."Run in User Session" := false;

        ClearLastError();
        Success := CODEUNIT.Run(CODEUNIT::"Job Queue Start Codeunit", JobQueueEntry);
        Assert.IsFalse(Success, StrSubstNo(UnhandledBufferedTransactionErr, JobQueueEntry."Object ID to Run"));
        Assert.IsTrue(GetLastErrorText <> '', UnhandledBufferedTransactionNoFailureTextErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T060_CreateNotificationTest()
    var
        RecordLink: Record "Record Link";
        JobQueueEntry: Record "Job Queue Entry";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        RecRef: RecordRef;
        RecID: RecordID;
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Job Queue OK Sample";
        JobQueueEntry.Description := 'This job will not run on job queue';
        JobQueueEntry.Insert(true);

        // For the purpose of this test, the Record ID does not need to be related to the target Codeunit.
        RecRef.GetTable(JobQueueEntry);
        RecID := RecRef.RecordId;
        JobQueueEntry."Record ID to Process" := RecID;

        JobQueueEntry."Error Message" := 'Test error message';
        JobQueueEntry.Status := JobQueueEntry.Status::Error;
        JobQueueEntry.Modify();

        RecordLink.LockTable();
        CODEUNIT.Run(CODEUNIT::"Job Queue - Send Notification", JobQueueEntry);
        RecordLink.FindLast();
        RecordLink.TestField("Record ID", RecID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T070_CalcNextRunHappyPathTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        // Test happy path scenario where no special code branches are covered.
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, DMY2Date(1, 1, 2012), 140000T, DMY2Date(1, 1, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T075_CalcNextDailyRunTest1()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 0);

        // Test Daily run where nothing else specified.
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, DMY2Date(2, 1, 2012), 000000T, DMY2Date(1, 1, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T076_CalcNextDailyRunTest2()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 0);

        // Test when an Earliest Start DateTime specified.
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(DMY2Date(1, 1, 2012), 090000T);
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, DMY2Date(2, 1, 2012), 000000T, DMY2Date(1, 1, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T077_CalcNextDailyRunTest3()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 0);

        // Test Daily Run with Starting Time specified.
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(DMY2Date(1, 1, 2012), 090000T);
        JobQueueEntry.Validate("Starting Time", 100000T);
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, DMY2Date(2, 1, 2012), 100000T, DMY2Date(1, 1, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T081_CalcNextWeeklyRunTest1()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        JobQueueEntry.Init();
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Sundays" := true;
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);

        // Test weekly run where nothing else specified.
        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120108D, 000000T, DMY2Date(1, 1, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T082_CalcNextWeeklyRunTest2()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        JobQueueEntry.Init();
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Sundays" := true;
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);

        // Test when an Earliest Start DateTime specified.
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(DMY2Date(1, 1, 2012), 090000T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120108D, 000000T, DMY2Date(1, 1, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T083_CalcNextWeeklyRunTest3()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        JobQueueEntry.Init();
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Sundays" := true;
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);

        // Test weekly run with Starting Time specified.
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(DMY2Date(1, 1, 2012), 090000T);
        JobQueueEntry.Validate("Starting Time", 100000T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120108D, 100000T, DMY2Date(1, 1, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T090_CalcNextRunFromDateFormula()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DateFormula: DateFormula;
    begin
        // [FEATURE] [Date Formula]
        // [SCENARIO] Calculated next run is the end of teh month at "Startting Time" if "Next Run Date Formula" is '1D + CM'
        // [GIVEN] Job queue entry, where "Earliest Start Date/Time" is '31.03.12 13:00' and
        Evaluate(DateFormula, '<1D + CM>');
        JobQueueEntry.Init();
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(DMY2Date(31, 3, 2012), 130000T);
        // [GIVEN] recurring parameters are "Next Run Date Formula" is '1D + CM', "Starting Time" is '11:00'
        JobQueueEntry.Validate("Next Run Date Formula", DateFormula);
        JobQueueEntry."Starting Time" := 110000T;

        // [WHEN] Calculate next run time
        // [THEN] "Earliest Start Date/Time" is '30.04.12 11:00'
        CalcAndVerifyNextRuntimes(
          JobQueueEntry, JobQueueEntry."Earliest Start Date/Time", DMY2Date(30, 4, 2012), 110000T, DMY2Date(31, 3, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T091_OverrideCalcNextRunBySubscription()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueDispatcher: Codeunit "Job Queue Dispatcher";
        NewRunDateTime: DateTime;
        DateFormula: DateFormula;
    begin
        // [FEATURE] [Event]
        // [SCENARIO] Override the calculated value of the next run for recurring job (by subscribing to COD448)
        // [GIVEN] Job queue entry, where "Earliest Start Date/Time" is '31.03.12 13:00' and
        JobQueueEntry.Init();
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(DMY2Date(31, 3, 2012), 130000T);
        // [GIVEN] recurring parameters are "Next Run Date Formula" is '1D + CM'
        Evaluate(DateFormula, '<1D + CM>');
        JobQueueEntry.Validate("Next Run Date Formula", DateFormula);
        // [GIVEN] Subscribed to COD448.OnBeforeCalcNextRecurringRunDateTime
        BindSubscription(this); // to run OnBeforeCalcNextRecurringRunDateTime, that returns '01.01.01 00:00'

        // [WHEN] Run COD448.CalcNextRunTimeForRecurringJob
        NewRunDateTime := JobQueueDispatcher.CalcNextRunTimeForRecurringJob(JobQueueEntry, JobQueueEntry."Earliest Start Date/Time");

        UnBindSubscription(this);

        // [THEN] Calculated value is '01.01.01 00:00'
        Assert.AreEqual(CreateDateTime(20010101D, 0T), NewRunDateTime, 'wrong new run datetime');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T101_CalcNextRunWhenCrossingEndOfDayTest1()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 30);
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 233000T);

        // Test midnight Boundary.
        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, DMY2Date(2, 1, 2012), 000000T, DMY2Date(1, 1, 2012), 233000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T102_CalcNextRunWhenCrossingEndOfDayTest2()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 2880);
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 233000T);

        // Test when crossing multiple days.
        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120103D, 233000T, DMY2Date(1, 1, 2012), 233000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T103_CalcNextRunWhenCrossingEndOfDayTest3()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 233000T);

        // Test when new time lands on valid new day.
        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, DMY2Date(2, 1, 2012), 003000T, DMY2Date(1, 1, 2012), 233000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T104_CalcNextRunWhenCrossingEndOfDayTest4()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 233000T);

        // Test when new time lands on valid new day where Starting Time was specified.
        JobQueueEntry.Validate("Starting Time", 100000T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, DMY2Date(2, 1, 2012), 100000T, DMY2Date(1, 1, 2012), 233000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T105_CalcNextRunWhenCrossingEndOfDayTest5()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 233000T);

        // Test when new time lands on invalid new day and the Starting Time was specified.
        JobQueueEntry."Run on Mondays" := false;
        JobQueueEntry."Run on Tuesdays" := false;
        JobQueueEntry.Validate("Starting Time", 100000T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120104D, 100000T, DMY2Date(1, 1, 2012), 233000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T106_CalcNextRunWhenCrossingEndOfDayTest6()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 233000T);

        // Test when new time lands on invalid new day but no Starting Time was specified.
        JobQueueEntry."Run on Mondays" := false;
        JobQueueEntry."Run on Tuesdays" := false;

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120104D, 000000T, DMY2Date(1, 1, 2012), 233000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T107_CalcNextRunWhenCrossingEndOfDayTest7()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 233000T);

        // Test when new time lands on invalid new day but Starting Time is earlier.
        JobQueueEntry."Run on Mondays" := false;
        JobQueueEntry."Run on Tuesdays" := false;
        JobQueueEntry.Validate("Starting Time", 001500T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120104D, 001500T, DMY2Date(1, 1, 2012), 233000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T111_CalcNextRunWhenCrossingEndTimeTest1()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 30);

        // Test End Time boundary.
        JobQueueEntry."Ending Time" := 133000T;
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, DMY2Date(1, 1, 2012), 133000T, DMY2Date(1, 1, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T112_CalcNextRunWhenCrossingEndTimeTest2()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);

        // Test when no Start Time specified.
        JobQueueEntry."Ending Time" := 133000T;
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, DMY2Date(2, 1, 2012), 000000T, DMY2Date(1, 1, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T113_CalcNextRunWhenCrossingEndTimeTest3()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);

        // Test when Start Time specified.
        JobQueueEntry.Validate("Starting Time", 100000T);
        JobQueueEntry."Ending Time" := 133000T;
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, DMY2Date(2, 1, 2012), 100000T, DMY2Date(1, 1, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T114_CalcNextRunWhenCrossingEndTimeTest4()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);

        // Test when next day is invalid day and Starting Time was specified.
        JobQueueEntry.Validate("Starting Time", 100000T);
        JobQueueEntry."Ending Time" := 133000T;
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);
        JobQueueEntry."Run on Mondays" := false;
        JobQueueEntry."Run on Tuesdays" := false;

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120104D, 100000T, DMY2Date(1, 1, 2012), 130000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T115_CalcNextRunWhenNoDaysSpecifiedTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueDispatcher: Codeunit "Job Queue Dispatcher";
        StartingDateTime: DateTime;
    begin
        JobQueueEntry.Init();

        // Test when job recurs every two days irrespective of day.
        JobQueueEntry."No. of Minutes between Runs" := 2880;

        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 130000T);
        asserterror StartingDateTime := JobQueueDispatcher.CalcNextRunTimeForRecurringJob(JobQueueEntry, StartingDateTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T116_CalcNextRunWhenResultingInNearestRunTimeInFuture()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueDispatcher: Codeunit "Job Queue Dispatcher";
        NewRunDateTime: DateTime;
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 60);

        // Test when next day is invalid day and Starting Time was specified.
        JobQueueEntry.Validate("Starting Time", 130000T);
        JobQueueEntry."Ending Time" := 133000T;

        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 120000T);
        JobQueueEntry."Run on Sundays" := false;
        JobQueueEntry."Run on Mondays" := false;
        JobQueueEntry."Run on Tuesdays" := false;
        JobQueueEntry."Run on Thursdays" := false;

        NewRunDateTime := JobQueueDispatcher.CalcNextRunTimeForRecurringJob(JobQueueEntry, StartingDateTime);
        Assert.AreEqual(CreateDateTime(DMY2Date(4, 1, 2012), 130000T), NewRunDateTime, 'Next Run Time');

        NewRunDateTime := JobQueueDispatcher.CalcInitialRunTime(JobQueueEntry, StartingDateTime);
        Assert.AreEqual(CreateDateTime(DMY2Date(4, 1, 2012), 130000T), NewRunDateTime, 'Initial Run Time');

        NewRunDateTime := JobQueueDispatcher.CalcNextRunTimeForRecurringJob(JobQueueEntry, NewRunDateTime);
        Assert.AreEqual(CreateDateTime(DMY2Date(6, 1, 2012), 130000T), NewRunDateTime, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T117_CalcNextRunVerifyServerTimeZone()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 5);

        // Test when next day is invalid day and Starting Time was specified.
        JobQueueEntry.Validate("Starting Time", 110000T);
        JobQueueEntry."Ending Time" := 120000T;
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(20150104D, 100000T); // Sunday

        StartingDateTime := CreateDateTime(20150105D, 090000T); // Monday
        JobQueueEntry."Run on Sundays" := false;

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20150105D, 110000T, 20150105D, 110000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNextRunWhenCrossingMidnight()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        InitializeRecurringJobQueueEntry(JobQueueEntry, 10);

        // Test when Starting Time > Ending Time, e.g. run from 22:00 - 02:00.
        JobQueueEntry.Validate("Starting Time", 220000T);
        JobQueueEntry."Ending Time" := 020000T;

        // Test that we just continue over midnight  (23:55 -> 00:05 next day)
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 235500T);
        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120102D, 000500T, DMY2Date(1, 1, 2012), 235500T);

        // Test that we only jump forward to today's starting time (20:00 -> 22:00 same day)
        StartingDateTime := CreateDateTime(DMY2Date(1, 1, 2012), 200000T);
        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120101D, 220000T, DMY2Date(1, 1, 2012), 220000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_Category_CreateTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
        RecordCountBeforeTest: Integer;
    begin
        JobQueueEntry.SetRange("Job Queue Category Code", '<>''''');
        JobQueueEntry.DeleteAll();

        RecordCountBeforeTest := JobQueueCategory.Count();

        JobQueueCategory.Init();
        JobQueueCategory.Code := 'COD1';
        JobQueueCategory.Description := 'COD1 Category';
        JobQueueCategory.Insert(true);

        JobQueueCategory.Reset();
        Assert.AreEqual(RecordCountBeforeTest + 1, JobQueueCategory.Count, 'Expected to find more records after insert');
        Assert.IsTrue(JobQueueCategory.Get('COD1'), 'Expected to find inserted item but GET returned false');
        Assert.AreEqual('COD1 Category', JobQueueCategory.Description, 'Found unexpected category');
        JobQueueCategory.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T121_Category_RenameWhenNotUsedTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
    begin
        JobQueueEntry.SetRange("Job Queue Category Code", '<>''''');
        JobQueueEntry.DeleteAll();

        JobQueueCategory.Init();
        JobQueueCategory.Code := 'COD2';
        JobQueueCategory.Description := 'COD2 Category';
        JobQueueCategory.Insert(true);

        Assert.IsTrue(JobQueueCategory.Get('COD2'), 'Expected to find inserted item');
        Assert.IsFalse(JobQueueCategory.Get('2DOC'), 'Did not expect to find non-inserted item');

        JobQueueCategory.Get('COD2');
        JobQueueCategory.Rename('2DOC');

        Assert.IsFalse(JobQueueCategory.Get('COD2'), 'Did not expect to find orginal item');
        Assert.IsTrue(JobQueueCategory.Get('2DOC'), 'Expected to find renamed item');
        JobQueueCategory.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T122_Category_RenameWhenUsedTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
    begin
        JobQueueEntry.SetRange("Job Queue Category Code", '<>''''');
        JobQueueEntry.DeleteAll();

        JobQueueCategory.Init();
        JobQueueCategory.Code := 'COD3';
        JobQueueCategory.Description := 'COD3 Category';
        JobQueueCategory.Insert(true);

        CreateSucceedingJobQueueEntry(JobQueueEntry);
        JobQueueEntry."Job Queue Category Code" := 'COD3';
        JobQueueEntry.Modify();

        JobQueueEntry.Reset();
        JobQueueEntry.SetRange("Job Queue Category Code", 'COD3');
        Assert.AreEqual(1, JobQueueEntry.Count, 'Expected to find job queue entry with job queue category code');
        JobQueueEntry.Reset();
        JobQueueEntry.SetRange("Job Queue Category Code", '3DOC');
        Assert.AreEqual(0, JobQueueEntry.Count, 'Did not expect to find job queue entry with job queue category code yet to be defined');

        JobQueueCategory.Get('COD3');
        JobQueueCategory.Rename('3DOC');

        JobQueueEntry.Reset();
        JobQueueEntry.SetRange("Job Queue Category Code", 'COD3');
        Assert.AreEqual(0, JobQueueEntry.Count, 'Did not expect to find entry with original job queue category code');
        JobQueueEntry.Reset();
        JobQueueEntry.SetRange("Job Queue Category Code", '3DOC');
        Assert.AreEqual(1, JobQueueEntry.Count, 'Expected to find inserted entry with renamed job queue category code');

        JobQueueEntry.Delete();
        JobQueueCategory.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T123_Category_DeleteWhenNotUsedTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
    begin
        JobQueueEntry.SetRange("Job Queue Category Code", '<>''''');
        JobQueueEntry.DeleteAll();

        JobQueueCategory.Init();
        JobQueueCategory.Code := 'COD4';
        JobQueueCategory.Description := 'COD4 Category';
        JobQueueCategory.Insert(true);
        JobQueueCategory.Reset();

        Assert.IsTrue(JobQueueCategory.Get('COD4'), 'Expected to find item');
        JobQueueCategory.Delete(true);
        Assert.IsFalse(JobQueueCategory.Get('COD4'), 'Did not expect to find delete item');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T124_Category_DeleteWhenUsedTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
        JobQueueEntryId: Guid;
    begin
        JobQueueEntry.SetRange("Job Queue Category Code", '<>''''');
        JobQueueEntry.DeleteAll();

        JobQueueCategory.Init();
        JobQueueCategory.Code := 'COD5';
        JobQueueCategory.Description := 'COD5 Category';
        JobQueueCategory.Insert(true);

        CreateSucceedingJobQueueEntry(JobQueueEntry);
        JobQueueEntry."Job Queue Category Code" := 'COD5';
        JobQueueEntry.Modify();
        JobQueueEntryId := JobQueueEntry.ID;

        JobQueueEntry.Reset();
        JobQueueEntry.SetRange("Job Queue Category Code", 'COD5');
        Assert.AreEqual(1, JobQueueEntry.Count, 'Expected to find inserted entry with set job queue category code');

        JobQueueCategory.Delete(true);
        Assert.IsFalse(JobQueueCategory.Get('COD5'), 'Did not expect to find deleted item');

        // There is inconsistency between rename and delete
        // Rename modified Job Queue Entries to update the new Job Queue Category Code
        // Delete does not change the Job Queue Entries

        JobQueueEntry.Get(JobQueueEntryId);
        Assert.AreEqual('COD5', JobQueueEntry."Job Queue Category Code", 'Expected no changes on Job Queue Entry');

        JobQueueEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T130_JobQueueEntry_DefaultsTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        Assert.IsTrue(Format(JobQueueEntry."Earliest Start Date/Time") = '',
          'Expected Earliest Start Date/Time to be empty when creating a new record');
        Assert.IsTrue(Format(JobQueueEntry."Expiration Date/Time") = '',
          'Expiration Date/Time to be empty when creating a new record');
        Assert.AreEqual(0, JobQueueEntry."Maximum No. of Attempts to Run",
          'Expected Maximum No. of Attempts to Run to be 0 when creating a new record');
        Assert.IsTrue(Format(JobQueueEntry."Starting Time") = '',
          'Expected Starting Time to be empty when creating a new record');
        Assert.IsTrue(Format(JobQueueEntry."Ending Time") = '',
          'Expected Ending Time to be empty when creating a new record');
        Assert.IsFalse(JobQueueEntry."Recurring Job",
          'Expected Recurring Job to be false when creating a new record');
        Assert.IsFalse(JobQueueEntry."Run on Mondays",
          'Expected Run on Mondays to be false when creating a new record');
        Assert.IsFalse(JobQueueEntry."Run on Tuesdays",
          'Expected Run on Tuesdays to be false when creating a new record');
        Assert.IsFalse(JobQueueEntry."Run on Wednesdays",
          'Expected Run on Wednesdays to be false when creating a new record');
        Assert.IsFalse(JobQueueEntry."Run on Thursdays",
          'Expected Run on Thursdays to be false when creating a new record');
        Assert.IsFalse(JobQueueEntry."Run on Fridays",
          'Expected Run on Fridays to be false when creating a new record');
        Assert.IsFalse(JobQueueEntry."Run on Saturdays",
          'Expected Run on Saturdays to be false when creating a new record');
        Assert.IsFalse(JobQueueEntry."Run on Sundays",
          'Expected "Run on Sundays to be false when creating a new record');
        JobQueueEntry.Insert(true);
        Assert.IsTrue(Format(JobQueueEntry."Earliest Start Date/Time") = '',
          'Expected Earliest Start Date/Time to be empty when inserting a new blank record');
        Assert.IsTrue(Format(JobQueueEntry."Expiration Date/Time") = '',
          'Expiration Date/Time to be empty when inserting a new blank record');
        Assert.AreEqual(0, JobQueueEntry."Maximum No. of Attempts to Run",
          'Expected Maximum No. of Attempts to Run to be 0 when inserting a new blank record');
        Assert.IsTrue(Format(JobQueueEntry."Starting Time") = '',
          'Expected Starting Time to be empty when inserting a new blank record');
        Assert.IsTrue(Format(JobQueueEntry."Ending Time") = '',
          'Expected Ending Time to be empty when inserting a new blank record');
        Assert.IsFalse(JobQueueEntry."Recurring Job",
          'Expected Recurring Job to be false when inserting a new blank record');
        Assert.IsFalse(JobQueueEntry."Run on Mondays",
          'Expected Run on Mondays to be false when inserting a new blank record');
        Assert.IsFalse(JobQueueEntry."Run on Tuesdays",
          'Expected Run on Tuesdays to be false when inserting a new blank record');
        Assert.IsFalse(JobQueueEntry."Run on Wednesdays",
          'Expected Run on Wednesdays to be false when inserting a new blank record');
        Assert.IsFalse(JobQueueEntry."Run on Thursdays",
          'Expected Run on Thursdays to be false when inserting a new blank record');
        Assert.IsFalse(JobQueueEntry."Run on Fridays",
          'Expected Run on Fridays to be false when inserting a new blank record');
        Assert.IsFalse(JobQueueEntry."Run on Saturdays",
          'Expected Run on Saturdays to be false when inserting a new blank record');
        Assert.IsFalse(JobQueueEntry."Run on Sundays",
          'Expected "Run on Sundays to be false when inserting a new blank record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T131_JobQueueEntry_TogglingRunOnTogglesRecurrentJobTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CreateSucceedingJobQueueEntry(JobQueueEntry);

        Assert.IsFalse(JobQueueEntry."Recurring Job", 'Expected Recurring Job to be false when inserting a new blank record');
        Assert.IsFalse(JobQueueEntry."Run on Mondays", 'Expected Run on Mondays to be false when inserting a new blank record');

        JobQueueEntry.Validate("Run on Mondays", true);
        JobQueueEntry.Modify(true);

        Assert.IsTrue(JobQueueEntry."Run on Mondays", 'Expected Run on Mondays to be true');
        Assert.IsTrue(JobQueueEntry."Recurring Job", 'Expected Recurring Job to toggle when setting Run on Mondays to true');

        JobQueueEntry.Validate("Run on Tuesdays", true);
        JobQueueEntry.Validate("Run on Mondays", false);
        JobQueueEntry.Modify(true);
        Assert.IsFalse(JobQueueEntry."Run on Mondays", 'Expected Run on Mondays to be false');
        Assert.IsTrue(JobQueueEntry."Recurring Job", 'Expected Recurring Job to toggle when setting Run on ''Day'' to true');

        JobQueueEntry.Validate("Run on Tuesdays", false);
        JobQueueEntry.Modify(true);
        Assert.IsFalse(JobQueueEntry."Recurring Job", 'Expected Recurring Job to toggle when setting Run on ''Day'' to false');
    end;

    [Test]
    [HandlerFunctions('CanShowErrorMessageHandler')]
    [Scope('OnPrem')]
    procedure T140_JobQueueEntriesList_CanShowErrorTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntries: TestPage "Job Queue Entries";
    begin
        CreateFailingJobQueueEntry(JobQueueEntry);
        // The message does not matter, it is replaced when JQE page is opened
        // Replaced to "Something went wrong and the job has stopped." and status becomes error
        JobQueueEntry."Error Message" := 'Part 1' + 'Part 2' + 'Part 3' + 'Part 4';
        JobQueueEntry.Modify(true);

        JobQueueEntries.OpenView();
        JobQueueEntries.GotoKey(JobQueueEntry.ID);
        JobQueueEntries.ShowError.Invoke();
    end;

    [Test]
    [HandlerFunctions('CanShowNoErrorMessageHandler')]
    [Scope('OnPrem')]
    procedure T141_JobQueueEntriesList_CanShowNoErrorTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntries: TestPage "Job Queue Entries";
    begin
        CreateSucceedingJobQueueEntry(JobQueueEntry);

        JobQueueEntries.OpenView();
        JobQueueEntries.GotoKey(JobQueueEntry.ID);
        JobQueueEntries.ShowError.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T150_JobQueueUserSession_ProcessingFailsOnFirstErrorTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        BindSubscription(LibraryJobQueue);
        CreateFailingJobQueueEntry(JobQueueEntry);

        asserterror LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        LibraryJobQueue.RunJobQueueErrorHandler(JobQueueEntry);

        Assert.IsTrue(JobQueueEntry.Status = JobQueueEntry.Status::Error, 'Job did not fail after first attempt');

        JobQueueEntry.Delete();
        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T160_MaxNoOfAttemptsToRun_ValidInputTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.Validate("Maximum No. of Attempts to Run", 0);
        JobQueueEntry.Validate("Maximum No. of Attempts to Run", 1);
        JobQueueEntry.Validate("Maximum No. of Attempts to Run", 45678);

        // Below commented out due to NAV7 #298926 WontFix
        // ASSERTERROR JobQueueEntry.VALIDATE("Maximum No. of Attempts to Run",-1);
        // ASSERTERROR JobQueueEntry.VALIDATE("Maximum No. of Attempts to Run",-45678903);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T180_CalcNextDailyRunTestStartingEndEndingTimeInDiffDays()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        // [SCENARIO 382334] The calculation of next run time relies on current value of "Earliest Start Date/Time" when "No. of Minutes between Runs" = 0
        InitializeRecurringJobQueueEntry(JobQueueEntry, 0);

        // Test Daily run where nothing else specified.
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(20120101D, 235950T);
        JobQueueEntry."Starting Time" := 235950T;
        JobQueueEntry."Ending Time" := 235959T;
        StartingDateTime := CreateDateTime(20120102D, 000010T);

        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120102D, 235950T, 20120102D, 235950T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T181_CalcNextDailyRunTestStartingAndEndingTimesAreEqual()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        StartDate: Date;
    begin
        // [SCENARIO 208294] "Job Queue Dispatcher" calculates next starting time for recurrent job queue entry once when "No. of Minutes between Runs" = 0
        BindSubscription(LibraryJobQueue);
        JobQueueEntry.DeleteAll();

        // [GIVEN] Job Queue Entry "J" where "No. of Minutes between Runs" = 0, "Recurrent Job" = TRUE
        // [GIVNE] "J"."Starting Time" = 11:00 and "J"."Ending Time" = 11:00 (equal times)
        // [GIVEN] "J"."Earliest Start Date/Time" = "22/02/2017 11:00"
        InitializeRecurringJobQueueEntry(JobQueueEntry, 0);
        LibraryJobQueue.SetTrackingJobQueueEntry(JobQueueEntry);

        // Test Daily run where nothing else specified.
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime;
        StartDate := DT2Date(CurrentDateTime);

        JobQueueEntry."Starting Time" := DT2Time(JobQueueEntry."Earliest Start Date/Time");
        JobQueueEntry."Ending Time" := JobQueueEntry."Starting Time";
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Workflow Create Payment Line"; // will exit without any action while there is no RecordID to handle.
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert();

        JobQueueEntry.SetRecFilter();
        // [WHEN] "Job Queue Dispatcher" codeunit processes "J"
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [GIVEN] "J"."Earliest Start Date/Time" = "23/02/2017 11:00" (day incremented once)
        LibraryJobQueue.GetCollectedJobQueueEntries(TempJobQueueEntry);
        JobQueueEntry.TestField("Earliest Start Date/Time", CreateDateTime(StartDate + 1, JobQueueEntry."Starting Time"));

        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T190_JobQueueEnqueueKeepsFailedRecurringJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryOther: Record "Job Queue Entry";
    begin
        // [SCENARIO 222564] Recurring job queue entries pointing to the same object are not deleted when run "Job Queue - Enqueue" codeunit failed
        BindSubscription(LibraryJobQueue);

        // [GIVEN] Recurrent "Job Queue Entry" "A" pointing to object "O"
        // [GIVEN] Recurrent "Job Queue Entry" "B" pointing to object "O"
        // [GIVEN] "A".Status = Ready, "B".Status = Failed
        InitializeRecurringJobQueueEntry(JobQueueEntry, LibraryRandom.RandInt(5));

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Type Helper";
        JobQueueEntry."Parameter String" := LibraryUtility.GenerateGUID();
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert();

        JobQueueEntryOther := JobQueueEntry;
        JobQueueEntryOther.ID := CreateGuid();
        JobQueueEntryOther.Status := JobQueueEntryOther.Status::Error;
        JobQueueEntryOther.Insert();

        // [GIVEN] When run "Job Queue - Enqueue"
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [THEN] "B" remained unchanged
        JobQueueEntryOther.Find();
        JobQueueEntryOther.TestField(Status, JobQueueEntryOther.Status::Error);
        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T200_CalcNextRunWhenNumberOfMinutesIsBigUT()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StartingDateTime: DateTime;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 251516] If JobQueueEntry."No. of Minutes between Runs" is big (e.g. 43200 minutes = 30 days), next run time must be calculated without an error
        InitializeRecurringJobQueueEntry(JobQueueEntry, 43200);
        StartingDateTime := CreateDateTime(20120101D, 233000T);

        // Test midnight Boundary.
        CalcAndVerifyNextRuntimes(JobQueueEntry, StartingDateTime, 20120131D, 233000T, 20120101D, 233000T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T201_AddMinIntMinutesToDateTime()
    var
        CurrentDateTime: DateTime;
        NewDateTime: DateTime;
        NoOfMinutes: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 251516] Min Int cannot be used for TypeHelper.AddMinutesToDateTime
        CurrentDateTime := CreateDateTime(50180101D, 233000T);
        NoOfMinutes := -2147483647;
        NewDateTime := JobQueueDispatcher.AddMinutesToDateTime(CurrentDateTime, NoOfMinutes);
        Assert.AreEqual(CreateDateTime(09341209D, 202300T), NewDateTime, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T202_AddZeroMinutesToDateTime()
    var
        CurrentDateTime: DateTime;
        NewDateTime: DateTime;
        NoOfMinutes: Integer;
    begin
        // [SCENARIO 251516] If 0 is added to DateTime, DateTime is kept unchanged
        CurrentDateTime := CreateDateTime(50180101D, 233000T);
        NoOfMinutes := 0;
        NewDateTime := JobQueueDispatcher.AddMinutesToDateTime(CurrentDateTime, NoOfMinutes);
        Assert.AreEqual(CurrentDateTime, NewDateTime, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T203_AddOneMinuteToDateTime()
    var
        CurrentDateTime: DateTime;
        NewDateTime: DateTime;
        NoOfMinutes: Integer;
    begin
        // [SCENARIO 251516] If 1 minute is added to DataTime 010118D 010000T, then resulting date must be 010118D 010100T
        CurrentDateTime := CreateDateTime(50180101D, 233000T);
        NoOfMinutes := 1;
        NewDateTime := JobQueueDispatcher.AddMinutesToDateTime(CurrentDateTime, NoOfMinutes);
        Assert.AreEqual(CreateDateTime(50180101D, 233100T), NewDateTime, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T204_AddMaxIntMinutesToDateTime()
    var
        CurrentDateTime: DateTime;
        NewDateTime: DateTime;
        NoOfMinutes: Integer;
    begin
        // [SCENARIO 251516] Max Int must be possible to add to DateTime
        CurrentDateTime := CreateDateTime(50180101D, 233000T);
        NoOfMinutes := 2147483647;
        NewDateTime := JobQueueDispatcher.AddMinutesToDateTime(CurrentDateTime, NoOfMinutes);
        Assert.AreEqual(CreateDateTime(91010125D, 013700T), NewDateTime, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T205_AddMinutesToZeroDateTime()
    var
        CurrentDateTime: DateTime;
        NewDateTime: DateTime;
        NoOfMinutes: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 251516]  Subtract minutes from date to January 3, 0001
        CurrentDateTime := CreateDateTime(10000101D, 000000T);
        NoOfMinutes := -525420000;
        NewDateTime := JobQueueDispatcher.AddMinutesToDateTime(CurrentDateTime, NoOfMinutes);
        Assert.AreEqual(CreateDateTime(00010103D, 000000T), NewDateTime, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T206_AddMinutesBelowZeroDateTime()
    var
        CurrentDateTime: DateTime;
        NoOfMinutes: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 251516] Subtract minutes from date below January 3, 0001
        CurrentDateTime := CreateDateTime(10000101D, 000000T);
        NoOfMinutes := -525420001;
        asserterror JobQueueDispatcher.AddMinutesToDateTime(CurrentDateTime, NoOfMinutes);
        Assert.ExpectedError('The date is not valid.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T210_RescheduleJobQueueEntryHavingInProgressEntriesSameCategory()
    var
        JobQueueCategory: Record "Job Queue Category";
        JobQueueEntryA: Record "Job Queue Entry";
        JobQueueEntryB: Record "Job Queue Entry";
        JobQueueDispatcher: Codeunit "Job Queue Dispatcher";
    begin
        // [FEATURE] [UT] [Job Queue Category]
        // [SCENARIO 259790] System is able to reschedule job queue with category code having running another job queue(s) with the same category code
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        CreateJobQueueCategory(JobQueueCategory);
        CreateRecurringJobQueueEntryWithStatus(JobQueueEntryA, JobQueueEntryA.Status::"In Process", JobQueueCategory.Code);
        CreateRecurringJobQueueEntryWithStatus(JobQueueEntryB, JobQueueEntryB.Status::"In Process", JobQueueCategory.Code);

        JobQueueDispatcher.MockTaskScheduler();
        JobQueueDispatcher.Run(JobQueueEntryB);

        Assert.IsTrue(JobQueueEntryB.Status in [JobQueueEntryB.Status::Ready, JobQueueEntryB.Status::Waiting], 'Status must be Ready or Waiting');
        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotRunRecurringJobQueueEntryWithErrorStatusOnCompanyOpen()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        // [FEATURE] [UT] [Company]
        // [SCENARIO 310997] Recurring Job Queue Entry with status "Error" does not started on company open
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();

        InitializeRecurringJobQueueEntry(JobQueueEntry, LibraryRandom.RandInt(5));
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Job Queue CAL Error Sample";
        JobQueueEntry.Description := 'This job should not run on company open';
        JobQueueEntry.Insert(true);
        JobQueueEntry.SetError('Test error message');

        CODEUNIT.Run(CODEUNIT::"Job Queue User Handler");

        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        Assert.RecordIsEmpty(JobQueueLogEntry);

        VerifyJobQueueEntryWithStatusExists(JobQueueEntry, JobQueueEntry.Status::Error);
        JobQueueEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CanShowNoErrorMessageHandler')]
    procedure RunJobQueueWithStartTimeGreaterThanEndTime()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        CurTime: Time;
    begin
        // [SCENARIO] Job queue will run even if start and end time is set to run across dates
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();

        // [GIVEN] A job queue that can run but is set outside of running hours 
        CreateSucceedingJobQueueEntry(JobQueueEntry);
        CurTime := CurrentDateTime().Time;
        JobQueueEntry."Starting Time" := CurTime + (1000 * 60 * 60); // 1 hour forward
        JobQueueEntry."Ending Time" := CurTime - (1000 * 60 * 60); // 1 hour backward
        JobQueueEntry.Modify();

        Assert.RecordCount(JobQueueEntry, 1);
        Assert.RecordCount(JobQueueLogEntry, 0);

        // [WHEN] Run the job queue (will also schedule a clean-up job if not exists)
        Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] The job queue does not run because it is outside the time range it should run
        Assert.RecordCount(JobQueueEntry, 2);
        Assert.RecordCount(JobQueueLogEntry, 0);
        JobQueueEntry.FindSet();
        repeat
            if JobQueueEntry."Object ID to Run" = Codeunit::"Job Queue Cleanup Tasks" then
                Assert.IsTrue(JobQueueEntry."Recurring Job", 'Clean-up job should be recurring')
            else
                if JobQueueEntry."Recurring Job" then
                    Assert.IsTrue(JobQueueEntry."Earliest Start Date/Time" > CurrentDateTime(), 'Earliest start time should be in the future');
        until JobQueueEntry.Next() = 0;

        // [GIVEN] The same job queue but set within running hours and across to the next day
        JobQueueEntry.SetFilter("Object ID to Run", '<>%1', Codeunit::"Job Queue Cleanup Tasks");
        JobQueueEntry.FindFirst();
        JobQueueEntry.SetRange("Object ID to Run");
        CurTime := CurrentDateTime().Time;
        JobQueueEntry."Starting Time" := CurTime - (1000 * 60 * 60); // 1 hour backward
        JobQueueEntry."Ending Time" := CurTime + (1000 * 60 * 60 * 22); // 22 hour forward
        JobQueueEntry.Modify();

        // [WHEN] Run the job queue
        Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] The job queue ran and the job is deleted
        Assert.RecordCount(JobQueueEntry, 1);  // only the clean-up task is left
        Assert.RecordCount(JobQueueLogEntry, 1);
    end;

    [Test]
    procedure RunCleanUpTask()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueCategory: Record "Job Queue Category";
        OrgTaskID: Guid;
    begin
        // [SCENARIO] Job queue cleanup will remove stale jobs
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();

        // [GIVEN] A job queue entry is 'active' but has no scheduled task
        CreateJobQueueCategory(JobQueueCategory);
        JobQueueCategory."Recovery Task Id" := CreateGuid(); // simulate that a task was scheduled at some point
        JobQueueCategory.Modify();
        OrgTaskID := JobQueueCategory."Recovery Task Id";

        CreateFailingJobQueueEntry(JobQueueEntry);  // status = 'In Process'. Keep this one as is
        JobQueueEntry."Object ID to Run" := Codeunit::"Job Queue Cleanup Tasks";
        JobQueueEntry.Modify();
        CreateFailingJobQueueEntry(JobQueueEntry);  // status = 'In Process'
        JobQueueEntry."Object ID to Run" := Codeunit::"Job Queue Cleanup Tasks";
        JobQueueEntry."Job Queue Category Code" := JobQueueCategory.Code;
        JobQueueEntry.Status := JobQueueEntry.Status::Waiting;
        JobQueueEntry.Modify();

        Assert.RecordCount(JobQueueEntry, 2);
        Assert.RecordCount(JobQueueLogEntry, 0);

        // [WHEN] Run the job queue cleanup runs more than 10 minutes later
        BindSubscription(this); // to run OnGetCheckDelayInMinutes
        Sleep(1000);  // Just to be sure some time has passed
        Codeunit.Run(Codeunit::"Job Queue Cleanup Tasks", JobQueueEntry);
        UnBindSubscription(this);

        // [THEN] The job queue entry is set to 'error'
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Error);
        Assert.RecordCount(JobQueueEntry, 1);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Waiting);
        Assert.RecordCount(JobQueueEntry, 1);
        Assert.RecordCount(JobQueueLogEntry, 0);

        JobQueueCategory.Find(); // get updated record
        Assert.AreNotEqual(OrgTaskID, JobQueueCategory."Recovery Task Id", 'recovery task was not scheduled');
    end;

    [Test]
    procedure RunCleanUpTaskWhenJobQueueRetriedByPlatform()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        // [SCENARIO] Job queue cleanup will update stale job after job queue is retried by platform

        // [GIVEN] No job queue entries or logs
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();

        // [GIVEN] Job Queue Entry that is in process, simulating a JQ that is being retried
        CreateFailingJobQueueEntry(JobQueueEntry);  // status = 'In Process'
        JobQueueEntry."User Service Instance ID" := 1;
        JobQueueEntry."User Session ID" := 2;
        JobQueueEntry.Modify();

        // [GIVEN] Job Queue Log Entry in process and different User Service Instance ID and User Session ID
        // This JQLE is simulating a stale JQLE 
        JobQueueLogEntry.Init();
        JobQueueLogEntry.ID := JobQueueEntry.ID;
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::"In Process";
        JobQueueLogEntry."User Service Instance ID" := 3;
        JobQueueLogEntry."User Session ID" := 4;
        JobQueueLogEntry.Insert();

        // [THEN] We should have 1 record of JQE and JQLE
        Assert.RecordCount(JobQueueEntry, 1);
        Assert.RecordCount(JobQueueLogEntry, 1);

        // [WHEN] The cleanup task is run, it will update the JQLE
        Codeunit.Run(Codeunit::"Job Queue Cleanup Tasks", JobQueueEntry);

        // [THEN] The job queue log entry is set to 'error'
        JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::Error);
        Assert.RecordCount(JobQueueLogEntry, 1);
    end;

    local procedure InitializeRecurringJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; MinutesBetween: Integer)
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry."No. of Minutes between Runs" := MinutesBetween;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CanShowNoErrorMessageHandler(Message: Text)
    begin
        // We need to catch the Sample Code unit message because theese tests are running on the client session and not on the user session
        if Message <> 'Sample Codeunit reported this message which should be suppressed when running silently on the Queue.' then
            Assert.IsFalse(Message <> 'There is no error message.', 'Expected no error message but found: ''' + Message + '''');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CanShowErrorMessageHandler(Message: Text)
    begin
        Assert.IsTrue(Message <> 'There is no error message.', 'Expected error message but found ''' + Message + '''');
        Assert.IsTrue(Message = 'Part 1' + 'Part 2' + 'Part 3' + 'Part 4', 'Expected a different error message. Found: ''' + Message + '''');
    end;

    [Normal]
    local procedure CreateSucceedingJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        SystemTaskId: Guid;
    begin
        SystemTaskId := TaskScheduler.CreateTask(0, 0);

        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := 132450;
        JobQueueEntry.Status := JobQueueEntry.Status::"In Process";
        JobQueueEntry."User Service Instance ID" := ServiceInstanceId();
        JobQueueEntry."User Session ID" := SessionId();
        JobQueueEntry."System Task ID" := SystemTaskId;
        JobQueueEntry.Insert(true);
    end;

    local procedure CreateFailingJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := 132453;
        JobQueueEntry.Status := JobQueueEntry.Status::"In Process";
        JobQueueEntry.Insert(true);
    end;

    local procedure CreateRecurringJobQueueEntryWithStatus(var JobQueueEntry: Record "Job Queue Entry"; NewStatus: Option; JobQueueCategoryCode: Code[10])
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Test Job Queue SNAP";
        JobQueueEntry.Status := NewStatus;
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Job Queue Category Code" := JobQueueCategoryCode;
        JobQueueEntry.Insert(true);
    end;

    local procedure CreateJobQueueCategory(var JobQueueCategory: Record "Job Queue Category")
    begin
        JobQueueCategory.Init();
        JobQueueCategory.Code := LibraryUtility.GenerateGUID();
        JobQueueCategory.Description := PadStr(JobQueueCategory.Code, MaxStrLen(JobQueueCategory.Description), '0');
        JobQueueCategory.Insert(true);
    end;

    local procedure CalcAndVerifyNextRuntimes(var JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime; NextDate: Date; NextTime: Time; InitialDate: Date; InitialTime: Time)
    var
        JobQueueDispatcher: Codeunit "Job Queue Dispatcher";
        NewRunDateTime: DateTime;
    begin
        NewRunDateTime := JobQueueDispatcher.CalcNextRunTimeForRecurringJob(JobQueueEntry, StartingDateTime);
        Assert.AreEqual(CreateDateTime(NextDate, NextTime), NewRunDateTime, '');
        Assert.IsTrue(NewRunDateTime = CreateDateTime(NextDate, NextTime), '');

        NewRunDateTime := JobQueueDispatcher.CalcInitialRunTime(JobQueueEntry, StartingDateTime);
        Assert.AreEqual(CreateDateTime(InitialDate, InitialTime), NewRunDateTime, '');
    end;

    local procedure VerifyJobQueueEntryWithStatusExists(var TempJobQueueEntry: Record "Job Queue Entry" temporary; Status: Option)
    begin
        TempJobQueueEntry.SetRange(Status, Status);
        Assert.RecordIsNotEmpty(TempJobQueueEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Dispatcher", 'OnBeforeCalcNextRunTimeForRecurringJob', '', false, false)]
    local procedure OnBeforeCalcNextRecurringRunDateTime(JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime; var NewRunDateTime: DateTime; var IsHandled: Boolean)
    begin
        NewRunDateTime := CreateDateTime(20010101D, 0T);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Management", 'OnGetCheckDelayInMinutes', '', false, false)]
    local procedure OnGetCheckDelayInMinutes(var DelayInMinutes: Integer)
    begin
        DelayInMinutes := 0;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

