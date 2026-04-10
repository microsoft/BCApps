codeunit 136310 "Job Batch Jobs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job]
        IsInitialized := false;
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        NoSeries: Record "No. Series";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        CreditMemoError: Label 'Credit Memo must not exist.';
        ThereIsNothingToChangeError: Label 'There is nothing to change.';
        TotalAmountError: Label 'Total amount must be equal.';
        SalesLineMustNotExistError: Label 'Sales Line must not exist.';
        UnknownError: Label 'Unknown Error';
        SalesInvoiceExistErr: Label '%1 should be empty.';
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CancelJobTransferToCreditMemo: Boolean;
        ChangeCurrencyDate: Boolean;
        ChangePlanningDate: Boolean;
        CreateNewCreditMemo: Boolean;
        IsInitialized: Boolean;
        AppendSalesInvoice: Boolean;
        ReverseOnly: Boolean;
        IncludeLineType: Option " ",Budget,Billable,"Budget+Billable";
        PostingDate: Date;
        NewRelationalExchangeRateAmount: Decimal;
        SalesLineTransferError: Label 'The lines were not transferred to an invoice.';
        JobNoErr: Label 'The field Project No. of table Project Planning Line Invoice contains a value (%1) that cannot be found in the related table (Project).';
        JobTaskNoErr: Label 'The field Project Task No. of table Project Planning Line Invoice contains a value (%1) that cannot be found in the related table (Project Task).';
        LineNoErr: Label 'The field Project Planning Line No. of table Project Planning Line Invoice contains a value (%1) that cannot be found in the related table (Project Planning Line).';
        WrongValueErr: Label 'Wrong value for field %1';
        XJOBTxt: Label 'PROJECT';
        XJ10Txt: Label 'J10';
        XJ99990Txt: Label 'J99990';
        XJOBWIPTxt: Label 'PROJECT-WIP', Comment = 'Cashflow is a name of Cash Flow Forecast No. Series.';
        XDefaultJobWIPNoTxt: Label 'WIP0000001', Comment = 'CF stands for Cash Flow.';
        XDefaultJobWIPEndNoTxt: Label 'WIP9999999';
        XJobWIPDescriptionTxt: Label 'PROJECT-WIP';
        LineDiscountErr: Label 'Value in Line Discount % must not be removed.';
        PostingDateErr: Label 'Posting Date should be updated.';

    [Test]
    [HandlerFunctions('ChangeJobDatesHandler')]
    [Scope('OnPrem')]
    procedure JobDateReportWithDefaultSetting()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Run Job Date report for Default setting and handle error message.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);

        // 2. Exercise: Run Change Job Dates report.
        asserterror RunChangeJobDates(JobTask."Job Task No.", JobTask."Job No.");  // Handler will be used for this report.

        // 3. Verify: Check the expected ERROR.
        Assert.AreEqual(StrSubstNo(ThereIsNothingToChangeError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ChangeJobDatesHandler')]
    [Scope('OnPrem')]
    procedure JobDateReportWithoutChangeCurrencyAndPlanningDateForSchedule()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Run Job Date report for false setting of change Currency and Planning date for include Line Type Budget and handle error message.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        AssignGlobalVariable(false, false, IncludeLineType::Budget);  // Assign global variables.

        // 2. Exercise: Run Change Job Dates report.
        asserterror RunChangeJobDates(JobTask."Job Task No.", JobTask."Job No.");  // Handler will be used for this report.

        // 3. Verify: Check the expected ERROR.
        Assert.AreEqual(StrSubstNo(ThereIsNothingToChangeError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ChangeJobDatesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobDateReportWithChangeCurrencyAndPlanningDateForSchedule()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Run Job Date report for true setting of change Currency and Planning date for include Line Type Budget and validate Job Planning Line.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        AssignGlobalVariable(true, true, IncludeLineType::Budget);  // Assign global variables.

        // 2. Exercise: Run Change Job Dates report.
        RunChangeJobDates(JobTask."Job Task No.", JobTask."Job No.");  // Handler will be used for this report.

        // 3. Verify: Check Planning Date in Job Planning Line.
        VerifyJobPlanningLine(
          JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line Type"::Budget, JobPlanningLine."No.");
    end;

    [Test]
    [HandlerFunctions('ChangeJobDatesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobDateReportWithChangeCurrencyAndPlanningDateForContract()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Run Job Date report for true setting of change Currency and Planning date for include Line Type Billable and validate Job Planning Line.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        AssignGlobalVariable(true, true, IncludeLineType::Billable);  // Assign global variables.

        // 2. Exercise: Run Change Job Dates report.
        RunChangeJobDates(JobTask."Job Task No.", JobTask."Job No.");  // Handler will be used for this report.

        // 3. Verify: Check Planning Date in Job Planning Line.
        VerifyJobPlanningLine(
          JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line Type"::Billable, JobPlanningLine."No.");
    end;

    [Test]
    [HandlerFunctions('ChangeJobDatesHandler')]
    [Scope('OnPrem')]
    procedure JobDateReportWithoutChangeCurrencyAndPlanningDateForContract()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Run Job Date report for false setting of change Currency and Planning date for include Line Type Billable and handle error message.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        AssignGlobalVariable(false, false, IncludeLineType::Billable);  // Assign global variables.

        // 2. Exercise: Run Change Job Dates report.
        asserterror RunChangeJobDates(JobTask."Job Task No.", JobTask."Job No.");  // Handler will be used for this report.

        // 3. Verify: Check the expected ERROR.
        Assert.AreEqual(StrSubstNo(ThereIsNothingToChangeError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ChangeJobDatesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobDateReportWithChangeCurrencyAndPlanningDateForBothScheduleAndContract()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Run Job Date report for true setting of change Currency and Planning date for include Line Type Both Budget and Billable and validate Job Planning Line.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        AssignGlobalVariable(true, true, IncludeLineType::"Budget+Billable");  // Assign global variables.

        // 2. Exercise: Run Change Job Dates report.
        RunChangeJobDates(JobTask."Job Task No.", JobTask."Job No.");  // Handler will be used for this report.

        // 3. Verify: Check Planning Date in Job Planning Line.
        VerifyJobPlanningLine(
          JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line Type"::"Both Budget and Billable",
          JobPlanningLine."No.");
    end;

    [Test]
    [HandlerFunctions('ChangeJobDatesHandler')]
    [Scope('OnPrem')]
    procedure JobDateReportWithoutChangeCurrencyAndPlanningDateForBothScheduleAndContract()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Run Job Date report for false setting of change Currency and Planning date for include Line Type Both Budget and Billable and handle error message.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        AssignGlobalVariable(false, false, IncludeLineType::"Budget+Billable");  // Assign global variables.

        // 2. Exercise: Run Change Job Dates report.
        asserterror RunChangeJobDates(JobTask."Job Task No.", JobTask."Job No.");  // Handler will be used for this report.

        // 3. Verify: Check the expected ERROR.
        Assert.AreEqual(StrSubstNo(ThereIsNothingToChangeError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobCalculateWIPBatch()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Test functionality of Job Calculate WIP batch.

        // 1. Setup: Create Initial setup for Job.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        CreateInitialSetupForJob(Job, JobJournalLine, JobTask."WIP-Total"::" ");

        // 2. Exercise: Run Job Calculate WIP.
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // 3. Verify: Verify Total WIP Cost Amount.
        Assert.AreEqual(JobJournalLine."Total Cost", GetTotalWIPCostAmount(Job), TotalAmountError);
    end;

    [Test]
    [HandlerFunctions('JobPostWIPToGLHandler,ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobPostWIPToGLBatchWithReverseOnlyFalse()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Test functionality of Job Post WIP To G/L batch with ReverseOnly as False.

        // 1. Setup: Create Initial setup for Job. Run Job Calculate WIP.
        Initialize();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryVariableStorage.Enqueue(true);
        CreateInitialSetupForJob(Job, JobJournalLine, JobTask."WIP-Total"::" ");
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // 2. Exercise: Run Job Post WIP To G/L.
        RunJobPostWIPToGL(Job);

        // 3. Verify: Verify Total WIP Cost G/L Amount.
        Assert.AreEqual(JobJournalLine."Total Cost", GetTotalWIPCostGLAmount(Job), TotalAmountError);
    end;

    [Test]
    [HandlerFunctions('JobPostWIPToGLHandler,ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobPostWIPToGLBatchWithReverseOnlyTrue()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Test functionality of Job Post WIP To G/L batch with ReverseOnly as True.

        // 1. Setup: Create Initial setup for Job. Run Job Calculate WIP. Run Job Post WIP To G/L.
        Initialize();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryVariableStorage.Enqueue(true);
        CreateInitialSetupForJob(Job, JobJournalLine, JobTask."WIP-Total"::" ");
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // 2. Exercise: Run Job Post WIP To G/L with Reverse Only as True.
        ReverseOnly := true;  // Use global variable ReverseOnly for JobPostWIPToGLHandler handler function.
        RunJobPostWIPToGL(Job);

        // 3. Verify: Verify Total WIP Cost G/L Amount.
        Assert.AreEqual(0, GetTotalWIPCostGLAmount(Job), TotalAmountError);
    end;

    [Test]
    [HandlerFunctions('JobPostWIPToGLHandler,ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobPostWIPToGLBatchWithChangingPostingGroup()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        GLAccount: Record "G/L Account";
        OldWIPCostsAccount: Code[20];
    begin
        // Test functionality of Job Post WIP To G/L batch with changing Posting Group.

        // 1. Setup: Create Initial setup for Job. Run Job Calculate WIP. Run Job Post WIP To G/L.
        Initialize();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryVariableStorage.Enqueue(true);
        CreateInitialSetupForJob(Job, JobJournalLine, JobTask."WIP-Total"::" ");
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        LibraryVariableStorage.Enqueue(false);
        RunJobPostWIPToGL(Job);

        // 2. Exercise: Create G/L Account and update WIP Costs Account. Run Job Calculate WIP. Run Job Post WIP To G/L.
        LibraryERM.CreateGLAccount(GLAccount);
        OldWIPCostsAccount := UpdateWIPCostsAccount(Job."Job Posting Group", GLAccount."No.");
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // 3. Verify: Verify Job WIP G/L Entry.
        VerifyJobWIPGLEntryWithGLBalAccountNo(Job."No.", OldWIPCostsAccount);
        VerifyJobWIPGLEntryWithGLBalAccountNo(Job."No.", GLAccount."No.");

        // 4. Tear down: Rollback WIP Costs Account changes.
        UpdateWIPCostsAccount(Job."Job Posting Group", OldWIPCostsAccount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobPostWIPToGLBatchWithChangingWIPMethod()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobWIPMethod: Record "Job WIP Method";
        JobCalculateWIP: Codeunit "Job Calculate WIP";
        TotalPrice: Decimal;
    begin
        // Test functionality of Job Calculate WIP batch with changing WIP Method.

        // 1. Setup: Create Initial setup for Job. Run Job Calculate WIP.
        Initialize();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryVariableStorage.Enqueue(true);
        TotalPrice := CreateInitialSetupForJob(Job, JobJournalLine, JobTask."WIP-Total"::" ");
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // 2. Exercise: Delete WIP Entries and change WIP Method on the Job. Run Job Calculate WIP.
        JobCalculateWIP.DeleteWIP(Job);
        LibraryVariableStorage.Enqueue(true);
        CreateJobWIPMethod(
          JobWIPMethod, JobWIPMethod."Recognized Costs"::"Usage (Total Cost)", JobWIPMethod."Recognized Sales"::"Sales Value");
        UpdateWIPMethodOnJob(Job, JobWIPMethod.Code);
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // 3. Verify: Verify Total WIP Sales Amount, Total WIP Cost Amount and Recog. Sales Amount.
        Assert.AreEqual(
          -JobJournalLine."Total Price" * JobJournalLine."Total Price" / TotalPrice, GetTotalWIPSalesAmount(Job), TotalAmountError);
        Assert.AreEqual(0, GetTotalWIPCostAmount(Job), TotalAmountError);
        Assert.AreEqual(
          JobJournalLine."Total Price" * JobJournalLine."Total Price" / TotalPrice, GetRecogSalesAmount(Job), TotalAmountError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobCalculateWIPBatchForExcludingPartOfJob()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Test functionality of Job Calculate WIP batch for excluding part of Job.

        // 1. Setup: Create Initial setup for Job.
        Initialize();
        CreateInitialSetupForJob(Job, JobJournalLine, JobTask."WIP-Total"::Excluded);

        // 2. Exercise: Run Job Calculate WIP.
        RunJobCalculateWIP(Job);

        // 3. Verify: Verify Total WIP Cost Amount.
        Assert.AreEqual(0, GetTotalWIPCostAmount(Job), TotalAmountError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLineAmountLcyOnJobJournalLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        //[506709] [Job Journal Line] [Line Amount LCY]
        // when updating the Line Amount field on the Job Journal Line, the Line Amount (LCY) field must be updated as well.
        Initialize();

        // [GIVEN] Create Job, Job Task
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.Modify();

        // [GIVEN] Create Job Journal Line with Type = G/L Account and random qty, unit cost, unit price
        LibraryJob.CreateJobJournalLineForType(JobJournalLine."Line Type"::" ", JobJournalLine.Type::"G/L Account", JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", LibraryJob.FindConsumable(JobJournalLine.Type));
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));
        JobJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        JobJournalLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));

        // [GIVEN] Line Amount and Line Amount (LCY) must be equal (no currency)
        JobJournalLine.TestField("Line Amount");
        JobJournalLine.TestField("Line Amount (LCY)");
        JobJournalLine.TestField("Currency Code", '');
        Assert.AreNearlyEqual(JobJournalLine."Line Amount", JobJournalLine."Line Amount (LCY)", 0.01, 'Line Amount and Line Amount (LCY) must be equal.');

        // [WHEN] Update Line Amount
        JobJournalLine.Validate("Line Amount", LibraryRandom.RandDec(200, 2));

        // [THEN] Line Amount and Line Amount (LCY) must be equal (no currency)
        Assert.AreNearlyEqual(JobJournalLine."Line Amount", JobJournalLine."Line Amount (LCY)", 0.01, 'Line Amount and Line Amount (LCY) must be equal.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure JobSplitPlanningLine()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Test functionality of Job Split Planning Line.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), CreateResource(), JobTask);

        // 2. Exercise: Run Job Split Planning Line.
        RunJobSplitPlanningLine(JobTask);

        // 3. Verify: Verify Job Planning lines.
        VerifyValuesOnJobPlanningLine(
          JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", LibraryJob.PlanningLineTypeSchedule(), JobPlanningLine.Quantity);
        VerifyValuesOnJobPlanningLine(
          JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", LibraryJob.PlanningLineTypeContract(), JobPlanningLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('JobTransferToPlanningLinesHandler,MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure JobTransferToPlanningLines()
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        LineNo: Integer;
    begin
        // Test functionality of Job Transfer To Planning Lines.

        // 1. Setup: Create Job and Job Task. Create and post Job Journal Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Item, JobTask, JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);
        LineNo := FindLastPlanningLineNo(JobTask);

        // 2. Exercise: Run Job Transfer To Planning Lines.
        RunJobTransferToPlanningLines(JobJournalLine."Document No.");

        // 3. Verify: Verify Transfer Job Planning Line.
        VerifyTransferJobPlanningLine(JobJournalLine, LibraryJob.PlanningLineTypeSchedule(), LineNo);
        VerifyTransferJobPlanningLine(JobJournalLine, LibraryJob.PlanningLineTypeContract(), LineNo);
    end;

    [Test]
    [HandlerFunctions('JobCalcRemainingUsageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobCalcRemainingUsage()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalBatch: Record "Job Journal Batch";
    begin
        // Test functionality of Job Calc. Remaining Usage.

        // 1. Setup: Create Job, Job Task, Job Planning Line and Job Journal Batch.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), CreateResource(), JobTask);
        CreateJobJournalBatch(JobJournalBatch);

        // 2. Exercise: Run Job Calc. Remaining Usage.
        RunJobCalcRemainingUsage(JobJournalBatch, JobTask);

        // 3. Verify: Verify Job Journal Line.
        VerifyJobJournalLine(JobJournalBatch, JobPlanningLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePlanningLineFromPurchaseInvoice()
    var
        JobTask: Record "Job Task";
        Quantity: Decimal;
    begin
        // Test Create Planning Line from Purchase Invoice.

        // 1. Setup: Create Job and Job Task.
        Initialize();
        CreateJobAndJobTask(JobTask);

        // 2. Exercise: Create and post Purchase Invoice.
        Quantity := CreateAndPostPurchaseInvoice(JobTask);

        // 3. Verify: Verify Job Planning Lines.
        VerifyValuesOnJobPlanningLine(JobTask."Job No.", JobTask."Job Task No.", LibraryJob.PlanningLineTypeSchedule(), Quantity);
        VerifyValuesOnJobPlanningLine(JobTask."Job No.", JobTask."Job Task No.", LibraryJob.PlanningLineTypeContract(), Quantity);
    end;

    [Test]
    [HandlerFunctions('JobTransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure JobTransferToCreditMemoWithoutPostingDate()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
    begin
        // Test functionality of Job Transfer To Credit Memo without Posting Date.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), CreateResource(), JobTask);

        // 2. Exercise: Transfer Job to Credit Memo.
        TransferJobToSales(JobPlanningLine, true);  // Use True for Credit Memo.

        // 3. Verify: Credit Memo must not exist.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("Bill-to Customer No.", FindBillToCustomerNo(JobTask."Job No."));
        Assert.IsFalse(SalesHeader.FindFirst(), CreditMemoError);
    end;

    [Test]
    [HandlerFunctions('JobTransferToCreditMemoHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobTransferToCreditMemoWithPostingDate()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
    begin
        // Test functionality of Job Transfer To Credit Memo with Posting Date.

        // 1. Setup: Create Job, Job Task and Job Planning Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), CreateResource(), JobTask);

        // 2. Exercise: Set Posting Date and Transfer Job to Credit Memo.
        PostingDate := WorkDate();  // Set global variable PostingDate.
        CreateNewCreditMemo := true;  // Set global variable CreateNewCreditMemo.
        TransferJobToSales(JobPlanningLine, true);  // Use True for Credit Memo.

        // 3. Verify: Verify Values On Sales Line.
        VerifyValuesOnSalesLineForCreditMemo(
          FindSalesHeader(JobTask."Job No.", SalesHeader."Document Type"::"Credit Memo"), JobPlanningLine);
    end;

    [Test]
    [HandlerFunctions('JobTransferToCreditMemoHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobTransferToCreditMemoWithSetCancel()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test functionality of Job Transfer To Credit Memo with Set Cancel.

        // 1. Setup: Create Job, Job Task and Job Planning Line. Set Posting Date and Transfer Job to Credit Memo.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), CreateResource(), JobTask);
        PostingDate := WorkDate();  // Set global variable PostingDate.
        CreateNewCreditMemo := true;  // Set global variable CreateNewCreditMemo.
        TransferJobToSales(JobPlanningLine, true);  // Use True for Credit Memo.
        CreateJobPlanningLine(JobPlanningLine2, LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), CreateResource(), JobTask);

        // 2. Exercise: Transfer Job to Credit Memo.
        CreateNewCreditMemo := false;  // Set global variable CreateNewCreditMemo.
        CancelJobTransferToCreditMemo := true;  // Set global variable CancelJobTransferToCreditMemo.
        TransferJobToSales(JobPlanningLine2, true);  // Use True for Credit Memo.

        // 3. Verify: Second Job Planning Line must not append to Credit Memo.
        Assert.IsFalse(
          FindSalesLine(
            SalesLine, SalesLine."Document Type"::"Credit Memo",
            FindSalesHeader(JobTask."Job No.", SalesHeader."Document Type"::"Credit Memo"), JobPlanningLine2."No."),
          SalesLineMustNotExistError);
    end;

    [Test]
    [HandlerFunctions('JobTransferToCreditMemoHandler,MessageHandler,SalesListHandler')]
    [Scope('OnPrem')]
    procedure JobTransferToCreditMemoWithoutSetCancel()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
    begin
        // Test functionality of Job Transfer To Credit Memo without Set Cancel.

        // 1. Setup: Create Job, Job Task and Job Planning Line. Set Posting Date and Transfer Job to Credit Memo.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), CreateResource(), JobTask);
        PostingDate := WorkDate();  // Set global variable PostingDate.
        CreateNewCreditMemo := true;  // Set global variable CreateNewCreditMemo.
        TransferJobToSales(JobPlanningLine, true);  // Use True for Credit Memo.
        CreateJobPlanningLine(JobPlanningLine2, LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), CreateResource(), JobTask);

        // 2. Exercise: Transfer Job to Credit Memo.
        CreateNewCreditMemo := false;  // Set global variable CreateNewCreditMemo.
        TransferJobToSales(JobPlanningLine2, true);  // Use True for Credit Memo.

        // 3. Verify: Second Job Planning Line must append to Credit Memo.
        VerifyValuesOnSalesLineForCreditMemo(
          FindSalesHeader(JobTask."Job No.", SalesHeader."Document Type"::"Credit Memo"), JobPlanningLine);
        VerifyValuesOnSalesLineForCreditMemo(
          FindSalesHeader(JobTask."Job No.", SalesHeader."Document Type"::"Credit Memo"), JobPlanningLine2);
    end;

    [Test]
    [HandlerFunctions('JobCreateSalesInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceFromJobTask()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
    begin
        // Test functionality of Job Create Sales Invoice.

        // 1. Setup: Create Job, Job Task and Job planning Line.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), CreateResource(), JobTask);

        // 2. Exercise: Run Job Create Sales Invoice.
        RunJobCreateSalesInvoice(JobTask);

        // 3. Verify: Verify values on Sales Line for invoice.
        VerifyValuesOnSalesLineForInvoice(FindSalesHeader(JobTask."Job No.", SalesHeader."Document Type"::Invoice), JobPlanningLine);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceFromJobPlanningLine()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Create a Sales Invoice for a Job and verify that Total Cost (LCY) must be equal to Invoiced Cost Amount (LCY) on Job Planning Line.

        // 1. Setup: Create Job, Job Task and Job planning Line. Transfer Job to Sales Invoice.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), CreateResource(), JobTask);
        TransferJobToSales(JobPlanningLine, false);  // Use False for Invoice.

        // 2. Exercise: Find and post Sales Invoice.
        FindAndPostSalesInvoice(JobTask."Job No.");

        // 3. Verify: Verify Total Cost (LCY) must be equal to Invoiced Cost Amount (LCY) on Job Planning Line.
        JobPlanningLine.CalcFields("Invoiced Cost Amount (LCY)");
        JobPlanningLine.TestField("Total Cost (LCY)", JobPlanningLine."Invoiced Cost Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,JobTransferToSalesInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LineDiscountAmountOnSalesInvoice()
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        LineAmount: Decimal;
    begin
        // Verify Line Discount Amount on Sales Invoice created from Job Planning Lines.

        // 1. Setup: Create Job, Job Task, Job Journal Line and post it after updating Line Amount.
        Initialize();
        CreateJobAndJobTask(JobTask);
        LineAmount := CreateUpdateAndPostJobJournalLine(JobJournalLine, JobTask);
        FindJobPlanningLine(JobPlanningLine, JobTask);

        // 2. Exercise: Create Sales Invoice from Job Planning Lines.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);  // Use False for Invoice.

        // 3. Verify: Verify Line Discount Amount on Sales Line.
        VerifyLineDiscountAmountOnSalesLine(JobJournalLine."Job No.", LineAmount - JobJournalLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,JobTransferToSalesInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceCreatedFromJobPlanningLine()
    var
        Customer: Record Customer;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        GeneralPostingSetup: Record "General Posting Setup";
        DocumentNo: Code[20];
        LineAmount: Decimal;
    begin
        // Verify posting the Sales Invoice created from Job Planning Lines after updating Line Amount on Job Journal Line and post it.

        // 1. Setup: Create Job, Job Task, Job Journal Line and post it after updating Line Amount.Transfer Job to Sales Invoice.
        Initialize();
        CreateJobAndJobTask(JobTask);
        LineAmount := CreateUpdateAndPostJobJournalLine(JobJournalLine, JobTask);
        FindJobPlanningLine(JobPlanningLine, JobTask);
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);  // Use False for Invoice.
        Customer.Get(FindBillToCustomerNo(JobTask."Job No."));
        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", JobJournalLine."Gen. Prod. Posting Group");

        // 2. Exercise: Find and post Sales Invoice.
        DocumentNo := FindAndPostSalesInvoice(JobTask."Job No.");

        // 3. Verify: Verify values on Job Ledger Entry and G/L Entry.
        VerifyJobLedgerEntry(JobJournalLine, DocumentNo, LineAmount);
        VerifyGLEntry(GeneralPostingSetup."Sales Account", DocumentNo, -LineAmount);
        VerifyGLEntry(GeneralPostingSetup."Sales Line Disc. Account", DocumentNo, LineAmount - JobJournalLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('JobCreateSalesInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceForItemFromJobTask()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
    begin
        // Check functionality of Job Create Sales Invoice with Type Item on Job Planning Line.

        // 1. Setup: Create Job, Job Task and Job planning Line with Item.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), CreateItem(), JobTask);

        // 2. Exercise: Run Job Create Sales Invoice.
        RunJobCreateSalesInvoice(JobTask);

        // 3. Verify: Verify values on Sales Line for Invoice.
        VerifyValuesOnSalesLineForInvoice(FindSalesHeader(JobTask."Job No.", SalesHeader."Document Type"::Invoice), JobPlanningLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountOnJobJournalLine()
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        LineAmount: Decimal;
        DiscountAmount: Decimal;
        FractionValue: Decimal;
    begin
        // Verify Line Amount and Line Discount Amount on Job Journal Line after updating the Line Amount.

        // 1. Setup: Create Job, Job Task.
        Initialize();
        CreateJobAndJobTask(JobTask);

        // 2. Exercise: Create Job Journal Line and update Line Amount and calculate values.
        FractionValue := LibraryUtility.GenerateRandomFraction();
        CreateAndUpdateJobJournalLine(JobJournalLine, JobTask, FractionValue);
        LineAmount := JobJournalLine.Quantity * JobJournalLine."Unit Price" - FractionValue;
        DiscountAmount := Round(JobJournalLine."Line Amount" * JobJournalLine."Line Discount %" / 100);

        // 3. Verify: Verify Line Amount and Line Discount Amount on Job Journal Line.
        Assert.AreNearlyEqual(LineAmount, JobJournalLine."Line Amount", LibraryERM.GetAmountRoundingPrecision(), 'Line Amount must match.');
        Assert.AreNearlyEqual(
          DiscountAmount, JobJournalLine."Line Discount Amount", LibraryERM.GetAmountRoundingPrecision(), 'Line Disc. Amount must match.');
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRatePageHandler,JobTransferToSalesInvoiceHandler,SalesListHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure SalesInvoiceLineWithExchangeRatesConfirmFalse()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
    begin
        // Verify no Sales Invoice Line is created through append functionality on Job Planning Line when click No on the confirmation message.

        // 1. Setup: Create Currency with Exchange Rate, create Job Planning Line with Currency and Sales Invoice Header with Currency. Change Exchange Rate on Sales Invoice.
        Initialize();
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        NewRelationalExchangeRateAmount := CurrencyExchangeRate."Relational Exch. Rate Amount" - LibraryRandom.RandInt(10);  // Modify Relational Exchange Rate field with Random value and assign in Global variable.
        CreateJobPlanningLineWithCurrency(JobPlanningLine, CurrencyExchangeRate."Currency Code");
        ChangeExchangeRateOnSalesInvoice(SalesHeader, JobPlanningLine."Job No.", CurrencyExchangeRate."Currency Code");
        AppendSalesInvoice := true;  // Assign in Global variable.

        // 2. Exercise: Create Sales Invoice Line through Job Planning Line.
        asserterror RunJobCreateInvoice(JobPlanningLine);

        // 3. Verify: Verify Sales Line is not created.
        Assert.ExpectedError(SalesLineTransferError);
    end;

    [Test]
    [HandlerFunctions('ChangeExchangeRatePageHandler,JobTransferToSalesInvoiceHandler,SalesListHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure CurrencyFactorOnJobPlanningLine()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CurrencyFactor: Decimal;
    begin
        // Verify Currency Factor on Job Planning Line and creation of Sales Invoice Line through append functionality on Job Planning Line when click Yes on the confirmation message
        // and Currency Exchange Rate is different between the Sales Invoice and Job Planning Line.

        // 1. Setup: Create Currency with Exchange Rate, create Job Planning Line with Currency and Sales Invoice Header with Currency. Change Exchange Rate on Sales Invoice.
        Initialize();
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        NewRelationalExchangeRateAmount := CurrencyExchangeRate."Relational Exch. Rate Amount" - LibraryRandom.RandInt(10);  // Modify Relational Exchange Rate field with Random value and assign in Global variable.
        CurrencyFactor := CurrencyExchangeRate."Exchange Rate Amount" / NewRelationalExchangeRateAmount;

        CreateJobPlanningLineWithCurrency(JobPlanningLine, CurrencyExchangeRate."Currency Code");
        ChangeExchangeRateOnSalesInvoice(SalesHeader, JobPlanningLine."Job No.", CurrencyExchangeRate."Currency Code");
        AppendSalesInvoice := true;  // Assign in Global variable.

        // 2. Exercise: Create Sales Invoice Line through Job Planning Line.
        RunJobCreateInvoice(JobPlanningLine);

        // 3. Verify: Verify Currency Factor on Job Planning Line and Sales Invoice Line exists.
        JobPlanningLine.TestField("Currency Factor", CurrencyFactor);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", JobPlanningLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobUnitCostAfterAdjustCostItemEntries()
    var
        InventorySetup: Record "Inventory Setup";
        JobTask: Record "Job Task";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        UnitCost: Decimal;
    begin
        // [FEATURE] [Revaluation] [Adjust Cost Item Entries]
        // [SCENARIO 374796] Unit and Total Cost of Job Ledger Entry and Job Planning Line should be updated after posting Revaluation and executing Adjust Cost Item Entry with "Automatic Update Job Item Cost"

        // [GIVEN] "Automatic Update Job Item Cost" = Yes in Job Setup.
        Initialize();
        UpdateCostFieldsInInventorySetup(true, InventorySetup."Automatic Cost Adjustment"::Never);
        UpdateAutomaticCostOnJobsSetup(true);
        // [GIVEN] Posted Purchase order
        ItemNo := CreateItem();
        DocumentNo := CreateAndPostPurchaseOrder(JobTask, ItemNo);
        // [GIVEN] Posted revaluation entry with "Unit Cost (Revalued)" = "Y"
        UnitCost := UpdateUnitCostAndPostRevaluationJournal(ItemNo);

        // [WHEN] Run Adjust Cost Item Entries Batch Job
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');  // Passing Blank Value for Item Category Filter.

        // [THEN] "Unit Cost" on Job Ledger Entry = "Y"
        VerifyUnitCostInJobLedgerEntry(DocumentNo, ItemNo, UnitCost);

        // [THEN] "Total Cost" of Item Ledger Entries is equal "Posted Total Costs" of Job Planning Line.
        VerifyPostedTotalCostOfJobPlanningLine(JobTask, ItemNo);
    end;

    [Test]
    [HandlerFunctions('JobCreateSalesInvoiceHandler,MessageHandler,JobInvoicePageHandler,SalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure CheckEntryAfterDeleteJoInvoiceOnPage()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Check Job Planning Line Invoice is Empty after delete the Sales Invoice.

        // 1. Setup: Create Job,Job Task,Job planning Line and Sale Invoice.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), CreateItem(), JobTask);
        RunJobCreateSalesInvoice(JobTask);

        // 2. Exercise: Open Job List and Delete The Sales Invoice.
        OpenJobListToDeleteSalesInvoice(JobTask."Job No.");

        // 3. Verify: Verify Job Planning Line Invoice is empty.
        VerifyEntryIsEmptyOnJobPlanningLineInvoice(JobTask);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTableRelationForJobNo()
    var
        Job: Record Job;
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        // Verify Job No. on Job Planning Line Invoice with Job No on Job.

        // Setup: Create job.
        Initialize();
        LibraryJob.CreateJob(Job);

        // Exercise: Validate Job No on Job Planning Line Invoice.
        CreateJobPlanningLineInvoiceTable(JobPlanningLineInvoice, Job."No.", '', 0);

        // Verify: Verifying that Job No. on Job Planning Line Invoice with Job No on Job.
        JobPlanningLineInvoice.TestField("Job No.", Job."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTableRelationForJobTaskNo()
    var
        JobTask: Record "Job Task";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        // Verify Job Task No on Job Planning Line Invoice is same as Job Task.

        // Setup: Create Job and Job Task.
        Initialize();
        CreateJobAndJobTask(JobTask);

        // Exercise: Validate Job and Job Task No.
        CreateJobPlanningLineInvoiceTable(JobPlanningLineInvoice, JobTask."Job No.", JobTask."Job Task No.", 0);

        // Verify: Verifying that Job Task No on Job Planning Line Invoice is same as Job Task.
        JobPlanningLineInvoice.TestField("Job No.", JobTask."Job No.");
        JobPlanningLineInvoice.TestField("Job Task No.", JobTask."Job Task No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTableRelationForJobPlanningLineNo()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        // Verify Job No, Job task No and Job Planning Line No on Job Planning Line Invoice.

        // Setup: Create Job, Job Task and Job Planning Line No.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(
          JobPlanningLine, LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), CreateItem(), JobTask);

        // Exercise: Validate Job, Job Task No and Job Planning Line No.
        CreateJobPlanningLineInvoiceTable(
          JobPlanningLineInvoice, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");

        // Verify: Verifying that Job Planning Line No on Job Planning Line Invoice is not same as Job Planning Line.
        JobPlanningLineInvoice.TestField("Job No.", JobPlanningLine."Job No.");
        JobPlanningLineInvoice.TestField("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLineInvoice.TestField("Job Planning Line No.", JobPlanningLine."Line No.")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTableRelationErrorForJobNo()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        // Verify Job No. on Job Planning Line Invoice table is not same as Job No on Job table

        // Setup: Create Job Planning Line.
        Initialize();
        CreateJobPlanningLineTable(JobPlanningLine);

        // Exercise: Validate Job No of Job Planning Line Invoice.
        JobPlanningLineInvoice.Init();
        asserterror JobPlanningLineInvoice.Validate("Job No.", JobPlanningLine."Job No.");

        // Verify: Verifying that Job No. on Job Planning Line Invoice table is not same as Job No on Job.
        Assert.ExpectedError(StrSubstNo(JobNoErr, JobPlanningLine."Job No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTableRelationErrorForJobTaskNo()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        // Verify Job Task No on Job Planning Line Invoice table is not same as Job Task.

        // Setup: Create Job Planning Line.
        Initialize();
        CreateJobPlanningLineTable(JobPlanningLine);

        // Exercise: Validate Job and Job Task No of Job Planning Line Invoice.
        JobPlanningLineInvoice.Init();
        asserterror JobPlanningLineInvoice.Validate("Job Task No.", JobPlanningLine."Job Task No.");

        // Verify: Verifying that Job Task No on Job Planning Line Invoice Table is not same as Job Task.
        Assert.ExpectedError(StrSubstNo(JobTaskNoErr, JobPlanningLine."Job Task No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTableRelationErrorForJobPlanningLineNo()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        // Verify Job Planning Line No on Job Planning Line Invoice table is not same as Line No of Job Planning Line.

        // Setup: Create Job Planning Line with Job And Job Task and Job Planning Line Invoice.
        Initialize();
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLineTable(JobPlanningLine);
        CreateJobPlanningLineInvoiceTable(JobPlanningLineInvoice, JobTask."Job No.", JobTask."Job Task No.", 0);

        // Exercise: Validate Job Planning Line No of Job Planning Line Invoice.
        asserterror JobPlanningLineInvoice.Validate("Job Planning Line No.", JobPlanningLine."Line No.");

        // Verify: Verifying that Job Planning Line No on Job Planning Line Invoice is not same as Line No of Job Planning Line.
        Assert.ExpectedError(StrSubstNo(LineNoErr, JobPlanningLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('JobPostWIPToGLHandler,ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobPostWIPToGLForCost()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        Cost: Decimal;
    begin
        // Setup: Create Job with WIP Method for Cost side. Create Job Task.
        Initialize();

        CreateInitialSetupForJobWithTask(
          Job, JobTask, Job."WIP Posting Method"::"Per Job Ledger Entry", JobWIPMethod."Recognized Costs"::"Cost Value",
          JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", JobTask."WIP-Total"::" ");

        // Create Two Job planning Lines. Create and Post Job Journal Lines separately.
        // Exercise: Run Job Calculate WIP and Job WIP To G/L batches.
        // Verify: Verify the WIP Entry Amount on Job WIP G/L Entry.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        PostWIPToGLAndVerifyWIPEntryAmountForCost(Job, JobTask, Cost); // Cost is 1st planning line's Total Cost.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        PostWIPToGLAndVerifyWIPEntryAmountForCost(Job, JobTask, Cost); // Cost is 1st planning line's Total Cost + 2nd planning line's Total Cost .
    end;

    [Test]
    [HandlerFunctions('JobPostWIPToGLHandler,MessageHandler,JobTransferToSalesInvoiceWithPostingDateHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure JobPostWIPToGLForSales()
    var
        Job: Record Job;
        JobWIPMethod: Record "Job WIP Method";
        JobTask: Record "Job Task";
        LineAmount: Decimal;
    begin
        // Setup: Create Job with WIP Method for Sales side. Create Job Task.
        Initialize();
        CreateInitialSetupForJobWithTask(
          Job, JobTask, Job."WIP Posting Method"::"Per Job Ledger Entry", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)",
          JobWIPMethod."Recognized Sales"::"Sales Value", JobTask."WIP-Total"::" ");

        // Create Two Job planning Lines and transfer Job to Sales Invoice separately.
        // Exercise: Run Job Calculate WIP and Job WIP To G/L batches.
        // Verify: Verify the WIP Entry Amount on Job WIP G/L Entry.
        PostWIPToGLAndVerifyWIPEntryAmountForSales(Job, JobTask, LineAmount); // Line Amount is 1st planning line's Line Amount.
        PostWIPToGLAndVerifyWIPEntryAmountForSales(Job, JobTask, LineAmount); // Line Amount is 1st planning line's Line Amount + 2nd planning line's Line Amount.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunAdjustCostItemEntriesForJob()
    var
        JobTask: Record "Job Task";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Posted Total Cost value for Job Planning Line was adjusted after Run Adjust Cost - Item Entries.

        // Setup: Set Automatic Update Job Item Cost = TRUE. Create Job with Task and Job Planning Line.
        // Create and post Item Journal Line. Create and Post Job Journal Line.
        Initialize();
        UpdateAutomaticCostOnJobsSetup(true);
        ItemNo := InitSetupForAdjustCostItemEntries(JobTask);

        // Exercise: Run Adjust Cost Item Entries Batch Job.
        LibraryCosting.AdjustCostItemEntries(ItemNo, ''); // Passing Blank Value for Item Category Filter.

        // Verify: Verify Posted Total Cost of Job Planning Line was adjusted.
        VerifyPostedTotalCostOfJobPlanningLine(JobTask, ItemNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyWIPMethodAfterCalculateWIP()
    var
        Job: array[2] of Record Job;
        JobWIPMethod: Record "Job WIP Method";
        LineCount: Integer;
    begin
        // Verify that WIP Method has not been set by Calculate WIP for all Job Task Lines except last line
        // for case when user does not set WIP-Total and WIP Method in Job Task lines

        // Create Job with user-defined WIP-Total fields and Job with empty WIP-Total fields
        CreateJobWIPMethod(JobWIPMethod,
          JobWIPMethod."Recognized Costs"::"Cost Value",
          JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)");
        LineCount := LibraryRandom.RandIntInRange(3, 5);
        CreateJobAndJobTaskLinesForWIPTotal(Job[1], JobWIPMethod.Code, LineCount, true);
        CreateJobAndJobTaskLinesForWIPTotal(Job[2], JobWIPMethod.Code, LineCount, false);

        // Exercise: Run Calculate WIP Batch Job.
        RunJobCalculateWIP(Job[1]);
        RunJobCalculateWIP(Job[2]);

        // Verify: WIP Method must be empty for all line except Total line for 2nd case
        // WIP-Total and WIP Method fields should be the same as in 1st Job Task lines
        VerifyWIPTotalForJobTaskLines(Job[1]."No.", Job[2]."No.", LineCount);
    end;

    [Test]
    [HandlerFunctions('JobCreateSalesInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunCreateSalesInvoicesForJobsWithDiffCurrency()
    var
        SalesHeader: Record "Sales Header";
        JobPlanningLineWithInvCurreny: Record "Job Planning Line";
        JobPlanningLineWithCurrency: Record "Job Planning Line";
        JobPlanningLineWithoutCurrency: Record "Job Planning Line";
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 376733] Batch job "Create Job Sales Invoice" should keep "Unit Price" in FCY if "Invoice Currency Code" is not defined and convert if defined

        Initialize();

        // [GIVEN] Job "A" with blank "Currency Code", "Invoice Currency Code" = EUR, "Unit Price" = 50, "Currency Factor" = 0.5
        CreateJobWithFCYPlanningLine(JobPlanningLineWithInvCurreny, '', LibraryERM.CreateCurrencyWithRandomExchRates());

        // [GIVEN] Job "B" wih "Currency Code" = USD, "Invoice Currency Code" is blank, "Unit Price" = 100
        CreateJobWithFCYPlanningLine(JobPlanningLineWithCurrency, LibraryERM.CreateCurrencyWithRandomExchRates(), '');

        // [GIVEN] Job "C" wih blank "Currency Code", blank "Invoice Currency Code", "Unit Price" = 200
        CreateJobWithFCYPlanningLine(JobPlanningLineWithoutCurrency, '', '');

        // [WHEN] Run batch job "Create Job Sales Invoice" for "A" and "B"
        RunJobCreateSalesInvoices(
          StrSubstNo('%1|%2|%3', JobPlanningLineWithInvCurreny."Job No.",
            JobPlanningLineWithCurrency."Job No.", JobPlanningLineWithoutCurrency."Job No."));

        // [THEN] Sales Invoice created for job "A" with "Unit Price" = 25
        VerifyUnitPriceOnJobPlanningLineInLCY(JobPlanningLineWithInvCurreny);

        // [THEN] Sales Invoice created for job "B" with "Unit Price" = 100
        VerifyValuesOnSalesLineForInvoice(
          FindSalesHeader(JobPlanningLineWithCurrency."Job No.", SalesHeader."Document Type"::Invoice), JobPlanningLineWithCurrency);

        // [THEN] Sales Invoice created for job "C" with "Unit Price" = 200
        VerifyValuesOnSalesLineForInvoice(
          FindSalesHeader(JobPlanningLineWithoutCurrency."Job No.", SalesHeader."Document Type"::Invoice), JobPlanningLineWithoutCurrency);
    end;

    [Test]
    [HandlerFunctions('JobCreateSalesInvoiceHandler,MessageHandler,JobInvoiceGetDocNoPageHandler')]
    [Scope('OnPrem')]
    procedure JobCardSalesInvoicesCreditMemos()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobCard: TestPage "Job Card";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 310619] Sales Invoices/Credit Memos action is available from Job Card page
        Initialize();

        // [GIVEN] Creage Job "J" and invoice "I" from job task 
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), CreateItem(), JobTask);
        RunJobCreateSalesInvoice(JobTask);
        InvoiceNo := FindSalesHeader(JobTask."Job No.", "Sales Document Type"::Invoice);

        // [WHEN] Action "Sales Invoices/Credit Memos" is being run from Job Card
        JobCard.OpenEdit();
        JobCard.FILTER.SetFilter("No.", JobTask."Job No.");
        JobCard.SalesInvoicesCreditMemos.Invoke();

        // [THEN] Job Invoices page contains created invoice "I"
        Assert.AreEqual(InvoiceNo, LibraryVariableStorage.DequeueText(), 'Invalid document number');
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceWithPostingDateHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunCreateSalesInvoiceJobPlanningLineWithBin()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: array[2] of Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Job Create Invoice] [Bin]
        // [SCENARIO 377653]
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create location with two bins - "B1", "B2".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Post 10 pcs of an item into each bin.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin[1].Code, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin[2].Code, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Job, job task.
        // [GIVEN] Create and post job journal line for 10 pcs from bin "B2".
        // [GIVEN] The bin "B2" is now empty.
        CreateJobAndJobTask(JobTask);
        LibraryJob.CreateJobJournalLine(LibraryJob.UsageLineTypeBoth(), JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", Item."No.");
        JobJournalLine.Validate("Location Code", Location.Code);
        JobJournalLine.Validate("Bin Code", Bin[2].Code);
        JobJournalLine.Validate(Quantity, Qty);
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [WHEN] Find the job planning line and run "Create Sales Invoice".
        FindJobPlanningLine(JobPlanningLine, JobTask);
        TransferJobToSales(JobPlanningLine, false);

        // [THEN] The sales invoice has been created. Bin Code on the sales line = "B2".
        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice, FindSalesHeader(JobTask."Job No.", SalesHeader."Document Type"::Invoice));
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", Item."No.");
        SalesLine.TestField("Job No.", JobTask."Job No.");
        SalesLine.TestField("Location Code", Location.Code);
        SalesLine.TestField("Bin Code", Bin[2].Code);

        // [THEN] The sales invoice can be posted.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        JobPlanningLine.FindLast();
        JobPlanningLine.CalcFields("Qty. Invoiced");
        JobPlanningLine.TestField("Qty. Invoiced", Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldSetDefaultBinCodeIfAvailableWhenLocationChanges()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        JobJournalLine: Record "Job Journal Line";
        LocationA: Record Location;
        LocationB: Record Location;
        BinA: Record Bin;
        BinB: Record Bin;
    begin
        // [SCENARIO] Should set the job journal line bin code when the item is set and the location changes to a location with a default bin code.
        InitSetupForDefaultBinCodeTests(ItemA, ItemB, JobJournalLine, LocationA, LocationB, BinA, BinB);

        // [WHEN] Setting item A on the job journal line.
        JobJournalLine.Validate("No.", ItemA."No.");

        // [THEN] The bin code is not set.
        Assert.AreEqual(JobJournalLine."Bin Code", '', 'Expected default bin to not be set. ');

        // [WHEN] Setting item A on the job journal line.
        JobJournalLine.Validate("Location Code", LocationB.Code);

        // [THEN] The bin code is not set.
        Assert.AreEqual(JobJournalLine."Bin Code", '', 'Expected default bin to not be set. ');

        // [WHEN] Setting location A on the job journal line.
        JobJournalLine.Validate("Location Code", LocationA.Code);

        // [THEN] The bin code is populated with the default bin code for item A.
        Assert.AreEqual(JobJournalLine."Bin Code", BinA.Code, 'Expected default bin to be set. ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldSetDefaultBinCodeIfAvailableWhenItemChanges()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        JobJournalLine: Record "Job Journal Line";
        LocationA: Record Location;
        LocationB: Record Location;
        BinA: Record Bin;
        BinB: Record Bin;
    begin
        // [SCENARIO] Should set the job journal line bin code when the location is set and the item changes to an item with a default bin code.
        InitSetupForDefaultBinCodeTests(ItemA, ItemB, JobJournalLine, LocationA, LocationB, BinA, BinB);

        // [WHEN] Setting item B on the job journal line.
        JobJournalLine.Validate("No.", ItemB."No.");

        // [THEN] The bin code is not set.
        Assert.AreEqual(JobJournalLine."Bin Code", '', 'Expected default bin to not be set. ');

        // [WHEN] Setting location A on the job journal line.
        JobJournalLine.Validate("Location Code", LocationA.Code);

        // [THEN] The bin code is not set.
        Assert.AreEqual(JobJournalLine."Bin Code", '', 'Expected default bin to not be set. ');

        // [WHEN] Setting item A on the job journal line.
        JobJournalLine.Validate("No.", ItemA."No.");

        // [THEN] The bin code is populated with the default bin code for item A.
        Assert.AreEqual(JobJournalLine."Bin Code", BinA.Code, 'Expected default bin to be set. ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldClearBinCodeWhenLocationChanges()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        JobJournalLine: Record "Job Journal Line";
        LocationA: Record Location;
        LocationB: Record Location;
        BinA: Record Bin;
        BinB: Record Bin;
    begin
        // [SCENARIO] Should clear the job journal line bin code when the location changes to a location with no default bin code.
        InitSetupForDefaultBinCodeTests(ItemA, ItemB, JobJournalLine, LocationA, LocationB, BinA, BinB);

        // [WHEN] Setting item A and location A on the job journal line.
        JobJournalLine.Validate("No.", ItemA."No.");
        JobJournalLine.Validate("Location Code", LocationA.Code);

        // [THEN] The bin code is populated with the default bin code for item A.
        Assert.AreEqual(JobJournalLine."Bin Code", BinA.Code, 'Expected default bin to be set. ');

        // [WHEN] Setting location B on the job journal line.
        JobJournalLine.Validate("Location Code", LocationB.Code);

        // [THEN] The bin code is cleared.
        Assert.AreEqual(JobJournalLine."Bin Code", '', 'Expected default bin to be cleared. ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShouldClearBinCodeWhenItemChanges()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        JobJournalLine: Record "Job Journal Line";
        LocationA: Record Location;
        LocationB: Record Location;
        BinA: Record Bin;
        BinB: Record Bin;
    begin
        // [SCENARIO] Should clear the job journal line bin code when the item changes to an item with no default bin code.
        InitSetupForDefaultBinCodeTests(ItemA, ItemB, JobJournalLine, LocationA, LocationB, BinA, BinB);

        // [WHEN] Setting item A and location A on the job journal line.
        JobJournalLine.Validate("No.", ItemA."No.");
        JobJournalLine.Validate("Location Code", LocationA.Code);

        // [THEN] The bin code is populated with the default bin code for item A.
        Assert.AreEqual(JobJournalLine."Bin Code", BinA.Code, 'Expected default bin to be set. ');

        // [WHEN] When setting item B.
        JobJournalLine.Validate("No.", ItemB."No.");

        // [THEN] The bin code is cleared.
        Assert.AreEqual(JobJournalLine."Bin Code", '', 'Expected default bin to be cleared. ');
    end;

    [Test]

    procedure TestJobAttachmentonJobListPage()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
    begin
        // [SCENARIO 443560] Check Attachments are visible in Jobs List page.
        Initialize();

        //[GIVEN] Create Job and Job task 
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        //[GIVEN] Create Document Attachment
        DocumentAttachment.Init();
        RecRef.GetTable(Job);
        CreateDocumentAttachment(DocumentAttachment, RecRef, 'foo.jpeg');

        //[VERIFY] Check Document attachment count will be 1 on Job list page.
        OpenJobListToAttachDocument(Job."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyJobJournalLineBlankAfterPosting()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalBatch: Record "Job Journal Batch";
        JobJournalLine: Record "Job Journal Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 463554] When a line is posted in the Job Journal, an "empty" journal line remains afterwards.
        Initialize();

        // [GIVEN] Create "Job Task" and "Job Planning Line".
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), CreateResource(), JobTask);

        // [GIVEN] Create "Job Journal Batch" and "Document No.".
        CreateJobJournalBatch(JobJournalBatch);
        Evaluate(DocumentNo, LibraryUtility.GenerateRandomCode(JobJournalLine.FieldNo("Document No."), DATABASE::"Job Journal Line"));

        // [GIVEN] Create Job Journal Line.
        LibraryJob.CreateJobJournalLineForType("Job Line Type"::Billable, JobJournalLine.Type::Resource, JobTask, JobJournalLine);

        // [WHEN] Post Job Journal Line.
        PostJobJournalBatch(JobJournalLine);

        // [VERIFY] Verify no line inserted after posting of Job Journal Line.
        JobJournalLine.SetRange("Journal Template Name", JobJournalBatch."Journal Template Name");
        JobJournalLine.SetRange("Journal Batch Name", JobJournalBatch.Name);
        Assert.IsTrue(JobJournalLine.IsEmpty(), '');
    end;

    [Test]
    procedure LineDiscountOnValidatingProjectTaskNoPurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        // [SCENARIO 572198] Line Discount % is not removed after validating Project Task No. in Purchase Line.
        Initialize();

        //[GIVEN] Create a Job.
        LibraryJob.CreateJob(Job);

        // [GIVEN] Create a Job Task from the Job.
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create a Purchase Header with Document Type Order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // [GIVEN] Create a Purchase Line with an Item.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            LibraryInventory.CreateItemNo(),
            LibraryRandom.RandInt(10));

        // [GIVEN] Validate "Location Code", "Direct Unit Cost" and "Line Discount %" on Purchase Line.
        PurchaseLine.Validate("Location Code", LibraryWarehouse.CreateLocation(Location));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandInt(10));

        // [WHEN] Validate "Job No." and "Job Task No." in Purchase Line.
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);

        // [THEN] Value in "Line Discount %" of Purchase Line must have value.
        Assert.AreNotEqual(0, PurchaseLine."Line Discount %", LineDiscountErr);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceHandlers,MessageHandler,ConfirmHandlerTrue')]
    procedure PostingWhenExchangeRatesChangeInSalesFromProjectPlanningLine()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobCreateInvoices: Codeunit "Job Create-Invoice";
        PostingDate: Date;
    begin
        // [SCENARIO 597632] The Posting when exchange rates change in sales documents created from Project Planning Line.
        Initialize();

        // [GIVEN] Create a currency.
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Create exchange rates for the currency for today and one month from today.
        CreateCurrencyExchangeRate(Currency.Code, WorkDate());
        CreateCurrencyExchangeRate(Currency.Code, CalcDate('<+1M>', WorkDate()));

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Job with Currency.
        LibraryJob.CreateJob(Job, Customer."No.");
        Job.Validate("Invoice Currency Code", Currency.Code);
        Job.Modify(true);

        // [GIVEN] Create a Job task.
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create a Job Planning Line with Quantity, Unit Price and Currency Factor.
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(10));
        JobPlanningLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        JobPlanningLine.Modify(true);

        // [GIVEN] Create Sales Invoice from Job Planning Line.
        Commit();
        JobCreateInvoices.CreateSalesInvoice(JobPlanningLine, false);

        // [GIVEN] Find the created Sales Header.
        FindSalesHeaderFromJobPlanningLine(JobPlanningLine, SalesHeader);

        // [GIVEN] Change Posting Date on Sales Header to one month from today.
        PostingDate := CalcDate('<+1M>', SalesHeader."Posting Date");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        // [THEN] Verify that the Posting Date is updated without any error.
        Assert.AreEqual(PostingDate, SalesHeader."Posting Date", PostingDateErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Batch Jobs");
        // Clear the needed global variables.
        ClearGlobals();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Batch Jobs");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        UpdateJobPostingGroups();

        DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
        DummyJobsSetup."Apply Usage Link by Default" := false;
        DummyJobsSetup.Modify();

        SetJobNoSeries(DummyJobsSetup, NoSeries);

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Jobs Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Batch Jobs");
    end;

    local procedure InitSetupForAdjustCostItemEntries(var JobTask: Record "Job Task"): Code[20]
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        Qty: Decimal;
    begin
        // Create Job with Task. Create Job Planning Line. Create and Post two Item Journal Lines with different Unit Cost.
        // Create and Post two Job Journal Lines.
        CreateJobAndJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), CreateItem(), JobTask);
        UpdateUsageLinkOfJobPlanningLine(JobPlanningLine, true);
        Qty := LibraryRandom.RandInt(5);
        CreateAndPostItemJournalLine(JobPlanningLine."No.", Qty, LibraryRandom.RandInt(10));
        CreateAndPostItemJournalLine(JobPlanningLine."No.", JobPlanningLine.Quantity - Qty, LibraryRandom.RandInt(10));

        CreateAndPostJobJournalLine(
          JobJournalLine, JobTask, LibraryJob.UsageLineTypeSchedule(), JobJournalLine.Type::Item, JobPlanningLine."No.",
          Qty, JobPlanningLine."Unit Cost", WorkDate());
        CreateAndPostJobJournalLine(
          JobJournalLine, JobTask, LibraryJob.UsageLineTypeSchedule(), JobJournalLine.Type::Item, JobPlanningLine."No.",
          Qty, JobPlanningLine."Unit Cost", WorkDate());

        exit(JobPlanningLine."No.");
    end;

    local procedure AssignGlobalVariable(ChangeCurrencyDate2: Boolean; ChangePlanningDate2: Boolean; IncludeLineType2: Option " ",Budget,Billable,"Budget+Billable")
    begin
        ChangeCurrencyDate := ChangeCurrencyDate2;
        ChangePlanningDate := ChangePlanningDate2;
        IncludeLineType := IncludeLineType2
    end;

    local procedure ClearGlobals()
    begin
        // Clear global variable.
        Clear(IncludeLineType);
        ChangeCurrencyDate := false;
        ChangePlanningDate := false;
        ReverseOnly := false;
        CreateNewCreditMemo := false;
        AppendSalesInvoice := false;
        CancelJobTransferToCreditMemo := false;
        PostingDate := 0D;
        NewRelationalExchangeRateAmount := 0;
    end;

    local procedure ClearRevaluationJournalLines(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.SetupNewBatch();
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure ChangeExchangeRateOnSalesInvoice(var SalesHeader: Record "Sales Header"; JobNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, FindBillToCustomerNo(JobNo));
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice."Currency Code".AssistEdit();
    end;

    local procedure CreateAndPostJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; LineType: Enum "Job Line Type"; ConsumableType: Enum "Job Planning Line Type"; No: Code[20]; Qty: Decimal; UnitCost: Decimal; PostingDate: Date)
    begin
        LibraryJob.CreateJobJournalLineForType(LineType, ConsumableType, JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", No);
        JobJournalLine.Validate(Quantity, Qty);
        JobJournalLine.Validate("Unit Cost", UnitCost);
        JobJournalLine.Validate("Posting Date", PostingDate);
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateAndPostPurchaseInvoice(JobTask: Record "Job Task") Quantity: Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocumentWithJob(PurchaseLine, JobTask, PurchaseHeader."Document Type"::Invoice, CreateItem());
        Quantity := PurchaseLine.Quantity;
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseOrder(var JobTask: Record "Job Task"; ItemNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateJobAndJobTask(JobTask);
        CreatePurchaseDocumentWithJob(PurchaseLine, JobTask, PurchaseHeader."Document Type"::Order, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseDocumentWithJob(var PurchaseLine: Record "Purchase Line"; JobTask: Record "Job Task"; DocumentType: Enum "Purchase Document Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandInt(100));  // Use random values for Quantity.
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::"Both Budget and Billable");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCurrencyWithExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();
    end;

    local procedure CreateUpdateAndPostJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task") LineAmount: Decimal
    begin
        CreateJobJournalLine(JobJournalLine, JobTask, CreateItem());
        LineAmount := JobJournalLine."Line Amount";
        JobJournalLine.Validate("Line Amount", JobJournalLine."Line Amount" - LibraryUtility.GenerateRandomFraction());  // Update Line Amount for generating Line Discount Amount.
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateInitialSetupForJob(var Job: Record Job; var JobJournalLine: Record "Job Journal Line"; WIPTotal: Option): Decimal
    var
        JobWIPMethod: Record "Job WIP Method";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        CreateInitialSetupForJobWithTask(
          Job, JobTask, Job."WIP Posting Method"::"Per Job",
          JobWIPMethod."Recognized Costs"::"At Completion", JobWIPMethod."Recognized Sales"::"At Completion", WIPTotal);

        CreateJobPlanningLine(JobPlanningLine, LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), CreateResource(), JobTask);
        CreateAndPostJobJournalLine(
          JobJournalLine, JobTask, LibraryJob.UsageLineTypeContract(), LibraryJob.ResourceType(), JobPlanningLine."No.",
          JobPlanningLine.Quantity / 2, JobPlanningLine."Unit Cost", WorkDate());
        CreateJobTask(JobTask, Job, JobTask."Job Task Type"::Total, JobTask."WIP-Total"::Total);
        exit(JobPlanningLine."Total Price");
    end;

    local procedure CreateInitialSetupForJobWithTask(var Job: Record Job; var JobTask: Record "Job Task"; WIPPostingMethod: Option; CostsRecognition: Enum "Job WIP Recognized Costs Type"; SalesRecognition: Enum "Job WIP Recognized Sales Type"; WIPTotal: Option)
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        CreateJobWIPMethod(JobWIPMethod, CostsRecognition, SalesRecognition);
        CreateJob(Job, JobWIPMethod.Code);
        UpdateWIPPostingMethod(Job, WIPPostingMethod);
        CreateJobTask(JobTask, Job, JobTask."Job Task Type"::Posting, WIPTotal);
    end;

    local procedure CreateJob(var Job: Record Job; WIPMethod: Code[20])
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", WIPMethod);
        Job.Modify(true);
    end;

    local procedure CreateJobAndJobTask(var JobTask: Record "Job Task")
    var
        Customer: Record Customer;
        Job: Record Job;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryJob.CreateJob(Job, Customer."No.");
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobJournalBatch(var JobJournalBatch: Record "Job Journal Batch")
    var
        JobJournalTemplate: Record "Job Journal Template";
    begin
        LibraryJob.GetJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
    end;

    local procedure CreateJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; No: Code[20])
    begin
        LibraryJob.CreateJobJournalLineForType("Job Line Type"::Billable, JobJournalLine.Type::Item, JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", No);
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        JobJournalLine.Modify(true);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; LineType: Enum "Job Planning Line Line Type"; Type: Enum "Job Planning Line Type"; No: Code[20]; JobTask: Record "Job Task")
    begin
        // Use Random values for Quantity and Unit Cost because values are not important.
        LibraryJob.CreateJobPlanningLine(LineType, Type, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", No);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandIntInRange(10, 20));  // Using Random value for Quantity because value is not important.
        JobPlanningLine.Validate("Unit Cost", LibraryRandom.RandInt(100));  // Using Random value for Unit Cost because value is not important.
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithCurrency(var JobPlanningLine: Record "Job Planning Line"; CurrencyCode: Code[10])
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        CreateJobAndJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        Job.Validate("Currency Code", CurrencyCode);
        Job.Modify(true);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::"G/L Account", JobTask, JobPlanningLine);

        GLAccount.Get(JobPlanningLine."No.");
        GenProductPostingGroup.Get(GLAccount."Gen. Prod. Posting Group");
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := GLAccount."VAT Prod. Posting Group"; // no validation to avoid massive update
        GenProductPostingGroup.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithPlanningDate(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; PlanningDate: Date)
    begin
        CreateJobPlanningLine(JobPlanningLine, LineType, LibraryJob.ResourceType(), CreateResource(), JobTask);
        JobPlanningLine.Validate("Planning Date", PlanningDate);
        JobPlanningLine.Validate("Qty. to Transfer to Journal", JobPlanningLine.Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobWithFCYPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobCurrencyCode: Code[10]; InvoiceCurrencyCode: Code[10])
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        CreateJobAndJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        Job.Validate("Currency Code", JobCurrencyCode);
        Job.Validate("Invoice Currency Code", InvoiceCurrencyCode);
        Job.Modify(true);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
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

    local procedure CreateResource(): Code[20]
    begin
        exit(LibraryResource.CreateResourceNo());
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using Random value for Unit Price because value is not important.
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));  // Using Random value for Last Direct Cost because value is not important.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateRevaluationJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; AppliesToEntry: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ClearRevaluationJournalLines(ItemJournalBatch);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::" ");
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        ItemJournalLine.Validate(Quantity, 1);  // Taking Quantity as 1 to avoid test Failure, Value is not important as it gets overridden by Applied Quantity after Application.
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndUpdateJobJournalLine(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; FractionValue: Decimal)
    begin
        CreateJobJournalLine(JobJournalLine, JobTask, LibraryJob.CreateConsumable("Job Planning Line Type"::Item));
        JobJournalLine.Validate("Line Amount", JobJournalLine."Line Amount" - FractionValue);  // Update Line Amount for generating Line Discount Amount.
        JobJournalLine.Modify(true);
    end;

    local procedure CreateJobAndJobTaskLinesForWIPTotal(var Job: Record Job; JobWIPMethodCode: Code[20]; LineCount: Integer; UpdateWIPTotal: Boolean)
    var
        JobTask: Record "Job Task";
        i: Integer;
    begin
        CreateJob(Job, JobWIPMethodCode);

        for i := 1 to LineCount do
            CreateJobTask(JobTask, Job, JobTask."Job Task Type"::Posting, JobTask."WIP-Total"::" ");
        if UpdateWIPTotal then
            UpdateJobTaskWIPTotal(JobTask, JobWIPMethodCode);
    end;

    local procedure PostWIPToGLAndVerifyWIPEntryAmountForCost(var Job: Record Job; JobTask: Record "Job Task"; var Cost: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        CreateJobPlanningLineWithPlanningDate(JobPlanningLine, JobTask, LibraryJob.PlanningLineTypeBoth(), WorkDate());
        Cost += JobPlanningLine."Total Cost";
        CreateAndPostJobJournalLine(
          JobJournalLine, JobTask, LibraryJob.UsageLineTypeBlank(),
          LibraryJob.ResourceType(), JobPlanningLine."No.", JobPlanningLine.Quantity, JobPlanningLine."Unit Cost", WorkDate());
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);
        VerifyWIPEntryAmountOnJobWIPGLEntry(Job."No.", -Cost, WorkDate());
        WorkDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
    end;

    local procedure PostWIPToGLAndVerifyWIPEntryAmountForSales(var Job: Record Job; JobTask: Record "Job Task"; var LineAmount: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        CreateJobPlanningLineWithPlanningDate(JobPlanningLine, JobTask, LibraryJob.PlanningLineTypeBoth(), WorkDate());
        LineAmount += JobPlanningLine."Line Amount";
        TransferJobToSales(JobPlanningLine, false); // Use False for Invoice.
        FindAndPostSalesInvoice(Job."No.");
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);
        VerifyWIPEntryAmountOnJobWIPGLEntry(Job."No.", LineAmount, WorkDate());
        WorkDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
    end;

    local procedure FindAndPostSalesInvoice(JobNo: Code[20]) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", FindBillToCustomerNo(JobNo));
        SalesHeader.FindFirst();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure FindBillToCustomerNo(No: Code[20]): Code[20]
    var
        Job: Record Job;
    begin
        Job.Get(No);
        exit(Job."Bill-to Customer No.");
    end;

    local procedure FindItemLedgerEntryNo(ItemNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.FindFirst();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; DocumentNo: Code[20]; No: Code[20])
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange("No.", No);
        JobLedgerEntry.FindFirst();
    end;

    local procedure FindJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task")
    begin
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.FindLast();
    end;

    local procedure FindLastPlanningLineNo(JobTask: Record "Job Task"): Integer
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.FindLast();
        exit(JobPlanningLine."Line No.");
    end;

    local procedure FindSalesHeader(JobNo: Code[20]; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("Bill-to Customer No.", FindBillToCustomerNo(JobNo));
        SalesHeader.FindFirst();
        exit(SalesHeader."No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; No: Code[20]): Boolean
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        exit(SalesLine.FindFirst())
    end;

    local procedure FindItemLedgerEntry(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalCost: Decimal;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            TotalCost += Abs(ItemLedgerEntry."Cost Amount (Actual)");
        until ItemLedgerEntry.Next() = 0;
        exit(TotalCost);
    end;

    local procedure GetRecogSalesAmount(Job: Record Job): Decimal
    begin
        Job.CalcFields("Recog. Sales Amount");
        exit(Job."Recog. Sales Amount");
    end;

    local procedure GetTotalWIPCostAmount(Job: Record Job): Decimal
    begin
        Job.CalcFields("Total WIP Cost Amount");
        exit(Job."Total WIP Cost Amount");
    end;

    local procedure GetTotalWIPCostGLAmount(Job: Record Job): Decimal
    begin
        Job.CalcFields("Total WIP Cost G/L Amount");
        exit(Job."Total WIP Cost G/L Amount");
    end;

    local procedure GetTotalWIPSalesAmount(Job: Record Job): Decimal
    begin
        Job.CalcFields("Total WIP Sales Amount");
        exit(Job."Total WIP Sales Amount");
    end;

    local procedure GetSalesHeader(var SalesHeader: Record "Sales Header"; JobNo: Code[20]; DocumentType: Enum "Sales Document Type")
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("Bill-to Customer No.", FindBillToCustomerNo(JobNo));
        SalesHeader.FindFirst();
    end;

    local procedure OpenJobListToDeleteSalesInvoice(JobNo: Code[20])
    var
        JobList: TestPage "Job List";
    begin
        JobList.OpenEdit();
        JobList.FILTER.SetFilter("No.", JobNo);
        JobList.SalesInvoicesCreditMemos.Invoke();
    end;

    local procedure UpdateUnitCostAndPostRevaluationJournal(ItemNo: Code[20]) UnitCostRevalued: Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Revaluation Journal for Item.
        CreateRevaluationJournal(ItemJournalLine, ItemNo, FindItemLedgerEntryNo(ItemNo));
        UpdateUnitCostOnRevaluationJournalLine(ItemJournalLine);
        UnitCostRevalued := ItemJournalLine."Unit Cost (Revalued)";  // Store Revalued Unit Cost in a variable to use it in Verification.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure RunChangeJobDates(JobTaskNo: Code[20]; JobNo: Code[20])
    var
        JobTask: Record "Job Task";
        ChangeJobDates: Report "Change Job Dates";
    begin
        Commit();  // Commit needs before run report.
        Clear(ChangeJobDates);
        JobTask.SetRange("Job Task No.", JobTaskNo);
        JobTask.SetRange("Job No.", JobNo);
        ChangeJobDates.SetTableView(JobTask);
        ChangeJobDates.Run();
    end;

    local procedure RunJobCalcRemainingUsage(JobJournalBatch: Record "Job Journal Batch"; JobTask: Record "Job Task")
    var
        JobCalcRemainingUsage: Report "Job Calc. Remaining Usage";
    begin
        JobTask.SetRange("Job No.", JobTask."Job No.");
        JobTask.SetRange("Job Task No.", JobTask."Job Task No.");
        Commit();  // Commit required for batch report.
        Clear(JobCalcRemainingUsage);
        JobCalcRemainingUsage.SetBatch(JobJournalBatch."Journal Template Name", JobJournalBatch.Name);
        JobCalcRemainingUsage.SetDocNo(JobJournalBatch.Name);
        JobCalcRemainingUsage.SetTableView(JobTask);
        JobCalcRemainingUsage.Run();
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

    local procedure RunJobCreateInvoice(var JobPlanningLine: Record "Job Planning Line")
    begin
        Commit();  // Commit is required before Create Sales Invoice batch job.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);  // Use False for Invoice.
    end;

    local procedure RunJobCreateSalesInvoice(JobTask: Record "Job Task")
    var
        JobCreateSalesInvoice: Report "Job Create Sales Invoice";
    begin
        Commit();  // Commit required for batch report.
        JobTask.SetRange("Job No.", JobTask."Job No.");
        JobTask.SetRange("Job Task No.", JobTask."Job Task No.");
        Clear(JobCreateSalesInvoice);
        JobCreateSalesInvoice.SetTableView(JobTask);
        JobCreateSalesInvoice.Run();
    end;

    local procedure RunJobCreateSalesInvoices(JobFilter: Text)
    var
        JobTask: Record "Job Task";
        JobCreateSalesInvoice: Report "Job Create Sales Invoice";
    begin
        Commit();  // Commit required for batch report.
        JobTask.SetFilter("Job No.", JobFilter);
        Clear(JobCreateSalesInvoice);
        JobCreateSalesInvoice.SetTableView(JobTask);
        JobCreateSalesInvoice.Run();
    end;

    local procedure RunJobPostWIPToGL(Job: Record Job)
    var
        JobPostWIPToGL: Report "Job Post WIP to G/L";
    begin
        Job.SetRange("No.", Job."No.");
        Clear(JobPostWIPToGL);
        JobPostWIPToGL.SetTableView(Job);
        JobPostWIPToGL.Run();
    end;

    local procedure RunJobSplitPlanningLine(JobTask: Record "Job Task")
    var
        JobSplitPlanningLine: Report "Job Split Planning Line";
    begin
        JobTask.SetRange("Job No.", JobTask."Job No.");
        JobTask.SetRange("Job Task No.", JobTask."Job Task No.");
        Commit();  // Commit required for batch report.
        Clear(JobSplitPlanningLine);
        JobSplitPlanningLine.SetTableView(JobTask);
        JobSplitPlanningLine.UseRequestPage(false);
        JobSplitPlanningLine.Run();
    end;

    local procedure RunJobTransferToPlanningLines(DocumentNo: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobTransferToPlanningLines: Report "Job Transfer To Planning Lines";
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.FindFirst();
        Commit();  // Commit required for batch report.
        Clear(JobTransferToPlanningLines);
        JobTransferToPlanningLines.GetJobLedgEntry(JobLedgerEntry);
        JobTransferToPlanningLines.Run();
    end;

    local procedure TransferJobToSales(var JobPlanningLine: Record "Job Planning Line"; CreditMemo: Boolean)
    begin
        Commit();  // Commit required for batch report.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, CreditMemo);  // Use True for Credit Memo and False for Invoice.
    end;

    local procedure UpdateAutomaticCostOnJobsSetup(AutomaticUpdateJobItemCost: Boolean)
    var
        JobsSetup: Record "Jobs Setup";
    begin
        JobsSetup.Get();
        JobsSetup.Validate("Automatic Update Job Item Cost", AutomaticUpdateJobItemCost);
        JobsSetup.Modify(true);
    end;

    local procedure UpdateCostFieldsInInventorySetup(AutomaticCostPosting: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", AutomaticCostPosting);
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateJobPostingGroups()
    var
        JobPostingGroup: Record "Job Posting Group";
    begin
        if JobPostingGroup.FindSet() then
            repeat
                LibraryJob.UpdateJobPostingGroup(JobPostingGroup);
            until JobPostingGroup.Next() = 0;
    end;

    local procedure UpdateUnitCostOnRevaluationJournalLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.Validate("Unit Cost (Revalued)", ItemJournalLine."Unit Cost (Revalued)" + LibraryRandom.RandInt(100));  // Update Unit Cost Revalued with Random Value.
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateWIPCostsAccount("Code": Code[20]; WIPCostsAccount: Code[20]) OldWIPCostsAccount: Code[20]
    var
        JobPostingGroup: Record "Job Posting Group";
    begin
        JobPostingGroup.Get(Code);
        OldWIPCostsAccount := JobPostingGroup."WIP Costs Account";
        JobPostingGroup.Validate("WIP Costs Account", WIPCostsAccount);
        JobPostingGroup.Modify(true);
    end;

    local procedure UpdateWIPMethodOnJob(Job: Record Job; WIPMethod: Code[20])
    begin
        Job.Get(Job."No.");
        Job.Validate("WIP Method", WIPMethod);
        Job.Modify(true);
    end;

    local procedure UpdateWIPPostingMethod(var Job: Record Job; WIPPostingMethod: Option)
    begin
        Job.Validate("WIP Posting Method", WIPPostingMethod);
        Job.Modify(true);
    end;

    local procedure UpdateUsageLinkOfJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; UsageLink: Boolean)
    begin
        JobPlanningLine.Validate("Usage Link", UsageLink);
        JobPlanningLine.Modify(true);
    end;

    local procedure UpdateJobTaskWIPTotal(var JobTask: Record "Job Task"; JobWIPMethodCode: Code[20])
    begin
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethodCode);
        JobTask.Modify();
    end;

    local procedure CreateJobPlanningLineInvoiceTable(var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; JobNo: Code[20]; JobTaskNo: Code[20]; LineNo: Integer)
    begin
        JobPlanningLineInvoice.Init();
        JobPlanningLineInvoice.Validate("Job No.", JobNo);
        JobPlanningLineInvoice.Validate("Job Task No.", JobTaskNo);
        JobPlanningLineInvoice.Validate("Job Planning Line No.", LineNo);
        JobPlanningLineInvoice.Insert();
    end;

    local procedure CreateJobPlanningLineTable(var JobPlanningLine: Record "Job Planning Line")
    var
        RecRef: RecordRef;
    begin
        JobPlanningLine.Init();
        JobPlanningLine."Job No." := LibraryUTUtility.GetNewCode();
        JobPlanningLine."Job Task No." := LibraryUTUtility.GetNewCode();
        RecRef.GetTable(JobPlanningLine);
        JobPlanningLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, JobPlanningLine.FieldNo("Line No."));
        JobPlanningLine.Insert();
    end;

    local procedure VerifyGLEntry(GLAccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyJobJournalLine(JobJournalBatch: Record "Job Journal Batch"; JobPlanningLine: Record "Job Planning Line")
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.SetRange("Journal Template Name", JobJournalBatch."Journal Template Name");
        JobJournalLine.SetRange("Journal Batch Name", JobJournalBatch.Name);
        JobJournalLine.FindFirst();
        JobJournalLine.TestField("Job No.", JobPlanningLine."Job No.");
        JobJournalLine.TestField("Job Task No.", JobPlanningLine."Job Task No.");
        JobJournalLine.TestField(Quantity, JobPlanningLine.Quantity);
    end;

    local procedure VerifyJobLedgerEntry(JobJournalLine: Record "Job Journal Line"; DocumentNo: Code[20]; LineAmount: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobJournalLine."No.");
        JobLedgerEntry.TestField(Quantity, -JobJournalLine.Quantity);
        JobLedgerEntry.TestField("Unit Price (LCY)", JobJournalLine."Unit Price (LCY)");
        JobLedgerEntry.TestField("Total Price (LCY)", -JobJournalLine."Total Price (LCY)");
        JobLedgerEntry.TestField("Line Discount Amount", -(LineAmount - JobJournalLine."Line Amount"));
        JobJournalLine.TestField("Line Discount %", Round((LineAmount - JobJournalLine."Line Amount") / LineAmount * 100, 0.00001));  // Taking rounding precision as used in Job Journal Line Table rounding precision.
    end;

    local procedure VerifyJobPlanningLine(JobNo: Code[20]; JobTaskNo: Code[20]; LineType: Enum "Job Planning Line Line Type"; No: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        JobPlanningLine.SetRange("Line Type", LineType);
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.SetRange("No.", No);
        JobPlanningLine.FindFirst();
        JobPlanningLine.TestField("Planning Date", Today);
    end;

    local procedure VerifyJobWIPGLEntryWithGLBalAccountNo(JobNo: Code[20]; GLBalAccountNo: Code[20])
    var
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        JobWIPGLEntry.SetRange("Job No.", JobNo);
        JobWIPGLEntry.SetRange("G/L Bal. Account No.", GLBalAccountNo);
        JobWIPGLEntry.FindFirst();
    end;

    local procedure VerifyLineDiscountAmountOnSalesLine(JobNo: Code[20]; LineDiscountAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Job No.", JobNo);
        SalesLine.FindFirst();
        SalesLine.TestField("Line Discount Amount", LineDiscountAmount);
    end;

    local procedure VerifyUnitCostInJobLedgerEntry(DocumentNo: Code[20]; No: Code[20]; UnitCost: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, No);
        JobLedgerEntry.TestField("Unit Cost", UnitCost);
    end;

    local procedure VerifyTransferJobPlanningLine(JobJournalLine: Record "Job Journal Line"; LineType: Enum "Job Planning Line Line Type"; LineNo: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobJournalLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobJournalLine."Job Task No.");
        JobPlanningLine.SetRange("Line Type", LineType);
        JobPlanningLine.SetFilter("Line No.", '>%1', LineNo);
        JobPlanningLine.FindFirst();
        JobPlanningLine.TestField(Quantity, JobJournalLine.Quantity);
    end;

    local procedure VerifyValuesOnJobPlanningLine(JobNo: Code[20]; JobTaskNo: Code[20]; LineType: Enum "Job Planning Line Line Type"; Quantity: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        JobPlanningLine.SetRange("Line Type", LineType);
        JobPlanningLine.FindFirst();
        JobPlanningLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyValuesOnSalesLineForCreditMemo(DocumentNo: Code[20]; JobPlanningLine: Record "Job Planning Line")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesLine."Document Type"::"Credit Memo", DocumentNo, JobPlanningLine."No.");
        SalesLine.TestField(Quantity, -JobPlanningLine."Qty. Transferred to Invoice");
        SalesLine.TestField("Unit Price", JobPlanningLine."Unit Price");
    end;

    local procedure VerifyValuesOnSalesLineForInvoice(DocumentNo: Code[20]; JobPlanningLine: Record "Job Planning Line")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, DocumentNo, JobPlanningLine."No.");
        SalesLine.TestField(Quantity, JobPlanningLine.Quantity);
        SalesLine.TestField("Unit Price", JobPlanningLine."Unit Price");
    end;

    local procedure VerifyEntryIsEmptyOnJobPlanningLineInvoice(JobTask: Record "Job Task")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        JobPlanningLineInvoice.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobTask."Job Task No.");
        if not JobPlanningLineInvoice.IsEmpty() then
            Error(SalesInvoiceExistErr, JobPlanningLineInvoice.TableCaption());
    end;

    local procedure VerifyWIPEntryAmountOnJobWIPGLEntry(JobNo: Code[20]; Amount: Decimal; PostingDate: Date)
    var
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        JobWIPGLEntry.SetRange("Job No.", JobNo);
        JobWIPGLEntry.SetRange("Posting Date", PostingDate);
        JobWIPGLEntry.FindFirst();
        JobWIPGLEntry.TestField("WIP Entry Amount", Amount);
    end;

    local procedure VerifyPostedTotalCostOfJobPlanningLine(JobTask: Record "Job Task"; ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        TotalCost: Decimal;
    begin
        TotalCost := FindItemLedgerEntry(ItemNo, ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        JobPlanningLine.SetRange("Schedule Line", true);
        FindJobPlanningLine(JobPlanningLine, JobTask);
        JobPlanningLine.TestField("Posted Total Cost", TotalCost);
    end;

    local procedure VerifyWIPTotalForJobTaskLines(JobNo1: Code[20]; JobNo2: Code[20]; LastLineNo: Integer)
    var
        JobTaskLine1: Record "Job Task";
        JobTaskLine2: Record "Job Task";
        LineNo: Integer;
    begin
        JobTaskLine1.SetRange("Job No.", JobNo1);
        JobTaskLine1.FindSet();
        JobTaskLine2.SetRange("Job No.", JobNo2);
        JobTaskLine2.FindSet();
        repeat
            LineNo += 1;
            if LineNo <> LastLineNo then
                Assert.AreEqual('', JobTaskLine2."WIP Method", StrSubstNo(WrongValueErr, JobTaskLine2.FieldCaption("WIP Method")));
            Assert.AreEqual(JobTaskLine1."WIP-Total", JobTaskLine2."WIP-Total", StrSubstNo(WrongValueErr, JobTaskLine2.FieldCaption("WIP-Total")));
            Assert.AreEqual(JobTaskLine1."WIP Method", JobTaskLine2."WIP Method", StrSubstNo(WrongValueErr, JobTaskLine2.FieldCaption("WIP Method")));
            JobTaskLine1.Next();
        until JobTaskLine2.Next() = 0;
    end;

    local procedure VerifyUnitPriceOnJobPlanningLineInLCY(JobPlanningLine: Record "Job Planning Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        GetSalesHeader(SalesHeader, JobPlanningLine."Job No.", SalesHeader."Document Type"::Invoice);
        JobPlanningLine."Unit Price" :=
          Round(
            JobPlanningLine."Unit Price" * SalesHeader."Currency Factor",
            LibraryJob.GetUnitAmountRoundingPrecision(SalesHeader."Currency Code"));
        VerifyValuesOnSalesLineForInvoice(SalesHeader."No.", JobPlanningLine);
    end;

    local procedure CreateCurrencyExchangeRate(CurrencyCode: Code[10]; ExchangeRateDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, ExchangeRateDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(1000, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDec(1000, 2));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure FindSalesHeaderFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Job No.", JobPlanningLine."Job No.");
        SalesLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        SalesLine.FindFirst();
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesLine."Document No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeExchangeRatePageHandler(var ChangeExchangeRate: TestPage "Change Exchange Rate")
    begin
        ChangeExchangeRate.RefExchRate.SetValue(NewRelationalExchangeRateAmount);
        ChangeExchangeRate.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ChangeJobDatesHandler(var ChangeJobDates: TestRequestPage "Change Job Dates")
    begin
        ChangeJobDates.ChangeCurrencyDate.SetValue(ChangeCurrencyDate);
        ChangeJobDates.FixedDateCurrency.SetValue(Today);
        ChangeJobDates.IncludeLineTypeCurrency.SetValue(IncludeLineType);
        ChangeJobDates.IncludeCurrDateFrom.SetValue(WorkDate());
        ChangeJobDates.IncludeCurrDateTo.SetValue(WorkDate());

        ChangeJobDates.ChangePlanningDate.SetValue(ChangePlanningDate);
        ChangeJobDates.FixedDatePlanning.SetValue(Today);
        ChangeJobDates.IncludeLineTypePlanning.SetValue(IncludeLineType);
        ChangeJobDates.IncludePlanDateFrom.SetValue(WorkDate());
        ChangeJobDates.IncludePlanDateTo.SetValue(WorkDate());
        ChangeJobDates.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobPostWIPToGLHandler(var JobPostWIPToGL: TestRequestPage "Job Post WIP to G/L")
    begin
        JobPostWIPToGL.ReversalPostingDate.SetValue(WorkDate());
        JobPostWIPToGL.ReversalDocumentNo.SetValue(Format(LibraryRandom.RandInt(10)));  // Use random Reversal Document No.
        JobPostWIPToGL.ReverseOnly.SetValue(ReverseOnly);
        JobPostWIPToGL.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToPlanningLinesHandler(var JobTransferToPlanningLines: TestRequestPage "Job Transfer To Planning Lines")
    begin
        JobTransferToPlanningLines.TransferTo.SetValue(2);  // Use 2 for Both Budget and Billable.
        JobTransferToPlanningLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCalcRemainingUsageHandler(var JobCalcRemainingUsage: TestRequestPage "Job Calc. Remaining Usage")
    begin
        JobCalcRemainingUsage.PostingDate.SetValue(Format(WorkDate()));
        JobCalcRemainingUsage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToCreditMemoHandler(var JobTransferToCreditMemo: TestRequestPage "Job Transfer to Credit Memo")
    begin
        if (PostingDate = 0D) or CancelJobTransferToCreditMemo then begin
            JobTransferToCreditMemo.Cancel().Invoke();
            exit
        end;

        JobTransferToCreditMemo.PostingDate.SetValue(PostingDate);

        // If Credit Memo is already exist then append to existing Credit Memo, otherwise create new Credit Memo.
        JobTransferToCreditMemo.CreateNewCreditMemo.SetValue(CreateNewCreditMemo);
        if not CreateNewCreditMemo then
            JobTransferToCreditMemo.AppendToCreditMemoNo.Lookup();

        JobTransferToCreditMemo.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        if AppendSalesInvoice then begin
            JobTransferToSalesInvoice.CreateNewInvoice.SetValue(AppendSalesInvoice);
            JobTransferToSalesInvoice.AppendToSalesInvoiceNo.Lookup();
        end;
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceWithPostingDateHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCreateSalesInvoiceHandler(var JobCreateSalesInvoice: TestRequestPage "Job Create Sales Invoice")
    begin
        JobCreateSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure JobTransferToSalesInvoiceHandlers(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.CreateNewInvoice.SetValue(true);
        JobTransferToSalesInvoice.PostingDate.SetValue(WorkDate());
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobInvoicePageHandler(var JobInvoices: TestPage "Job Invoices")
    begin
        JobInvoices.OpenSalesInvoiceCreditMemo.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobInvoiceGetDocNoPageHandler(var JobInvoices: TestPage "Job Invoices")
    begin
        LibraryVariableStorage.Enqueue(JobInvoices."Document No.".Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoicePageHandler(var SalesInvoice: TestPage "Sales Invoice")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoice."No.".Value);
        SalesHeader.Delete(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerMultipleResponses(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [Scope('OnPrem')]
    procedure SetJobNoSeries(var JobsSetup: Record "Jobs Setup"; var NoSeries: Record "No. Series")
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

    // Setups Item A with default bin code A and item B with non-default bin code B.
    local procedure InitSetupForDefaultBinCodeTests(
        var ItemA: Record Item;
        var ItemB: Record Item;
        var JobJournalLine: Record "Job Journal Line";
        var LocationA: Record Location;
        var LocationB: Record Location;
        var BinA: Record Bin;
        var BinB: Record Bin
    )
    var
        JobTask: Record "Job Task";
        BinContentA: Record "Bin Content";
        BinContentB: Record "Bin Content";
    begin
        Initialize();

        // Two locations, A and B.
        LibraryWarehouse.CreateLocationWMS(LocationA, true, true, false, false, false);
        LibraryWarehouse.CreateLocationWMS(LocationB, true, true, false, false, false);

        // Two items A and B.
        LibraryInventory.CreateItem(ItemA);
        LibraryInventory.CreateItem(ItemB);

        // Two bins, one default for item A and one not default for item B.
        LibraryWarehouse.CreateBin(
            BinA,
            LocationA.Code,
            CopyStr(
                LibraryUtility.GenerateRandomCode(BinA.FieldNo(Code), DATABASE::Bin),
                1,
                LibraryUtility.GetFieldLength(DATABASE::Bin, BinA.FieldNo(Code))
            ),
            '',
            ''
        );
        LibraryWarehouse.CreateBinContent(
            BinContentA, BinA."Location Code", '', BinA.Code, ItemA."No.", '', ItemA."Base Unit of Measure"
        );
        BinContentA.Validate(Fixed, true);
        BinContentA.Validate(Default, true);
        BinContentA.Modify(true);

        LibraryWarehouse.CreateBin(
            BinB,
            LocationB.Code,
            CopyStr(
                LibraryUtility.GenerateRandomCode(BinB.FieldNo(Code), DATABASE::Bin),
                1,
                LibraryUtility.GetFieldLength(DATABASE::Bin, BinB.FieldNo(Code))
            ),
            '',
            ''
        );
        LibraryWarehouse.CreateBinContent(
            BinContentB, BinB."Location Code", '', BinB.Code, ItemB."No.", '', ItemB."Base Unit of Measure"
        );

        // A job with an item journal line.
        CreateJobAndJobTask(JobTask);
        CreateJobJournalLine(JobJournalLine, JobTask, '');
    end;

    local procedure CreateDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        DocumentAttachment.Init();
        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
        Clear(DocumentAttachment);
    end;

    local procedure CreateTempBLOBWithImageOfType(var TempBlob: Codeunit "Temp Blob"; ImageType: Text)
    var
        ImageFormat: DotNet ImageFormat;
        Bitmap: DotNet Bitmap;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        Bitmap := Bitmap.Bitmap(1, 1);
        case ImageType of
            'png':
                Bitmap.Save(InStr, ImageFormat.Png);
            'jpeg':
                Bitmap.Save(InStr, ImageFormat.Jpeg);
            else
                Bitmap.Save(InStr, ImageFormat.Bmp);
        end;
        Bitmap.Dispose();
    end;

    local procedure OpenJobListToAttachDocument(JobNo: Code[20])
    var
        JobList: TestPage "Job List";
    begin
        JobList.OpenEdit();
        JobList.FILTER.SetFilter("No.", JobNo);

        JobList."Attached Documents List".First();
        Assert.AreEqual('foo', JobList."Attached Documents List".Name.Value, 'Document name is not as expected');
        Assert.AreEqual('jpeg', JobList."Attached Documents List"."File Extension".Value, 'Document extension is not as expected');
    end;

    local procedure PostJobJournalBatch(var JobJournalLine: Record "Job Journal Line")
    begin
        // Post job journal batch
        Codeunit.Run(Codeunit::"Job Jnl.-Post Batch", JobJournalLine);
    end;
}

