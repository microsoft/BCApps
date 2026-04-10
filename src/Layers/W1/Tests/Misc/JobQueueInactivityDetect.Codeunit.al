codeunit 139032 "Job Queue - Inactivity Detect"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue] [Inactivity Detection]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPermissions: Codeunit "Library - Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure T104_NotRecurringJobGetsDeletedEvenIfNoRecordChangedBySync()
    var
        JobQueueEntry: Record "Job Queue Entry";
        MockSynchJobRunner: Codeunit "Mock Synch. Job Runner";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Not recurring job that didn't result in modified/inserted records do not get 'On Hold' status
        Initialize();

        // [GIVEN] Active not recurring job 'X' is executed
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry.Modify();

        // [WHEN] Job is done and no changes were done
        BindSubscription(MockSynchJobRunner);  // returns flag of no changes by sync
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] Job should be deleted
        Assert.IsFalse(JobQueueEntry.Find(), 'Job should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T105A_ActiveJobBecomesOnHoldWithInactivityTimeoutNonZeroPeriodIfNoRecordChangedBySync()
    var
        JobQueueEntry: Record "Job Queue Entry";
        MockSynchJobRunner: Codeunit "Mock Synch. Job Runner";
        CurrDT: DateTime;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Active job becomes inactive for a period of time if the run didn't change anything and Inactivity Timeout Period > 0
        Initialize();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        // [GIVEN] Active recurring job 'X' is executed, Inactivity Timeout Period = 10
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);

        // [WHEN] Job is done and no changes were done
        BindSubscription(MockSynchJobRunner);
        CurrDT := CurrentDateTime;
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] Job gets status "On Hold with Inactivity period"
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        VerifyDateTimeDifference(CurrDT, JobQueueEntry."Earliest Start Date/Time", JobQueueEntry."Inactivity Timeout Period" * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T105B_ActiveJobBecomesOnHoldWithInactivityTimeoutZeroPeriodIfNoRecordChangedBySync()
    var
        JobQueueEntry: Record "Job Queue Entry";
        MockSynchJobRunner: Codeunit "Mock Synch. Job Runner";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Active job becomes inactive with "On Hold with Inactivity Timeout" state if the run didn't change anything and Inactivity Timeout Period = 0
        Initialize();

        // [GIVEN] Active recurring job 'X' is executed with Inactivity Timeout Period = 0
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);
        JobQueueEntry.Validate("Inactivity Timeout Period", 0);
        JobQueueEntry.Modify();

        // [WHEN] Job is done and no changes were done
        BindSubscription(MockSynchJobRunner);
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] Job gets status "On Hold with Inactivity Timeout"
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T106_ActiveJobsStaysActiveIfRecordIsChangedBySync()
    var
        JobQueueEntry: Record "Job Queue Entry";
        MockSynchJobRunner: Codeunit "Mock Synch. Job Runner";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Active job stays active if the run resulted in some activity.
        Initialize();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();

        // [GIVEN] Active recurring job 'X' is executed
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);

        // [WHEN] Job is done and changes were done
        MockSynchJobRunner.SetJobWasActive();
        BindSubscription(MockSynchJobRunner);
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] Job stays active, Status = Ready
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Ready);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T111_InactiveJobsBecomesActiveIfRecIsChangedManually()
    var
        Item: Record Item;
        JobQueueEntry: array[3] of Record "Job Queue Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Inactive job becomes active on manual record modification.
        Initialize();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();

        // [GIVEN] Integration Table Mapping 'ITEM', where "Table ID" = 'Item'
        // [GIVEN] Job 'ITEM1', where Status "On Hold with Inactivity period"
        CreateJobQueueEntry(JobQueueEntry[1], DATABASE::Item, JobQueueEntry[1].Status::"On Hold with Inactivity Timeout");
        JobQueueEntry[1]."Last Ready State" := CurrentDateTime; // last run very recently
        JobQueueEntry[1].Modify();
        // [GIVEN] Integration Table Mapping 'CUSTOMER', where "Table ID" = 'Customer'
        // [GIVEN] Job 'CUSTOMER', where Status "On Hold with Inactivity period"
        CreateJobQueueEntry(JobQueueEntry[2], DATABASE::Customer, JobQueueEntry[2].Status::"On Hold with Inactivity Timeout");
        // last run at a time in the past which makes it ready for another run, had the job queue been active.
        JobQueueEntry[2]."Last Ready State" := CurrentDateTime - 60000 * JobQueueEntry[3]."No. of Minutes between Runs";
        JobQueueEntry[2].Modify();
        // [GIVEN] Integration Table Mapping 'ITEM', where "Table ID" = 'Item'
        // [GIVEN] Job 'ITEM2', where Status "On Hold with Inactivity period"
        CreateJobQueueEntry(JobQueueEntry[3], DATABASE::Item, JobQueueEntry[3].Status::"On Hold with Inactivity Timeout");
        // last run at a time in the past which makes it ready for another run, had the job queue been active.
        JobQueueEntry[3]."Last Ready State" := CurrentDateTime - 60000 * JobQueueEntry[3]."No. of Minutes between Runs";
        JobQueueEntry[3].Modify();

        // [WHEN] Item 'X' has been inserted
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert(); // calls COD1.OnDatabaseInsert -> COD5150.InsertUpdateIntegrationRecord

        // [THEN] Job 'ITEM1' does not get status "Ready", as it has only recently executed.
        JobQueueEntry[1].Find();
        JobQueueEntry[1].TestField(Status, JobQueueEntry[1].Status::"On Hold with Inactivity Timeout");
        // [THEN] Job 'CUSTOMER' is not changed, the state of the job is "On Hold with Inactivity period"
        JobQueueEntry[2].Find();
        JobQueueEntry[2].TestField(Status, JobQueueEntry[2].Status::"On Hold with Inactivity Timeout");
        // [THEN] Job 'ITEM2' gets status "Ready"
        if TaskScheduler.CanCreateTask() then begin
            JobQueueEntry[3].Find();
            JobQueueEntry[3].TestField(Status, JobQueueEntry[3].Status::Ready);
            // [THEN] new "Earliest Start Date/Time" is about 1 second from now
            VerifyDateTimeDifference(CurrentDateTime, JobQueueEntry[3]."Earliest Start Date/Time", 1);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T112_InactiveJobsStaysInactiveDuringUpgrade()
    var
        Item: Record Item;
        JobQueueEntry: Record "Job Queue Entry";
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
    begin
        // [FEATURE] [UT] [Upgrade]
        // [SCENARIO] Inactive job stays inactive on manual record modification during upgrade.
        Initialize();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();

        // [GIVEN] Integration Table Mapping 'ITEM', where "Table ID" = 'Item'
        // [GIVEN] Job 'ITEM', where Status "On Hold with Inactivity period"
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        JobQueueEntry."Last Ready State" := CurrentDateTime;
        JobQueueEntry.Modify();

        // [GIVEN] Upgrade is in progress
        DataUpgradeMgt.SetUpgradeInProgress();

        // [WHEN] Item 'X' has been inserted
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert(); // calls COD1.OnDatabaseInsert -> COD5150.InsertUpdateIntegrationRecord

        // [THEN] Job 'ITEM', where status "On Hold with Inactivity period"
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T114_SetStatusOnHoldwithInactivityPeriodInactivityPeriodPositive()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CurrDT: DateTime;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] SetStatus "On Hold with Inactivity period" with Inactivity Timeout Period > 0
        Initialize();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();

        // [GIVEN] Active recurring job 'X' is executed, "Inactivity Timeout Period" = 10
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);

        // [WHEN] SetStatus("On Hold with Inactivity Timeout")
        JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        CurrDT := CurrentDateTime;

        // [THEN] Job gets status "On Hold with Inactivity period"
        // [THEN] "Earliest Start Date/Time" is set according to "Inactivity Timeout Period"
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        VerifyDateTimeDifference(CurrDT, JobQueueEntry."Earliest Start Date/Time", JobQueueEntry."Inactivity Timeout Period" * 60);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T115_SetStatusOnHoldwithInactivityPeriodInactivityPeriodZero()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] SetStatus "On Hold with Inactivity period" with Inactivity Timeout Period = 0
        Initialize();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();

        // [GIVEN] Active recurring job 'X' is executed, Inactivity Timeout Period = 0s
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);
        JobQueueEntry."Inactivity Timeout Period" := 0;
        JobQueueEntry.Modify();

        // [WHEN] SetStatus("On Hold with Inactivity Timeout")
        JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold with Inactivity Timeout");

        // [THEN] Job gets status "On Hold"
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RescheduleOnLoginWithStatusReadyWithNoScheduledTask()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduledTask: Guid;
    begin
        // [SCENARIO] Reschedule Job Queue on login with for Jobs with status Ready and no scheduled task
        Initialize();
        LibraryCRMIntegration.UnbindLibraryJobQueue();

        // [GIVEN] Active recurring job 'X' is executed
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready);
        ScheduledTask := JobQueueEntry."System Task ID";

        // [WHEN] Open company (run codeunit "Job Queue User Handler")
        CODEUNIT.Run(CODEUNIT::"Job Queue User Handler");

        // [THEN] Job is still status Ready and Scheduled Task ID has changed
        JobQueueEntry.FindFirst();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"Ready");
        Assert.AreNotEqual(ScheduledTask, JobQueueEntry."System Task ID", 'Scheduled Task ID was not updated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RescheduleOnLoginWithStatusInProcessWithNoScheduledTask()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduledTask: Guid;
    begin
        // [SCENARIO] Reschedule Job Queue on login with for Jobs with status In Process and no scheduled task
        Initialize();
        LibraryCRMIntegration.UnbindLibraryJobQueue();

        // [GIVEN] Active recurring job 'X' is executed
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::"In Process");
        ScheduledTask := JobQueueEntry."System Task ID";

        // [WHEN] Open company (run codeunit "Job Queue User Handler")
        CODEUNIT.Run(CODEUNIT::"Job Queue User Handler");

        // [THEN] Job status is Ready and Scheduled Task ID has changed
        JobQueueEntry.FindFirst();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"Ready");
        Assert.AreNotEqual(ScheduledTask, JobQueueEntry."System Task ID", 'Scheduled Task ID was not updated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RescheduleOnLoginWithStatusOnHoldWithInactivityTimeoutWithNoScheduledTask()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduledTask: Guid;
    begin
        // [SCENARIO] Reschedule Job Queue on login with for Jobs with status On Hold with Inactivity Timeout and no scheduled task
        Initialize();
        LibraryCRMIntegration.UnbindLibraryJobQueue();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        // [GIVEN] Active recurring job 'X' is executed
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        ScheduledTask := JobQueueEntry."System Task ID";

        // [WHEN] Open company (run codeunit "Job Queue User Handler")
        CODEUNIT.Run(CODEUNIT::"Job Queue User Handler");

        // [THEN] Job status is Ready and Scheduled Task ID has changed
        JobQueueEntry.FindFirst();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"Ready");
        Assert.AreNotEqual(ScheduledTask, JobQueueEntry."System Task ID", 'Scheduled Task ID was not updated.');
        UnbindSubscription(LibraryJobQueue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotRescheduledOnLoginWithStatusOnHoldWithNoScheduledTask()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduledTask: Guid;
    begin
        // [SCENARIO] Reschedule Job Queue on login with for Jobs with status On Hold and no scheduled task
        Initialize();

        // [GIVEN] Active recurring job 'X' is executed
        CreateJobQueueEntry(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::"On Hold");
        ScheduledTask := JobQueueEntry."System Task ID";

        // [WHEN] Open company (run codeunit "Job Queue User Handler")
        CODEUNIT.Run(CODEUNIT::"Job Queue User Handler");

        // [THEN] Job is still status On Hold and Scheduled Task ID has not changed
        JobQueueEntry.FindFirst();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold");
        Assert.AreEqual(ScheduledTask, JobQueueEntry."System Task ID", 'Scheduled Task ID was not updated.');
    end;

    local procedure Initialize()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        User: Record User;
    begin
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        User.SetRange("User Name", UserId());
        if User.IsEmpty() then
            LibraryPermissions.CreateUser(User, CopyStr(UserId(), 1, 50), true);
    end;

    local procedure CreateJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; TableNo: Integer; JobStatus: Option)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := LibraryUtility.GenerateGUID();
        IntegrationTableMapping."Table ID" := TableNo;
        IntegrationTableMapping.Insert();

        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry.Description := Format(TableNo);
        JobQueueEntry.Status := JobStatus;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Mock Synch. Job Runner";
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."No. of Minutes between Runs" := 5;
        JobQueueEntry."Record ID to Process" := IntegrationTableMapping.RecordId;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry."Inactivity Timeout Period" := 10;
        JobQueueEntry."System Task ID" := CreateGuid();
        JobQueueEntry.Insert(true);
    end;

    local procedure VerifyDateTimeDifference(DateTime1: DateTime; DateTime2: DateTime; ExpectedDiffInSeconds: Integer)
    var
        DiffInMilliseconds: Integer;
    begin
        DiffInMilliseconds := DateTime2 - DateTime1;
        Assert.AreEqual(ExpectedDiffInSeconds, Round(DiffInMilliseconds / 1000, 1), 'Expected shift in time.');
    end;

}
