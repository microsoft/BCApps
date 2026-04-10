codeunit 139846 "Cost Adj. Sch. Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        DidCheckAdjustCost: Boolean;
        DidCheckPostToGL: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShouldBeAbleToCreateAndScheduleJobQueues()
    var
        Wizard: TestPage "Cost Adj. Scheduling Wizard";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [GIVEN] No existing job queue entries.
        Initialize();

        // [WHEN] Opening the wizard and creating two job queues, one for cost adjustment and one for cost posting.
        Wizard.OpenView();
        Wizard.ActionNext.Invoke();
        Wizard.CreateCostAdjSchedule.SetValue(true);
        Wizard.CreatePostToGLSchedule.SetValue(true);
        Wizard.ActionNext.Invoke();
        Wizard.ActionFinish.Invoke();

        // [THEN] Two job queue entries are created, one for cost adjustment and one for cost posting.
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Adjust Cost - Item Entries");
        Assert.AreEqual(1, JobQueueEntry.Count(), 'Expected job queue to be created.');

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Post Inventory Cost to G/L");
        Assert.AreEqual(1, JobQueueEntry.Count(), 'Expected job queue to be created.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShouldShowReadonlyVariantOfCostAdjScheduleOptionIfJobQueueAlreadyExists()
    var
        Wizard: TestPage "Cost Adj. Scheduling Wizard";
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
    begin
        // [GIVEN] When a job queue entry exist for cost adjustment.
        Initialize();
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(
            JobQueueEntry."Object Type to Run"::Report,
            Report::"Adjust Cost - Item Entries",
            BlankRecordId);

        // [WHEN] When opening the wizard and going to the job queue entry selection.
        Wizard.OpenView();
        Wizard.ActionNext.Invoke();

        // [THEN] The cost adjustment selection is disabled.
        Assert.IsFalse(Wizard.CreateCostAdjSchedule.Enabled(), 'Expected CreateCostAdjSchedule to be disabled.');
        Assert.IsTrue(Wizard.CreatePostToGLSchedule.Enabled(), 'Expected CreatePostToGLSchedule to be enabled.');

        // Cleanup.
        Wizard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShouldShowReadonlyVariantOfPostToGLScheduleOptionIfJobQueueAlreadyExists()
    var
        Wizard: TestPage "Cost Adj. Scheduling Wizard";
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
    begin
        // [GIVEN] When a job queue entry exist for cost posting.
        Initialize();
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(
            JobQueueEntry."Object Type to Run"::Codeunit,
            Codeunit::"Post Inventory Cost to G/L",
            BlankRecordId);

        // [WHEN] When opening the wizard and going to the job queue entry selection.
        Wizard.OpenView();
        Wizard.ActionNext.Invoke();

        // [THEN] The cost posting selection is disabled.
        Assert.IsTrue(Wizard.CreateCostAdjSchedule.Enabled(), 'Expected CreateCostAdjSchedule to be enabled.');
        Assert.IsFalse(Wizard.CreatePostToGLSchedule.Enabled(), 'Expected CreatePostToGLSchedule to be disabled.');

        // Cleanup.
        Wizard.Close();
    end;

    [Test]
    [HandlerFunctions('JobQueueEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShouldOpenJobQueueEntriesForCreatedJobQueuesIfOptionSelected()
    var
        Wizard: TestPage "Cost Adj. Scheduling Wizard";
    begin
        // [GIVEN] No existing job queue entries.
        Initialize();

        // [WHEN] Creating two job queues, one for cost adjustment and one for cost posting and
        //  selecting the option to open the job queue list after finishing the wizard.
        Wizard.OpenView();
        Wizard.ActionNext.Invoke();
        Wizard.CreateCostAdjSchedule.SetValue(true);
        Wizard.CreatePostToGLSchedule.SetValue(true);
        Wizard.ActionNext.Invoke();
        Wizard.OpenJobQueueListAfterFinish.SetValue(true);
        Wizard.ActionFinish.Invoke();

        // [THEN] The job queue entries page is opened with a filter that only shows the two created job queues.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure JobQueueEntriesPageHandler(var JobQueueEntries: TestPage "Job Queue Entries")

    begin
        DidCheckAdjustCost := false;
        DidCheckPostToGL := false;

        JobQueueEntries.First();
        AssertIsCreatedJobQueue(JobQueueEntries);

        JobQueueEntries.Next();
        AssertIsCreatedJobQueue(JobQueueEntries);

        Assert.IsFalse(JobQueueEntries.Next(), 'Expected to only show two created job queues.');
        Assert.IsTrue(DidCheckAdjustCost and DidCheckPostToGL, 'Expected both types of job queues.');
    end;

    local procedure AssertIsCreatedJobQueue(JobQueueEntries: TestPage "Job Queue Entries")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntries."Object Type to Run".AsInteger() = JobQueueEntry."Object Type to Run"::Report then begin
            Assert.AreEqual(Report::"Adjust Cost - Item Entries", JobQueueEntries."Object ID to Run".AsInteger(),
                'Expected job queue for adjust cost.');
            DidCheckAdjustCost := true;
        end
        else begin
            Assert.AreEqual(Codeunit::"Post Inventory Cost to G/L", JobQueueEntries."Object ID to Run".AsInteger(),
                'Expected job queue for post inventory.');
            DidCheckPostToGL := true;
        end;

    end;

    local procedure Initialize()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Adjust Cost - Item Entries");
        JobQueueEntry.DeleteAll();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Post Inventory Cost to G/L");
        JobQueueEntry.DeleteAll();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Post Inventory Cost to G/L");
        JobQueueEntry.DeleteAll();
    end;
}