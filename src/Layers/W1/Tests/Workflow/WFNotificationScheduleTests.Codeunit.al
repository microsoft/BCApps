codeunit 134314 "WF Notification Schedule Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Notification] [Schedule]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        WrongFieldErr: Label 'The notification schedule contains a wrong field value.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        WFNotificationScheduleTests: Codeunit "WF Notification Schedule Tests";
        NotifyNowLbl: Label 'NOTIFYNOW', Locked = true;
        NotifyLaterLbl: Label 'NOTIFYLTR', Locked = true;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CreateNewSchedule()
    var
        NotificationSchedule: Record "Notification Schedule";
        NewUserId: Text[50];
        NotificationType: Enum "Notification Entry Type";
    begin
        // [SCENARIO TFS120835] Create new Notification Schedule

        NewUserId := LibraryUtility.GenerateGUID();
        NotificationType := NotificationSchedule."Notification Type"::Approval;

        // [WHEN] A schedule is being created with User ID X and Notification Type Y
        NotificationSchedule.CreateNewRecord(NewUserId, NotificationType);

        // [THEN] The schedule contains User ID X and Notification Type Y
        // [THEN] The default recurrence pattern is Instantly
        Assert.AreEqual(NewUserId, NotificationSchedule."User ID", WrongFieldErr);
        Assert.AreEqual(NotificationType, NotificationSchedule."Notification Type", WrongFieldErr);
        Assert.AreEqual(NotificationSchedule.Recurrence::Instantly, NotificationSchedule.Recurrence, WrongFieldErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInstantScheduleTime()
    var
        NotificationSchedule: Record "Notification Schedule";
        NotificationEntry: Record "Notification Entry";
        JobQueueEntry: Record "Job Queue Entry";
        EarliestDateTimeOfExecution: DateTime;
        LatestDateTimeOfExecution: DateTime;
    begin
        // [SCENARIO] Instant message are scheduled to run one minute after creating the notification.
        // [GIVEN] No Schedule exist.
        Initialize();

        // [WHEN] A Notification Entry is created.
        EarliestDateTimeOfExecution := CurrentDateTime + 59990; // Substract 10ms to accomodate for the DB rounding
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::"New Record", UserId(), NotificationSchedule, 0, '', '');
        LatestDateTimeOfExecution := CurrentDateTime + 60010; // Added 10ms to accomodate for the DB rounding

        // [THEN] A Instant Job Queue Entry is created for a minute later
        JobQueueEntry.FindFirst();
        Assert.AreEqual(1, JobQueueEntry.Count(), 'More than one Job Queue Entry exist');
        Assert.AreEqual(1509, JobQueueEntry."Object ID to Run", 'Invalid Dispatcher');
        Assert.AreEqual(NotifyNowLbl, JobQueueEntry."Job Queue Category Code", 'Category should be instant');
        Assert.IsTrue((JobQueueEntry."Earliest Start Date/Time" - EarliestDateTimeOfExecution) >= 0,
          StrSubstNo('Job sceduled too early Earliest:%1 Actual:%2', EarliestDateTimeOfExecution, JobQueueEntry."Earliest Start Date/Time"));
        Assert.IsTrue((LatestDateTimeOfExecution - JobQueueEntry."Earliest Start Date/Time") >= 0,
          StrSubstNo('Job sceduled too late Latest:%1 Actual:%2', LatestDateTimeOfExecution, JobQueueEntry."Earliest Start Date/Time"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReuseFailingSchedule()
    var
        NotificationSchedule: Record "Notification Schedule";
        NotificationEntry: Record "Notification Entry";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO] Notification Dispatcher can reuse a job that failed.
        // [GIVEN] A failed job.
        Initialize();
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::"New Record", UserId(), NotificationSchedule, 0, '', '');
        JobQueueEntry.FindFirst();
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Error);

        // [WHEN] A Notification Entry is created.
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::"New Record", UserId(), NotificationSchedule, 0, '', '');

        // [THEN] A Instant Job Queue Entry is created for a minute later
        JobQueueEntry.FindFirst();
        Assert.AreEqual(1, JobQueueEntry.Count(), 'More than one Job Queue Entry exist');
        Assert.AreEqual(JobQueueEntry.Status::Ready, JobQueueEntry.Status, 'Job should be ready');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDefaultInstantSchedule()
    var
        NotificationSchedule: Record "Notification Schedule";
        NotificationEntry: Record "Notification Entry";
        JobQueueEntry: Record "Job Queue Entry";
        ApprovalEntry: Record "Approval Entry";
        OverdueApprovalEntry: Record "Overdue Approval Entry";
    begin
        // [SCENARIO] By default all instant notification are reusing the same job.
        // [GIVEN] No Schedule exist.
        Initialize();

        // [WHEN] A Notification Entry is created.
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::Approval, UserId(), ApprovalEntry, 0, '', '');

        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::Approval, UserId(), ApprovalEntry, 0, '', '');
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::"New Record", UserId(), NotificationSchedule, 0, '', '');
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::Overdue, UserId(), OverdueApprovalEntry, 0, '', '');

        // [THEN] A Instant Job Queue Entry is created
        JobQueueEntry.FindFirst();
        Assert.AreEqual(1, JobQueueEntry.Count(), 'More than one Job Queue Entry exist');
        Assert.AreEqual(NotifyNowLbl, JobQueueEntry."Job Queue Category Code", 'Category should be instant');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInstantScheduleWithMultiNotifications()
    var
        NotificationSchedule: Record "Notification Schedule";
        NotificationEntry: Record "Notification Entry";
        JobQueueEntry: Record "Job Queue Entry";
        ApprovalEntry: Record "Approval Entry";
    begin
        // [SCENARIO] By default all instant notification are reusing the same job.
        // [GIVEN] One Instant Schedule exist.
        Initialize();

        NotificationSchedule.CreateNewRecord('', NotificationSchedule."Notification Type"::Approval);

        // [WHEN] A number of Notification Entry are created.
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::Approval, UserId(), ApprovalEntry, 0, '', '');
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::"New Record", UserId(), NotificationSchedule, 0, '', '');

        // [THEN] A Instant Job Queue Entry is created
        JobQueueEntry.FindFirst();
        Assert.AreEqual(1, JobQueueEntry.Count(), 'More than one Job Queue Entry exist');
        Assert.AreEqual(NotifyNowLbl, JobQueueEntry."Job Queue Category Code", 'Category should be instant');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestScheduledReuseSystemEmailFeature()
    var
        NotificationSchedule: Record "Notification Schedule";
        NotificationEntry: Record "Notification Entry";
        JobQueueEntry: Record "Job Queue Entry";
        ApprovalEntry: Record "Approval Entry";
        UserName: Code[50];
    begin
        // [SCENARIO] All notification of the same type are reusing the same job.
        // [GIVEN] Monthly schedule exist.
        Initialize();

        UserName := 'SomeUser';
        AddUserSetup(UserName);

        NotificationSchedule.CreateNewRecord(UserName, NotificationSchedule."Notification Type"::Approval);
        NotificationSchedule.Validate(Recurrence, NotificationSchedule.Recurrence::Monthly);
        NotificationSchedule.Modify(true);

        // [WHEN] A Notification Entry is created.
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::Approval, UserName, ApprovalEntry, 0, '', '');

        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::Approval, UserName, ApprovalEntry, 0, '', '');

        // [THEN] A Instant Job Queue Entry is created
        JobQueueEntry.FindFirst();

        Assert.AreEqual(1, JobQueueEntry.Count(), 'More than one Job Queue Entry exist');
        Assert.AreEqual(1509, JobQueueEntry."Object ID to Run", 'Invalid Dispatcher');
        Assert.AreEqual(NotifyLaterLbl, JobQueueEntry."Job Queue Category Code", 'Category should not be instant');
        NotificationEntry.SetView(JobQueueEntry."Parameter String");
        Assert.AreEqual(UserName, NotificationEntry.GetRangeMax("Recipient User ID"), 'User should be in the filter');
        Assert.AreEqual(NotificationEntry.Type::Approval, NotificationEntry.GetRangeMax(Type), 'Type shold be in the filter');
        NotificationSchedule.Find('=');
        Assert.AreEqual(JobQueueEntry.ID, NotificationSchedule."Last Scheduled Job", 'Schedule should point to last created job');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyExistingScheduleSystemEmailFeature()
    var
        NotificationSchedule: Record "Notification Schedule";
        NotificationEntry: Record "Notification Entry";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntry2: Record "Job Queue Entry";
        ApprovalEntry: Record "Approval Entry";
        EarliestDateTimeOfExecution: DateTime;
        OldEarliestDateTimeOfExecution: DateTime;
    begin
        // [SCENARIO] Modifying the schedule is reflected in the job queue.

        // [GIVEN] A schedule and an event already exist
        Initialize();

        EarliestDateTimeOfExecution := CurrentDateTime + 3600000;
        CreateMonthlyScheduleForApproval(NotificationSchedule);
        NotificationSchedule.Validate(Time, DT2Time(EarliestDateTimeOfExecution));
        NotificationSchedule.Modify(true);
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::Approval, UserId(), ApprovalEntry, 0, '', '');
        JobQueueEntry.FindFirst();
        OldEarliestDateTimeOfExecution := JobQueueEntry."Earliest Start Date/Time";

        // [THEN] There is one Job Queue.
        JobQueueEntry.FindFirst();
        Assert.AreEqual(1, JobQueueEntry.Count(), 'More than one Job Queue Entry exist');

        // [WHEN] The existing schedule date/time is modified
        NotificationSchedule.Find();
        NotificationSchedule.Validate(Time, DT2Time(EarliestDateTimeOfExecution + 1000));
        NotificationSchedule.Modify(true);

        // [THEN] The same job queue is still queued.
        JobQueueEntry2.FindFirst();
        Assert.AreEqual(1, JobQueueEntry.Count(), 'More than one Job Queue Entry exist');
        Assert.AreEqual(JobQueueEntry.ID, JobQueueEntry2.ID, 'The job queues are different.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteExistingScheduleSystemEmailFeature()
    var
        NotificationSchedule: Record "Notification Schedule";
        NotificationEntry: Record "Notification Entry";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntry2: Record "Job Queue Entry";
        ApprovalEntry: Record "Approval Entry";
    begin
        // [GIVEN] A schedule and an event already exist
        Initialize();

        CreateMonthlyScheduleForApproval(NotificationSchedule);
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::Approval, UserId(), ApprovalEntry, 0, '', '');

        // [THEN] There is one Job Queue.
        JobQueueEntry.FindFirst();
        Assert.AreEqual(1, JobQueueEntry.Count(), 'More than one Job Queue Entry exist');

        // [WHEN] The existing schedule is deleted
        NotificationSchedule.Find();
        NotificationSchedule.Delete(true);

        // [THEN] The same job queue is still queued.
        JobQueueEntry2.FindFirst();
        Assert.AreEqual(1, JobQueueEntry.Count(), 'More than one Job Queue Entry exist');
        Assert.AreEqual(JobQueueEntry.ID, JobQueueEntry2.ID, 'The job queues are different.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMonthlyScheduleFirstWorkDate()
    var
        NotificationSchedule: Record "Notification Schedule";
    begin
        // [GIVEN] An existing monthly schedule set on first workday
        Initialize();
        CreateMonthlyScheduleForApproval(NotificationSchedule);
        // [WHEN] The Job Queue entry is created after the first workday of the current month
        // [THEN] The Job Queue entry is scheduled for the first workday of next month at the given schedule time
        Assert.AreEqual(
          CreateDateTime(DMY2Date(1, 6, 2015), 120000T), NotificationSchedule.CalculateExecutionTime(CreateDateTime(DMY2Date(5, 5, 2015), 120000T)),
          'Monthly notification first work day incorrectly calculated');
        // [WHEN] The Job Queue entry is created on the first workday of the month at a time prior to the schedule time
        // [THEN] The Job Queue entry is scheduled for the same day at the given schedule time
        Assert.AreEqual(
          CreateDateTime(DMY2Date(1, 7, 2015), 120000T), NotificationSchedule.CalculateExecutionTime(CreateDateTime(DMY2Date(1, 7, 2015), 110000T)),
          'Monthly notification first work day incorrectly calculated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMonthlyScheduleLastWorkDate()
    var
        NotificationSchedule: Record "Notification Schedule";
    begin
        // [GIVEN] An existing monthly schedule set on last workday
        Initialize();
        CreateMonthlyScheduleForApproval(NotificationSchedule);
        NotificationSchedule.Validate("Monthly Notification Date", NotificationSchedule."Monthly Notification Date"::"Last Workday");
        // [WHEN] The Job Queue entry is created before the last workday of the current month
        // [THEN] The Job Queue entry is scheduled for the last workday of the current month at the given schedule time
        Assert.AreEqual(
          CreateDateTime(DMY2Date(29, 5, 2015), 120000T), NotificationSchedule.CalculateExecutionTime(CreateDateTime(DMY2Date(5, 5, 2015), 120000T)),
          'Monthly notification last work day incorrectly calculated');
        // [WHEN] The Job Queue entry is created on the last workday of the month at a time prior to the schedule time
        // [THEN] The Job Queue entry is scheduled for the same day at the given schedule time
        Assert.AreEqual(
          CreateDateTime(DMY2Date(30, 6, 2015), 120000T), NotificationSchedule.CalculateExecutionTime(CreateDateTime(DMY2Date(30, 6, 2015), 110000T)),
          'Monthly notification last work day incorrectly calculated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMonthlyScheduleCustomWorkDate()
    var
        NotificationSchedule: Record "Notification Schedule";
    begin
        // [GIVEN] An existing monthly schedule set on a custom date
        Initialize();
        CreateMonthlyScheduleForApproval(NotificationSchedule);
        NotificationSchedule.Validate("Monthly Notification Date", NotificationSchedule."Monthly Notification Date"::Custom);
        NotificationSchedule.Validate("Date of Month", 31);
        // [WHEN] The Job Queue entry is created before the custom date of the current month
        // [THEN] The Job Queue entry is scheduled for the given custom date of the current month at the given schedule time
        Assert.AreEqual(
          CreateDateTime(DMY2Date(31, 5, 2015), 120000T), NotificationSchedule.CalculateExecutionTime(CreateDateTime(DMY2Date(5, 5, 2015), 120000T)),
          'Monthly notification custom work day incorrectly calculated');
        // [WHEN] The Job Queue entry is created on the custom date of the month at a time prior to the schedule time
        // [THEN] The Job Queue entry is scheduled for the same day at the given schedule time
        Assert.AreEqual(
          CreateDateTime(DMY2Date(30, 4, 2015), 120000T), NotificationSchedule.CalculateExecutionTime(CreateDateTime(DMY2Date(30, 4, 2015), 110000T)),
          'Monthly notification custom work day incorrectly calculated');
        // [WHEN] The Job Queue entry is created before the custom date and the given custom day is not included in the month (e.g. 31 in June that has only 30 days)
        // [THEN] The Job Queue entry is scheduled for the last day instead
        Assert.AreEqual(
          CreateDateTime(DMY2Date(30, 6, 2015), 120000T), NotificationSchedule.CalculateExecutionTime(CreateDateTime(DMY2Date(5, 6, 2015), 110000T)),
          'Monthly notification custom work day incorrectly calculated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWeeklyScheduleWorkDates()
    var
        NotificationSchedule: Record "Notification Schedule";
    begin
        // [GIVEN] An existing weekly schedule set to workday
        Initialize();
        NotificationSchedule.CreateNewRecord(LibraryUtility.GenerateGUID(), NotificationSchedule."Notification Type"::Approval);
        NotificationSchedule.Validate(Recurrence, NotificationSchedule.Recurrence::Weekly);
        NotificationSchedule.Validate(Time, 120000T);
        // [WHEN] The Job Queue entry is created on a friday at a time later or equal to the schedule time
        // [THEN] The Job Queue entry is scheduled for the first workday of the next week
        Assert.AreEqual(
          CreateDateTime(DMY2Date(11, 5, 2015), 120000T), NotificationSchedule.CalculateExecutionTime(CreateDateTime(DMY2Date(8, 5, 2015), 120000T)),
          'Weekly notification first work day of week incorrectly calculated');
        // [WHEN] The Job Queue entry is created on a workday at a time prior to the schedule time
        // [THEN] The Job Queue entry is scheduled for the same day at the given schedule time
        Assert.AreEqual(
          CreateDateTime(DMY2Date(8, 5, 2015), 120000T), NotificationSchedule.CalculateExecutionTime(CreateDateTime(DMY2Date(8, 5, 2015), 110000T)),
          'Monthly notification last work day incorrectly calculated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDailyScheduleWorkDates()
    var
        NotificationSchedule: Record "Notification Schedule";
    begin
        // [GIVEN] An existing daily schedule set to weekday (workday)
        Initialize();
        NotificationSchedule.CreateNewRecord(LibraryUtility.GenerateGUID(), NotificationSchedule."Notification Type"::Approval);
        NotificationSchedule.Validate(Recurrence, NotificationSchedule.Recurrence::Daily);
        NotificationSchedule.Validate("Daily Frequency", NotificationSchedule."Daily Frequency"::Weekday);
        NotificationSchedule.Validate(Time, 120000T);
        // [WHEN] The Job Queue entry is created on a friday at a time later or equal to the schedule time
        // [THEN] The Job Queue entry is scheduled for the first workday of the next week
        Assert.AreEqual(
          CreateDateTime(DMY2Date(11, 5, 2015), 120000T), NotificationSchedule.CalculateExecutionTime(CreateDateTime(DMY2Date(8, 5, 2015), 120000T)),
          'Monthly notification last work day incorrectly calculated');
        // [WHEN] The Job Queue entry is created on a workday at a time prior to the schedule time
        // [THEN] The Job Queue entry is scheduled for the same day at the given schedule time
        Assert.AreEqual(
          CreateDateTime(DMY2Date(8, 5, 2015), 120000T), NotificationSchedule.CalculateExecutionTime(CreateDateTime(DMY2Date(8, 5, 2015), 110000T)),
          'Monthly notification last work day incorrectly calculated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDailyScheduleWorkDatesInDifferentTimeZone()
    var
        NotificationSchedule: Record "Notification Schedule";
        NotificationEntry: Record "Notification Entry";
        Approver: Record User;
        ApprovalEntry: Record "Approval Entry";
        JobQueueEntry: Record "Job Queue Entry";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryPermissions: Codeunit "Library - Permissions";
        TypeHelper: Codeunit "Type Helper";
        TempDateTime: DateTime;
    begin
        // [SCENARIO] [Bug 523664] The approver is in a different time zone. The job queue entry should be scheduled in the approver's time zone instead of the requester.
        Initialize();

        // [GIVEN] An approver in a different time zone with notification setting "daily" at 7:00 A.M. in the approver's time zone
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryPermissions.CreateUser(Approver, 'Approval', false);
        LibraryLowerPermissions.SetO365BusFull();
        SetTimeZone(Approver, 'China Standard Time');
        AddUserSetup(Approver."User Name");

        // [GIVEN] Calculate the time from the approver's time zone to the client's time zone
        TempDateTime := CreateDateTime(DMY2Date(8, 5, 2015), 070000T);
        TempDateTime := TypeHelper.ConvertDateTimeFromInputTimeZoneToClientTimezone(TempDateTime, 'China Standard Time');

        // [GIVEN] The notification setting for this user is "daily", and the time is set as 7:00 A.M. in the Approver's time zone
        NotificationSchedule.CreateNewRecord(Approver."User Name", "Notification Entry Type"::Approval);
        NotificationSchedule.Validate(Recurrence, NotificationSchedule.Recurrence::Daily);
        NotificationSchedule.Validate("Daily Frequency", NotificationSchedule."Daily Frequency"::Weekday);
        NotificationSchedule.Validate(Time, 070000T);
        NotificationSchedule.Modify(true);

        // [WHEN] The Job Queue entry is created on a workday at a time later or equal to the schedule time
        NotificationEntry.CreateNotificationEntry(NotificationEntry.Type::Approval, Approver."User Name", ApprovalEntry, 0, '', '');

        // [THEN] The Job Queue entry is scheduled and the date/time is calculated according to the timezone of the approver (China Standard Time)
        JobQueueEntry.FindFirst();
        Assert.AreEqual(1, JobQueueEntry.Count(), 'One Scheduled Job Queue Entry exist');
        Assert.AreEqual(TempDateTime.Time, JobQueueEntry."Earliest Start Date/Time".Time, 'Job Queue Entry is scheduled in the wrong time zone');
    end;

    local procedure SetTimeZone(User: Record User; TimeZone: Text[180])
    var
        UserPersonalization: Record "User Personalization";
    begin
        if not UserPersonalization.Get(User."User Security ID") then begin
            UserPersonalization.Validate("User SID", User."User Security ID");
            UserPersonalization.Insert();
        end;

        UserPersonalization.Get(User."User Security ID");
        UserPersonalization.Validate("Time Zone", TimeZone);
        UserPersonalization.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteExistingScheduleAndReadSystemEmailFeature()
    var
        NotificationSchedule: Record "Notification Schedule";
        NotificationEntry: Record "Notification Entry";
        JobQueueEntry: Record "Job Queue Entry";
        ApprovalEntry: Record "Approval Entry";
    begin
        // [GIVEN] A schedule and an event already exist
        Initialize();

        CreateMonthlyScheduleForApproval(NotificationSchedule);
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::Approval, UserId(), ApprovalEntry, 0, '', '');

        // [WHEN] The existing schedule is deleted and then it is readded
        NotificationSchedule.Find();
        NotificationSchedule.Delete(true);

        CreateMonthlyScheduleForApproval(NotificationSchedule);
        NotificationEntry.CreateNotificationEntry(
            NotificationEntry.Type::Approval, UserId(), ApprovalEntry, 0, '', '');

        // [THEN] We end up with only one Job Queue entries which scheduled and not instant.
        JobQueueEntry.SetRange("Job Queue Category Code", NotifyLaterLbl);
        JobQueueEntry.FindFirst();
        Assert.AreEqual(1, JobQueueEntry.Count(), 'One Scheduled Job Queue Entry exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationEntryCreatedTest()
    var
        NotificationEntry: Record "Notification Entry";
    begin
        // Setup
        Initialize();

        // Exercise
        NotificationEntry.Type := NotificationEntry.Type::"New Record";
        NotificationEntry."Recipient User ID" := UserId();
        NotificationEntry."Error Message" := UserId();
        NotificationEntry.Insert();

        // Verify
        NotificationEntry.FindLast();
        Assert.AreEqual(Format(NotificationEntry.ID), NotificationEntry."Error Message",
          'ID not correct. Event Subscriber failed on AutoIncrement field.');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Notification Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure NotificationEntryCreatedSubscriber(var Rec: Record "Notification Entry"; RunTrigger: Boolean)
    begin
        Rec."Error Message" := Format(Rec.ID);
        Rec.Modify(false);
    end;

    local procedure CreateMonthlyScheduleForApproval(var NotificationSchedule: Record "Notification Schedule")
    begin
        CreateScheduleForApproval("Notification Schedule Type"::Monthly, NotificationSchedule);
    end;

    local procedure CreateScheduleForApproval(NotificationType: Enum "Notification Schedule Type"; var NotificationSchedule: Record "Notification Schedule")
    begin
        NotificationSchedule.CreateNewRecord(UserId, "Notification Entry Type"::Approval);
        NotificationSchedule.Validate(Recurrence, NotificationType);
        NotificationSchedule.Modify(true);
    end;

    local procedure Initialize()
    var
        NotificationSchedule: Record "Notification Schedule";
        NotificationEntry: Record "Notification Entry";
        JobQueueEntry: Record "Job Queue Entry";
        LibraryEmail: Codeunit "Library - Email";
    begin
        LibraryEmail.SetUpEmailAccount();
        JobQueueEntry.DeleteAll();
        NotificationSchedule.DeleteAll();
        NotificationEntry.DeleteAll();

        if IsInitialized then
            exit;

        AddUserSetup(UserId);
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        BindSubscription(WFNotificationScheduleTests);
    end;

    local procedure AddUserSetup(NewUserID: code[50])
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(NewUserID) then begin
            UserSetup."User ID" := NewUserID;
            UserSetup.Insert();
        end;
    end;
}
