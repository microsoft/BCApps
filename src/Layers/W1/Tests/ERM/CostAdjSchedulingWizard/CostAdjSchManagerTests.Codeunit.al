codeunit 139845 "Cost Adj. Sch. Manager. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShouldCreateAdjCostJobQueueWithCorrectParameters()
    var
        CostAdjSchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
        JobQueueEntry: Record "Job Queue Entry";
        ExpectedDateFormula: DateFormula;
    begin
        // [GIVEN] No existing job queue entries.
        Initialize();

        // [WHEN] Creating an adjust cost job queue.
        CostAdjSchedulingManager.CreateAdjCostJobQueue();

        // [THEN] An adjust cost job queue entry is created starting everyday at 1 AM.
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Adjust Cost - Item Entries");

        Assert.AreEqual(1, JobQueueEntry.Count(), 'Expected only one job queue to have been created.');

        JobQueueEntry.FindFirst();
        Evaluate(ExpectedDateFormula, '<1D>');

        Assert.AreEqual(ExpectedDateFormula, JobQueueEntry."Next Run Date Formula", 'Expected job queue to run every day.');
        Assert.AreEqual(010000T, JobQueueEntry."Starting Time", 'Expected job queue to start at 1 AM.');
        Assert.IsTrue(JobQueueEntry."Recurring Job", 'Expected job queue to be a recurring job.');
        Assert.AreEqual(JobQueueEntry."Report Output Type", JobQueueEntry."Report Output Type"::"None (Processing only)",
            'Expected job queue to be processing only job.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShouldCreatePostInvCostToGLJobQueueWithCorrectParameters()
    var
        CostAdjSchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
        JobQueueEntry: Record "Job Queue Entry";
        ExpectedDateFormula: DateFormula;
    begin
        // [GIVEN] No existing job queue entries.
        Initialize();

        // [WHEN] Creating an post inventory cost job queue.
        CostAdjSchedulingManager.CreatePostInvCostToGLJobQueue();

        // [THEN] A post inventory cost job queue entry is created starting everyday at 2 AM.
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Post Inventory Cost to G/L");

        Assert.AreEqual(1, JobQueueEntry.Count(), 'Expected only one job queue to have been created.');

        JobQueueEntry.FindFirst();
        Evaluate(ExpectedDateFormula, '<1D>');

        Assert.AreEqual(ExpectedDateFormula, JobQueueEntry."Next Run Date Formula", 'Expected job queue to run every day.');
        Assert.AreEqual(020000T, JobQueueEntry."Starting Time", 'Expected job queue to start at 2 AM.');
        Assert.IsTrue(JobQueueEntry."Recurring Job", 'Expected job queue to be a recurring job.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShouldNotCreateAdjCostJobQueueIfItAlreadyExists()
    var
        CostAdjSchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
    begin
        // [GIVEN] An existing adjust cost job queue entry.
        Initialize();
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(
            JobQueueEntry."Object Type to Run"::Report,
            Report::"Adjust Cost - Item Entries",
            BlankRecordId);

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Adjust Cost - Item Entries");
        Assert.AreEqual(1, JobQueueEntry.Count(), 'Expected initial job queue to have been created.');

        // [WHEN] Attempting to create an adjust cost job queue.
        CostAdjSchedulingManager.CreateAdjCostJobQueue();

        // [THEN] No adjust cost job queue is created.
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Adjust Cost - Item Entries");
        Assert.AreEqual(1, JobQueueEntry.Count(), 'Expected no new job queue to have been created.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShouldNotCreatePostInvCostToGLJobQueueIfReportJobQueueAlreadyExists()
    var
        CostAdjSchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
    begin
        // [GIVEN] An existing post inventory cost job queue entry.
        Initialize();
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(
            JobQueueEntry."Object Type to Run"::Report,
            Report::"Post Inventory Cost to G/L",
            BlankRecordId);

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Post Inventory Cost to G/L");
        Assert.AreEqual(1, JobQueueEntry.Count(), 'Expected initial job queue to have been created.');

        // [WHEN] Attempting to create a post inventory cost job queue.
        CostAdjSchedulingManager.CreatePostInvCostToGLJobQueue();

        // [THEN] No post inventory cost job queue is created.
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Post Inventory Cost to G/L");
        Assert.AreEqual(1, JobQueueEntry.Count(), 'Expected no new job queue to have been created.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShouldNotCreatePostInvCostToGLJobQueueIfCodeunitJobQueueAlreadyExists()
    var
        CostAdjSchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
    begin
        // [GIVEN] An existing post inventory cost job queue entry using the codeunit wrapper.
        Initialize();
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(
            JobQueueEntry."Object Type to Run"::Codeunit,
            Codeunit::"Post Inventory Cost to G/L",
            BlankRecordId);

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Post Inventory Cost to G/L");
        Assert.AreEqual(1, JobQueueEntry.Count(), 'Expected initial job queue to have been created.');

        // [WHEN] Attempting to create a post inventory cost job queue.
        CostAdjSchedulingManager.CreatePostInvCostToGLJobQueue();

        // [THEN] No post inventory cost job queue is created.
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Post Inventory Cost to G/L");
        Assert.AreEqual(1, JobQueueEntry.Count(), 'Expected no new job queue to have been created.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure HasAdjCostJobQueueShouldReturnFalseIfNoMatchingJobQueueExists()
    var
        CostAdjSchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
    begin
        // [GIVEN] No existing job queue entries.
        Initialize();

        // [THEN] AdjCostJobQueueExists should return false.
        Assert.IsFalse(CostAdjSchedulingManager.AdjCostJobQueueExists(), 'Expected it to be false.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure HasAdjCostJobQueueShouldReturnTrueIfAMatchingJobQueueExists()
    var
        CostAdjSchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
    begin
        // [GIVEN] An existing adjust cost job queue entry.
        Initialize();
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(
            JobQueueEntry."Object Type to Run"::Report,
            Report::"Adjust Cost - Item Entries",
            BlankRecordId);

        // [THEN] AdjCostJobQueueExists should return true.
        Assert.IsTrue(CostAdjSchedulingManager.AdjCostJobQueueExists(), 'Expected it to be true.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure HasPostInvCostToGLJobQueueShouldReturnFalseIfNoMatchingJobQueueExists()
    var
        CostAdjSchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
    begin
        // [GIVEN] No existing job queue entries.
        Initialize();

        // [THEN] PostInvCostToGLJobQueueExists should return false.
        Assert.IsFalse(CostAdjSchedulingManager.PostInvCostToGLJobQueueExists(), 'Expected it to be false.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure HasPostInvCostToGLJobQueueShouldReturnTrueIfAMatchingReportJobQueueExists()
    var
        CostAdjSchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
    begin
        // [GIVEN] An existing post inventory cost job queue entry.
        Initialize();
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(
            JobQueueEntry."Object Type to Run"::Report,
            Report::"Post Inventory Cost to G/L",
            BlankRecordId);

        // [THEN] AdjCostJobQueueExists should return true.
        Assert.IsTrue(CostAdjSchedulingManager.PostInvCostToGLJobQueueExists(), 'Expected it to be true.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure HasPostInvCostToGLJobQueueShouldReturnTrueIfAMatchingCodeunitJobQueueExists()
    var
        CostAdjSchedulingManager: Codeunit "Cost Adj. Scheduling Manager";
        JobQueueEntry: Record "Job Queue Entry";
        BlankRecordId: RecordId;
    begin
        // [GIVEN] An existing post inventory cost job queue entry using the codeunit wrapper.
        Initialize();
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(
            JobQueueEntry."Object Type to Run"::Codeunit,
            Codeunit::"Post Inventory Cost to G/L",
            BlankRecordId);

        // [THEN] AdjCostJobQueueExists should return true.
        Assert.IsTrue(CostAdjSchedulingManager.PostInvCostToGLJobQueueExists(), 'Expected it to be true.');
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