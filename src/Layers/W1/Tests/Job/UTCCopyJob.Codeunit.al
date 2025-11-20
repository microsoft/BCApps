codeunit 136361 "UT C Copy Job"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Copy Job] [Job] [UT]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPriceCalculation: codeunit "Library - Price Calculation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        JobWithManualNoNotCreatedErr: Label 'Project with manual number is not created.';
        TestFieldValueErr: Label '%1 must be equal to %2.', Comment = '%1 - field caption, %2 - field value';
        UnitCostMustMatchErr: Label 'Unit Cost must match.';
        TotalCostMustMatchErr: Label 'Total Cost must match.';
        UnitPriceMustMatchErr: Label 'Unit Price must match.';
        TotalPriceMustMatchErr: Label 'Total Price must match.';

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionCopyJob()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: Record "Job Planning Line";
        TargetJob: Record Job;
        CopyJob: Codeunit "Copy Job";
        NewJobNo: Code[20];
    begin
        Initialize();
        SetUp(SourceJob, SourceJobTask, SourceJobPlanningLine);

        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        NewJobNo := LibraryUtility.GenerateGUID();
        CopyJob.CopyJob(SourceJob, NewJobNo, '', '', '');
        TargetJob.Get(NewJobNo);
        CompareJobFields(SourceJob, TargetJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionCopyJobTask()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: Record "Job Planning Line";
        TargetJob: Record Job;
        TargetJobTask: Record "Job Task";
        CopyJob: Codeunit "Copy Job";
    begin
        Initialize();
        SetUp(SourceJob, SourceJobTask, SourceJobPlanningLine);

        InitJobTask(TargetJob, SourceJob."Bill-to Customer No.", '');
        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJobTasks(SourceJob, TargetJob);
        TargetJobTask.Get(TargetJob."No.", SourceJobTask."Job Task No.");
        CompareJobTaskFields(SourceJobTask, TargetJobTask);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionCopyJobPlanningLine()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: Record "Job Planning Line";
        TargetJob: Record Job;
        TargetJobTask: Record "Job Task";
        TargetJobPlanningLine: Record "Job Planning Line";
        CopyJob: Codeunit "Copy Job";
    begin
        Initialize();
        SetUp(SourceJob, SourceJobTask, SourceJobPlanningLine);

        InitJobTask(TargetJob, SourceJob."Bill-to Customer No.", '');

        TargetJobTask.Init();
        TargetJobTask."Job No." := TargetJob."No.";
        TargetJobTask."Job Task No." := SourceJobTask."Job Task No.";
        TargetJobTask.Insert();

        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJobPlanningLines(SourceJobTask, TargetJobTask);
        TargetJobPlanningLine.Get(TargetJob."No.", TargetJobTask."Job Task No.", SourceJobPlanningLine."Line No.");
        CompareJobPlanningLineFields(SourceJobPlanningLine, TargetJobPlanningLine, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFunctionCopyJobPlanningLineWithoutQuantity()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: Record "Job Planning Line";
        TargetJob: Record Job;
        TargetJobTask: Record "Job Task";
        TargetJobPlanningLine: Record "Job Planning Line";
        CopyJob: Codeunit "Copy Job";
    begin
        Initialize();
        SetUp(SourceJob, SourceJobTask, SourceJobPlanningLine);

        InitJobTask(TargetJob, SourceJob."Bill-to Customer No.", '');

        TargetJobTask.Init();
        TargetJobTask."Job No." := TargetJob."No.";
        TargetJobTask."Job Task No." := SourceJobTask."Job Task No.";
        TargetJobTask.Insert();

        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.SetCopyQuantity(false);
        CopyJob.CopyJobPlanningLines(SourceJobTask, TargetJobTask);
        TargetJobPlanningLine.Get(TargetJob."No.", TargetJobTask."Job Task No.", SourceJobPlanningLine."Line No.");
        CompareJobPlanningLineFields(SourceJobPlanningLine, TargetJobPlanningLine, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyJobTaskPreserveWIPMethod()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: Record "Job Planning Line";
        TargetJob: Record Job;
        TargetJobTask: Record "Job Task";
        JobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        CopyJob: Codeunit "Copy Job";
    begin
        Initialize();
        SetUp(SourceJob, SourceJobTask, SourceJobPlanningLine);
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);

        UpdateJobTaskLines(SourceJob."No.", JobTask."Job Task Type"::Posting);

        InitJobTask(TargetJob, SourceJob."Bill-to Customer No.", JobWIPMethod.Code);

        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJobTasks(SourceJob, TargetJob);
        TargetJobTask.Get(TargetJob."No.", SourceJobTask."Job Task No.");
        TargetJobTask.TestField("WIP Method", TargetJob."WIP Method");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyJobModifyDescriptionAndCustomer()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: Record "Job Planning Line";
        TargetJob: Record Job;
        CopyJob: Codeunit "Copy Job";
        NewCustNo: Code[20];
        NewJobNo: Code[20];
        NewDescription: Text[50];
    begin
        Initialize();
        SetUp(SourceJob, SourceJobTask, SourceJobPlanningLine);

        NewDescription := LibraryUtility.GenerateGUID();
        NewCustNo := CreateCustomer();
        SourceJob.Validate(Status, SourceJob.Status::Planning);
        SourceJob.Modify();

        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        NewJobNo := LibraryUtility.GenerateGUID();
        CopyJob.CopyJob(SourceJob, NewJobNo, NewDescription, NewCustNo, '');
        TargetJob.Get(NewJobNo);

        Assert.AreEqual(NewDescription, TargetJob.Description, '');
        Assert.AreEqual(NewCustNo, TargetJob."Bill-to Customer No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyJobWithSeriesNoAndDisabledManualNos()
    var
        SourceJob: Record Job;
        CopyJob: Codeunit "Copy Job";
        ExpectedJobNo: Code[20];
    begin
        // [SCENARIO 108995] Job with disabled "Manual Nos" in "Job No. Series" can be copied
        Initialize();

        // [GIVEN] Job
        LibraryJob.CreateJob(SourceJob);

        // [GIVEN] Disable "Manual Nos" for "Job No. Series"
        SetupManualNos(false);

        // [GIVEN] Next "No." from "Job No. Series"
        ExpectedJobNo := LibraryUtility.GenerateGUID();

        // [WHEN] Copy the job
        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJob(SourceJob, ExpectedJobNo, '', '', '');

        // [THEN] New job created with "Job No." assigned from "Job No. Series"
        Assert.IsTrue(SourceJob.Get(ExpectedJobNo), JobWithManualNoNotCreatedErr);

        // TearDown
        SetupManualNos(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WIPMethodNotCopiedFromJobWhenOriginalValueIsBlank()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: Record "Job Planning Line";
        TargetJob: Record Job;
        TargetJobTask: Record "Job Task";
        JobWIPMethod: Record "Job WIP Method";
        CopyJob: Codeunit "Copy Job";
    begin
        // [SCENARIO 377532] "WIP Method" shouldn't be copied to Job Task if it was not defined in the original Job Task

        // [GIVEN] Source Job with Job Task "A" where "WIP Method" is not defined
        Initialize();
        SetUp(SourceJob, SourceJobTask, SourceJobPlanningLine);

        // [GIVEN] Target job with "WIP Method"
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        InitJobTask(TargetJob, SourceJob."Bill-to Customer No.", JobWIPMethod.Code);

        // [WHEN] Copy Source Job to Target Job
        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJobTasks(SourceJob, TargetJob);

        // [THEN] "WIP Method" in copied Job Task is blank
        TargetJobTask.Get(TargetJob."No.", SourceJobTask."Job Task No.");
        TargetJobTask.TestField("WIP Method", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineWithUnevenLineNoTwice()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: Record "Job Planning Line";
        TargetJob: Record Job;
        TargetJobTask: Record "Job Task";
        CopyJob: Codeunit "Copy Job";
    begin
        // [SCENARIO 195862] Job Planning Line with uneven "Line No." can be copied to new Job Task twice

        Initialize();

        // [GIVEN] Source Job Task and Job Planning Line
        SetUp(SourceJob, SourceJobTask, SourceJobPlanningLine);

        // [GIVEN] Additional Job Planning Line with "Line No." = 10625 for Source Job Task
        SourceJobPlanningLine."Line No." := 10625;
        SourceJobPlanningLine.Insert();

        // [GIVEN] Target Job Task
        InitJobTask(TargetJob, SourceJob."Bill-to Customer No.", '');
        MockJobTask(TargetJobTask, TargetJob."No.", SourceJobTask."Job Task No.");

        // [GIVEN] Job Planning Line copied from Source to Target Job Task
        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJobPlanningLines(SourceJobTask, TargetJobTask);

        // [WHEN] Copy Job Planning Line from Source to Target Job Task second time
        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJobPlanningLines(SourceJobTask, TargetJobTask);

        // [THEN] 4 Job Planning Lines are copied to Target Job Task
        VerifyJobPlanningLineCount(TargetJob."No.", TargetJobTask."Job Task No.", 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineWithLineNoCloseToZeroTwice()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        TargetJob: Record Job;
        TargetJobTask: Record "Job Task";
        CopyJob: Codeunit "Copy Job";
    begin
        // [SCENARIO 195862] Job Planning Line with "Line No." close to zero can be copied to new Job Task twice

        Initialize();

        // [GIVEN] Source Job and Job Task
        LibraryJob.CreateJob(SourceJob);
        LibraryJob.CreateJobTask(SourceJob, SourceJobTask);

        // [GIVEN] Job Planning Lines with "Line No." = 1 and "Line No." = 2
        MockJobPlanningLineWithSpecificLineNo(SourceJobTask, 1);
        MockJobPlanningLineWithSpecificLineNo(SourceJobTask, 2);

        // [GIVEN] Target Job Task
        InitJobTask(TargetJob, SourceJob."Bill-to Customer No.", '');
        MockJobTask(TargetJobTask, TargetJob."No.", SourceJobTask."Job Task No.");

        // [GIVEN] Job Planning Line copied from Source to Target Job Task
        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJobPlanningLines(SourceJobTask, TargetJobTask);

        // [WHEN] Copy Job Planning Line from Source to Target Job Task second time
        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJobPlanningLines(SourceJobTask, TargetJobTask);

        // [THEN] 4 Job Planning Lines are copied to Target Job Task
        VerifyJobPlanningLineCount(TargetJob."No.", TargetJobTask."Job Task No.", 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyJobPlanningLinesFromSameJob()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: Record "Job Planning Line";
        CopyJob: Codeunit "Copy Job";
    begin
        // [SCENARIO 382032] Copy Job Planning Lines from the same Job Task

        Initialize();

        // [GIVEN] Source Job Task and Job Planning Line
        SetUp(SourceJob, SourceJobTask, SourceJobPlanningLine);

        // [WHEN] Copy Job Planning Line from Source to Source Job Task
        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJobPlanningLines(SourceJobTask, SourceJobTask);

        // [THEN] Source Job Task have 2 Job Planning Lines
        VerifyJobPlanningLineCount(SourceJob."No.", SourceJobTask."Job Task No.", 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyJobWithJobTaskDimensions()
    var
        SourceJob: Record Job;
        TargetJob: Record Job;
        JobTask: Record "Job Task";
        CopyJob: Codeunit "Copy Job";
        TargetJobNo: Code[20];
    begin
        // [SCENARIO 272463] "Copy Job Task" page copies Job Task Dimensions

        Initialize();

        // [GIVEN] Job "J1" with Job Task "JT"
        LibraryJob.CreateJob(SourceJob);
        LibraryJob.CreateJobTask(SourceJob, JobTask);

        // [GIVEN] Default Dimensions for "J1"
        CreateJobDefaultDimension(SourceJob."No.");
        CreateJobDefaultDimension(SourceJob."No.");

        // [GIVEN] Job Task Dimensions for "JT"
        CreateJobTaskDimension(SourceJob."No.", JobTask."Job Task No.");
        UpdateJobTaskDimensionValue(
          SourceJob."No.",
          JobTask."Job Task No.",
          CopyStr(LibraryVariableStorage.DequeueText(), 1, 20));
        DeleteJobTaskDimension(
          SourceJob."No.",
          JobTask."Job Task No.",
          CopyStr(LibraryVariableStorage.DequeueText(), 1, 20));

        // [WHEN] Copy Job With Dimensions
        TargetJobNo := LibraryUtility.GenerateGUID();
        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJob(SourceJob, TargetJobNo, '', '', '');
        TargetJob.Get(TargetJobNo);

        // [THEN] Task Dimensions identical
        VerifyCopyTaskDimensions(SourceJob."No.", TargetJobNo, JobTask."Job Task No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyJobPlanningLineClearsLedgerEntryAndType()
    var
        Job: array[2] of Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        CopyJob: Codeunit "Copy Job";
    begin
        // [SCENARIO 225344] "Copy Job Task" page clears "Ledger Entry No.´Š¢ and ´Š¢Ledger Entry Type".
        Initialize();

        // [GIVEN] Job "J1" with Job Task "JT".
        LibraryJob.CreateJob(Job[1]);
        LibraryJob.CreateJobTask(Job[1], JobTask);

        // [GIVEN] Job Planning Line for "J1" with filled "Ledger Entry No." and "Ledger Entry Type".
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine."Ledger Entry Type" := JobPlanningLine."Ledger Entry Type"::Item;
        JobPlanningLine."Ledger Entry No." := LibraryRandom.RandInt(100);
        JobPlanningLine.Modify();

        // [GIVEN] Job "J2" whithout any Job Task Lines and Job Planning Lines.
        LibraryJob.CreateJob(Job[2]);

        // [WHEN] "Copy Job Task" is performed to copy "JT" from "J1" to "J2".
        CopyJob.SetJobTaskRange(JobTask."Job Task No.", JobTask."Job Task No.");
        CopyJob.CopyJobTasks(Job[1], Job[2]);

        // [THEN] Job Planning Line for "J2" is created with "Ledger Entry No." = 0, and "Ledger Entry Type" = Blank.
        VerifyJobPlanningLineLedgerEntryFields(Job[2]."No.", JobTask."Job Task No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyJobWithPriceDiffCurrency()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: array[3] of Record "Job Planning Line";
        JobGLAccountPrice: array[2] of Record "Job G/L Account Price";
        JobItemPrice: array[2] of Record "Job Item Price";
        JobResourcePrice: array[2] of Record "Job Resource Price";
        Currency: Record Currency;
        CopyJob: Codeunit "Copy Job";
        TargetJobNo: Code[20];
    begin
        // [SCENARIO 409848] Copy Job should not ignore prices with Currency <> Job Currency
        Initialize();

        // [GIVEN] Job with Currency Code = '' and with 3 Job Planning Lines of types "G/L Account", "Item", "Resource"
        LibraryJob.CreateJob(SourceJob);
        SourceJob.Validate("Currency Code", '');
        SourceJob.Modify();
        LibraryJob.CreateJobTask(SourceJob, SourceJobTask);
        CreateJobPlanningLine(SourceJobPlanningLine[1], SourceJobPlanningLine[1].Type::"G/L Account", SourceJobTask);
        CreateJobPlanningLine(SourceJobPlanningLine[2], SourceJobPlanningLine[2].Type::Item, SourceJobTask);
        CreateJobPlanningLine(SourceJobPlanningLine[3], SourceJobPlanningLine[3].Type::Resource, SourceJobTask);

        // [GIVEN] Currency "C"
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Job G/L Account Price, Job Item Price, Job Resource Price lines with Currency Code = "C"
        CreateJobGLAccPrice(JobGLAccountPrice[1], SourceJob."No.", SourceJobPlanningLine[1]."No.", Currency.Code);
        CreateJobItemPrice(JobItemPrice[1], SourceJob."No.", SourceJobPlanningLine[2]."No.", Currency.Code);
        CreateJobResourcePrice(JobResourcePrice[1], SourceJob."No.", SourceJobPlanningLine[3]."No.", Currency.Code);

        // [WHEN] Copy Job with Copy Price = true
        TargetJobNo := LibraryUtility.GenerateGUID();
        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJob(SourceJob, TargetJobNo, '', SourceJob."Bill-to Customer No.", '');

        // [THEN] New Job created with Job G/L Account Price, Job Item Price, Job Resource Price lines with Currency Code = "C"
        JobGLAccountPrice[2].SetRange("Job No.", TargetJobNo);
        JobGLAccountPrice[2].SetRange("G/L Account No.", SourceJobPlanningLine[1]."No.");
        JobGLAccountPrice[2].SetRange("Currency Code", Currency.Code);
        Assert.RecordIsNotEmpty(JobGLAccountPrice[2]);

        JobItemPrice[2].SetRange("Job No.", TargetJobNo);
        JobItemPrice[2].SetRange("Item No.", SourceJobPlanningLine[2]."No.");
        JobItemPrice[2].SetRange("Currency Code", Currency.Code);
        Assert.RecordIsNotEmpty(JobItemPrice[2]);

        JobResourcePrice[2].SetRange("Job No.", TargetJobNo);
        JobResourcePrice[2].SetRange(Code, SourceJobPlanningLine[3]."No.");
        JobResourcePrice[2].SetRange("Currency Code", Currency.Code);
        Assert.RecordIsNotEmpty(JobResourcePrice[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyJobWithPriceListsDiffCurrency()
    var
        ResourceGroup: Record "Resource Group";
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: array[3] of Record "Job Planning Line";
        PriceListHeader: array[4] of Record "Price List Header";
        PriceListLine: array[7] of Record "Price List Line";
        Currency: Record Currency;
        CopyJob: Codeunit "Copy Job";
        TargetJobNo: Code[20];
    begin
        // [SCENARIO 409848] Copy Job should not ignore prices with Currency <> Job Currency
        Initialize();
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Job with Currency Code = '' and with 3 Job Planning Lines of types "G/L Account", "Item", "Resource"
        LibraryJob.CreateJob(SourceJob);
        SourceJob.Validate("Currency Code", '');
        SourceJob.Modify();
        LibraryJob.CreateJobTask(SourceJob, SourceJobTask);
        CreateJobPlanningLine(SourceJobPlanningLine[1], SourceJobPlanningLine[1].Type::"G/L Account", SourceJobTask);
        CreateJobPlanningLine(SourceJobPlanningLine[2], SourceJobPlanningLine[2].Type::Item, SourceJobTask);
        CreateJobPlanningLine(SourceJobPlanningLine[3], SourceJobPlanningLine[3].Type::Resource, SourceJobTask);

        // [GIVEN] Currency "C"
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Price list for Job Task with 3 lines for G/L Account, Item, Resource with Currency Code = "C"
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"Job Task", SourceJob."No.", SourceJobTask."Job Task No.");
        PriceListHeader[1].Status := PriceListHeader[1].Status::Active;
        PriceListHeader[1].Modify();
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", SourceJobPlanningLine[1]."No.");
        PriceListLine[1]."Currency Code" := Currency.Code;
        PriceListLine[1].Modify();
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Item, SourceJobPlanningLine[2]."No.");
        PriceListLine[2]."Currency Code" := Currency.Code;
        PriceListLine[2].Status := PriceListLine[2].Status::Active;
        PriceListLine[2].Modify();
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[3], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Resource, SourceJobPlanningLine[3]."No.");
        PriceListLine[3]."Currency Code" := Currency.Code;
        PriceListLine[3].Modify();

        // [GIVEN] Price list for Job  with 3 lines for G/L Account, Item, Resource with Currency Code = "C"
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Job, SourceJob."No.");
        LibraryResource.CreateResourceGroup(ResourceGroup);
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[4], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::"Resource Group", ResourceGroup."No.");

        // [GIVEN] Price list for All Jobs with "Allow Updating Defaults" with 2 lines: one - for Job, second - for Job task
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[3], "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');
        PriceListHeader[3].Validate("Allow Updating Defaults", true);
        PriceListHeader[3].Modify();
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[6], PriceListHeader[3].Code, "Price Source Type"::Job, SourceJob."No.",
            "Price Asset Type"::"G/L Account", SourceJobPlanningLine[1]."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[7], PriceListHeader[3].Code, "Price Type"::Purchase, "Price Source Type"::"Job Task", SourceJob."No.", SourceJobTask."Job Task No.",
            "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", SourceJobPlanningLine[1]."No.");

        // [WHEN] Copy Job with Copy Price = true
        TargetJobNo := LibraryUtility.GenerateGUID();
        CopyJob.SetCopyOptions(true, true, true, 0, 0, 0);
        CopyJob.CopyJob(SourceJob, TargetJobNo, '', SourceJob."Bill-to Customer No.", '');

        // [THEN] New Job created with 2 price lists: 1st for Job with 1 line for "Resource Group"
        PriceListHeader[4].SetRange("Source Type", "Price Source Type"::Job);
        PriceListHeader[4].SetRange("Source No.", TargetJobNo);
        Assert.RecordCount(PriceListHeader[4], 1);
        PriceListHeader[4].FindFirst();
        PriceListHeader[4].TestField(Status, PriceListHeader[2].Status);

        PriceListLine[5].SetRange("Price List Code", PriceListHeader[4].Code);
        PriceListLine[5].SetRange("Source Type", "Price Source Type"::Job);
        PriceListLine[5].SetRange("Source No.", TargetJobNo);
        Assert.RecordCount(PriceListLine[5], 1);
        PriceListLine[5].SetRange("Asset Type", "Price Asset Type"::"Resource Group");
        PriceListLine[5].SetRange("Asset No.", ResourceGroup."No.");
        Assert.RecordCount(PriceListLine[5], 1);

        // [THEN] 2nd includes 3 price list lines for G/L Account, Item, Resource with Currency Code = "C"
        PriceListHeader[4].SetRange("Source Type", "Price Source Type"::"Job Task");
        PriceListHeader[4].SetRange("Parent Source No.", TargetJobNo);
        PriceListHeader[4].SetRange("Source No.", SourceJobTask."Job Task No.");
        Assert.RecordCount(PriceListHeader[4], 1);
        PriceListHeader[4].FindFirst();
        PriceListHeader[4].TestField(Status, PriceListHeader[1].Status);

        PriceListLine[5].SetRange("Price List Code", PriceListHeader[4].Code);
        PriceListLine[5].SetRange("Source Type", "Price Source Type"::"Job Task");
        PriceListLine[5].SetRange("Parent Source No.", TargetJobNo);
        PriceListLine[5].SetRange("Source No.", SourceJobTask."Job Task No.");
        PriceListLine[5].SetRange("Currency Code", Currency.Code);
        PriceListLine[5].SetRange("Asset Type");
        PriceListLine[5].SetRange("Asset No.");
        Assert.RecordCount(PriceListLine[5], 3);

        PriceListLine[5].SetRange("Asset Type", "Price Asset Type"::"G/L Account");
        PriceListLine[5].SetRange("Asset No.", SourceJobPlanningLine[1]."No.");
        Assert.RecordCount(PriceListLine[5], 1);
        PriceListLine[5].FindFirst();
        PriceListLine[5].TestField(Status, PriceListLine[1].Status);

        PriceListLine[5].SetRange("Asset Type", "Price Asset Type"::Item);
        PriceListLine[5].SetRange("Asset No.", SourceJobPlanningLine[2]."No.");
        Assert.RecordCount(PriceListLine[5], 1);
        PriceListLine[5].FindFirst();
        PriceListLine[5].TestField(Status, PriceListLine[2].Status);

        PriceListLine[5].SetRange("Asset Type", "Price Asset Type"::Resource);
        PriceListLine[5].SetRange("Asset No.", SourceJobPlanningLine[3]."No.");
        Assert.RecordCount(PriceListLine[5], 1);
        PriceListLine[5].FindFirst();
        PriceListLine[5].TestField(Status, PriceListLine[3].Status);

        // [THEN] 2 lines added to the "Allow Updating Defaults" price list: one - for Job, second - for Job task
        PriceListLine[5].SetRange("Currency Code");
        PriceListLine[5].SetRange("Asset Type");
        PriceListLine[5].SetRange("Asset No.");
        PriceListLine[5].SetRange("Price List Code", PriceListHeader[3].Code);
        PriceListLine[5].SetRange("Source Type", "Price Source Type"::"Job Task");
        PriceListLine[5].SetRange("Parent Source No.", TargetJobNo);
        PriceListLine[5].SetRange("Source No.", SourceJobTask."Job Task No.");
        Assert.RecordCount(PriceListLine[5], 1);
        PriceListLine[5].SetRange("Source Type", "Price Source Type"::Job);
        PriceListLine[5].SetRange("Source No.", TargetJobNo);
        PriceListLine[5].SetRange("Parent Source No.");
        Assert.RecordCount(PriceListLine[5], 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobSalesPriceWorkTypeCodeToNewLine()
    var
        ResourceGroup: Record "Resource Group";
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        WorkType: Record "Work Type";
        PriceAsset: Record "Price Asset";
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // [SCENARIO 458132] Incorrect values appear on Work type code for other than resource/resource group and the value cannot be removed
        Initialize();

        // [GIVEN] Enable Extended Price Calculation Feature 
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Create Resource Group, Work Type, Job, Job Task
        LibraryResource.CreateResourceGroup(ResourceGroup);
        LibraryResource.CreateWorkType(WorkType);
        LibraryJob.CreateJob(SourceJob);
        LibraryJob.CreateJobTask(SourceJob, SourceJobTask);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        // [GIVEN] Price list for Job Task with 2 lines for Resource Group, and Item
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"Job Task", SourceJob."No.", SourceJobTask."Job Task No.");
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"Resource Group", ResourceGroup."No.");
        PriceListLine[1].Validate("Work Type Code", WorkType.Code);
        PriceListLine[1].Modify();
        PriceListLine[1].CopyTo(PriceAsset);

        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine[2]."Work Type Code" := PriceAsset."Work Type Code";
        PriceListLine[2].Modify();

        // [VERIFY] Verify: Price Line List Work Type Code should equal Price Asset Work Type Code
        Assert.AreEqual(PriceAsset."Work Type Code", PriceListLine[2]."Work Type Code", StrSubstNo(TestFieldValueErr, PriceListLine[2].FieldCaption("Work Type Code"), Format(PriceListLine[2]."Work Type Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriceFromItemAndResourceWhenCopyJob()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        TargetJob: Record Job;
        TargetJobTask: Record "Job Task";
        CopyJob: Codeunit "Copy Job";
    begin
        // [SCENARIO 472435] Job prices get copied although the "Copy Job" action is used with the parameter "Copy Job Prices" = false
        Initialize();

        // [GIVEN] Create Source Job, Job Task, and Job Planning Lines with Item and Resourc
        JobSetUpWithItemAndResource(SourceJob, SourceJobTask);

        // [THEN] Initialize Target Job, Job Task
        InitJobTask(TargetJob, SourceJob."Bill-to Customer No.", '');
        TargetJobTask.Init();
        TargetJobTask."Job No." := TargetJob."No.";
        TargetJobTask."Job Task No." := SourceJobTask."Job Task No.";
        TargetJobTask.Insert();

        // [WHEN] Use Copy Job codeunit to copy all the Job Planning Line when Parameter "Copy Job Prices" is set to false
        CopyJob.SetCopyOptions(false, true, true, 0, 0, 0);
        CopyJob.CopyJobPlanningLines(SourceJobTask, TargetJobTask);

        // [VERIFY] Verify: Unit Cost and Price of Target Job Planning Lines with Item and Resource
        VerifyUnitCostAndPriceOnJobPlanningLine(SourceJobTask, TargetJobTask);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyJobPlanningLinesToActionShouldCopyPricesAndCost()
    var
        SourceJob: Record Job;
        SourceJobTask: Record "Job Task";
        SourceJobPlanningLine: Record "Job Planning Line";
        TargetJobTask: Record "Job Task";
        TargetJobPlanningLine: Record "Job Planning Line";
        CopyJob: Codeunit "Copy Job";
    begin
        // [SCENARIO 484709] [IcM] Copy Job Planning Lines no longer copying unit price and unit cost
        Initialize();

        // [GIVEN] Create Source Job, Job Task, and Job Planning Lines with Item and Resource.
        JobSetUpWithItemAndResource(SourceJob, SourceJobTask);

        // [GIVEN] Create Target Job Task for Source Job.
        LibraryJob.CreateJobTask(SourceJob, TargetJobTask);

        // [GIVEN] Use Copy Job codeunit to Set Copy Quanity & Copy Prices parameter as True.
        CopyJob.SetCopyQuantity(true);
        CopyJob.SetCopyPrices(true);

        // [GIVEN] Use Copy Job Codeunit to Copy Job Planning Lines.
        CopyJob.CopyJobPlanningLines(SourceJobTask, TargetJobTask);

        // [GIVEN] Find Source Job planning Lines.
        SourceJobPlanningLine.SetRange("Job No.", SourceJob."No.");
        SourceJobPlanningLine.SetRange("Job Task No.", SourceJobTask."Job Task No.");
        SourceJobPlanningLine.FindFirst();

        // [WHEN] Find Target Job Planning Lines.
        TargetJobPlanningLine.SetRange("Job No.", SourceJob."No.");
        TargetJobPlanningLine.SetRange("Job Task No.", TargetJobTask."Job Task No.");
        TargetJobPlanningLine.FindFirst();

        // [VERIFY] Verify Source Job Planning Lines Costs & Prices match with Target Job Planning Lines Costs & Prices.
        Assert.AreEqual(SourceJobPlanningLine."Unit Cost", TargetJobPlanningLine."Unit Cost", UnitCostMustMatchErr);
        Assert.AreEqual(SourceJobPlanningLine."Total Cost", TargetJobPlanningLine."Total Cost", TotalCostMustMatchErr);
        Assert.AreEqual(SourceJobPlanningLine."Unit Price", TargetJobPlanningLine."Unit Price", UnitPriceMustMatchErr);
        Assert.AreEqual(SourceJobPlanningLine."Total Price", TargetJobPlanningLine."Total Price", TotalPriceMustMatchErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT C Copy Job");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT C Copy Job");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT C Copy Job");
    end;

    local procedure SetUp(var SourceJob: Record Job; var SourceJobTask: Record "Job Task"; var SourceJobPlanningLine: Record "Job Planning Line")
    begin
        LibraryJob.CreateJob(SourceJob);

        LibraryJob.CreateJobTask(SourceJob, SourceJobTask);

        LibraryJob.CreateJobPlanningLine(
          SourceJobPlanningLine."Line Type"::"Both Budget and Billable", SourceJobPlanningLine.Type::Item, SourceJobTask,
          SourceJobPlanningLine);
        SourceJobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(1000));
        SourceJobPlanningLine.Modify();
    end;

    local procedure UpdateJobTaskLines(JobNo: Code[20]; JobTaskType: Enum "Job Task Type")
    var
        JobWIPMethod: Record "Job WIP Method";
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);

        JobTask.SetRange("Job No.", JobNo);
        JobTask.SetRange("Job Task Type", JobTaskType);
        JobTask.FindSet(true);
        repeat
            JobTask."WIP-Total" := JobTask."WIP-Total"::Total;
            JobTask."WIP Method" := JobWIPMethod.Code;
            JobTask.Modify();
        until JobTask.Next() = 0;
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobPlanningLineType: Enum "Job Planning Line Type"; JobTask: record "Job Task")
    begin
        LibraryJob.CreateJobPlanningLine(
            JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLineType, JobTask,
            JobPlanningLine);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(1000));
        JobPlanningLine.Modify();
    end;

    local procedure CreateJobGLAccPrice(var JobGLAccountPrice: Record "Job G/L Account Price"; JobNo: Code[20]; GLAccountNo: Code[20]; CurrencyCode: Code[20])
    begin
        LibraryJob.CreateJobGLAccountPrice(
            JobGLAccountPrice, JobNo, '', GLAccountNo, CurrencyCode);
        JobGLAccountPrice."Unit Price" := LibraryRandom.RandIntInRange(1, 10);
        JobGLAccountPrice.Modify();
    end;

    local procedure CreateJobItemPrice(var JobItemPrice: Record "Job Item Price"; JobNo: Code[20]; ItemNo: Code[20]; CurrencyCode: Code[20])
    begin
        LibraryJob.CreateJobItemPrice(
            JobItemPrice, JobNo, '', ItemNo, CurrencyCode, '', '');
        JobItemPrice."Unit Price" := LibraryRandom.RandIntInRange(1, 10);
        JobItemPrice.Modify();
    end;

    local procedure CreateJobResourcePrice(var JobResourcePrice: Record "Job Resource Price"; JobNo: Code[20]; ResourceNo: Code[20]; CurrencyCode: Code[20])
    begin
        LibraryJob.CreateJobResourcePrice(
            JobResourcePrice, JobNo, '', JobResourcePrice.Type::Resource, ResourceNo, '', CurrencyCode);
        JobResourcePrice."Unit Price" := LibraryRandom.RandIntInRange(1, 10);
        JobResourcePrice.Modify();
    end;

    local procedure CompareJobFields(SourceJob: Record Job; TargetJob: Record Job)
    begin
        Assert.AreEqual(SourceJob."Search Description", TargetJob."Search Description", '');
        Assert.AreEqual(SourceJob.Description, TargetJob.Description, '');
        Assert.AreEqual(SourceJob."Description 2", TargetJob."Description 2", '');
        Assert.AreEqual(SourceJob."Bill-to Customer No.", TargetJob."Bill-to Customer No.", '');
        Assert.AreEqual(TargetJob."Creation Date", Today, '');
        Assert.AreEqual(SourceJob."Starting Date", TargetJob."Starting Date", '');
        Assert.AreEqual(SourceJob."Ending Date", TargetJob."Ending Date", '');
        Assert.AreEqual(TargetJob.Status, TargetJob.Status::Planning, '');
        Assert.AreEqual(SourceJob."Person Responsible", TargetJob."Person Responsible", '');
        Assert.AreEqual(SourceJob."Global Dimension 1 Code", TargetJob."Global Dimension 1 Code", '');
        Assert.AreEqual(SourceJob."Global Dimension 2 Code", TargetJob."Global Dimension 2 Code", '');
        Assert.AreEqual(SourceJob."Job Posting Group", TargetJob."Job Posting Group", '');
        Assert.AreEqual(SourceJob.Blocked, TargetJob.Blocked, '');
        Assert.AreEqual(TargetJob."Last Date Modified", Today, '');
        Assert.AreEqual(SourceJob."Customer Disc. Group", TargetJob."Customer Disc. Group", '');
        Assert.AreEqual(SourceJob."Customer Price Group", TargetJob."Customer Price Group", '');
        Assert.AreEqual(SourceJob."Language Code", TargetJob."Language Code", '');
        Assert.AreEqual(SourceJob."Bill-to Name", TargetJob."Bill-to Name", '');
        Assert.AreEqual(SourceJob."Bill-to Address", TargetJob."Bill-to Address", '');
        Assert.AreEqual(SourceJob."Bill-to Address 2", TargetJob."Bill-to Address 2", '');
        Assert.AreEqual(SourceJob."Bill-to City", TargetJob."Bill-to City", '');
        Assert.AreEqual(SourceJob."Bill-to County", TargetJob."Bill-to County", '');
        Assert.AreEqual(SourceJob."Bill-to Post Code", TargetJob."Bill-to Post Code", '');
        Assert.AreEqual(SourceJob."No. Series", TargetJob."No. Series", '');
        Assert.AreEqual(SourceJob."Bill-to Country/Region Code", TargetJob."Bill-to Country/Region Code", '');
        Assert.AreEqual(SourceJob."Bill-to Name 2", TargetJob."Bill-to Name 2", '');
        Assert.AreEqual(SourceJob.Reserve, TargetJob.Reserve, '');
        Assert.AreEqual(SourceJob."WIP Method", TargetJob."WIP Method", '');
        Assert.AreEqual(SourceJob."Currency Code", TargetJob."Currency Code", '');
        Assert.AreEqual(SourceJob."Bill-to Contact No.", TargetJob."Bill-to Contact No.", '');
        Assert.AreEqual(SourceJob."Bill-to Contact", TargetJob."Bill-to Contact", '');
        Assert.AreEqual(SourceJob."WIP Posting Date", TargetJob."WIP Posting Date", '');
        Assert.AreEqual(SourceJob."Invoice Currency Code", TargetJob."Invoice Currency Code", '');
        Assert.AreEqual(SourceJob."Exch. Calculation (Cost)", TargetJob."Exch. Calculation (Cost)", '');
        Assert.AreEqual(SourceJob."Exch. Calculation (Price)", TargetJob."Exch. Calculation (Price)", '');
        Assert.AreEqual(SourceJob."Allow Schedule/Contract Lines", TargetJob."Allow Schedule/Contract Lines", '');
        Assert.AreEqual(SourceJob.Complete, TargetJob.Complete, '');
        Assert.AreEqual(SourceJob."Apply Usage Link", TargetJob."Apply Usage Link", '');
        Assert.AreEqual(SourceJob."WIP Posting Method", TargetJob."WIP Posting Method", '');
        Assert.AreEqual(SourceJob."Resource Filter", TargetJob."Resource Filter", '');
        Assert.AreEqual(SourceJob."Posting Date Filter", TargetJob."Posting Date Filter", '');
        Assert.AreEqual(SourceJob."Resource Gr. Filter", TargetJob."Resource Gr. Filter", '');
        Assert.AreEqual(SourceJob."Planning Date Filter", TargetJob."Planning Date Filter", '');

        SourceJob.CalcFields(Comment,
          "Scheduled Res. Qty.",
          "Scheduled Res. Gr. Qty.",
          "Total WIP Cost Amount",
          "Total WIP Cost G/L Amount",
          "WIP Entries Exist",
          "WIP G/L Posting Date");

        SourceJob.CalcFields("Recog. Sales Amount",
          "Recog. Sales G/L Amount",
          "Recog. Costs Amount",
          "Recog. Costs G/L Amount",
          "Total WIP Sales Amount",
          "Total WIP Sales G/L Amount",
          "WIP Completion Calculated",
          "Next Invoice Date",
          "WIP Warnings",
          "Applied Costs G/L Amount",
          "Applied Sales G/L Amount",
          "Calc. Recog. Sales Amount",
          "Calc. Recog. Costs Amount",
          "Calc. Recog. Sales G/L Amount",
          "Calc. Recog. Costs G/L Amount",
          "WIP Completion Posted");

        TargetJob.CalcFields(Comment,
          "Scheduled Res. Qty.",
          "Scheduled Res. Gr. Qty.",
          "Total WIP Cost Amount",
          "Total WIP Cost G/L Amount",
          "WIP Entries Exist",
          "WIP G/L Posting Date");

        TargetJob.CalcFields("Recog. Sales Amount",
          "Recog. Sales G/L Amount",
          "Recog. Costs Amount",
          "Recog. Costs G/L Amount",
          "Total WIP Sales Amount",
          "Total WIP Sales G/L Amount",
          "WIP Completion Calculated",
          "Next Invoice Date",
          "WIP Warnings",
          "Applied Costs G/L Amount",
          "Applied Sales G/L Amount",
          "Calc. Recog. Sales Amount",
          "Calc. Recog. Costs Amount",
          "Calc. Recog. Sales G/L Amount",
          "Calc. Recog. Costs G/L Amount",
          "WIP Completion Posted");

        Assert.AreEqual(SourceJob.Comment, TargetJob.Comment, '');
        Assert.AreEqual(SourceJob."Scheduled Res. Qty.", TargetJob."Scheduled Res. Qty.", '');
        Assert.AreEqual(SourceJob."Scheduled Res. Gr. Qty.", TargetJob."Scheduled Res. Gr. Qty.", '');
        Assert.AreEqual(SourceJob."Total WIP Cost Amount", TargetJob."Total WIP Cost Amount", '');
        Assert.AreEqual(SourceJob."Total WIP Cost G/L Amount", TargetJob."Total WIP Cost G/L Amount", '');
        Assert.AreEqual(SourceJob."WIP Entries Exist", TargetJob."WIP Entries Exist", '');
        Assert.AreEqual(SourceJob."WIP G/L Posting Date", TargetJob."WIP G/L Posting Date", '');
        Assert.AreEqual(SourceJob."Recog. Sales Amount", TargetJob."Recog. Sales Amount", '');
        Assert.AreEqual(SourceJob."Recog. Sales G/L Amount", TargetJob."Recog. Sales G/L Amount", '');
        Assert.AreEqual(SourceJob."Recog. Costs Amount", TargetJob."Recog. Costs Amount", '');
        Assert.AreEqual(SourceJob."Recog. Costs G/L Amount", TargetJob."Recog. Costs G/L Amount", '');
        Assert.AreEqual(SourceJob."Total WIP Sales Amount", TargetJob."Total WIP Sales Amount", '');
        Assert.AreEqual(SourceJob."Total WIP Sales G/L Amount", TargetJob."Total WIP Sales G/L Amount", '');
        Assert.AreEqual(SourceJob."WIP Completion Calculated", TargetJob."WIP Completion Calculated", '');
        Assert.AreEqual(SourceJob."Next Invoice Date", TargetJob."Next Invoice Date", '');
        Assert.AreEqual(SourceJob."WIP Warnings", TargetJob."WIP Warnings", '');
        Assert.AreEqual(SourceJob."Applied Costs G/L Amount", TargetJob."Applied Costs G/L Amount", '');
        Assert.AreEqual(SourceJob."Applied Sales G/L Amount", TargetJob."Applied Sales G/L Amount", '');
        Assert.AreEqual(SourceJob."Calc. Recog. Sales Amount", TargetJob."Calc. Recog. Sales Amount", '');
        Assert.AreEqual(SourceJob."Calc. Recog. Costs Amount", TargetJob."Calc. Recog. Costs Amount", '');
        Assert.AreEqual(SourceJob."Calc. Recog. Sales G/L Amount", TargetJob."Calc. Recog. Sales G/L Amount", '');
        Assert.AreEqual(SourceJob."Calc. Recog. Costs G/L Amount", TargetJob."Calc. Recog. Costs G/L Amount", '');
        Assert.AreEqual(SourceJob."WIP Completion Posted", TargetJob."WIP Completion Posted", '');
    end;

    local procedure CompareJobTaskFields(SourceJobTask: Record "Job Task"; TargetJobTask: Record "Job Task")
    begin
        Assert.AreEqual(SourceJobTask."Job Task No.", TargetJobTask."Job Task No.", '');
        Assert.AreEqual(SourceJobTask.Description, TargetJobTask.Description, '');
        Assert.AreEqual(SourceJobTask."Job Task Type", TargetJobTask."Job Task Type", '');
        Assert.AreEqual(SourceJobTask."WIP-Total", TargetJobTask."WIP-Total", '');
        Assert.AreEqual(SourceJobTask."Job Posting Group", TargetJobTask."Job Posting Group", '');
        Assert.AreEqual(SourceJobTask."WIP Method", TargetJobTask."WIP Method", '');
        Assert.AreEqual(SourceJobTask.Totaling, TargetJobTask.Totaling, '');
        Assert.AreEqual(SourceJobTask."New Page", TargetJobTask."New Page", '');
        Assert.AreEqual(SourceJobTask."No. of Blank Lines", TargetJobTask."No. of Blank Lines", '');
        Assert.AreEqual(SourceJobTask.Indentation, TargetJobTask.Indentation, '');
        Assert.AreEqual(SourceJobTask."Recognized Sales Amount", TargetJobTask."Recognized Sales Amount", '');
        Assert.AreEqual(SourceJobTask."Recognized Costs Amount", TargetJobTask."Recognized Costs Amount", '');
        Assert.AreEqual(SourceJobTask."Recognized Sales G/L Amount", TargetJobTask."Recognized Sales G/L Amount", '');
        Assert.AreEqual(SourceJobTask."Recognized Costs G/L Amount", TargetJobTask."Recognized Costs G/L Amount", '');
        Assert.AreEqual(SourceJobTask."Global Dimension 1 Code", TargetJobTask."Global Dimension 1 Code", '');
        Assert.AreEqual(SourceJobTask."Global Dimension 2 Code", TargetJobTask."Global Dimension 2 Code", '');
        Assert.AreEqual(SourceJobTask."Posting Date Filter", TargetJobTask."Posting Date Filter", '');
        Assert.AreEqual(SourceJobTask."Planning Date Filter", TargetJobTask."Planning Date Filter", '');

        SourceJobTask.CalcFields(
          "Schedule (Total Cost)",
          "Schedule (Total Price)",
          "Usage (Total Cost)",
          "Usage (Total Price)",
          "Contract (Total Cost)",
          "Contract (Total Price)",
          "Contract (Invoiced Price)",
          "Contract (Invoiced Cost)",
          "Outstanding Orders",
          "Amt. Rcd. Not Invoiced",
          "Remaining (Total Cost)",
          "Remaining (Total Price)");

        TargetJobTask.CalcFields(
          "Schedule (Total Cost)",
          "Schedule (Total Price)",
          "Usage (Total Cost)",
          "Usage (Total Price)",
          "Contract (Total Cost)",
          "Contract (Total Price)",
          "Contract (Invoiced Price)",
          "Contract (Invoiced Cost)",
          "Outstanding Orders",
          "Amt. Rcd. Not Invoiced",
          "Remaining (Total Cost)",
          "Remaining (Total Price)");

        Assert.AreEqual(SourceJobTask."Schedule (Total Cost)", TargetJobTask."Schedule (Total Cost)", '');
        Assert.AreEqual(SourceJobTask."Schedule (Total Price)", TargetJobTask."Schedule (Total Price)", '');
        Assert.AreEqual(SourceJobTask."Usage (Total Cost)", TargetJobTask."Usage (Total Cost)", '');
        Assert.AreEqual(SourceJobTask."Usage (Total Price)", TargetJobTask."Usage (Total Price)", '');
        Assert.AreEqual(SourceJobTask."Contract (Total Cost)", TargetJobTask."Contract (Total Cost)", '');
        Assert.AreEqual(SourceJobTask."Contract (Total Price)", TargetJobTask."Contract (Total Price)", '');
        Assert.AreEqual(SourceJobTask."Contract (Invoiced Price)", TargetJobTask."Contract (Invoiced Price)", '');
        Assert.AreEqual(SourceJobTask."Contract (Invoiced Cost)", TargetJobTask."Contract (Invoiced Cost)", '');
        Assert.AreEqual(SourceJobTask."Outstanding Orders", TargetJobTask."Outstanding Orders", '');
        Assert.AreEqual(SourceJobTask."Amt. Rcd. Not Invoiced", TargetJobTask."Amt. Rcd. Not Invoiced", '');
        Assert.AreEqual(SourceJobTask."Remaining (Total Cost)", TargetJobTask."Remaining (Total Cost)", '');
        Assert.AreEqual(SourceJobTask."Remaining (Total Price)", TargetJobTask."Remaining (Total Price)", '');
    end;

    local procedure CompareJobPlanningLineFields(SourceJobPlanningLine: Record "Job Planning Line"; TargetJobPlanningLine: Record "Job Planning Line"; QuantityCopied: Boolean)
    begin
        Assert.AreEqual(TargetJobPlanningLine."Planning Date", WorkDate(), '');
        Assert.AreEqual(SourceJobPlanningLine."Document No.", TargetJobPlanningLine."Document No.", '');
        Assert.AreEqual(SourceJobPlanningLine.Type, TargetJobPlanningLine.Type, '');
        Assert.AreEqual(SourceJobPlanningLine."No.", TargetJobPlanningLine."No.", '');
        Assert.AreEqual(SourceJobPlanningLine.Description, TargetJobPlanningLine.Description, '');
        if QuantityCopied then
            Assert.AreEqual(SourceJobPlanningLine.Quantity, TargetJobPlanningLine.Quantity, '')
        else
            Assert.AreEqual(TargetJobPlanningLine.Quantity, 0, '');
        Assert.AreEqual(SourceJobPlanningLine."Direct Unit Cost (LCY)", TargetJobPlanningLine."Direct Unit Cost (LCY)", '');
        Assert.AreEqual(SourceJobPlanningLine."Unit Cost (LCY)", TargetJobPlanningLine."Unit Cost (LCY)", '');
        if QuantityCopied then
            Assert.AreEqual(SourceJobPlanningLine."Total Cost (LCY)", TargetJobPlanningLine."Total Cost (LCY)", '')
        else
            Assert.AreEqual(TargetJobPlanningLine."Total Cost (LCY)", 0, '');
        Assert.AreEqual(SourceJobPlanningLine."Unit Price (LCY)", TargetJobPlanningLine."Unit Price (LCY)", '');
        if QuantityCopied then
            Assert.AreEqual(SourceJobPlanningLine."Total Price (LCY)", TargetJobPlanningLine."Total Price (LCY)", '')
        else
            Assert.AreEqual(TargetJobPlanningLine."Total Price (LCY)", 0, '');
        Assert.AreEqual(SourceJobPlanningLine."Resource Group No.", TargetJobPlanningLine."Resource Group No.", '');
        Assert.AreEqual(SourceJobPlanningLine."Unit of Measure Code", TargetJobPlanningLine."Unit of Measure Code", '');
        Assert.AreEqual(SourceJobPlanningLine."Location Code", TargetJobPlanningLine."Location Code", '');
    end;

    local procedure CreateJobDefaultDimension(JobNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Job, JobNo, Dimension.Code, DimensionValue.Code);
        LibraryVariableStorage.Enqueue(Dimension.Code);
    end;

    local procedure CreateJobTaskDimension(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        Dimension: Record Dimension;
        JobTaskDimension: Record "Job Task Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        JobTaskDimension.Init();
        JobTaskDimension.Validate("Job No.", JobNo);
        JobTaskDimension.Validate("Job Task No.", JobTaskNo);
        JobTaskDimension.Validate("Dimension Code", Dimension.Code);
        JobTaskDimension.Validate("Dimension Value Code", DimensionValue.Code);
        JobTaskDimension.Insert(true);
    end;

    local procedure DeleteJobTaskDimension(JobNo: Code[20]; JobTaskNo: Code[20]; DimCode: Code[20])
    var
        JobTaskDimension: Record "Job Task Dimension";
    begin
        JobTaskDimension.Get(JobNo, JobTaskNo, DimCode);
        JobTaskDimension.Delete(true);
    end;

    local procedure UpdateJobTaskDimensionValue(JobNo: Code[20]; JobTaskNo: Code[20]; DimCode: Code[20])
    var
        JobTaskDimension: Record "Job Task Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimCode);
        JobTaskDimension.Get(JobNo, JobTaskNo, DimCode);
        JobTaskDimension.Validate("Dimension Value Code", DimensionValue.Code);
        JobTaskDimension.Modify(true);
    end;

    local procedure SetupManualNos(ManualNos: Boolean)
    var
        JobsSetup: Record "Jobs Setup";
        NoSeries: Record "No. Series";
    begin
        JobsSetup.Get();
        NoSeries.Get(JobsSetup."Job Nos.");
        NoSeries."Manual Nos." := ManualNos;
        NoSeries.Modify();
    end;

    local procedure InitJobTask(var TargetJob: Record Job; CustNo: Code[20]; WIPMethodCode: Code[20])
    begin
        TargetJob.Init();
        TargetJob."No." := LibraryUtility.GenerateGUID();
        TargetJob.Validate("Bill-to Customer No.", CustNo);
        TargetJob."WIP Method" := WIPMethodCode;
        TargetJob.Insert();
    end;

    local procedure MockJobTask(var JobTask: Record "Job Task"; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        JobTask.Init();
        JobTask."Job No." := JobNo;
        JobTask."Job Task No." := JobTaskNo;
        JobTask.Insert();
    end;

    local procedure MockJobPlanningLineWithSpecificLineNo(JobTask: Record "Job Task"; LineNo: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", JobTask."Job No.");
        JobPlanningLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.Validate("Line No.", LineNo);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", LibraryJob.FindConsumable(JobPlanningLine.Type::Item));
        JobPlanningLine.Insert(true);
    end;

    local procedure VerifyJobPlanningLineCount(JobNo: Code[20]; JobTaskNo: Code[20]; ExpectedCount: Integer)
    var
        DummyJobPlanningLine: Record "Job Planning Line";
    begin
        DummyJobPlanningLine.SetRange("Job No.", JobNo);
        DummyJobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        Assert.RecordCount(DummyJobPlanningLine, ExpectedCount);
    end;

    local procedure VerifyJobPlanningLineLedgerEntryFields(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        JobPlanningLine.FindFirst();
        JobPlanningLine.TestField("Ledger Entry No.", 0);
        JobPlanningLine.TestField("Ledger Entry Type", JobPlanningLine."Ledger Entry Type"::" ");
    end;

    local procedure VerifyJobTaskDimension(JobNo: Code[20]; JobTaskNo: Code[20]; DimCode: Code[20]; DimValueCode: Code[20])
    var
        JobTaskDimension: Record "Job Task Dimension";
    begin
        JobTaskDimension.Get(JobNo, JobTaskNo, DimCode);
        JobTaskDimension.TestField("Dimension Value Code", DimValueCode);
    end;

    local procedure VerifyJobTaskDimensionCount(JobNo: Code[20]; JobTaskNo: Code[20]; ExpectedCount: Integer)
    var
        JobTaskDimension: Record "Job Task Dimension";
    begin
        JobTaskDimension.SetRange("Job No.", JobNo);
        JobTaskDimension.SetRange("Job Task No.", JobTaskNo);
        Assert.RecordCount(JobTaskDimension, ExpectedCount);
    end;

    local procedure VerifyCopyTaskDimensions(SourceJobNo: Code[20]; TargetJobNo: Code[20]; TaskNo: Code[20])
    var
        JobTaskDimension: Record "Job Task Dimension";
        "Count": Integer;
    begin
        JobTaskDimension.SetRange("Job No.", SourceJobNo);
        JobTaskDimension.SetRange("Job Task No.", TaskNo);
        JobTaskDimension.FindSet();
        repeat
            VerifyJobTaskDimension(TargetJobNo, TaskNo, JobTaskDimension."Dimension Code", JobTaskDimension."Dimension Value Code");
            Count += 1;
        until JobTaskDimension.Next() = 0;
        VerifyJobTaskDimensionCount(TargetJobNo, TaskNo, Count);
    end;

    local procedure JobSetUpWithItemAndResource(var SourceJob: Record Job; var SourceJobTask: Record "Job Task")
    var
        SourceJobPlanningLine: Record "Job Planning Line";
    begin
        LibraryJob.CreateJob(SourceJob);

        LibraryJob.CreateJobTask(SourceJob, SourceJobTask);

        LibraryJob.CreateJobPlanningLine(
            SourceJobPlanningLine."Line Type"::"Both Budget and Billable",
            SourceJobPlanningLine.Type::Item,
            SourceJobTask,
            SourceJobPlanningLine);

        SourceJobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(1000));
        SourceJobPlanningLine.Validate("Unit Cost", LibraryRandom.RandInt(1000));
        SourceJobPlanningLine.Validate("Unit Price", LibraryRandom.RandInt(1000));
        SourceJobPlanningLine.Modify();

        LibraryJob.CreateJobPlanningLine(
            SourceJobPlanningLine."Line Type"::"Both Budget and Billable",
            SourceJobPlanningLine.Type::Resource,
            SourceJobTask,
            SourceJobPlanningLine);

        SourceJobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(1000));
        SourceJobPlanningLine.Validate("Unit Cost", LibraryRandom.RandInt(1000));
        SourceJobPlanningLine.Validate("Unit Price", LibraryRandom.RandInt(1000));
        SourceJobPlanningLine.Modify();
    end;

    local procedure VerifyUnitCostAndPriceOnJobPlanningLine(SourceJobTask: Record "Job Task"; TargetJobTask: Record "Job Task")
    var
        SourceJobPlanningLine: Record "Job Planning Line";
        TargetJobPlanningLine: Record "Job Planning Line";
        Item: Record Item;
        Resource: Record Resource;
    begin
        SourceJobPlanningLine.SetRange("Job No.", SourceJobTask."Job No.");
        SourceJobPlanningLine.SetRange("Job Task No.", SourceJobTask."Job Task No.");
        SourceJobPlanningLine.FindSet();
        repeat
            TargetJobPlanningLine.Get(TargetJobTask."Job No.", TargetJobTask."Job Task No.", SourceJobPlanningLine."Line No.");
            Assert.IsFalse(SourceJobPlanningLine."Unit Cost" = TargetJobPlanningLine."Unit Cost", '');
            Assert.IsFalse(SourceJobPlanningLine."Unit Price" = TargetJobPlanningLine."Unit Price", '');

            case TargetJobPlanningLine.Type of
                TargetJobPlanningLine.Type::Item:
                    begin
                        Item.Get(TargetJobPlanningLine."No.");
                        Assert.IsTrue(TargetJobPlanningLine."Unit Cost" = Item."Unit Cost", '');
                        Assert.IsTrue(TargetJobPlanningLine."Unit Price" = Item."Unit Price", '');
                    end;
                TargetJobPlanningLine.Type::Resource:
                    begin
                        Resource.Get(TargetJobPlanningLine."No.");
                        Assert.IsTrue(TargetJobPlanningLine."Unit Cost" = Resource."Unit Cost", '');
                        Assert.IsTrue(TargetJobPlanningLine."Unit Price" = Resource."Unit Price", '');
                    end;
            end;
        until SourceJobPlanningLine.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

