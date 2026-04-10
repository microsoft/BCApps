codeunit 136356 "UT T Job WIP Entry"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [WIP Entry] [Job]
        IsInitialized := false;
    end;

    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPEntry: Record "Job WIP Entry";
        NoSeries: Record "No. Series";
        JobsSetup: Record "Jobs Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Text001: Label 'Rolling back changes...';
        LibraryRandom: Codeunit "Library - Random";
        LibraryJob: Codeunit "Library - Job";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        IncorrectWIPEntryAmountErr: Label 'Incorrect WIP Entry Amount.';

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionDeleteForJob()
    begin
        Initialize();
        SetUp();

        // Validate that the Job WIP Entry gets deleted.
        JobWIPEntry.DeleteEntriesForJob(Job);
        JobWIPEntry.SetRange("Job No.", Job."No.");
        Assert.IsFalse(JobWIPEntry.FindFirst(), 'Job WIP Entry was not deleted.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRecognizedCostsSalesOnNegativeEntryForOrderJob()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobCalculateWIP: Codeunit "Job Calculate WIP";
        ExpectedCostAmount: Decimal;
        ExpectedSalesAmount: Decimal;
    begin
        // [FEATURE] [Costs/Sales calculation]
        // [SCENARIO 123634] Verify that Recognized Costs/Sales calculation is considered the negative entry for Job in status Order
        Initialize();
        // [GIVEN] Job in status Order with WIP Method for Recognized Costs/Sales calculation
        CreateJobWithWIPMethod(JobTask, Job.Status::Open);
        // [GIVEN] Job Ledger entries for Costs and Sales with negative amount = "X"
        CreateJobLedgerEntries(Job, ExpectedCostAmount, ExpectedSalesAmount, JobTask);
        // [WHEN] Calculate Job WIP
        JobCalculateWIP.JobCalcWIP(Job, WorkDate(), LibraryUtility.GenerateGUID());
        // [THEN] Job WIP Entry is created with negative amount = "X"
        VerifyJobWIPEntryAmount(Job."No.", JobWIPEntry.Type::"Recognized Costs", ExpectedCostAmount);
        VerifyJobWIPEntryAmount(Job."No.", JobWIPEntry.Type::"Recognized Sales", ExpectedSalesAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerMultipleResponses')]
    [Scope('OnPrem')]
    procedure CalcRecognizedCostSalesOnNegativeEntryForCompletedJob()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobCalculateWIP: Codeunit "Job Calculate WIP";
        ExpectedCostAmount: Decimal;
        ExpectedSalesAmount: Decimal;
    begin
        // [FEATURE] [Costs/Sales calculation]
        // [SCENARIO 123634] Verify that Recognized Costs/Sales calculation is considered the negative entry for Job in status Completed
        Initialize();
        // [GIVEN] Job in status Completed with WIP Method for Recognized Costs/Sales calculation
        LibraryVariableStorage.Enqueue(true);
        CreateJobWithWIPMethod(JobTask, Job.Status::Completed);
        // [GIVEN] Job Ledger entries for Costs and Sales with negative amount = "X"
        CreateJobLedgerEntries(Job, ExpectedCostAmount, ExpectedSalesAmount, JobTask);
        // [WHEN] Calculate Job WIP
        LibraryVariableStorage.Enqueue(true);
        JobCalculateWIP.JobCalcWIP(Job, WorkDate(), LibraryUtility.GenerateGUID());
        // [THEN] Job WIP Entry is created with negative amount = "X"
        VerifyJobWIPEntryAmount(Job."No.", JobWIPEntry.Type::"Recognized Costs", ExpectedCostAmount);
        VerifyJobWIPEntryAmount(Job."No.", JobWIPEntry.Type::"Recognized Sales", ExpectedSalesAmount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        JobBatchJobs: Codeunit "Job Batch Jobs";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT T Job WIP Entry");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT T Job WIP Entry");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        JobBatchJobs.SetJobNoSeries(JobsSetup, NoSeries);

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT T Job WIP Entry");
    end;

    local procedure SetUp()
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        if JobWIPEntry.FindLast() then
            JobWIPEntry."Entry No." += 1
        else
            JobWIPEntry."Entry No." := 1;
        JobWIPEntry."Job No." := Job."No.";
        JobWIPEntry.Insert();

        JobWIPEntry.Modify();
    end;

    local procedure TearDown()
    begin
        Clear(Job);
        Clear(JobTask);
        Clear(JobWIPEntry);
        IsInitialized := false;
        asserterror Error(Text001);
    end;

    local procedure CreateJobLedgerEntries(var Job: Record Job; var ExpectedCostAmount: Decimal; var ExpectedSalesAmount: Decimal; JobTask: Record "Job Task")
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        Job.Get(JobTask."Job No.");
        ExpectedCostAmount := CreateJobLedgEntry(JobTask, JobLedgerEntry."Entry Type"::Usage);
        ExpectedSalesAmount := CreateJobLedgEntry(JobTask, JobLedgerEntry."Entry Type"::Sale);
    end;

    local procedure CreateJobWithWIPMethod(var JobTask: Record "Job Task"; JobStatus: Enum "Job Status")
    var
        Job: Record Job;
        JobWIPMethod: Record "Job WIP Method";
        JobCard: TestPage "Job Card";
    begin
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)");
        JobWIPMethod.Modify(true);
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Modify(true);
        JobCard.OpenEdit();
        JobCard.GotoRecord(Job);
        JobCard.Status.SetValue(JobStatus);
        JobCard.Close();
        Job.Get(Job."No.");

        LibraryJob.CreateJobTask(Job, JobTask);
        UpdateJobPostingGroup(Job."Job Posting Group");
    end;

    local procedure CreateJobLedgEntry(JobTask: Record "Job Task"; EntryType: Enum "Job Journal Line Entry Type"): Decimal
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(JobLedgerEntry);
        JobLedgerEntry.Init();
        JobLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, JobLedgerEntry.FieldNo("Entry No."));
        JobLedgerEntry."Posting Date" := WorkDate();
        JobLedgerEntry."Job No." := JobTask."Job No.";
        JobLedgerEntry."Job Task No." := JobTask."Job Task No.";
        JobLedgerEntry."Entry Type" := EntryType;
        JobLedgerEntry."Line Amount (LCY)" := -LibraryRandom.RandDec(100, 2);
        JobLedgerEntry."Total Cost (LCY)" := JobLedgerEntry."Line Amount (LCY)";
        JobLedgerEntry.Insert();
        exit(JobLedgerEntry."Total Cost (LCY)");
    end;

    local procedure UpdateJobPostingGroup(JobPostingGroupCode: Code[20])
    var
        JobPostingGroup: Record "Job Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        JobPostingGroup.Get(JobPostingGroupCode);
        JobPostingGroup.Validate("WIP Invoiced Sales Account", GLAccount."No.");
        JobPostingGroup.Validate("Job Sales Applied Account", GLAccount."No.");
        JobPostingGroup.Modify(true);
    end;

    local procedure VerifyJobWIPEntryAmount(JobNo: Code[20]; ExpectedType: Enum "Job WIP Buffer Type"; ExpectedAmount: Decimal)
    var
        JobWIPEntry: Record "Job WIP Entry";
    begin
        JobWIPEntry.SetRange("Job No.", JobNo);
        JobWIPEntry.SetRange(Type, ExpectedType);
        JobWIPEntry.CalcSums("WIP Entry Amount");
        Assert.AreEqual(ExpectedAmount, JobWIPEntry."WIP Entry Amount", IncorrectWIPEntryAmountErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerMultipleResponses(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

