codeunit 136355 "UT T Job WIP Warning"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [WIP Warning] [Job]
        IsInitialized := false;
    end;

    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPTotal: Record "Job WIP Total";
        JobWIPWarning: Record "Job WIP Warning";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Text001: Label 'Rolling back changes...';
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT T Job WIP Warning");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT T Job WIP Warning");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT T Job WIP Warning");
    end;

    [Normal]
    local procedure SetUp()
    var
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        JobWIPTotal.Init();
        JobWIPTotal."Job No." := Job."No.";
        JobWIPTotal."Job Task No." := JobTask."Job Task No.";
        JobWIPTotal."Contract (Total Price)" := 0;
        JobWIPTotal."Schedule (Total Cost)" := 0;
        JobWIPTotal."Schedule (Total Price)" := 0;
        JobWIPTotal."Usage (Total Cost)" := 1;
        JobWIPTotal.Insert();
    end;

    [Normal]
    local procedure TearDown()
    begin
        Clear(Job);
        Clear(JobTask);
        Clear(JobWIPWarning);
        asserterror Error(Text001);
        IsInitialized := false;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreation()
    begin
        Initialize();
        SetUp();

        // Validate that the generated Job WIP Entry generates 4 warnings.
        JobWIPWarning.CreateEntries(JobWIPTotal);
        JobWIPWarning.SetRange("Job No.", Job."No.");
        JobWIPWarning.SetRange("Job Task No.", JobTask."Job Task No.");
        Assert.AreEqual(4, JobWIPWarning.Count, 'The Job WIP Warning CreatEntries function did not create 4 warning messages.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionsDeleteEntries()
    begin
        Initialize();
        SetUp();

        // Validate that the generated Job WIP Warnings are deleted when the Job WIP Entry is deleted.
        JobWIPWarning.CreateEntries(JobWIPTotal);
        JobWIPWarning.DeleteEntries(JobWIPTotal);
        JobWIPWarning.SetRange("Job WIP Total Entry No.", JobWIPTotal."Entry No.");
        Assert.IsTrue(JobWIPWarning.IsEmpty, 'The Job WIP Warnings were not deleted when the DeleteEntries function was run.');

        TearDown();
    end;
}

