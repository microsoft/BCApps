codeunit 136352 "UT T Job Task Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [UT]
        IsInitialized := false;
    end;

    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Text001: Label 'Rolling back changes...';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        IsInitialized: Boolean;
        CannotModifyJobTaskErr: Label 'The Project Task cannot be modified because the project has associated project WIP entries.';

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletion()
    var
        JobWIPTotal: Record "Job WIP Total";
    begin
        Initialize();
        SetUp();

        // Verify that a Job Task can be deleted and that all Job Planning Lines and Job WIP Totals are deleted as well.
        JobWIPTotal.Init();
        JobWIPTotal."Job No." := Job."No.";
        JobWIPTotal."Job Task No." := JobTask."Job Task No.";
        JobWIPTotal.Insert();

        Assert.IsTrue(JobTask.Delete(true), 'The Job Task could not be deleted.');
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobWIPTotal.SetRange("Job No.", JobTask."Job No.");
        JobWIPTotal.SetRange("Job Task No.", JobTask."Job Task No.");
        JobWIPTotal.SetRange("Posted to G/L", false);
        Assert.IsFalse(JobPlanningLine.FindFirst(), 'Job Planning Lines still exist after deletion of Record.');
        Assert.IsFalse(JobWIPTotal.FindFirst(), 'Job WIP Totals still exist after deletion of Record.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModificationNotBlockedByJobWIPEntry()
    begin
        // [SCENARIO 253648] When Job WIP Entry exists, Job Task can be edit for allowed field.
        Initialize();
        SetUp();

        // Verify that a Job Task can be modified:
        JobTask.Description := LibraryUtility.GenerateGUID();
        JobTask.Modify();

        // Verify that a Job Task can't be modified, when Job WIP Entries exist for the Job.
        MockWIPEntry(Job."No.");
        JobTask.Description := LibraryUtility.GenerateGUID();
        JobTask.Modify();

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModificationBlockedByJobWIPEntry_JobTaskType()
    begin
        // [SCENARIO 253648] When Job WIP Entry exists, "Job Task Type" field cannot be edit.
        Initialize();

        // Job with Job Task
        SetUp();

        // Verify that "Job Task Type" can be modified
        JobTask."Job Task Type" := JobTask."Job Task Type"::"Begin-Total";
        JobTask.Modify();

        // Verify that "Job Task Type" cannot be modified, when the Job WIP Entry exist for the Job.
        MockWIPEntry(JobTask."Job No.");
        JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
        asserterror JobTask.Modify(true);
        Assert.ExpectedError(CannotModifyJobTaskErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModificationBlockedByJobWIPEntry_WIPTotal()
    begin
        // [SCENARIO 253648] When Job WIP Entry exists, "WIP-Total" field cannot be edit.
        Initialize();

        // Job with Job Task
        SetUp();

        // Verify that "WIP-Total" can be modified
        JobTask."WIP-Total" := JobTask."WIP-Total"::Excluded;
        JobTask.Modify();

        // Verify that "WIP-Total" cannot be modified, when the Job WIP Entry exist for the Job.
        MockWIPEntry(JobTask."Job No.");
        JobTask."WIP-Total" := JobTask."WIP-Total"::Total;
        asserterror JobTask.Modify(true);
        Assert.ExpectedError(CannotModifyJobTaskErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModificationBlockedByJobWIPEntry_JobPostingGroup()
    begin
        // [SCENARIO 253648] When Job WIP Entry exists, "Job Posting Group" field cannot be edit.
        Initialize();

        // Job with Job Task
        SetUp();

        // Verify that "Job Posting Group" can be modified
        JobTask."Job Posting Group" := LibraryUtility.GenerateGUID();
        JobTask.Modify();

        // Verify that "Job Posting Group" cannot be modified, when the Job WIP Entry exist for the Job.
        MockWIPEntry(JobTask."Job No.");
        JobTask."Job Posting Group" := LibraryUtility.GenerateGUID();
        asserterror JobTask.Modify(true);
        Assert.ExpectedError(CannotModifyJobTaskErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModificationBlockedByJobWIPEntry_WIPMethod()
    begin
        // [SCENARIO 253648] When Job WIP Entry exists, "WIP Method" field cannot be edit.
        Initialize();

        // Job with Job Task
        SetUp();

        // Verify that "WIP Method" can be modified
        JobTask."WIP Method" := LibraryUtility.GenerateGUID();
        JobTask.Modify();

        // Verify that "WIP Method" cannot be modified, when the Job WIP Entry exist for the Job.
        MockWIPEntry(JobTask."Job No.");
        JobTask."WIP Method" := LibraryUtility.GenerateGUID();
        asserterror JobTask.Modify(true);
        Assert.ExpectedError(CannotModifyJobTaskErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModificationBlockedByJobWIPEntry_Totaling()
    begin
        // [SCENARIO 253648] When Job WIP Entry exists, "Totaling" field cannot be edit.
        Initialize();

        // Job with Job Task
        SetUp();

        // Verify that "Totaling" can be modified
        JobTask.Totaling := LibraryUtility.GenerateGUID();
        JobTask.Modify();

        // Verify that "Totaling" cannot be modified, when the Job WIP Entry exist for the Job.
        MockWIPEntry(JobTask."Job No.");
        JobTask.Totaling := LibraryUtility.GenerateGUID();
        asserterror JobTask.Modify(true);
        Assert.ExpectedError(CannotModifyJobTaskErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModificationSkippedVerifyJobWIPEntryForTempTable()
    var
        Job: Record Job;
        TempJobTask: Record "Job Task" temporary;
    begin
        // [SCENARIO 253648] When Job WIP Entry exists, temporary record of "Job Task" can be modified.
        Initialize();

        // Job with temporary Job Task
        LibraryJob.CreateJob(Job);
        TempJobTask."Job No." := Job."No.";
        TempJobTask."Job Task No." := LibraryUtility.GenerateGUID();
        TempJobTask.Insert();

        // Verify that both "Totaling" and "Description" can be modified
        TempJobTask.Description := LibraryUtility.GenerateGUID();
        TempJobTask.Totaling := LibraryUtility.GenerateGUID();
        TempJobTask.Modify();

        // Verify that both "Totaling" and "Description" can be modified when the Job WIP Entry exist for the Job.
        MockWIPEntry(Job."No.");
        TempJobTask.Description := LibraryUtility.GenerateGUID();
        TempJobTask.Totaling := LibraryUtility.GenerateGUID();
        TempJobTask.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameBlockedByJobWIPEntry()
    var
        Value: array[2] of Code[20];
    begin
        // [SCENARIO 253648] When Job WIP Entry exists, Job Task cannot be renamed.
        Initialize();
        SetUp();

        Value[1] := LibraryUtility.GenerateGUID();
        Value[2] := LibraryUtility.GenerateGUID();

        // Verify that the Job Task can be renamed
        JobTask.Find();
        JobTask.Rename(Job."No.", Value[1]);

        // WIP Entry created for Job and Job Task
        MockWIPEntry(Job."No.");

        // Verify that the Job Task can't be renamed when the Job WIP Entry exist for the Job.
        asserterror JobTask.Rename(Job."No.", Value[2]);
        Assert.ExpectedError(CannotModifyJobTaskErr);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameSkippedVerifyJobWIPEntryForTempTable()
    var
        Job: Record Job;
        TempJobTask: Record "Job Task" temporary;
        Value: array[2] of Code[20];
    begin
        // [SCENARIO 253648] When Job WIP Entry exists, temporary record of "Job Task" can be renamed.
        Initialize();

        // Job with temporary Job Task
        LibraryJob.CreateJob(Job);
        TempJobTask."Job No." := Job."No.";
        TempJobTask."Job Task No." := LibraryUtility.GenerateGUID();
        TempJobTask.Insert();

        Value[1] := LibraryUtility.GenerateGUID();
        Value[2] := LibraryUtility.GenerateGUID();

        // Verify that the temporary record "Job Task" can be renamed
        TempJobTask.Rename(Job."No.", Value[1]);
        TempJobTask.TestField("Job Task No.", Value[1]);

        // WIP Entry created for Job and Job Task
        MockWIPEntry(Job."No.");

        // Verify that the temporary record "Job Task" can be renamed when the Job WIP Entry exist for the Job.
        TempJobTask.Rename(Job."No.", Value[2]);
        TempJobTask.TestField("Job Task No.", Value[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJobTaskType()
    begin
        Initialize();
        SetUp();
        // Prepare Job Task for later tests.
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Excluded);
        Assert.IsTrue(JobTask."Job Posting Group" <> '', 'Job Posting Group is not initalized with a Job Posting Group');
        // Verify that Job Task Type can't be modified when Job Planning Lines exist.
        asserterror JobTask.Validate("Job Task Type", JobTask."Job Task Type"::Total);
        // Verify that Job Task Type can be modified when no Job Planning Lines / Job Ledger Entries exist.
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.DeleteAll(true);
        JobTask.Validate("Job Task Type", JobTask."Job Task Type"::Total);
        Assert.AreEqual(JobTask."Job Task Type"::Total, JobTask."Job Task Type", 'Job Task Type was not set even if no Job Planning Lines existed.');
        Assert.IsTrue(
          JobTask."Job Posting Group" = '', 'Job Posting Group is not blanked when Type is set to something different then Posting');
        Assert.IsTrue(JobTask."WIP-Total" = JobTask."WIP-Total"::" ", 'WIP-Total is not blanked when Type is set to something different then Posting');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldWIPTotal()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        Initialize();
        SetUp();

        // Validate that WIP Method is set correctly when WIP-Total is defined.
        JobWIPMethod.FindFirst();
        Job."WIP Method" := JobWIPMethod.Code;
        Job.Modify();
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        Assert.AreEqual(JobWIPMethod.Code, JobTask."WIP Method", 'WIP Method is not defaulted correctly when WIP Total is set to Total.');

        // Validate that WIP Method is cleared when WIP-Total is set to Excluded.
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Excluded);
        Assert.AreEqual('', JobTask."WIP Method", 'WIP Method is not cleared when WIP Total is set to Excluded.');

        // Validate that WIP Method is cleared when WIP-Total is cleared.
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        Assert.AreEqual(JobWIPMethod.Code, JobTask."WIP Method", 'WIP Method is not defaulted correctly when WIP Total is set to Total.');
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::" ");
        Assert.AreEqual('', JobTask."WIP Method", 'WIP Method is not cleared when WIP Total is cleared.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldWIPMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        Initialize();
        SetUp();

        // Verify that WIP Method can be changed when WIP-Total is total.
        JobWIPMethod.FindFirst();
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethod.Code);
        Assert.AreEqual(JobWIPMethod.Code, JobTask."WIP Method", 'WIP Method cant be changed, even if WIP Total is total.');

        // Verify that WIP Method can't be set when WIP-Total is different from Total.
        JobWIPMethod.FindLast();
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::" ");
        asserterror JobTask.Validate("WIP Method", JobWIPMethod.Code);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldRemainingTotalCost()
    var
        JobPlanningLineSet: Record "Job Planning Line";
        RemainingTotalCost: Decimal;
    begin
        Initialize();
        SetUp();

        JobPlanningLineSet.SetRange("Job No.", Job."No.");
        JobPlanningLineSet.SetRange("Job Task No.", JobTask."Job Task No.");
        if JobPlanningLineSet.FindSet() then
            repeat
                RemainingTotalCost += JobPlanningLineSet."Remaining Total Cost (LCY)";
            until JobPlanningLineSet.Next() = 0;

        JobTask.CalcFields("Remaining (Total Cost)");
        Assert.AreEqual(RemainingTotalCost, JobTask."Remaining (Total Cost)", 'Remaining (Total Cost) does not have the correct value.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldRemainingTotalPrice()
    var
        JobPlanningLineSet: Record "Job Planning Line";
        RemainingTotalPrice: Decimal;
    begin
        Initialize();
        SetUp();

        JobPlanningLineSet.SetRange("Job No.", Job."No.");
        JobPlanningLineSet.SetRange("Job Task No.", JobTask."Job Task No.");
        if JobPlanningLineSet.FindSet() then
            repeat
                RemainingTotalPrice += JobPlanningLineSet."Remaining Line Amount (LCY)";
            until JobPlanningLineSet.Next() = 0;

        JobTask.CalcFields("Remaining (Total Price)");
        Assert.AreEqual(
          RemainingTotalPrice, JobTask."Remaining (Total Price)", 'Remaining (Total Price) does not have the correct value.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionInitWIPFields()
    var
        JobWIPMethod: Record "Job WIP Method";
        JobWIPTotal: Record "Job WIP Total";
    begin
        Initialize();
        SetUp();

        // Test that InitWIPFields initalizes all fields correctly.
        JobWIPMethod.FindFirst();
        JobTask."Recognized Sales Amount" := 1;
        JobTask."Recognized Costs Amount" := 1;
        JobTask.Modify();

        JobWIPTotal.Init();
        JobWIPTotal."Job No." := Job."No.";
        JobWIPTotal."Job Task No." := JobTask."Job Task No.";
        JobWIPTotal."WIP Posting Date" := WorkDate();
        JobWIPTotal."WIP Method" := JobWIPMethod.Code;
        JobWIPTotal."Schedule (Total Cost)" := 1;
        JobWIPTotal."Schedule (Total Price)" := 1;
        JobWIPTotal."Usage (Total Cost)" := 1;
        JobWIPTotal."Usage (Total Price)" := 1;
        JobWIPTotal."Contract (Total Cost)" := 1;
        JobWIPTotal."Contract (Total Price)" := 1;
        JobWIPTotal."Contract (Invoiced Price)" := 1;
        JobWIPTotal."Contract (Invoiced Cost)" := 1;
        JobWIPTotal."WIP Posting Date Filter" := 'test';
        JobWIPTotal."WIP Planning Date Filter" := 'test';
        JobWIPTotal."Calc. Recog. Costs Amount" := 1;
        JobWIPTotal."Calc. Recog. Sales Amount" := 1;
        JobWIPTotal."Cost Completion %" := 1;
        JobWIPTotal."Invoiced %" := 1;
        JobWIPTotal.Insert();

        JobWIPTotal.SetRange("Job No.", Job."No.");
        JobWIPTotal.SetRange("Job Task No.", JobTask."Job Task No.");
        JobWIPTotal.SetRange("Posted to G/L", false);
        Assert.IsTrue(JobWIPTotal.FindFirst(), 'Job WIP Total does not exist for the Job Task Line');

        JobTask.InitWIPFields();

        Assert.AreEqual(0, JobTask."Recognized Sales Amount", 'Field initalized wrongly.');
        Assert.AreEqual(0, JobTask."Recognized Costs Amount", 'Field initalized wrongly.');

        Assert.IsFalse(JobWIPTotal.FindFirst(), 'Job WIP Total does still exist for the Job Task Line');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ApplyPurchLineFilters()
    var
        PurchaseLine: Record "Purchase Line";
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // [FEATURE] [UT] [Job Task] [Purchase Line]
        // [SCENARIO 265274] ApplyPurchLineFilters returns PurchaseLine rec filtered for Order, Job No., Job Task No.
        Initialize();

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        JobTask.ApplyPurchaseLineFilters(PurchaseLine, JobTask."Job No.", JobTask."Job Task No.");

        Assert.AreEqual(JobTask."Job No.", PurchaseLine.GetFilter("Job No."), 'Filter for Job No. is expected');
        Assert.AreEqual(JobTask."Job Task No.", PurchaseLine.GetFilter("Job Task No."), 'Filter for Job Task No. is expected');
        Assert.AreEqual(
          Format(PurchaseLine."Document Type"::Order),
          PurchaseLine.GetFilter("Document Type"),
          'Filter for Order Document Type is expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ApplyPurchLineFilters_Totaling()
    var
        PurchaseLine: Record "Purchase Line";
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // [FEATURE] [UT] [Job Task] [Purchase Line]
        // [SCENARIO 265274] ApplyPurchLineFilters returns PurchaseLine rec filtered for Order, Job No., Job Task No. = JobTask.Totaling
        Initialize();

        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
        JobTask.Totaling := LibraryUtility.GenerateGUID();
        JobTask.Modify();

        JobTask.ApplyPurchaseLineFilters(PurchaseLine, JobTask."Job No.", JobTask."Job Task No.");

        Assert.AreEqual(JobTask."Job No.", PurchaseLine.GetFilter("Job No."), 'Filter for Job No. is expected');
        Assert.AreEqual(JobTask.Totaling, PurchaseLine.GetFilter("Job Task No."), 'Filter for Totaling is expected');
        Assert.AreEqual(
          Format(PurchaseLine."Document Type"::Order),
          PurchaseLine.GetFilter("Document Type"),
          'Filter for Order Document Type is expected');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT T Job Task Line");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT T Job Task Line");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT T Job Task Line");
    end;

    local procedure SetUp()
    var
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify();

        LibraryJob.CreateJobTask(Job, JobTask);

        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
    end;

    local procedure TearDown()
    begin
        Clear(Job);
        Clear(JobTask);
        Clear(JobPlanningLine);
        asserterror Error(Text001);
        IsInitialized := false;
    end;

    local procedure MockWIPEntry(JobNo: Code[20])
    var
        JobWIPEntry: Record "Job WIP Entry";
    begin
        JobWIPEntry."Entry No." := LibraryUtility.GetNewRecNo(JobWIPEntry, JobWIPEntry.FieldNo("Entry No."));
        JobWIPEntry."Job No." := JobNo;
        JobWIPEntry.Insert();
        JobWIPEntry.Modify();
    end;
}

