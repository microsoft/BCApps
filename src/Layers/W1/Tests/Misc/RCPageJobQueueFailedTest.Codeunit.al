codeunit 134663 "RC Page Job Queue Failed Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Role Center] [Job Queue Failure Notification]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        JobQueueMgt: Codeunit "Job Queue Management";
        FailedJobQueueEntryNameLbl: Label 'Failed Job Queue Entry For Current User';
        FailedJobQueueEntryNameForAnotherUserLbl: Label 'Failed Job Queue Entry For Another User';
        InProcessJobQueueEntryNameLbl: Label 'In Process Job Queue Entry For Current User';
        InProcessJobQueueEntryNameForAnotherUserLbl: Label 'In Process Job Queue Entry For Another User';
        WaitingJobQueueEntryNameLbl: Label 'Waiting Job Queue Entry For Current User';
        WaitingJobQueueEntryNameForAnotherUserLbl: Label 'Waiting Job Queue Entry For Another User';
        ReadyJobQueueEntryNameLbl: Label 'Ready Job Queue Entry For Current User';
        ReadyJobQueueEntryNameForAnotherUserLbl: Label 'Ready Job Queue Entry For Another User';
        TaskFailedCountIncorrectLbl: Label 'Task failed count is incorrect.';
        TaskInProcessCountIncorrectLbl: Label 'Task in process count is incorrect.';
        TaskInQueueCountIncorrectLbl: Label 'Task in queue count is incorrect.';

    [Test]
    [HandlerFunctions('TestPageCueSetUpHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure TestCueSetUp()
    var
        CuesAndKpis: Codeunit "Cues And KPIs";
    begin
        // [SCENARIO] [Job Queue Failure Notification]:
        // When he open the cue set up from Job Queue Tasks Activities page, the cue set up should be opened, and only 3 lines should be shown with the correct settings.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        LibraryVariableStorage.Clear();

        // [WHEN] Open Test Page and click on the action "Set up cues"
        CuesAndKpis.OpenCustomizePageForCurrentUser(Database::"Job Queue Role Center Cue");
    end;

    //============================================================================================================
    // Tests for Job Queue Notification Setup Scenario 1:
    // JobQueueNotificationSetup.InProductNotification := true;
    // JobQueueNotificationSetup.NotifyUserInitiatingTask := true;
    // JobQueueNotificationSetup.NotifyJobQueueAdmin := true;
    // JobQueueNotificationSetup.NotifyAfterThreshold := true;
    // JobQueueNotificationSetup.NotifyWhenJobFailed := true;
    //============================================================================================================
    [Test]
    [HandlerFunctions('SingleJobFailedInJobQueueNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_NotAdminSingleJobFailedTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification] [Setup Scenario 1]: For non-admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario1();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should show the detail of the failed job.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedInJobQueueNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_NotAdminSingleJobFailedTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification] [Setup Scenario 1]: For one non-admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // But in the Job Queue, for another user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of current user's failed job. The cues should show the count of the failed, in process with 1,1 respectively.
        // The in queue count should be 4 because it should contain all the jobs in the queue.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario1();
        CreateUser(User2, CreateGuid());
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries for current user
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should show the detail of the failed job.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,4 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;


    [Test]
    [HandlerFunctions('SingleJobFailedAndDisableNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_NotAdminSingleJobFailedAndDisableNotificationTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For non-admin user, 1 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        // When user clicks on the action to disable the notification, the notification should be disabled.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario1();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);
        // [WHEN] In the handler function, user clicks on the action to disable the notification
        // [THEN] The notification should be disabled.

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 0, 0, false);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedAndRescheduleFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_NotAdminSingleJobFailedAndRescheduleFromNotificationTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For non-admin user, 1 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 0,0,1 respectively.
        // When user clicks on the action to reschedule the failed job, the job should be reset to ready.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario1();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        JobQueueEntry := CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());
        LibraryVariableStorage.Enqueue(JobQueueEntry.ID);

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to reschedule the failed job
        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 0,0,0 respectively.
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 0, 0, 1, true);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedAndRescheduleFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_NotAdminSingleJobFailedAndRescheduleFromNotificationTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For non-admin user, 1 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 0,0,1 respectively.
        // But in the Job Queue, for another user, he has 2 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready. One is created before the current user's failed job and another is created after the current user's failed job.
        // When user clicks on the action to reschedule the failed job, the job should be reset to ready.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario1();
        CreateUser(User2, CreateGuid());
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        // [GIVEN] Create Job Queue Entries for current user
        JobQueueEntry := CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);

        // [GIVEN] Create Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());
        LibraryVariableStorage.Enqueue(JobQueueEntry.ID);

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to reschedule the failed job
        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 0,0,1 respectively.
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 0, 0, 1, true);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedAndShowMoreDetailsFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_SingleJobFailedAndShowMoreDetailNotificationTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
        TestPageJobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For non-admin user, 1 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        // When user clicks on the action to show more details, the related Job Queue Entry Card should render.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario1();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        TestPageJobQueueEntryCard.Trap();
        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to show more details
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntryCard.Description.Value(), 'Job Queue Entry Name is not correct');

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 0, 0, false);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedAndShowMoreDetailsFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_SingleJobFailedAndShowMoreDetailNotificationTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
        TestPageJobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For non-admin user, 1 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        // But in the Job Queue, for another user, he has 2 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready. One is created before the current user's failed job and another is created after the current user's failed job.
        // When user clicks on the action to show more details, the related Job Queue Entry Card should render.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario1();
        CreateUser(User2, CreateGuid());
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        // [GIVEN] Create Job Queue Entries for current user
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [GIVEN] Create Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        TestPageJobQueueEntryCard.Trap();
        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to show more details
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntryCard.Description.Value(), 'Job Queue Entry Name is not correct');

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 0, 0, false);
    end;

    [Test]
    [HandlerFunctions('MultiJobsFailedAndShowMoreDetailsFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_MultiJobsFailedAndShowMoreDetailNotificationTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
        TestPageJobQueueEntry: TestPage "Job Queue Entries";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For non-admin user, 2 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the general error message. The cues should show the count of the failed, in process and in queue jobs with 2,0,0 respectively.
        // When user clicks on the action to show more details, the Job Queue Entries page should render and show all the failed jobs.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario1();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create 2 failed Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);
        LibraryVariableStorage.Enqueue(2);

        TestPageJobQueueEntry.Trap();
        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to show more details
        // [THEN] The Job Queue Entries page should render and show all the failed jobs.
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntry.Description.Value(), 'Job Queue Entry Name is not correct');
        TestPageJobQueueEntry.Next();
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntry.Description.Value(), 'Job Queue Entry Name is not correct');

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 2,1,2 respectively.
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 2, 1, 2, false);
    end;

    [Test]
    [HandlerFunctions('MultiJobsFailedAndShowMoreDetailsFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_MultiJobsFailedAndShowMoreDetailNotificationTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
        TestPageJobQueueEntry: TestPage "Job Queue Entries";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For non-admin user, 2 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the general error message. The cues should show the count of the failed, in process and in queue jobs with 2,0,0 respectively.
        // But in the Job Queue, for another user, he has 2 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready. One is created before the current user's failed job and another is created after the current user's failed job.
        // When user clicks on the action to show more details, the Job Queue Entries page should render and show all the failed jobs.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario1();
        CreateUser(User2, CreateGuid());
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create 1 failed Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        // [GIVEN] Create 2 failed Job Queue Entries for current user
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);
        LibraryVariableStorage.Enqueue(2);
        // [GIVEN] Create 1 failed Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        TestPageJobQueueEntry.Trap();
        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to show more details
        // [THEN] The Job Queue Entries page should render and show all the failed jobs for current user.
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntry.Description.Value(), 'Job Queue Entry Name is not correct');
        TestPageJobQueueEntry.Next();
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntry.Description.Value(), 'Job Queue Entry Name is not correct');
        Assert.IsFalse(TestPageJobQueueEntry.Next(), 'There should be only 2 failed jobs');

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 2,1,2 respectively.
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 2, 1, 2, false);
    end;

    [Test]
    [HandlerFunctions('MultiJobsFailedAndDisableNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_MultiJobsFailedAndDisableNotificationTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For non-admin user, 2 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the general error message. The cues should show the count of the failed, in process and in queue jobs with 2,0,0 respectively.
        // When user clicks on the action to disable the notification, the notification should be disabled.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario1();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        LibraryVariableStorage.Enqueue(2);

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 2, 0, 0, false);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedInJobQueueNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_AdminJobFailedTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For an admin user, he has 0 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // But in the Job Queue, for another user 2, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of latest failed job. The cues should show the count of the failed, in process with 1,1 respectively.
        // The in queue count should be 2 because it should contain all the jobs in the queue.

        // [GIVEN] Init User, Job Queue Entry
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        PrepareJobQueueNotificationSetupScenario1();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        CreateUser(User2, CreateGuid());

        // // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);


        Assert.IsTrue(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should have super permissions');

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameForAnotherUserLbl);
        LibraryVariableStorage.Enqueue(User2."User Name");

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should show the detail of the failed job.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForAdminUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;

    [Test]
    [HandlerFunctions('AdminSingleJobFailedAndRescheduleFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_AdminJobFailedTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        User2: Record User;
        User3: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For an admin user, he has 0 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // But in the Job Queue, for user 2, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // But in the Job Queue, for user 3, he has 0 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,2,4 respectively.
        // When user clicks on the action to reschedule the failed job, the job should be reset to ready.

        // [GIVEN] Init User, Job Queue Entry
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        PrepareJobQueueNotificationSetupScenario1();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        CreateUser(User2, CreateGuid());
        CreateUser(User3, CreateGuid());
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for the other user
        JobQueueEntry := CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        CreateJobQueueEntry(User3."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User3."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User3."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries
        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameForAnotherUserLbl);
        LibraryVariableStorage.Enqueue(User2."User Name");
        LibraryVariableStorage.Enqueue(JobQueueEntry.ID);


        Assert.IsTrue(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should have super permissions');

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to reschedule the failed job
        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 0,2,5 respectively.
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(5, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForAdminUser(TestPageJobQueueTask, 0, 2, 5, true);
    end;

    [Test]
    [HandlerFunctions('MultiJobsFailedAndShowMoreDetailsFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario1_AdminJobFailedTest03()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        User2: Record User;
        User3: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
        TestPageJobQueueEntry: TestPage "Job Queue Entries";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For an admin user, he has 0 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // But in the Job Queue, for user 2, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // But in the Job Queue, for user 3, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of latest failed job. The cues should show the count of the failed, in process with 2,2 respectively.
        // The in queue count should be 4 because it should contain all the jobs in the queue.

        // [GIVEN] Init User, Job Queue Entry
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        PrepareJobQueueNotificationSetupScenario1();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        CreateUser(User2, CreateGuid());
        CreateUser(User3, CreateGuid());
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        CreateJobQueueEntry(User3."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User3."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User3."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User3."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);


        Assert.IsTrue(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should have super permissions');

        LibraryVariableStorage.Enqueue(2);

        TestPageJobQueueEntry.Trap();

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] When click on show more detail, it should show all the entries without filter.
        TestPageJobQueueEntry.First();
        Assert.IsSubstring(TestPageJobQueueEntry.Description.Value(), FailedJobQueueEntryNameForAnotherUserLbl);
        Assert.IsTrue(TestPageJobQueueEntry.Next(), 'There should be more than 1 failed job');
        Assert.IsSubstring(TestPageJobQueueEntry.Description.Value(), FailedJobQueueEntryNameForAnotherUserLbl);
        Assert.IsFalse(TestPageJobQueueEntry.Next(), 'There should not be more than 2 failed job');

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 2,2,4 respectively.
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(4, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        CheckOnDrillDownPageCorrectForAdminUser(TestPageJobQueueTask, 2, 2, 4, false);
    end;

    //======================================================================================================================
    // Tests for Job Queue Notification Setup Scenario 2:
    // JobQueueNotificationSetup.InProductNotification := true;
    // JobQueueNotificationSetup.NotifyUserInitiatingTask := true;
    // JobQueueNotificationSetup.NotifyJobQueueAdmin := false;
    // JobQueueNotificationSetup.NotifyAfterThreshold := true;
    // JobQueueNotificationSetup.NotifyWhenJobFailed := true;
    //======================================================================================================================
    [Test]
    [HandlerFunctions('SingleJobFailedInJobQueueNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_NotAdminSingleJobFailedTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 2]: For non-admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario2();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should show the detail of the failed job.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedInJobQueueNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_NotAdminSingleJobFailedTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For one non-admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // But in the Job Queue, for another user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of current user's failed job. The cues should show the count of the failed, in process with 1,1 respectively.
        // The in queue count should be 4 because it should contain all the jobs in the queue.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario2();
        CreateUser(User2, CreateGuid());
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries for current user
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should show the detail of the failed job.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,4 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;


    [Test]
    [HandlerFunctions('SingleJobFailedAndDisableNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_NotAdminSingleJobFailedAndDisableNotificationTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For non-admin user, 1 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        // When user clicks on the action to disable the notification, the notification should be disabled.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario2();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);
        // [WHEN] In the handler function, user clicks on the action to disable the notification
        // [THEN] The notification should be disabled.

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 0, 0, false);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedAndRescheduleFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_NotAdminSingleJobFailedAndRescheduleFromNotificationTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For non-admin user, 1 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 0,0,1 respectively.
        // When user clicks on the action to reschedule the failed job, the job should be reset to ready.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario2();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        JobQueueEntry := CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());
        LibraryVariableStorage.Enqueue(JobQueueEntry.ID);

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to reschedule the failed job
        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 0,0,0 respectively.
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 0, 0, 1, true);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedAndRescheduleFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_NotAdminSingleJobFailedAndRescheduleFromNotificationTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For non-admin user, 1 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 0,0,1 respectively.
        // But in the Job Queue, for another user, he has 2 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready. One is created before the current user's failed job and another is created after the current user's failed job.
        // When user clicks on the action to reschedule the failed job, the job should be reset to ready.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario2();
        CreateUser(User2, CreateGuid());
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        // [GIVEN] Create Job Queue Entries for current user
        JobQueueEntry := CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);

        // [GIVEN] Create Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());
        LibraryVariableStorage.Enqueue(JobQueueEntry.ID);

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to reschedule the failed job
        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 0,0,1 respectively.
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 0, 0, 1, true);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedAndShowMoreDetailsFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_SingleJobFailedAndShowMoreDetailNotificationTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
        TestPageJobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For non-admin user, 1 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        // When user clicks on the action to show more details, the related Job Queue Entry Card should render.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario2();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        TestPageJobQueueEntryCard.Trap();
        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to show more details
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntryCard.Description.Value(), 'Job Queue Entry Name is not correct');

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 0, 0, false);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedAndShowMoreDetailsFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_SingleJobFailedAndShowMoreDetailNotificationTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
        TestPageJobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For non-admin user, 1 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        // But in the Job Queue, for another user, he has 2 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready. One is created before the current user's failed job and another is created after the current user's failed job.
        // When user clicks on the action to show more details, the related Job Queue Entry Card should render.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario2();
        CreateUser(User2, CreateGuid());
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        // [GIVEN] Create Job Queue Entries for current user
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [GIVEN] Create Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        TestPageJobQueueEntryCard.Trap();
        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to show more details
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntryCard.Description.Value(), 'Job Queue Entry Name is not correct');

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 0, 0, false);
    end;

    [Test]
    [HandlerFunctions('MultiJobsFailedAndShowMoreDetailsFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_MultiJobsFailedAndShowMoreDetailNotificationTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
        TestPageJobQueueEntry: TestPage "Job Queue Entries";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For non-admin user, 2 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the general error message. The cues should show the count of the failed, in process and in queue jobs with 2,0,0 respectively.
        // When user clicks on the action to show more details, the Job Queue Entries page should render and show all the failed jobs.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario2();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create 2 failed Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);
        LibraryVariableStorage.Enqueue(2);

        TestPageJobQueueEntry.Trap();
        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to show more details
        // [THEN] The Job Queue Entries page should render and show all the failed jobs.
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntry.Description.Value(), 'Job Queue Entry Name is not correct');
        TestPageJobQueueEntry.Next();
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntry.Description.Value(), 'Job Queue Entry Name is not correct');

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 2,1,2 respectively.
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 2, 1, 2, false);
    end;

    [Test]
    [HandlerFunctions('MultiJobsFailedAndShowMoreDetailsFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_MultiJobsFailedAndShowMoreDetailNotificationTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
        TestPageJobQueueEntry: TestPage "Job Queue Entries";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For non-admin user, 2 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the general error message. The cues should show the count of the failed, in process and in queue jobs with 2,0,0 respectively.
        // But in the Job Queue, for another user, he has 2 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready. One is created before the current user's failed job and another is created after the current user's failed job.
        // When user clicks on the action to show more details, the Job Queue Entries page should render and show all the failed jobs.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario2();
        CreateUser(User2, CreateGuid());
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create 1 failed Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        // [GIVEN] Create 2 failed Job Queue Entries for current user
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);
        LibraryVariableStorage.Enqueue(2);
        // [GIVEN] Create 1 failed Job Queue Entries for another user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        TestPageJobQueueEntry.Trap();
        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to show more details
        // [THEN] The Job Queue Entries page should render and show all the failed jobs for current user.
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntry.Description.Value(), 'Job Queue Entry Name is not correct');
        TestPageJobQueueEntry.Next();
        Assert.AreEqual(FailedJobQueueEntryNameLbl, TestPageJobQueueEntry.Description.Value(), 'Job Queue Entry Name is not correct');
        Assert.IsFalse(TestPageJobQueueEntry.Next(), 'There should be only 2 failed jobs');

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 2,1,2 respectively.
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 2, 1, 2, false);
    end;

    [Test]
    [HandlerFunctions('MultiJobsFailedAndDisableNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_MultiJobsFailedAndDisableNotificationTest()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For non-admin user, 2 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // The Job Notification should show the general error message. The cues should show the count of the failed, in process and in queue jobs with 2,0,0 respectively.
        // When user clicks on the action to disable the notification, the notification should be disabled.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario2();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        LibraryVariableStorage.Enqueue(2);

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,0,0 respectively.
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 2, 0, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_AdminJobFailedTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For an admin user, he has 0 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // But in the Job Queue, for another user 2, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of latest failed job. The cues should show the count of the failed, in process with 1,1 respectively.
        // The in queue count should be 2 because it should contain all the jobs in the queue.

        // [GIVEN] Init User, Job Queue Entry
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        PrepareJobQueueNotificationSetupScenario2();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        CreateUser(User2, CreateGuid());

        // // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        Assert.IsTrue(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should have super permissions');

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameForAnotherUserLbl);
        LibraryVariableStorage.Enqueue(User2."User Name");

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] There is not any failed job for the current user, so the notification should not be shown.
        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForAdminUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;

    [Test]
    // [HandlerFunctions('AdminSingleJobFailedAndRescheduleFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_AdminJobFailedTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        User2: Record User;
        User3: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For an admin user, he has 0 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // But in the Job Queue, for user 2, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // But in the Job Queue, for user 3, he has 0 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,2,4 respectively.
        // When user clicks on the action to reschedule the failed job, the job should be reset to ready.

        // [GIVEN] Init User, Job Queue Entry
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        PrepareJobQueueNotificationSetupScenario2();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        CreateUser(User2, CreateGuid());
        CreateUser(User3, CreateGuid());
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for the other user
        JobQueueEntry := CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        CreateJobQueueEntry(User3."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User3."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User3."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries
        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameForAnotherUserLbl);
        LibraryVariableStorage.Enqueue(User2."User Name");
        LibraryVariableStorage.Enqueue(JobQueueEntry.ID);

        Assert.IsTrue(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should have super permissions');

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 0,2,5 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(4, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForAdminUser(TestPageJobQueueTask, 1, 2, 4, true);
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_AdminJobFailedTest03()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        User2: Record User;
        User3: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
        TestPageJobQueueEntry: TestPage "Job Queue Entries";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For an admin user, he has 0 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // But in the Job Queue, for user 2, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // But in the Job Queue, for user 3, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The admin should not receive the notification. The cues should show the count of the failed, in process with 2,2 respectively.
        // The in queue count should be 4 because it should contain all the jobs in the queue.

        // [GIVEN] Init User, Job Queue Entry
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        PrepareJobQueueNotificationSetupScenario2();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        CreateUser(User2, CreateGuid());
        CreateUser(User3, CreateGuid());
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        CreateJobQueueEntry(User3."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User3."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User3."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User3."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        Assert.IsTrue(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should have super permissions');

        TestPageJobQueueEntry.Trap();

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] There is not any failed job for the current user, so the notification should not be shown.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 2,2,4 respectively.
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(4, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        CheckOnDrillDownPageCorrectForAdminUser(TestPageJobQueueTask, 2, 2, 4, false);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedInJobQueueNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_AdminJobFailedTest04()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 2]: For admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.

        // [GIVEN] Init User, Job Queue Entry
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        PrepareJobQueueNotificationSetupScenario2();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should show the detail of the failed job.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedInJobQueueNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario2_AdminJobFailedTest05()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User2: Record User;
        JobQueueAdmin: Record "Job Queue Notified Admin";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario2]: For one admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // But in the Job Queue, for another user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of current user's failed job. The cues should show the count of the failed, in process with 1,1 respectively.
        // The in queue count should be 4 because it should contain all the jobs in the queue.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario2();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        CreateUser(User2, CreateGuid());
        Assert.IsTrue(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries for current user
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should show the detail of the failed job.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,4 respectively.
        Assert.AreEqual(3, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(4, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);
    end;

    //======================================================================================================================
    // Tests for Job Queue Notification Setup Scenario 3:
    // JobQueueNotificationSetup.InProductNotification := true;
    // JobQueueNotificationSetup.NotifyUserInitiatingTask := false;
    // JobQueueNotificationSetup.NotifyJobQueueAdmin := true;
    // JobQueueNotificationSetup.NotifyAfterThreshold := true;
    // JobQueueNotificationSetup.NotifyWhenJobFailed := true;
    //======================================================================================================================
    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario3_NotAdminSingleJobFailedTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification] [Setup Scenario3]: For non-admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario3();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should show the detail of the failed job.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario3_NotAdminSingleJobFailedTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification] [Setup Scenario3]: For one non-admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // But in the Job Queue, for another user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of current user's failed job. The cues should show the count of the failed, in process with 1,1 respectively.
        // The in queue count should be 4 because it should contain all the jobs in the queue.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario3();
        CreateUser(User2, CreateGuid());
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries for current user
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should not appear

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,4 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedInJobQueueNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario3_AdminJobFailedTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario3]: For an admin user, he has 0 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // But in the Job Queue, for another user 2, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of latest failed job. The cues should show the count of the failed, in process with 1,1 respectively.
        // The in queue count should be 2 because it should contain all the jobs in the queue.

        // [GIVEN] Init User, Job Queue Entry
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        PrepareJobQueueNotificationSetupScenario1();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        CreateUser(User2, CreateGuid());
        LibraryVariableStorage.Clear();

        // // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);


        Assert.IsTrue(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should have super permissions');

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameForAnotherUserLbl);
        LibraryVariableStorage.Enqueue(User2."User Name");

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should show the detail of the failed job.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForAdminUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;

    [Test]
    [HandlerFunctions('AdminSingleJobFailedAndRescheduleFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario3_AdminJobFailedTest02()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        User2: Record User;
        User3: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 1]: For an admin user, he has 0 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // But in the Job Queue, for user 2, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // But in the Job Queue, for user 3, he has 0 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,2,4 respectively.
        // When user clicks on the action to reschedule the failed job, the job should be reset to ready.

        // [GIVEN] Init User, Job Queue Entry
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        PrepareJobQueueNotificationSetupScenario1();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        CreateUser(User2, CreateGuid());
        CreateUser(User3, CreateGuid());
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for the other user
        JobQueueEntry := CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        CreateJobQueueEntry(User3."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User3."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User3."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries
        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameForAnotherUserLbl);
        LibraryVariableStorage.Enqueue(User2."User Name");
        LibraryVariableStorage.Enqueue(JobQueueEntry.ID);


        Assert.IsTrue(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should have super permissions');

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [WHEN] In the handler function, user clicks on the action to reschedule the failed job
        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 0,2,5 respectively.
        Assert.AreEqual(0, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(5, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForAdminUser(TestPageJobQueueTask, 0, 2, 5, true);
    end;

    [Test]
    [HandlerFunctions('MultiJobsFailedAndShowMoreDetailsFromNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario3_AdminJobFailedTest03()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        User2: Record User;
        User3: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
        TestPageJobQueueEntry: TestPage "Job Queue Entries";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 3]: For an admin user, he has 0 Job failed, 0 Job in process, 0 Job waiting and 0 Job ready.
        // But in the Job Queue, for user 2, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // But in the Job Queue, for user 3, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of latest failed job. The cues should show the count of the failed, in process with 2,2 respectively.
        // The in queue count should be 4 because it should contain all the jobs in the queue.

        // [GIVEN] Init User, Job Queue Entry
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        PrepareJobQueueNotificationSetupScenario1();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        CreateUser(User2, CreateGuid());
        CreateUser(User3, CreateGuid());
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        CreateJobQueueEntry(User3."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User3."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User3."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User3."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        Assert.IsTrue(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should have super permissions');

        LibraryVariableStorage.Enqueue(2);

        TestPageJobQueueEntry.Trap();

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] When click on show more detail, it should show all the entries without filter.
        TestPageJobQueueEntry.First();
        Assert.IsSubstring(TestPageJobQueueEntry.Description.Value(), FailedJobQueueEntryNameForAnotherUserLbl);
        Assert.IsTrue(TestPageJobQueueEntry.Next(), 'There should be more than 1 failed job');
        Assert.IsSubstring(TestPageJobQueueEntry.Description.Value(), FailedJobQueueEntryNameForAnotherUserLbl);
        Assert.IsFalse(TestPageJobQueueEntry.Next(), 'There should not be more than 2 failed job');

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 2,2,4 respectively.
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(4, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        CheckOnDrillDownPageCorrectForAdminUser(TestPageJobQueueTask, 2, 2, 4, false);
    end;

    [Test]
    [HandlerFunctions('SingleJobFailedInJobQueueNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario3_AdminJobFailedTest04()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario 3]: For admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.

        // [GIVEN] Init User, Job Queue Entry
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        PrepareJobQueueNotificationSetupScenario2();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should show the detail of the failed job.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;

    [Test]
    [HandlerFunctions('MultiJobsFailedNotificationHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario3_AdminJobFailedTest05()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueAdmin: Record "Job Queue Notified Admin";
        User2: Record User;
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification][Setup Scenario3]: For one admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // But in the Job Queue, for another user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of current user's failed job. The cues should show the count of the failed, in process with 1,1 respectively.
        // The in queue count should be 4 because it should contain all the jobs in the queue.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario3();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        CreateUser(User2, CreateGuid());
        Assert.IsTrue(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(User2."User Name", InProcessJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(User2."User Name", WaitingJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(User2."User Name", ReadyJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries for current user
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        // [GIVEN] Create Job Queue Entries for the other user
        CreateJobQueueEntry(User2."User Name", FailedJobQueueEntryNameForAnotherUserLbl, JobQueueEntry.Status::Error);

        LibraryVariableStorage.Enqueue(3);

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] The notification should show the detail of the failed job.

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,4 respectively.
        Assert.AreEqual(3, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(4, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);
    end;

    //============================================================================================================
    // Tests for Job Queue Notification Setup Scenario 4:
    // JobQueueNotificationSetup.InProductNotification := false;
    // JobQueueNotificationSetup.NotifyUserInitiatingTask := true;
    // JobQueueNotificationSetup.NotifyJobQueueAdmin := true;
    // JobQueueNotificationSetup.NotifyAfterThreshold := true;
    // JobQueueNotificationSetup.NotifyWhenJobFailed := true;
    //============================================================================================================
    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario4_NotAdminSingleJobFailedTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification] [Setup Scenario 4]: For non-admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario4();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] There should not be any notification

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;

    //============================================================================================================
    // Tests for Job Queue Notification Setup Scenario 5:
    // JobQueueNotificationSetup.InProductNotification := true;
    // JobQueueNotificationSetup.NotifyUserInitiatingTask := true;
    // JobQueueNotificationSetup.NotifyJobQueueAdmin := true;
    // JobQueueNotificationSetup.NotifyAfterThreshold := true;
    // JobQueueNotificationSetup.NotifyWhenJobFailed := false;
    //============================================================================================================
    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario5_NotAdminSingleJobFailedTest01()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TestPageJobQueueTask: TestPage "Job Queue Tasks Activities";
    begin
        // [SCENARIO] [Job Queue Failure Notification] [Setup Scenario 5]: For non-admin user, he has 1 Job failed, 1 Job in process, 1 Job waiting and 1 Job ready.
        // The Job Notification should show the detail of the failed job. The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.

        // [GIVEN] Init User, Job Queue Entry
        Initialize();
        PrepareJobQueueNotificationSetupScenario5();
        Assert.IsFalse(JobQueueMgt.CheckUserInJobQueueAdminList(UserId()), 'User should not be in the Job Queue Admin List');
        LibraryVariableStorage.Clear();

        // [GIVEN] Create Job Queue Entries
        CreateJobQueueEntry(UserId(), FailedJobQueueEntryNameLbl, JobQueueEntry.Status::Error);
        CreateJobQueueEntry(UserId(), InProcessJobQueueEntryNameLbl, JobQueueEntry.Status::"In Process");
        CreateJobQueueEntry(UserId(), WaitingJobQueueEntryNameLbl, JobQueueEntry.Status::Waiting);
        CreateJobQueueEntry(UserId(), ReadyJobQueueEntryNameLbl, JobQueueEntry.Status::Ready);

        LibraryVariableStorage.Enqueue(FailedJobQueueEntryNameLbl);
        LibraryVariableStorage.Enqueue(UserId());

        // [WHEN] Open Test Page
        TestPageJobQueueTask.OpenView();

        // [THEN] There should not be any notification

        // [THEN] The cues should show the count of the failed, in process and in queue jobs with 1,1,2 respectively.
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks Failed".AsInteger(), TaskFailedCountIncorrectLbl);
        Assert.AreEqual(1, TestPageJobQueueTask."Tasks In Process".AsInteger(), TaskInProcessCountIncorrectLbl);
        Assert.AreEqual(2, TestPageJobQueueTask."Tasks In Queue".AsInteger(), TaskInQueueCountIncorrectLbl);

        // [THEN] Check the detail of the failed job, in process job and in queue job
        CheckOnDrillDownPageCorrectForCommonUser(TestPageJobQueueTask, 1, 1, 2, false);
    end;

    //============================================================================================================
    // Tests for Job Queue Notification Assisted Set up
    //============================================================================================================
    [Test]
    procedure TestJobQueueNotificationAssistedSetup1()
    var
        JobQueueAdmin: Record "Job Queue Notified Admin";
        JobQueueNotificationSetup: Record "Job Queue Notification Setup";
        TestPageJobQueueNotificationSetup: TestPage "Job Queue Notification Wizard";
    begin
        JobQueueAdmin.DeleteAll();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        TestPageJobQueueNotificationSetup.OpenView();
        //Step1: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //Step2: Click on the Next button
        Assert.IsTrue(TestPageJobQueueNotificationSetup."Job Queue Admin List".First(), 'Job Queue Admin List should contain one record');
        //Step3: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //Change the values of the threshold
        TestPageJobQueueNotificationSetup.Threshold1.SetValue(1);
        TestPageJobQueueNotificationSetup.Threshold2.SetValue(2);
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //Step4: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        Assert.IsFalse(TestPageJobQueueNotificationSetup.NextAction.Enabled(), 'Next button should be disabled');
        TestPageJobQueueNotificationSetup.FinishAction.Invoke();

        // [THEN] The Job Queue Notification Setup should be created
        Assert.IsTrue(JobQueueAdmin.FindFirst(), 'Job Queue Admin should be created');
        Assert.AreEqual(UserId(), JobQueueAdmin."User Name", 'Job Queue Admin should be the current user');

        JobQueueNotificationSetup.Get();
        Assert.AreEqual(1, JobQueueNotificationSetup.Threshold1, 'Threshold1 should be set as 1');
        Assert.AreEqual(2, JobQueueNotificationSetup.Threshold2, 'Threshold2 should be set as 2');
    end;

    [Test]
    procedure TestJobQueueNotificationAssistedSetup2()
    var
        JobQueueAdmin: Record "Job Queue Notified Admin";
        TestPageJobQueueNotificationSetup: TestPage "Job Queue Notification Wizard";
    begin
        JobQueueAdmin.DeleteAll();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        TestPageJobQueueNotificationSetup.OpenView();
        //Step1: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //Step2: Click on the Next button
        Assert.IsTrue(TestPageJobQueueNotificationSetup."Job Queue Admin List".First(), 'Job Queue Admin List should contain one record');
        //Step3: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //Change the values of the threshold
        asserterror TestPageJobQueueNotificationSetup.Threshold1.SetValue(-1);
        Assert.ExpectedError('Threshold 1 must be greater than or equal to 0.');
    end;

    [Test]
    procedure TestJobQueueNotificationAssistedSetup3()
    var
        JobQueueAdmin: Record "Job Queue Notified Admin";
        TestPageJobQueueNotificationSetup: TestPage "Job Queue Notification Wizard";
    begin
        JobQueueAdmin.DeleteAll();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        TestPageJobQueueNotificationSetup.OpenView();
        //Step1: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //Step2: Click on the Next button
        Assert.IsTrue(TestPageJobQueueNotificationSetup."Job Queue Admin List".First(), 'Job Queue Admin List should contain one record');
        //Step3: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //Change the values of the threshold
        TestPageJobQueueNotificationSetup.Threshold1.SetValue(1);
        asserterror TestPageJobQueueNotificationSetup.Threshold2.SetValue(-2);
        Assert.ExpectedError('Threshold 2 must be greater than or equal to 0.');
    end;

    [Test]
    procedure TestJobQueueNotificationAssistedSetup4()
    var
        JobQueueAdmin: Record "Job Queue Notified Admin";
        TestPageJobQueueNotificationSetup: TestPage "Job Queue Notification Wizard";
    begin
        JobQueueAdmin.DeleteAll();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        TestPageJobQueueNotificationSetup.OpenView();
        //Step1: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //Step2: Click on the Next button
        Assert.IsTrue(TestPageJobQueueNotificationSetup."Job Queue Admin List".First(), 'Job Queue Admin List should contain one record');
        //Step3: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //Change the values of the threshold
        asserterror TestPageJobQueueNotificationSetup.Threshold1.SetValue(4);
        Assert.ExpectedError('Threshold 1 must be less than or equal to Threshold 2.');
    end;

    [Test]
    procedure TestJobQueueNotificationAssistedSetup5()
    var
        JobQueueAdmin: Record "Job Queue Notified Admin";
        TestPageJobQueueNotificationSetup: TestPage "Job Queue Notification Wizard";
    begin
        JobQueueAdmin.DeleteAll();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        TestPageJobQueueNotificationSetup.OpenView();
        //Step1: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //Step2: Click on the Next button
        Assert.IsTrue(TestPageJobQueueNotificationSetup."Job Queue Admin List".First(), 'Job Queue Admin List should contain one record');
        //Step3: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //Change the values of the threshold
        TestPageJobQueueNotificationSetup.Threshold1.SetValue(2);
        asserterror TestPageJobQueueNotificationSetup.Threshold2.SetValue(1);
        Assert.ExpectedError('Threshold 1 must be less than or equal to Threshold 2.');
    end;

    [Test]
    procedure AssistedSetupMutualExclusiveFieldsTest()
    var
        JobQueueAdmin: Record "Job Queue Notified Admin";
        TestPageJobQueueNotificationSetup: TestPage "Job Queue Notification Wizard";
    begin
        // [SCENARIO][Job Queue Failure Notification][Assisted Setup][Bug 546833]: User can select either Immediate or After Threshold is reached, but these two fields should be mutually exclusive.
        JobQueueAdmin.DeleteAll();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        TestPageJobQueueNotificationSetup.OpenView();
        //[Given] Step1: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //[Given] Step2: Click on the Next button
        Assert.IsTrue(TestPageJobQueueNotificationSetup."Job Queue Admin List".First(), 'Job Queue Admin List should contain one record');
        //[Given] Step3: Click on the Next button
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        //[Then] Show Notification Immediately should be selected by default.
        Assert.IsTrue(TestPageJobQueueNotificationSetup.ShowNotificationImmediately.AsBoolean(), 'Show Notification Immediately should be selected by default');
        Assert.IsFalse(TestPageJobQueueNotificationSetup.ShowNotificationReachingThreshold.AsBoolean(), 'Show Notification Reaching Threshold should not be selected by default');
        Assert.IsFalse(TestPageJobQueueNotificationSetup.Threshold1.Editable(), 'Threshold1 should not be editable');
        Assert.IsFalse(TestPageJobQueueNotificationSetup.Threshold2.Editable(), 'Threshold2 should not be editable');

        //[When] Set Show Notification Reaching Threshold to true
        TestPageJobQueueNotificationSetup.ShowNotificationReachingThreshold.SetValue(true);
        //[Then] Show Notification Immediately should be disabled, the Threshold1 and Threshold2 should be editable.
        Assert.IsFalse(TestPageJobQueueNotificationSetup.ShowNotificationImmediately.AsBoolean(), 'Show Notification Immediately should be not selected');
        Assert.IsTrue(TestPageJobQueueNotificationSetup.ShowNotificationReachingThreshold.AsBoolean(), 'Show Notification Reaching Threshold should be selected');
        Assert.IsTrue(TestPageJobQueueNotificationSetup.Threshold1.Editable(), 'Threshold1 should be editable');
        Assert.IsTrue(TestPageJobQueueNotificationSetup.Threshold2.Editable(), 'Threshold2 should be editable');

        //[When] Set Show Notification Reaching Threshold to true
        TestPageJobQueueNotificationSetup.ShowNotificationImmediately.SetValue(true);
        //[Then] Show Notification Immediately should be selected again.
        Assert.IsTrue(TestPageJobQueueNotificationSetup.ShowNotificationImmediately.AsBoolean(), 'Show Notification Immediately should be selected by default');
        Assert.IsFalse(TestPageJobQueueNotificationSetup.ShowNotificationReachingThreshold.AsBoolean(), 'Show Notification Reaching Threshold should not be selected by default');
        Assert.IsFalse(TestPageJobQueueNotificationSetup.Threshold1.Editable(), 'Threshold1 should not be editable');
        Assert.IsFalse(TestPageJobQueueNotificationSetup.Threshold2.Editable(), 'Threshold2 should not be editable');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure AssistedSetupUpdateMyNotificationTest01()
    var
        User1: Record User;
        User2: Record User;
        User3: Record User;
        MyNotifications: Record "My Notifications";
        JobQueueSendNotificationMgt: Codeunit "Job Queue - Send Notification";
        TestPageJobQueueNotificationSetup: TestPage "Job Queue Notification Wizard";
    begin
        // [SCENARIO][Job Queue Failure Notification][Assisted Setup][Bug 546866]: There are two common users and two admin users. When NotifyUserInitiatingBackgroundTasks and NotifyAdmin are selected, the notification should be created for all the users.

        // [GIVEN] Init User and Job Queue Notification Setup
        InitTestForAssistedSetupUpdateMyNotification(User1, User2, User3);

        // [WHEN] Set the NotifyUserInitiatingBackgroundTasks to true and NotifyAdmin to true
        TestPageJobQueueNotificationSetup.OpenView();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NotifyUserInitiatingBackgroundTasks.SetValue(true);
        TestPageJobQueueNotificationSetup.NotifyAdmin.SetValue(true);
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.FinishAction.Invoke();

        // [THEN] The two admin users should have the notification created
        Assert.IsTrue(MyNotifications.Get(UserId(), JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsTrue(MyNotifications.Enabled, 'My Notification should be enabled');
        Assert.IsTrue(MyNotifications.Get(User1."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsTrue(MyNotifications.Enabled, 'My Notification should be enabled');
        // [THEN] The two common users should have the notification created
        Assert.IsTrue(MyNotifications.Get(User2."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsTrue(MyNotifications.Enabled, 'My Notification should be enabled');
        Assert.IsTrue(MyNotifications.Get(User3."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsTrue(MyNotifications.Enabled, 'My Notification should be enabled');
    end;


    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure AssistedSetupUpdateMyNotificationTest02()
    var
        User1: Record User;
        User2: Record User;
        User3: Record User;
        MyNotifications: Record "My Notifications";
        JobQueueSendNotificationMgt: Codeunit "Job Queue - Send Notification";
        TestPageJobQueueNotificationSetup: TestPage "Job Queue Notification Wizard";
    begin
        // [SCENARIO][Job Queue Failure Notification][Assisted Setup][Bug 546866]: There are two common users and two admin users. When NotifyUserInitiatingBackgroundTasks to false and NotifyAdmin to true, the notification should be created for admin users.

        // [GIVEN] Init User and Job Queue Notification Setup
        InitTestForAssistedSetupUpdateMyNotification(User1, User2, User3);

        // [WHEN] Set the NotifyUserInitiatingBackgroundTasks to true and NotifyAdmin to true
        TestPageJobQueueNotificationSetup.OpenView();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NotifyUserInitiatingBackgroundTasks.SetValue(false);
        TestPageJobQueueNotificationSetup.NotifyAdmin.SetValue(true);
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.FinishAction.Invoke();

        // [THEN] The two admin users should have the notification created
        Assert.IsTrue(MyNotifications.Get(UserId(), JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsTrue(MyNotifications.Enabled, 'My Notification should be enabled');
        Assert.IsTrue(MyNotifications.Get(User1."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsTrue(MyNotifications.Enabled, 'My Notification should be enabled');
        // [THEN] The two common users should not have the notification created
        Assert.IsTrue(MyNotifications.Get(User2."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsFalse(MyNotifications.Enabled, 'My Notification should be enabled');
        Assert.IsTrue(MyNotifications.Get(User3."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsFalse(MyNotifications.Enabled, 'My Notification should be enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure AssistedSetupUpdateMyNotificationTest03()
    var
        User1: Record User;
        User2: Record User;
        User3: Record User;
        MyNotifications: Record "My Notifications";
        JobQueueSendNotificationMgt: Codeunit "Job Queue - Send Notification";
        TestPageJobQueueNotificationSetup: TestPage "Job Queue Notification Wizard";
    begin
        // [SCENARIO][Job Queue Failure Notification][Assisted Setup][Bug 546866]: There are two common users and two admin users. When NotifyUserInitiatingBackgroundTasks to false and NotifyAdmin to false, no notification should be created.

        // [GIVEN] Init User and Job Queue Notification Setup
        InitTestForAssistedSetupUpdateMyNotification(User1, User2, User3);

        // [WHEN] Set the NotifyUserInitiatingBackgroundTasks to false and NotifyAdmin to false
        TestPageJobQueueNotificationSetup.OpenView();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NotifyUserInitiatingBackgroundTasks.SetValue(false);
        TestPageJobQueueNotificationSetup.NotifyAdmin.SetValue(false);
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.FinishAction.Invoke();

        // [THEN] The two admin users should not have the notification created
        Assert.IsTrue(MyNotifications.Get(UserId(), JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsFalse(MyNotifications.Enabled, 'My Notification should be enabled');
        Assert.IsTrue(MyNotifications.Get(User1."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsFalse(MyNotifications.Enabled, 'My Notification should be enabled');
        // [THEN] The two common users should not have the notification created
        Assert.IsTrue(MyNotifications.Get(User2."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsFalse(MyNotifications.Enabled, 'My Notification should be enabled');
        Assert.IsTrue(MyNotifications.Get(User3."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsFalse(MyNotifications.Enabled, 'My Notification should be enabled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure AssistedSetupUpdateMyNotificationTest04()
    var
        User1: Record User;
        User2: Record User;
        User3: Record User;
        MyNotifications: Record "My Notifications";
        JobQueueSendNotificationMgt: Codeunit "Job Queue - Send Notification";
        TestPageJobQueueNotificationSetup: TestPage "Job Queue Notification Wizard";
    begin
        // [SCENARIO][Job Queue Failure Notification][Assisted Setup][Bug 546866]: There are two common users and two admin users. When NotifyUserInitiatingBackgroundTasks to true and NotifyAdmin to false, all notification should be created.

        // [GIVEN] Init User and Job Queue Notification Setup
        InitTestForAssistedSetupUpdateMyNotification(User1, User2, User3);

        // [WHEN] Set the NotifyUserInitiatingBackgroundTasks to true and NotifyAdmin to false
        TestPageJobQueueNotificationSetup.OpenView();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NotifyUserInitiatingBackgroundTasks.SetValue(true);
        TestPageJobQueueNotificationSetup.NotifyAdmin.SetValue(false);
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.NextAction.Invoke();
        TestPageJobQueueNotificationSetup.FinishAction.Invoke();

        // [THEN] The two common users should have the notification created
        Assert.IsTrue(MyNotifications.Get(UserId(), JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsTrue(MyNotifications.Enabled, 'My Notification should be enabled');
        Assert.IsTrue(MyNotifications.Get(User1."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsTrue(MyNotifications.Enabled, 'My Notification should be enabled');
        // [THEN] The two common users should have the notification created
        Assert.IsTrue(MyNotifications.Get(User2."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsTrue(MyNotifications.Enabled, 'My Notification should be enabled');
        Assert.IsTrue(MyNotifications.Get(User3."User Name", JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()), 'My Notification should exist.');
        Assert.IsTrue(MyNotifications.Enabled, 'My Notification should be enabled');
    end;

    local procedure InitTestForAssistedSetupUpdateMyNotification(var User1: Record User; var User2: Record User; var User3: Record User)
    var
        JobQueueAdmin: Record "Job Queue Notified Admin";
    begin
        CreateUser(User1, 'TestUser1');
        CreateUser(User2, 'TestUser2');
        CreateUser(User3, 'TestUser3');
        InitMyNotificationsForJobQueueFailed(UserId());
        InitMyNotificationsForJobQueueFailed(User1."User Name");
        InitMyNotificationsForJobQueueFailed(User2."User Name");
        InitMyNotificationsForJobQueueFailed(User3."User Name");
        JobQueueAdmin.DeleteAll();
        JobQueueAdmin."User Name" := UserId();
        JobQueueAdmin.Insert(true);
        JobQueueAdmin."User Name" := User1."User Name";
        JobQueueAdmin.Insert(true);
    end;

    local procedure InitMyNotificationsForJobQueueFailed(UserName: Text)
    var
        JobQueueSendNotificationMgt: Codeunit "Job Queue - Send Notification";
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Get(UserName, JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId()) then begin
            MyNotifications.Init();
            MyNotifications."User Id" := UserName;
            MyNotifications."Notification Id" := JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId();
            MyNotifications.Insert();
        end;
    end;

    local procedure CreateJobQueueEntry(UserId: Text; Description: Text; Status: Option): Record "Job Queue Entry"
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.Validate(ID, CreateGuid());
        JobQueueEntry.Validate("User ID", UserId);
        JobQueueEntry.Validate(Description, Description);
        JobQueueEntry.Validate(Status, Status);
        JobQueueEntry.Insert();
        exit(JobQueueEntry);
    end;

    local procedure CreateUser(var User: Record User; UserName: Text)
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryPermissions.CreateUser(User, UserName, false);
        LibraryLowerPermissions.SetO365BusFull();
    end;

    local procedure PrepareJobQueueNotificationSetupScenario1()
    var
        JobQueueNotificationSetup: Record "Job Queue Notification Setup";
    begin
        // All the notification settings are enabled
        JobQueueNotificationSetup.DeleteAll();
        JobQueueNotificationSetup.Init();
        JobQueueNotificationSetup.InProductNotification := true;
        JobQueueNotificationSetup.NotifyUserInitiatingTask := true;
        JobQueueNotificationSetup.NotifyJobQueueAdmin := true;
        JobQueueNotificationSetup.NotifyAfterThreshold := true;
        JobQueueNotificationSetup.NotifyWhenJobFailed := true;
        JobQueueNotificationSetup.Insert();
    end;


    local procedure PrepareJobQueueNotificationSetupScenario2()
    var
        JobQueueNotificationSetup: Record "Job Queue Notification Setup";
    begin
        // All the notification settings are enabled except for the NotifyJobQueueAdmin
        JobQueueNotificationSetup.DeleteAll();
        JobQueueNotificationSetup.Init();
        JobQueueNotificationSetup.InProductNotification := true;
        JobQueueNotificationSetup.NotifyUserInitiatingTask := true;
        JobQueueNotificationSetup.NotifyJobQueueAdmin := false;
        JobQueueNotificationSetup.NotifyAfterThreshold := true;
        JobQueueNotificationSetup.NotifyWhenJobFailed := true;
        JobQueueNotificationSetup.Insert();
    end;

    local procedure PrepareJobQueueNotificationSetupScenario3()
    var
        JobQueueNotificationSetup: Record "Job Queue Notification Setup";
    begin
        JobQueueNotificationSetup.DeleteAll();
        JobQueueNotificationSetup.Init();
        JobQueueNotificationSetup.InProductNotification := true;
        JobQueueNotificationSetup.NotifyUserInitiatingTask := false;
        JobQueueNotificationSetup.NotifyJobQueueAdmin := true;
        JobQueueNotificationSetup.NotifyAfterThreshold := true;
        JobQueueNotificationSetup.NotifyWhenJobFailed := true;
        JobQueueNotificationSetup.Insert();
    end;

    local procedure PrepareJobQueueNotificationSetupScenario4()
    var
        JobQueueNotificationSetup: Record "Job Queue Notification Setup";
    begin
        JobQueueNotificationSetup.DeleteAll();
        JobQueueNotificationSetup.Init();
        JobQueueNotificationSetup.InProductNotification := false;
        JobQueueNotificationSetup.NotifyUserInitiatingTask := true;
        JobQueueNotificationSetup.NotifyJobQueueAdmin := true;
        JobQueueNotificationSetup.NotifyAfterThreshold := true;
        JobQueueNotificationSetup.NotifyWhenJobFailed := true;
        JobQueueNotificationSetup.Insert();
    end;

    local procedure PrepareJobQueueNotificationSetupScenario5()
    var
        JobQueueNotificationSetup: Record "Job Queue Notification Setup";
    begin
        JobQueueNotificationSetup.DeleteAll();
        JobQueueNotificationSetup.Init();
        JobQueueNotificationSetup.InProductNotification := true;
        JobQueueNotificationSetup.NotifyUserInitiatingTask := true;
        JobQueueNotificationSetup.NotifyJobQueueAdmin := true;
        JobQueueNotificationSetup.NotifyAfterThreshold := true;
        JobQueueNotificationSetup.NotifyWhenJobFailed := false;
        JobQueueNotificationSetup.Insert();
    end;

    local procedure Initialize()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueNotificationSetup: Record "Job Queue Notification Setup";
        JobQueueAdminList: Record "Job Queue Notified Admin";
        User: Record User;
    begin
        JobQueueEntry.DeleteAll();
        JobQueueLogEntry.DeleteAll();
        JobQueueNotificationSetup.DeleteAll();
        JobQueueAdminList.DeleteAll();

        User.SetRange("User Name", UserId());
        if User.IsEmpty() then begin
            // Set the user permissions to Super to create the user
            LibraryLowerPermissions.SetOutsideO365Scope();
            LibraryPermissions.CreateUser(User, CopyStr(UserId(), 1, 50), true);
            // Set the user permissions back
            LibraryLowerPermissions.SetO365BusFull();
        end;
    end;

    local procedure CheckOnDrillDownPageCorrectForCommonUser(Tp: TestPage "Job Queue Tasks Activities"; FailedJobCount: Integer; InProcessJobCount: Integer; InQueueJobCount: Integer; FailedJobIsReschedule: Boolean)
    var
        TestPageJobFailed: TestPage "Job Queue Entries";
        TestPageJobInQueue: TestPage "Job Queue Entries";
        TestPageJobInProcess: TestPage "Job Queue Entries";
        i: Integer;
    begin
        // Check the failed job
        TestPageJobFailed.Trap();
        Tp."Tasks Failed".Drilldown();
        if FailedJobCount = 0 then
            Assert.IsFalse(TestPageJobFailed.First(), 'There should be no failed job')
        else
            repeat
                Assert.AreEqual(TestPageJobFailed.Description.Value(), FailedJobQueueEntryNameLbl, 'Job Queue Entry Name is not correct');
                i += 1;
            until not TestPageJobFailed.Next();
        Assert.AreEqual(i, FailedJobCount, 'Failed Job Count is incorrect');
        TestPageJobFailed.Close();

        // Check the in process job
        TestPageJobInProcess.Trap();
        Tp."Tasks In Process".Drilldown();
        if InProcessJobCount = 0 then
            Assert.IsFalse(TestPageJobInProcess.First(), 'There should be no in process job')
        else begin
            i := 0;
            repeat
                Assert.AreEqual(TestPageJobInProcess.Description.Value(), InProcessJobQueueEntryNameLbl, 'Job Queue Entry Name is not correct');
                i += 1;
            until not TestPageJobInProcess.Next();
            Assert.AreEqual(i, InProcessJobCount, 'In Process Job Count is incorrect');
        end;
        TestPageJobInProcess.Close();

        // Check the in queue job
        TestPageJobInQueue.Trap();
        Tp."Tasks In Queue".Drilldown();
        if InQueueJobCount = 0 then
            Assert.IsFalse(TestPageJobInQueue.First(), 'There should be no in queue job')
        else begin
            i := 0;
            repeat
                if FailedJobIsReschedule then
                    Assert.IsSubstring(WaitingJobQueueEntryNameLbl + ReadyJobQueueEntryNameLbl + ReadyJobQueueEntryNameForAnotherUserLbl + WaitingJobQueueEntryNameForAnotherUserLbl + FailedJobQueueEntryNameLbl, TestPageJobInQueue.Description.Value())
                else
                    Assert.IsSubstring(WaitingJobQueueEntryNameLbl + ReadyJobQueueEntryNameLbl + ReadyJobQueueEntryNameForAnotherUserLbl + WaitingJobQueueEntryNameForAnotherUserLbl, TestPageJobInQueue.Description.Value());
                i += 1;
            until not TestPageJobInQueue.Next();
            Assert.AreEqual(i, InQueueJobCount, 'In Queue Job Count is incorrect')
        end;
        TestPageJobInQueue.Close();
    end;

    local procedure CheckOnDrillDownPageCorrectForAdminUser(Tp: TestPage "Job Queue Tasks Activities"; FailedJobCount: Integer; InProcessJobCount: Integer; InQueueJobCount: Integer; FailedJobIsReschedule: Boolean)
    var
        TestPageJobFailed: TestPage "Job Queue Entries";
        TestPageJobInQueue: TestPage "Job Queue Entries";
        TestPageJobInProcess: TestPage "Job Queue Entries";
        i: Integer;
    begin
        // Check the failed job
        TestPageJobFailed.Trap();
        Tp."Tasks Failed".Drilldown();
        if FailedJobCount = 0 then
            Assert.IsFalse(TestPageJobFailed.First(), 'There should be no failed job')
        else
            repeat
                Assert.AreEqual(TestPageJobFailed.Description.Value(), FailedJobQueueEntryNameForAnotherUserLbl, 'Job Queue Entry Name is not correct');
                i += 1;
            until not TestPageJobFailed.Next();
        Assert.AreEqual(i, FailedJobCount, 'Failed Job Count is incorrect');
        TestPageJobFailed.Close();

        // Check the in process job
        TestPageJobInProcess.Trap();
        Tp."Tasks In Process".Drilldown();
        if InProcessJobCount = 0 then
            Assert.IsFalse(TestPageJobInProcess.First(), 'There should be no in process job')
        else begin
            i := 0;
            repeat
                Assert.AreEqual(TestPageJobInProcess.Description.Value(), InProcessJobQueueEntryNameForAnotherUserLbl, 'Job Queue Entry Name is not correct');
                i += 1;
            until not TestPageJobInProcess.Next();
            Assert.AreEqual(i, InProcessJobCount, 'In Process Job Count is incorrect');
        end;
        TestPageJobInProcess.Close();

        // Check the in queue job
        TestPageJobInQueue.Trap();
        Tp."Tasks In Queue".Drilldown();
        if InQueueJobCount = 0 then
            Assert.IsFalse(TestPageJobInQueue.First(), 'There should be no in queue job')
        else begin
            i := 0;
            repeat
                if FailedJobIsReschedule then
                    Assert.IsSubstring(ReadyJobQueueEntryNameForAnotherUserLbl + WaitingJobQueueEntryNameForAnotherUserLbl + FailedJobQueueEntryNameForAnotherUserLbl, TestPageJobInQueue.Description.Value())
                else
                    Assert.IsSubstring(ReadyJobQueueEntryNameForAnotherUserLbl + WaitingJobQueueEntryNameForAnotherUserLbl, TestPageJobInQueue.Description.Value());
                i += 1;
            until not TestPageJobInQueue.Next();
            Assert.AreEqual(i, InQueueJobCount, 'In Queue Job Count is incorrect')
        end;
        TestPageJobInQueue.Close();
    end;

    [SendNotificationHandler]
    procedure SingleJobFailedInJobQueueNotificationHandler(var Notification: Notification): Boolean
    var
        JobQueueNotificationMgnt: Codeunit "Job Queue - Send Notification";
    begin
        Assert.AreEqual(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId(), Notification.Id, 'Notification Id is not correct');
        Assert.ExpectedMessage(StrSubstNo(JobQueueNotificationMgnt.GetJobQueueSingleTaskFailedMsg(), LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText()), Notification.Message);
    end;

    [SendNotificationHandler]
    procedure SingleJobFailedAndDisableNotificationHandler(var Notification: Notification): Boolean
    var
        MyNotifications: Record "My Notifications";
        JobQueueNotificationMgnt: Codeunit "Job Queue - Send Notification";
    begin
        Assert.AreEqual(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId(), Notification.Id, 'Notification Id is not correct');
        Assert.ExpectedMessage(StrSubstNo(JobQueueNotificationMgnt.GetJobQueueSingleTaskFailedMsg(), LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText()), Notification.Message);
        //[WHEN] Disable the notification
        JobQueueNotificationMgnt.DisableNotification(Notification);
        //[THEN] This notification should be disabled
        Assert.IsFalse(MyNotifications.IsEnabled(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId()), 'Notification should have been disabled');
        //[THEN] Set the status back to true otherwise the notification will not be triggered again
        MyNotifications.SetStatus(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId(), true);
    end;

    [SendNotificationHandler]
    procedure SingleJobFailedAndRescheduleFromNotificationHandler(var Notification: Notification): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueNotificationMgnt: Codeunit "Job Queue - Send Notification";
    begin
        Assert.AreEqual(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId(), Notification.Id, 'Notification Id is not correct');
        Assert.ExpectedMessage(StrSubstNo(JobQueueNotificationMgnt.GetJobQueueSingleTaskFailedMsg(), LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText()), Notification.Message);
        //[WHEN] Restart the failed job
        JobQueueNotificationMgnt.RestartFailedJob(Notification);
        //[THEN] This status of the failed job should be changed to Ready
        JobQueueEntry.Get(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(JobQueueEntry.Status::Ready, JobQueueEntry.Status, 'Job Queue Entry status should be Ready');

        // [THEN] The status of another user's failed job should be changed to Ready
        JobQueueEntry.Reset();
        JobQueueEntry.SetRange(Description, FailedJobQueueEntryNameForAnotherUserLbl);
        if JobQueueEntry.FindFirst() then
            Assert.AreEqual(JobQueueEntry.Status::Error, JobQueueEntry.Status, 'Another user''s Job Queue Entry status should not be affected.');
    end;

    [SendNotificationHandler]
    procedure AdminSingleJobFailedAndRescheduleFromNotificationHandler(var Notification: Notification): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueNotificationMgnt: Codeunit "Job Queue - Send Notification";
    begin
        Assert.AreEqual(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId(), Notification.Id, 'Notification Id is not correct');
        Assert.ExpectedMessage(StrSubstNo(JobQueueNotificationMgnt.GetJobQueueSingleTaskFailedMsg(), LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText()), Notification.Message);
        //[WHEN] Restart the failed job
        JobQueueNotificationMgnt.RestartFailedJob(Notification);
        //[THEN] This status of the failed job should be changed to Ready
        JobQueueEntry.Get(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(JobQueueEntry.Status::Ready, JobQueueEntry.Status, 'Job Queue Entry status should be Ready');
    end;

    [SendNotificationHandler]
    procedure SingleJobFailedAndShowMoreDetailsFromNotificationHandler(var Notification: Notification): Boolean
    var
        JobQueueNotificationMgnt: Codeunit "Job Queue - Send Notification";
    begin
        if JobQueueNotificationMgnt.GetJobQueueFailedNotificationId() <> Notification.Id
        then
            exit(false);
        Assert.AreEqual(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId(), Notification.Id, 'Notification Id is not correct');
        Assert.ExpectedMessage(StrSubstNo(JobQueueNotificationMgnt.GetJobQueueSingleTaskFailedMsg(), LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText()), Notification.Message);
        //[WHEN] Click on the show more details action
        JobQueueNotificationMgnt.ShowMoreDetailForSingleFailedJob(Notification);
    end;

    [SendNotificationHandler]
    procedure MultiJobsFailedAndShowMoreDetailsFromNotificationHandler(var Notification: Notification): Boolean
    var
        JobQueueNotificationMgnt: Codeunit "Job Queue - Send Notification";
    begin
        Assert.AreEqual(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId(), Notification.Id, 'Notification Id is not correct');
        Assert.ExpectedMessage(StrSubstNo(JobQueueNotificationMgnt.GetJobQueueMultipleTaskFailedMsg(), LibraryVariableStorage.DequeueText()), Notification.Message);
        //[WHEN] Click on the show more details action
        JobQueueNotificationMgnt.ShowMoreDetailForMultipleFailedJobs(Notification);
    end;

    [SendNotificationHandler]
    procedure MultiJobsFailedNotificationHandler(var Notification: Notification): Boolean
    var
        JobQueueNotificationMgnt: Codeunit "Job Queue - Send Notification";
    begin
        Assert.AreEqual(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId(), Notification.Id, 'Notification Id is not correct');
        Assert.ExpectedMessage(StrSubstNo(JobQueueNotificationMgnt.GetJobQueueMultipleTaskFailedMsg(), LibraryVariableStorage.DequeueText()), Notification.Message);
    end;

    [SendNotificationHandler]
    procedure MultiJobsFailedAndDisableNotificationHandler(var Notification: Notification): Boolean
    var
        MyNotifications: Record "My Notifications";
        JobQueueNotificationMgnt: Codeunit "Job Queue - Send Notification";
    begin
        Assert.AreEqual(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId(), Notification.Id, 'Notification Id is not correct');
        Assert.ExpectedMessage(StrSubstNo(JobQueueNotificationMgnt.GetJobQueueMultipleTaskFailedMsg(), LibraryVariableStorage.DequeueText()), Notification.Message);
        //[WHEN] Disable the notification
        JobQueueNotificationMgnt.DisableNotification(Notification);
        //[THEN] This notification should be disabled
        Assert.IsFalse(MyNotifications.IsEnabled(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId()), 'Notification should have been disabled');
        //[THEN] Set the status back to true otherwise the notification will not be triggered again
        MyNotifications.SetStatus(JobQueueNotificationMgnt.GetJobQueueFailedNotificationId(), true);
    end;

    [ModalPageHandler]
    procedure TestPageCueSetUpHandler(var TestPageCueSetUp: TestPage "Cue Setup End User")
    begin
        // [THEN] The cue set up should be opened, and the settings should be correct. 
        Assert.IsSubstring(TestPageCueSetUp."Field Name".Value(), 'Job Queue - Tasks');
        TestPageCueSetUp.Next();
        Assert.IsSubstring(TestPageCueSetUp."Field Name".Value(), 'Job Queue - Tasks');
        TestPageCueSetUp.Next();
        Assert.IsSubstring(TestPageCueSetUp."Field Name".Value(), 'Job Queue - Tasks');
        Assert.IsFalse(TestPageCueSetUp.Next(), 'There should be only 3 lines in the cue set up.');
    end;
}