codeunit 136357 "UT T Job WIP Total"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [WIP Total] [Job]
        IsInitialized := false;
    end;

    var
        Text001: Label 'Rolling back changes...';
        Job: Record Job;
        JobTask: Record "Job Task";
        JobWIPTotal: Record "Job WIP Total";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        IsInitialized: Boolean;
        JobTaskTotalingLbl: Label '..%1', Comment = '%1 = Job Task No.';
        ValueMustBeEqualErr: Label '%1 must be equal to %2', Comment = '%1 = Caption , %2 = Expected Amount';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT T Job WIP Total");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT T Job WIP Total");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        UpdateJobPostingGroups();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT T Job WIP Total");
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

    [Normal]
    local procedure SetUp()
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify();

        LibraryJob.CreateJobTask(Job, JobTask);

        JobWIPTotal.Init();
        JobWIPTotal."Job No." := Job."No.";
        JobWIPTotal."Job Task No." := JobTask."Job Task No.";
        JobWIPTotal.Insert();
    end;

    [Normal]
    local procedure TearDown()
    begin
        Clear(Job);
        Clear(JobTask);
        Clear(JobWIPTotal);
        asserterror Error(Text001);
        IsInitialized := false;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletion()
    var
        JobWIPWarning: Record "Job WIP Warning";
    begin
        Initialize();
        SetUp();

        // Verify that a Job WIP Total can be deleted and that all Job WIP Warnings are deleted as well.
        JobWIPWarning.Init();
        JobWIPWarning."Job WIP Total Entry No." := JobWIPTotal."Entry No.";
        JobWIPWarning.Insert(true);

        JobWIPWarning.SetRange("Job WIP Total Entry No.", JobWIPTotal."Entry No.");
        Assert.IsTrue(JobWIPWarning.FindFirst(), 'No Job WIP Warnings were found.');

        Assert.IsTrue(JobWIPTotal.Delete(true), 'The Job WIP Total could not be deleted.');
        Assert.IsFalse(JobWIPWarning.FindFirst(), 'Job WIP Warnings still exist after deletion of Record.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldWIPWarnings()
    var
        JobWIPWarning: Record "Job WIP Warning";
    begin
        Initialize();
        SetUp();

        // Verify that WIP Warnings is false when no warnings exist.
        Assert.IsFalse(JobWIPTotal."WIP Warnings", 'WIP Warning is true, even if no warnings exist.');

        // Verify that WIP Warnings is true when warnings exist.
        JobWIPWarning.Init();
        JobWIPWarning."Job No." := Job."No.";
        JobWIPWarning."Job Task No." := JobTask."Job Task No.";
        JobWIPWarning."Job WIP Total Entry No." := JobWIPTotal."Entry No.";
        JobWIPWarning.Insert();
        JobWIPTotal.CalcFields("WIP Warnings");
        Assert.IsTrue(JobWIPTotal."WIP Warnings", 'WIP Warning is false, even if warnings exist.');

        TearDown();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalWIPSalesGLAmountIsCalculatedCorrectlyForJobWithPerJobWIPPostingMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPage: TestPage "Job Card";
        ResourceNo: Code[20];
        UnitPrice: Integer;
    begin
        Initialize();
        UnitPrice := LibraryRandom.RandIntInRange(201, 400);

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Usage (Total Price)");
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job");
        Job.Modify(true);

        // Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.Modify(true);

        // [GIVEN] Post usage on the Job Task
        ResourceNo := LibraryResource.CreateResourceNo();
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", ResourceNo);
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Price", UnitPrice);
        JobJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [WHEN] 'Calculate WIP' and 'Post WIP to G/L' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // [THEN] 'Total WIP Sales G/L Amount' is calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Sales G/L Amount".AssertEquals(-UnitPrice);
        JobPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalWIPSalesGLAmountIsCalculatedCorrectlyForJobWithPerJobLedgerEntryWIPPostingMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPage: TestPage "Job Card";
        ResourceNo: Code[20];
        UnitPrice: Integer;
    begin
        Initialize();
        UnitPrice := LibraryRandom.RandIntInRange(201, 400);

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job Ledger Entry'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Usage (Total Price)");
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job Ledger Entry");
        Job.Modify(true);

        // Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.Modify(true);

        // [GIVEN] Post usage on the Job Task
        ResourceNo := LibraryResource.CreateResourceNo();
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", ResourceNo);
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Price", UnitPrice);
        JobJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [WHEN] 'Calculate WIP' and 'Post WIP to G/L' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // [THEN] 'Total WIP Sales G/L Amount' is calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Sales G/L Amount".AssertEquals(-UnitPrice);
        JobPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure VerifyAmountsForJobWithPerJobLedgerEntryWithMultipleJobJournalAndSalesInvoice()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobPage: TestPage "Job Card";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        ResourceNo: Code[20];
        GLAccountNo: Code[20];
        ResourceUnitPrice: Integer;
        ResourceUnitCost: Integer;
        ResourceNewUnitPrice: Integer;
        GLUnitPrice: Integer;
        GLUnitCost: Integer;
    begin
        Initialize();
        ResourceUnitPrice := LibraryRandom.RandIntInRange(101, 200);
        ResourceNewUnitPrice := LibraryRandom.RandIntInRange(51, 100);
        ResourceUnitCost := LibraryRandom.RandIntInRange(1, 100);
        GLUnitPrice := LibraryRandom.RandIntInRange(401, 500);
        GLUnitCost := LibraryRandom.RandIntInRange(301, 400);

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job Ledger Entry'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Usage (Total Price)");
        JobWIPMethod.TestField("WIP Cost", true); //Make sure that this field is set to true.
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job Ledger Entry");
        Job.Modify(true);

        // Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.Modify(true);

        // [GIVEN] Post usage for a Resource the Job Task
        ResourceNo := LibraryResource.CreateResourceNo();
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", ResourceNo);
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Price", ResourceUnitPrice);
        JobJournalLine.Validate("Unit Cost", ResourceUnitCost);
        JobJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [GIVEN] Post usage for a G/L account the Job Task
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::"G/L Account");
        JobJournalLine.Validate("No.", GLAccountNo);
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Price", GLUnitPrice);
        JobJournalLine.Validate("Unit Cost", GLUnitCost);
        JobJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [WHEN] 'Calculate WIP' and 'Post WIP to G/L' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // [THEN] Amounts are calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Sales G/L Amount".AssertEquals(-(ResourceUnitPrice + GLUnitPrice));
        JobPage."Total WIP Cost G/L Amount".AssertEquals(0);
        JobPage."Recog. Sales G/L Amount".AssertEquals(ResourceUnitPrice + GLUnitPrice);
        JobPage."Recog. Costs G/L Amount".AssertEquals(ResourceUnitCost + GLUnitCost);
        JobPage.Close();

        // [GIVEN] Add a Job Planning Line for the same resource but with a different Unit Price
        LibraryJob.CreateJobPlanningLine("Job planning Line Line Type"::Billable, "Job Planning Line Type"::Resource, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Validate("Unit Cost", ResourceUnitCost);
        JobPlanningLine.Validate("Unit Price", ResourceNewUnitPrice);
        JobPlanningLine.Modify(true);

        // [GIVEN] Sales invoice created and posted for the 'Job Planning Line'
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        GetSalesDocument(JobPlanningLine, "Sales Document Type"::Invoice, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] 'Calculate WIP' and 'Post WIP to G/L' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // [THEN] Amounts are calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Sales G/L Amount".AssertEquals(-(ResourceUnitPrice + GLUnitPrice - ResourceNewUnitPrice));
        JobPage."Total WIP Cost G/L Amount".AssertEquals(0);
        // Recognized Sales and Costs are unchanged.
        JobPage."Recog. Sales G/L Amount".AssertEquals(ResourceUnitPrice + GLUnitPrice);
        JobPage."Recog. Costs G/L Amount".AssertEquals(ResourceUnitCost + GLUnitCost);
        JobPage.Close();
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalWIPCostGLAmountIsCalculatedCorrectlyForJobWithPerJobWIPPostingMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        JobPage: TestPage "Job Card";
        UnitCost: Integer;
        UnitPrice: Integer;
    begin
        Initialize();
        UnitCost := LibraryRandom.RandInt(200);
        UnitPrice := LibraryRandom.RandIntInRange(201, 400);

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Contract (Invoiced Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)");
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job");
        Job.Modify(true);

        // Add Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.Modify(true);

        // Add 'Job Planning Line'
        LibraryJob.CreateJobPlanningLine("Job planning Line Line Type"::Billable, "Job Planning Line Type"::Resource, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Validate("Unit Cost", UnitCost);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine.Modify(true);

        // [GIVEN] Sales invoice created posted for the 'Job Planning Line'
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        GetSalesDocument(JobPlanningLine, "Sales Document Type"::Invoice, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] 'Calculate WIP' and 'Post WIP to G/L' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // [THEN] 'Total WIP Cost G/L Amount' is calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Cost G/L Amount".AssertEquals(-UnitCost);
        JobPage.Close();
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure TotalWIPCostGLAmountIsCalculatedCorrectlyForJobWithPerJobLedgerEntryWIPPostingMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        JobPage: TestPage "Job Card";
        UnitCost: Integer;
        UnitPrice: Integer;
    begin
        Initialize();
        UnitCost := LibraryRandom.RandInt(200);
        UnitPrice := LibraryRandom.RandIntInRange(201, 400);

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job Ledger Entry'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Contract (Invoiced Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)");
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job Ledger Entry");
        Job.Modify(true);

        // Add Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.Modify(true);

        // Add 'Job Planning Line'
        LibraryJob.CreateJobPlanningLine("Job planning Line Line Type"::Billable, "Job Planning Line Type"::Resource, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Validate("Unit Cost", UnitCost);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine.Modify(true);

        // [GIVEN] Sales invoice created posted for the 'Job Planning Line'
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        GetSalesDocument(JobPlanningLine, "Sales Document Type"::Invoice, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] 'Calculate WIP' and 'Post WIP to G/L' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        RunJobPostWIPToGL(Job);

        // [THEN] 'Total WIP Cost G/L Amount' is calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Cost G/L Amount".AssertEquals(-UnitCost);
        JobPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure TestSalesAmountForWIPRecognizedSalesPOC()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        JobPage: TestPage "Job Card";
        ResourceNo: Code[20];
        UnitCost1: Integer;
        UnitCost2: Integer;
        UnitPrice1: Integer;
        UnitPrice2: Integer;
    begin
        // Bug - https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_workitems/edit/454399
        // [Scenario] Verify that the WIP Sales Amount calculated is correct when the 'Recognized Sales' is set to 'Percentage of Completion'
        Initialize();

        // [GIVEN] Input for JobPlanningLines
        UnitCost1 := 10000;
        UnitPrice1 := 11000;
        UnitCost2 := 165;
        UnitPrice2 := 9000;

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Percentage of Completion");
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job Ledger Entry");
        Job.Modify(true);

        // Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.Modify(true);

        // [GIVEN] Create JobPlanningLines
        ResourceNo := LibraryResource.CreateResourceNo();
        LibraryJob.CreateJobPlanningLine("Job Planning Line Line Type"::"Both Budget and Billable", "Job Planning Line Type"::Resource, JobTask, JobPlanningLine1);
        JobPlanningLine1.Validate("No.", ResourceNo);
        JobPlanningLine1.Validate(Quantity, 1);
        JobPlanningLine1.Validate("Unit Cost", UnitCost1);
        JobPlanningLine1.Validate("Unit Price", UnitPrice1);
        JobPlanningLine1.Modify(true);

        LibraryJob.CreateJobPlanningLine("Job Planning Line Line Type"::Billable, "Job Planning Line Type"::Resource, JobTask, JobPlanningLine2);
        JobPlanningLine2.Validate("No.", ResourceNo);
        JobPlanningLine2.Validate(Quantity, 1);
        JobPlanningLine2.Validate("Unit Cost", UnitCost2);
        JobPlanningLine2.Validate("Unit Price", UnitPrice2);
        JobPlanningLine2.Modify(true);

        // [GIVEN] Post usage for 80% of the needed resource consumption
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", ResourceNo);
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Cost", UnitCost1 * 0.8); // 80% usage cost = 8000);
        JobJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [WHEN] 'Calculate WIP' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // [THEN] 'Total WIP Sales Amount' is calculated correctly -> 80% of the total price
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Sales Amount".AssertEquals(-((UnitPrice1 + UnitPrice2) * 0.8)); // 80% of price = 16000);
        JobPage.Close();

        // [GIVEN] Sales invoice for second job plnning line is posted
        JobPlanningLine2.SetRecFilter();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine2, false);

        GetSalesDocument(JobPlanningLine2, "Sales Document Type"::Invoice, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] 'Calculate WIP' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // [THEN] 'Total WIP Sales Amount' is calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Sales Amount".AssertEquals(-(((UnitPrice1 + UnitPrice2) * 0.8) - UnitPrice2));// 80% of total price - posted sales invoice amount = 7000);
        JobPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestTotalWIPSalesAmountWhenUsgeIsPosted()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask1: Record "Job Task";
        JobTask2: Record "Job Task";
        JobTask3: Record "Job Task";
        JobJournalLine1: Record "Job Journal Line";
        JobJournalLine2: Record "Job Journal Line";
        JobPage: TestPage "Job Card";
        ResourceNo: Code[20];
        UnitCost: Integer;
        UnitPrice: Integer;

    begin
        // Bug - https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_workitems/edit/454399
        // [Scenario] Verify that the WIP Sales Amount calculated is correct when usage is posted for a job
        Initialize();

        // [GIVEN] Input for Job Journal Lines
        UnitCost := 165;
        UnitPrice := 290;

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Usage (Total Price)");
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job");
        Job.Modify(true);

        // Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask1);
        JobTask1.Validate("Job Task Type", JobTask1."Job Task Type"::Posting);
        JobTask1.Modify(true);

        LibraryJob.CreateJobTask(Job, JobTask2);
        JobTask2.Validate("Job Task Type", JobTask2."Job Task Type"::Posting);
        JobTask2.Modify(true);

        LibraryJob.CreateJobTask(Job, JobTask3);
        JobTask3.Validate("Job Task Type", JobTask3."Job Task Type"::Total);
        JobTask3.Validate(Totaling, StrSubstNo('%1..%2', JobTask1."Job Task No.", JobTask2."Job Task No."));
        JobTask3.Validate("WIP-Total", JobTask3."WIP-Total"::Total);
        JobTask3.Validate("WIP Method", JobWIPMethod.Code);
        JobTask3.Modify(true);

        // [GIVEN] Post 2 journal lines(usage)
        ResourceNo := LibraryResource.CreateResourceNo();
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask1, JobJournalLine1);
        JobJournalLine1.Validate("Job Task No.", JobTask1."Job Task No.");
        JobJournalLine1.Validate(Type, JobJournalLine1.Type::Resource);
        JobJournalLine1.Validate("No.", ResourceNo);
        JobJournalLine1.Validate(Quantity, 1);
        JobJournalLine1.Validate("Unit Cost", UnitCost);
        JobJournalLine1.Validate("Unit Price", UnitPrice);
        JobJournalLine1.Modify(true);

        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask2, JobJournalLine2);
        JobJournalLine2.Validate("Job Task No.", JobTask2."Job Task No.");
        JobJournalLine2.Validate(Type, JobJournalLine2.Type::Resource);
        JobJournalLine2.Validate("No.", ResourceNo);
        JobJournalLine2.Validate(Quantity, 1);
        JobJournalLine2.Validate("Unit Cost", UnitCost);
        JobJournalLine2.Validate("Unit Price", UnitPrice);
        JobJournalLine2.Modify(true);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryJob.PostJobJournal(JobJournalLine1);

        // [WHEN] 'Calculate WIP' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // [THEN] 'Total WIP Sales Amount' is calculated correctly
        JobPage.OpenView();
        JobPage.GoToRecord(Job);
        JobPage."Total WIP Sales Amount".AssertEquals(-(UnitPrice * 2));
        JobPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure VerifyTotalWIPSalesAmountForJobWithPerJobLedgerEntry()
    var
        Job: Record Job;
        JobWIPMethod: Record "Job WIP Method";
        JobJournalLine: Record "Job Journal Line";
        JobPlanningLine: Record "Job Planning Line";
        ExpectedTotalWIPSalesAmount: Integer;
        BillableResourceUnitPrice: Integer;
        BudgetResourceUnitPrice: Integer;
        NoOfJobTask: Integer;
        Quantity: Integer;
    begin
        // [SCENARIO 473135] Verify the Total WIP Sales Amount Per Job Ledger Entry when running Job WIP.
        Initialize();

        // [GIVEN] Create a Job WIP Method.
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);

        // [GIVEN] Update Recognized Costs and Recognized Sales in the Job WIP Method.
        UpdateRecognizedCostsAndRecognizedSales(
            JobWIPMethod,
            "Job WIP Recognized Costs Type"::"Usage (Total Cost)",
            "Job WIP Recognized Sales Type"::"Usage (Total Price)");

        // [GIVEN] Create a new Job.
        LibraryJob.CreateJob(Job);

        // [GIVEN] Update the WIP Method and WIP Posting Method in the Job.
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job Ledger Entry");
        Job.Modify(true);

        // [GIVEN] Generate a random no. of Job Task, Quantity, Billable and Budget Unit Price.
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        NoOfJobTask := LibraryRandom.RandIntInRange(2, 10);
        BudgetResourceUnitPrice := LibraryRandom.RandIntInRange(250, 300);
        BillableResourceUnitPrice := LibraryRandom.RandIntInRange(1000, 2000);

        // [GIVEN] Create Multiple Job Tasks for Job Task Type Posting.
        CreateMultipleJobTasksForJobTaskTypePosting(Job, NoOfJobTask);

        // [GIVEN] Create a Job Task for Job Task Type Total.
        CreateJobTaskForJobTaskTypeTotal(Job);

        // [GIVEN] Create Job Planning Lines for Multiple Job Task with Billable Resources, Qty., Resource Unit Cost and Unit Price.
        CreateJobPlanningLinesForMultipleJobTaskTypePosting(
            Job,
            Quantity,
            LibraryRandom.RandIntInRange(100, 200),
            BillableResourceUnitPrice);

        // [GIVEN] Save the Transaction.
        Commit();

        // [THEN] Find the Job Planning Line.
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.FindSet();

        // [THEN] Create a Sales Invoice and Post it.
        CreateAndPostSalesInvoice(JobPlanningLine);

        // [WHEN] Calculate WIP.
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // [GIVEN] Calculate Expected Total WIP Sales Amount.
        ExpectedTotalWIPSalesAmount := BillableResourceUnitPrice * Quantity * NoOfJobTask;

        // [VERIFY] Verify the Total WIP Sales Amount.
        Job.CalcFields("Total WIP Sales Amount");
        Assert.AreEqual(
            ExpectedTotalWIPSalesAmount,
            Job."Total WIP Sales Amount",
            StrSubstNo(
                ValueMustBeEqualErr,
                Job.FieldCaption("Total WIP Sales Amount"),
                ExpectedTotalWIPSalesAmount));

        // [GIVEN] Create Job Journal Lines for Multiple Job Task with Budget Resource, Qty., Resource Unit Cost and Unit Price.
        CreateJobJournalLinesForMultipleJobTaskTypePosting(
            Job,
            Quantity,
            LibraryRandom.RandIntInRange(100, 200),
            BudgetResourceUnitPrice);

        // [THEN] Find the Job Journal Lines.
        JobJournalLine.SetRange("Job No.", Job."No.");
        JobJournalLine.FindSet();

        // [GIVEN] Post the Job Journal Lines.
        LibraryVariableStorage.Enqueue(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [WHEN] Calculate WIP
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // [GIVEN] Calculate Expected Total WIP Sales Amount.
        ExpectedTotalWIPSalesAmount -= BudgetResourceUnitPrice * Quantity * NoOfJobTask;

        // [VERIFY] Verify the Total WIP Sales Amount.
        Job.CalcFields("Total WIP Sales Amount");
        Assert.AreEqual(
            ExpectedTotalWIPSalesAmount,
            Job."Total WIP Sales Amount",
            StrSubstNo(
                ValueMustBeEqualErr,
                Job.FieldCaption("Total WIP Sales Amount"),
                ExpectedTotalWIPSalesAmount));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler')]
    [Scope('OnPrem')]
    procedure RecogProfitGLAmountIsCalculatedCorrectlyForJobWithPerJobWIPPostingMethod()
    var
        JobWIPMethod: Record "Job WIP Method";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobWIPCockpit: TestPage "Job WIP Cockpit";
        ResourceNo: Code[20];
        UnitPrice: Integer;
    begin
        // [SCENARIO 474478] The field “Recog Profit G/L Amount” on Job WIP page does not show the same amount as on the Job Card.
        Initialize();
        UnitPrice := LibraryRandom.RandIntInRange(201, 400);

        // [GIVEN] Job with task where the WIP Posting Method is 'Per Job'
        // Create and setup 'Job WIP Method'
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Usage (Total Price)");
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job");
        Job.Modify(true);

        // Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate("WIP Method", JobWIPMethod.Code);
        JobTask.Modify(true);

        // [GIVEN] Post usage on the Job Task
        ResourceNo := LibraryResource.CreateResourceNo();
        LibraryJob.CreateJobJournalLine("Job Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", ResourceNo);
        JobJournalLine.Validate(Quantity, 1);
        JobJournalLine.Validate("Unit Price", UnitPrice);
        JobJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [WHEN] 'Calculate WIP' is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);

        // [VERIFY] Verify: "Recog. Profit G/L Amount" and "Recog. Profit Amount Difference" are calculated correctly when Calculate WIP
        JobWIPCockpit.OpenView();
        JobWIPCockpit.GoToRecord(Job);
        JobWIPCockpit."Recog. Profit Amount".AssertEquals(Job.CalcRecognizedProfitAmount());
        JobWIPCockpit."Recog. Profit Amount Difference".AssertEquals(
            Job.CalcRecognizedProfitAmount() - Job.CalcRecognizedProfitGLAmount());
        JobWIPCockpit.Close();

        // [WHEN] 'Post WIP to G/L' is called
        RunJobPostWIPToGL(Job);

        // [VERIFY] Verify: "Recog. Profit G/L Amount" and "Recog. Profit Amount Difference" are calculated correctly after Post WIP to G/L
        JobWIPCockpit.OpenView();
        JobWIPCockpit.GoToRecord(Job);
        JobWIPCockpit."Recog. Profit G/L Amount".AssertEquals(Job.CalcRecognizedProfitGLAmount());
        JobWIPCockpit."Recog. Profit Amount Difference".AssertEquals(
            Job.CalcRecognizedProfitAmount() - Job.CalcRecognizedProfitGLAmount());
        JobWIPCockpit.Close();
    end;

    local procedure GetSalesDocument(JobPlanningLine: Record "Job Planning Line"; DocumentType: Enum "Sales Document Type"; var SalesHeader: Record "Sales Header")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        JobPlanningLineInvoice.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        if DocumentType = SalesHeader."Document Type"::Invoice then
            JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::Invoice)
        else
            JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::"Credit Memo");
        JobPlanningLineInvoice.FindFirst();
        SalesHeader.Get(DocumentType, JobPlanningLineInvoice."Document No.")
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

    local procedure RunJobPostWIPToGL(Job: Record Job)
    var
        JobPostWIPToGL: Report "Job Post WIP to G/L";
    begin
        Job.SetRange("No.", Job."No.");
        Clear(JobPostWIPToGL);
        JobPostWIPToGL.SetTableView(Job);
        JobPostWIPToGL.UseRequestPage(false);
        JobPostWIPToGL.Run();
    end;

    local procedure UpdateRecognizedCostsAndRecognizedSales(
        var JobWIPMethod: Record "Job WIP Method";
        JobWIPRecognizedCostsType: Enum "Job WIP Recognized Costs Type";
        JobWIPRecognizedSalesType: Enum "Job WIP Recognized Sales Type")
    begin
        JobWIPMethod.Validate("Recognized Costs", JobWIPRecognizedCostsType);
        JobWIPMethod.Validate("Recognized Sales", JobWIPRecognizedSalesType);
        JobWIPMethod.Modify(true);
    end;

    local procedure CreateMultipleJobTasksForJobTaskTypePosting(Job: Record Job; NoOfJobTask: Integer)
    var
        JobTask: Record "Job Task";
        Counter: Integer;
    begin
        for Counter := 1 to NoOfJobTask do
            LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobTaskForJobTaskTypeTotal(Job: Record Job)
    var
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("Job Task Type", JobTask."Job Task Type"::Total);
        JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.Validate(Totaling, StrSubstNo(JobTaskTotalingLbl, JobTask."Job Task No."));
        JobTask.Modify(true);
    end;

    local procedure CreateJobPlanningLinesForMultipleJobTaskTypePosting(
        Job: Record Job;
        Quantity: Integer;
        ResourceUnitCost: Integer;
        ResourceUnitPrice: Integer)
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if JobTask.FindSet() then
            repeat
                LibraryJob.CreateJobPlanningLine(
                    "Job planning Line Line Type"::Billable,
                    "Job Planning Line Type"::Resource,
                    JobTask,
                    JobPlanningLine);

                JobPlanningLine.Validate(Quantity, Quantity);
                JobPlanningLine.Validate("Unit Cost", ResourceUnitCost);
                JobPlanningLine.Validate("Unit Price", ResourceUnitPrice);
                JobPlanningLine.Modify(true);
            until JobTask.Next() = 0;
    end;

    local procedure CreateAndPostSalesInvoice(var JobPlanningLine: Record "Job Planning Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        GetSalesDocument(JobPlanningLine, "Sales Document Type"::Invoice, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateJobJournalLinesForMultipleJobTaskTypePosting(
        Job: Record Job;
        Quantity: Integer;
        ResourceUnitCost: Integer;
        ResourceUnitPrice: Integer)
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if JobTask.FindSet() then
            repeat
                LibraryJob.CreateJobJournalLine("Job Line Type"::Budget, JobTask, JobJournalLine);
                JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
                JobJournalLine.Validate("No.", LibraryResource.CreateResourceNo());
                JobJournalLine.Validate(Quantity, Quantity);
                JobJournalLine.Validate("Unit Cost", ResourceUnitCost);
                JobJournalLine.Validate("Unit Price", ResourceUnitPrice);
                JobJournalLine.Modify(true);
            until JobTask.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferToInvoiceHandler(var RequestPage: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        RequestPage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerMultipleResponses(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}