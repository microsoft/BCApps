codeunit 136906 "Job Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job WIP To G/L] [Job]
        IsInitialized := false;
    end;

    var
        JobsSetup: Record "Jobs Setup";
        NoSeries: Record "No. Series";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryService: Codeunit "Library - Service";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        GLAccountCap: Label 'GLAcc__No__', Locked = true;
        XJOBTxt: Label 'JOB';
        XJ10Txt: Label 'J10';
        XJ99990Txt: Label 'J99990';
        XJOBWIPTxt: Label 'JOB-WIP', Comment = 'Cashflow is a name of Cash Flow Forecast No. Series.';
        XDefaultJobWIPNoTxt: Label 'WIP0000001', Comment = 'CF stands for Cash Flow.';
        XDefaultJobWIPEndNoTxt: Label 'WIP9999999';
        XJobWIPDescriptionTxt: Label 'Job-WIP';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Reports");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Reports");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        UpdateJobPostingGroup();

        SetJobNoSeries(JobsSetup, NoSeries);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Reports");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler,JobWIPToGLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure JobWIPToGLBeforeJobPostWIPToGL()
    var
        Job: Record Job;
        JobPostingGroup: Record "Job Posting Group";
    begin
        // Test functionality of Job WIP To G/L before running Job Post WIP To G/L.

        // 1. Setup: Create Initial setup for Job. Run Job Calculate WIP.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        CreateInitialSetupForJob(Job);
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // 2. Exercise: Run Job WIP To G/L report.
        RunJobWIPToGL(Job);

        // 3. Verify: Verify blank WIP Amount.
        LibraryReportDataset.LoadDataSetFile();
        JobPostingGroup.Get(Job."Job Posting Group");
        LibraryReportDataset.SetRange(GLAccountCap, JobPostingGroup."Job Costs Applied Account");
        Assert.IsFalse(
          LibraryReportDataset.GetNextRow(), StrSubstNo('No records exist for account:%1', JobPostingGroup."Job Costs Applied Account"));
    end;

    local procedure CreateAndPostJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; JobPlanningLine: Record "Job Planning Line")
    begin
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", JobPlanningLine."No.");
        JobJournalLine.Validate(Quantity, JobPlanningLine.Quantity / 2);  // Use partial Quantity.
        JobJournalLine.Validate("Unit Cost", JobPlanningLine."Unit Cost");
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateInitialSetupForJob(var Job: Record Job): Decimal
    var
        JobWIPMethod: Record "Job WIP Method";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        CreateJobWIPMethod(
          JobWIPMethod, JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"At Completion");
        CreateJobWithWIPMethod(Job, JobWIPMethod.Code);
        CreateJobTask(JobTask, Job, JobTask."Job Task Type"::Posting, JobTask."WIP-Total"::" ");
        CreateJobPlanningLine(JobPlanningLine, JobTask);
        CreateAndPostJobJournalLine(JobJournalLine, JobTask, JobPlanningLine);
        CreateJobTask(JobTask, Job, JobTask."Job Task Type"::Total, JobTask."WIP-Total"::Total);
        exit(JobJournalLine."Total Cost");
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task")
    begin
        // Use Random values for Quantity and Unit Cost because values are not important.
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", LibraryResource.CreateResourceNo());
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(100));
        JobPlanningLine.Validate("Unit Cost", LibraryRandom.RandInt(100));
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobTask(var JobTask: Record "Job Task"; Job: Record Job; JobTaskType: Enum "Job Task Type"; WIPTotal: Option)
    begin
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("Job Task Type", JobTaskType);
        JobTask.Validate("WIP-Total", WIPTotal);
        JobTask.Modify(true);
    end;

    local procedure CreateJobWIPMethod(var JobWIPMethod: Record "Job WIP Method"; RecognizedCosts: Enum "Job WIP Recognized Costs Type"; RecognizedSales: Enum "Job WIP Recognized Sales Type")
    begin
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", RecognizedCosts);
        JobWIPMethod.Validate("Recognized Sales", RecognizedSales);
        JobWIPMethod.Modify(true)
    end;

    local procedure CreateJobWithWIPMethod(var Job: Record Job; WIPMethod: Code[20])
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", WIPMethod);
        Job.Modify(true);
    end;

    local procedure SetJobNoSeries(var JobsSetup: Record "Jobs Setup"; var NoSeries: Record "No. Series")
    begin
        JobsSetup.Get();
        if JobsSetup."Job Nos." = '' then
            if not NoSeries.Get(XJOBTxt) then
                InsertSeries(JobsSetup."Job Nos.", XJOBTxt, XJOBTxt, XJ10Txt, XJ99990Txt, '', '', 10, true)
            else
                JobsSetup."Job Nos." := XJOBTxt;
        if JobsSetup."Job WIP Nos." = '' then
            if not NoSeries.Get(XJOBWIPTxt) then
                InsertSeries(JobsSetup."Job WIP Nos.", XJOBWIPTxt, XJobWIPDescriptionTxt, XDefaultJobWIPNoTxt, XDefaultJobWIPEndNoTxt, '', '', 1, true)
            else
                JobsSetup."Job WIP Nos." := XJOBWIPTxt;
        JobsSetup.Modify();
    end;

    local procedure InsertSeries(var SeriesCode: Code[20]; "Code": Code[20]; Description: Text[30]; StartingNo: Code[20]; EndingNo: Code[20]; LastNumberUsed: Code[20]; WarningNo: Code[20]; IncrementByNo: Integer; ManualNos: Boolean)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Init();
        NoSeries.Code := Code;
        NoSeries.Description := Description;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := ManualNos;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Ending No.", EndingNo);
        NoSeriesLine.Validate("Last No. Used", LastNumberUsed);
        if WarningNo <> '' then
            NoSeriesLine.Validate("Warning No.", WarningNo);
        NoSeriesLine.Validate("Increment-by No.", IncrementByNo);
        NoSeriesLine.Insert(true);

        SeriesCode := Code;
    end;

    local procedure RunJobCalculateWIP(Job: Record Job)
    var
        JobCalculateWIP: Report "Job Calculate WIP";
    begin
        Job.SetRange("No.", Job."No.");
        Clear(JobCalculateWIP);
        JobCalculateWIP.SetTableView(Job);

        // Use Document No. as Job No. because value is not important.
        JobCalculateWIP.InitializeRequest();
        JobCalculateWIP.UseRequestPage(false);
        JobCalculateWIP.Run();
    end;

    local procedure RunJobWIPToGL(Job: Record Job)
    var
        JobWIPToGL: Report "Job WIP To G/L";
    begin
        Job.SetRange("No.", Job."No.");
        Clear(JobWIPToGL);
        JobWIPToGL.SetTableView(Job);
        Commit();
        JobWIPToGL.Run();
    end;

    local procedure UpdateJobPostingGroup()
    var
        JobPostingGroup: Record "Job Posting Group";
    begin
        if JobPostingGroup.FindSet() then
            repeat
                JobPostingGroup.Validate("WIP Costs Account", LibraryERM.CreateGLAccountNo());
                JobPostingGroup.Validate("Job Costs Applied Account", LibraryERM.CreateGLAccountNo());
                JobPostingGroup.Modify(true);
            until JobPostingGroup.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobPostWIPToGLHandler(var JobPostWIPToGL: TestRequestPage "Job Post WIP to G/L")
    begin
        JobPostWIPToGL.ReversalPostingDate.SetValue(Format(WorkDate()));
        JobPostWIPToGL.ReversalDocumentNo.SetValue(Format(LibraryRandom.RandInt(10)));  // Use random Reversal Document No.
        JobPostWIPToGL.UseReversalDate.SetValue(true);
        JobPostWIPToGL.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobWIPToGLRequestPageHandler(var JobWIPtoGLRequestPage: TestRequestPage "Job WIP To G/L")
    begin
        JobWIPtoGLRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobWIPToGLToExcelRequestPageHandler(var JobWIPtoGLRequestPage: TestRequestPage "Job WIP To G/L")
    begin
        JobWIPtoGLRequestPage.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerMultipleResponses(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

